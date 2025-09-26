require_relative 'abstract_resource'
require_relative '../ordered_hash'

# NOTE: image_resource must follow resource due to inheritance
# NOTE: range must follow sequence due to inheritance
%w[
  annotation
  annotation_collection
  annotation_page
  canvas
  choice
  collection
  manifest
  nav_place
  resource
  image_resource
  sequence
  range
  service
].each do |f|
  require File.join(File.dirname(__FILE__), 'presentation', f)
end

module IIIF
  module V3
    module Presentation
      CONTEXT ||= [
        'http://www.w3.org/ns/anno.jsonld',
        'http://iiif.io/api/presentation/3/context.json'
      ]

      class MissingRequiredKeyError < StandardError; end
      class ProhibitedKeyError < StandardError; end
      class IllegalValueError < StandardError; end
    end
  end
end
