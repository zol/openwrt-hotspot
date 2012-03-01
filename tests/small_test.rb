#!/usr/bin/ruby

$stdin.sync = true

require 'test_request'
require 'uri'

baseurl = 'http://192.168.0.32/'
wimipurl = 'http://www.whatismyip.com/'

expectdir   = 'expected/'
checkpfile  = expectdir + 'check_pending.html'
checkofile  = expectdir + 'check_online.html'
addtimefile = expectdir + 'addtime_done.html'
infofile    = expectdir + 'info.html'

mins = 1
macdict = {'mac' => '00:02:2d:81:8c:5f'}
adddict = {'mac' => '00:02:2d:81:8c:5f', 'confirm' => 'true',
           'days' => '0', 'hours' => '0', 'minutes' => mins.to_s}

mainuri = URI.parse(baseurl + 'main.rb')
adduri  = URI.parse(baseurl + 'addtime.rb')
infouri = URI.parse(baseurl + 'info.rb')

check_pending = TestRequest.new(mainuri, checkpfile, nil, macdict)
check_online  = TestRequest.new(mainuri, checkofile, nil, macdict)
addtime       = TestRequest.new(adduri,  addtimefile, adddict)
info          = TestRequest.new(infouri, infofile, macdict)

# alright.. setup.. lets go

puts "Checking pending"
match = check_pending.test
raise "Not Pending" if match.nil?

token = match[1]
puts "Token is #{token}"

puts "Checking info"
match = info.test
puts "#{match[3]} in state #{match[6]}"

puts "Adding Time"
raise "Add Time Failed" if addtime.test.nil?

puts "Checking online"
raise "Not Online" if check_online.test.nil?

puts "Checking info"
match = info.test
puts "#{match[3]} in state #{match[6]}"

sleep(70)

puts "Checking pending"
raise "Not Pending" if check_pending.test.nil?