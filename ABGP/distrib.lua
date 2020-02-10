local AceGUI = LibStub("AceGUI-3.0");

local activeDistributionWindow;
local widths = { 110, 90, 65, 180, 35, 1.0 };

local function ProcessSelectedData()
    local window = activeDistributionWindow;
    local data = window:GetUserData("selectedData");

    window:GetUserData("distributeButton"):SetDisabled(data == nil);
    if not window:GetUserData("costEdited") then
        window:GetUserData("costEdit"):SetText((data and data.role == "OS") and 0 or window:GetUserData("costBase"));
    end
end

local function RebuildUI()
    local window = activeDistributionWindow;
    local data = window:GetUserData("data");
    local requests = window:GetUserData("requests");

    local requestsHeader = requests.children[1];
    table.remove(requests.children, 1);
    requests:ReleaseChildren();
    requests:AddChild(requestsHeader);

    local selectedData = window:GetUserData("selectedData");
    window:SetUserData("selectedData", nil);
    window:SetUserData("selectedElt", nil);
    ProcessSelectedData();

    for i, existing in ipairs(data) do
        local elt = AceGUI:Create("ABGP_DistribPlayer");
        elt:SetFullWidth(true);
        elt:SetData(existing);
        elt:SetWidths(widths);
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

local function ProcessNewData(entry)
    local window = activeDistributionWindow;
    local data = window:GetUserData("data");

    for i, existing in ipairs(data) do
        if existing.player == entry.player then
            table.remove(data, i);
            break;
        end
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

    local priority = 0;
    local epgp = ABGP:GetActivePlayer(sender);
    local itemName = GetItemInfo(itemLink);
    local value = ABGP:GetItemValue(itemName);

    if epgp and epgp[value.phase] then
        priority = epgp[value.phase].ratio;
    end

    ProcessNewData({
        player = sender,
        rank = guildRankName,
        priority = priority,
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
    local itemName = GetItemInfo(itemLink);
    local value = ABGP:GetItemValue(itemName);
    if not value then return; end

    if activeDistributionWindow then
        activeDistributionWindow:SetUserData("owner", UnitName("player"));
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
    local itemName = GetItemInfo(itemLink);
    local value = self:GetItemValue(itemName);
    if not value then return; end

    -- Only privileged users will see the distribution UI.
    if not self:IsPrivileged() then return; end

    if activeDistributionWindow then
        self:Error("Received DISTRIB_OPENED with an active window!");
        activeDistributionWindow:SetUserData("owner", nil);
        activeDistributionWindow:Hide();
    end

    local window = AceGUI:Create("Window");
    local oldMinW, oldMinH = window.frame:GetMinResize();
    local oldMaxW, oldMaxH = window.frame:GetMaxResize();
    window:SetWidth(750);
    window:SetHeight(425);
    window.frame:SetMinResize(600, 300);
    window.frame:SetMaxResize(900, 500);
    window.frame:SetFrameStrata("HIGH");
    window:SetTitle("Loot Distribution: " .. itemLink);
    window:SetCallback("OnClose", function(widget)
        local owned = (widget:GetUserData("owner") == UnitName("player"));
        if not owned or widget:GetUserData("closeConfirmed") then
            activeDistributionWindow = nil;

            if owned then
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
    window:SetUserData("owner", sender);

    local distrib = AceGUI:Create("Button");
    distrib:SetWidth(100);
    distrib:SetText("Distribute");
    distrib:SetDisabled(true);
    distrib:SetCallback("OnClick", function(widget)
        local cost = tonumber(window:GetUserData("costEdit"):GetText());
        local player = window:GetUserData("selectedData").player;

        self:SendComm({
            type = self.CommTypes.ITEM_DISTRIBUTION_AWARDED,
            itemLink = itemLink,
            player = player,
            cost = cost
        }, "BROADCAST");
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

    local scrollContainer = AceGUI:Create("InlineGroup");
    scrollContainer:SetTitle("Requests");
    scrollContainer:SetFullWidth(true);
    scrollContainer:SetFullHeight(true);
    scrollContainer:SetLayout("Fill");
    window:AddChild(scrollContainer);
    window:SetUserData("requestsTitle", scrollContainer);

    local scroll = AceGUI:Create("ScrollFrame");
    scroll:SetFullWidth(true);
    scroll:SetLayout("List");
    scrollContainer:AddChild(scroll);
    window:SetUserData("requests", scroll);

    local columns = { "Player", "Rank", "Priority", "Equipped", "Role", "Notes", weights = { unpack(widths) } };
    local header = AceGUI:Create("SimpleGroup");
    header:SetFullWidth(true);
    header:SetLayout("Table");
    header:SetUserData("table", { columns = columns.weights});
    scroll:AddChild(header);

    for i = 1, #columns do
        local desc = AceGUI:Create("Label");
        desc:SetText(columns[i]);
        header:AddChild(desc);
    end

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
            entry.priority = math.random() * 50;
            ProcessNewData(entry);
        end
    end
end

function ABGP:DistribOnDistAwarded(data, distribution, sender)
    if activeDistributionWindow then
        if activeDistributionWindow:GetUserData("itemLink") ~= data.itemLink then
            self:Error("Received DISTRIB_CLOSED for mismatched item!");
        end
        activeDistributionWindow:SetUserData("owner", nil);
        activeDistributionWindow:Hide();
    end
end

function ABGP:DistribOnDistClosed(data, distribution, sender)
    if activeDistributionWindow then
        if activeDistributionWindow:GetUserData("itemLink") ~= data.itemLink then
            self:Error("Received DISTRIB_CLOSED for mismatched item!");
        end
        activeDistributionWindow:SetUserData("owner", nil);
        activeDistributionWindow:Hide();
    end
end

StaticPopupDialogs["ABGP_CONFIRM_END_DIST"] = {
    text = "Are you sure you want to end distribution?",
    button1 = "I'm sure",
    button2 = "Nevermind",
	OnAccept = function(self, data)
        if activeDistributionWindow then
            activeDistributionWindow:SetUserData("closeConfirmed", true);
            activeDistributionWindow:Hide();
        end
	end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
};
