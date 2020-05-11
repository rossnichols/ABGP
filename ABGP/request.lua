local _G = _G;
local ABGP = _G.ABGP;

local UnitName = UnitName;
local GetItemInfo = GetItemInfo;
local GetInventoryItemLink = GetInventoryItemLink;
local UnitExists = UnitExists;
local table = table;
local pairs = pairs;
local select = select;
local next = next;

local activeItems = {};
local staticPopups = {
    ABGP_LOOTDISTRIB = "ABGP_LOOTDISTRIB",
    ABGP_LOOTDISTRIB_FAVORITE = "ABGP_LOOTDISTRIB_FAVORITE",
    ABGP_LOOTDISTRIB_ROLL = "ABGP_LOOTDISTRIB_ROLL",
    ABGP_LOOTDISTRIB_ROLL_FAVORITE = "ABGP_LOOTDISTRIB_ROLL_FAVORITE",
};

local function GetStaticPopupType(itemLink)
    if not activeItems[itemLink] then return; end

    local favorited = ABGP:IsItemFavorited(itemLink);
    if activeItems[itemLink].requestType == ABGP.RequestTypes.ROLL then
        return (favorited)
            and staticPopups.ABGP_LOOTDISTRIB_ROLL_FAVORITE
            or staticPopups.ABGP_LOOTDISTRIB_ROLL;
    end

    return (favorited)
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

local function ShowStaticPopup(itemLink, value, which)
    which = which or GetStaticPopupType(itemLink);
    CloseStaticPopups(itemLink);
    if which then
        local dialog = _G.StaticPopup_Show(which, itemLink, value and value.gp or 0, { itemLink = itemLink });
        if not dialog then
            ABGP:Error("Unable to open window for %s! Try closing other open ones.", itemLink);
        end
    end
end

function ABGP:HasActiveItems()
    return next(activeItems) ~= nil;
end

function ABGP:GetActiveItem(itemLink)
    return activeItems[itemLink];
end

function ABGP:ShowRequestPopup(itemLink)
    ShowStaticPopup(itemLink, self:GetItemValue(self:GetItemName(itemLink)));
end

local function VerifyItemRequests()
    for itemLink, item in pairs(activeItems) do
        if not UnitExists(item.sender) then
            -- The sender is gone, close the item.
            ABGP:RequestOnDistClosed({ itemLink = itemLink });
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
    self:Notify("You rolled %d on %s.", data.roll, data.itemLink);
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
        requestType = data.requestType,
        value = data.value,
    };

    local gpCost, priority, notes = "No GP cost (rolled)", "", "";
    local value = data.value;
    if value then
        self:CheckUpdatedItem(itemLink, value);
        if value.gp ~= 0 then
            gpCost = ("GP cost: %d"):format(value.gp);
        end
        if value.priority then
            priority = (", Priority: %s"):format(table.concat(value.priority, ", "));
        end
        if value.notes then
            notes = (". Notes: %s"):format(value.notes);
        end
    end

    self:Notify("Item distribution opened for %s! %s%s%s.", itemLink, gpCost, priority, notes);
end

function ABGP:RequestOnDistClosed(data, distribution, sender)
    local itemLink = data.itemLink;
    if activeItems[itemLink] then
        if data.count == 0 then
            self:Notify("Item distribution closed for %s.", itemLink);
        end

        CloseStaticPopups(itemLink);
        activeItems[itemLink] = nil;
    end
end

function ABGP:RequestOnItemAwarded(data, distribution, sender)
    local itemLink = data.itemLink;

    local player = data.player;
    local override = data.override;
    if data.testItem then override = "test"; end
    if not player then return; end

    local multiple = "";
    if data.count and data.count > 1 then
        multiple = (" #%d"):format(data.count);
    end

    local cost = "";
    if self:GetItemValue(self:GetItemName(itemLink)) then
        cost = (" for %d GP"):format(data.cost);
    end

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
        _G.LootAlertSystem:AddAlert(itemLink, nil, rollType, rollValue, nil, nil, nil, nil, lessAwesome, nil, true, nil);
        self:Notify("%s%s was awarded to you%s%s!%s", itemLink, multiple, cost, requestType, unfaved);
    else
        local roll = "";
        if data.roll then
            roll = (" with a roll of %d"):format(data.roll);
        end
        self:Notify("%s%s was awarded to %s%s%s%s.",
            itemLink, multiple, self:ColorizeName(player), cost, requestType, roll);
    end
