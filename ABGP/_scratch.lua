local function GetCandidatesForLootSlot(slot)
    local candidates = {};
    for i = 1, MAX_RAID_MEMBERS do
        local candidate = GetMasterLootCandidate(slot, i);
        if candidate then table.insert(candidates, candidate); end
    end

    return candidates;
end

local f = CreateFrame("Frame");
f:RegisterEvent("LOOT_OPENED");
f:RegisterEvent("LOOT_CLOSED");
f:RegisterEvent("LOOT_SLOT_CLEARED");
f:SetScript("OnEvent", function(self, event, ...)
    local method, idx = GetLootMethod();
    local isML = IsMasterLooter();
    local th = GetLootThreshold();

    if event == "LOOT_OPENED" then
        local loot = GetLootInfo();
        for i = 1, GetNumLootItems() do
            local item = loot[i];
            if item and (item.quality >= th) then
                print("Looks like " .. item.item .. " is a ML candidate");
                print(GetLootSlotLink(i):gsub("|", "||"));
                print("|cff1eff00|Hitem:1206|h[Moss Agate (BiS)]|h|r")
                print("Candidates: " .. table.concat(GetCandidatesForLootSlot(i), ","));
            end
        end
    end
end);

local activePlayers = {
    ["Nadrell"] = true,
    ["Cleaves"] = true,
    ["Oya"] = true,
    ["Esconar"] = true,
    ["Azuj"] = true,
    ["Lunamar"] = true,
    ["Xan"] = true,
    ["Shadowcraft"] = true,
    ["Coop"] = true,
    ["Bakedpancake"] = true,
    ["Solborion"] = true,
    ["Righteous"] = true,
    ["Groggy"] = true,
    ["Darknéss"] = true,
    ["Lago"] = true,
    ["Soggybottom"] = true,
    ["Jezail"] = true,
    ["Tikki"] = true,
    ["Maric"] = true,
    ["Ezekkiel"] = true,
    ["Jearom"] = true,
    ["Klisk"] = true,
    ["Carod"] = true,
    ["Marizol"] = true,
    ["Priestpimp"] = true,
    ["Starlight"] = true,
    ["Friend"] = true,
    ["Frostishot"] = true,
    ["Juicetea"] = true,
    ["Basherslice"] = true,
    ["Xane"] = true,
    ["Zomby"] = true,
    ["Tracer"] = true,
    ["Krustytop"] = true,
    ["Klue"] = true,
    ["Eevamoon"] = true,
    ["Xanido"] = true,
    ["Gyda"] = true,
};

local headers = {
    { value = "character", text = "Character", asc = false },
    { value = "rank", text = "Rank", asc = false },
    { value = "class", text = "Class", asc = false },
    { value = "role", text = "Role", asc = false },
    { value = "ep", text = "EP", asc = false },
    { value = "gp", text = "GP", asc = false },
    { value = "ratio", text = "Ratio", asc = false },
};

