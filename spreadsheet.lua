local epMapping = {
    ["Points Earned"] = "ep",
    ["Action Taken"] = "action",
    ["Character"] = "character",
    ["Date"] = "date",
};
local epColumns = {
    weights = { 100, 75, 50, 1 },
    { value = "character", text = "Character" },
    { value = "date", text = "Date" },
    { value = "ep", text = "Points" },
    { value = "action", text = "Action Taken" },
};

local gpMapping = {
    ["New Points"] = "gp",
    ["Item"] = "item",
    ["Character"] = "character",
    ["Date Won"] = "date",
};
local gpColumns = {
    weights = { 100, 75, 50, 1 },
    { value = "character", text = "Character" },
    { value = "date", text = "Date" },
    { value = "gp", text = "Points" },
    { value = "item", text = "Item" },
};

local itemMapping = {
    ["Item"] = "item",
    ["Druid (Heal)"] = "druidH",
    ["Druid (Tank)"] = "druidT",
    ["Hunter"] = "hunter",
    ["Mage"] = "mage",
    ["Paladin (Holy)"] = "paladinH",
    ["Paladin (Ret)"] = "paladinR",
    ["Priest (Heal)"] = "priestH",
    ["Priest (Shadow)"] = "priestS",
    ["Rogue"] = "rogue",
    ["Warlock"] = "warlock",
    ["Tank"] = "warriorT",
    ["Metal Rogue"] = "warriorD",
    ["Progression"] = "progression",
    ["Garbage"] = "garbage",
    ["GP"] = "gp",
};
local itemClasses = {
    ["druidH"] = "Druid (Heal)",
    ["druidT"] = "Druid (Tank)",
    ["hunter"] = "Hunter",
    ["mage"] = "Mage",
    ["paladinH"] = "Paladin (Holy)",
    ["paladinR"] = "Paladin (Ret)",
    ["priestH"] = "Priest (Heal)",
    ["priestS"] = "Priest (Shadow)",
    ["rogue"] = "Rogue",
    ["warlock"] = "Warlock",
    ["warriorT"] = "Tank",
    ["warriorD"] = "Metal Rogue",
    ["progression"] = "Progression",
    ["garbage"] = "Garbage",
};
local itemColumns = {
    weights = { 200, 50, 350 },
    { value = "item", text = "Item" },
    { value = "gp", text = "GP" },
    { value = "priority", text = "Priority" },
};

local priMapping = {
    ["Character"] = "character",
    ["Rank"] = "rank",
    ["Class"] = "class",
    ["Spec"] = "role",
    ["Effort Points"] = "ep",
    ["Gear Points"] = "gp",
    ["Ratio"] = "ratio",
};
local priColumns = {
    weights = { 100, 60, 60, 70, 60, 60, 60 },
    { value = "character", text = "Character" },
    { value = "rank", text = "Rank" },
    { value = "class", text = "Class" },
    { value = "role", text = "Role" },
    { value = "ep", text = "EP" },
    { value = "gp", text = "GP" },
    { value = "ratio", text = "Ratio" },
};

local openWindows = {};
local function CloseWindows()
    local found = false;
    for window in pairs(openWindows) do
        found = true;
        window:Hide();
    end
    return found;
end

local old_CloseSpecialWindows = CloseSpecialWindows;
CloseSpecialWindows = function()
    local found = old_CloseSpecialWindows();
    return CloseWindows() or found;
end

