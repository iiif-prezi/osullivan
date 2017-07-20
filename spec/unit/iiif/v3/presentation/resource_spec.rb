describe IIIF::V3::Presentation::Resource do
  describe '#required_keys' do
    it 'id' do
      expect(subject.required_keys).to include('id')
    end
    it 'type' do
      expect(subject.required_keys).to include('type')
    end
  end

  describe '#prohibited_keys' do
    it 'contains the expected key names' do
      keys = described_class::PAGING_PROPERTIES +
        %w{
          nav_date
          viewing_direction
          start_canvas
          content_annotations
        }
      expect(subject.prohibited_keys).to include(*keys)
    end
  end

  describe '#uri_only_keys' do
    it 'id' do
      expect(subject.uri_only_keys).to include('id')
    end
  end

  describe '#initialize' do
    it 'allows subclasses to override type' do
      subclass = Class.new(described_class) do
        def initialize(hsh={})
          hsh = { 'type' => 'a:SubClass' }
          super(hsh)
        end
      end
      sub = subclass.new
      expect(sub['type']).to eq 'a:SubClass'
    end
  end

  describe '#validate' do
    it 'raises an IllegalValueError if id is not URI' do
      subject['id'] = 'foo'
      subject['type'] = 'image/jpeg'
      exp_err_msg = "id must be an http(s) URI for #{described_class}"
      expect { subject.validate }.to raise_error(IIIF::V3::Presentation::IllegalValueError, exp_err_msg)
    end
    it 'raises an IllegalValueError if id is not http' do
      subject['id'] = 'ftp://www.example.org'
      subject['type'] = 'image/jpeg'
      exp_err_msg = "id must be an http(s) URI for #{described_class}"
      expect { subject.validate }.to raise_error(IIIF::V3::Presentation::IllegalValueError, exp_err_msg)
    end
  end

  describe 'realistic examples' do
    describe 'non-image examples from http://prezi3.iiif.io/api/presentation/3.0' do
      describe 'audio' do
        let(:file_id) { 'http://example.org/iiif/book1/res/music.mp3' }
        let(:file_type) { 'dctypes:Sound' }
        let(:file_mimetype) { 'audio/mpeg' }
        let(:resource_object) { IIIF::V3::Presentation::Resource.new({
            'id' => file_id,
            'type' => file_type,
            'format' => file_mimetype
        })}
        it 'validates' do
          expect{resource_object.validate}.not_to raise_error
        end
        it 'has expected required values' do
          expect(resource_object.id).to eq file_id
        end
        it 'has expected other values' do
          expect(resource_object.type).to eq file_type
          expect(resource_object.format).to eq file_mimetype
          expect(resource_object.service).to eq []
        end
      end
      describe 'text' do
        let(:file_id) { 'http://example.org/iiif/book1/res/tei-text-p1.xml' }
        let(:file_type) { 'dctypes:Text' }
        let(:file_mimetype) { 'application/tei+xml' }
        let(:resource_object) { IIIF::V3::Presentation::Resource.new({
            'id' => file_id,
            'type' => file_type,
            'format' => file_mimetype
        })}
        it 'validates' do
          expect{resource_object.validate}.not_to raise_error
        end
        it 'has expected required values' do
          expect(resource_object.id).to eq file_id
        end
        it 'has expected other values' do
          expect(resource_object.type).to eq file_type
          expect(resource_object.format).to eq file_mimetype
          expect(resource_object.service).to eq []
        end
      end

    end
    describe 'stanford' do
      describe 'non-image resource per purl code' do
        let(:file_id) { 'https://example.org/file/abc666/ocr.txt' }
        let(:file_type) { 'Document' }
        let(:file_mimetype) { 'text/plain' }
        let(:resource_object) {
          resource = IIIF::V3::Presentation::Resource.new
          resource['id'] = file_id
          resource['type'] = file_type
          resource.format = file_mimetype
          resource
        }
        describe 'world visible' do
          it 'validates' do
            expect{resource_object.validate}.not_to raise_error
          end
          it 'has expected required values' do
            expect(resource_object.id).to eq file_id
          end
          it 'has expected other values' do
            expect(resource_object.type).to eq file_type
            expect(resource_object.format).to eq file_mimetype
            expect(resource_object.service).to eq []
          end
        end
        describe 'requires login' do
          # let(:auth_token_service) {
          #   IIIF::V3::Presentation::Service.new({
          #     'id' => 'https://example.org/image/iiif/token',
          #     'profile' => IIIF::V3::Presentation::Service::IIIF_AUTHENTICATION_V1_TOKEN_PROFILE
          #     })}
          let(:service_label) { 'login message' }
          let(:token_service_id) { 'https://example.org/iiif/token' }
          let(:login_service) {
            IIIF::V3::Presentation::Service.new(
              'id' => 'https://example.org/auth/iiif',
              'profile' => 'http://iiif.io/api/auth/1/login',
              'label' => service_label,
              'service' => [{
                'id' => token_service_id,
                'profile' => 'http://iiif.io/api/auth/1/token'
              }]
            )
          }
          let(:resource_object_w_login) {
            resource = resource_object
            resource.service = login_service
            resource
          }
          it 'validates' do
            expect{resource_object_w_login.validate}.not_to raise_error
          end
          it 'has expected service value' do
            service_obj = resource_object_w_login.service
            expect(service_obj.class).to eq IIIF::V3::Presentation::Service
            expect(service_obj.keys.size).to eq 4
            expect(service_obj.id).to eq 'https://example.org/auth/iiif'
            expect(service_obj.profile).to eq IIIF::V3::Presentation::Service::IIIF_AUTHENTICATION_V1_LOGIN_PROFILE
            expect(service_obj.label).to eq service_label
            expect(service_obj.service.class).to eq Array
            expect(service_obj.service.size).to eq 1
            expect(service_obj.service.first.keys.size).to eq 2
            expect(service_obj.service.first['id']).to eq token_service_id
            expect(service_obj.service.first['profile']).to eq IIIF::V3::Presentation::Service::IIIF_AUTHENTICATION_V1_TOKEN_PROFILE
          end
        end
      end
    end
  end

end
