describe IIIF::V3::Presentation::AnnotationPage do

  describe '#required_keys' do
    it 'id' do
      expect(subject.required_keys).to include('id')
    end
  end

  describe '#prohibited_keys' do
    it 'contains the expected key names' do
      keys = described_class::CONTENT_RESOURCE_PROPERTIES +
       %w{
         first
         last
         total
         nav_date
         viewing_direction
         start_canvas
         content_annotations
       }
     expect(subject.prohibited_keys).to include(*keys)
   end
  end

  describe '#uri_only_keys' do
    it 'id' do
      expect(subject.uri_only_keys).to include('id')
    end
  end

  describe '#array_only_keys' do
    it 'items' do
      expect(subject.array_only_keys).to include('items')
    end
  end

  describe '#legal_viewing_hint_values' do
    it 'contains none' do
      expect(subject.legal_viewing_hint_values).to contain_exactly('none')
    end
  end

  describe '#initialize' do
    it 'sets type to AnnotationPage by default' do
      expect(subject['type']).to eq 'AnnotationPage'
    end
    it 'allows subclasses to override type' do
      subclass = Class.new(described_class) do
        def initialize(hsh={})
          hsh = { 'type' => 'a:SubClass' }
          super(hsh)
        end
      end
      sub = subclass.new
      expect(sub['type']).to eq 'a:SubClass'
    end
    it 'allows type to be passed in' do
      ap = described_class.new('type' => 'bar')
      expect(ap.type).to eq 'bar'
    end
  end

  describe '#validate' do
    it 'raises IllegalValueError if id is not URI' do
      exp_err_msg = "id value must be a String containing an http(s) URI for #{described_class}"
      subject['id'] = 'foo'
      expect { subject.validate }.to raise_error(IIIF::V3::Presentation::IllegalValueError, exp_err_msg)
    end
    it 'raises IllegalValueError if id is not http(s)' do
      subject['id'] = 'ftp://www.example.org'
      exp_err_msg = "id value must be a String containing an http(s) URI for #{described_class}"
      expect { subject.validate }.to raise_error(IIIF::V3::Presentation::IllegalValueError, exp_err_msg)
    end
    it 'raises IllegalValueError for items entry that is not an Annotation' do
      subject['id'] = 'http://example.com/iiif3/annotation_page/666'
      subject['items'] = [IIIF::V3::Presentation::ImageResource.new, IIIF::V3::Presentation::Annotation.new]
      exp_err_msg = "All entries in the items list must be a IIIF::V3::Presentation::Annotation"
      expect { subject.validate }.to raise_error(IIIF::V3::Presentation::IllegalValueError, exp_err_msg)
    end
  end

  describe 'realistic examples' do
    let(:ap_id) { 'http://example.com/iiif3/annotation_page/666' }
    let(:anno) { IIIF::V3::Presentation::Annotation.new(
      'id' => 'http://example.com/anno/666',
      'target' => 'http://example.com/canvas/abc'
      )}

    describe 'stanford (purl code)' do
      let(:anno_page) {
        anno_page = described_class.new
        anno_page['id'] = ap_id
        anno_page.items << anno
        anno_page
      }
      it 'validates' do
        expect{anno_page.validate}.not_to raise_error
      end
      it 'has expected required values' do
        expect(anno_page.id).to eq ap_id
        expect(anno_page['type']).to eq 'AnnotationPage'
      end
      it 'has expected additional values' do
        expect(anno_page.items).to eq [anno]
      end
    end

    describe 'two items' do
      let(:anno2) { IIIF::V3::Presentation::Annotation.new(
        'id' => 'http://example.com/anno/333',
        'target' => 'http://example.com/canvas/abc'
        )}
      let(:anno_page) {
        anno_page = described_class.new
        anno_page['id'] = ap_id
        anno_page.items = [anno, anno2]
        anno_page
      }
      it 'validates' do
        expect{anno_page.validate}.not_to raise_error
      end
      it 'has expected required values' do
        expect(anno_page.id).to eq ap_id
        expect(anno_page['type']).to eq 'AnnotationPage'
      end
      it 'has expected additional values' do
        expect(anno_page.items).to eq [anno, anno2]
      end
    end
  end
end
