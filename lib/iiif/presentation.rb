%w{
service 
  abstract_resource 
    annotation 
    canvas 
    hash_behaviours  
    manifest
    resource 
      image_resource 
    sequence 
}.each do |f|
  require File.join(File.dirname(__FILE__), 'presentation', f)
end
require File.join(File.dirname(__FILE__), '../active_support/ordered_hash')

module IIIF
  module Presentation
    CONTEXT ||= 'http://iiif.io/api/presentation/2/context.json'

    class MissingRequiredKeyError < StandardError; end
    class IllegalValueError < StandardError; end
  end
end
