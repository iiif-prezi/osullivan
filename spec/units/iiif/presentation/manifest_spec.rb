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

  describe '#initialize' do
    it 'sets @type to sc:Manifest by default' do
      expect(subject['@type']).to eq 'sc:Manifest'
    end
    it 'allows subclasses to override @type' do
      sub = subclass_subject.new
      expect(sub['@type']).to eq 'a:SubClass'
    end
  end

  describe '#metadata' do
    it 'roundtrips' do
      subject['@id'] = 'http://www.example.org/iiif/book1/manifest'
      subject.label = 'Book 1'
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
      expect(subject.metadata[1]['value'].length).to eq(2)
      expect(subject.metadata[1]['value'].select { |e| e['@language'] == 'fr'}.last['@value']).to eq('Paris, environ 14eme siecle')
      File.delete('/tmp/osullivan-spec.json')
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

  describe 'Array key accessor and mutators' do
    IIIF::Presentation::Manifest::ARRAY_KEYS.each do |prop|
      describe "#{prop}=" do
        it "sets #{prop}" do
          ex = [{'label' => 'XYZ'}]
          subject.send("#{prop}=", ex)
          expect(subject[prop]).to eq ex
        end
        # it 'raises an exception when attempting to set it to something other than an Array' do
        #   expect { subject.send("#{prop}=", 'Foo') }.to raise_error TypeError
        # end
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
end
