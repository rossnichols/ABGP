local AceGUI = LibStub("AceGUI-3.0");

do
    local Type, Version = "ABGP_DistribPlayer", 1;

    --[[-----------------------------------------------------------------------------
    Methods
    -------------------------------------------------------------------------------]]
    local methods = {
        ["OnAcquire"] = function(self)
            self.player.text:SetText("");
            self.rank.text:SetText("");
            self.priority.text:SetText("");
            self.equipped.textTop:SetText("");
            self.equipped.textMid:SetText("");
            self.equipped.textBot:SetText("");
            self.role.text:SetText("");
            self.notes.text:SetText("");
            self.msg.text:SetText("");

            self.equipped:Show();
            self.role:Show();
            self.notes:Show();
            self.msg:Show();

            self.frame.highlightRequests = 0;
            self.frame:UnlockHighlight();
        end,

        ["SetData"] = function(self, data)
            self.data = data;

            self.player.text:SetText(ABGP:ColorizeName(data.player or ""));
            self.rank.text:SetText(data.rank or "");
            self.priority.text:SetText(string.format("%.3f", data.priority or 0));
            if data.msg then
                self.msg.text:SetText(data.msg);
                self.equipped:Hide();
                self.role:Hide();
                self.notes:Hide();
            else
                self.msg:Hide();
                if data.equipped then
                    if #data.equipped == 2 then
                        self.equipped.textTop:SetText(data.equipped[1]);
                        self.equipped.textBot:SetText(data.equipped[2]);
                    elseif #data.equipped == 1 then
                        self.equipped.textMid:SetText(data.equipped[1]);
                    end
                end
                self.role.text:SetText(data.role or "");
                self.notes.text:SetText(data.notes or "--");
            end
        end,
    }

    --[[-----------------------------------------------------------------------------
    Constructor
    -------------------------------------------------------------------------------]]
    local function Constructor()
        local itemLink = GetInventoryItemLink("player", 1);

        local frame = CreateFrame("Button", nil, UIParent);
        frame:SetHeight(25);
        frame:Hide();

        frame.highlightRequests = 0;
        frame.RequestHighlight = function(self, enable)
            self.highlightRequests = self.highlightRequests + (enable and 1 or -1);
            self[self.highlightRequests > 0 and "LockHighlight" or "UnlockHighlight"](self);
        end;

        local function createElement(frame, anchor)
            local elt = CreateFrame("Button", nil, frame);
            elt:SetHeight(frame:GetHeight());
            elt:EnableMouse(true);
            elt:SetHyperlinksEnabled(true);
            elt:SetScript("OnHyperlinkEnter", function(self, itemLink)
                ShowUIPanel(GameTooltip);
                GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR");
                GameTooltip:SetHyperlink(itemLink);
                GameTooltip:Show();
                self:GetParent():RequestHighlight(true);
            end);
            elt:SetScript("OnHyperlinkLeave", function(self)
                GameTooltip:Hide();
                self:GetParent():RequestHighlight(false);
            end);
            elt:SetScript("OnEnter", function(self)
                self:GetParent():RequestHighlight(true);
            end);
            elt:SetScript("OnLeave", function(self)
                self:GetParent():RequestHighlight(false);
            end);
            elt:SetScript("OnClick", function(self, ...)
                self:GetParent().obj:Fire("OnClick", ...)
            end);

            if anchor then
                elt:SetPoint("TOPLEFT", anchor, "TOPRIGHT");
            else
                elt:SetPoint("TOPLEFT", frame);
            end

            return elt;
        end

        local function createFontString(frame, y)
            local fontstr = frame:CreateFontString(nil, "BACKGROUND", "GameFontNormalSmall");
            fontstr:SetJustifyH("LEFT");
            if y then
                fontstr:SetPoint("LEFT", frame, 0, y);
                fontstr:SetPoint("RIGHT", frame, -2, y);
            else
                fontstr:SetPoint("TOPLEFT", frame, 0, 0);
                fontstr:SetPoint("BOTTOMRIGHT", frame, -2, 0);
            end
            fontstr:SetWordWrap(false);

            return fontstr;
        end

        local highlight = frame:CreateTexture(nil, "HIGHLIGHT");
        highlight:SetTexture("Interface\\HelpFrame\\HelpFrameButton-Highlight");
        highlight:SetAllPoints();
        highlight:SetBlendMode("ADD");
        highlight:SetTexCoord(0, 1, 0, 0.578125);

        local player = createElement(frame);
        player:SetWidth(100);
        player.text = createFontString(player);

        local rank = createElement(frame, player);
        rank:SetWidth(80);
        rank.text = createFontString(rank);

        local priority = createElement(frame, rank);
        priority:SetWidth(60);
        priority.text = createFontString(priority);

        local equipped = createElement(frame, priority);
        equipped:SetWidth(150);
        equipped.textTop = createFontString(equipped, 5);
        equipped.textMid = createFontString(equipped);
        equipped.textBot = createFontString(equipped, -5);

        local role = createElement(frame, equipped);
        role:SetWidth(40);
        role.text = createFontString(role);

        local notes = createElement(frame, role);
        notes:SetPoint("TOPRIGHT", frame);
        notes.text = createFontString(notes);
        notes.text:SetWordWrap(true);
        notes:SetScript("OnEnter", function(self)
            if self.text:IsTruncated() then
                local text = self.text:GetText();
                ShowUIPanel(GameTooltip);
                GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR");
                GameTooltip:SetText(self.text:GetText(), 1, 1, 1, 1, true);
                GameTooltip:Show();
            end
            self:GetParent():RequestHighlight(true);
        end);
        notes:SetScript("OnLeave", function(self)
            GameTooltip:Hide();
            self:GetParent():RequestHighlight(false);
        end);

        local msg = createElement(frame, priority);
        msg:SetPoint("TOPRIGHT", frame);
        msg.text = createFontString(msg);
        msg.text:SetWordWrap(true);
        msg:SetScript("OnEnter", function(self)
            if self.text:IsTruncated() then
                local text = self.text:GetText();
                ShowUIPanel(GameTooltip);
                GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR");
                GameTooltip:SetText(self.text:GetText(), 1, 1, 1, 1, true);
                GameTooltip:Show();
            end
            self:GetParent():RequestHighlight(true);
        end);
        msg:SetScript("OnLeave", function(self)
            GameTooltip:Hide();
            self:GetParent():RequestHighlight(false);
        end);

        -- create widget
        local widget = {
            player = player,
            rank = rank,
            priority = priority,
            equipped = equipped,
            role = role,
            notes = notes,
            msg = msg,

            frame = frame,
            type  = Type
        }
        for method, func in pairs(methods) do
            widget[method] = func
        end

        return AceGUI:RegisterAsWidget(widget)
    end

    AceGUI:RegisterWidgetType(Type, Constructor, Version)
