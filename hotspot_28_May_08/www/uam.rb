#!/usr/bin/ruby

#add staff to include path
$: << ".."

require 'cgi'
require 'drb'
require 'hotlib'
require 'netutils'
require 'lib/siki-template'

if defined?(cgi) == nil then
  cgi = CGI.new('html4')
end


begin

#TODO error handling
out = "#{cgi.remote_addr}<br>"
mac = MACAddress.new(ArpQuery.MacFromIP(cgi.remote_addr))

# 2. Make a connection to the DRB server
DRb.start_service()
server = DRbObject.new(nil, HotConfig::URI)

# 3. Check if this mac address is registered
record = server.get_record(mac)

# 4. Add it if it isn't
if not record.nil?
  server.reset_pending(record) unless record.state.active?
else
  record = server.addnew(mac)
end

if record.state.active? then
  # FIXME -- this is silly
  cgi.out ("status" => "OK") {
    'hmm.. should not be here'
  }
else
  data = {
    :token => record.token.to_s
  }

  main_templ = IO.read("templates/uam.html")
  template = SikiTemplate::Template.new( main_templ )
  result = template.parse( data )

  # fix weird siki-template bug
  result[-1,1] = '' if result[-1] == 255

  cgi.out ("status" => "OK", "cache-control" => "no-cache") {
    result
  }
end
rescue
  cgi.out ("status" => "OK") {
    $!.backtrace.join("<br>") + ":" + $!.to_s
  }
ensure
  begin server.break_connection_HACK!; rescue; end
  DRb.stop_service()
end
