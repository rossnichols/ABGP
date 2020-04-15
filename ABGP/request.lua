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
local UnitExists = UnitExists;
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
        elt:SetCallback("OnClick", function(elt, event, button)
            if button == "RightButton" then
                if item.itemLink and ABGP:CanFavoriteItems() then
                    local faved = ABGP:IsItemFavorited(item.itemLink);
                    local context = {};
                    table.insert(context, {
                        text = faved and "Remove favorite" or "Add favorite",
                        func = function(self, data)
                            ABGP:SetItemFavorited(item.itemLink, not faved);
                            elt:SetData(data);
                        end,
                        arg1 = elt.data,
                        notCheckable = true
                    });
                    if elt.data.value then
                        table.insert(context, {
                            text = "Show item history",
                            func = function(self, data)
                                ABGP:ShowMainWindow({ command = ABGP.UICommands.ShowItemHistory, args = ABGP:GetItemName(data.itemLink), phase = data.value.phase })
                            end,
                            arg1 = elt.data,
                            notCheckable = true
                        });
                    end
                    table.insert(context, { text = "Cancel", notCheckable = true });
                    ABGP:ShowContextMenu(context);
                end
            else
                if not CloseStaticPopups(elt.data.itemLink) then
                    ShowStaticPopup(elt.data.itemLink, elt.data.value);
                end
            end
        end);

        container:AddChild(elt);
    end
end

function ABGP:GetActiveItem(itemLink)
    return activeItems[itemLink];
end

function ABGP:RequestOnGroupJoined()
    -- Check if any items are being actively distributed.
    -- Depending on the circumstances, the player may not
    -- be eligible for them, but it's still better to see.
    self:SendComm(self.CommTypes.ITEM_DISTRIBUTION_CHECK, {}, "BROADCAST");
end

local function VerifyItemRequests()
    for itemLink, item in pairs(activeItems) do
        if UnitExists(item.sender) then
            -- Ask the sender if the item is still being distributed.
            ABGP:SendComm(ABGP.CommTypes.ITEM_DISTRIBUTION_CHECK, { itemLink = itemLink }, "WHISPER", item.sender);
        else
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

function ABGP:RequestOnCheckResponse(data, distribution, sender)
    if not data.valid then
        self:RequestOnDistClosed({ itemLink = data.itemLink });
    end
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

    activeItems[itemLink] = {
        itemLink = itemLink,
        sender = sender,
        requestType = data.requestType,
        value = data.value,
    };
    table.insert(sortedItems, activeItems[itemLink]);

    local rank = self:GetItemRank(itemLink);
    if rank >= self.ItemRanks.NORMAL then
        local msg = ("%s: %s is open for distribution!"):format(self:ColorizeText("ABGP"), itemLink);
        _G.RaidNotice_AddMessage(_G.RaidWarningFrame, msg, { r = 1, g = 1, b = 1 });
        PlaySound(_G.SOUNDKIT.RAID_WARNING);
        FlashClientIcon();
    end

    local popup = GetStaticPopupType(itemLink);
    if popup == staticPopups.ABGP_LOOTDISTRIB_FAVORITE or popup == staticPopups.ABGP_LOOTDISTRIB_ROLL_FAVORITE then
        ShowStaticPopup(itemLink, data.value, popup);
    end

    local gpCost, priority, notes = "No GP cost (rolled)", "", "";
    local value = data.value;
    if value then
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

    local prompt = "";
    if self:Get("alwaysOpenWindow") or rank >= self.ItemRanks.NORMAL then
        self:ShowItemRequests(true);
    end
    if activeWindow then
        PopulateUI();
    else
        local keybinding = GetBindingKey("ABGP_SHOWITEMREQUESTS") or "<unbound>";
        prompt = ("Type '/abgp loot' or press your hotkey (%s) to open the request window."):format(keybinding);
    end
    self:Notify("Item distribution opened for %s! %s%s%s. %s", itemLink, gpCost, priority, notes, prompt);
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

function ABGP:RequestOnItemAwarded(data, distribution, sender)
    local itemLink = data.itemLink;

    local player = data.player;
    local cost = data.cost;
    local override = data.override;
    if data.testItem then override = "test"; end

    local multiple = "";
    if data.count > 1 then
        multiple = (" #%d"):format(data.count);
    end
    if activeItems[itemLink] then
        activeItems[itemLink].notified = true;
    end

    local requestTypes = {
        [ABGP.RequestTypes.MS] = " (%smain spec)",
        [ABGP.RequestTypes.OS] = " (%soff spec)",
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
        if self:IsItemFavorited(itemLink) and not data.testItem then
            self:SetItemFavorited(itemLink, false);
            unfaved = " Removed it from your AtlasLoot favorites.";
        end
        self:Notify("%s%s was awarded to you for %d GP%s!%s", itemLink, multiple, cost, requestType, unfaved);
    else
        local roll = "";
        if data.roll then
            roll = (" with a roll of %d"):format(data.roll);
        end
        self:Notify("%s%s was awarded to %s for %d GP%s%s.",
            itemLink, multiple, ABGP:ColorizeName(player), cost, requestType, roll);
    end
end

function ABGP:RequestOnItemTrashed(data, distribution, sender)
    local itemLink = data.itemLink;

    local info = "";
    if data.testItem then info = " (test)"; end

    local multiple = "";
    if data.count > 1 then
        multiple = (" #%d"):format(data.count);
    end
    if activeItems[itemLink] then
        activeItems[itemLink].notified = true;
    end

    self:Notify("%s%s will be disenchanted%s.", itemLink, multiple, info);
end

function ABGP:CreateRequestWindow()
    local window = AceGUI:Create("Window");
    window:SetTitle(("%s Active Items"):format(self:ColorizeText("ABGP")));
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

    return window;
end

function ABGP:ShowItemRequests(noAutoHide)
    if activeWindow then
        if not noAutoHide then activeWindow:Hide(); end
        return;
    end

    activeWindow = self:CreateRequestWindow();
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
    if ABGP:CanFavoriteItems() and not ABGP:IsItemFavorited(itemLink) then
        faveInfo = "To automatically show the request window for this item in the future, favorite it in AtlasLoot.";
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
        ABGP:SetItemFavorited(itemLink, false);
    end

    self:Notify("Passing on %s%s.", itemLink, faveRemove);
    activeItems[itemLink].sentComms = true;
    local elt = FindExistingElt(itemLink);
    if elt then
        SetEltText(elt);
        elt:SetData(elt.data);
    end
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
