describe IIIF::V3::Presentation::Collection do

  let(:fixed_values) do
    {
      "@context" => [
        "http://iiif.io/api/presentation/3/context.json",
        "http://www.w3.org/ns/anno.jsonld"
      ],
      'id' => 'http://example.org/iiif/collection/top',
      'type' => 'Collection',
      'label' => 'Top Level Collection for Example Organization',
      'description' => 'Description of Collection',
      'attribution' => 'Provided by Example Organization',

      'collections' => [
        { 'id' => 'http://example.org/iiif/collection/part1',
          'type' => 'Collection',
          'label' => 'Sub Collection 1'
         },
         { 'id' => 'http://example.org/iiif/collection/part2',
           'type' => 'Collection',
           'label' => 'Sub Collection 2'
          }
      ],
      'manifests' => [
        { 'id' => 'http://example.org/iiif/book1/manifest',
          'type' => 'Manifest',
          'label' => 'Book 1'
        }
      ]
    }
  end

  describe '#initialize' do
    it 'sets type to Collection by default' do
      expect(subject['type']).to eq 'Collection'
    end
  end

  describe "#{described_class}.define_methods_for_array_only_keys" do
    it_behaves_like 'it has the appropriate methods for array-only keys v3'
  end

  describe "#{described_class}.define_methods_for_string_only_keys" do
    it_behaves_like 'it has the appropriate methods for string-only keys v3'
  end

  describe "#{described_class}.define_methods_for_any_type_keys" do
    it_behaves_like 'it has the appropriate methods for any-type keys v3'
  end

  describe '#validate' do
  end

end
