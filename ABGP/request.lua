local activeItems = {};
local staticPopups = {
    ABGP_LOOTDISTRIB = "ABGP_LOOTDISTRIB",
    ABGP_LOOTDISTRIB_WISHLIST = "ABGP_LOOTDISTRIB_WISHLIST",
};

local function GetStaticPopupType(itemLink)
    local itemName = GetItemInfo(itemLink);
    local value = ABGP:GetItemValue(itemName);
    if value and value.onWishList then return staticPopups.ABGP_LOOTDISTRIB_WISHLIST; end
    return staticPopups.ABGP_LOOTDISTRIB;
end

local function ShowStaticPopup(itemLink, which)
    which = which or GetStaticPopupType(itemLink);
    local dialog = StaticPopup_Show(which, itemLink);
    if dialog then
        dialog.data = {
            itemLink = itemLink,
        };
    end
end

function ABGP:InitItemRequest()
    self.ActiveDistributions = 0;

    self:RegisterMessage(self.CommTypes.ITEM_DISTRIBUTION_OPENED, function(self, event, data, distribution, sender)
        local itemLink = data.itemLink;
        activeItems[itemLink] = sender;
        self.ActiveDistributions = self.ActiveDistributions + 1;

        local prompt = "";
        local popup = GetStaticPopupType(itemLink);
        if popup == staticPopups.ABGP_LOOTDISTRIB_WISHLIST then
            ShowStaticPopup(itemLink, which);
        else
            prompt = "Type '/abgp' if you want to request this item."
        end

        self:Notify("%s is being distributed! %s", itemLink, prompt);
    end, self);

    self:RegisterMessage(self.CommTypes.ITEM_DISTRIBUTION_CLOSED, function(self, event, data)
        local itemLink = data.itemLink;
        activeItems[itemLink] = nil;
        self.ActiveDistributions = self.ActiveDistributions - 1;
        self:Notify("Item distribution closed for %s.", itemLink);

        for index = 1, STATICPOPUP_NUMDIALOGS do
            local frame = _G["StaticPopup"..index];
            if frame:IsShown() and staticPopups[frame.which] then
                if frame.data.itemLink == itemLink then
                    frame:Hide();
                end
            end
        end
    end, self);

    -- TODO: figure out when the sender is no longer online?
    -- GROUP_ROSTER_UPDATE ?
end

function ABGP:PromptItemRequests()
    local found = false;
    for itemLink in pairs(activeItems) do
        ShowStaticPopup(itemLink);
        found = true;
    end

    if not found then
        self:Notify("There are no items being distributed.");
    end
end

function ABGP:RequestItem(itemLink, role, notes)
    if not activeItems[itemLink] then
        self:Notify("Unable to request %s - no longer being distributed.", itemLink);
        return;
    end
    local sender = activeItems[itemLink];

    local data = {
        type = self.CommTypes.ITEM_REQUEST,
        itemLink = itemLink,
        role = role,
        notes = (notes ~= "") and notes or nil,
        equipped = {},
    };
    local roles = {
        ["ms"] = "main spec",
        ["os"] = "off spec",
    };
    local itemMaps = {
        INVTYPE_2HWEAPON = { INVSLOT_MAINHAND, INVSLOT_OFFHAND },
        INVTYPE_AMMO = { INVSLOT_AMMO },
        INVTYPE_BODY = { INVSLOT_BODY },
        INVTYPE_CHEST = { INVSLOT_CHEST },
        INVTYPE_CLOAK = { INVSLOT_BACK },
        INVTYPE_FEET = { INVSLOT_FEET },
        INVTYPE_FINGER = { INVSLOT_FINGER1, INVSLOT_FINGER2 },
        INVTYPE_HAND = { INVSLOT_HAND },
        INVTYPE_HEAD = { INVSLOT_HEAD },
        INVTYPE_HOLDABLE = { INVSLOT_MAINHAND, INVSLOT_OFFHAND },
        INVTYPE_LEGS = { INVSLOT_LEGS },
        INVTYPE_NECK = { INVSLOT_NECK },
        INVTYPE_RANGED = { INVSLOT_RANGED },
        INVTYPE_RELIC = { INVSLOT_RANGED },
        INVTYPE_ROBE = { INVSLOT_CHEST },
        INVTYPE_SHIELD = { INVSLOT_MAINHAND, INVSLOT_OFFHAND },
        INVTYPE_SHOULDER = { INVSLOT_SHOULDER },
        INVTYPE_TABARD = { INVSLOT_TABARD },
        INVTYPE_TRINKET = { INVSLOT_TRINKET1, INVSLOT_TRINKET2 },
        INVTYPE_WAIST = { INVSLOT_WAIST },
        INVTYPE_WEAPON = { INVSLOT_MAINHAND, INVSLOT_OFFHAND },
        INVTYPE_WEAPONMAINHAND = { INVSLOT_MAINHAND, INVSLOT_OFFHAND },
        INVTYPE_WEAPONOFFHAND = { INVSLOT_MAINHAND, INVSLOT_OFFHAND },
        INVTYPE_WRIST = { INVSLOT_WRIST },
    };
    ABGP:Notify("Requesting %s for %s!", itemLink, role);
    local equipLoc = select(9, GetItemInfo(itemLink));
    if equipLoc and itemMaps[equipLoc] then
        local current1 = itemMaps[equipLoc][1] and GetInventoryItemLink("player", itemMaps[equipLoc][1]) or nil;
        local current2 = itemMaps[equipLoc][2] and GetInventoryItemLink("player", itemMaps[equipLoc][2]) or nil;
        if current1 then table.insert(data.equipped, current1); end
        if current2 then table.insert(data.equipped, current2); end
    end

    self:SendComm(data, "WHISPER", sender);
