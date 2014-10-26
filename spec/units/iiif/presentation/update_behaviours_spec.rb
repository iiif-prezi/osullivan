require 'active_support/ordered_hash'
describe IIIF::Presentation::UpdateBehaviours do
  
  let(:hash_like_class) do 
    Class.new do
      include IIIF::Presentation::UpdateBehaviours
      attr_accessor :data # Accessible for easier expects
      def initialize()
        @data = ActiveSupport::OrderedHash.new
      end
    end
  end

  let (:init_data) { [ ['wubble', 'fred'], ['baz', 'qux'], ['grault','garply'] ] }

  subject do 
    h = hash_like_class.new 
    init_data.each {|e| h.data[e[0]] = e[1]}
    h
  end

  describe '#insert' do
    it 'inserts as expected' do
      subject.insert(2, 'quux', 'corge')
      expect(subject.data[subject.data.keys[0]]).to eq 'fred'
      expect(subject.data[subject.data.keys[1]]).to eq 'qux'
      expect(subject.data[subject.data.keys[2]]).to eq 'corge'
      expect(subject.data[subject.data.keys[3]]).to eq 'garply'
    end
    it 'returns the instance' do
      expect(subject.insert(1, 'quux','corge')).to eq subject
    end
    it 'raises IndexError if a negative index is too small' do
      expect { subject.insert(-5, 'quux','corge') }.to raise_error IndexError
    end
    it 'puts index -1 on the end' do
      subject.insert(-1, 'thud','wibble')
      expect(subject.data[subject.data.keys.last]).to eq 'wibble'
    end
  end

  describe '#insert_before' do
    it 'inserts in the expected place with a supplied key' do
      subject.insert_before(existing_key: 'grault', new_key: 'quux', value: 'corge')
      expect(subject.data.keys).to eq ['wubble','baz','quux','grault']
    end
    it 'inserts in the expected place with a supplied block' do
      subject.insert_before(new_key: 'quux', value: 'corge') { |k,v| k.start_with?('g') }
      expect(subject.data.keys).to eq ['wubble','baz','quux','grault']
    end
    it 'returns the instance' do
      expect(subject.insert_before(existing_key: 'grault', new_key: 'quux', value: 'corge')).to be subject
    end
    describe 'raises KeyError' do
      it 'when the supplied existing key is not found' do
        expect { subject.insert_before(existing_key: 'foo', new_key: 'quux', value: 'corge') }.to raise_error KeyError
      end
      it 'when the supplied new key already exists' do
        expect { subject.insert_before(existing_key: 'grault', new_key: 'wubble', value: 'corge') }.to raise_error KeyError
      end
    end
  end

  describe '#insert_after' do
    it 'inserts in the expected place with a supplied key' do
      subject.insert_after(existing_key: 'baz', new_key: 'quux', value: 'corge')
      expect(subject.data.keys).to eq ['wubble','baz','quux','grault']
    end
    it 'inserts in the expected place with a supplied block' do
      subject.insert_after(new_key: 'quux', value: 'corge') { |k,v| k.start_with?('g') }
      expect(subject.data.keys).to eq ['wubble','baz','quux','grault']
    end
    it 'returns the instance' do
      expect(subject.insert_after(existing_key: 'baz', new_key: 'quux', value: 'corge')).to be subject
    end
    describe 'raises KeyError' do
      it 'when the supplied existing key is not found' do
        expect { subject.insert_after(existing_key: 'foo', new_key: 'quux', value: 'corge') }.to raise_error KeyError
      end
      it 'when the supplied new key already exists' do
        expect { subject.insert_after(existing_key: 'grault', new_key: 'wubble', value: 'corge') }.to raise_error KeyError
      end
    end
  end

  describe '#unshift' do
    it 'adds an entry to the front of the object' do
      subject.unshift('thud','wibble')
      expect(subject.data[subject.data.keys[0]]).to eq 'wibble'
    end
    it 'returns the instance' do
      expect(subject.unshift('thud','wibble')).to be subject
    end
  end


end
