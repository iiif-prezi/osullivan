class AbstractResourceSubClass < IIIF::V3::AbstractResource
  TYPE = 'Ignore'
  # need a property here for type of key not already initialized in AbstractResource
  def array_only_keys
    super + %w[array my_array]
  end

  def hash_only_keys
    super + %w[hash my_hash]
  end

  def int_only_keys
    super + %w[int my_int]
  end

  def numeric_only_keys
    super + %w[num my_num]
  end

  def uri_only_keys
    super + %w[uri my_uri]
  end

  def initialize(hsh = {})
    hsh = { 'type' => 'a:SubClass' }
    super(hsh)
  end
end

describe AbstractResourceSubClass do
  describe "*define_methods_for_any_type_keys" do
    # shared_example expects fixed_values;  these are roughly based on Stanford purl code
    # (see https://github.com/sul-dlss/purl/blob/master/app/models/iiif3_presentation_manifest.rb)
    let(:fixed_values) do
      {
        'label' => 'foo',
        'description' => 'bar',
        'thumbnail' => IIIF::V3::Presentation::ImageResource.new(
          'type' => 'Image',
          'id' => "http://example.org/full/!400,400/0/default.jpg",
          'format' => 'image/jpeg'
        ),
        'attribution' => ['foo'],
        'logo' => {
          'id' => 'https://example.org/default.jpg',
          'service' => IIIF::V3::Presentation::Service.new(
            '@context' => 'http://iiif.io/api/image/2/context.json',
            '@id' => 'http://example.org/1',
            'id' => 'http://example.org/1',
            'profile' => 'http://example.org/whatever'
          )
        },
        'see_also' => {
          'id' => 'http://example.org/whatever',
          'format' => 'application/mods+xml'
        },
        'related' => %w[no idea],
        'within' => { 'foo' => 'bar' }
      }
    end
    it_behaves_like 'it has the appropriate methods for any-type keys v3'
  end
  describe "*define_methods_for_array_only_keys" do
    it_behaves_like 'it has the appropriate methods for array-only keys v3'
  end
  describe "*define_methods_for_hash_only_keys" do
    it_behaves_like 'it has the appropriate methods for hash-only keys v3'
  end
  describe "*define_methods_for_int_only_keys" do
    it_behaves_like 'it has the appropriate methods for integer-only keys v3'
  end
  describe "*define_methods_for_numeric_only_keys" do
    it_behaves_like 'it has the appropriate methods for numeric-only keys v3'
  end
  describe "*define_methods_for_string_only_keys" do
    it_behaves_like 'it has the appropriate methods for string-only keys v3'
  end
  describe "*define_methods_for_uri_only_keys" do
    it_behaves_like 'it has the appropriate methods for uri-only keys v3'
  end
end
