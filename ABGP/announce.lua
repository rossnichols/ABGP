local _G = _G;
local ABGP = _G.ABGP;
local AceGUI = _G.LibStub("AceGUI-3.0");

local UnitName = UnitName;
local GetItemInfo = GetItemInfo;
local GetLootInfo = GetLootInfo;
local GetNumLootItems = GetNumLootItems;
local GetLootSlotLink = GetLootSlotLink;
local GetLootSourceInfo = GetLootSourceInfo;
local UnitExists = UnitExists;
local GetLootMethod = GetLootMethod;
local UnitGUID = UnitGUID;
local FlashClientIcon = FlashClientIcon;
local GetTime = GetTime;
local IsShiftKeyDown = IsShiftKeyDown;
local GetItemIcon = GetItemIcon;
local UnitIsGroupLeader = UnitIsGroupLeader;
local select = select;
local table = table;
local ipairs = ipairs;
local pairs = pairs;
local type = type;

local bossKills = {};
local lootAnnouncements = {};
local lastBoss;
local lastBossTime;
local activeLootFrames = {};
local forceClosures = {};
local forceCloseThreshold = 60;
local forceClosing = false;

local function ItemShouldBeAutoAnnounced(item)
    -- Announce rare+ BoP items.
    return item.quality >= 3 and select(14, GetItemInfo(item.link)) == 1;
end

local function ItemShouldTriggerAnnounce(item)
    -- Trigger on epic+ BoP items.
    return item.quality >= 4 and select(14, GetItemInfo(item.link)) == 1;
end

function ABGP:AnnounceOnLootOpened()
    local loot = GetLootInfo();

    -- Determine the items that meet announcement criteria, and what object is being looted.
    local announceItems = {};
    local lootSource;
    local hasItemToTriggerAnnounce = false;
    for i = 1, GetNumLootItems() do
        local item = loot[i];
        if item then
            -- In Classic, we can only loot one object at a time.
            lootSource = GetLootSourceInfo(i);

            item.link = GetLootSlotLink(i);
            if ItemShouldBeAutoAnnounced(item) then
                table.insert(announceItems, item.link);
            end
            hasItemToTriggerAnnounce = hasItemToTriggerAnnounce or ItemShouldTriggerAnnounce(item);
        end
    end
    if #announceItems == 0 then return; end

    -- Validate the source of the loot. If we're looting a chest and have an appropriate
    -- boss kill in the recent past, use that. Otherwise use our target if it matches.
    local source, name;
    if lootSource:find("GameObject-") and lastBossTime and GetTime() - lastBossTime < 120 then
        source, name = lastBoss, lastBoss;
    elseif UnitExists("target") then
        local guid = UnitGUID("target");
        if guid == lootSource then
            source, name = guid, UnitName("target");
        end
    end
    if not source then return; end

    -- Loot from boss kills should always be announced.
    -- If not from a boss, check if any of the items have an item value.
    local shouldAnnounce = hasItemToTriggerAnnounce or bossKills[name];
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
end

function ABGP:ShouldAutoDistribute()
    return UnitIsGroupLeader("player") and self:Get("autoDistribute");
end

function ABGP:AnnounceOnBossLoot(data)
    local source = data.source;
    local name = data.name;
    lootAnnouncements[source] = lootAnnouncements[source] or { name = name, announced = false };

    if not lootAnnouncements[source].announced then
        self:LogDebug("Announcing loot: name=%s source=%s", name, source);
        lootAnnouncements[source].announced = true;

        if GetLootMethod() == "master" then
            self:Notify("Loot from %s:", self:ColorizeText(name));
            for _, itemLink in ipairs(data.items) do
                self:Notify(itemLink);
                if self:Get("lootShowImmediately") then
                    self:ShowLootFrame(itemLink);
                end
            end
            if self:ShouldAutoDistribute() then
                self:ShowDistrib(data.items);
            end
        end
    end
end

-- Only allow bosses that aren't looted normally.
local allowedBosses = {
    [ABGP.BossIds.Majordomo] = true,
    [ABGP.BossIds.FourHorse] = true,
    [ABGP.BossIds.Chess] = true,
}

function ABGP:AnnounceOnBossKilled(id, name)
    bossKills[name] = true;
    if allowedBosses[id] then
        lastBoss = name;
        lastBossTime = GetTime();
    end
end

function ABGP:AnnounceOnZoneChanged()
    lastBoss = nil;
    lastBossTime = nil;
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

