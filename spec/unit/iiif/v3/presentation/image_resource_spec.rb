describe IIIF::V3::Presentation::ImageResource do

  describe '#initialize' do
    it 'sets type to Image' do
      expect(subject['type']).to eq 'Image'
    end
  end

  describe 'realistic examples' do
    let(:img_id) { 'https://example.org/image/iiif/abc666' }
    let(:image_v2_service) {
      IIIF::V3::Presentation::Service.new(
        '@context' => 'http://iiif.io/api/image/2/context.json',
        '@id' => img_id,
        'id' => img_id,
        'profile' => 'http://iiif.io/api/image/2/level1.json'
      )
    }
    let(:img_mimetype) { 'image/jpeg' }
    let(:width) { 999 }
    let(:height) { 666 }
    describe 'stanford' do
      describe 'thumbnail per purl code' do
        let(:thumb_id) { "#{img_id}/full/!400,400/0/default.jpg" }
        let(:thumb_object) {
          thumb = IIIF::V3::Presentation::ImageResource.new
          thumb['type'] = 'Image'
          thumb['id'] = thumb_id
          thumb.format = img_mimetype
          thumb.service = [image_v2_service]
          thumb
        }
        it 'validates' do
          expect{thumb_object.validate}.not_to raise_error
        end
        it 'has expected required values' do
          expect(thumb_object.type).to eq 'Image'
          expect(thumb_object.id).to eq thumb_id
        end
        it 'has expected additional values' do
          expect(thumb_object.format).to eq img_mimetype
          expect(thumb_object.service.first).to eq image_v2_service
        end
      end
      describe 'full size per purl code' do
        let(:full_id) { "#{img_id}/full/full/0/default.jpg" }
        let(:image_object) {
          img = IIIF::V3::Presentation::ImageResource.new
          img['id'] = full_id
          img.format = img_mimetype
          img.height = height
          img.width = width
          img.service = [image_v2_service]
          img
        }
        describe 'world visible' do
          it 'validates' do
            expect{image_object.validate}.not_to raise_error
          end
          it 'has expected required values' do
            expect(image_object.type).to eq 'Image'
            expect(image_object.id).to eq full_id
          end
          it 'has expected additional values' do
            expect(image_object.format).to eq img_mimetype
            expect(image_object.height).to eq height
            expect(image_object.width).to eq width
            expect(image_object.service.first).to eq image_v2_service
          end
          it 'has expected service value' do
            img_service_obj = image_object.service.first
            expect(img_service_obj.class).to eq IIIF::V3::Presentation::Service
            expect(img_service_obj.keys.size).to eq 4
            expect(img_service_obj.id).to eq img_id
            expect(img_service_obj['@id']).to eq img_id
            expect(img_service_obj.profile).to eq IIIF::V3::Presentation::Service::IIIF_IMAGE_V2_LEVEL1_PROFILE
          end
        end
        describe 'requires login' do
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
          let(:image_object_w_login) {
            img = image_object
            img.service.first['service'] = [login_service]
            img
          }
          it 'validates' do
            expect{image_object_w_login.validate}.not_to raise_error
          end
          it 'has expected service value' do
            img_service_obj = image_object_w_login.service.first
            expect(img_service_obj.class).to eq IIIF::V3::Presentation::Service
            expect(img_service_obj.keys.size).to eq 5
            expect(img_service_obj.id).to eq img_id
            expect(img_service_obj['@id']).to eq img_id
            expect(img_service_obj.profile).to eq IIIF::V3::Presentation::Service::IIIF_IMAGE_V2_LEVEL1_PROFILE
            expect(img_service_obj.service.class).to eq Array
            expect(img_service_obj.service.size).to eq 1

            login_service_obj = img_service_obj.service.first
            expect(login_service_obj.keys.size).to eq 4
            expect(login_service.id).to eq 'https://example.org/auth/iiif'
            expect(login_service.profile).to eq IIIF::V3::Presentation::Service::IIIF_AUTHENTICATION_V1_LOGIN_PROFILE
            expect(login_service.label).to eq service_label
            expect(login_service.service.class).to eq Array
            expect(login_service.service.size).to eq 1

            token_service_obj = login_service_obj.service.first
            expect(token_service_obj['id']).to eq token_service_id
            expect(token_service_obj['profile']).to eq IIIF::V3::Presentation::Service::IIIF_AUTHENTICATION_V1_TOKEN_PROFILE
          end
        end
      end
    end
    describe 'image examples from http://prezi3.iiif.io/api/presentation/3.0' do
      let(:image_object) {
        IIIF::V3::Presentation::ImageResource.new({
          'id' => "#{img_id}/full/full/0/default.jpg",
          'type' => 'dctypes:Image',
          'format' => img_mimetype,
          'height' => height,
          'width' => width,
          'service' => image_v2_service
          })
      }
      describe 'simpler' do
        it 'validates' do
          expect{image_object.validate}.not_to raise_error
        end
        it 'has expected required values' do
          expect(image_object.id).to eq "#{img_id}/full/full/0/default.jpg"
          expect(image_object.type).to eq 'dctypes:Image'
        end
        it 'has expected additional values' do
          expect(image_object.format).to eq img_mimetype
          expect(image_object.height).to eq height
          expect(image_object.width).to eq width
          expect(image_object.service).to eq image_v2_service
        end
      end
      describe 'height and width in service' do
        # {
        #   "id": "http://example.org/images/book1-page2/full/1500,2000/0/default.jpg",
        #   "type": "dctypes:Image",
        #   "format": "image/jpeg",
        #   "height":2000,
        #   "width":1500,
        #   "service": {
        #       "@context": "http://iiif.io/api/image/2/context.json",
        #       "id": "http://example.org/images/book1-page2",
        #       "profile": "http://iiif.io/api/image/2/level1.json",
        #       "height":8000,
        #       "width":6000,
        #       "tiles": [{"width": 512, "scaleFactors": [1,2,4,8,16]}]
        #   }
        # }
        let(:img_obj) {
          img = image_object
          img.service['height'] = 6666
          img.service['width'] = 9999
          img.service['tiles'] = [{"width" => 512, "scaleFactors" => [1,2,4,8,16]}]
          img
        }
        it 'validates' do
          expect{img_obj.validate}.not_to raise_error
        end
        it 'has expected service value' do
          service_obj = img_obj.service
          expect(service_obj.class).to eq IIIF::V3::Presentation::Service
          expect(service_obj.keys.size).to eq 7
          expect(service_obj['height']).to eq 6666
          expect(service_obj['width']).to eq 9999
          expect(service_obj['tiles']).to eq [{"width" => 512, "scaleFactors" => [1,2,4,8,16]}]
        end
      end
    end
  end
end
