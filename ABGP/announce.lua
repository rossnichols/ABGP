local _G = _G;
local ABGP = ABGP;
local AceGUI = _G.LibStub("AceGUI-3.0");

local UnitName = UnitName;
local GetItemInfo = GetItemInfo;
local GetLootInfo = GetLootInfo;
local GetNumLootItems = GetNumLootItems;
local GetLootSlotLink = GetLootSlotLink;
local UnitExists = UnitExists;
local UnitIsFriend = UnitIsFriend;
local UnitIsDead = UnitIsDead;
local GetServerTime = GetServerTime;
local GetLootMethod = GetLootMethod;
local CreateFrame = CreateFrame;
local select = select;
local table = table;
local ipairs = ipairs;
local pairs = pairs;

local bossKills = {};
local lastBoss;
local activeLootFrames = {};

local function ItemShouldBeAutoAnnounced(item)
    -- Announce rare+ BoP items
    return item.quality >= 3 and select(14, GetItemInfo(item.link)) == 1;
end

function ABGP:AnnounceOnLootOpened()
    if GetLootMethod() ~= "master" then return; end
    local loot = GetLootInfo();
    local announce = false;

    -- Check for an item that will trigger auto-announce.
    for i = 1, GetNumLootItems() do
        local item = loot[i];
        if item then
            item.link = GetLootSlotLink(i);
            if ItemShouldBeAutoAnnounced(item) then
                announce = true;
            end
        end
    end
    if not announce then return; end

    -- Determine the source of the loot. Use current target if it seems appropriate,
    -- otherwise use the last boss killed.
    local source = lastBoss;
    if UnitExists("target") and not UnitIsFriend('player', 'target') and UnitIsDead('target') then
        source = UnitName("target");
    end

    -- Limit auto-announce to boss kills, and only announce once per boss.
    if source and bossKills[source] and not bossKills[source].announced then
        -- Send messages for each item that meets announcement criteria.
        local announceItems = {};
        for i = 1, GetNumLootItems() do
            local item = loot[i];
            if item and ItemShouldBeAutoAnnounced(item) then
                table.insert(announceItems, GetLootSlotLink(i));
            end
        end

        local data = { source = source, items = announceItems };
        self:SendComm(self.CommTypes.BOSS_LOOT, data, "BROADCAST");
        self:AnnounceOnBossLoot(data);
    end
end

function ABGP:AnnounceOnBossLoot(data)
    if bossKills[data.source] and not bossKills[data.source].announced then
        bossKills[data.source].announced = true;

        self:Notify("Loot from %s:", self:ColorizeText(data.source));
        for _, itemLink in ipairs(data.items) do
            self:Notify(itemLink);
            self:ShowLootFrame(itemLink);
        end
    end
end

function ABGP:AnnounceOnBossKilled(id, name)
    bossKills[name] = { time = GetServerTime(), announced = false };
    lastBoss = name;
end

function ABGP:AnnounceOnZoneChanged()
    lastBoss = nil;
end

local function GetLootAnchor()
    return ABGP:Get("lootDirection") == "up" and _G.ABGPLootAnchorUp or _G.ABGPLootAnchorDown;
end

local function PositionLootFrame(elt)
    local index = activeLootFrames[elt];
    local direction = ABGP:Get("lootDirection");

    elt.frame:ClearAllPoints();
    if direction == "up" then
        elt.frame:SetPoint("BOTTOM", GetLootAnchor(), "BOTTOM", 0, (index - 1) * (elt.frame:GetHeight() + 10));
    else
        elt.frame:SetPoint("TOP", GetLootAnchor(), "TOP", 0, -1 * (index - 1) * (elt.frame:GetHeight() + 10));
    end
end

function ABGP:RefreshLootFrames()
    local i = 1;
    while activeLootFrames[i] do
        PositionLootFrame(activeLootFrames[i]);
        i = i + 1;
    end
end

function ABGP:ShowLootFrame(itemLink)
    local elt = AceGUI:Create("ABGP_LootFrame");
    elt:SetItem(itemLink);
    elt:SetDuration(15);

    -- Determine the first free slot for the frame.
    local i = 1;
    while activeLootFrames[i] do i = i + 1; end
    activeLootFrames[i] = elt;
    activeLootFrames[elt] = i;
    PositionLootFrame(elt);

    elt:SetCallback("OnClick", function(widget, event, button)
        if button == "RightButton" then
            local itemLink = widget:GetItem();
            local itemName = ABGP:GetItemName(itemLink);
            local value = ABGP:GetItemValue(itemName);

            local context = {};
            if ABGP:CanFavoriteItems() then
                local faved = ABGP:IsItemFavorited(itemLink);
                table.insert(context, {
                    text = faved and "Remove favorite" or "Add favorite",
                    func = function(self)
                        ABGP:SetItemFavorited(itemLink, not faved);
                        widget:SetItem(widget:GetItem());
                    end,
                    notCheckable = true
                });
            end
            if value then
                table.insert(context, {
                    text = "Show item history",
                    func = function(self)
                        ABGP:ShowMainWindow({ command = ABGP.UICommands.ShowItemHistory, args = itemName, phase = value.phase })
                    end,
                    notCheckable = true
                });
            end
            table.insert(context, { text = "Cancel", notCheckable = true });
            ABGP:ShowContextMenu(context);
        end
    end);
    elt:SetCallback("OnMouseDown", function(widget)
        GetLootAnchor():StartMoving();
    end);
    elt:SetCallback("OnMouseUp", function(widget)
        GetLootAnchor():StopMovingOrSizing();
    end);
    elt:SetCallback("OnHide", function(widget)
        -- Free up the slot, preserving the indices of other frames.
        activeLootFrames[activeLootFrames[widget]] = nil;
        activeLootFrames[widget] = nil;
    end);
end
