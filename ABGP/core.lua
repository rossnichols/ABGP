ABGP = LibStub("AceAddon-3.0"):NewAddon("ABGP", "AceConsole-3.0");

function ABGP:OnInitialize()
    self:HookTooltips();
    self:AddAnnounceHooks();

    if self.Debug then
        -- local AceConfig = LibStub("AceConfig-3.0")
        -- AceConfig:RegisterOptionsTable("ABGP", {
        --     type = "group",
        --     args = {
        --         show = {
        --             name = "Show",
        --             desc = "shows the window",
        --             type = "execute",
        --             func = function() ABGP:ShowWindow() end
        --         },
        --     },
        -- }, { "abp" });
        ABGP:RegisterChatCommand("abgp", function() ABGP:ShowWindow(); end);
    end

    self:CheckForDataUpdates();
    self:RefreshActivePlayers();
    self:RefreshItemValues();
end

ABGP.Color = "|cFF94E4FF";
ABGP.ColorTable = { 0.58, 0.89, 1 };
function ABGP:Notify(str, ...)
    DEFAULT_CHAT_FRAME:AddMessage(ABGP.Color .. "ABGP|r: " .. string.format(str, ...));
end

function ABGP:LogVerbose(str, ...)
    if self.Verbose then
        self:Notify(str, ...);
    end
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
    p1 = "Phase 1/2",
    p3 = "Phase 3",
};
ABGP.CurrentPhase = "p1";


--
-- Converts the item value arrays to a table with name-based lookup.
--

local itemValues = {};

function ABGP:RefreshItemValues()
    itemValues = {};
    for phase in pairs(self.Phases) do
        for _, item in ipairs(ABGP_Data[phase].itemValues) do
            local name = item.item or item[1];
            local gp = item.gp or item[2];
            itemValues[name] = {
                gp = gp,
                item = name,
                priority = item.priority,
                notes = item.notes
            };
        end
    end
end

function ABGP:GetItemValue(itemName)
    if not itemName then return; end
    return itemValues[itemName];
end


--
-- An "active player" is one with an assigned priority value on the ABP spreadsheet.
-- Importing EP/GP history is scoped to just active players to cut down on useless data.
--

local activePlayers = {};

function ABGP:RefreshActivePlayers()
    activePlayers = {};
    for phase in pairs(self.Phases) do
        for _, pri in ipairs(ABGP_Data[phase].priority) do
            activePlayers[pri.character] = true;
        end
    end
end

function ABGP:IsActivePlayer(name)
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

local old_HandleModifiedItemClick = HandleModifiedItemClick;
HandleModifiedItemClick = function(itemLink)
    local ret = old_HandleModifiedItemClick(itemLink);
    return ret or OnHandleModifiedItemClick(itemLink);
end
