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

data = {                                              
  :token => record.token.to_s,
  :mac   => record.mac.to_s,
  :time  => record.time.to_s,
  :start_time => record.time.start_time.asctime,
  :end_time => record.time.end_time.asctime,
  :state => record.state.to_s
} 


main_templ = IO.read("templates/info.html")
template = SikiTemplate::Template.new( main_templ )
result = template.parse( data )

# fix weird siki-template bug
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
