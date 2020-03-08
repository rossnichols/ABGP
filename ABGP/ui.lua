local _G = _G;
local ABGP = ABGP;
local AceGUI = _G.LibStub("AceGUI-3.0");

local IsInGuild = IsInGuild;
local CreateFrame = CreateFrame;
local UnitName = UnitName;
local date = date;
local time = time;
local table = table;
local ipairs = ipairs;
local pairs = pairs;
local unpack = unpack;

local activeWindow;
local filteredClasses = {};
local filteredPriorities = {};
local onlyUsable = false;
local selectedPhase = ABGP.CurrentPhase;

local function PopulateUI(rebuild)
    if not activeWindow then return; end
    local container = activeWindow:GetUserData("container");
    if rebuild then
        container:ReleaseChildren();
    end

    local drawFunc = activeWindow:GetUserData("drawFunc");
    drawFunc(container, rebuild);
end

local function DrawPriority(container, rebuild)
    local widths = { 35, 120, 110, 75, 75, 75 };

    if rebuild then
        local classSelector = AceGUI:Create("ABGP_Filter");
        classSelector:SetWidth(110);
        classSelector:SetValues(filteredClasses, {
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
    local priority = ABGP.Priorities[selectedPhase];
    for i, data in ipairs(priority) do
        if not filteredClasses[data.class] then
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

local function DrawItemHistory(container, rebuild)
    local widths = { 120, 70, 50, 1.0 };
    if rebuild then
        local mainLine = AceGUI:Create("SimpleGroup");
        mainLine:SetFullWidth(true);
        mainLine:SetLayout("table");
        mainLine:SetUserData("table", { columns = { 0, 0, 0, 1.0, 0 } });
        container:AddChild(mainLine);

        local search = AceGUI:Create("EditBox");
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

        local reset = AceGUI:Create("Button");
        reset:SetWidth(70);
        reset:SetText("Reset");
        reset:SetCallback("OnClick", function(widget)
            container:GetUserData("search"):SetText("");
            PopulateUI(false);
        end);
        mainLine:AddChild(reset);
        container:SetUserData("reset", reset);

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

                    text = text .. ("%s;%s;%s%s"):format(
                        item, data.player, data.date, (i == 1 and "" or "\n"));
                end

                local window = AceGUI:Create("Window");
                window:SetTitle("Export");
                window:SetLayout("Fill");
                window:SetCallback("OnClose", function(widget) AceGUI:Release(widget); ABGP:CloseWindow(widget); end);
                ABGP:OpenWindow(window);

                local edit = AceGUI:Create("MultiLineEditBox");
                edit:SetLabel("In the spreadsheet, paste into the 'Item' column, then choose Data > Split Text to Columns and use semicolon as the separator.");
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

    local history = container:GetUserData("itemHistory");
    history:ReleaseChildren();

    local pagination = container:GetUserData("pagination");
    local search = container:GetUserData("search");
    local searchText = search:GetText():lower();
    container:GetUserData("reset"):SetDisabled(searchText == "");
    local gpHistory = _G.ABGP_Data[selectedPhase].gpHistory;
    local filtered;
    if searchText == "" then
        filtered = gpHistory;
    else
        filtered = {};
        local exact = searchText:match("^\"(.+)\"$");
        exact = exact and exact:lower() or exact;
        for _, data in ipairs(gpHistory) do
            local guildInfo = ABGP:GetGuildInfo(data.player);
            local class = guildInfo and guildInfo[11] or "";
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
                            arg1 = elt.data,
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
                            arg1 = elt.data,
                            notCheckable = true
                        },
                        { text = "Cancel", notCheckable = true },
                    };
                    if data.itemLink and ABGP:CanFavoriteItems() then
                        local faved = ABGP:IsItemFavorited(data.itemLink);
                        table.insert(context, 1, {
                            text = faved and "Remove item favorite" or "Add item favorite",
                            func = function(self, data)
                                ABGP:SetFavorited(data.itemLink, not faved);
                            end,
                            arg1 = elt.data,
                            notCheckable = true
                        });
                    end
                    ABGP:ShowContextMenu(context);
                end
            end);
            history:AddChild(elt);
        end
    end
end

