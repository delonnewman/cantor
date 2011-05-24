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

		attr_reader :code
		attr_accessor :title, :subsets, :fields, :headers, :subtitle, :sections
	
		def initialize(superset=nil,  &block)
			@subsets  = [self]
			@sections = []

			@superset = superset
			@set      = lazy(@superset, &block)
		end

		def inspect
			"#<#{self.class.inspect}, @title=#{@title.inspect}, " +
				"@code=#{@code.inspect}, @subsets=#{@subsets.inspect}>"
		end

		def each(&block)
			@set.each(&block)
		end

		def map(&block)
			new { @set.map(&block) }
		end
	
		def get(pid)
			if @set.respond_to?(:get)
				@set.get(pid)
			else
				@set.select { |o| o.pid == pid }.first
			end
		end
		alias [] get

		def push(set)
			@subsets << set
			@sections << set
		end
		alias << push

		def subsets(*codes, &block)
			if codes && block
				@subsets = lazy { codes.map { |c| Set.new(c, &block) } }
			else
				@subsets
			end
		end

		def data
			@set
		end
	
		def where(query={}, &block)
			lazy {
				if @set.respond_to?(:all)
					Set.new { @set.all(query) }
				else
					Set.new { @set.select(&block) }
				end
			}
		end
	end
end
