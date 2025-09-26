shared_examples 'it has the appropriate methods for uri-only keys v3' do
  described_class.new.uri_only_keys.each do |prop|
    describe "#{prop}=" do
      it "sets #{prop}" do
        ex = 'http://example.org/foo'
        subject.send("#{prop}=", ex)
        expect(subject[prop]).to eq ex
      end
      it 'raises an exception when attempting to set it to something other than a String' do
        expect { subject.send("#{prop}=", ['Foo']) }.to raise_error IIIF::V3::Presentation::IllegalValueError
        expect { subject.send("#{prop}=", nil) }.to raise_error IIIF::V3::Presentation::IllegalValueError
      end
      it 'raises an exception when attempting to set it to something other than a parseable URI' do
        expect { subject.send("#{prop}=", 'Not a URI') }.to raise_error IIIF::V3::Presentation::IllegalValueError
        expect { subject.send("#{prop}=", '') }.to raise_error IIIF::V3::Presentation::IllegalValueError
      end
    end

    describe "#{prop}" do
      it "gets #{prop}" do
        ex = 'bar'
        subject[prop] = ex
        expect(subject.send(prop)).to eq ex
      end
    end
  end
end
