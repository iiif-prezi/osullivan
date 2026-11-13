describe IIIF::V3::Presentation::NavPlace do
  let(:subject) { described_class.new(coordinate_texts: coordinate_texts, base_uri: base_uri) }
  let(:base_uri) { "https://purl.stanford.edu" }
  let(:invalid_coordinates) { ["bogus", "stuff", "is", "here"] }
  let(:out_of_range_coordinates) { ["W 008°00′00″--W 004°00′00″/N 059°00′00″--N 543°00′00″"] }
  let(:wrong_axis_hemisphere_coordinates) { ["(W 117°57'--W 117°39'/E 34°50'--E 32°48')."] }
  let(:valid_coordinates) do
    ["W 23°54'00\"--E 53°36'00\"/N 71°19'00\"--N 33°30'00\"",
      "E 103°48ʹ/S 3°46ʹ).",
      "X 103°48ʹ/Y 3°46ʹ).",
      "In decimal degrees: (E 138.0--W 074.0/N 073.0--N 041.2).",
      "23°54′00″W -- 53°36′00″E / 71°19′00″N -- 33°30′00″N"]
  end
  let(:nav_place) do
    {id: "https://purl.stanford.edu/feature-collection/1",
     type: "FeatureCollection",
     features: [{id: "https://purl.stanford.edu/iiif/feature/1",
                 type: "Feature",
                 properties: {},
                 geometry: {type: "Polygon",
                            coordinates: [[[-23.9, 33.5],
                              [53.6, 33.5],
                              [53.6, 71.316667],
                              [-23.9, 71.316667],
                              [-23.9, 33.5]]]}},
       {id: "https://purl.stanford.edu/iiif/feature/2",
        type: "Feature",
        properties: {},
        geometry: {type: "Point", coordinates: [103.8, -3.766667]}},
       {id: "https://purl.stanford.edu/iiif/feature/3",
        type: "Feature",
        properties: {},
        geometry: {coordinates: [103.8, 3.766667], type: "Point"}},
       {id: "https://purl.stanford.edu/iiif/feature/4",
        type: "Feature",
        properties: {},
        geometry: {type: "MultiPolygon",
                   coordinates: [[[[138.0, 41.2],
                     [180.0, 41.2],
                     [180.0, 73.0],
                     [138.0, 73.0],
                     [138.0, 41.2]]],
                     [[[-180.0, 41.2],
                       [-74.0, 41.2],
                       [-74.0, 73.0],
                       [-180.0, 73.0],
                       [-180.0, 41.2]]]]}},
       {id: "https://purl.stanford.edu/iiif/feature/5",
        type: "Feature",
        properties: {},
        geometry: {type: "Polygon",
                   coordinates: [[[-23.9, 33.5],
                     [53.6, 33.5],
                     [53.6, 71.316667],
                     [-23.9, 71.316667],
                     [-23.9, 33.5]]]}}]}
  end
  let(:nav_place_without_ids) do
    without_id = ->(resource) { resource.except(:id) }
    without_id.call(nav_place).merge(features: nav_place[:features].map(&without_id))
  end

  describe "#initialize" do
    let(:coordinate_texts) { valid_coordinates }

    ["", " ", "/path", "example.com", "ftp://my.server"].each do |value|
      context "when base_uri is #{value.inspect}" do
        let(:base_uri) { value }

        it "raises ArgumentError" do
          expect { subject }.to raise_error(ArgumentError, /base_uri must be an absolute HTTP\(S\) URI/)
        end
      end
    end
  end

  describe "#build" do
    context "when coordinates are valid" do
      let(:coordinate_texts) { valid_coordinates }

      # Compare as JSON: Ruby's == treats a BigDecimal as equal to a Float, but
      # a BigDecimal serializes as a string, which GeoJSON does not allow.
      it "returns navPlace" do
        expect(JSON.parse(subject.build.to_json)).to eq JSON.parse(nav_place.to_json)
      end

      context "without a base_uri" do
        let(:subject) { described_class.new(coordinate_texts: coordinate_texts) }

        it "leaves out the ids" do
          expect(JSON.parse(subject.build.to_json)).to eq JSON.parse(nav_place_without_ids.to_json)
        end
      end
    end

    context "when the north and south edges are given in the reverse order" do
      let(:coordinate_texts) { ["W 10°00ʹ--E 20°00ʹ/S 5°00ʹ--N 5°00ʹ"] }

      it "still runs the ring counterclockwise" do
        expect(JSON.parse(subject.build.to_json)["features"][0]["geometry"]).to eq(
          "type" => "Polygon",
          "coordinates" => [[[-10.0, -5.0], [20.0, -5.0], [20.0, 5.0], [-10.0, 5.0], [-10.0, -5.0]]]
        )
      end
    end

    context "when a box crosses the antimeridian" do
      let(:coordinate_texts) { ["E 170°00ʹ--W 170°00ʹ/N 10°00ʹ--S 10°00ʹ"] }

      it "splits it into a MultiPolygon, per the spec" do
        expect(JSON.parse(subject.build.to_json)["features"][0]["geometry"]).to eq(
          "type" => "MultiPolygon",
          "coordinates" => [
            [[[170.0, -10.0], [180.0, -10.0], [180.0, 10.0], [170.0, 10.0], [170.0, -10.0]]],
            [[[-180.0, -10.0], [-170.0, -10.0], [-170.0, 10.0], [-180.0, 10.0], [-180.0, -10.0]]]
          ]
        )
      end
    end

    context "when a box has an edge on the antimeridian" do
      let(:coordinate_texts) { ["E 170°00ʹ--W 180°00ʹ/N 10°00ʹ--S 10°00ʹ", "E 180°00ʹ--W 170°00ʹ/N 10°00ʹ--S 10°00ʹ"] }

      it "makes bounds that do not require splitting" do
        geometries = JSON.parse(subject.build.to_json)["features"].map { |feature| feature["geometry"] }
        expect(geometries).to eq [
          {"type" => "Polygon", "coordinates" => [[[170.0, -10.0], [180.0, -10.0], [180.0, 10.0], [170.0, 10.0], [170.0, -10.0]]]},
          {"type" => "Polygon", "coordinates" => [[[-180.0, -10.0], [-170.0, -10.0], [-170.0, 10.0], [-180.0, 10.0], [-180.0, -10.0]]]}
        ]
      end
    end

    context "with decimal degrees" do
      let(:coordinate_texts) { ["E 138.5°/N 35.25°"] }

      it "reads the whole number" do
        expect(JSON.parse(subject.build.to_json)["features"][0]["geometry"]).to eq(
          "type" => "Point", "coordinates" => [138.5, 35.25]
        )
      end
    end

    context "with decimal degrees and minutes and seconds" do
      let(:coordinate_texts) { ["W 122°15.5ʹ/N 37°26ʹ30.5″"] }

      it "keeps them" do
        expect(JSON.parse(subject.build.to_json)["features"][0]["geometry"]).to eq(
          "type" => "Point", "coordinates" => [-122.258333, 37.441806]
        )
      end
    end

    context "when coordinates are not present" do
      let(:coordinate_texts) { [] }

      it "raises ArgumentError" do
        expect { subject.build }.to raise_error(ArgumentError)
      end
    end

    context "when coordinates are invalid" do
      let(:coordinate_texts) { invalid_coordinates }

      it "raises ArgumentError" do
        expect { subject.build }.to raise_error(ArgumentError)
      end
    end

    context "when coordinates are out of range" do
      let(:coordinate_texts) { out_of_range_coordinates }

      it "raises ArgumentError" do
        expect { subject.build }.to raise_error(ArgumentError, "invalid coordinates")
      end
    end

    context "when a hemisphere does not belong to its axis" do
      let(:coordinate_texts) { wrong_axis_hemisphere_coordinates }

      it "raises ArgumentError" do
        expect { subject.build }.to raise_error(ArgumentError, "invalid coordinates")
      end
    end

    context "when only some coordinates are unusable" do
      let(:coordinate_texts) { out_of_range_coordinates + valid_coordinates }

      it "skips them and builds the rest" do
        expect(subject.build).to eq nav_place
      end
    end
  end

  describe "#valid" do
    context "when coordinates are valid" do
      let(:coordinate_texts) { valid_coordinates }

      it "returns true" do
        expect(subject.valid?).to be true
      end
    end

    context "when coordinates are not present" do
      let(:coordinate_texts) { [] }

      it "returns false" do
        expect(subject.valid?).to be false
      end
    end

    context "when coordinates are invalid" do
      let(:coordinate_texts) { invalid_coordinates }

      it "returns false" do
        expect(subject.valid?).to be false
      end
    end

    context "when coordinates are out of range" do
      let(:coordinate_texts) { out_of_range_coordinates }

      it "returns false instead of raising" do
        expect(subject.valid?).to be false
      end
    end

    context "when a hemisphere does not belong to its axis" do
      let(:coordinate_texts) { wrong_axis_hemisphere_coordinates }

      it "returns false instead of raising" do
        expect(subject.valid?).to be false
      end
    end
  end

  describe "WKT coordinate texts" do
    let(:geometries) { JSON.parse(subject.build.to_json)["features"].map { |feature| feature["geometry"] } }

    context "with a point, a box, and a box split at the antimeridian" do
      let(:coordinate_texts) do
        ["POINT(-118.243700 34.052200)",
          "POLYGON((-23.900000 33.500000, 53.600000 33.500000, 53.600000 71.316667, -23.900000 71.316667, -23.900000 33.500000))",
          "MULTIPOLYGON(((170.000000 -10.000000, 180.000000 -10.000000, 180.000000 10.000000, 170.000000 10.000000, 170.000000 -10.000000)), " \
          "((-180.000000 -10.000000, -170.000000 -10.000000, -170.000000 10.000000, -180.000000 10.000000, -180.000000 -10.000000)))"]
      end

      it "reads each as its GeoJSON geometry" do
        expect(geometries).to eq [
          {"type" => "Point", "coordinates" => [-118.2437, 34.0522]},
          JSON.parse(nav_place[:features][0][:geometry].to_json),
          {"type" => "MultiPolygon",
           "coordinates" => [
             [[[170.0, -10.0], [180.0, -10.0], [180.0, 10.0], [170.0, 10.0], [170.0, -10.0]]],
             [[[-180.0, -10.0], [-170.0, -10.0], [-170.0, 10.0], [-180.0, 10.0], [-180.0, -10.0]]]
           ]}
        ]
      end
    end

    context "when rings run the other way" do
      let(:coordinate_texts) { ["polygon ((0 0, 0 10, 10 10, 10 0, 0 0), (2 2, 4 2, 4 4, 2 4, 2 2))"] }

      it "turns the exterior counterclockwise and holes clockwise" do
        expect(geometries).to eq [
          {"type" => "Polygon",
           "coordinates" => [
             [[0.0, 0.0], [10.0, 0.0], [10.0, 10.0], [0.0, 10.0], [0.0, 0.0]],
             [[2.0, 2.0], [2.0, 4.0], [4.0, 4.0], [4.0, 2.0], [2.0, 2.0]]
           ]}
        ]
      end
    end

    context "alongside other coordinate texts" do
      let(:coordinate_texts) { ["E 103°48ʹ/S 3°46ʹ).", "POINT(1.5 2.5)"] }

      it "keeps their order" do
        expect(geometries).to eq [
          {"type" => "Point", "coordinates" => [103.8, -3.766667]},
          {"type" => "Point", "coordinates" => [1.5, 2.5]}
        ]
      end
    end

    context "when the WKT cannot be used" do
      let(:coordinate_texts) do
        ["POINT(200 0)", "POINT(1 2 3)", "POINT EMPTY", "POLYGON((0 0, 1 1))", "POLYGON((0 0, 1 0, 1 1, 0 1, 0 2))",
          "POLYGON((0 0, 1 0, 1 1, 0 0", "MULTIPOLYGON()", "LINESTRING(0 0, 1 1)"]
      end

      it "skips it" do
        expect(subject.valid?).to be false
      end
    end
  end
end
