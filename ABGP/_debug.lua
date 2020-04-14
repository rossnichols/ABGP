local _G = _G;
local ABGP = ABGP;

local GetItemInfo = GetItemInfo;
local print = print;
local pairs = pairs;
local ipairs = ipairs;

ABGP.Debug = true;
-- ABGP.Verbose = true;
-- ABGP.PrivateComms = true;
-- ABGP.ShowTestDistrib = true;
ABGP.IgnoreSelfDistributed = true;
ABGP.VersionDebug = "3.5.0";
ABGP.VersionCmpDebug = "3.5.0";


local lookup = {};

local function BuildLookup()
    local succeeded = true;

    local mc = _G.AtlasLoot.ItemDB.Storage.AtlasLootClassic_DungeonsAndRaids.MoltenCore.items;
    local ony = _G.AtlasLoot.ItemDB.Storage.AtlasLootClassic_DungeonsAndRaids.Onyxia.items;
    local wb = _G.AtlasLoot.ItemDB.Storage.AtlasLootClassic_DungeonsAndRaids.WorldBosses.items;
    local bwl = _G.AtlasLoot.ItemDB.Storage.AtlasLootClassic_DungeonsAndRaids.BlackwingLair.items;
    for _, collection in ipairs({ mc, ony, wb, bwl }) do
        for _, sub in ipairs(collection) do
            if sub[1] then
                for _, item in ipairs(sub[1]) do
                    local name, link = GetItemInfo(item[2]);
                    if name then
                        lookup[name] = ABGP:ShortenLink(link);
                    else
                        succeeded = false;
                    end
                end
            end
        end
    end

    if not succeeded then
        print("Failed to query some items!");
    end

    return succeeded;
end

function ABGP:FixupItems()
    if not BuildLookup() then return; end

    local p1 = _G.ABGP_Data.p1.itemValues;
    local p3 = _G.ABGP_Data.p3.itemValues;
    for _, phase in ipairs({ p1, p3 }) do
        for _, entry in ipairs(phase) do
            if lookup[entry[1]] then
                entry[3] = lookup[entry[1]];
            else
                print(("FAILED TO FIND [%s]"):format(entry[1]));
            end
        end
    end
end

function ABGP:FixupHistory()
    if not BuildLookup() then return; end

    local p1 = _G.ABGP_Data.p1.gpHistory;
    local p3 = _G.ABGP_Data.p3.gpHistory;
    for _, phase in ipairs({ p1, p3 }) do
        for _, entry in ipairs(phase) do
            if lookup[entry.item] then
                entry.itemLink = lookup[entry.item];
            else
                for name, link in pairs(lookup) do
                    local lowered = entry.item:lower();
                    if lowered:find(name:lower(), 1, true) then
                        -- print(("Updating [%s] to [%s]"):format(entry.item, name));
                        entry.item = name;
                        entry.itemLink = link;
                        break;
                    end
                end
                if not entry.itemLink then
                    print(("FAILED TO FIND [%s]"):format(entry.item));
                end
            end
        end
    end
end
