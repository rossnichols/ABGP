local _G = _G;
_G.ABGP = _G.LibStub("AceAddon-3.0"):NewAddon("ABGP", "AceBucket-3.0", "AceConsole-3.0", "AceComm-3.0", "AceEvent-3.0", "AceTimer-3.0", "AceHook-3.0");
local ABGP = _G.ABGP;
local AceGUI = _G.LibStub("AceGUI-3.0");

local UnitExists = UnitExists;
local UnitClass = UnitClass;
local UnitGUID = UnitGUID;
local UnitName = UnitName;
local GuildRoster = GuildRoster;
local GetChatWindowInfo = GetChatWindowInfo;
local UnitAffectingCombat = UnitAffectingCombat;
local CreateFrame = CreateFrame;
local GetItemInfo = GetItemInfo;
local IsInGroup = IsInGroup;
local GetInstanceInfo = GetInstanceInfo;
local IsInGuild = IsInGuild;
local C_GuildInfo = C_GuildInfo;
local GetAddOnMetadata = GetAddOnMetadata;
local GetServerTime = GetServerTime;
local UnitIsGroupLeader = UnitIsGroupLeader;
local IsEquippableItem = IsEquippableItem;
local IsAltKeyDown = IsAltKeyDown;
local GetClassColor = GetClassColor;
local EasyMenu = EasyMenu;
local ToggleDropDownMenu = ToggleDropDownMenu;
local select = select;
local pairs = pairs;
local ipairs = ipairs;
local tonumber = tonumber;
local table = table;
local tostring = tostring;
local min = min;
local max = max;
local date = date;
local type = type;

local version = "${ADDON_VERSION}";

_G.BINDING_HEADER_ABGP = "ABGP";
_G.BINDING_NAME_ABGP_SHOWITEMREQUESTS = "Show items currently opened for distribution";
_G.BINDING_NAME_ABGP_OPENMAINWINDOW = "Open the main window";

local itemDataRequestToken = 0;

local function OnGroupJoined()
    ABGP:SendComm(ABGP.CommTypes.STATE_SYNC, {}, "BROADCAST");
    ABGP:VersionOnGroupJoined();
    ABGP:OutsiderOnGroupJoined();
    ABGP:EventOnGroupJoined();
end

function ABGP:OnGuildRosterUpdate()
    self:RebuildGuildInfo();
    self:VersionOnGuildRosterUpdate();
    self:PriorityOnGuildRosterUpdate();
    self:HistoryOnGuildRosterUpdate();
end

