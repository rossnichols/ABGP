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
local geterrorhandler = geterrorhandler;
local xpcall = xpcall;
local pairs = pairs;
local ipairs = ipairs;
local floor = floor;
local min = min;
local max = max;
local mod = mod;
local table = table;
local select = select;
local math = math;
local strlen = strlen;
local date = date;
local type = type;
local ceil = ceil;
local unpack = unpack;
local wipe = table.wipe;

local function errorhandler(err)
    return geterrorhandler()(err)
end

local function safecall(func, ...)
    if func then
        return xpcall(func, errorhandler, ...)
    end
end

local function pickfirstset(...)
    for i=1,select("#",...) do
        if select(i,...)~=nil then
            return select(i,...)
        end
    end
end

function ABGP:AddWidgetTooltip(widget, text)
    widget:SetCallback("OnEnter", function(widget)
        _G.GameTooltip:SetOwner(widget.frame, "ANCHOR_TOPRIGHT");
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
    local Type, Version = "ABGP_ItemButton", 1;

    local function ItemButton_OnEnter(self)
        local itemLink = self.itemLink;
        if not itemLink then return; end

        _G.ShowUIPanel(_G.GameTooltip);
        _G.GameTooltip:SetOwner(self, "ANCHOR_NONE");
        _G.GameTooltip:ClearAllPoints();
        _G.GameTooltip:SetPoint("TOPLEFT", self, "BOTTOMLEFT");
        _G.GameTooltip:SetHyperlink(itemLink);
        _G.GameTooltip:Show();
        self.hasItem = itemLink;
        CursorUpdate(self);
    end

    local function ItemButton_OnLeave(self)
        _G.GameTooltip:Hide();
        self.hasItem = nil;
        ResetCursor();
    end

    local function ItemButton_OnClick(frame)
        local self = frame.obj;
        if not frame.itemLink then return; end

        if IsModifiedClick() then
            _G.HandleModifiedItemClick(select(2, GetItemInfo(frame.itemLink)));
        elseif self.clickable then
            self:Fire("OnClick", frame.itemLink);
        end
    end

    local function ItemButton_OnUpdate(self)
        if _G.GameTooltip:IsOwned(self) and self.hasItem then
            _G.GameTooltip:SetOwner(self, "ANCHOR_NONE");
            _G.GameTooltip:ClearAllPoints();
            _G.GameTooltip:SetPoint("TOPLEFT", self, "BOTTOMLEFT");
            _G.GameTooltip:SetHyperlink(self.hasItem);
            CursorUpdate(self);
        end
    end

    local function ItemButton_OnEvent(frame, event)
        local self = frame.obj;
        self:SetItemLink(frame.itemLink, frame.checkUsable);
    end

    --[[-----------------------------------------------------------------------------
    Methods
    -------------------------------------------------------------------------------]]
    local methods = {
        ["OnAcquire"] = function(self)
            self.frame:Show();
            self:SetItemLink();
            self.frame:ClearAllPoints();
            self.frame:SetParent(_G.UIParent);

            self:SetClickable(false);
            self.frame:SetChecked(false);
        end,

        ["OnRelease"] = function(self)
            self.frame:UnregisterAllEvents();
        end,

        ["SetItemLink"] = function(self, itemLink, checkUsable)
            local button = self.frame;
            button.itemLink = itemLink;
            button.checkUsable = checkUsable;
            if not itemLink then return; end

            local _, _, rarity = GetItemInfo(itemLink);
            local usable = true;

            if rarity then
                button:UnregisterEvent("GET_ITEM_INFO_RECEIVED");
                if checkUsable then
                    usable = ABGP:IsItemUsable(itemLink);
                end
            else
                rarity = LE_ITEM_QUALITY_COMMON;
                button:RegisterEvent("GET_ITEM_INFO_RECEIVED");
            end
            local r, g, b = GetItemQualityColor(rarity);

            local name = button:GetName();
            _G[name .. "Icon"]:SetTexture(GetItemIcon(itemLink));
            if usable then
                _G[name .. "NormalTexture"]:SetVertexColor(r, g, b);
                _G[name .. "Icon"]:SetVertexColor(1, 1, 1);
            else
                _G[name .. "NormalTexture"]:SetVertexColor(0.9, 0, 0);
                _G[name .. "Icon"]:SetVertexColor(0.9, 0, 0);
            end
        end,

        ["SetClickable"] = function(self, clickable)
            self.clickable = clickable;
            if clickable then
                self.frame:GetCheckedTexture():SetAlpha(1);
                self.frame:GetPushedTexture():SetAlpha(1);
            else
                self.frame:GetCheckedTexture():SetAlpha(0);
                self.frame:GetPushedTexture():SetAlpha(0);
            end
        end,
    }

    --[[-----------------------------------------------------------------------------
    Constructor
    -------------------------------------------------------------------------------]]
    local function Constructor()
        local widgetNum = AceGUI:GetNextWidgetNum(Type)

        local frame = CreateFrame("CheckButton", "ABGPActionButton" .. widgetNum, _G.UIParent, "ActionButtonTemplate");
        frame:RegisterForClicks("LeftButtonUp");

        frame:SetScript("OnEnter", ItemButton_OnEnter);
        frame:SetScript("OnLeave", ItemButton_OnLeave);
        frame:SetScript("OnClick", ItemButton_OnClick);
        frame:SetScript("OnUpdate", ItemButton_OnUpdate);
        frame:SetScript("OnEvent", ItemButton_OnEvent);

        -- _G[frame:GetName() .. "Border"]:Show();
        _G[frame:GetName() .. "NormalTexture"]:SetSize(60, 60);
        _G[frame:GetName() .. "NormalTexture"]:SetPoint("CENTER");

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

do
    local Type, Version = "ABGP_Player", 1;

    local mainSpecFont = CreateFont("ABGPHighlight");
    mainSpecFont:CopyFontObject(GameFontHighlight);
    mainSpecFont:SetTextColor(unpack(ABGP.ColorTable));

    local gold = CreateFont("ABGPGold");
    gold:CopyFontObject(GameFontHighlight);
    gold:SetTextColor(0xEB/0xFF, 0xB4/0xFF, 0x00/0xFF);

    local silver = CreateFont("ABGPSilver");
    silver:CopyFontObject(GameFontHighlight);
    silver:SetTextColor(0x9B/0xFF, 0xA4/0xFF, 0xA8/0xFF);

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

        ["SetData"] = function(self, data, equippable, lowPrio)
            self.data = data;

            self.player.text:SetText(ABGP:ColorizeName(data.player or "", data.class));
            self.rank.text:SetText(data.rank or "");
            self.rank.text:SetFontObject((data.preferredGroup and data.group == data.preferredGroup) and "ABGPHighlight" or "GameFontNormal");
            if data.priority then
                self.priority.text:SetText(ABGP:FormatCost(data.priority, data.category, "%.3f%s"));
                self.priority.text:SetFontObject(lowPrio and "GameFontDisable" or "GameFontNormal");
            else
                self.priority.text:SetText("--");
                self.priority.text:SetFontObject("GameFontNormal");
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

            if data.selectedItem then
                self.frame:SetHeight(36);
                self.selectedItem:SetItemLink(data.selectedItem);
                self.selectedItem.frame:Show();
                self.selectedContainer:SetWidth((self.selectedItem.frame:GetWidth() - 8) * self.selectedItem.frame:GetScale());
            else
                self.selectedItem.frame:Hide();
                self.selectedContainer:SetWidth(1);
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

        local selectedContainer = CreateFrame("Frame");
        selectedContainer:SetPoint("BOTTOMLEFT", frame, 0, 3);
        local selectedItem = AceGUI:Create("ABGP_ItemButton");
        selectedItem.frame:SetParent(frame);
        selectedItem.frame:SetScale(0.4);
        selectedItem.frame:SetPoint("BOTTOMLEFT", selectedContainer, 6, 3);
        selectedContainer:SetHeight(1);

        local equipped = CreateElement(frame);
        equipped.text = CreateFontString(equipped);
        equipped.text:SetTextHeight(11);
        equipped:ClearAllPoints();
        equipped:SetPoint("BOTTOMLEFT", selectedContainer, "BOTTOMRIGHT");
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
            selectedItem = selectedItem,
            selectedContainer = selectedContainer,

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

        ["SetData"] = function(self, data, order, important, lowPrio)
            self.data = data;

            self.order.text:SetText(order or "");
            self.player.text:SetText(ABGP:ColorizeName(data.player or "", data.class));
            self.rank.text:SetText(data.rank or "");
            self.ep.text:SetText(data.ep and ("%.3f"):format(data.ep) or "--");
            self.silvergp.text:SetText(data.gp[ABGP.ItemCategory.SILVER] and ("%.3f"):format(data.gp[ABGP.ItemCategory.SILVER]) or "--");
            self.silverprio.text:SetText(data.priority[ABGP.ItemCategory.SILVER] and ("%.3f"):format(data.priority[ABGP.ItemCategory.SILVER]) or "--");
            self.goldgp.text:SetText(data.gp[ABGP.ItemCategory.GOLD] and ("%.3f"):format(data.gp[ABGP.ItemCategory.GOLD]) or "--");
            self.goldprio.text:SetText(data.priority[ABGP.ItemCategory.GOLD] and ("%.3f"):format(data.priority[ABGP.ItemCategory.GOLD]) or "--");

            local specialFont = important and "ABGPHighlight" or lowPrio and "GameFontDisable" or "GameFontNormal";
            self.order.text:SetFontObject(specialFont);
            self.player.text:SetFontObject(specialFont);
            self.rank.text:SetFontObject(specialFont);
            self.ep.text:SetFontObject(specialFont);
            self.silvergp.text:SetFontObject(specialFont);
            self.silverprio.text:SetFontObject(specialFont);
            self.goldgp.text:SetFontObject(specialFont);
            self.goldprio.text:SetFontObject(specialFont);
        end,

        ["SetWidths"] = function(self, widths)
            self.order:SetWidth(widths[1] or 0);
            self.player:SetWidth(widths[2] or 0);
            self.rank:SetWidth(widths[3] or 0);
            self.ep:SetWidth(widths[4] or 0);
            self.silvergp:SetWidth(widths[5] or 0);
            self.silverprio:SetWidth(widths[6] or 0);
            self.goldgp:SetWidth(widths[7] or 0);
            self.goldprio:SetWidth(widths[8] or 0);
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

        local silvergp = CreateElement(frame, ep);
        silvergp.text = CreateFontString(silvergp);

        local silverprio = CreateElement(frame, silvergp);
        silverprio.text = CreateFontString(silverprio);

        local goldgp = CreateElement(frame, silverprio);
        goldgp.text = CreateFontString(goldgp);

        local goldprio = CreateElement(frame, goldgp);
        goldprio.text = CreateFontString(goldprio);

        -- create widget
        local widget = {
            order = order,
            player = player,
            rank = rank,
            ep = ep,
            silvergp = silvergp,
            goldgp = goldgp,
            silverprio = silverprio,
            goldprio = goldprio,

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

            self.player.text:SetText(ABGP:ColorizeName(data[ABGP.ItemHistoryIndex.PLAYER] or ""));
            self.gp.text:SetText(data[ABGP.ItemHistoryIndex.GP]);
            local entryDate = date("%m/%d/%y", data[ABGP.ItemHistoryIndex.DATE]); -- https://strftime.org/
            self.date.text:SetText(entryDate);

            local value = ABGP:GetItemValue(data[ABGP.ItemHistoryIndex.ITEMID]);
            self.itemLink.text:SetText(value and value.itemLink or data[ABGP.ItemHistoryIndex.ITEMID]);
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

            self:SetRelatedItems();
        end,

        ["SetData"] = function(self, data)
            self.data = data;

            self.item.text:SetText(data[ABGP.ItemDataIndex.ITEMLINK] or data[ABGP.ItemDataIndex.NAME]);
            local gp = data[ABGP.ItemDataIndex.GP];
            self.gp.text:SetText(gp);
            self.notes.text:SetText(data[ABGP.ItemDataIndex.NOTES] and "[Note]" or "");
            self.priority.text:SetText(table.concat(data[ABGP.ItemDataIndex.PRIORITY], ", "));

            local font = ABGP:IsItemFavorited(data[ABGP.ItemDataIndex.ITEMLINK]) and "ABGPHighlight" or "GameFontNormal";
            self.notes.text:SetFontObject(font);
            self.priority.text:SetFontObject(font);

            local font = "GameFontNormal";
            if data[ABGP.ItemDataIndex.CATEGORY] == ABGP.ItemCategory.GOLD then font = "ABGPGold"; end
            if data[ABGP.ItemDataIndex.CATEGORY] == ABGP.ItemCategory.SILVER then font = "ABGPSilver"; end
            self.gp.text:SetFontObject(font);
        end,

        ["SetWidths"] = function(self, widths)
            self.item:SetWidth(widths[1] or 0);
            self.gp:SetWidth(widths[2] or 0);
            self.notes:SetWidth(widths[3] or 0);
        end,

        ["ShowBackground"] = function(self, show)
            self.background[show and "Show" or "Hide"](self.background);
        end,

        ["SetRelatedItems"] = function(self, items)
            for k, button in pairs(self.icons.buttons) do
                AceGUI:Release(button);
                self.icons.buttons[k] = nil;
            end
            if items then
                self.icons:Show();
                self.frame:SetHeight(40);
                self.item.text:SetPoint("LEFT", self.item, 2, 12);
                self.item.text:SetPoint("RIGHT", self.item, -2, 12);

                for i, itemLink in ipairs(items) do
                    local button = AceGUI:Create("ABGP_ItemButton");
                    self.icons.buttons[i] = button;
                    button:SetItemLink(itemLink, true);
                    button.frame:SetParent(self.icons);
                    button.frame:SetScale(0.5);

                    if i == 1 then
                        button.frame:SetPoint("BOTTOMLEFT", self.icons, 5, 11);
                    else
                        button.frame:SetPoint("LEFT", self.icons.buttons[i-1].frame, "RIGHT", 8, 0);
                    end
                end
            else
                self.icons:Hide();
                self.frame:SetHeight(20);
                self.item.text:SetPoint("LEFT", self.item, 2, 1);
                self.item.text:SetPoint("RIGHT", self.item, -2, 1);
            end
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

        local icons = CreateElement(frame);
        icons:ClearAllPoints();
        icons:SetAllPoints(item);
        icons.buttons = {};

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
            icons = icons,
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
            self:SetCallback("OnClosed", self.CheckDefaultText);
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

        ["SetDefaultText"] = function(self, text)
            self:SetUserData("_defaultText", text);
            self:SetText(text);
        end,

        ["CheckDefaultText"] = function(self)
            self:Fire("OnFilterClosed");
            local text = self:GetUserData("_defaultText");
            if text and self:ShowingAll() then
                self:SetText(text);
            end
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

            self:SetFont(_G.GameFontHighlight);
        end,

        ["EnableHighlight"] = function(self, enable)
            self.highlight[enable and "Show" or "Hide"](self.highlight);
        end,

        ["SetFont"] = function(self, font)
            self.text:SetFontObject(font);
        end,

        ["SetText"] = function(self, text)
            self.text:SetText(text);
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

        local highlight = frame:CreateTexture(nil, "HIGHLIGHT");
        highlight:SetTexture("Interface\\Buttons\\UI-Listbox-Highlight");
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
            self.entryPlayer.text:SetText("");
            self.entryDate.text:SetText("");
            self.auditType.text:SetText("");
            self.date.text:SetText("");
            self.audit.text:SetText("");

            self.frame.highlightRequests = 0;
            self.frame:UnlockHighlight();

            self.background:Hide();
        end,

        ["SetData"] = function(self, data)
            self.data = data;

            self.entryPlayer.text:SetText(data.entryPlayer);
            self.entryDate.text:SetText(data.entryDate);
            self.auditType.text:SetText(data.type);
            self.date.text:SetText(data.date);
            self.audit.text:SetText(data.audit);

            local font = data.deleted and "GameFontRed" or "GameFontNormal";
            self.entryPlayer.text:SetFontObject(font);
            self.entryDate.text:SetFontObject(font);
            self.auditType.text:SetFontObject(font);
            self.date.text:SetFontObject(font);
            self.audit.text:SetFontObject(data.deleted and "GameFontRed" or "GameFontHighlight");
        end,

        ["SetWidths"] = function(self, widths)
            self.entryPlayer:SetWidth(widths[1] or 0);
            self.entryDate:SetWidth(widths[2] or 0);
            self.auditType:SetWidth(widths[3] or 0);
            self.date:SetWidth(widths[4] or 0);
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

        local entryPlayer = CreateElement(frame);
        entryPlayer.text = CreateFontString(entryPlayer);

        local entryDate = CreateElement(frame, entryPlayer);
        entryDate.text = CreateFontString(entryDate);

        local auditType = CreateElement(frame, entryDate);
        auditType.text = CreateFontString(auditType);

        local date = CreateElement(frame, auditType);
        date.text = CreateFontString(date);

        local audit = CreateElement(frame, date);
        audit.text = CreateFontString(audit);
        audit:SetPoint("TOPRIGHT", frame);
        audit:SetScript("OnEnter", function(self)
            local obj = self:GetParent().obj;
            if self.text:IsTruncated() or obj.data.deleted or obj.data.deleteRef then
                _G.ShowUIPanel(_G.GameTooltip);
                _G.GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT");
                if obj.data.deleteRef then
                    _G.GameTooltip:SetText("Deleted Entry", 1, 1, 1, 1, true);
                    _G.GameTooltip:AddLine(obj.data.deleteRef, 1, 1, 1, 1, true);
                elseif obj.data.deleted then
                    _G.GameTooltip:SetText(obj.data.deleted, 1, 1, 1, 1, true);
                    _G.GameTooltip:AddLine(self.text:GetText(), 1, 1, 1, 1, true);
                else
                    _G.GameTooltip:SetText(self.text:GetText(), 1, 1, 1, 1, true);
                end
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
            entryPlayer = entryPlayer,
            entryDate = entryDate,
            auditType = auditType,
            date = date,
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

        if frame.checkLeave and not MouseIsOver(frame) then
            frame:GetScript("OnLeave")(frame);
        end
    end

    local function Frame_OnMouseDown(frame, button)
        if button == "LeftButton" then
            frame.obj:Fire("OnMouseDown");
        end
    end

    local function Frame_OnEnter(frame)
        if frame.relatedItemIds then
            if frame.elvui then
                frame.fsloot:Hide();
                frame.relatedItems:Show();
            else
                frame.RelatedItems:Show();
                frame.Cost:Hide();
            end
        end
    end

    local function Frame_OnLeave(frame)
        if MouseIsOver(frame) then
            frame.checkLeave = true;
        else
            frame.checkLeave = false;
            if frame.elvui then
                frame.fsloot:Show();
                frame.relatedItems:Hide();
            else
                frame.RelatedItems:Hide();
                frame.Cost:Show();
            end
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

    local function Need_OnMouseDown(frame)
        frame:GetNormalTexture():SetVertexColor(0.8, 0.8, 0.8);
    end

    local function Need_OnMouseUp(frame)
        frame:GetNormalTexture():SetVertexColor(1, 1, 1);
    end

    local function ShowTooltip_OnEnter(frame)
        _G.GameTooltip:SetOwner(frame, "ANCHOR_RIGHT");
        _G.GameTooltip:SetText(frame.tooltipText);
        if frame.tooltipSubtext then
            _G.GameTooltip:AddLine(frame.tooltipSubtext(), nil, nil, nil, true);
            _G.GameTooltip:Show();
        end
        if not frame:IsEnabled() then
            _G.GameTooltip:AddLine(frame.reason, RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b, true);
            _G.GameTooltip:Show();
        end
    end

    local function ShowTooltip_OnLeave(frame)
        _G.GameTooltip:Hide();
    end

    local function Close_OnClick(frame)
        local parent = frame:GetParent();
        parent.obj:SetUserData("forceClosed", true);
        parent:Hide();
    end

    local function RelatedItem_OnClick(widget, event, itemLink)
        local self = widget:GetUserData("lootFrame");
        local frame = self.frame;
        local relatedFrame = frame.elvui and frame.relatedItems or frame.RelatedItems;

        for _, button in pairs(relatedFrame.buttons) do
            if button ~= widget then
                button.frame:SetChecked(false);
            end
        end

        self:Fire("OnRelatedItemSelected", widget.frame:GetChecked() and itemLink or nil);
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
            self:SetRequestCount(0);
            self:SetRelatedItems();

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

            if not frame.elvui then
                if frame.relatedItemIds and not frame.Cost:GetText() then
                    frame.RelatedItems:Show();
                    frame.Cost:Hide();
                    frame:SetScript("OnEnter", nil);
                    frame:SetScript("OnLeave", nil);
                else
                    frame.RelatedItems:Hide();
                    frame.Cost:Show();
                    frame:SetScript("OnEnter", Frame_OnEnter);
                    frame:SetScript("OnLeave", Frame_OnLeave);
                end
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

        ["SetRequestCount"] = function(self, count)
            local frame = self.frame;
            if frame.elvui then
                frame.requestcountstr[count == 0 and "Hide" or "Show"](frame.requestcountstr);
                frame.requestcountstr:SetText(count == 0 and "" or count);
            else
                frame.IconFrame.RequestCount[count == 0 and "Hide" or "Show"](frame.IconFrame.RequestCount);
                frame.IconFrame.RequestCount:SetText(count == 0 and "" or count);
            end
        end,

        ["SetRequestCounts"] = function(self, main, off)
            if main == 0 and off == 0 then
                self:SetRequestCount(0);
                return;
            end

            local frame = self.frame;
            if frame.elvui then
                frame.requestcountstr:Show();
                frame.requestcountstr:SetText(("%d/%d"):format(main, off));
            else
                frame.IconFrame.RequestCount:Show();
                frame.IconFrame.RequestCount:SetText(("%d/%d"):format(main, off));
            end
        end,

        ["GetCount"] = function(self)
            return self.count;
        end,

        ["SetRelatedItems"] = function(self, items)
            local frame = self.frame;
            frame.relatedItemIds = items;

            local relatedFrame = frame.elvui and frame.relatedItems or frame.RelatedItems;
            for k, button in pairs(relatedFrame.buttons) do
                AceGUI:Release(button);
                relatedFrame.buttons[k] = nil;
            end
            if items then
                for i, itemLink in ipairs(items) do
                    local button = AceGUI:Create("ABGP_ItemButton");
                    button:SetUserData("lootFrame", self);
                    relatedFrame.buttons[i] = button;
                    button:SetItemLink(itemLink, true);
                    button.frame:SetParent(relatedFrame);
                    button.frame:SetScale(0.4);
                    button:SetClickable(true);
                    button:SetCallback("OnClick", RelatedItem_OnClick);

                    if i == 1 then
                        button.frame:SetPoint("BOTTOMLEFT", relatedFrame, 0, 0);
                    else
                        button.frame:SetPoint("LEFT", relatedFrame.buttons[i-1].frame, "RIGHT", 8, 0);
                    end
                end
            end

            if not frame.elvui then
                if frame.relatedItemIds and not frame.Cost:GetText() then
                    frame.RelatedItems:Show();
                    frame.Cost:Hide();
                    frame:SetScript("OnEnter", nil);
                    frame:SetScript("OnLeave", nil);
                else
                    frame.RelatedItems:Hide();
                    frame.Cost:Show();
                    frame:SetScript("OnEnter", Frame_OnEnter);
                    frame:SetScript("OnLeave", Frame_OnLeave);
                end
            end
        end,

        ["SetAlert"] = function(self, alert)
            local frame = self.frame;
            local tooltip = frame.tooltip;
            local need = frame.elvui and frame.needbutt or frame.NeedButton;
            if alert then
                tooltip:SetOwner(need, "ANCHOR_BOTTOMRIGHT");
                tooltip:SetText(alert, 1, 1, 1);
            else
                tooltip:Hide();
            end
        end,
    }

    --[[-----------------------------------------------------------------------------
    Constructor
    -------------------------------------------------------------------------------]]
    local function Constructor()
        local widgetNum = AceGUI:GetNextWidgetNum(Type);

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
            count:SetJustifyV("BOTTOM");
            count:Point("BOTTOMRIGHT", frame.button, -2, 2);
            count:FontTemplate(nil, nil, "OUTLINE");
            frame.countstr = count;

            -- Add request count fontstring
            local requestcount = frame.button:CreateFontString(nil, 'OVERLAY');
            requestcount:SetJustifyH("LEFT");
            requestcount:SetJustifyV("TOP");
            requestcount:Point("TOPLEFT", frame.button, 2, -2);
            requestcount:FontTemplate(nil, nil, "OUTLINE");
            frame.requestcountstr = requestcount;

            -- Add close button
            frame.closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton");
            frame.closeButton:Point("RIGHT", 2, 0);
            frame.closeButton:SetAlpha(0.5);
            frame.closeButton:SetScale(0.8);

            -- For related items
            frame.relatedItems = CreateFrame("Frame", nil, frame);
            frame.relatedItems:Point("LEFT", frame.fsbind, "RIGHT", 0, 0);
            frame.relatedItems:Point("RIGHT", frame, "RIGHT", -5, 0);
            frame.relatedItems:Size(200, 14);
            frame.relatedItems:Hide();
            frame.relatedItems.buttons = {};

            -- -- Dragon!
            -- local dragon = frame.button:CreateTexture(nil, "OVERLAY", nil, 1);
            -- dragon:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Gold-Dragon");
            -- dragon:SetSize(47, 47);
            -- dragon:SetPoint("TOPLEFT", -13, 9);
            -- frame.dragon = dragon;

            frame.fsbind:Point("LEFT", frame.pass, "RIGHT");

            frame:SetScript("OnEnter", Frame_OnEnter);
            frame:SetScript("OnLeave", Frame_OnLeave);

            button = frame.button;
            need = frame.needbutt;
            close = frame.closeButton;
        else
            frameCount = frameCount + 1;
            frame = CreateFrame("Frame", "ABGP_LootFrame" .. frameCount, _G.UIParent, "ABGPLootTemplate");
            button = frame.IconFrame;
            need = frame.NeedButton;
            close = frame.CloseButton;

            frame.RelatedItems.buttons = {};
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
        need:SetScript("OnMouseDown", Need_OnMouseDown);
        need:SetScript("OnMouseUp", Need_OnMouseUp);
        need:SetScript("OnEnter", ShowTooltip_OnEnter);
        need:SetScript("OnLeave", ShowTooltip_OnLeave);
        need.tooltipText = "Request this item";

        need:SetNormalTexture("Interface\\CHATFRAME\\UI-ChatIcon-Share");
        need:SetHighlightTexture("Interface\\GLUES\\Models\\UI_Alliance\\Glow32", "ADD");
        need:SetPushedTexture(nil);

        close:SetScript("OnClick", Close_OnClick);
        close:SetScript("OnEnter", ShowTooltip_OnEnter);
        close:SetScript("OnLeave", ShowTooltip_OnLeave);
        close.tooltipText = "Close";
        close.tooltipSubtext = function()
            local qualifier = ABGP:Get("lootShiftAll") and "" or " you haven't requested";
            return ("|cffffffffShift+click|r to close all items%s."):format(qualifier);
        end;
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

        local tooltipName = "ABGPLootFrameTooltip" .. widgetNum;
        frame.tooltip = CreateFrame("GameTooltip", tooltipName, _G.UIParent, "GameTooltipTemplate");
        _G[tooltipName .. "TextLeft1"]:SetFontObject("GameFontNormalSmall");

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

do
    local Type, Version = "ABGP_EditBox", 1;

    local function Edit_OnFocusGained(frame)
        local self = frame.obj;
        self:SetValue(self:GetValue());
        self:HighlightText();
        self.editbox:SetCursorPosition(strlen(self:GetText()));
    end

    local function Edit_OnFocusLost(frame)
        local self = frame.obj;
        self:SetValue(self:GetValue());
    end

    local function Edit_OnEnterPressed(widget, event, value)
        local oldValue = widget:GetValue();
        widget:SetValue(value);
        local cancel = widget:Fire("OnValueChanged", value);
        if cancel then
            widget:SetValue(oldValue);
            Edit_OnFocusGained(widget.editbox);
        else
            AceGUI:ClearFocus();
        end
        return cancel;
    end

    --[[-----------------------------------------------------------------------------
    Methods
    -------------------------------------------------------------------------------]]

    local methods = {
        ["OnAcquire"] = function(self)
            self:EditBoxOnAcquire();
            self:DisableButton(true);

            self:SetAutoCompleteSource(nil);
            self:SetFormat(nil);
            self:SetValue(nil);
            self:SetCallback("OnEnterPressed", Edit_OnEnterPressed);
        end,

        ["SetAutoCompleteSource"] = function(self, fn, include, exclude)
            _G.AutoCompleteEditBox_SetAutoCompleteSource(self.editbox, fn, include, exclude);
        end,

        ["SetValue"] = function(self, value)
            self.value = value;
            if self.formatStr then
                self:SetText(self.formatStr:format(value or ""));
            else
                self:SetText(value or "");
            end
        end,

        ["GetValue"] = function(self)
            return self.value;
        end,

        ["SetFormat"] = function(self, formatStr)
            self.formatStr = formatStr;
            self:SetValue(self:GetValue());
        end,
    }

    --[[-----------------------------------------------------------------------------
    Constructor
    -------------------------------------------------------------------------------]]
    local function Constructor()
        local elt = AceGUI:Create("EditBox");

        local scripts = {
            OnTabPressed = _G.AutoCompleteEditBox_OnTabPressed,
            OnEnterPressed = _G.AutoCompleteEditBox_OnEnterPressed,
            OnTextChanged = _G.AutoCompleteEditBox_OnTextChanged,
            OnChar = _G.AutoCompleteEditBox_OnChar,
            OnEditFocusLost = _G.AutoCompleteEditBox_OnEditFocusLost,
            OnEscapePressed = _G.AutoCompleteEditBox_OnEscapePressed,
            OnArrowPressed = _G.AutoCompleteEditBox_OnArrowPressed,
        };
        local alwaysExisting = { OnEnterPressed = true };
        for name, script in pairs(scripts) do
            local existing = elt.editbox:GetScript(name);
            if existing then
                elt.editbox:SetScript(name, function(...)
                    return (script(...) and not alwaysExisting[name]) or existing(...);
                end);
            else
                elt.editbox:SetScript(name, script);
            end
        end

        elt.editbox:HookScript("OnEditFocusGained", Edit_OnFocusGained);
        elt.editbox:HookScript("OnEditFocusLost", Edit_OnFocusLost);

        elt.type = Type;
        elt.EditBoxOnAcquire = elt.OnAcquire;
        for method, func in pairs(methods) do
            elt[method] = func;
        end

        return elt;
    end

    AceGUI:RegisterWidgetType(Type, Constructor, Version)
end

do
    local Type, Version = "ABGP_OpaqueWindow", 1;

    --[[-----------------------------------------------------------------------------
    Methods
    -------------------------------------------------------------------------------]]

    local methods = {
        ["OnAcquire"] = function(self)
            self:WindowOnAcquire();
        end,
    }

    --[[-----------------------------------------------------------------------------
    Constructor
    -------------------------------------------------------------------------------]]
    local function Constructor()
        local elt = AceGUI:Create("Window");

        local background = elt.frame:CreateTexture(nil, "BACKGROUND");
		background:SetPoint("TOPLEFT", 8, -24);
		background:SetPoint("BOTTOMRIGHT", -6, 8);
        background:SetColorTexture(0, 0, 0, 1);

        elt.type = Type;
        elt.WindowOnAcquire = elt.OnAcquire;
        for method, func in pairs(methods) do
            elt[method] = func;
        end

        return elt;
    end

    AceGUI:RegisterWidgetType(Type, Constructor, Version)
end

-- Get alignment method and value. Possible alignment methods are a callback, a number, "start", "middle", "end", "fill" or "TOPLEFT", "BOTTOMRIGHT" etc.
local GetCellAlign = function (dir, tableObj, colObj, cellObj, cell, child)
    local fn = cellObj and (cellObj["align" .. dir] or cellObj.align)
            or colObj and (colObj["align" .. dir] or colObj.align)
            or tableObj["align" .. dir] or tableObj.align
            or "CENTERLEFT"
    local child, cell, val = child or 0, cell or 0, nil

    if type(fn) == "string" then
        fn = fn:lower()
        fn = dir == "V" and (fn:sub(1, 3) == "top" and "start" or fn:sub(1, 6) == "bottom" and "end" or fn:sub(1, 6) == "center" and "middle")
          or dir == "H" and (fn:sub(-4) == "left" and "start" or fn:sub(-5) == "right" and "end" or fn:sub(-6) == "center" and "middle")
          or fn
        val = (fn == "start" or fn == "fill") and 0 or fn == "end" and cell - child or (cell - child) / 2
    elseif type(fn) == "function" then
        val = fn(child or 0, cell, dir)
    else
        val = fn
    end

    return fn, max(0, min(val, cell))
end

-- Get width or height for multiple cells combined
local GetCellDimension = function (dir, laneDim, from, to, space)
    local dim = 0
    for cell=from,to do
        dim = dim + (laneDim[cell] or 0)
    end
    return dim + max(0, to - from) * (space or 0)
end

--[[ Options
============
Container:
 - columns ({col, col, ...}): Column settings. "col" can be a number (<= 0: content width, <1: rel. width, <10: weight, >=10: abs. width) or a table with column setting.
 - rows ({row, row, ...}): Row settings. "row" can be a number (<= 0: content height, <1: rel. height, <10: weight, >=10: abs. height) or a table with row setting.
 - space, spaceH, spaceV: Overall, horizontal and vertical spacing between cells.
 - align, alignH, alignV: Overall, horizontal and vertical cell alignment. See GetCellAlign() for possible values.
Columns:
 - width: Fixed column width (nil or <=0: content width, <1: rel. width, >=1: abs. width).
 - min or 1: Min width for content based width
 - max or 2: Max width for content based width
 - weight: Flexible column width. The leftover width after accounting for fixed-width columns is distributed to weighted columns according to their weights.
 - align, alignH, alignV: Overwrites the container setting for alignment.
Rows:
 - height: Fixed column height (nil or <=0: content height, <1: rel. height, >=1: abs. height).
 - weight: Flexible column height. The leftover height after accounting for fixed-height rows is distributed to weighted rows according to their weights.
Cell:
 - colspan: Makes a cell span multiple columns.
 - rowspan: Makes a cell span multiple rows.
 - align, alignH, alignV: Overwrites the container and column setting for alignment.
 - paddingLeft, paddingTop, paddingRight, paddingBottom, paddingH, paddingV, padding: Adds padding for an individual cell
]]
AceGUI:RegisterLayout("ABGP_Table", function (content, children)
    local obj = content.obj
    obj:PauseLayout()

    local tableObj = obj:GetUserData("table")
    local cols = tableObj.columns
    local rowObjs = tableObj.rows or {};
    local spaceH = tableObj.spaceH or tableObj.space or 0
    local spaceV = tableObj.spaceV or tableObj.space or 0
    local totalH = (content:GetWidth() or content.width or 0) - spaceH * (#cols - 1)

    -- We need to reuse these because layout events can come in very frequently
    local layoutCache = obj:GetUserData("layoutCache")
    if not layoutCache then
        layoutCache = {{}, {}, {}, {}, {}, {}}
        obj:SetUserData("layoutCache", layoutCache)
    end
    local t, laneH, laneV, rowspans, rowStart, colStart = unpack(layoutCache)

    -- Create the grid
    local n, slotFound = 0
    for i,child in ipairs(children) do
        if child:IsShown() then
            repeat
                n = n + 1
                local col = (n - 1) % #cols + 1
                local row = ceil(n / #cols)
                local rowspan = rowspans[col]
                local cell = rowspan and rowspan.child or child
                local cellObj = cell:GetUserData("cell")
                slotFound = not rowspan

                -- Rowspan
                if not rowspan and cellObj and cellObj.rowspan then
                    rowspan = {child = child, from = row, to = row + cellObj.rowspan - 1}
                    rowspans[col] = rowspan
                end
                if rowspan and i == #children then
                    rowspan.to = row
                end

                -- Colspan
                local colspan = max(0, min((cellObj and cellObj.colspan or 1) - 1, #cols - col))
                n = n + colspan

                -- Place the cell
                if not rowspan or rowspan.to == row then
                    t[n] = cell
                    rowStart[cell] = rowspan and rowspan.from or row
                    colStart[cell] = col

                    if rowspan then
                        rowspans[col] = nil
                    end
                end
            until slotFound
        end
    end

    local rows = ceil(n / #cols)
    local totalV = (content:GetHeight() or content.height or 0) - spaceV * (rows - 1)

    -- Determine fixed size cols and collect weights
    local extantH, totalWeight = totalH, 0
    for col,colObj in ipairs(cols) do
        laneH[col] = 0

        if type(colObj) == "number" then
            colObj = {[colObj >= 1 and colObj < 10 and "weight" or "width"] = colObj}
            cols[col] = colObj
        end

        if colObj.weight then
            -- Weight
            totalWeight = totalWeight + (colObj.weight or 1)
        else
            if not colObj.width or colObj.width <= 0 then
                -- Content width
                for row=1,rows do
                    local child = t[(row - 1) * #cols + col]
                    if child then
                        local f = child.frame
                        f:ClearAllPoints()
                        local childH = f:GetWidth() or 0

                        laneH[col] = max(laneH[col], childH - GetCellDimension("H", laneH, colStart[child], col - 1, spaceH))
                    end
                end

                laneH[col] = max(colObj.min or colObj[1] or 0, min(laneH[col], colObj.max or colObj[2] or laneH[col]))
            else
                -- Rel./Abs. width
                laneH[col] = colObj.width < 1 and colObj.width * totalH or colObj.width
            end
            extantH = max(0, extantH - laneH[col])
        end
    end

    -- Determine sizes based on weight
    local scale = totalWeight > 0 and extantH / totalWeight or 0
    for col,colObj in pairs(cols) do
        if colObj.weight then
            laneH[col] = scale * colObj.weight
        end
    end

    local extantV, totalWeight = totalV, 0
    for row,rowObj in pairs(rowObjs) do
        if type(rowObj) == "number" then
            rowObj = {[rowObj >= 1 and rowObj < 10 and "weight" or "height"] = rowObj}
            rowObjs[row] = rowObj;
        end
    end

    -- Arrange children
    for row=1,rows do
        local rowV = 0

        local rowObj = rowObjs[row];
        if not rowObj then
            rowObj = { height = 0 };
            rowObjs[row] = rowObj;
        end

        if rowObj.weight then
            -- Weight
            totalWeight = totalWeight + (rowObj.weight or 1)
        end

        -- Horizontal placement and sizing
        for col=1,#cols do
            local child = t[(row - 1) * #cols + col]
            if child then
                local colObj = cols[colStart[child]]
                local cellObj = child:GetUserData("cell")
                local offsetH = GetCellDimension("H", laneH, 1, colStart[child] - 1, spaceH) + (colStart[child] == 1 and 0 or spaceH)
                local cellH = GetCellDimension("H", laneH, colStart[child], col, spaceH)
                local paddingLeft, paddingRight = 0, 0
                if cellObj then
                    paddingLeft = pickfirstset(cellObj.paddingLeft, cellObj.paddingH, cellObj.padding, 0)
                    paddingRight = pickfirstset(cellObj.paddingRight, cellObj.paddingH, cellObj.padding, 0)
                end
                cellH = cellH - paddingLeft - paddingRight

                local f = child.frame
                f:ClearAllPoints()
                local childH = f:GetWidth() or 0

                local alignFn, align = GetCellAlign("H", tableObj, colObj, cellObj, cellH, childH)
                f:SetPoint("LEFT", content, offsetH + align + paddingLeft, 0)
                if child:IsFullWidth() or alignFn == "fill" or childH > cellH then
                    f:SetPoint("RIGHT", content, "LEFT", offsetH + align + paddingLeft + cellH, 0)
                end

                if child.DoLayout then
                    child:DoLayout()
                end

                if not rowObj.weight then
                    if not rowObj.height or rowObj.height <= 0 then
                        -- Content height
                        rowV = max(rowV, (f:GetHeight() or 0) - GetCellDimension("V", laneV, rowStart[child], row - 1, spaceV))
                    else
                        -- Rel./Abs. height
                        rowV = rowObj.height < 1 and rowObj.height * totalV or rowObj.height
                    end
                end
            end
        end

        laneV[row] = rowV
        extantV = max(0, extantV - laneV[row])
    end

    local scale = totalWeight > 0 and extantV / totalWeight or 0
    for row,rowObj in pairs(rowObjs) do
        if rowObj.weight then
            laneV[row] = scale * rowObj.weight
        end
    end

    for row=1,rows do
        -- Vertical placement and sizing
        for col=1,#cols do
            local child = t[(row - 1) * #cols + col]
            if child then
                local colObj = cols[colStart[child]]
                local cellObj = child:GetUserData("cell")
                local offsetV = GetCellDimension("V", laneV, 1, rowStart[child] - 1, spaceV) + (rowStart[child] == 1 and 0 or spaceV)
                local cellV = GetCellDimension("V", laneV, rowStart[child], row, spaceV)
                local paddingTop, paddingBottom = 0, 0
                if cellObj then
                    paddingTop = pickfirstset(cellObj.paddingTop, cellObj.paddingV, cellObj.padding, 0)
                    paddingBottom = pickfirstset(cellObj.paddingBottom, cellObj.paddingV, cellObj.padding, 0)
                end
                cellV = cellV - paddingTop - paddingBottom

                local f = child.frame
                local childV = f:GetHeight() or 0

                local alignFn, align = GetCellAlign("V", tableObj, colObj, cellObj, cellV, childV)
                if child:IsFullHeight() or alignFn == "fill" then
                    f:SetPoint("BOTTOM", content, "TOP", 0, -(offsetV + align + paddingTop + cellV))
                end
                f:SetPoint("TOP", content, 0, -(offsetV + align + paddingTop))
            end
        end
    end

    -- Calculate total height
    local totalV = GetCellDimension("V", laneV, 1, #laneV, spaceV)

    -- Cleanup
    for _,v in pairs(layoutCache) do wipe(v) end

    safecall(obj.LayoutFinished, obj, nil, totalV)
obj:ResumeLayout()
end)
