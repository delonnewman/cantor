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

	Name = Struct.new(:value)

	class Set
		include Enumerable
		include Reportable::Collection

		attr_accessor :name
		attr_reader :superset, :subsets, :id, :source, :names
		@@num_sets = 0

		def initialize(*args, &block)
			@set = @superset = nil

			if !args.empty? && !block
				if args.count > 2
					@set = lazy(self) { args }
				elsif args.count == 2
					if args[0].is_a?(Cantor::Set) && args[1].is_a?(Hash)
						@set     = args[0]
						@members = args[1]
					else
						@superset = args[0]
						@set      = lazy(self) { args[1] }
					end
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
			
			@subsets   = { :self => self }
			@members ||= {} 
			@names     = {} # namespace

			@source = @set

			@@num_sets = @@num_sets.next

			@id = :"s#{@@num_sets}"

			@superset.subset(@id => self) if @superset
		end

		def self.count
			@@num_sets
		end

		def name=(name)
			superset.names[@id] = name if superset
			@name = name
		end

		def name
			@name || @id
		end

		def inspect
			"#<#{name} " +
			(@members.empty? ? '{}' : 
				"{ #{@members.keys.map { |k| "#{@names[k]||k}: #{@members.fetch(k).inspect}" }.join(', ')} }") +
			">"
		end

		def member_names
			@mns ||= @members.keys.map { |id| @names.fetch(id, nil) || id }
		end

		def each_member(&block)
			@members.each_pair { |id, v| block.call(id, @names.fetch(k, nil), v) }
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
			if @source
				self.eval.each(&block)
			else
				each_member(&block)
			end
		end

		def map(&block)
			Set.new { self.eval.map(&block) }
		end

		def join(sep)
			self.eval.join(sep)
		end

		def sort(&block)
			subset(:self_sorted => Set.new { self.eval.sort(&block) })
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
			subset(:self_uniq => Set.new { self.eval.uniq })
		end

		def union(enum)
			s = nil
			if enum.is_a?(Cantor::Set)
				if @source
					s = Set.new { self.eval + enum.eval }
				else
					s = Set.new
					s.members(self.members)
					s.members(enum.members)
				end
				enum.superset = s
			else
				s = Set.new { self.eval + enum }
			end

			self.superset = s
			s
		end
		alias + union

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
										 else											 Set.new(self) { v }
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

		def find_member(id)
			members[id] || (@superset ? @superset.find_member(id) : nil)
		end
		alias [] find_member

		def delete(member)
			@members.fetch(member).delete
		end

		def member?(id)
			!!find_member(id)	
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

			subset(set.name => set)
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
			if    subsets.keys.include?(method)     then subsets.fetch(method)
			elsif member = self.find_member(method) then member
			elsif @names.has_value?(method)
				self.send(@names.select { |k, v| v == method }.last.first)
			elsif Enumerable.instance_methods.include?(method)
				self.eval.send(method, *args, &block)
			elsif method.to_s.match(/=$/)
				add_members(method.to_s.gsub('=', '').to_sym => args.first)
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
