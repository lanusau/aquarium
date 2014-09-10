# -*- encoding: utf-8 -*-
require File.expand_path('../lib/aquarium/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors = ["Laimonas Anusauskas"]
  gem.email = ["lanusauskas@corp.untd.com"]
  gem.description = %q{Aquarium - database change manegement}
  gem.summary = %q{Aqarium - database change manegement}
  gem.homepage = "https://github.com/lanusau/aquarium"
  gem.license = 'MIT'

  gem.add_runtime_dependency 'dbd-mysql', '~> 0.4'
  gem.add_runtime_dependency 'ruby-oci8', '~> 2.1'
  gem.add_runtime_dependency  'encryptor', '~> 1.3'
  gem.add_runtime_dependency  'colored', '~> 1.2'

  gem.add_development_dependency 'rspec', '~> 3.0'
  gem.add_development_dependency 'simplecov', '~> 0.9'
  gem.add_development_dependency 'rake', '~> 10.3'
  gem.add_development_dependency 'byebug'

  gem.executables = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files = `git ls-files`.split("\n")
  gem.test_files = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name = "aquarium"
  gem.require_paths = ["lib"]
  gem.version = Aquarium::VERSION
end
