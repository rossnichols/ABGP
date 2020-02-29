local _G = _G;
_G.ABGP = _G.LibStub("AceAddon-3.0"):NewAddon("ABGP", "AceConsole-3.0", "AceComm-3.0", "AceEvent-3.0", "AceTimer-3.0");
local ABGP = ABGP;
local AceGUI = _G.LibStub("AceGUI-3.0");

local UnitExists = UnitExists;
local UnitClass = UnitClass;
local UnitGUID = UnitGUID;
local GetClassColor = GetClassColor;
local GuildRoster = GuildRoster;
local GetChatWindowInfo = GetChatWindowInfo;
local UnitAffectingCombat = UnitAffectingCombat;
local EasyMenu = EasyMenu;
local ToggleDropDownMenu = ToggleDropDownMenu;
local CreateFrame = CreateFrame;
local GetItemInfo = GetItemInfo;
local IsInGroup = IsInGroup;
local GetNumGuildMembers = GetNumGuildMembers;
local GetGuildRosterInfo = GetGuildRosterInfo;
local Ambiguate = Ambiguate;
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

function ABGP:OnInitialize()
    self:RegisterComm("ABGP");
    local AceConfig = _G.LibStub("AceConfig-3.0");
    local addonText = "ABGP";
    local version = self:GetVersion();
    if self:ParseVersion(version) then
        addonText = "ABGP-v" .. version;
    end
    local options = {
        show = {
            name = "Show",
            desc = "shows the main window",
            type = "execute",
            func = function() ABGP:ShowMainWindow(); end
        },
        loot = {
            name = "Loot",
            desc = "shows the item request window",
            type = "execute",
            func = function() ABGP:ShowItemRequests(); end
        },
        import = {
            name = "Data Import",
            desc = "shows the import window",
            type = "execute",
            cmdHidden = true,
            validate = function() if not ABGP:IsPrivileged() then return "|cffff0000not privileged|r"; end end,
            func = function() ABGP:ShowImportWindow(); end
        },
        versioncheck = {
            name = "Version Check",
            desc = "checks the raid for an outdated or missing addon versions (alias: vc)",
            type = "execute",
            cmdHidden = not ABGP:IsPrivileged(),
            validate = function() if not ABGP:IsPrivileged() then return "|cffff0000not privileged|r"; end end,
            func = function() ABGP:PerformVersionCheck(); end
        },
    };
    options.vc = { hidden = true };
    for k, v in pairs(options.versioncheck) do options.vc[k] = v; end
    options.vc.cmdHidden = nil;

    AceConfig:RegisterOptionsTable(ABGP:ColorizeText(addonText), {
        type = "group",
        args = options,
    }, { "abgp" });

    local defaults = {

    };
    self.db = _G.LibStub("AceDB-3.0"):New("ABGP_DB", defaults);

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

    self:RegisterMessage(self.InternalEvents.ACTIVE_PLAYERS_REFRESHED, function(self)
        self:DistribOnActivePlayersRefreshed();
        self:RefreshUI();
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
        self:SendComm(self.CommTypes.ITEM_DISTRIBUTION_CHECK, {}, "BROADCAST");
    end
end

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
-- Checks for privilege to access certain features locked to guild officers.
--

function ABGP:IsPrivileged()
    -- Check officer status by looking for the privilege to speak in officer chat.
    local isOfficer = C_GuildInfo.GuildControlGetRankFlags(C_GuildInfo.GetGuildRankOrder(UnitGUID("player")))[4];
    return isOfficer or ABGP.Debug;
end

function ABGP:CanEditOfficerNotes()
    return C_GuildInfo.GuildControlGetRankFlags(C_GuildInfo.GetGuildRankOrder(UnitGUID("player")))[12];
end

local guildInfo = {};

function ABGP:RebuildGuildInfo()
    table.wipe(guildInfo);
    for i = 1, GetNumGuildMembers() do
        local data = { GetGuildRosterInfo(i) };
        data.player = Ambiguate(data[1], "short");
        data.index = i;
        guildInfo[data.player] = data;
    end
end

function ABGP:GetGuildInfo(player)
    return guildInfo[player];
end

function ABGP:IsTrial(rank)
    return (rank == "Trial");
end


--
-- Content phase tracking support
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
-- Converts the item value arrays to a table with name-based lookup.
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
        end
    end
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

ABGP.RequestTypes = {
    MS_OS = "MS_OS",
    ROLL = "ROLL",
    MS = "MS",
    OS = "OS"
};


--
-- An "active player" is one with an assigned priority value on the ABP spreadsheet.
-- Importing EP/GP history is scoped to just active players to cut down on useless data.
--

local activePlayers = {};

function ABGP:RefreshActivePlayers()
    activePlayers = {};
    for phase in pairs(self.Phases) do
        for _, pri in ipairs(self.Priorities[phase]) do
            activePlayers[pri.player] = activePlayers[pri.player] or {};
            activePlayers[pri.player][phase] = pri;
            activePlayers[pri.player].player = pri.player;
        end
    end

    self:SendMessage(self.InternalEvents.ACTIVE_PLAYERS_REFRESHED);
end

function ABGP:GetActivePlayer(name, ignoreAlts)
    if not activePlayers[name] and not ignoreAlts then
        local guildInfo = self:GetGuildInfo(name);
        if guildInfo and activePlayers[guildInfo[8]] then
            return activePlayers[guildInfo[8]], true;
        end
    end
    return activePlayers[name];
end


--
-- Override of HandleModifiedItemClick. This seems to be the easiest way to extend
-- [mod]+clicking on items in a way that works across different AddOns and doesn't
-- get in the way when trying to do something else with the action (e.g. insert
-- link into chat, view model, etc.).
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

hooksecurefunc("ReloadUI", function()
    ABGP:DistribOnReloadUI();
end);

local rollRegex = RANDOM_ROLL_RESULT:gsub("([()-])", "%%%1");
rollRegex = rollRegex:gsub("%%s", "(%%S+)");
rollRegex = rollRegex:gsub("%%d", "(%%d+)");

local f = CreateFrame("Frame");
f:RegisterEvent("GUILD_ROSTER_UPDATE");
f:RegisterEvent("CHAT_MSG_SYSTEM");
f:RegisterEvent("GROUP_JOINED");
f:RegisterEvent("GROUP_LEFT");
f:RegisterEvent("GROUP_ROSTER_UPDATE");
f:RegisterEvent("PLAYER_LEAVING_WORLD");
f:RegisterEvent("LOADING_SCREEN_ENABLED");
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
        ABGP:VersionOnGroupJoined();
        ABGP:RequestOnGroupJoined();
    elseif event == "GROUP_LEFT" then
        ABGP:RequestOnGroupLeft();
    elseif event == "GROUP_ROSTER_UPDATE" then
        ABGP:RequestOnGroupUpdate();
    elseif event == "PLAYER_LEAVING_WORLD" then
        ABGP:DistribOnLeavingWorld();
    elseif event == "LOADING_SCREEN_ENABLED" then
        ABGP:DistribOnLoadingScreen();
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
