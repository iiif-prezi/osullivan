require 'geo/coord'

module IIIF
  module V3
    module Presentation
      class NavPlace < IIIF::V3::AbstractResource
        Rect = Struct.new(:coord1, :coord2)

        COORD_REGEX = /(?:(?<hemisphere>[NSEW])\s*)?(?<degrees>\d+)[°⁰*](?:\s*(?<minutes>\d+)['ʹ′])?(?:\s*(?<seconds>\d+)["ʺ″])?(?:\s*(?<hemisphere>[NSEW]))?/
        def initialize(coordinate_texts:, base_uri:)
          @coordinate_texts = coordinate_texts
          @base_uri = base_uri
        end

        # @return [Boolean] indicates if coordinate_texts passed in are valid
        def valid?
          !(coordinates.nil? || coordinates.empty?)
        end

        def build
          raise ArgumentError.new('invalid coordinates') unless valid?

          {
            id: "#{base_uri}/feature-collection/1",
            type: 'FeatureCollection',
            features: features
          }
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
        end

        def rect_for(coordinate_parts)
          coord1 = coord_for(coordinate_parts[0], coordinate_parts[2])
          coord2 = coord_for(coordinate_parts[1], coordinate_parts[3])
          return if coord1.nil? || coord2.nil?

          Rect.new(coord1, coord2)
        end

        def features
          coordinates.map.with_index(1) do |coordinate, index|
            {
              id: "#{base_uri}/iiif/feature/#{index}",
              type: 'Feature',
              properties: {},
              geometry: coordinate.is_a?(Rect) ? polygon_geometry(coordinate) : point_geometry(coordinate)
            }
          end
        end

        def point_geometry(coord)
          {
            type: 'Point',
            coordinates: [format(coord.lng), format(coord.lat)]
          }
        end

        def polygon_geometry(rect)
          {
            type: 'Polygon',
            coordinates: [
              [
                [format(rect.coord1.lng), format(rect.coord1.lat)],
                [format(rect.coord2.lng), format(rect.coord1.lat)],
                [format(rect.coord2.lng), format(rect.coord2.lat)],
                [format(rect.coord1.lng), format(rect.coord2.lat)],
                [format(rect.coord1.lng), format(rect.coord1.lat)]
              ]
            ]
          }
        end

        # @param [BigDecimal] coordinate value from geocoord gem
        # @return [String] string formatted with max 6 digits after the decimal point
        # The to_f ensures removal of scientific notation of BigDecimal before converting to a string.
        # examples:
        # input value is BigDecimal("-23.9") or "0.239e2", output value is "-23.9" as string
        # input value is BigDecimal("23.9424213434") or "0.239424213434e2", output value is "23.942421" as string
        def format(decimal)
          decimal.truncate(6).to_f.to_s
        end
      end
    end
  end
end
