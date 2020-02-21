local _G = _G;
local ABGP = ABGP;
local AceGUI = _G.LibStub("AceGUI-3.0");

local PlaySound = PlaySound;
local FlashClientIcon = FlashClientIcon;
local UnitName = UnitName;
local GetItemInfo = GetItemInfo;
local GetInventoryItemLink = GetInventoryItemLink;
local RandomRoll = RandomRoll;
local GetBindingKey = GetBindingKey;
local table = table;
local pairs = pairs;
local select = select;
local time = time;
local ipairs = ipairs;

local activeWindow;
local activeItems = {};
local sortedItems = {};
local staticPopups = {
    ABGP_LOOTDISTRIB = "ABGP_LOOTDISTRIB",
    ABGP_LOOTDISTRIB_FAVORITE = "ABGP_LOOTDISTRIB_FAVORITE",
    ABGP_LOOTDISTRIB_ROLL = "ABGP_LOOTDISTRIB_ROLL",
    ABGP_LOOTDISTRIB_ROLL_FAVORITE = "ABGP_LOOTDISTRIB_ROLL_FAVORITE",
};

local function AtlasLootFaves()
    if _G.AtlasLoot and _G.AtlasLoot.Addons and _G.AtlasLoot.Addons.GetAddon then
        return _G.AtlasLoot.Addons:GetAddon("Favourites");
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

local function ShowStaticPopup(itemLink, which)
    which = which or GetStaticPopupType(itemLink);
    CloseStaticPopups(itemLink);
    if which then
        local dialog = _G.StaticPopup_Show(which, itemLink, nil, { itemLink = itemLink });
        if not dialog then
            ABGP:Error("Unable to open window for %s! Try closing other open ones.", itemLink);
        end
    end
end

local function FindExistingElt(itemLink)
    if not activeWindow then return; end
    local window = activeWindow;
    local container = window:GetUserData("itemsContainer");

    for _, elt in ipairs(container.children) do
        if elt.data and elt.data.itemLink == itemLink then
            return elt;
        end
    end
end

local function SetEltText(elt)
    local item = activeItems[elt.data.itemLink];
    if item then
        local text = "Show";
        if item.dialogShown then
            text = "Hide";
        elseif item.sentComms then
            text = "Update";
        end
        elt:SetText(text);
    end
end

local function PopulateUI()
    if not activeWindow then return; end
    local window = activeWindow;
    local container = window:GetUserData("itemsContainer");
    container:ReleaseChildren();

    for _, item in ipairs(sortedItems) do
        local elt = AceGUI:Create("ABGP_Item");
        elt:SetFullWidth(true);
        elt:SetData(item);
        SetEltText(elt);
        elt:SetCallback("OnClick", function(elt)
            if not CloseStaticPopups(elt.data.itemLink) then
                ShowStaticPopup(elt.data.itemLink);
            end
        end);

        container:AddChild(elt);
    end
end

function ABGP:RequestOnGroupJoined()
    self:SendComm(self.CommTypes.ITEM_DISTRIBUTION_CHECK, {}, "BROADCAST");
end

function ABGP:RequestOnItemRolled(data, distribution, sender)
    self:Notify("You rolled %d on %s.", data.roll, data.itemLink);
end

function ABGP:RequestOnDistOpened(data, distribution, sender)
    local itemLink = data.itemLink;
    activeItems[itemLink] = {
        itemLink = itemLink,
        sender = sender,
        requestType = data.requestType
    };
    table.insert(sortedItems, activeItems[itemLink]);

    local msg;
    local value = data.value;
    if value then
        local notes = "";
        if value.notes then
            notes = ", Notes: " .. value.notes
        end
        if value.gp == 0 then
            msg = ("Now distributing %s! No GP cost, Priority: %s%s."):format(
                itemLink, table.concat(value.priority, ", "), notes);
        else
            msg = ("Now distributing %s! GP cost: %d, Priority: %s%s."):format(
                itemLink, value.gp, table.concat(value.priority, ", "), notes);
        end
    else
        msg = ("Now distributing %s! No GP cost."):format(itemLink);
    end

    _G.RaidNotice_AddMessage(_G.RaidWarningFrame, msg, ABGP.ColorTable);
    PlaySound(_G.SOUNDKIT.RAID_WARNING);
    FlashClientIcon();

    local prompt = "";
    local popup = GetStaticPopupType(itemLink);
    if popup == staticPopups.ABGP_LOOTDISTRIB_FAVORITE or popup == staticPopups.ABGP_LOOTDISTRIB_ROLL_FAVORITE then
        ShowStaticPopup(itemLink, popup);
    end

    self:Notify("Item distribution opened for %s!", itemLink);

    if #sortedItems == 1 then
        self:ShowItemRequests();
    end
    if activeWindow then
        PopulateUI();
    end
