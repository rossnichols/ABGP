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

    -- Update this if a breaking change is introduced in the compression,
    -- so that older data can be identified and decoded properly.
    local _COMPRESSION_VERSION = 1

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
    LibSerialize._COMPRESSION_VERSION = _COMPRESSION_VERSION
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

local function Pack2(a, b)
    return bit_lshift(a, 8) + b
end

local function Pack4(a, b, c, d)
    return bit_lshift(a, 24) + bit_lshift(b, 16) + bit_lshift(c, 8) + d
end

local function Unpack2(val)
    return (bit_rshift(val, 8) % 256),
           (val % 256)
end

local function Unpack4(val)
    return (bit_rshift(val, 24) % 256),
           (bit_rshift(val, 16) % 256),
           (bit_rshift(val, 8) % 256),
           (val % 256)
end

local function GetRequiredBytes(value, allow8)
    if value < 256 then return 1 end
    if value < 65536 then return 2 end
    if value < 4294967296 then return 4 end

    -- Most numbers (like counts) should fit into four bytes.
    -- The caller has to explicitly opt into the larger size.
    if not allow8 then
        error("Object limit exceeded")
    end
    return 8
end

local debugPrint = function(...)
    print(...)
    -- ABGP:WriteLogged("SERIALIZE", table_concat({tostringall(...)}, " "))
end


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
        -- Only bulk to buffer every 4 bytes. This is quicker.
        if cache_bitlen >= 32 then
            buffer_size = buffer_size + 1
            buffer[buffer_size] =
                _byte_to_char[cache % 256]
                .._byte_to_char[((cache-cache%256)/256 % 256)]
                .._byte_to_char[((cache-cache%65536)/65536 % 256)]
                .._byte_to_char[((cache-cache%16777216)/16777216 % 256)]
            local rshift_mask = _pow2[32 - cache_bitlen + bitlen]
            cache = (value - value%rshift_mask)/rshift_mask
            cache_bitlen = cache_bitlen - 32
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
        end
        cache_bitlen = 0
        buffer_size = buffer_size + 1
        buffer[buffer_size] = str
        total_bitlen = total_bitlen + #str*8
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
        return Pack4(0xFF, 0x88, 0x00, 0x00) -- nan
    elseif mant == math_huge or expo > 0x80 then
        if sign == 0 then
            return Pack4(0x7F, 0x80, 0x00, 0x00) -- inf
        else
            return Pack4(0xFF, 0x80, 0x00, 0x00) -- -inf
        end
    elseif (mant == 0.0 and expo == 0) or expo < -0x7E then
        return Pack4(sign, 0x00, 0x00, 0x00)-- zero
    else
        expo = expo + 0x7E
        mant = floor((mant * 2.0 - 1.0) * ldexp(0.5, 24))
        return Pack4(sign + floor(expo / 0x2), (expo % 0x2) * 0x80 + floor(mant / 0x10000), floor(mant / 0x100) % 0x100, mant % 0x100)
    end
end

local function IntBitsToFloat(int)
    local b1, b2, b3, b4 = Unpack4(int)
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
    Object reuse:
    As strings are serialized or deserialized, they are stored in this lookup
    table in case they're encountered again, at which point they can be referenced
    by their index into this table rather than repeating the string contents.
--]]---------------------------------------------------------------------------

LibSerialize._existingCount = 0
LibSerialize._existingEntries = {}
LibSerialize._existingEntriesReversed = {}

function LibSerialize:_AddExisting(value)
    self._existingCount = self._existingCount + 1
    self._existingEntries[value] = self._existingCount
    self._existingEntriesReversed[self._existingCount] = value
end

function LibSerialize:_ClearExisting()
    self._existingCount = 0
    self._existingEntries = {}
    self._existingEntriesReversed = {}
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
    return Pack2(string_byte(self._readBuffer[2]),
                 string_byte(self._readBuffer[1]))
end

