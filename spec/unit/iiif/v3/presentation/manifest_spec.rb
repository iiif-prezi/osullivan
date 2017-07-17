describe IIIF::V3::Presentation::Manifest do

  describe '#required_keys' do
    %w{ type id label items }.each do |k|
      it k do
        expect(subject.required_keys).to include(k)
      end
    end
  end

  describe '#prohibited_keys' do
    it 'contains the expected key names' do
      keys = IIIF::V3::Presentation::Service::CONTENT_RESOURCE_PROPERTIES +
        IIIF::V3::Presentation::Service::PAGING_PROPERTIES +
        %w{
          start_canvas
          content_annotation
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
    %w{ items structures}.each do |k|
      it k do
        expect(subject.array_only_keys).to include(k)
      end
    end
  end

  describe '#legal_viewing_hint_values' do
    it 'contains the expected values' do
      expect(subject.legal_viewing_hint_values).to contain_exactly('individuals', 'paged', 'continuous', 'auto-advance')
    end
  end

  describe '#initialize' do
    it 'sets type to Manifest by default' do
      expect(subject['type']).to eq 'Manifest'
    end
    it 'allows subclasses to override type' do
      subclass = Class.new(IIIF::V3::Presentation::Manifest) do
        def initialize(hsh={})
          hsh = { 'type' => 'a:SubClass' }
          super(hsh)
        end
      end
      sub = subclass.new
      expect(sub['type']).to eq 'a:SubClass'
    end
  end

  let(:manifest_id) { 'http://www.example.org/iiif/book1/manifest' }

  describe '#validate' do
    it 'raises an IllegalValueError if id is not http' do
      subject.label = 'Book 1'
      subject['id'] = 'ftp://www.example.org'
      subject['items'] = [IIIF::V3::Presentation::Sequence.new]
      exp_err_msg = "id must be an http(s) URI for IIIF::V3::Presentation::Manifest"
      expect { subject.validate }.to raise_error(IIIF::V3::Presentation::IllegalValueError, exp_err_msg)
    end
    it 'raises MissingRequiredKeyError for items entry without values' do
      subject['id'] = manifest_id
      subject.label = 'Book 1'
      subject['items'] = []
      exp_err_msg = "The items list must have at least one entry (and it must be a IIIF::V3::Presentation::Sequence)"
      expect { subject.validate }.to raise_error(IIIF::V3::Presentation::MissingRequiredKeyError, exp_err_msg)
    end
    it 'raises IllegalValueError for items entry that is not a Sequence' do
      subject['id'] = manifest_id
      subject.label = 'Book 1'
      subject['items'] = [IIIF::V3::Presentation::Sequence.new, IIIF::V3::Presentation::Canvas.new]
      exp_err_msg = "All entries in the items list must be a IIIF::V3::Presentation::Sequence"
      expect { subject.validate }.to raise_error(IIIF::V3::Presentation::IllegalValueError, exp_err_msg)
    end
    it 'raises IllegalValueError for default Sequence that is not written out' do
      subject['id'] = manifest_id
      subject.label = 'Book 1'
      seq = IIIF::V3::Presentation::Sequence.new
      seq['items'] = []
      subject['items'] = [seq]
      exp_err_msg = 'The default Sequence (the first entry of "items") must be written out in full within the Manifest file'
      expect { subject.validate }.to raise_error(IIIF::V3::Presentation::IllegalValueError, exp_err_msg)
    end
    it 'raises IllegalValueError for Sequences without "label" if there are multiple Sequences' do
      subject['id'] = manifest_id
      subject.label = 'Book 1'
      seq1 = IIIF::V3::Presentation::Sequence.new
      seq1['items'] = [IIIF::V3::Presentation::Canvas.new]
      seq2 = IIIF::V3::Presentation::Sequence.new
      seq2['label'] = 'label2'
      subject['items'] = [seq1, seq2]
      exp_err_msg = 'If there are multiple Sequences in a manifest then they must each have at least one label'
      expect { subject.validate }.to raise_error(IIIF::V3::Presentation::IllegalValueError, exp_err_msg)
    end
    it 'raises IllegalValueError for structures entry that is not a Range' do
      subject['id'] = manifest_id
      subject.label = 'Book 1'
      seq = IIIF::V3::Presentation::Sequence.new
      seq['items'] = [IIIF::V3::Presentation::Canvas.new]
      subject['items'] = [seq]
      subject['structures'] = [IIIF::V3::Presentation::Sequence.new]
      exp_err_msg = "All entries in the structures list must be a IIIF::V3::Presentation::Range"
      expect { subject.validate }.to raise_error(IIIF::V3::Presentation::IllegalValueError, exp_err_msg)
    end
  end

  describe 'realistic examples' do
    let!(:canvas_object) { IIIF::V3::Presentation::Canvas.new({
      "type" => "Canvas",
      "id" => "https://example.org/abc666/iiif3/canvas/0001",
      "label" => "image",
      "height" => 7579,
      "width" => 10108,
      "content" => [
        {
          "type" => "AnnotationPage",
          "id" => "https://example.org/abc666/iiif3/annotation_page/0001",
          "items" => [
            {
              "type" => "Annotation",
              "motivation" => "painting",
              "id" => "https://example.org/abc666/iiif3/annotation/0001",
              "body" => {
                "type" => "Image",
                "id" => "https://example.org/image/iiif/abc666_05_0001/full/full/0/default.jpg",
                "format" => "image/jpeg",
                "height" => 7579,
                "width" => 10108,
                "service" => {
                  "@context" => "http://iiif.io/api/image/2/context.json",
                  "@id" => "https://example.org/image/iiif/abc666_05_0001",
                  "id" => "https://example.org/image/iiif/abc666_05_0001",
                  "profile" => "http://iiif.io/api/image/2/level1.json"
                }
              },
              "target" => "https://example.org/abc666/iiif3/canvas/0001"
            }
          ]
        }
      ]
    })}
    let!(:default_sequence_object) {IIIF::V3::Presentation::Sequence.new({
      "id" => "https://example.org/abc666#sequence-1",
      "label" => "Current order",
      "type" => "Sequence",
      "items" => [canvas_object]
    })}
    describe 'realistic(?) minimal manifest' do
      let!(:manifest_object) { described_class.new({
        "@context" => [
          "http://www.w3.org/ns/anno.jsonld",
          "http://iiif.io/api/presentation/3/context.json"
        ],
        "id" => "https://example.org/abc666/iiif3/manifest",
        "type" => "Manifest",
        "label" => "blah",
        "attribution" => "bleah",
        "description" => "blargh",
        "items" => [default_sequence_object]
      })}
      it 'validates' do
        expect{manifest_object.validate}.not_to raise_error
      end
      it 'has expected required values' do
        expect(manifest_object.type).to eq 'Manifest'
        expect(manifest_object.id).to eq "https://example.org/abc666/iiif3/manifest"
        expect(manifest_object.label).to eq "blah"
        expect(manifest_object.items.size).to be 1
        expect(manifest_object.items.first).to eq default_sequence_object
      end
      it 'has expected context' do
        expect(manifest_object['@context'].size).to be 2
        expect(manifest_object['@context']).to include(*IIIF::V3::Presentation::CONTEXT)
      end
      it 'has expected string values' do
        expect(manifest_object.attribution).to eq "bleah"
        expect(manifest_object.description).to eq "blargh"
      end
    end

    describe 'realistic example from Stanford purl manifests' do
      let!(:manifest_object) { described_class.new({
        "@context" => [
          "http://www.w3.org/ns/anno.jsonld",
          "http://iiif.io/api/presentation/3/context.json"
        ],
        "id" => "https://example.org/abc666/iiif3/manifest",
        "type" => "Manifest",
        "label" => "blah",
        "attribution" => "bleah",
        "description" => "blargh",
        "items" => [default_sequence_object],
        "logo" => {
          "id" => "https://example.org/logo/full/400,/0/default.jpg",
          "service" => {
            "@context" => "http://iiif.io/api/image/2/context.json",
            "@id" => "https://example.org/logo",
            "id" => "https://example.org/logo",
            "profile" => "http://iiif.io/api/image/2/level1.json"
          }
        },
        "seeAlso" => {
          "id" => "https://example.org/abc666.mods",
          "format" => "application/mods+xml"
        },
        "metadata" => [
          {
            "label" => "Type",
            "value" => "map"
          },
          {
            "label" => "Rights",
            "value" => "stuff"
          }
        ],
        "thumbnail" => [{
          "type" => "Image",
          "id" => "https://example.org/image/iiif/abc666_05_0001/full/!400,400/0/default.jpg",
          "format" => "image/jpeg",
          "service" => {
            "@context" => "http://iiif.io/api/image/2/context.json",
            "@id" => "https://example.org/image/iiif/abc666_05_0001",
            "id" => "https://example.org/image/iiif/abc666_05_0001",
            "profile" => "http://iiif.io/api/image/2/level1.json"
          }
        }]
      })}
      it 'validates' do
        expect{manifest_object.validate}.not_to raise_error
      end
      it 'has expected required values' do
        expect(manifest_object.type).to eq 'Manifest'
        expect(manifest_object.id).to eq "https://example.org/abc666/iiif3/manifest"
        expect(manifest_object.label).to eq "blah"
        expect(manifest_object.items.size).to be 1
        expect(manifest_object.items.first).to eq default_sequence_object
      end
      it 'has expected context' do
        expect(manifest_object['@context'].size).to be 2
        expect(manifest_object['@context']).to include(*IIIF::V3::Presentation::CONTEXT)
      end
      it 'has expected string values' do
        expect(manifest_object.attribution).to eq "bleah"
        expect(manifest_object.description).to eq "blargh"
      end
      it 'has expected additional content' do
        expect(manifest_object.logo.keys.size).to be 2
        expect(manifest_object.seeAlso.keys.size).to be 2
        expect(manifest_object.metadata.size).to be 2
        expect(manifest_object.thumbnail.size).to be 1
      end
    end
  end
end