local function SetDefaultInfo(elt, itemLink)
    local itemName = ABGP:GetItemName(itemLink);
    local value = ABGP:GetItemValue(itemName);
    local valueText = value and ABGP:FormatCost(value.gp, value.category) or "";
    local valueTextCompact = value and ABGP:FormatCost(value.gp, value.category, "%s%s") or "--";
    if value and value.token then
        elt:SetUserData("isToken", true);
        valueText = nil;
        valueTextCompact = "T";
        elt:SetRelatedItems(ABGP:GetTokenItems(itemLink));
        local tokenItem = elt:GetUserData("tokenItem");
        if tokenItem then
            elt:SelectRelatedItem(tokenItem, true);
        end
    end
    elt:SetSecondaryText(valueText, valueTextCompact);
end

local function SetRequestInfo(elt, itemLink, activeItem)
    local requestType = activeItem.sentRequestType;

    if requestType then
        elt:SetUserData("requested", true);
        local requestTypes = {
            [ABGP.RequestTypes.MS] = "main spec",
            [ABGP.RequestTypes.OS] = "off spec",
        };
        local requestTypesCompact = {
            [ABGP.RequestTypes.MS] = "MS",
            [ABGP.RequestTypes.OS] = "OS",
        };
        local text, compact;
        local roll = activeItem.roll;
        if roll or ABGP:ItemRequiresRoll(itemLink, elt:GetUserData("tokenItem"), requestType) then
            if roll then
                text = ("Rolled for %s (%s)"):format(ABGP:ColorizeText(requestTypes[requestType]), ABGP:ColorizeText(activeItem.roll));
                compact = ("%s:|cffffffff%s|r"):format(requestTypesCompact[requestType], roll);
            else
                text = ("Rolled for %s"):format(ABGP:ColorizeText(requestTypes[requestType]));
                compact = requestTypesCompact[requestType];
            end
        else
            text = ("Requested for %s"):format(ABGP:ColorizeText(requestTypes[requestType]));
            compact = requestTypesCompact[requestType];
        end
        if not activeItem.receivedAck then
            text = text .. "...";
            compact = "|cffffffff" .. compact;
        end
        elt:SetSecondaryText(text, compact);
    else
        elt:SetUserData("requested", false);
        SetDefaultInfo(elt, itemLink);
    end

    elt:SetCount(activeItem.count);
    if activeItem.msRequestCount > 0 or activeItem.osRequestCount > 0 then
        elt:SetRequestCounts(activeItem.msRequestCount, activeItem.osRequestCount);
    else
        elt:SetRequestCount(activeItem.requestCount);
    end
end

function ABGP:GetLootCount(itemLink)
    local elt = GetLootFrame(itemLink);
    if not elt then return; end

    return elt:GetCount();
end

