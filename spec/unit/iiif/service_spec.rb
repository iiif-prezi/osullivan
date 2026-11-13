describe IIIF::Service do
  describe "self#get_descendant_class_by_jld_type" do
    let(:dummy_class) do
      Class.new(IIIF::Service) do
        const_set(:TYPE, "sc:Collection")
        def self.singleton_class?
          true
        end
      end
    end
    it "gets the right class" do
      klass = described_class.get_descendant_class_by_jld_type("sc:Canvas")
      expect(klass).to be IIIF::Presentation::Canvas
    end
    context "when there are singleton classes which are returned" do
      it "gets the right class" do
        allow(IIIF::Service).to receive(:descendants).and_return([dummy_class, IIIF::Presentation::Collection])
        klass = described_class.get_descendant_class_by_jld_type("sc:Collection")
        expect(klass).to be IIIF::Presentation::Collection
      end
    end
  end
end
