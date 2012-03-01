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
DRb.start_service()
server = DRbObject.new(nil, HotConfig::URI)

raise "No MAC supplied to script" if not cgi.has_key?('mac')

mac = MACAddress.new(cgi['mac'])
record = server.get_record(mac)

raise "Record not found" if not record

if cgi.has_key?('confirm') or cgi.has_key?('cancel')
  # if we are confirming we will need to do some state changing
  if cgi.has_key?('confirm')
    if cgi.has_key?('permanent') 
      record.state = HotState::PERMANENT
    else
      record.state = HotState::ONLINE
      #record.time.begin(cgi['days'].to_i, cgi['hours'].to_i, cgi['minutes'].to_i, 0)
    end

    if cgi.has_key?('identifier') and cgi['identifier'] != ''
      record.token = identifier
    end

    if cgi['days'].to_i >= 0 and cgi['days'].to_i <= 365 and
       cgi['hours'].to_i >= 0 and cgi['hours'].to_i <= 24 and
       cgi['minutes'].to_i >= 0 and cgi['minutes'].to_i <= 60
    then
      server.update_record(record)
      server.update_record_time(record.mac, cgi['days'].to_i, cgi['hours'].to_i, cgi['minutes'].to_i, 0)
    end
  end


  templ = IO.read("templates/close.html")
  template = SikiTemplate::Template.new( templ )
  result = template.parse

  result[-1,1] = '' if result[-1] == 255
  cgi.out {
    result
  }
else

data = {                                              
  :mac   => AttrString.new(nil, {:value => mac.to_s}),
  :token => record.token.to_s
} 


main_templ = IO.read("templates/addtime.html")
template = SikiTemplate::Template.new( main_templ )
result = template.parse( data )

# fix weird siki-template bug
result[-1,1] = '' if result[-1] == 255

cgi.out {
  result
}
end

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

