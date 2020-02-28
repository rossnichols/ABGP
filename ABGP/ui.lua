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
local ignoredClasses = {};
local pageSize = 50;
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
    local widths = { 120, 110, 75, 75, 75 };

    if rebuild then
        local classSelector = AceGUI:Create("Dropdown");
        classSelector:SetWidth(110);
        local classes = {
            "DRUID",
            "HUNTER",
            "MAGE",
            "PALADIN",
            "PRIEST",
            "ROGUE",
            "WARLOCK",
            "WARRIOR",
            "ALL",
        };
        classSelector:SetList({
            DRUID = "Druid",
            HUNTER = "Hunter",
            MAGE = "Mage",
            PALADIN = "Paladin",
            PRIEST = "Priest",
            ROGUE = "Rogue",
            WARLOCK = "Warlock",
            WARRIOR = "Warrior",
            ALL = "All",
        }, classes);
        classSelector:SetMultiselect(true);

        local function showingAll()
            local hasIgnoredClass = false;
            for _, state in pairs(ignoredClasses) do
                if state then
                    hasIgnoredClass = true;
                    break;
                end
            end

            return not hasIgnoredClass;
        end
        local function showingNone()
            local hasShownClass = false;
            for _, class in ipairs(classes) do
                if class ~= "ALL" and not ignoredClasses[class] then
                    hasShownClass = true;
                    break;
                end
            end

            return not hasShownClass;
        end
        local function updateCheckboxes(widget)
            local all = showingAll();
            for _, class in ipairs(classes) do
                if class == "ALL" then
                    widget:SetItemValue(class, all);
                else
                    widget:SetItemValue(class, not all and not ignoredClasses[class]);
                end
            end
        end
        local function valueChangedCallback(widget, event, class, checked)
            if class == "ALL" then
                if checked then
                    ignoredClasses = {};
                end
            else
                if checked then
                    if showingAll() then
                        ignoredClasses = {
                            DRUID = true,
                            HUNTER = true,
                            MAGE = true,
                            PALADIN = true,
                            PRIEST = true,
                            ROGUE = true,
                            WARLOCK = true,
                            WARRIOR = true,
                        };
                    end
                end
                ignoredClasses[class] = not checked;
                if showingNone() then
                    ignoredClasses = {};
                end
            end

            widget:SetCallback("OnValueChanged", nil);
            updateCheckboxes(widget);
            widget:SetCallback("OnValueChanged", valueChangedCallback);
            PopulateUI(false);
        end
        updateCheckboxes(classSelector);
        classSelector:SetCallback("OnValueChanged", valueChangedCallback);
        classSelector:SetText("Classes");
        container:AddChild(classSelector);

        local scrollContainer = AceGUI:Create("SimpleGroup");
        scrollContainer:SetFullWidth(true);
        scrollContainer:SetFullHeight(true);
        scrollContainer:SetLayout("Flow");
        container:AddChild(scrollContainer);

        local columns = { "Player", "Rank", "EP", "GP", "Priority", weights = { unpack(widths) } };
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
    local priority = ABGP.Priorities[selectedPhase];
    for i, data in ipairs(priority) do
        if not ignoredClasses[data.class] then
            count = count + 1;
            local elt = AceGUI:Create("ABGP_Player");
            elt:SetFullWidth(true);
            elt:SetData(data);
            elt:SetWidths(widths);
            elt:ShowBackground((count % 2) == 0);
            elt:SetHeight(20);
            if data.player == UnitName("player") then
                elt.frame:RequestHighlight(true);
            end

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
        mainLine:SetUserData("table", { columns = { 0, 0, 0, 0, 0, 1.0, 0 } });
        container:AddChild(mainLine);

        local pageSizes = {
            [25] = "25",
            [50] = "50",
            [100] = "100",
        };
        local pageSizeSelector = AceGUI:Create("Dropdown");
        pageSizeSelector:SetWidth(70);
        pageSizeSelector:SetList(pageSizes, { 25, 50, 100 });
        pageSizeSelector:SetValue(pageSize);
        pageSizeSelector:SetCallback("OnValueChanged", function(widget, event, value)
            pageSize = value;
            PopulateUI(false);
        end);
        mainLine:AddChild(pageSizeSelector);

        local desc = AceGUI:Create("Label");
        desc:SetWidth(70);
        desc:SetText(" Page Size");
        mainLine:AddChild(desc);

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

                    text = text .. ("%s;%s;%s;Exported from ABGP%s"):format(
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
    local searchText = container:GetUserData("search"):GetText():lower();
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
            if exact then
                if data.player:lower() == exact or
                   data.item:lower() == exact or
                   data.class:lower() == exact or
                   data.date:lower() == exact then
                    table.insert(filtered, data);
                end
            else
                if data.player:lower():find(searchText, 1, true) or
                   data.item:lower():find(searchText, 1, true) or
                   data.class:lower():find(searchText, 1, true) or
                   data.date:lower():find(searchText, 1, true) then
                    table.insert(filtered, data);
                end
            end
        end
    end

    pagination:SetValues(#filtered, pageSize);
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
            history:AddChild(elt);
        end
    end
end

local function DrawAuditLog(container, rebuild)
    local widths = { 70, 1.0 };
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

        local columns = { "Date", "Info", weights = { unpack(widths) } };
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
    pagination:SetValues(#entries, 10);
    if #entries > 0 then
        local first, last = pagination:GetRange();
        local requestTypes = {
            [ABGP.RequestTypes.MS] = "ms",
            [ABGP.RequestTypes.OS] = "os",
            [ABGP.RequestTypes.ROLL] = "roll",
        };
        for i = first, last do
            local data = entries[i];
            local logged = {};
            for _, distrib in ipairs(data.distributions) do
                local audit;
                if distrib.trashed then
                    audit = ("%s was disenchanted"):format(data.itemLink);
                else
                    logged[distrib.player] = true;
                    local requestType = requestTypes[distrib.requestType];
                    local override = distrib.override
                        and (",%s"):format(distrib.override)
                        or "";
                    audit = ("%s for %dgp to %s (%s%s): ep=%.2f gp=%.2f pri=%.2f"):format(
                        data.itemLink, distrib.cost, distrib.player, requestType, override, distrib.ep, distrib.gp, distrib.priority);
                end
                local elt = AceGUI:Create("ABGP_AuditLog");
                elt:SetFullWidth(true);
                elt:SetData({
                    date = date("%m/%d/%y", data.time),
                    audit = audit,
                    important = true,
                });
                elt:SetWidths(widths);
                auditLog:AddChild(elt);
            end
            for _, request in ipairs(data.requests) do
                if not logged[request.player] then
                    local requestType = requestTypes[request.requestType];
                    local audit = ("%s by %s (%s): ep=%.2f gp=%.2f pri=%.2f"):format(
                        data.itemLink, request.player, requestType, request.ep, request.gp, request.priority);
                    local elt = AceGUI:Create("ABGP_AuditLog");
                    elt:SetFullWidth(true);
                    elt:SetData({
                        date = date("%m/%d/%y", data.time),
                        audit = audit,
                        important = false,
                    });
                    elt:SetWidths(widths);
                    auditLog:AddChild(elt);
                end
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
        minWidth = 550,
        maxWidth = 700,
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
    window:AddChild(phaseSelector);

    local tabs = {
        { value = "priority", text = "Priority", draw = DrawPriority },
        -- { value = "ep", text = "Effort Points", draw = DrawEP },
        { value = "gp", text = "Item History", draw = DrawItemHistory },
        -- { value = "items", text = "Items", draw = DrawItems },
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
