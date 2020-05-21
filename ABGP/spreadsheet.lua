local _G = _G;
local ABGP = _G.ABGP;
local AceGUI = _G.LibStub("AceGUI-3.0");

local GetItemInfo = GetItemInfo;
local pairs = pairs;
local ipairs = ipairs;
local strupper = strupper;
local type = type;
local floor = floor;
local table = table;
local tonumber = tonumber;
local time = time;

local activeWindow;

local epMapping = {
    ["Points Earned"] = "ep",
    ["Action Taken"] = "action",
    ["Character"] = "player",
    ["Date"] = "date",
    ["Notes"] = false,
};
local epColumns = {
    weights = { 100, 75, 50, 1 },
    { value = "player", text = "Character" },
    { value = "date", text = "Date" },
    { value = "ep", text = "Points" },
    { value = "action", text = "Action Taken" },
};

local gpMapping = {
    ["New Points"] = ABGP.ItemHistoryIndex.GP,
    ["Item"] = ABGP.ItemHistoryIndex.NAME,
    ["Character"] = ABGP.ItemHistoryIndex.PLAYER,
    ["Date Won"] = ABGP.ItemHistoryIndex.DATE,
    ["Boss"] = false,
};
local gpColumns = {
    weights = { 100, 75, 50, 1 },
    { value = ABGP.ItemHistoryIndex.PLAYER, text = "Character" },
    { value = ABGP.ItemHistoryIndex.DATE, text = "Date" },
    { value = ABGP.ItemHistoryIndex.GP, text = "Points" },
    { value = ABGP.ItemHistoryIndex.NAME, text = "Item" },
};

local itemPriorities = ABGP:GetItemPriorities();
local itemMapping = {
    ["Item"] = ABGP.ItemDataIndex.NAME,
    ["GP Cost"] = ABGP.ItemDataIndex.GP,
    ["Boss"] = ABGP.ItemDataIndex.BOSS,
    ["Notes"] = ABGP.ItemDataIndex.NOTES,
    -- ABGP.ItemDataIndex.ITEMLINK and ABGP.ItemDataIndex.PRIORITY populated elsewhere
};
for value, text in pairs(itemPriorities) do
    itemMapping[text] = value;
end
local itemColumns = {
    weights = { 200, 50, 350 },
    { value = ABGP.ItemDataIndex.NAME, text = "Item" },
    { value = ABGP.ItemDataIndex.GP, text = "GP" },
    { value = "priority", text = "Priority" },
};

local priMapping = {
    ["Character"] = "player",
    ["Rank"] = false,
    ["Class"] = false,
    ["Spec"] = false,
    ["Effort Points"] = "ep",
    ["Gear Points"] = "gp",
    ["Ratio"] = false,
};
local priColumns = {
    weights = { 110, 90, 60, 60, 60, 60 },
    { value = "player", text = "Character" },
    { value = "rank", text = "Rank" },
    { value = "class", text = "Class" },
    { value = "ep", text = "EP" },
    { value = "gp", text = "GP" },
    { value = "priority", text = "Ratio" },
};

