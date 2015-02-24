require 'eax/version'
require 'tty'
require 'filesize'

module Eax

  class FileListing

    # List all items in a given directory
    # +dir+ is the directory in which to list the items
    # +hidden+ display hidden files
    def self.list_files_in(dir, hidden: false, parent_dir: true)
      args = [File.join(dir, '*')]
      args << File::FNM_DOTMATCH if hidden
      files = Dir.glob(*args)
      files.reject! { |file| file.end_with? '.' or file.end_with? '..' } if parent_dir
      files
    end
  end

  class EaxDir
    attr_accessor :eax_files, :options, :list

    def initialize(options)
      @eax_files = []
      @options = options
      hidden = (options.all? or options.long?)
      order(
          FileListing.list_files_in(options.arguments.first || Dir.pwd, hidden: hidden),
          by: (options[:sort] || :name).to_sym,
          desc: options.reverse?
      )
    end

    def to_s
      files_info = eax_files.map {|file| file.output(options) }
      if print_list?
        files_info.join("\n")
      else
        files_info.join(' ' * 3)
      end
    end

    private

      def print_list?
        options.oneline? or options.long?
      end

    def init_eax_files(files)
      files.each do |file|
        @eax_files << EaxFile.new(file)
      end
    end

    def order(files, by: :name, desc: false)
      case by
        when :name
          files.sort!
          files.reverse! if desc
          init_eax_files files
        else
          init_eax_files files
      end
    end
  end

  class EaxFile

    attr_accessor :type, :path_name

    def initialize(file)
      @path_name = Pathname.new(file)
      @type = file_type(@path_name)
    end

    def color
      @color ||= Pastel.new
    end

    def output(options)
      if options.long?
        [print_rights, print_size(bytes: options.bytes?), print_user(group: options.group?),
        choose_date_to_print(options), print_name
        ]
      else
        [print_name]
      end.join(' ')
    end

    private
    def print_rights(group: false)
      mode = path_name.stat.mode.to_s(8)
      folder = mode[0] == '4' ? color.blue('d') : '.'
      user = mode[-3].to_i
      group = mode[-2].to_i
      other = mode[-1].to_i
      rights = [folder, color.bold(determine_right(user))]
      rights << determine_right(group) << determine_right(other) if group
      rights.join
    end

    def determine_right(number)
      right = ''

      {4 => color.dim.yellow('r'), 2 => color.red('w'), 1 => color.green('x'), 0 => '-'}.each { |key, value|
        compar = number - key
        if compar >= 0
          right += value
        else
          right += '-'
          next
        end
        number = compar
      }
      right[0..-2]
    end

    def print_size(bytes: false)
      return ' ' * 5 + '-' if path_name.directory?
      size = path_name.stat.size
      return color.green.bold size.to_s if bytes
      size_in_word = Filesize.from("#{size} B").pretty.gsub(/\.00/, '').gsub(' ', '').gsub(/B/, '')
      color.green.bold(' ' * (6 - size_in_word.length) + size_in_word )
    end

    def print_user(group: false)
      user = color.yellow.bold(Etc.getpwuid(path_name.stat.uid).name)
      user += color.yellow(' ' + Etc.getgrgid(path_name.stat.gid).name) if group
      user
    end

    def print_date(date)
      color.blue date.strftime("%d %b %H:%M")
    end

    def choose_date_to_print(options)
      stat = path_name.stat
      if options.modified?
        print_date stat.mtime
      else
        print_date stat.ctime
      end
    end

    def print_name
      type.output(path_name.basename)
    end

    def file_type(path_name)
      return FileTypes::FolderType.new if path_name.directory?
      return FileTypes::ExecutableType.new if path_name.executable?
      return FileTypes::ImportantType.new if %w(README.md Gemfile Grunt.js).include? path_name.basename.to_s
      case path_name.extname
        when 'jpeg', 'jpg', 'gif', 'svg', 'bitmap'
          FileTypes::ImageType.new
        else
          FileTypes::NormalType.new
      end
    end
  end

  module Console

    def terminal
      @terminal ||= TTY::Terminal.new
    end

    def color
      @color ||= Pastel.new
    end
  end

  module FileTypes

    class NormalType
      include Console

      def output(string)
        string
      end
    end

    class BinaryType < NormalType
      def output(string)

      end
    end

    class ImportantType < NormalType

      def output(string)
        color.yellow.underline.bold string
      end
    end

    class ImageType < NormalType
      def output(string)
      end
    end

    class ExecutableType < NormalType

      def output(string)
        color.green string
      end
    end

    class FolderType < NormalType

      def output(string)
        color.blue.bold string
      end
    end
  end
end
