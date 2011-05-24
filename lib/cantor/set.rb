require 'church'

require File.join(File.dirname(__FILE__), 'report')

module Cantor
	module ClassMethods
		def method_missing(method, *args, &block)
			if match = method.to_s.match(/^cc(\d\d\d)/i)
				Set.new(match[1], us) { |c, s| s.where(:ccode => c.code) }
			else
				us::All.send(method, *args, &block)
			end
		end

		def us
			self
		end

		def set(&block)
			Set.new(&block)
		end
	end

	def self.included(klass)
		klass.extend(Reportable::Collection)
		klass.extend(ClassMethods)
	end


	class Set
		include Enumerable
		include Reportable::Collection

		attr_accessor :subsets, :superset, :members, :fields
	
		def initialize(superset=nil, set=nil, &block)
			if !set && !block
				raise "must specify a set as an enumrable object or a block"
			end

			@set      = !!set ? lazy(self) { set } : lazy(self, &block)

			@superset = superset.add_subset(self) if superset
			@subsets  = Set.new(self, [self])
			@members  = Set.new(self, [@set, @subsets])
		end

		def inspect
			"#<#{self.class.inspect} @superset=#{@superset.inspect}
			 @set=#{@set.inspect} @subsets=#{@subsets.inspect}>"
		end

		def eval
			@set.eval
		end

		def each(&block)
			@set.each(&block)
		end

		def map(&block)
			Set.new(self) { @set.map(&block) }
		end

		def join(sep)
			@set.join(sep)
		end

		def select(*fields)
			s = Struct.new(*fields)
			map { |r| s.new(*fields.map { |f| r.send(f) }) }
		end
	
		def push(set)
			@members << set
		end
		alias << push

		def add_subset(set)
			@subsets << set
		end

		def element?(obj)
			@subsets.include?(obj) || 
				(elem = @members.map { |m| m.include?(obj) }.uniq).count == 1 && elem.first == true
		end
		alias element? include?
		alias element? member?

		def where(query={}, &block)
			if @set.respond_to?(:all)
				Set.new(self) { @set.all(query) }
			else
				Set.new(self) { @set.select(&block) }
			end
		end

		def method_missing(method, *args, &block)
			@set.send(method, *args, &block)
		end
	end
end
