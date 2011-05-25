require File.join(File.dirname(__FILE__), 'cantor/set')

module Cantor
	VERSION = '0.0.1'
end

module Kernel
	def defset(name, *args, &block)
		s = Cantor::Set.new(*args, &block)
		s.name = name
		mod = self.to_s == 'main' ? Kernel : self
		mod.const_set(name, s)
		s
	end

	def where(method=nil, &block)
		if method
			block = Proc.new { |r| r.send(method) }	
		end

		Cantor::WhereClause.new(&block)
	end
end
