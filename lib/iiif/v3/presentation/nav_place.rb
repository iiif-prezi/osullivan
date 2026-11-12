require 'geo/coord'
require 'uri'

module IIIF
  module V3
    module Presentation
      class NavPlace < IIIF::V3::AbstractResource
        Rect = Struct.new(:coord1, :coord2)

        DECIMAL = /\d+(?:\.\d+)?/

        # Matches one coordinate, in either of two forms:
        # - degrees with a degree sign, optionally followed by minutes and seconds,
        #   any of which may be decimal, with the hemisphere before or after
        #   ("W 23°54'00\"", "23°54′00″W", "E 138.5°", "N 37°26ʹ30.5″");
        # - decimal degrees with no degree sign, which need the hemisphere first
        #   ("E 138.0").
        COORD_REGEX = /
          (?:(?<hemisphere>[NSEW])\s*)?(?<![\d.])(?<degrees>#{DECIMAL})[°⁰*]
          (?:\s*(?<minutes>#{DECIMAL})[\'ʹ′])?
          (?:\s*(?<seconds>#{DECIMAL})["ʺ″])?
          (?:\s*(?<hemisphere>[NSEW]))?
        |
          (?<hemisphere>[NSEW])\s*(?<degrees>\d+\.\d+)(?![\d.°⁰*\'ʹ′"ʺ″])
        /x

        # @param [Array<String>] coordinate_texts
        # @param [String, nil] base_uri optional prefix for the Feature Collection and Feature ids
        def initialize(coordinate_texts:, base_uri: nil)
          raise ArgumentError, "base_uri must be an absolute HTTP(S) URI, got #{base_uri.inspect}" unless base_uri.nil? || base_uri.start_with?(/https?:\/\//)

          @coordinate_texts = coordinate_texts
          @base_uri = base_uri
        end

        # @return [Boolean] indicates if coordinate_texts passed in are valid
        def valid?
          !(coordinates.nil? || coordinates.empty?)
        end

        def build
          raise ArgumentError.new('invalid coordinates') unless valid?

          with_id("#{base_uri}/feature-collection/1",
                  type: 'FeatureCollection',
                  features: features)
        end

        private

        attr_reader :coordinate_texts, :base_uri

        def coordinates
          @coordinates ||= coordinate_texts.map do |coordinate_text|
            coordinate_parts = coordinate_text.split(%r{ ?--|/})
            case coordinate_parts.length
            when 2
              coord_for(coordinate_parts[0], coordinate_parts[1])
            when 4
              rect_for(coordinate_parts)
            end
          end.compact
        end

        def coord_for(long_str, lat_str)
          long_matcher = long_str.match(COORD_REGEX)
          lat_matcher = lat_str.match(COORD_REGEX)
          return unless long_matcher && lat_matcher

          Geo::Coord.new(latd: lat_matcher[:degrees], latm: lat_matcher[:minutes], lats: lat_matcher[:seconds], lath: lat_matcher[:hemisphere],
                        lngd: long_matcher[:degrees], lngm: long_matcher[:minutes], lngs: long_matcher[:seconds], lngh: long_matcher[:hemisphere])
        rescue ArgumentError
          nil
        end

        def rect_for(coordinate_parts)
          coord1 = coord_for(coordinate_parts[0], coordinate_parts[2])
          coord2 = coord_for(coordinate_parts[1], coordinate_parts[3])
          return if coord1.nil? || coord2.nil?

          Rect.new(coord1, coord2)
        end

        def features
          coordinates.map.with_index(1) do |coordinate, index|
            with_id("#{base_uri}/iiif/feature/#{index}",
                    type: 'Feature',
                    properties: {},
                    geometry: coordinate.is_a?(Rect) ? polygon_geometry(coordinate) : point_geometry(coordinate))
          end
        end

        # The navPlace extension makes ids optional, so leave them out without a base_uri.
        def with_id(id, resource)
          base_uri ? { id: id }.merge(resource) : resource
        end

        def point_geometry(coord)
          {
            type: 'Point',
            coordinates: [format(coord.lng), format(coord.lat)]
          }
        end

        def polygon_geometry(rect)
          west = edge(format(rect.coord1.lng), from: 180.0, to: -180.0)
          east = edge(format(rect.coord2.lng), from: -180.0, to: 180.0)
          south, north = [format(rect.coord1.lat), format(rect.coord2.lat)].minmax

          return { type: 'Polygon', coordinates: [ring(west, east, south, north)] } unless west > east

          # A box reads west to east, so a west edge greater than its east edge means
          # the box crosses the antimeridian. GeoJSON has no wrapping boxes, so such a
          # box is split there into two polygons (RFC 7946, section 3.1.9).
          {
            type: 'MultiPolygon',
            coordinates: [
              [ring(west, 180.0, south, north)],
              [ring(-180.0, east, south, north)]
            ]
          }
        end

        # If a box edge sits right on the antimeridian it could be counted as
        # 180 or -180; we pick whichever one won't require splitting (see above).
        def edge(lng, from:, to:)
          lng == from ? to : lng
        end

        # Exterior rings run counterclockwise (RFC 7946, section 3.1.6).
        def ring(west, east, south, north)
          [[west, south], [east, south], [east, north], [west, north], [west, south]]
        end

        # GeoJSON positions are arrays of numbers (RFC 7946, section 3.1.1), so
        # coordinates are emitted as Floats rather than strings.
        # @param [BigDecimal] coordinate value from geocoord gem
        # @return [Float] value rounded to at most 6 digits after the decimal point
        # examples:
        # input value is BigDecimal("-23.9") or "0.239e2", output value is -23.9
        # input value is BigDecimal("23.9424216434") or "0.239424216434e2", output value is 23.942422
        def format(decimal)
          decimal.round(6).to_f
        end
      end
    end
  end
end
