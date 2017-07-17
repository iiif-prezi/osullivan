describe IIIF::V3::Presentation::Sequence do

  describe '#required_keys' do
    %w{ type items }.each do |k|
      it k do
        expect(subject.required_keys).to include(k)
      end
    end
  end

  describe '#prohibited_keys' do
    it 'contains the expected key names' do
      keys = described_class::CONTENT_RESOURCE_PROPERTIES +
        described_class::PAGING_PROPERTIES +
        %w{
          nav_date
          content_annotations
        }
      expect(subject.prohibited_keys).to include(*keys)
    end
  end

  describe '#array_only_keys' do
    it 'items' do
      expect(subject.array_only_keys).to include('items')
    end
  end

  describe '#legal_viewing_hint_values' do
    it 'contains the expected values' do
      expect(subject.legal_viewing_hint_values).to contain_exactly('individuals', 'paged', 'continuous', 'auto-advance')
    end
  end

  describe '#initialize' do
    it 'sets type to Sequence by default' do
      expect(subject['type']).to eq 'Sequence'
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
  end

  describe '#validate' do
     it 'raises MissingRequiredKeyError for items as empty Array' do
      subject['items'] = []
      exp_err_msg = "The items list must have at least one entry (and it must be a IIIF::V3::Presentation::Canvas)"
      expect { subject.validate }.to raise_error(IIIF::V3::Presentation::MissingRequiredKeyError, exp_err_msg)
    end
    it 'raises IllegalValueError for items entry that is not a Canvas' do
      subject['items'] = [IIIF::V3::Presentation::Canvas.new, IIIF::V3::Presentation::AnnotationPage.new]
      exp_err_msg = "All entries in the items list must be a IIIF::V3::Presentation::Canvas"
      expect { subject.validate }.to raise_error(IIIF::V3::Presentation::IllegalValueError, exp_err_msg)
    end
  end

  describe 'realistic examples' do
    let!(:canvas_object) { IIIF::V3::Presentation::Canvas.new({
      "id" => "https://example.org/abc666/iiif3/canvas/0001",
      "label" => "p. 1",
      "height" => 7579,
      "width" => 10108,
      "content" => []
      })}
    describe 'minimal sequence' do
      let!(:sequence_object) { described_class.new({
        "items" => [canvas_object]
      })}
      it 'validates' do
        expect{sequence_object.validate}.not_to raise_error
      end
      it 'has expected required values' do
        expect(sequence_object.type).to eq 'Sequence'
        expect(sequence_object.items.size).to be 1
        expect(sequence_object.items.first).to eq canvas_object
      end
    end
    
    describe 'example from Stanford purl' do
      let!(:sequence_object) {IIIF::V3::Presentation::Sequence.new({
        "id" => "https://example.org/abc666#sequence-1",
        "label" => "Current order",
        "type" => "Sequence",
        "items" => [canvas_object]
      })}
      it 'validates' do
        expect{sequence_object.validate}.not_to raise_error
      end
      it 'has expected required values' do
        expect(sequence_object.type).to eq 'Sequence'
        expect(sequence_object.items.size).to be 1
        expect(sequence_object.items.first).to eq canvas_object
      end
      it 'has expected string values' do
        expect(sequence_object.id).to eq "https://example.org/abc666#sequence-1"
        expect(sequence_object.label).to eq "Current order"
      end
    end

    describe 'example from http://prezi3.iiif.io/api/presentation/3.0' do
      let!(:sequence_object) { described_class.new({
        "id" => "http://example.org/iiif/book1/sequence/normal",
        "label" => {"en" => "Current Page Order"},
        "viewingDirection" => "left-to-right",
        "viewingHint" => ["paged"],
        "startCanvas" => canvas_object.id,
        "items" => [canvas_object]
      })}
      it 'validates' do
        expect{sequence_object.validate}.not_to raise_error
      end
      it 'has expected required values' do
        expect(sequence_object.type).to eq 'Sequence'
        expect(sequence_object.items.size).to be 1
        expect(sequence_object.items.first).to eq canvas_object
      end
      it 'has expected string values' do
        expect(sequence_object.id).to eq "http://example.org/iiif/book1/sequence/normal"
        expect(sequence_object.viewingDirection).to eq "left-to-right"
        expect(sequence_object.startCanvas).to eq "https://example.org/abc666/iiif3/canvas/0001"
      end
      it 'has expected additional content' do
        expect(sequence_object.viewingHint).to eq ["paged"]
        expect(sequence_object.label).to eq ({"en" => "Current Page Order"})
      end
    end

    describe 'another example' do
      let!(:sequence_object) { described_class.new({
        "id" => "http://example.com/prefix/sequence/456",
        'label' => 'Book 1',
        'description' => 'A longer description of this example book. It should give some real information.',
        'thumbnail' => [{
          'id' => 'http://www.example.org/images/book1-page1/full/80,100/0/default.jpg',
          'type' => 'Image',
          'service'=> {
            '@context' => 'http://iiif.io/api/image/2/context.json',
            'id' => 'http://www.example.org/images/book1-page1',
            'profile' => 'http://iiif.io/api/image/2/level1.json'
          }
        }],
        'attribution' => 'Provided by Example Organization',
        'rights' => [{'id' => 'http://www.example.org/license.html'}],
        'logo' => 'http://www.example.org/logos/institution1.jpg',
        'see_also' => 'http://www.example.org/library/catalog/book1.xml',
        'service' => {
          '@context' => 'http://example.org/ns/jsonld/context.json',
          'id' =>  'http://example.org/service/example',
          'profile' => 'http://example.org/docs/example-service.html'
        },
        'related' => {
          'id' => 'http://www.example.org/videos/video-book1.mpg',
          'format' => 'video/mpeg'
        },
        'within' => 'http://www.example.org/collections/books/',
        # Sequence
        'metadata' => [{'label'=>'Author', 'value'=>'Anne Author'}],
        "items" => [canvas_object],
        'start_canvas' => 'http://www.example.org/iiif/book1/canvas/p2',
        "viewingDirection" => "left-to-right",
        "viewingHint" => ["paged"],
        "startCanvas" => canvas_object.id,
      })}
      it 'validates' do
        expect{sequence_object.validate}.not_to raise_error
      end
    end
  end
end
