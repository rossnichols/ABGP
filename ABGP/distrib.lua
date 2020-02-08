local AceGUI = LibStub("AceGUI-3.0");

do
    local Type, Version = "ABGP_DistribPlayer", 1;

    --[[-----------------------------------------------------------------------------
    Support functions
    -------------------------------------------------------------------------------]]

    local function UpdateWidths(self)
        if self.resizing then return end
        local frame = self.frame;
        local weights = self.weights;
        local width = frame:GetWidth();

        self.player:SetWidth(weights[1] * width);
        self.priority:SetWidth(weights[2] * width);
        self.current:SetWidth(weights[3] * width);
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
        local weights = { 0.3, 0.2, 0.5 };
        local itemLink = GetInventoryItemLink("player", 1);

        local frame = CreateFrame("Button", nil, UIParent);
        frame:SetWidth(200);
        frame:SetHeight(25);
        frame:EnableMouse(true);
        frame:SetHyperlinksEnabled(true);
        frame:Hide();

        frame:SetScript("OnClick", function(self)
            self.selected = not self.selected;
            if self.selected then
                self:LockHighlight();
            else
                self:UnlockHighlight();
            end
        end);
        frame:SetScript("OnHyperlinkEnter", function(self)
            ShowUIPanel(GameTooltip);
            GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR");
            GameTooltip:SetHyperlink(itemLink);
            GameTooltip:Show();
        end);
        frame:SetScript("OnHyperlinkLeave", function(self)
            GameTooltip:Hide();
        end);

        local highlight = frame:CreateTexture(nil, "HIGHLIGHT");
        highlight:SetTexture("Interface\\HelpFrame\\HelpFrameButton-Highlight");
        highlight:SetAllPoints();
        highlight:SetBlendMode("ADD");
        highlight:SetTexCoord(0, 1, 0, 0.578125);

        local player = frame:CreateTexture(nil, "BACKGROUND");
        player:SetHeight(frame:GetHeight());
        -- player:SetColorTexture(1, 0, 0, 0.1);
        player:SetPoint("TOPLEFT", frame);

        local playerText = frame:CreateFontString(nil, "BACKGROUND", "GameFontNormalSmall");
        playerText:SetText("Xanido");
        playerText:SetPoint("LEFT", player, 2, 0);

        local priority = frame:CreateTexture(nil, "BACKGROUND");
        priority:SetHeight(frame:GetHeight());
        -- priority:SetColorTexture(0, 1, 0, 0.1);
        priority:SetPoint("TOPLEFT", player, "TOPRIGHT");

        local priorityText = frame:CreateFontString(nil, "BACKGROUND", "GameFontNormalSmall");
        priorityText:SetText("0.000");
        priorityText:SetPoint("LEFT", priority, 2, 0);

        local current = frame:CreateTexture(nil, "BACKGROUND");
        current:SetHeight(frame:GetHeight());
        -- current:SetColorTexture(0, 0, 1, 0.1);
        current:SetPoint("TOPLEFT", priority, "TOPRIGHT");

        local currentText = frame:CreateFontString(nil, "BACKGROUND", "GameFontNormalSmall");
        currentText:SetText(itemLink);
        currentText:SetPoint("LEFT", current, 2, 0);

        -- create widget
        local widget = {
            weights = weights,

            player = player,
            priority = priority,
            current = current,

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

function ABGP:ShowDistrib(itemLink)
    self:SendComm({
        type = self.CommTypes.ITEM_DISTRIBUTION_OPENED,
        itemLink = itemLink
    }, "BROADCAST");

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
    window:SetWidth(700);
    window:SetHeight(500);
    -- self:OpenWindow(window);

    local announce = AceGUI:Create("Button");
    announce:SetWidth(100);
    announce:SetText("Announce");
    window:AddChild(announce);

    local distrib = AceGUI:Create("Button");
    distrib:SetWidth(100);
    distrib:SetText("Distribute");
    distrib:SetDisabled(true);
    window:AddChild(distrib);

    local cost = AceGUI:Create("EditBox");
    cost:SetWidth(75);
    cost:SetText("250");
    window:AddChild(cost);
    cost:SetCallback("OnEnterPressed", function(widget) AceGUI:ClearFocus(); end);
    local desc = AceGUI:Create("Label");
    desc:SetWidth(50);
    desc:SetText("Cost");
    window:AddChild(desc);

    do
        local scrollContainer = AceGUI:Create("InlineGroup");
        scrollContainer:SetTitle("Main Spec Requests");
        scrollContainer:SetFullWidth(true);
        scrollContainer:SetHeight(200);
        scrollContainer:SetLayout("Fill");
        window:AddChild(scrollContainer);

        local scroll = AceGUI:Create("ScrollFrame");
        scroll:SetFullWidth(true);
        scroll:SetLayout("List");
        scrollContainer:AddChild(scroll);

        local columns = { "Player", "Priority", "Current", weights = { 0.3, 0.2, 0.5 }};
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

        for i = 1, 20 do
            local player = AceGUI:Create("ABGP_DistribPlayer");
            player:SetFullWidth(true);
            scroll:AddChild(player);
        end
    end

    do
        local scrollContainer = AceGUI:Create("InlineGroup");
        scrollContainer:SetTitle("Off Spec Requests");
        scrollContainer:SetFullWidth(true);
        scrollContainer:SetHeight(200);
        scrollContainer:SetLayout("Fill");
        window:AddChild(scrollContainer);

        local scroll = AceGUI:Create("ScrollFrame");
        scroll:SetFullWidth(true);
        scroll:SetLayout("List");
        scrollContainer:AddChild(scroll);

        local columns = { "Player", "Priority", "Current", weights = { 0.3, 0.2, 0.5 }};
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

    ShowUIPanel(ItemRefTooltip);
    ItemRefTooltip:SetOwner(window.frame, "ANCHOR_NONE");
    ItemRefTooltip:SetPoint("TOPLEFT", window.frame, "TOPRIGHT");
    ItemRefTooltip:SetHyperlink(itemLink);
    ItemRefTooltip:Show();
end
