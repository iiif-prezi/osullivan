describe IIIF::V3::Presentation::Annotation do

  describe "#{described_class}.define_methods_for_abstract_resource_only_keys" do
    it_behaves_like 'it has the appropriate methods for abstract_resource_only_keys v3'
  end

  describe '#validate' do
    it 'raises an error if time_mode isn\'t an allowable value' do
      subject['time_mode'] = 'foo'
      expect { subject.validate }.to raise_error IIIF::V3::Presentation::IllegalValueError
    end
  end
end
