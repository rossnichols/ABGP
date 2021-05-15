local _G = _G;
local ABGP = _G.ABGP;

local GetServerTime = GetServerTime;
local UnitName = UnitName;
local table = table;
local ipairs = ipairs;
local pairs = pairs;
local date = date;
local max = max;
local abs = abs;
local floor = floor;
local tonumber = tonumber;

local hasCompleteCached = false;
local hasComplete = false;
local hasActivePlayers = false;
local checkedHistory = false;
local lastHistoryId = 0;
local historyVersion = 1;

ABGP.ItemHistoryType = {
    DELETE = 1,

    ITEMADD = 10,
    ITEMREMOVE = 11,
    ITEMUPDATE = 12,
    ITEMWIPE = 13,

    GPITEM = 20,
    GPBONUS = 21,
    GPDECAY = 22,
    GPRESET = 23,
};
ABGP.ItemHistoryIndex = {
    TYPE = 1,       -- from ABGP.ItemHistoryType
    ID = 2,         -- from ABGP:GetHistoryId()
    DATE = 3,       -- date applied (number)

    -- ABGP.ItemHistoryType.DELETE
    DELETEDID = 4,  -- from ABGP:GetHistoryId()

    -- ABGP.ItemHistoryType.ITEMADD, ITEMUPDATE
    -- ABGP.ItemDataIndex.*

    -- ABGP.ItemHistoryType.ITEMREMOVE
    -- ABGP.ItemDataIndex.NAME
    -- ABGP.ItemDataIndex.ITEMLINK
    -- ABGP.ItemDataIndex.PRERELEASE

    -- ABGP.ItemHistoryType.ITEMWIPE
    -- ABGP.ItemDataIndex.PRERELEASE

    -- ABGP.ItemHistoryType.GPITEM
    PLAYER = 4,     -- player name (string)
    GP = 5,         -- gp cost (number)
    CATEGORY = 6,   -- from ABGP.ItemCategory
    ITEMLINK = 7,   -- item link (string)
    TOKENLINK = 8,  -- token item link (string)

    -- ABGP.ItemHistoryType.GPBONUS
    -- PLAYER = 4,     -- player name (string)
    -- GP = 5,         -- gp award (number)
    -- CATEGORY = 6,   -- from ABGP.ItemCategory
    NOTES = 7,      -- notes (string)

    -- ABGP.ItemHistoryType.GPDECAY
    VALUE = 4,      -- decay percentage (number)
    FLOOR = 5,      -- gp floor (number)

    -- ABGP.ItemHistoryType.GPRESET
    -- PLAYER = 4,     -- player name (string)
    -- GP = 5,         -- new gp (number)
    -- CATEGORY = 6,   -- from ABGP.ItemCategory
    -- NOTES = 7,      -- notes (string)
};

function ABGP:CheckHistoryVersion()
    _G.ABGP_Data2 = _G.ABGP_Data2 or {};
    _G.ABGP_Data2.history = _G.ABGP_Data2.history or {
        timestamp = 0,
        data = {},
        version = historyVersion
    };

    if _G.ABGP_Data2.history.version ~= historyVersion then
        -- In theory, we'd want to try to convert the older history to the new format.
        _G.ABGP_Data2.history.version = historyVersion;
        _G.ABGP_Data2.history.timestamp = 0;
        _G.ABGP_Data2.history.data = {};
    end
end

function ABGP:GetHistoryId()
    local nextId = max(lastHistoryId, (GetServerTime() - 1600000000) * 100);
    if nextId == lastHistoryId then nextId = nextId + 1; end
    lastHistoryId = nextId;
    return ("%s:%d"):format(UnitName("player"), nextId);
end

function ABGP:ParseHistoryId(id)
    local player, date = id:match("^(.-):(.-)$");
    if player then date = floor(tonumber(date) / 100) + 1600000000; end
    return player, date;
end

function ABGP:HistoryTriggerDecay(decayTime)
    local decayValue, decayFloor = self:GetGPDecayInfo();
    self:AddHistoryEntry(self.ItemHistoryType.GPDECAY, {
        [self.ItemHistoryIndex.DATE] = decayTime,
        [self.ItemHistoryIndex.VALUE] = decayValue,
        [self.ItemHistoryIndex.FLOOR] = decayFloor,
    });

    local floorText = "";
    if decayFloor ~= 0 then
        floorText = (" (floor: %d"):format(decayFloor);
    end
    self:Notify("Applied a decay of %d%%%s to EPGP.", decayValue, floorText);
    self:Notify("NOTE: this just adds the appropriate history entries for now. Officer notes are unchanged.");
end