end

function ABGP:RequestOnItemUnawarded(data)
    local player = (data.player == UnitName("player")) and "you" or  self:ColorizeName(data.player);
    self:Notify("Award of %s to %s for %d GP was removed.",
        data.itemLink, player, data.gp);
end

function ABGP:RequestOnItemTrashed(data, distribution, sender)
    local itemLink = data.itemLink;

    local info = "";
    if data.testItem then info = " (test)"; end

    local multiple = "";
    if data.count > 1 then
        multiple = (" #%d"):format(data.count);
    end

    self:Notify("%s%s will be disenchanted%s.", itemLink, multiple, info);
end

function ABGP:ShowItemRequests()
    for itemLink in pairs(activeItems) do
        self:EnsureLootItemVisible(itemLink, true);
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

function ABGP:RequestItem(itemLink, requestType, notes)
    if not activeItems[itemLink] then
        self:Notify("Unable to request %s - no longer being distributed.", itemLink);
        return;
    end
    local sender = activeItems[itemLink].sender;

    local data = {
        itemLink = itemLink,
        requestType = requestType,
    };
    local requestTypes = {
        [ABGP.RequestTypes.MS] = "for main spec",
        [ABGP.RequestTypes.OS] = "for off spec",
        [ABGP.RequestTypes.ROLL] = "by rolling",
    };
    local itemMaps = {
        INVTYPE_HEAD = { _G.INVSLOT_HEAD },
        INVTYPE_NECK = { _G.INVSLOT_NECK },
        INVTYPE_SHOULDER = { _G.INVSLOT_SHOULDER },
        INVTYPE_BODY = { _G.INVSLOT_BODY },
        INVTYPE_CHEST = { _G.INVSLOT_CHEST },
        INVTYPE_WAIST = { _G.INVSLOT_WAIST },
        INVTYPE_LEGS = { _G.INVSLOT_LEGS },
        INVTYPE_FEET = { _G.INVSLOT_FEET },
        INVTYPE_WRIST = { _G.INVSLOT_WRIST },
        INVTYPE_HAND = { _G.INVSLOT_HAND },
        INVTYPE_FINGER = { _G.INVSLOT_FINGER1, _G.INVSLOT_FINGER2 },
        INVTYPE_TRINKET = { _G.INVSLOT_TRINKET1, _G.INVSLOT_TRINKET2 },
        INVTYPE_WEAPON = { _G.INVSLOT_MAINHAND, _G.INVSLOT_OFFHAND },
        INVTYPE_SHIELD = { _G.INVSLOT_MAINHAND, _G.INVSLOT_OFFHAND },
        INVTYPE_RANGED = { _G.INVSLOT_RANGED },
        INVTYPE_CLOAK = { _G.INVSLOT_BACK },
        INVTYPE_2HWEAPON = { _G.INVSLOT_MAINHAND, _G.INVSLOT_OFFHAND },
        INVTYPE_TABARD = { _G.INVSLOT_TABARD },
        INVTYPE_ROBE = { _G.INVSLOT_CHEST },
        INVTYPE_WEAPONMAINHAND = { _G.INVSLOT_MAINHAND, _G.INVSLOT_OFFHAND },
        INVTYPE_WEAPONOFFHAND = { _G.INVSLOT_MAINHAND, _G.INVSLOT_OFFHAND },
        INVTYPE_HOLDABLE = { _G.INVSLOT_MAINHAND, _G.INVSLOT_OFFHAND },
        INVTYPE_AMMO = { _G.INVSLOT_AMMO },
        INVTYPE_THROWN = { _G.INVSLOT_RANGED },
        INVTYPE_RANGEDRIGHT = { _G.INVSLOT_RANGED },
        INVTYPE_RELIC = { _G.INVSLOT_RANGED },
    };

    if activeItems[itemLink].sentComms and activeItems[itemLink].sentRequest then
        self:Notify("Updated request for %s.", itemLink);
    else
        self:Notify("Requesting %s %s!", itemLink, requestTypes[requestType]);
    end

    data.notes = (notes ~= "") and notes or nil;
    data.equipped = {};
    local equipLoc = select(9, GetItemInfo(itemLink));
    if equipLoc and itemMaps[equipLoc] then
        local current1 = itemMaps[equipLoc][1] and GetInventoryItemLink("player", itemMaps[equipLoc][1]) or nil;
        local current2 = itemMaps[equipLoc][2] and GetInventoryItemLink("player", itemMaps[equipLoc][2]) or nil;
        if current1 then table.insert(data.equipped, current1); end
        if current2 then table.insert(data.equipped, current2); end
    end

    self:SendMessage(self.InternalEvents.ITEM_REQUESTED, data);

    local synchronous = self:SendComm(self.CommTypes.ITEM_REQUEST, data, "WHISPER", sender);
    if not synchronous then
        -- The request wasn't completed synchronously. Send another one with a reduced payload.
        data.notes = nil;
        data.equipped = nil;
        self:SendComm(self.CommTypes.ITEM_REQUEST, data, "WHISPER", sender);
    end

    activeItems[itemLink].sentComms = true;
    activeItems[itemLink].sentRequest = true;
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

    self:SendMessage(self.InternalEvents.ITEM_PASSED, data);
    self:SendComm(self.CommTypes.ITEM_PASS, data, "WHISPER", sender);

    local faveRemove = "";
    if removeFromFaves then
        faveRemove = " and removing from AtlasLoot favorites";
        ABGP:SetItemFavorited(itemLink, false);
    end

    self:Notify("Passing on %s%s.", itemLink, faveRemove);
    activeItems[itemLink].sentComms = true;
