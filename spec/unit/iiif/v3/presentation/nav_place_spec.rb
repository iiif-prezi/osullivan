describe IIIF::V3::Presentation::NavPlace do
  let(:subject) { described_class.new(coordinate_texts: coordinate_texts, base_uri: base_uri) }
  let(:base_uri) { "https://purl.stanford.edu" }
  let(:invalid_coordinates) { ["bogus", "stuff", "is", "here"] }
  let(:valid_coordinates) do
    ["W 23°54'00\"--E 53°36'00\"/N 71°19'00\"--N 33°30'00\"",
    'E 103°48ʹ/S 3°46ʹ).',
    'X 103°48ʹ/Y 3°46ʹ).',
    'In decimal degrees: (E 138.0--W 074.0/N 073.0--N 041.2).', # currently invalid therefore doesn't show up in nav_place
    '23°54′00″W -- 53°36′00″E / 71°19′00″N -- 33°30′00″N'
    ]
  end
  let(:nav_place) do
    { id: 'https://purl.stanford.edu/feature-collection/1',
      type: 'FeatureCollection',
      features: [{ id: 'https://purl.stanford.edu/iiif/feature/1',
                  type: 'Feature',
                  properties: {},
                  geometry: { type: 'Polygon',
                              coordinates: [[['-23.9', '71.316666'],
                                              ['53.6', '71.316666'],
                                              ['53.6', '33.5'],
                                              ['-23.9', '33.5'],
                                              ['-23.9', '71.316666']]] } },
                { id: 'https://purl.stanford.edu/iiif/feature/2',
                  type: 'Feature',
                  properties: {},
                  geometry: { type: 'Point', coordinates: ['103.8', '-3.766666'] } },
                { id: 'https://purl.stanford.edu/iiif/feature/3',
                  type: 'Feature',
                  properties: {},
                  geometry: { coordinates: ['103.8', '3.766666'], type: "Point" } },
                { id: 'https://purl.stanford.edu/iiif/feature/4',
                  type: 'Feature',
                  properties: {},
                  geometry: { type: 'Polygon',
                              coordinates: [[['-23.9', '71.316666'],
                                              ['53.6', '71.316666'],
                                              ['53.6', '33.5'],
                                              ['-23.9', '33.5'],
                                              ['-23.9', '71.316666']]] } }
                ] }
  end

  describe '#build' do
    context 'when coordinates are valid' do
      let(:coordinate_texts) { valid_coordinates }

      it 'returns navPlace' do
        expect(subject.build).to eq nav_place
      end
    end

    context 'when coordinates are not present' do
      let(:coordinate_texts) { [] }

      it 'raises ArgumentError' do
        expect { subject.build }.to raise_error(ArgumentError)
      end
    end

    context 'when coordinates are invalid' do
      let(:coordinate_texts) { invalid_coordinates }

      it 'raises ArgumentError' do
        expect { subject.build }.to raise_error(ArgumentError)
      end
    end
  end

  describe '#valid' do
    context 'when coordinates are valid' do
      let(:coordinate_texts) { valid_coordinates }

      it 'returns true' do
        expect(subject.valid?).to be true
      end
    end

    context 'when coordinates are not present' do
      let(:coordinate_texts) { [] }

      it 'returns false' do
        expect(subject.valid?).to be false
      end
    end

    context 'when coordinates are invalid' do
      let(:coordinate_texts) { invalid_coordinates }

      it 'returns false' do
        expect(subject.valid?).to be false
      end
    end
  end
end