local pList = {
    { character = "Oya", rank = "Raider", class = "Warrior", role = "Damage", ep = 205.91, gp = 111.2365723, ratio = 18.51101702 },
    { character = "Cleaves", rank = "Closer", class = "Warrior", role = "Damage", ep = 270.09, gp = 155.7312012, ratio = 17.34312889 },
    { character = "Esconar", rank = "Raider", class = "Warrior", role = "Damage", ep = 269.21, gp = 166.2385254, ratio = 16.19408219 },
    { character = "Azuj", rank = "Raider", class = "Rogue", role = "Damage", ep = 255.03, gp = 180.302124, ratio = 14.14454306 },
    { character = "Xan", rank = "Raider", class = "Priest", role = "Damage", ep = 264.48, gp = 196.6415405, ratio = 13.44998038 },
    { character = "Coop", rank = "Raider", class = "Warrior", role = "Damage", ep = 202.18, gp = 151.9282837, ratio = 13.30787368 },
    { character = "Bakedpancake", rank = "Raider", class = "Priest", role = "Healer", ep = 256.23, gp = 214.0686035, ratio = 11.96957367 },
    { character = "Righteous", rank = "Closer", class = "Paladin", role = "Healer", ep = 267.73, gp = 258.817749, ratio = 10.34433711 },
    { character = "Solborion", rank = "Raider", class = "Hunter", role = "Damage", ep = 250.94, gp = 254.8561401, ratio = 9.846260131 },
    { character = "Lago", rank = "Raider", class = "Priest", role = "Healer", ep = 255.16, gp = 264.7650146, ratio = 9.637041648 },
    { character = "Groggy", rank = "Officer", class = "Paladin", role = "Healer", ep = 265.48, gp = 275.723877, ratio = 9.62860447 },
    { character = "Darknéss", rank = "Officer", class = "Paladin", role = "Healer", ep = 271.11, gp = 284.6466064, ratio = 9.524393028 },
    { character = "Shadowcraft", rank = "Raider", class = "Rogue", role = "Damage", ep = 141.46, gp = 149.5464478, ratio = 9.459027686 },
    { character = "Soggybottom", rank = "Closer", class = "Priest", role = "Healer", ep = 269.42, gp = 295.645752, ratio = 9.112906517 },
    { character = "Jearom", rank = "Raider", class = "Warrior", role = "Damage", ep = 224.00, gp = 285.75, ratio = 7.839020122 },
    { character = "Ezekkiel", rank = "Raider", class = "Mage", role = "Damage", ep = 264.48, gp = 352.3480225, ratio = 7.50628553 },
    { character = "Jezail", rank = "Raider", class = "Warrior", role = "Damage", ep = 271.11, gp = 381.7871094, ratio = 7.101041621 },
    { character = "Nadrell", rank = "Raider", class = "Paladin", role = "Healer", ep = 262.75, gp = 381.885376, ratio = 6.880206265 },
    { character = "Carod", rank = "Raider", class = "Mage", role = "Damage", ep = 269.42, gp = 404.4067383, ratio = 6.662085085 },
    { character = "Marizol", rank = "Raider", class = "Warlock", role = "Damage", ep = 263.79, gp = 400.1531982, ratio = 6.592330415 },
    { character = "Klisk", rank = "Closer", class = "Warrior", role = "Tank", ep = 267.10, gp = 407.4908447, ratio = 6.55465714 },
    { character = "Tikki", rank = "Closer", class = "Warrior", role = "Tank", ep = 271.11, gp = 436.0003662, ratio = 6.218082286 },
    { character = "Friend", rank = "Raider", class = "Warlock", role = "Damage", ep = 265.48, gp = 432.2955322, ratio = 6.141252815 },
    { character = "Priestpimp", rank = "Raider", class = "Priest", role = "Healer", ep = 257.54, gp = 478.2641602, ratio = 5.38483069 },
    { character = "Starlight", rank = "Officer", class = "Druid", role = "Healer", ep = 265.48, gp = 503.9831543, ratio = 5.26770812 },
    { character = "Basherslice", rank = "Raider", class = "Hunter", role = "Damage", ep = 221.36, gp = 448.2235718, ratio = 4.938550763 },
    { character = "Juicetea", rank = "Raider", class = "Rogue", role = "Damage", ep = 267.05, gp = 542.4978638, ratio = 4.922529302 },
    { character = "Frostishot", rank = "Raider", class = "Hunter", role = "Damage", ep = 214.86, gp = 518.9609375, ratio = 4.140254086 },
    { character = "Xane", rank = "Raider", class = "Mage", role = "Damage", ep = 265.27, gp = 660.791626, ratio = 4.014464308 },
    { character = "Klue", rank = "Closer", class = "Warlock", role = "Damage", ep = 266.36, gp = 667.4865723, ratio = 3.990530038 },
    { character = "Krustytop", rank = "Raider", class = "Warlock", role = "Damage", ep = 254.92, gp = 640.1257324, ratio = 3.982318895 },
    { character = "Tracer", rank = "Raider", class = "Warrior", role = "Tank", ep = 267.52, gp = 672.6855469, ratio = 3.976874932 },
    { character = "Maric", rank = "Raider", class = "Rogue", role = "Damage", ep = 270.11, gp = 691.7984009, ratio = 3.904424843 },
    { character = "Lunamar", rank = "Raider", class = "Mage", role = "Damage", ep = 263.61, gp = 689.3493652, ratio = 3.824020572 },
    { character = "Zomby", rank = "Closer", class = "Rogue", role = "Damage", ep = 263.58, gp = 799.5413208, ratio = 3.296678076 },
    { character = "Eevamoon", rank = "Raider", class = "Warlock", role = "Damage", ep = 55.31, gp = 202.5868359, ratio = 2.729949136 },
    { character = "Xanido", rank = "Raider", class = "Mage", role = "Damage", ep = 224.00, gp = 975.75, ratio = 2.295669997 },
};
table.sort(pList, function(a, b)
    if a.ratio == b.ratio then return a.character > b.character end
    return a.ratio > b.ratio;
end);

