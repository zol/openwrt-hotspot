$: << '..'

require 'drb'
require 'hotlib'

DRb.start_service()
obj = DRbObject.new(nil, HotConfig::URI)

obj.addnew(MACAddress.random)
