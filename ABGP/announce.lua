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
local GetLootMethod = GetLootMethod;
local CreateFrame = CreateFrame;
local UnitGUID = UnitGUID;
local select = select;
local table = table;
local ipairs = ipairs;
local pairs = pairs;

local bossKills = {};
local lootAnnouncements = {};
local lastBoss;
local activeLootFrames = {};

local function ItemShouldBeAutoAnnounced(item)
    -- Announce rare+ BoP items
    return item.quality >= 3 and select(14, GetItemInfo(item.link)) == 1;
end

function ABGP:AnnounceOnLootOpened()
    if GetLootMethod() ~= "master" then return; end
    local loot = GetLootInfo();

    -- Determine the items that meet announcement criteria.
    local announceItems = {};
    for i = 1, GetNumLootItems() do
        local item = loot[i];
        if item then
            item.link = GetLootSlotLink(i);
            if ItemShouldBeAutoAnnounced(item) then
                table.insert(announceItems, item.link);
            end
        end
    end
    if #announceItems == 0 then return; end

    -- Determine the source of the loot. Use current target if it seems appropriate,
    -- otherwise use the last boss killed.
    local source, name = lastBoss, lastBoss;
    if UnitExists("target") and not UnitIsFriend('player', 'target') and UnitIsDead('target') then
        source, name = UnitGUID("target"), UnitName("target");
    end
    if not source then return; end

    -- Only use the target GUID as the source if it's not a boss kill.
    if bossKills[name] then source = name; end

    -- Loot from boss kills should always be announced.
    -- If not from a boss, check if any of the items have an item value.
    local shouldAnnounce = bossKills[name];
    if not shouldAnnounce then
        for _, itemLink in ipairs(announceItems) do
            if self:GetItemValue(self:GetItemName(itemLink)) then
                shouldAnnounce = true;
                break;
            end
        end
    end
    if not shouldAnnounce then return; end

    -- Only announce once per source.
    lootAnnouncements[source] = lootAnnouncements[source] or { name = name, announced = false };
    if lootAnnouncements[source].announced then return; end

    local data = { source = source, name = name, items = announceItems };
    self:SendComm(self.CommTypes.BOSS_LOOT, data, "BROADCAST");
    self:AnnounceOnBossLoot(data);
end

function ABGP:AnnounceOnBossLoot(data)
    local source = data.source;
    local name = data.name or source;
    lootAnnouncements[source] = lootAnnouncements[source] or { name = name, announced = false };

    if not lootAnnouncements[source].announced then
        lootAnnouncements[source].announced = true;

        self:Notify("Loot from %s:", self:ColorizeText(name));
        for _, itemLink in ipairs(data.items) do
            self:Notify(itemLink);
            self:ShowLootFrame(itemLink);
        end
    end
end

function ABGP:AnnounceOnBossKilled(id, name)
    bossKills[name] = true;
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
    if not self:Get("showLootFrames") then return; end
    local elt = AceGUI:Create("ABGP_LootFrame");
    elt:SetItem(itemLink);
    elt:SetDuration(self:Get("lootDuration"));

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
            if #context > 0 then
                table.insert(context, { text = "Cancel", notCheckable = true });
                ABGP:ShowContextMenu(context);
            end
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
        AceGUI:Release(widget);
    end);
end

function ABGP:ShowTestLoot()
    self:ShowLootFrame("|cffff8000|Hitem:19019|h[Thunderfury, Blessed Blade of the Windseeker]|h|r");
    self:ShowLootFrame("|cffa335ee|Hitem:19375::::::::60:::::|h[Mish'undare, Circlet of the Mind Flayer]|h|r");
    self:ShowLootFrame("|cffa335ee|Hitem:19406::::::::60:::::|h[Drake Fang Talisman]|h|r");
    self:ShowLootFrame("|cff0070dd|Hitem:18259::::::::60:::::|h[Formula: Enchant Weapon - Spell Power]|h|r");
end
