require 'rubygems'
require 'ideas'

require File.join(File.dirname(__FILE__), '..', 'lib', 'cantor')

defset :NRF, IDEAS::NRF
NRF[:fields] = [ :PID ]
#p NRF.respond_to?(:fields)
#p NRF.fields
NRF.export.to('/home/dnewman/public/nlst-nrf.csv')
#File.open('/home/dnewman/public/nlst-nrf.pdf', 'w') { |f| f.write(pdf) }
