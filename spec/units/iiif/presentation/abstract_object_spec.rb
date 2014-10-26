require 'active_support/inflector'
require 'json'

describe IIIF::Presentation::AbstractObject do

  let(:fixtures_dir) { File.join(File.dirname(__FILE__), '../../../fixtures') }
  let(:manifest_from_spec_path) { File.join(fixtures_dir, 'manifests/complete_from_spec.json') }
  let(:fixed_values) do
    {
      'type' => 'a:SubClass',
      'id' => 'http://example.com/prefix/manifest/123',
      'context' => IIIF::Presentation::AbstractObject::CONTEXT,
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

  let(:abstract_object_subclass) do 
    Class.new(IIIF::Presentation::AbstractObject) do
      include IIIF::Presentation::HashBehaviours
      def initialize(hsh={}, include_context=false)
        opts = {
          '@type' => 'a:SubClass', 
          '@id' => 'http://example.com/prefix/manifest/123',
        }
        super(opts, true)
      end
    end
  end

  subject { abstract_object_subclass.new }

  describe '#initialize' do
  	it 'raises an error if you try to instantiate AbstractObject' do
      expect { IIIF::Presentation::AbstractObject.new }.to raise_error(RuntimeError)
    end
    it 'sets @type' do
      expect(subject['@type']).to eq 'a:SubClass'
    end
  end

  describe 'self.parse' do
    it 'works from a file' do
      abs_obj = abstract_object_subclass.parse(manifest_from_spec_path)
      expect(abs_obj['label']).to eq 'Book 1'
    end
    it 'works from a string of JSON' do
      file = File.open(manifest_from_spec_path, 'rb')
      json_string = file.read
      file.close
      abs_obj = abstract_object_subclass.parse(json_string)
      expect(abs_obj['label']).to eq 'Book 1'
    end
    describe 'works from a hash' do
      it 'plain old' do
        h = JSON.parse(IO.read(manifest_from_spec_path))
        abs_obj = abstract_object_subclass.parse(h)
        expect(abs_obj['label']).to eq 'Book 1'
      end
      it 'ActiveSupport::OrderedHash' do
        h = JSON.parse(IO.read(manifest_from_spec_path))
        oh = ActiveSupport::OrderedHash[h]
        abs_obj = abstract_object_subclass.parse(oh)
        expect(abs_obj['label']).to eq 'Book 1'
      end
    end
  end

  describe 'JSON LD accessor and mutators' do
    IIIF::Presentation::AbstractObject::JSON_LD_PROPS.each do |prop|
      describe "#{prop}=" do
        it "sets self['@#{prop}']" do
          subject.send("#{prop}=", fixed_values[prop])
          expect(subject["@#{prop}"]).to eq fixed_values[prop]
        end
        it "is aliased as set#{prop.camelize}" do
          subject.send("set#{prop.camelize}", 'my:NewType')
          expect(subject["@#{prop}"]).to eq 'my:NewType'
        end
      end

      describe "##{prop}" do
        it "gets self[@#{prop}]" do
          expect(subject.send("#{prop}")).to eq fixed_values[prop]
        end
        it "is aliased as get#{prop.camelize}" do
          expect(subject.send("get#{prop.camelize}")).to eq fixed_values[prop]
        end
      end

    end
  end


  describe 'Attributes allowed anywhere' do
    IIIF::Presentation::AbstractObject::ALLOWED_ANYWHERE_PROPS.each do |prop|
      describe "##{prop}=" do
        it "sets self['#{prop}']" do
          subject.send("#{prop}=", fixed_values[prop])
          expect(subject["#{prop}"]).to eq fixed_values[prop]
        end
        it "is aliased as set#{prop.camelize}" do
          subject.send("set#{prop.camelize}", fixed_values[prop])
          expect(subject["#{prop}"]).to eq fixed_values[prop]
        end
      end

      describe "##{prop}" do
        it "gets self[#{prop}]" do
          subject.send("[]=", prop, fixed_values[prop])
          expect(subject.send("#{prop}")).to eq fixed_values[prop]
        end
        it "is aliased as get#{prop.camelize}" do
          subject.send("[]=", prop, fixed_values[prop])
          expect(subject.send("get#{prop.camelize}")).to eq fixed_values[prop]
        end
      end

    end
  end

  describe '#metadata' do
    it 'returns [] if not set' do
      expect(subject.metadata).to eq([])
    end
    it 'is not in #to_hash at all if access it but do not append to it' do
      subject.metadata # touch it
      expect(subject.metadata).to eq([])
      expect(subject.to_hash.has_key?('metadata')).to be_falsey
    end
    it 'gets structured as we\'d expect' do
      subject.metadata << {
        'label' => 'Author', 
        'value' => 'Anne Author'
      }
      subject.metadata << {
        'label' => 'Published', 
        'value' => [
          {'@value'=> 'Paris, circa 1400', '@language'=>'en'},
          {'@value'=> 'Paris, environ 14eme siecle', '@language'=>'fr'}
        ]
      }
      expect(subject.metadata[0]['label']).to eq('Author')
      expect(subject.metadata[1]['value'].length).to eq(2)
      expect(subject.metadata[1]['value'].select { |e| e['@language'] == 'fr'}.last['@value']).to eq('Paris, environ 14eme siecle')
    end
    it 'roundtrips' do
      subject.metadata << {
        'label' => 'Author', 
        'value' => 'Anne Author'
      }
      subject.metadata << {
        'label' => 'Published', 
        'value' => [
          {'@value'=> 'Paris, circa 1400', '@language'=>'en'},
          {'@value'=> 'Paris, environ 14eme siecle', '@language'=>'fr'}
        ]
      }
      File.open('/tmp/osullivan-spec.json','w') do |f|
        f.write(subject.to_pretty_json)
      end
      parsed = subject.class.parse('/tmp/osullivan-spec.json')
      expect(parsed.metadata[0]['label']).to eq('Author')
      expect(parsed.metadata[1]['value'].length).to eq(2)
      expect(parsed.metadata[1]['value'].select { |e| e['@language'] == 'fr'}.last['@value']).to eq('Paris, environ 14eme siecle')
      expect(parsed['metadata'][0]['label']).to eq('Author')
      expect(parsed['metadata'][1]['value'].length).to eq(2)
      expect(parsed['metadata'][1]['value'].select { |e| e['@language'] == 'fr'}.last['@value']).to eq('Paris, environ 14eme siecle')
      File.delete('/tmp/osullivan-spec.json')
    end

    describe 'raises a TypeError when parent#to_hash is called if all of its members aren\'t a type of hash' do
      it 'can be a Hash' do
      end
      it 'can be an ActiveSupport::OrderedHash' do
      end
      it 'can\'t be, e.g., a String' do
      end
      it 'can\'t be, e.g., an Integer' do
      end
    end

  end

end
