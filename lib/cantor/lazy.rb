module Kernel
	def lazy(*args, &block)
		LazyObject.new(*args, &block)
	end
end

class BasicObject
  instance_methods.each do |m|
    undef_method(m) if m.to_s !~ /(?:^__|^nil?$|^send$|^object_id$)/
  end
end

class LazyObject < BasicObject
	def initialize(*args, &block)
		@args  = args
		@block = block
	end

	def inspect
		@object ? @object.inspect : "#<LazyObject @args=#{@args.inspect} @block=#{@block.inspect}>"
	end

	def method_missing(method, *args, &block)
		(@object ||= @block.call(*@args)).send(method, *args, &block)
	end
end
