local LibSerialize = require("LibSerialize")

local pairs = pairs
local type = type


--[[---------------------------------------------------------------------------
    Examples from the top of LibSerialize.lua
--]]---------------------------------------------------------------------------

do
    local t = { "test", [false] = {} }
    t[ t[false] ] = "hello"
    local serialized = LibSerialize:Serialize(t, "extra")
    local success, tab, str = LibSerialize:Deserialize(serialized)
    assert(success)
    assert(tab[1] == "test")
    assert(tab[ tab[false] ] == "hello")
    assert(str == "extra")
end

do
    local serialized = LibSerialize:SerializeEx({ errorOnUnserializableType = false },
                                                print, { a = 1, b = print })
    local success, fn, tab = LibSerialize:Deserialize(serialized)
    assert(success)
    assert(fn == nil)
    assert(tab.a == 1)
    assert(tab.b == nil)
end

do
    local t = { a = 1 }
    t.t = t
    local serialized = LibSerialize:Serialize(t)
    local success, tab = LibSerialize:Deserialize(serialized)
    assert(success)
    assert(tab.t.t.t.t.t.t.a == 1)
end

do
    local t = { a = 1, b = print, c = 3 }
    local nested = { a = 1, b = print, c = 3 }
    t.nested = nested
    setmetatable(nested, { __LibSerialize = {
        filter = function(t, k, v) return k ~= "c" end
    }})
    local opts = {
        filter = function(t, k, v) return LibSerialize:IsSerializableType(k, v) end
    }
    local serialized = LibSerialize:SerializeEx(opts, t)
    local success, tab = LibSerialize:Deserialize(serialized)
    assert(success)
    assert(tab.a == 1)
    assert(tab.b == nil)
    assert(tab.c == 3)
    assert(tab.nested.a == 1)
    assert(tab.nested.b == nil)
    assert(tab.nested.c == nil)
end


--[[---------------------------------------------------------------------------
    Utilities
--]]---------------------------------------------------------------------------


local function tCompare(lhsTable, rhsTable, depth)
    depth = depth or 1
    for key, value in pairs(lhsTable) do
        if type(value) == "table" then
            local rhsValue = rhsTable[key]
            if type(rhsValue) ~= "table" then
                return false
            end
            if depth > 1 then
                if not tCompare(value, rhsValue, depth - 1) then
                    return false
                end
            end
        elseif value ~= rhsTable[key] then
            -- print("mismatched value: " .. key .. ": " .. tostring(value) .. ", " .. tostring(rhsTable[key]))
            return false
        end
    end
    -- Check for any keys that are in rhsTable and not lhsTable.
    for key, value in pairs(rhsTable) do
        if lhsTable[key] == nil then
            -- print("mismatched key: " .. key)
            return false
        end
    end
    return true
end

local function tCopy(t)
    local copy = {}
    for k, v in pairs(t) do
        if type(v) == "table" then
            copy[k] = tCopy(v)
        else
            copy[k] = v
        end
    end
    return copy
end


--[[---------------------------------------------------------------------------
    Test cases for serialization
--]]---------------------------------------------------------------------------

-- Format: each test case is { value, bytelen }. The value will be serialized
-- and then deserialized, checking for success and equality, and the length of
-- the serialized string will be compared against bytelen. Note that the length
-- always contains one extra byte for the version number.
local testCases = {
    { nil, 2 },
    { true, 2 },
    { false, 2 },
    { 0, 2 },
    { 1, 2 },
    { 127, 2 },
    { 128, 3 },
    { 4095, 3 },
    { 4096, 4 },
    { 65535, 4 },
    { 65536, 5 },
    { 16777215, 5 },
    { 16777216, 6 },
    { 4294967295, 6 },
    { 4294967296, 9 },
    { 9007199254740992, 9 },
    { -1, 3 },
    { -4095, 3 },
    { -4096, 4 },
    { -65535, 4 },
    { -65536, 5 },
    { -16777215, 5 },
    { -16777216, 6 },
    { -4294967295, 6 },
    { -4294967296, 9 },
    { -9007199254740992, 9 },
    { 1.5, 6 },
    { 123.45678901235, 10 },
    { 148921291233.23, 10 },
    { -1.5, 6 },
    { -123.45678901235, 10 },
    { -148921291233.23, 10 },
}

local function assertion(i, desc)
    return ("Test case %d: %s"):format(i, desc)
end

for i, testCase in ipairs(testCases) do
    local serialized = LibSerialize:Serialize(testCase[1])
    assert(#serialized == testCase[2], assertion(i, ("Unexpected serialized length (%d)"):format(#serialized)))

    local success, deserialized = LibSerialize:Deserialize(serialized)
    assert(success, assertion(i, "Deserialization failed"))

    if type(testCase[1]) == "table" then
        assert(tCompare(testCase[1], deserialized), assertion(i, "Non-matching deserialization result (tables)"))
    else
        assert(testCase[1] == deserialized,
            assertion(i, ("Non-matching deserialization result: %s, %s"):format(tostring(testCase[1]), tostring(deserialized))))
    end
end
