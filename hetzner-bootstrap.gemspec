# -*- encoding: utf-8 -*-
$LOAD_PATH.push File.expand_path('../lib', __FILE__)
require 'hetzner/bootstrap/version'

Gem::Specification.new do |s|
  s.name        = 'hetzner-bootstrap'
  s.version     = Hetzner::Bootstrap::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Roland Moriz']
  s.email       = ['roland@moriz.de']
  s.homepage    = 'http://moriz.de/opensource/hetzner-api'
  s.summary     = 'Easy bootstrapping of hetzner.de rootservers using hetzner-api'
  s.description = 'Easy bootstrapping of hetzner.de rootservers using hetzner-api'

  s.add_dependency 'hetzner-api', '>= 1.1.0'
  s.add_dependency 'net-ssh',     '>= 2.6.0'
  s.add_dependency 'erubis',      '>= 2.7.0'

  s.add_development_dependency 'rspec', '~> 3.4.0'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rubocop', '~> 0.36.0'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.require_paths = ['lib']
end