function ABGP:OnEnable()
    if GetAddOnMetadata("ABGP", "Version") ~= version then
        self:NotifyVersionMismatch();
        self:RegisterChatCommand("abgp", function()
            self:Error("Please restart your game client!");
        end);
        return;
    end

    self:RegisterComm("ABGP");
    self:RegisterComm(self:GetCommPrefix());
    self:CheckHistoryVersion();
    self:InitOptions();
    self:HookTooltips();
    self:AddItemHooks();
    self:AddDataHooks();
    self:RefreshItemValues();
    self:SetupCommMonitor();
    self:InitMinimapIcon();
    self:InitEvents();

    -- Trigger a guild roster update to refresh priorities.
    GuildRoster();

    self:SetCallback(self.CommTypes.ITEM_REQUEST.name, function(self, event, data, distribution, sender, version)
        self:DistribOnItemRequest(data, distribution, sender, version);
    end, self);

    self:SetCallback(self.CommTypes.ITEM_PASS.name, function(self, event, data, distribution, sender, version)
        self:DistribOnItemPass(data, distribution, sender, version);
    end, self);

    self:SetCallback(self.CommTypes.ITEM_REQUESTCOUNT.name, function(self, event, data, distribution, sender, version)
        self:RequestOnItemRequestCount(data, distribution, sender, version);
        self:AnnounceOnItemRequestCount(data, distribution, sender, version);
    end, self);

    self:SetCallback(self.CommTypes.ITEM_COUNT.name, function(self, event, data, distribution, sender, version)
        self:RequestOnItemCount(data, distribution, sender, version);
        self:AnnounceOnItemCount(data, distribution, sender, version);
    end, self);

    self:SetCallback(self.CommTypes.ITEM_DIST_OPENED.name, function(self, event, data, distribution, sender, version)
        self:RequestOnDistOpened(data, distribution, sender, version);
        self:DistribOnDistOpened(data, distribution, sender, version);
        self:AnnounceOnDistOpened(data, distribution, sender, version);
        self:MinimapOnDistOpened(data, distribution, sender, version);
    end, self);

    self:SetCallback(self.CommTypes.ITEM_DIST_SUMMARY.name, function(self, event, data, distribution, sender, version)
        for _, eventData in ipairs(data) do
            self:Fire(eventData[1], eventData[2], distribution, sender, version);
        end
    end, self);

    self:SetCallback(self.CommTypes.ITEM_DIST_CLOSED.name, function(self, event, data, distribution, sender, version)
        self:RequestOnDistClosed(data, distribution, sender, version);
        self:AnnounceOnDistClosed(data, distribution, sender, version);
        self:MinimapOnDistClosed(data, distribution, sender, version);
    end, self);

    self:SetCallback(self.CommTypes.ITEM_AWARDED.name, function(self, event, data, distribution, sender, version)
        self:HistoryOnItemAwarded(data, distribution, sender, version);
        self:PriorityOnItemAwarded(data, distribution, sender, version);
        self:RequestOnItemAwarded(data, distribution, sender, version);
        self:AnnounceOnItemAwarded(data, distribution, sender, version);
    end, self);

    self:SetCallback(self.CommTypes.ITEM_TRASHED.name, function(self, event, data, distribution, sender, version)
        self:RequestOnItemTrashed(data, distribution, sender, version);
        self:AnnounceOnItemTrashed(data, distribution, sender, version);
    end, self);

    self:SetCallback(self.CommTypes.ITEM_REQUEST_RECEIVED.name, function(self, event, data, distribution, sender, version)
        self:RequestOnItemRequestReceived(data, distribution, sender, version);
        self:AnnounceOnItemRequestReceived(data, distribution, sender, version);
    end, self);

    self:SetCallback(self.CommTypes.ITEM_REQUEST_REJECTED.name, function(self, event, data, distribution, sender, version)
        self:RequestOnItemRequestRejected(data, distribution, sender, version);
    end, self);

    self:SetCallback(self.CommTypes.STATE_SYNC.name, function(self, event, data, distribution, sender, version)
        self:DistribOnStateSync(data, distribution, sender, version);
    end, self);

    self:SetCallback(self.CommTypes.VERSION_REQUEST.name, function(self, event, data, distribution, sender, version)
        self:OnVersionRequest(data, distribution, sender, version);
    end, self);

    self:SetCallback(self.CommTypes.VERSION_RESPONSE.name, function(self, event, data, distribution, sender, version)
        self:OnVersionResponse(data, distribution, sender, version);
    end, self);

    self:SetCallback(self.CommTypes.GUILD_NOTES_UPDATED.name, function(self, event, data, distribution, sender, version)
        if self:Get("outsider") then
            self:OutsiderOnOfficerNotesUpdated(data, distribution, sender, version);
        elseif IsInGuild() then
            GuildRoster();
            self:OnGuildRosterUpdate();
        end
    end, self);

    self:SetCallback(self.CommTypes.ITEM_ROLLED.name, function(self, event, data, distribution, sender, version)
        self:RequestOnItemRolled(data, distribution, sender, version);
        self:AnnounceOnItemRolled(data, distribution, sender, version);
    end, self);

    self:SetCallback(self.CommTypes.REQUEST_PRIORITY_SYNC.name, function(self, event, data, distribution, sender, version)
        self:OnPrioritySyncRequested(data, distribution, sender, version);
    end, self);

    self:SetCallback(self.CommTypes.PRIORITY_SYNC.name, function(self, event, data, distribution, sender, version)
        self:OnPrioritySync(data, distribution, sender, version);
    end, self);

    self:SetCallback(self.CommTypes.BOSS_LOOT.name, function(self, event, data, distribution, sender, version)
        self:AnnounceOnBossLoot(data, distribution, sender, version);
        self:EventOnBossLoot(data, distribution, sender, version);
    end, self);

    self:SetCallback(self.CommTypes.HISTORY_SYNC.name, function(self, event, data, distribution, sender, version)
        self:HistoryOnSync(data, distribution, sender, version);
    end, self);

    self:SetCallback(self.CommTypes.HISTORY_REPLACE_INITIATION.name, function(self, event, data, distribution, sender, version)
        self:HistoryOnReplaceInit(data, distribution, sender, version);
    end, self);

    self:SetCallback(self.CommTypes.HISTORY_MERGE.name, function(self, event, data, distribution, sender, version)
        self:HistoryOnMerge(data, distribution, sender, version);
    end, self);

    self:SetCallback(self.CommTypes.HISTORY_REPLACE.name, function(self, event, data, distribution, sender, version)
        self:HistoryOnReplace(data, distribution, sender, version);
    end, self);

    self:SetCallback(self.CommTypes.HISTORY_REPLACE_REQUEST.name, function(self, event, data, distribution, sender, version)
        self:HistoryOnReplaceRequest(data, distribution, sender, version);
    end, self);

    self:SetCallback(self.InternalEvents.ACTIVE_PLAYERS_REFRESHED, function(self)
        self:GuildOnActivePlayersRefreshed();
        self:DistribOnActivePlayersRefreshed();
        self:HistoryOnActivePlayersRefreshed();
        self:RefreshUI(self.RefreshReasons.ACTIVE_PLAYERS_REFRESHED);
    end, self);

    self:SetCallback(self.InternalEvents.ITEM_UNAWARDED, function(self, event, data)
        self:PriorityOnItemUnawarded(data);
        self:RequestOnItemUnawarded(data);
    end, self);

    self:SetCallback(self.InternalEvents.ITEM_CLOSED, function(self, event, data)
        self:RequestOnDistClosed(data);
        self:AnnounceOnDistClosed(data);
        self:MinimapOnDistClosed(data);
    end, self);

    self:SetCallback(self.InternalEvents.ITEM_REQUESTED, function(self, event, data)
        self:AnnounceOnItemRequested(data);
    end, self);

    self:SetCallback(self.InternalEvents.ITEM_PASSED, function(self, event, data)
        self:AnnounceOnItemPassed(data);
    end, self);

    self:SetCallback(self.InternalEvents.ITEM_FAVORITED, function(self, event, data)
        self:AnnounceOnItemFavorited(data);
    end, self);

    self:SetCallback(self.InternalEvents.LOOT_FRAME_OPENED, function(self, event, data)
        self:MinimapOnLootFrameOpened();
    end, self);

    self:SetCallback(self.InternalEvents.LOOT_FRAME_CLOSED, function(self, event, data)
        self:MinimapOnLootFrameClosed();
    end, self);

    self:SetCallback(self.InternalEvents.HISTORY_UPDATED, function(self, event, data)
        -- ITEMTODO: kind of expensive to refresh item values if you get non-item history entries
        self:RefreshItemValues();
        self:HistoryOnUpdate();
        self:RefreshUI(self.RefreshReasons.HISTORY_UPDATED);
        self:OptionsOnHistoryUpdate();
    end, self);

    local rollRegex = self:ConvertChatString(_G.RANDOM_ROLL_RESULT);
    local lootMultipleRegex = self:ConvertChatString(_G.LOOT_ITEM_MULTIPLE);
    local lootRegex = self:ConvertChatString(_G.LOOT_ITEM);
    local lootMultipleSelfRegex = self:ConvertChatString(_G.LOOT_ITEM_SELF_MULTIPLE);
    local lootSelfRegex = self:ConvertChatString(_G.LOOT_ITEM_SELF);
    local lastZone;

    self:RegisterBucketEvent("GUILD_ROSTER_UPDATE", 1, "OnGuildRosterUpdate");
    self:RegisterEvent("CHAT_MSG_SYSTEM", function(self, event, ...)
        local text = ...;
        local sender, roll, minRoll, maxRoll = text:match(rollRegex);
        if minRoll == "1" and maxRoll == "100" and sender and UnitExists(sender) then
            roll = tonumber(roll);
            self:DistribOnRoll(sender, roll);
        end
    end, self);
    self:RegisterEvent("CHAT_MSG_LOOT", function(self, event, ...)
        local text, _, _, _, player = ...;
        if not UnitExists(player) then return; end
        local _, item = text:match(lootMultipleRegex);
        if not item then
            _, item = text:match(lootRegex);
        end
        if not item then
            item = text:match(lootMultipleSelfRegex);
        end
        if not item then
            item = text:match(lootSelfRegex);
        end
        if item then
            -- self:LogDebug("%s looted %s.", player, item);
        end
    end, self);
    self:RegisterEvent("GROUP_JOINED", function(self, event, ...)
        OnGroupJoined();
    end, self);
    self:RegisterEvent("GROUP_LEFT", function(self, event, ...)
        self:RequestOnGroupLeft();
        self:OutsiderOnGroupLeft();
    end, self);
    self:RegisterEvent("GROUP_ROSTER_UPDATE", function(self, event, ...)
        self:RequestOnGroupUpdate();
        self:OutsiderOnGroupUpdate();
        self:EventOnGroupUpdate();
    end, self);
    self:RegisterEvent("PLAYER_LEAVING_WORLD", function(self, event, ...)
        self:DistribOnLeavingWorld();
    end, self);
    self:RegisterEvent("PLAYER_ENTERING_WORLD", function(self, event, ...)
        self:VersionOnEnteringWorld(...);
        self:CommOnEnteringWorld(...);
        self:HistoryOnEnteringWorld(...);
    end, self);
    self:RegisterEvent("LOADING_SCREEN_ENABLED", function(self, event, ...)
        self:DistribOnLoadingScreen();
    end, self);
    self:RegisterEvent("PLAYER_LOGOUT", function(self, event, ...)
        self:DistribOnLogout();
    end, self);
    self:RegisterEvent("BOSS_KILL", function(self, event, ...)
        self:EventOnBossKilled(...);
        self:AnnounceOnBossKilled(...);
    end, self);
    self:RegisterEvent("LOADING_SCREEN_DISABLED", function(self, event, ...)
        -- Per DBM, GetInstanceInfo() can return stale data for a period of time
        -- after this event is triggered. Workaround: wait a short period of time. Amazing.
        self:ScheduleTimer(function()
            local name, _, _, _, _, _, _, instanceId = GetInstanceInfo();
            if name and name ~= lastZone then
                lastZone = name;
                self:EventOnZoneChanged(name, instanceId);
                self:AnnounceOnZoneChanged(name, instanceId);
            end
        end, 5);
    end, self);
    self:RegisterEvent("LOOT_OPENED", function(self, event, ...)
        self:AnnounceOnLootOpened();
        self:DistribOnLootOpened();
    end, self);
    self:RegisterEvent("PARTY_LEADER_CHANGED", function(self, event, ...)
        self:OutsiderOnPartyLeaderChanged();
    end, self);
    self:RegisterEvent("ENCOUNTER_START", function(self, event, ...)
        self:CommOnEncounterStart(...);
    end, self);
    self:RegisterEvent("ENCOUNTER_END", function(self, event, ...)
        self:CommOnEncounterEnd(...);
        self:EventOnEncounterEnd(...);
    end, self);

    -- Precreate frames to avoid issues generating them during combat.
    if not UnitAffectingCombat("player") then
        AceGUI:Release(self:CreateMainWindow());
        AceGUI:Release(self:CreateDistribWindow());
        local frames = {};
        for i = 1, 50 do frames[AceGUI:Create("ABGP_Player")] = true; end
        for i = 1, 10 do frames[AceGUI:Create("ABGP_LootFrame")] = true; end
        for frame in pairs(frames) do AceGUI:Release(frame); end
    end

    if IsInGroup() then
        OnGroupJoined();
    end
