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
local C_GuildInfo = C_GuildInfo;
local select = select;
local pairs = pairs;
local ipairs = ipairs;
local tonumber = tonumber;
local table = table;
local tostring = tostring;
local min = min;
local max = max;

_G.BINDING_HEADER_ABGP = "ABGP";
_G.BINDING_NAME_ABGP_SHOWITEMREQUESTS = "Show item request window";

local function OnGroupJoined()
    ABGP:VersionOnGroupJoined();
    ABGP:RequestOnGroupJoined();
    ABGP:OutsiderOnGroupJoined();
end

function ABGP:OnInitialize()
    self:RegisterComm("ABGP");
    self:InitOptions();
    self:HookTooltips();
    self:AddItemHooks();
    self:CheckHardcodedData();
    self:RefreshItemValues();
    self:TrimAuditLog(30 * 24 * 60 * 60); -- 30 days

    -- Trigger a guild roster update to refresh priorities.
    GuildRoster();

    self:RegisterMessage(self.CommTypes.ITEM_REQUEST, function(self, event, data, distribution, sender)
        self:DistribOnItemRequest(data, distribution, sender);
    end, self);

    self:RegisterMessage(self.CommTypes.ITEM_PASS, function(self, event, data, distribution, sender)
        self:DistribOnItemPass(data, distribution, sender);
    end, self);

    self:RegisterMessage(self.CommTypes.ITEM_DISTRIBUTION_OPENED, function(self, event, data, distribution, sender)
        self:RequestOnDistOpened(data, distribution, sender);
        self:DistribOnDistOpened(data, distribution, sender);
    end, self);

    self:RegisterMessage(self.CommTypes.ITEM_DISTRIBUTION_CLOSED, function(self, event, data, distribution, sender)
        self:RequestOnDistClosed(data, distribution, sender);
    end, self);

    self:RegisterMessage(self.CommTypes.ITEM_DISTRIBUTION_AWARDED, function(self, event, data, distribution, sender)
        self:RequestOnItemAwarded(data, distribution, sender);
        self:PriorityOnItemAwarded(data, distribution, sender);
        self:HistoryOnItemAwarded(data, distribution, sender);
    end, self);

    self:RegisterMessage(self.CommTypes.ITEM_DISTRIBUTION_TRASHED, function(self, event, data, distribution, sender)
        self:RequestOnItemTrashed(data, distribution, sender);
    end, self);

    self:RegisterMessage(self.CommTypes.ITEM_DISTRIBUTION_CHECK, function(self, event, data, distribution, sender)
        self:DistribOnCheck(data, distribution, sender);
    end, self);

    self:RegisterMessage(self.CommTypes.ITEM_DISTRIBUTION_CHECK_RESPONSE, function(self, event, data, distribution, sender)
        self:RequestOnCheckResponse(data, distribution, sender);
    end, self);

    self:RegisterMessage(self.CommTypes.VERSION_REQUEST, function(self, event, data, distribution, sender)
        self:OnVersionRequest(data, distribution, sender);
    end, self);

    self:RegisterMessage(self.CommTypes.VERSION_RESPONSE, function(self, event, data, distribution, sender)
        self:OnVersionResponse(data, distribution, sender);
    end, self);

    self:RegisterMessage(self.CommTypes.OFFICER_NOTES_UPDATED, function(self, event, data, distribution, sender)
        GuildRoster();
    end, self);

    self:RegisterMessage(self.CommTypes.ITEM_ROLLED, function(self, event, data, distribution, sender)
        self:RequestOnItemRolled(data, distribution, sender);
    end, self);

    self:RegisterMessage(self.CommTypes.REQUEST_PRIORITY_SYNC, function(self, event, data, distribution, sender)
        self:OnPrioritySyncRequested(data, distribution, sender);
    end, self);

    self:RegisterMessage(self.CommTypes.PRIORITY_SYNC, function(self, event, data, distribution, sender)
        self:OnPrioritySync(data, distribution, sender);
    end, self);

    self:RegisterMessage(self.CommTypes.BOSS_LOOT, function(self, event, data, distribution, sender)
        self:AnnounceOnBossLoot(data, distribution, sender);
    end, self);

    self:RegisterMessage(self.InternalEvents.ACTIVE_PLAYERS_REFRESHED, function(self)
        self:DistribOnActivePlayersRefreshed();
        self:RefreshUI(self.RefreshReasons.ACTIVE_PLAYERS_REFRESHED);
    end, self);

    -- Precreate frames to avoid issues generating them during combat.
    if not UnitAffectingCombat("player") then
        AceGUI:Release(self:CreateMainWindow());
        AceGUI:Release(self:CreateDistribWindow());
        AceGUI:Release(self:CreateRequestWindow());
        for i = 1, 10 do AceGUI:Release(AceGUI:Create("ABGP_Item")); end
        for i = 1, 50 do AceGUI:Release(AceGUI:Create("ABGP_Player")); end
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
    if self.Debug then
        self:Notify("|cffff0000ERROR:|r " .. str, ...);
    end
end

function ABGP:ColorizeText(text)
    return ("%s%s|r"):format(ABGP.Color, text);
end

function ABGP:ColorizeName(name, class)
    if not class then
        if UnitExists(name) then
            local _, className = UnitClass(name);
            class = className;
        end
    end
    if not class then
        local epgp = self:GetActivePlayer(name);
        if epgp then
            class = epgp.class;
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
    return isOfficer or ABGP.Debug;
end

function ABGP:CanEditOfficerNotes()
    return C_GuildInfo.GuildControlGetRankFlags(C_GuildInfo.GetGuildRankOrder(UnitGUID("player")))[12];
end


--
-- Helpers for content phases
--

