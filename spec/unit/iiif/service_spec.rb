RSpec.describe IIIF::Service do
  describe '.get_descendant_class_by_jld_type' do
    before do
      class DummyClass < IIIF::Service
        TYPE = "Collection"
        def self.singleton_class?
          true
        end
      end
    end
    after do
      Object.send(:remove_const, :DummyClass)
    end
    it 'gets the right class' do
      klass = described_class.get_descendant_class_by_jld_type('Canvas')
      expect(klass).to be IIIF::Presentation::Canvas
    end

    context "when there are singleton classes which are returned" do
      it "gets the right class" do
        allow(IIIF::Service).to receive(:descendants).and_return([DummyClass, IIIF::Presentation::Collection])
        klass = described_class.get_descendant_class_by_jld_type('Collection')
        expect(klass).to be IIIF::Presentation::Collection
      end
    end
  end
end
