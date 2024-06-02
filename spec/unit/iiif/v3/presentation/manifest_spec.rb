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
      subject.label = {'en' => ['Book 1']}
      subject['id'] = 'ftp://www.example.org'
      subject['items'] = [IIIF::V3::Presentation::Sequence.new]
      exp_err_msg = "id value must be a String containing an http(s) URI for #{described_class}"
      expect { subject.validate }.to raise_error(IIIF::V3::Presentation::IllegalValueError, exp_err_msg)
    end

    let(:item_list_err) { 'The items list must have at least one entry (and it must be a IIIF::V3::Presentation::Canvas)' }
    let(:item_entry_err) { 'All entries in the items list must be a IIIF::V3::Presentation::Canvas' }

    it 'raises MissingRequiredKeyError if no items or sequences key' do
      subject['id'] = manifest_id
      subject.label = {'en' => ['Book 1']}
      expect { subject.validate }.to raise_error(IIIF::V3::Presentation::MissingRequiredKeyError, item_list_err)
    end
    describe 'items' do
      it 'raises MissingRequiredKeyError for items entry without values' do
        subject['id'] = manifest_id
        subject.label = {'en' => ['Book 1']}
        subject['items'] = []
        expect { subject.validate }.to raise_error(IIIF::V3::Presentation::MissingRequiredKeyError, item_list_err)
      end
      it 'raises IllegalValueError for items entry that is not a Sequence' do
        subject['id'] = manifest_id
        subject.label = {'en' => ['Book 1']}
        subject['items'] = [IIIF::V3::Presentation::Sequence.new, IIIF::V3::Presentation::Canvas.new]
        expect { subject.validate }.to raise_error(IIIF::V3::Presentation::IllegalValueError, item_entry_err)
      end
      it 'raises no error items populated with canvases' do
        subject['items'] = [IIIF::V3::Presentation::Canvas.new]
        subject['id'] = manifest_id
        subject.label = {'en' => ['Book 1']}
        expect { subject.validate }.not_to raise_error
      end
    end

    it 'raises IllegalValueError for structures entry that is not a Range' do
      subject['id'] = manifest_id
      subject.label = {'en' => ['Book 1']}
      subject['items'] = [IIIF::V3::Presentation::Canvas.new]
      subject['structures'] = [IIIF::V3::Presentation::Sequence.new]
      exp_err_msg = "All entries in the structures list must be a IIIF::V3::Presentation::Range"
      expect { subject.validate }.to raise_error(IIIF::V3::Presentation::IllegalValueError, exp_err_msg)
    end
    it 'raises no error when structures entry is a Range' do
      subject['id'] = manifest_id
      subject.label = {'en' => ['Book 1']}
      subject['items'] = [IIIF::V3::Presentation::Canvas.new]
      subject['structures'] = [IIIF::V3::Presentation::Range.new]
      expect { subject.validate }.not_to raise_error
    end
  end

  describe 'realistic examples' do
    let!(:canvas_object) { IIIF::V3::Presentation::Canvas.new({
      "id" => "https://example.org/abc666/iiif3/canvas/0001",
      "label" => {'en' => ['image']},
      "height" => 7579,
      "width" => 10108,
      "content" => []
    })}
    describe 'realistic(?) minimal manifest' do
      let!(:manifest_object) { described_class.new({
        "@context" => [
          "http://www.w3.org/ns/anno.jsonld",
          "http://iiif.io/api/presentation/3/context.json"
        ],
        "id" => "https://example.org/abc666/iiif3/manifest",
        "label" => {"en" => ["blah"]},
        "requiredStatement" => {
          "label": { "en": [ "Attribution" ] },
          "value": { "en": [ "bleah" ] },
        },
        'summary' => { 'en' => ['blargh'] },
        "items" => [canvas_object]
      })}
      it 'validates' do
        expect{manifest_object.validate}.not_to raise_error
      end
      it 'has expected required values' do
        expect(manifest_object.type).to eq 'Manifest'
        expect(manifest_object.id).to eq "https://example.org/abc666/iiif3/manifest"
        expect(manifest_object.label['en']).to include "blah"
        expect(manifest_object.items.size).to be 1
        expect(manifest_object.items.first).to eq canvas_object
      end
      it 'has expected context' do
        expect(manifest_object['@context'].size).to be 2
        expect(manifest_object['@context']).to include(*IIIF::V3::Presentation::CONTEXT)
      end
      it 'has other values' do
        expect(manifest_object['required_statement'][:value][:en].first).to eq 'bleah'
        expect(manifest_object.summary['en'].first).to eq 'blargh'
      end
    end

    describe 'realistic example from Stanford purl manifests' do
      let!(:logo_service) { IIIF::V3::Presentation::Service.new({
        "@id" => "https://example.org/logo",
        "@type" => "ImageService2",
        "id" => "https://example.org/logo",
        "profile" => "http://iiif.io/api/image/2/level1.json"
        })}
      let!(:thumbnail_image_service) { IIIF::V3::Presentation::Service.new({
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
        "label" => {"en" => ["blah"]},
        "requiredStatement" => {
          "label": { "en": [ "Attribution" ] },
          "value": { "en": [ "bleah" ] },
        },
        'summary' => { 'en' => ['blargh'] },
        "items" => [canvas_object],
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
        expect(manifest_object.label['en']).to include "blah"
        expect(manifest_object.items.size).to be 1
        expect(manifest_object.items.first).to eq canvas_object
      end
      it 'has expected additional content' do
        expect(manifest_object['required_statement'][:value][:en].first).to eq 'bleah'
        expect(manifest_object.summary['en'].first).to eq 'blargh'
        expect(manifest_object.logo.keys.size).to be 2
        expect(manifest_object.seeAlso.keys.size).to be 2
        expect(manifest_object.metadata.size).to be 2
        expect(manifest_object.thumbnail.size).to be 1
      end

      describe 'from stanford purl CODE' do
        let!(:manifest_data) {
          {
            "id" => "https://example.org/abc666/iiif3/manifest",
            "label" => {"en" => ["blah"]},
            "requiredStatement" => {
              "label": { "en": [ "Attribution" ] },
              "value": { "en": [ "bleah" ] },
            },
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
          m.summary = { 'en' => ['blargh'] }
          m.thumbnail = [thumbnail_image]
          m.items << canvas_object
          m
        }
        it 'manifest validates' do
          expect{manifest_object.validate}.not_to raise_error
        end
        it 'has expected required values' do
          expect(manifest_object.type).to eq 'Manifest'
          expect(manifest_object.id).to eq "https://example.org/abc666/iiif3/manifest"
          expect(manifest_object.label['en']).to include "blah"
          expect(manifest_object.items.size).to be 1
          expect(manifest_object.items.first).to eq canvas_object
        end
        it 'has expected additional content' do
          expect(manifest_object['required_statement'][:value][:en].first).to eq 'bleah'
          expect(manifest_object.summary['en'].first).to eq 'blargh'
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
        "label" => {"en" => ["home, home on the"]},
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
        "summary" => {"en" => ["A longer description of this example book. It should give some real information."]},
        "thumbnail" => [{
          "id" => "http://example.org/images/book1-page1/full/80,100/0/default.jpg",
          "type" => "Image",
          "service" => {
            "id" => "http://example.org/images/book1-page1",
            "type" => "ImageService2",
            "profile" => ["http://iiif.io/api/image/2/level1.json"]
          }
        }],
        "viewingDirection" => "right-to-left",
        "viewingHint" => ["paged"],
        "navDate" => "1856-01-01T00:00:00Z",
        "rights" => "http://example.org/license.html",
        "requiredStatement" => {
          "label": { "en": [ "Attribution" ] },
          "value": { "en": [ "bleah" ] },
        },
        "logo" => {
          "id" => "http://example.org/logos/institution1.jpg",
          "service" => {
              "id" => "http://example.org/service/inst1",
              "type" => "ImageService2",
              "profile" => ["http://iiif.io/api/image/2/profiles/level2.json"]
          }
        },
        "related" => [{
          "id" => "http://example.org/videos/video-book1.mpg",
          "format" => "video/mpeg"
        }],
        "service" => [{
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
        "items" => [canvas_object],
        "structures" => [range_object]
      })}
      it 'validates' do
        expect{manifest_object.validate}.not_to raise_error
      end
    end
  end
end
