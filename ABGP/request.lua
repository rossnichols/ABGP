local activeItems = {};
local staticPopups = {
    LOOTDISTRIB = "ABGP_LOOTDISTRIB",
    LOOTDISTRIB_FAVORITE = "ABGP_LOOTDISTRIB_FAVORITE",
    LOOTDISTRIB_ROLL = "ABGP_LOOTDISTRIB_ROLL",
    LOOTDISTRIB_ROLL_FAVORITE = "ABGP_LOOTDISTRIB_ROLL_FAVORITE",
};

local function AtlasLootFaves()
    if AtlasLoot and AtlasLoot.Addons and AtlasLoot.Addons.GetAddon then
        return AtlasLoot.Addons:GetAddon("Favourites");
    end
end

local function GetStaticPopupType(itemLink)
    if not activeItems[itemLink] then return; end

    local favorited = false;
    local faves = AtlasLootFaves();
    if faves then
        local itemId = ABGP:GetItemId(itemLink);
        if faves:IsFavouriteItemID(itemId) then
            favorited = true;
        end
    end

    if activeItems[itemLink].requestType == ABGP.RequestTypes.ROLL then
        return (favorited)
            and staticPopups.LOOTDISTRIB_ROLL_FAVORITE
            or staticPopups.LOOTDISTRIB_ROLL;
    end

    return (favorited)
        and staticPopups.LOOTDISTRIB_FAVORITE
        or staticPopups.LOOTDISTRIB;
end

local function CloseStaticPopups(itemLink)
    for index = 1, STATICPOPUP_NUMDIALOGS do
        local frame = _G["StaticPopup"..index];
        if frame:IsShown() and staticPopups[frame.which] then
            if frame.data.itemLink == itemLink then
                frame:Hide();
            end
        end
    end
end

local function ShowStaticPopup(itemLink, which)
    which = which or GetStaticPopupType(itemLink);
    CloseStaticPopups(itemLink);
    if which then
        StaticPopup_Show(which, itemLink, nil, { itemLink = itemLink });
    end
end

function ABGP:RequestOnDistOpened(data, distribution, sender)
    local itemLink = data.itemLink;
    activeItems[itemLink] = { sender = sender, requestType = data.requestType };

    local msg;
    local value = data.value;
    if value then
        local notes = "";
        if value.notes then
            notes = ", Notes: " .. value.notes
        end
        if value.gp == 0 then
            msg = string.format("Now distributing %s! No GP cost, Priority: %s%s.",
                itemLink, table.concat(value.priority, ", "), notes);
        else
            msg = string.format("Now distributing %s! GP cost: %d, Priority: %s%s.",
                itemLink, value.gp, table.concat(value.priority, ", "), notes);
        end
    else
        msg = string.format("Now distributing %s! No GP cost.",
            itemLink);
    end

    RaidNotice_AddMessage(RaidWarningFrame, msg, ABGP.ColorTable);
    PlaySound(SOUNDKIT.RAID_WARNING);
    FlashClientIcon();

    local prompt = "";
    local popup = GetStaticPopupType(itemLink);
    if popup == staticPopups.LOOTDISTRIB_FAVORITE or popup == staticPopups.LOOTDISTRIB_ROLL_FAVORITE then
        ShowStaticPopup(itemLink, which);
        prompt = "This item is favorited in AtlasLoot."
    else
        local keybinding = GetBindingKey("ABGP_SHOWITEMREQUESTS") or "currently unbound";
        prompt = string.format("Type '/abgp loot' or press your hotkey (%s) if you want to request this item.", keybinding);
    end

    self:Notify("%s is being distributed! %s", itemLink, prompt);
end

function ABGP:RequestOnDistClosed(data, distribution, sender)
    local itemLink = data.itemLink;
    if activeItems[itemLink] then
        if not activeItems[itemLink].notified then
            self:Notify("Item distribution closed for %s.", itemLink);
        end

        CloseStaticPopups(itemLink);
        activeItems[itemLink] = nil;
    end
end

