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

      def prohibited_keys
        super + %w{ verboten }
      end

      def legal_viewing_hint_values
        %w{ viewing_hint1 viewing_hint2 }
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
    it 'raises ProhibitedKeyError if prohibited key is present' do
      subject['verboten'] = 666
      exp_err_msg = "verboten is a prohibited key in #{subject.class}"
      expect { subject.validate }.to raise_error(IIIF::V3::Presentation::ProhibitedKeyError, exp_err_msg)
    end
    it 'raises IllegalValueError for bad viewing_direction' do
      subject['viewing_direction'] = 'foo'
      exp_err_msg = "viewingDirection must be one of #{subject.legal_viewing_direction_values}"
      expect { subject.validate }.to raise_error(IIIF::V3::Presentation::IllegalValueError, exp_err_msg)
    end
    describe 'viewing_hint' do
      it 'can be a uri' do
        subject['viewing_hint'] = 'https://example.org/viewiing_hint'
        expect { subject.validate }.not_to raise_error
      end
      it 'can be a member of legal_viewing_hint_values' do
        subject['viewing_hint'] = subject.legal_viewing_hint_values.first
        expect { subject.validate }.not_to raise_error
      end
      it 'raises IllegalValueError for bad viewing_hint' do
        subject['viewing_hint'] = 'foo'
        exp_err_msg = "viewingHint for #{subject.class} must be one or more of #{subject.legal_viewing_hint_values} or a URI"
        expect { subject.validate }.to raise_error(IIIF::V3::Presentation::IllegalValueError, exp_err_msg)
      end
      it 'can have multiple values' do
        subject['viewing_hint'] = [subject.legal_viewing_hint_values.first, subject.legal_viewing_hint_values.last]
        expect { subject.validate }.not_to raise_error
      end
    end
    describe 'metadata' do
      it 'raises IllegalValueError for entry that is not a Hash' do
        subject['metadata'] = ['error']
        exp_err_msg = "metadata must be an Array with Hash members"
        expect { subject.validate }.to raise_error(IIIF::V3::Presentation::IllegalValueError, exp_err_msg)
      end
      it 'does not raise error for entry that contains exactly "label" and "value"' do
        subject['metadata'] = [{ 'label' => 'bar', 'value' => 'foo' }]
        expect { subject.validate }.not_to raise_error
      end
      it 'raises IllegalValueError for entry that does not contain exactly "label" and "value"' do
        subject['metadata'] = [{ 'label' => 'bar', 'bar' => 'foo' }]
        exp_err_msg = "metadata members must be a Hash of keys 'label' and 'value'"
        expect { subject.validate }.to raise_error(IIIF::V3::Presentation::IllegalValueError, exp_err_msg)
      end
    end
    describe 'thumbnail' do
      it 'raises IllegalValueError for entry that is not a Hash' do
        subject['thumbnail'] = ['error']
        exp_err_msg = "thumbnail must be an Array with Hash members"
        expect { subject.validate }.to raise_error(IIIF::V3::Presentation::IllegalValueError, exp_err_msg)
      end
      it 'does not raise error for entry with "id" and "type"' do
        subject['thumbnail'] = [{ 'id' => 'bar', 'type' => 'foo', 'random' => 'xxx' }]
        expect { subject.validate }.not_to raise_error
      end
      it 'raises IllegalValueError for entry that does not contain "id" and "type"' do
        subject['thumbnail'] = [{ 'id' => 'bar' }]
        exp_err_msg = 'thumbnail members must be a Hash including keys "id" and "type"'
        expect { subject.validate }.to raise_error(IIIF::V3::Presentation::IllegalValueError, exp_err_msg)
      end
    end
    describe 'nav_date' do
      it 'does not raise error for value of form YYYY-MM-DDThh:mm:ssZ' do
        subject['nav_date'] = '1991-01-02T13:04:27Z'
        expect { subject.validate }.not_to raise_error
      end
      it 'raises IllegalValueError for value not of form YYYY-MM-DDThh:mm:ssZ' do
        subject['nav_date'] = '1991-01-02T13:04:27+0500'
        exp_err_msg = 'nav_date must be of form YYYY-MM-DDThh:mm:ssZ'
        expect { subject.validate }.to raise_error(IIIF::V3::Presentation::IllegalValueError, exp_err_msg)
      end
    end
    describe 'rights' do
      it 'raises IllegalValueError for entry that is not a Hash' do
        subject['rights'] = ['error']
        exp_err_msg = "rights must be an Array with Hash members"
        expect { subject.validate }.to raise_error(IIIF::V3::Presentation::IllegalValueError, exp_err_msg)
      end
      it 'does not raise error for entry with "id" that is URI' do
        subject['rights'] = [{ 'id' => 'http://example.org/rights', 'format' => 'text/html' }]
        expect { subject.validate }.not_to raise_error
      end
      it 'raises IllegalValueError for entry with "id" that is not URI' do
        subject['rights'] = [{ 'id' => 'bar', 'format' => 'text/html' }]
        exp_err_msg = "id value must be a String containing a URI"
        expect { subject.validate }.to raise_error(IIIF::V3::Presentation::IllegalValueError, exp_err_msg)
      end
      it 'raises IllegalValueError for entry that does not contain "id"' do
        subject['rights'] = [{ 'whoops' => 'http://example.org/rights' }]
        exp_err_msg = 'rights members must be a Hash including "id"'
        expect { subject.validate }.to raise_error(IIIF::V3::Presentation::IllegalValueError, exp_err_msg)
      end
    end
    describe 'rendering' do
      it 'raises IllegalValueError for entry that is not a Hash' do
        subject['rendering'] = ['error']
        exp_err_msg = "rendering must be an Array with Hash members"
        expect { subject.validate }.to raise_error(IIIF::V3::Presentation::IllegalValueError, exp_err_msg)
      end
      it 'does not raise error for entry with "label" and "format"' do
        subject['rendering'] = [{ 'label' => 'bar', 'format' => 'foo', 'random' => 'xxx' }]
        expect { subject.validate }.not_to raise_error
      end
      it 'raises IllegalValueError for entry that does not contain "label" and "format"' do
        subject['rendering'] = [{ 'label' => 'bar' }]
        exp_err_msg = 'rendering members must be a Hash including keys "label" and "format"'
        expect { subject.validate }.to raise_error(IIIF::V3::Presentation::IllegalValueError, exp_err_msg)
      end
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
