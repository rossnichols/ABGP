local _G = _G;
local ABGP = _G.ABGP;

local UnitName = UnitName;
local GetItemInfo = GetItemInfo;
local GetInventoryItemLink = GetInventoryItemLink;
local UnitExists = UnitExists;
local PlaySoundFile = PlaySoundFile;
local SendSystemMessage = SendSystemMessage;
local table = table;
local pairs = pairs;
local ipairs = ipairs;
local next = next;

local activeItems = {};
local staticPopups = {
    ABGP_LOOTDISTRIB = "ABGP_LOOTDISTRIB",
    ABGP_LOOTDISTRIB_FAVORITE = "ABGP_LOOTDISTRIB_FAVORITE",
    ABGP_LOOTDISTRIB_ROLL = "ABGP_LOOTDISTRIB_ROLL",
    ABGP_LOOTDISTRIB_ROLL_FAVORITE = "ABGP_LOOTDISTRIB_ROLL_FAVORITE",
    ABGP_LOOTDISTRIB_UPDATEROLL = "ABGP_LOOTDISTRIB_UPDATEROLL",
    ABGP_LOOTDISTRIB_UPDATEROLL_FAVORITE = "ABGP_LOOTDISTRIB_UPDATEROLL_FAVORITE",
};

local function GetStaticPopupType(itemLink)
    if not activeItems[itemLink] then return; end

    return ABGP:IsItemFavorited(itemLink)
        and staticPopups.ABGP_LOOTDISTRIB_FAVORITE
        or staticPopups.ABGP_LOOTDISTRIB;
end

local function CloseStaticPopups(itemLink)
    local found = false;
    for index = 1, _G.STATICPOPUP_NUMDIALOGS do
        local frame = _G["StaticPopup" .. index];
        if frame:IsShown() and staticPopups[frame.which] then
            if frame.data.itemLink == itemLink then
                frame:Hide();
                found = true;
            end
        end
    end

    return found;
end

local function ShowStaticPopup(itemLink, value, selected)
    local which = GetStaticPopupType(itemLink);
    CloseStaticPopups(itemLink);
    if which then
        local gp = value and value.gp or 0;
        local category = value and value.category;
        local selectedItemLink;
        local requestedItemLink = itemLink;
        if selected then
            local name, fullLink = GetItemInfo(selected);
            local selectedValue = ABGP:GetItemValue(name);
            requestedItemLink = fullLink;
            selectedItemLink = fullLink;
            gp = selectedValue.gp;
            category = selectedValue.category;
        end
        local dialog = _G.StaticPopup_Show(which, requestedItemLink, ABGP:FormatCost(gp, category), { itemLink = itemLink, selectedItem = selectedItemLink });
        if not dialog then
            ABGP:Error("Unable to open request dialog for %s! Try closing other open ones.", itemLink);
        end
    else
        ABGP:Error("Unable to open request dialog for %s! It's not open for distribution.", itemLink);
    end
end

function ABGP:HasActiveItems()
    return next(activeItems) ~= nil;
end

function ABGP:GetActiveItem(itemLink)
    return activeItems[itemLink];
end

function ABGP:ShowRequestPopup(itemLink, related)
    ShowStaticPopup(itemLink, self:GetItemValue(self:GetItemName(itemLink)), related);
end

local function VerifyItemRequests()
    for itemLink, item in pairs(activeItems) do
        if not UnitExists(item.sender) then
            -- The sender is gone, close the item.
            ABGP:Fire(ABGP.InternalEvents.ITEM_CLOSED, {
                itemLink = itemLink,
                interrupted = true,
            }, "BROADCAST");
        end
    end
end

function ABGP:RequestOnGroupLeft()
    VerifyItemRequests();
end

function ABGP:RequestOnGroupUpdate()
    VerifyItemRequests();
end

function ABGP:RequestOnItemRolled(data, distribution, sender)
    local itemLink = data.itemLink;

    if activeItems[itemLink] then
        self:Notify("You rolled %d on %s.", data.roll, data.selectedItem or itemLink);
        activeItems[itemLink].roll = data.roll;
    end
end

function ABGP:RequestOnItemRequestCount(data, distribution, sender)
    local itemLink = data.itemLink;

    if activeItems[itemLink] then
        activeItems[itemLink].requestCount = data.count;
        activeItems[itemLink].msRequestCount = data.main or 0;
        activeItems[itemLink].osRequestCount = data.off or 0;
    end
