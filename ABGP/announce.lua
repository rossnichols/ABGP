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
local UnitGUID = UnitGUID;
local select = select;
local table = table;
local ipairs = ipairs;
local pairs = pairs;
local type = type;

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
        elt.frame:SetPoint("BOTTOM", GetLootAnchor(), "BOTTOM", 0, (index - 1) * (elt.frame:GetHeight() + 4));
    else
        elt.frame:SetPoint("TOP", GetLootAnchor(), "TOP", 0, -1 * (index - 1) * (elt.frame:GetHeight() + 4));
    end
end

local function GetLootFrame(itemLink)
    for _, elt in pairs(activeLootFrames) do
        if type(elt) == "table" and elt:GetItem() == itemLink and not elt:GetUserData("blockReuse") then
            return elt;
        end
    end
end

function ABGP:ShowLootFrame(itemLink)
    if not self:Get("showLootFrames") then return; end

    local _, fullLink = GetItemInfo(itemLink);
    itemLink = fullLink or itemLink;

    local elt = GetLootFrame(itemLink);
    if elt then
        elt:SetCount(elt:GetCount() + 1);
        elt:SetDuration(self:Get("lootDuration"));
        return elt;
    end

    elt = AceGUI:Create("ABGP_LootFrame");
    elt:SetItem(itemLink);
    elt:SetDuration(self:Get("lootDuration"));

    local reason;
    if self:Get("lootIntegration") then
        reason = "Item not open for distribution.";
    end
    elt:EnableRequests(false, reason);

    local itemName = ABGP:GetItemName(itemLink);
    local value = ABGP:GetItemValue(itemName);
    local valueText = (value and value.gp ~= 0) and ("GP cost: %s"):format(self:ColorizeText(value.gp)) or "No GP Cost";
    local valueTextCompact = (value and value.gp ~= 0) and value.gp or "--";
    elt:SetSecondaryText(valueText, valueTextCompact);

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
                        ABGP:ShowMainWindow({ command = ABGP.UICommands.ShowItemHistory, args = itemName, phase = value.phase });
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
    elt:SetCallback("OnRequest", function(widget)
        local itemLink = widget:GetItem();
        ABGP:ShowRequestPopup(itemLink);
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

    return elt;
end

function ABGP:AnnounceOnDistOpened(data, distribution, sender)
    if not self:Get("lootIntegration") then return; end
    local elt = GetLootFrame(data.itemLink) or self:ShowLootFrame(data.itemLink);
    if not elt then return; end

    elt:EnableRequests(true);
    elt:SetDuration(nil);
end

function ABGP:AnnounceOnDistClosed(data, distribution, sender)
    if not self:Get("lootIntegration") then return; end
    local elt = GetLootFrame(data.itemLink);
    if not elt then return; end

    elt:EnableRequests(false);
    elt:SetDuration(5);
    elt:SetUserData("blockReuse", true);

    local awards = elt:GetUserData("awards");
    if awards then
        elt:SetSecondaryText(("Awarded to %s"):format(table.concat(awards, ", ")));
    elseif elt:GetUserData("trashed") then
        elt:SetSecondaryText(self:ColorizeText("Disenchanted"));
    else
        elt:SetSecondaryText("Distribution closed");
    end
end

function ABGP:AnnounceOnItemAwarded(data, distribution, sender)
    if not self:Get("lootIntegration") then return; end
    local elt = GetLootFrame(data.itemLink);
    if not elt then return; end

    elt:SetUserData("awards", elt:GetUserData("awards") or {});

    local requestTypes = {
        [self.RequestTypes.MS] = "ms",
        [self.RequestTypes.OS] = "os",
    };
    local extra;
    if requestTypes[data.requestType] then
        extra = requestTypes[data.requestType];
    elseif data.roll then
        extra = data.roll;
    end
    extra = extra and (" (%s)"):format(self:ColorizeText(extra)) or "";
    local award = ("%s%s"):format(self:ColorizeName(data.player), extra);
    table.insert(elt:GetUserData("awards"), award);
end

function ABGP:AnnounceOnItemTrashed(data, distribution, sender)
    if not self:Get("lootIntegration") then return; end
    local elt = GetLootFrame(data.itemLink);
    if not elt then return; end

    elt:SetUserData("trashed", true);
end

function ABGP:AnnounceOnItemRolled(data, distribution, sender)
    if not self:Get("lootIntegration") then return; end
    local elt = GetLootFrame(data.itemLink);
    if not elt then return; end

    local roll = data.roll
    elt:SetUserData("roll", roll);
    local rollText = ("Requested by %srolling|r (%s%d|r)"):format(self.Color, self.Color, roll);
    local rollTextCompact = ("|cffffffffR:|r%d"):format(roll);
    elt:SetSecondaryText(rollText, rollTextCompact);
end

function ABGP:AnnounceOnItemRequested(data)
    if not self:Get("lootIntegration") then return; end
    local elt = GetLootFrame(data.itemLink);
    if not elt then return; end

    local roll = elt:GetUserData("roll");
    if roll then
        local rollText = ("Requested by %srolling|r (%s%d|r)"):format(self.Color, self.Color, roll);
        local rollTextCompact = ("|cffffffffR:|r%d"):format(roll);
        elt:SetSecondaryText(rollText, rollTextCompact);
    else
        local requestTypesPre = {
            [ABGP.RequestTypes.MS] = "for",
            [ABGP.RequestTypes.OS] = "for",
            [ABGP.RequestTypes.ROLL] = "by",
        };
        local requestTypes = {
            [ABGP.RequestTypes.MS] = "main spec",
            [ABGP.RequestTypes.OS] = "off spec",
            [ABGP.RequestTypes.ROLL] = "rolling",
        };
        local requestTypesCompact = {
            [ABGP.RequestTypes.MS] = "MS",
            [ABGP.RequestTypes.OS] = "OS",
            [ABGP.RequestTypes.ROLL] = "Roll",
        };
        local text = ("Requested %s %s"):format(requestTypesPre[data.requestType], self:ColorizeText(requestTypes[data.requestType]));
        elt:SetSecondaryText(text, requestTypesCompact[data.requestType]);
    end
end

function ABGP:AnnounceOnItemPassed(data)
    if not self:Get("lootIntegration") then return; end
    local elt = GetLootFrame(data.itemLink);
    if not elt then return; end

    local itemName = ABGP:GetItemName(data.itemLink);
    local value = ABGP:GetItemValue(itemName);
    local valueText = (value and value.gp ~= 0) and ("GP cost: %s"):format(self:ColorizeText(value.gp)) or "No GP Cost";
    local valueTextCompact = (value and value.gp ~= 0) and value.gp or "--";
    elt:SetSecondaryText(valueText, valueTextCompact);
end

function ABGP:ShowTestLoot()
    self:ShowLootFrame("|cffff8000|Hitem:19019|h[Thunderfury, Blessed Blade of the Windseeker]|h|r");
    self:ShowLootFrame("|cffa335ee|Hitem:19375|h[Mish'undare, Circlet of the Mind Flayer]|h|r");
    self:ShowLootFrame("|cffa335ee|Hitem:19406|h[Drake Fang Talisman]|h|r");
    self:ShowLootFrame("|cff0070dd|Hitem:18259|h[Formula: Enchant Weapon - Spell Power]|h|r");
end
