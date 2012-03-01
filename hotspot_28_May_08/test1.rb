require 'netutils.rb'
ip = '192.168.1.100'
print "query for: #{ip} is: #{ArpQuery.MacFromIP(ip)}\n"