end

function ABGP:RequestOnItemCount(data, distribution, sender)
    local itemLink = data.itemLink;

    if activeItems[itemLink] then
        activeItems[itemLink].count = data.count;
    end
end

function ABGP:RequestOnDistOpened(data, distribution, sender)
    local itemLink = data.itemLink;
    if activeItems[itemLink] then
        if sender ~= activeItems[itemLink].sender then
            self:Error("Duplicate distribution for %s! (%s new, %s existing)",
                itemLink, ABGP:ColorizeName(sender), ABGP:ColorizeName(activeItems[itemLink].sender));
        end
        return;
    end

    -- Ensure item info is cached locally.
    GetItemInfo(itemLink);

    activeItems[itemLink] = {
        itemLink = itemLink,
        sender = sender,
        value = ABGP:GetItemValue(ABGP:GetItemName(itemLink)),
        slots = data.slots,
        roll = nil,
        sentComms = false,
        receivedAck = false,
        sentRequestType = nil,
        count = data.count or 1,
        requestCount = 0,
        msRequestCount = 0,
        osRequestCount = 0,
    };

    local gpCost, priority, notes = "", "", "";
    local value = activeItems[itemLink].value;
    if value then
        if value.token then
            gpCost = "Token (variable GP cost)";
        else
            local rolled = data.rollsAllowed and (" (rolled)") or "";
            gpCost = ("Cost: %s%s"):format(self:FormatCost(value.gp, value.category), rolled);
        end
        if value.priority and next(value.priority) then
            priority = (", Priority: %s"):format(table.concat(value.priority, ", "));
        end
        if value.notes then
            notes = (". Notes: %s"):format(value.notes);
        end
    end

    self:Notify("Item distribution opened for %s! %s%s%s", itemLink, gpCost, priority, notes);
end

function ABGP:RequestOnDistClosed(data)
    local itemLink = data.itemLink;
    if activeItems[itemLink] then
        if data.interrupted then
            self:Notify("Item distribution interrupted for %s (distributor no longer found).", itemLink);
        elseif data.count == 0 then
            self:Notify("Item distribution closed for %s.", itemLink);
        end

        CloseStaticPopups(itemLink);
        activeItems[itemLink] = nil;
    end
end

function ABGP:RequestOnItemAwarded(data, distribution, sender)
    local itemLink = data.itemLink;
    local selectedItemLink = data.selectedItem or itemLink;

    if not data.testItem and not data.updated then
        -- See if we can ML the item to the player.
        self:GiveItemViaML(data.itemLink, data.player);
    end

    local player = data.player;
    local override = data.override;

    local multiple = "";
    local itemCount = activeItems[data.itemLink] and activeItems[data.itemLink].count or 1;
    if (data.count and data.count > 1) or itemCount > 1 then
        multiple = (" #%d"):format(data.count);
    end

    local cost = "";
    local value = self:GetItemValue(self:GetItemName(itemLink));
    if value then
        local effective = self:GetEffectiveCost(data.historyId, data.cost);
        effective = (effective and effective.cost ~= data.cost.cost) and (" (%.3f effective)"):format(effective.cost) or "";
        cost = (" for %s%s"):format(self:FormatCost(data.cost), effective);
    else
        override = nil;
    end
    if data.testItem then override = "test"; end

    local requestTypes = {
        [self.RequestTypes.MS] = " (%smain spec)",
        [self.RequestTypes.OS] = " (%soff spec)",
        [self.RequestTypes.MANUAL] = " (%smanual)",
    };
    local requestType = "";
    if requestTypes[data.requestType] then
        override = override and ("%s, "):format(override) or "";
        requestType = requestTypes[data.requestType]:format(override);
    elseif override then
        requestType = (" (%s)"):format(override);
    end
    if player == UnitName("player") then
        local unfaved = "";
        if not data.testItem then
            if self:IsItemFavorited(itemLink) then
                self:SetItemFavorited(itemLink, false);
                unfaved = " Removed it from your AtlasLoot favorites.";
            end
        end

        local rollType, rollValue;
        if data.roll then
            rollType = _G.LOOT_ROLL_TYPE_NEED;
            rollValue = data.roll;
        end
        local lessAwesome = (data.cost == 0);
        _G.LootAlertSystem:AddAlert(selectedItemLink, nil, rollType, rollValue, nil, nil, nil, nil, lessAwesome, nil, true, nil);
        self:Notify("%s%s was awarded to you%s%s!%s", selectedItemLink, multiple, cost, requestType, unfaved);
    else
        local roll = "";
        if data.roll then
            roll = (" with a roll of %d"):format(data.roll);
        end
        self:Notify("%s%s was awarded to %s%s%s%s.",
            selectedItemLink, multiple, self:ColorizeName(player), cost, requestType, roll);
    end
