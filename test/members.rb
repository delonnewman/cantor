require 'rubygems'
require 'ideas'

require File.join(File.dirname(__FILE__), '..', 'lib', 'cantor')

defset :NRF, IDEAS::NRF
NRF.members :fields   => [ :PID, :DateOfDeath, :CompletionDate ],
						:title		=> "NLST NRF %D, %C Cases",
						:sections => [
							((dc = NRF.DateOfDeath)[:title] = "Deceased, %C Cases"; dc),
							((sy = NRF.StudyYear('06'))[:title] = "Study Year 06, %C Cases"; sy) ]

NRF.DateOfDeath.export.to('/home/dnewman/public/nlst-nrf-dc-%d-%C.pdf')
NRF.DateOfDeath.export.to('/home/dnewman/public/nlst-nrf-dc-%d-%C.csv')
NRF.DateOfDeath.export.to('/home/dnewman/public/nlst-nrf-dc-%d-%C.yaml')
