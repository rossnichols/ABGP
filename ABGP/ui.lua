local _G = _G;
local ABGP = _G.ABGP;
local AceGUI = _G.LibStub("AceGUI-3.0");

local UnitName = UnitName;
local UnitExists = UnitExists;
local IsInGroup = IsInGroup;
local GetItemInfo = GetItemInfo;
local date = date;
local table = table;
local ipairs = ipairs;
local pairs = pairs;
local unpack = unpack;
local floor = floor;
local select = select;

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
    ShowItem = "ShowItem",
};

local function PopulateUI(options)
    if not activeWindow then return; end
    local container = activeWindow:GetUserData("container");
    if options.rebuild then
        container:ReleaseChildren();
        container:SetLayout("Flow");
    end

    local drawFunc = activeWindow:GetUserData("drawFunc");
    drawFunc(container, options);
    ABGP:HideContextMenu();
end

local function DrawPriority(container, options)
    local rebuild = options.rebuild;
    local reason = options.reason;
    local preserveScroll = options.preserveScroll;
    -- local command = options.command;
    if not rebuild and reason and reason ~= ABGP.RefreshReasons.ACTIVE_PLAYERS_REFRESHED then return; end

    local widths = { 35, 120, 110, 75, 75, 75, 75, 75 };
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
            PopulateUI({ rebuild = false });
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
                PopulateUI({ rebuild = false });
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

        local columns = {
            { canSort = false, name = "" },
            { canSort = true, defaultAsc = true, name = "Player" },
            { canSort = true, defaultAsc = true, name = "Rank" },
            { canSort = true, defaultAsc = false, name = "EP" },
            { canSort = true, defaultAsc = false, name = ABGP:FormatCost("GP", ABGP.ItemCategory.SILVER) },
            { canSort = true, defaultAsc = false, name = ABGP:FormatCost("Prio", ABGP.ItemCategory.SILVER) },
            { canSort = true, defaultAsc = false, name = ABGP:FormatCost("GP", ABGP.ItemCategory.GOLD) },
            { canSort = true, defaultAsc = false, name = ABGP:FormatCost("Prio", ABGP.ItemCategory.GOLD) },
            weights = { unpack(widths) } };
        local header = AceGUI:Create("SimpleGroup");
        header:SetFullWidth(true);
        header:SetLayout("Table");
        header:SetUserData("table", { columns = columns.weights });
        scrollContainer:AddChild(header);

        for i = 1, #columns do
            local desc = AceGUI:Create("ABGP_Header");
            desc:SetFullWidth(true);
            desc:SetFont(_G.GameFontHighlightSmall);
            desc:SetText(columns[i].name);
            if columns[i].canSort then
                desc:EnableHighlight(true);
                desc:SetCallback("OnClick", function()
                    local current = container:GetUserData("sortCol");
                    if current == i then
                        container:SetUserData("sortAsc", not container:GetUserData("sortAsc"));
                    else
                        container:SetUserData("sortAsc", columns[i].defaultAsc);
                    end
                    container:SetUserData("sortCol", i);
                    PopulateUI({ rebuild = false });
                end);
            end
            header:AddChild(desc);
        end

        local scroll = AceGUI:Create("ScrollFrame");
        scroll:SetFullWidth(true);
        scroll:SetFullHeight(true);
        scroll:SetLayout("List");
        scroll:SetUserData("statusTable", {});
        scroll:SetStatusTable(scroll:GetUserData("statusTable"));
        scrollContainer:AddChild(scroll);
        container:SetUserData("priorities", scroll);

        container:SetUserData("sortCol", 8);
        container:SetUserData("sortAsc", false);
    end

    local priorities = container:GetUserData("priorities");
    local scrollValue = preserveScroll and priorities:GetUserData("statusTable").scrollvalue or 0;
    priorities:ReleaseChildren();

    local priority = ABGP.Priorities;
    local filtered = {};
    for i, data in ipairs(priority) do
        local inRaidGroup = not currentRaidGroup or data.raidGroup == currentRaidGroup;
        local isGrouped = not onlyGrouped or UnitExists(data.player);
        if allowedClasses[data.class] and inRaidGroup and isGrouped then
            table.insert(filtered, data);
        end
    end

    local sorts = {
        nil,
        function(a, b) return a.player < b.player, a.player == b.player; end,
        function(a, b) return a.rank < b.rank, a.rank == b.rank; end,
        function(a, b) return a.ep < b.ep, a.ep == b.ep; end,
        function(a, b) return a.gp[ABGP.ItemCategory.SILVER] < b.gp[ABGP.ItemCategory.SILVER], a.gp[ABGP.ItemCategory.SILVER] == b.gp[ABGP.ItemCategory.SILVER]; end,
        function(a, b) return a.priority[ABGP.ItemCategory.SILVER] < b.priority[ABGP.ItemCategory.SILVER], a.priority[ABGP.ItemCategory.SILVER] == b.priority[ABGP.ItemCategory.SILVER]; end,
        function(a, b) return a.gp[ABGP.ItemCategory.GOLD] < b.gp[ABGP.ItemCategory.GOLD], a.gp[ABGP.ItemCategory.GOLD] == b.gp[ABGP.ItemCategory.GOLD]; end,
        function(a, b) return a.priority[ABGP.ItemCategory.GOLD] < b.priority[ABGP.ItemCategory.GOLD], a.priority[ABGP.ItemCategory.GOLD] == b.priority[ABGP.ItemCategory.GOLD]; end,
    };

    local sortCol = container:GetUserData("sortCol");
    local sortAsc = container:GetUserData("sortAsc");
    table.sort(filtered, function(a, b)
        local lt, eq = sorts[sortCol](a, b);
        if eq then
            return sorts[2](a, b);
        elseif sortAsc then
            return lt;
        else
            return not lt;
        end
    end);

    local order = 1;
    for i, data in ipairs(filtered) do
        local elt = AceGUI:Create("ABGP_Priority");
        elt:SetFullWidth(true);
        local important = (data.player == UnitName("player"));
        if i > 1 and not select(2, sorts[sortCol](data, filtered[i - 1])) then
            order = i;
        end
        local lowPrio = data.ep and data.ep < ABGP:GetMinEP(data.raidGroup);
        elt:SetData(data, order, important, lowPrio);
        elt:SetWidths(widths);
        elt:ShowBackground((i % 2) == 0);
        elt:SetCallback("OnClick", function(widget, event, button)
            if button == "RightButton" then
                ABGP:ShowContextMenu({
                    {
                        text = "Show player history",
                        func = function(self, data)
                            if activeWindow then
                                local container = activeWindow:GetUserData("container");
                                container:SelectTab("gp");
                                container:GetUserData("search"):SetValue(("\"%s\""):format(data.player));
                                PopulateUI({ rebuild = false });
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

    priorities:SetScroll(scrollValue);
end

local function DrawItemHistory(container, options)
    local rebuild = options.rebuild;
    local reason = options.reason;
    local preserveScroll = options.preserveScroll;
    local command = options.command;
    if not rebuild and reason and reason ~= ABGP.RefreshReasons.HISTORY_UPDATED then return; end

    local widths = { 120, 70, 50, 1.0 };
    if rebuild then
        container:SetLayout("ABGP_Table");
        container:SetUserData("table", { columns = { 1.0 }, rows = { 0, 1.0, 0 } });

        local mainLine = AceGUI:Create("SimpleGroup");
        mainLine:SetFullWidth(true);
        mainLine:SetLayout("table");
        mainLine:SetUserData("table", { columns = { 0, 0, 1.0, 0 } });
        container:AddChild(mainLine);

        local search = AceGUI:Create("ABGP_EditBox");
        search:SetWidth(125);
        search:SetCallback("OnValueChanged", function(widget)
            PopulateUI({ rebuild = false });
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

                    local itemId = data[ABGP.ItemHistoryIndex.ITEMID];
                    local value = ABGP:GetItemValue(itemId);
                    local itemDate = date("%m/%d/%y", data[ABGP.ItemHistoryIndex.DATE]);

                    text = text .. ("%s\t%s\t%s\t%s%s"):format(
                        data[ABGP.ItemHistoryIndex.GP], value.item, data[ABGP.ItemHistoryIndex.PLAYER], itemDate, (i == 1 and "" or "\n"));
                end

                local window = AceGUI:Create("ABGP_OpaqueWindow");
                window.frame:SetFrameStrata("DIALOG");
                window:SetTitle("Export");
                window:SetLayout("Fill");
                window:SetCallback("OnClose", function(widget) AceGUI:Release(widget); ABGP:ClosePopup(widget); end);
                ABGP:OpenPopup(window);

                local edit = AceGUI:Create("MultiLineEditBox");
                edit:SetLabel("Paste the following into the spreadsheet.");
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

        local scrollContainer = AceGUI:Create("SimpleGroup");
        scrollContainer:SetUserData("cell", { align = "fill", paddingBottom = 5 });
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
            desc:SetFullWidth(true);
            desc:SetFont(_G.GameFontHighlightSmall);
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
        scroll:SetUserData("statusTable", {});
        scroll:SetStatusTable(scroll:GetUserData("statusTable"));
        scrollContainer:AddChild(scroll);
        container:SetUserData("itemHistory", scroll);

        local pagination = AceGUI:Create("ABGP_Paginator");
        pagination:SetFullWidth(true);
        pagination:SetCallback("OnRangeSet", function()
            PopulateUI({ rebuild = false });
        end);
        container:AddChild(pagination);
        container:SetUserData("pagination", pagination);
    end

    if command then
        if command.command == ABGP.UICommands.ShowItemHistory then
            container:GetUserData("search"):SetValue(("\"%s\""):format(command.args));
        end
    end

    local history = container:GetUserData("itemHistory");
    local scrollValue = preserveScroll and history:GetUserData("statusTable").scrollvalue or 0;
    history:ReleaseChildren();

    local pagination = container:GetUserData("pagination");
    local search = container:GetUserData("search");
    local searchText = search:GetText():lower();
    local gpHistory = ABGP:ProcessItemHistory(_G.ABGP_Data2[ABGP.CurrentPhase].gpHistory);
    local filtered = {};
    local exact = searchText:match("^\"(.+)\"$");
    exact = exact and exact:lower() or exact;
    for _, data in ipairs(gpHistory) do
        local value = ABGP:GetItemValue(data[ABGP.ItemHistoryIndex.ITEMID]);
        local epgp = ABGP:GetActivePlayer(data[ABGP.ItemHistoryIndex.PLAYER]);
        if value and ((epgp and epgp[ABGP.CurrentPhase]) or not currentRaidGroup) then
            if not currentRaidGroup or epgp.raidGroup == currentRaidGroup then
                local class = epgp and epgp.class:lower() or "";
                local entryDate = date("%m/%d/%y", data[ABGP.ItemHistoryIndex.DATE]):lower(); -- https://strftime.org/
                if exact then
                    if data[ABGP.ItemHistoryIndex.PLAYER]:lower() == exact or
                        value.item:lower() == exact or
                        class == exact or
                        entryDate == exact then
                        table.insert(filtered, data);
                    end
                else
                    if data[ABGP.ItemHistoryIndex.PLAYER]:lower():find(searchText, 1, true) or
                        value.item:lower():find(searchText, 1, true) or
                        class:find(searchText, 1, true) or
                        entryDate:find(searchText, 1, true) then
                        table.insert(filtered, data);
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
                local value = ABGP:GetItemValue(data[ABGP.ItemHistoryIndex.ITEMID]);
                if button == "RightButton" then
                    local context = {
                        {
                            text = "Show player history",
                            func = function(self, arg1)
                                if activeWindow then
                                    search:SetValue(("\"%s\""):format(arg1[ABGP.ItemHistoryIndex.PLAYER]));
                                    PopulateUI({ rebuild = false });
                                end
                            end,
                            arg1 = data,
                            notCheckable = true
                        },
                        {
                            text = "Show item history",
                            func = function(self, arg1)
                                if activeWindow then
                                    search:SetValue(("\"%s\""):format(value.item));
                                    PopulateUI({ rebuild = false });
                                end
                            end,
                            arg1 = data,
                            notCheckable = true
                        },
                    };
                    if ABGP:CanFavoriteItems() then
                        local faved = ABGP:IsItemFavorited(value.itemLink);
                        table.insert(context, 1, {
                            text = faved and "Remove item favorite" or "Add item favorite",
                            func = function(self, arg1)
                                ABGP:SetItemFavorited(value.itemLink, not faved);
                            end,
                            arg1 = data,
                            notCheckable = true
                        });
                    end
                    if data[ABGP.ItemHistoryIndex.ID] and ABGP:IsPrivileged() then
                        table.insert(context, {
                            text = "Edit cost",
                            func = function(self, arg1)
                                _G.StaticPopup_Show("ABGP_UPDATE_COST", value.itemLink, ABGP:ColorizeName(arg1[ABGP.ItemHistoryIndex.PLAYER]), {
                                    value = value,
                                    historyId = arg1[ABGP.ItemHistoryIndex.ID],
                                    itemLink = value.itemLink,
                                    player = arg1[ABGP.ItemHistoryIndex.PLAYER],
                                    gp = arg1[ABGP.ItemHistoryIndex.GP],
                                    awarded = arg1[ABGP.ItemHistoryIndex.DATE],
                                });
                            end,
                            arg1 = data,
                            notCheckable = true
                        });
                        table.insert(context, {
                            text = "Edit player",
                            func = function(self, arg1)
                                _G.StaticPopup_Show("ABGP_UPDATE_PLAYER", value.itemLink, arg1[ABGP.ItemHistoryIndex.GP], {
                                    value = value,
                                    historyId = arg1[ABGP.ItemHistoryIndex.ID],
                                    itemLink = value.itemLink,
                                    player = arg1[ABGP.ItemHistoryIndex.PLAYER],
                                    gp = arg1[ABGP.ItemHistoryIndex.GP],
                                    awarded = arg1[ABGP.ItemHistoryIndex.DATE],
                                });
                            end,
                            arg1 = data,
                            notCheckable = true
                        });
                        table.insert(context, {
                            text = "Delete entry",
                            func = function(self, arg1)
                                local award = ("%s for %d GP"):format(ABGP:ColorizeName(arg1[ABGP.ItemHistoryIndex.PLAYER]), arg1[ABGP.ItemHistoryIndex.GP]);
                                _G.StaticPopup_Show("ABGP_CONFIRM_UNAWARD", value.itemLink, award, {
                                    value = value,
                                    historyId = arg1[ABGP.ItemHistoryIndex.ID],
                                    itemLink = value.itemLink,
                                    player = arg1[ABGP.ItemHistoryIndex.PLAYER],
                                    gp = arg1[ABGP.ItemHistoryIndex.GP],
                                });
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

    history:SetScroll(scrollValue);
end

local function DrawItems(container, options)
    local rebuild = options.rebuild;
    local reason = options.reason;
    local preserveScroll = options.preserveScroll;
    local command = options.command;
    if not rebuild and reason then return; end

    local widths = { 225, 50, 50, 1.0 };
    if rebuild then
        container:SetLayout("ABGP_Table");
        container:SetUserData("table", { columns = { 1.0 }, rows = { 0, 1.0, 0 } });

        local mainLine = AceGUI:Create("SimpleGroup");
        mainLine:SetFullWidth(true);
        mainLine:SetLayout("table");
        mainLine:SetUserData("table", { columns = { 0, 0, 0, 0, 0, 1.0, 0 } });
        container:AddChild(mainLine);

        local priSelector = AceGUI:Create("ABGP_Filter");
        priSelector:SetWidth(125);
        priSelector:SetValues(allowedPriorities, true, ABGP:GetItemPriorities());
        priSelector:SetCallback("OnFilterUpdated", function()
            PopulateUI({ rebuild = false });
        end);
        priSelector:SetText("Priorities");
        mainLine:AddChild(priSelector);
        container:SetUserData("priSelector", priSelector);

        local search = AceGUI:Create("ABGP_EditBox");
        search:SetWidth(120);
        search:SetCallback("OnValueChanged", function(widget)
            PopulateUI({ rebuild = false });
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
            PopulateUI({ rebuild = false });
        end);
        mainLine:AddChild(usable);

        if ABGP:CanFavoriteItems() then
            local faved = AceGUI:Create("CheckBox");
            faved:SetWidth(80);
            faved:SetLabel("Faved");
            faved:SetValue(onlyFaved);
            faved:SetCallback("OnValueChanged", function(widget, event, value)
                onlyFaved = value;
                PopulateUI({ rebuild = false });
            end);
            mainLine:AddChild(faved);
        else
            local spacer = AceGUI:Create("Label");
            spacer:SetWidth(80);
            mainLine:AddChild(spacer);
        end

        if ABGP:IsPrivileged() then
            local spacer = AceGUI:Create("Label");
            mainLine:AddChild(spacer);

            local export = AceGUI:Create("Button");
            export:SetWidth(100);
            export:SetText("Export");
            export:SetCallback("OnClick", function(widget, event)
                local _, sortedPriorities = ABGP:GetItemPriorities();
                local function buildPrioString(prio)
                    local itemPriorities = {};
                    for _, pri in ipairs(prio) do itemPriorities[pri] = true; end
                    local priorities = {};
                    for _, pri in ipairs(sortedPriorities) do
                        table.insert(priorities, itemPriorities[pri] and "TRUE" or "");
                    end
                    return table.concat(priorities, "\t");
                end

                local tokens = {};
                local items = _G.ABGP_Data2[ABGP.CurrentPhase].itemValues;
                local text = ("Boss\tItem\tCategory\tGP\t%s\tNotes\n"):format(table.concat(sortedPriorities, "\t"));
                for i, item in ipairs(items) do
                    if item[ABGP.ItemDataIndex.GP] == -1 then
                        tokens[item[ABGP.ItemDataIndex.NAME]] = item;
                    elseif item[ABGP.ItemDataIndex.RELATED] then
                        local token = tokens[item[ABGP.ItemDataIndex.RELATED]];
                        text = text .. ("%s\t%s\t%s\t%s\t%s\t%s\n"):format(
                            token[ABGP.ItemDataIndex.BOSS] or "",
                            ("%s (%s)"):format(item[ABGP.ItemDataIndex.RELATED], item[ABGP.ItemDataIndex.NAME]),
                            item[ABGP.ItemDataIndex.CATEGORY],
                            item[ABGP.ItemDataIndex.GP],
                            buildPrioString(token[ABGP.ItemDataIndex.PRIORITY]),
                            token[ABGP.ItemDataIndex.NOTES] or "",
                            "\n");
                    else
                        text = text .. ("%s\t%s\t%s\t%s\t%s\t%s\n"):format(
                            item[ABGP.ItemDataIndex.BOSS] or "",
                            item[ABGP.ItemDataIndex.NAME],
                            item[ABGP.ItemDataIndex.CATEGORY],
                            item[ABGP.ItemDataIndex.GP],
                            buildPrioString(item[ABGP.ItemDataIndex.PRIORITY]),
                            item[ABGP.ItemDataIndex.NOTES] or "",
                            "\n");
                    end
                end

                local window = AceGUI:Create("ABGP_OpaqueWindow");
                window.frame:SetFrameStrata("DIALOG");
                window:SetTitle("Export");
                window:SetLayout("Fill");
                window:SetCallback("OnClose", function(widget) AceGUI:Release(widget); ABGP:ClosePopup(widget); end);
                ABGP:OpenPopup(window);

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

        local scrollContainer = AceGUI:Create("SimpleGroup");
        scrollContainer:SetUserData("cell", { align = "fill", paddingBottom = 5 });
        scrollContainer:SetFullWidth(true);
        scrollContainer:SetFullHeight(true);
        scrollContainer:SetLayout("Flow");
        container:AddChild(scrollContainer);

        local columns = {
            { canSort = true, defaultAsc = true, name = "Item" },
            { canSort = true, defaultAsc = false, name = "GP" },
            { canSort = false, name = "Notes" },
            { canSort = false, name = "Priority" },
            weights = { unpack(widths) } };
        local header = AceGUI:Create("SimpleGroup");
        header:SetFullWidth(true);
        header:SetLayout("Table");
        header:SetUserData("table", { columns = columns.weights });
        scrollContainer:AddChild(header);

        for i = 1, #columns do
            local desc = AceGUI:Create("ABGP_Header");
            desc:SetFullWidth(true);
            desc:SetFont(_G.GameFontHighlightSmall);
            desc:SetText(columns[i].name);
            if columns[i].name == "GP" then
                desc:SetJustifyH("RIGHT");
                desc:SetPadding(2, -10);
            end
            if columns[i].canSort then
                desc:EnableHighlight(true);
                desc:SetCallback("OnClick", function()
                    local current = container:GetUserData("sortCol");
                    if current == i then
                        container:SetUserData("sortAsc", not container:GetUserData("sortAsc"));
                    else
                        container:SetUserData("sortAsc", columns[i].defaultAsc);
                    end
                    container:SetUserData("sortCol", i);
                    PopulateUI({ rebuild = false });
                end);
            end
            header:AddChild(desc);
        end

        local scroll = AceGUI:Create("ScrollFrame");
        scroll:SetFullWidth(true);
        scroll:SetFullHeight(true);
        scroll:SetLayout("List");
        scroll:SetUserData("statusTable", {});
        scroll:SetStatusTable(scroll:GetUserData("statusTable"));
        scrollContainer:AddChild(scroll);
        container:SetUserData("itemList", scroll);

        local pagination = AceGUI:Create("ABGP_Paginator");
        pagination:SetFullWidth(true);
        pagination:SetCallback("OnRangeSet", function()
            PopulateUI({ rebuild = false });
        end);
        container:AddChild(pagination);
        container:SetUserData("pagination", pagination);

        container:SetUserData("sortCol", 1);
        container:SetUserData("sortAsc", true);
    end

    if command then
        if command.command == ABGP.UICommands.ShowItem then
            container:GetUserData("search"):SetValue(("\"%s\""):format(command.args));
        end
    end

    local itemList = container:GetUserData("itemList");
    local scrollValue = preserveScroll and itemList:GetUserData("statusTable").scrollvalue or 0;
    itemList:ReleaseChildren();

    local items = _G.ABGP_Data2[ABGP.CurrentPhase].itemValues;
    local filtered = {};
    local selector = container:GetUserData("priSelector");
    local search = container:GetUserData("search");
    local searchText = search:GetText():lower();

    if selector:ShowingAll() and not onlyUsable and not onlyFaved and searchText == "" then
        for i, item in ipairs(items) do
            if not item[ABGP.ItemDataIndex.RELATED] then
                table.insert(filtered, item);
            end
        end
    else
        local exact = searchText:match("^\"(.+)\"$");
        exact = exact and exact:lower() or exact;
        for i, item in ipairs(items) do
            if not item[ABGP.ItemDataIndex.RELATED] then
                if not onlyUsable or ABGP:IsItemUsable(item[ABGP.ItemDataIndex.ITEMLINK]) then
                    if not onlyFaved or ABGP:IsItemFavorited(item[ABGP.ItemDataIndex.ITEMLINK]) then
                        local matchesSearch = false;
                        if exact then
                            if item[ABGP.ItemDataIndex.NAME]:lower() == exact or
                                item[ABGP.ItemDataIndex.BOSS]:lower() == exact or
                                (item[ABGP.ItemDataIndex.NOTES] or ""):lower() == exact then
                                matchesSearch = true;
                            end
                        else
                            if item[ABGP.ItemDataIndex.NAME]:lower():find(searchText, 1, true) or
                                item[ABGP.ItemDataIndex.BOSS]:lower():find(searchText, 1, true) or
                                (item[ABGP.ItemDataIndex.NOTES] or ""):lower():find(searchText, 1, true) then
                                matchesSearch = true;
                            end
                        end

                        if matchesSearch then
                            if #item[ABGP.ItemDataIndex.PRIORITY] > 0 then
                                for _, pri in ipairs(item[ABGP.ItemDataIndex.PRIORITY]) do
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
    end

    table.sort(filtered, function(a, b)
        return a[ABGP.ItemDataIndex.NAME] < b[ABGP.ItemDataIndex.NAME];
    end);

    local sorts = {
        function(a, b) return a[ABGP.ItemDataIndex.NAME] < b[ABGP.ItemDataIndex.NAME], a[ABGP.ItemDataIndex.NAME] == b[ABGP.ItemDataIndex.NAME]; end,
        function(a, b)
            local acat, bcat = a[ABGP.ItemDataIndex.CATEGORY], b[ABGP.ItemDataIndex.CATEGORY];
            local acost, bcost = a[ABGP.ItemDataIndex.GP], b[ABGP.ItemDataIndex.GP];
            if acat == bcat then
                return acost < bcost, acost == bcost;
            else
                return acat == ABGP.ItemCategory.SILVER, false;
            end
        end,
    };

    local sortCol = container:GetUserData("sortCol");
    local sortAsc = container:GetUserData("sortAsc");
    table.sort(filtered, function(a, b)
        local lt, eq = sorts[sortCol](a, b);
        if eq then
            return sorts[1](a, b);
        elseif sortAsc then
            return lt;
        else
            return not lt;
        end
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
            elt:SetRelatedItems(ABGP:GetTokenItems(data[ABGP.ItemDataIndex.ITEMLINK]));
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
                                    container:GetUserData("search"):SetValue(("\"%s\""):format(data[ABGP.ItemDataIndex.NAME]));
                                    PopulateUI({ rebuild = false });
                                end
                            end,
                            arg1 = data,
                            notCheckable = true
                        },
                    };
                    if data[ABGP.ItemDataIndex.ITEMLINK] and ABGP:CanFavoriteItems() then
                        local faved = ABGP:IsItemFavorited(data[ABGP.ItemDataIndex.ITEMLINK]);
                        table.insert(context, 1, {
                            text = faved and "Remove favorite" or "Add favorite",
                            func = function(self, data)
                                ABGP:SetItemFavorited(data[ABGP.ItemDataIndex.ITEMLINK], not faved);
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
                                _G.StaticPopup_Show("ABGP_UPDATE_GP", widget.data[ABGP.ItemDataIndex.ITEMLINK], nil, widget);
                            end,
                            arg1 = widget,
                            notCheckable = true
                        });
                        table.insert(context, {
                            text = "Edit notes",
                            func = function(self, widget)
                                _G.StaticPopup_Show("ABGP_UPDATE_NOTES", widget.data[ABGP.ItemDataIndex.ITEMLINK], nil, widget);
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
                local pri = widget.data[ABGP.ItemDataIndex.PRIORITY];
                if #pri > 0 then
                    ABGP:Notify("Priorities for %s: %s.", widget.data[ABGP.ItemDataIndex.ITEMLINK], table.concat(pri, ", "));
                else
                    ABGP:Notify("Priorities for %s have been cleared.", widget.data[ABGP.ItemDataIndex.ITEMLINK]);
                end
                if ABGP.Phases[ABGP.CurrentPhase] then
                    ABGP:CommitItemData();
                end
            end);
            itemList:AddChild(elt);
        end
    end

    itemList:SetScroll(scrollValue);
end

local function DrawRaidHistory(container, options)
    local rebuild = options.rebuild;
    local reason = options.reason;
    local preserveScroll = options.preserveScroll;
    -- local command = options.command;
    if not rebuild and reason then return; end

    local widths = { 1.0 };
    if rebuild then
        local pagination = AceGUI:Create("ABGP_Paginator");
        pagination:SetFullWidth(true);
        pagination:SetCallback("OnRangeSet", function()
            PopulateUI({ rebuild = false });
        end);
        container:AddChild(pagination);
        container:SetUserData("pagination", pagination);

        local scrollContainer = AceGUI:Create("SimpleGroup");
        scrollContainer:SetFullWidth(true);
        scrollContainer:SetFullHeight(true);
        scrollContainer:SetLayout("Flow");
        container:AddChild(scrollContainer);

        local columns = { "Name", weights = { unpack(widths) } };
        local header = AceGUI:Create("SimpleGroup");
        header:SetFullWidth(true);
        header:SetLayout("Table");
        header:SetUserData("table", { columns = columns.weights });
        scrollContainer:AddChild(header);

        for i = 1, #columns do
            local desc = AceGUI:Create("ABGP_Header");
            desc:SetFullWidth(true);
            desc:SetFont(_G.GameFontHighlightSmall);
            desc:SetText(columns[i]);
            header:AddChild(desc);
        end

        local scroll = AceGUI:Create("ScrollFrame");
        scroll:SetFullWidth(true);
        scroll:SetFullHeight(true);
        scroll:SetLayout("List");
        scroll:SetUserData("statusTable", {});
        scroll:SetStatusTable(scroll:GetUserData("statusTable"));
        scrollContainer:AddChild(scroll);
        container:SetUserData("raidList", scroll);
    end

    local raidList = container:GetUserData("raidList");
    local scrollValue = preserveScroll and raidList:GetUserData("statusTable").scrollvalue or 0;
    raidList:ReleaseChildren();

    local raids = _G.ABGP_RaidInfo.pastRaids;
    local filtered = {};
    for _, raid in ipairs(raids) do
        if raid.phase == ABGP.CurrentPhase then
            table.insert(filtered, raid);
        end
    end

    local pagination = container:GetUserData("pagination");
    pagination:SetValues(#filtered, 100);
    if #filtered > 0 then
        local first, last = pagination:GetRange();
        for i = first, last do
            local raid = filtered[i];
            local elt = AceGUI:Create("ABGP_Header");
            elt:SetFullWidth(true);
            local raidDate = date("%m/%d/%y", raid.startTime); -- https://strftime.org/
            elt:SetText(("%s (%s)"):format(raid.name, raidDate));
            elt:EnableHighlight(true);
            elt:SetCallback("OnClick", function(widget, event, button)
                if button == "RightButton" then
                    ABGP:ShowContextMenu({
                        {
                            text = "Export",
                            func = function(self, raid)
                                ABGP:ExportRaid(raid);
                            end,
                            arg1 = raid,
                            notCheckable = true
                        },
                        {
                            text = "Manage",
                            func = function(self, raid)
                                ABGP:UpdateRaid(raid);
                            end,
                            arg1 = raid,
                            notCheckable = true
                        },
                        { text = "Cancel", notCheckable = true },
                    });
                end
            end);
            raidList:AddChild(elt);
        end
    end

    raidList:SetScroll(scrollValue);
end

local function DrawAuditLog(container, options)
    local rebuild = options.rebuild;
    local reason = options.reason;
    local preserveScroll = options.preserveScroll;
    -- local command = options.command;
    if not rebuild and reason and reason ~= ABGP.RefreshReasons.HISTORY_UPDATED then return; end

    local widths = { 120, 80, 50, 70, 1.0 };
    if rebuild then
        container:SetLayout("ABGP_Table");
        container:SetUserData("table", { columns = { 1.0 }, rows = { 1.0, 0 } });

        local scrollContainer = AceGUI:Create("SimpleGroup");
        scrollContainer:SetUserData("cell", { align = "fill", paddingBottom = 5 });
        scrollContainer:SetFullWidth(true);
        scrollContainer:SetFullHeight(true);
        scrollContainer:SetLayout("Flow");
        container:AddChild(scrollContainer);

        local columns = { "Player", "Date", "Type", "Effective", "Info", weights = { unpack(widths) } };
        local header = AceGUI:Create("SimpleGroup");
        header:SetFullWidth(true);
        header:SetLayout("Table");
        header:SetUserData("table", { columns = columns.weights });
        scrollContainer:AddChild(header);

        for i = 1, #columns do
            local desc = AceGUI:Create("ABGP_Header");
            desc:SetFullWidth(true);
            desc:SetFont(_G.GameFontHighlightSmall);
            desc:SetText(columns[i]);
            desc:SetFullWidth(true);
            header:AddChild(desc);
        end

        local scroll = AceGUI:Create("ScrollFrame");
        scroll:SetFullWidth(true);
        scroll:SetFullHeight(true);
        scroll:SetLayout("List");
        scroll:SetUserData("statusTable", {});
        scroll:SetStatusTable(scroll:GetUserData("statusTable"));
        scrollContainer:AddChild(scroll);
        container:SetUserData("auditLog", scroll);

        local pagination = AceGUI:Create("ABGP_Paginator");
        pagination:SetFullWidth(true);
        pagination:SetCallback("OnRangeSet", function()
            PopulateUI({ rebuild = false });
        end);
        container:AddChild(pagination);
        container:SetUserData("pagination", pagination);
    end

    local auditLog = container:GetUserData("auditLog");
    local scrollValue = preserveScroll and auditLog:GetUserData("statusTable").scrollvalue or 0;
    auditLog:ReleaseChildren();

    local entries = _G.ABGP_Data2[ABGP.CurrentPhase].gpHistory;
    local deletedEntries = {};
    local deleteReferences = {};
    for i, entry in ipairs(entries) do
        local entryType = entry[ABGP.ItemHistoryIndex.TYPE];
        local id = entry[ABGP.ItemHistoryIndex.ID];

        if entryType == ABGP.ItemHistoryType.DELETE then
            deleteReferences[entry[ABGP.ItemHistoryIndex.DELETEDID]] = false;
            if not deletedEntries[id] then
                deletedEntries[entry[ABGP.ItemHistoryIndex.DELETEDID]] = entry;
            end
        end

        if deleteReferences[id] ~= nil then
            deleteReferences[id] = entry;
        end
    end
    local typeNames = {
        [ABGP.ItemHistoryType.ITEM] = "Item",
        [ABGP.ItemHistoryType.BONUS] = "Award",
        [ABGP.ItemHistoryType.DECAY] = "Decay",
        [ABGP.ItemHistoryType.DELETE] = "Delete",
        [ABGP.ItemHistoryType.RESET] = "Reset",
    };

    local function getAuditMessage(entry)
        local entryMsg = "UNKNOWN";
        local entryType = entry[ABGP.ItemHistoryIndex.TYPE];

        if entryType == ABGP.ItemHistoryType.DELETE then
            local reference = deleteReferences[entry[ABGP.ItemHistoryIndex.DELETEDID]];
            if reference then
                local _, refDate = ABGP:ParseHistoryId(reference[ABGP.ItemHistoryIndex.ID]);
                entryMsg = ("Deleted an entry of type '%s' from %s"):format(
                    typeNames[reference[ABGP.ItemHistoryIndex.TYPE]], date("%m/%d/%y", refDate));
            else
                entryMsg = "Deleted a nonexistent entry";
            end
        else
            if entryType == ABGP.ItemHistoryType.ITEM then
                local item = entry[ABGP.ItemHistoryIndex.ITEMID];
                local value = ABGP:GetItemValue(item);
                if value then item = value.itemLink; end
                entryMsg = ("%s to %s for %d GP"):format(
                    item, ABGP:ColorizeName(entry[ABGP.ItemHistoryIndex.PLAYER]), entry[ABGP.ItemHistoryIndex.GP]);
            elseif entryType == ABGP.ItemHistoryType.BONUS then
                entryMsg = ("%s awarded %.3f GP"):format(
                    entry[ABGP.ItemHistoryIndex.PLAYER], entry[ABGP.ItemHistoryIndex.GP]);
            elseif entryType == ABGP.ItemHistoryType.DECAY then
                entryMsg = ("GP decayed by %d%%"):format(
                    floor(entry[ABGP.ItemHistoryIndex.VALUE] * 100 + 0.5));
            elseif entryType == ABGP.ItemHistoryType.RESET then
                entryMsg = ("%s reset to %.3f GP"):format(
                    entry[ABGP.ItemHistoryIndex.PLAYER], entry[ABGP.ItemHistoryIndex.GP]);
            end
        end

        return entryMsg;
    end

    local pagination = container:GetUserData("pagination");
    pagination:SetValues(#entries, 50);
    if #entries > 0 then
        local first, last = pagination:GetRange();
        for i = first, last do
            local entry = entries[i];
            local id = entry[ABGP.ItemHistoryIndex.ID];
            local entryPlayer, entryDate = ABGP:ParseHistoryId(id);
            local entryType = entry[ABGP.ItemHistoryIndex.TYPE];

            local actionDate = date("%m/%d/%y", entry[ABGP.ItemHistoryIndex.DATE]);
            local entryMsg = getAuditMessage(entry);

            local deleteRef;
            if entryType == ABGP.ItemHistoryType.DELETE then
                local reference = deleteReferences[entry[ABGP.ItemHistoryIndex.DELETEDID]];
                if reference then
                    deleteRef = getAuditMessage(reference);
                end
            end

            local deleted;
            if deletedEntries[entry[ABGP.ItemHistoryIndex.ID]] then
                local del = deletedEntries[entry[ABGP.ItemHistoryIndex.ID]];
                local delPlayer, delDate = ABGP:ParseHistoryId(del[ABGP.ItemHistoryIndex.ID]);
                deleted = ("Deleted by %s on %s"):format(ABGP:ColorizeName(delPlayer), date("%m/%d/%y", delDate));
            end

            local elt = AceGUI:Create("ABGP_AuditLog");
            elt:SetFullWidth(true);
            elt:SetData({
                entryPlayer = ABGP:ColorizeName(entryPlayer),
                entryDate = date("%m/%d/%y", entryDate),
                type = typeNames[entryType],
                date = actionDate,
                audit = entryMsg,
                deleted = deleted,
                deleteRef = deleteRef,
            });
            elt:SetWidths(widths);
            elt:SetCallback("OnClick", function(widget, event, button)
                if not ABGP:GetDebugOpt("HistoryUI") then return; end
                if button == "RightButton" then
                    local context = {};

                    if deleted then
                        table.insert(context, {
                            text = "Undelete entry [NYI]",
                            func = function(self, arg1)

                            end,
                            arg1 = entry,
                            notCheckable = true
                        });
                    else
                        if entryType == ABGP.ItemHistoryType.ITEM then
                            local value = ABGP:GetItemValue(entry[ABGP.ItemHistoryIndex.ITEMID]);
                            if value then
                                table.insert(context, {
                                    text = "Edit cost",
                                    func = function(self, arg1)
                                        _G.StaticPopup_Show("ABGP_UPDATE_COST", value.itemLink, ABGP:ColorizeName(arg1[ABGP.ItemHistoryIndex.PLAYER]), {
                                            value = value,
                                            historyId = arg1[ABGP.ItemHistoryIndex.ID],
                                            itemLink = value.itemLink,
                                            player = arg1[ABGP.ItemHistoryIndex.PLAYER],
                                            gp = arg1[ABGP.ItemHistoryIndex.GP],
                                            awarded = arg1[ABGP.ItemHistoryIndex.DATE],
                                        });
                                    end,
                                    arg1 = entry,
                                    notCheckable = true
                                });
                                table.insert(context, {
                                    text = "Edit player",
                                    func = function(self, arg1)
                                        _G.StaticPopup_Show("ABGP_UPDATE_PLAYER", value.itemLink, arg1[ABGP.ItemHistoryIndex.GP], {
                                            value = value,
                                            historyId = arg1[ABGP.ItemHistoryIndex.ID],
                                            itemLink = value.itemLink,
                                            player = arg1[ABGP.ItemHistoryIndex.PLAYER],
                                            gp = arg1[ABGP.ItemHistoryIndex.GP],
                                            awarded = arg1[ABGP.ItemHistoryIndex.DATE],
                                        });
                                    end,
                                    arg1 = entry,
                                    notCheckable = true
                                });
                                if ABGP:GetDebugOpt() then
                                    table.insert(context, {
                                        text = "Effective cost",
                                        func = function(self, arg1)
                                            local cost, decayCount = ABGP:GetEffectiveCost(entry[ABGP.ItemHistoryIndex.ID], entry[ABGP.ItemHistoryIndex.GP], ABGP.CurrentPhase);
                                            if cost then
                                                ABGP:LogDebug("Effective cost is %.3f after %d decays.", cost, decayCount);
                                            else
                                                ABGP:LogDebug("Failed to calculate!");
                                            end
                                        end,
                                        arg1 = entry,
                                        notCheckable = true
                                    });
                                end
                            end
                        elseif  entryType == ABGP.ItemHistoryType.BONUS then
                            table.insert(context, {
                                text = "Edit amount [NYI]",
                                func = function(self, arg1)

                                end,
                                arg1 = entry,
                                notCheckable = true
                            });
                        end

                        table.insert(context, {
                            text = "Delete entry",
                            func = function(self, arg1)
                                ABGP:HistoryDeleteEntry(ABGP.CurrentPhase, arg1);
                            end,
                            arg1 = entry,
                            notCheckable = true
                        });
                    end

                    table.insert(context, { text = "Cancel", notCheckable = true });
                    ABGP:ShowContextMenu(context);
                end
            end);
            auditLog:AddChild(elt);
        end
    end

    auditLog:SetScroll(scrollValue);
end

ABGP.RefreshReasons = {
    ACTIVE_PLAYERS_REFRESHED = "ACTIVE_PLAYERS_REFRESHED",
    HISTORY_UPDATED = "HISTORY_UPDATED",
};
function ABGP:RefreshUI(reason)
    PopulateUI({ rebuild = false, reason = reason, preserveScroll = true });
end

function ABGP:CreateMainWindow(command)
    local window = AceGUI:Create("Window");
    window.frame:SetFrameStrata("MEDIUM");
    window:SetTitle(("%s v%s"):format(self:ColorizeText("ABGP"), self:GetVersion()));
    window:SetLayout("Flow");
    self:BeginWindowManagement(window, "main", {
        version = 2,
        defaultWidth = 700,
        minWidth = 700,
        maxWidth = 850,
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
    mainLine:SetUserData("table", { columns = { 0, 1.0, 0 } });
    window:AddChild(mainLine);

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
        PopulateUI({ rebuild = false });
    end);
    currentRaidGroup = ABGP:GetPreferredRaidGroup();
    groupSelector:SetValue(currentRaidGroup);
    mainLine:AddChild(groupSelector);

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
        { value = "items", text = "Items", draw = DrawItems },
        { value = "gp", text = "Item History", draw = DrawItemHistory },
    };
    if _G.ABGP_RaidInfo.pastRaids and #_G.ABGP_RaidInfo.pastRaids > 0 then
        table.insert(tabs, { value = "ep", text = "Raid History", draw = DrawRaidHistory });
    end
    if self:IsPrivileged() then
        table.insert(tabs, { value = "audit", text = "Audit Log", draw = DrawAuditLog });
    end
    local tabGroup = AceGUI:Create("TabGroup");
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
        PopulateUI({ rebuild = true });
    end);
    window:AddChild(tabGroup);
    window:SetUserData("container", tabGroup);

    local tab = 1;
    if command then
        if command.command == ABGP.UICommands.ShowItemHistory then
            tab = 3;
        elseif command.command == ABGP.UICommands.ShowItem then
            tab = 2;
        end
    end
    tabGroup:SelectTab(tabs[tab].value);

    window.frame:Raise();
    return window;
end

function ABGP:ShowMainWindow(command)
    if activeWindow and not command then
        activeWindow:Hide();
        return;
    end

    if activeWindow then
        activeWindow:Hide();
        activeWindow = nil;
    end

    activeWindow = self:CreateMainWindow(command);
    PopulateUI({ rebuild = true, command = command });
end

StaticPopupDialogs["ABGP_UPDATE_COST"] = ABGP:StaticDialogTemplate(ABGP.StaticDialogTemplates.EDIT_BOX, {
    text = "Update the cost of %s to %s:",
    button1 = "Done",
    button2 = "Cancel",
    maxLetters = 31,
    Validate = function(text, data)
        return ABGP:DistribValidateCost(text, data.player, data.value);
    end,
    Commit = function(cost, data)
        ABGP:HistoryUpdateCost(data, cost);
    end,
});
StaticPopupDialogs["ABGP_UPDATE_PLAYER"] = ABGP:StaticDialogTemplate(ABGP.StaticDialogTemplates.EDIT_BOX, {
    text = "Update the recipient of %s for %d GP:",
    button1 = "Done",
    button2 = "Cancel",
    maxLetters = 31,
    autoCompleteSource = GetAutoCompleteResults,
    autoCompleteArgs = { bit.bor(AUTOCOMPLETE_FLAG_IN_GROUP, AUTOCOMPLETE_FLAG_IN_GUILD), AUTOCOMPLETE_FLAG_NONE },
    Validate = function(text, data)
        return ABGP:DistribValidateRecipient(text, data.gp, data.value);
    end,
    Commit = function(player, data)
        ABGP:HistoryUpdatePlayer(data, player);
    end,
});
StaticPopupDialogs["ABGP_CONFIRM_UNAWARD"] = ABGP:StaticDialogTemplate(ABGP.StaticDialogTemplates.JUST_BUTTONS, {
    text = "Remove award of %s to %s?",
    button1 = "Yes",
    button2 = "No",
    OnAccept = function(self, data)
        ABGP:HistoryDeleteItemAward(data);
    end,
});
StaticPopupDialogs["ABGP_UPDATE_GP"] = ABGP:StaticDialogTemplate(ABGP.StaticDialogTemplates.EDIT_BOX, {
    text = "Update the cost of %s:",
    button1 = "Done",
    button2 = "Cancel",
    maxLetters = 31,
    Validate = function(text, widget)
        return ABGP:DistribValidateCost(text);
    end,
    Commit = function(cost, widget)
        widget.data[ABGP.ItemDataIndex.GP] = cost;
        widget:SetData(widget.data);

        ABGP:Notify("Cost of %s is now %d.", widget.data[ABGP.ItemDataIndex.ITEMLINK], cost);
        if ABGP.Phases[ABGP.CurrentPhase] then
            ABGP:CommitItemData();
        end
    end,
});
StaticPopupDialogs["ABGP_UPDATE_NOTES"] = ABGP:StaticDialogTemplate(ABGP.StaticDialogTemplates.EDIT_BOX, {
    text = "Update the notes for %s:",
    button1 = "Done",
    button2 = "Cancel",
    maxLetters = 100,
    Commit = function(text, widget)
        if text == "" then
            ABGP:Notify("Cleared note for %s.", widget.data[ABGP.ItemDataIndex.ITEMLINK]);
            text = nil;
        else
            ABGP:Notify("Notes for %s is now '%s'.", widget.data[ABGP.ItemDataIndex.ITEMLINK], text);
        end
        widget.data[ABGP.ItemDataIndex.NOTES] = text
        widget:SetData(widget.data);

        if ABGP.Phases[ABGP.CurrentPhase] then
            ABGP:CommitItemData();
        end
    end,
});