function LibSerialize:_ReadInt32()
    -- debugPrint("Reading int32")

    self._readBytes(4, self._readBuffer, 0)
    return Pack4(string_byte(self._readBuffer[4]),
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
    -- debugPrint("Extracting values for mixed table,", arrayCount, tableCount)

    local ret = {}
    self:_ReadArray(arrayCount, ret)
    self:_ReadTable(tableCount, ret)
    return ret
end

function LibSerialize:_ReadString(len)
    -- debugPrint("Reading string,", len)

    self._readBytes(len, self._readBuffer, 0)
    local value = table_concat(self._readBuffer, "", 1, len)
    self:_AddExisting(value)
    return value
end

LibSerialize._ReaderIndex = {
    NUM_8_POS = 1,
    NUM_8_NEG = 2,
    NUM_16_POS = 3,
    NUM_16_NEG = 4,
    NUM_32_POS = 5,
    NUM_32_NEG = 6,
    NUM_64_POS = 7,
    NUM_64_NEG = 8,
    NUM_FLOAT = 9,

    STR_8 = 10,
    STR_16 = 11,
    STR_32 = 12,

    BOOL_T = 13,
    BOOL_F = 14,

    TABLE_8 = 15,
    TABLE_16 = 16,
    TABLE_32 = 17,

    ARRAY_8 = 18,
    ARRAY_16 = 19,
    ARRAY_32 = 20,

    MIXED_8 = 21,
    MIXED_16 = 22,
    MIXED_32 = 23,

    EXISTING_8 = 24,
    EXISTING_16 = 25,
    EXISTING_32 = 26,
}

-- NOTE: must not skip any indices, for number packing to work properly.
LibSerialize.ReaderTable = {
    -- Numbers
    [LibSerialize._ReaderIndex.NUM_8_POS]  = function(self) return self:_ReadByte() end,
    [LibSerialize._ReaderIndex.NUM_8_NEG]  = function(self) return -self:_ReadByte() end,
    [LibSerialize._ReaderIndex.NUM_16_POS] = function(self) return self:_ReadInt16() end,
    [LibSerialize._ReaderIndex.NUM_16_NEG] = function(self) return -self:_ReadInt16() end,
    [LibSerialize._ReaderIndex.NUM_32_POS] = function(self) return self:_ReadInt32() end,
    [LibSerialize._ReaderIndex.NUM_32_NEG] = function(self) return -self:_ReadInt32() end,
    [LibSerialize._ReaderIndex.NUM_64_POS] = function(self) return self:_ReadInt64() end,
    [LibSerialize._ReaderIndex.NUM_64_NEG] = function(self) return -self:_ReadInt64() end,
    [LibSerialize._ReaderIndex.NUM_FLOAT]  = function(self) return IntBitsToFloat(self:_ReadInt32()) end,

    -- Strings (encoded as size + buffer)
    [LibSerialize._ReaderIndex.STR_8]  = function(self) return self:_ReadString(self:_ReadByte()) end,
    [LibSerialize._ReaderIndex.STR_16] = function(self) return self:_ReadString(self:_ReadInt16()) end,
    [LibSerialize._ReaderIndex.STR_32] = function(self) return self:_ReadString(self:_ReadInt32()) end,

    -- Booleans
    [LibSerialize._ReaderIndex.BOOL_T] = function(self) return true end,
    [LibSerialize._ReaderIndex.BOOL_F] = function(self) return false end,

    -- Tables (encoded as count + key/value pairs)
    [LibSerialize._ReaderIndex.TABLE_8]  = function(self) return self:_ReadTable(self:_ReadByte()) end,
    [LibSerialize._ReaderIndex.TABLE_16] = function(self) return self:_ReadTable(self:_ReadInt16()) end,
    [LibSerialize._ReaderIndex.TABLE_32] = function(self) return self:_ReadTable(self:_ReadInt32()) end,

    -- Arrays (encoded as count + values)
    [LibSerialize._ReaderIndex.ARRAY_8]  = function(self) return self:_ReadArray(self:_ReadByte()) end,
    [LibSerialize._ReaderIndex.ARRAY_16] = function(self) return self:_ReadArray(self:_ReadInt16()) end,
    [LibSerialize._ReaderIndex.ARRAY_32] = function(self) return self:_ReadArray(self:_ReadInt32()) end,

    -- Mixed array/tables (encoded as arrayCount + tableCount + arrayValues + key/value pairs)
    [LibSerialize._ReaderIndex.MIXED_8]  = function(self) return self:_ReadMixed(self:_ReadByte(), self:_ReadByte()) end,
    [LibSerialize._ReaderIndex.MIXED_16] = function(self) return self:_ReadMixed(self:_ReadInt16(), self:_ReadInt16()) end,
    [LibSerialize._ReaderIndex.MIXED_32] = function(self) return self:_ReadMixed(self:_ReadInt32(), self:_ReadInt32()) end,

    -- Existing entries previously added to bookkeeping
    [LibSerialize._ReaderIndex.EXISTING_8]  = function(self) return self._existingEntriesReversed[self:_ReadByte()] end,
    [LibSerialize._ReaderIndex.EXISTING_16] = function(self) return self._existingEntriesReversed[self:_ReadInt16()] end,
    [LibSerialize._ReaderIndex.EXISTING_32] = function(self) return self._existingEntriesReversed[self:_ReadInt32()] end,
}


--[[---------------------------------------------------------------------------
    Write (serialization) support.
--]]---------------------------------------------------------------------------

-- Lookup tables to map the number of required bytes to the appropriate
-- reader table index. Note that for numbers, we leave space for the
-- negative versions of each level as well.
local numberIndices = {
    [1] = LibSerialize._ReaderIndex.NUM_8_POS,
    [2] = LibSerialize._ReaderIndex.NUM_16_POS,
    [4] = LibSerialize._ReaderIndex.NUM_32_POS,
    [8] = LibSerialize._ReaderIndex.NUM_64_POS,
}
local stringIndices = {
    [1] = LibSerialize._ReaderIndex.STR_8,
    [2] = LibSerialize._ReaderIndex.STR_16,
    [4] = LibSerialize._ReaderIndex.STR_32,
}
local tableIndices = {
    [1] = LibSerialize._ReaderIndex.TABLE_8,
    [2] = LibSerialize._ReaderIndex.TABLE_16,
    [4] = LibSerialize._ReaderIndex.TABLE_32,
}
local arrayIndices = {
    [1] = LibSerialize._ReaderIndex.ARRAY_8,
    [2] = LibSerialize._ReaderIndex.ARRAY_16,
    [4] = LibSerialize._ReaderIndex.ARRAY_32,
}
local mixedIndices = {
    [1] = LibSerialize._ReaderIndex.MIXED_8,
    [2] = LibSerialize._ReaderIndex.MIXED_16,
    [4] = LibSerialize._ReaderIndex.MIXED_32,
}
local existingIndices = {
    [1] = LibSerialize._ReaderIndex.EXISTING_8,
    [2] = LibSerialize._ReaderIndex.EXISTING_16,
    [4] = LibSerialize._ReaderIndex.EXISTING_32,
}

function LibSerialize:_WriteObject(obj)
    local typ = type(obj)
    local writeFn = self.WriterTable[typ] or error(("Unhandled type: %s"):format(typ))
    writeFn(self, obj)
end

function LibSerialize:_WriteKeyValuePair(key, value)
    assert(key ~= nil and value ~= nil)

    self:_WriteObject(key)
    self:_WriteObject(value)
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
        local c = bottom % 65536
        local d = (bottom - c) / 65536
        local top = (value - bottom) / 4294967296
        local a = top % 65536
        local b = (top - a) / 65536
        self._writeBits(a, 16)
        self._writeBits(b, 16)
        self._writeBits(c, 16)
        self._writeBits(d, 16)
    elseif threshold == 4 then
        local a = value % 65536
        local b = (value - a) / 65536
        self._writeBits(a, 16)
        self._writeBits(b, 16)
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
            -- The type byte can be used to store small nonnegative
            -- numbers for all the values that don't correspond to
            -- one with an actual meaning. Calculate how much space
            -- we have to work with.
            local numReaderIndices = #self.ReaderTable
            local maxPacked = 255 - numReaderIndices - 1

            if value >= 0 and value <= maxPacked then
                -- Pack the value into the type byte
                -- debugPrint("Serializing embedded number:", value)
                self:_WriteByte(value + numReaderIndices + 1)
            else
                -- debugPrint("Serializing number:", value)
                local sign = 0
                if value < 0 then
                    value = -value
                    sign = 1
                end
                local required = GetRequiredBytes(value, true)
                self:_WriteByte(sign + numberIndices[required])
                self:_WriteInt(value, required)
            end
        end
    end,
    ["float"] = function(self, value)
        -- debugPrint("Serializing float:", value)
        self:_WriteByte(self._ReaderIndex.NUM_FLOAT)
        self:_WriteInt(FloatBitsToInt(value), 4)
    end,
    ["string"] = function(self, value)
        local existing = self._existingEntries[value]
        -- Small strings get serialized into #value + 1 bytes,
        -- with their length as the extra byte. If this string has
        -- been seen before, we'll use the bookkeeping entry as
        -- long as the number of bytes for it is smaller.
        if existing and GetRequiredBytes(existing) < #value + 1 then
            -- debugPrint("Serializing existing string:", value)
            local required = GetRequiredBytes(existing)
            self:_WriteByte(existingIndices[required])
            self:_WriteInt(self._existingEntries[value], required)
        else
            local len = #value
            -- debugPrint("Serializing string:", value, len)
            local required = GetRequiredBytes(len)
            self:_WriteByte(stringIndices[required])
            self:_WriteInt(len, required)
            self._writeString(value)
            self:_AddExisting(value)
        end
    end,
    ["boolean"] = function(self, value)
        -- debugPrint("Serializing bool:", value)
        self:_WriteByte(value and self._ReaderIndex.BOOL_T or self._ReaderIndex.BOOL_F)
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
                self:_WriteObject(v)
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
                self:_WriteObject(v)
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
    self:_ClearExisting()
    local WriteBits, WriteString, FlushWriter = CreateWriter()

    self._writeBits = WriteBits
    self._writeString = WriteString
    self._flushWriter = FlushWriter
    self:_WriteByte(self._COMPRESSION_VERSION)
    self:_WriteObject(input)

    local total_bitlen, result = FlushWriter(_FLUSH_MODE_OUTPUT)
    return result
end

function LibSerialize:_Deserialize(input)
    self:_ClearExisting()
    local ReadBytes = CreateReader(input)

    self._readBuffer = {}
    self._readBytes = ReadBytes

    -- Since there's only one compression version currently,
    -- no extra work needs to be done to decode the data.
    local version = self:_ReadByte()
    assert(version == self._COMPRESSION_VERSION)
    return self:_ReadObject()
end

function LibSerialize:Deserialize(input)
    return pcall(LibSerialize._Deserialize, self, input)
end

function LibSerialize:Hash(value)
    -- An implementation of the djb2 hash algorithm.
    -- See http://www.cs.yorku.ca/~oz/hash.html.
    assert(type(value) == "string")

    local h = 5381
    for i = 1, #value do
        h = bit_band((33 * h + string_byte(value, i)), 4294967295)
    end
    return h
end
