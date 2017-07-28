describe IIIF::V3::Presentation::Manifest do

  describe '#required_keys' do
    # NOTE:  relaxing requirement for items as Universal Viewer currently only accepts sequences
    #  see https://github.com/sul-dlss/osullivan/issues/27, sul-dlss/purl/issues/167
    # %w{ type id label items }.each do |k|
    %w{ type id label }.each do |k|
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
    # NOTE:  also allowing sequences as Universal Viewer currently only accepts sequences
    #  see https://github.com/sul-dlss/osullivan/issues/27, sul-dlss/purl/issues/167
    %w{ items sequences structures}.each do |k|
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

  let(:manifest_id) { 'http://www.example.org/iiif/book1/manifest' }

  describe '#validate' do
    it 'raises an IllegalValueError if id is not http' do
      subject.label = 'Book 1'
      subject['id'] = 'ftp://www.example.org'
      subject['items'] = [IIIF::V3::Presentation::Sequence.new]
      exp_err_msg = "id must be an http(s) URI for #{described_class}"
      expect { subject.validate }.to raise_error(IIIF::V3::Presentation::IllegalValueError, exp_err_msg)
    end

    let(:seq_list_err) { 'The (items or sequences) list must have at least one entry (and it must be a IIIF::V3::Presentation::Sequence)' }
    let(:seq_entry_err) { 'All entries in the (items or sequences) list must be a IIIF::V3::Presentation::Sequence' }
    let(:def_seq_err) { 'The default Sequence (the first entry of (items or sequences)) must be written out in full within the Manifest file' }

    it 'raises MissingRequiredKeyError if no items or sequences key' do
      subject['id'] = manifest_id
      subject.label = 'Book 1'
      expect { subject.validate }.to raise_error(IIIF::V3::Presentation::MissingRequiredKeyError, seq_list_err)
    end
    describe 'items' do
      it 'raises MissingRequiredKeyError for items entry without values' do
        subject['id'] = manifest_id
        subject.label = 'Book 1'
        subject['items'] = []
        expect { subject.validate }.to raise_error(IIIF::V3::Presentation::MissingRequiredKeyError, seq_list_err)
      end
      it 'raises IllegalValueError for items entry that is not a Sequence' do
        subject['id'] = manifest_id
        subject.label = 'Book 1'
        subject['items'] = [IIIF::V3::Presentation::Sequence.new, IIIF::V3::Presentation::Canvas.new]
        expect { subject.validate }.to raise_error(IIIF::V3::Presentation::IllegalValueError, seq_entry_err)
      end
      describe 'raises IllegalValueError for default Sequence that is not written out' do
        it 'Sequence has "items"' do
          subject['id'] = manifest_id
          subject.label = 'Book 1'
          seq = IIIF::V3::Presentation::Sequence.new
          seq['items'] = []
          subject['items'] = [seq]
          expect { subject.validate }.to raise_error(IIIF::V3::Presentation::IllegalValueError, def_seq_err)
        end
        # NOTE:  also allowing canvases as Universal Viewer currently only accepts canvases
        #  see https://github.com/sul-dlss/osullivan/issues/27, sul-dlss/purl/issues/167
        it 'Sequence has "canvases"' do
          subject['id'] = manifest_id
          subject.label = 'Book 1'
          seq = IIIF::V3::Presentation::Sequence.new
          seq['canvases'] = []
          subject['items'] = [seq]
          expect { subject.validate }.to raise_error(IIIF::V3::Presentation::IllegalValueError, def_seq_err)
        end
      end
      it 'raises no error for Sequence with populated "items"' do
        seq = IIIF::V3::Presentation::Sequence.new
        seq['items'] = [IIIF::V3::Presentation::Canvas.new]
        subject['items'] = [seq]
        subject['id'] = manifest_id
        subject.label = 'Book 1'
        expect { subject.validate }.not_to raise_error
      end
      it 'raises no error for Sequence with populated "canvases"' do
        seq = IIIF::V3::Presentation::Sequence.new
        seq['canvases'] = [IIIF::V3::Presentation::Canvas.new]
        subject['items'] = [seq]
        subject['id'] = manifest_id
        subject.label = 'Book 1'
        expect { subject.validate }.not_to raise_error
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
    end
    describe 'sequences' do
      it 'raises MissingRequiredKeyError for sequences entry without values' do
        subject['id'] = manifest_id
        subject.label = 'Book 1'
        subject['sequences'] = []
        expect { subject.validate }.to raise_error(IIIF::V3::Presentation::MissingRequiredKeyError, seq_list_err)
      end
      it 'raises IllegalValueError for sequences entry that is not a Sequence' do
        subject['id'] = manifest_id
        subject.label = 'Book 1'
        subject['sequences'] = [IIIF::V3::Presentation::Sequence.new, IIIF::V3::Presentation::Canvas.new]
        expect { subject.validate }.to raise_error(IIIF::V3::Presentation::IllegalValueError, seq_entry_err)
      end
      describe 'raises IllegalValueError for default Sequence that is not written out' do
        it 'Sequence has "items"' do
          subject['id'] = manifest_id
          subject.label = 'Book 1'
          seq = IIIF::V3::Presentation::Sequence.new
          seq['items'] = []
          subject['sequences'] = [seq]
          expect { subject.validate }.to raise_error(IIIF::V3::Presentation::IllegalValueError, def_seq_err)
        end
        # NOTE:  also allowing canvases as Universal Viewer currently only accepts canvases
        #  see https://github.com/sul-dlss/osullivan/issues/27, sul-dlss/purl/issues/167
        it 'Sequence has "canvases"' do
          subject['id'] = manifest_id
          subject.label = 'Book 1'
          seq = IIIF::V3::Presentation::Sequence.new
          seq['canvases'] = []
          subject['sequences'] = [seq]
          expect { subject.validate }.to raise_error(IIIF::V3::Presentation::IllegalValueError, def_seq_err)
        end
      end
      it 'raises no error for Sequence with populated "items"' do
        seq = IIIF::V3::Presentation::Sequence.new
        seq['items'] = [IIIF::V3::Presentation::Canvas.new]
        subject['sequences'] = [seq]
        subject['id'] = manifest_id
        subject.label = 'Book 1'
        expect { subject.validate }.not_to raise_error
      end
      it 'raises no error for Sequence with populated "canvases"' do
        seq = IIIF::V3::Presentation::Sequence.new
        seq['canvases'] = [IIIF::V3::Presentation::Canvas.new]
        subject['sequences'] = [seq]
        subject['id'] = manifest_id
        subject.label = 'Book 1'
        expect { subject.validate }.not_to raise_error
      end
      it 'raises IllegalValueError for Sequences without "label" if there are multiple Sequences' do
        subject['id'] = manifest_id
        subject.label = 'Book 1'
        seq1 = IIIF::V3::Presentation::Sequence.new
        seq1['items'] = [IIIF::V3::Presentation::Canvas.new]
        seq2 = IIIF::V3::Presentation::Sequence.new
        seq2['label'] = 'label2'
        subject['sequences'] = [seq1, seq2]
        exp_err_msg = 'If there are multiple Sequences in a manifest then they must each have at least one label'
        expect { subject.validate }.to raise_error(IIIF::V3::Presentation::IllegalValueError, exp_err_msg)
      end
      it 'raises no error for single Sequences without "label"' do
        subject['id'] = manifest_id
        subject.label = 'Book 1'
        seq = IIIF::V3::Presentation::Sequence.new
        seq['items'] = [IIIF::V3::Presentation::Canvas.new]
        subject['sequences'] = [seq]
        expect { subject.validate }.not_to raise_error
      end
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
    it 'raises no error when structures entry is a Range' do
      subject['id'] = manifest_id
      subject.label = 'Book 1'
      seq = IIIF::V3::Presentation::Sequence.new
      seq['items'] = [IIIF::V3::Presentation::Canvas.new]
      subject['items'] = [seq]
      subject['structures'] = [IIIF::V3::Presentation::Range.new]
      expect { subject.validate }.not_to raise_error
    end
  end

  describe 'realistic examples' do
    let!(:canvas_object) { IIIF::V3::Presentation::Canvas.new({
      "id" => "https://example.org/abc666/iiif3/canvas/0001",
      "label" => "image",
      "height" => 7579,
      "width" => 10108,
      "content" => []
    })}
    let!(:default_sequence_object) {IIIF::V3::Presentation::Sequence.new({
      "id" => "https://example.org/abc666#sequence-1",
      "label" => "Current order",
      "items" => [canvas_object]
    })}
    describe 'realistic(?) minimal manifest' do
      let!(:manifest_object) { described_class.new({
        "@context" => [
          "http://www.w3.org/ns/anno.jsonld",
          "http://iiif.io/api/presentation/3/context.json"
        ],
        "id" => "https://example.org/abc666/iiif3/manifest",
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
      let!(:logo_service) { IIIF::V3::Presentation::Service.new({
        "@context" => "http://iiif.io/api/image/2/context.json",
        "@id" => "https://example.org/logo",
        "id" => "https://example.org/logo",
        "profile" => "http://iiif.io/api/image/2/level1.json"
        })}
      let!(:thumbnail_image_service) { IIIF::V3::Presentation::Service.new({
        "@context" => IIIF::V3::Presentation::Service::IIIF_IMAGE_V2_CONTEXT,
        "@id" => "https://example.org/image/iiif/abc666_05_0001",
        "id" => "https://example.org/image/iiif/abc666_05_0001",
        "profile" => IIIF::V3::Presentation::Service::IIIF_IMAGE_V2_LEVEL1_PROFILE
        })}
      let!(:thumbnail_image) { IIIF::V3::Presentation::ImageResource.new({
        "id" => "https://example.org/image/iiif/abc666_05_0001/full/!400,400/0/default.jpg",
        "format" => "image/jpeg",
        "service" => thumbnail_image_service
        })}
      let!(:manifest_object) { described_class.new({
        "id" => "https://example.org/abc666/iiif3/manifest",
        "label" => "blah",
        "attribution" => "bleah",
        "description" => "blargh",
        "sequences" => [default_sequence_object],
        "logo" => {
          "id" => "https://example.org/logo/full/400,/0/default.jpg",
          "service" => logo_service
        },
        "seeAlso" => {
          "id" => "https://example.org/abc666.mods",
          "format" => "application/mods+xml"
        },
        "viewingHint" => "paged",
        "viewingDirection" => "right-to-left",
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
        "thumbnail" => [thumbnail_image]
      })}
      it 'thumbnail image object validates' do
        expect{thumbnail_image.validate}.not_to raise_error
      end
      it 'manifest validates' do
        expect{manifest_object.validate}.not_to raise_error
      end
      it 'has expected required values' do
        expect(manifest_object.type).to eq 'Manifest'
        expect(manifest_object.id).to eq "https://example.org/abc666/iiif3/manifest"
        expect(manifest_object.label).to eq "blah"
        # NOTE:  using sequences as Universal Viewer currently only accepts sequences
        #  see https://github.com/sul-dlss/osullivan/issues/27, sul-dlss/purl/issues/167
        expect(manifest_object.sequences.size).to be 1
        expect(manifest_object.sequences.first).to eq default_sequence_object
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

      describe 'from stanford purl CODE' do
        let!(:seq_object) {
          s = IIIF::V3::Presentation::Sequence.new({
          'id' => 'https://example.org/abc666#sequence-1',
          'label' => 'Current order'
          })
          s.viewingDirection = 'left-to-right'
          s.canvases << canvas_object
          s
        }
        let!(:manifest_data) {
          {
            "id" => "https://example.org/abc666/iiif3/manifest",
            "label" => "blah",
            "attribution" => "bleah",
            "logo" => {
              "id" => "https://example.org/logo/full/400,/0/default.jpg",
              "service" => logo_service
            },
            "seeAlso" => {
              "id" => "https://example.org/abc666.mods",
              "format" => "application/mods+xml"
            }
          }
        }
        let!(:manifest_object) {
          m = described_class.new manifest_data
          m.viewingHint = 'paged'
          m.metadata = [
            { 'label' => 'title', 'value' => 'who wants to know?' },
            { 'label' => 'PublishDate', 'value' => 'sometime' }
          ]
          m.description = 'blargh'
          m.thumbnail = [thumbnail_image]
          m.sequences << seq_object
          m
        }
        it 'manifest validates' do
          expect{manifest_object.validate}.not_to raise_error
        end
        it 'has expected required values' do
          expect(manifest_object.type).to eq 'Manifest'
          expect(manifest_object.id).to eq "https://example.org/abc666/iiif3/manifest"
          expect(manifest_object.label).to eq "blah"
          # NOTE:  using sequences as Universal Viewer currently only accepts sequences
          #  see https://github.com/sul-dlss/osullivan/issues/27, sul-dlss/purl/issues/167
          expect(manifest_object.sequences.size).to be 1
          expect(manifest_object.sequences.first).to eq seq_object
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
    describe 'example from http://prezi3.iiif.io/api/presentation/3.0' do
      let!(:range_object) { IIIF::V3::Presentation::Range.new({
        "id" => "http://example.org/iiif/book1/range/top",
        "label" => "home, home on the",
        "viewingHint" => ["top"]
        })
      }
      let!(:manifest_object) { described_class.new({
        "@context" => [
          "http://www.w3.org/ns/anno.jsonld",
          "http://iiif.io/api/presentation/3/context.json"
        ],
        "id" => "http://example.org/iiif/book1/manifest",
        "label" => {"en" => ["Book 1"]},
        "metadata" => [
          {"label" => {"en" => ["Author"]},
           "value" => {"@none" => ["Anne Author"]}},
          {"label" => {"en" => ["Published"]},
           "value" => {
              "en" => ["Paris, circa 1400"],
              "fr" => ["Paris, environ 1400"]}
          },
          {"label" => {"en" => ["Notes"]},
           "value" => {"en" => ["Text of note 1", "Text of note 2"]}},
          {"label" => {"en" => ["Source"]},
           "value" => {"@none" => ["<span>From: <a href=\"http://example.org/db/1.html\">Some Collection</a></span>"]}}
        ],
        "description" => {"en" => ["A longer description of this example book. It should give some real information."]},
        "thumbnail" => [{
          "id" => "http://example.org/images/book1-page1/full/80,100/0/default.jpg",
          "type" => "Image",
          "service" => {
            "@context" => "http://iiif.io/api/image/2/context.json",
            "id" => "http://example.org/images/book1-page1",
            "profile" => ["http://iiif.io/api/image/2/level1.json"]
          }
        }],
        "viewingDirection" => "right-to-left",
        "viewingHint" => ["paged"],
        "navDate" => "1856-01-01T00:00:00Z",
        "rights" => [{
          "id" =>"http://example.org/license.html",
          "format" => "text/html"}],
        "attribution" => {"en" => ["Provided by Example Organization"]},
        "logo" => {
          "id" => "http://example.org/logos/institution1.jpg",
          "service" => {
              "@context" => "http://iiif.io/api/image/2/context.json",
              "id" => "http://example.org/service/inst1",
              "profile" => ["http://iiif.io/api/image/2/profiles/level2.json"]
          }
        },
        "related" => [{
          "id" => "http://example.org/videos/video-book1.mpg",
          "format" => "video/mpeg"
        }],
        "service" => [{
          "@context" => "http://example.org/ns/jsonld/context.json",
          "id" => "http://example.org/service/example",
          "profile" => ["http://example.org/docs/example-service.html"]
        }],
        "seeAlso" => [{
          "id" => "http://example.org/library/catalog/book1.xml",
          "format" => "text/xml",
          "profile" => ["http://example.org/profiles/bibliographic"]
        }],
        "rendering" => [{
          "id" => "http://example.org/iiif/book1.pdf",
          "label" => {"en" => ["Download as PDF"]},
          "format" => "application/pdf"
        }],
        "within" => [{
          "id" => "http://example.org/collections/books/",
          "type" => "Collection"
        }],
        "items" => [default_sequence_object],
        "structures" => [range_object]
      })}
      it 'validates' do
        expect{manifest_object.validate}.not_to raise_error
      end
    end
  end
end
