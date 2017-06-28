describe IIIF::V3::Presentation::AnnotationCollection do

  let(:fixed_values) do
    {
      "@context": [
        "http://iiif.io/api/presentation/3/context.json",
        "http://www.w3.org/ns/anno.jsonld"
      ],
      'id' => 'http://www.example.org/iiif/book1/annoColl/transcription',
      'type' => 'AnnotationCollection',
      'label' => 'Diplomatic Transcription',
      'first' => 'http://www.example.org/iiif/book1/list/l1',
      'last' => 'http://www.example.org/iiif/book1/list/l4',
    }
  end


  describe '#initialize' do
    it 'sets type' do
      expect(subject['type']).to eq 'AnnotationCollection'
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
