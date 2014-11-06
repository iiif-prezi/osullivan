Dir["#{File.join(File.dirname(__FILE__), 'presentation')}/*.rb"].each do |f|
  require f
end

module IIIF
  module Presentation
  end
end
