describe IIIF::Presentation::Manifest do

  subject { IIIF::Presentation::Manifest.new }

  let(:subclass_subject) do
    Class.new(IIIF::Presentation::Manifest) do
      def initialize(hsh={})
        hsh = { '@type' => 'a:SubClass' }
        super(hsh)
      end
    end
  end

  let(:fixed_values) do
    {
      'type' => 'a:SubClass',
      'id' => 'http://example.com/prefix/manifest/123',
      'context' => IIIF::Presentation::CONTEXT,
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
    }
  end

  describe '#initialize' do
    it 'sets @type to sc:Manifest by default' do
      expect(subject['@type']).to eq 'sc:Manifest'
    end
    it 'allows subclasses to override @type' do
      sub = subclass_subject.new
      expect(sub['@type']).to eq 'a:SubClass'
    end
  end

  describe '#required_keys' do
    it 'accumulates' do
      expect(subject.required_keys).to eq %w{ @type @id label }
    end
  end

  describe '#validate' do
    it 'raises an error if there is no @id' do
      subject.label = 'Book 1'
      expect { subject.to_hash }.to raise_error IIIF::Presentation::MissingRequiredKeyError
    end
    it 'raises an error if there is no label' do
      subject['@id'] = 'http://www.example.org/iiif/book1/manifest'
      expect { subject.to_hash }.to raise_error IIIF::Presentation::MissingRequiredKeyError
    end
    it 'raises an error if there is no @type' do
      subject.delete('@type')
      subject.label = 'Book 1'
      subject['@id'] = 'http://www.example.org/iiif/book1/manifest'
      expect { subject.to_hash }.to raise_error IIIF::Presentation::MissingRequiredKeyError
    end
  end

  describe 'Array only key accessor and mutators' do
    # This is lame, but we can't access subject from here
    IIIF::Presentation::Manifest.new.array_only_keys.each do |prop|
      describe "#{prop}=" do
        it "sets #{prop}" do
          ex = [{'label' => 'XYZ'}]
          subject.send("#{prop}=", ex)
          expect(subject[prop]).to eq ex
        end
        if prop.camelize(:lower) != prop
          it "is aliased as ##{prop.camelize(:lower)}=" do
            ex = [{'label' => 'XYZ'}]
            subject.send("#{prop.camelize(:lower)}=", ex)
            expect(subject[prop]).to eq ex
          end
        end
        it 'raises an exception when attempting to set it to something other than an Array' do
          expect { subject.send("#{prop}=", 'Foo') }.to raise_error TypeError
        end
      end
      describe "#{prop}" do
        it "gets #{prop}" do
          ex = [{'label' => 'XYZ'}]
          subject[prop] = ex
          expect(subject.send(prop)).to eq ex
        end
        if prop.camelize(:lower) != prop
          it "is aliased as ##{prop.camelize(:lower)}" do
            ex = [{'label' => 'XYZ'}]
            subject[prop] = ex
            expect(subject.send("#{prop.camelize(:lower)}")).to eq ex
          end
        end
      end
    end
  end

  describe 'String-only key accessor and mutators' do
    # This is lame, but we can't access subject from here
    IIIF::Presentation::Manifest.new.string_only_keys.each do |prop|
      describe "#{prop}=" do
        it "sets #{prop}" do
          ex = 'foo'
          subject.send("#{prop}=", ex)
          expect(subject[prop]).to eq ex
        end
        if prop.camelize(:lower) != prop
          it "is aliased as ##{prop.camelize(:lower)}=" do
            ex = 'foo'
            subject.send("#{prop.camelize(:lower)}=", ex)
            expect(subject[prop]).to eq ex
          end
        end
        it 'raises an exception when attempting to set it to something other than a String' do
          expect { subject.send("#{prop}=", ['Foo']) }.to raise_error TypeError
        end
      end
      describe "#{prop}" do
        it "gets #{prop}" do
          ex = 'bar'
          subject[prop] = ex
          expect(subject.send(prop)).to eq ex
        end
        if prop.camelize(:lower) != prop
          it "is aliased as ##{prop.camelize(:lower)}" do
            ex = 'bar'
            subject[prop] = ex
            expect(subject.send("#{prop.camelize(:lower)}")).to eq ex
          end
        end
      end
    end
  end

  describe 'Attributes allowed anywhere' do
    IIIF::Presentation::Manifest.new.any_type_keys.each do |prop|
      describe "##{prop}=" do
        it "sets self['#{prop}']" do
          subject.send("#{prop}=", fixed_values[prop])
          expect(subject[prop]).to eq fixed_values[prop]
        end
        if prop.camelize(:lower) != prop
          it "is aliased as ##{prop.camelize(:lower)}=" do
            subject.send("#{prop.camelize(:lower)}=", fixed_values[prop])
            expect(subject[prop]).to eq fixed_values[prop]
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
  end

end
