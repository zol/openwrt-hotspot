require 'net/http'

class TestRequest
  def initialize(uri, template, params = nil, substs = {})
    @uri = uri
    set_regexp(template, substs)
    @params = params
  end
 
  def set_regexp(filename, substs)
    regstr = IO.read(filename)
    substs.each { |key, value|
      regstr.gsub!('#{' + key + '}', value)
    }
  
    #puts regstr
    @regexp = Regexp.new(regstr)
  end
  
  def test
    if @params != nil
      res = Net::HTTP.post_form(@uri, @params).body
    else
      res = Net::HTTP.get(@uri)    
    end
    
    #puts res
    @regexp.match(res) 
  end
end
