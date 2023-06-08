RSpec.describe IIIF::Service do

  let(:fixtures_dir) { File.join(File.dirname(__FILE__), '../../fixtures') }
  let(:manifest_from_spec_path) { File.join(fixtures_dir, 'manifests/complete_from_spec.json') }

  describe '.parse' do
    it 'works from a file' do
      s = described_class.parse(manifest_from_spec_path)
      expect(s['label']).to eq("en" => ["Book 1"])
    end
    it 'works from a string of JSON' do
      file = File.open(manifest_from_spec_path, 'rb')
      json_string = file.read
      file.close
      s = described_class.parse(json_string)
      expect(s['label']).to eq("en" => ["Book 1"])
    end
    describe 'works from a hash' do
      it 'plain old' do
        h = JSON.parse(IO.read(manifest_from_spec_path))
        s = described_class.parse(h)
        expect(s['label']).to eq("en" => ["Book 1"])
      end
      it 'IIIF::OrderedHash' do
        h = JSON.parse(IO.read(manifest_from_spec_path))
        oh = IIIF::OrderedHash[h]
        s = described_class.parse(oh)
        expect(s['label']).to eq("en" => ["Book 1"])
      end
    end
    it 'turns camels to snakes' do
      s = described_class.parse(manifest_from_spec_path)
      expect(s.keys.include?('see_also')).to be_truthy
      expect(s.keys.include?('seeAlso')).to be_falsey
    end
  end

  describe 'self#from_ordered_hash' do
    subject(:parsed) { described_class.from_ordered_hash(fixture) }

    let(:fixture) do
      JSON.parse(
      <<~JSON
      {
        "@context": "http://iiif.io/api/presentation/3/context.json",
        "id": "https://example.org/iiif/book1/manifest",
        "type": "Manifest",
        "label": { "en": [ "Book 1" ] },
        "metadata": [
          {
            "label": { "en": [ "Author" ] },
            "value": { "none": [ "Anne Author" ] }
          },
          {
            "label": { "en": [ "Published" ] },
            "value": {
              "en": [ "Paris, circa 1400" ],
              "fr": [ "Paris, environ 1400" ]
            }
          },
          {
            "label": { "en": [ "Notes" ] },
            "value": {
              "en": [
                "Text of note 1",
                "Text of note 2"
              ]
            }
          },
          {
            "label": { "en": [ "Source" ] },
            "value": { "none": [ "<span>From: <a href=\\"https://example.org/db/1.html\\">Some Collection</a></span>" ] }
          }
        ],
        "summary": { "en": [ "Book 1, written be Anne Author, published in Paris around 1400." ] },
      
        "thumbnail": [
          {
            "id": "https://example.org/iiif/book1/page1/full/80,100/0/default.jpg",
            "type": "Image",
            "format": "image/jpeg",
            "service": [
              {
                "id": "https://example.org/iiif/book1/page1",
                "type": "ImageService3",
                "profile": "level1"
              }
            ]
          }
        ],
      
        "viewingDirection": "right-to-left",
        "behavior": [ "paged" ],
        "navDate": "1856-01-01T00:00:00Z",
      
        "rights": "https://creativecommons.org/licenses/by/4.0/",
        "requiredStatement": {
          "label": { "en": [ "Attribution" ] },
          "value": { "en": [ "Provided by Example Organization" ] }
        },
      
        "provider": [
            {
              "id": "https://example.org/about",
              "type": "Agent",
              "label": { "en": [ "Example Organization" ] },
              "homepage": [
                {
                  "id": "https://example.org/",
                  "type": "Text",
                  "label": { "en": [ "Example Organization Homepage" ] },
                  "format": "text/html"
                }
              ],
              "logo": [
                {
                  "id": "https://example.org/service/inst1/full/max/0/default.png",
                  "type": "Image",
                  "format": "image/png",
                  "service": [
                    {
                      "id": "https://example.org/service/inst1",
                      "type": "ImageService3",
                      "profile": "level2"
                    }
                  ]
                }
              ],
              "seeAlso": [
                {
                  "id": "https://data.example.org/about/us.jsonld",
                  "type": "Dataset",
                  "format": "application/ld+json",
                  "profile": "https://schema.org/"
                }
              ]
            }
          ],
        "homepage": [
          {
            "id": "https://example.org/info/book1/",
            "type": "Text",
            "label": { "en": [ "Home page for Book 1" ] },
            "format": "text/html"
          }
        ],
        "service": [
          {
            "id": "https://example.org/service/example",
            "type": "ExampleExtensionService",
            "profile": "https://example.org/docs/example-service.html"
          }
        ],
        "seeAlso": [
          {
            "id": "https://example.org/library/catalog/book1.xml",
            "type": "Dataset",
            "format": "text/xml",
            "profile": "https://example.org/profiles/bibliographic"
          }
        ],
        "rendering": [
          {
            "id": "https://example.org/iiif/book1.pdf",
            "type": "Text",
            "label": { "en": [ "Download as PDF" ] },
            "format": "application/pdf"
          }
        ],
        "partOf": [
          {
            "id": "https://example.org/collections/books/",
            "type": "Collection"
          }
        ],
        "start": {
          "id": "https://example.org/iiif/book1/canvas/p2",
          "type": "Canvas"
        },
      
        "services": [
          {
            "@id": "https://example.org/iiif/auth/login",
            "@type": "AuthCookieService1",
            "profile": "http://iiif.io/api/auth/1/login",
            "label": "Login to Example Institution",
            "service": [
              {
                "@id": "https://example.org/iiif/auth/token",
                "@type": "AuthTokenService1",
                "profile": "http://iiif.io/api/auth/1/token"          
              }
            ]
          }
        ],
      
        "items": [
          {
            "id": "https://example.org/iiif/book1/canvas/p1",
            "type": "Canvas",
            "label": { "none": [ "p. 1" ] },
            "height": 1000,
            "width": 750,
            "items": [
              {
                "id": "https://example.org/iiif/book1/page/p1/1",
                "type": "AnnotationPage",
                "items": [
                  {
                    "id": "https://example.org/iiif/book1/annotation/p0001-image",
                    "type": "Annotation",
                    "motivation": "painting",
                    "body": {
                      "id": "https://example.org/iiif/book1/page1/full/max/0/default.jpg",
                      "type": "Image",
                      "format": "image/jpeg",
                      "service": [
                        {
                          "id": "https://example.org/iiif/book1/page1",
                          "type": "ImageService3",
                          "profile": "level2",
                          "service": [
                            {
                              "@id": "https://example.org/iiif/auth/login",
                              "@type": "AuthCookieService1"
                            }
                          ]
                        }
                      ],
                      "height": 2000,
                      "width": 1500
                    },
                    "target": "https://example.org/iiif/book1/canvas/p1"
                  }
                ]
              }
            ],
            "annotations": [
              {
                "id": "https://example.org/iiif/book1/comments/p1/1",
                "type": "AnnotationPage"
              }
            ]
          },
          {
            "id": "https://example.org/iiif/book1/canvas/p2",
            "type": "Canvas",
            "label": { "none": [ "p. 2" ] },
            "height": 1000,
            "width": 750,
            "items": [
              {
                "id": "https://example.org/iiif/book1/page/p2/1",
                "type": "AnnotationPage",
                "items": [
                  {
                    "id": "https://example.org/iiif/book1/annotation/p0002-image",
                    "type": "Annotation",
                    "motivation": "painting",
                    "body": {
                      "id": "https://example.org/iiif/book1/page2/full/max/0/default.jpg",
                      "type": "Image",
                      "format": "image/jpeg",
                      "service": [
                        {
                          "id": "https://example.org/iiif/book1/page2",
                          "type": "ImageService3",
                          "profile": "level2"
                        }
                      ],
                      "height": 2000,
                      "width": 1500
                    },
                    "target": "https://example.org/iiif/book1/canvas/p2"
                  }
                ]
              }
            ]
          }
        ],
        "structures": [
          {
            "id": "https://example.org/iiif/book1/range/r0",
            "type": "Range",
            "label": { "en": [ "Table of Contents" ] },
            "items": [
              {
                "id": "https://example.org/iiif/book1/range/r1",
                "type": "Range",
                "label": { "en": [ "Introduction" ] },
                "supplementary": {
                  "id": "https://example.org/iiif/book1/annocoll/introTexts",
                  "type": "AnnotationCollection"
                },
                "items": [
                  {
                    "id": "https://example.org/iiif/book1/canvas/p1",
                    "type": "Canvas"
                  },
                  {
                    "type": "SpecificResource",
                    "source": "https://example.org/iiif/book1/canvas/p2",
                    "selector": {
                      "type": "FragmentSelector",
                      "value": "xywh=0,0,750,300"
                    }
                  }
                ]
              }
            ]
          }
        ],
        "annotations": [
          {
            "id": "https://example.org/iiif/book1/page/manifest/1",
            "type": "AnnotationPage",
            "items": [
              {
                "id": "https://example.org/iiif/book1/page/manifest/a1",
                "type": "Annotation",
                "motivation": "commenting",
                "body": {
                  "type": "TextualBody",
                  "language": "en",
                  "value": "I love this manifest!"
                },
                "target": "https://example.org/iiif/book1/manifest"
              }
            ]
          }
        ]
      }
      JSON
      )
    end
    it 'doesn\'t raise a NoMethodError when we check the keys' do
      expect { parsed }.to_not raise_error
    end

    it 'turns the fixture into a Manifest instance' do
      expect(parsed).to be_a IIIF::Presentation::Manifest
    end

    it 'turns keys without "type" into an OrderedHash' do
      parsed = described_class.from_ordered_hash(fixture)
      expect(parsed['summary'].class).to be IIIF::OrderedHash
    end

    it 'turns services into Services' do
      expect(parsed['service']).to all be_kind_of IIIF::Presentation::Service
    end

    it 'round-trips' do
      fp = '/tmp/osullivan-spec.json'
      File.open(fp,'w') do |f|
        f.write(parsed.to_json)
      end
      from_file = IIIF::Service.parse('/tmp/osullivan-spec.json')
      File.delete(fp)
      # is this sufficient?
      expect(parsed.to_ordered_hash.to_a - from_file.to_ordered_hash.to_a).to eq []
      expect(from_file.to_ordered_hash.to_a - parsed.to_ordered_hash.to_a).to eq []
    end

    it 'turns each member of items into an instance of Canvas' do
      expect(parsed['items']).to all be_a IIIF::Presentation::Canvas
    end

    it 'turns the keys into snakes' do
      expect(parsed.has_key?('seeAlso')).to be_falsey
      expect(parsed.has_key?('see_also')).to be_truthy
    end

    it 'copies over plain-old key-values' do
      expect(parsed['rights']).to eq 'https://creativecommons.org/licenses/by/4.0/'
    end
  end

  describe '#to_ordered_hash' do
    let(:logo_uri) { 'http://www.example.org/logos/institution1.jpg' }
    let(:within_uri) { 'http://www.example.org/collections/books/' }
    let(:see_also) { 'http://www.example.org/library/catalog/book1.xml' }

    describe 'it puts the json-ld keys at the top' do
      let(:extra_props) { [ 
        ['label','foo'], 
        ['logo','http://example.com/logo.jpg'],
        ['within','http://example.com/something']
      ] }
      let(:sorted_ld_keys) { 
        subject.keys.select { |k| k.start_with?('@') }.sort!
      }
      before(:each) { 
        extra_props.reverse.each do |k,v| 
          subject.unshift(k,v) 
        end
      }

      it 'by default' do
        (0..extra_props.length-1).each do |i|
          expect(subject.keys[i]).to eq(extra_props[i][0])
        end
        oh = subject.to_ordered_hash
        (0..sorted_ld_keys.length-1).each do |i|
          expect(oh.keys[i]).to eq(sorted_ld_keys[i])
        end
      end
      it 'unless you say not to' do
        (0..extra_props.length-1).each do |i|
          expect(subject.keys[i]).to eq(extra_props[i][0])
        end
        oh = subject.to_ordered_hash(sort_json_ld_keys: false)
        (0..extra_props.length-1).each do |i|
          expect(oh.keys[i]).to eq(extra_props[i][0])
        end
      end
    end

    describe 'removes empty keys' do
      it 'if they\'re arrays' do
        subject['logo'] = logo_uri
        subject['within'] = []
        ordered_hash = subject.to_ordered_hash
        expect(ordered_hash.has_key?('within')).to be_falsey
      end
      it 'if they\'re nil' do
        subject['logo'] = logo_uri
        subject['within'] = nil
        ordered_hash = subject.to_ordered_hash
        expect(ordered_hash.has_key?('within')).to be_falsey
      end
    end

    it 'converts snake_case keys to camelCase' do
      subject['see_also'] = logo_uri
      subject['within'] = within_uri
      ordered_hash = subject.to_ordered_hash
      expect(ordered_hash.keys.include?('seeAlso')).to be_truthy
    end
  end

end
