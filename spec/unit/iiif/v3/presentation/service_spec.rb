describe IIIF::V3::Presentation::Service do

  describe 'self#get_descendant_class_by_jld_type' do
    before do
      class DummyClass < IIIF::V3::Presentation::Service
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
      expect(klass).to eq IIIF::V3::Presentation::Canvas
    end
    context "when there are singleton classes which are returned" do
      it "gets the right class" do
        allow(IIIF::V3::Presentation::Service).to receive(:descendants).and_return([DummyClass, IIIF::V3::Presentation::Collection])
        klass = described_class.get_descendant_class_by_jld_type('Collection')
        expect(klass).to eq IIIF::V3::Presentation::Collection
      end
    end
  end

end
