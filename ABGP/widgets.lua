local _G = _G;
local ABGP = _G.ABGP;
local AceGUI = _G.LibStub("AceGUI-3.0");

local CreateFrame = CreateFrame;
local GetItemInfo = GetItemInfo;
local GetItemIcon = GetItemIcon;
local IsModifiedClick = IsModifiedClick;
local GetItemQualityColor = GetItemQualityColor;
local ResetCursor = ResetCursor;
local MouseIsOver = MouseIsOver;
local RED_FONT_COLOR = RED_FONT_COLOR;
local CursorUpdate = CursorUpdate;
local LE_ITEM_QUALITY_COMMON = LE_ITEM_QUALITY_COMMON;
local LE_ITEM_QUALITY_ARTIFACT = LE_ITEM_QUALITY_ARTIFACT;
local pairs = pairs;
local ipairs = ipairs;
local floor = floor;
local min = min;
local max = max;
local mod = mod;
local table = table;
local select = select;
local math = math;

function ABGP:AddWidgetTooltip(widget, text)
    widget:SetCallback("OnEnter", function(widget)
        _G.GameTooltip:SetOwner(widget.frame, "ANCHOR_RIGHT");
        _G.GameTooltip:SetText(text, nil, nil, nil, nil, true);
    end);
    widget:SetCallback("OnLeave", function(widget)
        _G.GameTooltip:Hide();
    end);
end

