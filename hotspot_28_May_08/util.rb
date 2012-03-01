class EnumeratedType
 class <<self
   def const_missing(sym)
     obj = new(sym.to_s)
     const_set(sym, obj)
   end
 end

 def initialize(str)
   @symbol = str
 end

 def to_s
   "#{@symbol}"
 end

 def ==(other)
   self.to_s == other.to_s
 end

 # make new private
 private_class_method :new, :allocate
end
