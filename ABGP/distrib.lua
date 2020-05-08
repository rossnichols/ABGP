local _G = _G;
local ABGP = _G.ABGP;
local AceGUI = _G.LibStub("AceGUI-3.0");

local UnitExists = UnitExists;
local UnitName = UnitName;
local GetItemInfo = GetItemInfo;
local IsAltKeyDown = IsAltKeyDown;
local GetServerTime = GetServerTime;
local IsInGroup = IsInGroup;
local table = table;
local ipairs = ipairs;
local pairs = pairs;
local tonumber = tonumber;
local unpack = unpack;
local math = math;
local type = type;
local max = max;

local lastEditId = 0;
local activeDistributionWindow;
local currentRaidGroup;
local widths = { 110, 100, 70, 70, 70, 180, 60, 40, 1.0 };

local function CalculateCost(request)
    local window = activeDistributionWindow;
    local currentItem = window:GetUserData("currentItem");

    if not currentItem.data.value then
        return 0, false, "no value";
    end

    if request and request.override then
        return 0, false, request.override;
    end
    local costBase = (request and request.requestType ~= ABGP.RequestTypes.MS) and 0 or currentItem.costBase;
    return currentItem.costEdited or costBase, currentItem.data.value ~= nil;
end

local function ProcessSelectedRequest()
    local window = activeDistributionWindow;
    local currentItem = window:GetUserData("currentItem");
    local selected = currentItem.selectedRequest;

    window:GetUserData("disenchantButton"):SetDisabled(selected ~= nil);
    window:GetUserData("distributeButton"):SetDisabled(selected == nil);

    local cost, editable, reason = CalculateCost(selected);
    local edit = window:GetUserData("costEdit");
    edit:SetText(reason or cost);
    edit:SetDisabled(not editable);
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
    local award = ("%s for %d GP"):format(ABGP:ColorizeName(player), cost);

    _G.StaticPopup_Show("ABGP_CONFIRM_DIST", itemLink, award, {
        itemLink = currentItem.itemLink,
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
        [ABGP.RequestTypes.ROLL] = 3,
    };

    table.sort(requests, function(a, b)
        if a.requestType ~= b.requestType then
            return requestTypes[a.requestType] < requestTypes[b.requestType];
        elseif a.group ~= b.group then
            return a.group and (not b.group or a.group == currentRaidGroup);
        elseif a.priority ~= b.priority and a.requestType ~= ABGP.RequestTypes.ROLL then
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
        [ABGP.RequestTypes.ROLL] = "Rolls",
    };

    local currentHeading;
    local maxRolls = {};
    for i, request in ipairs(requests) do
        local heading;
        if currentItem.data.value then
            local group = request.group and ABGP.RaidGroupNames[request.group] or "Other";
            heading = ("%s (%s)"):format(typeHeadings[request.requestType], group);
        else
            heading = typeHeadings[request.requestType];
        end
        if currentHeading ~= heading then
            currentHeading = heading;
            local elt = AceGUI:Create("Heading");
            elt:SetFullWidth(true);
            elt:SetText(heading);
            requestsContainer:AddChild(elt);
        end

        request.currentMaxRoll = false;

        local elt = AceGUI:Create("ABGP_Player");
        elt:SetFullWidth(true);
        elt:SetData(request);
        elt:SetWidths(widths);
        elt:ShowBackground((i % 2) == 0);
        elt:SetCallback("OnClick", function(elt, event, button)
            if button == "RightButton" then
                local cost = CalculateCost(elt.data);
                ABGP:ShowContextMenu({
                    {
                        text = ("Award for %d GP"):format(cost),
                        func = function(self, request)
                            AwardItem(request);
                        end,
                        arg1 = elt.data,
                        notCheckable = true
                    },
                    { text = "Cancel", notCheckable = true },
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
            elt:SetData(elt.data);
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
    for i, tab in ipairs(tabs) do
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

    window:SetTitle("Loot Distribution: " .. currentItem.itemLink);

    if _G.ItemRefTooltip:IsOwned(window.frame) then
        _G.ShowUIPanel(_G.ItemRefTooltip);
        _G.ItemRefTooltip:SetOwner(window.frame, "ANCHOR_NONE");
        _G.ItemRefTooltip:SetPoint("TOPLEFT", window.frame, "TOPRIGHT");
        _G.ItemRefTooltip:SetHyperlink(currentItem.itemLink);
        _G.ItemRefTooltip:SetFrameStrata("HIGH");
        _G.ItemRefTooltip:Show();
    end

    ABGP:HideContextMenu();
end

local function RemoveRequest(sender, itemLink)
    local window = activeDistributionWindow;
    local activeItems = window:GetUserData("activeItems");
    local requests = activeItems[itemLink].requests;
    local currentItem = window:GetUserData("currentItem");

    for i, request in ipairs(requests) do
        if request.player == sender then
            table.remove(requests, i);
            ABGP:Notify("%s is now passing on %s.", ABGP:ColorizeName(sender), currentItem.itemLink);
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

local function ProcessNewRequest(request)
    local window = activeDistributionWindow;
    local activeItems = window:GetUserData("activeItems");
    local item = activeItems[request.itemLink];
    local requests = item.requests;
    local currentItem = window:GetUserData("currentItem");
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
    if request.requestType == ABGP.RequestTypes.ROLL and not request.roll then
        request.roll = math.random(1, 100);
        if UnitExists(request.player) then
            ABGP:SendComm(ABGP.CommTypes.ITEM_ROLLED, {
                itemLink = request.itemLink,
                roll = request.roll,
            }, "WHISPER", request.player);
        end
    end

    -- Persist the equipped items (for requests that come in without them)
    if oldRequest and oldRequest.equipped then
        request.equipped = oldRequest.equipped;
    end

    -- Persist the roll
    item.rolls[request.player] = request.roll;

    if not oldRequest or oldRequest.requestType ~= request.requestType then
        local requestTypes = {
            [ABGP.RequestTypes.MS] = "for main spec",
            [ABGP.RequestTypes.OS] = "for off spec",
            [ABGP.RequestTypes.ROLL] = "by rolling",
        };
        ABGP:Notify("%s is requesting %s %s.", ABGP:ColorizeName(request.player), request.itemLink, requestTypes[request.requestType]);
    end

    table.insert(requests, request);

    if request.itemLink == currentItem.itemLink then
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
            RebuildUI();
        end
    end
end

local function AddActiveItem(data)
    local window = activeDistributionWindow;
    local activeItems = window:GetUserData("activeItems");
    local itemLink = data.itemLink;

    local newItem = {
        itemLink = itemLink,
        requests = {},
        rolls = {},
        costBase = data.value and data.value.gp or 0,
        selectedRequest = nil,
        selectedElt = nil,
        costEdited = nil,
        closeConfirmed = false,
        distributions = {},
        rollsAllowed = (data.requestType == ABGP.RequestTypes.ROLL),
        data = data,
        receivedComm = false,
        testItem = not IsInGroup(),
        totalCount = ABGP:GetLootCount(itemLink) or 1,
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

    ABGP:SendComm(ABGP.CommTypes.ITEM_DISTRIBUTION_CLOSED, {
        itemLink = itemLink,
        count = #item.distributions
    }, "BROADCAST");

    if not item.testItem then
        ABGP:AuditItemDistribution(item);
    end
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

    _G.StaticPopup_Show("ABGP_CHOOSE_RECIPIENT", itemLink, cost, {
        itemLink = currentItem.itemLink,
        cost = cost,
        value = currentItem.data.value,
        requestType = ABGP.RequestTypes.MANUAL
    });
end

function ABGP:DistribValidateRecipient(player, cost, value)
    player = UnitExists(player) and UnitName(player);
    if not player then return false, "The player must be in your group"; end

    local epgp = self:GetActivePlayer(player);
    if cost ~= 0 and not (epgp and epgp[value.phase]) then
        return false, "The player must have EPGP for this phase";
    end

    return player;
end

function ABGP:DistribValidateCost(cost, player, value)
    cost = tonumber(cost);
    if type(cost) ~= "number" then return false, "Not a number"; end
    if cost < 0 then return false, "Can't be negative"; end
    if math.floor(cost) ~= cost then return false, "Must be a whole number"; end

    if player then
        local epgp = self:GetActivePlayer(player);
        if cost ~= 0 and not (epgp and epgp[value.phase]) then
            return false, "The player doesn't have EPGP for this phase";
        end
    end

    return cost;
end

local function DistributeItem(data)
    if not activeDistributionWindow then return; end
    local window = activeDistributionWindow;
    local activeItems = window:GetUserData("activeItems");

    local currentItem = activeItems[data.itemLink];
    local ep, gp, priority = 0, 0, 0;
    local value = currentItem.data.value;
    if value then
        local epgp = ABGP:GetActivePlayer(data.player);
        if epgp and epgp[value.phase] then
            ep = epgp[value.phase].ep;
            gp = epgp[value.phase].gp;
            priority = epgp[value.phase].priority;
        end
    end
    table.insert(currentItem.distributions, {
        player = data.player,
        ep = ep,
        gp = gp,
        priority = priority,
        cost = data.cost,
        roll = data.roll,
        requestType = data.requestType,
        override = data.override,
    });

    local commData = {
        itemLink = data.itemLink,
        player = data.player,
        cost = data.cost,
        roll = data.roll,
        requestType = data.requestType,
        override = data.override,
        count = #currentItem.distributions,
        testItem = currentItem.testItem,
        editId = ABGP:GetEditId(),
    };
    ABGP:SendComm(ABGP.CommTypes.ITEM_DISTRIBUTION_AWARDED, commData, "BROADCAST");
    ABGP:HistoryOnItemAwarded(commData, nil, UnitName("player"));
    ABGP:PriorityOnItemAwarded(commData, nil, UnitName("player"));

    if #currentItem.distributions < currentItem.totalCount then
        RebuildUI();
    else
        RemoveActiveItem(data.itemLink);
    end
end

function ABGP:DistribOnStateSync(data, distribution, sender)
    local window = activeDistributionWindow;
    local activeItems = window and window:GetUserData("activeItems") or {};

    for _, item in pairs(activeItems) do
        self:SendComm(self.CommTypes.ITEM_DISTRIBUTION_OPENED, item.data, "WHISPER", sender);
    end
end

local function PopulateRequest(request, value)
    local override;
    local rank, class;
    local priority, ep, gp;
    local raidGroup;
    local requestGroup;
    local preferredGroup = currentRaidGroup;

    if request.testContent then
        priority = request.priority;
        ep = request.ep;
        gp = request.gp;
        rank = request.rank;
        class = request.class;
        override = request.override;
        raidGroup = value and ABGP:GetGPRaidGroup(rank, value.phase);
    else
        local epgp = ABGP:GetActivePlayer(request.player);
        if epgp then
            rank = epgp.rank;
            class = epgp.class;
            if epgp.trial then
                override = "trial";
            end
        end

        if value then
            priority, ep, gp = 0, 0, 0;
            if epgp and epgp[value.phase] then
                priority = epgp[value.phase].priority;
                ep = epgp[value.phase].ep;
                gp = epgp[value.phase].gp;
                raidGroup = epgp[value.phase].gpRaidGroup;
            elseif not override then
                override = "non-raider";
            end
        end
    end

    if rank and value and not override then
        requestGroup = raidGroup;
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
    checkValue(request, "ep", ep);
    checkValue(request, "gp", gp);
    checkValue(request, "rank", rank);
    checkValue(request, "class", class);
    checkValue(request, "override", override);
    checkValue(request, "group", requestGroup);
    checkValue(request, "preferredGroup", preferredGroup);
    return needsUpdate;
end

local function RepopulateRequests()
    if not activeDistributionWindow then return false; end
    local activeItems = activeDistributionWindow:GetUserData("activeItems");

    local needsUpdate = false;
    for itemLink, item in pairs(activeItems) do
        local value = item.data.value;
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

function ABGP:GetEditId()
    local nextId = GetServerTime();
    while nextId == lastEditId do nextId = nextId + 1; end
    lastEditId = nextId;
    return nextId;
end

function ABGP:DistribOnItemRequest(data, distribution, sender)
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
        notes = data.notes
    };
    PopulateRequest(request, activeItems[itemLink].data.value);

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

function ABGP:ShowDistrib(itemLink)
    local _, fullLink = GetItemInfo(itemLink);
    itemLink = fullLink or itemLink;

    if activeDistributionWindow then
        local window = activeDistributionWindow;
        local activeItems = window:GetUserData("activeItems");
        if activeItems[itemLink] then
            local currentItem = window:GetUserData("currentItem");
            if currentItem.itemLink ~= itemLink then
                window:GetUserData("tabGroup"):SelectTab(itemLink);
            end
            return;
        end
    end

    local existing = self:GetActiveItem(itemLink);
    if existing then
        self:Error("%s is already being distributed by %s!", itemLink, ABGP:ColorizeName(existing.sender));
        return;
    end

    local value = ABGP:GetItemValue(ABGP:GetItemName(itemLink));
    local requestType = (value and value.gp ~= 0)
        and self.RequestTypes.MS_OS
        or self.RequestTypes.ROLL;

    if not activeDistributionWindow then
        activeDistributionWindow = self:CreateDistribWindow();
        _G.ItemRefTooltip:SetOwner(activeDistributionWindow.frame, "ANCHOR_NONE");
    end

    local data = {
        itemLink = itemLink,
        value = value,
        requestType = requestType,
    };
    AddActiveItem(data);

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
        local testBase = {
            itemLink = itemLink,
            testContent = true,
            -- override = "trial",
            notes = "This is a custom note. It is very long. Why would someone leave a note this long? It's a mystery for sure. But people can, so here it is.",
            equipped = {
                "|cffff8000|Hitem:19019|h[Thunderfury, Blessed Blade of the Windseeker]|h|r",
                "|cffff8000|Hitem:17182|h[Sulfuras, Hand of Ragnaros]|h|r"
            },
        };
        for i = 1, 9 do
            local entry = {};
            for k, v in pairs(testBase) do entry[k] = v; end
            entry.player = "TestTestPlayer" .. i;
            entry.rank = ranks[math.random(1, #ranks)];
            local rand = math.random();
            if rand < 0.33 then entry.requestType = ABGP.RequestTypes.MS;
            elseif rand < 0.67 then entry.requestType = ABGP.RequestTypes.OS;
            else entry.requestType = ABGP.RequestTypes.ROLL;
            end
            if value then
                entry.ep = math.random() * 2000;
                entry.gp = math.random() * 2000;
                entry.priority = entry.ep * 10 / entry.gp;
            end
            PopulateRequest(entry, value);
            ProcessNewRequest(entry);
        end
    end

    self:SendComm(self.CommTypes.ITEM_DISTRIBUTION_OPENED, data, "BROADCAST");
end

function ABGP:CreateDistribWindow()
    local window = AceGUI:Create("Window");
    window:SetLayout("Flow");
    window.frame:SetFrameStrata("HIGH"); -- restored by Window.OnAcquire
    self:BeginWindowManagement(window, "distrib", {
        version = 1,
        defaultWidth = 1000,
        minWidth = 900,
        maxWidth = 1100,
        defaultHeight = 500,
        minHeight = 300,
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

            ABGP:EndWindowManagement(widget);
            AceGUI:Release(widget);
            _G.ItemRefTooltip:Hide();
            _G.ItemRefTooltip:SetFrameStrata("TOOLTIP");

            _G.StaticPopup_Hide("ABGP_CONFIRM_END_DIST");
            _G.StaticPopup_Hide("ABGP_CONFIRM_DIST");
            _G.StaticPopup_Hide("ABGP_CONFIRM_TRASH");
            _G.StaticPopup_Hide("ABGP_CONFIRM_DONE");
        else
            _G.StaticPopup_Show("ABGP_CONFIRM_END_DIST");
            widget:Show();
        end
    end);

    local raidGroups, raidGroupNames = {}, {};
    for i, v in ipairs(ABGP.RaidGroupsSorted) do raidGroups[i] = v; end
    for k, v in pairs(ABGP.RaidGroupNames) do raidGroupNames[k] = v; end
    local groupSelector = AceGUI:Create("Dropdown");
    groupSelector:SetWidth(110);
    groupSelector:SetList(raidGroupNames, raidGroups);
    groupSelector:SetCallback("OnValueChanged", function(widget, event, value)
        currentRaidGroup = value;
        RepopulateRequests();
        RebuildUI();
    end);
    if not currentRaidGroup then
        currentRaidGroup = ABGP:GetPreferredRaidGroup();
    end
    groupSelector:SetValue(currentRaidGroup);
    window:AddChild(groupSelector);

    local tabGroup = AceGUI:Create("TabGroup");
    tabGroup:SetFullWidth(true);
    tabGroup:SetFullHeight(true);
    tabGroup:SetLayout("Flow");
    tabGroup:SetCallback("OnGroupSelected", function(container, event, itemLink)
        local activeItems = window:GetUserData("activeItems");
        window:SetUserData("currentItem", activeItems[itemLink]);
        RebuildUI();
    end);
    window:AddChild(tabGroup);
    window:SetUserData("tabGroup", tabGroup);

    local mainLine = AceGUI:Create("SimpleGroup");
    mainLine:SetFullWidth(true);
    mainLine:SetLayout("table");
    mainLine:SetUserData("table", { columns = { 0, 0, 0, 0, 0, 0, 0, 1.0, 0, 0 } });
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

    local distrib = AceGUI:Create("Button");
    distrib:SetWidth(105);
    distrib:SetText("Distribute");
    distrib:SetDisabled(true);
    distrib:SetCallback("OnClick", function() AwardItem(); end);
    mainLine:AddChild(distrib);
    window:SetUserData("distributeButton", distrib);

    local cost = AceGUI:Create("EditBox");
    cost:SetWidth(75);
    cost:SetCallback("OnEnterPressed", function(widget)
        local currentItem = window:GetUserData("currentItem");
        AceGUI:ClearFocus();
        local text = widget:GetText();
        if type(tonumber(text)) == "number" then
            currentItem.costEdited = tonumber(text);
        else
            currentItem.costEdited = nil;
        end
        ProcessSelectedRequest();
    end);
    mainLine:AddChild(cost);
    window:SetUserData("costEdit", cost);

    local desc = AceGUI:Create("Label");
    desc:SetWidth(45);
    desc:SetText(" Cost");
    mainLine:AddChild(desc);

    local multiple = AceGUI:Create("Dropdown");
    multiple:SetText("Count");
    multiple:SetWidth(80);
    multiple:SetCallback("OnValueChanged", function(widget, event, value)
        local currentItem = window:GetUserData("currentItem");
        currentItem.totalCount = value;
        RebuildUI();
    end);
    mainLine:AddChild(multiple);
    window:SetUserData("itemCountDropdown", multiple);

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
    mainLine:AddChild(resetRolls);
    window:SetUserData("resetRollsButton", resetRolls);

    local choose = AceGUI:Create("Button");
    choose:SetWidth(125);
    choose:SetText("Choose Player");
    choose:SetCallback("OnClick", function() ChooseRecipient(); end);
    mainLine:AddChild(choose);

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
                extra = ("You haven't distributed the remaining %d of %d instances yet!"):format(remaining, currentItem.totalCount);
            end
            _G.StaticPopup_Show("ABGP_CONFIRM_DONE", itemLink, extra, {
                itemLink = itemLink,
            });
        end
    end);
    mainLine:AddChild(done);

    local spacer = AceGUI:Create("Label");
    spacer:SetFullWidth(true);
    spacer:SetText(" ");
    tabGroup:AddChild(spacer);

    local scrollContainer = AceGUI:Create("SimpleGroup");
    scrollContainer:SetFullWidth(true);
    scrollContainer:SetFullHeight(true);
    scrollContainer:SetLayout("Flow");
    tabGroup:AddChild(scrollContainer);

    local columns = { "Player", "Rank", "EP", "GP", "Priority", "Equipped", "Request", "Roll", "Notes", weights = { unpack(widths) } };
    local header = AceGUI:Create("SimpleGroup");
    header:SetFullWidth(true);
    header:SetLayout("Table");
    header:SetUserData("table", { columns = columns.weights });
    scrollContainer:AddChild(header);

    for i = 1, #columns do
        local desc = AceGUI:Create("ABGP_Header");
        desc:SetText(columns[i]);
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

local function ShouldDistributeLoot()
    return IsAltKeyDown() and ABGP:IsPrivileged();
end

local function DistributeLoot(itemLink)
    if not (itemLink and ShouldDistributeLoot()) then
        return false;
    end
    if ABGP:GetDebugOpt("TestLootFrame") then
        ABGP:ShowLootFrame(itemLink);
    else
        ABGP:ShowDistrib(itemLink);
    end
    return true;
end

function ABGP:AddItemHooks()
    self:RegisterModifiedItemClickFn(DistributeLoot);
end

StaticPopupDialogs["ABGP_CONFIRM_DIST"] = {
    text = "Award %s to %s?",
    button1 = "Yes",
    button2 = "No",
    OnAccept = function(self, data)
        DistributeItem(data);
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    exclusive = true,
};

StaticPopupDialogs["ABGP_CONFIRM_TRASH"] = {
    text = "Disenchant %s?",
    button1 = "Yes",
    button2 = "No",
    OnAccept = function(self, data)
        if not activeDistributionWindow then return; end
        local window = activeDistributionWindow;
        local activeItems = window:GetUserData("activeItems");

        local currentItem = activeItems[data.itemLink];
        table.insert(currentItem.distributions, {
            trashed = true,
        });

        ABGP:SendComm(ABGP.CommTypes.ITEM_DISTRIBUTION_TRASHED, {
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
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    exclusive = true,
};

StaticPopupDialogs["ABGP_CONFIRM_END_DIST"] = {
    text = "Stop distribution of all items?",
    button1 = "Yes",
    button2 = "No",
    OnAccept = function(self, data)
        if not activeDistributionWindow then return; end
        local window = activeDistributionWindow;

        for _, item in pairs(window:GetUserData("activeItems")) do
            item.closeConfirmed = true;
        end
        window:Hide();
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    exclusive = true,
    showAlert = true,
};

StaticPopupDialogs["ABGP_CONFIRM_DONE"] = {
    text = "Done with %s? %s",
    button1 = "Yes",
    button2 = "No",
    OnAccept = function(self, data)
        RemoveActiveItem(data.itemLink);
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    exclusive = true,
};

StaticPopupDialogs["ABGP_CHOOSE_RECIPIENT"] = {
    text = "Choose the recipient of %s for %d GP:",
    button1 = "Done",
    button2 = "Cancel",
	hasEditBox = 1,
	autoCompleteSource = GetAutoCompleteResults,
	autoCompleteArgs = { AUTOCOMPLETE_FLAG_IN_GROUP, AUTOCOMPLETE_FLAG_NONE },
	maxLetters = 31,
    OnAccept = function(self, data)
        local player = ABGP:DistribValidateRecipient(self.editBox:GetText(), data.cost, data.value);
        if player then
            data.player = player;
            DistributeItem(data);
        end
    end,
    OnShow = function(self, data)
        self.editBox:SetAutoFocus(false);
        self.button1:Disable();
    end,
    EditBoxOnTextChanged = function(self, data)
        local parent = self:GetParent();
        local player = ABGP:DistribValidateRecipient(parent.editBox:GetText(), data.cost, data.value);
        if player then
            parent.button1:Enable();
        else
            parent.button1:Disable();
        end
    end,
    EditBoxOnEnterPressed = function(self, data)
        local parent = self:GetParent();
        if parent.button1:IsEnabled() then
            parent.button1:Click();
        else
            local _, errorText = ABGP:DistribValidateRecipient(parent.editBox:GetText(), data.cost, data.value);
            ABGP:Error("Invalid recipient! %s.", errorText);
        end
    end,
    EditBoxOnEscapePressed = function(self)
		self:ClearFocus();
    end,
    OnHide = function(self, data)
        self.editBox:SetAutoFocus(true);
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    exclusive = true,
};
