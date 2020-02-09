local AceGUI = LibStub("AceGUI-3.0");

local activeDistributionWindow;

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
    local whispers = window:GetUserData("whispers");

    local requestsHeader = requests.children[1];
    table.remove(requests.children, 1);
    local whispersHeader = whispers.children[1];
    table.remove(whispers.children, 1);

    requests:ReleaseChildren();
    requests:AddChild(requestsHeader);
    whispers:ReleaseChildren();
    whispers:AddChild(whispersHeader);

    local selectedData = window:GetUserData("selectedData");
    window:SetUserData("selectedData", nil);
    window:SetUserData("selectedElt", nil);
    ProcessSelectedData();

    for i, existing in ipairs(data) do
        local elt = AceGUI:Create("ABGP_DistribPlayer");
        elt:SetFullWidth(true);
        elt:SetData(existing);
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

        if existing.msg then
            whispers:AddChild(elt);
        else
            requests:AddChild(elt);
        end

        if selectedData and existing.player == selectedData.player then
            elt:Fire("OnClick");
        end
    end

    local nRequests = #requests.children - 1;
    window:GetUserData("requestsTitle"):SetTitle(string.format("Requests%s",
        nRequests > 0 and " (" .. nRequests .. ")" or ""));
    local nWhispers = #whispers.children - 1;
    window:GetUserData("whispersTitle"):SetTitle(string.format("Whispers%s",
    nWhispers > 0 and " (" .. nWhispers .. ")" or ""));
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

    entry.timestamp = time();

    local insert = true;
    for i, existing in ipairs(data) do
        if existing.player == entry.player then
            local existingWhisper = (existing.msg ~= nil);
            local newWhisper = (entry.msg ~= nil);
            if existingWhisper then
                if newWhisper then
                    -- If the existing entry is a whisper, and the new one is as well,
                    -- remove the existing entry and prepend its msg contents to the new msg.
                    table.remove(data, i);
                    entry.msg = existing.msg .. "\n" .. entry.msg;
                else
                    -- If the existing entry is a whisper, and the new one is a request,
                    -- remove the existing entry but prepend its msg contents to the notes.
                    table.remove(data, i);
                    if entry.notes then
                        entry.notes = existing.msg .. "\n" .. entry.notes;
                    else
                        entry.notes = existing.msg;
                    end
                end
            else
                if newWhisper then
                    -- If the existing entry is a request, and the new one is a whisper,
                    -- modify the existing entry with the new msg.
                    insert = false;
                    if existing.notes then
                        existing.notes = existing.notes .. "\n" .. entry.msg;
                    else
                        existing.notes = entry.msg;
                    end
                else
                    -- If the existing entry is a request, and the new one is as well,
                    -- remove the existing entry without preserving any data.
                    table.remove(data, i);
                end
            end
            break;
        end
    end

    if insert then
        table.insert(data, entry);
    end

    table.sort(data, function(a, b)
        if a.priority ~= b.priority then
            return a.priority > b.priority;
        elseif (a.msg ~= nil) ~= (b.msg ~= nil) then
            return a.msg ~= nil;
        elseif a.msg ~= nil then
            if a.timestamp ~= b.timestamp then
                return a.timestamp < b.timestamp;
            else
                return a.player < b.player;
            end
        elseif a.role ~= b.role then
            return a.role == "MS";
        elseif a.timestamp ~= b.timestamp then
            return a.timestamp < b.timestamp;
        else
            return a.player < b.player;
        end
    end);

    RebuildUI();
end

