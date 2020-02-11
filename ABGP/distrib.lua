local AceGUI = LibStub("AceGUI-3.0");

local activeDistributionWindow;
local widths = { 110, 90, 60, 60, 60, 180, 35, 1.0 };

local function ProcessSelectedData()
    local window = activeDistributionWindow;
    local data = window:GetUserData("selectedData");

    window:GetUserData("disenchantButton"):SetDisabled(data ~= nil);
    window:GetUserData("distributeButton"):SetDisabled(data == nil);
    if not window:GetUserData("costEdited") then
        window:GetUserData("costEdit"):SetText((data and data.role == "OS") and 0 or window:GetUserData("costBase"));
    end
end

local function RebuildUI()
    local window = activeDistributionWindow;
    local data = window:GetUserData("data");
    local requests = window:GetUserData("requests");
    requests:ReleaseChildren();

    local selectedData = window:GetUserData("selectedData");
    window:SetUserData("selectedData", nil);
    window:SetUserData("selectedElt", nil);
    ProcessSelectedData();

    local msHeading, osHeading;
    for i, existing in ipairs(data) do
        if existing.role == "MS" and not msHeading then
            msHeading = true;
            local mainspec = AceGUI:Create("Heading");
            mainspec:SetFullWidth(true);
            mainspec:SetText("Main Spec");
            requests:AddChild(mainspec);
        end
        if existing.role == "OS" and not osHeading then
            osHeading = true;
            local offspec = AceGUI:Create("Heading");
            offspec:SetFullWidth(true);
            offspec:SetText("Off Spec");
            requests:AddChild(offspec);
        end
        local elt = AceGUI:Create("ABGP_DistribPlayer");
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
    end

    local nRequests = #requests.children - 1;
    window:GetUserData("requestsTitle"):SetTitle(string.format("Requests%s",
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
            table.remove(data, i);
            break;
        end
    end

    local pending = window:GetUserData("pendingWhispers");
    if pending and pending[entry.player] then
        entry.notes = CombineNotes(pending[entry.player], entry.notes);
        pending[entry.player] = nil;
    end

    table.insert(data, entry);

    table.sort(data, function(a, b)
        if a.role ~= b.role then
            return a.role == "MS";
        elseif a.priority ~= b.priority then
            return a.priority > b.priority;
        else
            return a.player < b.player;
        end
    end);

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

local whisperFrame = CreateFrame("Frame");
whisperFrame:RegisterEvent("CHAT_MSG_WHISPER");
whisperFrame:RegisterEvent("CHAT_MSG_BN_WHISPER");
whisperFrame:SetScript("OnEvent", function(self, event, ...)
    if not activeDistributionWindow then
        return;
    end
    local window = activeDistributionWindow;

    local msg, sender, _;
    if event == "CHAT_MSG_WHISPER" then
        msg, _, _, _, sender = ...;
    elseif event == "CHAT_MSG_BN_WHISPER" then
        msg = ...;
        local bnetId = select(13, ...);
        sender = GetPlayerFromBNet(bnetId);
    end

    local found = false;
    if msg and sender and UnitExists(sender) then
        local requests = window:GetUserData("requests");
        for _, elt in ipairs(requests.children) do
            if elt.data and elt.data.player == sender then
                elt.data.notes = CombineNotes(elt.data.notes, msg);
                elt:SetData(elt.data);
                found = true;
                break;
            end
        end
    end

    if not found then
        if not window:GetUserData("pendingWhispers") then
            window:SetUserData("pendingWhispers", {});
        end
        local pending = window:GetUserData("pendingWhispers");
        pending[sender] = CombineNotes(pending[sender], msg);
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

    local roles = {
        ["ms"] = "main spec",
        ["os"] = "off spec",
    };
    ABGP:Notify("%s is requesting %s for %s.", ABGP:ColorizeName(sender), itemLink, roles[data.role]);

    local priority, ep, gp = 0, 0, 0;
    local epgp = ABGP:GetActivePlayer(sender);
    local itemName = string.match(itemLink, "%[(.*)%]");
    local value = ABGP:GetItemValue(itemName);

    if epgp and epgp[value.phase] then
        priority = epgp[value.phase].ratio;
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
        role = strupper(data.role),
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

function ABGP:ShowDistrib(itemLink)
    local itemName = string.match(itemLink, "%[(.*)%]");
    local value = ABGP:GetItemValue(itemName);
    if not value then return; end

    if activeDistributionWindow then
        activeDistributionWindow:SetUserData("closeConfirmed", true);
        activeDistributionWindow:Hide();
    end

    self:SendComm({
        type = self.CommTypes.ITEM_DISTRIBUTION_OPENED,
        itemLink = itemLink
    }, "BROADCAST");
end

function ABGP:DistribOnDistOpened(data, distribution, sender)
    local itemLink = data.itemLink;
    local itemName = string.match(itemLink, "%[(.*)%]");
    local value = self:GetItemValue(itemName);
    if not value then return; end

    if sender ~= UnitName("player") then return; end

    local window = AceGUI:Create("Window");
    local oldMinW, oldMinH = window.frame:GetMinResize();
    local oldMaxW, oldMaxH = window.frame:GetMaxResize();
    window:SetWidth(900);
    window:SetHeight(425);
    window.frame:SetMinResize(700, 300);
    window.frame:SetMaxResize(1000, 500);
    window.frame:SetFrameStrata("HIGH");
    window:SetTitle("Loot Distribution: " .. itemLink);
    window:SetCallback("OnClose", function(widget)
        local primary = widget:GetUserData("primary");
        if not primary or widget:GetUserData("closeConfirmed") then
            activeDistributionWindow = nil;

            if primary then
                self:SendComm({
                    type = self.CommTypes.ITEM_DISTRIBUTION_CLOSED,
                    itemLink = itemLink
                }, "BROADCAST");
            end

            widget.frame:SetMinResize(oldMinW, oldMinH);
            widget.frame:SetMaxResize(oldMaxW, oldMaxH);
            AceGUI:Release(widget);
            ItemRefTooltip:Hide();
        else
            StaticPopup_Show("ABGP_CONFIRM_END_DIST");
            widget:Show();
        end
    end);
    window:SetLayout("Flow");
    window:SetUserData("itemLink", itemLink);
    window:SetUserData("data", {});
    window:SetUserData("primary", true);

    local disenchant = AceGUI:Create("Button");
    disenchant:SetWidth(100);
    disenchant:SetText("Disenchant");
    disenchant:SetCallback("OnClick", function(widget)
        StaticPopup_Show("ABGP_CONFIRM_TRASH", itemLink, nil, {
            itemLink = itemLink
        });
    end);
    window:AddChild(disenchant);
    window:SetUserData("disenchantButton", disenchant);

    local distrib = AceGUI:Create("Button");
    distrib:SetWidth(100);
    distrib:SetText("Distribute");
    distrib:SetDisabled(true);
    distrib:SetCallback("OnClick", function(widget)
        local cost = tonumber(window:GetUserData("costEdit"):GetText());
        local player = window:GetUserData("selectedData").player;
        local award = string.format("%s for %d gp", ABGP:ColorizeName(player), cost);

        StaticPopup_Show("ABGP_CONFIRM_DIST", itemLink, award, {
            itemLink = itemLink,
            player = player,
            cost = cost
        });
    end);
    window:AddChild(distrib);
    window:SetUserData("distributeButton", distrib);

    local cost = AceGUI:Create("EditBox");
    cost:SetWidth(75);
    cost:SetText(value.gp);
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
    window:SetUserData("costBase", value.gp);

    local desc = AceGUI:Create("Label");
    desc:SetWidth(50);
    desc:SetText("Cost");
    window:AddChild(desc);

    local multiple = AceGUI:Create("CheckBox");
    multiple:SetLabel("Multiple");
    multiple:SetCallback("OnValueChanged", function(widget, value)
        window:SetUserData("multipleItems", value);
    end);
    window:AddChild(multiple);

    local scrollContainer = AceGUI:Create("InlineGroup");
    scrollContainer:SetTitle("Requests");
    scrollContainer:SetFullWidth(true);
    scrollContainer:SetFullHeight(true);
    scrollContainer:SetLayout("Flow");
    window:AddChild(scrollContainer);
    window:SetUserData("requestsTitle", scrollContainer);

    local columns = { "Player", "Rank", "EP", "GP", "Priority", "Equipped", "Role", "Notes", weights = { unpack(widths) } };
    local header = AceGUI:Create("SimpleGroup");
    header:SetFullWidth(true);
    header:SetLayout("Table");
    header:SetUserData("table", { columns = columns.weights});
    scrollContainer:AddChild(header);

    for i = 1, #columns do
        local desc = AceGUI:Create("Label");
        desc:SetText(columns[i] .. "\n");
        desc:SetFontObject(GameFontHighlight);
        header:AddChild(desc);
    end

    local scroll = AceGUI:Create("ScrollFrame");
    scroll:SetFullWidth(true);
    scroll:SetFullHeight(true);
    scroll:SetLayout("List");
    scrollContainer:AddChild(scroll);
    window:SetUserData("requests", scroll);

    ShowUIPanel(ItemRefTooltip);
    ItemRefTooltip:SetOwner(window.frame, "ANCHOR_NONE");
    ItemRefTooltip:SetPoint("TOPLEFT", window.frame, "TOPRIGHT");
    ItemRefTooltip:SetHyperlink(itemLink);
    ItemRefTooltip:Show();

    activeDistributionWindow = window;

    if self.Debug then
        local testBase = {
            rank = "Blue Lobster",
            notes = "This is a custom note. It is very long. Why would someone leave a note this long? It's a mystery for sure. But people can, so here it is.",
            equipped = {
                "\124cffff8000\124Hitem:19019::::::::60:::::\124h[Thunderfury, Blessed Blade of the Windseeker]\124h\124r",
                "\124cffff8000\124Hitem:17182::::::::60:::::\124h[Sulfuras, Hand of Ragnaros]\124h\124r"
            },
        };
        for i = 1, 9 do
            local entry = {};
            for k, v in pairs(testBase) do entry[k] = v; end
            entry.player = "TestTestPlayer" .. i;
            entry.role = math.random() < 0.5 and "MS" or "OS";
            entry.ep = math.random() * 2000;
            entry.gp = math.random() * 2000;
            entry.priority = entry.ep * 10 / entry.gp;
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

        ABGP:SendComm({
            type = ABGP.CommTypes.ITEM_DISTRIBUTION_AWARDED,
            itemLink = data.itemLink,
            player = data.player,
            cost = data.cost
        }, "BROADCAST");

        window:SetUserData("closeConfirmed", true);
        if window:GetUserData("multipleItems") then
            local entries = window:GetUserData("data");
            for i, existing in ipairs(entries) do
                if existing.player == data.player then
                    table.remove(entries, i);
                    RebuildUI();
                    break;
                end
            end
        else
            window:Hide();
        end
	end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
};

StaticPopupDialogs["ABGP_CONFIRM_TRASH"] = {
    text = "Disenchant %s?",
    button1 = "Yes",
    button2 = "No",
    OnAccept = function(self, data)
        if not activeDistributionWindow then return; end
        local window = activeDistributionWindow;

        ABGP:SendComm({
            type = ABGP.CommTypes.ITEM_DISTRIBUTION_TRASHED,
            itemLink = data.itemLink
        }, "BROADCAST");

        window:SetUserData("closeConfirmed", true);
        if not window:GetUserData("multipleItems") then
            window:Hide();
        end
	end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
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
};
