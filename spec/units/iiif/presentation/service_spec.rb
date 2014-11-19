require 'active_support/inflector'
require 'json'



describe IIIF::Presentation::Service do

  let(:fixtures_dir) { File.join(File.dirname(__FILE__), '../../../fixtures') }
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
