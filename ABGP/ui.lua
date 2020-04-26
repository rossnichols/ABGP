local _G = _G;
local ABGP = ABGP;
local AceGUI = _G.LibStub("AceGUI-3.0");

local IsInGuild = IsInGuild;
local CreateFrame = CreateFrame;
local UnitName = UnitName;
local UnitExists = UnitExists;
local IsInGroup = IsInGroup;
local date = date;
local time = time;
local table = table;
local ipairs = ipairs;
local pairs = pairs;
local unpack = unpack;

local activeWindow;
local allowedClasses = {
    DRUID = "Druid",
    HUNTER = "Hunter",
    MAGE = "Mage",
    PALADIN = "Paladin",
    PRIEST = "Priest",
    ROGUE = "Rogue",
    WARLOCK = "Warlock",
    WARRIOR = "Warrior",
};
local allowedPriorities = ABGP:GetItemPriorities();
local onlyUsable = false;
local onlyFaved = false;
local onlyGrouped = false;
local currentRaidGroup;

ABGP.UICommands = {
    ShowItemHistory = "ShowItemHistory",
};

local function PopulateUI(rebuild, reason, command)
    if not activeWindow then return; end
    local container = activeWindow:GetUserData("container");
    if rebuild then
        container:ReleaseChildren();
    end

    local drawFunc = activeWindow:GetUserData("drawFunc");
    drawFunc(container, rebuild, reason, command);
end

local function DrawPriority(container, rebuild, reason)
    if not rebuild and reason and reason ~= ABGP.RefreshReasons.ACTIVE_PLAYERS_REFRESHED then return; end

    local widths = { 35, 120, 110, 75, 75, 75 };
    if rebuild then
        local classSelector = AceGUI:Create("ABGP_Filter");
        classSelector:SetWidth(110);
        classSelector:SetValues(allowedClasses, true, {
            DRUID = "Druid",
            HUNTER = "Hunter",
            MAGE = "Mage",
            PALADIN = "Paladin",
            PRIEST = "Priest",
            ROGUE = "Rogue",
            WARLOCK = "Warlock",
            WARRIOR = "Warrior",
        }, {
            "DRUID",
            "HUNTER",
            "MAGE",
            "PALADIN",
            "PRIEST",
            "ROGUE",
            "WARLOCK",
            "WARRIOR",
        });
        classSelector:SetCallback("OnFilterUpdated", function()
            PopulateUI(false);
        end);
        classSelector:SetText("Classes");
        container:AddChild(classSelector);

        if IsInGroup() then
            local grouped = AceGUI:Create("CheckBox");
            grouped:SetWidth(80);
            grouped:SetLabel("Grouped");
            grouped:SetValue(onlyGrouped);
            grouped:SetCallback("OnValueChanged", function(widget, event, value)
                onlyGrouped = value;
                PopulateUI(false);
            end);
            container:AddChild(grouped);
        else
            onlyGrouped = false;
        end

        local scrollContainer = AceGUI:Create("SimpleGroup");
        scrollContainer:SetFullWidth(true);
        scrollContainer:SetFullHeight(true);
        scrollContainer:SetLayout("Flow");
        container:AddChild(scrollContainer);

        local columns = { "", "Player", "Rank", "EP", "GP", "Priority", weights = { unpack(widths) } };
        local header = AceGUI:Create("SimpleGroup");
        header:SetFullWidth(true);
        header:SetLayout("Table");
        header:SetUserData("table", { columns = columns.weights });
        scrollContainer:AddChild(header);

        for i = 1, #columns do
            local desc = AceGUI:Create("ABGP_Header");
            desc:SetText(columns[i]);
            header:AddChild(desc);
        end

        local scroll = AceGUI:Create("ScrollFrame");
        scroll:SetFullWidth(true);
        scroll:SetFullHeight(true);
        scroll:SetLayout("List");
        scrollContainer:AddChild(scroll);
        container:SetUserData("priorities", scroll);
    end

    local priorities = container:GetUserData("priorities");
    priorities:ReleaseChildren();
    local count = 0;
    local order = 0;
    local lastPriority = -1;
    local priority = ABGP.Priorities[ABGP.CurrentPhase];
    for i, data in ipairs(priority) do
        local inRaidGroup = not currentRaidGroup or ABGP:GetRaidGroup(data.rank, ABGP.CurrentPhase) == currentRaidGroup;
        local isGrouped = not onlyGrouped or UnitExists(data.player);
        if allowedClasses[data.class] and inRaidGroup and isGrouped then
            count = count + 1;
            local elt = AceGUI:Create("ABGP_Priority");
            elt:SetFullWidth(true);
            if data.player == UnitName("player") then
                data.important = true;
            end
            if data.priority ~= lastPriority then
                lastPriority = data.priority;
                order = count;
            end
            data.order = order;
            elt:SetData(data);
            elt:SetWidths(widths);
            elt:ShowBackground((count % 2) == 0);
            elt:SetCallback("OnClick", function(widget, event, button)
                if button == "RightButton" then
                    ABGP:ShowContextMenu({
                        {
                            text = "Show player history",
                            func = function(self, data)
                                if activeWindow then
                                    local container = activeWindow:GetUserData("container");
                                    container:SelectTab("gp");
                                    container:GetUserData("search"):SetText(("\"%s\""):format(data.player));
                                    PopulateUI(false);
                                end
                            end,
                            arg1 = elt.data,
                            notCheckable = true
                        },
                        { text = "Cancel", notCheckable = true },
                    });
                end
            end);

            priorities:AddChild(elt);
        end
    end
