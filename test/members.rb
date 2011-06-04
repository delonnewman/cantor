require 'rubygems'
require 'ideas'

require File.join(File.dirname(__FILE__), '..', 'lib', 'cantor')

defset :NRF do
	from IDEAS::NRF
	has :fields   => [ :PID, :DateOfDeath, :CompletionDate ]
	has :title		=> "NLST NRF"
	has :subtitle => "%D, %C Cases"
	has :sections => [
		((dc = us.DateOfDeath)[:title] = "Deceased, %C Cases"; dc),
		((sy = us.StudyYear('06'))[:title] = "Study Year 06, %C Cases"; sy) ]
end

NRF.DateOfDeath.export.to('/home/dnewman/public/nlst-nrf-dc-%d-%C.pdf')
NRF.DateOfDeath.export.to('/home/dnewman/public/nlst-nrf-dc-%d-%C.csv')
NRF.DateOfDeath.export.to('/home/dnewman/public/nlst-nrf-dc-%d-%C.yaml')
