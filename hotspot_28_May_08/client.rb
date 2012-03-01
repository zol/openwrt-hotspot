$: << '..'

require 'drb'
require 'hotlib'

include GC

host = 'localhost'
#host = '192.168.0.32'

puts 'Running client...'

DRb.start_service()
#obj = DRbObject.new(nil, "drbunix://#{host}:9000")
obj = DRbObject.new(nil, "drbunix:/tmp/foo.soc")

#puts "#{obj.protocol.inspect}"

puts "connected"

#obj.save_data()
#obj.addnew(MACAddress.random)

records = obj.list()

DRb.stop_service()

garbage_collect

records.each {|r| puts "#{r}, time: #{r.time.isover?}"}
