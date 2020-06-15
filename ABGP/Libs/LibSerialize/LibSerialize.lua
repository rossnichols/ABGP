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

Credits:
The following projects are used to help implement this project.
Their original licenses shall be complied with when used.

1. LibDeflate, by Haoqian He. https://github.com/SafeteeWoW/LibDeflate
    For the CreateReader/CreateWriter functions.
    Licensed under GPLv3.
2. lua-MessagePack, by François Perrad. https://framagit.org/fperrad/lua-MessagePack
    For the mechanism for packing/unpacking floats and ints.
    Licensed under MIT.
3. LibQuestieSerializer, by aero. https://github.com/AeroScripts/LibQuestieSerializer
    For the general approach of "type byte, payload" for serializing.
    Licensed under GPLv3.
]]


--[[
LibSerialize is a library for efficiently serializing/deserializing arbitrary tables.
It supports serializing nils, numbers, booleans, strings, and tables using these types.


Three functions are provided:
* LibSerialize:Serialize(input)
    Arguments:
    * input: any valid value (see above)
    Returns:
    * result: `input` serialized as a string
* LibSerialize:Deserialize(input)
    Arguments:
    * input: a string previously returned from LibSerialize:Serialize()
    Returns:
    * success: a boolean indicating if deserialization was successful
    * result: the deserialized value if successful, or a string containing the error
* LibSerialize:DeserializeValue(input)
    Arguments:
    * input: a string previously returned from LibSerialize:Serialize()
    Returns:
    * result: the deserialized value

Serialize() will cause a Lua error if the input cannot be serialized.
This will occur if any unsupported types are encountered (e.g. functions),
or if any of the following exceed 16777215: any string length, any table
key count, number of unique strings, number of unique tables.

Deserialize() and DeserializeValue() are equivalent, except the latter
returns the deserialization result directly and will not catch any Lua
errors that may occur when deserializing invalid input.


Encoding format:
Every object is encoded as a type byte followed by type-dependent payload.

For numbers, the payload is the number itself (with extra work for floats),
using a number of bytes appropriate for the number. Small numbers can be
ambedded directly into the type bit, optionally with an additional byte
following for more possible values. Negative numbers are encoded as their
absolute value, with the type byte indicating that it is negative.

For strings and tables, the length/count is also specified so that the
payload doesn't need a special terminator. Small counts can be embedded
directly into the type byte, whereas larger counts are encoded directly
following the type byte, before the payload.

Strings are stored directly, with no transformations. Tables are stored
in one of three ways, depending on their layout:
* Array-like: all keys are numbers starting from 1 and increasing by 1.
    Only the table's values are encoded.
* Map-like: the table has no array-like keys.
    The table is encoded as key-value pairs.
* Mixed: the table has both map-like and array-like keys.
    The table is encoded first with the values of the array-like keys,
    followed by key-value pairs for the map-like keys. For this version,
    two counts are encoded, one each for the two different portions.

Strings and tables are also tracked as they are encountered, to detect reuse.
If a string or table is reused, it is encoded instead as an index into the
tracking table for that type. Strings must be >2 bytes in length to be tracked.


Type byte:
The type byte uses the following formats to implement the above:

* NNNN NNN1: a 7 bit non-negative int
* CCCC TT10: a 2 bit type index and 4 bit count (strlen, #tab, etc.)
    * Followed by the type-dependent payload
* NNNN N100: the lower five bits of a 13 bit positive int
    * Followed by a byte for the upper bits
* TTTT T000: a 5 bit type index
    * Followed by the type-dependent payload, including count(s) if needed
--]]

local LibSerialize
local MAJOR, MINOR = "LibSerialize", 1
local LibSerialize = LibStub and LibStub:NewLibrary(MAJOR, MINOR) or {}

if not LibSerialize then return end -- No Upgrade needed.

local assert = assert
local error = error
local pairs = pairs
local ipairs = ipairs
local string_byte = string.byte
local string_char = string.char
local string_sub = string.sub
local table_concat = table.concat
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

-- Returns the number of bytes required to store the value,
-- up to a maximum of three. Errors if three bytes is insufficient.
local function GetRequiredBytes(value)
    if value < 256 then return 1 end
    if value < 65536 then return 2 end
    if value < 16777216 then return 3 end
    error("Object limit exceeded")
end

-- Returns the number of bytes required to store the value,
-- though always returning seven if four bytes is insufficient.
-- Doubles have room for 53bit numbers, so seven bits max.
local function GetRequiredBytesNumber(value)
    if value < 256 then return 1 end
    if value < 65536 then return 2 end
    if value < 16777216 then return 3 end
    if value < 4294967296 then return 4 end
    return 7
end

-- Returns whether the value (a number) is fractional,
-- as opposed to a whole number.
local function IsFractional(value)
    local _, fract = math_modf(value)
    return fract ~= 0
end

-- Prints args to the chat window. To enable debug statements,
-- do a find/replace in this file with "-- DebugPrint(" for "DebugPrint(",
-- or the reverse to disable them again.
local DebugPrint = function(...)
    print(...)
    -- ABGP:WriteLogged("SERIALIZE", table_concat({tostringall(...)}, " "))
end


--[[---------------------------------------------------------------------------
    Code taken/modified from LibDeflate: CreateReader, CreateWriter.
    Exposes a mechanism to read/write bytes from/to a buffer. The more
    advanced functionality of reading/writing partial bytes has been removed.
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
        -- DebugPrint("Writing string:", str, #str)
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
    2. ReaderBytesLeft()
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

    local function ReaderBytesLeft()
        return input_strlen - input_next_byte_pos + 1
    end

    return ReadBytes, ReaderBytesLeft
end


--[[---------------------------------------------------------------------------
    Code taken/modified from lua-MessagePack: FloatToString, StringToFloat,
    IntToString, StringToInt. Used for serializing/deserializing numbers.
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

local function IntToString(n, required)
    if required == 1 then
        return string_char(n)
    elseif required == 2 then
        return string_char(floor(n / 0x100),
                           n % 0x100)
    elseif required == 3 then
        return string_char(floor(n / 0x10000),
                           floor(n / 0x100) % 0x100,
                           n % 0x100)
    elseif required == 4 then
        return string_char(floor(n / 0x1000000),
                           floor(n / 0x10000) % 0x100,
                           floor(n / 0x100) % 0x100,
                           n % 0x100)
    elseif required == 7 then
        return string_char(floor(n / 0x1000000000000) % 0x100,
                            floor(n / 0x10000000000) % 0x100,
                            floor(n / 0x100000000) % 0x100,
                            floor(n / 0x1000000) % 0x100,
                            floor(n / 0x10000) % 0x100,
                            floor(n / 0x100) % 0x100,
                            n % 0x100)
    end

    error("Invalid required bytes: " .. required)
end

local function StringToInt(str, required)
    if required == 1 then
        return string_byte(str)
    elseif required == 2 then
        local b1, b2 = string_byte(str, 1, 2)
        return b1 * 0x100 + b2
    elseif required == 3 then
        local b1, b2, b3 = string_byte(str, 1, 3)
        return (b1 * 0x100 + b2) * 0x100 + b3
    elseif required == 4 then
        local b1, b2, b3, b4 = string_byte(str, 1, 4)
        return ((b1 * 0x100 + b2) * 0x100 + b3) * 0x100 + b4
    elseif required == 7 then
        local b1, b2, b3, b4, b5, b6, b7, b8 = 0, string_byte(str, 1, 7)
        return ((((((b1 * 0x100 + b2) * 0x100 + b3) * 0x100 + b4) * 0x100 + b5) * 0x100 + b6) * 0x100 + b7) * 0x100 + b8
    end

    error("Invalid required bytes: " .. required)
end


--[[---------------------------------------------------------------------------
    Object reuse:
    As strings/tables are serialized or deserialized, they are stored in this lookup
    table in case they're encountered again, at which point they can be referenced
    by their index into this table rather than repeating the string contents.
--]]---------------------------------------------------------------------------

local refsDirty = false
local stringRefs = {}
local tableRefs = {}

function LibSerialize:_AddReference(refs, value)
    refsDirty = true

    local ref = #refs + 1
    refs[ref] = value
    refs[value] = ref
end

function LibSerialize:_ClearReferences()
    if refsDirty then
        stringRefs = {}
        tableRefs = {}
    end
end


--[[---------------------------------------------------------------------------
    Read (deserialization) support.
--]]---------------------------------------------------------------------------

function LibSerialize:_ReadObject()
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
        local k, v = self:_ReadPair(self._ReadObject)
        value[k] = v
    end

    if addRef then
        self:_AddReference(tableRefs, value)
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
        self:_AddReference(tableRefs, value)
    end

    return value
end

function LibSerialize:_ReadMixed(arrayCount, mapCount)
    -- DebugPrint("Extracting values for mixed table:", arrayCount, mapCount)

    local value = {}

    self:_ReadArray(arrayCount, value)
    self:_ReadTable(mapCount, value)
    self:_AddReference(tableRefs, value)

    return value
end

function LibSerialize:_ReadString(len)
    -- DebugPrint("Reading string,", len)

    local value = self._readBytes(len)
    if len > 2 then
        self:_AddReference(stringRefs, value)
    end
    return value
end

function LibSerialize:_ReadByte()
    -- DebugPrint("Reading byte")

    return self:_ReadInt(1)
end

function LibSerialize:_ReadInt(required)
    -- DebugPrint("Reading int", required)

    return StringToInt(self._readBytes(required), required)
end

function LibSerialize:_ReadPair(fn, ...)
    local first = fn(self, ...)
    local second = fn(self, ...)
    return first, second
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
    [LibSerialize._EmbeddedIndex.STRING] = function(self, c) return self:_ReadString(c) end,
    [LibSerialize._EmbeddedIndex.TABLE] =  function(self, c) return self:_ReadTable(c) end,
    [LibSerialize._EmbeddedIndex.ARRAY] =  function(self, c) return self:_ReadArray(c) end,
    -- For MIXED, the 4-bit count contains two 2-bit counts that are one less than the true count.
    [LibSerialize._EmbeddedIndex.MIXED] =  function(self, c) return self:_ReadMixed((c % 4) + 1, floor(c / 4) + 1) end,
}

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
    STR_24 = 16,

    TABLE_8 = 17,
    TABLE_16 = 18,
    TABLE_24 = 19,

    ARRAY_8 = 20,
    ARRAY_16 = 21,
    ARRAY_24 = 22,

    MIXED_8 = 23,
    MIXED_16 = 24,
    MIXED_24 = 25,

    STRINGREF_8 = 26,
    STRINGREF_16 = 27,
    STRINGREF_24 = 28,

    TABLEREF_8 = 29,
    TABLEREF_16 = 30,
    TABLEREF_24 = 31,
}
LibSerialize._ReaderTable = {
    -- Nil (only expected as the entire input)
    [LibSerialize._ReaderIndex.NIL]  = function(self) return nil end,

    -- Numbers
    [LibSerialize._ReaderIndex.NUM_8_POS]  = function(self) return self:_ReadByte() end,
    [LibSerialize._ReaderIndex.NUM_8_NEG]  = function(self) return -self:_ReadByte() end,
    [LibSerialize._ReaderIndex.NUM_16_POS] = function(self) return self:_ReadInt(2) end,
    [LibSerialize._ReaderIndex.NUM_16_NEG] = function(self) return -self:_ReadInt(2) end,
    [LibSerialize._ReaderIndex.NUM_24_POS] = function(self) return self:_ReadInt(3) end,
    [LibSerialize._ReaderIndex.NUM_24_NEG] = function(self) return -self:_ReadInt(3) end,
    [LibSerialize._ReaderIndex.NUM_32_POS] = function(self) return self:_ReadInt(4) end,
    [LibSerialize._ReaderIndex.NUM_32_NEG] = function(self) return -self:_ReadInt(4) end,
    [LibSerialize._ReaderIndex.NUM_64_POS] = function(self) return self:_ReadInt(7) end,
    [LibSerialize._ReaderIndex.NUM_64_NEG] = function(self) return -self:_ReadInt(7) end,
    [LibSerialize._ReaderIndex.NUM_FLOAT]  = function(self) return StringToFloat(self._readBytes(8)) end,

    -- Booleans
    [LibSerialize._ReaderIndex.BOOL_T] = function(self) return true end,
    [LibSerialize._ReaderIndex.BOOL_F] = function(self) return false end,

    -- Strings (encoded as size + buffer)
    [LibSerialize._ReaderIndex.STR_8]  = function(self) return self:_ReadString(self:_ReadByte()) end,
    [LibSerialize._ReaderIndex.STR_16] = function(self) return self:_ReadString(self:_ReadInt(2)) end,
    [LibSerialize._ReaderIndex.STR_24] = function(self) return self:_ReadString(self:_ReadInt(3)) end,

    -- Tables (encoded as count + key/value pairs)
    [LibSerialize._ReaderIndex.TABLE_8]  = function(self) return self:_ReadTable(self:_ReadByte()) end,
    [LibSerialize._ReaderIndex.TABLE_16] = function(self) return self:_ReadTable(self:_ReadInt(2)) end,
    [LibSerialize._ReaderIndex.TABLE_24] = function(self) return self:_ReadTable(self:_ReadInt(3)) end,

    -- Arrays (encoded as count + values)
    [LibSerialize._ReaderIndex.ARRAY_8]  = function(self) return self:_ReadArray(self:_ReadByte()) end,
    [LibSerialize._ReaderIndex.ARRAY_16] = function(self) return self:_ReadArray(self:_ReadInt(2)) end,
    [LibSerialize._ReaderIndex.ARRAY_24] = function(self) return self:_ReadArray(self:_ReadInt(3)) end,

    -- Mixed arrays/maps (encoded as arrayCount + mapCount + arrayValues + key/value pairs)
    [LibSerialize._ReaderIndex.MIXED_8]  = function(self) return self:_ReadMixed(self:_ReadPair(self._ReadByte)) end,
    [LibSerialize._ReaderIndex.MIXED_16] = function(self) return self:_ReadMixed(self:_ReadPair(self._ReadInt, 2)) end,
    [LibSerialize._ReaderIndex.MIXED_24] = function(self) return self:_ReadMixed(self:_ReadPair(self._ReadInt, 3)) end,

    -- Previously referenced strings
    [LibSerialize._ReaderIndex.STRINGREF_8]  = function(self) return stringRefs[self:_ReadByte()] end,
    [LibSerialize._ReaderIndex.STRINGREF_16] = function(self) return stringRefs[self:_ReadInt(2)] end,
    [LibSerialize._ReaderIndex.STRINGREF_24] = function(self) return stringRefs[self:_ReadInt(3)] end,

    -- Previously referenced tables
    [LibSerialize._ReaderIndex.TABLEREF_8]  = function(self) return tableRefs[self:_ReadByte()] end,
    [LibSerialize._ReaderIndex.TABLEREF_16] = function(self) return tableRefs[self:_ReadInt(2)] end,
    [LibSerialize._ReaderIndex.TABLEREF_24] = function(self) return tableRefs[self:_ReadInt(3)] end,
}


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
    self._writeString(IntToString(n, threshold))
end

-- Lookup tables to map the number of required bytes to the
-- appropriate reader table index.
local numberIndices = {
    [1] = LibSerialize._ReaderIndex.NUM_8_POS,
    [2] = LibSerialize._ReaderIndex.NUM_16_POS,
    [3] = LibSerialize._ReaderIndex.NUM_24_POS,
    [4] = LibSerialize._ReaderIndex.NUM_32_POS,
    [7] = LibSerialize._ReaderIndex.NUM_64_POS,
}
local stringIndices = {
    [1] = LibSerialize._ReaderIndex.STR_8,
    [2] = LibSerialize._ReaderIndex.STR_16,
    [3] = LibSerialize._ReaderIndex.STR_24,
}
local tableIndices = {
    [1] = LibSerialize._ReaderIndex.TABLE_8,
    [2] = LibSerialize._ReaderIndex.TABLE_16,
    [3] = LibSerialize._ReaderIndex.TABLE_24,
}
local arrayIndices = {
    [1] = LibSerialize._ReaderIndex.ARRAY_8,
    [2] = LibSerialize._ReaderIndex.ARRAY_16,
    [3] = LibSerialize._ReaderIndex.ARRAY_24,
}
local mixedIndices = {
    [1] = LibSerialize._ReaderIndex.MIXED_8,
    [2] = LibSerialize._ReaderIndex.MIXED_16,
    [3] = LibSerialize._ReaderIndex.MIXED_24,
}
local stringRefIndices = {
    [1] = LibSerialize._ReaderIndex.STRINGREF_8,
    [2] = LibSerialize._ReaderIndex.STRINGREF_16,
    [3] = LibSerialize._ReaderIndex.STRINGREF_24,
}
local tableRefIndices = {
    [1] = LibSerialize._ReaderIndex.TABLEREF_8,
    [2] = LibSerialize._ReaderIndex.TABLEREF_16,
    [3] = LibSerialize._ReaderIndex.TABLEREF_24,
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
        local ref = stringRefs[value]
        if ref then
            -- DebugPrint("Serializing string ref:", value)
            local required = GetRequiredBytes(ref)
            self:_WriteByte(readerIndexShift * stringRefIndices[required])
            self:_WriteInt(stringRefs[value], required)
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
                self:_AddReference(stringRefs, value)
            end
        end
    end,
    ["table"] = function(self, value)
        local ref = tableRefs[value]
        if ref then
            -- DebugPrint("Serializing table ref:", value)
            local required = GetRequiredBytes(ref)
            self:_WriteByte(readerIndexShift * tableRefIndices[required])
            self:_WriteInt(tableRefs[value], required)
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
                    -- Exclude keys that have already been written via the previous loop.
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

            self:_AddReference(tableRefs, value)
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
    self:_WriteByte(MINOR)
    self:_WriteObject(input)

    self:_ClearReferences()
    return FlushWriter()
end

function LibSerialize:DeserializeValue(input)
    self:_ClearReferences()
    local ReadBytes, ReaderBytesLeft = CreateReader(input)

    self._readBytes = ReadBytes

    -- Since there's only one compression version currently,
    -- no extra work needs to be done to decode the data.
    local version = self:_ReadByte()
    assert(version == MINOR)
    local output = self:_ReadObject()

    local remaining = ReaderBytesLeft()
    if remaining ~= 0 then
        error(remaining > 0
              and "Input not fully read"
              or "Reader went past end of input")
    end

    self:_ClearReferences()
    return output
end

function LibSerialize:Deserialize(input)
    local success, output = pcall(self.DeserializeValue, self, input)

    self:_ClearReferences()
    return success, output
end
