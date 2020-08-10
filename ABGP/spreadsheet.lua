local _G = _G;
local ABGP = _G.ABGP;
local AceGUI = _G.LibStub("AceGUI-3.0");

local GetItemInfo = GetItemInfo;
local tContains = tContains;
local pairs = pairs;
local ipairs = ipairs;
local strupper = strupper;
local type = type;
local floor = floor;
local table = table;
local tonumber = tonumber;
local time = time;
local date = date;

local activeWindow;

local epMapping = {
    ["Points Earned"] = "ep",
    ["Action Taken"] = "action",
    ["Character"] = "player",
    ["Date"] = "date",
};

local gpMapping = {
    ["New Points"] = ABGP.ItemHistoryIndex.GP,
    ["Item"] = ABGP.ItemHistoryIndex.ITEMID,
    ["Character"] = ABGP.ItemHistoryIndex.PLAYER,
    ["Date Won"] = ABGP.ItemHistoryIndex.DATE,
    ["Boss"] = "boss",
};

local itemPriorities = ABGP:GetItemPriorities();
local itemMapping = {
    ["Raid"] = ABGP.ItemDataIndex.RAID,
    ["Boss"] = ABGP.ItemDataIndex.BOSS,
    ["Item"] = ABGP.ItemDataIndex.NAME,
    ["Category"] = ABGP.ItemDataIndex.CATEGORY,
    ["GP"] = ABGP.ItemDataIndex.GP,
    ["Notes"] = ABGP.ItemDataIndex.NOTES,
    -- ABGP.ItemDataIndex.ITEMLINK and ABGP.ItemDataIndex.PRIORITY populated elsewhere
};
local catMapping = {
    ["Silver"] = ABGP.ItemCategory.SILVER,
    ["Gold"] = ABGP.ItemCategory.GOLD,
};
for value, text in pairs(itemPriorities) do
    itemMapping[text] = value;
end

local priMapping = {
    ["Player"] = "player",
    ["EP"] = "ep",
    ["Silver GP"] = "gpS",
    ["Gold GP"] = "gpG",
};

local function OpenImportWindow(importFunc, canBeDelta)
    local window = AceGUI:Create("ABGP_OpaqueWindow");
    window.frame:SetFrameStrata("DIALOG");
    window:SetTitle("Import");
    window:SetLayout("Flow");
    window:SetCallback("OnClose", function(widget) AceGUI:Release(widget); ABGP:ClosePopup(widget); end);
    ABGP:OpenPopup(window);

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
    edit:SetUserData("window", window);
    window:AddChild(edit);

    window.frame:Raise();
    edit:SetFocus();
end

function ABGP:OpenExportWindow(text)
    local window = AceGUI:Create("ABGP_OpaqueWindow");
    window.frame:SetFrameStrata("DIALOG");
    window:SetTitle("Export");
    window:SetLayout("Fill");
    window:SetCallback("OnClose", function(widget) AceGUI:Release(widget); ABGP:ClosePopup(widget); end);
    ABGP:OpenPopup(window);

    local edit = AceGUI:Create("MultiLineEditBox");
    edit:SetLabel("Export the data");

    edit:SetText(text);
    edit:DisableButton(true);
    edit:SetCallback("OnEditFocusGained", function(widget)
        widget:HighlightText();
    end);
    edit:SetCallback("OnEnterPressed", function()
        window:Hide();
    end);
    window:AddChild(edit);

    window.frame:Raise();
    edit:SetFocus();
end

local function ImportSpreadsheetText(text, spreadsheet, mapping, filter)
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
            for colName in pairs(mapping) do
                if not tContains(labels, colName) then
                    ABGP:Notify("Expected column '%s' not found. Canceling import!", colName);
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
            local insert, isError = true, false;
            if filter then
                insert, isError = filter(row, newData);
            end
            if isError then
                ABGP:Notify("Canceling import!");
                return false;
            end
            if insert then
                table.insert(newData, row);
            end
        end
    end

    table.wipe(spreadsheet);
    for k, v in pairs(newData) do spreadsheet[k] = v; end
    return true;
end

