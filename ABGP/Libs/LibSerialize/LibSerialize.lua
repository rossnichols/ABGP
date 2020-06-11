--[[
This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as published by
the Free Software Foundation, either version 3 of the License, or
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public License
along with this program.  If not, see https://www.gnu.org/licenses/.

Credits and Disclaimer:
The following projects are used to help implement this project.
Their original licenses shall be complied with when used.

1. LibDeflate, by Haoqian He. https://github.com/SafeteeWoW/LibDeflate
    Licensed under GPLv3.
2. lua-MessagePack, by François Perrad. https://framagit.org/fperrad/lua-MessagePack
    Licensed under MIT.
3. LibQuestieSerializer, by aero. https://github.com/AeroScripts/LibQuestieSerializer
    Licensed under GPLv3.
]]

local LibSerialize

do
	-- Semantic version. all lowercase.
	-- Suffix can be alpha1, alpha2, beta1, beta2, rc1, rc2, etc.
	-- NOTE: Two version numbers needs to modify.
	-- 1. On the top of LibSerialize.lua
	-- 2. _VERSION
	-- 3. _MINOR

	-- version to store the official version of LibSerialize
	local _VERSION = "0.1.0-prerelease"

	-- When MAJOR is changed, I should name it as LibSerialize2
	local _MAJOR = "LibSerialize"

	-- Update this whenever a new version, for LibStub version registration.
	local _MINOR = 1

	local _COPYRIGHT =
	"LibSerialize ".. _VERSION
	.. " Copyright (C) 2020 Ross Nichols."
	.. " License LGPLv3+: GNU Lesser General Public License version 3 or later"

	-- Register in the World of Warcraft library "LibStub" if detected.
	if LibStub then
		local lib, minor = LibStub:GetLibrary(_MAJOR, true)
		if lib and minor and minor >= _MINOR then -- No need to update.
			return lib
		else -- Update or first time register
			LibSerialize = LibStub:NewLibrary(_MAJOR, _MINOR)
			-- NOTE: It is important that new version has implemented
			-- all exported APIs and tables in the old version,
			-- so the old library is fully garbage collected,
			-- and we 100% ensure the backward compatibility.
		end
	else -- "LibStub" is not detected.
		LibSerialize = {}
	end

	LibSerialize._VERSION = _VERSION
	LibSerialize._MAJOR = _MAJOR
	LibSerialize._MINOR = _MINOR
	LibSerialize._COPYRIGHT = _COPYRIGHT
end

-- localize Lua api for faster access.
local assert = assert
local error = error
local pairs = pairs
local ipairs = ipairs
local string_byte = string.byte
local string_char = string.char
local string_sub = string.sub
local table_concat = table.concat
local bit_band = bit.band
local bit_lshift = bit.lshift
local bit_rshift = bit.rshift
local math_huge = math.huge
local math_modf = math.modf
local type = type
local max = max
local frexp = frexp
local ldexp = ldexp
local floor = floor
local pcall = pcall
local print = print


--[[---------------------------------------------------------------------------
    Helper functions.
--]]---------------------------------------------------------------------------

local function Pack(a, b, c, d)
    return bit_lshift(a, 24) + bit_lshift(b, 16) + bit_lshift(c, 8) + d
end

local function Unpack(val)
    return (bit_rshift(val % 24, 256)),
           (bit_rshift(val % 16, 256)),
           (bit_rshift(val % 8, 256)),
           (val % 256)
end

local function GetRequiredBytes(value)
    if value < 256 then return 1 end
    if value < 65536 then return 2 end
    if value < 4294967296 then return 4 end
    return 8
end

-- local debugPrinting = false
-- -- local debugPrinting = true
-- local function debugPrint(...)
--     if debugPrinting then
--         print(...)
--         -- ABGP:WriteLogged("SERIALIZE", table_concat({tostringall(...)}, " "))
--     end
-- end


