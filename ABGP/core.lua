local _G = _G;
_G.ABGP = _G.LibStub("AceAddon-3.0"):NewAddon("ABGP", "AceConsole-3.0", "AceComm-3.0", "AceEvent-3.0", "AceTimer-3.0");
local ABGP = ABGP;
local AceGUI = _G.LibStub("AceGUI-3.0");

local UnitExists = UnitExists;
local UnitClass = UnitClass;
local UnitGUID = UnitGUID;
local UnitName = UnitName;
local GetClassColor = GetClassColor;
local GuildRoster = GuildRoster;
local GetChatWindowInfo = GetChatWindowInfo;
local UnitAffectingCombat = UnitAffectingCombat;
local EasyMenu = EasyMenu;
local ToggleDropDownMenu = ToggleDropDownMenu;
local CreateFrame = CreateFrame;
local GetItemInfo = GetItemInfo;
local IsInGroup = IsInGroup;
local GetInstanceInfo = GetInstanceInfo;
local IsInGuild = IsInGuild;
local C_GuildInfo = C_GuildInfo;
local GetAddOnMetadata = GetAddOnMetadata;
local GetServerTime = GetServerTime;
local UnitIsGroupLeader = UnitIsGroupLeader;
local GetTime = GetTime;
local select = select;
local pairs = pairs;
local ipairs = ipairs;
local tonumber = tonumber;
local table = table;
local tostring = tostring;
local min = min;
local max = max;
local date = date;
local unpack = unpack;

local version = "${ADDON_VERSION}";

_G.BINDING_HEADER_ABGP = "ABGP";
_G.BINDING_NAME_ABGP_SHOWITEMREQUESTS = "Show item request window";

local itemDataRequestToken = 0;

local function OnGroupJoined()
    ABGP:SendComm(ABGP.CommTypes.STATE_SYNC, {
        token = GetTime(),
        itemDataTime = _G.ABGP_DataTimestamp,
    }, "BROADCAST");
    ABGP:VersionOnGroupJoined();
    ABGP:OutsiderOnGroupJoined();
end

local function OnGuildRosterUpdate()
    ABGP:RebuildGuildInfo();
    ABGP:VersionOnGuildRosterUpdate();
    ABGP:PriorityOnGuildRosterUpdate();
end

