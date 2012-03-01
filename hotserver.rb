require 'hotlib'
require 'iptables'

#wraps hotdata class, provides access over wire and marshalling
class HotServer
   DATAFILE = 'hotdata.dat'
   CLEAN_INTERVAL = 10

   def initialize()
      @log = HotLogger.instance.log
      @tables = IPTables.instance
   
      @data = HotData.new
      #ensure thread safety (I'm not sure if this is necessary)
      #@data.extend(MonitorMixin)
      
      load_data()

      cleaner_thread()

      @log.info 'HotServer ready...'
   end

   #------ data access methods

   # create a unique token and add record
   def addnew(mac)
      if not mac.kind_of?(MACAddress)
        raise "Incorrect MAC address supplied"
      end
   
      if get_record(mac)
        raise "MAC address already registered"
      end
   
      rec = HotRecord.new(mac)
      rec.token = gen_token()

      @data.records << rec
      reset_pending(rec) # see note below

      save_data()

      @log.info "Added #{rec}"
      rec
   end
   
   # NOTE -- have to do this after! adding to @data
   def reset_pending(rec)
     @log.info "resetting time for #{rec}"
     r = get_record(rec.mac)
     r.time.begin(0, 0, HotConfig::PENDING_TIME, 0)
   end

   def get_record(mac)
     @data.records.find { |r| r.mac == mac }
   end

   def del_record(mac)
     @log.info "Deleting record with mac:#{mac}" 
     r = get_record(mac)
     
     if r 
       @tables.remove(r.mac) if r.state.active?
       @data.records.delete(r)
     end

     save_data()
     r
   end

   def update_record(new)
      # search for record
      old = @data.records.find {|r| r.mac == new.mac}

      # TODO -- something here
      raise "Record not found" if not old

      @log.info "Updating #{old.state} => #{new.state}"

      # check if we need to update iptables
      if new.state.activated?(old.state) then
         @log.info "Allowing #{new.mac}"
         @tables.allow(new.mac)
      elsif new.state.deactivated?(old.state) then
         @log.info "Removing #{new.mac}"
         @tables.remove(new.mac)
      end

      # update the list and save
      @data.records[@data.records.index(old)] = new
      save_data
   end

   def update_record_time(mac, days, hours, mins, secs)
     r = get_record(mac)
     r.time.begin(days, hours, mins, secs) if r != nil     

     #update logs
     sec_added = secs + (mins * 60) + (hours * 3600) + (days * 24 * 3600)
     @data.sec_served += sec_added
     @data.access_logs << HotLogRecord.new(r.token, r.mac, sec_added, Time.now)

     save_data()
   end

   def list()
      @data.records
   end

   def list_logs()
      @data.access_logs
   end

   def get_sec_served()
      @data.sec_served
   end

   def list_state(state)
      @data.records.find_all { |r| r.state == state}
   end


   #--------------------------

   def save_data()
      #synchronize do
         File.open(DATAFILE, "w") do |f|
            Marshal.dump(@data, f)
         end
      #end
   end
   
   def load_data()
      begin
         File.open(DATAFILE) do |f|
            @data = Marshal.load(f)
         end
         @log.info 'Loaded data file'
      rescue Errno::ENOENT
         #file not found, write empty and try again
         @log.info 'Writing empty data file'

         save_data()
         retry #is this dangerous?
      end

      @data.records.each {|r|
        @tables.allow(r.mac) if r.state.active?
      }
   end

  
private
   #return a token which is free to be used
   def gen_token()
      used_tokens = []
      @data.records.each() { |r| used_tokens << r.token }

      free_tokens = @data.tokens - used_tokens

      srand
      free_tokens[rand(free_tokens.length)]
   end

   #gets rid of users in iptables who have 'timed out'
   def cleaner_thread()
      return if HotConfig::TEST_MODE
      
      @log.info 'Started cleaner thread'

      Thread.new {
         begin
           loop do
              #@log.info 'Cleaner cleaning'
              #find all timed out
              timed_out = @data.records.find_all { |r| r.time.isover? }

              #remove them
              timed_out.each { |r| 
                 if r.state.active?
                   @tables.remove(r.mac)
                   r.state = HotState::PENDING
                   reset_pending(r)
                   
                   @log.info "Reset #{r} to PENDING"
                 else 
                   @data.records.delete(r)
                   
                   @log.info "Cleaned #{r}"  
                 end
              }
              
              save_data() if timed_out.length > 0            
              
              @log.info 'Cleaner done'
              sleep(CLEAN_INTERVAL)
           end
         catch 
           @log.error "Exception in cleaner thread: #{$!}"
         end
      }
   end
end