local whisperFrame = CreateFrame("Frame");
whisperFrame:RegisterEvent("CHAT_MSG_WHISPER");
whisperFrame:RegisterEvent("CHAT_MSG_BN_WHISPER");
whisperFrame:SetScript("OnEvent", function(self, event, ...)
    if not activeDistributionWindow then
        return;
    end

    local msg, sender, _;
    if event == "CHAT_MSG_WHISPER" then
        msg, _, _, _, sender = ...;
    elseif event == "CHAT_MSG_BN_WHISPER" then
        msg = ...;
        local bnetId = select(13, ...);
        local _, characterName, clientProgram, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, wowProjectID = BNGetGameAccountInfo(bnetId);
        local gameInfo = C_BattleNet.GetGameAccountInfoByID(bnetId);
        if clientProgram == BNET_CLIENT_WOW and wowProjectID == WOW_PROJECT_CLASSIC then
            sender = characterName;
        end
    end

    if ABGP.Debug then
        ABGP:Notify("Whisper from %s: %s", sender, msg);
    end

    if msg and sender and UnitExists(sender) then
        local playerGuild = GetGuildInfo("player");
        local guildName, guildRankName = GetGuildInfo(sender);
        if guildName and guildName ~= playerGuild then
            guildRankName = "[Other guild]";
        end

        ProcessNewData({
            player = sender,
            rank = guildRankName,
            priority = 0, -- one day!
            msg = msg
        });
    end
end);

function ABGP:DistribOnItemRequest(data, distribution, sender)
    local itemLink = data.itemLink;
    if not activeDistributionWindow then return; end

    -- Check if the sender is grouped with us
    if not UnitExists(sender) then return; end

    -- Check if this is our own reflected message
    if distribution == "OFFICER" and sender == UnitName("player") then return; end

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

    ProcessNewData({
        player = sender,
        rank = guildRankName,
        priority = 0, -- one day!
        equipped = data.equipped,
        role = strupper(data.role),
        notes = data.notes
    });

    -- reflect into officer channel
    if distribution == "WHISPER" then
        self:SendComm(data, "OFFICER");
    end
end

function ABGP:DistribOnItemPass(data, distribution, sender)
    local itemLink = data.itemLink;
    if not activeDistributionWindow then return; end

    -- Check if the sender is grouped with us
    if not UnitExists(sender) then return; end

    -- Check if this is our own reflected message
    if distribution == "OFFICER" and sender == UnitName("player") then return; end

    local itemLinkCmp = activeDistributionWindow:GetUserData("itemLink");
    if itemLink ~= itemLinkCmp then
        self:Error("%s passed on %s but you're distributing %s!", sender, itemLink, itemLinkCmp);
        return;
    end

    RemoveData(sender);

    -- reflect into officer channel
    if distribution == "WHISPER" then
        self:SendComm(data, "OFFICER");
    end
end