function ABGP:ImportPriority()
    local importFunc = function(widget, event)
        if widget:GetUserData("deltaImport") then
            local newPriorities = {};
            if ImportSpreadsheetText(widget:GetText(), newPriorities, priMapping) then
                for _, newPri in ipairs(newPriorities) do
                    local found = false;
                    for _, existingPri in ipairs(self.Priorities) do
                        if existingPri.player == newPri.player then
                            found = true;
                            existingPri.ep = newPri.ep;
                            existingPri.gp = { [self.ItemCategory.GOLD] = newPri.gpG, [self.ItemCategory.SILVER] = newPri.gpS };
                            break;
                        end
                    end

                    if not found then
                        newPri.gp = { [self.ItemCategory.GOLD] = newPri.gpG, [self.ItemCategory.SILVER] = newPri.gpS };
                        newPri.gpG = nil;
                        newPri.gpS = nil;
                        table.insert(self.Priorities, newPri);
                    end
                end
            end
        else
            ImportSpreadsheetText(widget:GetText(), self.Priorities, priMapping, function(row)
                if row.ep ~= 0 and row.gpS and row.gpS ~= 0 and row.gpG and row.gpG ~= 0 then
                    row.gp = { [self.ItemCategory.GOLD] = row.gpG, [self.ItemCategory.SILVER] = row.gpS };
                    row.gpG = nil;
                    row.gpS = nil;
                    return true;
                else
                    return false;
                end
            end);
        end

        self:RefreshActivePlayers();
        if not self:GetDebugOpt("SkipOfficerNote") then
            self:RebuildOfficerNotes();
        end

        widget:GetUserData("window"):Hide();
    end

    OpenImportWindow(importFunc, true);
end

function ABGP:ImportItems()
    if not (_G.AtlasLoot and
            _G.AtlasLoot.ItemDB and
            _G.AtlasLoot.ItemDB.Storage and
            _G.AtlasLoot.ItemDB.Storage.AtlasLootClassic_DungeonsAndRaids) then
        self:Error("You must have AtlasLoot installed to show this window!");
        return;
    end

    self:BuildItemLookup();

    local importFunc = function(widget, event)
        ImportSpreadsheetText(widget:GetText(), _G.ABGP_Data2.itemValues.data, itemMapping, function(row)
            row[ABGP.ItemDataIndex.PRIORITY] = {};
            for k, v in pairs(row) do
                if itemPriorities[k] then
                    table.insert(row[ABGP.ItemDataIndex.PRIORITY], itemPriorities[k]);
                    row[k] = nil;
                end
            end
            table.sort(row[ABGP.ItemDataIndex.PRIORITY]);

            if not catMapping[row[ABGP.ItemDataIndex.CATEGORY]] then
                ABGP:Notify("Bad category %s. Canceling import!", row[ABGP.ItemDataIndex.CATEGORY]);
                return false;
            end
            row[ABGP.ItemDataIndex.CATEGORY] = catMapping[row[ABGP.ItemDataIndex.CATEGORY]];

            if row[ABGP.ItemDataIndex.GP] == "T" then
                return true;
            end

            local name = row[ABGP.ItemDataIndex.NAME];
            local item, token = name:match("^(.+) %((.+)%)$");
            if token then
                row[ABGP.ItemDataIndex.NAME] = item;
                row[ABGP.ItemDataIndex.RELATED] = token;
                row[ABGP.ItemDataIndex.NOTES] = nil;
                row[ABGP.ItemDataIndex.PRIORITY] = {};
            end

            return true;
        end);

        widget:GetUserData("window"):Hide();

        if ABGP:FixupItems() then
            ABGP:RefreshItemValues();
            ABGP:CommitItemData();
        else
            ABGP:Error("Couldn't find item links for some items! Unable to commit these updates.");
        end
    end

    OpenImportWindow(importFunc);
end

function ABGP:ExportItems()
    local _, sortedPriorities = self:GetItemPriorities();
    local function buildPrioString(prio)
        local itemPriorities = {};
        for _, pri in ipairs(prio) do itemPriorities[pri] = true; end
        local priorities = {};
        for _, pri in ipairs(sortedPriorities) do
            table.insert(priorities, itemPriorities[pri] and "TRUE" or "");
        end
        return table.concat(priorities, "\t");
    end

    local items = _G.ABGP_Data2.itemValues.data;
    local text = ("Raid\tBoss\tItem\tCategory\tGP\t%s\tNotes\n"):format(table.concat(sortedPriorities, "\t"));
    for i, item in ipairs(items) do
        if item[self.ItemDataIndex.RELATED] then
            text = text .. ("%s\t%s\t%s\t%s\t%s\t%s\n"):format(
                item[self.ItemDataIndex.RAID],
                item[self.ItemDataIndex.BOSS],
                ("%s (%s)"):format(item[self.ItemDataIndex.NAME], item[self.ItemDataIndex.RELATED]),
                item[self.ItemDataIndex.CATEGORY],
                item[self.ItemDataIndex.GP],
                buildPrioString({}),
                "",
                "\n");
        else
            text = text .. ("%s\t%s\t%s\t%s\t%s\t%s\n"):format(
                item[self.ItemDataIndex.RAID],
                item[self.ItemDataIndex.BOSS],
                item[self.ItemDataIndex.NAME],
                item[self.ItemDataIndex.CATEGORY],
                item[self.ItemDataIndex.GP],
                buildPrioString(item[self.ItemDataIndex.PRIORITY]),
                item[self.ItemDataIndex.NOTES] or "",
                "\n");
        end
    end

    self:OpenExportWindow(text);