end

function ABGP:RequestOnItemUnawarded(data)
    local player = (data.player == UnitName("player")) and "you" or self:ColorizeName(data.player);
    self:Notify("Award of %s to %s was removed.", data.itemLink, player);
end

function ABGP:RequestOnItemTrashed(data, distribution, sender)
    local itemLink = data.itemLink;

    local info = "";
    if data.testItem then info = " (test)"; end

    local multiple = "";
    local itemCount = activeItems[data.itemLink] and activeItems[data.itemLink].count or 1;
    if data.count > 1 or itemCount > 1 then
        multiple = (" #%d"):format(data.count);
    end

    -- See if we can ML the item to the raid disenchanter.
    self:GiveItemViaML(data.itemLink, ABGP:GetRaidDisenchanter());

    self:Notify("%s%s will be disenchanted%s.", itemLink, multiple, info);
end

function ABGP:RequestOnItemRequestReceived(data, distribution, sender)
    local itemLink = data.itemLink;
    if not activeItems[itemLink] then return; end

    self:Notify("Your %s %s has been received.", data.requestType and "request for" or "pass on", data.selectedItem or itemLink);

    activeItems[itemLink].receivedAck = true;

    if not activeItems[itemLink].sentComms then
        -- We didn't realize we sent this request (reloaded UI, perhaps).
        activeItems[itemLink].sentComms = true;
        activeItems[itemLink].sentRequestType = data.requestType;
        if data.sentRequestType then
            self:Fire(self.InternalEvents.ITEM_REQUESTED, data);
        else
            self:Fire(self.InternalEvents.ITEM_PASSED, data);
        end
    end
end

function ABGP:RequestOnItemRequestRejected(data, distribution, sender)
    local itemLink = data.itemLink;
    if not activeItems[itemLink] then return; end

    if data.player == UnitName("player") then
        SendSystemMessage("access: PERMISSION DENIED....and...");
        SendSystemMessage("YOU DIDN'T SAY THE MAGIC WORD!");
        PlaySoundFile("Interface\\AddOns\\ABGP\\Assets\\beep.ogg", "Master");
        PlaySoundFile("Interface\\AddOns\\ABGP\\Assets\\nedry.ogg", "Master");
        self:Alert("Your request for %s has been |cffff0000rejected|r!", itemLink);
        if data.reason then
            self:Notify("Reason: %s", data.reason);
        end
        activeItems[itemLink].sentComms = true;
        activeItems[itemLink].receivedAck = true;
        activeItems[itemLink].sentRequestType = nil;

        self:Fire(self.InternalEvents.ITEM_PASSED, {
            itemLink = itemLink,
        });
    else
        self:Notify("%s's request for %s has been |cffff0000rejected|r!", self:ColorizeName(data.player), data.selectedItem or itemLink);
        if data.reason then
            self:Notify("Reason: %s", data.reason);
        end
    end
end

function ABGP:ShowItemRequests()
    if self:HasActiveItems() then
        for itemLink in pairs(activeItems) do
            self:EnsureLootItemVisible(itemLink, true);
        end
    else
        self:Notify("No items are being distributed.");
    end
end

function ABGP:HasHiddenItemRequests()
    for itemLink in pairs(activeItems) do
        if not self:IsLootItemVisible(itemLink) then
            return true;
        end
    end

    return false;
end