--[[---------------------------------------------------------------------------
    Code taken from LibDeflate: CreateReader, CreateWriter.
    Exposes a mechanism to read/write bytes from/to a buffer.
--]]---------------------------------------------------------------------------

-- Converts i to 2^i, (0<=i<=32)
-- This is used to implement bit left shift and bit right shift.
-- "x >> y" in C:   "(x-x%_pow2[y])/_pow2[y]" in Lua
-- "x << y" in C:   "x*_pow2[y]" in Lua
local _pow2 = {}

-- Converts any byte to a character, (0<=byte<=255)
local _byte_to_char = {}

-- _reverseBitsTbl[len][val] stores the bit reverse of
-- the number with bit length "len" and value "val"
-- For example, decimal number 6 with bits length 5 is binary 00110
-- It's reverse is binary 01100,
-- which is decimal 12 and 12 == _reverseBitsTbl[5][6]
-- 1<=len<=9, 0<=val<=2^len-1
-- The reason for 1<=len<=9 is that the max of min bitlen of huffman code
-- of a huffman alphabet is 9?
local _reverse_bits_tbl = {}

for i = 0, 255 do
    _byte_to_char[i] = string_char(i)
end

do
    local pow = 1
    for i = 0, 32 do
        _pow2[i] = pow
        pow = pow * 2
    end
end

for i = 1, 9 do
    _reverse_bits_tbl[i] = {}
    for j=0, _pow2[i+1]-1 do
        local reverse = 0
        local value = j
        for _ = 1, i do
            -- The following line is equivalent to "res | (code %2)" in C.
            reverse = reverse - reverse%2
                + (((reverse%2==1) or (value % 2) == 1) and 1 or 0)
            value = (value-value%2)/2
            reverse = reverse * 2
        end
        _reverse_bits_tbl[i][j] = (reverse-reverse%2)/2
    end
end

-- partial flush to save memory
local _FLUSH_MODE_MEMORY_CLEANUP = 0
-- full flush with partial bytes
local _FLUSH_MODE_OUTPUT = 1
-- write bytes to get to byte boundary
local _FLUSH_MODE_BYTE_BOUNDARY = 2
-- no flush, just get num of bits written so far
local _FLUSH_MODE_NO_FLUSH = 3

