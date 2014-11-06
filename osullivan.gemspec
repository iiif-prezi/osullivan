version = File.read(File.expand_path('../VERSION', __FILE__)).strip

Gem::Specification.new do |spec|
  spec.name          = 'osullivan'
  spec.version       = version 
  spec.authors       = ['Jon Stroop']
  spec.email         = ['jpstroop@gmail.com']
  spec.description   = 'API for working with IIIF Presentation manifests.'
  spec.summary       = 'API for working with IIIF Presentation manifests.'
  spec.license       = 'APACHE2'
  spec.homepage      = 'https://github.com/jpstroop/osullivan'

  spec.files         = `git ls-files`.split($/)
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'coveralls' #, require: false

  spec.add_dependency 'json'
  spec.add_dependency 'activesupport', '~> 4.1.6'
end