end

function ABGP:ImportItemHistory()
    if not (_G.AtlasLoot and
            _G.AtlasLoot.ItemDB and
            _G.AtlasLoot.ItemDB.Storage and
            _G.AtlasLoot.ItemDB.Storage.AtlasLootClassic_DungeonsAndRaids) then
        self:Error("You must have AtlasLoot installed to show this window!");
        return;
    end

    self:BuildItemLookup();

    local lastRowTime = 0;
    local lastDecayTime = 0;
    local rowTimes = {};
    local importFunc = function(widget, event)
        local success = ImportSpreadsheetText(widget:GetText(), _G.ABGP_Data2.history.data, gpMapping, function(row)
            if not row[ABGP.ItemHistoryIndex.DATE] then
                -- Only print an error if the row isn't completely blank.
                local isError = false;
                for _, v in pairs(row) do
                    if v then
                        ABGP:Error("Found row without date!");
                        isError = true;
                        break;
                    end
                end
                return false, isError;
            end
            local rowDate =  row[ABGP.ItemHistoryIndex.DATE];
            rowDate = rowDate:gsub("20(%d%d)", "%1");
            local m, d, y = rowDate:match("^(%d-)/(%d-)/(%d-)$");
            if not m then
                ABGP:Error("Malformed date: %s", row[ABGP.ItemHistoryIndex.DATE]);
                return false, true;
            end
            local rowTime = time({ year = 2000 + tonumber(y), month = tonumber(m), day = tonumber(d), hour = 0, min = 0, sec = 0 });
            if rowTime < lastRowTime then
                ABGP:Error("Out of order date: %s", row[ABGP.ItemHistoryIndex.DATE]);
                return false, true;
            end
            if rowTime == lastDecayTime then
                ABGP:Error("Entry after decay on same date: %s", row[ABGP.ItemHistoryIndex.DATE]);
                return false, true;
            end

            if row[ABGP.ItemHistoryIndex.PLAYER] == "DECAY" then
                row[ABGP.ItemHistoryIndex.TYPE] = ABGP.ItemHistoryType.DECAY;
                lastDecayTime = rowTime;

                -- Set the time to the last second of the day, to give room for backdating other entries.
                rowTime = rowTime + (24 * 60 * 60) - 1;

                rowTimes[rowTime] = true;
                row[ABGP.ItemHistoryIndex.DATE] = rowTime;
                row[ABGP.ItemHistoryIndex.ID] = ("%s:%s"):format("IMPORT", rowTime);

                local gpDecay, gpFloor = ABGP:GetGPDecayInfo();
                row[ABGP.ItemHistoryIndex.VALUE] = gpDecay;
                row[ABGP.ItemHistoryIndex.FLOOR] = gpFloor;

                return true;
            else
                while rowTimes[rowTime] do rowTime = rowTime + 1; end

                if not row[ABGP.ItemHistoryIndex.PLAYER] then
                    ABGP:Error("Found row without player on %s!", row[ABGP.ItemHistoryIndex.DATE]);
                    return false, true;
                end

                row[ABGP.ItemHistoryIndex.GP] = row[ABGP.ItemHistoryIndex.GP] or 0;
                if row[ABGP.ItemHistoryIndex.GP] < 0 then
                    ABGP:Error("Found row with negative gp on %s!", row[ABGP.ItemHistoryIndex.DATE]);
                    return false, true;
                end

                rowTimes[rowTime] = true;
                row[ABGP.ItemHistoryIndex.DATE] = rowTime;
                row[ABGP.ItemHistoryIndex.ID] = ("%s:%s"):format("IMPORT", rowTime);
                local boss = row.boss;
                row.boss = nil;

                if row[ABGP.ItemHistoryIndex.ITEMID] == "Bonus GP" then
                    row[ABGP.ItemHistoryIndex.TYPE] = ABGP.ItemHistoryType.BONUS;
                    row[ABGP.ItemHistoryIndex.NOTES] = boss;
                elseif row[ABGP.ItemHistoryIndex.ITEMID] == "Reset GP" then
                    row[ABGP.ItemHistoryIndex.TYPE] = ABGP.ItemHistoryType.RESET;
                    row[ABGP.ItemHistoryIndex.NOTES] = boss;
                else
                    row[ABGP.ItemHistoryIndex.TYPE] = ABGP.ItemHistoryType.ITEM;
                end

                return ABGP:GetActivePlayer(row[ABGP.ItemHistoryIndex.PLAYER]);
            end
        end);

        if success then
            local function reverse(arr)
                local i, j = 1, #arr;
                while i < j do
                    arr[i], arr[j] = arr[j], arr[i];
                    i = i + 1;
                    j = j - 1;
                end
            end
            reverse(_G.ABGP_Data2.history.data);

            widget:GetUserData("window"):Hide();

            if ABGP:FixupHistory() then
                ABGP:CommitHistory();
            end
        end
    end

    OpenImportWindow(importFunc);
