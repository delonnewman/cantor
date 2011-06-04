require 'rubygems'
require 'ideas'

require File.join(File.dirname(__FILE__), '..', 'lib', 'cantor')

defset :NRF do
	from IDEAS::NRF
	has :fields   => [ :PID, :DateOfDeath, :CompletionDate ],
			:title		=> "NLST NRF",
			:subtitle => "%D, %C Cases",
			:sections => []
end

defset :DC do
	from NRF.DateOfDeath
	has :title => "Deceased, %C Cases"

	NRF.sections << us
end

NRF.map { |r| r.StudyYear }.uniq.sort.each do |y|
	defset :"SY#{y}" do
		from NRF.StudyYear(y)
		has :title => "Study Year #{y}, %C Cases"
	
		NRF.sections << us
	end
end

NRF.export.to('/home/dnewman/public/nlst-nrf-%d-%C.pdf')
NRF.DateOfDeath.export.to('/home/dnewman/public/nlst-nrf-dc-%d-%C.csv')
NRF.DateOfDeath.export.to('/home/dnewman/public/nlst-nrf-dc-%d-%C.yaml')
