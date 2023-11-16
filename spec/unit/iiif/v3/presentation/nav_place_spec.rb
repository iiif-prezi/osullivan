describe IIIF::V3::Presentation::NavPlace do
  let(:subject) { described_class.new(coordinate_texts:, base_uri:) }
  let(:base_uri) { 'https://purl.stanford.edu' }

  describe '#build' do
    context 'when coordinates are present' do
      let(:coordinate_texts) do
        ["W 23°54'00\"--E 53°36'00\"/N 71°19'00\"--N 33°30'00\"",
        'E 103°48ʹ/S 3°46ʹ).',
        'X 103°48ʹ/Y 3°46ʹ).',
        'In decimal degrees: (E 138.0--W 074.0/N 073.0--N 041.2).']
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
                      geometry: { type: 'Point', coordinates: ['103.8', '-3.766666'] } }] }
      end

      it 'returns navPlace' do
        expect(subject.build).to eq nav_place
      end
    end

    context 'when coordinates are not present' do
      let(:coordinate_texts) { [] }

      it 'returns nil' do
        expect(subject.build).to be nil
      end
    end
  end
end
