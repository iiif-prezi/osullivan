require 'active_support/inflector'
require 'json'
require_relative '../../../../lib/iiif/hash_behaviours'

describe IIIF::V3::AbstractResource do

  let(:fixtures_dir) { File.join(File.dirname(__FILE__), '../../../fixtures') }
  let(:manifest_from_spec_path) { File.join(fixtures_dir, 'v3/manifests/complete_from_spec.json') }
  let(:abstract_resource_subclass) do
    Class.new(IIIF::V3::AbstractResource) do
      include IIIF::HashBehaviours

      def initialize(hsh={})
        hsh['type'] = 'a:SubClass' unless hsh.has_key?('type')
        super(hsh)
      end

      def required_keys
        super + %w{ id }
      end
    end
  end
  subject do
    instance = abstract_resource_subclass.new
    instance['id'] = 'http://example.com/prefix/manifest/123'
    instance
  end

  describe '#required_keys' do
    it 'accumulate' do
      expect(subject.required_keys).to eq %w{ type id }
    end
  end

  describe '#initialize' do
    it 'raises an error if you try to instantiate AbstractResource' do
      expect { IIIF::V3::AbstractResource.new }.to raise_error(RuntimeError)
    end
    it 'sets type' do
      expect(subject['type']).to eq 'a:SubClass'
    end
    it 'can take any old hash' do
      hsh = JSON.parse(IO.read(manifest_from_spec_path))
      new_instance = abstract_resource_subclass.new(hsh)
      expect(new_instance['label']).to eq 'Book 1'
    end
  end

  describe '#validate' do
    it 'raises MissingRequiredKeyError if required key is missing' do
      subject.required_keys.each { |k| subject.delete(k) }
      expect { subject.validate }.to raise_error IIIF::V3::Presentation::MissingRequiredKeyError
    end
    it 'raises IllegalValueError for bad viewing_direction' do
      subject['viewing_direction'] = 'foo'
      exp_err_msg = "viewingDirection must be one of #{subject.legal_viewing_direction_values}"
      expect { subject.validate }.to raise_error(IIIF::V3::Presentation::IllegalValueError, exp_err_msg)
    end
    it 'raises IllegalValueError for bad viewing_hint' do
      subject['viewing_hint'] = 'foo'
      exp_err_msg = "viewingHint for #{subject.class} must be one of #{subject.legal_viewing_hint_values}"
      expect { subject.validate }.to raise_error(IIIF::V3::Presentation::IllegalValueError, exp_err_msg)
    end
    it 'raises IllegalValueError for metadata entry that is not a Hash' do
      subject['metadata'] = [{ 'foo' => 'bar' }, 'error', { 'bar' => 'foo' }]
      exp_err_msg = "All entries in the metadata list must be a type of Hash"
      expect { subject.validate }.to raise_error(IIIF::V3::Presentation::IllegalValueError, exp_err_msg)
    end
  end

  describe 'A nested object (e.g. self[\'metadata\'])' do
    it 'returns [] if not set' do
      expect(subject.metadata).to eq([])
    end
    it 'is not in #to_ordered_hash at all if we access it but do not append to it' do
      subject.metadata # touch it
      expect(subject.metadata).to eq([])
      expect(subject.to_ordered_hash.has_key?('metadata')).to be_falsey
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
        f.write(subject.to_json)
      end
      parsed = subject.class.parse('/tmp/osullivan-spec.json')
      expect(parsed['metadata'][0]['label']).to eq('Author')
      expect(parsed['metadata'][1]['value'].length).to eq(2)
      expect(parsed['metadata'][1]['value'].select { |e| e['@language'] == 'fr'}.last['@value']).to eq('Paris, environ 14eme siecle')
      File.delete('/tmp/osullivan-spec.json')
    end
  end

  describe '#to_ordered_hash' do
    describe 'adds the @context' do
      before(:each) { subject.delete('@context') }
      it 'by default' do
        expect(subject.has_key?('@context')).to be_falsey
        expect(subject.to_ordered_hash.has_key?('@context')).to be_truthy
      end
      it 'unless you say not to' do
        expect(subject.has_key?('@context')).to be_falsey
        expect(subject.to_ordered_hash(include_context: false).has_key?('@context')).to be_falsey
      end
      it 'or it\'s already there' do
        different_ctxt = 'http://example.org/context'
        subject['@context'] = different_ctxt
        oh = subject.to_ordered_hash
        expect(oh['@context']).to eq different_ctxt
      end
    end

    describe 'runs the validations' do
      let(:error) { IIIF::V3::Presentation::MissingRequiredKeyError }
      before(:each) { subject.delete('id') }
      it 'raises exceptions' do
        expect { subject.to_ordered_hash }.to raise_error error
      end
      it 'unless you tell it not to' do
        expect { subject.to_ordered_hash(force: true) }.to_not raise_error
      end
    end
  end

  describe '*get_descendant_class_by_jld_type' do
    before do
      class DummyClass < IIIF::V3::AbstractResource
        TYPE = "Collection"
        def self.singleton_class?
          true
        end
      end
    end
    after do
      Object.send(:remove_const, :DummyClass)
    end
    it 'gets the right class' do
      klass = described_class.get_descendant_class_by_jld_type('Canvas')
      expect(klass).to eq IIIF::V3::Presentation::Canvas
    end
    context "when there are singleton classes which are returned" do
      it "gets the right class" do
        allow(IIIF::V3::AbstractResource).to receive(:descendants).and_return([DummyClass, IIIF::V3::Presentation::Collection])
        klass = described_class.get_descendant_class_by_jld_type('Collection')
        expect(klass).to eq IIIF::V3::Presentation::Collection
      end
    end
  end

end
