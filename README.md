# O'Sullivan: A Ruby API for working with IIIF Presentation manifests

[![Coverage Status](https://coveralls.io/repos/github/iiif-prezi/osullivan/badge.svg?branch=development)](https://coveralls.io/github/iiif-prezi/osullivan?branch=development)
[![Gem Version](https://badge.fury.io/rb/iiif-presentation.svg)](https://badge.fury.io/rb/iiif-presentation)


## Installation

From the source code do `rake install`, or get the latest release [from RubyGems](https://rubygems.org/gems/iiif-presentation).

## Building New Objects

There is (or will be) a class for all types in [IIIF Presentation API Spec v3.0](http://iiif.io/api/presentation/3.0/).




```ruby
require 'iiif/presentation'

seed = {
    'id' => 'http://example.com/manifest',
    'label' => 'My Manifest'
}
# Any options you add are added to the object
manifest = IIIF::Presentation::Manifest.new(seed)

# sequences array is generated for you, but let's add a sequence object
sequence = IIIF::Presentation::Sequence.new()
sequence['@id'] = "http://example.com/manifest/seq/"
manifest.sequences << sequence

canvas = IIIF::Presentation::Canvas.new()
# All classes act like `ActiveSupport::OrderedHash`es, for the most part.
# Use `[]=` to set JSON-LD properties...
canvas.id = 'http://example.com/canvas'
# ...but there are also accessors and mutators for the properties mentioned in 
# the spec
canvas.width = 10
canvas.height = 20
canvas.label = 'My Canvas'

# Add images 
service = IIIF::Presentation::Resource.new('@context' => 'http://iiif.io/api/image/3/context.json', 'profile' => 'http://iiif.io/api/image/2/level2.json', 'id' => "http://images.exampl.com/loris2/my-image")

image = IIIF::Presentation::ImageResource.new
i.id = "http://images.exampl.com/loris2/my-image/full/#{canvas.width},#{canvas.height}/0/default.jpg"
i.format = "image/jpeg"
i.width = canvas.width
i.height = canvas.height
i.service = service

annotation = IIIF::Presentation::Annotation.new('type' => 'Annotation', 'motivation' => 'painting', 'id' => "#{canvas.id}/images", 'resource' => i)

annotation_page = IIIF::Presentation::AnnotationPage.new()
annotation_page.items << annotation
canvas.items << annoation_page

# Add other content resources
oc = IIIF::Presentation::Resource.new('@id' => 'http://example.com/content')
canvas.other_content << oc

manifest.canvases << canvas

puts manifest.to_json(pretty: true)
```

Methods are generated dynamically, which means `#methods` is your friend:

```ruby
manifest = IIIF::Presentation::Manifest.new()
puts manifest.methods(false)
> label=
> label
> description=
> description
> thumbnail=
> thumbnail
> attribution=
> attribution
> viewing_hint=
> viewingHint=
> viewing_hint
> viewingHint
[...]
```

Note that multi-word properties are implemented as snake_case (because this is
Ruby), but is serialized as camelCase. There are camelCase aliases for these.

```ruby
manifest = IIIF::Presentation::Manifest.new()
manifest.viewing_hint = 'paged'
puts manifest.to_json(pretty: true, force: true) # force: true skips validations

> {
>   "@context": "http://iiif.io/api/presentation/3/context.json",
>   "type": "Manifest",
>   "viewingHint": "paged"
> }

```

## Parsing Existing Objects

Use `IIIF::Service#parse`. It will figure out what the object
should be, based on `type`, and fall back to `Hash` when
it can't e.g.:

```ruby
seed = '{
  "@context": "http://iiif.io/api/presentation/3/context.json",
  "id": "http://example.com/manifest",
  "type": "Manifest",
  "label": "My Manifest",
  "service": {
    "@context": "http://iiif.io/api/image/2/context.json",
    "id":"http://www.example.org/images/book1-page1",
    "profile":"http://iiif.io/api/image/2/profiles/level2.json"
  },
  "seeAlso": {
    "id": "http://www.example.org/library/catalog/book1.marc",
    "format": "application/marc"
  },
  "items": [
    {
      "id": "http://example.com/canvas",
      "type": "Canvas",
      "width": 10,
      "height": 20,
      "label": "My Canvas",
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
      ]
    }
  ]
}'


obj = IIIF::Service.parse(seed) # can also be a file path or a Hash
puts obj.class
puts obj.see_also.class

> IIIF::Presentation::Manifest
> Hash
```

## Validation and Exceptions

This is work in progress. Right now exceptions are generally raised when you 
try to set something to a type it should never be:

```ruby
manifest = IIIF::Presentation::Manifest.new
manifest.items = 'quux'

> [...] items must be an Array. (IIIF::Presentation::IllegalValueError)
```

and also if any required properties are missing when calling `to_json`

```ruby
canvas = IIIF::Presentation::Canvas.new('id' => 'http://example.com/canvas')
puts canvas.to_json(pretty: true)

> A(n) width is required for each IIIF::Presentation::Canvas (IIIF::Presentation::MissingRequiredKeyError)
```

but you can skip this validation by adding `force: true`:

```ruby
canvas = IIIF::Presentation::Canvas.new('id' => 'http://example.com/canvas')
puts canvas.to_json(pretty: true, force: true)

> {
>   "@context": "http://iiif.io/api/presentation/3/context.json",
>   "id": "http://example.com/canvas",
>   "type": "Canvas"
> }
```
This all needs a bit of tidying up, finishing, and refactoring, so expect it to 
change.
