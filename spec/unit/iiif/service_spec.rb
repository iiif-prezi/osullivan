describe IIIF::Service do

  describe 'self#get_descendant_class_by_jld_type' do
    it 'gets the right class' do
      klass = described_class.get_descendant_class_by_jld_type('sc:Canvas')
      expect(klass).to be IIIF::Presentation::Canvas
    end
  end

end
