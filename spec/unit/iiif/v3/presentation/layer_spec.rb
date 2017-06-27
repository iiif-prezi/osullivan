describe IIIF::V3::Presentation::Layer do

  let(:fixed_values) do
    {
      'id' => 'http://www.example.org/iiif/book1/layer/transcription',
      'type' => 'Layer',
      'label' => 'Diplomatic Transcription',
      'otherContent' => [
        'http://www.example.org/iiif/book1/list/l1',
        'http://www.example.org/iiif/book1/list/l2',
        'http://www.example.org/iiif/book1/list/l3',
        'http://www.example.org/iiif/book1/list/l4'
      ]
    }
  end


  describe '#initialize' do
    it 'sets type' do
      expect(subject['type']).to eq 'Layer'
    end
  end

  describe "#{described_class}.define_methods_for_string_only_keys" do
    it_behaves_like 'it has the appropriate methods for string-only keys v3'
  end

  describe "#{described_class}.define_methods_for_array_only_keys" do
    it_behaves_like 'it has the appropriate methods for array-only keys v3'
  end

  describe "#{described_class}.define_methods_for_any_type_keys" do
    it_behaves_like 'it has the appropriate methods for any-type keys v3'
  end

end
