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
