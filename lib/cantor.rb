require File.join(File.dirname(__FILE__), 'cantor/set')

module Cantor
	VERSION = '0.0.1'
end

module Kernel
	def set(*args, &block)
		Cantor::Set.new(*args, &block)
	end
end