function ABGP:ShowDistrib(itemLink)
    local itemName = GetItemInfo(itemLink);
    local value = ABGP:GetItemValue(itemName);
    if not value then return; end

    if activeDistributionWindow then
        activeDistributionWindow:SetUserData("owner", UnitName("player"));
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
    window:SetWidth(700);
    window:SetHeight(500);
    window.frame:SetMinResize(600, 300);
    window.frame:SetMaxResize(800, 700);
    window:SetTitle("Loot Distribution: " .. itemLink);
    window:SetCallback("OnClose", function(widget)
        -- self:CloseWindow(widget);
        activeDistributionWindow = nil;

        if widget:GetUserData("owner") == UnitName("player") then
            self:SendComm({
                type = self.CommTypes.ITEM_DISTRIBUTION_CLOSED,
                itemLink = itemLink
            }, "BROADCAST");
        end

        widget.frame:SetMinResize(oldMinW, oldMinH);
        widget.frame:SetMaxResize(oldMaxW, oldMaxH);
        AceGUI:Release(widget);
        ItemRefTooltip:Hide();
    end);
    window:SetLayout("Flow");
    window:SetUserData("itemLink", itemLink);
    window:SetUserData("data", {});
    window:SetUserData("owner", sender);
    -- self:OpenWindow(window);

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

    local container = AceGUI:Create("SimpleGroup");
    container:SetFullWidth(true);
    container:SetFullHeight(true);
    container:SetLayout("List");
    container:SetUserData("table", { columns = { 1.0 } });
    window:AddChild(container);

    do
        local scrollContainer = AceGUI:Create("InlineGroup");
        scrollContainer:SetTitle("Requests");
        scrollContainer:SetFullWidth(true);
        scrollContainer:SetHeight(container.frame:GetHeight() / 2);
        scrollContainer:SetLayout("Fill");
        scrollContainer:SetAutoAdjustHeight(false);
        container:AddChild(scrollContainer);
        window:SetUserData("requestsTitle", scrollContainer);

        local scroll = AceGUI:Create("ScrollFrame");
        scroll:SetFullWidth(true);
        scroll:SetLayout("List");
        scrollContainer:AddChild(scroll);
        window:SetUserData("requests", scroll);

        local columns = { "Player", "Rank", "Priority", "Equipped", "Role", "Notes", weights = { 100, 80, 60, 150, 40, 1.0 }};
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
    end

    do
        local scrollContainer = AceGUI:Create("InlineGroup");
        scrollContainer:SetTitle("Whispers");
        scrollContainer:SetFullWidth(true);
        scrollContainer:SetHeight(container.frame:GetHeight() / 2);
        scrollContainer:SetLayout("Fill");
        scrollContainer:SetAutoAdjustHeight(false);
        container:AddChild(scrollContainer);
        window:SetUserData("whispersTitle", scrollContainer);

        local scroll = AceGUI:Create("ScrollFrame");
        scroll:SetFullWidth(true);
        scroll:SetLayout("List");
        scrollContainer:AddChild(scroll);
        window:SetUserData("whispers", scroll);

        local columns = { "Player", "Rank", "Priority", "Message", weights = { 100, 80, 60, 1.0 }};
        local header = AceGUI:Create("SimpleGroup");
        header:SetLayout("Table");
        header:SetUserData("table", { columns = columns.weights});
        scroll:AddChild(header);

        for i = 1, #columns do
            local desc = AceGUI:Create("Label");
            desc:SetText(columns[i]);
            header:AddChild(desc);
        end
    end

    container.frame:SetScript("OnSizeChanged", function(self)
        local height = self:GetHeight();
        window:GetUserData("requestsTitle"):SetHeight(height / 2);
        window:GetUserData("whispersTitle"):SetHeight(height / 2);
        container:DoLayout();
    end);
    container:SetCallback("OnRelease", function(widget)
        container.frame:SetScript("OnSizeChanged", nil);
    end);

    ShowUIPanel(ItemRefTooltip);
    ItemRefTooltip:SetOwner(window.frame, "ANCHOR_NONE");
    ItemRefTooltip:SetPoint("TOPLEFT", window.frame, "TOPRIGHT");
    ItemRefTooltip:SetHyperlink(itemLink);
    ItemRefTooltip:Show();

    activeDistributionWindow = window;

    if self.Debug then
        local testBase = {
            rank = "Test rank",
            priority = 0,
        };
        for i = 1, 10 do
            local entry = {};
            for k, v in pairs(testBase) do entry[k] = v; end
            entry.player = "TestPlayer" .. i;
            if math.random() < 0.5 then
                -- request
                entry.equipped = {
                    "\124cffff8000\124Hitem:19019::::::::60:::::\124h[Thunderfury, Blessed Blade of the Windseeker]\124h\124r",
                    "\124cffff8000\124Hitem:17182::::::::60:::::\124h[Sulfuras, Hand of Ragnaros]\124h\124r"
                };
                entry.role = math.random() < 0.5 and "MS" or "OS";
                entry.notes = "Test notes";
            else
                -- whisper
                entry.msg = "Test msg";
            end
            ProcessNewData(entry);
        end
    end

    -- for i = 1, 10 do
    --     local elt = AceGUI:Create("ABGP_DistribPlayer");
    --     elt:SetData({
    --         player = "AbpSummonbot",
    --         rank = "Red Lobster",
    --         priority = 50 * math.random(),
    --         equipped = { "\124cffff8000\124Hitem:19019::::::::60:::::\124h[Thunderfury, Blessed Blade of the Windseeker]\124h\124r",
    --             "\124cffff8000\124Hitem:17182::::::::60:::::\124h[Sulfuras, Hand of Ragnaros]\124h\124r" },
    --         role = "MS",
    --         notes = "This is a custom note. It is very long. Why would someone leave a note this long? It's a mystery for sure. But people can, so here it is.",
    --     });
    --     elt:SetFullWidth(true);
    --     scroll:AddChild(elt);
    -- end
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
