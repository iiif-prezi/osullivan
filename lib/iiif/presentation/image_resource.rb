require File.join(File.dirname(__FILE__), 'resource')
require 'faraday'
require 'json'

module IIIF
  module Presentation
    class ImageResource < Resource

      TYPE = 'dctypes:Image'

      def int_only_keys
        super + %w{ width height }
      end

      def initialize(hsh={})
        hsh['@type'] = 'dcterms:Image' unless hsh.has_key? '@type'
        super(hsh)
      end

      class << self
        IMAGE_API_DEFAULT_PARAMS = '/full/!200,200/0/default.jpg'
        IMAGE_API_CONTEXT = 'http://iiif.io/api/image/2/context.json'
        DEFAULT_FORMAT = 'image/jpeg'
        # Create a new ImageResource that includes a IIIF Image API Service
        # See http://iiif.io/api/presentation/2.0/#image-resources
        #
        # Params
        #  * :service_id (required) - The base URI for the image on the image 
        #      server.
        #  * :resource_id - The id for the resource; if supplied this should 
        #      resolve to an actual image. Default: 
        #      "#{:service_id}/full/!200,200/0/default.jpg"
        #  * :format - The format of the image that is returned when 
        #       `:resource_id` is resolved. Default: 'image/jpeg'
        #  * :height (Integer)
        #  * :profile (String)
        #  * :width (Integer) - If width, height, and profile are not supplied, 
        #      this method will try to get the info from the server (based on 
        #      :resource_id) and raise an Exception if this is not possible for
        #       some reason.
        #  * :copy_info (bool)- Even if width and height are supplied, try to 
        #      get the info.json from the server and copy it in. Default: false
        #
        # Raises:
        #  * KeyError if `:service_id` is not supplied
        #  * Expections related to HTTP problems if a call to an image server fails
        #
        # The result is something like this:
        #
        # {
        #   "@id":"http://www.example.org/iiif/book1/res/page1.jpg",
        #   "@type":"dctypes:Image",
        #   "format":"image/jpeg",
        #   "service": {
        #     "@context": "http://iiif.io/api/image/2/context.json",
        #     "@id":"http://www.example.org/images/book1-page1",
        #     "profile":"http://iiif.io/api/image/2/profiles/level2.json",
        #   },
        #   "height":2000,
        #   "width":1500
        # }
        #
        def create_image_api_image_resource(params={})

          service_id = params.fetch(:service_id)
          resource_id_default = "#{service_id}#{IMAGE_API_DEFAULT_PARAMS}"
          resource_id = params.fetch(:resource_id, resource_id_default)
          format = params.fetch(:format, DEFAULT_FORMAT)
          height = params.fetch(:height, nil)
          profile = params.fetch(:profile, nil)
          width = params.fetch(:width, nil)
          copy_info = params.fetch(:copy_info, false)
          
          have_whp = [width, height, profile].all? { |prop| !prop.nil? }

          remote_info = get_info(service_id) if !have_whp || copy_info

          resource = self.new
          resource['@id'] = resource_id
          resource.format = format
          resource.width = width.nil? ? remote_info['width'] : width
          resource.height = height.nil? ? remote_info['height'] : height
          resource.service = Service.new
          if copy_info
            resource.service.merge!(remote_info)
          else
            resource.service['@context'] = IMAGE_API_CONTEXT
            resource.service['@id'] = service_id
            if profile.nil?
              if remote_info['profile'].kind_of?(Array)
                resource.service['profile'] = remote_info['profile'][0]
              else
                resource.service['profile'] = remote_info['profile'][0]
              end
            else
              resource.service['profile'] = profile
            end
          end
          return resource
        end

        protected
        def get_info(svc_id)
          conn = Faraday.new("#{svc_id}/info.json") do |c|
            c.use Faraday::Response::RaiseError
            c.use Faraday::Adapter::NetHttp
          end
          resp = conn.get # raises exceptions that indicate HTTP problems
          JSON.parse(resp.body)
        end
      end

    end
  end
end
