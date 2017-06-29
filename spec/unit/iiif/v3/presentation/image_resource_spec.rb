describe IIIF::V3::Presentation::ImageResource do

  describe '#initialize' do
    it 'sets type to Image' do
      expect(subject['type']).to eq 'Image'
    end
  end

  describe "#{described_class}.int_only_keys" do
    it_behaves_like 'it has the appropriate methods for integer-only keys v3'
  end

end
