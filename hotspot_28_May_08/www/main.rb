#!/usr/bin/ruby
#add staff to include path
$: << ".."

require 'lib/siki-template'
require 'hotlib'
require 'drb'
require 'cgi'

if defined?(cgi) == nil then
  cgi = CGI.new('html4')
end


begin
main_templ = IO.read("templates/main.html")

DRb.start_service()

server = DRbObject.new(nil, HotConfig::URI)

clear_params = {}

#process paramaters
if cgi.has_key?('action') and cgi.has_key?('mac') then
  action = cgi.params['action'][0]
  mac = MACAddress.new(cgi.params['mac'][0])

  server.del_record(mac) if action == 'del'

  #reset url
  cgi.out("Location" => "main.rb") {""}
  
else

records = server.list

pending   = records.find_all {|r| r.state == HotState::PENDING}
online    = records.find_all {|r| r.state == HotState::ONLINE}
permanent = records.find_all {|r| r.state == HotState::PERMANENT}

pending.map! {|r| 
  {:token => r.token.to_s,
   :addlink => AttrString.new(nil, {'href' => "addtime.rb?mac=#{r.mac}"}),
   :dellink => AttrString.new(nil, {'href' => "main.rb?action=del&mac=#{r.mac}"}),
   :infolink => AttrString.new(nil, {'href' => "info.rb?mac=#{r.mac}"}) 
  }
}

online.map! {|r| 
  {:token => r.token.to_s,
   :addlink => AttrString.new(nil, {'href' => "addtime.rb?mac=#{r.mac}"}),
   :dellink => AttrString.new(nil, {'href' => "main.rb?action=del&mac=#{r.mac}"}),
   :infolink => AttrString.new(nil, {'href' => "info.rb?mac=#{r.mac}"}),
   :timeinfo => r.time.to_s
  }
}

permanent.map! {|r| 
  {:token => r.token.to_s,
   :dellink => AttrString.new(nil, {'href' => "main.rb?action=del&mac=#{r.mac}"}),
   :infolink => AttrString.new(nil, {'href' => "info.rb?mac=#{r.mac}"})
  }
}

if pending.empty?
  pending = {:token => 'There are no records', :addlink => nil,
             :dellink => nil, :infolink => nil}
end

if online.empty?
  online = {:token => 'There are no records', :addlink => nil,
            :dellink => nil, :infolink => nil, :timeinfo => nil}
end

if permanent.empty?
  permanent = {:token => 'There are no records', 
               :dellink => nil, :infolink => nil}
end

data = {
  :onload        => clear_params,
  :pendingPane   => {:pending   => pending},
  :onlinePane    => {:online    => online},
  :permanentPane => {:permanent => permanent}
}

#clear params if we have to
#if clear_params == true then
#end

template = SikiTemplate::Template.new( main_templ )
result = template.parse( data )

# fix weird siki-template bug (actually a bug on linksys :-/
result[-1,1] = '' if result[-1] == 255

cgi.out {
  result
}
end
rescue
  print "Content-Type: text/plain\r\n\r\n"
  puts $!.inspect, $!.backtrace
  cgi.out("cache-control" => "no-cache") {
    $!.backtrace.join("<br>") + ":" + $!.to_s
  }
  raise
ensure
  begin server.break_connection_HACK!; rescue; end
  DRb.stop_service()
end

