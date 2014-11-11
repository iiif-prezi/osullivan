describe IIIF::Presentation::Canvas do

  let(:fixed_values) do
    {
      "@context" => "http://iiif.io/api/presentation/2/context.json",
      "@id" => "http://www.example.org/iiif/book1/canvas/p1",
      "@type" => "sc:Canvas",
      "label" => "p. 1",
      "height" => 1000,
      "width" => 750,
      "images" =>  [ ],
      "otherContent" =>  [ ]
    }
  end


  describe '#initialize' do
    it 'sets @type' do
      expect(subject['@type']).to eq 'sc:Canvas'
    end
  end

  describe 'Integer only key accessor and mutators' do
    IIIF::Presentation::Canvas.new.int_only_keys.each do |prop|
      describe "#{prop}=" do
        before(:all) do
          @ex = 7200
        end
        it "sets #{prop}" do
          subject.send("#{prop}=", @ex)
          expect(subject[prop]).to eq @ex
        end
        if prop.camelize(:lower) != prop
          it "is aliased as ##{prop.camelize(:lower)}=" do
            subject.send("#{prop.camelize(:lower)}=", @ex)
            expect(subject[prop]).to eq @ex
          end
        end
        it 'raises an exception when attempting to set it to something other than an Integer' do
          expect { subject.send("#{prop}=", 'Foo') }.to raise_error IIIF::Presentation::IllegalValueError
        end
        it 'raises an exception when attempting to set it to a negative number' do
          expect { subject.send("#{prop}=", -1) }.to raise_error IIIF::Presentation::IllegalValueError
        end
      end
      describe "#{prop}" do
        before(:all) do
          @ex = 7200
        end
        it "gets #{prop}" do
          subject[prop] = @ex
          expect(subject.send(prop)).to eq @ex
        end
        if prop.camelize(:lower) != prop
          it "is aliased as ##{prop.camelize(:lower)}" do
            subject[prop] = @ex
            expect(subject.send("#{prop.camelize(:lower)}")).to eq @ex
          end
        end
      end
    end
  end


end