function ABGP:OnInitialize()
    if GetAddOnMetadata("ABGP", "Version") ~= version then
        self:NotifyVersionMismatch();
        return;
    end

    self:RegisterComm("ABGP");
    self:InitOptions();
    self:HookTooltips();
    self:AddItemHooks();
    self:AddDataHooks();
    self:CheckHardcodedData();
    self:RefreshItemValues();
    self:TrimAuditLog(30 * 24 * 60 * 60); -- 30 days

    -- Trigger a guild roster update to refresh priorities.
    GuildRoster();

    self:RegisterMessage(self.CommTypes.ITEM_REQUEST.name, function(self, event, data, distribution, sender)
        self:DistribOnItemRequest(data, distribution, sender);
    end, self);

    self:RegisterMessage(self.CommTypes.ITEM_PASS.name, function(self, event, data, distribution, sender)
        self:DistribOnItemPass(data, distribution, sender);
    end, self);

    self:RegisterMessage(self.CommTypes.ITEM_DISTRIBUTION_OPENED.name, function(self, event, data, distribution, sender)
        self:RequestOnDistOpened(data, distribution, sender);
        self:DistribOnDistOpened(data, distribution, sender);
    end, self);

    self:RegisterMessage(self.CommTypes.ITEM_DISTRIBUTION_CLOSED.name, function(self, event, data, distribution, sender)
        self:RequestOnDistClosed(data, distribution, sender);
    end, self);

    self:RegisterMessage(self.CommTypes.ITEM_DISTRIBUTION_AWARDED.name, function(self, event, data, distribution, sender)
        if sender ~= UnitName("player") then
            self:HistoryOnItemAwarded(data, distribution, sender);
            self:PriorityOnItemAwarded(data, distribution, sender);
        end

        self:RequestOnItemAwarded(data, distribution, sender);
    end, self);

    self:RegisterMessage(self.CommTypes.ITEM_DISTRIBUTION_TRASHED.name, function(self, event, data, distribution, sender)
        self:RequestOnItemTrashed(data, distribution, sender);
    end, self);

    self:RegisterMessage(self.CommTypes.STATE_SYNC.name, function(self, event, data, distribution, sender)
        self:DistribOnStateSync(data, distribution, sender);
        self:ItemOnStateSync(data, distribution, sender);
    end, self);

    self:RegisterMessage(self.CommTypes.VERSION_REQUEST.name, function(self, event, data, distribution, sender)
        self:OnVersionRequest(data, distribution, sender);
    end, self);

    self:RegisterMessage(self.CommTypes.VERSION_RESPONSE.name, function(self, event, data, distribution, sender)
        self:OnVersionResponse(data, distribution, sender);
    end, self);

    self:RegisterMessage(self.CommTypes.OFFICER_NOTES_UPDATED.name, function(self, event, data, distribution, sender)
        if self:Get("outsider") then
            self:OutsiderOnOfficerNotesUpdated();
        elseif IsInGuild() then
            GuildRoster();
            OnGuildRosterUpdate();
        end
    end, self);

    self:RegisterMessage(self.CommTypes.ITEM_ROLLED.name, function(self, event, data, distribution, sender)
        self:RequestOnItemRolled(data, distribution, sender);
    end, self);

    self:RegisterMessage(self.CommTypes.REQUEST_PRIORITY_SYNC.name, function(self, event, data, distribution, sender)
        self:OnPrioritySyncRequested(data, distribution, sender);
    end, self);

    self:RegisterMessage(self.CommTypes.PRIORITY_SYNC.name, function(self, event, data, distribution, sender)
        self:OnPrioritySync(data, distribution, sender);
    end, self);

    self:RegisterMessage(self.CommTypes.BOSS_LOOT.name, function(self, event, data, distribution, sender)
        self:AnnounceOnBossLoot(data, distribution, sender);
    end, self);

    self:RegisterMessage(self.CommTypes.REQUEST_ITEM_DATA_SYNC.name, function(self, event, data, distribution, sender)
        self:ItemOnRequestDataSync(data, distribution, sender);
    end, self);

    self:RegisterMessage(self.CommTypes.ITEM_DATA_SYNC.name, function(self, event, data, distribution, sender)
        self:ItemOnDataSync(data, distribution, sender);
    end, self);

    self:RegisterMessage(self.InternalEvents.ACTIVE_PLAYERS_REFRESHED, function(self)
        self:DistribOnActivePlayersRefreshed();
        self:RefreshUI(self.RefreshReasons.ACTIVE_PLAYERS_REFRESHED);
    end, self);

    self:RegisterMessage(self.InternalEvents.ITEM_DISTRIBUTION_UNAWARDED, function(self, event, data)
        self:PriorityOnItemUnawarded(data);
        self:RequestOnItemUnawarded(data);
    end, self);

    local rollRegex = self:ConvertChatString(_G.RANDOM_ROLL_RESULT);
    local lootMultipleRegex = self:ConvertChatString(_G.LOOT_ITEM_MULTIPLE);
    local lootRegex = self:ConvertChatString(_G.LOOT_ITEM);
    local lootMultipleSelfRegex = self:ConvertChatString(_G.LOOT_ITEM_SELF_MULTIPLE);
    local lootSelfRegex = self:ConvertChatString(_G.LOOT_ITEM_SELF);
    local lastZone;

    self:RegisterEvent("GUILD_ROSTER_UPDATE", function(self, event, ...)
        if not self:Get("outsider") then
            OnGuildRosterUpdate();
        end
    end, self);
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
    end, self);
    self:RegisterEvent("PLAYER_LEAVING_WORLD", function(self, event, ...)
        self:DistribOnLeavingWorld();
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
        -- Schedule two timers so we opportunistically process it quicker, with the
        -- second one to ensure we end up in the right final state.
        local onZoneChanged = function()
            local name, _, _, _, _, _, _, instanceId = GetInstanceInfo();
            if name and name ~= lastZone then
                lastZone = name;
                self:EventOnZoneChanged(name, instanceId);
                self:AnnounceOnZoneChanged(name, instanceId);
            end
        end
        self:ScheduleTimer(onZoneChanged, 1);
        self:ScheduleTimer(onZoneChanged, 5);
    end, self);
    self:RegisterEvent("LOOT_OPENED", function(self, event, ...)
        self:AnnounceOnLootOpened();
    end, self);
    self:RegisterEvent("PARTY_LEADER_CHANGED", function(self, event, ...)
        self:OutsiderOnPartyLeaderChanged();
    end, self);

    -- Precreate frames to avoid issues generating them during combat.
    if not UnitAffectingCombat("player") then
        AceGUI:Release(self:CreateMainWindow());
        AceGUI:Release(self:CreateDistribWindow());
        AceGUI:Release(self:CreateRequestWindow());
        local frames = {};
        for i = 1, 10 do frames[AceGUI:Create("ABGP_Item")] = true; end
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

