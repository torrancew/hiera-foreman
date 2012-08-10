# -*- encoding: utf-8 -*-

Gem::Specification.new do |gem|
  gem.authors       = ["Tray Torrance"]
  gem.email         = ["devwork@warrentorrance.com"]
  gem.description   = %q{A simple hiera backend that queries the Foreman REST API for data}
  gem.summary       = %q{Hiera backend to query Foreman}
  gem.homepage      = "https://github.com/torrancew/hiera-foreman"

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = "hiera-foreman"
  gem.require_paths = ["lib"]
  gem.version       = '0.0.1'
end

