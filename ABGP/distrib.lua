local _G = _G;
local ABGP = _G.ABGP;
local AceGUI = _G.LibStub("AceGUI-3.0");

local UnitExists = UnitExists;
local UnitName = UnitName;
local IsShiftKeyDown = IsShiftKeyDown;
local IsControlKeyDown = IsControlKeyDown;
local GetServerTime = GetServerTime;
local IsMasterLooter = IsMasterLooter;
local GiveMasterLoot = GiveMasterLoot;
local GetMasterLootCandidate = GetMasterLootCandidate;
local GetLootInfo = GetLootInfo;
local GetNumLootItems = GetNumLootItems;
local IsInRaid = IsInRaid;
local GetLootSlotLink = GetLootSlotLink;
local table = table;
local ipairs = ipairs;
local pairs = pairs;
local tonumber = tonumber;
local unpack = unpack;
local math = math;
local type = type;
local max = max;

local activeDistributionWindow;
local prioritizeByRank = false;
local widths = { 110, 100, 90, 40, 40, 1.0 };

local function CalculateCost(request)
    local returnedCost = { cost = 0 };
    local window = activeDistributionWindow;
    local currentItem = window:GetUserData("currentItem");

    if not currentItem.value then
        return returnedCost, false, "no value";
    end
    returnedCost.category = currentItem.value.category;

    if request and request.override then
        return returnedCost, false, request.override;
    end

    returnedCost.cost = currentItem.costBase.cost;
    returnedCost.category = currentItem.costBase.category;
    if request then
        if request.requestType == ABGP.RequestTypes.MS then
            if request.selectedItem then
                local selectedValue = ABGP:GetItemValue(ABGP:GetItemId(request.selectedItem));
                if selectedValue then
                    returnedCost.cost = selectedValue.gp;
                    returnedCost.category = selectedValue.category;
                end
            end
        else
            returnedCost.cost = 0;
        end
    end

    if currentItem.selectedItem then
        local selectedValue = ABGP:GetItemValue(ABGP:GetItemId(currentItem.selectedItem));
        if selectedValue then
            returnedCost.cost = selectedValue.gp;
            returnedCost.category = selectedValue.category;
        end
    end

    return currentItem.costEdited or returnedCost, true;
end

local function ProcessSelectedRequest()
    local window = activeDistributionWindow;
    local currentItem = window:GetUserData("currentItem");
    local selected = currentItem.selectedRequest;

    window:GetUserData("disenchantButton"):SetDisabled(selected ~= nil);
    window:GetUserData("distributeButton"):SetDisabled(selected == nil);

    local cost, editable, reason = CalculateCost(selected);
    local edit = window:GetUserData("costEdit");
    edit:SetValue(reason or cost.cost);
    edit:SetDisabled(not editable);
    local selector = window:GetUserData("categorySelector");
    if cost.category then selector:SetText(ABGP.ItemCategoryNames[cost.category]); end
    selector:SetDisabled(not editable);
    ABGP:LogDebug("Calculated cost: %s", ABGP:FormatCost(cost));
end

local function AwardItem(request)
    if not activeDistributionWindow then return; end
    local window = activeDistributionWindow;
    local currentItem = window:GetUserData("currentItem");
    request = request or currentItem.selectedRequest;

    local player = request.player;
    local cost = CalculateCost(request);

    local itemLink = currentItem.itemLink;
    if currentItem.totalCount > 1 then
        local count = #currentItem.distributions;
        itemLink = ("%s #%d"):format(itemLink, count + 1);
    end
    local award = ("%s for %s"):format(ABGP:ColorizeName(player), ABGP:FormatCost(cost));

    _G.StaticPopup_Show("ABGP_CONFIRM_DIST", request.selectedItem or itemLink, award, {
        itemLink = currentItem.itemLink,
        selectedItem = request.selectedItem,
        player = player,
        cost = cost,
        roll = request.roll,
        requestType = request.requestType,
        override = request.override,
    });
end

