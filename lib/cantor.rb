require File.expand_path(File.join(File.dirname(__FILE__), 'cantor/set'))

module Kernel
	def defset(name, &block)
		block.call || raise("must define set with block")
		raise "must define set with 'from'" unless @set
		@set[:name] = name
		mod = self.to_s == 'main' ? Kernel : self
		mod.const_set(name, @set)
		@set
	end

	def set(*args, &block)
		Cantor::Set.new(*args, &block)
	end
	alias from set

	def where(method=nil, &block)
		if method
			block = Proc.new { |r| r.send(method) }	
		end

		Cantor::Query.new(&block)
	end

	def has(member)
		@set.members.merge!(member)
	end

	def from(enum, &block)
		@set = set(enum, &block)
	end

	def us
		@set
	end
end
