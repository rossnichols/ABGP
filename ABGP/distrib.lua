local _G = _G;
local ABGP = ABGP;
local AceGUI = _G.LibStub("AceGUI-3.0");

local BNGetFriendInfoByID = BNGetFriendInfoByID;
local BNGetGameAccountInfo = BNGetGameAccountInfo;
local UnitExists = UnitExists;
local GetGuildInfo = GetGuildInfo;
local UnitName = UnitName;
local UnitIsInMyGuild = UnitIsInMyGuild;
local table = table;
local ipairs = ipairs;
local pairs = pairs;
local tonumber = tonumber;
local select = select;
local unpack = unpack;
local math = math;
local type = type;
local max = max;

local activeDistributionWindow;
local widths = { 110, 100, 70, 70, 70, 180, 60, 40, 1.0 };

local function CalculateCost(request)
    local window = activeDistributionWindow;
    local currentItem = window:GetUserData("currentItem");

    if request and request.override then
        return 0, false;
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

    local cost, editable = CalculateCost(selected);
    local edit = window:GetUserData("costEdit");
    edit:SetText(cost);
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
    if currentItem.multipleItems then
        local count = currentItem.distributionCount;
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

    local requestTypes = {
        [ABGP.RequestTypes.MS] = 1,
        [ABGP.RequestTypes.OS] = 2,
        [ABGP.RequestTypes.ROLL] = 3,
    };

    table.sort(requests, function(a, b)
        if a.requestType ~= b.requestType then
            return requestTypes[a.requestType] < requestTypes[b.requestType];
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

    local msHeading, osHeading, rollHeading;
    local maxRolls = {};
    for i, request in ipairs(requests) do
        if request.requestType == ABGP.RequestTypes.MS and not msHeading then
            msHeading = true;
            local mainspec = AceGUI:Create("Heading");
            mainspec:SetFullWidth(true);
            mainspec:SetText("Main Spec");
            requestsContainer:AddChild(mainspec);
        end
        if request.requestType == ABGP.RequestTypes.OS and not osHeading then
            osHeading = true;
            local offspec = AceGUI:Create("Heading");
            offspec:SetFullWidth(true);
            offspec:SetText("Off Spec");
            requestsContainer:AddChild(offspec);
        end
        if request.requestType == ABGP.RequestTypes.ROLL and not rollHeading then
            rollHeading = true;
            local roll = AceGUI:Create("Heading");
            roll:SetFullWidth(true);
            roll:SetText("Rolls");
            requestsContainer:AddChild(roll);
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

    local multiple = window:GetUserData("multipleItemsCheckbox");
    multiple:SetWidth(100);
    multiple:SetValue(currentItem.multipleItems);
    multiple:SetDisabled(currentItem.distributionCount > 0);

    local resetRolls = window:GetUserData("resetRollsButton");
    resetRolls:SetText(currentItem.rollsAllowed and "Reset Rolls" or "Allow Rolls");

    window:SetTitle("Loot Distribution: " .. currentItem.itemLink);

    _G.ShowUIPanel(_G.ItemRefTooltip);
    _G.ItemRefTooltip:SetOwner(window.frame, "ANCHOR_NONE");
    _G.ItemRefTooltip:SetPoint("TOPLEFT", window.frame, "TOPRIGHT");
    _G.ItemRefTooltip:SetHyperlink(currentItem.itemLink);
    _G.ItemRefTooltip:SetFrameStrata("HIGH");
    _G.ItemRefTooltip:Show();

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

    for i, existing in ipairs(requests) do
        if existing.player == request.player then
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

    -- Persist the roll
    item.rolls[request.player] = request.roll;

    table.insert(requests, request);

    if request.itemLink == currentItem.itemLink then
        RebuildUI();
    end
end

local function GetPlayerFromBNet(bnetId)
    local _, _, _, _, _, gameAccountID = BNGetFriendInfoByID(bnetId);
    if gameAccountID then
        -- local _, characterName, clientProgram, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, wowProjectID = BNGetGameAccountInfo(gameAccountID);
        -- if clientProgram == BNET_CLIENT_WOW and wowProjectID == WOW_PROJECT_CLASSIC then
        --     return characterName;
        -- end
        local _, characterName = BNGetGameAccountInfo(gameAccountID);
        if UnitExists(characterName) then
            return characterName;
        end
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
        multipleItems = false,
        distributionCount = 0,
        rollsAllowed = (data.requestType == ABGP.RequestTypes.ROLL),
        data = data,
    };

    activeItems[itemLink] = newItem;

    local tabs = window:GetUserData("tabs");
    table.insert(tabs, { value = itemLink, text = ABGP:GetItemName(itemLink) });
    local tabGroup = window:GetUserData("tabGroup");
    tabGroup:SetTabs(tabs);
    tabGroup:SelectTab(itemLink);
