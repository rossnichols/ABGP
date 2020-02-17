local _G = _G;
local ABGP = ABGP;
local AceGUI = LibStub("AceGUI-3.0");

local CreateFrame = CreateFrame;
local pairs = pairs;
local floor = floor;

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
            self.requestType.text:SetText(data.requestType and "   " .. requestTypes[data.requestType] or "");
            local specialFont = (data.requestType and data.requestType == ABGP.RequestTypes.MS) and "ABGPHighlight" or "GameFontHighlight";
            self.requestType.text:SetFontObject(specialFont);

            self.roll.text:SetText(data.roll or "");
            self.roll.text:SetFontObject(data.currentMaxRoll and "ABGPHighlight" or "GameFontHighlight");

            self.notes.text:SetText(data.notes or "--");
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
            self.player:SetHeight(height);
            self.rank:SetHeight(height);
            self.ep:SetHeight(height);
            self.gp:SetHeight(height);
            self.priority:SetHeight(height);
            self.equipped:SetHeight(height);
            self.requestType:SetHeight(height);
            self.roll:SetHeight(height);
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

        local function createElement(frame, anchor)
            local elt = CreateFrame("Button", nil, frame);
            elt:SetHeight(frame:GetHeight());
            elt:EnableMouse(true);
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

        local background = frame:CreateTexture(nil, "BACKGROUND");
        background:SetAllPoints();
        background:SetColorTexture(0, 0, 0, 0.5);

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

        local requestType = createElement(frame, equipped);
        requestType.text = createFontString(requestType);

        local roll = createElement(frame, requestType);
        roll.text = createFontString(roll);

        local notes = createElement(frame, roll);
        notes:SetPoint("TOPRIGHT", frame);
        notes.text = createFontString(notes);
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