end

function ABGP:ExportItemHistory(history)
    local text = "";
    for i = #history, 1, -1 do
        local data = history[i];
        local itemId = data[self.ItemHistoryIndex.ITEMID];
        local value = self:GetItemValue(itemId);
        local itemDate = date("%m/%d/%y", data[self.ItemHistoryIndex.DATE]);

        text = text .. ("%s\t%s\t%s\t%s%s"):format(
            data[self.ItemHistoryIndex.GP], value.item, data[self.ItemHistoryIndex.PLAYER], itemDate, (i == 1 and "" or "\n"));
    end

    self:OpenExportWindow(text);
end


local lookup = {};

function ABGP:BuildItemLookup(shouldPrint)
    local succeeded = true;

    -- local mc = _G.AtlasLoot.ItemDB.Storage.AtlasLootClassic_DungeonsAndRaids.MoltenCore.items;
    -- local ony = _G.AtlasLoot.ItemDB.Storage.AtlasLootClassic_DungeonsAndRaids.Onyxia.items;
    local wb = _G.AtlasLoot.ItemDB.Storage.AtlasLootClassic_DungeonsAndRaids.WorldBosses.items;
    local bwl = _G.AtlasLoot.ItemDB.Storage.AtlasLootClassic_DungeonsAndRaids.BlackwingLair.items;
    -- local aq20 = _G.AtlasLoot.ItemDB.Storage.AtlasLootClassic_DungeonsAndRaids.TheRuinsofAhnQiraj.items;
    local aq40 = _G.AtlasLoot.ItemDB.Storage.AtlasLootClassic_DungeonsAndRaids.TheTempleofAhnQiraj.items;
    local token = _G.AtlasLoot.Data.Token;
    for _, collection in ipairs({ wb, bwl, aq40 }) do
        for _, sub in ipairs(collection) do
            if sub[1] then
                for _, item in ipairs(sub[1]) do
                    if type(item[2]) == "number" then
                        local name, link = GetItemInfo(item[2]);
                        if name then
                            lookup[name] = ABGP:ShortenLink(link);
                        else
                            succeeded = false;
                        end

                        local tokenData = token.GetTokenData(item[2]);
                        if tokenData then
                            for _, v in ipairs(tokenData) do
                                if type(v) ~= "table" then
                                    local name, link = GetItemInfo(v);
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
            end
        end
    end

    if not succeeded and shouldPrint then
        self:Notify("Failed to query some items!");
    end

    return succeeded;
end

function ABGP:FixupItems()
    self:BuildItemLookup();

    for _, entry in ipairs(_G.ABGP_Data2.itemValues.data) do
        if lookup[entry[ABGP.ItemDataIndex.NAME]] then
            entry[ABGP.ItemDataIndex.ITEMLINK] = lookup[entry[ABGP.ItemDataIndex.NAME]];
        else
            self:Notify(("FAILED TO FIND [%s]"):format(entry[ABGP.ItemDataIndex.NAME]));
            return false;
        end
    end

    self:Notify("Done fixing up items!");
    return true;
end

function ABGP:FixupHistory()
    if not self:BuildItemLookup(true) then return false; end

    for _, entry in ipairs(_G.ABGP_Data2.history.data) do
        if entry[self.ItemHistoryIndex.TYPE] == self.ItemHistoryType.ITEM and type(entry[self.ItemHistoryIndex.ITEMID]) == "string" then
            -- NOTE: The ITEMID field is still the item name at this point.
            if not lookup[entry[self.ItemHistoryIndex.ITEMID]] then
                self:Notify(("FAILED TO FIND [%s]"):format(entry[self.ItemHistoryIndex.ITEMID]));
                return false;
            end

            entry[self.ItemHistoryIndex.ITEMID] = self:GetItemId(lookup[entry[self.ItemHistoryIndex.ITEMID]]);
        end
    end

    return true;
end