local function RebuildUI()
    local window = activeDistributionWindow;
    local currentItem = window:GetUserData("currentItem");
    local requests = currentItem.requests;
    local requestsContainer = window:GetUserData("requestsContainer");
    requestsContainer:ReleaseChildren();

    if not currentItem.receivedComm then
        local elt = AceGUI:Create("ABGP_Header");
        elt:SetFullWidth(true);
        elt:SetJustifyH("CENTER");
        elt:SetText(ABGP:ColorizeText("Waiting for distribution confirmation..."));
        requestsContainer:AddChild(elt);
    end

    local requestTypes = {
        [ABGP.RequestTypes.MS] = 1,
        [ABGP.RequestTypes.OS] = 2,
    };

    table.sort(requests, function(a, b)
        local aRollRequired = ABGP:ItemRequiresRoll(currentItem.itemLink, a.selectedItem, a.requestType);
        local bRollRequired = ABGP:ItemRequiresRoll(currentItem.itemLink, b.selectedItem, b.requestType);

        if a.requestType ~= b.requestType then
            return requestTypes[a.requestType] < requestTypes[b.requestType];
        elseif a.rankPriority ~= b.rankPriority then
            return a.rankPriority < b.rankPriority;
        elseif aRollRequired ~= bRollRequired then
            return bRollRequired;
        elseif a.category ~= b.category and not aRollRequired then
            return a.category == ABGP.ItemCategory.GOLD;
        elseif a.priority ~= b.priority and not aRollRequired then
            return a.priority > b.priority;
        elseif a.roll ~= b.roll then
            return (a.roll or 0) > (b.roll or 0);
        else
            return a.player < b.player;
        end
    end);

    local selectedRequest = currentItem.selectedRequest;
    currentItem.selectedRequest = nil;
    currentItem.selectedElt = nil;
    ProcessSelectedRequest();

    local typeHeadings = {
        [ABGP.RequestTypes.MS] = "Main Spec",
        [ABGP.RequestTypes.OS] = "Off Spec",
    };

    local currentHeading, currentRankPriority;
    local maxRolls = {};
    for i, request in ipairs(requests) do
        local heading = typeHeadings[request.requestType];
        if currentHeading ~= heading or currentRankPriority ~= request.rankPriority then
            currentHeading = heading;
            currentRankPriority = request.rankPriority;
            local elt = AceGUI:Create("Heading");
            elt:SetFullWidth(true);
            elt:SetText(("|cffffffff%s|r"):format(heading));
            requestsContainer:AddChild(elt);
        end

        request.currentMaxRoll = false;

        local elt = AceGUI:Create("ABGP_Player");
        elt:SetFullWidth(true);
        local lowPrio;
        local active = ABGP:GetActivePlayer(request.player);
        if active and not active.trial and request.ep and currentItem.value then
            lowPrio = request.ep < ABGP:GetMinEP();
        end
        local equippable = ABGP:GetItemEquipSlots(currentItem.itemLink) or (currentItem.value and currentItem.value.token);
        elt:SetData(request, equippable, lowPrio);
        elt:SetWidths(widths);
        elt:ShowBackground((i % 2) == 0);
        elt:SetCallback("OnClick", function(elt, event, button)
            if button == "RightButton" then
                local cost = CalculateCost(elt.data);
                ABGP:ShowContextMenu({
                    {
                        text = ("Award for %s"):format(ABGP:FormatCost(cost)),
                        func = function(self, request)
                            AwardItem(request);
                        end,
                        arg1 = elt.data,
                        notCheckable = true
                    },
                    {
                        text = "Whisper",
                        func = function(self, request)
                            _G.ChatFrame_OpenChat(("/t %s "):format(request.player));
                        end,
                        arg1 = elt.data,
                        notCheckable = true
                    },
                    {
                        text = "REJECT",
                        func = function(self, request)
                            _G.StaticPopup_Show("ABGP_CONFIRM_REJECT", ABGP:ColorizeName(request.player), request.itemLink, request);
                        end,
                        arg1 = elt.data,
                        notCheckable = true
                    },
                    { text = "Cancel", notCheckable = true, fontObject = "GameFontDisableSmall" },
                });
            else
                local currentItem = window:GetUserData("currentItem");
                local oldElt = currentItem.selectedElt;
                if oldElt then
                    oldElt.frame:RequestHighlight(false);
                end

                local oldRequest = currentItem.selectedRequest;
                if not oldRequest or oldRequest.player ~= elt.data.player then
                    currentItem.selectedRequest = elt.data;
                    currentItem.selectedElt = elt;
                    elt.frame:RequestHighlight(true);
                else
                    currentItem.selectedRequest = nil;
                    currentItem.selectedElt = nil;
                end

                ProcessSelectedRequest();
                ABGP:HideContextMenu();
            end
        end);

        requestsContainer:AddChild(elt);

        if selectedRequest and request.player == selectedRequest.player then
            elt:Fire("OnClick");
        end

        if request.roll then
            local reqType = request.requestType;
            if not maxRolls[reqType] then
                maxRolls[reqType] = { roll = request.roll, elts = { elt } };
            elseif request.roll > maxRolls[reqType].roll then
                maxRolls[reqType] = { roll = request.roll, elts = { elt } };
            elseif request.roll == maxRolls[reqType].roll then
                table.insert(maxRolls[reqType].elts, elt);
            end
        end
    end

    for _, rolls in pairs(maxRolls) do
        for _, elt in ipairs(rolls.elts) do
            elt.data.currentMaxRoll = true;
            local lowPrio;
            local active = ABGP:GetActivePlayer(elt.data.player);
            if active and not active.trial and elt.data.ep and currentItem.value then
                lowPrio = elt.data.ep < ABGP:GetMinEP();
            end
            local equippable = ABGP:GetItemEquipSlots(currentItem.itemLink) or (currentItem.value and currentItem.value.token);
            elt:SetData(elt.data, equippable, lowPrio);
        end
    end

    local multiple = window:GetUserData("itemCountDropdown");
    local minCount = math.max(1, #currentItem.distributions + 1);
    local maxCount = math.max(5, currentItem.totalCount);
    local values = {};
    for i = minCount, maxCount do values[i] = i; end
    multiple:SetList(values);
    multiple:SetValue(currentItem.totalCount);
    multiple:SetText(("Count: %s"):format(currentItem.totalCount));
    local itemLink = currentItem.itemLink;
    local tabs = window:GetUserData("tabs");
    local tabGroup = window:GetUserData("tabGroup");
    for _, tab in ipairs(tabs) do
        if tab.value == itemLink then
            tab.text = (currentItem.totalCount == 1)
                and ABGP:GetItemName(itemLink)
                or ("%s %d/%d"):format(ABGP:GetItemName(itemLink), #currentItem.distributions + 1, currentItem.totalCount);
        end
    end
    tabGroup:SetTabs(tabs);

    local test = window:GetUserData("testCheckbox");
    test:SetValue(currentItem.testItem);

    local resetRolls = window:GetUserData("resetRollsButton");
    resetRolls:SetText(currentItem.rollsAllowed and "Reset Rolls" or "Allow Rolls");
    ABGP:AddWidgetTooltip(resetRolls, currentItem.rollsAllowed
        and "Reset the recorded rolls for everyone (e.g., in case of a tie). Ask the appropriate players to /roll."
        or "Start recording rolls made by players who requested this item.");

    window:SetTitle(("Loot Distribution: |cffffffff%s|r"):format(ABGP:GetItemName(currentItem.itemLink)));

    local itemRef = window:GetUserData("itemRef");
    itemRef:SetText(currentItem.itemLink);
    itemRef:SetWidth(itemRef.text:GetStringWidth() + 5);
    window:GetUserData("topLine"):DoLayout();

    local related = ABGP:GetTokenItems(currentItem.itemLink);
    local relatedElts = window:GetUserData("relatedItems");
    for k, elt in pairs(relatedElts) do
        AceGUI:Release(elt);
        relatedElts[k] = nil;
    end
    if related then
        for i = #related, 1, -1 do
            local itemLink = related[i];
            local button = AceGUI:Create("ABGP_ItemButton");
            relatedElts[i] = button;
            button:SetItemLink(itemLink, false);
            button:SetClickable(true);
            button:SetCallback("OnClick", function(widget, event, button)
                for _, button in pairs(relatedElts) do
                    if button ~= widget then
                        button.frame:SetChecked(false);
                    end
                end

                currentItem.selectedItem = widget.frame:GetChecked() and itemLink or nil;
                RebuildUI();
            end);
            button.frame:SetParent(itemRef.frame);
            button.frame:SetScale(0.5);
            button.frame:SetChecked(itemLink == currentItem.selectedItem);

            if i == #related then
                button.frame:SetPoint("TOPRIGHT", itemRef.frame, "BOTTOMRIGHT", -3, 0);
            else
                button.frame:SetPoint("RIGHT", relatedElts[i+1].frame, "LEFT", -8, 0);
            end
        end
    end

    window:GetUserData("chooseButton"):SetDisabled(related and not currentItem.selectedItem);

    ABGP:HideContextMenu();
end

local function GetRequestCounts(requests)
    local total, main, off = #requests, 0, 0;

    for _, request in ipairs(requests) do
        if request.requestType == ABGP.RequestTypes.MS then main = main + 1; end
        if request.requestType == ABGP.RequestTypes.OS then off = off + 1; end
    end

    return total, main, off;
end

local function RemoveRequest(sender, itemLink, silent)
    local window = activeDistributionWindow;
    local activeItems = window:GetUserData("activeItems");
    local requests = activeItems[itemLink].requests;
    local currentItem = window:GetUserData("currentItem");

    for i, request in ipairs(requests) do
        if request.player == sender then
            table.remove(requests, i);
            if not silent then
                ABGP:Notify("%s is now passing on %s.", ABGP:ColorizeName(sender), itemLink);
            end
            local total, main, off = GetRequestCounts(requests);
            ABGP:SendComm(ABGP.CommTypes.ITEM_REQUESTCOUNT, {
                itemLink = itemLink,
                count = total,
                main = main,
                off = off,
            }, "BROADCAST");
            break;
        end
    end

    if itemLink == currentItem.itemLink then
        RebuildUI();
    end
end

local function CombineNotes(a, b)
    if not a then return b; end
    if not b then return a; end
    return a .. "\n" .. b;
end

function ABGP:ItemRequiresRoll(itemLink, selectedItem, requestType)
    if requestType and requestType == self.RequestTypes.OS then return true; end
    local value = ABGP:GetItemValue(ABGP:GetItemId(itemLink));
    if not value or value.gp == 0 then return true; end
    if not selectedItem then return false; end

    local selectedValue = ABGP:GetItemValue(ABGP:GetItemId(selectedItem));
    return not selectedValue or selectedValue.gp == 0;
end

local function ProcessNewRequest(request, summary)
    local window = activeDistributionWindow;
    local activeItems = window:GetUserData("activeItems");
    local item = activeItems[request.itemLink];
    local requests = item.requests;
    local oldRequest;

    for i, existing in ipairs(requests) do
        if existing.player == request.player then
            oldRequest = existing;
            request.notes = CombineNotes(existing.notes, request.notes);
            table.remove(requests, i);
            break;
        end
    end

    -- Restore roll if we've previously recorded one
    if item.rolls[request.player] then
        request.roll = item.rolls[request.player];
    end

    -- Generate a new roll if necessary
    if ABGP:ItemRequiresRoll(item.itemLink, request.selectedItem, request.requestType) then
        request.roll = request.roll or math.random(1, 100);
    end

    -- Tell the requester what they rolled.
    if request.roll and UnitExists(request.player) then
        ABGP:SendComm(ABGP.CommTypes.ITEM_ROLLED, {
            itemLink = request.itemLink,
            selectedItem = request.selectedItem,
            roll = request.roll,
        }, "WHISPER", request.player);
    end

    -- Persist the roll
    item.rolls[request.player] = request.roll;

    -- Persist the equipped items (for requests that come in without them)
    if oldRequest and oldRequest.equipped and not request.equipped then
        request.equipped = oldRequest.equipped;
    end

    table.insert(requests, request);
    if not oldRequest or oldRequest.requestType ~= request.requestType then
        local requestTypes = {
            [ABGP.RequestTypes.MS] = "for main spec",
            [ABGP.RequestTypes.OS] = "for off spec",
        };
        ABGP:Notify("%s is requesting %s %s.", ABGP:ColorizeName(request.player), request.itemLink, requestTypes[request.requestType]);

        local total, main, off = GetRequestCounts(requests);
        local commData = {
            itemLink = request.itemLink,
            count = total,
            main = main,
            off = off,
        };
        if summary then
            table.insert(summary, { ABGP.CommTypes.ITEM_REQUESTCOUNT.name, commData });
        else
            ABGP:SendComm(ABGP.CommTypes.ITEM_REQUESTCOUNT, commData, "BROADCAST");
        end
    end

    if request.itemLink == window:GetUserData("currentItem").itemLink then
        RebuildUI();
    end
end

local function FindExistingElt(sender)
    local requests = activeDistributionWindow:GetUserData("requestsContainer");
    for _, elt in ipairs(requests.children) do
        if elt.data and elt.data.player == sender then
            return elt;
        end
    end
end

function ABGP:DistribOnRoll(sender, roll)
    if not activeDistributionWindow then return; end
    local currentItem = activeDistributionWindow:GetUserData("currentItem");

    if currentItem.rollsAllowed then
        local elt = FindExistingElt(sender);
        if elt and not elt.data.roll then
            elt.data.roll = roll;
            currentItem.rolls[elt.data.player] = roll;
            self:SendComm(self.CommTypes.ITEM_ROLLED, {
                itemLink = currentItem.itemLink,
                selectedItem = elt.data.selectedItem,
                roll = roll,
            }, "WHISPER", sender);
            RebuildUI();
        end
    end
end

local function AddActiveItem(data)
    local window = activeDistributionWindow;
    local activeItems = window:GetUserData("activeItems");
    local itemLink = data.itemLink;
    local value = ABGP:GetItemValue(ABGP:GetItemName(data.itemLink));

    local newItem = {
        itemLink = itemLink,
        requests = {},
        rolls = {},
        value = value,
        costBase = value and { cost = (value.token and 0 or value.gp), category = value.category } or { cost = 0 },
        selectedRequest = nil,
        selectedElt = nil,
        selectedItem = nil,
        costEdited = nil,
        closeConfirmed = false,
        distributions = {},
        rollsAllowed = ABGP:ItemRequiresRoll(itemLink),
        data = data,
        receivedComm = false,
        testItem = not IsInRaid(),
        totalCount = data.count or 1,
    };

    activeItems[itemLink] = newItem;

    local tabs = window:GetUserData("tabs");
    table.insert(tabs, { value = itemLink, text = ABGP:GetItemName(itemLink) });
    local tabGroup = window:GetUserData("tabGroup");
    tabGroup:SetTabs(tabs);
    tabGroup:SelectTab(itemLink);
end

local function RemoveActiveItem(itemLink, item)
    if activeDistributionWindow then
        local window = activeDistributionWindow;
        local activeItems = window:GetUserData("activeItems");
        local currentItem = window:GetUserData("currentItem");

        item = activeItems[itemLink];
        activeItems[itemLink] = nil;
        local tabs = window:GetUserData("tabs");
        local removedIndex = 0;
        for i, tab in ipairs(tabs) do
            if tab.value == itemLink then
                removedIndex = i;
                table.remove(tabs, removedIndex);
                break;
            end
        end

        local tabGroup = window:GetUserData("tabGroup");
        tabGroup:SetTabs(tabs);
        if currentItem.itemLink == itemLink then
            if #tabs > 0 then
                tabGroup:SelectTab(tabs[max(1, removedIndex - 1)].value);
            else
                window:Hide();
            end
        end
    end

    ABGP:SendComm(ABGP.CommTypes.ITEM_DIST_CLOSED, {
        itemLink = itemLink,
        count = #item.distributions
    }, "BROADCAST");
end

local function ChooseRecipient()
    if not activeDistributionWindow then return; end
    local window = activeDistributionWindow;
    local currentItem = window:GetUserData("currentItem");
    local cost = CalculateCost();

    local itemLink = currentItem.itemLink;
    if currentItem.totalCount > 1 then
        local count = #currentItem.distributions;
        itemLink = ("%s #%d"):format(itemLink, count + 1);
    end

    _G.StaticPopup_Show("ABGP_CHOOSE_RECIPIENT", currentItem.selectedItem or itemLink, ABGP:FormatCost(cost), {
        itemLink = currentItem.itemLink,
        selectedItem = currentItem.selectedItem,
        cost = cost,
        value = currentItem.value,
        requestType = ABGP.RequestTypes.MANUAL
    });
end

function ABGP:DistribValidateRecipient(player, cost)
    if cost and cost.cost ~= 0 and not self:GetActivePlayer(player) then
        return false, "The player must have EPGP";
    end

    if not player or player == "" then
        return false, "Must enter a player";
    end

    return player;
end

function ABGP:DistribValidateCost(cost, player)
    cost = tonumber(cost);
    if type(cost) ~= "number" then return false, "Not a number"; end
    if cost < 0 then return false, "Can't be negative"; end
    if math.floor(cost) ~= cost then return false, "Must be a whole number"; end

    if player then
        if cost ~= 0 and not self:GetActivePlayer(player) then
            return false, "The player must have EPGP";
        end
    end

    return cost;
end

function ABGP:GiveItemViaML(itemLink, player)
    if self:Get("masterLoot") and IsMasterLooter() and player then
        player = player:lower();
        local itemName = self:GetItemName(itemLink);
        local slot;

        local loot = GetLootInfo();
        for i = 1, GetNumLootItems() do
            local item = loot[i];
            if item and item.item == itemName then
                slot = i;
                break;
            end
        end

        if slot then
            for i = 1, _G.MAX_RAID_MEMBERS do
                local candidate = GetMasterLootCandidate(slot, i);
                if candidate and candidate:lower() == player then
                    GiveMasterLoot(slot, i);
                    return;
                end
            end
        end

        player = UnitName(player) or player;
        self:Error("Couldn't ML %s to %s!", itemLink, self:ColorizeName(player));
    end
end

local function DistributeItem(data)
    if not activeDistributionWindow then return; end
    local window = activeDistributionWindow;
    local activeItems = window:GetUserData("activeItems");

    local currentItem = activeItems[data.itemLink];
    table.insert(currentItem.distributions, {
        player = data.player,
    });

    local historyId = ABGP:GetHistoryId();
    local commData = {
        itemLink = data.itemLink,
        selectedItem = data.selectedItem,
        player = data.player,
        cost = data.cost,
        roll = data.roll,
        requestType = data.requestType,
        override = data.override,
        count = #currentItem.distributions,
        testItem = currentItem.testItem,
        historyId = historyId,
        awarded = GetServerTime(),
    };
    ABGP:SendComm(ABGP.CommTypes.ITEM_AWARDED, commData, "BROADCAST");

    if #currentItem.distributions < currentItem.totalCount then
        RebuildUI();
    else
        RemoveActiveItem(data.itemLink);
    end
end

function ABGP:DistribOnStateSync(data, distribution, sender)
    local window = activeDistributionWindow;
    local activeItems = window and window:GetUserData("activeItems") or {};

    local summary = {};
    for _, item in pairs(activeItems) do
        local total, main, off = GetRequestCounts(item.requests);
        local senderRequest;
        for _, request in ipairs(item.requests) do
            if request.player == sender then
                senderRequest = request;
                break;
            end
        end

        table.insert(summary, { self.CommTypes.ITEM_DIST_OPENED.name, item.data });
        table.insert(summary, { self.CommTypes.ITEM_COUNT.name, {
            itemLink = item.itemLink,
            count = item.totalCount,
        }});
        table.insert(summary, { self.CommTypes.ITEM_REQUESTCOUNT.name, {
            itemLink = item.itemLink,
            count = total,
            main = main,
            off = off
        }});
        if senderRequest then
            table.insert(summary, { self.CommTypes.ITEM_REQUEST_RECEIVED.name, {
                itemLink = item.itemLink,
                selectedItem = senderRequest.selectedItem,
                requestType = senderRequest.requestType,
            }});
            if item.rolls[sender] then
                table.insert(summary, { self.CommTypes.ITEM_ROLLED.name, {
                    itemLink = item.itemLink,
                    selectedItem = senderRequest.selectedItem,
                    roll = item.rolls[sender],
                }});
            end
        end
    end

    if #summary > 0 then
        self:SendComm(self.CommTypes.ITEM_DIST_SUMMARY, summary, "WHISPER", sender);
    end
end

local function PopulateRequest(request, value)
    local override;
    local rank, class;
    local priority, ep, gp;
    local category;
    local rankPriority = math.huge;

    if request.testContent then
        priority = request.priority;
        ep = request.ep;
        gp = request.gp;
        rank = request.rank;
        class = request.class;
        override = request.override;
        rankPriority = ABGP:GetRankPriority(rank);
        if not prioritizeByRank and rankPriority ~= math.huge then
            rankPriority = 0;
        end
    else
        local epgp = ABGP:GetActivePlayer(request.player);
        if epgp then
            rank = epgp.rank;
            class = epgp.class;
            if epgp.trial then
                override = "trial";
            end
        else
            local guildInfo = ABGP:GetGuildInfo(request.player);
            if guildInfo then
                rank = guildInfo[2];
                class = guildInfo[11];
            end
        end

        if value then
            priority, ep, gp = 0, 0, 0;
            if epgp then
                ep = epgp.ep;
                gp = epgp.gp[value.category];
                category = value.category;
                priority = epgp.priority[value.category];

                if request.selectedItem then
                    local selectedValue = ABGP:GetItemValue(ABGP:GetItemId(request.selectedItem));
                    if selectedValue then
                        priority = epgp.priority[selectedValue.category];
                        gp = epgp.gp[selectedValue.category];
                        category = selectedValue.category;
                    end
                end
            elseif not override then
                override = "non-raider";
            end
        end

        if epgp and rank and value then
            rankPriority = prioritizeByRank and ABGP:GetRankPriority(rank) or 0;
        end
    end

    local needsUpdate = false;
    local function checkValue(t, k, v)
        local old = t[k];
        if old ~= v then
            t[k] = v;
            needsUpdate = true;
        end
    end

    checkValue(request, "priority", priority);
    checkValue(request, "category", category);
    checkValue(request, "ep", ep);
    checkValue(request, "gp", gp);
    checkValue(request, "rank", rank);
    checkValue(request, "class", class);
    checkValue(request, "rankPriority", rankPriority);
    checkValue(request, "override", override);
    return needsUpdate;
end

local function RepopulateRequests()
    if not activeDistributionWindow then return false; end
    local activeItems = activeDistributionWindow:GetUserData("activeItems");

    local needsUpdate = false;
    for _, item in pairs(activeItems) do
        local value = item.value;
        if value then
            for _, request in ipairs(item.requests) do
                if PopulateRequest(request, value) then
                    needsUpdate = true;
                end
            end
        end
    end

    return needsUpdate;
end

function ABGP:DistribOnItemRequest(data, distribution, sender, version)
    local itemLink = data.itemLink;
    local window = activeDistributionWindow;
    if not window then return; end

    -- Check if the sender is grouped with us
    if not UnitExists(sender) then return; end

    local activeItems = window:GetUserData("activeItems");
    if not activeItems[itemLink] then
        ABGP:Error("%s requested %s but it's not being distributed!", ABGP:ColorizeName(sender), itemLink);
        return;
    end

    local request = {
        itemLink = itemLink,
        player = sender,
        equipped = data.equipped,
        requestType = data.requestType,
        selectedItem = data.selectedItem,
        notes = data.notes,
        version = version
    };
    PopulateRequest(request, activeItems[itemLink].value);

    self:SendComm(self.CommTypes.ITEM_REQUEST_RECEIVED, {
        itemLink = itemLink,
        selectedItem = data.selectedItem,
        requestType = data.requestType,
    }, "WHISPER", sender);
    ProcessNewRequest(request);
end

function ABGP:DistribOnItemPass(data, distribution, sender)
    local itemLink = data.itemLink;
    if not activeDistributionWindow then return; end

    -- Check if the sender is grouped with us
    if not UnitExists(sender) then return; end

    local activeItems = activeDistributionWindow:GetUserData("activeItems");
    if not activeItems[itemLink] then
        ABGP:Error("%s passed on %s but it's not being distributed!", ABGP:ColorizeName(sender), itemLink);
        return;
    end

    self:SendComm(self.CommTypes.ITEM_REQUEST_RECEIVED, {
        itemLink = itemLink,
        selectedItem = data.selectedItem,
    }, "WHISPER", sender);
    RemoveRequest(sender, itemLink);
end

function ABGP:DistribOnActivePlayersRefreshed()
    if RepopulateRequests() then
        RebuildUI();
    end
end

local function EndDistribution()
    if not activeDistributionWindow then return; end
    local window = activeDistributionWindow;

    for _, item in pairs(window:GetUserData("activeItems")) do
        item.closeConfirmed = true;
    end
    window:Hide();
end

function ABGP:DistribOnLeavingWorld()
    EndDistribution();
end

function ABGP:DistribOnLoadingScreen()
    EndDistribution();
end

function ABGP:DistribOnLogout()
    EndDistribution();
end

function ABGP:ShowItemDistrib(itemLink, summary)
    if activeDistributionWindow then
        local window = activeDistributionWindow;
        local activeItems = window:GetUserData("activeItems");
        if activeItems[itemLink] then
            activeItems[itemLink].totalCount = activeItems[itemLink].totalCount + 1;
            table.insert(summary, { ABGP.CommTypes.ITEM_COUNT.name, {
                itemLink = itemLink,
                count = activeItems[itemLink].totalCount,
            }});
            local currentItem = window:GetUserData("currentItem");
            if currentItem.itemLink ~= itemLink then
                window:GetUserData("tabGroup"):SelectTab(itemLink);
            else
                RebuildUI();
            end
            return;
        end
    end

    local existing = self:GetActiveItem(itemLink);
    if existing then
        self:Error("%s is already being distributed by %s!", itemLink, ABGP:ColorizeName(existing.sender));
        return;
    end

    if not activeDistributionWindow then
        activeDistributionWindow = self:CreateDistribWindow();
    end

    local value = ABGP:GetItemValue(ABGP:GetItemName(itemLink));
    local count = self:GetLootCount(itemLink) or 1;
    count = (count ~= 1) and count or nil;
    local data = {
        itemLink = itemLink,
        slots = self:GetItemEquipSlots(itemLink, true),
        count = count,
    };
    AddActiveItem(data);

    table.insert(summary, { self.CommTypes.ITEM_DIST_OPENED.name, data });

    if self:GetDebugOpt("ShowTestDistrib") then
        local ranks = {
            "Guild Master",
            "Officer",
            "Closer",
            "Red Lobster",
            "Purple Lobster",
            "Purple Lobster",
            "Blue Lobster",
            "Officer Alt",
            "Lobster Alt",
            "Fiddler Crab",
            "Other rank",
        };
        local classes = {
            "DRUID",
            "HUNTER",
            "MAGE",
            "PALADIN",
            "PRIEST",
            "ROGUE",
            "WARLOCK",
            "WARRIOR",
        };
        local testBase = {
            itemLink = itemLink,
            testContent = true,
            -- override = "trial",
            notes = "This is a custom note. It is very long. Why would someone leave a note this long? It's a mystery for sure. But people can, so here it is.",
            equipped = {
                "|cffff8000|Hitem:19019|h[Thunderfury, Blessed Blade of the Windseeker]|h|r",
                "|cffff8000|Hitem:17182|h[Sulfuras, Hand of Ragnaros]|h|r"
            },
            version = self:GetVersion(),
        };
        for i = 1, 10 do
            local entry = {};
            for k, v in pairs(testBase) do entry[k] = v; end
            entry.player = "TestTestPlayer" .. i;
            entry.rank = ranks[math.random(1, #ranks)];
            entry.class = classes[math.random(1, #classes)];
            entry.requestType = math.random() < 0.5 and ABGP.RequestTypes.MS or ABGP.RequestTypes.OS;
            if value then
                entry.ep = math.random() * 2000;
                entry.gp = math.random() * 2000;
                entry.priority = entry.ep * 10 / entry.gp;
            end
            PopulateRequest(entry, value);
            ProcessNewRequest(entry, summary);
        end
    end

    return true;
end

function ABGP:ShowDistrib(itemLinks)
    local summary = {};

    if type(itemLinks) == "table" then
        -- Any newly distributed items should only have ShowItemDistrib()
        -- called once, since we'll call GetLootCount() to determine the
        -- initial count. If the item is already being distributed, each
        -- subsequent call will add one to the count.
        local filtered = {};
        for _, itemLink in ipairs(itemLinks) do
            if not filtered[itemLink] then
                local newDistrib = self:ShowItemDistrib(itemLink, summary);
                if newDistrib then
                    filtered[itemLink] = true;
                end
            end
        end
    else
        self:ShowItemDistrib(itemLinks, summary);
    end

    if #summary > 0 then
        self:SendComm(self.CommTypes.ITEM_DIST_SUMMARY, summary, "BROADCAST");
    end
end

function ABGP:CreateDistribWindow()
    local window = AceGUI:Create("Window");
    window:SetLayout("Flow");
    window.frame:SetFrameStrata("MEDIUM"); -- restored by Window.OnAcquire
    self:BeginWindowManagement(window, "distrib", {
        version = 2,
        defaultWidth = 600,
        minWidth = 550,
        maxWidth = 800,
        defaultHeight = 400,
        minHeight = 350,
        maxHeight = 600
    });
    window:SetCallback("OnClose", function(widget)
        local closeConfirmed = true;
        local activeItems = widget:GetUserData("activeItems");
        for _, item in pairs(activeItems) do
            if not item.closeConfirmed then
                closeConfirmed = false;
                break;
            end
        end
        if closeConfirmed then
            activeDistributionWindow = nil;
            for _, item in pairs(activeItems) do
                RemoveActiveItem(item.itemLink, item);
            end

            local relatedElts = widget:GetUserData("relatedItems");
            for _, elt in pairs(relatedElts) do
                AceGUI:Release(elt);
            end

            ABGP:EndWindowManagement(widget);
            AceGUI:Release(widget);

            _G.StaticPopup_Hide("ABGP_CONFIRM_END_DIST");
            _G.StaticPopup_Hide("ABGP_CONFIRM_DIST");
            _G.StaticPopup_Hide("ABGP_CONFIRM_TRASH");
            _G.StaticPopup_Hide("ABGP_CONFIRM_DONE");
        else
            _G.StaticPopup_Show("ABGP_CONFIRM_END_DIST");
            widget:Show();
        end
    end);

    local topLine = AceGUI:Create("SimpleGroup");
    topLine:SetFullWidth(true);
    topLine:SetLayout("table");
    topLine:SetUserData("table", { columns = { 0, 1.0, 0 } });
    window:AddChild(topLine);

    local rankPriority = AceGUI:Create("CheckBox");
    rankPriority:SetWidth(150);
    rankPriority:SetLabel("Rank-based Priority");
    rankPriority:SetCallback("OnValueChanged", function(widget, event, value)
        prioritizeByRank = value;
        RepopulateRequests();
        RebuildUI();
    end);
    rankPriority:SetValue(prioritizeByRank);
    topLine:AddChild(rankPriority);
    self:AddWidgetTooltip(rankPriority, "If selected, requests will be prioritized based on guild rank, when appropriate.");

    local spacer = AceGUI:Create("ABGP_Header");
    topLine:AddChild(spacer);

    local itemRef = AceGUI:Create("ABGP_Header");
    itemRef:SetJustifyH("RIGHT");
    itemRef:SetJustifyV("TOP");
    itemRef:SetUserData("cell", { align = "TOPRIGHT" });
    topLine:AddChild(itemRef);
    window:SetUserData("topLine", topLine);
    window:SetUserData("itemRef", itemRef);
    window:SetUserData("relatedItems", {});

    local tabGroup = AceGUI:Create("TabGroup");
    tabGroup:SetFullWidth(true);
    tabGroup:SetFullHeight(true);
    tabGroup:SetLayout("Flow");
    tabGroup:SetCallback("OnGroupSelected", function(widget, event, itemLink)
        local activeItems = window:GetUserData("activeItems");
        window:SetUserData("currentItem", activeItems[itemLink]);
        RebuildUI();
    end);
    window:AddChild(tabGroup);
    window:SetUserData("tabGroup", tabGroup);

    local mainLine = AceGUI:Create("SimpleGroup");
    mainLine:SetFullWidth(true);
    mainLine:SetLayout("table");
    mainLine:SetUserData("table", { columns = { 0, 0, 0, 1.0, 0, 0 } });
    tabGroup:AddChild(mainLine);

    local disenchant = AceGUI:Create("Button");
    disenchant:SetWidth(115);
    disenchant:SetText("Disenchant");
    disenchant:SetCallback("OnClick", function(widget)
        local currentItem = window:GetUserData("currentItem");
        local itemLink = currentItem.itemLink;
        if currentItem.totalCount > 1 then
            local count = #currentItem.distributions;
            itemLink = ("%s #%d"):format(itemLink, count + 1);
        end
        _G.StaticPopup_Show("ABGP_CONFIRM_TRASH", itemLink, nil, {
            itemLink = currentItem.itemLink
        });
    end);
    mainLine:AddChild(disenchant);
    window:SetUserData("disenchantButton", disenchant);
    self:AddWidgetTooltip(disenchant, "Marks the item as disenchanted. If configured, the item will be ML'd to the designated disenchanter.");

    local distrib = AceGUI:Create("Button");
    distrib:SetWidth(105);
    distrib:SetText("Distribute");
    distrib:SetDisabled(true);
    distrib:SetCallback("OnClick", function() AwardItem(); end);
    mainLine:AddChild(distrib);
    window:SetUserData("distributeButton", distrib);
    self:AddWidgetTooltip(distrib, "Awards the item to the selected player. If configured, the item will be ML'd to them.");

    local choose = AceGUI:Create("Button");
    choose:SetWidth(125);
    choose:SetText("Choose Player");
    choose:SetCallback("OnClick", function() ChooseRecipient(); end);
    mainLine:AddChild(choose);
    window:SetUserData("chooseButton", choose);
    self:AddWidgetTooltip(choose, "Manually choose the player to whom the item will be awarded. If configured, the item will be ML'd to them.");

    local spacer = AceGUI:Create("Label");
    mainLine:AddChild(spacer);

    local test = AceGUI:Create("CheckBox");
    test:SetWidth(60);
    test:SetLabel("Test");
    test:SetCallback("OnValueChanged", function(widget, event, value)
        local currentItem = window:GetUserData("currentItem");
        currentItem.testItem = value;
    end);
    mainLine:AddChild(test);
    window:SetUserData("testCheckbox", test);
    self:AddWidgetTooltip(test, "Items marked as test don't affect GP and won't be recorded in the item history.");

    local done = AceGUI:Create("Button");
    done:SetWidth(75);
    done:SetText("Done");
    done:SetCallback("OnClick", function(widget)
        local currentItem = window:GetUserData("currentItem");
        local itemLink = currentItem.itemLink;

        if currentItem.closeConfirmed then
            RemoveActiveItem(itemLink);
        else
            local extra = "";
            if #currentItem.distributions == 0 then
                extra = "You haven't distributed it to anyone yet!";
            elseif #currentItem.distributions < currentItem.totalCount then
                local remaining = currentItem.totalCount - #currentItem.distributions;
                extra = ("You haven't distributed the remaining %d of %d copies yet!"):format(remaining, currentItem.totalCount);
            end
            _G.StaticPopup_Show("ABGP_CONFIRM_DONE", itemLink, extra, {
                itemLink = itemLink,
            });
        end
    end);
    mainLine:AddChild(done);
    self:AddWidgetTooltip(done, "End distribution of this item.");

    local secondLine = AceGUI:Create("SimpleGroup");
    secondLine:SetFullWidth(true);
    secondLine:SetLayout("Flow");
    tabGroup:AddChild(secondLine);

    local resetRolls = AceGUI:Create("Button");
    resetRolls:SetWidth(110);
    resetRolls:SetCallback("OnClick", function(widget)
        local currentItem = window:GetUserData("currentItem");
        if currentItem.rollsAllowed then
            for _, request in ipairs(currentItem.requests) do
                request.roll = nil;
            end
            table.wipe(currentItem.rolls);
        else
            currentItem.rollsAllowed = true;
        end
        RebuildUI();
    end);
    secondLine:AddChild(resetRolls);
    window:SetUserData("resetRollsButton", resetRolls);

    local cost = AceGUI:Create("ABGP_EditBox");
    cost:SetWidth(75);
    cost:SetCallback("OnValueChanged", function(widget, event, value)
        local currentItem = window:GetUserData("currentItem");
        local cost = self:DistribValidateCost(value);
        if cost then
            if not currentItem.costEdited then
                currentItem.costEdited = { category = currentItem.costBase.category };
            end
            currentItem.costEdited.cost = cost;
        else
            currentItem.costEdited = nil;
        end
        ProcessSelectedRequest();
    end);
    secondLine:AddChild(cost);
    window:SetUserData("costEdit", cost);
    self:AddWidgetTooltip(cost, "Edit the GP cost of this item.");

    local catSelector = AceGUI:Create("Dropdown");
    catSelector:SetWidth(80);
    catSelector:SetList(self.ItemCategoryNames, self.ItemCategoriesSorted);
    catSelector:SetCallback("OnValueChanged", function(widget, event, value)
        local currentItem = window:GetUserData("currentItem");
        if not currentItem.costEdited then
            currentItem.costEdited = { cost = currentItem.costBase.cost };
        end
        currentItem.costEdited.category = value;
    end);
    secondLine:AddChild(catSelector);
    window:SetUserData("categorySelector", catSelector);
    self:AddWidgetTooltip(catSelector, "Edit the GP category of this item.");

    local desc = AceGUI:Create("Label");
    desc:SetWidth(45);
    desc:SetText(" Cost");
    secondLine:AddChild(desc);

    local multiple = AceGUI:Create("Dropdown");
    multiple:SetText("Count");
    multiple:SetWidth(80);
    multiple:SetCallback("OnValueChanged", function(widget, event, value)
        local currentItem = window:GetUserData("currentItem");
        currentItem.totalCount = value;
        ABGP:SendComm(ABGP.CommTypes.ITEM_COUNT, {
            itemLink = currentItem.itemLink,
            count = currentItem.totalCount,
        }, "BROADCAST");
        RebuildUI();
    end);
    secondLine:AddChild(multiple);
    window:SetUserData("itemCountDropdown", multiple);
    self:AddWidgetTooltip(multiple, "Choose how many copies of this item are being distributed.");

    local spacer = AceGUI:Create("Label");
    spacer:SetFullWidth(true);
    spacer:SetText(" ");
    tabGroup:AddChild(spacer);

    local scrollContainer = AceGUI:Create("SimpleGroup");
    scrollContainer:SetFullWidth(true);
    scrollContainer:SetFullHeight(true);
    scrollContainer:SetLayout("Flow");
    tabGroup:AddChild(scrollContainer);

    local columns = { "Player", "Rank", "Priority", "Type", "Roll", "Notes", weights = { unpack(widths) } };
    local header = AceGUI:Create("SimpleGroup");
    header:SetFullWidth(true);
    header:SetLayout("Table");
    header:SetUserData("table", { columns = columns.weights });
    scrollContainer:AddChild(header);

    for i = 1, #columns do
        local desc = AceGUI:Create("ABGP_Header");
        desc:SetFullWidth(true);
        desc:SetFont(_G.GameFontHighlightSmall);
        desc:SetText(columns[i]);
        if columns[i] == "Roll" then
            desc:SetJustifyH("RIGHT");
            desc:SetPadding(0, -10);
        elseif columns[i] == "Type" then
            desc:SetJustifyH("CENTER");
        end
        header:AddChild(desc);
    end

    local scroll = AceGUI:Create("ScrollFrame");
    scroll:SetFullWidth(true);
    scroll:SetFullHeight(true);
    scroll:SetLayout("List");
    scrollContainer:AddChild(scroll);
    window:SetUserData("requestsContainer", scroll);

    window:SetUserData("activeItems", {});
    window:SetUserData("tabs", {});

    window.frame:Raise();
    return window;
end

function ABGP:DistribOnDistOpened(data, distribution, sender)
    if sender ~= UnitName("player") then return; end
    if not activeDistributionWindow then return; end

    local window = activeDistributionWindow;
    local activeItems = window:GetUserData("activeItems");
    if activeItems[data.itemLink] then
        activeItems[data.itemLink].receivedComm = true;
        RebuildUI();
    end
end

local function ChooseCandidate(candidates)
    for player in candidates:gmatch("[^, ]+") do
        player = UnitName(player);
        if player then return player; end
    end
end

function ABGP:GetRaidDisenchanter()
    local candidates = self:GetGlobal("raidDisenchanters");
    return ChooseCandidate(candidates), candidates ~= "";
end

function ABGP:GetRaidMule()
    local candidates = self:GetGlobal("raidMules");
    return ChooseCandidate(candidates), candidates ~= "";
end

local function DistributeLoot(itemLink)
    local context = {
        {
            text = ("%sABGP|r Item Options"):format(ABGP.Color),
            isTitle = true,
            notCheckable = true,
        },
        {
            text = "Distribute item",
            func = function(self, arg1)
                if ABGP:GetDebugOpt("TestLootFrame") then
                    ABGP:ShowLootFrame(arg1);
                else
                    ABGP:ShowDistrib(arg1);
                end
            end,
            arg1 = itemLink,
            notCheckable = true
        },
    };
    if IsMasterLooter() then
        local mule, hasCandidates = ABGP:GetRaidMule();
        if mule then
            table.insert(context, {
                text = "Give to raid mule",
                func = function(self, arg1, arg2)
                    ABGP:GiveItemViaML(arg1, arg2);
                end,
                arg1 = itemLink,
                arg2 = mule,
                notCheckable = true
            });
        else
            table.insert(context, {
                text = "No raid mule",
                fontObject = "GameFontRedSmall",
                func = function(self, arg1)
                    ABGP:Notify("%s! Update the setting in the options window.",
                        arg1 and "None of your configured mules are in the raid" or "You don't have a raid mules configured");
                end,
                arg1 = hasCandidates,
                notCheckable = true
            });
        end
        local disenchanter, hasCandidates = ABGP:GetRaidDisenchanter();
        if disenchanter then
            table.insert(context, {
                text = "Give to raid disenchanter",
                func = function(self, arg1, arg2)
                    ABGP:GiveItemViaML(arg1, arg2);
                end,
                arg1 = itemLink,
                arg2 = disenchanter,
                notCheckable = true
            });
        else
            table.insert(context, {
                text = "No raid disenchanter",
                fontObject = "GameFontRedSmall",
                func = function(self, arg1)
                    ABGP:Notify("%s! Update the setting in the options window.",
                        arg1 and "None of your configured disenchanters are in the raid" or "You don't have a raid disenchanter configured");
                end,
                arg1 = hasCandidates,
                notCheckable = true
            });
        end
    end
    table.insert(context, { text = "Cancel", notCheckable = true, fontObject = "GameFontDisableSmall" });
    ABGP:ShowContextMenu(context);
    return true;
end

function ABGP:AddItemHooks()
    self:RegisterModifiedItemClickFn(DistributeLoot);
end

function ABGP:DistribOnLootOpened()
    if not IsMasterLooter() then return; end
    local mule = self:GetRaidMule();
    if not mule then return; end

    local autoMLItems = {}
    local autoMLText = self:GetGlobal("autoMLItems");
    for item in autoMLText:gmatch("[^\n]+") do autoMLItems[item:lower()] = true; end

    local loot = GetLootInfo();
    for i = 1, GetNumLootItems() do
        local item = loot[i];
        if item and autoMLItems[item.item:lower()] then
            self:GiveItemViaML(GetLootSlotLink(i), mule);
        end
    end
end

StaticPopupDialogs["ABGP_CONFIRM_DIST"] = ABGP:StaticDialogTemplate(ABGP.StaticDialogTemplates.JUST_BUTTONS, {
    text = "Award %s to %s?",
    button1 = "Award",
    button2 = "Cancel",
    OnAccept = function(self, data)
        DistributeItem(data);
    end,
});
StaticPopupDialogs["ABGP_CONFIRM_TRASH"] = ABGP:StaticDialogTemplate(ABGP.StaticDialogTemplates.JUST_BUTTONS, {
    text = "Disenchant %s?",
    button1 = "Disenchant",
    button2 = "Cancel",
    OnAccept = function(self, data)
        if not activeDistributionWindow then return; end
        local window = activeDistributionWindow;
        local activeItems = window:GetUserData("activeItems");

        local currentItem = activeItems[data.itemLink];
        table.insert(currentItem.distributions, {
            trashed = true,
        });

        ABGP:SendComm(ABGP.CommTypes.ITEM_TRASHED, {
            itemLink = data.itemLink,
            count = #currentItem.distributions,
            testItem = currentItem.testItem
        }, "BROADCAST");

        if #currentItem.distributions < currentItem.totalCount then
            RebuildUI();
        else
            RemoveActiveItem(data.itemLink);
        end
    end,
});
StaticPopupDialogs["ABGP_CONFIRM_END_DIST"] = ABGP:StaticDialogTemplate(ABGP.StaticDialogTemplates.JUST_BUTTONS, {
    text = "Stop distribution of all items?",
    button1 = "Stop",
    button2 = "Cancel",
    showAlert = true,
    OnAccept = function(self, data)
        if not activeDistributionWindow then return; end
        local window = activeDistributionWindow;

        for _, item in pairs(window:GetUserData("activeItems")) do
            item.closeConfirmed = true;
        end
        window:Hide();
    end,
});
StaticPopupDialogs["ABGP_CONFIRM_DONE"] = ABGP:StaticDialogTemplate(ABGP.StaticDialogTemplates.JUST_BUTTONS, {
    text = "Done with %s? %s",
    button1 = "Done",
    button2 = "Cancel",
    showAlert = true,
    OnAccept = function(self, data)
        RemoveActiveItem(data.itemLink);
    end,
});
StaticPopupDialogs["ABGP_CHOOSE_RECIPIENT"] = ABGP:StaticDialogTemplate(ABGP.StaticDialogTemplates.EDIT_BOX, {
    text = "Choose the recipient of %s for %s:",
    button1 = "Done",
    button2 = "Cancel",
    maxLetters = 31,
    autoCompleteSource = GetAutoCompleteResults,
    autoCompleteArgs = { AUTOCOMPLETE_FLAG_IN_GROUP, AUTOCOMPLETE_FLAG_NONE },
    Validate = function(text, data)
        return ABGP:DistribValidateRecipient(text, data.cost);
    end,
    Commit = function(player, data)
        data.player = player;
        DistributeItem(data);
    end,
});
StaticPopupDialogs["ABGP_CONFIRM_REJECT"] = ABGP:StaticDialogTemplate(ABGP.StaticDialogTemplates.EDIT_BOX, {
    text = "Reject %s's request for %s? You can optionally add a reason below.",
    button1 = "Reject (public)",
    button2 = "Reject (private)",
    button3 = "Cancel",
    maxLetters = 200,
    notFocused = true,
    noCancelOnEscape = true,
    suppressEnterCommit = true,
    Commit = function(text, data)
        ABGP:Notify("%s's request for %s has been rejected (public).", ABGP:ColorizeName(data.player), data.itemLink);
        RemoveRequest(data.player, data.itemLink, true);

        if UnitExists(data.player) then
            local reason = text ~= "" and text or nil;

            ABGP:SendComm(ABGP.CommTypes.ITEM_REQUEST_REJECTED, {
                itemLink = data.itemLink,
                reason = reason,
                player = data.player,
            }, "BROADCAST");
        end
    end,
    OnCancel = function(self, data, reason)
        if not self then return; end
        if reason == "override" then return; end
        local text = self.editBox:GetText();

        ABGP:Notify("%s's request for %s has been rejected (private).", ABGP:ColorizeName(data.player), data.itemLink);
        RemoveRequest(data.player, data.itemLink, true);

        if UnitExists(data.player) then
            local reason = text ~= "" and text or nil;

            ABGP:SendComm(ABGP.CommTypes.ITEM_REQUEST_REJECTED, {
                itemLink = data.itemLink,
                reason = reason,
                player = data.player,
            }, "WHISPER", data.player);
        end
    end,
});