end

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
    if not activeDistributionWindow or ABGP.ActiveDistributions == 0 then
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

function ABGP:InitItemDistribution()
    self:RegisterMessage(self.CommTypes.ITEM_REQUEST, function(self, event, data, distribution, sender)
        local itemLink = data.itemLink;
        if not activeDistributionWindow then
            ABGP:Notify("%s requested %s but there's no active distribution!", sender, itemLink);
            return;
        end

        local itemLinkCmp = activeDistributionWindow:GetUserData("itemLink");
        if itemLink ~= itemLinkCmp then
            ABGP:Notify("%s requested %s but you're distributing %s!", sender, itemLink, itemLinkCmp);
            return;
        end

        if not UnitExists(sender) then
            ABGP:Notify("%s requested %s but they're not grouped with you!", sender, itemLink);
            return;
        end

        local playerGuild = GetGuildInfo("player");
        local guildName, guildRankName = GetGuildInfo(sender);
        if guildName and guildName ~= playerGuild then
            guildRankName = "[Other guild]";
        end

        ProcessNewData({
            player = sender,
            rank = guildRankName,
            priority = 0, -- one day!
            equipped = data.equipped,
            role = strupper(data.role),
            notes = data.notes
        });
    end, self);

    self:RegisterMessage(self.CommTypes.ITEM_PASS, function(self, event, data, distribution, sender)
        local itemLink = data.itemLink;
        if not activeDistributionWindow then
            ABGP:Notify("%s requested %s but there's no active distribution!", sender, itemLink);
            return;
        end

        local itemLinkCmp = activeDistributionWindow:GetUserData("itemLink");
        if itemLink ~= itemLinkCmp then
            ABGP:Notify("%s requested %s but you're distributing %s!", sender, itemLink, itemLinkCmp);
            return;
        end

        if not UnitExists(sender) then
            ABGP:Notify("%s requested %s but they're not grouped with you!", sender, itemLink);
            return;
        end

        RemoveData(sender);
    end, self);
