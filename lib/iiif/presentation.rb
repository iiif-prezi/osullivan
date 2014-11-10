Dir["#{File.join(File.dirname(__FILE__), 'presentation')}/*.rb"].each do |f|
  require f
end

module IIIF
  module Presentation
  	CONTEXT ||= 'http://iiif.io/api/presentation/2/context.json'

    class MissingRequiredKeyError < StandardError; end
    class IllegalValueError < StandardError; end
  end
end

# p = IIIF::Presentation::Manifest.new
# puts p.methods
