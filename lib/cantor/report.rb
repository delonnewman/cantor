require 'prawn'
require 'prawn/layout'
require 'church'


module Reportable
	class Report
		attr_accessor :fields, :headers

		def initialize(obj, *fields, &block)
			@other   = obj
			@block   = block
			@fields  = fields

			if not @block.nil?
				@block.call(self, obj)
			else
				if @fields.count == 1 && @fields.first.respond_to?(:keys)
					fields   = @fields.first.keys
					@headers = fields.map { |f| @fields.first[f] }
					@fields  = fields
				elsif @fields.count == 1 && @fields.first.respond_to?(:each)
					@fields = fields.first
				else
					@fields = fields
				end

				@headers = @fields.map { |f| f.to_s.upcase.gsub('_', ' ') }
			end
			
		end

		@@formats = [ :pdf, :ascii, :csv ]

		def to_format(format, out=nil)
			klass = Reportable.const_get(:"#{format.to_s.upcase}")::Report
			klass.new(@other, *@fields, &@block).write(out)
		end

		def method_missing(method, *args, &block)
			if !!method.to_s.match(/^to_/) &&
				 @@formats.include?(format = method.to_s.sub('to_', '').to_sym)
				to_format(format, args.first)	
			else
				raise "'#{method}' missing from #{self.class} at #{__FILE__}:#{__LINE__}"
			end
		end

		def write(out=nil)
			if out
				io = out.is_a?(String) ? File.open(out, 'w') : $stdout 
				io.write(render)
			else
				render
			end
		end
	end

	module PDF
		class Report < Reportable::Report
			def generate
				doc = Prawn::Document.new
				doc.text(@other.title, :size => 14, :style => :bold) if @other.title
				doc.text("\n")
	
				if @other.sections && !@other.sections.empty?
					@other.sections.each do |s|
						if s.subtitle
							doc.text(s.subtitle, :size => 12, :style => :bold)
							doc.text("\n")
						end
						__gen_body(doc, s)
						doc.text("\n")
					end
				else
					__gen_body(doc, @other)
				end
	
				doc
			end
	
			def render
				generate.render
			end
	
	
			def __gen_body(doc, obj)
				doc.table(obj.data, :headers      => obj.headers,
													  :font_size    => 10,
													  :border_style => :grid,
													  :header_color => 'dddddd') if obj.data
			end
		end
	end
	
	module HTML
	
	end
	
	module CSV
		require 'fastercsv'


		class Report < Reportable::Report
			def initialize(obj, *fields, &block)
				super(obj, *fields, &block)
	
				if @fields.empty?
					if obj.respond_to?(:fields)
						obj.fields
					else
						raise "Fields cannot be empty"
					end
				end
	
			end

			def generate
				(@headers ? FasterCSV.generate_line(@headers) : "") +

				if @other.respond_to?(:us) || @other.respond_to?(:map)
					@other.map do |o|
						if @fields
							FasterCSV.generate_line(@fields.map { |f| o.send(f) })
						else
							FasterCSV.generate_line(o.to_a)
						end
					end
				elsif @other.to_a.count > 1
					FasterCSV.generate_line(@other.to_a)
				else
					@other.to_s
				end.join("").gsub('true', '1').gsub('false', '0')
			end

			def render
				generate
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
		def to_pdf(path=nil)
			pdf = PDF::Report.new(:title => title)
			sections.each do |d|
				pdf << PDF::Report.new(:subtitle => d.title,
															 :data     => d.data,
															 :headers  => d.headers)
			end

			if path
				File.open(path, 'w') { |f| f.write(pdf.render) }
			else
				pdf.render
			end
		end

		def report(*fields, &block)
			::Reportable::Report.new(self, *fields, &block)
		end
		alias export report
	end
end
