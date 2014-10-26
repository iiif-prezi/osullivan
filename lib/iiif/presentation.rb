Dir["#{File.join(File.dirname(__FILE__), 'presentation')}/*.rb"].each do |f| 
  require f
end

module IIIF
  module Presentation
  end
end


# ctx = 'http://foo.bar'
# m = IIIF::Presentation::Manifest.new('@context' => ctx)
# m['label'] = 'My Manifest'
# m['xyz'] = 'abc'
# # puts m.shift
# puts m.to_h
