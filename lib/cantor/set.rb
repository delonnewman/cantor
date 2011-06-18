require 'rubygems'
require 'church'

require File.join(File.dirname(__FILE__), 'report')

module Cantor
	class Query
		attr_reader :block

		def initialize(&block)
			@block = block
		end
	end

	class Set
		include Enumerable
		include Reportable::Collection

		attr_accessor :name
		attr_reader :superset, :subsets, :source
		@@num_sets = 0

		def initialize(*args, &block)
			@set = @superset = nil

			if !args.empty? && !block
				if args.count > 2
					@set = lazy(self) { args }
				elsif args.count == 2
					@superset = args[0]
					@set      = lazy(self) { args[1] }
				else
					if args.first.is_a?(self.class)
						@set = args.first
					else
						@set = lazy(self) { args[0] }
					end
				end
			elsif !args.empty? && !!block
				@superset = args.first
				@set      = lazy(self, &block)
			elsif args.empty? && !!block
				@set = lazy(self, &block)
			else
				#raise "must specify a set as an enumerable object or a block"
			end
			
			#	TODO: try to create a sort of namespace/symbol table
			# so sets can be named and renamed easily.	
			@subsets = { :self => self }
			@members = { } 

			@@num_sets = @@num_sets.next

			@name = :"s#{@@num_sets}"

			@superset.subset(@name => self) if @superset
		end

		def self.set_count
			@@num_sets
		end

		def inspect
			"#<#{@name} " +
			(@members.empty? ? '{}' : 
				"#{@members.keys.map { |k| "#{k}=#{@members.fetch(k).inspect}" }.join(' ')}") +
			">"
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

		def sort(&block)
			Set.new(self) { self.eval.sort(&block) }
		end

		def sort_by(method, &block)
			if block
				Set.new(self) { self.eval.sort_by(&block) }
			else
				Set.new(self) { self.eval.sort_by { |r| r.send(method) } }
			end
		end
		alias order sort_by

		def uniq
			Set.new(self) { self.eval.uniq }
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
				n = set.keys.first
				v = set[n]
				subsets[n] = if    v.is_a?(Query) then where(&v.block)
										 elsif v.is_a?(Set)   then v
										 else											Set.new(self) { v }
										 end

				self.members(n => subsets[n])

				subsets[n]
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
				@members.merge(@subsets)
			end
		end

		# TODO: add support for arrays, convert to hash with object_id for name and merge
		def add_members(members)
			@members.merge!(members)
		end
		alias << add_members

		def find_member(name)
			members[name] || (@superset ? @superset.find_member(name) : nil)
		end
		alias [] find_member

		def delete(member)
			@members[member].delete
		end

		def where(*args, &block)
			query   = nil
			method  = nil
			methods = nil
			negate  = false

			query   = args.shift if args.first.is_a?(Hash)
			method  = args.shift if args.first.is_a?(Symbol)
			methods = args.shift if args.first.is_a?(Array)
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

			if methods
				block = Proc.new { |r| methods.map { |m| r.send(m) }.include?(args.first) }
			end

			set = if @set.respond_to?(:all) && !block
							Set.new(self) { @set.all(query) }
						elsif @set.respond_to?(:all) && block
							Set.new(self) { @set.all.send(q_meth, &block) }
						else
							Set.new(self) { @set.send(q_meth, &block) }
						end

			@subsets.merge!(set.name => set)
			set
		end

		alias std_respond_to? respond_to?
		def respond_to?(meth)
			subsets.keys.include?(meth) ||
			self.find_member(meth) ||
			Enumerable.instance_methods.include?(meth) ||
			std_respond_to?(meth)
		end

		def method_missing(method, *args, &block)
			if subsets.keys.include?(method)
				subsets[method]
			elsif member = self.find_member(method)
				member
			elsif Enumerable.instance_methods.include?(method)
				self.eval.send(method, *args, &block)
			else
				self.where(method, *args, &block)
			end
		end

		private

		def member_name
			:"m_#{@members.count}"
		end
	end
end
