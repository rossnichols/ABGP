ABGP = LibStub("AceAddon-3.0"):NewAddon("ABGP", "AceConsole-3.0");
local autoShow_DEBUG = false;
-- autoShow_DEBUG = true;

-- local AceConfig = LibStub("AceConfig-3.0")
-- AceConfig:RegisterOptionsTable("ABGP", {
--     type = "group",
--     args = {
--         show = {
--             name = "Show",
--             desc = "shows the window",
--             type = "execute",
--             func = function() ABGP:ShowWindow() end
--         },
--     },
-- }, { "abp" });
ABGP:RegisterChatCommand("abgp", function() ABGP:ShowWindow() end);

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
ABP_Priority = {};

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
ABP_EP = {};

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
ABP_GP = {};

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
ABP_ItemValues = {};

local activePlayers = {};
local function CalculateActivePlayers()
    activePlayers = {};
    for _, pri in pairs(ABP_Priority) do
        activePlayers[pri.character] = true;
    end
end

local itemValues = {};
local function CalculateItemValues()
    itemValues = {};
    for _, item in pairs(ABP_ItemValues) do
        itemValues[item.item] = item;
    end
end

local function HookTooltips()
    local function showGP(tooltip, itemLink)
        if itemLink == nil then return; end
        local itemName = GetItemInfo(itemLink);
        if itemName and itemValues[itemName] then
            tooltip:AddDoubleLine("ABP GP Value: ", itemValues[itemName].gp, 0, 1, 0, 1, 1, 1);
            tooltip:AddDoubleLine("ABP Priorities: ", table.concat(itemValues[itemName].priority, ", "), 0, 1, 0, 1, 1, 1);
        end
    end

    hooksecurefunc(GameTooltip, "SetBagItem", function(tip, bag, slot)
        showGP(tip, GetContainerItemLink(bag, slot));
    end);

    hooksecurefunc(GameTooltip, "SetLootItem", function (tip, slot)
        if LootSlotHasItem(slot) then
            showGP(tip, GetLootSlotLink(slot));
        end
    end);

    hooksecurefunc(GameTooltip, "SetLootRollItem", function (tip, slot)
        showGP(tip, GetLootRollItemLink(slot));
    end);

    hooksecurefunc(GameTooltip, "SetInventoryItem", function (tip, unit, slot)
        showGP(tip, GetInventoryItemLink(unit, slot));
    end);

    hooksecurefunc(GameTooltip, "SetTradePlayerItem", function (tip, id)
        showGP(tip, GetTradePlayerItemLink(id));
    end);

    hooksecurefunc(GameTooltip, "SetTradeTargetItem", function (tip, id)
        showGP(tip, GetTradeTargetItemLink(id));
    end);

    hooksecurefunc(GameTooltip, "SetHyperlink", function(tip, itemstring)
        local _, link = GetItemInfo(itemstring);
        showGP(tip, link);
    end);

    hooksecurefunc(GameTooltip, "SetItemByID", function(tip, itemID)
        local _, link = GetItemInfo(itemID);
        showGP(tip, link);
    end);

    hooksecurefunc(ItemRefTooltip, "SetHyperlink", function(tip, itemstring)
        local _, link = GetItemInfo(itemstring);
        showGP(tip, link);
    end);
end

local function HookLootButtons()
    for _, frame in ipairs({ LootButton1, LootButton2, LootButton3, LootButton4 }) do
        frame:HookScript("OnClick", function(self, event)
            if IsShiftKeyDown() then
                local itemLink = GetLootSlotLink(self.slot);
                -- local itemLink = GetInventoryItemLink("player", self:GetID());
                if not itemLink then return; end
                local itemName = GetItemInfo(itemLink);
                local data, channel;
                if itemName and itemValues[itemName] then
                    data = itemValues[itemName];
                    channel = "RAID_WARNING";
                else
                    data = (math.random() < 0.5)
                        and { gp = 0, priority = { "Garbage" } }
                        or { gp = 100, priority = { "Groggy's alts" } };
                    channel = "SAY";
                end

                if data.gp == 0 then
                    SendChatMessage(
                        string.format(
                            "Now distributing %s - please roll if you want this item! No GP cost, Priority: %s",
                            itemLink,
                            table.concat(data.priority, ", ")),
                        channel);
                else
                    SendChatMessage(
                        string.format(
                            "Now distributing %s - please whisper %s if you want this item! GP cost: %d, Priority: %s",
                            itemLink,
                            UnitName("player"),
                            data.gp,
                            table.concat(data.priority, ", ")),
                        channel);
                end
            end
        end);
    end
end

function ABGP:OnInitialize()
    CalculateActivePlayers();
    CalculateItemValues();
    HookTooltips();
    HookLootButtons();

    local escapeFrame = CreateFrame("Frame", "APB_EPGP_EscapeFrame", UIParent);
    if autoShow_DEBUG then
        ABGP:ShowWindow();
    else
        tinsert(UISpecialFrames, escapeFrame:GetName());
    end
end

