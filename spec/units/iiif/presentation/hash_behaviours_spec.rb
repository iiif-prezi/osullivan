describe IIIF::Presentation::HashBehaviours do
  
  let(:hash_like_class) do 
    Class.new do
      attr_accessor :data # Accessible for easier expects
      def initialize(type)
        @data = []
      end
      include IIIF::Presentation::HashBehaviours
    end
  end

  let(:init_options) { 'os:FakeHashLike' }

  subject { hash_like_class.new(init_options) }

  describe '#[]=' do
    it 'assigns a new k and value to the node' do
      subject['foo'] = 'bar'
      expect(subject['foo']).to eq 'bar'
    end
    it 'always puts new entries at the end' do
      subject['baz'] = 'qux'
      subject['quux'] = 'corge'
      subject['grault'] = 'garply'
      expect(subject.data.last).to eq ['grault', 'garply']
    end
    it 'replaces keys that already exist in the same place' do
      subject['waldo'] = 'fred'
      subject['plugh'] = 'xyzzy'
      subject['thud'] = 'wibble'
      subject['plugh'] = 'wobble'
      expect(subject.data.select {|e| e[0] == 'plugh'}[0][1]).to eq 'wobble'
    end
  end

  describe '#[]' do
    it 'retrieves the expected value' do
      subject.data << ['wibble', 'wobble']
      subject.data << ['wubble', 'fred']
      expect(subject['wibble']).to eq 'wobble'
    end
    it 'returns nil if the key is not found' do
      subject.data << ['wibble', 'wobble']
      subject.data << ['wubble', 'fred']
      expect(subject['flob']).to be_nil
    end
  end

  describe '#clear' do
    it 'clears all properties' do
      subject.data << ['wibble', 'wobble']
      subject.data << ['wubble', 'fred']
      expect(subject.clear).to eq subject
    end
  end

  describe '#delete' do
    it 'removes an entry from the object' do
      subject.data << ['waldo', 'fred']
      subject.data << ['plugh', 'xyzzy']
      subject.delete('waldo')
      expect(subject.data).to eq [['plugh', 'xyzzy']]
    end
    it 'returns the value of the entry that was removed' do
      subject.data << ['waldo', 'fred']
      subject.data << ['plugh', 'xyzzy']
      expect(subject.delete('waldo')).to eq 'fred'
    end
  end

  describe '#empty' do
    it 'returns true when there are no entries' do
      expect(subject.empty?).to be_truthy
    end
    it 'returns false when we have data' do
      subject.data << ['waldo', 'fred']
      expect(subject.empty?).to be_falsey
    end
  end

  describe '#fetch' do
    it 'retrieves the expected value' do
      subject.data << ['wibble', 'wobble']
      subject.data << ['wubble', 'fred']
      expect(subject.fetch('wibble')).to eq 'wobble'
    end
    it 'returns the default if the key is not found and one is supplied' do
      subject.data << ['wibble', 'wobble']
      subject.data << ['wubble', 'fred']
      expect(subject.fetch('flob', 'waldo')).to eq 'waldo'
    end
    it 'raises a KeyError if the key is not found and no default is supplied' do
      expect { subject.fetch('flob') }.to raise_error KeyError
    end
  end

  describe '#has_key? (and aliases)' do
    it 'is true when the key exists' do
      subject.data << ['wibble', 'wobble']
      expect(subject.has_key? 'wibble').to be_truthy
    end
    it 'is false when the key does not exist' do
      expect(subject.has_key? 'wibble').to be_falsey
    end
  end

  describe '#has_value? (and aliases)' do
    it 'is true when the value exists' do
      subject.data << ['wibble', 'wobble']
      expect(subject.has_value? 'wobble').to be_truthy
    end
    it 'is false when the value does not exist' do
      expect(subject.has_value? 'wobble').to be_falsey
    end
  end

  describe '#key' do
    it 'is the key associated with a value' do
      subject.data << ['thud', 'wibble']
      subject.data << ['plugh', 'wobble']
      expect(subject.key 'wibble').to eq 'thud'
      expect(subject.key 'wobble').to eq 'plugh'
    end
    it 'is nil if the value is not found' do
      subject.data << ['thud', 'wibble']
      subject.data << ['plugh', 'wobble']
      expect(subject.key 'foo').to be_nil
    end
  end

  describe '#keys' do
    it 'is an array of all of the keys in the object' do
      subject.data << ['foo', 'bar']
      subject.data << ['waldo', 'fred']
      subject.data << ['plugh', 'xyzzy']
      expect(subject.keys).to eq ['foo', 'waldo', 'plugh']
    end
  end

  describe '#shift' do
    it 'returns the first element in the hash without a param' do
      subject.data << ['thud', 'wibble']
      subject.data << ['plugh', 'wobble']
      expect(subject.shift).to eq ['thud','wibble']
      expect(subject.data).to eq([['plugh', 'wobble']])
    end
    it 'can remove multiple entries' do
      subject.data << ['thud', 'wibble']
      subject.data << ['plugh', 'wobble']
      subject.data << ['waldo', 'fred']
      expect(subject.shift(2)).to eq({'thud'=>'wibble', 'plugh'=>'wobble'})
      expect(subject.data).to eq([['waldo', 'fred']])
    end
  end

  describe '#unshift' do
    it 'adds an entry to the front of the object' do
      subject.data << ['wubble', 'fred']
      expect(subject.unshift('plugh', 'wobble')).to eq subject
      expect(subject.data).to eq [['plugh', 'wobble'],['wubble', 'fred']]
    end
    # TODO: more. See note in impl.
  end

  describe '#values' do
    it 'is an array of all of the keys in the object' do
      subject.data << ['foo', 'bar']
      subject.data << ['waldo', 'fred']
      subject.data << ['plugh', 'xyzzy']
      expect(subject.values).to eq ['bar', 'fred', 'xyzzy']
    end
  end

end