end


--
-- Helpers for chat messages and colorization
--

local function GetSystemFrame()
    for i = 1, _G.NUM_CHAT_WINDOWS do
        local shown = select(7, GetChatWindowInfo(i));
        if shown then
            local frame = _G["ChatFrame" .. i];
            for _, type in ipairs(frame.messageTypeList) do
                if type == "SYSTEM" then
                    return frame;
                end
            end
        end
    end

    return _G.DEFAULT_CHAT_FRAME;
end

_G.ABGP_MessageLog = {};

ABGP.Color = "|cFF94E4FF";
ABGP.ColorTable = { 0.58, 0.89, 1, r = 0.58, g = 0.89, b = 1 };
function ABGP:Notify(str, ...)
    local msg = ("%s: %s"):format(self:ColorizeText("ABGP"), tostring(str):format(...));
    GetSystemFrame():AddMessage(msg, 1, 1, 1);
end

function ABGP:WriteLogged(log, str, ...)
    local formatted = tostring(str):format(...);

    _G.ABGP_MessageLog[log] = _G.ABGP_MessageLog[log] or {};
    log = _G.ABGP_MessageLog[log];
    -- while #log >= 2000 do table.remove(log, 1); end

    local timestamp = date("%m/%d/%y %I:%M:%S%p", GetServerTime()); -- https://strftime.org/
    table.insert(log, ("%s: %s"):format(timestamp, formatted));
