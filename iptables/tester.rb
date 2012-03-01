$: << ".."

require 'hotlib'
require 'iptables'

tables = IPTables.instance

tables.allow(MACAddress.random)