function ABGP:HistoryAddPlayer(player, addTime, ep, gpS, gpG)
    self:AddHistoryEntry(self.ItemHistoryType.GPRESET, {
        [self.ItemHistoryIndex.DATE] = addTime,
        [self.ItemHistoryIndex.PLAYER] = player,
        [self.ItemHistoryIndex.GP] = gpS,
        [self.ItemHistoryIndex.CATEGORY] = self.ItemCategory.SILVER,
        [self.ItemHistoryIndex.NOTES] = "New active raider",
    }, true);
    self:AddHistoryEntry(self.ItemHistoryType.GPRESET, {
        [self.ItemHistoryIndex.DATE] = addTime,
        [self.ItemHistoryIndex.PLAYER] = player,
        [self.ItemHistoryIndex.GP] = gpG,
        [self.ItemHistoryIndex.CATEGORY] = self.ItemCategory.GOLD,
        [self.ItemHistoryIndex.NOTES] = "New active raider",
    });
end

function ABGP:AddHistoryEntry(entryType, entry, skipEvent)
    entry[self.ItemHistoryIndex.TYPE] = entryType;
    entry[self.ItemHistoryIndex.ID] = self:GetHistoryId();

    if not entry[self.ItemHistoryIndex.DATE] then
        local _, entryDate = self:ParseHistoryId(entry[self.ItemHistoryIndex.ID]);
        entry[self.ItemHistoryIndex.DATE] = entryDate;
    end

    table.insert(_G.ABGP_Data2.history.data, 1, entry);

    self:SyncNewEntries({ [entry[self.ItemHistoryIndex.ID]] = entry });

    if not skipEvent then
        self:UpdateHistory();
    end

    return entry;
end

function ABGP:UpdateHistory()
    self:Fire(self.InternalEvents.HISTORY_UPDATED);
end

function ABGP:ProcessItemHistory(gpHistory, includeNonItems)
    local processed = {};
    local deleted = {};
    for _, data in ipairs(gpHistory) do
        if not deleted[data[ABGP.ItemHistoryIndex.ID]] then
            local entryType = data[ABGP.ItemHistoryIndex.TYPE];
            if entryType == ABGP.ItemHistoryType.GPITEM then
                table.insert(processed, data);
            elseif entryType == ABGP.ItemHistoryType.DELETE then
                deleted[data[ABGP.ItemHistoryIndex.DELETEDID]] = true;
            elseif includeNonItems then
                table.insert(processed, data);
            end
        end
    end

    table.sort(processed, function(a, b)
        return a[ABGP.ItemHistoryIndex.DATE] > b[ABGP.ItemHistoryIndex.DATE];
    end);

    return processed;
end

function ABGP:GetItemData(prerelease)
    local history = _G.ABGP_Data2.history.data;
    local processed = {};
    local deleted = {};

    -- Find the most recent entry for each item name,
    -- breaking early if an item wipe entry is encountered.
    for _, data in ipairs(history) do
        if not deleted[data[self.ItemHistoryIndex.ID]] then
            local entryType = data[self.ItemHistoryIndex.TYPE];
            if entryType == self.ItemHistoryType.ITEMADD or
               entryType == self.ItemHistoryType.ITEMREMOVE or
               entryType == self.ItemHistoryType.ITEMUPDATE then

                local item = data[self.ItemDataIndex.NAME];
                if not processed[item] and data[self.ItemDataIndex.PRERELEASE] == prerelease then
                    processed[item] = data;
                end
            elseif entryType == self.ItemHistoryType.ITEMWIPE then
                if data[self.ItemDataIndex.PRERELEASE] == prerelease then
                    break;
                end
            elseif entryType == ABGP.ItemHistoryType.DELETE then
                deleted[data[ABGP.ItemHistoryIndex.DELETEDID]] = true;
            end
        end
    end

    -- If the most recent entry for any item is a remove, remove the item.
    for item, data in pairs(processed) do
        if data[self.ItemHistoryIndex.TYPE] == self.ItemHistoryType.ITEMREMOVE then
            processed[item] = nil
        end
    end

    -- Convert the entries to an array.
    local array = {};
    for item, item in pairs(processed) do
        table.insert(array, item);
    end

    -- Sort the array alphabetically, but ensuring a token's items directly follow it.
    table.sort(array, function(a, b)
        local aItem = a[self.ItemDataIndex.NAME];
        local bItem = b[self.ItemDataIndex.NAME];
        local aRelated = a[self.ItemDataIndex.RELATED];
        local bRelated = b[self.ItemDataIndex.RELATED];

        if aRelated == bRelated then
            return aItem < bItem;
        elseif aRelated and bRelated then
            return aRelated < bRelated;
        elseif aRelated then
            if aRelated == bItem then
                return false;
            else
                return aRelated < bItem;
            end
        else
            if aItem == bRelated then
                return true;
            else
                return aItem < bRelated;
            end
        end
    end);

    return array;
end

