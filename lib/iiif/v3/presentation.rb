require File.join(File.dirname(__FILE__), 'service')
%w{
abstract_resource
  annotation
  annotation_collection
  annotation_page
  canvas
  collection
  manifest
  resource
    image_resource
  sequence
    range
}.each do |f|
  require File.join(File.dirname(__FILE__), 'presentation', f)
end

require_relative 'ordered_hash'

module IIIF
  module V3
    module Presentation
      # TODO: when v3 is baked, there will be a context
      # CONTEXT ||= 'http://iiif.io/api/presentation/2/context.json'

      class MissingRequiredKeyError < StandardError; end
      class IllegalValueError < StandardError; end
    end
  end
end
