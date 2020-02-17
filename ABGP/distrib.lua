local _G = _G;
local ABGP = ABGP;
local AceGUI = _G.LibStub("AceGUI-3.0");

local BNGetFriendInfoByID = BNGetFriendInfoByID;
local BNGetGameAccountInfo = BNGetGameAccountInfo;
local UnitExists = UnitExists;
local GetGuildInfo = GetGuildInfo;
local UnitName = UnitName;
local table = table;
local ipairs = ipairs;
local pairs = pairs;
local tonumber = tonumber;
local select = select;
local unpack = unpack;
local math = math;
local type = type;

local rollRegex = RANDOM_ROLL_RESULT:gsub("([()-])", "%%%1");
rollRegex = rollRegex:gsub("%%s", "(%%S+)");
rollRegex = rollRegex:gsub("%%d", "(%%d+)");

local activeDistributionWindow;
local widths = { 110, 100, 70, 70, 70, 180, 60, 35, 1.0 };

local function ProcessSelectedData()
    local window = activeDistributionWindow;
    local data = window:GetUserData("selectedData");

    window:GetUserData("disenchantButton"):SetDisabled(data ~= nil);
    window:GetUserData("distributeButton"):SetDisabled(data == nil);
    if not window:GetUserData("costEdited") then
        window:GetUserData("costEdit"):SetText((data and data.requestType ~= ABGP.RequestTypes.MS) and 0 or window:GetUserData("costBase"));
    end
end

