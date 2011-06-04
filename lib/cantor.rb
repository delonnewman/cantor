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

	def from(*args, &block)
		@set = if args.first && args.first.is_a?(Cantor::Set)
						 args.first
					 else
						 Cantor::Set.new(*args, &block)
					 end
	end
	alias set from unless respond_to?(:set)

	def where(method=nil, &block)
		if method
			block = Proc.new { |r| r.send(method) }	
		end

		Cantor::Query.new(&block)
	end

	def has(members)
		@set.members(members)
	end

	def us
		@set
	end
end
