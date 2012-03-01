#!/usr/bin/ruby

require 'drb'
require 'hotlib'
require 'hotserver'

#load 'hotspotd.conf'

class HotSpotD
   def initialize()
      @log = HotLogger.instance.log

      if ARGV.length > 0 and ARGV[0] == '-f'
         fork_launch()
      else
         launch()
      end
   end

   def launch()
      server = HotServer.new
      DRb.start_service(HotConfig::URI, server)
      @log.info("lithium hotspot daemon started...")
      DRb.thread.join
   end

   def fork_launch()
      pid = fork
      if pid == nil
         Process.setsid
         exit if fork #zap session leader
         
         #free file descriptors
         STDIN.reopen "/dev/null"
         STDOUT.reopen "/dev/null", "a"
         STDERR.reopen "/dev/null"

         HotLogger.instance.set_to_file(HotConfig::LOGFILE)
         @log = HotLogger.instance.log
         launch()
      else
         #@log.info("forked, pid=#{pid}")
         exit
      end
   end
end

HotSpotD.new
