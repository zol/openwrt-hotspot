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
main_templ = IO.read("templates/logs.html")

DRb.start_service()
server = DRbObject.new(nil, HotConfig::URI)

clear_params = {}

logs = server.list_logs
#TODO -> logs.sort

sec_served = server.get_sec_served

logs.map! {|l|
  {:token => l.token,
   :mac => l.mac.to_s,
   :added_time => HotTime.sec_to_str(l.sec_added),
   :added_at => "on #{l.at_time.asctime}"
  }
}

if logs.empty?
  logs = {:token => 'There are no logs', :mac => nil,
          :added_time => nil, :added_at => nil}
end

data = {
  :total_time => "Total time added: #{HotTime.sec_to_str(sec_served)}",
  :logsPane   => {:logs   => logs}
}

template = SikiTemplate::Template.new( main_templ )
result = template.parse( data )

# fix weird siki-template bug (actually a bug on linksys :-/
result[-1,1] = '' if result[-1] == 255

cgi.out {
  result
}
rescue
  print "Content-Type: text/plain\r\n\r\n"
  puts $!.inspect, $!.backtrace
  cgi.out {
    $!.backtrace.join("<br>") + ":" + $!.to_s
  }
  raise
ensure
  begin server.break_connection_HACK!; rescue; end
  DRb.stop_service()
end
