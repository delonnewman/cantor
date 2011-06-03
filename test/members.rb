require 'rubygems'
require 'ideas'

require File.join(File.dirname(__FILE__), '..', 'lib', 'cantor')

defset :NRF, IDEAS::NRF
NRF.members :fields   => [ :PID, :DateOfDeath ],
						:headers  => [ 'pid', 'dod' ],
						:title		=> "NLST NRF",
						:sections => [
							((dc = NRF.DateOfDeath)[:title] = "DC"; dc),
							((sy = NRF.StudyYear('06'))[:title] = "06"; sy) ]

NRF.DateOfDeath.export.to('/home/dnewman/public/nlst-nrf-dc.pdf')
NRF.DateOfDeath.export.to('/home/dnewman/public/nlst-nrf-dc.csv')
NRF.DateOfDeath.export.to('/home/dnewman/public/nlst-nrf-dc.yaml')