function ABGP:ShowLootFrame(itemLink)
    local elt = GetLootFrame(itemLink);
    if elt then
        if not self:GetActiveItem(itemLink) then
            elt:SetCount(elt:GetCount() + 1);
            elt:SetDuration(self:Get("lootDuration"));
        end
        return elt;
    end

    elt = AceGUI:Create("ABGP_LootFrame");
    elt:SetItem(itemLink);
    elt:SetDuration(self:Get("lootDuration"));
    elt:EnableRequests(false, "Item not open for distribution.");
    SetDefaultInfo(elt, itemLink);
    forceClosures[itemLink] = nil;

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
                    text = "Show item",
                    func = function(self)
                        ABGP:ShowMainWindow({ command = ABGP.UICommands.ShowItem, args = itemName });
                    end,
                    notCheckable = true
                });
                table.insert(context, {
                    text = "Show item history",
                    func = function(self)
                        ABGP:ShowMainWindow({ command = ABGP.UICommands.ShowItemHistory, args = itemName });
                    end,
                    notCheckable = true
                });
                if not value.token and ABGP:GetActivePlayer(UnitName("player")) and ABGP:GetDebugOpt() then
                    table.insert(context, {
                        text = "Show impact on priority",
                        func = function(self)
                            ABGP:ShowMainWindow({ command = ABGP.UICommands.ShowItemImpact, args = itemName });
                        end,
                        notCheckable = true
                    });
                end
            end
            if #context > 0 then
                table.insert(context, { text = "Cancel", notCheckable = true, fontObject = "GameFontDisableSmall" });
                ABGP:ShowContextMenu(context);
            end
        end
    end);
    elt:SetCallback("OnRequest", function(widget)
        local function requestItem(widget, itemLink, tokenItem)
            widget:SetUserData("requestAttempted", false);
            ABGP:ShowRequestPopup(itemLink, tokenItem);
            ABGP:HideContextMenu();
        end

        local itemLink = widget:GetItem();
        if widget:GetUserData("isToken") then
            local tokenItem = widget:GetUserData("tokenItem");
            if tokenItem then
                requestItem(widget, itemLink, tokenItem);
            else
                local itemLinks = widget:GetRelatedItems();
                local context = {
                    {
                        text = "Select an item",
                        isTitle = true,
                        notCheckable = true
                    }
                };

                local tokenCount = 0;
                local selectedTokenItem;
                local function processTokenItem(tokenItem)
                    tokenCount = tokenCount + 1;
                    selectedTokenItem = tokenItem;

                    local menu = {};
                    local value = ABGP:GetItemValue(ABGP:GetItemId(tokenItem));
                    menu.icon = GetItemIcon(tokenItem);
                    menu.text = ("%s: %s"):format(ABGP:ColorizeText(value.item), ABGP:FormatCost(value.gp, value.category, "%s%s"));
                    menu.notCheckable = true;
                    menu.func = function()
                        widget:SelectRelatedItem(tokenItem, true);
                        requestItem(widget, itemLink, tokenItem);
                    end;
                    table.insert(context, menu);
                end

                -- First try to just add usable items.
                for _, tokenItem in ipairs(itemLinks) do
                    if ABGP:IsItemUsable(tokenItem) then
                        processTokenItem(tokenItem);
                    end
                end

                -- If nothing was added, just add everything.
                if tokenCount == 0 then
                    for _, tokenItem in ipairs(itemLinks) do
                        processTokenItem(tokenItem);
                    end
                end

                -- If a single item was added, immediately select it.
                -- Otherwise, show the menu.
                if tokenCount == 1 then
                    widget:SelectRelatedItem(selectedTokenItem, true);
                    requestItem(widget, itemLink, selectedTokenItem);
                else
                    table.insert(context, { text = "Cancel", notCheckable = true, fontObject = "GameFontDisableSmall" });
                    ABGP:ShowContextMenu(context);
                    widget:SetUserData("requestAttempted", true);
                end
            end
        else
            requestItem(widget, itemLink);
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

        if widget:GetItem() and widget:GetUserData("forceClosed") then
            forceClosures[widget:GetItem()] = GetTime();

            if IsShiftKeyDown() and not forceClosing then
                forceClosing = true;
                for _, elt in pairs(activeLootFrames) do
                    if type(elt) == "table" and elt:GetItem() then
                        local shouldClose = self:Get("lootShiftAll") or not elt:GetUserData("requested");
                        if shouldClose then
                            elt:SetUserData("forceClosed", true);
                            elt.frame:Hide();
                        end
                    end
                end
                forceClosing = false;
            end
        end

        AceGUI:Release(widget);
        self:Fire(self.InternalEvents.LOOT_FRAME_CLOSED);
        self:HideContextMenu();
    end);
    elt:SetCallback("OnRelatedItemSelected", function(widget, event, itemLink)
        widget:SetUserData("tokenItem", itemLink);
        if widget:GetUserData("requestAttempted") then
            widget:Fire("OnRequest");
        end
    end);
    elt:SetCallback("OnRelatedItemClicked", function(widget, event, itemLink, button)
        if button == "RightButton" then
            local context = {};
            local itemName = ABGP:GetItemName(itemLink);
            if ABGP:GetActivePlayer(UnitName("player")) and ABGP:GetDebugOpt() then
                table.insert(context, {
                    text = "Show impact on priority",
                    func = function(self)
                        ABGP:ShowMainWindow({ command = ABGP.UICommands.ShowItemImpact, args = itemName });
                    end,
                    notCheckable = true
                });
            end

            if #context > 0 then
                table.insert(context, { text = "Cancel", notCheckable = true, fontObject = "GameFontDisableSmall" });
                ABGP:ShowContextMenu(context);
            end
        end
    end);

    self:Fire(self.InternalEvents.LOOT_FRAME_OPENED);
    return elt;
end

function ABGP:AnnounceOnDistOpened(data, distribution, sender)
    local itemLink = data.itemLink;
    FlashClientIcon();

    if forceClosures[itemLink] and GetTime() - forceClosures[itemLink] < forceCloseThreshold then
        -- This itemlink was force-closed recently. Don't pop up the loot item again.
        return;
    end
    self:EnsureLootItemVisible(data.itemLink);
