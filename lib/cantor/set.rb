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
	
		def initialize(code=nil, superset=nil,  &block)
			@fields   = [ :pid, :name, :dx_date, :path_report ]
			@headers  = %w{ PID Name DX\ Date Path\ Report }
			@subsets  = [self]
			@sections = []

			@superset = superset
			@code     = CancerCode.get(code)
			@set      = lazy(@code, @superset, &block)

			if @code
				@title = "#{@code.code} - #{@code.description}, #{count} Cases"
			end
		end

		def inspect
			"#<#{self.class.inspect}, @title=#{@title.inspect}, " +
				"@code=#{@code.inspect}, @subsets=#{@subsets.inspect}>"
		end

		def subtitle
			@subtitle || @title
		end

		def each(&block)
			@set.each(&block)
		end
	
		def get(pid)
			if @set.respond_to?(:get)
				@set.get(pid)
			else
				@set.select { |o| o.pid == pid }
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
			# return @set if is AoA
			return @set if @set.respond_to?(:first) && @set.first.respond_to?(:first)
			lazy {
				@set.map { |c|
					c.get_dxs(@code.code).map { |dx|
						@fields.map { |f|
							if    f == :dx_date     then dx.date.strftime('%D')
							elsif f == :path_report then dx.path_report
							else 
								c.send(f)
							end
						}
					}
				}.fflatten(1)
			}
		end
	
		def where(query={}, &block)
			lazy {
				fields = REDUNDANT_FIELDS.mmap(:to_sym)
				if @set.respond_to?(:all)
					if query.keys.any? { |k| fields.include?(k) }
						subquery = nil
		
						fields.each do |f|
							if query.has_key?(f)
								q = (1..4).map do |i|
									@set.all(:"#{f}_#{i}" => query[f])
								end.reduce(:+)
		
								subquery = subquery ? subquery + q : q
							end
		
							query.delete(f)
						end
		
						Set.new { subquery & @set.all(query) }
					else
						Set.new { @set.all(query) }
					end
				else
					Set.new { @set.select(&block) }
				end
			}
		end
	end
end