local function DrawTable(container, spreadsheet, columns, importFunc, exportFunc, canBeDelta)
    spreadsheet = spreadsheet or {};
    container:SetLayout("Flow");

    if importFunc then
        local import = AceGUI:Create("Button");
        import:SetText("Import");
        import:SetCallback("OnClick", function(widget, event)
            local window = AceGUI:Create("Window");
            window:SetTitle("Import");
            window:SetLayout("Flow");
            window:SetCallback("OnClose", function(widget) AceGUI:Release(widget); ABGP:CloseWindow(widget); end);
            ABGP:OpenWindow(window);

            local edit = AceGUI:Create("MultiLineEditBox");
            if canBeDelta then
                local delta = AceGUI:Create("CheckBox");
                delta:SetLabel("Delta Import");
                delta:SetWidth(110);
                ABGP:AddWidgetTooltip(delta, "If checked, the import process will only consider the data to be an update, rather than a replacement of existing data.");
                delta:SetCallback("OnValueChanged", function(widget, event, value)
                    edit:SetUserData("deltaImport", value);
                end);
                window:AddChild(delta);
            end

            edit:SetFullWidth(true);
            edit:SetFullHeight(true);
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
            window:SetCallback("OnClose", function(widget) AceGUI:Release(widget); ABGP:CloseWindow(widget); end);
            ABGP:OpenWindow(window);

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
                data = (floor(data) == data and "%d" or "%.3f"):format(data);
            end
            if type(data) == "table" then
                data = table.concat(data, ", ");
            end
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
    local newData = {};
    local labels;
    for line in text:gmatch("[^\n]+") do
        if line:find("    ") then
            line = line .. "    ";
        else
            line = line .. ",";
        end
        local values = {};
        for value in line:gmatch("(.-)    ") do
            table.insert(values, value);
        end
        for value in line:gmatch("(.-),") do
            table.insert(values, value);
        end
        if not labels then
            labels = values;
            for j = 1, #labels do
                if mapping[labels[j]] == nil then
                    ABGP:Notify("No mapping for column: %s. Cancelling import!", labels[j]);
                    return false;
                end
            end
        else
            local row = {};
            for j = 1, #values do
                if mapping[labels[j]] and values[j] ~= "" then
                    row[mapping[labels[j]]] = (type(tonumber(values[j])) == "number" and tonumber(values[j]) or values[j]);
                end
            end
            if (not filter or filter(row)) then
                table.insert(newData, row);
            end
        end
    end

    table.wipe(spreadsheet);
    for k, v in pairs(newData) do spreadsheet[k] = v; end
    return true;
end

local function DrawPriority(container)
    local importFunc = function(widget, event)
        if widget:GetUserData("deltaImport") then
            local newPriorities = {};
            if PopulateSpreadsheet(widget:GetText(), newPriorities, priMapping) then
                for _, newPri in ipairs(newPriorities) do
                    local found = false;
                    for _, existingPri in ipairs(ABGP.Priorities[ABGP.CurrentPhase]) do
                        if existingPri.player == newPri.player then
                            found = true;
                            existingPri.ep = newPri.ep;
                            existingPri.gp = newPri.gp;
                            break;
                        end
                    end

                    if not found then
                        table.insert(ABGP.Priorities[ABGP.CurrentPhase], newPri);
                    end
                end
            end
        else
            PopulateSpreadsheet(widget:GetText(), ABGP.Priorities[ABGP.CurrentPhase], priMapping);
        end

        ABGP:RefreshActivePlayers();
        ABGP:RebuildOfficerNotes();
        ABGP:RefreshFromOfficerNotes();

        widget:GetUserData("window"):Hide();
        container:ReleaseChildren();
        DrawPriority(container);
    end

    local exportFunc = function()
        local text = "Character,Rank,Class,Spec,Effort Points,Gear Points,Ratio\n";
        for _, item in ipairs(ABGP.Priorities[ABGP.CurrentPhase]) do
            text = text .. ("%s,%s,%s,%s,%s,%s,%s\n"):format(
                item.player, item.rank, item.class, item.role, item.ep, item.gp, item.priority);
        end

        return text;
    end

    DrawTable(container, ABGP.Priorities[ABGP.CurrentPhase], priColumns, importFunc, exportFunc, true);
end

local function DrawEP(container)
    local importFunc = function(widget, event)
        PopulateSpreadsheet(widget:GetText(), _G.ABGP_Data[ABGP.CurrentPhase].epHistory, epMapping, function(row)
            return ABGP:GetActivePlayer(row.player);
        end);

        widget:GetUserData("window"):Hide();
        container:ReleaseChildren();
        DrawEP(container);
    end

    local exportFunc = function()
        local text = "Points Earned,Action Taken,Character,Date\n";
        for _, item in ipairs(_G.ABGP_Data[ABGP.CurrentPhase].epHistory) do
            text = text .. ("%s,%s,%s,%s\n"):format(
                item.ep, item.action, item.player, item.date);
        end

        return text;
    end

    DrawTable(container, _G.ABGP_Data[ABGP.CurrentPhase].epHistory, epColumns, importFunc, exportFunc);
end

local function DrawGP(container)
    local banned = {
        ["placeholder decay"] = true,
        ["starting gp"] = true,
        ["conversion from trial"] = true,
        ["promotion to raider"] = true,
        ["conversion to raider"] = true,
        ["week 9 decay"] = true,
        ["trial end"] = true,
        ["trial"] = true,
        ["carryover gp from previous bwl"] = true,
        ["split start gp"] = true,
    };
    local entryTimes = {};
    local importFunc = function(widget, event)
        PopulateSpreadsheet(widget:GetText(), _G.ABGP_Data[ABGP.CurrentPhase].gpHistory, gpMapping, function(row)
            row[ABGP.ItemHistoryIndex.TYPE] = ABGP.ItemHistoryType.ITEM;
            row[ABGP.ItemHistoryIndex.GP] = row[ABGP.ItemHistoryIndex.GP] or 0;
            row[ABGP.ItemHistoryIndex.DATE] = row[ABGP.ItemHistoryIndex.DATE] or "";
            row[ABGP.ItemHistoryIndex.DATE] = row[ABGP.ItemHistoryIndex.DATE]:gsub("20(%d%d)", "%1");
            local m, d, y = row[ABGP.ItemHistoryIndex.DATE]:match("^(%d-)/(%d-)/(%d-)$");
            if m ~= "" then
                row[ABGP.ItemHistoryIndex.DATE] = ("%02d/%02d/%02d"):format(m, d, y);
                m, d, y = row[ABGP.ItemHistoryIndex.DATE]:match("^(%d-)/(%d-)/(%d-)$");
                local entryTime = time({ year = 2000 + y, month = m, day = d });
                while entryTimes[entryTime] do entryTime = entryTime + 1; end
                entryTimes[entryTime] = true;
                row[ABGP.ItemHistoryIndex.ID] = ("%s:%s"):format("IMPORT", entryTime);
            end
            return
                row[ABGP.ItemHistoryIndex.PLAYER] and
                row[ABGP.ItemHistoryIndex.NAME] and
                row[ABGP.ItemHistoryIndex.GP] >= 0 and
                not banned[row[ABGP.ItemHistoryIndex.NAME]:lower()] and
                ABGP:GetActivePlayer(row[ABGP.ItemHistoryIndex.PLAYER]);
        end);

        local function reverse(arr)
            local i, j = 1, #arr;
            while i < j do
                arr[i], arr[j] = arr[j], arr[i];
                i = i + 1;
                j = j - 1;
            end
        end
        reverse(_G.ABGP_Data[ABGP.CurrentPhase].gpHistory);

        widget:GetUserData("window"):Hide();
        container:ReleaseChildren();
        DrawGP(container);

        if not ABGP:FixupHistory() then
            ABGP:ScheduleTimer("FixupHistory", 5);
        end
    end

    local exportFunc = function()
        local text = "New Points,Item,Character,Date Won\n";
        for _, item in ipairs(_G.ABGP_Data[ABGP.CurrentPhase].gpHistory) do
            text = text .. ("%s,%s,%s,%s\n"):format(
                item[ABGP.ItemHistoryIndex.GP], item[ABGP.ItemHistoryIndex.NAME], item[ABGP.ItemHistoryIndex.PLAYER], item[ABGP.ItemHistoryIndex.DATE]);
        end

        return text;
    end

    DrawTable(container, _G.ABGP_Data[ABGP.CurrentPhase].gpHistory, gpColumns, importFunc, exportFunc);
end

local function DrawItems(container)
    local importFunc = function(widget, event)
        PopulateSpreadsheet(widget:GetText(), _G.ABGP_Data[ABGP.CurrentPhase].itemValues, itemMapping, function(row)
            row[ABGP.ItemDataIndex.PRIORITY] = {};
            for k, v in pairs(row) do
                if itemPriorities[k] then
                    table.insert(row[ABGP.ItemDataIndex.PRIORITY], itemPriorities[k]);
                    row[k] = nil;
                end
            end
            table.sort(row[ABGP.ItemDataIndex.PRIORITY]);
            return true;
        end);

        widget:GetUserData("window"):Hide();
        container:ReleaseChildren();
        DrawItems(container);

        if ABGP:FixupItems() then
            ABGP:CommitItemData();
        else
            ABGP:Error("Couldn't find item links for some items! Unable to commit these updates.");
        end
    end

    DrawTable(container, _G.ABGP_Data[ABGP.CurrentPhase].itemValues, itemColumns, importFunc, nil);
end

function ABGP:ShowImportWindow()
    if activeWindow then return; end
    if not (_G.AtlasLoot and
            _G.AtlasLoot.ItemDB and
            _G.AtlasLoot.ItemDB.Storage and
            _G.AtlasLoot.ItemDB.Storage.AtlasLootClassic_DungeonsAndRaids) then
        self:Error("You must have AtlasLoot installed to show this window!");
        return;
    end

    self:BuildItemLookup();

    local window = AceGUI:Create("Window");
    window.frame:SetFrameStrata("MEDIUM");
    window:SetTitle(("%s Spreadsheet Interop"):format(self:ColorizeText("ABGP")));
    window:SetWidth(650);
    window:SetHeight(400);
    window:SetLayout("Flow");
    window:SetCallback("OnClose", function(widget) AceGUI:Release(widget); ABGP:CloseWindow(widget); activeWindow = nil; end);
    ABGP:OpenWindow(window);

    local tabs = {
        { value = "priority", text = "Priority", selected = DrawPriority },
        { value = "ep", text = "Effort Points", selected = DrawEP },
        { value = "gp", text = "Gear Points", selected = DrawGP },
        { value = "items", text = "Items", selected = DrawItems },
    };
    local selectedTab = tabs[1].value;

    local phases, phaseNames = {}, {};
    for i, v in ipairs(ABGP:IsPrivileged() and ABGP.PhasesSortedAll or ABGP.PhasesSorted) do phases[i] = v; end
    for k, v in pairs(ABGP:IsPrivileged() and ABGP.PhaseNamesAll or ABGP.PhaseNames) do phaseNames[k] = v; end
    local phaseSelector = AceGUI:Create("Dropdown");
    phaseSelector:SetWidth(110);
    phaseSelector:SetList(phaseNames, phases);
    phaseSelector:SetValue(ABGP.CurrentPhase);
    phaseSelector:SetCallback("OnValueChanged", function(widget, event, value)
        ABGP.CurrentPhase = value;
        widget:GetUserData("tabGroup"):SelectTab(selectedTab);
    end);
    window:AddChild(phaseSelector);

    local tabGroup = AceGUI:Create("TabGroup");
    tabGroup:SetFullWidth(true);
    tabGroup:SetFullHeight(true);
    tabGroup:SetTabs(tabs);
    tabGroup:SetCallback("OnGroupSelected", function(container, event, tab)
        selectedTab = tab;
        container:ReleaseChildren();
        for i, v in ipairs(tabs) do
            if v.value == selectedTab then
                v.selected(container);
                break;
            end
        end
    end);
    tabGroup:SelectTab(selectedTab);
    phaseSelector:SetUserData("tabGroup", tabGroup);
    window:AddChild(tabGroup);
    window.frame:Raise();
    activeWindow = window;
end


local blacklist = {
    [17012] = true, -- Core Leather
};

local lookup = {};

function ABGP:BuildItemLookup(shouldPrint)
    local succeeded = true;

    local mc = _G.AtlasLoot.ItemDB.Storage.AtlasLootClassic_DungeonsAndRaids.MoltenCore.items;
    local ony = _G.AtlasLoot.ItemDB.Storage.AtlasLootClassic_DungeonsAndRaids.Onyxia.items;
    local wb = _G.AtlasLoot.ItemDB.Storage.AtlasLootClassic_DungeonsAndRaids.WorldBosses.items;
    local bwl = _G.AtlasLoot.ItemDB.Storage.AtlasLootClassic_DungeonsAndRaids.BlackwingLair.items;
    -- local aq20 = _G.AtlasLoot.ItemDB.Storage.AtlasLootClassic_DungeonsAndRaids.TheRuinsofAhnQiraj.items;
    local aq40 = _G.AtlasLoot.ItemDB.Storage.AtlasLootClassic_DungeonsAndRaids.TheTempleofAhnQiraj.items;
    for _, collection in ipairs({ mc, ony, wb, bwl, aq40 }) do
        for _, sub in ipairs(collection) do
            if sub[1] then
                for _, item in ipairs(sub[1]) do
                    if type(item[2]) == "number" and not blacklist[item[2]] then
                        local name, link = GetItemInfo(item[2]);
                        if name then
                            lookup[name] = ABGP:ShortenLink(link);
                        else
                            succeeded = false;
                        end
                    end
                end
            end
        end
    end

    if not succeeded and shouldPrint then
        self:Notify("Failed to query some items!");
    end

    return succeeded;
end

function ABGP:FixupItems()
    if not self:BuildItemLookup(true) then return false; end

    local p1 = _G.ABGP_Data.p1.itemValues;
    local p3 = _G.ABGP_Data.p3.itemValues;
    local p5 = _G.ABGP_Data.p5.itemValues;
    for _, phase in ipairs({ p1, p3, p5 }) do
        for _, entry in ipairs(phase) do
            if lookup[entry[ABGP.ItemDataIndex.NAME]] then
                entry[ABGP.ItemDataIndex.ITEMLINK] = lookup[entry[ABGP.ItemDataIndex.NAME]];
            else
                self:Notify(("FAILED TO FIND [%s]"):format(entry[ABGP.ItemDataIndex.NAME]));
            end
        end
    end

    self:Notify("Done fixing up items!");
    return true;
end

function ABGP:FixupHistory()
    if not self:BuildItemLookup(true) then return false; end

    local p1 = _G.ABGP_Data.p1.gpHistory;
    local p3 = _G.ABGP_Data.p3.gpHistory;
    for _, phase in ipairs({ p1, p3 }) do
        for _, entry in ipairs(phase) do
            if not lookup[entry[self.ItemHistoryIndex.NAME]] then
                for name, link in pairs(lookup) do
                    local lowered = entry[self.ItemHistoryIndex.NAME]:lower();
                    if lowered:find(name:lower(), 1, true) then
                        -- print(("Updating [%s] to [%s]"):format(entry[self.ItemHistoryIndex.NAME], name));
                        entry[self.ItemHistoryIndex.NAME] = name;
                        break;
                    end
                end
                if not lookup[entry[self.ItemHistoryIndex.NAME]] then
                    self:Notify(("FAILED TO FIND [%s]"):format(entry[self.ItemHistoryIndex.NAME]));
                end
            end
        end
    end

    self:Notify("Done fixing up history!");
    return true;
end
