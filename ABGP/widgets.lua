local _G = _G;
local ABGP = ABGP;
local AceGUI = _G.LibStub("AceGUI-3.0");

local CreateFrame = CreateFrame;
local pairs = pairs;
local floor = floor;

local function CreateElement(frame, anchor, template)
    local elt = CreateFrame("Button", nil, frame, template);
    elt:SetHeight(frame:GetHeight());
    elt:EnableMouse(true);
    elt:RegisterForClicks("LeftButtonUp", "RightButtonUp");
    elt:SetHyperlinksEnabled(true);
    elt:SetScript("OnHyperlinkEnter", function(self, itemLink)
        _G.ShowUIPanel(_G.GameTooltip);
        _G.GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT");
        _G.GameTooltip:SetHyperlink(itemLink);
        _G.GameTooltip:Show();
        self:GetParent():RequestHighlight(true);
    end);
    elt:SetScript("OnHyperlinkLeave", function(self)
        _G.GameTooltip:Hide();
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
    elt:SetPoint("BOTTOM", frame);

    return elt;
end

local function CreateFontString(frame, y)
    local fontstr = frame:CreateFontString(nil, "BACKGROUND", "GameFontNormal");
    fontstr:SetJustifyH("LEFT");
    if y then
        fontstr:SetPoint("LEFT", frame, 2, y);
        fontstr:SetPoint("RIGHT", frame, -2, y);
    else
        fontstr:SetPoint("LEFT", frame, 2, 1);
        fontstr:SetPoint("RIGHT", frame, -2, 1);
    end
    fontstr:SetWordWrap(false);

    return fontstr;
end

do
    local Type, Version = "ABGP_Player", 1;

    local mainSpecFont = CreateFont("ABGPHighlight");
    mainSpecFont:CopyFontObject(GameFontHighlight);
    mainSpecFont:SetTextColor(unpack(ABGP.ColorTable));

    --[[-----------------------------------------------------------------------------
    Methods
    -------------------------------------------------------------------------------]]
    local methods = {
        ["OnAcquire"] = function(self)
            self:SetHeight(32);

            self.player.text:SetText("");
            self.rank.text:SetText("");
            self.priority.text:SetText("");
            self.equipped.textTop:SetText("");
            self.equipped.textMid:SetText("");
            self.equipped.textBot:SetText("");
            self.requestType.text:SetText("");
            self.notes.text:SetText("");

            self.frame.highlightRequests = 0;
            self.frame:UnlockHighlight();

            self.background:Hide();
        end,

        ["SetData"] = function(self, data)
            self.data = data;

            self.player.text:SetText(ABGP:ColorizeName(data.player or "", data.class));
            self.rank.text:SetText(data.rank or "");
            self.ep.text:SetText(("%.3f"):format(data.ep or 0));
            self.gp.text:SetText(("%.3f"):format(data.gp or 0));
            self.priority.text:SetText(("%.3f"):format(data.priority or 0));

            if data.equipped then
                if #data.equipped == 2 then
                    self.equipped.textTop:SetText(data.equipped[1]);
                    self.equipped.textBot:SetText(data.equipped[2]);
                elseif #data.equipped == 1 then
                    self.equipped.textMid:SetText(data.equipped[1]);
                end
            end

            local requestTypes = {
                [ABGP.RequestTypes.MS] = "MS",
                [ABGP.RequestTypes.OS] = "OS",
                [ABGP.RequestTypes.ROLL] = "",
            };
            self.requestType.text:SetText(data.requestType and requestTypes[data.requestType] or "");
            local specialFont = (data.requestType and data.requestType == ABGP.RequestTypes.MS) and "ABGPHighlight" or "GameFontHighlight";
            self.requestType.text:SetFontObject(specialFont);

            self.roll.text:SetText(data.roll or "");
            self.roll.text:SetFontObject(data.currentMaxRoll and "ABGPHighlight" or "GameFontHighlight");

            self.notes.text:SetText(data.notes or "");
        end,

        ["SetWidths"] = function(self, widths)
            self.player:SetWidth(widths[1] or 0);
            self.rank:SetWidth(widths[2] or 0);
            self.ep:SetWidth(widths[3] or 0);
            self.gp:SetWidth(widths[4] or 0);
            self.priority:SetWidth(widths[5] or 0);
            self.equipped:SetWidth(widths[6] or 0);
            self.requestType:SetWidth(widths[7] or 0);
            self.roll:SetWidth(widths[8] or 0);
        end,

        ["SetHeight"] = function(self, height)
            self.frame:SetHeight(height);
        end,

        ["ShowBackground"] = function(self, show)
            self.background[show and "Show" or "Hide"](self.background);
        end,
    }

    --[[-----------------------------------------------------------------------------
    Constructor
    -------------------------------------------------------------------------------]]
    local function Constructor()
        local frame = CreateFrame("Button");
        frame:SetHeight(32);
        frame:Hide();

        frame.highlightRequests = 0;
        frame.RequestHighlight = function(self, enable)
            self.highlightRequests = self.highlightRequests + (enable and 1 or -1);
            self[self.highlightRequests > 0 and "LockHighlight" or "UnlockHighlight"](self);
        end;

        local highlight = frame:CreateTexture(nil, "HIGHLIGHT");
        highlight:SetTexture("Interface\\HelpFrame\\HelpFrameButton-Highlight");
        highlight:SetAllPoints();
        highlight:SetBlendMode("ADD");
        highlight:SetTexCoord(0, 1, 0, 0.578125);

        local background = frame:CreateTexture(nil, "BACKGROUND");
        background:SetAllPoints();
        background:SetColorTexture(0, 0, 0, 0.5);

        local player = CreateElement(frame);
        player.text = CreateFontString(player);

        local rank = CreateElement(frame, player);
        rank.text = CreateFontString(rank);

        local ep = CreateElement(frame, rank);
        ep.text = CreateFontString(ep);

        local gp = CreateElement(frame, ep);
        gp.text = CreateFontString(gp);

        local priority = CreateElement(frame, gp);
        priority.text = CreateFontString(priority);

        local equipped = CreateElement(frame, priority);
        equipped.textTop = CreateFontString(equipped, 8);
        equipped.textMid = CreateFontString(equipped);
        equipped.textBot = CreateFontString(equipped, -4);

        local requestType = CreateElement(frame, equipped);
        requestType.text = CreateFontString(requestType);
        requestType.text:SetJustifyH("CENTER");

        local roll = CreateElement(frame, requestType);
        roll.text = CreateFontString(roll);
        roll.text:SetJustifyH("RIGHT");
        roll.text:SetPoint("RIGHT", roll, -10, 1);

        local notes = CreateElement(frame, roll);
        notes:SetPoint("TOPRIGHT", frame);
        notes.text = CreateFontString(notes);
        notes.text:ClearAllPoints();
        notes.text:SetPoint("TOPLEFT", notes, 0, 1);
        notes.text:SetPoint("BOTTOMRIGHT", notes, -2, 1);
        notes.text:SetWordWrap(true);
        notes:SetScript("OnEnter", function(self)
            if self.text:IsTruncated() then
                local text = self.text:GetText();
                _G.ShowUIPanel(_G.GameTooltip);
                _G.GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT");
                _G.GameTooltip:SetText(self.text:GetText(), 1, 1, 1, 1, true);
                _G.GameTooltip:Show();
            end
            self:GetParent():RequestHighlight(true);
        end);
        notes:SetScript("OnLeave", function(self)
            _G.GameTooltip:Hide();
            self:GetParent():RequestHighlight(false);
        end);

        -- create widget
        local widget = {
            player = player,
            rank = rank,
            ep = ep,
            gp = gp,
            priority = priority,
            equipped = equipped,
            requestType = requestType,
            roll = roll,
            notes = notes,

            background = background,

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

do
    local Type, Version = "ABGP_Item", 1;

    --[[-----------------------------------------------------------------------------
    Methods
    -------------------------------------------------------------------------------]]
    local methods = {
        ["OnAcquire"] = function(self)
            self.button:SetText("")
            self.itemLink.text:SetText("");

            self.frame.highlightRequests = 0;
            self.frame:UnlockHighlight();
        end,

        ["SetData"] = function(self, data)
            self.data = data;

            self.itemLink.text:SetText(data.itemLink);
        end,

        ["SetText"] = function(self, text)
            self.button:SetText(text);
        end,
    }

    --[[-----------------------------------------------------------------------------
    Constructor
    -------------------------------------------------------------------------------]]
    local function Constructor()
        local frame = CreateFrame("Button");
        frame:SetHeight(24);
        frame:Hide();

        frame.highlightRequests = 0;
        frame.RequestHighlight = function(self, enable)
            self.highlightRequests = self.highlightRequests + (enable and 1 or -1);
            self[self.highlightRequests > 0 and "LockHighlight" or "UnlockHighlight"](self);
        end;

        local highlight = frame:CreateTexture(nil, "HIGHLIGHT");
        highlight:SetTexture("Interface\\HelpFrame\\HelpFrameButton-Highlight");
        highlight:SetAllPoints();
        highlight:SetBlendMode("ADD");
        highlight:SetTexCoord(0, 1, 0, 0.578125);

        local button = CreateElement(frame, nil, "UIPanelButtonTemplate");
        button:SetWidth(75);
        button:ClearAllPoints();
        button:SetPoint("TOPRIGHT", frame, -1, -1);
        button:SetPoint("BOTTOMRIGHT", frame, -1, 3);

        local itemLink = CreateElement(frame);
        itemLink.text = CreateFontString(itemLink);
        itemLink:ClearAllPoints();
        itemLink:SetPoint("TOPLEFT", frame);
        itemLink:SetPoint("BOTTOMLEFT", frame);
        itemLink:SetPoint("RIGHT", button, "LEFT");

        -- create widget
        local widget = {
            itemLink = itemLink,
            button = button,

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

do
    local Type, Version = "ABGP_ItemHistory", 1;

    --[[-----------------------------------------------------------------------------
    Methods
    -------------------------------------------------------------------------------]]
    local methods = {
        ["OnAcquire"] = function(self)
            self.player.text:SetText("");
            self.gp.text:SetText("");
            self.date.text:SetText("");
            self.itemLink.text:SetText("");

            self.frame.highlightRequests = 0;
            self.frame:UnlockHighlight();

            self.background:Hide();
        end,

        ["SetData"] = function(self, data)
            self.data = data;

            self.player.text:SetText(ABGP:ColorizeName(data.player or "", data.class));
            self.gp.text:SetText(data.gp);
            self.date.text:SetText(data.date);
            self.itemLink.text:SetText(data.itemLink);
        end,

        ["SetWidths"] = function(self, widths)
            self.player:SetWidth(widths[1] or 0);
            self.date:SetWidth(widths[2] or 0);
            self.gp:SetWidth(widths[3] or 0);
        end,

        ["ShowBackground"] = function(self, show)
            self.background[show and "Show" or "Hide"](self.background);
        end,
    }

    --[[-----------------------------------------------------------------------------
    Constructor
    -------------------------------------------------------------------------------]]
    local function Constructor()
        local frame = CreateFrame("Button");
        frame:SetHeight(20);
        frame:Hide();

        frame.highlightRequests = 0;
        frame.RequestHighlight = function(self, enable)
            self.highlightRequests = self.highlightRequests + (enable and 1 or -1);
            self[self.highlightRequests > 0 and "LockHighlight" or "UnlockHighlight"](self);
        end;

        local highlight = frame:CreateTexture(nil, "HIGHLIGHT");
        highlight:SetTexture("Interface\\HelpFrame\\HelpFrameButton-Highlight");
        highlight:SetAllPoints();
        highlight:SetBlendMode("ADD");
        highlight:SetTexCoord(0, 1, 0, 0.578125);

        local background = frame:CreateTexture(nil, "BACKGROUND");
        background:SetAllPoints();
        background:SetColorTexture(0, 0, 0, 0.5);

        local player = CreateElement(frame);
        player.text = CreateFontString(player);

        local date = CreateElement(frame, player);
        date.text = CreateFontString(date);

        local gp = CreateElement(frame, date);
        gp.text = CreateFontString(gp);
        gp.text:SetJustifyH("RIGHT");
        gp.text:SetPoint("LEFT", gp, 2, 1);
        gp.text:SetPoint("RIGHT", gp, -10, 1);

        local itemLink = CreateElement(frame, gp);
        itemLink.text = CreateFontString(itemLink);
        itemLink:SetPoint("TOPRIGHT", frame);

        -- create widget
        local widget = {
            player = player,
            gp = gp,
            date = date,
            itemLink = itemLink,

            background = background,

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

do
    local Type, Version = "ABGP_Header", 1;

    --[[-----------------------------------------------------------------------------
    Methods
    -------------------------------------------------------------------------------]]
    local methods = {
        ["OnAcquire"] = function(self)
            self.text:SetText("");
            self.frame:SetWidth(100);
            self.frame:SetHeight(16);
            self.text:SetJustifyH("LEFT");
            self.text:SetJustifyV("CENTER");
            self.text:SetPoint("LEFT", self.frame, 2, 1);
            self.text:SetPoint("RIGHT", self.frame, -2, 1);
        end,

        ["SetText"] = function(self, text)
            self.text:SetText(text);
        end,

        ["SetWidth"] = function(self, width)
            self.frame:SetWidth(width);
        end,

        ["SetHeight"] = function(self, height)
            self.frame:SetHeight(height);
        end,

        ["SetJustifyH"] = function(self, justify)
            self.text:SetJustifyH(justify);
        end,

        ["SetJustifyV"] = function(self, justify)
            self.text:SetJustifyV(justify);
        end,

        ["SetPadding"] = function(self, left, right)
            self.text:SetPoint("LEFT", self.frame, left, 1);
            self.text:SetPoint("RIGHT", self.frame, right, 1);
        end,
    }

    --[[-----------------------------------------------------------------------------
    Constructor
    -------------------------------------------------------------------------------]]
    local function Constructor()
        local frame = CreateFrame("Button");
        frame:SetHeight(16);
        frame:Hide();

        local text = CreateFontString(frame);
        text:SetFontObject(_G.GameFontHighlight);

        -- create widget
        local widget = {
            text = text,

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
