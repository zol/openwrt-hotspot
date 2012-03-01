require 'logger'
require 'singleton'
require 'util'

load 'hotspotd.conf'

#data wrapper which is marshalled to file
class HotData
   attr_reader :records, :access_logs, :sec_served, :tokens
   attr_writer :records, :access_logs, :sec_served, :tokens
   
   def initialize()
      @records = []
      @access_logs = []
      @sec_served = 0

      #default tokens
      @tokens = ['zol', 'kris', 'tom', 'ange', 'tess', 'sophie', 'chaz', 'laurence', 'tinka', 'clemmo']
      load_tokens
   end

   def load_tokens
      f = File.open("hottokens.txt")

      @tokens = []
      
      f.each { |line|
        @tokens << line.chomp
      }
      
      f.close
   end
end

#each individual record is stored in here
class HotRecord
   attr_writer :token, :mac, :time, :state
   attr_reader :token, :mac, :time, :state

   def initialize(mac)
      @mac = mac
      @time = HotTime.new
      @token = 'UNSET'
      @state = HotState::PENDING
   end

   def to_s
      "HotRecord-> token:#{@token} mac:#{@mac} state:#{@state} time:#{@time}"
   end
end

class HotLogRecord
  attr_reader :token, :mac, :sec_added, :at_time

  def initialize(token, mac, sec_added, at_time)
    @token = token
    @mac = mac
    @sec_added = sec_added
    @at_time = at_time
  end
end

class HotState < EnumeratedType
  PENDING
  ONLINE
  PERMANENT

  def activated?(old)
    not old.active? and self.active?
  end

  def deactivated?(old)
    old.active? and not self.active?
  end

  def active?
    self == HotState::ONLINE || self == HotState::PERMANENT 
  end 
end

#holds times by which we time out users
class HotTime
   attr_reader :end_time, :start_time

   def initialize()
      @start_time = Time.at(0) #1969
      @end_time = Time.at(0) #1969
   end

   def begin(days, hours, mins, secs)
      @start_time = Time.now

      #calculate when to terminate us
      period_secs = secs + (mins * 60) + (hours * 3600) + (days * 24 * 3600)
      @end_time =  @start_time + period_secs
   end

   def add_time(days, hours, mins, secs)
      period_secs = secs + (mins * 60) + (hours * 3600) + (days * 24 * 3600)
      @end_time =  @end_time + period_secs
   end

   def isover?()
      Time.now > end_time
   end

   #format the time remaining as a string e.g. 4d 2h 31m 10s
   def remaining_str()
      return "expired" if isover?

      diff = (@end_time - Time.now).floor
      diff, seconds = diff.divmod 60
      diff, minutes = diff.divmod 60
      diff, hours   = diff.divmod 24
      days    = diff

      str = ''
      str += "#{days}d" if days != 0
      str += "#{hours}h" if hours != 0
      str += "#{minutes}m" if minutes != 0
      str += "#{seconds}s" if seconds != 0
      "#{str} remaining"
   end

   def HotTime.sec_to_str(secs)
      secs, seconds = secs.divmod 60
      secs, minutes = secs.divmod 60
      secs, hours   = secs.divmod 24
      days = secs

      str = ''
      str += "#{days}d" if days != 0
      str += "#{hours}h" if hours != 0
      str += "#{minutes}m" if minutes != 0
      str += "#{seconds}s" if seconds != 0
      str
   end

   def to_s
      #"#{@start_time.asctime} to #{@end_time.asctime}"
     remaining_str
   end
end

#simple wrapper for log class
class HotLogger
   include Singleton

   attr_reader :log

   def initialize()
      set_to_STDOUT()
   end

   def defaults()
      @log.level = Logger::DEBUG
      #@log.datetime_format = "%H:%H:%S"
   end

   def set_to_file(filename)
      @log = Logger.new(filename, 1, 10*1024) #rotate when 10k
      defaults()
   end

   def set_to_STDOUT()
      @log = Logger.new(STDOUT)
      defaults()
   end
end

class MACAddress
  attr_accessor :parts
  
  def initialize (str)
    matchstr = (["([[:xdigit:]]{2})"] * 6).join "[-:]?"
    
    match = str.match "^#{matchstr}$"
    if not match 
      raise "Incorrectly formatted mac address: '#{str}'"
    end
    @parts = match [1,6]
    @parts.each {|part| part.downcase!}
  end

  # generate a random mac address
  def self.random
    mac = self.new('00:00:00:00:00:00')
    srand
    
    6.times do |i|
      2.times do |j|
        r = rand(16)
        r = (r+87).chr if r >= 10 # to hex
        mac.parts[i][j] = r.to_s
      end
    end

    mac
  end

  # perhaps a bit of a hack, but not the end of the world
  def ==(other)
    self.to_s == other.to_s
  end
  
  def to_s ()
    @parts.join ":"
  end
end

class IPTablesException < RuntimeError
end
