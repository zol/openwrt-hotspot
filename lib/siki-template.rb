# SikiTemplate
# Ver.0.7.0 (20050429)
# (c) Nowake <nowake@fiercewinds.net>
# License BSD License
# http://cvs.sourceforge.jp/cgi-bin/viewcvs.cgi/sikiwiki/siki/lib/RAA/xml/siki-template.rb
# TestCode http://cvs.sourceforge.jp/cgi-bin/viewcvs.cgi/sikiwiki/siki/lib/testunit/lib/RAA/xml/
# Check end of this file

require 'singleton'
require 'pathname'

class AttrString < String
  def initialize(s, attributes)
    if s == nil
      @change = false
      s = ''
    else
      @change = true
    end

    super(s)
    @attributes = attributes
  end

  def change_content?
    @change
  end

  def attr_string
    attr_str = ""
    if not @attributes.empty? then
       attr_pairs = @attributes.map { |k, v| "#{k}=\"#{v}\"" }
       attr_str += attr_pairs.join(" ")
    end
    attr_str
  end

  def parse_leader(leader)
    tail = ""
    @attributes.each { |k, v|  
      attr_str = "#{k}=\"#{v}\""
      test = leader.gsub!(/#{k}=([\"']).*?\1/, attr_str)
      tail += attr_str if test == nil
    }    

    leader [-1,0] = " #{tail}" if tail != ""
    leader
  end
end

module SikiTemplate
  class TemplateCompiler
    attr_reader( :compiled_template )
    def initialize( template )
      @aset = self.class::AttributeSet.new
      @compiled_template = compile_template( template.gsub('%','&#x25;') )
    end
    private
    TagParseRegexp =
        /(
         (?>\<\!\-\-\/\|)|
         (?>\<\!\-\-\_\|)|
         (?>\<))                   # [1] leader
        (\/)?                      # [2] leader or terminator?
        ((?>[^\s\>\/\-]*))         # [3] tag name
        (?:\s
          ((?:[^>]*?))             # [4] attributes
        )?
        (\/)?                      # [5] empty tag or not
        (
        (?>\-\-\>)|
        (?>\>))                    # [6] teminator
        /x  
    def compile_template( template )
      stack = []; r = ''; @aset.clear
      template.gsub( TagParseRegexp ) do
        target = vals = attrs = nil
        next $~[0] if $~[0][1] == '?'[0]
        next $~[0] if $~[0][1] == '!'[0] and $~[1] != '<!--_|' and $~[1] != '<!--/|'
        next $~[0] if $~[1] == '<' and $~[6] != '>'
        next $~[0] if $~[1] == '<!--_|' and $~[6] != '-->'
        next $~[0] if $~[1] == '<!--/|' and $~[6] != '-->'
        next $~[2] ? "%:%;" : "%#{$~[3]}:%;" if $~[1] == '<!--/|'
        next (stack.pop ? "%:</#{$~[3]}>%;" : "</#{$~[3]}>") if $~[2]
        
        m = $~.to_a
        m[3..4] = [nil, m[4] ? "#{m[3]} #{m[4]}":m[3]] if m[3].include?('=')
        
        @aset.variable = @aset.joint = true if m[1] == '<!--_|'
        @aset.add_attributes_text(m[4]) if m[4]
        r = @aset.target ? "%#{@aset.target}:<#{m[3]}" : "<#{m[3]}"
        r << "#{@aset.result}" if @aset.result
        if m[1] == '<!--_|'
          @aset.target ||= m[3]
          m[3] = ""
        end
        if @aset.joint
          @aset.joint = false
          r = ''
        else
          if m[5]
            r << (@aset.target ? ">%;%:</#{m[3]}>%;" : "></#{m[3]}>")
          else
            stack.push( @aset.target )
            r << (@aset.target ? '>%;' : '>')
          end
          @aset = AttributeSet.new
        end
        r
      end
    end
    def treat_attributes( string )
      @aset.clear
      @aset.attributes_text = string
      [@aset.target, @aset.result]
    end
    class AttributeSet
      attr_accessor( :target, :joint, :variable )
      AttributeParseRegexp =
          /([^=\s]+)=            # [1] name
           ([\"\'])              # [2] terminator
           (?:([^@$].*?)|        # [3] not target value
           (?:(?:\$(\$?[^@]*?))? # [4] element target
           (?:\@([^@$]+?))?      # [5] attribute target
           (?:\@\$([^@$]+?))?    # [6] new attribute name
           (?:@@(.+?))?))\2      # [7] default value
          /x
      def initialize
        @joint = false; @variable = false
        @data = Hash.new do | h, k | h[k] = self.class::Attribute.new( k ) end
      end
      def clear
        @joint = false; @variable = false; @target = nil
        @data.clear
        self
      end
      def add_attributes_text( text )
        attrs = ''; vals = nil; target = nil
        text.scan( AttributeParseRegexp ) do
          m = $~
          if m[3]
            if @variable
              @data[m[1]].target = m[3].gsub( '"', '&quot;' )
            else
              @data[m[1]].default = m[3].gsub( '"', '&quot;' )
            end
          else
            @data[m[1]].default = m[7].gsub( '"', '&quot;' ) if m[7]
            if m[4][0] == "$"[0]
              @target ||= m[4][1...m[4].size]
              @target = nil if @target.empty?
              @joint = true
            else
              @target = m[4]
            end if m[4]
            @data[m[1]].target = m[5] if m[5]
            if m[6]
              data = @data.delete( m[1] )
              data.name = m[6] if data
              @data[m[6]] = data
            end
          end
        end
      end
      def result
        result = ''
        @data.each do | k, v | result << v.result unless v.target end
        @data.each do | k, v | result << v.result if v.target end
        result
      end
      class Attribute
        attr_reader( :name, :target, :default )
        def initialize( val ); @name = val; @target = @default = nil end
        def default=( val ); @default ||= val end
        def target=( val ); @target ||= val end
        def name=( val ); @name = val end
        def result
          if @target
            "%#{@target}: #{@name}=\"%;#{@default}%:\"%;"
          else
            " #{@name}=\"#{@default}\""
          end
        end
      end
    end
  end
  
  class ResultData
    attr_accessor( :leader, :content, :terminator )
    def initialize; @leader = ''; @content = ''; @terminator = '' end
    def result
      @leader.to_s.gsub('&#x25;','%') +
          @content.to_s.gsub('&#x25;','%') +
          @terminator.to_s.gsub('&#x25;','%')
    end 
  end
  
  class PullParser
    attr_reader(
      :template, :pos, :target, :document, :passed_content, :last_content,
      :filter_set, :last_filter, :command, :last_target,
      :cache, :cache_pos
     )
    def initialize(template, pos=0, target=false, filter_set=[] )
      @initial_template = template;
      @initial_pos = pos; @initial_target = target;
      @initial_filter_set = filter_set;
      @cache = []
      reset
    end
    def advance
      return nil unless @pos
      return cached_advance if @cache_pos
      pos = @pos; @target = nil
      @pos = @template.index( '%', pos ) if pos
      unless @pos
        result = @template[pos...@template.size]
        cache( @pos, @target, @last_target, @filter_set, @last_filter, @command, result )
        @cache_pos = true
        return result
      end
      if @template[@pos+1] == ';'[0] # terminator
        @target = false
        result = @template[pos...@pos]
        @pos += 2
      else # leader
        target_end = @template.index( ':', @pos + 1 )
        @target, filters = parse_filters( @template[(@pos+1)...target_end] )
        if filters
          @filter_set.push( filters ) 
          @last_filter = nil
        elsif target == nil
          @last_filter = @filter_set.pop
        else
          @last_filter = nil
          @filter_set.push( nil )
        end
        @target, command = parse_commands( @target )
        @command = command if command
        @target = @target.to_sym if @target.instance_of?( String )
        @last_target = @target
        result = @template[pos...@pos]
        @pos = target_end + 1
      end
      cache( @pos, @target, @last_target, @filter_set, @last_filter, @command, result )
      result
    end
    def traverse
      count = 1; @passed_content = ''
      begin
        @last_content = advance.to_s
        @passed_content << @last_content
        count += (@target == nil) ? -1 : 1 if @target != false
        return @passed_content unless @pos
      end while count > 0
      @passed_content
    end
    def skip
      @passed_content = traverse
      @last_content = @pos ? advance : ""
      @passed_content + @last_content
    end
    def inner
      enter
      sp = @pos
      traverse
      ep = @pos - 2 # size of tag "%;"
      advance
      @template[sp...ep]
    end
    def delete_tag
      advance while ((not @target) and @pos)
      return "" unless @pos
      target = @target
      "%#{target.to_s}:%;#{inner}%:%;"
    end
    def filter( result, &procedure )
      @filter_set.push( @last_filter )
      @filter_set.reverse_each do | i |
        i.each do | j | result = j.filter( result, &procedure ) end if i
      end
      @filter_set.pop
      result
    end
    def reset
      @template = @initial_template
      @pos = @initial_pos; @target = @initial_target;
      @filter_set = @initial_filter_set.clone;
      @last_filter = nil; @command = nil; @document = ''
      @passed_content = ''; @last_content = nil; @last_target = nil
      @cache_pos = 0 if @cache_pos
    end
    private
    def parse_filters( string )
      return nil unless string
      return nil if string.empty?
      return string unless string.include?( '|' )
      target, *filters = string.split( '|' )
      target = true if target.empty?
      filters.each_index do | index |
        filters[index] = Filter.create_filter( filters[index], target )
      end
      [target, filters]
    end
    def parse_commands( string )
      return string unless string.instance_of?( String )
      return string unless string.include?( '.' )
      string.split( '.' )
    end
    def enter
      count = @target ? 1 : 0;
      begin
        advance
        count += (@target==false) ? -1 : 1
      end while (count > 0) && @pos
    end
    def cache( end_pos, target, last_target, filter_set, last_filter, command, result )
      value = []
      value << end_pos
      value << target
      value << last_target
      value << filter_set
      value << last_filter
      value << result
      @cache << value
      result
    end
    def cached_advance
      value = @cache[@cache_pos]
      @cache_pos += 1
      @pos = value[0]
      @target = value[1]
      @last_target = value[2]
      @filter_set = value[3]
      @last_filter = value[4]
      value[5]
    end
  end
  
  
  class EventBase
    private_class_method  :new
    @@use_execute = false
    def self.create( data=nil ); new( data ) end
    attr_accessor( :parent )
    def initialize; @filter_set = [] end
    def filter( result, parser )
      @filter_set.each do | i | i.filter( result ) end
      parser.filter( result ) if @allow_filter
      result
    end
    private
    def create_command( obj )
      if obj.kind_of?( EventBase )
      elsif obj.instance_of?( Hash )
        obj = ChooseEvent.create( obj )
      elsif obj.instance_of?( String )
        obj = ChangeContents.create( obj )
      elsif obj.instance_of?( AttrString )
        obj = ChangeContentsAttr.create( obj )
      elsif obj.instance_of?( Array )
        obj = Repeat.create( obj )
      elsif obj.instance_of?( Symbol )
        obj = ChangeElement.create( obj.to_s )
      elsif obj.instance_of?( TrueClass )
        obj = NoChange.create
      elsif obj.instance_of?( NilClass )
        obj = DeleteElement.create
      elsif obj.instance_of?( FalseClass )
        obj = Delete.create
      elsif obj.kind_of?( Numeric )
        obj = Count.create( obj, Count::BaseStep, true, Filter::DeleteTag )
      elsif obj.instance_of?( Proc ) or obj.instance_of?( Method )
        obj = Proceed.create( obj )
      elsif @@use_execute
        obj = Execute.create( obj ) unless obj.instance_of?( Execute )
      else
        raise "#{obj.class}::#{obj} is not correct Command Object"
      end
      obj.parent = self
      obj
    end
    def create_result( parser )
      result = ResultData.new
      sp = parser.document.size
      tsp = parser.pos
      parser.document << parser.advance.to_s
      while parser.target
        @parent.assume( parser )
        parser.document << parser.advance.to_s
      end if @parent
      parser.skip
      cep = parser.pos
      result.leader = parser.document.slice!( sp...parser.document.size )
      result.content =  parser.passed_content
      result.terminator = parser.last_content
      result
    end
  end
  
  class ContentIntegrateBase < EventBase
    def integrate( parser )
      result = create_result( parser )
      result = create_content( result, parser )
      result = filter( result, parser )
      parser.document << result.result
      parser
    end
  end
  
  class Template < ContentIntegrateBase
    def self.create( modeldata, template, cachefile=nil )
      t = Template.new( template, cachefile )
      t.modeldata = modeldata
      t
    end
    public_class_method  :new
    Compiler = TemplateCompiler
    def initialize( template, cachefile=nil )
      super()
      Filter.reset
      @filter_set = []
      @allow_filter = true
      @modeldata = ChooseEvent.create
      @modeldata.parent = self
      if template.kind_of?( Pathname )
        tf = template; cf = cachefile
        cf = Pathname.new( tf.to_s + '.cache' ) if cf == true
        if cf and cf.exist? and (tf.mtime < cf.mtime)
          @template = cf.open( 'r' ) do | f | f.read end
        elsif tf.exist?
          @template = tf.open( 'r' ) do | f | f.read end
          @template = self.class::Compiler.new( @template ).compiled_template
          cf.open( "w+b" ) do | f | f << @template end if cf
        else
          raise "SikiTemplate Error. File: #{tf.to_s} isn't exists"
        end
      else
        @template = self.class::Compiler.new( template ).compiled_template
      end
    end
    attr_reader( :modeldata )
    def modeldata=( var ); @modeldata = ChooseEvent.create( var ) end
    def parse( contents=@modeldata )
      @parser ||= PullParser.new( @template )
      @parser.reset
      set_filter_set( @parser )
      create_command( contents ).integrate( @parser )
      @parser.document
      
      #fix wierd fuck up on linksys
      #re[-1] = ' ' if re[-1] == 0xff
      #re
      
      #parser = PullParser.new( @template )
      #set_filter_set( parser )
      #create_command( contents ).integrate( parser )
      #parser.document
    end
    def assume( parser )
      result = create_result( parser )
      #result = create_content( result, parser )
      result = filter( result, parser )
      parser.document << result.result
      parser
    end
    def to_s; parse end
    private
    def create_content( result, parser )
      prs = PullParser.new( @template )
      set_filter_set( parser )
      create_command( @modeldata ).integrate( prs )
      result.content = prs.document
      result
    end
    def set_filter_set( parser ); end
    def self.use_execute=( var ); @@use_execute = var end
  end
  
  class XMLTemplate < Template
    private
    def set_filter_set( parser )
      parser.filter_set << [Filter::SanitizeXML, Filter::DeleteIfEmpty ]
    end
  end
  
=begin 
  class SanitizingTemplateCompiler < TemplateCompiler
    class AttributeSet < TemplateCompiler::AttributeSet
      class Attribute < TemplateCompiler::AttributeSet::Attribute
        def result
          p @name
          if @target and (@name == 'href' or @name == 'src')
            ""
          elsif @target
            "%#{@target}: #{@name}=\"%;#{@default}%:\"%;"
          else
            " #{@name}=\"#{@default}\""
          end
        end
      end
    end
    
  end

  class XHTMLTemplate < XMLTemplate
    Compiler = SanitizingTemplateCompiler
    p 'test'
    p Compiler
  end
=end  
  
  
  class ChooseEvent < EventBase
    def initialize( data, parent=nil )
      super()
      @data = Hash.new
      #@data = Hash.new do |h, k|
      #  h[k] = Hash.new { |hash, key| h.default_proc.call(hash, key) }
      #end
      data.each_pair do | k,v | @data[k.to_sym] = create_command(v) end if data
    end
    def assume( parser ); process_target( parser ) end
    def integrate( parser )
      parser.document << parser.advance.to_s if parser.target
      while parser.target != nil
        unless parser.target
          parser.document << parser.advance.to_s
          next
        end
        process_target( parser )
        parser.document << parser.advance.to_s
        parser.document << parser.advance.to_s if parser.target == false
      end
      parser.document << parser.advance.to_s
      parser
    end
    def key(key); @data[key] end
    def [](key); Wrapper.create( self, key, @data[key] ) end
    def []=(key, val); @data[key] = create_command(val) end
    private
    def process_target( parser )
      if @data.key?( parser.target )
        @data[parser.target].integrate( parser )
      elsif parser.target != true
        @parent.assume( parser )
      end
    end
    class Wrapper < EventBase
      def self.create( owner, name, target ); new( owner, name, target ) end
      def initialize( owner, name, target )
        @owner = owner
        @name = name
        @target = target
      end
      def <<( val )
        if @owner.key(@name).kind_of?(Repeat)
          result = @owner.key(@name)
        else
          result = Repeat.create
          result.parent = @owner
          result << @owner.key(@name) if @owner.key(@name)
        end
        result << create_command(val)
        @owner[@name] = @target = result
      end
      def <=( val )
        unless @owner.key(@name).kind_of?(Repeat)
          result = Repeat.create
          result.parent = @owner
          if @owner.key(@name)
            result << @owner.key(@name)
          else
            result << Repeat.create
            result.last.parent = @owner
          end
          @owner[@name] = result
        end
        unless @owner.key(@name).last.kind_of?(Repeat)
          result = Repeat.create
          result.parent = @owner.key(@name).last
          result << @owner.key(@name).last if @owner.key(@name).last
          @owner.key(@name).last = @target = result
        end
        result = @owner.key(@name).last
        result << create_command(val)
        result
      end
      def []( key )
        unless @target
          @owner[@name] = @target = ChooseEvent.create
          @target.parent = @owner
        end
        @target[key.to_sym]
      end
      def []=( key, val )
        unless @target
          @owner[@name] = @target = ChooseEvent.create
          @target.parent = @owner
        end
        @target[key.to_sym] = create_command(val)
      end
      def integrate( parser ); @target.integrate( parser ) end
      protected
      attr_accessor( :target )
    end
  end
  
  class Repeat < EventBase
    def initialize( data, parent=nil )
      super()
      @data = []
      data.each do | i | @data << create_command( i ) end if data
    end
    def assume( parser ); @parent.assume( parser ) end
    def integrate( parser )
      target = parser.target
      sp = parser.pos
      parser.skip
      ep = parser.pos
      ep ||= parser.template.size
      f = parser.filter_set.clone << parser.last_filter
      prs = PullParser.new( parser.template[sp...ep], 0, target, f )
      @data.each do | i |
        prs.reset
        if i.kind_of?(Repeat)
          template = prs.delete_tag
          prs.reset
          result = create_result( prs )
          iprs = PullParser.new(template, 0, false, f)
          iprs.advance
          result.content = i.integrate(iprs).document
          parser.document << result.result
        else
          parser.document << i.integrate( prs ).document
        end
      end
      parser
    end
    def <<( val ); @data << create_command(val) end
    def []( key ); @data[-1][key] end
    def []=( key, val ) @data[-1][key] = val end
    def last; @data[-1] end
    def last=(val); @data[-1] = val end
  end
  
  class ChangeElement < EventBase
    def self.create( data, allow_filter=true, *filter_set )
      obj = new( data, *filter_set )
      obj.allow_filter = allow_filter
      obj
    end
    attr_accessor( :filter_set, :allow_filter )
    def initialize( data, *filter_set )
      super()
      @data = data; @allow_filter = true; @filter_set = filter_set
    end
    def integrate( parser )
      result = ResultData.new
      result.content = @data.to_s
      parser.skip
      @filter_set.each do | i | i.filter( result ) end
      parser.filter( result ) if allow_filter
      parser.document << result.result
      parser
    end
  end
  
  class ChangeContents < ContentIntegrateBase
    def self.create( data, allow_filter=true, *filter_set )
      obj = new( data, *filter_set )
      obj.allow_filter = allow_filter
      obj
    end
    attr_accessor( :filter_set, :allow_filter )
    def initialize( data, *filter_set )
      @data = data; @allow_filter = true; @filter_set = filter_set
    end
    def create_content( result, parser ); result.content = @data.to_s; result end
  end

  class ChangeContentsAttr < ChangeContents
    def create_content( result, parser )
      #perform attribute substitution
      result.leader = @data.parse_leader(result.leader)
      result.content = @data.to_s if @data.change_content?
      result 
    end
  end
  
  class Delete < EventBase
    include Singleton
    def self.create; self.instance end
    def integrate( parser )
      parser.document << parser.advance.to_s
      while parser.target != false
        parser.advance
        s = parser.advance
      end
      parser.document << s
      parser.skip
      parser.document << parser.last_content
      parser
    end
  end
  
  class DeleteElement < EventBase
    include Singleton
    def self.create; self.instance end
    def integrate( parser )
      parser.skip
      parser
    end
  end
  
  class NoChange < ContentIntegrateBase
    include Singleton
    attr_accessor( :filter_set, :allow_filter )
    def self.create; self.instance end
    def initialize; @allow_filter = true; @filter_set = [] end
    def create_content( result, parser ); result end
  end
  
  class Count < ContentIntegrateBase
    BaseStep = 1
    def self.create( start, step, allow_filter=true, *filter_set )
      obj = new( start, step, *filter_set )
      obj.allow_filter = allow_filter
      obj
    end
    attr_accessor( :filter_set, :allow_filter )
    def initialize( start, step, *filter_set )
      super()
      @data = start; @step = step
      @allow_filter = true; @filter_set = filter_set
    end
    def create_content( result, parser )
      d = @data
      @data += @step
      result.content = d.to_s
      result
    end
    def +( var ); @data += var end
  end
  
  class Proceed < EventBase
    def self.create( data, allow_filter=true, *filter_set )
      obj = new( data, *filter_set )
      obj.allow_filter = allow_filter
      obj
    end
    attr_accessor( :filter_set, :allow_filter )
    def initialize( data, *filter_set )
      @data = data; @filter_set = filter_set
    end
    def integrate( parser )
      @data.call( parser )
      parser
    end
  end
  
  class Execute < ContentIntegrateBase
    def self.create( data, allow_filter=true, *filter_set )
      obj = new( data, *filter_set )
      obj.allow_filter = allow_filter
      obj
    end
    attr_accessor( :filter_set, :allow_filter )
    def initialize( data, *filter_set )
      super()
      @data = data; @filter_set = filter_set
    end
    
    def create_content( result, parser )
      begin
        result.content = @data.method( parser.command ).call
      rescue
        raise "#{parser.last_target}##{parser.command} is not correct Command"
      end
      result
    end
  end
  
  
  module Filter
    def self.reset
      RotateValue.reset
    end
    def self.create_filter( filter_name, target )
      if filter_name == 'SanitizeXML'
        SanitizeXML
      elsif filter_name == 'DeleteTag'
        DeleteTag
      elsif filter_name == 'Delete'
        Delete
      elsif (/RotateValue/.match(filter_name) )
        RotateValue.create( filter_name, target )
      else
        raise "#{filter_name} is not correct Filter"
      end
    end
    class FilterBase
      def self.filter( result ); result end
      def filter( result ); result end
    end
    class SanitizeXML < FilterBase
      def self.filter( result )
        result.content = CGI::escapeHTML( result.content )
        result
      end
    end
    class Delete < FilterBase
      def self.filter( result )
        result.leader = ''; result.terminator = ''; result.content = ''
        result
      end
    end
    class DeleteTag < FilterBase
      def self.filter( result )
        result.leader = ''; result.terminator = ''
        result
      end
    end
    class DeleteIfEmpty < FilterBase
      def self.filter( result )
        if result.content.empty?
          result.leader = ''
          result.terminator = ''
        end
        result
      end
    end
    class RotateValue < FilterBase
      def self.reset; @@type = {} end
      def self.create( filter_text, target )
        filter_text.delete!( " " )
        type_name = "#{target}|#{filter_text}"
        unless @@type[type_name]
          ary = /RotateValue\[([^\]]*)\]/.match(filter_text)[1].split(/,/)
          ary << "" if ary.empty?
          @@type[type_name] = RotateValue.new( ary )
        end
        @@type[type_name]
      end
      def initialize( val ); @val = val; @index = 0 end
      def filter( result )
        result.content << @val[@index]
        @index += 1
        @index = 0 if @val.size <= @index
        result
      end
    end
  end
  
  
  class HandlerForRails
    def self.setup( engine=XMLTemplate )
      @@modeldata = Hash.new do |h, k|
        h[k] = Hash.new { |hash, key| h.default_proc.call(hash, key) }
      end
      ActionView::Base.register_template_handler( "siki", self )
      @@engine = engine
      @@modeldata
    end
    def self.modeldata; @@modeldata end
    def self.modeldata=( var ); @@modeldata = var end
    def initialize( view ); @view = view end
    def render( template, local_assigns={} )
      data = @@modeldata.to_hash.merge(local_assigns)
      @@engine.new( template ).parse( data )
    end
  end
end

__END__

---------------------------------------------------------------------------
SikiTemplate

---------------------------------------------------------------------------
Copyright (C) 2004 Nowake(野分) nowake@fircewinds.net
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:

  * Redistributions of source code must retain the above copyright notice,
    this list of conditions and the following disclaimer.
  * Redistributions in binary form must reproduce the above copyright notice,
    this list of conditions and the following disclaimer in the documentation
    and/or other materials provided with the distribution.
  * Neither the name of the Nowake(野分) nor the names of its contributors
    may be used to endorse or promote products derived from this software
    without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
THE POSSIBILITY OF SUCH DAMAGE.
---------------------------------------------------------------------------
Copyright (c) 2004, 2005 Nowake(野分) nowake@fircewinds.net
All rights reserved.

    ソースコード形式かバイナリ形式か、変更するかしないかを問わず、以下の条件を
    満たす場合に限り、再頒布および使用が許可されます。

    * ソースコードを再頒布する場合、上記の著作権表示、本条件一覧、および下記
      免責条項を含めること。
    * バイナリ形式で再頒布する場合、頒布物に付属のドキュメント等の資料に、
      上記の著作権表示、本条件一覧、および下記免責条項を含めること。
    * 書面による特別の許可なしに、本ソフトウェアから派生した製品の宣伝または
      販売促進に、Nowake(野分)の名前またはコントリビューターの名前を使用しては
      ならない。

    本ソフトウェアは、著作権者およびコントリビューターによって「現状のまま」
    提供されており、明示黙示を問わず、商業的な使用可能性、および特定の目的に
    対する適合性に関する暗黙の保証も含め、またそれに限定されない、いかなる
    保証もありません。
    著作権者もコントリビューターも、事由のいかんを問わず、損害発生の原因いかん
    を問わず、かつ責任の根拠が契約であるか厳格責任であるか（過失その他の）
    不法行為であるかを問わず、仮にそのような損害が発生する可能性を知らされていた
    としても、本ソフトウェアの使用によって発生した（代替品または代用サービスの
    調達、使用の喪失、データの喪失、利益の喪失、業務の中断も含め、またそれに
    限定されない）直接損害、間接損害、偶発的な損害、特別損害、懲罰的損害、
    または結果損害について、一切責任を負わないものとします。
-------------------------------------------------------------------------------