local function DrawItems(container, rebuild)
    local widths = { 200, 50, 50, 1.0 };
    if rebuild then
        local priSelector = AceGUI:Create("ABGP_Filter");
        priSelector:SetWidth(125);
        priSelector:SetValues(filteredPriorities, {
            ["Druid (Heal)"] = "Druid (Heal)",
            ["KAT4FITE"] = "KAT4FITE",
            ["Hunter"] = "Hunter",
            ["Mage"] = "Mage",
            ["Paladin (Holy)"] = "Paladin (Holy)",
            ["Paladin (Ret)"] = "Paladin (Ret)",
            ["Priest (Heal)"] = "Priest (Heal)",
            ["Priest (Shadow)"] = "Priest (Shadow)",
            ["Rogue"] = "Rogue",
            ["Slicey Rogue"] = "Slicey Rogue",
            ["Stabby Rogue"] = "Stabby Rogue",
            ["Warlock"] = "Warlock",
            ["Tank"] = "Tank",
            ["Metal Rogue"] = "Metal Rogue",
            ["Progression"] = "Progression",
            ["Garbage"] = "Garbage",
        }, {
            "Druid (Heal)",
            "KAT4FITE",
            "Hunter",
            "Mage",
            "Metal Rogue",
            "Paladin (Holy)",
            "Paladin (Ret)",
            "Priest (Heal)",
            "Priest (Shadow)",
            "Rogue",
            "Slicey Rogue",
            "Stabby Rogue",
            "Tank",
            "Warlock",
            "Progression",
            "Garbage",
        });
        priSelector:SetCallback("OnFilterUpdated", function()
            PopulateUI(false);
        end);
        priSelector:SetText("Priorities");
        container:AddChild(priSelector);
        container:SetUserData("priSelector", priSelector);

        local search = AceGUI:Create("EditBox");
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
            _G.GameTooltip:AddLine("Search by item name. Enclose your search in \"quotes\" for an exact match. All searches are case-insensitive.", 1, 1, 1, true);
            _G.GameTooltip:Show();
        end);
        search:SetCallback("OnLeave", function(widget)
            _G.GameTooltip:Hide();
        end);
        container:AddChild(search);
        container:SetUserData("search", search);

        local desc = AceGUI:Create("Label");
        desc:SetWidth(50);
        desc:SetText(" Search");
        container:AddChild(desc);

        local reset = AceGUI:Create("Button");
        reset:SetWidth(70);
        reset:SetText("Reset");
        reset:SetCallback("OnClick", function(widget)
            container:GetUserData("search"):SetText("");
            PopulateUI(false);
        end);
        container:AddChild(reset);
        container:SetUserData("reset", reset);

        local usable = AceGUI:Create("CheckBox");
        usable:SetWidth(100);
        usable:SetLabel("Only Usable");
        usable:SetValue(onlyUsable);
        usable:SetCallback("OnValueChanged", function(widget, event, value)
            onlyUsable = value;
            PopulateUI(false);
        end);
        container:AddChild(usable);

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
    local items = _G.ABGP_Data[selectedPhase].itemValues;
    local filtered = {};
    local selector = container:GetUserData("priSelector");
    local search = container:GetUserData("search");
    local searchText = search:GetText():lower();
    container:GetUserData("reset"):SetDisabled(searchText == "");


    if selector:ShowingAll() and not onlyUsable and searchText == "" then
        filtered = items;
    else
        local exact = searchText:match("^\"(.+)\"$");
        exact = exact and exact:lower() or exact;
        for i, item in ipairs(items) do
            if not onlyUsable or ABGP:IsItemUsable(item[3]) then
                if (searchText == "") or
                   (exact and item[1]:lower() == exact) or
                   (not exact and item[1]:lower():find(searchText, 1, true)) then
                    for _, pri in ipairs(item.priority) do
                        if not filteredPriorities[pri] then
                            table.insert(filtered, item);
                            break;
                        end
                    end
                end
            end
        end
    end

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
                            arg1 = elt.data,
                            notCheckable = true
                        },
                        { text = "Cancel", notCheckable = true },
                    };
                    if data[3] and ABGP:CanFavoriteItems() then
                        local faved = ABGP:IsItemFavorited(data[3]);
                        table.insert(context, 1, {
                            text = faved and "Remove favorite" or "Add favorite",
                            func = function(self, data)
                                ABGP:SetFavorited(data[3], not faved);
                                elt:SetData(data);
                            end,
                            arg1 = elt.data,
                            notCheckable = true
                        });
                    end
                    ABGP:ShowContextMenu(context);
                end
            end);
            itemList:AddChild(elt);
        end
    end
end

local function DrawAuditLog(container, rebuild)
    local widths = { 70, 60, 1.0 };
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

    local entries = _G.ABGP_ItemAuditLog[selectedPhase];
    local pagination = container:GetUserData("pagination");
    pagination:SetValues(#entries, 100);
    if #entries > 0 then
        local first, last = pagination:GetRange();
        local requestTypes = {
            [ABGP.RequestTypes.MS] = "ms",
            [ABGP.RequestTypes.OS] = "os",
            [ABGP.RequestTypes.ROLL] = "roll",
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
            end
        end
    end
end

function ABGP:RefreshUI()
    PopulateUI(false);
end

function ABGP:CreateMainWindow()
    local window = AceGUI:Create("Window");
    window:SetTitle(self:ColorizeText("ABGP"));
    window:SetLayout("Flow");
    self:BeginWindowManagement(window, "main", {
        version = 1,
        defaultWidth = 600,
        minWidth = 600,
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
    mainLine:SetUserData("table", { columns = { 0, 1.0, 0 } });
    window:AddChild(mainLine);

    local phases = {
        [ABGP.Phases.p1] = "Phase 1/2",
        [ABGP.Phases.p3] = "Phase 3",
    };
    local phaseSelector = AceGUI:Create("Dropdown");
    phaseSelector:SetWidth(110);
    phaseSelector:SetList(phases, { ABGP.Phases.p1, ABGP.Phases.p3 });
    phaseSelector:SetValue(selectedPhase);
    phaseSelector:SetCallback("OnValueChanged", function(widget, event, value)
        selectedPhase = value;

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
    if #_G.ABGP_ItemAuditLog[ABGP.Phases.p1] > 0 or #_G.ABGP_ItemAuditLog[ABGP.Phases.p3] > 0 then
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
    tabGroup:SelectTab(tabs[1].value);

    return window;
end

function ABGP:ShowMainWindow()
    if activeWindow then return; end

    activeWindow = self:CreateMainWindow();
    PopulateUI(true);
end