local function DrawPriority(container)
    container:SetLayout("Flow");

    local header = AceGUI:Create("SimpleGroup");
    header:SetFullWidth(true);
    header:SetLayout("Table");
    header:SetUserData("table", { columns = { 100, 60, 60, 70, 60, 60, 60 }});
    container:AddChild(header);

    for i = 1, #headers do
        local desc = AceGUI:Create("InteractiveLabel");
        desc:SetText(strupper(headers[i].text));
        desc:SetUserData("HeaderData", headers[i]);
        desc:SetCallback("OnClick", function(widget, event)
            local data = widget:GetUserData("HeaderData");
            data.asc = not data.asc;
            table.sort(pList, function(a, b)
                local value = data.value;
                if a[value] == b[value] then value = "character" end
                if data.asc then
                    return a[value] < b[value];
                end
                return a[value] > b[value];
            end);
            container:ReleaseChildren();
            DrawPriority(container);
        end);
        header:AddChild(desc);
    end

    local scrollContainer = AceGUI:Create("SimpleGroup");
    scrollContainer:SetFullWidth(true);
    scrollContainer:SetFullHeight(true);
    scrollContainer:SetLayout("Fill");
    container:AddChild(scrollContainer);

    local scroll = AceGUI:Create("ScrollFrame");
    scroll:SetLayout("List");
    scrollContainer:AddChild(scroll);

    local group = AceGUI:Create("SimpleGroup");
    group:SetFullWidth(true);
    group:SetLayout("Table");
    group:SetUserData("table", { columns = { 100, 60, 60, 70, 60, 60, 60 }});
    scroll:AddChild(group);

    group:PauseLayout();
    for i = 1, #pList do
        for j = 1, #headers do
            local desc = AceGUI:Create("Label");
            local data = pList[i][headers[j].value];
            if type(data) == "number" then data = string.format("%.1f", data) end
            desc:SetText(data);
            desc:SetFullWidth(true);
            group:AddChild(desc);
        end
    end
    group:ResumeLayout();
    group:DoLayout();
    scroll:DoLayout();
end

local function DrawEP(container)
    container:SetLayout("Flow");

    local import = AceGUI:Create("Button");
    import:SetText("Import");
    import:SetCallback("OnClick", function(widget, event)
        local window = AceGUI:Create("Window");
        window:SetTitle("Import EP");
        window:SetLayout("Fill");
        window:SetCallback("OnClose", function(widget) AceGUI:Release(widget) end);

        local edit = AceGUI:Create("MultiLineEditBox");
        edit:SetLabel("Copy the data from the ABP spreadsheet");
        edit:SetCallback("OnEnterPressed", function(widget, event)
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
                            epLine[epMapping[labels[j]]] = values[j];
                        end
                    end
                    if epLine.action == "Decay" or activePlayers[epLine.character] then
                        table.insert(ABP_EP, epLine);
                    end
                end
            end

            for player in pairs(activePlayers) do
                local ep = 0;
                for _, epLine in ipairs(ABP_EP) do
                    if epLine.character == player then
                        ep = ep + epLine.ep;
                    end
                    if epLine.action == "Decay" then
                        ep = ep * 0.75;
                    end
                end
                for _, hardCoded in ipairs(pList) do
                    if hardCoded.character == player then
                        if math.abs(ep - hardCoded.ep) > 0.01 then print(string.format("Mismatched EP for %s! Expected %f, got %f",
                            player, hardCoded.ep, ep));
                        end
                        break;
                    end
                end
            end

            window.frame:Hide();
            container:ReleaseChildren();
            DrawEP(container);
        end);
        window:AddChild(edit);
        window.frame:Raise();
        edit:SetFocus();
    end);
    container:AddChild(import);

    local export = AceGUI:Create("Button");
    export:SetText("Export");
    export:SetCallback("OnClick", function(widget, event)
        local window = AceGUI:Create("Window");
        window:SetTitle("Export EP");
        window:SetLayout("Fill");
        window:SetCallback("OnClose", function(widget) AceGUI:Release(widget) end);

        local edit = AceGUI:Create("MultiLineEditBox");
        edit:SetLabel("Export the data");

        local text = "Points Earned,Action Taken,Character,Date\n";
        for _, item in ipairs(ABP_EP) do
            text = text .. string.format("%s,%s,%s,%s\n",
                item.ep, item.action, item.character, item.date);
        end
        edit:SetText(text);
        edit.button:Enable();
        window:AddChild(edit);
        window.frame:Raise();
        edit:SetFocus();
    end);
    container:AddChild(export);

    local header = AceGUI:Create("SimpleGroup");
    header:SetFullWidth(true);
    header:SetLayout("Table");
    header:SetUserData("table", { columns = { 100, 75, 50, 1 }});
    container:AddChild(header);

    for i = 1, #epColumns do
        local desc = AceGUI:Create("Label");
        desc:SetText(strupper(epColumns[i].text));
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
    group:SetUserData("table", { columns = { 100, 75, 50, 1 }});
    scroll:AddChild(group);

    group:PauseLayout();
    for i = 1, #ABP_EP do
        for j = 1, #epColumns do
            local desc = AceGUI:Create("Label");
            local data = ABP_EP[i][epColumns[j].value];
            if type(data) == "number" then data = string.format("%.1f", data) end
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