end

function ABGP:NotifyLogged(log, str, ...)
    local formatted = tostring(str):format(...);
    self:Notify(formatted);
    self:WriteLogged(log, formatted);
end

function ABGP:LogDebug(str, ...)
    if self:GetDebugOpt() then
        self:Notify(str, ...);
    end
end

function ABGP:LogVerbose(str, ...)
    if self:GetDebugOpt("Verbose") then
        self:Notify(str, ...);
    end
end

function ABGP:Error(str, ...)
    self:Notify("|cffff0000ERROR:|r " .. str, ...);
end

function ABGP:ErrorLogged(log, str, ...)
    self:NotifyLogged(log, "|cffff0000ERROR:|r " .. str, ...);
end

function ABGP:Alert(str, ...)
    local msg = ("%s: %s"):format(self:ColorizeText("ABGP"), tostring(str):format(...));
    _G.RaidNotice_AddMessage(_G.RaidWarningFrame, msg, { r = 1, g = 1, b = 1 });
    self:Notify(str, ...);
end

function ABGP:ColorizeText(text)
    return ("%s%s|r"):format(ABGP.Color, text);
end

function ABGP:ColorizeName(name, class)
    if not class then
        local epgp = self:GetActivePlayer(name);
        if epgp then
            class = epgp.class;
        end
    end
    if not class then
        if UnitExists(name) then
            local _, className = UnitClass(name);
            class = className;
        end
    end
    if not class then
        local guildInfo = self:GetGuildInfo(name);
        if guildInfo then
            class = guildInfo[11];
        end
    end
    if not class then return name; end
    local color = select(4, GetClassColor(class));
    return ("|c%s%s|r"):format(color, name);
end


--
-- Helpers for privilege checks
--

function ABGP:IsPrivileged()
    -- Check officer status by looking for the privilege to speak in officer chat.
    local isOfficer = C_GuildInfo.GuildControlGetRankFlags(C_GuildInfo.GetGuildRankOrder(UnitGUID("player")))[4];
    return (isOfficer and not self:Get("outsider")) or ABGP:GetDebugOpt();
end

function ABGP:CanEditPublicNotes()
    if self:Get("outsider") then return false; end
    return C_GuildInfo.GuildControlGetRankFlags(C_GuildInfo.GetGuildRankOrder(UnitGUID("player")))[10];
end

function ABGP:CanEditOfficerNotes(player)
    if self:Get("outsider") then return false; end
    local guid = UnitGUID("player");
    if player then
        local guildInfo = self:GetGuildInfo(player);
        if not guildInfo then return false; end
        guid = guildInfo[17];
    end
    return C_GuildInfo.GuildControlGetRankFlags(C_GuildInfo.GetGuildRankOrder(guid))[12];
end


--
-- Helpers for item queries
--

local historyVersion = 1;

function ABGP:CheckHistoryVersion()
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

local itemValues = {};
local itemValuesPrerelease = {};
local lastHistoryId = 0;

ABGP.ItemDataIndex = {
    NAME = 4,
    GP = 5,
    ITEMLINK = 6,
    RAID = 7,
    BOSS = 8,
    PRIORITY = 9,
    CATEGORY = 10,
    NOTES = 11,
    RELATED = 12,
    PRERELEASE = 13,
};
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

    -- ABGP.ItemHistoryType.ITEM
    -- see ABGP.ItemDataIndex

    -- ABGP.ItemHistoryType.GPITEM
    PLAYER = 4,     -- player name (string)
    GP = 5,         -- gp cost (number)
    CATEGORY = 6,   -- from ABGP.ItemCategory
    ITEMID = 7,     -- item id (number)

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
ABGP.ItemCategory = {
    SILVER = "SILVER",
    GOLD = "GOLD",
};
ABGP.ItemCategoryNames = {
    [ABGP.ItemCategory.SILVER] = "Silver",
    [ABGP.ItemCategory.GOLD] = "Gold",
};
ABGP.ItemCategoriesSorted = {
    ABGP.ItemCategory.SILVER,
    ABGP.ItemCategory.GOLD
};

