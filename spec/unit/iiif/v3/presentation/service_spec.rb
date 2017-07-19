describe IIIF::V3::Presentation::Service do

  describe '#required_keys' do
    it '"type" is not required' do
      expect(subject.required_keys).not_to include('type')
    end
  end

  describe '#prohibited_keys' do
    it 'contains the expected key names' do
      keys = described_class::CONTENT_RESOURCE_PROPERTIES +
        described_class::PAGING_PROPERTIES +
        %w{
          nav_date
          viewing_direction
          start_canvas
          content_annotation
        }
      expect(subject.prohibited_keys).to include(*keys)
    end
  end

  describe '#uri_only_keys' do
    it '@context' do
      expect(subject.uri_only_keys).to include('@context')
    end
    it '@id' do
      expect(subject.uri_only_keys).to include('@id')
    end
    it 'id' do
      expect(subject.uri_only_keys).to include('id')
    end
  end

  let(:id_uri) { "https://example.org/image1" }

  describe '#initialize' do
    it 'assigns hash values passed in' do
      label_val = 'foo'
      inner_service_id = 'http://example.org/whatever'
      inner_service_profile = 'http://iiif.io/api/auth/1/token'
      inner_service_val = described_class.new({
        'id' => inner_service_id,
        'profile' => inner_service_profile
        })
      service_obj = described_class.new({
        '@context' => described_class::IIIF_IMAGE_V2_CONTEXT,
        'id' => id_uri,
        'profile' => described_class::IIIF_IMAGE_V2_LEVEL1_PROFILE,
        'label' => label_val,
        'service' => [inner_service_val]
      })
      expect(service_obj.keys.size).to eq 5
      expect(service_obj['id']).to eq id_uri
      expect(service_obj['@context']).to eq described_class::IIIF_IMAGE_V2_CONTEXT
      expect(service_obj['profile']).to eq described_class::IIIF_IMAGE_V2_LEVEL1_PROFILE
      expect(service_obj['label']).to eq label_val
      expect(service_obj['service'][0]['id']).to eq inner_service_id
      expect(service_obj['service'][0]['profile']).to eq inner_service_profile
    end
    it 'allows both "id" and "@id" as keys' do
      id_uri = "https://stacks.stanford.edu/image/iiif/wy534zh7137%2FSULAIR_rosette"
      service_obj = described_class.new({
        'id' => id_uri,
        '@id' => id_uri
      })
      expect(service_obj.keys.size).to eq 2
      expect(service_obj['id']).to eq id_uri
      expect(service_obj['@id']).to eq id_uri
    end
    it 'allows non-URI profile value' do
      expect{
        described_class.new({
          "profile" => [
            "http://iiif.io/api/image/2/level2.json",
            {
              "formats" => [ "gif", "pdf" ],
              "qualities" => [ "color", "gray" ],
              "supports" => [ "canonicalLinkHeader", "rotationArbitrary", "http://example.com/feature" ]
            }
          ]
        })
      }.not_to raise_error
    end
  end

  describe '#validate' do
    describe '@context = IIIF_IMAGE_API_V2_CONTEXT' do
      it 'must have a "@id"' do
        service_obj = described_class.new({
          '@context' => described_class::IIIF_IMAGE_V2_CONTEXT,
          'id' => id_uri,
          'profile' => described_class::IIIF_IMAGE_V2_LEVEL1_PROFILE
          })
        exp_err_msg = '@id is required for IIIF::V3::Presentation::Service with @context http://iiif.io/api/image/2/context.json'
        expect{service_obj.validate}.to raise_error(IIIF::V3::Presentation::MissingRequiredKeyError, exp_err_msg)
      end
      it 'must have a profile' do
        service_obj = described_class.new({
          '@context' => described_class::IIIF_IMAGE_V2_CONTEXT,
          '@id' => id_uri
          })
        exp_err_msg = 'profile is required for IIIF::V3::Presentation::Service with @context http://iiif.io/api/image/2/context.json'
        expect{service_obj.validate}.to raise_error(IIIF::V3::Presentation::MissingRequiredKeyError, exp_err_msg)
      end
      it 'must have matching values for "@id" and "id" if both are specified' do
        service_obj = described_class.new({
          '@context' => described_class::IIIF_IMAGE_V2_CONTEXT,
          '@id' => id_uri,
          'id' => "#{id_uri}/foo"
          })
        exp_err_msg = 'id and @id values must match for IIIF::V3::Presentation::Service with @context http://iiif.io/api/image/2/context.json'
        expect{service_obj.validate}.to raise_error(IIIF::V3::Presentation::IllegalValueError, exp_err_msg)
      end
    end
  end

  describe 'realistic examples' do
    describe 'from Stanford purl manifests' do
      it 'iiif image v2 service' do
        service_obj = described_class.new({
          '@context' => described_class::IIIF_IMAGE_V2_CONTEXT,
          'id' => id_uri,
          '@id' => id_uri,
          'profile' => described_class::IIIF_IMAGE_V2_LEVEL1_PROFILE
        })
        expect{service_obj.validate}.not_to raise_error
        expect(service_obj.keys.size).to eq 4
        expect(service_obj.keys).to include('@context', '@id', 'id', 'profile')
        expect(service_obj['@context']).to eq described_class::IIIF_IMAGE_V2_CONTEXT
        expect(service_obj['id']).to eq id_uri
        expect(service_obj['@id']).to eq id_uri
        expect(service_obj['profile']).to eq described_class::IIIF_IMAGE_V2_LEVEL1_PROFILE
      end
      it 'login service' do
        token_service = described_class.new({
          'id' => 'https://example.org/image/iiif/token',
          'profile' => described_class::IIIF_AUTHENTICATION_V1_TOKEN_PROFILE
        })
        expect{token_service.validate}.not_to raise_error
        expect(token_service.class).to eq described_class
        expect(token_service.keys.size).to eq 2
        expect(token_service.keys).to include('id', 'profile')
        expect(token_service['id']).to eq 'https://example.org/image/iiif/token'
        expect(token_service['profile']).to eq described_class::IIIF_AUTHENTICATION_V1_TOKEN_PROFILE
        service_obj = described_class.new(
          'id' => 'https://example.org/auth/iiif',
          'profile' => described_class::IIIF_AUTHENTICATION_V1_LOGIN_PROFILE,
          'label' => 'label value',
          'service' => [token_service]
        )
        expect{service_obj.validate}.not_to raise_error
        expect(service_obj.keys.size).to eq 4
        expect(service_obj.keys).to include('id', 'profile', 'label', 'service')
        expect(service_obj['id']).to eq 'https://example.org/auth/iiif'
        expect(service_obj['profile']).to eq described_class::IIIF_AUTHENTICATION_V1_LOGIN_PROFILE
        expect(service_obj['label']).to eq 'label value'
        inner_service = service_obj['service'][0]
        expect(inner_service.class).to eq described_class
        expect{inner_service.validate}.not_to raise_error
        expect(inner_service.keys.size).to eq 2
        expect(inner_service.keys).to include('id', 'profile')
        expect(inner_service['id']).to eq 'https://example.org/image/iiif/token'
        expect(inner_service['profile']).to eq described_class::IIIF_AUTHENTICATION_V1_TOKEN_PROFILE
      end
      it 'triply nested service' do
        inner = described_class.new({
          'id' => 'https://example.org/image/iiif/token',
          'profile' => described_class::IIIF_AUTHENTICATION_V1_TOKEN_PROFILE
          })
        expect{inner.validate}.not_to raise_error
        middle = described_class.new({
          "id" => "https://example.org/auth/iiif",
          "profile" => described_class::IIIF_AUTHENTICATION_V1_LOGIN_PROFILE,
          "label" => "Stanford-affiliated? Login to view",
          "service" => [inner]
          })
        expect{middle.validate}.not_to raise_error
        outer = described_class.new({
          "@context" => described_class::IIIF_IMAGE_V2_CONTEXT,
            "@id" => "https://example.org/iiif/yy816tv6021_img_1",
            "id" => "https://example.org/iiif/yy816tv6021_img_1",
            "profile" => described_class::IIIF_IMAGE_V2_LEVEL1_PROFILE,
            "service" => [middle]
          })
        expect{outer.validate}.not_to raise_error
      end
    end
    describe 'example from http://prezi3.iiif.io/api/presentation/3.0' do
      it 'iiif image v2' do
        service_obj = described_class.new({
          "@context" => "http://iiif.io/api/image/2/context.json",
          "id" => "http://example.org/images/book1-page2",
          "@id" => "http://example.org/images/book1-page2",
          "profile" => "http://iiif.io/api/image/2/level1.json",
          "height" => 8000,
          "width" => 6000,
          "tiles" => [{"width" => 512, "scaleFactors" => [1,2,4,8,16]}]
        })
        expect(service_obj.keys.size).to eq 7
        expect(service_obj['@context']).to eq described_class::IIIF_IMAGE_V2_CONTEXT
        expect(service_obj['id']).to eq 'http://example.org/images/book1-page2'
        expect(service_obj['@id']).to eq 'http://example.org/images/book1-page2'
        expect(service_obj['profile']).to eq described_class::IIIF_IMAGE_V2_LEVEL1_PROFILE
        expect(service_obj['height']).to eq 8000
        expect(service_obj['width']).to eq 6000
        expect(service_obj['tiles']).to eq [{"width" => 512, "scaleFactors" => [1,2,4,8,16]}]
        # TODO:  note that this won't validate because "height is a prohibited key in IIIF::V3::Presentation::Service"
        # expect{service_obj.validate}.not_to raise_error
      end
    end
  end
end
