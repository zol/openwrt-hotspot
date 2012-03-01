$: << '..'

require 'drb'
require 'hotlib'

#host = 'localhost'
host = '192.168.0.32'

puts 'Running client...'

DRb.start_service()
obj = DRbObject.new(nil, "druby://#{host}:9000")

puts "connected"

#obj.save_data()
obj.addnew(MACAddress.random)

records = obj.list()

Drb.stop_service()
#sleep(10000)

records.each {|r| puts "#{r}, time: #{r.time.isover?}"}