function ABGP:FormatCost(cost, category, fmt)
    if type(cost) == "table" then
        category = cost.category;
        cost = cost.cost;
    end

    local suffix = "";
    if category == self.ItemCategory.GOLD then suffix = " |cFFEBB400[G]|r"; end
    if category == self.ItemCategory.SILVER then suffix = " |cFF9BA4A8[S]|r"; end
    return (fmt or "%s%s GP"):format(cost, suffix);
end

function ABGP:GetHistoryId()
    local nextId = max(lastHistoryId, GetServerTime());
    if nextId == lastHistoryId then nextId = nextId + 1; end
    lastHistoryId = nextId;
    return ("%s:%d"):format(UnitName("player"), nextId);
end

function ABGP:ParseHistoryId(id)
    local player, date = id:match("^(.-):(.-)$");
    if player then date = tonumber(date); end
    return player, date;
end

function ABGP:ValueFromItem(item)
    return {
        item = item[ABGP.ItemDataIndex.NAME],
        itemLink = item[ABGP.ItemDataIndex.ITEMLINK],
        itemId = ABGP:GetItemId(item[ABGP.ItemDataIndex.ITEMLINK]),
        gp = item[ABGP.ItemDataIndex.GP],
        boss = ABGP.tCopy(item[ABGP.ItemDataIndex.BOSS]),
        raid = item[ABGP.ItemDataIndex.RAID],
        priority = ABGP.tCopy(item[ABGP.ItemDataIndex.PRIORITY]),
        notes = item[ABGP.ItemDataIndex.NOTES],
        token = (item[ABGP.ItemDataIndex.GP] == "T") and {},
        related = item[ABGP.ItemDataIndex.RELATED],
        category = item[ABGP.ItemDataIndex.CATEGORY],
        dataStore = item,
    };
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

function ABGP:RefreshItemValues()
    local dataSets = {
        { store = itemValues, prerelease = false },
        { store = itemValuesPrerelease, prerelease = true },
    };

    for _, data in pairs(dataSets) do
        table.wipe(data.store);
        local items = self:GetItemData(data.prerelease);

        for _, item in ipairs(items) do
            local itemLink = item[ABGP.ItemDataIndex.ITEMLINK];
            local value = self:ValueFromItem(item);
            data.store[item[ABGP.ItemDataIndex.NAME]] = value;
            data.store[ABGP:GetItemId(itemLink)] = value;

            if value.related then
                local token = ABGP:GetItemValue(value.related, data.prerelease);
                table.insert(token.token, itemLink);
            end

            -- Try to ensure info about the item is cached locally.
            if itemLink then GetItemInfo(itemLink); end
        end
    end
end

function ABGP:ItemValueIsUpdated(value, oldValue)
    local isUpdated = true;
    local oldValue = oldValue or ABGP:GetItemValue(value.item);
    if oldValue then
        isUpdated =
            oldValue.gp ~= value.gp or
            oldValue.category ~= value.category or
            oldValue.notes ~= value.notes or
            #oldValue.priority ~= #value.priority;

        if not isUpdated then
            for i, oldPri in ipairs(oldValue.priority) do
                if value.priority[i] ~= oldPri then
                    isUpdated = true;
                    break;
                end
            end
        end
    end

    return isUpdated;
end

function ABGP:GetItemValue(itemName, prerelease)
    if not itemName then return; end
    return (prerelease and itemValuesPrerelease or itemValues)[itemName];
end

function ABGP:GetItemName(itemLink)
    return itemLink:match("%[(.-)%]");
end

function ABGP:GetItemId(itemLink)
    if not itemLink then return 0; end
    if type(itemLink) == "number" then return itemLink; end
    return tonumber(itemLink:match("item:(%d+)") or "");
end

function ABGP:ShortenLink(itemLink)
    return (itemLink:gsub("|H(item:%d+).-|h", "|H%1|h"));
end

local scanner = CreateFrame("GameTooltip", "ABGPScanningTooltip", nil, "GameTooltipTemplate");
scanner:SetOwner(UIParent, "ANCHOR_NONE");
function ABGP:IsItemUsable(itemLink)
    scanner:ClearLines();
    scanner:SetHyperlink(itemLink);
    -- self:LogVerbose("%s:%d", itemLink, select("#", scanner:GetRegions()));
    for i = 1, select("#", scanner:GetRegions()) do
        local region = select(i, scanner:GetRegions());
        if region and region:GetObjectType() == "FontString" and region:GetText() then
            if region:GetText() == "Retrieving item information" then
                -- No info available: assume usable.
                -- self:LogVerbose("no item info available");
                return true;
            end
            local r, g, b = region:GetTextColor();
            if r >= .9 and g <= .2 and b <= .2 then
                -- self:LogVerbose("%s is not usable: %s %.2f %.2f %.2f", itemLink, region:GetText() or "<none>", r, g, b);
                return false;
            else
                -- self:LogVerbose("%s %.2f %.2f %.2f", region:GetText() or "<none>", r, g, b);
            end
        end
    end

    local itemId = self:GetItemId(itemLink);
    local value = self:GetItemValue(itemId) or self:GetItemValue(itemId, true);
    if value and value.token then
        for _, item in ipairs(value.token) do
            if self:IsItemUsable(item) then return true; end
        end
        return false;
    end

    return true;
