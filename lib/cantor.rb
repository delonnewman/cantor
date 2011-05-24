require File.join(File.dirname(__FILE__), 'cantor/set')

module Cantor
	VERSION = '0.0.1'
end

module Kernel
	def defset(name, *args, &block)
		s = Cantor::Set.new(*args, &block)
		s.name = name
		self.const_set(name, s)
		s
	end
end
