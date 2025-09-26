describe IIIF::V3::Presentation::Choice do
  describe '#prohibited_keys' do
    it 'contains the expected key names' do
      keys = described_class::PAGING_PROPERTIES +
             described_class::CONTENT_RESOURCE_PROPERTIES +
             %w[
               nav_date
               viewing_direction
               start_canvas
               content_annotations
             ]
      expect(subject.prohibited_keys).to include(*keys)
    end
  end

  describe '#any_type_keys' do
    it 'default' do
      expect(subject.any_type_keys).to include('default')
    end
  end

  describe '#string_only_keys' do
    it 'choice_hint' do
      expect(subject.string_only_keys).to include('choice_hint')
    end
  end

  describe '#array_only_keys' do
    it 'items' do
      expect(subject.array_only_keys).to include('items')
    end
  end

  describe '#legal_choice_hint_values' do
    it 'contains the expected values' do
      expect(subject.legal_choice_hint_values).to contain_exactly('client', 'user')
    end
  end

  describe '#legal_viewing_hint_values' do
    it 'contains none' do
      expect(subject.legal_viewing_hint_values).to contain_exactly('none')
    end
  end

  describe '#initialize' do
    it 'sets type to Choice by default' do
      expect(subject['type']).to eq 'Choice'
    end
    it 'allows subclasses to override type' do
      subclass = Class.new(described_class) do
        def initialize(hsh = {})
          hsh = { 'type' => 'a:SubClass' }
          super(hsh)
        end
      end
      sub = subclass.new
      expect(sub['type']).to eq 'a:SubClass'
    end
    it 'allows type to be passed in' do
      my_choice = described_class.new('type' => 'bar')
      expect(my_choice.type).to eq 'bar'
    end
  end

  describe '#validate' do
    it 'raises an IllegalValueError if choice_hint isn\'t an allowable value' do
      exp_err_msg = "choiceHint for #{described_class} must be one of [\"client\", \"user\"]."
      subject['choice_hint'] = 'foo'
      expect { subject.validate }.to raise_error IIIF::V3::Presentation::IllegalValueError, exp_err_msg
    end
  end

  describe 'realistic examples' do
    describe 'from digerati' do
      let(:item_type) { 'Video' }
      let(:item1_id) { 'http://example.org/foo.mp4f' }
      let(:item1_mime) { 'video/mp4' }
      let(:item1_res) do
        IIIF::V3::Presentation::Resource.new(
          'id' => item1_id,
          'type' => item_type,
          'format' => item1_mime
        )
      end
      let(:item2_id) { 'http://example.org/foo.webm' }
      let(:item2_mime) { 'video/webm' }
      let(:item2_res) do
        IIIF::V3::Presentation::Resource.new(
          'id' => item2_id,
          'type' => item_type,
          'format' => item2_mime
        )
      end
      let(:choice) do
        IIIF::V3::Presentation::Choice.new(
          'choiceHint' => 'client',
          'items' => [item1_res, item2_res]
        )
      end
      it 'validates' do
        expect { choice.validate }.not_to raise_error
      end
      it 'has expected required values' do
        expect(choice['type']).to eq 'Choice'
      end
      it 'has expected additional values' do
        expect(choice.id).to be_nil
        expect(choice['choice_hint']).to eq 'client'
        expect(choice.choiceHint).to eq 'client'
        expect(choice['items']).to eq [item1_res, item2_res]
        first = choice['items'].first
        expect(first.keys.size).to eq 3
        expect(first['id']).to eq item1_id
        expect(first['type']).to eq item_type
        expect(first['format']).to eq item1_mime
        second = choice['items'].last
        expect(second.keys.size).to eq 3
        expect(second['id']).to eq item2_id
        expect(second['type']).to eq item_type
        expect(second['format']).to eq item2_mime
      end
    end
  end
end
