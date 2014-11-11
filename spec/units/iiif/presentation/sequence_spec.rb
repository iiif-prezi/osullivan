describe IIIF::Presentation::Sequence do

  let(:subclass_subject) do
    Class.new(IIIF::Presentation::Sequence) do
      def initialize(hsh={})
        hsh = { '@type' => 'a:SubClass' }
        super(hsh)
      end
    end
  end

  let(:fixed_values) do
    {
      '@type' => 'sc:Sequence',
      '@id' => 'http://example.com/prefix/sequence/456',
      '@context' => IIIF::Presentation::CONTEXT,
      'label' => 'Book 1',
      'description' => 'A longer description of this example book. It should give some real information.',
      'thumbnail' => {
        '@id' => 'http://www.example.org/images/book1-page1/full/80,100/0/default.jpg',
        'service'=> {
          '@context' => 'http://iiif.io/api/image/2/context.json',
          '@id' => 'http://www.example.org/images/book1-page1',
          'profile' => 'http://iiif.io/api/image/2/level1.json'
        }
      },
      'attribution' => 'Provided by Example Organization',
      'license' => 'http://www.example.org/license.html',
      'logo' => 'http://www.example.org/logos/institution1.jpg',
      'see_also' => 'http://www.example.org/library/catalog/book1.xml',
      'service' => {
        '@context' => 'http://example.org/ns/jsonld/context.json',
        '@id' =>  'http://example.org/service/example',
        'profile' => 'http://example.org/docs/example-service.html'
      },
      'related' => {
        '@id' => 'http://www.example.org/videos/video-book1.mpg',
        'format' => 'video/mpeg'
      },
      'within' => 'http://www.example.org/collections/books/',
      # Sequence
      'metadata' => [{'label'=>'Author', 'value'=>'Anne Author'}],
      'canvases' => [{
        '@id' => 'http://www.example.org/iiif/book1/canvas/p1',
        '@type' => 'sc:Canvas',
        'label' => 'p. 1',
        'height' => 1000,
        'width' => 750,
        'images'=>  []
      }],
      'viewing_hint' => 'paged',
      'start_canvas' => 'http://www.example.org/iiif/book1/canvas/p2',
      'viewing_direction' => 'right-to-left',
    }
  end

  describe '#initialize' do
    it 'sets @type to sc:Sequence by default' do
      expect(subject['@type']).to eq 'sc:Sequence'
    end
    it 'allows subclasses to override @type' do
      sub = subclass_subject.new
      expect(sub['@type']).to eq 'a:SubClass'
    end
  end

  describe '#required_keys' do
    it 'accumulates from the superclass' do
      expect(subject.required_keys).to eq %w{ @type }
    end
  end

  describe '#string_only_keys' do
    it 'accumulates from the superclass' do
      expect(subject.string_only_keys).to eq %w{ viewing_hint start_canvas viewing_direction }
    end
  end

  describe '#array_only_keys' do
    it 'accumulates from the superclass' do
      expect(subject.array_only_keys).to eq %w{ metadata canvases }
    end
  end

  describe 'Array only key accessor and mutators' do
    IIIF::Presentation::Sequence.new.array_only_keys.each do |prop|
      describe "#{prop}=" do
        it "sets #{prop}" do
          ex = [{'label' => 'XYZ'}]
          subject.send("#{prop}=", ex)
          expect(subject[prop]).to eq ex
        end
        it 'raises an exception when attempting to set it to something other than an Array' do
          expect { subject.send("#{prop}=", 'Foo') }.to raise_error IIIF::Presentation::IllegalValueError
        end
      end
      describe "#{prop}" do
        it "gets #{prop}" do
          ex = [{'label' => 'XYZ'}]
          subject[prop] = ex
          expect(subject.send(prop)).to eq ex
        end
      end
    end
  end

  describe 'String-only key accessor and mutators' do
    IIIF::Presentation::Sequence.new.string_only_keys.each do |prop|
      describe "#{prop}=" do
        it "sets #{prop}" do
          ex = 'foo'
          subject.send("#{prop}=", ex)
          expect(subject[prop]).to eq ex
        end
        it 'raises an exception when attempting to set it to something other than a String' do
          expect { subject.send("#{prop}=", ['Foo']) }.to raise_error IIIF::Presentation::IllegalValueError
        end
      end
      describe "#{prop}" do
        it "gets #{prop}" do
          ex = 'bar'
          subject[prop] = ex
          expect(subject.send(prop)).to eq ex
        end
      end
    end
  end

  describe 'Attributes allowed anywhere' do
    IIIF::Presentation::Sequence.new.any_type_keys.each do |prop|
      describe "##{prop}=" do
        it "sets self['#{prop}']" do
          subject.send("#{prop}=", fixed_values[prop])
          expect(subject["#{prop}"]).to eq fixed_values[prop]
        end
        if prop.camelize(:lower) != prop
          it "is aliased as ##{prop.camelize(:lower)}=" do
            subject.send("#{prop.camelize(:lower)}=", fixed_values[prop])
            expect(subject["#{prop}"]).to eq fixed_values[prop]
          end
        end
      end

      describe "##{prop}" do
        it "gets self[#{prop}]" do
          subject.send("[]=", prop, fixed_values[prop])
          expect(subject.send("#{prop}")).to eq fixed_values[prop]
        end
        if prop.camelize(:lower) != prop
          it "is aliased as ##{prop.camelize(:lower)}" do
            subject.send("[]=", prop, fixed_values[prop])
            expect(subject.send("#{prop.camelize(:lower)}")).to eq fixed_values[prop]
          end
        end
      end
    end

    describe '#validate' do
      it 'raises an error if viewing_hint isn\'t an allowable value' do
        subject['viewing_hint'] = 'foo'
        expect { subject.validate }.to raise_error IIIF::Presentation::IllegalValueError
      end
      it 'raises an error if viewing_directon isn\'t an allowable value' do
        subject['viewing_direction'] = 'foo-to-bar'
        expect { subject.validate }.to raise_error IIIF::Presentation::IllegalValueError
      end
    end

  end

end

