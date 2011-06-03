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

			@members = {:superset => @superset, :subsets => { :self => self }} 
		end

		def inspect
			"#<#{self.class.inspect} @superset=#{@superset.inspect} " +
			"@subsets=#{@subsets.inspect}>"
		end

		def eval
			if @object then @object
			else
				if (@object = @set.eval).respond_to?(:each)
					@object
				elsif !@object.respond_to?(:each) && @object.respond_to?(:all)
					# dereference ActiveRecord && DataMapper classes
					@object = @set.eval.all
				else
					raise "set should be enumerable"
				end
				@object
			end
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

		def empty?
			count == 0
		end

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
				raise "wrong arguments, expected: subset(:name => where([args]))"
			end
		end

		def add_member(name, value)
			@members[name] = value
		end
		alias []= add_member

		def members(members=nil)
			if members
				add_members(members)
			else
				@members
			end
		end

		# TODO: add support for arrays, convert to hash with object_id for name and merge
		def add_members(members)
			@members.merge(members)
		end
		alias << add_members

		def find_member(name)
			@members[name] || (superset ? superset.find_member(name) : nil)
		end
		alias [] find_member

		def where(*args, &block)
			query  = nil
			method = nil
			negate = false

			query  = args.shift if args.first.is_a?(Hash)
			method = args.shift if args.first.is_a?(Symbol)
			if args[0].is_a?(Symbol) && args[0] == :not
				args.shift
				negate = true
			end

			q_meth = negate ? :reject : :find_all

			if method
				block = if args.count > 0
									Proc.new { |r| args.any? { |arg| r.send(method) == arg } }
								else
									Proc.new { |r| r.send(method) }	
								end

			end

			if @set.respond_to?(:all) && !block
				Set.new(self) { @set.all(query) }
			elsif @set.respond_to?(:all) && block
				Set.new(self) { @set.all.send(q_meth, &block) }
			else
				Set.new(self) { @set.send(q_meth, &block) }
			end
		end

		alias std_respond_to? respond_to?
		def respond_to?(meth)
			@subsets.keys.include?(meth) ||
			self.find_member(meth) ||
			Enumerable.instance_methods.include?(meth) ||
			std_respond_to?(meth)
		end

		def method_missing(method, *args, &block)
			if (subsets = self.find_member(:subsets)).keys.include?(method)
				subsets[method]
			elsif member = self.find_member(method)
				member
			elsif Enumerable.instance_methods.include?(method)
				self.eval.send(method, *args, &block)
			else
				self.where(method, *args, &block)
			end
		end
	end
end
