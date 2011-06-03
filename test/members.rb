require 'rubygems'
require 'ideas'

require File.join(File.dirname(__FILE__), '..', 'lib', 'cantor')

defset :NRF, IDEAS::NRF
NRF[:fields] = [ :PID ]
NRF[:title]  = "NLST NRF"
NRF[:headers] = [ 'pid' ]
NRF.DateOfDeath.export.to('/home/dnewman/public/nlst-nrf-dod.pdf')
