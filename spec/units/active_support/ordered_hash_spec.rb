describe ActiveSupport::OrderedHash do

  describe '#camelize_keys' do
    before(:each) do
      @uri = 'http://www.example.org/descriptions/book1.xml'
      @within_uri = 'http://www.example.org/collections/books/'
      subject['see_also'] = @uri
      subject['within'] = @within_uri
    end
    it 'changes snake_case keys to camelCase' do
      subject.camelize_keys # #send gets past protection
      expect(subject.keys.include?('seeAlso')).to be_truthy
      expect(subject.keys.include?('see_also')).to be_falsey
    end
    it 'keeps the right values' do
      subject.camelize_keys
      expect(subject['seeAlso']).to eq @uri
      expect(subject['within']).to eq @within_uri
    end
    it 'keeps things in the same position' do
      see_also_position = subject.keys.index('see_also')
      within_position = subject.keys.index('within')
      subject.camelize_keys
      expect(subject.keys[see_also_position]).to eq 'seeAlso'
      expect(subject.keys[within_position]).to eq 'within'
    end

  end

  describe '#snakeize_keys' do
    before(:each) do
      @uri = 'http://www.example.org/descriptions/book1.xml'
      @within_uri = 'http://www.example.org/collections/books/'
      subject['seeAlso'] = @uri
      subject['within'] = @within_uri
    end
    it 'changes camelCase keys to snake_case' do
      subject.snakeize_keys
      expect(subject.keys.include?('see_also')).to be_truthy
      expect(subject.keys.include?('seeAlso')).to be_falsey
    end
    it 'keeps the right values' do
      subject.snakeize_keys
      expect(subject['see_also']).to eq @uri
      expect(subject['within']).to eq @within_uri
    end
    it 'keeps things in the same position' do
      see_also_position = subject.keys.index('seeAlso')
      within_position = subject.keys.index('within')
      subject.snakeize_keys
      expect(subject.keys[see_also_position]).to eq 'see_also'
      expect(subject.keys[within_position]).to eq 'within'
    end
  end

  describe 'insertion patches' do

    let (:init_data) { [ ['wubble', 'fred'], ['baz', 'qux'], ['grault','garply'] ] }
    
    subject do 
      hsh = ActiveSupport::OrderedHash.new
      init_data.each { |e| hsh[e[0]] = e[1] }
      hsh
    end

    describe '#insert' do
      it 'inserts as expected' do
        subject.insert(2, 'quux', 'corge')
        expect(subject[subject.keys[0]]).to eq 'fred'
        expect(subject[subject.keys[1]]).to eq 'qux'
        expect(subject[subject.keys[2]]).to eq 'corge'
        expect(subject[subject.keys[3]]).to eq 'garply'
      end
      it 'returns the instance' do
        expect(subject.insert(1, 'quux','corge')).to eq subject
      end
      it 'raises IndexError if a negative index is too small' do
        expect { subject.insert(-5, 'quux','corge') }.to raise_error IndexError
      end
      it 'puts index -1 on the end' do
        subject.insert(-1, 'thud','wibble')
        expect(subject[subject.keys.last]).to eq 'wibble'
      end
    end

    describe '#insert_before' do
      it 'inserts in the expected place with a supplied key' do
        subject.insert_before(existing_key: 'grault', new_key: 'quux', value: 'corge')
        expect(subject.keys).to eq ['wubble','baz','quux','grault']
      end
      it 'inserts in the expected place with a supplied block' do
        subject.insert_before(new_key: 'quux', value: 'corge') { |k,v| k.start_with?('g') }
        expect(subject.keys).to eq ['wubble','baz','quux','grault']
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
        expect(subject.keys).to eq ['wubble','baz','quux','grault']
      end
      it 'inserts in the expected place with a supplied block' do
        subject.insert_after(new_key: 'quux', value: 'corge') { |k,v| k.start_with?('g') }
        expect(subject.keys).to eq ['wubble','baz','quux','grault']
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
        expect(subject[subject.keys[0]]).to eq 'wibble'
      end
      it 'returns the instance' do
        expect(subject.unshift('thud','wibble')).to be subject
      end
    end

    describe '#remove_empties' do
      it 'if they\'re arrays' do
        subject[:wubble] = []
        subject.remove_empties
        expect(subject.has_key?(:wubble)).to be_falsey
      end
      it 'if they\'re nil' do
        subject[:wubble] = nil
        subject.remove_empties
        expect(subject.has_key?(:wubble)).to be_falsey
      end
    end

  end
end