function ABGP:RequestOnDistAwarded(data, distribution, sender)
    local itemLink = data.itemLink;

    local player = data.player;
    local cost = data.cost;

    local multiple = "";
    if activeItems[itemLink] then
        if activeItems[itemLink].notified then
            activeItems[itemLink].notified = activeItems[itemLink].notified + 1;
            multiple = string.format(" #%d", activeItems[itemLink].notified);
        else
            activeItems[itemLink].notified = 1;
        end
    end

    if player == UnitName("player") then
        self:Notify("%s%s was awarded to you for %d GP!", itemLink, multiple, cost);
    else
        self:Notify("%s%s was awarded to %s for %d GP.", itemLink, multiple, ABGP:ColorizeName(player), cost);
    end
end

function ABGP:RequestOnDistTrashed(data, distribution, sender)
    local itemLink = data.itemLink;

    local multiple = "";
    if activeItems[itemLink] then
        if activeItems[itemLink].notified then
            activeItems[itemLink].notified = activeItems[itemLink].notified + 1;
            multiple = string.format(" #%d", activeItems[itemLink].notified);
        else
            activeItems[itemLink].notified = 1;
        end
    end

    self:Notify("%s%s will be disenchanted.", itemLink, multiple);
end

function ABGP:ShowItemRequests()
    local found = false;
    for itemLink in pairs(activeItems) do
        ShowStaticPopup(itemLink);
        found = true;
    end

    if not found then
        self:Notify("There are no items being distributed.");
    end
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
        notes = (notes ~= "") and notes or nil,
        equipped = {},
    };
    local requestTypes = {
        [ABGP.RequestTypes.MS] = "for main spec",
        [ABGP.RequestTypes.OS] = "for off spec",
        [ABGP.RequestTypes.ROLL] = "by rolling",
    };
    local itemMaps = {
        INVTYPE_HEAD = { INVSLOT_HEAD },
        INVTYPE_NECK = { INVSLOT_NECK },
        INVTYPE_SHOULDER = { INVSLOT_SHOULDER },
        INVTYPE_BODY = { INVSLOT_BODY },
        INVTYPE_CHEST = { INVSLOT_CHEST },
        INVTYPE_WAIST = { INVSLOT_WAIST },
        INVTYPE_LEGS = { INVSLOT_LEGS },
        INVTYPE_FEET = { INVSLOT_FEET },
        INVTYPE_WRIST = { INVSLOT_WRIST },
        INVTYPE_HAND = { INVSLOT_HAND },
        INVTYPE_FINGER = { INVSLOT_FINGER1, INVSLOT_FINGER2 },
        INVTYPE_TRINKET = { INVSLOT_TRINKET1, INVSLOT_TRINKET2 },
        INVTYPE_WEAPON = { INVSLOT_MAINHAND, INVSLOT_OFFHAND },
        INVTYPE_SHIELD = { INVSLOT_MAINHAND, INVSLOT_OFFHAND },
        INVTYPE_RANGED = { INVSLOT_RANGED },
        INVTYPE_CLOAK = { INVSLOT_BACK },
        INVTYPE_2HWEAPON = { INVSLOT_MAINHAND, INVSLOT_OFFHAND },
        INVTYPE_TABARD = { INVSLOT_TABARD },
        INVTYPE_ROBE = { INVSLOT_CHEST },
        INVTYPE_WEAPONMAINHAND = { INVSLOT_MAINHAND, INVSLOT_OFFHAND },
        INVTYPE_WEAPONOFFHAND = { INVSLOT_MAINHAND, INVSLOT_OFFHAND },
        INVTYPE_HOLDABLE = { INVSLOT_MAINHAND, INVSLOT_OFFHAND },
        INVTYPE_AMMO = { INVSLOT_AMMO },
        INVTYPE_THROWN = { INVSLOT_RANGED },
        INVTYPE_RANGEDRIGHT = { INVSLOT_RANGED },
        INVTYPE_RELIC = { INVSLOT_RANGED },
    };
    local equipLoc = select(9, GetItemInfo(itemLink));
    if equipLoc and itemMaps[equipLoc] then
        local current1 = itemMaps[equipLoc][1] and GetInventoryItemLink("player", itemMaps[equipLoc][1]) or nil;
        local current2 = itemMaps[equipLoc][2] and GetInventoryItemLink("player", itemMaps[equipLoc][2]) or nil;
        if current1 then table.insert(data.equipped, current1); end
        if current2 then table.insert(data.equipped, current2); end
    end

    local faveInfo = "";
    local faves = AtlasLootFaves();
    if faves then
        local itemId = ABGP:GetItemId(itemLink);
        if not faves:IsFavouriteItemID(itemId) then
            faveInfo = "To automatically show the request window for this item in the future, favorite it in AtlasLoot.";
        end
    end
    ABGP:Notify("Requesting %s %s! To update your request, open the window again. %s", itemLink, requestTypes[requestType], faveInfo);

    self:SendComm(self.CommTypes.ITEM_REQUEST, data, "WHISPER", sender);
