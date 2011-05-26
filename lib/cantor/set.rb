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

	class WhereClause
		attr_reader :block

		def initialize(&block)
			@block = block
		end
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
			@object ||= @set.eval
		end

		def each(&block)
			self.eval.each(&block)
		end

		def map(&block)
			Set.new(self) { self.eval.map(&block) }
		end

		def join(sep)
			self.eval.join(sep)
		end

		alias enum_select select
		def select(*fields)
			@cache ||={}
			name = fields.to_s
			if c = @cache[name] then c
			else
				s = Struct.new(*fields)
				c = @cache[name] = map { |r| s.new(*fields.map { |f| r.send(f) }) }
				c
			end
		end

		def subset(set)
			if set.count == 1 && set.respond_to?(:keys)
				@subset = set.keys.first
				@subsets[@subset] = where(&set[@subset].block)
				@subsets[@subset]
			else
				raise "Wrong arguments"
			end
		end

		def element?(obj)
			@subsets.include?(obj) || 
				(elem = @members.map { |m| m.include?(obj) }.uniq).count == 1 && elem.first == true
		end
		alias element? include?
		alias element? member?

		def where(*args, &block)
			query  = nil
			method = nil

			query  = args.first if args.first.is_a?(Hash)
			method = args.first if args.first.is_a?(Symbol)

			if method
				block = Proc.new { |r| r.send(method) }	
				return Set.new(self) { @set.select(&block) }
			end

			if @set.respond_to?(:all) && !block
				Set.new(self) { @set.all(query) }
			else
				Set.new(self) {
					if @set.respond_to?(:enum_select)
						@set.enum_select(&block)
					else
						@set.select(&block)
					end
				}
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
