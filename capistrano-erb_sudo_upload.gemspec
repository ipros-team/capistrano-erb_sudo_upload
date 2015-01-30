# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "capistrano-erb_sudo_upload"
  spec.version       = "0.1.0"
  spec.authors       = ["toyama0919"]
  spec.email         = ["toyama0919@gmail.com"]
  spec.description   = %q{Generate erb file and sudo upload.}
  spec.summary       = %q{Generate erb file and sudo upload.}
  spec.homepage      = "https://github.com/toyama0919/capistrano-erb_sudo_upload"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency 'capistrano', '>= 2.15.0'
  spec.add_dependency 'capistrano-switchuser'
  spec.add_development_dependency "bundler", "~> 1.72"
  spec.add_development_dependency "rake"
end