end

function ABGP:PassOnItem(itemLink, removeFromWishList)
    if not activeItems[itemLink] then
        self:Notify("Unable to pass on %s - no longer being distributed.", itemLink);
        return;
    end
    local sender = activeItems[itemLink];

    self:SendComm({
        type = self.CommTypes.ITEM_PASS,
        itemLink = itemLink,
    }, "WHISPER", sender);

    if removeFromWishList then
        ABGP:Notify("Passing on %s and removing from wish list.", itemLink);
    else
        ABGP:Notify("Passing on %s.", itemLink);
    end
end

StaticPopupDialogs[staticPopups.ABGP_LOOTDISTRIB] = {
    text = "%s is being distributed! You may request it and provide an optional note.",
    button1 = "Request (MS)",
    button2 = "Request (OS)",
    button3 = "Pass",
	hasEditBox = 1,
	maxLetters = 255,
	countInvisibleLetters = true,
    OnHyperlinkEnter = function(self, itemLink)
        ShowUIPanel(GameTooltip);
        GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR");
        GameTooltip:SetHyperlink(itemLink);
        GameTooltip:Show();
    end,
    OnHyperlinkLeave = function(self, itemLink)
        GameTooltip:Hide();
    end,
    EditBoxOnEscapePressed = function(self)
        self:SetAutoFocus(false);
		self:ClearFocus();
    end,
    OnHide = function(self, data)
        if not data.clicked and activeItems[data.itemLink] then
            ABGP:Notify("Request window hidden. To show again, type '/abgp'.");
        end
        self.editBox:SetAutoFocus(true);
    end,
	OnButton1 = function(self, data)
        data.clicked = true;
        ABGP:RequestItem(data.itemLink, "ms", self.editBox:GetText());
	end,
	OnCancel = function(self, data)
        data.clicked = true;
        ABGP:RequestItem(data.itemLink, "os", self.editBox:GetText());
	end,
	OnAlt = function(self, data)
        data.clicked = true;
        ABGP:PassOnItem(data.itemLink, false);
	end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    noCancelOnEscape = true,
    multiple = true,
};

StaticPopupDialogs[staticPopups.ABGP_LOOTDISTRIB_WISHLIST] = { unpack(StaticPopupDialogs[staticPopups.ABGP_LOOTDISTRIB]) };
local dialog = StaticPopupDialogs[staticPopups.ABGP_LOOTDISTRIB_WISHLIST];
dialog.extraButton = "Pass and remove from wish list";
dialog.OnExtraButton = function(self, data)
    data.clicked = true;
    ABGP:PassOnItem(data.itemLink, true);
end
