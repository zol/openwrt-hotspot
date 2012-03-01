#load 'hotspotd.conf'

#returns a mac address for the given IP based on the dhcp.leases file
class ArpQuery
   def ArpQuery.MacFromIP(ip)
      mac = ''

      File.open(HotConfig::LEASES).grep(/#{ip}/) { |line|
         re = /(\w\w:\w\w:\w\w:\w\w:\w\w:\w\w) #{ip}/
         md = re.match(line)
         mac = md[1] if md.length > 0
      }
      
      raise "ARPQUERY unsuccesful, maybe you aren't a wireless client" if mac == ''

      mac
   end
end