end

local function RemoveActiveItem(itemLink)
    ABGP:SendComm(ABGP.CommTypes.ITEM_DISTRIBUTION_CLOSED, {
        itemLink = itemLink
    }, "BROADCAST");

    if activeDistributionWindow then
        local window = activeDistributionWindow;
        local activeItems = window:GetUserData("activeItems");
        local currentItem = window:GetUserData("currentItem");

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
end

function ABGP:DistribOnCheck(data, distribution, sender)
    local window = activeDistributionWindow;
    if not window then return; end

    local activeItems = window:GetUserData("activeItems");
    for _, item in pairs(activeItems) do
        self:SendComm(self.CommTypes.ITEM_DISTRIBUTION_OPENED, item.data, "WHISPER", sender);
    end
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

    local override;
    local guildName, guildRankName;
    if UnitIsInMyGuild(sender) then
        guildName, guildRankName = GetGuildInfo(sender);
        if self:IsTrial(guildRankName) then
            override = "trial";
        end
    else
        guildRankName = "[Non-guildie]";
        override = "non-guildie";
    end

    local requestTypes = {
        [ABGP.RequestTypes.MS] = "for main spec",
        [ABGP.RequestTypes.OS] = "for off spec",
        [ABGP.RequestTypes.ROLL] = "by rolling",
    };
    ABGP:Notify("%s is requesting %s %s.", ABGP:ColorizeName(sender), itemLink, requestTypes[data.requestType]);

    local priority, ep, gp = 0, 0, 0;
    local epgp = ABGP:GetActivePlayer(sender);
    local itemName = ABGP:GetItemName(itemLink);
    local value = ABGP:GetItemValue(itemName);

    if value and epgp and epgp[value.phase] then
        priority = epgp[value.phase].priority;
        ep = epgp[value.phase].ep;
        gp = epgp[value.phase].gp;
    end

    ProcessNewRequest({
        itemLink = itemLink,
        player = sender,
        override = override,
        rank = guildRankName,
        priority = priority,
        ep = ep,
        gp = gp,
        equipped = data.equipped,
        requestType = data.requestType,
        notes = data.notes
    });
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
    if not activeDistributionWindow then return; end
    local activeItems = activeDistributionWindow:GetUserData("activeItems");
    for itemLink, item in pairs(activeItems) do
        local value = item.data.value;
        if value then
            for _, request in ipairs(item.requests) do
                local epgp = self:GetActivePlayer(request.player);
                if epgp and epgp[value.phase] then
                    request.priority = epgp[value.phase].priority;
                    request.ep = epgp[value.phase].ep;
                    request.gp = epgp[value.phase].gp;
                end
            end
        end
    end

    RebuildUI();
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

function ABGP:DistribOnReloadUI()
    -- If distribution is open when reloading UI,
    -- hide the window so it generates the appropriate comms.
    EndDistribution();
end

function ABGP:ShowDistrib(itemLink)
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

    self:SendComm(self.CommTypes.ITEM_DISTRIBUTION_OPENED, {
        itemLink = itemLink,
        value = value,
        requestType = requestType,
    }, "BROADCAST");
end

