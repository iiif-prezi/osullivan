require 'active_support/inflector'
require 'json'

describe IIIF::Service do

  let(:fixtures_dir) { File.join(File.dirname(__FILE__), '../../fixtures') }
  let(:manifest_from_spec_path) { File.join(fixtures_dir, 'manifests/complete_from_spec.json') }

  describe 'self.parse' do
    it 'works from a file' do
      s = described_class.parse(manifest_from_spec_path)
      expect(s['label']).to eq 'Book 1'
    end
    it 'works from a string of JSON' do
      file = File.open(manifest_from_spec_path, 'rb')
      json_string = file.read
      file.close
      s = described_class.parse(json_string)
      expect(s['label']).to eq 'Book 1'
    end
    describe 'works from a hash' do
      it 'plain old' do
        h = JSON.parse(IO.read(manifest_from_spec_path))
        s = described_class.parse(h)
        expect(s['label']).to eq 'Book 1'
      end
      it 'ActiveSupport::OrderedHash' do
        h = JSON.parse(IO.read(manifest_from_spec_path))
        oh = ActiveSupport::OrderedHash[h]
        s = described_class.parse(oh)
        expect(s['label']).to eq 'Book 1'
      end
    end
    it 'turns camels to snakes' do
      s = described_class.parse(manifest_from_spec_path)
      expect(s.keys.include?('see_also')).to be_truthy
      expect(s.keys.include?('seeAlso')).to be_falsey
    end
  end

  describe 'self#from_ordered_hash' do
    let(:fixture) { JSON.parse('{
        "@context": "http://iiif.io/api/presentation/2/context.json",
        "@id": "http://example.com/manifest",
        "@type": "sc:Manifest",
        "label": "My Manifest",
        "service": {
          "@context": "http://iiif.io/api/image/2/context.json",
          "@id":"http://www.example.org/images/book1-page1",
          "profile":"http://iiif.io/api/image/2/profiles/level2.json"
        },
        "some_other_thing": {
          "foo" : "bar"
        },
        "seeAlso": {
          "@id": "http://www.example.org/library/catalog/book1.marc",
          "format": "application/marc"
        },
        "sequences": [
          {
            "@id":"http://www.example.org/iiif/book1/sequence/normal",
            "@type":"sc:Sequence",
            "label":"Current Page Order",

            "viewingDirection":"left-to-right",
            "viewingHint":"paged",
            "startCanvas": "http://www.example.org/iiif/book1/canvas/p2",

            "canvases": [
              {
                "@id": "http://example.com/canvas",
                "@type": "sc:Canvas",
                "width": 10,
                "height": 20,
                "label": "My Canvas",
                "otherContent": [
                  {
                    "@id": "http://example.com/content",
                    "@type":"sc:AnnotationList",
                    "motivation": "sc:painting"
                  }
                ]
              }
            ]
          }
        ]
      }')
    }
    it 'doesn\'t raise a NoMethodError when we check the keys' do
      expect { described_class.from_ordered_hash(fixture) }.to_not raise_error
    end
    it 'turns the fixture into a Manifest instance' do
      expected_klass = IIIF::Presentation::Manifest
      parsed = described_class.from_ordered_hash(fixture)
      expect(parsed.class).to be expected_klass
    end
    it 'turns keys without "@type" into an OrderedHash' do
      expected_klass = ActiveSupport::OrderedHash
      parsed = described_class.from_ordered_hash(fixture)
      expect(parsed['some_other_thing'].class).to be expected_klass
    end

    it 'turns services into Services' do
     expected_klass = IIIF::Service
      parsed = described_class.from_ordered_hash(fixture)
      expect(parsed['service'].class).to be expected_klass
    end

    it 'round-trips' do
      fp = '/tmp/osullivan-spec.json'
      parsed = described_class.from_ordered_hash(fixture)
      File.open(fp,'w') do |f|
        f.write(parsed.to_json)
      end
      from_file = IIIF::Service.parse('/tmp/osullivan-spec.json')
      File.delete(fp)
      # is this sufficient?
      expect(parsed.to_ordered_hash.to_a - from_file.to_ordered_hash.to_a).to eq []
      expect(from_file.to_ordered_hash.to_a - parsed.to_ordered_hash.to_a).to eq []
    end
    it 'turns each memeber of "sequences" into an instance of Sequence' do
      expected_klass = IIIF::Presentation::Sequence
      parsed = described_class.from_ordered_hash(fixture)
      parsed['sequences'].each do |s|
        expect(s.class).to be expected_klass
      end
    end
    it 'turns each member of sequences/canvaes in an instance of Canvas' do
      expected_klass = IIIF::Presentation::Canvas
      parsed = described_class.from_ordered_hash(fixture)
      parsed['sequences'].each do |s|
        s.canvases.each do |c|
          expect(c.class).to be expected_klass
        end
      end
    end
    it 'turns the keys into snakes' do
      expect(described_class.from_ordered_hash(fixture).has_key?('seeAlso')).to be_falsey
      expect(described_class.from_ordered_hash(fixture).has_key?('see_also')).to be_truthy
    end
    it 'copies over plain-old key-values' do
      parsed = described_class.from_ordered_hash(fixture)
      expect(parsed['label']).to eq 'My Manifest'
    end

  end

  describe '#to_ordered_hash' do
    let(:logo_uri) { 'http://www.example.org/logos/institution1.jpg' }
    let(:within_uri) { 'http://www.example.org/collections/books/' }
    let(:see_also) { 'http://www.example.org/library/catalog/book1.xml' }

    describe 'it puts the json-ld keys at the top' do
      let(:extra_props) { [ 
        ['label','foo'], 
        ['logo','http://example.com/logo.jpg'],
        ['within','http://example.com/something']
      ] }
      let(:sorted_ld_keys) { 
        subject.keys.select { |k| k.start_with?('@') }.sort!
      }
      before(:each) { 
        extra_props.reverse.each do |k,v| 
          subject.unshift(k,v) 
        end
      }

      it 'by default' do
        (0..extra_props.length-1).each do |i|
          expect(subject.keys[i]).to eq(extra_props[i][0])
        end
        oh = subject.to_ordered_hash
        (0..sorted_ld_keys.length-1).each do |i|
          expect(oh.keys[i]).to eq(sorted_ld_keys[i])
        end
      end
      it 'unless you say not to' do
        (0..extra_props.length-1).each do |i|
          expect(subject.keys[i]).to eq(extra_props[i][0])
        end
        oh = subject.to_ordered_hash(sort_json_ld_keys: false)
        (0..extra_props.length-1).each do |i|
          expect(oh.keys[i]).to eq(extra_props[i][0])
        end
      end
    end

    describe 'removes empty keys' do
      it 'if they\'re arrays' do
        subject['logo'] = logo_uri
        subject['within'] = []
        ordered_hash = subject.to_ordered_hash
        expect(ordered_hash.has_key?('within')).to be_falsey
      end
      it 'if they\'re nil' do
        subject['logo'] = logo_uri
        subject['within'] = nil
        ordered_hash = subject.to_ordered_hash
        expect(ordered_hash.has_key?('within')).to be_falsey
      end
    end

    it 'converts snake_case keys to camelCase' do
      subject['see_also'] = logo_uri
      subject['within'] = within_uri
      ordered_hash = subject.to_ordered_hash
      expect(ordered_hash.keys.include?('seeAlso')).to be_truthy
    end
  end

end
