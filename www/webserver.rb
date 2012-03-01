#!/usr/bin/ruby
require 'webrick'
include WEBrick


class InlineRubyServlet < HTTPServlet::AbstractServlet
  def do_GET(req, res)
    rbfile = @options[0]
    auth = @options[1]

    if auth != nil then
      if auth.authenticate(req, res) == false then
        auth.challenge(req, res)
      end
    end

    #res.body = "<HTML>hello, world.</HTML>"
    
    #setup env
    ENV['REQUEST_METHOD'] = req.request_method
    ENV['QUERY_STRING'] = req.query_string
  
    #capture stdout
    buff = ""
    def buff.write(str)
      self << str
    end 

    def buff.print(str)
      self << str
    end 

    $stdout = buff
  
    #workaround strange bug on linksys
    page = IO.read(rbfile)
    page[-1,1] = '' if page[-1] == 255

    eval page

    $stdout = STDOUT

    #slight hack to get rid of first two lines in output from cgi 
    buff.sub!(/^Content-Type:.*$/, '')
    buff.sub!(/^Content-Length:.*$/, '')

    res.body = buff
    res['Content-Type'] = "text/html"

  end
end

s = HTTPServer.new( :Port => 80 )

s.mount("/admin", HTTPServlet::FileHandler, ".", true)

#do auth
userdb = {"sys" => "dba"}
userdb.extend(WEBrick::HTTPAuth::UserDB)
userdb.auth_type = WEBrick::HTTPAuth::BasicAuth
auth = WEBrick::HTTPAuth::BasicAuth.new({:Realm => "lithium", :UserDB => userdb })

s.mount("/admin/main.rb", InlineRubyServlet, "main.rb", auth)
s.mount("/admin/addtime.rb", InlineRubyServlet, "addtime.rb", auth)

trap("INT"){ s.shutdown }
s.start
