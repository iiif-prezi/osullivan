describe IIIF::V3::Presentation::Canvas do

  describe '#required_keys' do
     %w{ type id label }.each do |k|
       it k do
         expect(subject.required_keys).to include(k)
       end
     end
   end

  describe '#prohibited_keys' do
    it 'contains the expected key names' do
     keys = described_class::PAGING_PROPERTIES +
       %w{
         viewing_direction
         format
         nav_date
         start_canvas
         content_annotations
       }
     expect(subject.prohibited_keys).to include(*keys)
   end
  end

  describe '#array_only_keys' do
    it 'content' do
      expect(subject.array_only_keys).to include('content')
    end
  end

  describe '#legal_viewing_hint_values' do
    it 'contains the expected values' do
      expect(subject.legal_viewing_hint_values).to contain_exactly('paged', 'continuous', 'non-paged', 'facing-pages', 'auto-advance')
    end
  end

  describe '#initialize' do
    it 'sets type to Canvas by default' do
      expect(subject['type']).to eq 'Canvas'
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
    let(:exp_id_err_msg) { "id must be an http(s) URI without a fragment for #{described_class}" }
    before(:each) do
      subject['id'] = 'http://www.example.org/my_canvas'
      subject['label'] = 'foo'
    end
    it 'raises an IllegalValueError if id is not URI' do
      subject['id'] = 'foo'
      expect { subject.validate }.to raise_error(IIIF::V3::Presentation::IllegalValueError, exp_id_err_msg)
    end
    it 'raises an IllegalValueError if id is not http(s)' do
      subject['id'] = 'ftp://www.example.org'
      expect { subject.validate }.to raise_error(IIIF::V3::Presentation::IllegalValueError, exp_id_err_msg)
    end
    it 'raises an IllegalValueError if id has a fragment' do
      subject['id'] = 'http://www.example.org#foo'
      expect { subject.validate }.to raise_error(IIIF::V3::Presentation::IllegalValueError, exp_id_err_msg)
    end

    let(:exp_extent_err_msg) { "#{described_class} must have (a height and a width) and/or a duration" }
    it 'raises an IllegalValueError if height is a string' do
      subject['height'] = 'foo'
      expect { subject.validate }.to raise_error(IIIF::V3::Presentation::IllegalValueError, exp_extent_err_msg)
    end
    it 'raises an IllegalValueError if height but no width' do
      subject['height'] = 666
      expect { subject.validate }.to raise_error(IIIF::V3::Presentation::IllegalValueError, exp_extent_err_msg)
    end
    it 'raises an IllegalValueError if width but no height' do
      subject['width'] = 666
      subject['duration'] = 66.6
      expect { subject.validate }.to raise_error(IIIF::V3::Presentation::IllegalValueError, exp_extent_err_msg)
    end
    it 'raises an IllegalValueError if no width, height or duration' do
      expect { subject.validate }.to raise_error(IIIF::V3::Presentation::IllegalValueError, exp_extent_err_msg)
    end
    it 'allows width, height and duration' do
      subject['width'] = 666
      subject['height'] = 666
      subject['duration'] = 66.6
      expect { subject.validate }.not_to raise_error
    end

    it 'raises IllegalValueError for content entry that is not an AnnotationPage' do
      subject['content'] = [IIIF::V3::Presentation::AnnotationPage.new, IIIF::V3::Presentation::Annotation.new]
      exp_err_msg = "All entries in the content list must be a IIIF::V3::Presentation::AnnotationPage"
      expect { subject.validate }.to raise_error(IIIF::V3::Presentation::IllegalValueError, exp_err_msg)
    end
  end

  describe 'realistic examples' do
    let(:minimal_canvas_object) { described_class.new({
      "id" => "http://example.org/iiif/book1/canvas/c1",
      'label' => "so minimal it's not here",
      "height" => 1000,
      "width" => 1000
    })}
    describe 'minimal canvas' do
      it 'validates' do
        expect{minimal_canvas_object.validate}.not_to raise_error
      end
      it 'has expected required values' do
        expect(minimal_canvas_object.type).to eq described_class::TYPE
        expect(minimal_canvas_object.id).to eq "http://example.org/iiif/book1/canvas/c1"
        expect(minimal_canvas_object.label).to eq "so minimal it's not here"
        expect(minimal_canvas_object.height).to eq 1000
        expect(minimal_canvas_object.width).to eq 1000
      end
    end
    describe 'minimal with empty content' do
      let(:canvas_object) {
        minimal_canvas_object['content'] = []
        minimal_canvas_object
      }
      it 'validates' do
        expect{canvas_object.validate}.not_to raise_error
      end
      it 'has additional values' do
        expect(canvas_object.content).to eq []
      end
    end
    let(:anno_page) { IIIF::V3::Presentation::AnnotationPage.new(
      "id" => "http://example.org/iiif/book1/page/p1/1",
      'items' => []
      ) }
    describe 'minimal with content' do
      let(:canvas_object) {
        minimal_canvas_object['content'] = [anno_page, anno_page]
        minimal_canvas_object
      }
      it 'validates' do
        expect{canvas_object.validate}.not_to raise_error
      end
      it 'has content value' do
        expect(canvas_object.content.size).to eq 2
        expect(canvas_object.content).to eq [anno_page, anno_page]
      end
    end

    ex5 = {
            "id" => "http://example.org/iiif/book1/canvas/p2",
            "type" => "Canvas",
            "label" => "p. 2",
            "height" =>1000,
            "width" =>750,
            "images" => [
              {
                "type" => "Annotation",
                "motivation" => "painting",
                "resource" =>{
                    "id" => "http://example.org/images/book1-page2/full/1500,2000/0/default.jpg",
                    "type" => "dctypes:Image",
                    "format" => "image/jpeg",
                    "height" =>2000,
                    "width" =>1500,
                    "service" => {
                        "@context" => "http://iiif.io/api/image/2/context.json",
                        "id" => "http://example.org/images/book1-page2",
                        "profile" => "http://iiif.io/api/image/2/level1.json",
                        "height" =>8000,
                        "width" =>6000,
                        "tiles" => [{"width" => 512, "scaleFactors" => [1,2,4,8,16]}]
                    }
                },
                "on" => "http://example.org/iiif/book1/canvas/p2"
              }
            ],
            "otherContent" => [
              {
                "id" => "http://example.org/iiif/book1/list/p2",
                "type" => "AnnotationList",
                "within" => "http://example.org/iiif/book1/layer/l1"
              }
            ]
          }

    describe 'video object' do
      let(:canvas_for_video) { described_class.new({
        "id" => "http://tomcrane.github.io/scratch/manifests/3/canvas/1",
        "label" => "Associate multiple Video representations as Choice",
        "height" => 1000,
        "width" => 1000,
        "duration" => 100,
        "content" => [anno_page]
        }) }
      it 'validates' do
        expect{canvas_for_video.validate}.not_to raise_error
      end
      it 'height, width, duration' do
        expect(canvas_for_video.height).to eq 1000
        expect(canvas_for_video.width).to eq 1000
        expect(canvas_for_video.duration).to eq 100
      end
    end

    describe 'audio object' do
      let(:canvas_for_audio) { described_class.new({
        "id" => "http://tomcrane.github.io/scratch/manifests/3/canvas/2",
        "label" => "Track 2",
        "description" => "foo",
        "duration" => 45,
        "content" => [anno_page]
        })}
      it 'validates' do
        expect{canvas_for_audio.validate}.not_to raise_error
      end
      it 'duration' do
        expect(canvas_for_audio.duration).to eq 45
      end
      it 'description' do
        expect(canvas_for_audio.description).to eq 'foo'
      end
    end

  ex_3d_tom_crane = {
               "id" =>"http://tomcrane.github.io/scratch/manifests/3/canvas/3d",
               "type" =>"Canvas",
               "thumbnail" =>"http://files.universalviewer.io/manifests/nelis/animal-skull/thumb.jpg",
               "width" =>10000,
               "height" =>10000,
               "depth" =>10000,
               "label" =>"A stage for an object",
               "content" =>[
                  {
                     "id" =>"...",
                     "type" =>"AnnotationPage",
                     "items" =>[
                        {
                           "id" =>"http://tomcrane.github.io/scratch/manifests/3/3d/anno1",
                           "type" =>"Annotation",
                           "motivation" =>"painting",
                           "body" =>{
                              "id" =>"http://files.universalviewer.io/manifests/nelis/animal-skull/animal-skull.json",
                              "type" =>"PhysicalObject",
                              "format" =>"application/vnd.threejs+json",
                              "label" =>"Animal Skull"
                           },
                           "target" =>"http://tomcrane.github.io/scratch/manifests/3/canvas/3d"
                        }
                     ]
                  }
               ]
}

    # file
    # Audio
    # video
    # 3d object
    # document
    # citation
    # image
    # book

    stanford_1 =        {
          "type" => "Canvas",
          "id" => "https://purl.stanford.edu/bc592pz8308/iiif3/canvas/0001",
          "label" => "image",
          "height" => 7579,
          "width" => 10108,
          "content" => [
            {
              "type" => "AnnotationPage",
              "id" => "https://purl.stanford.edu/bc592pz8308/iiif3/annotation_page/0001",
              "items" => [
                {
                  "type" => "Annotation",
                  "motivation" => "painting",
                  "id" => "https://purl.stanford.edu/bc592pz8308/iiif3/annotation/0001",
                  "body" => {
                    "type" => "Image",
                    "id" => "https://stacks.stanford.edu/image/iiif/bc592pz8308%2Fbc592pz8308_05_0001/full/full/0/default.jpg",
                    "format" => "image/jpeg",
                    "height" => 7579,
                    "width" => 10108,
                    "service" => {
                      "@context" => "http://iiif.io/api/image/2/context.json",
                      "@id" => "https://stacks.stanford.edu/image/iiif/bc592pz8308%2Fbc592pz8308_05_0001",
                      "id" => "https://stacks.stanford.edu/image/iiif/bc592pz8308%2Fbc592pz8308_05_0001",
                      "profile" => "http://iiif.io/api/image/2/level1.json"
                    }
                  },
                  "target" => "https://purl.stanford.edu/bc592pz8308/iiif3/canvas/0001"
                }
              ]
            }
          ]
        }

  end

end