--[[
    Create an empty writer to easily write stuffs as the unit of bits.
    Return values:
    1. WriteBits(code, bitlen):
    2. WriteString(str):
    3. Flush(mode):
--]]
local function CreateWriter()
    local buffer_size = 0
    local cache = 0
    local cache_bitlen = 0
    local total_bitlen = 0
    local buffer = {}
    -- When buffer is big enough, flush into result_buffer to save memory.
    local result_buffer = {}

    -- Write bits with value "value" and bit length of "bitlen" into writer.
    -- @param value: The value being written
    -- @param bitlen: The bit length of "value"
    -- @return nil
    local function WriteBits(value, bitlen)
        -- debugPrint("Writing value", value, "bitlen", bitlen)
        cache = cache + value * _pow2[cache_bitlen]
        cache_bitlen = cache_bitlen + bitlen
        total_bitlen = total_bitlen + bitlen
        -- debugPrint("cache", cache, cache_bitlen)
        -- Only bulk to buffer every 4 bytes. This is quicker.
        if cache_bitlen >= 32 then
            -- debugPrint("cacheflush", cache)
            buffer_size = buffer_size + 1
            buffer[buffer_size] =
                _byte_to_char[cache % 256]
                .._byte_to_char[((cache-cache%256)/256 % 256)]
                .._byte_to_char[((cache-cache%65536)/65536 % 256)]
                .._byte_to_char[((cache-cache%16777216)/16777216 % 256)]
            local rshift_mask = _pow2[32 - cache_bitlen + bitlen]
            cache = (value - value%rshift_mask)/rshift_mask
            cache_bitlen = cache_bitlen - 32

            -- debugPrint(buffer_size, total_bitlen, string_byte(buffer[buffer_size], 1, 4))
        end
    end

    -- Write the entire string into the writer.
    -- @param str The string being written
    -- @return nil
    local function WriteString(str)
        -- debugPrint("Writing string len", #str, "bitlen", #str * 8)
        for _ = 1, cache_bitlen, 8 do
            buffer_size = buffer_size + 1
            buffer[buffer_size] = string_char(cache % 256)
            cache = (cache-cache%256)/256

            -- debugPrint(buffer_size, total_bitlen, string_byte(buffer[buffer_size]))
        end
        cache_bitlen = 0
        buffer_size = buffer_size + 1
        buffer[buffer_size] = str
        total_bitlen = total_bitlen + #str*8

        -- debugPrint(buffer_size, total_bitlen, buffer[buffer_size])
    end

    -- Flush current stuffs in the writer and return it.
    -- This operation will free most of the memory.
    -- @param mode See the descrtion of the constant and the source code.
    -- @return The total number of bits stored in the writer right now.
    -- for byte boundary mode, it includes the padding bits.
    -- for output mode, it does not include padding bits.
    -- @return Return the outputs if mode is output.
    local function FlushWriter(mode)
        if mode == _FLUSH_MODE_NO_FLUSH then
            return total_bitlen
        end

        if mode == _FLUSH_MODE_OUTPUT
            or mode == _FLUSH_MODE_BYTE_BOUNDARY then
            -- Full flush, also output cache.
            -- Need to pad some bits if cache_bitlen is not multiple of 8.
            local padding_bitlen = (8 - cache_bitlen % 8) % 8

            if cache_bitlen > 0 then
                -- padding with all 1 bits, mainly because "\000" is not
                -- good to be tranmitted. I do this so "\000" is a little bit
                -- less frequent.
                cache = cache - _pow2[cache_bitlen]
                    + _pow2[cache_bitlen+padding_bitlen]
                for _ = 1, cache_bitlen, 8 do
                    buffer_size = buffer_size + 1
                    buffer[buffer_size] = _byte_to_char[cache % 256]
                    cache = (cache-cache%256)/256
                end

                cache = 0
                cache_bitlen = 0
            end
            if mode == _FLUSH_MODE_BYTE_BOUNDARY then
                total_bitlen = total_bitlen + padding_bitlen
                return total_bitlen
            end
        end

        local flushed = table_concat(buffer)
        buffer = {}
        buffer_size = 0
        result_buffer[#result_buffer+1] = flushed

        if mode == _FLUSH_MODE_MEMORY_CLEANUP then
            return total_bitlen
        else
            return total_bitlen, table_concat(result_buffer)
        end
    end

    return WriteBits, WriteString, FlushWriter
end

--[[
    Create a reader to easily reader stuffs as the unit of bits.
    Return values:
    1. ReadBytes(bytelen, buffer, buffer_size)
--]]
local function CreateReader(input_string)
    local input = input_string
    local input_strlen = #input_string
    local input_next_byte_pos = 1
    local cache_bitlen = 0
    local cache = 0

    -- Read some bytes from the reader.
    -- Assume reader is on the byte boundary.
    -- @param bytelen The number of bytes to be read.
    -- @param buffer The byte read will be stored into this buffer.
    -- @param buffer_size The buffer will be modified starting from
    --    buffer[buffer_size+1], ending at buffer[buffer_size+bytelen-1]
    -- @return the new buffer_size
    local function ReadBytes(bytelen, buffer, buffer_size)
        assert(cache_bitlen % 8 == 0)

        local byte_from_cache = (cache_bitlen/8 < bytelen)
            and (cache_bitlen/8) or bytelen
        for _=1, byte_from_cache do
            local byte = cache % 256
            buffer_size = buffer_size + 1
            buffer[buffer_size] = string_char(byte)
            cache = (cache - byte) / 256
        end
        cache_bitlen = cache_bitlen - byte_from_cache*8
        bytelen = bytelen - byte_from_cache
        if (input_strlen - input_next_byte_pos - bytelen + 1) * 8
            + cache_bitlen < 0 then
            return -1 -- out of input
        end
        for i=input_next_byte_pos, input_next_byte_pos+bytelen-1 do
            buffer_size = buffer_size + 1
            buffer[buffer_size] = string_sub(input, i, i)
        end

        input_next_byte_pos = input_next_byte_pos + bytelen
        return buffer_size
    end

    return ReadBytes
end


--[[---------------------------------------------------------------------------
    Code taken/modified from lua-MessagePack: FloatBitsToInt, IntBitsToFloat.
    Used for serializing/deserializing floating point numbers.
    NOTE: although Lua uses double precision floating point numbers (by default),
    the serialization only uses single precision, for space saving.
--]]---------------------------------------------------------------------------

local function FloatBitsToInt(n)
    local sign = 0
    if n < 0.0 then
        sign = 0x80
        n = -n
    end
    local mant, expo = frexp(n)
    if mant ~= mant then
        return Pack(0xFF, 0x88, 0x00, 0x00) -- nan
    elseif mant == math_huge or expo > 0x80 then
        if sign == 0 then
            return Pack(0x7F, 0x80, 0x00, 0x00) -- inf
        else
            return Pack(0xFF, 0x80, 0x00, 0x00) -- -inf
        end
    elseif (mant == 0.0 and expo == 0) or expo < -0x7E then
        return Pack(sign, 0x00, 0x00, 0x00)-- zero
    else
        expo = expo + 0x7E
        mant = floor((mant * 2.0 - 1.0) * ldexp(0.5, 24))
        return Pack(sign + floor(expo / 0x2), (expo % 0x2) * 0x80 + floor(mant / 0x10000), floor(mant / 0x100) % 0x100, mant % 0x100)
    end
end

local function IntBitsToFloat(int)
    local b1, b2, b3, b4 = Unpack(int)
    local sign = b1 > 0x7F
    local expo = (b1 % 0x80) * 0x2 + floor(b2 / 0x80)
    local mant = ((b2 % 0x80) * 0x100 + b3) * 0x100 + b4
    if sign then
        sign = -1
    else
        sign = 1
    end
    local n
    if mant == 0 and expo == 0 then
        n = sign * 0.0
    elseif expo == 0xFF then
        if mant == 0 then
            n = sign * math_huge
        else
            n = 0.0/0.0
        end
    else
        n = sign * ldexp(1.0 + mant / 0x800000, expo - 0x7F)
    end
    return n
end


--[[---------------------------------------------------------------------------
    Hashing support: an implementation of the djb2 hash function.
    See http://www.cs.yorku.ca/~oz/hash.html.
--]]---------------------------------------------------------------------------

function LibSerialize:Hash(value)
    assert(type(value) == "string")

    local h = 5381
    for i = 1, #value do
        h = bit_band((33 * h + string_byte(value, i)), 4294967295)
    end
    return h
end

-- As strings are serialized or deserialized, their hashes are stored
-- in a lookup table so that subsequent uses of the same string are
-- referenced by their hash instead of writing out the entire string.
LibSerialize._stringHashes = {}
LibSerialize._stringHashesReversed = {}

function LibSerialize:_AddHash(str)
    local hash = self:Hash(str)
    if self._stringHashesReversed[hash] then
        -- dont add, also prevents collissions
        return
    end
    self._stringHashes[str] = hash
    self._stringHashesReversed[hash] = str
end

function LibSerialize:_ClearHashes()
    self._stringHashes = {}
    self._stringHashesReversed = {}
end


--[[---------------------------------------------------------------------------
    Read (deserialization) support.
--]]---------------------------------------------------------------------------

function LibSerialize:_ReadByte()
    -- debugPrint("Reading byte")

    self._readBytes(1, self._readBuffer, 0)
    return string_byte(self._readBuffer[1])
end

function LibSerialize:_ReadInt16()
    -- debugPrint("Reading int16")

    self._readBytes(2, self._readBuffer, 0)
    return Pack(0,
                0,
                string_byte(self._readBuffer[2]),
                string_byte(self._readBuffer[1]))
end

function LibSerialize:_ReadInt32()
    -- debugPrint("Reading int32")

    self._readBytes(4, self._readBuffer, 0)
    return Pack(string_byte(self._readBuffer[4]),
                string_byte(self._readBuffer[3]),
                string_byte(self._readBuffer[2]),
                string_byte(self._readBuffer[1]))
end

function LibSerialize:_ReadInt64()
    -- debugPrint("Reading int64")

    local top, bottom = self:_ReadInt32(), self:_ReadInt32()
    return (top * 4294967296) + bottom
end

function LibSerialize:_ReadObject()
    local typ = self:_ReadByte()
    -- debugPrint("Found type", typ)

    local numReaderIndices = #self.ReaderTable
    if typ > numReaderIndices then
        -- The object was a number encoded in the type byte.
        return typ - numReaderIndices - 1
    end
    return self.ReaderTable[typ](self)
end

function LibSerialize:_ReadTable(entryCount, ret)
    -- debugPrint("Extracting keys/values for table,", entryCount)

    ret = ret or {}
    for i = 1, entryCount do
        local key, value = self:_ReadObject(), self:_ReadObject()
        ret[key] = value
    end
    return ret
end

function LibSerialize:_ReadArray(entryCount, ret)
    -- debugPrint("Extracting values for array,", entryCount)

    ret = ret or {}
    for i = 1, entryCount do
        ret[i] = self:_ReadObject()
    end
    return ret
end

function LibSerialize:_ReadMixed(arrayCount, tableCount)
    -- debugPrint("Extracting values for array,", arrayCount, tableCount)

    local ret = {}
    self:_ReadArray(arrayCount, ret)
    self:_ReadTable(tableCount, ret)
    return ret
end

function LibSerialize:_ReadString(len)
    -- debugPrint("Reading string,", len)

    local size = self._readBytes(len, self._readBuffer, 0)
    local value = table_concat(self._readBuffer, "", 1, size)
    self:_AddHash(value)
    return value
end

-- NOTE: must not skip any indices, for number packing to work properly.
LibSerialize.ReaderTable = {
    -- Numbers
    [1]  = function(self) return self:_ReadByte() end,
    [2]  = function(self) return -self:_ReadByte() end,
    [3]  = function(self) return self:_ReadInt16() end,
    [4]  = function(self) return -self:_ReadInt16() end,
    [5]  = function(self) return self:_ReadInt32() end,
    [6]  = function(self) return -self:_ReadInt32() end,
    [7]  = function(self) return self:_ReadInt64() end,
    [8]  = function(self) return -self:_ReadInt64() end,
    [9]  = function(self) return IntBitsToFloat(self:_ReadInt32()) end,

    -- Strings (encoded as size + buffer)
    [10] = function(self) return self:_ReadString(self:_ReadByte()) end,
    [11] = function(self) return self:_ReadString(self:_ReadInt16()) end,
    [12] = function(self) return self:_ReadString(self:_ReadInt32()) end,
    [13] = function(self) return self:_ReadString(self:_ReadInt64()) end,
    [14] = function(self) return self._stringHashesReversed[self:_ReadInt32()] end,

    -- Booleans
    [15] = function(self) return true end,
    [16] = function(self) return false end,

    -- Tables (encoded as count + key/value pairs)
    [17] = function(self) return self:_ReadTable(self:_ReadByte()) end,
    [18] = function(self) return self:_ReadTable(self:_ReadInt16()) end,
    [19] = function(self) return self:_ReadTable(self:_ReadInt32()) end,
    [20] = function(self) return self:_ReadTable(self:_ReadInt64()) end,

    -- Arrays (encoded as count + values)
    [21] = function(self) return self:_ReadArray(self:_ReadByte()) end,
    [22] = function(self) return self:_ReadArray(self:_ReadInt16()) end,
    [23] = function(self) return self:_ReadArray(self:_ReadInt32()) end,
    [24] = function(self) return self:_ReadArray(self:_ReadInt64()) end,

    -- Mixed array/tables (encoded as arrayCount + tableCount + arrayValues + key/value pairs)
    [25] = function(self) return self:_ReadMixed(self:_ReadByte(), self:_ReadByte()) end,
    [26] = function(self) return self:_ReadMixed(self:_ReadInt16(), self:_ReadInt16()) end,
    [27] = function(self) return self:_ReadMixed(self:_ReadInt32(), self:_ReadInt32()) end,
    [28] = function(self) return self:_ReadMixed(self:_ReadInt64(), self:_ReadInt64()) end,
}


--[[---------------------------------------------------------------------------
    Write (serialization) support.
--]]---------------------------------------------------------------------------

-- Lookup tables to map the number of required bytes to the appropriate
-- reader table index. Note that for numbers, we leave space for the
-- negative versions of each level as well.
local numberIndices = {
    [1] = 1,
    [2] = 3,
    [4] = 5,
    [8] = 7,
}
local stringIndices = {
    [1] = 10,
    [2] = 11,
    [4] = 12,
    [8] = 13,
}
local tableIndices = {
    [1] = 17,
    [2] = 18,
    [4] = 19,
    [8] = 20,
}
local arrayIndices = {
    [1] = 21,
    [2] = 22,
    [4] = 23,
    [8] = 24,
}
local mixedIndices = {
    [1] = 25,
    [2] = 26,
    [4] = 27,
    [8] = 28,
}

function LibSerialize:_WriteKeyValuePair(key, value)
    assert(key ~= nil and value ~= nil)

    local keyType = type(key)
    local valueType = type(value)
    local writeKey = self.WriterTable[keyType] or error(("Unhandled key type: %s"):format(keyType))
    local writeValue = self.WriterTable[valueType] or error(("Unhandled value type: %s"):format(valueType))

    writeKey(self, key)
    writeValue(self, value)
end

function LibSerialize:_WriteByte(value)
    self:_WriteInt(value, 1)
end

function LibSerialize:_WriteInt(value, threshold)
    -- NOTE: Due to LibDeflate's usage of a cache when writing bits,
    -- it's possible to corrupt the cache if it's reaching its limit
    -- and you then write a large number of bits. By writing only
    -- 8 or 16 at a time, the max cached bits is only 40 which is
    -- still reasonable.
    if threshold == 8 then
        local bottom = value % 4294967296
        local a = bottom % 65536
        local b = (bottom - a) / 65536
        local top = (value - bottom) / 4294967296
        local c = top % 65536
        local d = (top - c) / 65536
        self._writeBits(d, 16)
        self._writeBits(c, 16)
        self._writeBits(b, 16)
        self._writeBits(a, 16)
    elseif threshold == 4 then
        local a = value % 65536
        local b = (value - a) / 65536
        self._writeBits(b, 16)
        self._writeBits(a, 16)
    else
        self._writeBits(value, threshold * 8)
    end
end

LibSerialize.WriterTable = {
    ["number"] = function(self, value)
        local _, fract = math_modf(value)
        if fract ~= 0 then
            self.WriterTable["float"](self, value)
        else
            -- debugPrint("Serializing number:", value)
            -- The type byte can be used to store small nonnegative
            -- numbers for all the values that don't correspond to
            -- one with an actual meaning. Calculate how much space
            -- we have to work with.
            local numReaderIndices = #self.ReaderTable
            local maxPacked = 255 - numReaderIndices - 1

            if value >= 0 and value <= maxPacked then
                -- Pack the value into the type byte
                self:_WriteByte(value + numReaderIndices + 1)
            else
                local sign = 0
                if value < 0 then
                    value = -value
                    sign = 1
                end
                local required = GetRequiredBytes(value)
                self:_WriteByte(sign + numberIndices[required])
                self:_WriteInt(value, required)
            end
        end
    end,
    ["float"] = function(self, value)
        -- debugPrint("Serializing float:", value)
        self:_WriteByte(9)
        self:_WriteInt(FloatBitsToInt(value), 4)
    end,
    ["string"] = function(self, value)
        -- debugPrint("Serializing string:", value)
        if self._stringHashes[value] and #value > 3 then
            -- A hash takes up four bytes, whereas a string takes up
            -- the number of bytes required for its len + its len.
            -- For a 4-byte string, we thus need five bytes, so it's
            -- better to use the hashes for anything with len >= 4.
            self:_WriteByte(14)
            self:_WriteInt(self._stringHashes[value], 4)
        else
            local len = #value
            local required = GetRequiredBytes(len)
            self:_WriteByte(stringIndices[required])
            self:_WriteInt(len, required)
            self._writeString(value)
            self:_AddHash(value)
        end
    end,
    ["boolean"] = function(self, value)
        -- debugPrint("Serializing bool:", value)
        self:_WriteByte(value and 15 or 16)
    end,
    ["table"] = function(self, value)
        local count, arraySize = 0, #value
        for key, v in pairs(value) do
            count = count + 1
        end
        if count == arraySize then
            -- debugPrint("Serializing array:", count)
            -- The table is effectively an array. We can avoid writing the keys.
            local required = GetRequiredBytes(count)
            self:_WriteByte(arrayIndices[required])
            self:_WriteInt(count, required)

            for _, v in ipairs(value) do
                local valueType = type(v)
                local writeValue = self.WriterTable[valueType] or error(("Unhandled value type: %s"):format(valueType))

                writeValue(self, v)
            end
        elseif arraySize ~= 0 then
            -- debugPrint("Serializing mixed array-table:", arraySize, count)
            count = count - arraySize;

            -- Use the max required bytes for the two counts.
            local required = max(GetRequiredBytes(count), GetRequiredBytes(arraySize))
            self:_WriteByte(mixedIndices[required])
            self:_WriteInt(arraySize, required)
            self:_WriteInt(count, required)

            for _, v in ipairs(value) do
                local valueType = type(v)
                local writeValue = self.WriterTable[valueType] or error(("Unhandled value type: %s"):format(valueType))

                writeValue(self, v)
            end

            local mapCount = 0
            for k, v in pairs(value) do
                if type(k) ~= "number" or k < 1 or k > arraySize then
                    mapCount = mapCount + 1
                    self:_WriteKeyValuePair(k, v)
                end
            end
            assert(mapCount == count)
        else
            -- debugPrint("Serializing table:", count)
            local required = GetRequiredBytes(count)
            self:_WriteByte(tableIndices[required])
            self:_WriteInt(count, required)

            for k, v in pairs(value) do
                self:_WriteKeyValuePair(k, v)
            end
        end
    end,
}


--[[---------------------------------------------------------------------------
    API support.
--]]---------------------------------------------------------------------------

function LibSerialize:Serialize(input)
    self:_ClearHashes()
    local WriteBits, WriteString, FlushWriter = CreateWriter()

    self._writeBits = WriteBits
    self._writeString = WriteString
    self._flushWriter = FlushWriter
    self:_WriteKeyValuePair(1, input)

    local total_bitlen, result = FlushWriter(_FLUSH_MODE_OUTPUT)
    return result
end

function LibSerialize:_Deserialize(input)
    self:_ClearHashes()
    local ReadBytes = CreateReader(input)

    self._readBuffer = {}
    self._readBytes = ReadBytes
    local data = self:_ReadTable(1)
    return data[1]
end

function LibSerialize:Deserialize(input)
    return pcall(LibSerialize._Deserialize, self, input)
end
