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

  describe '#int_only_keys' do
    it 'depth (for 3d objects)' do
      expect(subject.int_only_keys).to include('depth')
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
    let(:canvas_id) { 'http://example.org/iiif/book1/canvas/c1' }
    let(:exp_id_err_msg1) { "id value must be a String containing an http(s) URI for #{described_class}" }
    let(:exp_id_err_msg2) { "id must be an http(s) URI without a fragment for #{described_class}" }
    before(:each) do
      subject['id'] = canvas_id
      subject['label'] = 'foo'
    end
    it 'raises IllegalValueError if id is not URI' do
      subject['id'] = 'foo'
      expect { subject.validate }.to raise_error(IIIF::V3::Presentation::IllegalValueError, exp_id_err_msg1)
    end
    it 'raises IllegalValueError if id is not http(s)' do
      subject['id'] = 'ftp://www.example.org'
      expect { subject.validate }.to raise_error(IIIF::V3::Presentation::IllegalValueError, exp_id_err_msg1)
    end
    it 'raises IllegalValueError if id has a fragment' do
      subject['id'] = 'http://www.example.org#foo'
      expect { subject.validate }.to raise_error(IIIF::V3::Presentation::IllegalValueError, exp_id_err_msg2)
    end

    # let(:exp_extent_err_msg) { "#{described_class} must have (a height and a width) and/or a duration" }
    #  (see sul-dlss/purl/issues/169)
    let(:exp_extent_err_msg) { "#{described_class} requires both height and width or neither" }
    it 'raises IllegalValueError if height is a string' do
      subject['height'] = 'foo'
      expect { subject.validate }.to raise_error(IIIF::V3::Presentation::IllegalValueError, exp_extent_err_msg)
    end
    it 'raises IllegalValueError if height but no width' do
      subject['height'] = 666
      expect { subject.validate }.to raise_error(IIIF::V3::Presentation::IllegalValueError, exp_extent_err_msg)
    end
    it 'raises IllegalValueError if width but no height' do
      subject['width'] = 666
      subject['duration'] = 66.6
      expect { subject.validate }.to raise_error(IIIF::V3::Presentation::IllegalValueError, exp_extent_err_msg)
    end
    it 'raises IllegalValueError if no width, height or duration' do
      # (see sul-dlss/purl/issues/169)
      skip('while this is in the current v3 spec, it does not make sense for some content (e.g. txt files)')
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

    it 'IllegalValueError for content with annotation target not the canvas id' do
      anno = IIIF::V3::Presentation::Annotation.new(
        'id' => 'http://example.com/anno/666',
        'target' => canvas_id)
      anno_page = IIIF::V3::Presentation::AnnotationPage.new(
        'id' => "http://example.org/iiif/book1/page/p1/1",
        'items' => [anno])
      subject['content'] = [anno_page]

      expect { subject.validate }.not_to raise_error

      anno['target'] = 'http://example.com/canvas/abc'
      exp_err_msg = 'URI of the canvas must be repeated in the target field of included Annotations'
      expect { subject.validate }.to raise_error(IIIF::V3::Presentation::IllegalValueError, exp_err_msg)
    end
  end

  describe 'realistic examples' do
    let(:canvas_id) { 'http://example.org/iiif/book1/canvas/c1' }
    let(:minimal_canvas_object) { described_class.new({
      "id" => canvas_id,
      'label' => {"en" => ["so minimal it's not here"]},
      'height' => 1000,
      'width' => 1000
    })}
    let(:anno_page) { IIIF::V3::Presentation::AnnotationPage.new(
      "id" => "http://example.org/iiif/book1/page/p1/1",
      'items' => []
      )}
    describe 'minimal canvas' do
      it 'validates' do
        expect{minimal_canvas_object.validate}.not_to raise_error
      end
      it 'has expected required values' do
        expect(minimal_canvas_object.type).to eq described_class::TYPE
        expect(minimal_canvas_object.id).to eq canvas_id
        expect(minimal_canvas_object.label['en']).to include "so minimal it's not here"
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
      it 'has empty array for content' do
        expect(canvas_object.content).to eq []
      end
    end
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

      describe 'stanford (purl code)' do
        let(:canvas_object) {
          c = described_class.new
          c['id'] = canvas_id
          c.label = {'en' => ['label']}
          c.content << anno_page
          c
        }
        describe 'non-image' do
          it 'validates' do
            expect{canvas_object.validate}.not_to raise_error
          end
          it 'has expected required values' do
            expect(canvas_object.type).to eq described_class::TYPE
            expect(canvas_object.id).to eq canvas_id
            expect(canvas_object.label['en']).to include "label"
          end
          it 'has expected additional values' do
            expect(canvas_object.content).to eq [anno_page]
          end
        end
        describe 'image' do
          let(:img_canvas) {
            canvas_object.height = 666
            canvas_object.width = 888
            canvas_object
          }
          it 'validates' do
            expect{img_canvas.validate}.not_to raise_error
          end
          it 'has expected required values' do
            expect(img_canvas.type).to eq described_class::TYPE
            expect(img_canvas.id).to eq canvas_id
            expect(img_canvas.label['en']).to include "label"
            expect(img_canvas.height).to eq 666
            expect(img_canvas.width).to eq 888
          end
          it 'has expected additional values' do
            expect(img_canvas.content).to eq [anno_page]
          end
        end
      end

      describe 'file object' do
        describe 'without extent info' do
          let(:file_object) { described_class.new({
            "id" => "https://example.org/bd742gh0511/iiif3/canvas/bd742gh0511_1",
            "label" => {"en" => ["File 1"]},
            "content" => [anno_page]
            })}
          it 'validates' do
            expect{file_object.validate}.not_to raise_error
          end
        end
      end

      describe 'image object' do
        describe 'without extent info' do
          let(:image_object) { described_class.new({
            "id" => "https://example.org/yv090xk3108/iiif3/canvas/yv090xk3108_1",
            "label" => {"en" => ["image"]},
            "content" => [anno_page]
            })}
          it 'validates' do
            expect{image_object.validate}.not_to raise_error
          end
        end
        describe 'with extent given' do
          let(:image_object) { described_class.new({
            "id" => "https://example.org/yy816tv6021/iiif3/canvas/yy816tv6021_3",
            "label" => {"en" => ["Image of media (1 of 2)"]},
            "height" => 3456,
            "width" => 5184,
            "content" => [anno_page]
            })}
          it 'validates' do
            expect{image_object.validate}.not_to raise_error
          end
        end
      end

      describe 'audio object' do
        describe 'without duration' do
          let(:canvas_for_audio) { described_class.new({
            "id" => "https://example.org/xk681bt2506/iiif3/canvas/xk681bt2506_1",
            "label" => {"en" => ["Audio file 1"]},
            "content" => [anno_page]
            })}
          it 'validates' do
            expect{canvas_for_audio.validate}.not_to raise_error
          end
        end
        describe 'digerati example' do
          let(:canvas_for_audio) { described_class.new({
            "id" => "http://tomcrane.github.io/scratch/manifests/3/canvas/2",
            "label" => "Track 2",
            'summary' => {
              'en' => ['foo']
            },
            "duration" => 45,
            "content" => [anno_page]
            })}
          it 'validates' do
            expect{canvas_for_audio.validate}.not_to raise_error
          end
          it 'duration' do
            expect(canvas_for_audio.duration).to eq 45
          end
          it 'summary' do
            expect(canvas_for_audio.summary['en'].first).to eq 'foo'
          end
        end
      end

      describe '3d object' do
        let(:canvas_3d_object) { described_class.new({
          "id" => "http://tomcrane.github.io/scratch/manifests/3/canvas/3d",
          "thumbnail" => [{'id' => "http://files.universalviewer.io/manifests/nelis/animal-skull/thumb.jpg",
            'type' => 'Image'}],
          "width" => 10000,
          "height" => 10000,
          "depth" => 10000,
          "label" => "A stage for an object",
          "content" => [anno_page]
          })}
        it 'validates' do
          expect{canvas_3d_object.validate}.not_to raise_error
        end
        it 'thumbnail' do
          expect(canvas_3d_object.thumbnail).to eq [{'id' => "http://files.universalviewer.io/manifests/nelis/animal-skull/thumb.jpg", 'type' => 'Image'}]
        end
        it 'depth' do
          expect(canvas_3d_object.depth).to eq 10000
        end
      end

      describe 'video object' do
        describe 'with extent info' do
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
      end
    end
  end
end