ABGP.Color = "|cFF94E4FF";
ABGP.ColorTable = { 0.58, 0.89, 1, r = 0.58, g = 0.89, b = 1 };
function ABGP:Notify(str, ...)
    local msg = ("%s: %s"):format(self:ColorizeText("ABGP"), tostring(str):format(...));
    GetSystemFrame():AddMessage(msg, 1, 1, 1);
end

function ABGP:LogDebug(str, ...)
    if self.Debug then
        self:Notify(str, ...);
    end
end

function ABGP:LogVerbose(str, ...)
    if self.Verbose then
        self:Notify(str, ...);
    end
end

function ABGP:Error(str, ...)
    self:Notify("|cffff0000ERROR:|r " .. str, ...);
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
    return (isOfficer and not self:Get("outsider")) or ABGP.Debug;
end

function ABGP:CanEditPublicNotes()
    if self:Get("outsider") then return false; end
    return C_GuildInfo.GuildControlGetRankFlags(C_GuildInfo.GetGuildRankOrder(UnitGUID("player")))[10];
end

function ABGP:CanEditOfficerNotes()
    if self:Get("outsider") then return false; end
    return C_GuildInfo.GuildControlGetRankFlags(C_GuildInfo.GetGuildRankOrder(UnitGUID("player")))[12];
end


--
-- Helpers for item queries
--

local itemValues = {};
ABGP.ItemDataIndex = {
    NAME = 1,
    GP = 2,
    ITEMLINK = 3,
    BOSS = 4,
    PRIORITY = 5,
    NOTES = 6,
};

local function ValueFromItem(item, phase)
    return {
        item = item[ABGP.ItemDataIndex.NAME],
        gp = item[ABGP.ItemDataIndex.GP],
        boss = item[ABGP.ItemDataIndex.BOSS],
        priority = item[ABGP.ItemDataIndex.PRIORITY],
        notes = item[ABGP.ItemDataIndex.NOTES],
        phase = phase
    };
end

function ABGP:RefreshItemValues()
    itemValues = {};
    for phase in pairs(self.PhasesAll) do
        for _, item in ipairs(_G.ABGP_Data[phase].itemValues) do
            itemValues[item[ABGP.ItemDataIndex.NAME]] = ValueFromItem(item, phase);

            -- Try to ensure info about the item is cached locally.
            if item[ABGP.ItemDataIndex.ITEMLINK] then GetItemInfo(item[ABGP.ItemDataIndex.ITEMLINK]); end
        end
    end
end

function ABGP:BuildDefaultItemValues()
    local itemValues = {};
    for phase in pairs(self.PhasesAll) do
        for _, item in ipairs(self.initialData.ABGP_Data[phase].itemValues) do
            itemValues[item[ABGP.ItemDataIndex.NAME]] = ValueFromItem(item, phase);
        end
    end

    return itemValues;
end

local function IsValueUpdated(value, oldValue)
    local isUpdated = true;
    local oldValue = oldValue or ABGP:GetItemValue(value.item);
    if oldValue then
        isUpdated =
            oldValue.gp ~= value.gp or
            oldValue.boss ~= value.boss or
            oldValue.notes ~= value.notes or
            oldValue.phase ~= value.phase or
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

function ABGP:ItemOnStateSync(data, distribution, sender)
    local incomingTime = data.itemDataTime;
    if incomingTime > _G.ABGP_DataTimestamp then
        -- This person has newer item data. Request a sync.
        self:SendComm(self.CommTypes.REQUEST_ITEM_DATA_SYNC, {
            token = data.token,
        }, "WHISPER", sender);
    elseif incomingTime < _G.ABGP_DataTimestamp and UnitIsGroupLeader("player") then
        -- This person has older item data. Send them the latest.
        self:BroadcastItemData(sender);
    end
end

function ABGP:ItemOnRequestDataSync(data, distribution, sender)
    if data.token ~= itemDataRequestToken then
        itemDataRequestToken = data.token;
        self:BroadcastItemData();
    end
end

function ABGP:ItemOnDataSync(data, distribution, sender)
    -- Ignore data syncs that don't have a newer timestamp.
    if data.itemDataTime <= _G.ABGP_DataTimestamp then return; end

    _G.ABGP_DataTimestamp = data.itemDataTime;
    for phase, values in pairs(data.itemValues) do
        _G.ABGP_Data[phase].itemValues = values;
    end

    self:RefreshItemValues();

    self:Notify("Received the latest EPGP item data from %s!", self:ColorizeName(sender));
    self:LogDebug("Data timestamp: %s", date("%m/%d/%y %I:%M%p", _G.ABGP_DataTimestamp)); -- https://strftime.org/