end

local function DrawItemHistory(container, rebuild, reason, command)
    if not rebuild and reason and reason ~= ABGP.RefreshReasons.HISTORY_UPDATED then return; end

    local widths = { 120, 70, 50, 1.0 };
    if rebuild then
        local mainLine = AceGUI:Create("SimpleGroup");
        mainLine:SetFullWidth(true);
        mainLine:SetLayout("table");
        mainLine:SetUserData("table", { columns = { 0, 0, 1.0, 0 } });
        container:AddChild(mainLine);

        local search = AceGUI:Create("ABGP_EditBox");
        search:SetWidth(125);
        search:SetCallback("OnEnterPressed", function(widget)
            AceGUI:ClearFocus();
            PopulateUI(false);
        end);
        search:SetCallback("OnEnter", function(widget)
            _G.ShowUIPanel(_G.GameTooltip);
            _G.GameTooltip:SetOwner(widget.frame, "ANCHOR_TOPLEFT");
            _G.GameTooltip:ClearLines();
            _G.GameTooltip:AddLine("Help");
            _G.GameTooltip:AddLine("Search by player, class, item, or date. Enclose your search in \"quotes\" for an exact match. All searches are case-insensitive.", 1, 1, 1, true);
            _G.GameTooltip:Show();
        end);
        search:SetCallback("OnLeave", function(widget)
            _G.GameTooltip:Hide();
        end);
        mainLine:AddChild(search);
        container:SetUserData("search", search);

        local desc = AceGUI:Create("Label");
        desc:SetWidth(50);
        desc:SetText(" Search");
        mainLine:AddChild(desc);

        if ABGP:IsPrivileged() then
            local spacer = AceGUI:Create("Label");
            mainLine:AddChild(spacer);

            local export = AceGUI:Create("Button");
            export:SetWidth(100);
            export:SetText("Export");
            export:SetCallback("OnClick", function(widget, event)
                local history = container:GetUserData("itemHistory");
                local text = "";
                for i = #history.children, 1, -1 do
                    local elt = history.children[i];
                    local data = elt.data;

                    local item = data.item;
                    local value = ABGP:GetItemValue(item);
                    if value and value.gp ~= data.gp then
                        if data.gp == 0 then
                            item = item .. " OFF";
                        else
                            item = ("%s @ %d"):format(item, data.gp);
                        end
                    end

                    text = text .. ("%s\t%s\t%s%s"):format(
                        item, data.player, data.date, (i == 1 and "" or "\n"));
                end

                local window = AceGUI:Create("Window");
                window.frame:SetFrameStrata("DIALOG");
                window:SetTitle("Export");
                window:SetLayout("Fill");
                window:SetCallback("OnClose", function(widget) AceGUI:Release(widget); ABGP:CloseWindow(widget); end);
                ABGP:OpenWindow(window);

                local edit = AceGUI:Create("MultiLineEditBox");
                edit:SetLabel("In the spreadsheet, paste into the 'Item' colum.");
                edit:SetText(text);
                edit.button:Enable();
                window:AddChild(edit);
                window.frame:Raise();
                edit:SetFocus();
                edit:HighlightText();
                edit:SetCallback("OnEnterPressed", function()
                    window:Hide();
                end);
            end);
            mainLine:AddChild(export);
        end

        local pagination = AceGUI:Create("ABGP_Paginator");
        pagination:SetFullWidth(true);
        pagination:SetCallback("OnRangeSet", function()
            PopulateUI(false);
        end);
        container:AddChild(pagination);
        container:SetUserData("pagination", pagination);

        local scrollContainer = AceGUI:Create("SimpleGroup");
        scrollContainer:SetFullWidth(true);
        scrollContainer:SetFullHeight(true);
        scrollContainer:SetLayout("Flow");
        container:AddChild(scrollContainer);

        local columns = { "Player", "Date", "GP", "Item", weights = { unpack(widths) } };
        local header = AceGUI:Create("SimpleGroup");
        header:SetFullWidth(true);
        header:SetLayout("Table");
        header:SetUserData("table", { columns = columns.weights });
        scrollContainer:AddChild(header);

        for i = 1, #columns do
            local desc = AceGUI:Create("ABGP_Header");
            desc:SetText(columns[i]);
            if columns[i] == "GP" then
                desc:SetJustifyH("RIGHT");
                desc:SetPadding(2, -10);
            end
            header:AddChild(desc);
        end

        local scroll = AceGUI:Create("ScrollFrame");
        scroll:SetFullWidth(true);
        scroll:SetFullHeight(true);
        scroll:SetLayout("List");
        scrollContainer:AddChild(scroll);
        container:SetUserData("itemHistory", scroll);
    end

    if command then
        if command.command == ABGP.UICommands.ShowItemHistory then
            container:GetUserData("search"):SetText(command.args);
        end
    end

    local history = container:GetUserData("itemHistory");
    history:ReleaseChildren();

    local pagination = container:GetUserData("pagination");
    local search = container:GetUserData("search");
    local searchText = search:GetText():lower();
    local gpHistory = _G.ABGP_Data[ABGP.CurrentPhase].gpHistory;
    local filtered = gpHistory;
    if searchText ~= "" or currentRaidGroup then
        filtered = {};
        local exact = searchText:match("^\"(.+)\"$");
        exact = exact and exact:lower() or exact;
        for _, data in ipairs(gpHistory) do
            local epgp = ABGP:GetActivePlayer(data.player);
            if epgp then
                if not currentRaidGroup or ABGP:GetRaidGroup(epgp.rank, ABGP.CurrentPhase) == currentRaidGroup then
                    local class = epgp.class;
                    if exact then
                        if data.player:lower() == exact or
                            data.item:lower() == exact or
                            class:lower() == exact or
                            data.date:lower() == exact then
                            table.insert(filtered, data);
                        end
                    else
                        if data.player:lower():find(searchText, 1, true) or
                            data.item:lower():find(searchText, 1, true) or
                            class:lower():find(searchText, 1, true) or
                            data.date:lower():find(searchText, 1, true) then
                            table.insert(filtered, data);
                        end
                    end
                end
            end
        end
    end

    pagination:SetValues(#filtered, 50);
    if #filtered > 0 then
        local first, last = pagination:GetRange();
        local count = 0;
        for i = first, last do
            count = count + 1;
            local data = filtered[i];
            local elt = AceGUI:Create("ABGP_ItemHistory");
            elt:SetFullWidth(true);
            elt:SetData(data);
            elt:SetWidths(widths);
            elt:ShowBackground((count % 2) == 0);
            elt:SetCallback("OnClick", function(widget, event, button)
                if button == "RightButton" then
                    local context = {
                        {
                            text = "Show player history",
                            func = function(self, data)
                                if activeWindow then
                                    search:SetText(("\"%s\""):format(data.player));
                                    PopulateUI(false);
                                end
                            end,
                            arg1 = data,
                            notCheckable = true
                        },
                        {
                            text = "Show item history",
                            func = function(self, data)
                                if activeWindow then
                                    search:SetText(("\"%s\""):format(data.item));
                                    PopulateUI(false);
                                end
                            end,
                            arg1 = data,
                            notCheckable = true
                        },
                    };
                    if data.itemLink and ABGP:CanFavoriteItems() then
                        local faved = ABGP:IsItemFavorited(data.itemLink);
                        table.insert(context, 1, {
                            text = faved and "Remove item favorite" or "Add item favorite",
                            func = function(self, data)
                                ABGP:SetItemFavorited(data.itemLink, not faved);
                            end,
                            arg1 = data,
                            notCheckable = true
                        });
                    end
                    if data.editId and data.sender == UnitName("player") then
                        table.insert(context, {
                            text = "Edit cost",
                            func = function(self, data)
                                data.value = ABGP:GetItemValue(data.item);
                                _G.StaticPopup_Show("ABGP_UPDATE_COST", data.itemLink, ABGP:ColorizeName(data.player), data);
                            end,
                            arg1 = data,
                            notCheckable = true
                        });
                        table.insert(context, {
                            text = "Edit player",
                            func = function(self, data)
                                data.value = ABGP:GetItemValue(data.item);
                                _G.StaticPopup_Show("ABGP_UPDATE_PLAYER", data.itemLink, data.gp, data);
                            end,
                            arg1 = data,
                            notCheckable = true
                        });
                        table.insert(context, {
                            text = "Delete entry",
                            func = function(self, data)
                                data.value = ABGP:GetItemValue(data.item);
                                local award = ("%s for %d GP"):format(ABGP:ColorizeName(data.player), data.gp);
                                _G.StaticPopup_Show("ABGP_CONFIRM_UNAWARD", data.itemLink, award, data);
                            end,
                            arg1 = data,
                            notCheckable = true
                        });
                    end
                    table.insert(context, { text = "Cancel", notCheckable = true });
                    ABGP:ShowContextMenu(context);
                end
            end);
            history:AddChild(elt);
        end
    end
end

local function DrawItems(container, rebuild, reason)
    if not rebuild and reason then return; end

    local widths = { 225, 50, 50, 1.0 };
    if rebuild then
        local mainLine = AceGUI:Create("SimpleGroup");
        mainLine:SetFullWidth(true);
        mainLine:SetLayout("table");
        mainLine:SetUserData("table", { columns = { 0, 0, 0, 0, 0, 1.0, 0 } });
        container:AddChild(mainLine);

        local priSelector = AceGUI:Create("ABGP_Filter");
        priSelector:SetWidth(125);
        priSelector:SetValues(allowedPriorities, true, ABGP:GetItemPriorities());
        priSelector:SetCallback("OnFilterUpdated", function()
            PopulateUI(false);
        end);
        priSelector:SetText("Priorities");
        mainLine:AddChild(priSelector);
        container:SetUserData("priSelector", priSelector);

        local search = AceGUI:Create("ABGP_EditBox");
        search:SetWidth(120);
        search:SetCallback("OnEnterPressed", function(widget)
            AceGUI:ClearFocus();
            PopulateUI(false);
        end);
        search:SetCallback("OnEnter", function(widget)
            _G.ShowUIPanel(_G.GameTooltip);
            _G.GameTooltip:SetOwner(widget.frame, "ANCHOR_TOPLEFT");
            _G.GameTooltip:ClearLines();
            _G.GameTooltip:AddLine("Help");
            _G.GameTooltip:AddLine("Search by item name, source, or notes. Enclose your search in \"quotes\" for an exact match. All searches are case-insensitive.", 1, 1, 1, true);
            _G.GameTooltip:Show();
        end);
        search:SetCallback("OnLeave", function(widget)
            _G.GameTooltip:Hide();
        end);
        mainLine:AddChild(search);
        container:SetUserData("search", search);

        local desc = AceGUI:Create("Label");
        desc:SetWidth(50);
        desc:SetText(" Search");
        mainLine:AddChild(desc);

        local usable = AceGUI:Create("CheckBox");
        usable:SetWidth(80);
        usable:SetLabel("Usable");
        usable:SetValue(onlyUsable);
        usable:SetCallback("OnValueChanged", function(widget, event, value)
            onlyUsable = value;
            PopulateUI(false);
        end);
        mainLine:AddChild(usable);

        if ABGP:CanFavoriteItems() then
            local faved = AceGUI:Create("CheckBox");
            faved:SetWidth(80);
            faved:SetLabel("Faved");
            faved:SetValue(onlyFaved);
            faved:SetCallback("OnValueChanged", function(widget, event, value)
                onlyFaved = value;
                PopulateUI(false);
            end);
            mainLine:AddChild(faved);
        else
            local spacer = AceGUI:Create("Label");
            mainLine:AddChild(spacer);
        end

        if ABGP:IsPrivileged() then
            local spacer = AceGUI:Create("Label");
            mainLine:AddChild(spacer);

            local export = AceGUI:Create("Button");
            export:SetWidth(100);
            export:SetText("Export");
            export:SetCallback("OnClick", function(widget, event)
                local items = _G.ABGP_Data[ABGP.CurrentPhase].itemValues;
                local text = "";
                local _, sortedPriorities = ABGP:GetItemPriorities();
                local text = ("Boss\tItem\t%s\tGP Cost\tNotes\n"):format(table.concat(sortedPriorities, "\t"));
                for i, item in ipairs(items) do
                    local itemPriorities = {};
                    for _, pri in ipairs(item.priority) do itemPriorities[pri] = true; end
                    local priorities = {};
                    for _, pri in ipairs(sortedPriorities) do
                        table.insert(priorities, itemPriorities[pri] and "TRUE" or "");
                    end
                    text = text .. ("%s\t%s\t%s\t%s\t%s%s"):format(
                        item[4] or "", item[1], table.concat(priorities, "\t"), item[2], item[5] or "", (i == #items and "" or "\n"));
                end

                local window = AceGUI:Create("Window");
                window.frame:SetFrameStrata("DIALOG");
                window:SetTitle("Export");
                window:SetLayout("Fill");
                window:SetCallback("OnClose", function(widget) AceGUI:Release(widget); ABGP:CloseWindow(widget); end);
                ABGP:OpenWindow(window);

                local edit = AceGUI:Create("MultiLineEditBox");
                edit:SetLabel("In the spreadsheet, select all, press <delete>, select A1, then paste.");
                edit:SetText(text);
                edit.button:Enable();
                window:AddChild(edit);
                window.frame:Raise();
                edit:SetFocus();
                edit:HighlightText();
                edit:SetCallback("OnEnterPressed", function()
                    window:Hide();
                end);
            end);
            mainLine:AddChild(export);
        end

        local pagination = AceGUI:Create("ABGP_Paginator");
        pagination:SetFullWidth(true);
        pagination:SetCallback("OnRangeSet", function()
            PopulateUI(false);
        end);
        container:AddChild(pagination);
        container:SetUserData("pagination", pagination);

        local scrollContainer = AceGUI:Create("SimpleGroup");
        scrollContainer:SetFullWidth(true);
        scrollContainer:SetFullHeight(true);
        scrollContainer:SetLayout("Flow");
        container:AddChild(scrollContainer);

        local columns = { "Item", "GP", "Notes", "Priority", weights = { unpack(widths) } };
        local header = AceGUI:Create("SimpleGroup");
        header:SetFullWidth(true);
        header:SetLayout("Table");
        header:SetUserData("table", { columns = columns.weights });
        scrollContainer:AddChild(header);

        for i = 1, #columns do
            local desc = AceGUI:Create("ABGP_Header");
            desc:SetText(columns[i]);
            if columns[i] == "GP" then
                desc:SetJustifyH("RIGHT");
                desc:SetPadding(2, -10);
            end
            header:AddChild(desc);
        end

        local scroll = AceGUI:Create("ScrollFrame");
        scroll:SetFullWidth(true);
        scroll:SetFullHeight(true);
        scroll:SetLayout("List");
        scrollContainer:AddChild(scroll);
        container:SetUserData("itemList", scroll);
    end

    local itemList = container:GetUserData("itemList");
    itemList:ReleaseChildren();
    local count = 0;
    local items = _G.ABGP_Data[ABGP.CurrentPhase].itemValues;
    local filtered = {};
    local selector = container:GetUserData("priSelector");
    local search = container:GetUserData("search");
    local searchText = search:GetText():lower();

    if selector:ShowingAll() and not onlyUsable and not onlyFaved and searchText == "" then
        for i, item in ipairs(items) do
            table.insert(filtered, item)
        end
    else
        local exact = searchText:match("^\"(.+)\"$");
        exact = exact and exact:lower() or exact;
        for i, item in ipairs(items) do
            if not onlyUsable or ABGP:IsItemUsable(item[3]) then
                if not onlyFaved or ABGP:IsItemFavorited(item[3]) then
                    local matchesSearch = false;
                    if exact then
                        if item[1]:lower() == exact or
                            item[4]:lower() == exact or
                            (item[6] or ""):lower() == exact then
                            matchesSearch = true;
                        end
                    else
                        if item[1]:lower():find(searchText, 1, true) or
                            item[4]:lower():find(searchText, 1, true) or
                            (item[6] or ""):lower():find(searchText, 1, true) then
                            matchesSearch = true;
                        end
                    end

                    if matchesSearch then
                        if #item[5] > 0 then
                            for _, pri in ipairs(item[5]) do
                                if allowedPriorities[pri] then
                                    table.insert(filtered, item);
                                    break;
                                end
                            end
                        else
                            table.insert(filtered, item);
                        end
                    end
                end
            end
        end
    end

    table.sort(filtered, function(a, b)
        return a[1] < b[1];
    end);

    local pagination = container:GetUserData("pagination");
    pagination:SetValues(#filtered, 50);
    if #filtered > 0 then
        local first, last = pagination:GetRange();
        local count = 0;
        for i = first, last do
            count = count + 1;
            local data = filtered[i];
            local elt = AceGUI:Create("ABGP_ItemValue");
            elt:SetData(data);
            elt:SetWidths(widths);
            elt:SetFullWidth(true);
            elt:ShowBackground((count % 2) == 0);
            elt:SetCallback("OnClick", function(widget, event, button)
                if button == "RightButton" then
                    local context = {
                        {
                            text = "Show item history",
                            func = function(self, data)
                                if activeWindow then
                                    local container = activeWindow:GetUserData("container");
                                    container:SelectTab("gp");
                                    container:GetUserData("search"):SetText(("\"%s\""):format(data[1]));
                                    PopulateUI(false);
                                end
                            end,
                            arg1 = data,
                            notCheckable = true
                        },
                    };
                    if data[3] and ABGP:CanFavoriteItems() then
                        local faved = ABGP:IsItemFavorited(data[3]);
                        table.insert(context, 1, {
                            text = faved and "Remove favorite" or "Add favorite",
                            func = function(self, data)
                                ABGP:SetItemFavorited(data[3], not faved);
                                elt:SetData(data);
                            end,
                            arg1 = data,
                            notCheckable = true
                        });
                    end
                    if ABGP:IsPrivileged() then
                        table.insert(context, {
                            text = "Edit GP",
                            func = function(self, widget)
                                _G.StaticPopup_Show("ABGP_UPDATE_GP", widget.data[3], nil, widget);
                            end,
                            arg1 = widget,
                            notCheckable = true
                        });
                        table.insert(context, {
                            text = "Edit notes",
                            func = function(self, widget)
                                _G.StaticPopup_Show("ABGP_UPDATE_NOTES", widget.data[3], nil, widget);
                            end,
                            arg1 = widget,
                            notCheckable = true
                        });
                        table.insert(context, {
                            text = "Edit priority",
                            func = function(self, widget)
                                widget:EditPriorities();
                            end,
                            arg1 = widget,
                            notCheckable = true
                        });
                    end
                    table.insert(context, { text = "Cancel", notCheckable = true });
                    ABGP:ShowContextMenu(context);
                end
            end);
            elt:SetCallback("OnPrioritiesUpdated", function(widget, event)
                ABGP:Notify("Priorities for %s: %s.", widget.data[3], table.concat(widget.data.priority, ", "));
                ABGP:CommitItemData();
                ABGP:RefreshItemValues();
            end);
            itemList:AddChild(elt);
        end
    end
end

local function DrawAuditLog(container, rebuild, reason)
    if not rebuild and reason then return; end

    local widths = { 70, 70, 1.0 };
    if rebuild then
        local pagination = AceGUI:Create("ABGP_Paginator");
        pagination:SetFullWidth(true);
        pagination:SetCallback("OnRangeSet", function()
            PopulateUI(false);
        end);
        container:AddChild(pagination);
        container:SetUserData("pagination", pagination);

        local scrollContainer = AceGUI:Create("SimpleGroup");
        scrollContainer:SetFullWidth(true);
        scrollContainer:SetFullHeight(true);
        scrollContainer:SetLayout("Flow");
        container:AddChild(scrollContainer);

        local columns = { "Date", "Type", "Info", weights = { unpack(widths) } };
        local header = AceGUI:Create("SimpleGroup");
        header:SetFullWidth(true);
        header:SetLayout("Table");
        header:SetUserData("table", { columns = columns.weights });
        scrollContainer:AddChild(header);

        for i = 1, #columns do
            local desc = AceGUI:Create("ABGP_Header");
            desc:SetText(columns[i]);
            header:AddChild(desc);
        end

        local scroll = AceGUI:Create("ScrollFrame");
        scroll:SetFullWidth(true);
        scroll:SetFullHeight(true);
        scroll:SetLayout("List");
        scrollContainer:AddChild(scroll);
        container:SetUserData("auditLog", scroll);
    end

    local auditLog = container:GetUserData("auditLog");
    auditLog:ReleaseChildren();

    local entries = _G.ABGP_ItemAuditLog[ABGP.CurrentPhase];
    local pagination = container:GetUserData("pagination");
    pagination:SetValues(#entries, 100);
    if #entries > 0 then
        local first, last = pagination:GetRange();
        local requestTypes = {
            [ABGP.RequestTypes.MS] = "ms",
            [ABGP.RequestTypes.OS] = "os",
            [ABGP.RequestTypes.ROLL] = "roll",
            [ABGP.RequestTypes.MANUAL] = "manual",
        };
        for i = first, last do
            local data = entries[i];
            if data.distribution then
                local distrib = data.distribution;
                local audit;
                if distrib.trashed then
                    audit = ("%s was disenchanted"):format(data.itemLink);
                else
                    local requestType = requestTypes[distrib.requestType];
                    if distrib.roll then
                        requestType = ("%s:%d"):format(requestType, distrib.roll);
                    end
                    local override = distrib.override
                        and (",%s"):format(distrib.override)
                        or "";
                    local epgp = ("ep=%.2f gp=%.2f pri=%.2f"):format(distrib.ep, distrib.gp, distrib.priority);
                    audit = ("%s for %dgp to %s (%s%s): %s"):format(
                        data.itemLink, distrib.cost, distrib.player, requestType, override, epgp);
                end
                local elt = AceGUI:Create("ABGP_AuditLog");
                elt:SetFullWidth(true);
                elt:SetData({
                    date = date("%m/%d/%y", data.time),
                    type = "Distrib",
                    audit = audit,
                    important = true,
                });
                elt:SetWidths(widths);
                auditLog:AddChild(elt);
            elseif data.request then
                local request = data.request;
                local requestType = requestTypes[request.requestType];
                if request.roll then
                    requestType = ("%s:%d"):format(requestType, request.roll);
                end
                local epgp = ("ep=%.2f gp=%.2f pri=%.2f"):format(request.ep, request.gp, request.priority);
                local audit = ("%s by %s (%s): %s"):format(
                    data.itemLink, request.player, requestType, epgp);
                local elt = AceGUI:Create("ABGP_AuditLog");
                elt:SetFullWidth(true);
                elt:SetData({
                    date = date("%m/%d/%y", data.time),
                    type = "Request",
                    audit = audit,
                    important = false,
                });
                elt:SetWidths(widths);
                auditLog:AddChild(elt);
            elseif data.update then
                local update = data.update;
                local audit = "";
                if update.oldPlayer then
                    audit = ("%s recipient new=%s old=%s cost=%d"):format(update.itemLink, update.player or "none", update.oldPlayer, update.cost);
                elseif update.oldCost then
                    audit = ("%s cost new=%d old=%d player=%s"):format(update.itemLink, update.cost, update.oldCost, update.player);
                end
                local elt = AceGUI:Create("ABGP_AuditLog");
                elt:SetFullWidth(true);
                elt:SetData({
                    date = date("%m/%d/%y", data.time),
                    type = "Update",
                    audit = audit,
                    important = false,
                });
                elt:SetWidths(widths);
                auditLog:AddChild(elt);
            end
        end
    end
end

ABGP.RefreshReasons = {
    ACTIVE_PLAYERS_REFRESHED = "ACTIVE_PLAYERS_REFRESHED",
    HISTORY_UPDATED = "HISTORY_UPDATED",
};
function ABGP:RefreshUI(reason)
    PopulateUI(false, reason);
end

function ABGP:CreateMainWindow(command)
    local window = AceGUI:Create("Window");
    window.frame:SetFrameStrata("DIALOG");
    window:SetTitle(self:ColorizeText("ABGP"));
    window:SetLayout("Flow");
    self:BeginWindowManagement(window, "main", {
        version = 1,
        defaultWidth = 600,
        minWidth = 625,
        maxWidth = 750,
        defaultHeight = 500,
        minHeight = 300,
        maxHeight = 700
    });
    ABGP:OpenWindow(window);
    window:SetCallback("OnClose", function(widget)
        ABGP:EndWindowManagement(widget);
        ABGP:CloseWindow(widget);
        AceGUI:Release(widget);
        activeWindow = nil;
    end);

    local mainLine = AceGUI:Create("SimpleGroup");
    mainLine:SetFullWidth(true);
    mainLine:SetLayout("table");
    mainLine:SetUserData("table", { columns = { 0, 0, 1.0, 0 } });
    window:AddChild(mainLine);

    local phases, phaseNames = {}, {};
    for i, v in ipairs(ABGP:IsPrivileged() and ABGP.PhasesSortedAll or ABGP.PhasesSorted) do phases[i] = v; end
    for k, v in pairs(ABGP:IsPrivileged() and ABGP.PhaseNamesAll or ABGP.PhaseNames) do phaseNames[k] = v; end
    local phaseSelector = AceGUI:Create("Dropdown");
    phaseSelector:SetWidth(110);
    phaseSelector:SetList(phaseNames, phases);
    phaseSelector:SetCallback("OnValueChanged", function(widget, event, value)
        ABGP.CurrentPhase = value;

        if activeWindow then
            local container = activeWindow:GetUserData("container");
            local pagination = container:GetUserData("pagination");
            if pagination then
                pagination:SetPage(1);
            end
        end
        PopulateUI(false);
    end);
    mainLine:AddChild(phaseSelector);

    local raidGroups, raidGroupNames = {}, {};
    for i, v in ipairs(ABGP.RaidGroupsSorted) do raidGroups[i] = v; end
    for k, v in pairs(ABGP.RaidGroupNames) do raidGroupNames[k] = v; end
    table.insert(raidGroups, "ALL");
    raidGroupNames.ALL = "All";
    local groupSelector = AceGUI:Create("Dropdown");
    groupSelector:SetWidth(110);
    groupSelector:SetList(raidGroupNames, raidGroups);
    groupSelector:SetCallback("OnValueChanged", function(widget, event, value)
        currentRaidGroup = (value ~= "ALL") and value or nil;

        if activeWindow then
            local container = activeWindow:GetUserData("container");
            local pagination = container:GetUserData("pagination");
            if pagination then
                pagination:SetPage(1);
            end
        end
        PopulateUI(false);
    end);
    currentRaidGroup = ABGP:GetPreferredRaidGroup();
    groupSelector:SetValue(currentRaidGroup);
    mainLine:AddChild(groupSelector);

    if command then
        ABGP.CurrentPhase = command.phase;
    end
    phaseSelector:SetValue(ABGP.CurrentPhase);

    local spacer = AceGUI:Create("Label");
    mainLine:AddChild(spacer);

    local opts = AceGUI:Create("Button");
    opts:SetWidth(100);
    opts:SetText("Options");
    opts:SetCallback("OnClick", function(widget)
        window:Hide();
        ABGP:ShowOptionsWindow();
    end);
    mainLine:AddChild(opts);

    local tabs = {
        { value = "priority", text = "Priority", draw = DrawPriority },
        -- { value = "ep", text = "Effort Points", draw = DrawEP },
        { value = "gp", text = "Item History", draw = DrawItemHistory },
        { value = "items", text = "Items", draw = DrawItems },
    };
    local hasAuditLog = false;
    for _, log in pairs(_G.ABGP_ItemAuditLog) do
        if #log > 0 then
            hasAuditLog = true;
            break;
        end
    end
    if hasAuditLog then
        table.insert(tabs, { value = "audit", text = "Audit Log", draw = DrawAuditLog });
    end
    local tabGroup = AceGUI:Create("TabGroup");
    tabGroup:SetLayout("Flow");
    tabGroup:SetFullWidth(true);
    tabGroup:SetFullHeight(true);
    tabGroup:SetTabs(tabs);
    tabGroup:SetCallback("OnGroupSelected", function(widget, event, value)
        for _, tab in ipairs(tabs) do
            if tab.value == value then
                window:SetUserData("drawFunc", tab.draw);
                break;
            end
        end
        PopulateUI(true);
    end);
    window:AddChild(tabGroup);
    window:SetUserData("container", tabGroup);

    local tab = 1;
    if command then
        if command.command == ABGP.UICommands.ShowItemHistory then
            tab = 2;
        end
    end
    tabGroup:SelectTab(tabs[tab].value);

    return window;
end

function ABGP:ShowMainWindow(command)
    if activeWindow and not command then return; end

    if activeWindow then
        activeWindow:Hide();
        activeWindow = nil;
    end

    activeWindow = self:CreateMainWindow(command);
    PopulateUI(true, nil, command);
end

StaticPopupDialogs["ABGP_UPDATE_COST"] = {
    text = "Update the cost of %s to %s:",
    button1 = "Done",
    button2 = "Cancel",
	hasEditBox = 1,
	maxLetters = 31,
    OnAccept = function(self, data)
        local cost = ABGP:DistribValidateCost(self.editBox:GetText(), data.player, data.value);
        if cost then
            ABGP:HistoryUpdateCost(data, cost);
        end
    end,
    OnShow = function(self, data)
        self.editBox:SetAutoFocus(false);
        self.button1:Disable();
    end,
    EditBoxOnTextChanged = function(self, data)
        local parent = self:GetParent();
        local cost = ABGP:DistribValidateCost(parent.editBox:GetText(), data.player, data.value);
        if cost then
            parent.button1:Enable();
        else
            parent.button1:Disable();
        end
    end,
    EditBoxOnEnterPressed = function(self, data)
        local parent = self:GetParent();
        if parent.button1:IsEnabled() then
            parent.button1:Click();
        else
            local _, errorText = ABGP:DistribValidateCost(parent.editBox:GetText(), data.player, data.value);
            ABGP:Error("Invalid cost! %s.", errorText);
        end
    end,
    EditBoxOnEscapePressed = function(self)
		self:ClearFocus();
    end,
    OnHide = function(self, data)
        self.editBox:SetAutoFocus(true);
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    exclusive = true,
};

StaticPopupDialogs["ABGP_UPDATE_PLAYER"] = {
    text = "Update the recipient of %s for %d GP:",
    button1 = "Done",
    button2 = "Cancel",
	hasEditBox = 1,
	autoCompleteSource = GetAutoCompleteResults,
	autoCompleteArgs = { AUTOCOMPLETE_FLAG_IN_GROUP, AUTOCOMPLETE_FLAG_NONE },
	maxLetters = 31,
    OnAccept = function(self, data)
        local player = ABGP:DistribValidateRecipient(self.editBox:GetText(), data.gp, data.value);
        if player then
            ABGP:HistoryUpdatePlayer(data, player);
        end
    end,
    OnShow = function(self, data)
        self.editBox:SetAutoFocus(false);
        self.button1:Disable();
    end,
    EditBoxOnTextChanged = function(self, data)
        local parent = self:GetParent();
        local player = ABGP:DistribValidateRecipient(parent.editBox:GetText(), data.gp, data.value);
        if player then
            parent.button1:Enable();
        else
            parent.button1:Disable();
        end
    end,
    EditBoxOnEnterPressed = function(self, data)
        local parent = self:GetParent();
        if parent.button1:IsEnabled() then
            parent.button1:Click();
        else
            local _, errorText = ABGP:DistribValidateRecipient(parent.editBox:GetText(), data.gp, data.value);
            ABGP:Error("Invalid recipient! %s.", errorText);
        end
    end,
    EditBoxOnEscapePressed = function(self)
		self:ClearFocus();
    end,
    OnHide = function(self, data)
        self.editBox:SetAutoFocus(true);
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    exclusive = true,
};

StaticPopupDialogs["ABGP_CONFIRM_UNAWARD"] = {
    text = "Remove award of %s to %s?",
    button1 = "Yes",
    button2 = "No",
    OnAccept = function(self, data)
        ABGP:HistoryDelete(data);
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    exclusive = true,
};

StaticPopupDialogs["ABGP_UPDATE_GP"] = {
    text = "Update the cost of %s:",
    button1 = "Done",
    button2 = "Cancel",
	hasEditBox = 1,
	maxLetters = 31,
    OnAccept = function(self, widget)
        local cost = ABGP:DistribValidateCost(self.editBox:GetText());
        if cost then
            widget.data[2] = cost;
            widget:SetData(widget.data);

            ABGP:Notify("Cost of %s is now %d.", widget.data[3], cost);
            ABGP:CommitItemData();
            ABGP:RefreshItemValues();
        end
    end,
    OnShow = function(self)
        self.editBox:SetAutoFocus(false);
        self.button1:Disable();
    end,
    EditBoxOnTextChanged = function(self)
        local parent = self:GetParent();
        local cost = ABGP:DistribValidateCost(parent.editBox:GetText());
        if cost then
            parent.button1:Enable();
        else
            parent.button1:Disable();
        end
    end,
    EditBoxOnEnterPressed = function(self)
        local parent = self:GetParent();
        if parent.button1:IsEnabled() then
            parent.button1:Click();
        else
            local _, errorText = ABGP:DistribValidateCost(parent.editBox:GetText());
            ABGP:Error("Invalid cost! %s.", errorText);
        end
    end,
    EditBoxOnEscapePressed = function(self)
		self:ClearFocus();
    end,
    OnHide = function(self, data)
        self.editBox:SetAutoFocus(true);
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    exclusive = true,
};

StaticPopupDialogs["ABGP_UPDATE_NOTES"] = {
    text = "Update the notes for %s:",
    button1 = "Done",
    button2 = "Cancel",
	hasEditBox = 1,
	maxLetters = 31,
    OnAccept = function(self, widget)
        local text = self.editBox:GetText();
        if text == "" then
            ABGP:Notify("Cleared note for %s.", widget.data[3]);
            text = nil;
        else
            ABGP:Notify("Notes for %s is now '%s'.", widget.data[3], text);
        end
        widget.data[5] = text
        widget:SetData(widget.data);

        ABGP:CommitItemData();
        ABGP:RefreshItemValues();
    end,
    OnShow = function(self)
        self.editBox:SetAutoFocus(false);
    end,
    EditBoxOnEnterPressed = function(self)
        self:GetParent().button1:Click();
    end,
    EditBoxOnEscapePressed = function(self)
		self:ClearFocus();
    end,
    OnHide = function(self)
        self.editBox:SetAutoFocus(true);
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    exclusive = true,
};