end

function ABGP:ShowDistrib(itemLink)
    local itemName = GetItemInfo(itemLink);
    local value = ABGP:GetItemValue(itemName);
    if not value then return; end

    if activeDistributionWindow then
        activeDistributionWindow:Hide();
        activeDistributionWindow = nil;
    end

    local window = AceGUI:Create("Window");
    local oldMinW, oldMinH = window.frame:GetMinResize();
    local oldMaxW, oldMaxH = window.frame:GetMaxResize();
    window:SetWidth(700);
    window:SetHeight(500);
    window.frame:SetMinResize(700, 500);
    window.frame:SetMaxResize(700, 500);
    window:SetTitle("Loot Distribution: " .. itemLink);
    window:SetCallback("OnClose", function(widget)
        -- self:CloseWindow(widget);
        activeDistributionWindow = nil;
        widget.frame:SetMinResize(oldMinW, oldMinH);
        widget.frame:SetMaxResize(oldMaxW, oldMaxH);
        AceGUI:Release(widget);
        ItemRefTooltip:Hide();

        self:SendComm({
            type = self.CommTypes.ITEM_DISTRIBUTION_CLOSED,
            itemLink = itemLink
        }, "BROADCAST");
    end);
    window:SetLayout("Flow");
    -- self:OpenWindow(window);

    local distrib = AceGUI:Create("Button");
    distrib:SetWidth(100);
    distrib:SetText("Distribute");
    distrib:SetDisabled(true);
    distrib:SetCallback("OnClick", function(widget)
        local cost = tonumber(window:GetUserData("costEdit"):GetText());
        local player = window:GetUserData("selectedData").player;

        window:Hide();
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

    do
        local scrollContainer = AceGUI:Create("InlineGroup");
        scrollContainer:SetTitle("Requests");
        scrollContainer:SetFullWidth(true);
        scrollContainer:SetHeight(200);
        scrollContainer:SetLayout("Fill");
        window:AddChild(scrollContainer);
        window:SetUserData("requestsTitle", scrollContainer);

        local scroll = AceGUI:Create("ScrollFrame");
        scroll:SetFullWidth(true);
        scroll:SetLayout("List");
        scrollContainer:AddChild(scroll);

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
        window:SetUserData("requests", scroll);
    end

    do
        local scrollContainer = AceGUI:Create("InlineGroup");
        scrollContainer:SetTitle("Whispers");
        scrollContainer:SetFullWidth(true);
        scrollContainer:SetHeight(200);
        scrollContainer:SetLayout("Fill");
        window:AddChild(scrollContainer);
        window:SetUserData("whispersTitle", scrollContainer);

        local scroll = AceGUI:Create("ScrollFrame");
        scroll:SetFullWidth(true);
        scroll:SetLayout("List");
        scrollContainer:AddChild(scroll);

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
        window:SetUserData("whispers", scroll);
    end

    ShowUIPanel(ItemRefTooltip);
    ItemRefTooltip:SetOwner(window.frame, "ANCHOR_NONE");
    ItemRefTooltip:SetPoint("TOPLEFT", window.frame, "TOPRIGHT");
    ItemRefTooltip:SetHyperlink(itemLink);
    ItemRefTooltip:Show();

    window:SetUserData("itemLink", itemLink);
    window:SetUserData("data", {});
    activeDistributionWindow = window;
    self:SendComm({
        type = self.CommTypes.ITEM_DISTRIBUTION_OPENED,
        itemLink = itemLink
    }, "BROADCAST");

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
                entry.equipped = {};
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
