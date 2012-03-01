#!/usr/bin/ruby

require 'hotlib'


def save_data(filename, data)
      File.open(filename, "w") do |f|
         Marshal.dump(data, f)
      end
end

def repair_record(obj, data)
  if obj.instance_of? HotRecord then
    if obj.state == HotState::PERMANENT then
      newrec = HotRecord.new(obj.mac)
      newrec.token = obj.token
      newrec.state = obj.state
      data.records << newrec
      puts obj.inspect              
    end
  end
end

def repair_datafile(oldfile, newfile)
   newdata = HotData.new
   newdata.load_tokens
   
   begin
     text = open(oldfile, 'rb') { |f| f.read }
     
     @data = Marshal.load(text, Proc.new {|o| repair_record(o, newdata)})    
   rescue
     #ignore exceptions
   ensure
      puts 'Writing new data file'
      save_data(newfile, newdata)
   end
end

def print_datafile(datafile)
    text = open(datafile, 'rb') { |f| f.read }     
    @data = Marshal.load(text)   
    puts @data.inspect
end

#print_datafile('hotdata_fix.dat')
repair_datafile('hotdata.dat', 'hotdata_fix.dat')
