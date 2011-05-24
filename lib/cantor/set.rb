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

		attr_accessor :title, :subsets, :fields, :headers, :subtitle, :sections
	
		def initialize(superset=nil,  &block)
			@subsets  = [self]

			@superset = superset
			@set      = lazy(@superset, &block)
		end

		def inspect
			"#<#{self.class.inspect} @superset=#{@superset.inspect} @subsets=#{@subsets.inspect}>"
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
			@subsets << set
		end
		alias << push

		def where(query={}, &block)
			lazy {
				if @set.respond_to?(:all)
					Set.new(self) { @set.all(query) }
				else
					Set.new(self) { @set.select(&block) }
				end
			}
		end
	end
end
