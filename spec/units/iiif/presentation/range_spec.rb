describe IIIF::Presentation::Range do

  describe '#initialize' do
    it 'sets @type to sc:Range by default' do
      expect(subject['@type']).to eq 'sc:Range'
    end
  end

  describe "#{described_class}.define_methods_for_array_only_keys" do
    it_behaves_like 'it has the appropriate methods for array-only keys'
  end

  describe "#{described_class}.define_methods_for_string_only_keys" do
    it_behaves_like 'it has the appropriate methods for string-only keys'
  end

  describe '#validate' do
  end

end

