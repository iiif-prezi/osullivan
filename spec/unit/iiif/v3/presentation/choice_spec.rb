describe IIIF::V3::Presentation::Choice do

  describe "#{described_class}.define_methods_for_array_only_keys" do
    it_behaves_like 'it has the appropriate methods for array-only keys v3'
  end

  describe "#{described_class}.define_methods_for_string_only_keys" do
    it_behaves_like 'it has the appropriate methods for string-only keys v3'
  end

  describe '#validate' do
    it 'raises an error if choice_hint isn\'t an allowable value' do
      subject['choice_hint'] = 'foo'
      expect { subject.validate }.to raise_error IIIF::V3::Presentation::IllegalValueError
    end
  end
end