function ABGP:GetMispricedAwards(timeLen)
    timeLen = timeLen or 30 * 24 * 60 * 60;
    local history = self:ProcessItemHistory(_G.ABGP_Data2.history.data, false);
    local endTime = GetServerTime() - timeLen;

    for i, entry in ipairs(history) do
        if entry[self.ItemHistoryIndex.DATE] < endTime then break; end

        local gp = entry[self.ItemHistoryIndex.GP];
        local cat = entry[self.ItemHistoryIndex.CATEGORY];
        local itemLink = entry[self.ItemHistoryIndex.ITEMLINK];
        local value = self:GetItemValue(self:GetItemId(itemLink));
        if value and gp ~= 0 and (gp ~= value.gp or cat ~= value.category) then
            local entryMsg = ("%s to %s for %s on %s now costs %s"):format(
                value.itemLink,
                self:ColorizeName(entry[self.ItemHistoryIndex.PLAYER]),
                self:FormatCost(entry[self.ItemHistoryIndex.GP], entry[self.ItemHistoryIndex.CATEGORY]),
                date("%m/%d/%y", entry[self.ItemHistoryIndex.DATE]),
                self:FormatCost(value.gp, value.category));
            self:Notify(entryMsg);
        end
    end
end

function ABGP:GetEffectiveCost(id, cost)
    if cost.cost == 0 then return cost, 0; end
    local history = self:ProcessItemHistory(_G.ABGP_Data2.history.data, true);
    local effectiveCost = 0;
    local decayCount = 0;

    for i = #history, 1, -1 do
        local entry = history[i];
        if entry[self.ItemHistoryIndex.ID] == id then
            effectiveCost = cost.cost;
        elseif cost ~= 0 and entry[self.ItemHistoryIndex.TYPE] == self.ItemHistoryType.GPDECAY then
            effectiveCost = effectiveCost * (1 - (entry[self.ItemHistoryIndex.VALUE] * 0.01));
            effectiveCost = max(effectiveCost, entry[self.ItemHistoryIndex.FLOOR]);
            decayCount = decayCount + 1;
        end
    end

    if effectiveCost == 0 then
        return false;
    end
    return { cost = effectiveCost, category = cost.category }, decayCount;
end

function ABGP:HistoryOnActivePlayersRefreshed()
    hasCompleteCached = false;
    hasActivePlayers = true;
    if not checkedHistory then
        self:HistoryOnGuildRosterUpdate();
    end
end

function ABGP:HistoryOnUpdate()
    -- ITEMTODO: kind of expensive to refresh item values if you get non-item history entries
    self:RefreshItemValues();
    hasCompleteCached = false;
end

function ABGP:CalculateCurrentGP(player, category, history)
    history = history or self:ProcessItemHistory(_G.ABGP_Data2.history.data, true);
    local gp = 0;
    for i = #history, 1, -1 do
        local entry = history[i];
        local entryType = entry[self.ItemHistoryIndex.TYPE];
        if (entryType == self.ItemHistoryType.GPITEM or entryType == self.ItemHistoryType.GPBONUS) and
           entry[self.ItemHistoryIndex.PLAYER] == player and
           entry[self.ItemHistoryIndex.CATEGORY] == category then
            gp = gp + entry[self.ItemHistoryIndex.GP];
            -- print("adding", entry[self.ItemHistoryIndex.GP], "=>", gp);
        elseif entryType == self.ItemHistoryType.GPDECAY then
            gp = gp * (1 - (entry[self.ItemHistoryIndex.VALUE] * 0.01));
            gp = max(gp, entry[self.ItemHistoryIndex.FLOOR]);
            -- print("decaying", "=>", gp);
        elseif entryType == self.ItemHistoryType.GPRESET and
               entry[self.ItemHistoryIndex.PLAYER] == player and
               entry[self.ItemHistoryIndex.CATEGORY] == category then
            gp = entry[self.ItemHistoryIndex.GP];
            -- print("resetting", entry[self.ItemHistoryIndex.GP], "=>", gp);
        end
    end

    return gp;
end

function ABGP:HasCompleteHistory(shouldPrint)
    if hasCompleteCached and not shouldPrint then return hasComplete; end

    hasComplete = true;
    local history = self:ProcessItemHistory(_G.ABGP_Data2.history.data, true);
    for category in pairs(self.ItemCategory) do
        for player, epgp in pairs(self:GetActivePlayers()) do
            if not epgp.trial then
                local calculated = self:CalculateCurrentGP(player, category, history);
                if abs(calculated - epgp.gp[category]) > 0.0015 then
                    hasComplete = false;
                    if shouldPrint then
                        self:Notify("Incomplete %s history for %s: expected %.3f, calculated %.3f.",
                            self.ItemCategoryNames[category], self:ColorizeName(player), epgp.gp[category], calculated);
                    end
                end
            end
        end
    end

    if hasComplete and shouldPrint then self:Notify("GP history is complete!"); end
    hasCompleteCached = true;
    return hasComplete;
end

function ABGP:HistoryOnEnteringWorld(isInitialLogin)
    -- Only check history on the initial login.
    if not isInitialLogin then checkedHistory = true; end
end

function ABGP:HistoryOnGuildRosterUpdate()
    if checkedHistory or not hasActivePlayers then return; end
    checkedHistory = true;
    hasCompleteCached = false;

    self:SyncHistory(true);
end

function ABGP:HistoryDeleteEntry(entry)
    self:AddHistoryEntry(self.ItemHistoryType.DELETE, {
        [ABGP.ItemHistoryIndex.DELETEDID] = entry[ABGP.ItemHistoryIndex.ID],
    });
end