ABGP.Phases = {
    p1 = "p1",
    p3 = "p3",
};
ABGP.Priorities = {};
for phase in pairs(ABGP.Phases) do
    ABGP.Priorities[phase] = {};
end
ABGP.CurrentPhase = ABGP.Phases.p3;


--
-- Helpers for item queries
--

local itemValues = {};

function ABGP:RefreshItemValues()
    itemValues = {};
    for phase in pairs(self.Phases) do
        for _, item in ipairs(_G.ABGP_Data[phase].itemValues) do
            local name = item.item or item[1];
            local gp = item.gp or item[2];
            itemValues[name] = {
                gp = gp,
                item = name,
                priority = item.priority,
                notes = item.notes,
                phase = phase
            };

            -- Try to ensure info about the item is cached locally.
            if item[3] then
                self:IsItemUsable(item[3]);
            end
        end
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
    return itemLink:gsub("|H(item:%d+).-|h", "|H%1|h");
end

local scanner = CreateFrame("GameTooltip", "ABGPScanningTooltip", nil, "GameTooltipTemplate");
scanner:SetOwner(UIParent, "ANCHOR_NONE");
function ABGP:IsItemUsable(itemLink)
    scanner:ClearLines();
    scanner:SetHyperlink(itemLink);
    for i = 1, select("#", scanner:GetRegions()) do
        local region = select(i, scanner:GetRegions());
        if region and region:GetObjectType() == "FontString" and region:GetText() then
            if region:GetText() == "Retrieving item information" then
                -- No info available: assume usable.
                return true;
            end
            local r, g, b = region:GetTextColor();
            if r >= .9 and g <= .2 and b <= .2 then
                -- self:LogVerbose("%s is not usable: %s %.2f %.2f %.2f", itemLink, region:GetText(), r, g, b);
                return false;
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


--
-- Helpers for item requests
--

ABGP.RequestTypes = {
    MS_OS = "MS_OS",
    ROLL = "ROLL",
    MS = "MS",
    OS = "OS"
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
        end
    end

    self:SendMessage(self.InternalEvents.ACTIVE_PLAYERS_REFRESHED);
end

function ABGP:GetActivePlayer(name)
    return activePlayers[name];
end

function ABGP:OnPrioritySyncRequested(data, distribution, sender)
    self:SendComm(ABGP.CommTypes.PRIORITY_SYNC, {
        commPriority = "BULK",
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
-- Support for other events delivered to components.
--

local rollRegex = RANDOM_ROLL_RESULT:gsub("([()-])", "%%%1");
rollRegex = rollRegex:gsub("%%s", "(%%S+)");
rollRegex = rollRegex:gsub("%%d", "(%%d+)");
local lastZone;

local f = CreateFrame("Frame");
f:RegisterEvent("GUILD_ROSTER_UPDATE");
f:RegisterEvent("CHAT_MSG_SYSTEM");
f:RegisterEvent("GROUP_JOINED");
f:RegisterEvent("GROUP_LEFT");
f:RegisterEvent("GROUP_ROSTER_UPDATE");
f:RegisterEvent("PLAYER_LEAVING_WORLD");
f:RegisterEvent("LOADING_SCREEN_ENABLED");
f:RegisterEvent("PLAYER_LOGOUT");
f:RegisterEvent("BOSS_KILL");
f:RegisterEvent("LOADING_SCREEN_DISABLED");
f:RegisterEvent("LOOT_OPENED");
f:SetScript("OnEvent", function(self, event, ...)
    if event == "GUILD_ROSTER_UPDATE" then
        ABGP:RebuildGuildInfo();
        ABGP:VersionOnGuildRosterUpdate();
        ABGP:PriorityOnGuildRosterUpdate();
    elseif event == "CHAT_MSG_SYSTEM" then
        local text = ...;
        local sender, roll, minRoll, maxRoll = text:match(rollRegex);
        if minRoll == "1" and maxRoll == "100" and sender and UnitExists(sender) then
            roll = tonumber(roll);
            ABGP:DistribOnRoll(sender, roll);
        end
    elseif event == "GROUP_JOINED" then
        OnGroupJoined();
    elseif event == "GROUP_LEFT" then
        ABGP:RequestOnGroupLeft();
    elseif event == "GROUP_ROSTER_UPDATE" then
        ABGP:RequestOnGroupUpdate();
    elseif event == "PLAYER_LEAVING_WORLD" then
        ABGP:DistribOnLeavingWorld();
    elseif event == "LOADING_SCREEN_ENABLED" then
        ABGP:DistribOnLoadingScreen();
    elseif event == "PLAYER_LOGOUT" then
        ABGP:DistribOnLogout();
    elseif event == "BOSS_KILL" then
        ABGP:EventOnBossKilled(...);
        ABGP:AnnounceOnBossKilled(...);
    elseif event == "LOADING_SCREEN_DISABLED" then
        -- Per DBM, GetInstanceInfo() can return stale data for a period of time
        -- after this event is triggered. Workaround: wait a short period of time. Amazing.
        -- Schedule two timers so we opportunistically process it quicker, with the
        -- second one to ensure we end up in the right final state.
        local onZoneChanged = function()
            local name, _, _, _, _, _, _, instanceId = GetInstanceInfo();
            if name and name ~= lastZone then
                lastZone = name;
                ABGP:EventOnZoneChanged(name, instanceId);
                ABGP:AnnounceOnZoneChanged(name, instanceId);
            end
        end
        ABGP:ScheduleTimer(onZoneChanged, 1);
        ABGP:ScheduleTimer(onZoneChanged, 5);
    elseif event == "LOOT_OPENED" then
        ABGP:AnnounceOnLootOpened();
    end
end);


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

function ABGP:HideContextMenu()
    if _G.UIDROPDOWNMENU_OPEN_MENU == contextFrame then
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
