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
    local _SERIALIZATION_VERSION = 1

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
    LibSerialize._SERIALIZATION_VERSION = _SERIALIZATION_VERSION
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

local function GetRequiredBytes(value)
    if value < 256 then return 1 end
    if value < 65536 then return 2 end
    if value < 4294967296 then return 4 end
    error("Object limit exceeded")
end

local function GetRequiredBytesNumber(value)
    if value < 256 then return 1 end
    if value < 65536 then return 2 end
    if value < 16777216 then return 3 end
    if value < 4294967296 then return 4 end
    return 8
end

local function IsFractional(value)
    local _, fract = math_modf(value)
    return fract ~= 0
end

local DebugPrint = function(...)
    print(...)
    -- ABGP:WriteLogged("SERIALIZE", table_concat({tostringall(...)}, " "))
end


--[[---------------------------------------------------------------------------
    Code taken/modified from LibDeflate: CreateReader, CreateWriter.
    Exposes a mechanism to read/write bytes from/to a buffer.
--]]---------------------------------------------------------------------------

--[[
    Create an empty writer to easily write stuffs as the unit of bits.
    Return values:
    1. WriteString(str)
    2. Flush(mode)
--]]
local function CreateWriter()
    local buffer_size = 0
    local buffer = {}

    -- Write the entire string into the writer.
    -- @param str The string being written
    -- @return nil
    local function WriteString(str)
        -- DebugPrint("Writing string len", #str, "bitlen", #str * 8)
        buffer_size = buffer_size + 1
        buffer[buffer_size] = str
    end

    -- Flush current stuffs in the writer and return it.
    -- This operation will free most of the memory.
    -- @return The total number of bits stored in the writer right now.
    -- @return Return the output.
    local function FlushWriter()
        local flushed = table_concat(buffer)
        buffer = {}
        buffer_size = 0
        return flushed
    end

    return WriteString, FlushWriter
end

--[[
    Create a reader to easily reader stuffs as the unit of bits.
    Return values:
    1. ReadBytes(bytelen, buffer, buffer_size)
    2. ReaderBitlenLeft()
--]]
local function CreateReader(input_string)
    local input = input_string
    local input_strlen = #input_string
    local input_next_byte_pos = 1

    -- Read some bytes from the reader.
    -- @param bytelen The number of bytes to be read.
    -- @return the bytes as a string
    local function ReadBytes(bytelen)
        local result = string_sub(input, input_next_byte_pos, input_next_byte_pos + bytelen - 1)
        input_next_byte_pos = input_next_byte_pos + bytelen
        return result
    end

    local function ReaderBitlenLeft()
        return (input_strlen - input_next_byte_pos + 1) * 8
    end

    return ReadBytes, ReaderBitlenLeft
end


--[[---------------------------------------------------------------------------
    Code taken/modified from lua-MessagePack: FloatToString, StringToFloat.
    Used for serializing/deserializing floating point numbers.
--]]---------------------------------------------------------------------------

local function FloatToString(n)
    local sign = 0
    if n < 0.0 then
        sign = 0x80
        n = -n
    end
    local mant, expo = frexp(n)
    if mant ~= mant then -- nan
        return string_char(0xFF, 0xF8, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00)
    elseif mant == math_huge or expo > 0x400 then
        if sign == 0 then -- inf
            return string_char(0x7F, 0xF0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00)
        else -- -inf
            return string_char(0xFF, 0xF0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00)
        end
    elseif (mant == 0.0 and expo == 0) or expo < -0x3FE then -- zero
        return string_char(sign, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00)
    else
        expo = expo + 0x3FE
        mant = floor((mant * 2.0 - 1.0) * ldexp(0.5, 53))
        return string_char(sign + floor(expo / 0x10),
                           (expo % 0x10) * 0x10 + floor(mant / 0x1000000000000),
                           floor(mant / 0x10000000000) % 0x100,
                           floor(mant / 0x100000000) % 0x100,
                           floor(mant / 0x1000000) % 0x100,
                           floor(mant / 0x10000) % 0x100,
                           floor(mant / 0x100) % 0x100,
                           mant % 0x100)
    end
end

local function StringToFloat(str)
    local b1, b2, b3, b4, b5, b6, b7, b8 = string_byte(str, 1, 8)
    local sign = b1 > 0x7F
    local expo = (b1 % 0x80) * 0x10 + floor(b2 / 0x10)
    local mant = ((((((b2 % 0x10) * 0x100 + b3) * 0x100 + b4) * 0x100 + b5) * 0x100 + b6) * 0x100 + b7) * 0x100 + b8
    if sign then
        sign = -1
    else
        sign = 1
    end
    local n
    if mant == 0 and expo == 0 then
        n = sign * 0.0
    elseif expo == 0x7FF then
        if mant == 0 then
            n = sign * math_huge
        else
            n = 0.0/0.0
        end
    else
        n = sign * ldexp(1.0 + mant / 4503599627370496.0, expo - 0x3FF)
    end
    return n
end


--[[---------------------------------------------------------------------------
    Object reuse:
    As strings/tables are serialized or deserialized, they are stored in this lookup
    table in case they're encountered again, at which point they can be referenced
    by their index into this table rather than repeating the string contents.
--]]---------------------------------------------------------------------------

LibSerialize._stringRefs = {}
LibSerialize._tableRefs = {}

function LibSerialize:_AddReference(refs, value)
    local ref = #refs + 1
    refs[ref] = value
    refs[value] = ref
end

function LibSerialize:_ClearReferences()
    self._stringRefs = {}
    self._tableRefs = {}
end


--[[---------------------------------------------------------------------------
    Read (deserialization) support.
--]]---------------------------------------------------------------------------

function LibSerialize:_ReadObject()
    --[[-----------------------------------------------------------------------
        Encoding format:
        The type byte supports the following formats:
        * NNNN NNN1: a 7 bit non-negative int
        * CCCC TT10: a 2 bit type index and 4 bit count (strlen, #tab, etc.)
          * Followed by the type-dependent payload
        * NNNN N100: the lower five bits of a 13 bit int
          * Followed by a byte for the upper bits
        * TTTT T000: a 5 bit type index
          * Followed by the type-dependent payload, including count(s) if needed
    --]]-----------------------------------------------------------------------

    local value = self:_ReadByte()

    if value % 2 == 1 then
        -- Number embedded in the top 7 bits.
        local num = (value - 1) / 2
        -- DebugPrint("Found embedded number (1byte):", value, num)
        return num
    end

    if value % 4 == 2 then
        -- Type with embedded count. Extract both.
        -- The type is in bits 3-4, count in 5-8.
        local typ = (value - 2) / 4
        local count = (typ - typ % 4) / 4
        typ = typ % 4
        -- DebugPrint("Found type with embedded count:", value, typ, count)
        return self._EmbeddedReaderTable[typ](self, count)
    end

    if value % 8 == 4 then
        -- Number embedded in the top 5 bits, plus an additional byte's worth (so 13 bits).
        local packed = self:_ReadByte() * 0x100 + value
        local num = (packed - 4) / 8
        -- DebugPrint("Found embedded number (2bytes):", value, packed, num)
        return num
    end

    -- Otherwise, the type index is embedded in the upper 5 bits.
    local typ = value / 8
    -- DebugPrint("Found type:", value, typ)
    return self._ReaderTable[typ](self)
end

function LibSerialize:_ReadTable(entryCount, value)
    -- DebugPrint("Extracting keys/values for table:", entryCount)

    local addRef = (value == nil)
    value = value or {}

    for i = 1, entryCount do
        local key, value = self:_ReadObject(), self:_ReadObject()
        value[key] = value
    end

    if addRef then
        self:_AddReference(self._tableRefs, value)
    end

    return value
end

function LibSerialize:_ReadArray(entryCount, value)
    -- DebugPrint("Extracting values for array:", entryCount)

    local addRef = (value == nil)
    value = value or {}

    for i = 1, entryCount do
        value[i] = self:_ReadObject()
    end

    if addRef then
        self:_AddReference(self._tableRefs, value)
    end

    return value
end

function LibSerialize:_ReadMixed(arrayCount, tableCount)
    -- DebugPrint("Extracting values for mixed table:", arrayCount, tableCount)

    local value = {}

    self:_ReadArray(arrayCount, value)
    self:_ReadTable(tableCount, value)
    self:_AddReference(self._tableRefs, value)

    return value
end

function LibSerialize:_ReadString(len)
    -- DebugPrint("Reading string,", len)

    local value = self._readBytes(len)
    if len > 2 then
        self:_AddReference(self._stringRefs, value)
    end
    return value
end

function LibSerialize:_ReadByte()
    -- DebugPrint("Reading byte")

    local str = self._readBytes(1)
    return string_byte(str)
end

function LibSerialize:_ReadInt16()
    -- DebugPrint("Reading int16")

    local str = self._readBytes(2)
    local b1, b2 = string_byte(str, 1, 2)
    return b1 * 0x100 + b2
end

function LibSerialize:_ReadInt24()
    -- DebugPrint("Reading int24")

    local str = self._readBytes(3)
    local b1, b2, b3 = string_byte(str, 1, 3)
    return (b1 * 0x100 + b2) * 0x100 + b3
end

function LibSerialize:_ReadInt32()
    -- DebugPrint("Reading int32")

    local str = self._readBytes(4)
    local b1, b2, b3, b4 = string_byte(str, 1, 4)
    return ((b1 * 0x100 + b2) * 0x100 + b3) * 0x100 + b4
end

function LibSerialize:_ReadInt64()
    -- DebugPrint("Reading int64")

    local str = self._readBytes(7)
    local b1, b2, b3, b4, b5, b6, b7, b8 = 0, string_byte(str, 1, 7)
    return ((((((b1 * 0x100 + b2) * 0x100 + b3) * 0x100 + b4) * 0x100 + b5) * 0x100 + b6) * 0x100 + b7) * 0x100 + b8
end

local embeddedIndexShift = 4
local embeddedCountShift = 16
LibSerialize._EmbeddedIndex = {
    STRING = 0,
    TABLE = 1,
    ARRAY = 2,
    MIXED = 3,
}
LibSerialize._EmbeddedReaderTable = {
    [LibSerialize._EmbeddedIndex.STRING] = function(self, count) return self:_ReadString(count) end,
    [LibSerialize._EmbeddedIndex.TABLE] =  function(self, count) return self:_ReadTable(count) end,
    [LibSerialize._EmbeddedIndex.ARRAY] =  function(self, count) return self:_ReadArray(count) end,
    [LibSerialize._EmbeddedIndex.MIXED] =  function(self, count)
        local arrayCount = count % 4
        local tableCount = (count - arrayCount) / 4
        return self:_ReadMixed(arrayCount + 1, tableCount + 1)
    end,
}
assert(#LibSerialize._EmbeddedReaderTable < 4) -- two bits reserved

local readerIndexShift = 8
LibSerialize._ReaderIndex = {
    NIL = 0,

    NUM_8_POS = 1,
    NUM_8_NEG = 2,
    NUM_16_POS = 3,
    NUM_16_NEG = 4,
    NUM_24_POS = 5,
    NUM_24_NEG = 6,
    NUM_32_POS = 7,
    NUM_32_NEG = 8,
    NUM_64_POS = 9,
    NUM_64_NEG = 10,
    NUM_FLOAT = 11,

    BOOL_T = 12,
    BOOL_F = 13,

    STR_8 = 14,
    STR_16 = 15,
    STR_32 = 16,

    TABLE_8 = 17,
    TABLE_16 = 18,
    TABLE_32 = 19,

    ARRAY_8 = 20,
    ARRAY_16 = 21,
    ARRAY_32 = 22,

    MIXED_8 = 23,
    MIXED_16 = 24,
    MIXED_32 = 25,

    STRINGREF_8 = 26,
    STRINGREF_16 = 27,
    STRINGREF_32 = 28,

    TABLEREF_8 = 29,
    TABLEREF_16 = 30,
    TABLEREF_32 = 31,
}
LibSerialize._ReaderTable = {
    -- Nil (only expected as the entire input)
    [LibSerialize._ReaderIndex.NIL]  = function(self) return nil end,

    -- Numbers
    [LibSerialize._ReaderIndex.NUM_8_POS]  = function(self) return self:_ReadByte() end,
    [LibSerialize._ReaderIndex.NUM_8_NEG]  = function(self) return -self:_ReadByte() end,
    [LibSerialize._ReaderIndex.NUM_16_POS] = function(self) return self:_ReadInt16() end,
    [LibSerialize._ReaderIndex.NUM_16_NEG] = function(self) return -self:_ReadInt16() end,
    [LibSerialize._ReaderIndex.NUM_24_POS] = function(self) return self:_ReadInt24() end,
    [LibSerialize._ReaderIndex.NUM_24_NEG] = function(self) return -self:_ReadInt24() end,
    [LibSerialize._ReaderIndex.NUM_32_POS] = function(self) return self:_ReadInt32() end,
    [LibSerialize._ReaderIndex.NUM_32_NEG] = function(self) return -self:_ReadInt32() end,
    [LibSerialize._ReaderIndex.NUM_64_POS] = function(self) return self:_ReadInt64() end,
    [LibSerialize._ReaderIndex.NUM_64_NEG] = function(self) return -self:_ReadInt64() end,
    [LibSerialize._ReaderIndex.NUM_FLOAT]  = function(self) return StringToFloat(self._readBytes(8)) end,

    -- Booleans
    [LibSerialize._ReaderIndex.BOOL_T] = function(self) return true end,
    [LibSerialize._ReaderIndex.BOOL_F] = function(self) return false end,

    -- Strings (encoded as size + buffer)
    [LibSerialize._ReaderIndex.STR_8]  = function(self) return self:_ReadString(self:_ReadByte()) end,
    [LibSerialize._ReaderIndex.STR_16] = function(self) return self:_ReadString(self:_ReadInt16()) end,
    [LibSerialize._ReaderIndex.STR_32] = function(self) return self:_ReadString(self:_ReadInt32()) end,

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

    -- Previously referenced strings
    [LibSerialize._ReaderIndex.STRINGREF_8]  = function(self) return self._stringRefs[self:_ReadByte()] end,
    [LibSerialize._ReaderIndex.STRINGREF_16] = function(self) return self._stringRefs[self:_ReadInt16()] end,
    [LibSerialize._ReaderIndex.STRINGREF_32] = function(self) return self._stringRefs[self:_ReadInt32()] end,

    -- Previously referenced tables
    [LibSerialize._ReaderIndex.TABLEREF_8]  = function(self) return self._tableRefs[self:_ReadByte()] end,
    [LibSerialize._ReaderIndex.TABLEREF_16] = function(self) return self._tableRefs[self:_ReadInt16()] end,
    [LibSerialize._ReaderIndex.TABLEREF_32] = function(self) return self._tableRefs[self:_ReadInt32()] end,
}
assert(#LibSerialize._ReaderTable < 32) -- five bits reserved


--[[---------------------------------------------------------------------------
    Write (serialization) support.
--]]---------------------------------------------------------------------------

function LibSerialize:_WriteObject(obj)
    local typ = type(obj)
    local writeFn = self._WriterTable[typ] or error(("Unhandled type: %s"):format(typ))
    writeFn(self, obj)
end

function LibSerialize:_WriteByte(value)
    self:_WriteInt(value, 1)
end

function LibSerialize:_WriteInt(n, threshold)
    local str
    if threshold == 8 then
        -- Since a double can only hold a 53 bit int,
        -- we only need to write seven bytes.
        str = string_char(floor(n / 0x1000000000000) % 0x100,
                          floor(n / 0x10000000000) % 0x100,
                          floor(n / 0x100000000) % 0x100,
                          floor(n / 0x1000000) % 0x100,
                          floor(n / 0x10000) % 0x100,
                          floor(n / 0x100) % 0x100,
                          n % 0x100)
    elseif threshold == 4 then
        str = string_char(floor(n / 0x1000000),
                          floor(n / 0x10000) % 0x100,
                          floor(n / 0x100) % 0x100,
                          n % 0x100)
    elseif threshold == 3 then
        str = string_char(floor(n / 0x10000),
                          floor(n / 0x100) % 0x100,
                          n % 0x100)
    elseif threshold == 2 then
        str = string_char(floor(n / 0x100),
                          n % 0x100)
    elseif threshold == 1 then
        str = string_char(n)
    end
    self._writeString(str)
end

-- Lookup tables to map the number of required bytes to the appropriate
-- reader table index. Note that for numbers, we leave space for the
-- negative versions of each level as well.
local numberIndices = {
    [1] = LibSerialize._ReaderIndex.NUM_8_POS,
    [2] = LibSerialize._ReaderIndex.NUM_16_POS,
    [3] = LibSerialize._ReaderIndex.NUM_24_POS,
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
local stringRefIndices = {
    [1] = LibSerialize._ReaderIndex.STRINGREF_8,
    [2] = LibSerialize._ReaderIndex.STRINGREF_16,
    [4] = LibSerialize._ReaderIndex.STRINGREF_32,
}
local tableRefIndices = {
    [1] = LibSerialize._ReaderIndex.TABLEREF_8,
    [2] = LibSerialize._ReaderIndex.TABLEREF_16,
    [4] = LibSerialize._ReaderIndex.TABLEREF_32,
}

LibSerialize._WriterTable = {
    ["nil"] = function(self)
        -- DebugPrint("Serializing nil")
        self:_WriteByte(readerIndexShift * self._ReaderIndex.NIL)
    end,
    ["number"] = function(self, value)
        if IsFractional(value) then
            -- DebugPrint("Serializing float:", value)
            self:_WriteByte(readerIndexShift * self._ReaderIndex.NUM_FLOAT)
            self._writeString(FloatToString(value))
        elseif value >= 0 and value < 8192 then
            -- The type byte supports two modes by which a number can be embedded:
            -- A 1-byte mode for 7-bit numbers, and a 2-byte mode for 13-bit numbers.
            if value < 128 then
                -- DebugPrint("Serializing embedded number (1byte):", value)
                self:_WriteByte(value * 2 + 1)
            else
                -- DebugPrint("Serializing embedded number (2bytes):", value)
                value = value * 8 + 4
                local upper, lower = floor(value / 0x100), value % 0x100
                self:_WriteByte(lower)
                self:_WriteByte(upper)
            end
        else
            -- DebugPrint("Serializing number:", value)
            local sign = 0
            if value < 0 then
                value = -value
                sign = readerIndexShift
            end
            local required = GetRequiredBytesNumber(value)
            self:_WriteByte(sign + readerIndexShift * numberIndices[required])
            self:_WriteInt(value, required)
        end
    end,
    ["boolean"] = function(self, value)
        -- DebugPrint("Serializing bool:", value)
        self:_WriteByte(readerIndexShift * (value and self._ReaderIndex.BOOL_T or self._ReaderIndex.BOOL_F))
    end,
    ["string"] = function(self, value)
        local ref = self._stringRefs[value]
        if ref then
            -- DebugPrint("Serializing string ref:", value)
            local required = GetRequiredBytes(ref)
            self:_WriteByte(readerIndexShift * stringRefIndices[required])
            self:_WriteInt(self._stringRefs[value], required)
        else
            local len = #value
            if len < 16 then
                -- Short lengths can be embedded directly into the type byte.
                -- DebugPrint("Serializing string, embedded count:", value, len)
                self:_WriteByte(embeddedCountShift * len + embeddedIndexShift * self._EmbeddedIndex.STRING + 2)
            else
                -- DebugPrint("Serializing string:", value, len)
                local required = GetRequiredBytes(len)
                self:_WriteByte(readerIndexShift * stringIndices[required])
                self:_WriteInt(len, required)
            end

            self._writeString(value)
            if len > 2 then
                self:_AddReference(self._stringRefs, value)
            end
        end
    end,
    ["table"] = function(self, value)
        local ref = self._tableRefs[value]
        if ref then
            -- DebugPrint("Serializing table ref:", value)
            local required = GetRequiredBytes(ref)
            self:_WriteByte(readerIndexShift * tableRefIndices[required])
            self:_WriteInt(self._tableRefs[value], required)
        else
            -- First determine the "proper" length of the array portion of the table,
            -- which terminates at its first nil value.
            local arrayCount = 0
            for k, v in ipairs(value) do
                arrayCount = k
            end

            -- Next determine the count of all entries in the table.
            local mapCount = 0
            for k, v in pairs(value) do
                mapCount = mapCount + 1
            end

            -- The final map count is simply the total count minus the array count.
            mapCount = mapCount - arrayCount

            if mapCount == 0 then
                -- The table is an array. We can avoid writing the keys.
                if arrayCount < 16 then
                    -- Short counts can be embedded directly into the type byte.
                    -- DebugPrint("Serializing array, embedded count:", arrayCount)
                    self:_WriteByte(embeddedCountShift * arrayCount + embeddedIndexShift * self._EmbeddedIndex.ARRAY + 2)
                else
                    -- DebugPrint("Serializing array:", arrayCount)
                    local required = GetRequiredBytes(arrayCount)
                    self:_WriteByte(readerIndexShift * arrayIndices[required])
                    self:_WriteInt(arrayCount, required)
                end

                for _, v in ipairs(value) do
                    self:_WriteObject(v)
                end
            elseif arrayCount ~= 0 then
                -- The table has both array and dictionary keys. We can still save space
                -- by writing the array values first without keys.

                if mapCount < 5 and arrayCount < 5 then
                    -- Short counts can be embedded directly into the type byte.
                    -- They have to be really short though, since we have two counts.
                    -- Since neither can be zero (this is a mixed table),
                    -- we can get away with not being able to represent 0.
                    -- DebugPrint("Serializing mixed array-table, embedded counts:", arrayCount, mapCount)
                    local combined = (mapCount - 1) * 4 + arrayCount - 1
                    self:_WriteByte(embeddedCountShift * combined + embeddedIndexShift * self._EmbeddedIndex.MIXED + 2)
                else
                    -- Use the max required bytes for the two counts.
                    -- DebugPrint("Serializing mixed array-table:", arrayCount, mapCount)
                    local required = max(GetRequiredBytes(mapCount), GetRequiredBytes(arrayCount))
                    self:_WriteByte(readerIndexShift * mixedIndices[required])
                    self:_WriteInt(arrayCount, required)
                    self:_WriteInt(mapCount, required)
                end

                for _, v in ipairs(value) do
                    self:_WriteObject(v)
                end

                local mapCountWritten = 0
                for k, v in pairs(value) do
                    if type(k) ~= "number" or k < 1 or k > arrayCount or IsFractional(k) then
                        mapCountWritten = mapCountWritten + 1
                        self:_WriteObject(k)
                        self:_WriteObject(v)
                    end
                end
                assert(mapCount == mapCountWritten)
            else
                -- The table has only dictionary keys, so we'll write them all.
                if mapCount < 16 then
                    -- Short counts can be embedded directly into the type byte.
                    -- DebugPrint("Serializing table, embedded count:", mapCount)
                    self:_WriteByte(embeddedCountShift * mapCount + embeddedIndexShift * self._EmbeddedIndex.TABLE + 2)
                else
                    -- DebugPrint("Serializing table:", mapCount)
                    local required = GetRequiredBytes(mapCount)
                    self:_WriteByte(readerIndexShift * tableIndices[required])
                    self:_WriteInt(mapCount, required)
                end

                for k, v in pairs(value) do
                    self:_WriteObject(k)
                    self:_WriteObject(v)
                end
            end

            self:_AddReference(self._tableRefs, value)
        end
    end,
}


--[[---------------------------------------------------------------------------
    API support.
--]]---------------------------------------------------------------------------

function LibSerialize:Serialize(input)
    self:_ClearReferences()
    local WriteString, FlushWriter = CreateWriter()

    self._writeString = WriteString
    self._flushWriter = FlushWriter
    self:_WriteByte(self._SERIALIZATION_VERSION)
    self:_WriteObject(input)

    return FlushWriter()
end

function LibSerialize:_Deserialize(input)
    self:_ClearReferences()
    local ReadBytes, ReaderBitlenLeft = CreateReader(input)

    self._readBuffer = {}
    self._readBytes = ReadBytes

    -- Since there's only one compression version currently,
    -- no extra work needs to be done to decode the data.
    local version = self:_ReadByte()
    assert(version == self._SERIALIZATION_VERSION)
    local obj = self:_ReadObject()

    local remaining = ReaderBitlenLeft()
    if remaining ~= 0 then
        error(remaining > 0
              and "Buffer contents not fully read"
              or "Reader went past end of buffer")
    end

    return obj
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
