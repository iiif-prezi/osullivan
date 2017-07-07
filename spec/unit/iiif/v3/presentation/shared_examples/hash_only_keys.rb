shared_examples 'it has the appropriate methods for hash-only keys v3' do

  described_class.new.hash_only_keys.each do |prop|

    describe "#{prop}=" do
      it "sets #{prop}" do
        ex = {'label' => 'XYZ', 'fooBar' => 'bar'}
        subject.send("#{prop}=", ex)
        expect(subject[prop]).to eq ex
      end
      if prop.camelize(:lower) != prop
        it "is aliased as ##{prop.camelize(:lower)}=" do
          ex = [{'label' => 'XYZ'}]
          subject.send("#{prop.camelize(:lower)}=", ex)
          expect(subject[prop]).to eq ex
        end
      end
      it 'raises an exception when attempting to set it to something other than a Hash' do
        expect { subject.send("#{prop}=", ['Foo']) }.to raise_error IIIF::V3::Presentation::IllegalValueError
      end
    end

    describe "#{prop}" do
      it "gets #{prop}" do
        ex = {'label' => 'XYZ', 'fooBar' => 'bar'}
        subject[prop] = ex
        expect(subject.send(prop)).to eq ex
      end
      if prop.camelize(:lower) != prop
        it "is aliased as ##{prop.camelize(:lower)}" do
          ex = {'fooBar' => 'bar'}
          subject[prop] = ex
          expect(subject.send("#{prop.camelize(:lower)}")).to eq ex
        end
      end
    end

  end

end
