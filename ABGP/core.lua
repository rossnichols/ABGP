local _G = _G;
_G.ABGP = _G.LibStub("AceAddon-3.0"):NewAddon("ABGP", "AceConsole-3.0", "AceComm-3.0", "AceEvent-3.0", "AceTimer-3.0");
local ABGP = ABGP;

local UnitExists = UnitExists;
local UnitClass = UnitClass;
local UnitGUID = UnitGUID;
local GetClassColor = GetClassColor;
local GuildRoster = GuildRoster;
local C_GuildInfo = C_GuildInfo;
local select = select;
local pairs = pairs;
local ipairs = ipairs;
local tonumber = tonumber;
local table = table;
local tostring = tostring;

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
    AceConfig:RegisterOptionsTable(ABGP:ColorizeText(addonText), {
        type = "group",
        args = {
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
                desc = "checks the raid for an outdated or missing addon versions",
                type = "execute",
                cmdHidden = not ABGP:IsPrivileged(),
                validate = function() if not ABGP:IsPrivileged() then return "|cffff0000not privileged|r"; end end,
                func = function() ABGP:PerformVersionCheck(); end
            },
            priority = {
                name = "Priority",
                desc = "shows the player priority window",
                type = "execute",
                func = function() ABGP:ShowPriority(); end
            },
        },
    }, { "abgp" });

    self:HookTooltips();
    self:AddItemHooks();
    self:CheckForDataUpdates();
    self:RefreshActivePlayers();
    self:RefreshItemValues();
    self:InitVersionCheck();

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
        self:RequestOnDistAwarded(data, distribution, sender);
        self:PriorityOnDistAwarded(data, distribution, sender);
    end, self);

    self:RegisterMessage(self.CommTypes.ITEM_DISTRIBUTION_TRASHED, function(self, event, data, distribution, sender)
        self:RequestOnDistTrashed(data, distribution, sender);
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
end

ABGP.Color = "|cFF94E4FF";
ABGP.ColorTable = { 0.58, 0.89, 1, r = 0.58, g = 0.89, b = 1 };
function ABGP:Notify(str, ...)
    _G.DEFAULT_CHAT_FRAME:AddMessage(self:ColorizeText("ABGP") .. ": " .. tostring(str):format(...));
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


--
-- Content phase tracking support
--

ABGP.Phases = {
    p1 = "p1",
    p3 = "p3",
};
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
        for _, pri in ipairs(_G.ABGP_Data[phase].priority) do
            activePlayers[pri.player] = activePlayers[pri.player] or {};
            activePlayers[pri.player][phase] = pri;
        end
    end
end

function ABGP:GetActivePlayer(name)
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
    for _, fn in ipairs(hmicFns) do
        if fn(itemLink) then return true; end
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

local f = CreateFrame("Frame");
f:RegisterEvent("GUILD_ROSTER_UPDATE");
f:SetScript("OnEvent", function(self, event)
    ABGP:VersionOnGuildRosterUpdate();
    ABGP:PriorityOnGuildRosterUpdate();
end);
