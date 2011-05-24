require 'rubygems'
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

		attr_accessor :subsets, :superset, :members, :fields, :name
	
		def initialize(*args, &block)
			@set = @superset = nil

			if !args.empty? && !block
				if args.count > 2
					@set = lazy(self) { args }
				elsif args.count == 2
					@superset = args[0]
					@set      = lazy(self) { args[1] }
				else
					@set = lazy(self) { args[0] }
				end
			elsif !args.empty? && !!block
				@superset = args.first
				@set      = lazy(self, &block)
			elsif args.empty? && !!block
				@set = lazy(self, &block)
			else
				raise "must specify a set as an enumerable object or a block"
			end

			@subsets  = {:self => self}
		end

		def inspect
			"#<#{self.class.inspect} @superset=#{@superset.inspect} " +
			"@subsets=#{@subsets.inspect}>"
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

		alias enum_select select
		def select(*fields)
			s = Struct.new(*fields)
			map { |r| s.new(*fields.map { |f| r.send(f) }) }
		end

		def add_subset(name, set)
			@subsets[name] = set
		end
	
		def subset(name)
			if superset
				superset.add_subset(name, self)
			end
		end

		def element?(obj)
			@subsets.include?(obj) || 
				(elem = @members.map { |m| m.include?(obj) }.uniq).count == 1 && elem.first == true
		end
		alias element? include?
		alias element? member?

		def where(query={}, &block)
			if @set.respond_to?(:all) && !block
				Set.new(self) { @set.all(query) }
			else
				Set.new(self) { @set.enum_select(&block) }
			end
		end

		def method_missing(method, *args, &block)
			if @subsets.keys.include?(method)
				@subsets[method]
			else
				raise "method '#{method}' missing at #{__FILE__}:#{__LINE__}"
			end
		end
	end
end
