require 'test/common'

class TestExport < Test::Unit::TestCase
	class Date
		def today
			Date.new(2011, 6, 9)
		end
	end

	def setup
		@count = NRF.count
		@dir   = '/home/dnewman/public'
		@file  = "#{@dir}/nlst-nrf"
	end

	def test_export_pdf
		file = "#{@file}.pdf"
		NRF.export.to(file)
		assert File.exists?(file)
	end

	def test_export_csv
		file = "#{@file}.csv"
		NRF.export.to(file)
		assert File.exists?(file)
	end

	def test_export_yaml
		file = "#{@file}.yaml"
		NRF.export.to(file)
		assert File.exists?(file)
	end
end
