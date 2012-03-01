$: << '..'

require 'drb'
require 'hotlib'

DRb.start_service()
obj = DRbObject.new(nil, 'druby://192.168.0.25:9000')#HotConfig::URI)

#pending
obj.addnew(MACAddress.new('00:00:00:00:00:01'))
obj.addnew(MACAddress.new('00:00:00:00:00:02'))
obj.addnew(MACAddress.new('00:00:00:00:00:03'))
obj.addnew(MACAddress.new('00:00:00:00:00:04'))

#online
obj.addnew(MACAddress.new('00:00:00:00:00:05'))
obj.addnew(MACAddress.new('00:00:00:00:00:06'))

o1 = obj.get_record('00:00:00:00:00:05')
o2 = obj.get_record('00:00:00:00:00:06')

o1.state = HotState::ONLINE
o2.state = HotState::ONLINE

obj.update_record(o1)
obj.update_record(o2)
obj.update_record_time(o1.mac, 0, 2, 0, 0)
obj.update_record_time(o2.mac, 0, 0, 5, 0)

#permanent
obj.addnew(MACAddress.new('00:00:00:00:00:07'))
obj.addnew(MACAddress.new('00:00:00:00:00:08'))

p1 = obj.get_record('00:00:00:00:00:07')
p2 = obj.get_record('00:00:00:00:00:08')

p1.state = HotState::PERMANENT
p2.state = HotState::PERMANENT

obj.update_record(p1)
obj.update_record(p2)

list = obj.list()
list.each {|r| puts "#{r}\n"}