local function DrawTable(container, spreadsheet, columns, importFunc, exportFunc)
    local AceGUI = LibStub("AceGUI-3.0");
    container:SetLayout("Flow");

    if importFunc then
        local import = AceGUI:Create("Button");
        import:SetText("Import");
        import:SetCallback("OnClick", function(widget, event)
            local window = AceGUI:Create("Window");
            window:SetTitle("Import");
            window:SetLayout("Fill");
            window:SetCallback("OnClose", function(widget) AceGUI:Release(widget); openWindows[widget] = nil; end);
            openWindows[window] = true;

            local edit = AceGUI:Create("MultiLineEditBox");
            edit:SetLabel("Copy the data from the ABP spreadsheet");
            edit:SetCallback("OnEnterPressed", importFunc);
            window:AddChild(edit);
            window.frame:Raise();
            edit:SetFocus();
            edit:SetUserData("window", window);
        end);
        container:AddChild(import);
    end

    if exportFunc then
        local export = AceGUI:Create("Button");
        export:SetText("Export");
        export:SetCallback("OnClick", function(widget, event)
            local window = AceGUI:Create("Window");
            window:SetTitle("Export");
            window:SetLayout("Fill");
            window:SetCallback("OnClose", function(widget) AceGUI:Release(widget); openWindows[widget] = nil; end);
            openWindows[window] = true;

            local edit = AceGUI:Create("MultiLineEditBox");
            edit:SetLabel("Export the data");

            edit:SetText(exportFunc());
            edit.button:Enable();
            window:AddChild(edit);
            window.frame:Raise();
            edit:SetFocus();
            edit:SetUserData("window", window);
        end);
        container:AddChild(export);
    end

    local header = AceGUI:Create("SimpleGroup");
    header:SetFullWidth(true);
    header:SetLayout("Table");
    header:SetUserData("table", { columns = columns.weights});
    container:AddChild(header);

    for i = 1, #columns do
        local desc = AceGUI:Create("Label");
        desc:SetText(strupper(columns[i].text));
        header:AddChild(desc);
    end

    local scrollContainer = AceGUI:Create("SimpleGroup");
    scrollContainer:SetFullWidth(true);
    scrollContainer:SetFullHeight(true);
    scrollContainer:SetLayout("Fill");
    container:AddChild(scrollContainer);

    local scroll = AceGUI:Create("ScrollFrame");
    scroll:SetFullWidth(true);
    scroll:SetLayout("List");
    scrollContainer:AddChild(scroll);

    local group = AceGUI:Create("SimpleGroup");
    group:SetFullWidth(true);
    group:SetLayout("Table");
    group:SetUserData("table", { columns = columns.weights });
    scroll:AddChild(group);

    group:PauseLayout();
    for i = 1, #spreadsheet do
        for j = 1, #columns do
            local desc = AceGUI:Create("Label");
            local data = spreadsheet[i][columns[j].value];
            if type(data) == "number" then
                data = string.format(floor(data) == data and "%d" or "%.2f", data);
            end
            if type(data) == "table" then data = table.concat(data, ", "); end
            desc:SetText(data);
            desc:SetWidth(0);
            desc:SetFullWidth(true);
            group:AddChild(desc);
        end
    end
    group:ResumeLayout();
    group:DoLayout();
    scroll:DoLayout();
end

local function PopulateSpreadsheet(text, spreadsheet, mapping, filter)
    table.wipe(spreadsheet);

    local labels;
    for line in string.gmatch(text, "[^\n]+") do
        if line:find("    ") then
            line = line .. "    ";
        else
            line = line .. ",";
        end
        local values = {};
        for value in string.gmatch(line, "(.-)    ") do
            table.insert(values, value);
        end
        for value in string.gmatch(line, "(.-),") do
            table.insert(values, value);
        end
        if not labels then
            labels = values;
        else
            local row = {};
            for j = 1, #values do
                if mapping[labels[j]] then
                    row[mapping[labels[j]]] = (type(tonumber(values[j])) == "number" and tonumber(values[j]) or values[j]);
                end
            end
            if (not filter or filter(row)) then
                table.insert(spreadsheet, row);
            end
        end
    end
end

