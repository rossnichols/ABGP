local _G = _G;
local ABGP = _G.ABGP;
local AceGUI = _G.LibStub("AceGUI-3.0");

local GetItemInfo = GetItemInfo;
local GuildRoster = GuildRoster;
local tContains = tContains;
local pairs = pairs;
local ipairs = ipairs;
local type = type;
local table = table;
local tonumber = tonumber;
local time = time;
local date = date;
local select = select;

local priMapping = {
    ["Player"] = "player",
    ["EP"] = "ep",
    ["Silver GP"] = "gpS",
    ["Gold GP"] = "gpG",
};

local historyMapping = {
    ["Action"] = "action",
    ["Date"] = "date",
    ["Info"] = "info",
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
for value, text in pairs(itemPriorities) do
    itemMapping[text] = value;
end
local catMapping = {
    ["Silver"] = ABGP.ItemCategory.SILVER,
    ["Gold"] = ABGP.ItemCategory.GOLD,
};
local catMappingHistory = {
    ["S"] = ABGP.ItemCategory.SILVER,
    ["G"] = ABGP.ItemCategory.GOLD,
    ["SG"] = ABGP.ItemCategory.GOLD,
};
local catMappingHistoryExport = {
    [ABGP.ItemCategory.SILVER] = "GP-S",
    [ABGP.ItemCategory.GOLD] = "GP-G",
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

function ABGP:OpenExportWindow(text, extra)
    local window = AceGUI:Create("ABGP_OpaqueWindow");
    window.frame:SetFrameStrata("DIALOG");
    window:SetTitle("Export");
    window:SetLayout("Flow");
    window:SetCallback("OnClose", function(widget) AceGUI:Release(widget); ABGP:ClosePopup(widget); end);
    ABGP:OpenPopup(window);

    if extra then
        window:AddChild(extra);
    end

    local edit = AceGUI:Create("MultiLineEditBox");
    edit:SetFullWidth(true);
    edit:SetFullHeight(true);
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

    return edit;
end

local function ImportSpreadsheetText(text, spreadsheet, mapping, filter, postProcess)
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

    local success = not postProcess or postProcess(newData);
    if success then
        table.wipe(spreadsheet);
        for k, v in pairs(newData) do spreadsheet[k] = v; end
        return true;
    else
        ABGP:Notify("Canceling import!");
        return false;
    end
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
                    local active = self.tCopy(self:GetActivePlayer(row.player) or {});
                    active.player = row.player;
                    active.ep = row.ep;
                    active.gp = { [self.ItemCategory.GOLD] = row.gpG, [self.ItemCategory.SILVER] = row.gpS };
                    table.wipe(row);
                    for k, v in pairs(active) do row[k] = v; end
                    return true;
                else
                    return false;
                end
            end);
        end

        -- Refresh the active players now that we've rebuilt the priorities table,
        -- then rebuild the officer notes from that table. For new players that didn't
        -- have the other table values, we'll rebuild again on the next GUILD_ROSTER_UPDATE.
        self:RefreshActivePlayers();
        if not self:GetDebugOpt("SkipOfficerNote") then
            self:RebuildOfficerNotes();
            GuildRoster();
        end

        widget:GetUserData("window"):Hide();
    end

    OpenImportWindow(importFunc, true);
end

function ABGP:ImportItems(prerelease)
    -- ITEMTODO: what does it mean to import when you can also import history?
    local items = {};

    if not (_G.AtlasLoot and
            _G.AtlasLoot.ItemDB and
            _G.AtlasLoot.ItemDB.Storage and
            _G.AtlasLoot.ItemDB.Storage.AtlasLootClassic_DungeonsAndRaids) then
        self:Error("You must have AtlasLoot installed to show this window!");
        return;
    end

    self:BuildItemLookup();

    local importFunc = function(widget, event)
        local success = ImportSpreadsheetText(widget:GetText(), items, itemMapping, function(row)
            row[ABGP.ItemDataIndex.PRIORITY] = {};
            for k in pairs(row) do
                if itemPriorities[k] then
                    table.insert(row[ABGP.ItemDataIndex.PRIORITY], itemPriorities[k]);
                    row[k] = nil;
                end
            end
            table.sort(row[ABGP.ItemDataIndex.PRIORITY]);

            if not catMapping[row[ABGP.ItemDataIndex.CATEGORY]] then
                ABGP:Notify("Bad category '%s' for %s.", row[ABGP.ItemDataIndex.CATEGORY], row[ABGP.ItemDataIndex.NAME]);
                return false, true;
            end
            row[ABGP.ItemDataIndex.CATEGORY] = catMapping[row[ABGP.ItemDataIndex.CATEGORY]];
            row[ABGP.ItemDataIndex.BOSS] = { (";"):split(row[ABGP.ItemDataIndex.BOSS]) };

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
        end, function(newData)
            if not ABGP:FixupItems(newData) then
                ABGP:Error("Couldn't find item links for some items!");
                return false;
            end

            return true;
        end);

        if success then
            -- ITEMTODO: now what?
        end

        widget:GetUserData("window"):Hide();
    end

    OpenImportWindow(importFunc);
end

function ABGP:ExportItems(prerelease)
    -- ITEMTODO: how to export?
    local items = {};

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

    local text = ("Raid\tBoss\tItem\tCategory\tGP\t%s\tNotes\n"):format(table.concat(sortedPriorities, "\t"));
    for _, item in ipairs(items) do
        if item[self.ItemDataIndex.RELATED] then
            text = text .. ("%s\t%s\t%s\t%s\t%s\t%s\t%s\n"):format(
                item[self.ItemDataIndex.RAID],
                table.concat(item[self.ItemDataIndex.BOSS], ";"),
                ("%s (%s)"):format(item[self.ItemDataIndex.NAME], item[self.ItemDataIndex.RELATED]),
                self.ItemCategoryNames[item[self.ItemDataIndex.CATEGORY]],
                item[self.ItemDataIndex.GP],
                buildPrioString({}),
                "");
        else
            text = text .. ("%s\t%s\t%s\t%s\t%s\t%s\t%s\n"):format(
                item[self.ItemDataIndex.RAID],
                table.concat(item[self.ItemDataIndex.BOSS], ";"),
                item[self.ItemDataIndex.NAME],
                self.ItemCategoryNames[item[self.ItemDataIndex.CATEGORY]],
                item[self.ItemDataIndex.GP],
                buildPrioString(item[self.ItemDataIndex.PRIORITY]),
                item[self.ItemDataIndex.NOTES] or "");
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
    local importFunc = function(widget, event)
        local imported = {};
        local success = ImportSpreadsheetText(widget:GetText(), imported, historyMapping, function(row)
            local rowDate =  row.date;
            rowDate = rowDate:gsub("20(%d%d)", "%1");
            local m, d, y = rowDate:match("^(%d-)/(%d-)/(%d-)$");
            if not m then
                ABGP:Error("Malformed date: %s", row.date);
                return false, true;
            end
            local rowTime = time({ year = 2000 + tonumber(y), month = tonumber(m), day = tonumber(d), hour = 0, min = 0, sec = 0 });
            if rowTime < lastRowTime then
                ABGP:Error("Out of order date: %s", row.date);
                return false, true;
            end
            if rowTime == lastDecayTime then
                ABGP:Error("Entry after decay on same date: %s", row.date);
                return false, true;
            end

            if row.action == "DECAY" then
                lastDecayTime = rowTime;
                -- Set the time to the last second of the day, to ensure it's processed as the last entry.
                rowTime = rowTime + (24 * 60 * 60) - 1;
            end

            lastRowTime = rowTime;
            row.time = rowTime;
            return true;
        end);

        if success then
            local newGPHistory = {};
            for _, entry in ipairs(imported) do
                if entry.action == "DECAY" then
                    local _, gpDecay = entry.info:match("(%d+),(%d+)");
                    table.insert(newGPHistory, {
                        [self.ItemHistoryIndex.TYPE] = self.ItemHistoryType.GPDECAY,
                        [self.ItemHistoryIndex.ID] = ("%s:%s"):format("IMPORT", entry.time),
                        [self.ItemHistoryIndex.DATE] = entry.time,
                        [self.ItemHistoryIndex.VALUE] = tonumber(gpDecay),
                        [self.ItemHistoryIndex.FLOOR] = 0,
                    });
                elseif entry.action == "GP Awards" then
                    local entryTime = entry.time;
                    for player, item, cat, gp in entry.info:gmatch("(.-):(.-):(.-):([0-9.]+)%s*") do
                        if self:GetActivePlayer(player) then
                            if item == "Reset GP" then
                                table.insert(newGPHistory, {
                                    [self.ItemHistoryIndex.TYPE] = self.ItemHistoryType.GPRESET,
                                    [self.ItemHistoryIndex.ID] = ("%s:%s"):format("IMPORT", entryTime),
                                    [self.ItemHistoryIndex.DATE] = entryTime,
                                    [self.ItemHistoryIndex.PLAYER] = player,
                                    [self.ItemHistoryIndex.GP] = tonumber(gp),
                                    [self.ItemHistoryIndex.CATEGORY] = catMappingHistory[cat],
                                });
                                entryTime = entryTime + 1;
                            elseif item == "Bonus GP" then
                                table.insert(newGPHistory, {
                                    [self.ItemHistoryIndex.TYPE] = self.ItemHistoryType.GPBONUS,
                                    [self.ItemHistoryIndex.ID] = ("%s:%s"):format("IMPORT", entryTime),
                                    [self.ItemHistoryIndex.DATE] = entryTime,
                                    [self.ItemHistoryIndex.PLAYER] = player,
                                    [self.ItemHistoryIndex.GP] = tonumber(gp),
                                    [self.ItemHistoryIndex.CATEGORY] = catMappingHistory[cat],
                                });
                                entryTime = entryTime + 1;
                            else
                                table.insert(newGPHistory, {
                                    [self.ItemHistoryIndex.TYPE] = self.ItemHistoryType.GPITEM,
                                    [self.ItemHistoryIndex.ID] = ("%s:%s"):format("IMPORT", entryTime),
                                    [self.ItemHistoryIndex.DATE] = entryTime,
                                    [self.ItemHistoryIndex.PLAYER] = player,
                                    [self.ItemHistoryIndex.GP] = tonumber(gp),
                                    [self.ItemHistoryIndex.CATEGORY] = catMappingHistory[cat],
                                    [self.ItemHistoryIndex.ITEMLINK] = item, -- Name will be converted to link later
                                    -- ITEMTODO: doesn't populate TOKENLINK
                                });
                                entryTime = entryTime + 1;
                                if cat == "SG" then
                                    -- Any "SG" awards are first processed as gold, then the same amount
                                    -- of gp is awarded as bonus silver.
                                    table.insert(newGPHistory, {
                                        [self.ItemHistoryIndex.TYPE] = self.ItemHistoryType.GPBONUS,
                                        [self.ItemHistoryIndex.ID] = ("%s:%s"):format("IMPORT", entryTime),
                                        [self.ItemHistoryIndex.DATE] = entryTime,
                                        [self.ItemHistoryIndex.PLAYER] = player,
                                        [self.ItemHistoryIndex.GP] = tonumber(gp),
                                        [self.ItemHistoryIndex.CATEGORY] = ABGP.ItemCategory.SILVER,
                                    });
                                    entryTime = entryTime + 1;
                                end
                            end
                        end
                    end
                end
            end

            widget:GetUserData("window"):Hide();

            if self:FixupHistory(newGPHistory) then
                self.reverse(newGPHistory);
                table.wipe(_G.ABGP_Data2.history.data);
                for k, v in pairs(newGPHistory) do _G.ABGP_Data2.history.data[k] = v; end
                self:CommitHistory();
            else
                self:Error("Couldn't find item links for some items! Unable to commit this data.");
            end
        end
    end

    OpenImportWindow(importFunc);
end

function ABGP:BuildItemHistoryExport(history)
    local text = "";
    for i = #history, 1, -1 do
        local data = history[i];
        local itemDate = date("%m/%d/%y", data[self.ItemHistoryIndex.DATE]);

        -- ITEMTODO: doesn't export TOKENLINK
        text = text .. ("%s\t%s\t%s\t%s\t%s\n"):format(
            data[self.ItemHistoryIndex.GP],
            catMappingHistoryExport[data[self.ItemHistoryIndex.CATEGORY]],
            self:GetItemName(data[self.ItemHistoryIndex.ITEMLINK]),
            data[self.ItemHistoryIndex.PLAYER],
            itemDate);
    end

    return text;
end

function ABGP:ExportItemHistory(history)
    local text = self:BuildItemHistoryExport(history);
    self:OpenExportWindow(text);
end


local lookup = {};

function ABGP:BuildItemLookup(shouldPrint)
    local succeeded = true;

    local mc = _G.AtlasLoot.ItemDB.Storage.AtlasLootClassic_DungeonsAndRaids.MoltenCore;
    -- local ony = _G.AtlasLoot.ItemDB.Storage.AtlasLootClassic_DungeonsAndRaids.Onyxia;
    local wb = _G.AtlasLoot.ItemDB.Storage.AtlasLootClassic_DungeonsAndRaids.WorldBosses;
    local bwl = _G.AtlasLoot.ItemDB.Storage.AtlasLootClassic_DungeonsAndRaids.BlackwingLair;
    -- local aq20 = _G.AtlasLoot.ItemDB.Storage.AtlasLootClassic_DungeonsAndRaids.TheRuinsofAhnQiraj;
    local aq40 = _G.AtlasLoot.ItemDB.Storage.AtlasLootClassic_DungeonsAndRaids.TheTempleofAhnQiraj;
    local naxx = _G.AtlasLoot.ItemDB.Storage.AtlasLootClassic_DungeonsAndRaids.Naxxramas;
    local token = _G.AtlasLoot.Data.Token;
    for _, collection in ipairs({ mc, wb, bwl, aq40, naxx }) do
        for _, sub in ipairs(collection.items) do
            if sub[1] then
                for _, item in ipairs(sub[1]) do
                    if type(item[2]) == "number" then
                        local name, link = GetItemInfo(item[2]);
                        if name then
                            lookup[name] = ABGP:ShortenLink(link);
                        else
                            succeeded = false;
                            if shouldPrint then
                                self:Notify("Failed to query %s!", item[2]);
                            end
                        end

                        local tokenData = token.GetTokenData(item[2]);
                        if tokenData and type(tokenData) == "table" then
                            for _, v in ipairs(tokenData) do
                                if type(v) == "number" and v ~= 0 then
                                    local name, link = GetItemInfo(v);
                                    if name then
                                        lookup[name] = ABGP:ShortenLink(link);
                                    else
                                        succeeded = false;
                                        if shouldPrint then
                                            self:Notify("Failed to query %s [token:%s]!", v, item[2]);
                                        end
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

function ABGP:FixupItems(items)
    self:BuildItemLookup();

    for _, entry in ipairs(items) do
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

function ABGP:FixupHistory(history)
    if not self:BuildItemLookup(true) then return false; end

    for _, entry in ipairs(history) do
        if entry[self.ItemHistoryIndex.TYPE] == self.ItemHistoryType.GPITEM and not entry[self.ItemHistoryIndex.ITEMLINK]:find("[") then
            -- NOTE: The ITEMLINK field is still the item name at this point.
            if not lookup[entry[self.ItemHistoryIndex.ITEMLINK]] then
                self:Notify(("FAILED TO FIND [%s]"):format(entry[self.ItemHistoryIndex.ITEMLINK]));
                return false;
            end

            entry[self.ItemHistoryIndex.ITEMLINK] = lookup[entry[self.ItemHistoryIndex.ITEMLINK]];
        end
    end

    self:Notify("Done fixing up history!");
    return true;
end

function ABGP:GenerateItemList()
    if not self:BuildItemLookup(true) then return false; end

    local items = {};
    local naxx = _G.AtlasLoot.ItemDB.Storage.AtlasLootClassic_DungeonsAndRaids.Naxxramas;
    local token = _G.AtlasLoot.Data.Token;
    for _, collection in ipairs({ naxx }) do
        for _, sub in ipairs(collection.items) do
            if sub[1] then
                for _, item in ipairs(sub[1]) do
                    if type(item[2]) == "number" then
                        local name, link = GetItemInfo(item[2]);
                        if name then
                            if not items[name] then
                                local itemData = {
                                    [ABGP.ItemDataIndex.NAME] = name,
                                    [ABGP.ItemDataIndex.GP] = 0,
                                    [ABGP.ItemDataIndex.ITEMLINK] = ABGP:ShortenLink(link),
                                    [ABGP.ItemDataIndex.RAID] = collection.AtlasMapID,
                                    [ABGP.ItemDataIndex.BOSS] = { sub.name },
                                    [ABGP.ItemDataIndex.PRIORITY] = {},
                                    [ABGP.ItemDataIndex.CATEGORY] = ABGP.ItemCategory.GOLD,
                                    [ABGP.ItemDataIndex.NOTES] = nil,
                                    [ABGP.ItemDataIndex.RELATED] = nil,
                                };
                                items[name] = itemData;
                            end

                            local tokenData = token.GetTokenData(item[2]);
                            if tokenData and type(tokenData) == "table" then
                                for _, v in ipairs(tokenData) do
                                    if type(v) == "number" and v ~= 0 then
                                        local tokenName, link = GetItemInfo(v);
                                        if tokenName and not items[tokenName] then
                                            items[name][ABGP.ItemDataIndex.GP] = "T";
                                            items[tokenName] = {
                                                [ABGP.ItemDataIndex.NAME] = tokenName,
                                                [ABGP.ItemDataIndex.GP] = 0,
                                                [ABGP.ItemDataIndex.ITEMLINK] = ABGP:ShortenLink(link),
                                                [ABGP.ItemDataIndex.RAID] = collection.AtlasMapID,
                                                [ABGP.ItemDataIndex.BOSS] = { sub.name },
                                                [ABGP.ItemDataIndex.PRIORITY] = {},
                                                [ABGP.ItemDataIndex.CATEGORY] = ABGP.ItemCategory.GOLD,
                                                [ABGP.ItemDataIndex.NOTES] = nil,
                                                [ABGP.ItemDataIndex.RELATED] = name,
                                            };
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    for _, item in pairs(items) do
        if not self:GetItemValue(item[ABGP.ItemDataIndex.NAME], true) then
            item[ABGP.ItemDataIndex.PRERELEASE] = true;
            self:AddHistoryEntry(self.ItemHistoryType.ITEMADD, item, true);
        end
    end

    self:UpdateHistory();
end