end

function ABGP:EnsureLootItemVisible(itemLink, noAnimate)
    local elt = GetLootFrame(itemLink) or self:ShowLootFrame(itemLink);

    local activeItem = self:GetActiveItem(itemLink);
    if activeItem then
        elt:EnableRequests(true, nil, noAnimate);
        elt:SetDuration(nil);
        SetRequestInfo(elt, itemLink, activeItem);
    end
end

function ABGP:IsLootItemVisible(itemLink)
    return (GetLootFrame(itemLink) ~= nil);
end

function ABGP:AnnounceOnDistClosed(data)
    local elt = GetLootFrame(data.itemLink);
    if not elt then return; end

    elt:EnableRequests(false);
    elt:SetDuration(5);
    elt:SetUserData("blockReuse", true);

    local awards = elt:GetUserData("awards");
    if awards and #awards > 0 then
        local awardText = {};
        for _, award in ipairs(awards) do table.insert(awardText, award.text); end
        elt:SetSecondaryText(table.concat(awardText, ", "));
    elseif elt:GetUserData("trashed") then
        elt:SetSecondaryText(self:ColorizeText("Disenchanted"));
    else
        elt:SetSecondaryText("Distribution closed");
    end
end

function ABGP:AnnounceOnItemAwarded(data, distribution, sender)
    local elt = GetLootFrame(data.itemLink);
    if not elt then return; end

    elt:SetUserData("awards", elt:GetUserData("awards") or {});
    local awards = elt:GetUserData("awards");

    if data.player then
        local requestTypes = {
            [self.RequestTypes.MS] = "MS",
            [self.RequestTypes.OS] = "OS",
        };
        local extra;
        if requestTypes[data.requestType] then
            extra = data.roll and ("%s:%s"):format(requestTypes[data.requestType], data.roll) or requestTypes[data.requestType];
        elseif data.roll then
            extra = data.roll;
        end
        extra = extra and (" (%s)"):format(self:ColorizeText(extra)) or "";
        local award = ("%s%s"):format(self:ColorizeName(data.player), extra);
        table.insert(awards, { text = award });
    end
end

function ABGP:AnnounceOnItemTrashed(data, distribution, sender)
    local elt = GetLootFrame(data.itemLink);
    if not elt then return; end

    elt:SetUserData("trashed", true);
end

local function UpdateLootFrame(itemLink)
    local elt = GetLootFrame(itemLink);
    if not elt then return; end

    local activeItem = ABGP:GetActiveItem(itemLink);

    if activeItem then
        SetRequestInfo(elt, itemLink, activeItem);
    end
end

function ABGP:AnnounceOnItemRolled(data, distribution, sender)
    UpdateLootFrame(data.itemLink);
end

function ABGP:AnnounceOnItemRequested(data)
    UpdateLootFrame(data.itemLink);
end

function ABGP:AnnounceOnItemPassed(data)
    UpdateLootFrame(data.itemLink);
end

function ABGP:AnnounceOnItemRequestCount(data, distribution, sender)
    UpdateLootFrame(data.itemLink);
end

function ABGP:AnnounceOnItemRequestReceived(data, distribution, sender)
    UpdateLootFrame(data.itemLink);
end

function ABGP:AnnounceOnItemCount(data, distribution, sender)
    UpdateLootFrame(data.itemLink);
end

function ABGP:AnnounceOnItemFavorited(data)
    local elt = GetLootFrame(data.itemLink);
    if not elt then return; end

    elt:SetItem(elt:GetItem());
end

function ABGP:ShowTestLoot()
    local itemLinks = {
        "|cffff8000|Hitem:19019::::::::60:::::::|h[Thunderfury, Blessed Blade of the Windseeker]|h|r",
        "|cffa335ee|Hitem:19375::::::::60:::::::|h[Mish'undare, Circlet of the Mind Flayer]|h|r",
        "|cffa335ee|Hitem:19375::::::::60:::::::|h[Mish'undare, Circlet of the Mind Flayer]|h|r",
        "|cffa335ee|Hitem:19406::::::::60:::::::|h[Drake Fang Talisman]|h|r",
        "|cff0070dd|Hitem:18259::::::::60:::::::|h[Formula: Enchant Weapon - Spell Power]|h|r",
    };
    for _, itemLink in ipairs(itemLinks) do
        self:ShowLootFrame(itemLink);
    end
    if self:Get("autoDistribute") and self:GetDebugOpt() then
        self:ShowDistrib(itemLinks);
    end
end