function ABGP:ShowWindow()
    local AceGUI = LibStub("AceGUI-3.0");
    local window = AceGUI:Create("Window");
    window:SetTitle("ABP EPGP");
    window:SetWidth(650);
    window:SetHeight(400);
    window:SetLayout("Fill");
    window:SetCallback("OnClose", function(widget) AceGUI:Release(widget); openWindows[widget] = nil; end);
    openWindows[window] = true;

    local function DrawPriority(container)
        local importFunc = function(widget, event)
            PopulateSpreadsheet(widget:GetText(), ABGP_Priority, priMapping);
            ABGP:RefreshActivePlayers();

            widget:GetUserData("window"):Hide();
            container:ReleaseChildren();
            DrawPriority(container);
        end

        local exportFunc = function()
            local text = "Character,Rank,Class,Spec,Effort Points,Gear Points,Ratio\n";
            for _, item in ipairs(ABGP_EP) do
                text = text .. string.format("%s,%s,%s,%s,%s,%s,%s\n",
                    item.character, item.rank, item.class, item.role, item.ep, item.gp, item.ratio);
            end

            return text;
        end

        DrawTable(container, ABGP_Priority, priColumns, importFunc, exportFunc);
    end

    local function DrawEP(container)
        local importFunc = function(widget, event)
            PopulateSpreadsheet(widget:GetText(), ABGP_EP, epMapping, function(row)
                return ABGP:IsActivePlayer(row.character);
            end);

            widget:GetUserData("window"):Hide();
            container:ReleaseChildren();
            DrawEP(container);
        end

        local exportFunc = function()
            local text = "Points Earned,Action Taken,Character,Date\n";
            for _, item in ipairs(ABGP_EP) do
                text = text .. string.format("%s,%s,%s,%s\n",
                    item.ep, item.action, item.character, item.date);
            end

            return text;
        end

        DrawTable(container, ABGP_EP, epColumns, importFunc, exportFunc);
    end

    local function DrawGP(container)
        local importFunc = function(widget, event)
            PopulateSpreadsheet(widget:GetText(), ABGP_GP, gpMapping, function(row)
                if gpLine.gp == "" then gpLine.gp = 0; end
                return ABGP:IsActivePlayer(row.character);
            end);

            widget:GetUserData("window"):Hide();
            container:ReleaseChildren();
            DrawGP(container);
        end

        local exportFunc = function()
            local text = "New Points,Item,Character,Date Won\n";
            for _, item in ipairs(ABGP_GP) do
                text = text .. string.format("%s,%s,%s,%s\n",
                    item.gp, item.item, item.character, item.date);
            end

            return text;
        end

        DrawTable(container, ABGP_GP, gpColumns, importFunc, exportFunc);
    end

    local function DrawItems(container)
        local importFunc = function(widget, event)
            PopulateSpreadsheet(widget:GetText(), ABGP_ItemValues, itemMapping, function(row)
                row.priority = {};
                for k, v in pairs(row) do
                    if itemClasses[k] then
                        if v ~= "" then
                            table.insert(row.priority, itemClasses[k]);
                        end
                        row[k] = nil;
                    end
                end
                return true;
            end);
            CalculateItemValues();

            widget:GetUserData("window"):Hide();
            container:ReleaseChildren();
            DrawItems(container);
        end

        DrawTable(container, ABGP_ItemValues, itemColumns, importFunc, nil);
    end

    local tabs = {
        { value = "priority", text = "Priority", selected = DrawPriority },
        { value = "ep", text = "Effort Points", selected = DrawEP },
        { value = "gp", text = "Gear Points", selected = DrawGP },
        { value = "items", text = "Items", selected = DrawItems },
    };

    local tabGroup = AceGUI:Create("TabGroup");
    tabGroup:SetTabs(tabs);
    tabGroup:SetCallback("OnGroupSelected", function(container, event, group)
        container:ReleaseChildren();
        for i, v in ipairs(tabs) do
            if v.value == group then
                v.selected(container);
                break;
            end
        end
    end);
    tabGroup:SelectTab(tabs[1].value);
    window:AddChild(tabGroup);
end