local function DrawGP(container)
    container:SetLayout("Flow");

    local import = AceGUI:Create("Button");
    import:SetText("Import");
    import:SetCallback("OnClick", function(widget, event)
        local window = AceGUI:Create("Window");
        window:SetTitle("Import GP");
        window:SetLayout("Fill");
        window:SetCallback("OnClose", function(widget) AceGUI:Release(widget) end);

        local edit = AceGUI:Create("MultiLineEditBox");
        edit:SetLabel("Copy the data from the ABP spreadsheet");
        edit:SetCallback("OnEnterPressed", function(widget, event)
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
                            gpLine[gpMapping[labels[j]]] = values[j];
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

            for player in pairs(activePlayers) do
                local gp = 0;
                for _, gpLine in ipairs(ABP_GP) do
                    if gpLine.character == player then
                        gp = gp + gpLine.gp;
                    end
                    if gpLine.item == "Decay" then
                        gp = gp * 0.75;
                    end
                end
                for _, hardCoded in ipairs(pList) do
                    if hardCoded.character == player then
                        if math.abs(gp - hardCoded.gp) > 0.01 then print(string.format("Mismatched GP for %s! Expected %f, got %f",
                            player, hardCoded.gp, gp));
                        end
                        break;
                    end
                end
            end

            window.frame:Hide();
            container:ReleaseChildren();
            DrawGP(container);
        end);
        window:AddChild(edit);
        window.frame:Raise();
        edit:SetFocus();
    end);
    container:AddChild(import);

    local export = AceGUI:Create("Button");
    export:SetText("Export");
    export:SetCallback("OnClick", function(widget, event)
        local window = AceGUI:Create("Window");
        window:SetTitle("Export GP");
        window:SetLayout("Fill");
        window:SetCallback("OnClose", function(widget) AceGUI:Release(widget) end);

        local edit = AceGUI:Create("MultiLineEditBox");
        edit:SetLabel("Export the data");

        local text = "New Points,Item,Character,Date Won\n";
        for _, item in ipairs(ABP_GP) do
            text = text .. string.format("%s,%s,%s,%s\n",
                item.gp, item.item, item.character, item.date);
        end
        edit:SetText(text);
        edit.button:Enable();
        window:AddChild(edit);
        window.frame:Raise();
        edit:SetFocus();
    end);
    container:AddChild(export);

    local header = AceGUI:Create("SimpleGroup");
    header:SetFullWidth(true);
    header:SetLayout("Table");
    header:SetUserData("table", { columns = { 100, 75, 50, 1 }});
    container:AddChild(header);

    for i = 1, #gpColumns do
        local desc = AceGUI:Create("Label");
        desc:SetText(strupper(gpColumns[i].text));
        -- desc:SetJustifyH("CENTER");
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
    group:SetUserData("table", { columns = { 100, 75, 50, 1 }});
    scroll:AddChild(group);

    group:PauseLayout();
    for i = 1, #ABP_GP do
        for j = 1, #gpColumns do
            local desc = AceGUI:Create("Label");
            local data = ABP_GP[i][gpColumns[j].value];
            if type(data) == "number" then data = string.format("%.1f", data) end
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

name:SetCallback("OnEnterPressed", function(widget)
    AceGUI:ClearFocus();
    widget:SetText(widget:GetText():gsub("^%s*(.-)%s*$", "%1"));
    widget.editbox:SetCursorPosition(strlen(widget:GetText()));

    -- Workaround for a bug where, if the precursor-text is the same on a subsequent
    -- press of tab, the contents of the editbox will be overwritten.
    widget.editbox.at3_last_precursor = nil;
end);
name:SetCallback("OnRelease", function(widget)
    AceTab:UnregisterTabCompletion("ABGP-InstanceNames");
end);
window:AddChild(name);
AceTab:RegisterTabCompletion("ABGP-InstanceNames", nil, function(candidates, text)
    if text:sub(strlen(text)) ~= " " then
        for _, instance in pairs(instanceInfo) do
            table.insert(candidates, instance.name);
            table.insert(candidates, instance.name .. "2");
        end
    end
end, false, name.editbox);