function ABGP:ShowWindow()
    local AceGUI = LibStub("AceGUI-3.0");
    local window = AceGUI:Create("Window");
    window:SetTitle("ABP EPGP");
    window:SetWidth(650);
    window:SetHeight(400);
    window:SetLayout("Fill");
    window:SetCallback("OnClose", function(widget) AceGUI:Release(widget) end);

    local function DrawTable(container, tableName, columns, importFunc, exportFunc)
        container:SetLayout("Flow");

        if importFunc then
            local import = AceGUI:Create("Button");
            import:SetText("Import");
            import:SetCallback("OnClick", function(widget, event)
                local window = AceGUI:Create("Window");
                window:SetTitle("Import");
                window:SetLayout("Fill");
                window:SetCallback("OnClose", function(widget) AceGUI:Release(widget) end);

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
                window:SetCallback("OnClose", function(widget) AceGUI:Release(widget) end);

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
        for i = 1, #_G[tableName] do
            for j = 1, #columns do
                local desc = AceGUI:Create("Label");
                local data = _G[tableName][i][columns[j].value];
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

    local function DrawPriority(container)
        local importFunc = function(widget, event)
            ABP_Priority = {};
            local text = widget:GetText();
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
                    local priLine = {};
                    for j = 1, #values do
                        if priMapping[labels[j]] then
                            priLine[priMapping[labels[j]]] = (type(tonumber(values[j])) == "number" and tonumber(values[j]) or values[j]);
                        end
                    end
                    table.insert(ABP_Priority, priLine);
                end
            end

            CalculateActivePlayers();

            widget:GetUserData("window").frame:Hide();
            container:ReleaseChildren();
            DrawPriority(container);
        end

        local exportFunc = function()
            local text = "Character,Rank,Class,Spec,Effort Points,Gear Points,Ratio\n";
            for _, item in ipairs(ABP_EP) do
                text = text .. string.format("%s,%s,%s,%s,%s,%s,%s\n",
                    item.character, item.rank, item.class, item.role, item.ep, item.gp, item.ratio);
            end

            return text;
        end

        DrawTable(container, "ABP_Priority", priColumns, importFunc, exportFunc);
    end

    local function DrawEP(container)
        local importFunc = function(widget, event)
            ABP_EP = {};
            local text = widget:GetText();
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
                    local epLine = {};
                    for j = 1, #values do
                        if epMapping[labels[j]] then
                            epLine[epMapping[labels[j]]] = (type(tonumber(values[j])) == "number" and tonumber(values[j]) or values[j]);
                        end
                    end
                    if epLine.action == "Decay" or activePlayers[epLine.character] then
                        table.insert(ABP_EP, epLine);
                    end
                end
            end

            widget:GetUserData("window").frame:Hide();
            container:ReleaseChildren();
            DrawEP(container);
        end

        local exportFunc = function()
            local text = "Points Earned,Action Taken,Character,Date\n";
            for _, item in ipairs(ABP_EP) do
                text = text .. string.format("%s,%s,%s,%s\n",
                    item.ep, item.action, item.character, item.date);
            end

            return text;
        end

        DrawTable(container, "ABP_EP", epColumns, importFunc, exportFunc);
    end

    local function DrawGP(container)
        local importFunc = function(widget, event)
            ABP_GP = {};
            local text = widget:GetText();
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
                    local gpLine = {};
                    for j = 1, #values do
                        if gpMapping[labels[j]] then
                            gpLine[gpMapping[labels[j]]] = (type(tonumber(values[j])) == "number" and tonumber(values[j]) or values[j]);
                        end
                    end
                    if gpLine.item == "Decay" then
                        table.insert(ABP_GP, gpLine);
                    end
                    if activePlayers[gpLine.character] then
                        if gpLine.gp == "" then gpLine.gp = 0; end
                        table.insert(ABP_GP, gpLine);
                    end
                end
            end

            widget:GetUserData("window").frame:Hide();
            container:ReleaseChildren();
            DrawGP(container);
        end

        local exportFunc = function()
            local text = "New Points,Item,Character,Date Won\n";
            for _, item in ipairs(ABP_GP) do
                text = text .. string.format("%s,%s,%s,%s\n",
                    item.gp, item.item, item.character, item.date);
            end

            return text;
        end

        DrawTable(container, "ABP_GP", gpColumns, importFunc, exportFunc);
    end

    local function DrawItems(container)
        local importFunc = function(widget, event)
            ABP_ItemValues = {};
            local text = widget:GetText();
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
                    local itemLine = {};
                    for j = 1, #values do
                        if itemMapping[labels[j]] then
                            if itemClasses[itemMapping[labels[j]]] then
                                itemLine.priority = itemLine.priority or {};
                                if values[j] ~= "" then
                                    table.insert(itemLine.priority, itemClasses[itemMapping[labels[j]]]);
                                end
                            else
                                itemLine[itemMapping[labels[j]]] = (type(tonumber(values[j])) == "number" and tonumber(values[j]) or values[j]);
                            end
                        end
                    end
                    table.insert(ABP_ItemValues, itemLine);
                end
            end

            CalculateItemValues();

            widget:GetUserData("window").frame:Hide();
            container:ReleaseChildren();
            DrawItems(container);
        end

        DrawTable(container, "ABP_ItemValues", itemColumns, importFunc, nil);
    end

    local tabs = {
        { value = "priority", text = "Priority", selected = DrawPriority },
        { value = "ep", text = "Effort Points", selected = DrawEP },
        { value = "gp", text = "Gear Points", selected = DrawGP },
        { value = "items", text = "Items", selected = DrawItems },
    };

    local function SelectGroup(container, event, group)
        container:ReleaseChildren();
        for i, v in ipairs(tabs) do
            if v.value == group then
                v.selected(container);
                break;
            end
        end
    end

    local tabGroup = AceGUI:Create("TabGroup");
    tabGroup:SetTabs(tabs);
    tabGroup:SetCallback("OnGroupSelected", SelectGroup);
    tabGroup:SelectTab("priority");
    window:AddChild(tabGroup);

    APB_EPGP_EscapeFrame:SetScript("OnHide", function(self)
        window:Hide();
    end);
    APB_EPGP_EscapeFrame:Show();
end
