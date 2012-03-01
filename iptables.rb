require 'singleton'
require 'hotlib'

#load 'hotspotd.conf'

class IPTables
  include Singleton
  
  #IPTABLES_SCRIPT  = './iptables/iptables'
  IPTABLES_SCRIPT  = '/usr/bin/iptables-wrapper'
  
  def initialize ()
    @allowed = []
    @log = HotLogger.instance.log
    reset
  end
  
  def reset ()
    return if HotConfig::TEST_MODE
    runCommand "reset", 0
    @log.info "iptables: resetting"
  end

  def allow (mac)
    return if HotConfig::TEST_MODE

    index = @allowed.length

    runCommand 'add-filt', index, mac.to_s
    begin # if this one fails, we better delete the last one
      runCommand 'add-nat', index, mac.to_s
    rescue IPTablesException
      runCommand 'del-filt', index
      raise
    end

    # if we get here, we successfully added
    @log.info "iptables: added mac #{mac}"
    @allowed [index] = mac
  end

  def remove (mac)
    return if HotConfig::TEST_MODE

    index = @allowed.index mac
    if not index
      raise "Mac address not registered #{mac}"
    end
    removeIndex index
    @log.info "iptables: deleted mac #{mac}"
  end

  private
  def removeIndex (index)
    if not @allowed [index]
      raise "Incorrect index #{index}"
    end
    
    begin
      runCommand 'del-filt', index
      runCommand 'del-nat', index
    end

    # delete the positions of the array.
    # NOTE That all the other indices change. Thus this method is private
    @allowed [index, 1] = []
  end

  # NOTE - iptables expects minimum index 1
  # so we will fake it by adding 1 to the index here. AND HERE ONLY
  def runCommand (cmd, index, mac = nil)
    index += 1
    error = system(IPTABLES_SCRIPT, cmd, index.to_s, mac.to_s)
    if not error then
      raise IPTablesException.new("iptables error: #{$?.exitstatus}")
    end
  end
end

#tables = IPTables.instance
#mac = MACAddress.new('00000000bac0')
#tables.allow mac
#tables.remove mac
