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
        ABGP:RegisterChatCommand("abgp", function() if ABGP.ShowWindow then ABGP:ShowWindow(); end end);
    end

    self:CheckForDataUpdates();
    self:RefreshActivePlayers();
    self:RefreshItemValues();
end

function ABGP:IsPrivileged()
    -- Check officer status by looking for the privilege to edit the officer note.
    local isOfficer = C_GuildInfo.GuildControlGetRankFlags(C_GuildInfo.GetGuildRankOrder(UnitGUID("player")))[12];
    return isOfficer or ABGP.Debug;
end

function ABGP:Notify(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cFFCC0000ABGP|R: " .. msg);
end


local itemValues = {};

function ABGP:RefreshItemValues()
    itemValues = {};
    for _, item in pairs(ABGP_ItemValues) do
        itemValues[item.item] = item;
    end
end

function ABGP:GetItemValue(itemName)
    if not itemName then return; end
    return itemValues[itemName];
end


local activePlayers = {};

function ABGP:RefreshActivePlayers()
    activePlayers = {};
    for _, pri in pairs(ABGP_Priority) do
        activePlayers[pri.character] = true;
    end
end

function ABGP:IsActivePlayer(name)
    return activePlayers[name];
end


function ABGP:CheckForDataUpdates()
    if ABGP_DataTimestamp == nil or ABGP_DataTimestamp < ABGP.InitialData.timestamp then
        ABGP_DataTimestamp = ABGP.InitialData.timestamp;
        ABGP_Priority = ABGP.InitialData.ABGP_Priority;
        ABGP_EP = ABGP.InitialData.ABGP_EP;
        ABGP_GP = ABGP.InitialData.ABGP_GP;
        ABGP_ItemValues = ABGP.InitialData.ABGP_ItemValues;

        local d = date("%I:%M%p, %m/%d/%y", ABGP_DataTimestamp); -- https://strftime.org/
        ABGP:Notify(string.format("Loaded new data! (updated %s)", d));
    end
end


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