end

function ABGP:PassOnItem(itemLink, removeFromFaves)
    if not activeItems[itemLink] then
        self:Notify("Unable to pass on %s - no longer being distributed.", itemLink);
        return;
    end
    local sender = activeItems[itemLink].sender;

    self:SendComm(self.CommTypes.ITEM_PASS, {
        itemLink = itemLink,
    }, "WHISPER", sender);

    local faveRemove = "";
    if removeFromFaves then
        faveRemove = " and removing from AtlasLoot favorites";
        local faves = AtlasLootFaves();
        if faves then
            local itemId = ABGP:GetItemId(itemLink);
            faves:RemoveItemID(itemId);
        end
    end
    ABGP:Notify("Passing on %s%s. To update your request, open the window again.", itemLink, faveRemove);
end

StaticPopupDialogs[staticPopups.LOOTDISTRIB] = {
    text = "%s is being distributed! You may request it and provide an optional note.",
    button1 = "Request (MS)",
    button2 = "Request (OS)",
    button3 = "Pass",
	hasEditBox = 1,
	maxLetters = 255,
	countInvisibleLetters = true,
    OnHyperlinkEnter = function(self, itemLink)
        ShowUIPanel(GameTooltip);
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM");
        GameTooltip:SetHyperlink(itemLink);
        GameTooltip:Show();
    end,
    OnHyperlinkLeave = function(self, itemLink)
        GameTooltip:Hide();
    end,
    OnShow = function(self)
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
	OnCancel = function(self, data)
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
for k, v in pairs(StaticPopupDialogs[staticPopups.LOOTDISTRIB]) do dialog[k] = v; end
dialog.extraButton = "Pass and unfavorite";
dialog.OnExtraButton = function(self, data)
    data.clicked = true;
    ABGP:PassOnItem(data.itemLink, true);
end
StaticPopupDialogs[staticPopups.LOOTDISTRIB_FAVORITE] = dialog;

local dialog = {};
for k, v in pairs(StaticPopupDialogs[staticPopups.LOOTDISTRIB]) do dialog[k] = v; end
dialog.text = "%s is being distributed! You may roll for it and provide an optional note.";
dialog.button1 = "Roll";
dialog.button2 = nil;
dialog.OnAccept = function(self, data)
    RandomRoll(1, 100);
    ABGP:RequestItem(data.itemLink, ABGP.RequestTypes.ROLL, self.editBox:GetText());
end
StaticPopupDialogs[staticPopups.LOOTDISTRIB_ROLL] = dialog;

local dialog = {};
for k, v in pairs(StaticPopupDialogs[staticPopups.LOOTDISTRIB_ROLL]) do dialog[k] = v; end
dialog.extraButton = "Pass and unfavorite";
dialog.OnExtraButton = function(self, data)
    data.clicked = true;
    ABGP:PassOnItem(data.itemLink, true);
end
StaticPopupDialogs[staticPopups.LOOTDISTRIB_ROLL_FAVORITE] = dialog;
