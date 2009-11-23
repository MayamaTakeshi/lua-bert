local bits = require 'bert.bits'
local Types = require 'bert.types'
local sym = require 'bert.sym'
local tuple = require 'bert.tuple'

local string = string
local setmetatable = setmetatable
local error = error
local table = table
local type = type
local ipairs = ipairs
local unpack = unpack

module('bert.encode')

Encode = {}
Encode.__index = Encode

function Encode:new()
	return setmetatable({ out = {} }, self)
end

function Encode:str()
	return string.char(unpack(self.out))
end

function Encode:write_any(obj)
	self:write_1(Types.MAGIC)
	self:write_any_raw(obj)
end

function Encode:write_any_raw(obj)
	local obj_type = type(obj)
	if obj_type == "string" then
		self:write_binary(obj)
	elseif tuple.is_tuple(obj) then
		self:write_tuple(obj)
	elseif sym.is_symbol(obj) then
		self:write_symbol(obj)
	elseif obj_type == "table" then
		if obj[1] then
			self:write_list(obj)		
		else			
			error "should not happen"
		end		
	elseif obj_type == "number" then
		self:write_fixnum(obj)
	end
end

function Encode:write_1(byte)
	self.out[#self.out+1] = byte
end

function Encode:write_2(short)
	local bb = bits.to_bits(short) -- TODO rename variables
	local b = bits.bytes(2, bb)
	for i=1,2 do
		self:write_1(b[i])
	end
end

function Encode:write_4(long)
	local bb = bits.to_bits(long) -- TODO rename variables
	local b = bits.bytes(4, bb)
	for i=1,4 do
		self:write_1(b[i])
	end
end

function Encode:write_float(float)
end

function Encode:write_boolean(bool)
	error "not tested"
	self:write_symbol(sym.s(tostring(bool)))
end

function Encode:write_symbol(sym)
	self:write_1(Types.ATOM)
	self:write_2(sym.name:len())
	self:write_string(sym.name)
end

function Encode:write_string(str)
	local bytes = { str:byte(1, str:len()) }
	for _, b in ipairs(bytes) do
		table.insert(self.out, b)
	end
end

function Encode:write_tuple(data)
	if #data < 256 then
		self:write_1(Types.SMALL_TUPLE)
		self:write_1(#data)
	else
		self:write_1(Types.LARGE_TUPLE)
		self:write_4(#data)
	end
	
	for _, d in ipairs(data) do
		self:write_any_raw(d)
	end
end

function Encode:write_list(data)
	if #data == 0 then
		self:write_1(Types.NIL)
	else
		self:write_1(Types.LIST)
		self:write_4(#data)
		for _, d in ipairs(data) do
			self:write_any_raw(d)
		end
		self:write_1(Types.NIL)
	end
end

function Encode:write_binary(data)
	self:write_1(Types.BIN)
	self:write_4(data:len())
	self:write_string(data)
end

function Encode:write_fixnum(num)
  if num >= 0 and num < 256 then
    self:write_1(Types.SMALL_INT)
    self:write_1(num)
  -- elsif num <= MAX_INT && num >= MIN_INT
	else
    self:write_1(Types.INT)
    self:write_4(num)
  -- else
  --   write_bignum num
  end
end
