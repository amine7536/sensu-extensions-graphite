# coding: utf-8

Gem::Specification.new do |spec|
  spec.name          = "sensu-extensions-graphite"
  spec.version       = "0.0.2"
  spec.authors       = ["Sensu-Extensions and contributors"]
  spec.email         = ["<amine.benseddik@gmail.com>"]

  spec.summary       = "Extension to get metrics into Graphite"
  spec.description   = "Extension to get metrics into Graphite"
  spec.homepage      = "https://github.com/amine7536/sensu-extensions-graphite"

  spec.files         = Dir.glob('{bin,lib}/**/*') + %w(LICENSE README.md CHANGELOG.md)
  spec.require_paths = ["lib"]

  spec.add_dependency "sensu-extension"

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "sensu-logger"
  spec.add_development_dependency "sensu-settings"
end
