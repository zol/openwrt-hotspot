require 'drb'
require 'hotdata'

host = '192.168.0.25'


1.upto(1000) { |i|
   puts "Sending record #{i}"
   record = HotRecord.new('test', i, Time.now.asctime)

   serv = DRb.start_service()
   puts serv
   obj = DRbObject.new(nil, "druby://#{host}:9000")
   obj.add(record)
   obj.to_file()
   serv.stop_service 
   #DRb.stop_service()
   #ObjectSpace.garbage_collect
   
   puts "Sleeping.."
   sleep(100)
}