end

function ABGP:ConvertChatString(chatString)
    chatString = chatString:gsub("([()-.%[%]])", "%%%1");
    chatString = chatString:gsub("%%s", "(.-)");
    chatString = chatString:gsub("%%d", "(%%d+)");
    return chatString;
end


--
-- Helpers for item requests
--

ABGP.RequestTypes = {
    MS = "MS",
    OS = "OS",
    MANUAL = "MANUAL",
};


--
-- Helpers for active player tracking
--

local activePlayers = {};

function ABGP:RefreshActivePlayers()
    table.wipe(activePlayers);
    for _, pri in ipairs(self.Priorities) do
        activePlayers[pri.player] = pri;
    end

    self:Fire(self.InternalEvents.ACTIVE_PLAYERS_REFRESHED);
end

function ABGP:GetActivePlayers()
    return activePlayers;
end

function ABGP:GetActivePlayer(name)
    return activePlayers[name or UnitName("player")];
end

function ABGP:OnPrioritySyncRequested(data, distribution, sender)
    self:SendComm(ABGP.CommTypes.PRIORITY_SYNC, {
        priorities = self.Priorities,
    }, "WHISPER", sender);
end

function ABGP:OnPrioritySync(data, distribution, sender)
    self:Notify("Received sync data from %s!", self:ColorizeName(sender));
    self.Priorities = data.priorities;
    self:RefreshActivePlayers();
end


--
-- Hook for HandleModifiedItemClick to detect [mod]-clicks on items
--

local hmicFns = {};

function ABGP:RegisterModifiedItemClickFn(fn)
    table.insert(hmicFns, fn);
end

ABGP:SecureHook("HandleModifiedItemClick", function(itemLink)
    if not IsAltKeyDown() or not ABGP:IsPrivileged() then return; end

    local _, fullLink = GetItemInfo(itemLink);
    if fullLink then
        for _, fn in ipairs(hmicFns) do
            if fn(fullLink) then return true; end
        end
    elseif ABGP:GetDebugOpt() then
        ABGP:Error("Failed GetItemInfo on %s!", itemLink);
    end
    return false;
end);


--
-- Hook for CloseSpecialWindows to allow our UI windows to close on Escape.
--

local openWindows = {};
local openPopups = {};
local function CloseABGPWindows(t)
    local found = false;
    for window in pairs(t) do
        found = true;
        window:Hide();
    end
    return found;
end

function ABGP:CloseSpecialWindows()
    local found = self.hooks.CloseSpecialWindows();
    return CloseABGPWindows(openWindows) or found;
end
ABGP:RawHook("CloseSpecialWindows", true);

function ABGP:StaticPopup_EscapePressed()
    local found = self.hooks.StaticPopup_EscapePressed();
    return CloseABGPWindows(openPopups) or found;
end
ABGP:RawHook("StaticPopup_EscapePressed", true);

function ABGP:OpenWindow(window)
    openWindows[window] = true;
end

function ABGP:CloseWindow(window)
    openWindows[window] = nil;
end

function ABGP:OpenPopup(window)
    openPopups[window] = true;
end

function ABGP:ClosePopup(window)
    openPopups[window] = nil;
end


--
-- Support for maintaining window positions/sizes across reloads/relogs
--

_G.ABGP_WindowManagement = {};

function ABGP:BeginWindowManagement(window, name, defaults)
    _G.ABGP_WindowManagement[name] = _G.ABGP_WindowManagement[name] or {};
    local saved = _G.ABGP_WindowManagement[name];
    if not defaults.version or saved.version ~= defaults.version then
        table.wipe(saved);
        saved.version = defaults.version;
    end

    defaults.minWidth = defaults.minWidth or defaults.defaultWidth;
    defaults.maxWidth = defaults.maxWidth or defaults.defaultWidth;
    defaults.minHeight = defaults.minHeight or defaults.defaultHeight;
    defaults.maxHeight = defaults.maxHeight or defaults.defaultHeight;

    local management = { name = name, defaults = defaults };
    window:SetUserData("windowManagement", management);

    saved.width = min(max(defaults.minWidth, saved.width or defaults.defaultWidth), defaults.maxWidth);
    saved.height = min(max(defaults.minHeight, saved.height or defaults.defaultHeight), defaults.maxHeight);
    window:SetStatusTable(saved);

    management.oldMinW, management.oldMinH = window.frame:GetMinResize();
    management.oldMaxW, management.oldMaxH = window.frame:GetMaxResize();
    window.frame:SetMinResize(defaults.minWidth, defaults.minHeight);
    window.frame:SetMaxResize(defaults.maxWidth, defaults.maxHeight);

    -- Ensure the window is onscreen.
    local offset = window.frame:GetLeft() - _G.UIParent:GetLeft();
    if offset < 0 then
        saved.left = saved.left - offset;
    end
    offset = _G.UIParent:GetTop() - window.frame:GetTop();
    if offset < 0 then
        saved.top = saved.top + offset;
    end
    offset = _G.UIParent:GetRight() - window.frame:GetRight();
    if offset < 0 then
        saved.left = saved.left + offset;
    end
    offset = window.frame:GetBottom() - _G.UIParent:GetBottom();
    if offset < 0 then
        saved.top = saved.top - offset;
    end
    window:SetStatusTable(saved);

    if defaults.minWidth == defaults.maxWidth and defaults.minHeight == defaults.maxHeight then
        window.line1:Hide();
        window.line2:Hide();
    end
