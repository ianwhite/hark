# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'hark/version'

Gem::Specification.new do |spec|
  spec.name          = "ianwhite-hark"
  spec.version       = Hark::VERSION
  spec.authors       = ["Ian White"]
  spec.email         = ["ian.w.white@gmail.com"]
  spec.description   = %q{Create ad-hoc listener objects with impunity}
  spec.summary       = %q{Hark is a gem that enables  writing code in a "hexagonal architecture" or "tell don't ask" style}
  spec.homepage      = "http://github.com/ianwhite/hark"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "coveralls"
end