local function CreateElement(frame, anchor, template)
    local elt = CreateFrame("Button", nil, frame, template);
    elt:SetHeight(frame:GetHeight());
    elt:EnableMouse(true);
    elt:RegisterForClicks("LeftButtonUp", "RightButtonUp");
    elt:SetHyperlinksEnabled(true);
    elt:SetScript("OnHyperlinkEnter", function(self, itemLink)
        _G.ShowUIPanel(_G.GameTooltip);
        _G.GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT");
        _G.GameTooltip:SetHyperlink(itemLink);
        _G.GameTooltip:Show();
        self:GetParent():RequestHighlight(true);
        self.hasItem = itemLink;
        CursorUpdate(self);
    end);
    elt:SetScript("OnHyperlinkLeave", function(self)
        _G.GameTooltip:Hide();
        self:GetParent():RequestHighlight(false);
        self.hasItem = nil;
        ResetCursor();
    end);
    elt:SetScript("OnHyperlinkClick", function(self, itemLink, text, ...)
        if IsModifiedClick() then
            _G.HandleModifiedItemClick(select(2, GetItemInfo(itemLink)));
        else
            self:GetParent().obj:Fire("OnClick", ...);
        end
    end);
    elt:SetScript("OnUpdate", function(self)
        if _G.GameTooltip:IsOwned(self) and self.hasItem then
            _G.GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT");
            _G.GameTooltip:SetHyperlink(self.hasItem);
            CursorUpdate(self);
        end
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
            self.player.text:SetText("");
            self.rank.text:SetText("");
            self.priority.text:SetText("");
            self.equipped.text:SetText("");
            self.requestType.text:SetText("");
            self.notes.text:SetText("");

            self.frame.highlightRequests = 0;
            self.frame:UnlockHighlight();

            self.background:Hide();
        end,

        ["SetData"] = function(self, data, equippable)
            self.data = data;

            self.player.text:SetText(ABGP:ColorizeName(data.player or "", data.class));
            self.rank.text:SetText(data.rank or "");
            self.rank.text:SetFontObject((data.preferredGroup and data.group == data.preferredGroup) and "ABGPHighlight" or "GameFontNormal");
            if data.priority then
                self.priority.text:SetText(("%.3f"):format(data.priority));
                self.priority.text:SetJustifyH("LEFT");
            else
                self.priority.text:SetText("--");
                self.priority.text:SetJustifyH("CENTER");
            end

            if equippable then
                self.frame:SetHeight(36);
                if data.equipped then
                    self.equipped.text:SetText(table.concat(data.equipped, ""));
                end
            else
                self.frame:SetHeight(22);
                self.equipped.text:SetText("");
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
            self.priority:SetWidth(widths[3] or 0);
            self.requestType:SetWidth(widths[4] or 0);
            self.roll:SetWidth(widths[5] or 0);
        end,

        ["ShowBackground"] = function(self, show)
            self.background[show and "Show" or "Hide"](self.background);
        end,
    }

    --[[-----------------------------------------------------------------------------
    Constructor
    -------------------------------------------------------------------------------]]
    local function Constructor()
        local frame = CreateFrame("Button", nil, _G.UIParent);
        frame:SetHeight(36);
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
        player:ClearAllPoints();
        player:SetPoint("TOPLEFT", frame, 0, -3);
        player:SetHeight(16);

        local rank = CreateElement(frame);
        rank.text = CreateFontString(rank);
        rank:ClearAllPoints();
        rank:SetPoint("TOPLEFT", player, "TOPRIGHT");
        rank:SetHeight(16);

        local priority = CreateElement(frame);
        priority.text = CreateFontString(priority);
        priority:ClearAllPoints();
        priority:SetPoint("TOPLEFT", rank, "TOPRIGHT");
        priority:SetHeight(16);
        priority:SetScript("OnEnter", function(self)
            local obj = self:GetParent().obj;
            if obj.data.ep and obj.data.gp then
                _G.ShowUIPanel(_G.GameTooltip);
                _G.GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT");
                _G.GameTooltip:AddDoubleLine(("|cffffffff%.3f|r EP"):format(obj.data.ep), ("|cffffffff%.3f|r GP"):format(obj.data.gp));
                _G.GameTooltip:Show();
            end
            self:GetParent():RequestHighlight(true);
        end);
        priority:SetScript("OnLeave", function(self)
            _G.GameTooltip:Hide();
            self:GetParent():RequestHighlight(false);
        end);

        local equipped = CreateElement(frame);
        equipped.text = CreateFontString(equipped);
        equipped.text:SetTextHeight(11);
        equipped:ClearAllPoints();
        equipped:SetPoint("BOTTOMLEFT", frame, 0, 3);
        equipped:SetPoint("BOTTOMRIGHT", frame, 0, 3);
        equipped:SetHeight(16);

        local requestType = CreateElement(frame);
        requestType.text = CreateFontString(requestType);
        requestType.text:SetJustifyH("CENTER");
        requestType:ClearAllPoints();
        requestType:SetPoint("TOPLEFT", priority, "TOPRIGHT");
        requestType:SetHeight(16);

        local roll = CreateElement(frame);
        roll.text = CreateFontString(roll);
        roll.text:SetJustifyH("RIGHT");
        roll.text:SetPoint("RIGHT", roll, -10, 1);
        roll:ClearAllPoints();
        roll:SetPoint("TOPLEFT", requestType, "TOPRIGHT");
        roll:SetHeight(16);

        local notes = CreateElement(frame, roll);
        notes.text = CreateFontString(notes);
        notes:ClearAllPoints();
        notes:SetPoint("TOPLEFT", roll, "TOPRIGHT");
        notes:SetPoint("TOPRIGHT", frame, 0, -2);
        notes:SetHeight(16);
        notes:SetScript("OnEnter", function(self)
            if self.text:IsTruncated() then
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
    local Type, Version = "ABGP_Priority", 1;

    local mainSpecFont = CreateFont("ABGPHighlight");
    mainSpecFont:CopyFontObject(GameFontHighlight);
    mainSpecFont:SetTextColor(unpack(ABGP.ColorTable));

    --[[-----------------------------------------------------------------------------
    Methods
    -------------------------------------------------------------------------------]]
    local methods = {
        ["OnAcquire"] = function(self)
            self:SetHeight(20);

            self.frame.highlightRequests = 0;
            self.frame:UnlockHighlight();

            self.background:Hide();
        end,

        ["SetData"] = function(self, data, order)
            self.data = data;

            self.order.text:SetText(order or "");
            self.player.text:SetText(ABGP:ColorizeName(data.player or "", data.class));
            self.rank.text:SetText(data.rank or "");
            self.ep.text:SetText(data.ep and ("%.3f"):format(data.ep) or "--");
            self.gp.text:SetText(data.gp and ("%.3f"):format(data.gp) or "--");
            self.priority.text:SetText(data.priority and ("%.3f"):format(data.priority) or "--");

            local specialFont = data.important and "ABGPHighlight" or "GameFontNormal";
            self.order.text:SetFontObject(specialFont);
            self.player.text:SetFontObject(specialFont);
            self.rank.text:SetFontObject(specialFont);
            self.ep.text:SetFontObject(specialFont);
            self.gp.text:SetFontObject(specialFont);
            self.priority.text:SetFontObject(specialFont);
        end,

        ["SetWidths"] = function(self, widths)
            self.order:SetWidth(widths[1] or 0);
            self.player:SetWidth(widths[2] or 0);
            self.rank:SetWidth(widths[3] or 0);
            self.ep:SetWidth(widths[4] or 0);
            self.gp:SetWidth(widths[5] or 0);
            self.priority:SetWidth(widths[6] or 0);
        end,

        ["ShowBackground"] = function(self, show)
            self.background[show and "Show" or "Hide"](self.background);
        end,
    }

    --[[-----------------------------------------------------------------------------
    Constructor
    -------------------------------------------------------------------------------]]
    local function Constructor()
        local frame = CreateFrame("Button", nil, _G.UIParent);
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

        local order = CreateElement(frame);
        order.text = CreateFontString(order);
        order.text:SetJustifyH("RIGHT");
        order.text:SetPoint("LEFT", order, 2, 1);
        order.text:SetPoint("RIGHT", order, -10, 1);

        local player = CreateElement(frame, order);
        player.text = CreateFontString(player);

        local rank = CreateElement(frame, player);
        rank.text = CreateFontString(rank);

        local ep = CreateElement(frame, rank);
        ep.text = CreateFontString(ep);

        local gp = CreateElement(frame, ep);
        gp.text = CreateFontString(gp);

        local priority = CreateElement(frame, gp);
        priority.text = CreateFontString(priority);

        -- create widget
        local widget = {
            order = order,
            player = player,
            rank = rank,
            ep = ep,
            gp = gp,
            priority = priority,

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
            self.itemLink.text:SetText(data.itemLink or data.item);
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
        local frame = CreateFrame("Button", nil, _G.UIParent);
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
    local Type, Version = "ABGP_ItemValue", 1;

    --[[-----------------------------------------------------------------------------
    Methods
    -------------------------------------------------------------------------------]]
    local methods = {
        ["OnAcquire"] = function(self)
            self.item.text:SetText("");
            self.gp.text:SetText("");
            self.notes.text:SetText("");
            self.priority.text:SetText("");

            self.frame.highlightRequests = 0;
            self.frame:UnlockHighlight();

            self.background:Hide();
        end,

        ["SetData"] = function(self, data)
            self.data = data;

            self.item.text:SetText(data[ABGP.ItemDataIndex.ITEMLINK] or data[ABGP.ItemDataIndex.NAME]);
            self.gp.text:SetText(data[ABGP.ItemDataIndex.GP]);
            self.notes.text:SetText(data[ABGP.ItemDataIndex.NOTES] and "[Note]" or "");
            self.priority.text:SetText(table.concat(data[ABGP.ItemDataIndex.PRIORITY], ", "));

            local font =ABGP:IsItemFavorited(data[ABGP.ItemDataIndex.ITEMLINK]) and "ABGPHighlight" or "GameFontNormal";
            self.gp.text:SetFontObject(font);
            self.notes.text:SetFontObject(font);
            self.priority.text:SetFontObject(font);
        end,

        ["SetWidths"] = function(self, widths)
            self.item:SetWidth(widths[1] or 0);
            self.gp:SetWidth(widths[2] or 0);
            self.notes:SetWidth(widths[3] or 0);
        end,

        ["ShowBackground"] = function(self, show)
            self.background[show and "Show" or "Hide"](self.background);
        end,

        ["EditPriorities"] = function(self)
            self.frame:SetHeight(30);
            if not self.priorityEditor then
                local priorityEditor = AceGUI:Create("ABGP_Filter");
                priorityEditor.frame:ClearAllPoints();
                priorityEditor.frame:SetPoint("TOPLEFT", self.notes, "TOPRIGHT");
                priorityEditor.frame:SetPoint("TOPRIGHT", self.frame);
                priorityEditor.frame:SetParent(self.frame);

                self.currentPriorities = {};
                for _, pri in ipairs(self.data[ABGP.ItemDataIndex.PRIORITY]) do self.currentPriorities[pri] = true; end

                priorityEditor:SetValues(self.currentPriorities, false, ABGP:GetItemPriorities());
                priorityEditor:SetCallback("OnClosed", function()
                    self.frame:SetHeight(20);
                    self.priority:Show();
                    self.priorityEditor.frame:Hide();

                    self.data[ABGP.ItemDataIndex.PRIORITY] = {};
                    for pri, value in pairs(self.currentPriorities) do
                        if value then table.insert(self.data[ABGP.ItemDataIndex.PRIORITY], pri); end
                    end
                    table.sort(self.data[ABGP.ItemDataIndex.PRIORITY]);

                    self:SetData(self.data);
                    self:Fire("OnPrioritiesUpdated");
                end);
                priorityEditor:SetText(table.concat(self.data[ABGP.ItemDataIndex.PRIORITY], ", "));
                self.priorityEditor = priorityEditor;
            end

            self.priority:Hide();
            self.priorityEditor.frame:Show();
            self.priorityEditor.button:Click();
        end,
    }

    --[[-----------------------------------------------------------------------------
    Constructor
    -------------------------------------------------------------------------------]]
    local function Constructor()
        local frame = CreateFrame("Button", nil, _G.UIParent);
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

        local item = CreateElement(frame);
        item.text = CreateFontString(item);

        local gp = CreateElement(frame, item);
        gp.text = CreateFontString(gp);
        gp.text:SetJustifyH("RIGHT");
        gp.text:SetPoint("LEFT", gp, 2, 1);
        gp.text:SetPoint("RIGHT", gp, -10, 1);

        local notes = CreateElement(frame, gp);
        notes.text = CreateFontString(notes);
        notes:SetScript("OnEnter", function(self)
            local notes = self:GetParent().obj.data[ABGP.ItemDataIndex.NOTES];
            if notes then
                _G.ShowUIPanel(_G.GameTooltip);
                _G.GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT");
                _G.GameTooltip:SetText(notes, 1, 1, 1, 1, true);
                _G.GameTooltip:Show();
            end
            self:GetParent():RequestHighlight(true);
        end);
        notes:SetScript("OnLeave", function(self)
            _G.GameTooltip:Hide();
            self:GetParent():RequestHighlight(false);
        end);

        local priority = CreateElement(frame, notes);
        priority.text = CreateFontString(priority);
        priority:SetPoint("TOPRIGHT", frame);
        priority:SetScript("OnEnter", function(self)
            if self.text:IsTruncated() then
                _G.ShowUIPanel(_G.GameTooltip);
                _G.GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT");
                _G.GameTooltip:SetText(self.text:GetText(), 1, 1, 1, 1, true);
                _G.GameTooltip:Show();
            end
            self:GetParent():RequestHighlight(true);
        end);
        priority:SetScript("OnLeave", function(self)
            _G.GameTooltip:Hide();
            self:GetParent():RequestHighlight(false);
        end);

        -- create widget
        local widget = {
            item = item,
            gp = gp,
            notes = notes,
            priority = priority,

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
    local Type, Version = "ABGP_Paginator", 1;

    --[[-----------------------------------------------------------------------------
    Methods
    -------------------------------------------------------------------------------]]
    local methods = {
        ["OnAcquire"] = function(self)
            self.dataCount = 0;
            self.page = 1;
            self:CalculateRange(true);
        end,

        ["SetValues"] = function(self, dataCount, pageSize)
            self.dataCount = dataCount;
            self.pageSize = pageSize;
            self.pageCount = floor(self.dataCount / self.pageSize) + ((mod(self.dataCount, self.pageSize) == 0) and 0 or 1);
            self.page = min(max(1, self.page), self.pageCount);
            self:CalculateRange(true);
        end,

        ["CalculateRange"] = function(self, suppressEvent)
            if self.dataCount == 0 then
                self.first = 0;
                self.last = 0;

                self.firstBtn:SetDisabled(true);
                self.prevBtn:SetDisabled(true);

                self.nextBtn:SetDisabled(true);
                self.lastBtn:SetDisabled(true);

                self.text:SetText("");
            else
                self.first = 1 + (self.pageSize * (self.page - 1));
                self.last = min(self.first + self.pageSize - 1, self.dataCount);

                self.firstBtn:SetDisabled(self.page == 1);
                self.prevBtn:SetDisabled(self.page == 1);

                self.nextBtn:SetDisabled(self.page == self.pageCount);
                self.lastBtn:SetDisabled(self.page == self.pageCount);

                self.text:SetText(("Showing %d-%d of %d"):format(self.first, self.last, self.dataCount));
            end

            if not suppressEvent then
                self:Fire("OnRangeSet", self.first, self.last);
            end
        end,

        ["SetPage"] = function(self, page)
            self.page = page;
        end,

        ["GetRange"] = function(self)
            return self.first, self.last;
        end,
    }

    --[[-----------------------------------------------------------------------------
    Constructor
    -------------------------------------------------------------------------------]]
    local function Constructor()
        local widget = {};

        local container = AceGUI:Create("SimpleGroup");
        container:SetFullWidth(true);
        container:SetLayout("table");
        container:SetUserData("table", { columns = { 0, 0, 1.0, 0, 0 } });

        local left1 = AceGUI:Create("Button");
        left1:SetWidth(45);
        left1:SetText("<<");
        left1:SetCallback("OnClick", function()
            widget.page = 1;
            widget:CalculateRange();
        end);
        container:AddChild(left1);

        local left2 = AceGUI:Create("Button");
        left2:SetWidth(40);
        left2:SetText("<");
        left2:SetCallback("OnClick", function()
            widget.page = widget.page - 1;
            widget:CalculateRange();
        end);
        container:AddChild(left2);

        local mid = AceGUI:Create("ABGP_Header");
        mid:SetFullWidth(true);
        mid:SetJustifyH("CENTER");
        container:AddChild(mid);

        local right1 = AceGUI:Create("Button");
        right1:SetWidth(40);
        right1:SetText(">");
        right1:SetCallback("OnClick", function()
            widget.page = widget.page + 1;
            widget:CalculateRange();
        end);
        container:AddChild(right1);

        local right2 = AceGUI:Create("Button");
        right2:SetWidth(45);
        right2:SetText(">>");
        right2:SetCallback("OnClick", function()
            widget.page = widget.pageCount;
            widget:CalculateRange();
        end);
        container:AddChild(right2);

        -- create widget
        widget.container = container;
        widget.firstBtn = left1;
        widget.prevBtn = left2;
        widget.text = mid;
        widget.nextBtn = right1;
        widget.lastBtn = right2;
        widget.frame = container.frame;
        widget.type  = Type;
        for method, func in pairs(methods) do
            widget[method] = func
        end

        return AceGUI:RegisterAsWidget(widget)
    end

    AceGUI:RegisterWidgetType(Type, Constructor, Version)
end

do
    local Type, Version = "ABGP_Filter", 1;

    --[[-----------------------------------------------------------------------------
    Methods
    -------------------------------------------------------------------------------]]

    local methods = {
        ["OnAcquire"] = function(self)
            self:DropdownOnAcquire();
            self:SetMultiselect(true);
            self:SetCallback("OnOpened", self.UpdateCheckboxes);
        end,

        ["SetValues"] = function(self, allowed, showAllButton, values, sorted)
            self.allowed = allowed;
            self.values = values;
            self.showAllButton = showAllButton;

            if showAllButton then
                values.ALL = "All";
                table.insert(sorted, "ALL");
            end

            self:SetList(values, sorted);
            self:UpdateCheckboxes();
        end,

        ["ValueChangedCallback"] = function(self, event, value, checked)
            if value == "ALL" then
                if checked then
                    for value in pairs(self.values) do
                        if value ~= "ALL" then self.allowed[value] = true; end
                    end
                end
            else
                if checked then
                    if self:ShowingAll() then
                        table.wipe(self.allowed);
                    end
                end
                self.allowed[value] = checked;
                if self:ShowingNone() and self.showAllButton then
                    for value in pairs(self.values) do
                        if value ~= "ALL" then self.allowed[value] = true; end
                    end
                end
            end

            self:UpdateCheckboxes();
            self:Fire("OnFilterUpdated");
        end,

        ["UpdateCheckboxes"] = function(self)
            self:SetCallback("OnValueChanged", nil);
            local all = self:ShowingAll();
            for value in pairs(self.values) do
                if value == "ALL" then
                    self:SetItemValue(value, all);
                else
                    self:SetItemValue(value, (not all or not self.showAllButton) and self.allowed[value]);
                end
            end
            self:SetCallback("OnValueChanged", self.ValueChangedCallback);
        end,

        ["ShowingAll"] = function(self)
            for value in pairs(self.values) do
                if value ~= "ALL" and not self.allowed[value] then return false; end
            end

            return true;
        end,

        ["ShowingNone"] = function(self)
            for _, state in pairs(self.allowed) do
                if state then return false; end
            end

            return true;
        end,
    }

    --[[-----------------------------------------------------------------------------
    Constructor
    -------------------------------------------------------------------------------]]
    local function Constructor()
        local dropdown = AceGUI:Create("Dropdown");

        dropdown.type = Type;
        dropdown.DropdownOnAcquire = dropdown.OnAcquire;
        for method, func in pairs(methods) do
            dropdown[method] = func;
        end

        return dropdown;
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
            self.text:SetWordWrap(false);
            self.highlight:Hide();
        end,

        ["EnableHighlight"] = function(self, enable)
            self.highlight[enable and "Show" or "Hide"](self.highlight);
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

        ["SetWordWrap"] = function(self, enable)
            self.text:SetWordWrap(enable);
        end,
    }

    --[[-----------------------------------------------------------------------------
    Constructor
    -------------------------------------------------------------------------------]]
    local function Constructor()
        local frame = CreateFrame("Button", nil, _G.UIParent);
        frame:SetHeight(16);
        frame:Hide();

        frame:RegisterForClicks("LeftButtonUp", "RightButtonUp");
        frame:SetScript("OnClick", function(self, ...)
            self.obj:Fire("OnClick", ...);
        end);
        frame:SetHyperlinksEnabled(true);
        frame:SetScript("OnHyperlinkEnter", function(self, itemLink)
            _G.ShowUIPanel(_G.GameTooltip);
            _G.GameTooltip:SetOwner(self, "ANCHOR_NONE");
            _G.GameTooltip:ClearAllPoints();
            _G.GameTooltip:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT");
            _G.GameTooltip:SetHyperlink(itemLink);
            _G.GameTooltip:Show();
            self.hasItem = itemLink;
            CursorUpdate(self);
        end);
        frame:SetScript("OnHyperlinkLeave", function(self)
            _G.GameTooltip:Hide();
            self.hasItem = nil;
            ResetCursor();
        end);
        frame:SetScript("OnHyperlinkClick", function(self, itemLink, text, ...)
            if IsModifiedClick() then
                _G.HandleModifiedItemClick(select(2, GetItemInfo(itemLink)));
            else
                self:GetParent().obj:Fire("OnClick", ...);
            end
        end);
        frame:SetScript("OnUpdate", function(self)
            if _G.GameTooltip:IsOwned(self) and self.hasItem then
                _G.GameTooltip:SetOwner(self, "ANCHOR_NONE");
                _G.GameTooltip:ClearAllPoints();
                _G.GameTooltip:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT");
                _G.GameTooltip:SetHyperlink(self.hasItem);
                CursorUpdate(self);
            end
        end);

        local text = CreateFontString(frame);
        text:SetFontObject(_G.GameFontHighlight);

        local highlight = frame:CreateTexture(nil, "HIGHLIGHT");
        highlight:SetTexture("Interface\\HelpFrame\\HelpFrameButton-Highlight");
        highlight:SetAllPoints();
        highlight:SetBlendMode("ADD");
        highlight:SetTexCoord(0, 1, 0, 0.578125);

        -- create widget
        local widget = {
            text = text,
            highlight = highlight,

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
    local Type, Version = "ABGP_AuditLog", 1;

    --[[-----------------------------------------------------------------------------
    Methods
    -------------------------------------------------------------------------------]]
    local methods = {
        ["OnAcquire"] = function(self)
            self.date.text:SetText("");
            self.auditType.text:SetText("");
            self.audit.text:SetText("");

            self.frame.highlightRequests = 0;
            self.frame:UnlockHighlight();

            self.background:Hide();
        end,

        ["SetData"] = function(self, data)
            self.data = data;

            self.date.text:SetText(data.date);
            self.auditType.text:SetText(data.type);
            self.audit.text:SetText(data.audit);

            local specialFont = (data.important) and "ABGPHighlight" or "GameFontHighlight";
            self.auditType.text:SetFontObject(specialFont);
            self.audit.text:SetFontObject(specialFont);
        end,

        ["SetWidths"] = function(self, widths)
            self.date:SetWidth(widths[1] or 0);
            self.auditType:SetWidth(widths[2] or 0);
        end,

        ["ShowBackground"] = function(self, show)
            self.background[show and "Show" or "Hide"](self.background);
        end,
    }

    --[[-----------------------------------------------------------------------------
    Constructor
    -------------------------------------------------------------------------------]]
    local function Constructor()
        local frame = CreateFrame("Button", nil, _G.UIParent);
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

        local date = CreateElement(frame);
        date.text = CreateFontString(date);

        local auditType = CreateElement(frame, date);
        auditType.text = CreateFontString(auditType);

        local audit = CreateElement(frame, auditType);
        audit.text = CreateFontString(audit);
        audit:SetPoint("TOPRIGHT", frame);
        audit:SetScript("OnEnter", function(self)
            if self.text:IsTruncated() then
                _G.ShowUIPanel(_G.GameTooltip);
                _G.GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT");
                _G.GameTooltip:SetText(self.text:GetText(), 1, 1, 1, 1, true);
                _G.GameTooltip:Show();
            end
            self:GetParent():RequestHighlight(true);
        end);
        audit:SetScript("OnLeave", function(self)
            _G.GameTooltip:Hide();
            self:GetParent():RequestHighlight(false);
        end);

        -- create widget
        local widget = {
            date = date,
            auditType = auditType,
            audit = audit,

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
    local Type, Version = "ABGP_LootFrame", 1;

    local function Frame_OnEvent(frame, event)
        local self = frame.obj;
        self:SetItem(self:GetItem());
    end

    local function Frame_OnUpdate(frame, elapsed)
        local self = frame.obj;
        self.elapsed = self.elapsed + elapsed;
        if self.duration and (MouseIsOver(frame) or (frame.button and MouseIsOver(frame.button)) or ABGP:IsContextMenuOpen()) then
            self.elapsed = math.min(self.elapsed, self.duration - 1);
        end

        if self.elapsed <= self.fadeIn then
            -- Fade in
            local alpha = self.elapsed / self.fadeIn;
            frame:SetAlpha(alpha);
        elseif not self.duration or self.elapsed <= self.duration then
            -- Normal state
            frame:SetAlpha(1);
        elseif self.elapsed >= self.duration + self.fadeOut then
            -- Completed
            frame:Hide();
        else
            -- Fade out
            local alpha = 1 - (self.elapsed - self.duration) / self.fadeOut;
            frame:SetAlpha(alpha);
        end
    end

    local function Frame_OnMouseDown(frame, button)
        if button == "LeftButton" then
            frame.obj:Fire("OnMouseDown");
        end
    end

    local function Frame_OnMouseUp(frame, button)
        if button == "LeftButton" then
            frame.obj:Fire("OnMouseUp");
        elseif button == "RightButton" then
            frame.obj:Fire("OnClick", button, false);
        end
    end

    local function Frame_OnHide(frame)
        frame.obj:Fire("OnHide");
    end

    local function Button_OnClick(frame, button, down)
        local self = frame:GetParent().obj;
        local itemLink = self.itemLink;
        if not itemLink then return; end

        if IsModifiedClick() then
            _G.HandleModifiedItemClick(itemLink);
        else
            self:Fire("OnClick", button, down);
        end
    end

    local function Button_OnEnter(frame)
        local itemLink = frame:GetParent().obj.itemLink;
        if itemLink then
            _G.GameTooltip:SetOwner(frame, "ANCHOR_RIGHT");
            _G.GameTooltip:SetHyperlink(itemLink);
            CursorUpdate(frame);
        end
    end

    local function Button_OnLeave(frame)
        _G.GameTooltip:Hide();
        ResetCursor();
    end

    local function Button_OnUpdate(frame)
        if _G.GameTooltip:IsOwned(frame) then
            _G.GameTooltip:SetOwner(frame, "ANCHOR_RIGHT");
            _G.GameTooltip:SetHyperlink(frame:GetParent().obj.itemLink);
            CursorUpdate(frame);
        end
    end

    local function Need_OnClick(frame, button, down)
        local self = frame:GetParent().obj;
        self:Fire("OnRequest");
    end

    local function ShowTooltip_OnEnter(frame)
        _G.GameTooltip:SetOwner(frame, "ANCHOR_RIGHT");
        _G.GameTooltip:SetText(frame.tooltipText);
        if not frame:IsEnabled() then
            _G.GameTooltip:AddLine(frame.reason, RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b, true);
            _G.GameTooltip:Show();
        end
    end

    local function ShowTooltip_OnLeave(frame)
        _G.GameTooltip:Hide();
    end

    local function Close_OnClick(frame)
        frame:GetParent():Hide();
    end

    local frameCount = 0;

    --[[-----------------------------------------------------------------------------
    Methods
    -------------------------------------------------------------------------------]]
    local methods = {
        ["OnAcquire"] = function(self)
            self.frame:SetAlpha(0);
            self.frame:Show();
            self.frame.glow:Hide();

            self:SetItem(nil);
            self:SetCount(1);

            self.elapsed = 0;
            self.fadeIn = 0.2;
            self.duration = nil;
            self.fadeOut = nil;
        end,

        ["OnRelease"] = function(self)
            self.frame:UnregisterAllEvents();
        end,

        ["GetItem"] = function(self)
            return self.itemLink;
        end,

        ["SetItem"] = function(self, itemLink)
            self.itemLink = itemLink;
            if not self.itemLink then return; end

            local frame = self.frame;
            local itemName = ABGP:GetItemName(itemLink);
            local _, _, rarity = GetItemInfo(itemLink);
            local usable = true;

            if rarity then
                frame:UnregisterEvent("GET_ITEM_INFO_RECEIVED");
                usable = ABGP:IsItemUsable(itemLink);
            else
                rarity = LE_ITEM_QUALITY_COMMON;
                frame:RegisterEvent("GET_ITEM_INFO_RECEIVED");
            end
            local r, g, b = GetItemQualityColor(rarity);

            if frame.elvui then
                if ABGP:IsItemFavorited(itemLink) then
                    rarity = LE_ITEM_QUALITY_ARTIFACT;
                    r, g, b = GetItemQualityColor(rarity);
                    -- frame.dragon:Show();
                -- else
                    -- frame.dragon:Hide();
                end

                frame.button.icon:SetTexture(GetItemIcon(itemLink));
                if usable then
                    frame.button.icon:SetVertexColor(1, 1, 1);
                else
                    frame.button.icon:SetVertexColor(0.9, 0, 0);
                end
                frame.button.link = itemLink;

                frame.fsloot:SetText(itemName);

                frame.status:SetStatusBarColor(r, g, b, .7);
                frame.status.bg:SetColorTexture(r, g, b);

                local color = ABGP.ColorTable;
                frame.fsbind:SetVertexColor(color.r, color.g, color.b);
            else
                frame.IconFrame.Icon:SetTexture(GetItemIcon(itemLink));
                if usable then
                    frame.IconFrame.Icon:SetVertexColor(1, 1, 1);
                else
                    frame.IconFrame.Icon:SetVertexColor(0.9, 0, 0);
                end

                frame.Name:SetVertexColor(r, g, b);
                frame.Name:SetText(itemName);

                frame.Cost:SetVertexColor(1, 1, 1);

                if ABGP:IsItemFavorited(itemLink) then
                    frame:SetBackdrop({
                        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Background",
                        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
                        tile = true,
                        tileSize = 32,
                        edgeSize = 32,
                        insets = { left = 11, right = 12, top = 12, bottom = 11 }
                    });
                    _G[frame:GetName().."Corner"]:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Gold-Corner");
                    _G[frame:GetName().."Decoration"]:Show();
                else
                    frame:SetBackdrop({
                        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
                        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
                        tile = true,
                        tileSize = 32,
                        edgeSize = 32,
                        insets = { left = 11, right = 12, top = 12, bottom = 11 }
                    });
                    _G[frame:GetName().."Corner"]:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Corner");
                    _G[frame:GetName().."Decoration"]:Hide();
                end
            end
        end,

        ["SetSecondaryText"] = function(self, text, compact)
            local frame = self.frame;
            if frame.elvui then
                if compact then
                    frame.fsloot:SetText(ABGP:GetItemName(self.itemLink));
                    frame.fsbind:SetText(compact);
                else
                    frame.fsloot:SetText(text);
                    frame.fsbind:SetText("");
                end
            else
                frame.Cost:SetText(text);
            end
        end,

        ["SetDuration"] = function(self, duration, fadeOut)
            self.elapsed = math.min(self.elapsed, self.fadeIn);
            self.duration = duration;
            self.fadeOut = fadeOut or 1;
        end,

        ["EnableRequests"] = function(self, enabled, reason, noAnimate)
            local frame = self.frame;
            local need = frame.elvui and frame.needbutt or frame.NeedButton;
            if enabled then
                _G.GroupLootFrame_EnableLootButton(need);

                if not noAnimate then
                    frame.glow:Show();
                    frame.glow.animIn:Play();
                end
            elseif reason then
                _G.GroupLootFrame_DisableLootButton(need);
                need.reason = reason;
            else
                need:Disable();
                need:SetAlpha(0);
            end
        end,

        ["SetCount"] = function(self, count)
            self.count = count;
            local frame = self.frame;
            if frame.elvui then
                frame.countstr[self.count == 1 and "Hide" or "Show"](frame.countstr);
                frame.countstr:SetText(self.count == 1 and "" or self.count);
            else
                frame.IconFrame.Count[self.count == 1 and "Hide" or "Show"](frame.IconFrame.Count);
                frame.IconFrame.Count:SetText(self.count == 1 and "" or self.count);
            end
        end,

        ["GetCount"] = function(self)
            return self.count;
        end,
    }

    --[[-----------------------------------------------------------------------------
    Constructor
    -------------------------------------------------------------------------------]]
    local function Constructor()
        local frame, button, need, close;
        if ABGP:Get("lootElvUI") and _G.ElvUI then
            frame = _G.ElvUI[1]:GetModule("Misc"):CreateRollFrame();
            frame.elvui = true;
            frame:UnregisterAllEvents();
            frame:SetScale(1.0);

            -- Change default width
            frame:SetWidth(260);
            frame.fsbind:SetWidth(30);
            frame.fsloot:SetPoint("RIGHT", frame, "RIGHT", -20, 0);

            -- "Hide" greed/pass buttons
            frame.greedbutt:SetAlpha(0);
            frame.greedbutt:Disable();
            frame.greedbutt:SetWidth(1);
            frame.pass:GetParent():SetAlpha(0);
            frame.pass:GetParent():Disable();
            frame.pass:GetParent():SetWidth(1);

            -- Add count fontstring
            local count = frame.button:CreateFontString(nil, 'OVERLAY');
            count:SetJustifyH("RIGHT");
            count:Point("BOTTOMRIGHT", frame.button, -2, 2);
            count:FontTemplate(nil, nil, "OUTLINE");
            frame.countstr = count;

            -- Add close button
            frame.closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton");
            frame.closeButton:Point("RIGHT", 2, 0);
            frame.closeButton:SetAlpha(0.5);
            frame.closeButton:SetScale(0.8);

            -- -- Dragon!
            -- local dragon = frame.button:CreateTexture(nil, "OVERLAY", nil, 1);
            -- dragon:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Gold-Dragon");
            -- dragon:SetSize(47, 47);
            -- dragon:SetPoint("TOPLEFT", -13, 9);
            -- frame.dragon = dragon;

            button = frame.button;
            need = frame.needbutt;
            close = frame.closeButton;
        else
            frameCount = frameCount + 1;
            frame = CreateFrame("Frame", "ABGP_LootFrame" .. frameCount, _G.UIParent, "ABGPLootTemplate");
            button = frame.IconFrame;
            need = frame.NeedButton;
            close = frame.CloseButton;
        end

        frame:SetScript("OnEvent", Frame_OnEvent);
        frame:SetScript("OnUpdate", Frame_OnUpdate);
        frame:SetScript("OnHide", Frame_OnHide);

        frame:EnableMouse(true);
        frame:SetClampedToScreen(true);
        frame:SetScript("OnMouseDown", Frame_OnMouseDown);
        frame:SetScript("OnMouseUp", Frame_OnMouseUp);

        button.hasItem = true;
        button:RegisterForClicks("LeftButtonUp", "RightButtonUp");
        button:SetScript("OnClick", Button_OnClick);
        button:SetScript("OnEnter", Button_OnEnter);
        button:SetScript("OnLeave", Button_OnLeave);
        button:SetScript("OnUpdate", Button_OnUpdate);

        need:SetScript("OnClick", Need_OnClick);
        need:SetScript("OnEnter", ShowTooltip_OnEnter);
        need:SetScript("OnLeave", ShowTooltip_OnLeave);
        need.tooltipText = "Request this item";

        close:SetScript("OnClick", Close_OnClick);
        close:SetScript("OnEnter", ShowTooltip_OnEnter);
        close:SetScript("OnLeave", ShowTooltip_OnLeave);
        close.tooltipText = "Close";
        if frame.elvui then
            -- Must be run after scripts are set.
            _G.ElvUI[1]:GetModule("Skins"):HandleCloseButton(close);
        end

        local glow = need:CreateTexture(nil, "OVERLAY");
        glow:SetAtlas("loottoast-glow");
        glow:SetBlendMode("ADD");
        if frame.elvui then
            glow:SetPoint("TOPLEFT", frame, -40, 4);
            glow:SetPoint("BOTTOMRIGHT", frame, 10, -4);
        else
            glow:SetPoint("TOPLEFT", frame, -10, 10);
            glow:SetPoint("BOTTOMRIGHT", frame, 10, -10);
        end
        local animIn = glow:CreateAnimationGroup();
        animIn:SetScript("OnFinished", function(self) self:GetParent():Hide(); end);
        local fadeIn = animIn:CreateAnimation("Alpha");
        fadeIn:SetFromAlpha(0);
        fadeIn:SetToAlpha(1);
        fadeIn:SetDuration(0.1);
        fadeIn:SetOrder(1);
        local fadeOut= animIn:CreateAnimation("Alpha");
        fadeOut:SetFromAlpha(1);
        fadeOut:SetToAlpha(0);
        fadeOut:SetDuration(0.25);
        fadeOut:SetOrder(2);
        frame.glow = glow;
        glow.animIn = animIn;

        -- create widget
        local widget = {
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