function ABGP:CreateDistribWindow()
    local window = AceGUI:Create("Window");
    window:SetLayout("Fill");
    window.frame:SetFrameStrata("HIGH"); -- restored by Window.OnAcquire
    self:BeginWindowManagement(window, "distrib", {
        version = 1,
        defaultWidth = 950,
        minWidth = 800,
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
                RemoveActiveItem(item.itemLink);
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

    local tabGroup = AceGUI:Create("TabGroup");
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
    mainLine:SetUserData("table", { columns = { 0, 0, 0, 0, 0, 0, 1.0, 0 } });
    tabGroup:AddChild(mainLine);

    local disenchant = AceGUI:Create("Button");
    disenchant:SetWidth(125);
    disenchant:SetText("Disenchant");
    disenchant:SetCallback("OnClick", function(widget)
        local currentItem = window:GetUserData("currentItem");
        local itemLink = currentItem.itemLink;
        if currentItem.multipleItems then
            local count = currentItem.distributionCount;
            itemLink = ("%s #%d"):format(itemLink, count + 1);
        end
        _G.StaticPopup_Show("ABGP_CONFIRM_TRASH", itemLink, nil, {
            itemLink = currentItem.itemLink
        });
    end);
    mainLine:AddChild(disenchant);
    window:SetUserData("disenchantButton", disenchant);

    local distrib = AceGUI:Create("Button");
    distrib:SetWidth(125);
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
    desc:SetWidth(50);
    desc:SetText(" Cost");
    mainLine:AddChild(desc);

    local multiple = AceGUI:Create("CheckBox");
    multiple:SetWidth(100);
    multiple:SetLabel("Multiple");
    multiple:SetCallback("OnValueChanged", function(widget, value)
        local currentItem = window:GetUserData("currentItem");
        currentItem.multipleItems = value;
    end);
    mainLine:AddChild(multiple);
    window:SetUserData("multipleItemsCheckbox", multiple);

    local resetRolls = AceGUI:Create("Button");
    resetRolls:SetWidth(125);
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

    local spacer = AceGUI:Create("Label");
    mainLine:AddChild(spacer);

    local done = AceGUI:Create("Button");
    done:SetWidth(80);
    done:SetText("Done");
    done:SetCallback("OnClick", function(widget)
        local currentItem = window:GetUserData("currentItem");
        local itemLink = currentItem.itemLink;

        _G.StaticPopup_Show("ABGP_CONFIRM_DONE", itemLink, nil, {
            itemLink = itemLink,
        });
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

    if not activeDistributionWindow then
        activeDistributionWindow = self:CreateDistribWindow();
    end

    AddActiveItem(data);

    if self.Debug then
        local testBase = {
            itemLink = data.itemLink,
            rank = "Blue Lobster",
            notes = "This is a custom note. It is very long. Why would someone leave a note this long? It's a mystery for sure. But people can, so here it is.",
            equipped = {
                "|cffff8000|Hitem:19019::::::::60:::::|h[Thunderfury, Blessed Blade of the Windseeker]|h|r",
                "|cffff8000|Hitem:17182::::::::60:::::|h[Sulfuras, Hand of Ragnaros]|h|r"
            },
        };
        for i = 1, 9 do
            local entry = {};
            for k, v in pairs(testBase) do entry[k] = v; end
            entry.player = "TestTestPlayer" .. i;
            local rand = math.random();
            if rand < 0.33 then entry.requestType = ABGP.RequestTypes.MS;
            elseif rand < 0.67 then entry.requestType = ABGP.RequestTypes.OS;
            else entry.requestType = ABGP.RequestTypes.ROLL;
            end
            entry.ep = math.random() * 2000;
            entry.gp = math.random() * 2000;
            entry.priority = entry.ep * 10 / entry.gp;
            ProcessNewRequest(entry);
        end
    end
end

StaticPopupDialogs["ABGP_CONFIRM_DIST"] = {
    text = "Award %s to %s?",
    button1 = "Yes",
    button2 = "No",
    OnAccept = function(self, data)
        if not activeDistributionWindow then return; end
        local window = activeDistributionWindow;
        local activeItems = window:GetUserData("activeItems");

        local currentItem = activeItems[data.itemLink];
        currentItem.distributionCount = currentItem.distributionCount + 1;

        ABGP:SendComm(ABGP.CommTypes.ITEM_DISTRIBUTION_AWARDED, {
            itemLink = data.itemLink,
            player = data.player,
            cost = data.cost,
            roll = data.roll,
            requestType = data.requestType,
            override = data.override,
            count = currentItem.distributionCount
        }, "BROADCAST");

        currentItem.closeConfirmed = true;
        if currentItem.multipleItems then
            window:GetUserData("multipleItemsCheckbox"):SetDisabled(true);
        else
            RemoveActiveItem(data.itemLink);
        end
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
        currentItem.distributionCount = currentItem.distributionCount + 1;

        ABGP:SendComm(ABGP.CommTypes.ITEM_DISTRIBUTION_TRASHED, {
            itemLink = data.itemLink,
            count = currentItem.distributionCount
        }, "BROADCAST");

        currentItem.closeConfirmed = true;
        if currentItem.multipleItems then
            window:GetUserData("multipleItemsCheckbox"):SetDisabled(true);
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
    text = "Are you sure you want to stop distribution?",
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
    text = "Done distributing %s?",
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