end

function ABGP:CommitItemData()
    _G.ABGP_DataTimestamp = GetServerTime();
    self:BroadcastItemData();
end

function ABGP:BroadcastItemData(target)
    local payload = {
        itemDataTime = _G.ABGP_DataTimestamp,
        itemValues = {},
    };

    -- local defaultValues = self:BuildDefaultItemValues();
    for phase in pairs(ABGP.Phases) do
        payload.itemValues[phase] = _G.ABGP_Data[phase].itemValues;

        -- payload.itemValues[phase] = {};
        -- for i, item in ipairs( _G.ABGP_Data[phase].itemValues) do
        --     local copy = { unpack(item) };
        --     if defaultValues[copy[self.ItemDataIndex.NAME]] then
        --         copy[ABGP.ItemDataIndex.BOSS] = "";
        --     end
        --     table.insert(payload.itemValues[phase], copy);
        -- end
    end

    if target then
        self:SendComm(self.CommTypes.ITEM_DATA_SYNC, payload, "WHISPER", target);
    else
        self:SendComm(self.CommTypes.ITEM_DATA_SYNC, payload, "BROADCAST");
    end
end

function ABGP:CheckUpdatedItem(itemLink, value)
    if IsValueUpdated(value) then
        local found = false;
        local items = _G.ABGP_Data[value.phase].itemValues;
        for i, item in ipairs(items) do
            if item[ABGP.ItemDataIndex.NAME] == value.item then
                item[ABGP.ItemDataIndex.GP] = value.gp;
                item[ABGP.ItemDataIndex.BOSS] = value.boss;
                item[ABGP.ItemDataIndex.NOTES] = value.notes;
                item[ABGP.ItemDataIndex.PRIORITY] = value.priority;
                found = true;
                self:Notify("%s's EPGP data was updated!", itemLink);
                break;
            end
        end

        if not found then
            local oldValue = self:GetItemValue(value.item);
            if oldValue then
                local items = _G.ABGP_Data[oldValue.phase].itemValues;
                for i, item in ipairs(items) do
                    if item[ABGP.ItemDataIndex.NAME] == value.item then
                        table.remove(items, i);
                        self:Notify("%s's EPGP data was removed from %s!", itemLink, self.PhaseNamesAll[oldValue.phase]);
                        break;
                    end
                end
            end

            table.insert(items, {
                [ABGP.ItemDataIndex.NAME] = value.item,
                [ABGP.ItemDataIndex.GP] = value.gp,
                [ABGP.ItemDataIndex.ITEMLINK] = self:ShortenLink(itemLink),
                [ABGP.ItemDataIndex.BOSS] = value.boss,
                [ABGP.ItemDataIndex.PRIORITY] = value.priority,
                [ABGP.ItemDataIndex.NOTES] = value.notes,
            });
            self:Notify("%s's EPGP data has been added to %s!", itemLink, self.PhaseNamesAll[value.phase]);
        end

        self:RefreshItemValues();
    end
end

function ABGP:HasReceivedItem(itemName)
    local player = UnitName("player");
    local value = self:GetItemValue(itemName);
    if not value then return false; end

    for _, item in ipairs(_G.ABGP_Data[value.phase].gpHistory) do
        if item.item == itemName and item.player == player then
            return true;
        end
    end

    return false;
end

function ABGP:GetItemValue(itemName)
    if not itemName then return; end
    return itemValues[itemName];
end

function ABGP:GetItemName(itemLink)
    return itemLink:match("%[(.-)%]");
end

function ABGP:GetItemId(itemLink)
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
        if region and region:GetObjectType() == "FontString" then
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

    return true;
end

ABGP.ItemRanks = {
    HIGH = 3,
    NORMAL = 2,
    LOW = 1,
};

