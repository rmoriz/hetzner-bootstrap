# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "hetzner/bootstrap/version"

Gem::Specification.new do |s|
  s.name        = "hetzner"
  s.version     = Hetzner::Bootstrap::VERSION
  #s.version     = '0.0.1'
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["TODO: Write your name"]
  s.email       = ["TODO: Write your email address"]
  s.homepage    = ""
  s.summary     = %q{TODO: Write a gem summary}
  s.description = %q{TODO: Write a gem description}

  s.rubyforge_project = "hetzner"

  s.add_dependency 'hetzner-api'
  s.add_dependency 'net-ssh'
  s.add_dependency 'erubis'

  s.add_development_dependency "rspec",   ">= 2.4.0"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
