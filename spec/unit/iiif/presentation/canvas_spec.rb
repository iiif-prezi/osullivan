describe IIIF::Presentation::Canvas do

  let(:fixed_values) do
    {
      "@context" => "http://iiif.io/api/presentation/3/context.json",
      "id" => "http://www.example.org/iiif/book1/canvas/p1",
      "type" => "Canvas",
      "label" => "p. 1",
      "height" => 1000,
      "width" => 750,
      "images" =>  [ ],
      "otherContent" =>  [ ]
    }
  end


  describe '#initialize' do
    it 'sets type' do
      expect(subject['type']).to eq 'Canvas'
    end
  end

  describe "#{described_class}.int_only_keys" do
    it_behaves_like 'it has the appropriate methods for integer-only keys'
  end

  describe "#{described_class}.define_methods_for_string_only_keys" do
    it_behaves_like 'it has the appropriate methods for string-only keys'
  end
  
  describe "#{described_class}.define_methods_for_array_only_keys" do
    it_behaves_like 'it has the appropriate methods for array-only keys'
  end

  describe "#{described_class}.define_methods_for_any_type_keys" do
    it_behaves_like 'it has the appropriate methods for any-type keys'
  end

  describe "#legal_viewing_hint_values" do
    it "should not error" do
      expect{subject.legal_viewing_hint_values}.not_to raise_error
    end
  end

end