end

function ABGP:EndWindowManagement(window)
    local management = window:GetUserData("windowManagement");
    local name = management.name;
    _G.ABGP_WindowManagement[name] = _G.ABGP_WindowManagement[name] or {};
    local saved = _G.ABGP_WindowManagement[name];

    saved.left = window.frame:GetLeft();
    saved.top = window.frame:GetTop();
    saved.width = window.frame:GetWidth();
    saved.height = window.frame:GetHeight();
    window.frame:SetMinResize(management.oldMinW, management.oldMinH);
    window.frame:SetMaxResize(management.oldMaxW, management.oldMaxH);
    window.line1:Show();
    window.line2:Show();

    self:HideContextMenu();
end


--
-- Context Menu support (https://wow.gamepedia.com/UI_Object_UIDropDownMenu)
--

local contextFrame = CreateFrame("Frame", "ABGPContextMenu", _G.UIParent, "UIDropDownMenuTemplate");
contextFrame.relativePoint = "BOTTOMRIGHT";
function ABGP:ShowContextMenu(context, frame)
    if self:IsContextMenuOpen() then
        self:HideContextMenu();
    else
        EasyMenu(context, contextFrame, frame or "cursor", 3, -3, "MENU");
    end
end

function ABGP:IsContextMenuOpen()
    return (_G.UIDROPDOWNMENU_OPEN_MENU == contextFrame);
end

function ABGP:HideContextMenu()
    if self:IsContextMenuOpen() then
        ToggleDropDownMenu(nil, nil, contextFrame);
    end
end


--
-- AtlasLoot favorites integration
--

local function AtlasLootFaves()
    if _G.AtlasLoot and _G.AtlasLoot.Addons and _G.AtlasLoot.Addons.GetAddon then
        return _G.AtlasLoot.Addons:GetAddon("Favourites");
    end
end

function ABGP:CanFavoriteItems()
    return AtlasLootFaves() ~= nil;
end

function ABGP:IsItemFavorited(itemLink)
    local faves = AtlasLootFaves();
    if faves and itemLink then
        local itemId = self:GetItemId(itemLink);
        if faves:IsFavouriteItemID(itemId) then
            return true;
        end
    end
    return false;
end

function ABGP:SetItemFavorited(itemLink, favorited)
    local faves = AtlasLootFaves();
    if faves then
        local itemId = self:GetItemId(itemLink);
        if favorited then
            faves:AddItemID(itemId);
        else
            faves:RemoveItemID(itemId);
        end
        self:Fire(self.InternalEvents.ITEM_FAVORITED, {
            itemLink = itemLink
        });
    end
end


--
-- Util
--

ABGP.tCompare = function(lhsTable, rhsTable, depth)
    depth = depth or 1;
    for key, value in pairs(lhsTable) do
        if type(value) == "table" then
            local rhsValue = rhsTable[key];
            if type(rhsValue) ~= "table" then
                return false;
            end
            if depth > 1 then
                if not ABGP.tCompare(value, rhsValue, depth - 1) then
                    return false;
                end
            end
        elseif value ~= rhsTable[key] then
            -- print("mismatched value: " .. key .. ": " .. tostring(value) .. ", " .. tostring(rhsTable[key]));
            return false;
        end
    end
    -- Check for any keys that are in rhsTable and not lhsTable.
    for key in pairs(rhsTable) do
        if lhsTable[key] == nil then
            -- print("mismatched key: " .. key);
            return false;
        end
    end
    return true;
end

ABGP.tCopy = function(t)
    local copy = {};
    for k, v in pairs(t) do
        if type(v) == "table" then
            copy[k] = ABGP.tCopy(v)
        else
            copy[k] = v;
        end
    end
    return copy;
end

ABGP.reverse = function(arr)
    local i, j = 1, #arr;
    while i < j do
        arr[i], arr[j] = arr[j], arr[i];
        i = i + 1;
        j = j - 1;
    end
end

local itemSlots = {
    INVTYPE_HEAD = { _G.INVSLOT_HEAD },
    INVTYPE_NECK = { _G.INVSLOT_NECK },
    INVTYPE_SHOULDER = { _G.INVSLOT_SHOULDER },
    INVTYPE_BODY = { _G.INVSLOT_BODY },
    INVTYPE_CHEST = { _G.INVSLOT_CHEST },
    INVTYPE_WAIST = { _G.INVSLOT_WAIST },
    INVTYPE_LEGS = { _G.INVSLOT_LEGS },
    INVTYPE_FEET = { _G.INVSLOT_FEET },
    INVTYPE_WRIST = { _G.INVSLOT_WRIST },
    INVTYPE_HAND = { _G.INVSLOT_HAND },
    INVTYPE_FINGER = { _G.INVSLOT_FINGER1, _G.INVSLOT_FINGER2 },
    INVTYPE_TRINKET = { _G.INVSLOT_TRINKET1, _G.INVSLOT_TRINKET2 },
    INVTYPE_WEAPON = { _G.INVSLOT_MAINHAND, _G.INVSLOT_OFFHAND },
    INVTYPE_SHIELD = { _G.INVSLOT_MAINHAND, _G.INVSLOT_OFFHAND },
    INVTYPE_RANGED = { _G.INVSLOT_RANGED },
    INVTYPE_CLOAK = { _G.INVSLOT_BACK },
    INVTYPE_2HWEAPON = { _G.INVSLOT_MAINHAND, _G.INVSLOT_OFFHAND },
    INVTYPE_TABARD = { _G.INVSLOT_TABARD },
    INVTYPE_ROBE = { _G.INVSLOT_CHEST },
    INVTYPE_WEAPONMAINHAND = { _G.INVSLOT_MAINHAND, _G.INVSLOT_OFFHAND },
    INVTYPE_WEAPONOFFHAND = { _G.INVSLOT_MAINHAND, _G.INVSLOT_OFFHAND },
    INVTYPE_HOLDABLE = { _G.INVSLOT_MAINHAND, _G.INVSLOT_OFFHAND },
    INVTYPE_AMMO = { _G.INVSLOT_AMMO },
    INVTYPE_THROWN = { _G.INVSLOT_RANGED },
    INVTYPE_RANGEDRIGHT = { _G.INVSLOT_RANGED },
    INVTYPE_RELIC = { _G.INVSLOT_RANGED },
};

local itemOverrides = {
    -- Primal Hakkari Idol
    [22637] = { slots = { "INVTYPE_HEAD", "INVTYPE_LEGS" } },
};

function ABGP:GetTokenItems(itemLink, prerelease)
    local itemId = self:GetItemId(itemLink);
    local value = self:GetItemValue(itemId, prerelease);
    return value and value.token;
end

function ABGP:GetItemEquipSlots(itemLink, onlyOverride)
    local itemId = self:GetItemId(itemLink);
    if itemOverrides[itemId] and itemOverrides[itemId].slots then
        if #itemOverrides[itemId].slots == 1 then
            return itemSlots[itemOverrides[itemId].slots[1]];
        else
            local slots = {};
            for _, loc in ipairs(itemOverrides[itemId].slots) do
                for _, slot in ipairs(itemSlots[loc]) do
                    table.insert(slots, slot);
                end
            end
            return slots;
        end
    elseif not onlyOverride and IsEquippableItem(itemLink) then
        local equipLoc = select(9, GetItemInfo(itemLink));
        if equipLoc and itemSlots[equipLoc] then
            return itemSlots[equipLoc];
        end
    end
end

ABGP.StaticDialogTemplates = {
    JUST_BUTTONS = "JUST_BUTTONS",
    EDIT_BOX = "EDIT_BOX",
};

function ABGP:StaticDialogTemplate(template, t)
    t.timeout = 0;
    t.whileDead = true;
    t.hideOnEscape = true;
    if t.exclusive == nil then
        t.exclusive = true;
    end
    t.OnHyperlinkEnter = function(self, itemLink)
        _G.ShowUIPanel(_G.GameTooltip);
        _G.GameTooltip:SetOwner(self, "ANCHOR_BOTTOM");
        _G.GameTooltip:SetHyperlink(itemLink);
        _G.GameTooltip:Show();
    end;
    t.OnHyperlinkLeave = function(self)
        _G.GameTooltip:Hide();
    end;

    if template == ABGP.StaticDialogTemplates.JUST_BUTTONS then
        return t;
    elseif template == ABGP.StaticDialogTemplates.EDIT_BOX then
        t.hasEditBox = true;
        t.countInvisibleLetters = true;
        t.OnAccept = function(self, data)
            local text = self.editBox:GetText();
            if t.Validate then
                text = t.Validate(text, data);
                if text then
                    t.Commit(text, data);
                end
            else
                t.Commit(text, data);
            end
        end;
        t.OnShow = function(self, data)
            self.editBox:SetAutoFocus(false);
            if t.Validate then
                self.button1:Disable();
            end
            if t.notFocused then
                self.editBox:ClearFocus();
            end
        end;
        t.EditBoxOnTextChanged = function(self, data)
            if t.Validate then
                local parent = self:GetParent();
                local text = self:GetText();
                if t.Validate(text, data) then
                    parent.button1:Enable();
                else
                    parent.button1:Disable();
                end
            end
        end;
        t.EditBoxOnEnterPressed = function(self, data)
            if t.suppressEnterCommit then return; end

            local parent = self:GetParent();
            local text = self:GetText();
            if t.Validate then
                if parent.button1:IsEnabled() then
                    parent.button1:Click();
                else
                    local _, errorText = t.Validate(text, data);
                    if errorText then ABGP:Error("Invalid input! %s.", errorText); end
                end
            else
                parent.button1:Click();
            end
        end;
        t.EditBoxOnEscapePressed = function(self)
            self:ClearFocus();
        end;
        t.OnHide = function(self, data)
            self.editBox:SetAutoFocus(true);
        end;
        return t;
    end
end

StaticPopupDialogs["ABGP_PROMPT_RELOAD"] = ABGP:StaticDialogTemplate(ABGP.StaticDialogTemplates.JUST_BUTTONS, {
    text = "%s",
    button1 = "Reload",
    button2 = "Close",
    showAlert = true,
    OnAccept = ReloadUI,
});
