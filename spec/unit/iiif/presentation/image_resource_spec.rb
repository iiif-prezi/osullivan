describe IIIF::Presentation::ImageResource do

  describe '#initialize' do
    it 'sets @type to dctypes:Image' do
      expect(subject['@type']).to eq 'dctypes:Image'
    end
  end

  describe "#{described_class}.int_only_keys" do
    it_behaves_like 'it has the appropriate methods for integer-only keys'
  end

end