end

StaticPopupDialogs[staticPopups.ABGP_LOOTDISTRIB] = {
    text = "%s is being distributed for %d GP! You may request it and provide an optional note.",
    button1 = "Request (MS)",
    button2 = "Request (OS)",
    button3 = "Pass",
	hasEditBox = 1,
	maxLetters = 255,
	countInvisibleLetters = true,
    OnHyperlinkEnter = function(self, itemLink)
        _G.ShowUIPanel(_G.GameTooltip);
        _G.GameTooltip:SetOwner(self, "ANCHOR_BOTTOM");
        _G.GameTooltip:SetHyperlink(itemLink);
        _G.GameTooltip:Show();
    end,
    OnHyperlinkLeave = function(self, itemLink)
        _G.GameTooltip:Hide();
    end,
    OnShow = function(self, data)
        self.editBox:SetAutoFocus(false);
        self.editBox:ClearFocus();
	end,
    EditBoxOnEscapePressed = function(self)
		self:ClearFocus();
    end,
    OnHide = function(self, data)
        self.editBox:SetAutoFocus(true);
    end,
	OnAccept = function(self, data)
        ABGP:RequestItem(data.itemLink, ABGP.RequestTypes.MS, self.editBox:GetText());
	end,
    OnCancel = function(self, data, reason)
        if not self then return; end
        if reason == "override" then return; end
        ABGP:RequestItem(data.itemLink, ABGP.RequestTypes.OS, self.editBox:GetText());
	end,
	OnAlt = function(self, data)
        ABGP:PassOnItem(data.itemLink, false);
	end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    noCancelOnEscape = true,
    multiple = true,
};

local dialog = {};
for k, v in pairs(StaticPopupDialogs[staticPopups.ABGP_LOOTDISTRIB]) do dialog[k] = v; end
dialog.extraButton = "Pass and unfavorite";
dialog.OnExtraButton = function(self, data)
    ABGP:PassOnItem(data.itemLink, true);
end
StaticPopupDialogs[staticPopups.ABGP_LOOTDISTRIB_FAVORITE] = dialog;

local dialog = {};
for k, v in pairs(StaticPopupDialogs[staticPopups.ABGP_LOOTDISTRIB]) do dialog[k] = v; end
dialog.text = "%s is being distributed! You may roll for it and provide an optional note.";
dialog.button1 = "Roll";
dialog.button2 = nil;
dialog.OnAccept = function(self, data)
    ABGP:RequestItem(data.itemLink, ABGP.RequestTypes.ROLL, self.editBox:GetText());
end
StaticPopupDialogs[staticPopups.ABGP_LOOTDISTRIB_ROLL] = dialog;

local dialog = {};
for k, v in pairs(StaticPopupDialogs[staticPopups.ABGP_LOOTDISTRIB_ROLL]) do dialog[k] = v; end
dialog.extraButton = "Pass and unfavorite";
dialog.OnExtraButton = function(self, data)
    ABGP:PassOnItem(data.itemLink, true);
end
StaticPopupDialogs[staticPopups.ABGP_LOOTDISTRIB_ROLL_FAVORITE] = dialog;
