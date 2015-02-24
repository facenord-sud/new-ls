# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'eax/version'

Gem::Specification.new do |spec|
  spec.name          = "eax"
  spec.version       = Eax::VERSION
  spec.authors       = ["facenord"]
  spec.email         = ["facenord.sud@gmail.com"]
  spec.summary       = %q{Replacement for ls}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"

  spec.add_dependency 'tty', '~> 0.1.2'
  spec.add_dependency 'slop', '~> 4.0.0'
  spec.add_dependency 'filesize', '~> 0.0.4'
end