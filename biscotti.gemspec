# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'biscotti/version'

Gem::Specification.new do |gem|
  gem.name          = "biscotti"
  gem.version       = Biscotti::VERSION
  gem.authors       = ["Jeff Fernandez"]
  gem.email         = ["catnapper321@gmail.com"]
  gem.description   = %q{A module packed with convenience methods for scripting}
  gem.summary       = %q{Grab bag of scripting helper methods}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency 'values', '~>1.2.1'
end
