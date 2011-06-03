require 'prawn'
require 'prawn/layout'
require 'fastercsv'
require 'yaml'

require 'church'


module Reportable
	class Report
		attr_accessor :fields, :headers

		def initialize(obj, args={}, &block)
			@other   = obj
			@block   = block
			@args    = args
			@fields  = args[:fields]
			@headers = args[:headers] || (obj.respond_to?(:headers) ? obj.headers : nil)

			if not @block.nil?
				@block.call(self, obj)
			end

			if !@fields && @other.respond_to?(:fields)
				@fields = @other.fields
			elsif @fields.nil? || @fields.empty?
				raise "fields: '#{@fields.inspect}' cannot be nil or empty"
			elsif @fields.count == 1 && @fields.first.respond_to?(:keys)
				fields   = @fields.first.keys
				@headers = fields.map { |f| @fields.first[f] }
				@fields  = fields
			else
				@fields = args[:fields]
			end

			@headers = @fields.map { |f| f.to_s.upcase.gsub('_', ' ') } unless @headers
		end

		def count
			headers? ? data.count - 1 : data.count
		end

		def headers?
			@headers && !@headers.empty?
		end

		def data?
			not data.empty?
		end

		def data
			if @data then @data
			else
				@data = []
				@data << @headers if headers?
	
				if @other.respond_to?(:us) || @other.respond_to?(:map)
					@other = @other.respond_to?(:eval) ? @other.eval : @other
					@other.each { |o| @data << @fields.map { |f| o.send(f) } }
				else
					raise "object must be enumerable"
				end
				@data
			end
		end

		@@formats = [ :pdf, :csv, :yaml ]

		def format(format, args={})
			if args.respond_to?(:keys)
				out = args.delete(:to)
				@args.merge(args)
			else
				raise "args should be a hash"
			end

			raise "valid formats are #{@@formats.join(', ')}, '#{format}' given" unless @@formats.include?(format)

			klass = get_format_class(format)

			if    out == :string then klass.new(@other, @args, &@block).write
			elsif out == nil     then klass.new(@other, @args, &@block)
			else                      klass.new(@other, @args, &@block).write(out)
			end
		end
		alias as format

		def write(out=nil)
			if self.class == Reportable::Report && out.is_a?(String) && (ext = File.extname(out))
				p get_format_class(ext.gsub('.','')).new(@other, @args, &@block).write(out)
			else
				if out
					io = if    out.is_a?(String)       then File.open(out, 'w')
							 elsif out.respond_to?(:write) then out 
							 else  $stdout
							 end
	
					str = render
					io.write(str)
				else
					render
				end
			end
		end
		alias to write

		private

		@@date_format_strings = %w{   }

		def format_file_name

		end

		def get_format_class(format)
			@klass ||= Reportable.const_get(:"#{format.to_s.upcase}")::Report
		end
	end

	module PDF
		class Report < Reportable::Report
			attr_accessor :title

			def initialize(other, args={}, &block)
				super(other, args, &block)

				raise "headers are required" unless headers?
			end

			def generate
				doc = Prawn::Document.new
				if @other.respond_to?(:title)
					doc.text(@other.title, :size => 14, :style => :bold) 
					doc.text("\n")
				end
	
				if @other.respond_to?(:sections)
					@other.sections.each do |s|
						if s.respond_to?(:title)
							doc.text(s.title, :size => 12, :style => :bold)
							doc.text("\n")
						end
						data = self.class.new(s, @args, &@block).data
						d = data? && headers? ? data.drop(1) : data
						__gen_body(doc, d)
						doc.text("\n")
					end
				else
					d = data? && headers? ? data.drop(1) : data
					__gen_body(doc, d)
				end
	
				doc
			end
	
			def render
				generate.render
			end
	
	
			def __gen_body(doc, data)
				doc.table(data, :headers      => headers,
										    :font_size    => 10,
										    :border_style => :grid,
										    :header_color => 'dddddd') if data?
			end
		end
	end
	
	module CSV
		class Report < Reportable::Report
			def render
				data.map { |r| FasterCSV.generate_line(r) }.join("").gsub('true', '1').gsub('false', '0')
			end
		end
	end

	module YAML
		class Report < Reportable::Report
			def render
				::YAML.dump(data)
			end
		end
	end

	module ASCII
		
		class << self
			def table(data, headers)
				widths = column_widths(data)

				headers(headers, widths) + "\n|" +
				data.map { |row| table_row(row) }.join("|\n#{table_line(widths)}\n|") + "\n"
			end
		
			def table_line(widths)
				widths.inspect + "\n" +
				'+' + widths.map { |w| "-" * w }.join('+') + '+'
			end
		
			def table_row(row)
				row.map { |cell| " #{cell} " }.join("|")
			end
		
			def column_widths(table)
				column_widths = []
				
				table.each do |row|
					row.each do |cell|
						column_widths[row.index(cell)] = (cell.to_s.size + 2)
					end
				end
		
				column_widths
			end

			def headers(headers, widths)
				hs = headers.map { |h|
					w = widths[headers.index(h)]
					s = h.to_s.size
					n = if s > w
								s
								widths[headers.index(h)] = s + 2
							else
								(w - 2 - h.to_s.size)
							end

					" #{h} " + (" " * n)
				}.join('|') + "|\n"
				table_line(widths) + "\n|" + hs +
				table_line(widths)
			end
		end

		class Report < Reportable::Report
			def render
				@ascii = ""
				if @other.title
					@ascii += @other.title + "\n"
					@ascii += "=" * @other.title.size + "\n\n"
				end

				if @other.sections && !@other.sections.empty?
					@ascii += @other.sections.map { |s| self.class.new(s).render }.join("\n")
				else
					if @other.subtitle	
						@ascii += @other.title + "\n"
						@ascii += "=" * @other.title.size + "\n\n"
					end

					@ascii += ASCII.table(@other.data, @other.headers)
				end

				@ascii
			end

			def __gen_body(obj)

			end
		end
	end

	module Collection
		def report(args={}, &block)
			::Reportable::Report.new(self, args, &block)
		end
		alias export report
	end
end
