describe IIIF::V3::Presentation::Annotation do
  let(:content_id) { 'http://example.org/iiif/book1/res/tei-text-p1.xml' }
  let(:content_type) { 'dctypes:Text' }
  let(:mimetype) { 'application/tei+xml' }
  let(:image_2_api_service) do
    IIIF::V3::Presentation::Service.new({
                                          'id' => content_id,
                                          '@id' => content_id,
                                          'profile' => IIIF::V3::Presentation::Service::IIIF_IMAGE_V2_LEVEL1_PROFILE
                                        })
  end
  let(:img_content_resource) do
    IIIF::V3::Presentation::ImageResource.new(
      'id' => content_id,
      'type' => content_type,
      'format' => mimetype,
      'service' => [image_2_api_service]
    )
  end

  describe '#required_keys' do
    %w[type id motivation target].each do |k|
      it k do
        expect(subject.required_keys).to include(k)
      end
    end
  end

  describe '#prohibited_keys' do
    it 'contains the expected key names' do
      keys = described_class::PAGING_PROPERTIES +
             described_class::CONTENT_RESOURCE_PROPERTIES +
             %w[
               nav_date
               viewing_direction
               start_canvas
               content_annotations
             ]
      expect(subject.prohibited_keys).to include(*keys)
    end
  end

  describe '#any_type_keys' do
    it 'body' do
      expect(subject.any_type_keys).to include('body')
    end
    it 'target' do
      expect(subject.any_type_keys).to include('target')
    end
  end

  describe '#uri_only_keys' do
    it 'id' do
      expect(subject.uri_only_keys).to include('id')
    end
  end

  describe '#string_only_keys' do
    it 'time_mode' do
      expect(subject.string_only_keys).to include('time_mode')
    end
  end

  describe '#legal_time_mode_values' do
    it 'contains the expected values' do
      expect(subject.legal_time_mode_values).to contain_exactly('trim', 'scale', 'loop')
    end
  end

  describe '#legal_viewing_hint_values' do
    it 'contains none' do
      expect(subject.legal_viewing_hint_values).to contain_exactly('none')
    end
  end

  describe '#initialize' do
    it 'sets type to Annotation by default' do
      expect(subject['type']).to eq 'Annotation'
    end
    it 'allows subclasses to override type' do
      subclass = Class.new(described_class) do
        def initialize(hsh = {})
          hsh = { 'type' => 'a:SubClass' }
          super(hsh)
        end
      end
      sub = subclass.new
      expect(sub['type']).to eq 'a:SubClass'
    end
    it 'sets motivation to painting by default' do
      expect(subject['motivation']).to eq 'painting'
    end
    it 'allows motivation to be passed in' do
      my_anno = described_class.new('motivation' => 'foo')
      expect(my_anno.motivation).to eq 'foo'
    end
    it 'allows type to be passed in' do
      my_anno = described_class.new('type' => 'bar')
      expect(my_anno.type).to eq 'bar'
    end
  end

  describe '#validate' do
    before(:each) do
      subject['id'] = 'http://example.org/iiif/anno/1s'
      subject['target'] = 'foo'
    end
    it 'raises IllegalValueError if id is not URI' do
      exp_err_msg = "id value must be a String containing a URI for #{described_class}"
      subject['id'] = 'foo'
      expect { subject.validate }.to raise_error(IIIF::V3::Presentation::IllegalValueError, exp_err_msg)
    end

    it 'raises IllegalValueError if time_mode isn\'t an allowable value' do
      exp_err_msg = "timeMode for #{described_class} must be one of [\"trim\", \"scale\", \"loop\"]."
      subject['time_mode'] = 'foo'
      expect { subject.validate }.to raise_error IIIF::V3::Presentation::IllegalValueError, exp_err_msg
    end

    describe 'body is a kind of IIIF::V3::Presentation::ImageResource' do
      let(:img_body_anno) do
        subject['id'] = 'http://example.org/iiif/anno/1s'
        subject['target'] = 'foo'
        subject['body'] = img_content_resource
        subject
      end
      it 'raises IllegalValueError if motivation isn\'t "painting"' do
        exp_err_msg = "#{described_class} motivation must be 'painting' when body is a kind of IIIF::V3::Presentation::ImageResource"
        img_body_anno['motivation'] = 'foo'
        expect { img_body_anno.validate }.to raise_error IIIF::V3::Presentation::IllegalValueError, exp_err_msg
      end
      let(:img_resource_without_id) do
        IIIF::V3::Presentation::ImageResource.new(
          'type' => content_type,
          'format' => mimetype
        )
      end
      let(:http_uri_err_msg) do
        "when #{described_class} body is a kind of IIIF::V3::Presentation::ImageResource, ImageResource id must be an http(s) URI"
      end
      it 'raises IllegalValueError if no id field in ImageResource' do
        img_body_anno.body = img_resource_without_id
        expect { img_body_anno.validate }.to raise_error IIIF::V3::Presentation::IllegalValueError, http_uri_err_msg
      end
      it 'raises IllegalValueError if id in ImageResource isn\'t URI' do
        img_resource_without_id['id'] = 'foo'
        img_body_anno.body = img_resource_without_id
        expect { img_body_anno.validate }.to raise_error IIIF::V3::Presentation::IllegalValueError, http_uri_err_msg
      end
      it 'raises IllegalValueError if id in ImageResource isn\'t http(s) URI' do
        img_resource_without_id['id'] = 'ftp://example.com/somewhere'
        img_body_anno.body = img_resource_without_id
        expect { img_body_anno.validate }.to raise_error IIIF::V3::Presentation::IllegalValueError, http_uri_err_msg
      end
    end
  end

  describe 'realistic examples' do
    let(:anno_id) { 'http://example.org/iiif/annoation/abc666' }
    let(:target_id) { 'http://example.org/iiif/canvas/abc666' }

    describe 'stanford (purl code)' do
      let(:anno) do
        anno = described_class.new
        anno['id'] = anno_id
        anno['target'] = target_id
        anno.body = img_content_resource
        anno
      end
      it 'validates' do
        expect { anno.validate }.not_to raise_error
      end
      it 'has expected required values' do
        expect(anno.id).to eq anno_id
        expect(anno['type']).to eq 'Annotation'
        expect(anno['motivation']).to eq 'painting'
        expect(anno['target']).to eq target_id
      end
      it 'has expected additional values' do
        expect(anno['body']).to eq img_content_resource
      end
    end

    describe 'from http://prezi3.iiif.io/api/presentation/3.0' do
      describe 'body is image_resource with height and width' do
        let(:img_type) { 'dctypes:Image' }
        let(:img_mime) { 'image/jpeg' }
        let(:img_h) { 2000 }
        let(:img_w) { 1500 }
        let(:img_hw_resource) do
          IIIF::V3::Presentation::ImageResource.new(
            'id' => content_id,
            'type' => img_type,
            'format' => img_mime,
            'height' => img_h,
            'width' => img_w,
            'service' => [image_2_api_service]
          )
        end
        let(:my_anno) do
          anno = described_class.new
          anno['id'] = anno_id
          anno['target'] = target_id
          anno.body = img_hw_resource
          anno
        end
        it 'validates' do
          expect { my_anno.validate }.not_to raise_error
        end
        it 'has expected additional values' do
          expect(my_anno['body']).to eq img_hw_resource
          expect(my_anno['body']['height']).to eq img_h
          expect(my_anno['body']['width']).to eq img_w
        end

        describe 'and service with height and width and tiles' do
          let(:tiles_val) { [{ "width" => 512, "scaleFactors" => [1, 2, 4, 8, 16] }] }
          let(:service) do
            s = image_2_api_service
            s['height'] = 8000
            s['width'] = 6000
            s['tiles'] = tiles_val
            [s]
          end
          it 'validates' do
            img_hw_resource['service'] = service
            expect { my_anno.validate }.not_to raise_error
          end
          it "body['service'] has expected additional values'" do
            annotation_service = my_anno['body']['service'].first
            expect(annotation_service).to eq service.first
            expect(annotation_service['height']).to eq 8000
            expect(annotation_service['width']).to eq 6000
            expect(annotation_service['tiles']).to eq tiles_val
          end
        end
      end
    end

    describe 'from digerati' do
      describe 'anno body is audio' do
        let(:body_id) { 'http://example.org/iiif/foo2.mp3' }
        let(:body_type) { 'Audio' }
        let(:audio_res) do
          IIIF::V3::Presentation::Resource.new(
            'id' => body_id,
            'type' => body_type
          )
        end
        let(:my_anno) do
          anno = described_class.new
          anno['id'] = anno_id
          anno['target'] = target_id
          anno.body = audio_res
          anno
        end
        it 'validates' do
          expect { my_anno.validate }.not_to raise_error
        end
        it 'has expected required values' do
          expect(my_anno['type']).to eq 'Annotation'
          expect(my_anno.id).to eq anno_id
          expect(my_anno['motivation']).to eq 'painting'
          expect(my_anno['target']).to eq target_id
        end
        it 'has expected additional values' do
          expect(my_anno['body']).to eq audio_res
          expect(my_anno['body']['type']).to eq body_type
          expect(my_anno['body']['id']).to eq body_id
        end
      end

      describe 'anno body is video' do
        let(:body_id) { 'http://example.org/foo.webm' }
        let(:body_type) { 'Video' }
        let(:body_mime) { 'video/webm' }
        let(:video_res) do
          IIIF::V3::Presentation::Resource.new(
            'id' => body_id,
            'type' => body_type,
            'format' => body_mime
          )
        end
        let(:my_anno) do
          anno = described_class.new
          anno['id'] = anno_id
          anno['target'] = target_id
          anno.body = video_res
          anno
        end
        it 'validates' do
          expect { my_anno.validate }.not_to raise_error
        end
        it 'has expected body values' do
          expect(my_anno['body']).to eq video_res
          expect(my_anno['body']['type']).to eq body_type
          expect(my_anno['body']['id']).to eq body_id
          expect(my_anno['body']['format']).to eq body_mime
        end
      end

      describe 'anno body is 3d object' do
        let(:body_id) { 'http://files.universalviewer.io/manifests/nelis/animal-skull/animal-skull.json' }
        let(:body_type) { 'PhysicalObject' }
        let(:body_mime) { 'application/vnd.threejs+json' }
        let(:body_label) { 'Animal Skull' }
        let(:body_res) do
          IIIF::V3::Presentation::Resource.new(
            'id' => body_id,
            'type' => body_type,
            'format' => body_mime,
            'label' => body_label
          )
        end
        let(:my_anno) do
          anno = described_class.new
          anno['id'] = anno_id
          anno['target'] = target_id
          anno.body = body_res
          anno
        end
        it 'validates' do
          expect { my_anno.validate }.not_to raise_error
        end
        it 'has expected body values' do
          expect(my_anno['body']).to eq body_res
          expect(my_anno['body']['type']).to eq body_type
          expect(my_anno['body']['id']).to eq body_id
          expect(my_anno['body']['format']).to eq body_mime
          expect(my_anno['body']['label']).to eq body_label
        end
      end

      describe 'anno body is pdf' do
        let(:body_id) { 'http://example.org/iiif/some-document.pdf' }
        let(:body_type) { 'Document' }
        let(:body_mime) { 'application/pdf' }
        let(:body_res) do
          IIIF::V3::Presentation::Resource.new(
            'id' => body_id,
            'type' => body_type,
            'format' => body_mime
          )
        end
        let(:my_anno) do
          anno = described_class.new
          anno['id'] = anno_id
          anno['target'] = target_id
          anno.body = body_res
          anno
        end
        it 'validates' do
          expect { my_anno.validate }.not_to raise_error
        end
        it 'has expected body values' do
          expect(my_anno['body']).to eq body_res
          expect(my_anno['body']['type']).to eq body_type
          expect(my_anno['body']['id']).to eq body_id
          expect(my_anno['body']['format']).to eq body_mime
        end
      end

      describe 'anno body is choice (of 2 videos)' do
        let(:body_type) { 'Video' }
        let(:body1_id) { 'http://example.org/foo.mp4f' }
        let(:body1_mime) { 'video/mp4; codec..xxxxx' }
        let(:body1_res) do
          IIIF::V3::Presentation::Resource.new(
            'id' => body1_id,
            'type' => body_type,
            'format' => body1_mime
          )
        end
        let(:body2_id) { 'http://example.org/foo.webm' }
        let(:body2_mime) { 'video/webm' }
        let(:body2_res) do
          IIIF::V3::Presentation::Resource.new(
            'id' => body2_id,
            'type' => body_type,
            'format' => body2_mime
          )
        end
        let(:body_res) do
          IIIF::V3::Presentation::Choice.new(
            'items' => [body1_res, body2_res],
            'choiceHint' => 'client'
          )
        end
        let(:my_anno) do
          anno = described_class.new
          anno['id'] = anno_id
          anno['target'] = target_id
          anno.body = body_res
          anno
        end
        it 'validates' do
          expect { my_anno.validate }.not_to raise_error
        end
        it 'has expected body values' do
          expect(my_anno['body']).to eq body_res
          expect(my_anno['body'].keys.size).to eq 3
          expect(my_anno['body']['type']).to eq 'Choice'
          expect(my_anno['body'].choiceHint).to eq 'client'
          expect(my_anno['body']['items']).to eq [body1_res, body2_res]
        end
      end
    end
  end
end
