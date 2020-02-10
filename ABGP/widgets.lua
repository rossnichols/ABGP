local AceGUI = LibStub("AceGUI-3.0");

do
    local Type, Version = "ABGP_DistribPlayer", 1;

    local mainSpecFont = CreateFont("ABGPMainSpec");
    mainSpecFont:CopyFontObject(GameFontHighlight);
    mainSpecFont:SetTextColor(unpack(ABGP.ColorTable));

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

            self.frame.highlightRequests = 0;
            self.frame:UnlockHighlight();
        end,

        ["SetData"] = function(self, data)
            self.data = data;

            self.player.text:SetText(ABGP:ColorizeName(data.player or ""));
            self.rank.text:SetText(data.rank or "");
            self.ep.text:SetText(string.format("%.2f", data.ep or 0));
            self.gp.text:SetText(string.format("%.2f", data.gp or 0));
            self.priority.text:SetText(string.format("%.2f", data.priority or 0));
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

            local specialFont = (data.role and data.role == "MS") and "ABGPMainSpec" or "GameFontHighlight";
            self.role.text:SetFontObject(specialFont);
        end,

        SetWidths = function(self, widths)
            self.player:SetWidth(widths[1]);
            self.rank:SetWidth(widths[2]);
            self.ep:SetWidth(widths[3]);
            self.gp:SetWidth(widths[4]);
            self.priority:SetWidth(widths[5]);
            self.equipped:SetWidth(widths[6]);
            self.role:SetWidth(widths[7]);
        end,
    }

    --[[-----------------------------------------------------------------------------
    Constructor
    -------------------------------------------------------------------------------]]
    local function Constructor()
        local itemLink = GetInventoryItemLink("player", 1);

        local frame = CreateFrame("Button", nil, UIParent);
        frame:SetHeight(32);
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
                GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT");
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
            local fontstr = frame:CreateFontString(nil, "BACKGROUND", "GameFontNormal");
            fontstr:SetJustifyH("LEFT");
            if y then
                fontstr:SetPoint("LEFT", frame, 0, y);
                fontstr:SetPoint("RIGHT", frame, -2, y);
            else
                fontstr:SetPoint("LEFT", frame, 0, 1);
                fontstr:SetPoint("RIGHT", frame, -2, 1);
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

        local rank = createElement(frame, player);
        rank.text = createFontString(rank);

        local ep = createElement(frame, rank);
        ep.text = createFontString(ep);

        local gp = createElement(frame, ep);
        gp.text = createFontString(gp);

        local priority = createElement(frame, gp);
        priority.text = createFontString(priority);

        local equipped = createElement(frame, priority);
        equipped.textTop = createFontString(equipped, 8);
        equipped.textMid = createFontString(equipped);
        equipped.textBot = createFontString(equipped, -4);

        local role = createElement(frame, equipped);
        role.text = createFontString(role);

        local notes = createElement(frame, role);
        notes:SetPoint("TOPRIGHT", frame);
        notes.text = createFontString(notes);
        notes.text:ClearAllPoints();
        notes.text:SetPoint("TOPLEFT", notes, 0, 1);
        notes.text:SetPoint("BOTTOMRIGHT", notes, -2, 1);
        notes.text:SetWordWrap(true);
        notes:SetScript("OnEnter", function(self)
            if self.text:IsTruncated() then
                local text = self.text:GetText();
                ShowUIPanel(GameTooltip);
                GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT");
                GameTooltip:SetText(self.text:GetText(), 1, 1, 1, 1, true);
                GameTooltip:Show();
            end
            self:GetParent():RequestHighlight(true);
        end);
        notes:SetScript("OnLeave", function(self)
            GameTooltip:Hide();
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