function ABGP:RequestItem(itemLink, selected, requestType, notes)
    if not activeItems[itemLink] then
        self:Notify("Unable to request %s - no longer being distributed.", itemLink);
        return;
    end
    local sender = activeItems[itemLink].sender;

    local data = {
        itemLink = itemLink,
        selectedItem = selected,
        requestType = requestType,
    };
    local requestTypes = {
        [ABGP.RequestTypes.MS] = "for main spec",
        [ABGP.RequestTypes.OS] = "for off spec",
    };

    local requestedItemLink = selected or itemLink;
    if activeItems[itemLink].sentComms and activeItems[itemLink].sentRequestType then
        self:Notify("Updated request for %s.", requestedItemLink);
    else
        self:Notify("Requesting %s %s!", requestedItemLink, requestTypes[requestType]);
    end

    data.notes = (notes ~= "") and notes or nil;
    data.equipped = {};
    local slots = activeItems[itemLink].slots or self:GetItemEquipSlots(requestedItemLink);
    if slots then
        for _, slot in ipairs(slots) do
            local equippedLink = GetInventoryItemLink("player", slot);
            if equippedLink then table.insert(data.equipped, equippedLink); end
        end
    end

    local synchronous = self:SendComm(self.CommTypes.ITEM_REQUEST, data, "WHISPER", sender);
    if not synchronous then
        -- The request wasn't completed synchronously. Send another one with a reduced payload.
        data.notes = nil;
        data.equipped = nil;
        self:SendComm(self.CommTypes.ITEM_REQUEST, data, "WHISPER", sender);
    end

    activeItems[itemLink].sentComms = true;
    activeItems[itemLink].receivedAck = false;
    activeItems[itemLink].sentRequestType = requestType;

    self:Fire(self.InternalEvents.ITEM_REQUESTED, data);
end

function ABGP:PassOnItem(itemLink, removeFromFaves)
    if not activeItems[itemLink] then
        self:Notify("Unable to pass on %s - no longer being distributed.", itemLink);
        return;
    end
    local sender = activeItems[itemLink].sender;

    local data = {
        itemLink = itemLink,
    };

    self:SendComm(self.CommTypes.ITEM_PASS, data, "WHISPER", sender);

    local faveRemove = "";
    if removeFromFaves then
        faveRemove = " and removing from AtlasLoot favorites";
        ABGP:SetItemFavorited(itemLink, false);
    end

    self:Notify("Passing on %s%s.", itemLink, faveRemove);
    activeItems[itemLink].sentComms = true;
    activeItems[itemLink].receivedAck = false;
    activeItems[itemLink].sentRequestType = nil;

    self:Fire(self.InternalEvents.ITEM_PASSED, data);
end

StaticPopupDialogs[staticPopups.ABGP_LOOTDISTRIB] = ABGP:StaticDialogTemplate(ABGP.StaticDialogTemplates.EDIT_BOX, {
    text = "Request %s for %s? You may provide an optional note.",
    button1 = "Request (MS)",
    button2 = "Request (OS)",
    button3 = "Pass",
    maxLetters = 255,
    notFocused = true,
    noCancelOnEscape = true,
    suppressEnterCommit = true,
    Commit = function(text, data)
        ABGP:RequestItem(data.itemLink, data.selectedItem, ABGP.RequestTypes.MS, text);
    end,
    OnCancel = function(self, data, reason)
        if not self then return; end
        if reason == "override" then return; end
        ABGP:RequestItem(data.itemLink, data.selectedItem, ABGP.RequestTypes.OS, self.editBox:GetText());
    end,
    OnAlt = function(self, data)
        ABGP:PassOnItem(data.itemLink, false);
    end,
});
StaticPopupDialogs[staticPopups.ABGP_LOOTDISTRIB_FAVORITE] = ABGP:StaticDialogTemplate(ABGP.StaticDialogTemplates.EDIT_BOX, {
    text = "Request %s for %s? You may provide an optional note.",
    button1 = "Request (MS)",
    button2 = "Request (OS)",
    button3 = "Pass",
    extraButton = "Pass and unfavorite",
    maxLetters = 255,
    notFocused = true,
    noCancelOnEscape = true,
    suppressEnterCommit = true,
    Commit = function(text, data)
        ABGP:RequestItem(data.itemLink, data.selectedItem, ABGP.RequestTypes.MS, text);
    end,
    OnCancel = function(self, data, reason)
        if not self then return; end
        if reason == "override" then return; end
        ABGP:RequestItem(data.itemLink, data.selectedItem, ABGP.RequestTypes.OS, self.editBox:GetText());
    end,
    OnAlt = function(self, data)
        ABGP:PassOnItem(data.itemLink, false);
    end,
    OnExtraButton = function(self, data)
        ABGP:PassOnItem(data.itemLink, true);
    end,
});
