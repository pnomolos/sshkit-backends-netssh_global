# -*- encoding: utf-8 -*-
require File.expand_path('../lib/sshkit/backends/version', __FILE__)

Gem::Specification.new do |gem|

  gem.authors       = ["Theo Cushion", "Dennis Ideler"]
  gem.email         = ["tcushion@pivotal.io", "dennis.ideler@fundingcircle.com"]
  gem.summary       = %q{SSHKit backend for globally sudoing commands}
  gem.description   = %q{A backend to be used in conjunction with Capistrano 3
and SSHKit to allow deployment on setups where users login as one identity and
then need to sudo to a different identity for each command.}
  gem.homepage      = "http://github.com/fundingcircle/sshkit-backends-netssh_global"
  # gem.license       = "GPL3"

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- test/*`.split("\n")
  gem.name          = "sshkit-backends-netssh_global"
  gem.require_paths = ["lib"]
  gem.version       = SSHKit::Backends::NetsshGlobal::VERSION

  gem.add_runtime_dependency('sshkit', '1.31.1')

  gem.add_development_dependency('minitest', ['>= 2.11.3', '< 2.12.0'])
  gem.add_development_dependency('rake')
  gem.add_development_dependency('turn')
  gem.add_development_dependency('mocha')
end
