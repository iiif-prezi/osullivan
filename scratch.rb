require 'json'

module IIIF
	class AbstractPresentationType
    INITIALIZABLE_KEYS = ['@context', '@id', 'label']
    # You can initialize @context, @id, and label when constucting.
  	def initialize(hsh={})
  		@data = []
      INITIALIZABLE_KEYS.each { |i| @data << [i, hsh[i]] if hsh.has_key? i }
  	end
    # What about initializing with an ActiveSupport::OrderedHash or 2d array?




  	# push, pop, shift, unshift, insert ... What does Ruby name these?
    # delete?
  	# has_key? or whatever? Other common Hash methods?
  end

  class Manifest < AbstractPresentationType



  end

end



ctx = 'http://foo.bar'
m = IIIF::Manifest.new('@context' => ctx)
m['label'] = 'My Manifest'
m['xyz'] = 'abc'
puts m.shift

