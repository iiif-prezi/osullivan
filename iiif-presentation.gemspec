version = File.read(File.expand_path('VERSION', __dir__)).strip

Gem::Specification.new do |spec|
  spec.name          = 'iiif-presentation'
  spec.version       = version
  spec.authors       = ['Jon Stroop']
  spec.email         = ['jpstroop@gmail.com']
  spec.description   = 'API for working with IIIF Presentation manifests.'
  spec.summary       = 'API for working with IIIF Presentation manifests.'
  spec.license       = 'Simplified BSD'
  spec.homepage      = 'https://github.com/iiif/osullivan'

  spec.files         = `git ls-files`.split($/)
  spec.test_files    = spec.files.grep(%r{^spec/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'coveralls'
  spec.add_development_dependency 'multi_json'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'vcr', '~> 5'
  spec.add_development_dependency 'webmock'

  spec.add_dependency 'activesupport', '>= 3.2.18'
  spec.add_dependency 'faraday', '~> 2.7'
  spec.add_dependency 'geo_coord'
  spec.add_dependency 'json'
end
