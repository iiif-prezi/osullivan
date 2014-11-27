require File.join(File.dirname(__FILE__), '../../spec_helper')
require 'active_support/ordered_hash'
describe IIIF::HashBehaviours do

  let(:hash_like_class) do
    Class.new do
      include IIIF::HashBehaviours
      attr_accessor :data # Accessible for easier expects...not sure you'd do this in a real class
      def initialize()
        @data = ActiveSupport::OrderedHash.new
      end
    end
  end

  # TODO: let(:init_data)...rather than repeating so much below
  subject { hash_like_class.new }

  describe '#[]=' do
    it 'assigns a new k and value to the node' do
      subject['foo'] = 'bar'
      expect(subject.data).to eq({'foo' => 'bar'})
    end
    it 'always puts new entries at the end' do
      subject['baz'] = 'qux'
      subject['quux'] = 'corge'
      subject['grault'] = 'garply'
      expect(subject.data[subject.data.keys.last]).to eq 'garply'
    end
    it 'replaces keys that already exist in the same place' do
      subject['waldo'] = 'fred'
      subject['plugh'] = 'xyzzy'
      subject['thud'] = 'wibble'
      subject['plugh'] = 'wobble'
      expect(subject.data.select {|k,v| k == 'plugh'}).to eq({'plugh'=>'wobble'})
    end
  end

  describe '#[]' do
    it 'retrieves the expected value' do
      subject['wibble'] = 'wobble'
      subject['wubble'] = 'fred'
      expect(subject['wibble']).to eq 'wobble'
    end
    it 'returns nil if the key is not found' do
      subject['wibble'] = 'wobble'
      subject['wubble'] = 'fred'
      expect(subject['flob']).to be_nil
    end
  end

  describe '#clear' do
    it 'clears all properties' do
      subject['wibble'] = 'wobble'
      subject['wubble'] = 'fred'
      subject.clear
      expect(subject.keys).to eq []
    end
    it 'returns the instance on which it was called' do
      subject['wibble'] = 'wobble'
      subject['wubble'] = 'fred'
      expect(subject.clear).to eq subject
    end
  end

  describe '#delete' do
    it 'removes an entry from the object' do
      subject['waldo'] = 'fred'
      subject['plugh'] = 'xyzzy'
      subject.delete('waldo')
      expect(subject.data).to eq({'plugh' => 'xyzzy'})
    end
    it 'returns the value of the entry that was removed' do
      subject['waldo'] = 'fred'
      subject['plugh'] = 'xyzzy'
      expect(subject.delete('waldo')).to eq 'fred'
    end
    it 'can take a block as well' do
      subject['waldo'] = 'fred'
      subject['plugh'] = 'xyzzy'
      expect { |b| subject.delete('wubble', &b) }.to yield_with_args
      expect(subject.delete('foo') {|e| e.reverse }).to eq 'oof'
    end
  end

  describe '#delete_if' do
    it 'can take a block' do
      subject['wibble'] = 'foo'
      subject['waldo'] = 'fred'
      subject['plugh'] = 'xyzzy'
      expect { |b| subject.delete_if(&b) }.to yield_successive_args(['wibble', 'foo'], ['waldo', 'fred'], ['plugh', 'xyzzy'])
    end
    it 'returns the instance' do
      subject['wibble'] = 'foo'
      subject['waldo'] = 'fred'
      subject['plugh'] = 'xyzzy'
      expect( subject.delete_if { |k,v| k.start_with?('w') } ).to eq subject
    end
    it 'works' do
      subject['wibble'] = 'foo'
      subject['waldo'] = 'fred'
      subject['plugh'] = 'xyzzy'
      subject.delete_if { |k,v| k.start_with?('w') }
      expect(subject.data).to eq({'plugh' => 'xyzzy'})
    end
    it 'returns an enumerator if no block is supplied' do
      subject['wibble'] = 'foo'
      subject['waldo'] = 'fred'
      subject['plugh'] = 'xyzzy'
      expect(subject.delete_if).to be_a Enumerator
    end
  end

  describe '#each' do
    it 'yields' do
      subject['plugh'] = 'xyzzy'
      expect { |b| subject.each(&b) }.to yield_with_args
    end
    it 'returns the instance' do
      subject.data['waldo'] = 'fred'
      subject.data['plugh'] = 'xyzzy'
      expect(subject.each { |k,v| nil }).to eq subject
    end
    it 'loops as expected' do
      subject.data['wibble'] = 'foo'
      subject.data['waldo'] = 'fred'
      subject.data['plugh'] = 'xyzzy'
      capped_keys = []
      subject.each { |k,v| capped_keys << k.capitalize }
      expect(capped_keys).to eq ['Wibble', 'Waldo', 'Plugh']
    end
    it 'returns an enumerator if no block is supplied' do
      subject['wibble'] = 'foo'
      subject['waldo'] = 'fred'
      subject['plugh'] = 'xyzzy'
      expect(subject.delete_if).to be_a Enumerator
    end
  end

  describe '#each_key' do
    it 'yields' do
      subject['plugh'] = 'xyzzy'
      expect { |b| subject.each_key(&b) }.to yield_with_args
    end
    it 'returns the instance' do
      subject.data['waldo'] = 'fred'
      subject.data['plugh'] = 'xyzzy'
      expect(subject.each_key { |k| nil }).to eq subject
    end
    it 'loops as expected' do
      subject['wibble'] = 'foo'
      subject['waldo'] = 'fred'
      subject['plugh'] = 'xyzzy'
      key_accumulator = []
      subject.each_key { |k| key_accumulator << k }
      expect(key_accumulator).to eq ['wibble', 'waldo', 'plugh']
    end
    it 'returns an enumerator if no block is supplied' do
      subject['wibble'] = 'foo'
      subject['waldo'] = 'fred'
      subject['plugh'] = 'xyzzy'
      expect(subject.each_key).to be_a Enumerator
    end
  end

  describe '#each_value' do
    it 'yields' do
      subject['plugh'] = 'xyzzy'
      expect { |b| subject.each_value(&b) }.to yield_with_args
    end
    it 'returns the instance' do
      subject.data['waldo'] = 'fred'
      subject.data['plugh'] = 'xyzzy'
      expect(subject.each_value { |v| nil }).to eq subject
    end
    it 'loops as expected' do
      subject['wibble'] = 'foo'
      subject['waldo'] = 'fred'
      subject['plugh'] = 'xyzzy'
      value_accumulator = []
      subject.each_value { |v| value_accumulator << v }
      expect(value_accumulator).to eq ['foo', 'fred', 'xyzzy']
    end
    it 'returns an enumerator if no block is supplied' do
      subject['wibble'] = 'foo'
      subject['waldo'] = 'fred'
      subject['plugh'] = 'xyzzy'
      expect(subject.each_value).to be_a Enumerator
    end

  end

  describe '#empty' do
    it 'returns true when there are no entries' do
      expect(subject.empty?).to be_truthy
    end
    it 'returns false when we have data' do
      subject['waldo'] = 'fred'
      expect(subject.empty?).to be_falsey
    end
  end

  describe '#fetch' do
    it 'retrieves the expected value' do
      subject['wibble'] = 'wobble'
      subject['wubble'] = 'fred'
      expect(subject.fetch('wibble')).to eq 'wobble'
    end
    it 'returns the default if the key is not found and one is supplied' do
      subject['wibble'] = 'wobble'
      subject['wubble'] = 'fred'
      expect(subject.fetch('flob', 'waldo')).to eq 'waldo'
    end
    it 'raises a KeyError if the key is not found and no default is supplied' do
      expect { subject.fetch('flob') }.to raise_error KeyError
    end
    it 'can take a block as well' do
      subject['wibble'] = 'wobble'
      subject['wubble'] = 'fred'
      expect(subject.fetch('wubble') {|e| e.capitalize }).to eq 'fred' # value takes precence
      expect { |b| subject.fetch('foo', &b) }.to yield_with_args
      expect(subject.fetch('foo') {|e| e.reverse }).to eq 'oof'
    end
  end

  describe '#has_key? (and aliases)' do
    it 'is true when the key exists' do
      subject['wibble'] = 'wobble'
      expect(subject.has_key? 'wibble').to be_truthy
    end
    it 'is false when the key does not exist' do
      expect(subject.has_key? 'wibble').to be_falsey
    end
  end

  describe '#has_value? (and aliases)' do
    it 'is true when the value exists' do
      subject['wibble'] = 'wobble'
      expect(subject.has_value? 'wobble').to be_truthy
    end
    it 'is false when the value does not exist' do
      expect(subject.has_value? 'wobble').to be_falsey
    end
  end

  describe '#keep_if' do
    it 'can take a block' do
      subject['wibble'] = 'foo'
      subject['waldo'] = 'fred'
      subject['plugh'] = 'xyzzy'
      expect { |b| subject.keep_if(&b) }.to yield_successive_args(['wibble', 'foo'], ['waldo', 'fred'], ['plugh', 'xyzzy'])
    end
    it 'returns the instance' do
      subject['wibble'] = 'foo'
      subject['waldo'] = 'fred'
      subject['plugh'] = 'xyzzy'
      expect( subject.keep_if { |k,v| k.start_with?('w') } ).to eq subject
    end
    it 'works' do
      subject['wibble'] = 'foo'
      subject['waldo'] = 'fred'
      subject['plugh'] = 'xyzzy'
      subject.keep_if { |k,v| k.start_with?('w') }
      expect(subject.data).to eq({'wibble'=>'foo', 'waldo'=>'fred'})
    end
  end

  describe '#key' do
    it 'is the key associated with a value' do
      subject['thud'] = 'wibble'
      subject['plugh'] = 'wobble'
      expect(subject.key 'wibble').to eq 'thud'
      expect(subject.key 'wobble').to eq 'plugh'
    end
    it 'is nil if the value is not found' do
      subject['thud'] = 'wibble'
      subject['plugh'] = 'wobble'
      expect(subject.key 'foo').to be_nil
    end
  end

  describe '#keys' do
    it 'is an array of all of the keys in the object' do
      subject['foo'] = 'bar'
      subject['waldo'] = 'fred'
      subject['plugh'] = 'xyzzy'
      expect(subject.keys).to eq ['foo', 'waldo', 'plugh']
    end
  end

  describe '#length' do
    it 'works' do
      subject['wibble'] = 'foo'
      subject['waldo'] = 'fred'
      expect(subject.length).to eq 2
    end
  end

  describe '#merge' do
    it 'returns a new instance of the calling class' do
      subject['wibble'] = 'foo'
      another = hash_like_class.new
      another['waldo'] = 'fred'
      merged = subject.merge(another)
      # clear them all to confirm we're not testing equality of anything other
      # than that we have different instances
      subject.data.clear
      another.data.clear
      merged.data.clear
      expect(subject.merge(another).class).to eq subject.class # same class but'
      expect(merged).to_not be subject # different instance
      expect(merged).to_not be another # different instance
    end
    # it 'adds new entries to the end' do
    #   subject['wibble'] = 'foo'
    #   subject['plugh'] = 'xyzzy'
    #   another = hash_like_class.new
    #   another['waldo'] = 'fred'
    #   new_instance = subject.merge(another)
    #   expect(new_instance.data.last).to eq ['waldo', 'fred']
    # end
    it 'retains the index position for existing entries, replacing the value' do
      subject['wibble'] = 'foo'
      subject['plugh'] = 'xyzzy'
      subject['foo'] = 'bar'
      another = hash_like_class.new
      another['plugh'] = 'fred'
      new_instance = subject.merge(another)
      expect(new_instance['plugh']).to eq 'fred'
      expect(new_instance[new_instance.keys[1]]).to eq 'fred'
    end
    it 'takes a block' do
      subject['wibble'] = 'foo'
      subject['plugh'] = 'xyzzy'
      subject['foo'] = 'bar'
      another = hash_like_class.new
      another['plugh'] = 'fred'
      # e.g. give a block that turns common keys into an Array
      new_instance = subject.merge(another) { |k, old_val,new_val| [old_val, new_val] }
      expect(new_instance['wibble']).to eq 'foo'
      expect(new_instance['plugh']).to eq ['xyzzy', 'fred']
      expect(new_instance['foo']).to eq 'bar'
      expect(new_instance.data).to eq({'wibble'=>'foo', 'plugh'=>['xyzzy', 'fred'], 'foo'=>'bar'})
    end
    describe 'takes anything that implements `#each { |k,v| block }` and #has_key?' do
      it 'returns a new instance of the calling class' do
        subject['wibble'] = 'foo'
        another = {'waldo' => 'fred'}
        merged = subject.merge(another)
        # clear them all to confirm we're not testing equality of anything other
        # than that we have different instances
        subject.data.clear
        another.clear
        merged.data.clear
        expect(subject.merge(another).class).to eq subject.class # same class but'
        expect(merged).to_not be subject # different instance
        expect(merged).to_not be another # different instance
      end
      # it 'adds new entries to the end' do
      #   subject['wibble'] = 'foo'
      #   subject['plugh'] = 'xyzzy'
      #   another = {'waldo' => 'fred'}
      #   new_instance = subject.merge(another)
      #   expect(new_instance.data.last).to eq ['waldo', 'fred']
      # end
      it 'retains the index position for existing entries, replacing the value' do
        subject['wibble'] = 'foo'
        subject['plugh'] = 'xyzzy'
        subject['foo'] = 'bar'
        another = {'plugh' => 'fred' }
        another['plugh'] = 'fred'
        new_instance = subject.merge(another)
        expect(new_instance['plugh']).to eq 'fred'
        expect(new_instance[new_instance.keys[1]]).to eq 'fred'
      end
      it 'takes a block' do
        subject['wibble'] = 'foo'
        subject['plugh'] = 'xyzzy'
        subject['foo'] = 'bar'
        another = {'plugh' => 'fred'}
        # e.g. give a block that turns common keys into an Array
        new_instance = subject.merge(another) { |k, old_val,new_val| [old_val, new_val] }
        expect(new_instance['wibble']).to eq 'foo'
        expect(new_instance['plugh']).to eq ['xyzzy', 'fred']
        expect(new_instance['foo']).to eq 'bar'
        expect(new_instance.data).to eq({'wibble'=>'foo', 'plugh'=>['xyzzy', 'fred'], 'foo'=>'bar'})
      end
    end
  end

  describe '#merge!' do
    it 'returns the instance on which is was called' do
      subject['wibble'] = 'foo'
      another = hash_like_class.new
      another['waldo'] = 'fred'
      expect(subject.merge!(another)).to eq subject # same instance
    end
    it 'adds new entries to the end' do
      subject['wibble'] = 'foo'
      subject['plugh'] = 'xyzzy'
      another = hash_like_class.new
      another['waldo'] = 'fred'
      subject.merge!(another)
      expect(subject.data[subject.data.keys.last]).to eq 'fred'
    end
    it 'retains the index position for existing entries, replacing the value' do
      subject['wibble'] = 'foo'
      subject['plugh'] = 'xyzzy'
      subject['foo'] = 'bar'
      another = hash_like_class.new
      another['plugh'] = 'fred'
      subject.merge!(another)
      expect(subject['plugh']).to eq 'fred'
      expect(subject.data[subject.keys[1]]).to eq 'fred'
    end
    it 'takes a block' do
      subject['wibble'] = 'foo'
      subject['plugh'] = 'xyzzy'
      subject['foo'] = 'bar'
      another = hash_like_class.new
      another['plugh'] = 'fred'
      # e.g. give a block that turns common keys into an Array
      subject.merge!(another) { |k, old_val,new_val| [old_val, new_val] }
      expect(subject['wibble']).to eq 'foo'
      expect(subject['plugh']).to eq ['xyzzy', 'fred']
      expect(subject['foo']).to eq 'bar'
      expect(subject.data).to eq({'wibble'=>'foo', 'plugh'=>['xyzzy', 'fred'], 'foo'=>'bar'})
    end
    describe 'takes anything that implements `#each { |k,v| block }` and #has_key?' do
      it 'returns a new instance of the calling class' do
        subject['wibble'] = 'foo'
        another = {'waldo' => 'fred'}
        expect(subject.merge!(another)).to eq subject # same instance
      end
      it 'adds new entries to the end' do
        subject['wibble'] = 'foo'
        subject['plugh'] = 'xyzzy'
        another = {'waldo' => 'fred'}
        subject.merge!(another)
        expect(subject.data[subject.data.keys.last]).to eq 'fred'
      end
      it 'retains the index position for existing entries, replacing the value' do
        subject['wibble'] = 'foo'
        subject['plugh'] = 'xyzzy'
        subject['foo'] = 'bar'
        another = {'plugh' => 'fred' }
        subject.merge!(another)
        expect(subject['plugh']).to eq 'fred'
        expect(subject.data[subject.keys[1]]).to eq 'fred'
      end
      it 'takes a block' do
        subject['wibble'] = 'foo'
        subject['plugh'] = 'xyzzy'
        subject['foo'] = 'bar'
        another = {'plugh' => 'fred'}
        subject.merge!(another) { |k, old_val,new_val| "#{k}, #{old_val}, #{new_val}" }
        expect(subject['wibble']).to eq 'foo'
        expect(subject['plugh']).to eq 'plugh, xyzzy, fred'
        expect(subject['foo']).to eq 'bar'
        expect(subject.data).to eq({'wibble'=>'foo', 'plugh'=>'plugh, xyzzy, fred', 'foo'=>'bar'})
      end
    end
  end

  describe '#reject!' do
    it 'can take a block' do
      subject['wibble'] = 'foo'
      subject['waldo'] = 'fred'
      subject['plugh'] = 'xyzzy'
      expect { |b| subject.reject!(&b) }.to yield_successive_args(['wibble', 'foo'], ['waldo', 'fred'], ['plugh', 'xyzzy'])
    end
    it 'returns the instance if there were changes' do
      subject['wibble'] = 'foo'
      subject['waldo'] = 'fred'
      subject['plugh'] = 'xyzzy'
      expect( subject.reject! { |k| k.start_with?('w') } ).to be subject
    end
    it 'returns nil if there were no changes' do
      subject['wibble'] = 'foo'
      subject['waldo'] = 'fred'
      subject['plugh'] = 'xyzzy'
      expect( subject.reject! { |k| k.start_with?('X') } ).to be_nil
    end
    it 'works' do
      subject['wibble'] = 'foo'
      subject['waldo'] = 'fred'
      subject['plugh'] = 'xyzzy'
      subject.reject! { |k| k.start_with?('w') }
      expect(subject.data).to eq({'plugh' => 'xyzzy'})
    end
  end

  describe '#select' do
    it 'yields' do
      subject['thud'] = 'wibble'
      subject['plugh'] = 'wobble'
      subject['waldo'] = 'fred'
      expect { |b| subject.select(&b) }.to yield_successive_args(['thud', 'wibble'], ['plugh', 'wobble'], ['waldo', 'fred'])
    end
    it 'returns a new instance of the class' do
      subject['thud'] = 'wibble'
      subject['plugh'] = 'wobble'
      subject['waldo'] = 'fred'
      expect( subject.select{ |k,v| true }.class ).to eq subject.class
      expect( subject.select{ |k,v| true } ).to_not eq subject
    end
    it 'selects but doesn\'t delete from the original instance' do
      subject['thud'] = 'wibble'
      subject['plugh'] = 'wobble'
      subject['waldo'] = 'fred'
      expect( subject.select{ |k,v| k.include?('u') }.data ).to eq({'thud'=>'wibble', 'plugh'=>'wobble'})
      expect( subject.data ).to eq subject.data
    end
  end

  describe '#select!' do
    it 'can take a block' do
      subject['wibble'] = 'foo'
      subject['waldo'] = 'fred'
      subject['plugh'] = 'xyzzy'
      expect { |b| subject.select!(&b) }.to yield_successive_args(['wibble', 'foo'], ['waldo', 'fred'], ['plugh', 'xyzzy'])
    end
    it 'returns nil if there were no changes' do
      subject['wibble'] = 'foo'
      subject['waldo'] = 'fred'
      subject['wobble'] = 'xyzzy'
      expect( subject.select! { |k,v| k.start_with?('w') } ).to be_nil
    end
    it 'returns the instance if there were changes' do
      subject['wibble'] = 'foo'
      subject['waldo'] = 'fred'
      subject['plugh'] = 'xyzzy'
      expect( subject.select! { |k,v| k.start_with?('w') } ).to eq subject
    end
    it 'works' do
      subject['wibble'] = 'foo'
      subject['waldo'] = 'fred'
      subject['plugh'] = 'xyzzy'
      subject.select! { |k,v| k.start_with?('p') }
      expect(subject.data).to eq({'plugh' => 'xyzzy'})
    end
  end

  describe '#shift' do
    it 'returns the first element in the hash without a param' do
      subject['thud'] = 'wibble'
      subject['plugh'] = 'wobble'
      expect(subject.shift).to eq ['thud','wibble']
      expect(subject.data).to eq({'plugh' => 'wobble'})
    end
  end

  describe 'store' do
    it 'works as an alias for []=' do
      subject.store('foo', 'bar')
      expect(subject.data).to eq({'foo' => 'bar'})
    end
  end

  describe '#values' do
    it 'is an array of all of the keys in the object' do
      subject['foo'] = 'bar'
      subject['waldo'] = 'fred'
      subject['plugh'] = 'xyzzy'
      expect(subject.values).to eq ['bar', 'fred', 'xyzzy']
    end
  end

end