local function RebuildUI()
    local window = activeDistributionWindow;
    local data = window:GetUserData("data");
    local requests = window:GetUserData("requests");
    requests:ReleaseChildren();

    local requestTypes = {
        [ABGP.RequestTypes.MS] = 1,
        [ABGP.RequestTypes.OS] = 2,
        [ABGP.RequestTypes.ROLL] = 3,
    };

    table.sort(data, function(a, b)
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

    local selectedData = window:GetUserData("selectedData");
    window:SetUserData("selectedData", nil);
    window:SetUserData("selectedElt", nil);
    ProcessSelectedData();

    local msHeading, osHeading, rollHeading;
    local ignoredChildren = 0;
    local maxRolls = {};
    for i, existing in ipairs(data) do
        if existing.requestType == ABGP.RequestTypes.MS and not msHeading then
            msHeading = true;
            local mainspec = AceGUI:Create("Heading");
            mainspec:SetFullWidth(true);
            mainspec:SetText("Main Spec");
            requests:AddChild(mainspec);
            ignoredChildren = ignoredChildren + 1;
        end
        if existing.requestType == ABGP.RequestTypes.OS and not osHeading then
            osHeading = true;
            local offspec = AceGUI:Create("Heading");
            offspec:SetFullWidth(true);
            offspec:SetText("Off Spec");
            requests:AddChild(offspec);
            ignoredChildren = ignoredChildren + 1;
        end
        if existing.requestType == ABGP.RequestTypes.ROLL and not rollHeading then
            rollHeading = true;
            local roll = AceGUI:Create("Heading");
            roll:SetFullWidth(true);
            roll:SetText("Rolls");
            requests:AddChild(roll);
            ignoredChildren = ignoredChildren + 1;
        end

        existing.currentMaxRoll = false;

        local elt = AceGUI:Create("ABGP_Player");
        elt:SetFullWidth(true);
        elt:SetData(existing);
        elt:SetWidths(widths);
        elt:ShowBackground((i % 2) == 0);
        elt:SetCallback("OnClick", function(elt)
            local oldElt = window:GetUserData("selectedElt");
            if oldElt then
                oldElt.frame:RequestHighlight(false);
            end

            local oldData = window:GetUserData("selectedData");
            if not oldData or oldData.player ~= elt.data.player then
                window:SetUserData("selectedData", elt.data);
                window:SetUserData("selectedElt", elt);
                elt.frame:RequestHighlight(true);
            else
                window:SetUserData("selectedData", nil);
                window:SetUserData("selectedElt", nil);
            end
            ProcessSelectedData();
        end);

        requests:AddChild(elt);

        if selectedData and existing.player == selectedData.player then
            elt:Fire("OnClick");
        end

        if existing.roll then
            local reqType = existing.requestType;
            if not maxRolls[reqType] then
                maxRolls[reqType] = { roll = existing.roll, elts = { elt } };
            elseif existing.roll > maxRolls[reqType].roll then
                maxRolls[reqType] = { roll = existing.roll, elts = { elt } };
            elseif existing.roll == maxRolls[reqType].roll then
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

    local nRequests = #requests.children - ignoredChildren;
    window:GetUserData("requestsTitle"):SetTitle(("Requests%s"):format(
        nRequests > 0 and " (" .. nRequests .. ")" or ""));
end

local function RemoveData(sender)
    local window = activeDistributionWindow;
    local data = window:GetUserData("data");

    for i, existing in ipairs(data) do
        if existing.player == sender then
            table.remove(data, i);
            ABGP:Notify("%s is now passing on %s.", ABGP:ColorizeName(sender), window:GetUserData("itemLink"));
            break;
        end
    end

    RebuildUI();
end

local function CombineNotes(a, b)
    if not a then return b; end
    if not b then return a; end
    return a .. "\n" .. b;
end

local function ProcessNewData(entry)
    local window = activeDistributionWindow;
    local data = window:GetUserData("data");

    for i, existing in ipairs(data) do
        if existing.player == entry.player then
            entry.notes = CombineNotes(existing.notes, entry.notes);
            entry.roll = existing.roll;
            table.remove(data, i);
            break;
        end
    end

    local pending = window:GetUserData("pendingWhispers");
    if pending and pending[entry.player] then
        entry.notes = CombineNotes(pending[entry.player], entry.notes);
        pending[entry.player] = nil;
    end

    pending = window:GetUserData("pendingRolls");
    if pending and pending[entry.player] then
        entry.roll = pending[entry.player];
        pending[entry.player] = nil;
    end

    table.insert(data, entry);
    RebuildUI();
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
    local requests = activeDistributionWindow:GetUserData("requests");
    for _, elt in ipairs(requests.children) do
        if elt.data and elt.data.player == sender then
            return elt;
        end
    end
end

local msgFrame = CreateFrame("Frame");
msgFrame:RegisterEvent("CHAT_MSG_WHISPER");
msgFrame:RegisterEvent("CHAT_MSG_BN_WHISPER");
msgFrame:RegisterEvent("CHAT_MSG_SYSTEM");
msgFrame:SetScript("OnEvent", function(self, event, ...)
    if not activeDistributionWindow then
        return;
    end
    local window = activeDistributionWindow;

    if event == "CHAT_MSG_SYSTEM" then
        local text = ...;
        local sender, roll, minRoll, maxRoll = text:match(rollRegex);
        if minRoll == "1" and maxRoll == "100" and sender and UnitExists(sender) then
            local elt = FindExistingElt(sender);
            if elt then
                if not elt.data.roll then
                    elt.data.roll = tonumber(roll);
                    RebuildUI();
                end
            else
                if not window:GetUserData("pendingRolls") then
                    window:SetUserData("pendingRolls", {});
                end
                local pending = window:GetUserData("pendingRolls");
                if not pending[sender] then
                    pending[sender] = tonumber(roll);
                end
            end
        end
    else
        local msg, sender, _;
        if event == "CHAT_MSG_WHISPER" then
            msg, _, _, _, sender = ...;
        elseif event == "CHAT_MSG_BN_WHISPER" then
            msg = ...;
            local bnetId = select(13, ...);
            sender = GetPlayerFromBNet(bnetId);
        end

        if msg and sender and UnitExists(sender) then
            local elt = FindExistingElt(sender);
            if elt then
                elt.data.notes = CombineNotes(elt.data.notes, msg);
                elt:SetData(elt.data);
            else
                if not window:GetUserData("pendingWhispers") then
                    window:SetUserData("pendingWhispers", {});
                end
                local pending = window:GetUserData("pendingWhispers");
                pending[sender] = CombineNotes(pending[sender], msg);
            end
        end
    end
end);

function ABGP:DistribOnItemRequest(data, distribution, sender)
    local itemLink = data.itemLink;
    if not activeDistributionWindow then return; end

    -- Check if the sender is grouped with us
    if not UnitExists(sender) then return; end

    local itemLinkCmp = activeDistributionWindow:GetUserData("itemLink");
    if itemLink ~= itemLinkCmp then
        ABGP:Error("%s requested %s but you're distributing %s!", sender, itemLink, itemLinkCmp);
        return;
    end

    local playerGuild = GetGuildInfo("player");
    local guildName, guildRankName = GetGuildInfo(sender);
    if guildName and guildName ~= playerGuild then
        guildRankName = "[Other guild]";
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

    ProcessNewData({
        player = sender,
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

    local itemLinkCmp = activeDistributionWindow:GetUserData("itemLink");
    if itemLink ~= itemLinkCmp then
        self:Error("%s passed on %s but you're distributing %s!", sender, itemLink, itemLinkCmp);
        return;
    end

    RemoveData(sender);
end

function ABGP:DistribOnReloadUI()
    -- If distribution is open when reloading UI,
    -- hide the window so it generates the appropriate comms.
    if activeDistributionWindow then
        activeDistributionWindow:SetUserData("closeConfirmed", true);
        activeDistributionWindow:Hide();
    end
end

function ABGP:ShowDistrib(itemLink)
    local itemName = ABGP:GetItemName(itemLink);
    local value = ABGP:GetItemValue(itemName);

    if activeDistributionWindow then
        activeDistributionWindow:SetUserData("closeConfirmed", true);
        activeDistributionWindow:Hide();
    end

    local requestType = (value and value.gp ~= 0)
        and self.RequestTypes.MS_OS
        or self.RequestTypes.ROLL;

    self:SendComm(self.CommTypes.ITEM_DISTRIBUTION_OPENED, {
        itemLink = itemLink,
        value = value,
        requestType = requestType,
    }, "BROADCAST");
end

function ABGP:DistribOnDistOpened(data, distribution, sender)
    local itemLink = data.itemLink;
    local itemName = self:GetItemName(itemLink);
    local value = self:GetItemValue(itemName);

    if sender ~= UnitName("player") then return; end

    local window = AceGUI:Create("Window");
    local oldMinW, oldMinH = window.frame:GetMinResize();
    local oldMaxW, oldMaxH = window.frame:GetMaxResize();
    window:SetWidth(975);
    window:SetHeight(500);
    window.frame:SetMinResize(750, 300);
    window.frame:SetMaxResize(1100, 600);
    window.frame:SetFrameStrata("HIGH");
    window:SetTitle("Loot Distribution: " .. itemLink);
    window:SetCallback("OnClose", function(widget)
        local primary = widget:GetUserData("primary");
        if not primary or widget:GetUserData("closeConfirmed") then
            activeDistributionWindow = nil;

            if primary then
                self:SendComm(self.CommTypes.ITEM_DISTRIBUTION_CLOSED, {
                    itemLink = itemLink
                }, "BROADCAST");
            end

            widget.frame:SetMinResize(oldMinW, oldMinH);
            widget.frame:SetMaxResize(oldMaxW, oldMaxH);
            AceGUI:Release(widget);
            _G.ItemRefTooltip:Hide();

            _G.StaticPopup_Hide("ABGP_CONFIRM_END_DIST");
            _G.StaticPopup_Hide("ABGP_CONFIRM_DIST");
            _G.StaticPopup_Hide("ABGP_CONFIRM_TRASH");
        else
            _G.StaticPopup_Show("ABGP_CONFIRM_END_DIST");
            widget:Show();
        end
    end);
    window:SetLayout("Flow");
    window:SetUserData("itemLink", itemLink);
    window:SetUserData("data", {});
    window:SetUserData("primary", true);

    local disenchant = AceGUI:Create("Button");
    disenchant:SetWidth(125);
    disenchant:SetText("Disenchant");
    disenchant:SetCallback("OnClick", function(widget)
        local item = itemLink;
        if window:GetUserData("multipleItems") then
            local count = window:GetUserData("distributionCount") or 0;
            item = ("%s #%d"):format(itemLink, count + 1);
        end
        _G.StaticPopup_Show("ABGP_CONFIRM_TRASH", item, nil, {
            itemLink = itemLink
        });
    end);
    window:AddChild(disenchant);
    window:SetUserData("disenchantButton", disenchant);

    local distrib = AceGUI:Create("Button");
    distrib:SetWidth(125);
    distrib:SetText("Distribute");
    distrib:SetDisabled(true);
    distrib:SetCallback("OnClick", function(widget)
        local cost = tonumber(window:GetUserData("costEdit"):GetText());
        local player = window:GetUserData("selectedData").player;

        local item = itemLink;
        if window:GetUserData("multipleItems") then
            local count = window:GetUserData("distributionCount") or 0;
            item = ("%s #%d"):format(itemLink, count + 1);
        end
        local award = ("%s for %d GP"):format(ABGP:ColorizeName(player), cost);

        _G.StaticPopup_Show("ABGP_CONFIRM_DIST", item, award, {
            itemLink = itemLink,
            player = player,
            cost = cost
        });
    end);
    window:AddChild(distrib);
    window:SetUserData("distributeButton", distrib);

    local cost = AceGUI:Create("EditBox");
    local costBase = value and value.gp or 0;
    cost:SetWidth(75);
    cost:SetText(costBase);
    window:AddChild(cost);
    cost:SetCallback("OnEnterPressed", function(widget)
        AceGUI:ClearFocus();
        local text = widget:GetText();
        if type(tonumber(text)) == "number" then
            window:SetUserData("costEdited", true);
        else
            window:SetUserData("costEdited", false);
        end
        ProcessSelectedData();
    end);
    window:SetUserData("costEdit", cost);
    window:SetUserData("costBase", costBase);

    local desc = AceGUI:Create("Label");
    desc:SetWidth(100);
    desc:SetText("Cost");
    window:AddChild(desc);

    local resetRolls = AceGUI:Create("Button");
    resetRolls:SetWidth(125);
    resetRolls:SetText("Reset Rolls");
    resetRolls:SetCallback("OnClick", function(widget)
        window:SetUserData("pendingRolls", nil);
        local data = window:GetUserData("data");
        for _, entry in ipairs(data) do
            entry.roll = nil;
        end
        RebuildUI();
    end);
    window:AddChild(resetRolls);

    local multiple = AceGUI:Create("CheckBox");
    multiple:SetLabel("Multiple");
    multiple:SetCallback("OnValueChanged", function(widget, value)
        window:SetUserData("multipleItems", value);
    end);
    window:AddChild(multiple);
    window:SetUserData("multipleItemsCheckbox", multiple);

    local scrollContainer = AceGUI:Create("InlineGroup");
    scrollContainer:SetTitle("Requests");
    scrollContainer:SetFullWidth(true);
    scrollContainer:SetFullHeight(true);
    scrollContainer:SetLayout("Flow");
    window:AddChild(scrollContainer);
    window:SetUserData("requestsTitle", scrollContainer);

    local columns = { "Player", "Rank", "EP", "GP", "Priority", "Equipped", "Request", "Roll", "Notes", weights = { unpack(widths) } };
    local header = AceGUI:Create("SimpleGroup");
    header:SetFullWidth(true);
    header:SetLayout("Table");
    header:SetUserData("table", { columns = columns.weights });
    scrollContainer:AddChild(header);

    for i = 1, #columns do
        local desc = AceGUI:Create("Label");
        desc:SetText(columns[i] .. "\n");
        desc:SetFontObject(_G.GameFontHighlight);
        header:AddChild(desc);
    end

    local scroll = AceGUI:Create("ScrollFrame");
    scroll:SetFullWidth(true);
    scroll:SetFullHeight(true);
    scroll:SetLayout("List");
    scrollContainer:AddChild(scroll);
    window:SetUserData("requests", scroll);

    _G.ShowUIPanel(_G.ItemRefTooltip);
    _G.ItemRefTooltip:SetOwner(window.frame, "ANCHOR_NONE");
    _G.ItemRefTooltip:SetPoint("TOPLEFT", window.frame, "TOPRIGHT");
    _G.ItemRefTooltip:SetHyperlink(itemLink);
    _G.ItemRefTooltip:Show();

    activeDistributionWindow = window;

    if self.Debug then
        local testBase = {
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
            entry.roll = math.random(1, 100);
            ProcessNewData(entry);
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

        ABGP:SendComm(ABGP.CommTypes.ITEM_DISTRIBUTION_AWARDED, {
            itemLink = data.itemLink,
            player = data.player,
            cost = data.cost
        }, "BROADCAST");

        window:SetUserData("closeConfirmed", true);
        if window:GetUserData("multipleItems") then
            window:GetUserData("multipleItemsCheckbox"):SetDisabled(true);
            if window:GetUserData("distributionCount") then
                window:SetUserData("distributionCount", window:GetUserData("distributionCount") + 1);
            else
                window:SetUserData("distributionCount", 1);
            end
        else
            window:Hide();
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

        ABGP:SendComm(ABGP.CommTypes.ITEM_DISTRIBUTION_TRASHED, {
            itemLink = data.itemLink
        }, "BROADCAST");

        window:SetUserData("closeConfirmed", true);
        if window:GetUserData("multipleItems") then
            window:GetUserData("multipleItemsCheckbox"):SetDisabled(true);
            if window:GetUserData("distributionCount") then
                window:SetUserData("distributionCount", window:GetUserData("distributionCount") + 1);
            else
                window:SetUserData("distributionCount", 1);
            end
        else
            window:Hide();
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

        window:SetUserData("closeConfirmed", true);
        window:Hide();
	end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    exclusive = true,
    showAlert = true,
};