end

function ABGP:RequestOnDistClosed(data, distribution, sender)
    local itemLink = data.itemLink;
    if activeItems[itemLink] then
        if not activeItems[itemLink].notified then
            self:Notify("Item distribution closed for %s.", itemLink);
        end

        CloseStaticPopups(itemLink);
        for i, item in ipairs(sortedItems) do
            if item == activeItems[itemLink] then
                table.remove(sortedItems, i);
                break;
            end
        end
        activeItems[itemLink] = nil;

        if activeWindow then
            if #sortedItems == 0 then
                activeWindow:Hide();
            else
                PopulateUI();
            end
        end
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
            multiple = (" #%d"):format(activeItems[itemLink].notified);
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
            multiple = (" #%d"):format(activeItems[itemLink].notified);
        else
            activeItems[itemLink].notified = 1;
        end
    end

    self:Notify("%s%s will be disenchanted.", itemLink, multiple);
end

function ABGP:ShowItemRequests()
    if activeWindow then
        activeWindow:Hide();
        return;
    end

    local window = AceGUI:Create("Window");
    window:SetTitle(("%s Item Requests"):format(self:ColorizeText("ABGP")));
    window:SetLayout("Flow");
    self:BeginWindowManagement(window, "request", {
        version = 1,
        defaultWidth = 325,
        minWidth = 250,
        maxWidth = 400,
        defaultHeight = 175,
        minHeight = 100,
        maxHeight = 300
    });
    self:OpenWindow(window);
    window:SetCallback("OnClose", function(widget)
        ABGP:EndWindowManagement(window);
        ABGP:CloseWindow(widget);
        AceGUI:Release(widget);
        activeWindow = nil;
    end);

    local scrollContainer = AceGUI:Create("SimpleGroup");
    scrollContainer:SetFullWidth(true);
    scrollContainer:SetFullHeight(true);
    scrollContainer:SetLayout("Flow");
    window:AddChild(scrollContainer);

    local scroll = AceGUI:Create("ScrollFrame");
    scroll:SetFullWidth(true);
    scroll:SetFullHeight(true);
    scroll:SetLayout("List");
    scrollContainer:AddChild(scroll);
    window:SetUserData("itemsContainer", scroll);

    activeWindow = window;
    PopulateUI();
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

    if activeItems[itemLink].sentComms and activeItems[itemLink].sentRequest then
        self:Notify("Updated request for %s.", itemLink);
    else
        self:Notify("Requesting %s %s! %s", itemLink, requestTypes[requestType], faveInfo);
    end

    self:SendComm(self.CommTypes.ITEM_REQUEST, data, "WHISPER", sender);
    activeItems[itemLink].sentComms = true;
    activeItems[itemLink].sentRequest = true;
    local elt = FindExistingElt(itemLink);
    if elt then
        SetEltText(elt);
    end
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

    self:Notify("Passing on %s%s.", itemLink, faveRemove);
    activeItems[itemLink].sentComms = true;
    local elt = FindExistingElt(itemLink);
    if elt then
        SetEltText(elt);
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
        if activeItems[data.itemLink] then
            activeItems[data.itemLink].dialogShown = true;
            local elt = FindExistingElt(data.itemLink);
            if elt then
                SetEltText(elt);
            end
        end
	end,
    EditBoxOnEscapePressed = function(self)
		self:ClearFocus();
    end,
    OnHide = function(self, data)
        self.editBox:SetAutoFocus(true);
        if activeItems[data.itemLink] then
            activeItems[data.itemLink].dialogShown = false;
            local elt = FindExistingElt(data.itemLink);
            if elt then
                SetEltText(elt);
            end
        end
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
    data.clicked = true;
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
    data.clicked = true;
    ABGP:PassOnItem(data.itemLink, true);
end
StaticPopupDialogs[staticPopups.ABGP_LOOTDISTRIB_ROLL_FAVORITE] = dialog;