function ABGP:GetItemRank(itemLink)
    local rank = self.ItemRanks.NORMAL;
    if itemLink then
        local itemName = self:GetItemName(itemLink);
        if ABGP:IsItemFavorited(itemLink) then
            rank = self.ItemRanks.HIGH;
        elseif ABGP:HasReceivedItem(itemName) or not ABGP:IsItemUsable(itemLink) then
            rank = self.ItemRanks.LOW;
        elseif self:Get("usePreferredPriority") then
            local name = self:GetItemName(itemLink);
            local value = self:GetItemValue(name);
            if value then
                rank = self.ItemRanks.LOW;
                local preferred = self:Get("preferredPriorities");
                for _, pri in ipairs(value.priority) do
                    if preferred[pri] then
                        rank = self.ItemRanks.NORMAL;
                        break;
                    end
                end
            end
        end
    end

    return rank;
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
    MS_OS = "MS_OS",
    ROLL = "ROLL",
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
    for phase in pairs(self.Phases) do
        for _, pri in ipairs(self.Priorities[phase]) do
            activePlayers[pri.player] = activePlayers[pri.player] or {};
            activePlayers[pri.player][phase] = pri;
            activePlayers[pri.player].proxy = pri.proxy;
            activePlayers[pri.player].rank = pri.rank;
            activePlayers[pri.player].class = pri.class;
            activePlayers[pri.player].trial = pri.trial;
        end
    end

    self:SendMessage(self.InternalEvents.ACTIVE_PLAYERS_REFRESHED);
end

function ABGP:GetActivePlayer(name)
    return activePlayers[name];
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

local function OnHandleModifiedItemClick(itemLink)
    local _, fullLink = GetItemInfo(itemLink);
    if fullLink then
        for _, fn in ipairs(hmicFns) do
            if fn(fullLink) then return true; end
        end
    elseif ABGP.Debug then
        ABGP:Error("Failed GetItemInfo on %s!", itemLink);
    end
    return false;
end

local old_HandleModifiedItemClick = _G.HandleModifiedItemClick;
_G.HandleModifiedItemClick = function(itemLink)
    local ret = old_HandleModifiedItemClick(itemLink);
    return ret or OnHandleModifiedItemClick(itemLink);
end


--
-- Hook for CloseSpecialWindows to allow our UI windows to close on Escape.
--

local openWindows = {};
local function CloseABGPWindows()
    local found = false;
    for window in pairs(openWindows) do
        found = true;
        window:Hide();
    end
    return found;
end

local old_CloseSpecialWindows = _G.CloseSpecialWindows;
_G.CloseSpecialWindows = function()
    local found = old_CloseSpecialWindows();
    return CloseABGPWindows() or found;
end

function ABGP:OpenWindow(window)
    openWindows[window] = true;
end

function ABGP:CloseWindow(window)
    openWindows[window] = nil;
end


--
-- Support for maintaining window positions/sizes across reloads/relogs
--

_G.ABGP_WindowManagement = {};

function ABGP:BeginWindowManagement(window, name, defaults)
    _G.ABGP_WindowManagement[name] = _G.ABGP_WindowManagement[name] or {};
    local saved = _G.ABGP_WindowManagement[name];
    if saved.version ~= defaults.version then
        table.wipe(saved);
        saved.version = defaults.version;
    end

    local management = { name = name, defaults = defaults };
    window:SetUserData("windowManagement", management);

    saved.width = min(max(defaults.minWidth, saved.width or defaults.defaultWidth), defaults.maxWidth);
    saved.height = min(max(defaults.minHeight, saved.height or defaults.defaultHeight), defaults.maxHeight);
    window:SetStatusTable(saved);

    management.oldMinW, management.oldMinH = window.frame:GetMinResize();
    management.oldMaxW, management.oldMaxH = window.frame:GetMaxResize();
    window.frame:SetMinResize(defaults.minWidth, defaults.minHeight);
    window.frame:SetMaxResize(defaults.maxWidth, defaults.maxHeight);
end

function ABGP:EndWindowManagement(window)
    local management = window:GetUserData("windowManagement");
    local name = management.name;
    local defaults = management.defaults;
    _G.ABGP_WindowManagement[name] = _G.ABGP_WindowManagement[name] or {};
    local saved = _G.ABGP_WindowManagement[name];

    saved.left = window.frame:GetLeft();
    saved.top = window.frame:GetTop();
    saved.width = window.frame:GetWidth();
    saved.height = window.frame:GetHeight();
    window.frame:SetMinResize(management.oldMinW, management.oldMinH);
    window.frame:SetMaxResize(management.oldMaxW, management.oldMaxH);
end


--
-- Context Menu support
--

local contextFrame = CreateFrame("Frame", "ABGPContextMenu", UIParent, "UIDropDownMenuTemplate");
function ABGP:ShowContextMenu(context)
    EasyMenu(context, contextFrame, "cursor", 3, -3, "MENU");
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
    end
end
