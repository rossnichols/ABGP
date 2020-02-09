local AceGUI = LibStub("AceGUI-3.0");

do
    local Type, Version = "ABGP_DistribPlayer", 1;

    --[[-----------------------------------------------------------------------------
    Support functions
    -------------------------------------------------------------------------------]]

    local function UpdateWidths(self)
        if self.resizing then return end
        local frame = self.frame;
        local weights = { 100, 80, 60, 200, 40, 1.0 };
        local width = frame:GetWidth();

        local spareWidth = width;
        local widths = {};
        for i, weight in ipairs(weights) do
            if weight > 1.0 then
                widths[i] = weight;
                spareWidth = spareWidth - weight;
            end
        end
        for i, weight in ipairs(weights) do
            if weight <= 1.0 then
                widths[i] = spareWidth * weight;
            end
        end

        self.player:SetWidth(widths[1]);
        self.rank:SetWidth(widths[2]);
        self.priority:SetWidth(widths[3]);
        self.current:SetWidth(widths[4]);
        self.role:SetWidth(widths[5]);
        self.notes:SetWidth(widths[6]);
    end

    --[[-----------------------------------------------------------------------------
    Methods
    -------------------------------------------------------------------------------]]
    local methods = {
        ["OnAcquire"] = function(self)
            -- set the flag to stop constant size updates
            self.resizing = true;

            -- reset the flag
            self.resizing = nil
        end,

        -- ["OnRelease"] = nil,

        ["OnWidthSet"] = function(self, width)
            self.frame:SetWidth(width);
            UpdateWidths(self);
        end,
    }

    --[[-----------------------------------------------------------------------------
    Constructor
    -------------------------------------------------------------------------------]]
    local function Constructor()
        local itemLink = GetInventoryItemLink("player", 1);

        local frame = CreateFrame("Button", nil, UIParent);
        frame:SetHeight(25);
        frame:EnableMouse(true);
        frame:SetHyperlinksEnabled(true);
        frame:Hide();

        -- frame:SetScript("OnClick", function(self)
        --     self.selected = not self.selected;
        --     if self.selected then
        --         self:LockHighlight();
        --     else
        --         self:UnlockHighlight();
        --     end
        -- end);
        frame:SetScript("OnHyperlinkEnter", function(self, itemLink)
            ShowUIPanel(GameTooltip);
            GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR");
            GameTooltip:SetHyperlink(itemLink);
            GameTooltip:Show();
            self:LockHighlight();
        end);
        frame:SetScript("OnHyperlinkLeave", function(self)
            GameTooltip:Hide();
            self:UnlockHighlight();
        end);

        local function createElement(frame, anchor)
            local elt = CreateFrame("Frame", nil, frame);
            elt:SetHeight(frame:GetHeight());

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
        player.text = createFontString(player);
        player.text:SetText("AbpSummonbot");

        local rank = createElement(frame, player);
        rank.text = createFontString(rank);
        rank.text:SetText("Red Lobster");

        local priority = createElement(frame, rank);
        priority.text = createFontString(priority);
        priority.text:SetText("888.888");

        local current = createElement(frame, priority);
        current.textTop = createFontString(current, 5);
        current.textMid = createFontString(current);
        current.textBot = createFontString(current, -5);
        current.textTop:SetText("\124cffff8000\124Hitem:19019::::::::60:::::\124h[Thunderfury, Blessed Blade of the Windseeker]\124h\124r");
        current.textBot:SetText("\124cffff8000\124Hitem:17182::::::::60:::::\124h[Sulfuras, Hand of Ragnaros]\124h\124r");

        local role = createElement(frame, current);
        role.text = createFontString(role);
        role.text:SetText("MS");

        local notes = createElement(frame, role);
        notes.text = createFontString(notes);
        notes.text:SetWordWrap(true);
        notes.text:SetText("This is a custom note. It is very long. Why would someone leave a note this long? It's a mystery for sure. But people can, so here it is.");
        notes:SetScript("OnEnter", function(self)
            ShowUIPanel(GameTooltip);
            GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR");
            GameTooltip:SetText(self.text:GetText(), 1, 1, 1, 1, true);
            GameTooltip:Show();
            self:GetParent():LockHighlight();
        end);
        notes:SetScript("OnLeave", function(self)
            GameTooltip:Hide();
            self:GetParent():UnlockHighlight();
        end);

        -- create widget
        local widget = {
            weights = weights,

            player = player,
            rank = rank,
            priority = priority,
            current = current,
            role = role,
            notes = notes,

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

function ABGP:InitItemDistribution()
    self:RegisterMessage(self.CommTypes.ITEM_REQUEST, function(self, event, data, distribution, sender)
        local itemLink = data.itemLink;
        if not activeDistributionWindow then return; end

        local playerGuild = GetGuildInfo("player");
        local guildName, guildRankName = GetGuildInfo(sender);
        if guildName and guildName ~= playerGuild then
            guildRankName = "[Different guild]";
        end

        local _, class = UnitClass(sender);

        local elt = AceGUI:Create("ABGP_DistribPlayer");
        elt:SetFullWidth(true);
        elt:SetWeights({ 100, 80, 60, 200, 40, 1.0 });
        elt:SetData({
            player = sender,
            playerColor = select(4, GetClassColor(class)),
            rank = guildRankName,
            priority = 50 * math.random(),
            current = data.equipped,
            role = strupper(data.role),
            notes = data.notes,
        });
        activeDistributionWindow:GetUserData("requests"):AddChild(elt);
    end, self);

    self:RegisterMessage(self.CommTypes.ITEM_PASS, function(self, event, data, distribution, sender)
        local itemLink = data.itemLink;
    end, self);
end

function ABGP:ShowDistrib(itemLink)
    local itemName = GetItemInfo(itemLink);
    local value = ABGP:GetItemValue(itemName);
    if not value then return; end

    if activeDistributionWindow then
        activeDistributionWindow.frame:Hide();
        activeDistributionWindow = nil;
    end

    local window = AceGUI:Create("Window");
    window:SetTitle("Loot Distribution")
    window:SetCallback("OnClose", function(widget)
        -- self:CloseWindow(widget);
        AceGUI:Release(widget);
        ItemRefTooltip:Hide();

        self:SendComm({
            type = self.CommTypes.ITEM_DISTRIBUTION_CLOSED,
            itemLink = itemLink
        }, "BROADCAST");
    end);
    window:SetLayout("Flow");
    window:SetWidth(800);
    window:SetHeight(500);
    -- self:OpenWindow(window);

    local distrib = AceGUI:Create("Button");
    distrib:SetWidth(100);
    distrib:SetText("Distribute");
    distrib:SetDisabled(true);
    window:AddChild(distrib);

    local cost = AceGUI:Create("EditBox");
    cost:SetWidth(75);
    cost:SetText(value.gp);
    window:AddChild(cost);
    cost:SetCallback("OnEnterPressed", function(widget) AceGUI:ClearFocus(); end);
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

        local scroll = AceGUI:Create("ScrollFrame");
        scroll:SetFullWidth(true);
        scroll:SetLayout("List");
        scrollContainer:AddChild(scroll);

        local columns = { "Player", "Rank", "Priority", "Current", "Role", "Notes", weights = { 100, 80, 60, 200, 40, 1.0 }};
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

        for i = 1, 20 do
            local player = AceGUI:Create("ABGP_DistribPlayer");
            player:SetFullWidth(true);
            scroll:AddChild(player);
        end
    end

    do
        local scrollContainer = AceGUI:Create("InlineGroup");
        scrollContainer:SetTitle("Whispers");
        scrollContainer:SetFullWidth(true);
        scrollContainer:SetHeight(200);
        scrollContainer:SetLayout("Fill");
        window:AddChild(scrollContainer);

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

    activeDistributionWindow = window;
    self:SendComm({
        type = self.CommTypes.ITEM_DISTRIBUTION_OPENED,
        itemLink = itemLink
    }, "BROADCAST");
end
