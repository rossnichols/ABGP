local _G = _G;
local ABGP = _G.ABGP;
local AceGUI = _G.LibStub("AceGUI-3.0");

local UnitName = UnitName;
local UnitExists = UnitExists;
local IsInGroup = IsInGroup;
local GetAutoCompleteResults = GetAutoCompleteResults;
local SecondsToTime = SecondsToTime;
local AUTOCOMPLETE_FLAG_IN_GUILD = AUTOCOMPLETE_FLAG_IN_GUILD;
local AUTOCOMPLETE_FLAG_NONE = AUTOCOMPLETE_FLAG_NONE;
local date = date;
local table = table;
local ipairs = ipairs;
local pairs = pairs;
local unpack = unpack;
local select = select;
local type = type;

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
local allowedSources;
local showPrerelease = false;
local onlyUsable = false;
local onlyFaved = false;
local onlyGrouped = false;
local currentRaidGroup;

ABGP.UICommands = {
    ShowItemHistory = "ShowItemHistory",
    ShowItem = "ShowItem",
    ShowItemImpact = "ShowItemImpact",
};

local infoText = [[
<html><body>
    <h1 align="center">|cFF94E4FFABGP|r: Always Be Pulling Loot System</h1>

    <p><br/>Always Be Pulling uses a modified EPGP loot system. Unlike most EPGP systems, the GP values in ABGP are priced individually and are based on their real value and learned knowledge from 15 years of min-maxing by the community.
    </p>

    <h2><br/>How does the EPGP system work?</h2>
    <p>EPGP is a simplistic system designed to take all effort put into raiding and all gear received to generate a single value that shows your priority for loot.
    <br/>
    <br/>• Every time a player is on time for a raid, participates in progression, or is present for a boss kill (or on standby), they will gain EP (effort points).
    <br/>• Raiders gain GP (gear points) based on the piece of gear they receive. Off-spec items are valued at 0 GP.
    <br/>• Only active raiders gain EP and GP. Trials and non-raiders are still tracked for attendance, but they do not gain GP for any items they receive.
    <br/>• Every week, EP and GP values decay by a certain percentage, to value more recent gains higher than older gains.
    <br/>
    <br/>With perfect attendance, a player will earn 100 EP per week. For the weekday raid group, each raid night is worth the same amount of EP. For the weekend raid group, all 100 EP comes from the Saturday raid, except for Purple Lobsters, whose EP comes from both AQ and splits.
    <br/>
    <br/>Each item tracked by ABGP has the following info associated with it:
    <br/>• Category: Gold or Silver. GP and priority are tracked separately for each category.
    <br/>• GP Value: the amount of GP gained when the item is awarded for main-spec.
    <br/>• Priority: a list of classes/specs that will be given main-spec priority for the item.
    <br/>
    <br/>EP/GP is read as a ratio, determining priority. The person with the highest priority ratio of those requesting a given item will receive it, after evaluating their eligibility for loot and the specific item. The final decision is at the discretion of the loot distributor (the guild leader or an officer), but deviations from this procedure are rare.
    </p>

    <h2><br/>When am I eligible for loot?</h2>
    <p>Players are considered eligible for loot in the following priority order:
    <br/>• Raiders above the minimum EP threshold
    <br/>• Raiders below the minimum EP threshold
    <br/>• Trial raiders
    <br/>• Non-raiders
    </p>

    <h2><br/>What items am I eligible for?</h2>
    <p>Players are considered eligible for a given item in the following priority order:
    <br/>• Main-spec requests, when the player meets the item's class/spec priority
    <br/>• Main-spec requests, when the player does not meet that priority
    <br/>• Off-spec requests
    </p>

    <h2><br/>How is loot prioritized in splits?</h2>
    <p>In our split runs of BWL and MC (bindings), loot is prioritized first to Red and Purple Lobsters, for whom split attendance is required to obtain the max of 100 EP per week. Blue Lobsters and Lobster Alts are next in priority, followed by trial raiders and finally non-raiders.
    </p>

    <h2><br/>Is there a limit on loot I can receive?</h2>
    <p>No, there is no limit.
    </p>

    <h2><br/>Can my EP or GP decrease?</h2>
    <p>For a player, EP and GP is only awarded, never removed. However, each week, everyone's current EP and GP will decay by a flat percentage: 25% for EP, and 15% for GP. This means that a given EP or GP award has a higher impact to your current EP/GP the more recent it is. For EP, this means that more recent attendance is weighted higher, and the impact of missing a raid lessens over time. For GP, this encourages requesting items as they drop instead of waiting for a specific item, since the earlier you are awarded an item, the sooner the GP gained begins decaying.
    </p>

    <h2><br/>How is my initial priority determined?</h2>
    <p>When a player becomes a new active raider (either with an alt, or by passing their trial), their initial EP and GP are calculated using the values of the other players in the raid group, to insert them into the middle-bottom of overall priority. This system ensures that newly-active players with no item awards are not placed at the top end of priority.
    </p>

    <h2><br/>When do EP and GP gains take effect?</h2>
    <p>GP gains take effect immediately upon receiving an item. EP is updated once per week, at the end of the weekly raid reset (Monday). When EP is updated, EP and GP decay is also applied, with a one-week lag (i.e., when the current week's EP is applied, the EP and GP values from the previous week are decayed).
    </p>
</body></html>
]];

local function PopulateUI(options)
    if not activeWindow then return; end
    local container = activeWindow:GetUserData("container");
    if options.rebuild then
        container:ReleaseChildren();
        container:SetLayout("Flow");
        table.wipe(container:GetUserDataTable());
    end

    local drawFunc = activeWindow:GetUserData("drawFunc");
    drawFunc(container, options);
    ABGP:HideContextMenu();
end

local function DrawInfo(container, options)
    local rebuild = options.rebuild;
    local reason = options.reason;
    -- local preserveScroll = options.preserveScroll;
    -- local command = options.command;
    if not rebuild and reason then return; end

    if rebuild then
        container:SetFullWidth(true);
        container:SetFullHeight(true);
        container:SetLayout("Fill");

        local scroll = AceGUI:Create("ScrollFrame");
        scroll:SetLayout("Fill");
        container:AddChild(scroll);

        local html = AceGUI:Create("ABGP_SimpleHTML");
        html:SetText(infoText);
        scroll:AddChild(html);
    end
end

local function DrawPriority(container, options)
    local rebuild = options.rebuild;
    local reason = options.reason;
    local preserveScroll = options.preserveScroll;
    local command = options.command;
    if not rebuild and reason and reason ~= ABGP.RefreshReasons.ACTIVE_PLAYERS_REFRESHED then return; end

    local widths = { 35, 120, 110, 75, 75, 85, 75, 85 };
    if rebuild then
        local addedItemImpact;
        if command and command.command == ABGP.UICommands.ShowItemImpact then
            addedItemImpact = command.args;
            container:SetUserData("addedItemImpact", addedItemImpact);
        end

        container:SetLayout("ABGP_Table");
        container:SetUserData("table", { columns = { 1.0 }, rows = addedItemImpact and { 0, 0, 1.0 } or { 0, 1.0 } });

        if addedItemImpact then
            local impactLine = AceGUI:Create("SimpleGroup");
            impactLine:SetFullWidth(true);
            impactLine:SetLayout("table");
            impactLine:SetUserData("table", { columns = { 1.0, 0 } });
            container:AddChild(impactLine);

            local itemImpact = AceGUI:Create("ABGP_Header");
            itemImpact:SetFullWidth(true);

            local value = ABGP:GetItemValue(addedItemImpact);
            itemImpact:SetText(("Added %s from %s to your EPGP."):format(
                ABGP:FormatCost(value.gp, value.category),
                value.itemLink));
            impactLine:AddChild(itemImpact);

            local clearImpact = AceGUI:Create("Button");
            clearImpact:SetWidth(85);
            clearImpact:SetText("Clear");
            clearImpact:SetCallback("OnClick", function()
                PopulateUI({ rebuild = true });
            end);
            impactLine:AddChild(clearImpact);
        end

        local mainLine = AceGUI:Create("SimpleGroup");
        mainLine:SetFullWidth(true);
        mainLine:SetLayout("table");
        mainLine:SetUserData("table", { columns = { 0, 0, 1.0, 0 } });
        container:AddChild(mainLine);

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
        classSelector:SetDefaultText("Classes");
        mainLine:AddChild(classSelector);

        if IsInGroup() then
            local grouped = AceGUI:Create("CheckBox");
            grouped:SetWidth(80);
            grouped:SetLabel("Grouped");
            grouped:SetValue(onlyGrouped);
            grouped:SetCallback("OnValueChanged", function(widget, event, value)
                onlyGrouped = value;
                PopulateUI({ rebuild = false });
            end);
            mainLine:AddChild(grouped);
        else
            onlyGrouped = false;
            local spacer = AceGUI:Create("Label");
            mainLine:AddChild(spacer);
        end

        if ABGP:IsPrivileged() then
            local spacer = AceGUI:Create("Label");
            mainLine:AddChild(spacer);

            local import = AceGUI:Create("Button");
            import:SetWidth(45);
            import:SetText("I");
            import:SetCallback("OnClick", function(widget, event)
                ABGP:ImportPriority();
            end);
            mainLine:AddChild(import);
        end

        local scrollContainer = AceGUI:Create("SimpleGroup");
        scrollContainer:SetUserData("cell", { align = "fill", paddingBottom = 5 });
        scrollContainer:SetFullWidth(true);
        scrollContainer:SetFullHeight(true);
        scrollContainer:SetLayout("Flow");
        container:AddChild(scrollContainer);

        local columns = {
            { canSort = false, name = "" },
            { canSort = true, defaultAsc = true, name = "Player" },
            { canSort = true, defaultAsc = true, name = "Rank" },
            { canSort = true, defaultAsc = false, name = "EP" },
            { canSort = true, defaultAsc = false, name = ABGP:FormatCost("GP", ABGP.ItemCategory.SILVER, "%s%s") },
            { canSort = true, defaultAsc = false, name = ABGP:FormatCost("Prio", ABGP.ItemCategory.SILVER, "%s%s") },
            { canSort = true, defaultAsc = false, name = ABGP:FormatCost("GP", ABGP.ItemCategory.GOLD, "%s%s") },
            { canSort = true, defaultAsc = false, name = ABGP:FormatCost("Prio", ABGP.ItemCategory.GOLD, "%s%s") },
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
    local addedItemImpact = container:GetUserData("addedItemImpact");
    priorities:ReleaseChildren();

    local priority = ABGP.Priorities;
    local filtered = {};
    for _, data in ipairs(priority) do
        local inRaidGroup = not currentRaidGroup or ABGP:IsInRaidGroup(data, currentRaidGroup);
        local isGrouped = not onlyGrouped or UnitExists(data.player);
        if allowedClasses[data.class] and inRaidGroup and isGrouped then
            if addedItemImpact and data.player == UnitName("player") then
                data = ABGP.tCopy(data);
                local value = ABGP:GetItemValue(addedItemImpact);
                data.gp[value.category] = data.gp[value.category] + value.gp;
                data.priority[value.category] = data.ep * 10 / data.gp[value.category];
            end
            table.insert(filtered, data);
        end
    end

    local sorts = {
        -- Rank
        nil,

        -- Player
        function(a, b) return a.player < b.player, a.player == b.player; end,

        -- Rank
        function(a, b) return a.rank < b.rank, a.rank == b.rank; end,

        -- EP
        function(a, b) return a.ep < b.ep, a.ep == b.ep; end,

        -- GP[S]
        function(a, b) return a.gp[ABGP.ItemCategory.SILVER] < b.gp[ABGP.ItemCategory.SILVER], a.gp[ABGP.ItemCategory.SILVER] == b.gp[ABGP.ItemCategory.SILVER]; end,

        -- Prio[G]
        function(a, b)
            -- local lowPrioA, lowPrioB = a.ep < ABGP:GetMinEP(a.raidGroup), b.ep < ABGP:GetMinEP(b.raidGroup);
            -- if lowPrioA ~= lowPrioB then return lowPrioA; end
            return a.priority[ABGP.ItemCategory.SILVER] < b.priority[ABGP.ItemCategory.SILVER], a.priority[ABGP.ItemCategory.SILVER] == b.priority[ABGP.ItemCategory.SILVER];
        end,

        -- GP[G]
        function(a, b) return a.gp[ABGP.ItemCategory.GOLD] < b.gp[ABGP.ItemCategory.GOLD], a.gp[ABGP.ItemCategory.GOLD] == b.gp[ABGP.ItemCategory.GOLD]; end,

        -- Prio[G]
        function(a, b)
            -- local lowPrioA, lowPrioB = a.ep < ABGP:GetMinEP(a.raidGroup), b.ep < ABGP:GetMinEP(b.raidGroup);
            -- if lowPrioA ~= lowPrioB then return lowPrioA; end
            return a.priority[ABGP.ItemCategory.GOLD] < b.priority[ABGP.ItemCategory.GOLD], a.priority[ABGP.ItemCategory.GOLD] == b.priority[ABGP.ItemCategory.GOLD];
        end,
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
        local lowPrio = not data.trial and data.ep < ABGP:GetMinEP(data.raidGroup);
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
                    { text = "Cancel", notCheckable = true, fontObject = "GameFontDisableSmall" },
                });
            end
        end);

        priorities:AddChild(elt);
    end

    priorities:SetScroll(scrollValue);
end

local function DrawItems(container, options)
    local rebuild = options.rebuild;
    local reason = options.reason;
    local preserveScroll = options.preserveScroll;
    local command = options.command;
    if not rebuild and reason then return; end

    local widths = { 275, 50, 50, 1.0 };
    if rebuild then
        container:SetLayout("ABGP_Table");
        container:SetUserData("table", { columns = { 1.0 }, rows = { 0, 1.0, 0 } });

        local mainLine = AceGUI:Create("SimpleGroup");
        mainLine:SetFullWidth(true);
        mainLine:SetLayout("table");
        mainLine:SetUserData("table", { columns = { 0, 0, 0, 0, 0, 0, 1.0, 0, 0 } });
        container:AddChild(mainLine);

        local priSelector = AceGUI:Create("ABGP_Filter");
        priSelector:SetWidth(125);
        priSelector:SetValues(allowedPriorities, true, ABGP:GetItemPriorities());
        priSelector:SetCallback("OnFilterUpdated", function()
            PopulateUI({ rebuild = false });
        end);
        priSelector:SetDefaultText("Priorities");
        mainLine:AddChild(priSelector);
        container:SetUserData("priSelector", priSelector);

        local items = showPrerelease and _G.ABGP_Data2.itemValuesPrerelease.data or _G.ABGP_Data2.itemValues.data;
        local sources, sourcesSorted = {}, {};
        local lastRaid, lastBoss;
        for _, item in ipairs(items) do
            local raid = item[ABGP.ItemDataIndex.RAID];
            local boss = item[ABGP.ItemDataIndex.BOSS];
            if raid ~= lastRaid then
                local entry = raid;
                sources[entry] = ABGP:ColorizeText(entry);
                table.insert(sourcesSorted, entry);
                lastRaid = raid;
                lastBoss = nil;
            end
            if #boss == 1 and boss[1] ~= lastBoss then
                local entry = boss[1];
                sources[entry] = entry;
                table.insert(sourcesSorted, entry);
                lastBoss = boss[1];
            end
        end
        allowedSources = ABGP.tCopy(sources);

        local sourceSelector = AceGUI:Create("ABGP_Filter");
        sourceSelector:SetWidth(175);
        sourceSelector:SetValues(allowedSources, true, sources, sourcesSorted);
        sourceSelector:SetCallback("OnFilterUpdated", function()
            PopulateUI({ rebuild = false });
        end);
        sourceSelector:SetDefaultText("Source");
        mainLine:AddChild(sourceSelector);
        container:SetUserData("sourceSelector", sourceSelector);

        local search = AceGUI:Create("ABGP_EditBox");
        search:SetWidth(120);
        search:SetCallback("OnValueChanged", function(widget)
            PopulateUI({ rebuild = false });
        end);
        search:SetCallback("OnEnter", function(widget)
            _G.ShowUIPanel(_G.GameTooltip);
            _G.GameTooltip:SetOwner(widget.frame, "ANCHOR_TOPLEFT");
            _G.GameTooltip:ClearLines();
            _G.GameTooltip:AddLine("Search");
            _G.GameTooltip:AddLine("Search by item, raid, boss, or notes. Enclose your search in \"quotes\" for an exact match. All searches are case-insensitive.", 1, 1, 1, true);
            _G.GameTooltip:Show();
        end);
        search:SetCallback("OnLeave", function(widget)
            _G.GameTooltip:Hide();
        end);
        mainLine:AddChild(search);
        container:SetUserData("search", search);

        local usable = AceGUI:Create("CheckBox");
        usable:SetWidth(72);
        usable:SetLabel("Usable");
        usable:SetValue(onlyUsable);
        usable:SetCallback("OnValueChanged", function(widget, event, value)
            onlyUsable = value;
            PopulateUI({ rebuild = false });
        end);
        mainLine:AddChild(usable);

        if ABGP:CanFavoriteItems() then
            local faved = AceGUI:Create("CheckBox");
            faved:SetWidth(65);
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
            local prerelease = AceGUI:Create("CheckBox");
            prerelease:SetWidth(93);
            prerelease:SetLabel("Future");
            prerelease:SetValue(showPrerelease);
            prerelease:SetCallback("OnValueChanged", function(widget, event, value)
                showPrerelease = value;
                PopulateUI({ rebuild = true });
            end);
            mainLine:AddChild(prerelease);
        else
            local spacer = AceGUI:Create("Label");
            mainLine:AddChild(spacer);
        end

        if ABGP:IsPrivileged() then
            local spacer = AceGUI:Create("Label");
            mainLine:AddChild(spacer);

            local export = AceGUI:Create("Button");
            export:SetWidth(45);
            export:SetText("E");
            export:SetCallback("OnClick", function(widget, event)
                ABGP:ExportItems(showPrerelease);
            end);
            mainLine:AddChild(export);

            local import = AceGUI:Create("Button");
            import:SetWidth(45);
            import:SetText("I");
            import:SetCallback("OnClick", function(widget, event)
                ABGP:ImportItems(showPrerelease);
            end);
            mainLine:AddChild(import);
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
            { canSort = true, defaultAsc = false, name = "Notes" },
            { canSort = true, defaultAsc = true, name = "Priority" },
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

    local items = showPrerelease and _G.ABGP_Data2.itemValuesPrerelease.data or _G.ABGP_Data2.itemValues.data;
    local filtered = {};
    local priSelector = container:GetUserData("priSelector");
    local sourceSelector = container:GetUserData("sourceSelector");
    local search = container:GetUserData("search");
    local searchText = search:GetText():lower();

    if priSelector:ShowingAll() and sourceSelector:ShowingAll() and not onlyUsable and not onlyFaved and searchText == "" then
        for _, item in ipairs(items) do
            if not item[ABGP.ItemDataIndex.RELATED] then
                table.insert(filtered, item);
            end
        end
    else
        local exact = searchText:match("^\"(.+)\"$");
        for _, item in ipairs(items) do
            if not item[ABGP.ItemDataIndex.RELATED] then
                local allowedBySource = allowedSources[item[ABGP.ItemDataIndex.RAID]];
                if not allowedBySource then
                    for _, boss in ipairs(item[ABGP.ItemDataIndex.BOSS]) do
                        if allowedSources[boss] then
                            allowedBySource = true;
                            break;
                        end
                    end
                end
                if allowedBySource then
                    if not onlyUsable or ABGP:IsItemUsable(item[ABGP.ItemDataIndex.ITEMLINK]) then
                        if not onlyFaved or ABGP:IsItemFavorited(item[ABGP.ItemDataIndex.ITEMLINK]) then
                            local matchesSearch = false;
                            if exact then
                                if item[ABGP.ItemDataIndex.NAME]:lower() == exact or
                                    item[ABGP.ItemDataIndex.RAID]:lower() == exact or
                                    (item[ABGP.ItemDataIndex.NOTES] or ""):lower() == exact then
                                    matchesSearch = true;
                                end
                            else
                                if item[ABGP.ItemDataIndex.NAME]:lower():find(searchText, 1, true) or
                                    item[ABGP.ItemDataIndex.RAID]:lower():find(searchText, 1, true) or
                                    (item[ABGP.ItemDataIndex.NOTES] or ""):lower():find(searchText, 1, true) then
                                    matchesSearch = true;
                                end
                            end

                            if not matchesSearch then
                                for _, boss in ipairs(item[ABGP.ItemDataIndex.BOSS]) do
                                    if exact then
                                        if boss:lower() == exact then
                                            matchesSearch = true;
                                            break;
                                        end
                                    else
                                        if boss:lower():find(searchText, 1, true) then
                                            matchesSearch = true;
                                            break;
                                        end
                                    end
                                end
                            end

                            if not matchesSearch and item[ABGP.ItemDataIndex.GP] == "T" then
                                local value = ABGP:GetItemValue(item[ABGP.ItemDataIndex.NAME], showPrerelease);
                                for _, itemLink in ipairs(value.token) do
                                    local name = ABGP:GetItemName(itemLink);
                                    if exact then
                                        if name:lower() == exact then
                                            matchesSearch = true;
                                            break;
                                        end
                                    else
                                        if name:lower():find(searchText, 1, true) then
                                            matchesSearch = true;
                                            break;
                                        end
                                    end
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
    end

    table.sort(filtered, function(a, b)
        return a[ABGP.ItemDataIndex.NAME] < b[ABGP.ItemDataIndex.NAME];
    end);

    local sorts = {
        -- Item
        function(a, b) return a[ABGP.ItemDataIndex.NAME] < b[ABGP.ItemDataIndex.NAME], a[ABGP.ItemDataIndex.NAME] == b[ABGP.ItemDataIndex.NAME]; end,

        -- GP
        function(a, b)
            local acat, bcat = a[ABGP.ItemDataIndex.CATEGORY], b[ABGP.ItemDataIndex.CATEGORY];
            local acost, bcost = a[ABGP.ItemDataIndex.GP], b[ABGP.ItemDataIndex.GP];
            if acat == bcat then
                if type(acost) == "number" and type(bcost) == "number" then
                    return acost < bcost, acost == bcost;
                else
                    return type(bcost) == "number", acost == bcost;
                end
            else
                return acat == ABGP.ItemCategory.SILVER, false;
            end
        end,

        -- Notes
        function(a, b)
            local anotes, bnotes = a[ABGP.ItemDataIndex.NOTES], b[ABGP.ItemDataIndex.NOTES];
            if type(anotes) == "string" and type(bnotes) == "string" then
                return anotes < bnotes, anotes == bnotes;
            else
                return type(bnotes) == "string", anotes == bnotes;
            end
        end,

        -- Priority
        function(a, b)
            local apri, bpri = a[ABGP.ItemDataIndex.PRIORITY], b[ABGP.ItemDataIndex.PRIORITY];
            local firstDiff, lastA;
            for i, pri in ipairs(apri) do
                lastA = i;
                if bpri[i] ~= pri then
                    firstDiff = i;
                    break;
                end
            end

            if firstDiff then
                if bpri[firstDiff] then
                    return apri[firstDiff] < bpri[firstDiff], false;
                else
                    return false, false;
                end
            else
                return bpri[lastA + 1] ~= nil, bpri[lastA + 1] == nil;
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
            local related = ABGP:GetTokenItems(data[ABGP.ItemDataIndex.ITEMLINK], showPrerelease);
            if related and searchText ~= "" then
                local exact = searchText:match("^\"(.+)\"$");
                local filteredRelated = {};
                for _, itemLink in ipairs(related) do
                    local matchesSearch = false;
                    local name = ABGP:GetItemName(itemLink);
                    if exact then
                        if name:lower() == exact then matchesSearch = true; end
                    else
                        if name:lower():find(searchText, 1, true) then matchesSearch = true; end
                    end

                    if matchesSearch then
                        table.insert(filteredRelated, itemLink);
                    end
                end

                if #filteredRelated > 0 then
                    related = filteredRelated;
                end
            end
            elt:SetRelatedItems(related);
            elt:ShowBackground((count % 2) == 0);
            elt:SetCallback("OnRelatedItemClicked", function(widget, event, itemLink, button)
                if button == "RightButton" then
                    local context = {};
                    local itemName = ABGP:GetItemName(itemLink);
                    if ABGP:GetActivePlayer(UnitName("player")) and ABGP:GetDebugOpt() then
                        table.insert(context, {
                            text = "Show impact on priority",
                            func = function(self)
                                ABGP:ShowMainWindow({ command = ABGP.UICommands.ShowItemImpact, args = itemName });
                            end,
                            notCheckable = true
                        });
                    end

                    if #context > 0 then
                        table.insert(context, { text = "Cancel", notCheckable = true, fontObject = "GameFontDisableSmall" });
                        ABGP:ShowContextMenu(context);
                    end
                end
            end);
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
                    if data[ABGP.ItemDataIndex.GP] ~= "T" and ABGP:GetActivePlayer(UnitName("player")) and ABGP:GetDebugOpt() then
                        table.insert(context, {
                            text = "Show impact on priority",
                            func = function(self)
                                ABGP:ShowMainWindow({ command = ABGP.UICommands.ShowItemImpact, args = data[ABGP.ItemDataIndex.NAME] });
                            end,
                            arg1 = data,
                            notCheckable = true
                        });
                    end
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
                            text = "Edit item",
                            func = function(self, data)
                                local value = ABGP:GetItemValue(data[ABGP.ItemDataIndex.NAME], showPrerelease);
                                local priorities = {};

                                local window = AceGUI:Create("ABGP_OpaqueWindow");
                                window:SetLayout("Flow");
                                window:SetTitle(("Edit %s"):format(data[ABGP.ItemDataIndex.ITEMLINK]));
                                ABGP:OpenPopup(window);
                                window:SetCallback("OnClose", function(widget)
                                    ABGP:ClosePopup(widget);
                                    ABGP:EndWindowManagement(widget);
                                    AceGUI:Release(widget);
                                end);

                                local container = AceGUI:Create("SimpleGroup");
                                container:SetFullWidth(true);
                                container:SetLayout("Table");
                                container:SetUserData("table", { columns = { 1.0 }});
                                window:AddChild(container);

                                local costContainer = AceGUI:Create("InlineGroup");
                                costContainer:SetTitle("Cost");
                                costContainer:SetFullWidth(true);
                                costContainer:SetLayout("Table");
                                costContainer:SetUserData("table", { columns = { 1.0, 1.0 }});
                                container:AddChild(costContainer);

                                local processItemValue;

                                local cost;
                                if data[ABGP.ItemDataIndex.GP] == "T" then
                                    local desc = AceGUI:Create("ABGP_Header");
                                    desc:SetFullWidth(true);
                                    desc:SetText("Token");
                                    costContainer:AddChild(desc);
                                else
                                    cost = AceGUI:Create("ABGP_EditBox");
                                    cost:SetFullWidth(true);
                                    cost:SetValue(data[ABGP.ItemDataIndex.GP]);
                                    cost:SetCallback("OnValueChanged", function(widget, event, value)
                                        local gp, errorText = ABGP:DistribValidateCost(value);
                                        if not gp then
                                            ABGP:Error("Invalid input! %s.", errorText);
                                            return true;
                                        end
                                        cost:SetValue(gp);
                                        processItemValue();
                                    end);
                                    costContainer:AddChild(cost);
                                    ABGP:AddWidgetTooltip(cost, "Edit the GP cost of this item.");
                                end

                                local catSelector = AceGUI:Create("Dropdown");
                                catSelector:SetFullWidth(true);
                                catSelector:SetList(ABGP.ItemCategoryNames, ABGP.ItemCategoriesSorted);
                                catSelector:SetValue(data[ABGP.ItemDataIndex.CATEGORY]);
                                catSelector:SetCallback("OnValueChanged", function() processItemValue(); end);
                                costContainer:AddChild(catSelector);
                                ABGP:AddWidgetTooltip(catSelector, "Edit the GP category of this item.");

                                for _, pri in ipairs(data[ABGP.ItemDataIndex.PRIORITY]) do priorities[pri] = true; end
                                local priorityEditor = AceGUI:Create("ABGP_Filter");
                                priorityEditor:SetLabel("Priorities");
                                priorityEditor:SetFullWidth(true);
                                priorityEditor:SetValues(priorities, false, ABGP:GetItemPriorities());
                                priorityEditor:SetCallback("OnFilterUpdated", function() processItemValue(); end);
                                container:AddChild(priorityEditor);
                                ABGP:AddWidgetTooltip(priorityEditor, "Edit the class/spec priorities of this item.");

                                local notes = AceGUI:Create("ABGP_EditBox");
                                notes:SetLabel("Notes");
                                notes:SetFullWidth(true);
                                notes:SetValue(data[ABGP.ItemDataIndex.NOTES]);
                                notes:SetCallback("OnValueChanged", function(widget, event, value)
                                    if value == "" then widget:SetValue(nil); end
                                    processItemValue();
                                end);
                                container:AddChild(notes);
                                ABGP:AddWidgetTooltip(notes, "Edit the notes for this item.");

                                local tokenPrices = {};
                                if value.token then
                                    local itemsContainer = AceGUI:Create("InlineGroup");
                                    itemsContainer:SetTitle("Item Costs");
                                    itemsContainer:SetFullWidth(true);
                                    itemsContainer:SetLayout("Table");
                                    itemsContainer:SetUserData("table", { columns = { 0, 1.0, 1.0 }});
                                    container:AddChild(itemsContainer);

                                    for _, itemLink in ipairs(value.token) do
                                        local itemValue = ABGP:GetItemValue(ABGP:GetItemName(itemLink), showPrerelease);
                                        local button = AceGUI:Create("ABGP_ItemButton");
                                        button:SetItemLink(itemLink);
                                        itemsContainer:AddChild(button);

                                        local cost = AceGUI:Create("ABGP_EditBox");
                                        cost:SetFullWidth(true);
                                        cost:SetValue(itemValue.gp);
                                        cost:SetCallback("OnValueChanged", function(widget, event, value)
                                            local gp, errorText = ABGP:DistribValidateCost(value);
                                            if not gp then
                                                ABGP:Error("Invalid input! %s.", errorText);
                                                return true;
                                            end
                                            cost:SetValue(gp);
                                            processItemValue();
                                        end);
                                        itemsContainer:AddChild(cost);
                                        ABGP:AddWidgetTooltip(cost, "Edit the GP cost of this item.");

                                        local catSelector = AceGUI:Create("Dropdown");
                                        catSelector:SetFullWidth(true);
                                        catSelector:SetList(ABGP.ItemCategoryNames, ABGP.ItemCategoriesSorted);
                                        catSelector:SetValue(itemValue.category);
                                        catSelector:SetCallback("OnValueChanged", function() processItemValue(); end);
                                        itemsContainer:AddChild(catSelector);
                                        ABGP:AddWidgetTooltip(catSelector, "Edit the GP category of this item.");

                                        tokenPrices[itemLink] = { cost = cost, category = catSelector, value = itemValue };
                                    end
                                end

                                local done = AceGUI:Create("Button");
                                done:SetWidth(100);
                                done:SetText("Update");
                                done:SetUserData("cell", { align = "CENTERRIGHT" });
                                done:SetCallback("OnClick", function(widget)
                                    if cost then
                                        value.dataStore[ABGP.ItemDataIndex.GP] = cost:GetValue();
                                    end
                                    value.dataStore[ABGP.ItemDataIndex.CATEGORY] = catSelector:GetValue();
                                    value.dataStore[ABGP.ItemDataIndex.NOTES] = notes:GetValue();

                                    value.dataStore[ABGP.ItemDataIndex.PRIORITY] = {};
                                    for pri, checked in pairs(priorities) do
                                        if checked then table.insert(value.dataStore[ABGP.ItemDataIndex.PRIORITY], pri); end
                                    end
                                    table.sort(value.dataStore[ABGP.ItemDataIndex.PRIORITY]);

                                    for _, info in pairs(tokenPrices) do
                                        info.value.dataStore[ABGP.ItemDataIndex.GP] = info.cost:GetValue();
                                        info.value.dataStore[ABGP.ItemDataIndex.CATEGORY] = info.category:GetValue();
                                    end

                                    ABGP:Notify("%s has been updated!", data[ABGP.ItemDataIndex.ITEMLINK]);
                                    elt:SetData(elt.data);
                                    ABGP:CommitItemData(showPrerelease);

                                    window:Hide();
                                end);
                                container:AddChild(done);

                                container:DoLayout();
                                local height = container.frame:GetHeight() + 57;
                                ABGP:BeginWindowManagement(window, "popup", {
                                    defaultWidth = 300,
                                    defaultHeight = height,
                                });

                                processItemValue = function()
                                    local newValue = {
                                        gp = cost and cost:GetValue() or "T",
                                        category = catSelector:GetValue(),
                                        notes = notes:GetValue(),
                                        priority = {},
                                    };
                                    for pri, checked in pairs(priorities) do
                                        if checked then table.insert(newValue.priority, pri); end
                                    end
                                    table.sort(newValue.priority);
                                    local hasChange = ABGP:ItemValueIsUpdated(newValue, value);
                                    if not hasChange then
                                        for _, info in pairs(tokenPrices) do
                                            newValue = {
                                                gp = info.cost:GetValue(),
                                                category = info.category:GetValue(),
                                                priority = {},
                                            };
                                            hasChange = hasChange or ABGP:ItemValueIsUpdated(newValue, info.value);
                                            if hasChange then break; end
                                        end
                                    end
                                    done:SetDisabled(not hasChange);
                                end
                                processItemValue();
                            end,
                            arg1 = data,
                            notCheckable = true
                        });
                        if showPrerelease and ABGP:GetDebugOpt() then
                            table.insert(context, {
                                text = "Delete item",
                                func = function(self, data)
                                    for i, v in ipairs(items) do
                                        if v[ABGP.ItemDataIndex.NAME] == data[ABGP.ItemDataIndex.NAME] then
                                            ABGP:Notify("Removing item: %s", v[ABGP.ItemDataIndex.NAME]);
                                            table.remove(items, i);
                                            if v[ABGP.ItemDataIndex.GP] == "T" then
                                                while true do
                                                    local found = false;
                                                    for i, v in ipairs(items) do
                                                        if v[ABGP.ItemDataIndex.RELATED] == data[ABGP.ItemDataIndex.NAME] then
                                                            ABGP:Notify("Removing item: %s", v[ABGP.ItemDataIndex.NAME]);
                                                            found = true;
                                                            table.remove(items, i);
                                                            break;
                                                        end
                                                    end
                                                    if not found then break; end
                                                end
                                            end
                                            break;
                                        end
                                    end
                                    PopulateUI({ rebuild = false, preserveScroll = true });
                                end,
                                arg1 = data,
                                notCheckable = true
                            });
                        end
                    end
                    table.insert(context, { text = "Cancel", notCheckable = true, fontObject = "GameFontDisableSmall" });
                    ABGP:ShowContextMenu(context);
                end
            end);
            itemList:AddChild(elt);
        end
    end

    itemList:SetScroll(scrollValue);
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
        mainLine:SetUserData("table", { columns = { 0, 1.0, 0, 0 } });
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
            _G.GameTooltip:AddLine("Search");
            _G.GameTooltip:AddLine("Search by player, class, item, or date. Enclose your search in \"quotes\" for an exact match. All searches are case-insensitive.", 1, 1, 1, true);
            _G.GameTooltip:Show();
        end);
        search:SetCallback("OnLeave", function(widget)
            _G.GameTooltip:Hide();
        end);
        mainLine:AddChild(search);
        container:SetUserData("search", search);

        if ABGP:IsPrivileged() then
            local spacer = AceGUI:Create("Label");
            mainLine:AddChild(spacer);

            local export = AceGUI:Create("Button");
            export:SetWidth(45);
            export:SetText("E");
            export:SetCallback("OnClick", function(widget, event)
                local filtered = container:GetUserData("shownItemHistory");
                ABGP:ExportItemHistory(filtered);
            end);
            mainLine:AddChild(export);

            local import = AceGUI:Create("Button");
            import:SetWidth(45);
            import:SetText("I");
            import:SetCallback("OnClick", function(widget, event)
                ABGP:ImportItemHistory();
            end);
            mainLine:AddChild(import);
        end

        local scrollContainer = AceGUI:Create("SimpleGroup");
        scrollContainer:SetUserData("cell", { align = "fill", paddingBottom = 5 });
        scrollContainer:SetFullWidth(true);
        scrollContainer:SetFullHeight(true);
        scrollContainer:SetLayout("Flow");
        container:AddChild(scrollContainer);

        local columns = {
            { canSort = true, defaultAsc = true, name = "Player" },
            { canSort = true, defaultAsc = false, name = "Date" },
            { canSort = true, defaultAsc = false, name = "GP" },
            { canSort = true, defaultAsc = true, name = "Item" },
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
        container:SetUserData("itemHistory", scroll);

        local pagination = AceGUI:Create("ABGP_Paginator");
        pagination:SetFullWidth(true);
        pagination:SetCallback("OnRangeSet", function()
            PopulateUI({ rebuild = false });
        end);
        container:AddChild(pagination);
        container:SetUserData("pagination", pagination);

        container:SetUserData("sortCol", 2);
        container:SetUserData("sortAsc", false);
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
    local gpHistory = ABGP:ProcessItemHistory(_G.ABGP_Data2.history.data);
    local filtered = {};
    local exact = searchText:match("^\"(.+)\"$");
    exact = exact and exact:lower() or exact;
    for _, data in ipairs(gpHistory) do
        local value = ABGP:GetItemValue(data[ABGP.ItemHistoryIndex.ITEMID]);
        local epgp = ABGP:GetActivePlayer(data[ABGP.ItemHistoryIndex.PLAYER]);
        if value and (epgp or not currentRaidGroup) then
            if not currentRaidGroup or ABGP:IsInRaidGroup(epgp, currentRaidGroup) then
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

    local sorts = {
        -- Player
        function(a, b) return a[ABGP.ItemHistoryIndex.PLAYER] < b[ABGP.ItemHistoryIndex.PLAYER], a[ABGP.ItemHistoryIndex.PLAYER] == b[ABGP.ItemHistoryIndex.PLAYER]; end,

        -- Date
        function(a, b) return a[ABGP.ItemHistoryIndex.DATE] < b[ABGP.ItemHistoryIndex.DATE], a[ABGP.ItemHistoryIndex.DATE] == b[ABGP.ItemHistoryIndex.DATE]; end,

        -- GP
        function(a, b)
            local acat, bcat = a[ABGP.ItemHistoryIndex.CATEGORY], b[ABGP.ItemHistoryIndex.CATEGORY];
            local acost, bcost = a[ABGP.ItemHistoryIndex.GP], b[ABGP.ItemHistoryIndex.GP];
            if acat == bcat then
                if type(acost) == "number" and type(bcost) == "number" then
                    return acost < bcost, acost == bcost;
                else
                    return type(bcost) == "number", acost == bcost;
                end
            else
                return acat == ABGP.ItemCategory.SILVER, false;
            end
        end,

        -- Item
        function(a, b)
            local avalue = ABGP:GetItemValue(a[ABGP.ItemHistoryIndex.ITEMID]);
            local bvalue = ABGP:GetItemValue(b[ABGP.ItemHistoryIndex.ITEMID]);
            return avalue.item < bvalue.item, avalue.item == bvalue.item;
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

    local shownItemHistory = {};
    pagination:SetValues(#filtered, 50);
    if #filtered > 0 then
        local first, last = pagination:GetRange();
        local count = 0;
        for i = first, last do
            count = count + 1;
            local data = filtered[i];
            table.insert(shownItemHistory, data);
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
                        {
                            text = "Show item",
                            func = function(self)
                                ABGP:ShowMainWindow({ command = ABGP.UICommands.ShowItem, args = value.item });
                            end,
                            notCheckable = true
                        }
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
                    if ABGP:IsPrivileged() then
                        table.insert(context, {
                            text = "Edit entry",
                            func = function(self, arg1)
                                local window = AceGUI:Create("ABGP_OpaqueWindow");
                                window:SetLayout("Flow");
                                window:SetTitle("Edit Award");
                                ABGP:OpenPopup(window);
                                window:SetCallback("OnClose", function(widget)
                                    ABGP:ClosePopup(widget);
                                    ABGP:EndWindowManagement(widget);
                                    AceGUI:Release(widget);
                                end);

                                local container = AceGUI:Create("SimpleGroup");
                                container:SetFullWidth(true);
                                container:SetLayout("Table");
                                container:SetUserData("table", { columns = { 1.0 }});
                                window:AddChild(container);

                                local item = AceGUI:Create("ABGP_Header");
                                item:SetFullWidth(true);
                                item:SetText(value.itemLink);
                                container:AddChild(item);

                                local awarded = AceGUI:Create("ABGP_Header");
                                awarded:SetFullWidth(true);
                                local entryDate = date("%m/%d/%y", arg1[ABGP.ItemHistoryIndex.DATE]); -- https://strftime.org/
                                awarded:SetText(entryDate);
                                container:AddChild(awarded);

                                local cost, catSelector;
                                local playerEdit = AceGUI:Create("ABGP_EditBox");
                                playerEdit:SetWidth(150);
                                playerEdit:SetLabel("Player");
                                playerEdit:SetAutoCompleteSource(GetAutoCompleteResults, AUTOCOMPLETE_FLAG_IN_GUILD, AUTOCOMPLETE_FLAG_NONE);
                                playerEdit:SetValue(arg1[ABGP.ItemHistoryIndex.PLAYER]);
                                playerEdit:SetCallback("OnValueChanged", function(widget, event, value)
                                    local currentCost = { cost = cost:GetValue(), category = catSelector:GetValue() };
                                    local player, errorText = ABGP:DistribValidateRecipient(value, currentCost);
                                    if not player then
                                        ABGP:Error("Invalid input! %s.", errorText);
                                        return true;
                                    end
                                    playerEdit:SetValue(player);
                                end);
                                container:AddChild(playerEdit);
                                ABGP:AddWidgetTooltip(playerEdit, "Enter the player receiving the award.");

                                local costContainer = AceGUI:Create("InlineGroup");
                                costContainer:SetTitle("Cost");
                                costContainer:SetFullWidth(true);
                                costContainer:SetLayout("Table");
                                costContainer:SetUserData("table", { columns = { 1.0, 1.0 }});
                                container:AddChild(costContainer);

                                cost = AceGUI:Create("ABGP_EditBox");
                                cost:SetFullWidth(true);
                                cost:SetValue(arg1[ABGP.ItemHistoryIndex.GP]);
                                cost:SetCallback("OnValueChanged", function(widget, event, value)
                                    local gp, errorText = ABGP:DistribValidateCost(value, playerEdit:GetValue());
                                    if not gp then
                                        ABGP:Error("Invalid input! %s.", errorText);
                                        return true;
                                    end
                                    cost:SetValue(gp);
                                end);
                                costContainer:AddChild(cost);
                                ABGP:AddWidgetTooltip(cost, "Edit the GP cost of this award.");

                                catSelector = AceGUI:Create("Dropdown");
                                catSelector:SetFullWidth(true);
                                catSelector:SetList(ABGP.ItemCategoryNames, ABGP.ItemCategoriesSorted);
                                catSelector:SetValue(arg1[ABGP.ItemHistoryIndex.CATEGORY]);
                                costContainer:AddChild(catSelector);
                                ABGP:AddWidgetTooltip(catSelector, "Edit the GP category of this award.");

                                local done = AceGUI:Create("Button");
                                done:SetWidth(100);
                                done:SetText("Done");
                                done:SetUserData("cell", { align = "CENTERRIGHT" });
                                done:SetCallback("OnClick", function(widget, event)
                                    local player = playerEdit:GetValue();
                                    local gp = cost:GetValue();
                                    local cat = catSelector:GetValue();

                                    if player ~= arg1[ABGP.ItemHistoryIndex.PLAYER] or
                                       gp ~= arg1[ABGP.ItemHistoryIndex.GP] or
                                       cat ~= arg1[ABGP.ItemHistoryIndex.CATEGORY] then
                                        ABGP:HistoryUpdateItemAward({
                                            itemLink = value.itemLink,
                                            historyId = arg1[ABGP.ItemHistoryIndex.ID],
                                            awarded = arg1[ABGP.ItemHistoryIndex.DATE],
                                        }, player, { cost = gp, category = cat });
                                    end

                                    window:Hide();
                                end);
                                container:AddChild(done);

                                container:DoLayout();
                                ABGP:BeginWindowManagement(window, "popup", {
                                    defaultWidth = 300,
                                    defaultHeight = container.frame:GetHeight() + 57,
                                });
                            end,
                            arg1 = data,
                            notCheckable = true
                        });
                        table.insert(context, {
                            text = "Delete entry",
                            func = function(self, arg1)
                                local award = ("%s for %s"):format(
                                    ABGP:ColorizeName(arg1[ABGP.ItemHistoryIndex.PLAYER]),
                                    ABGP:FormatCost(arg1[ABGP.ItemHistoryIndex.GP], arg1[ABGP.ItemHistoryIndex.CATEGORY]));
                                _G.StaticPopup_Show("ABGP_CONFIRM_UNAWARD", value.itemLink, award, {
                                    historyId = arg1[ABGP.ItemHistoryIndex.ID],
                                    itemLink = value.itemLink,
                                });
                            end,
                            arg1 = data,
                            notCheckable = true
                        });
                    end
                    table.insert(context, { text = "Cancel", notCheckable = true, fontObject = "GameFontDisableSmall" });
                    ABGP:ShowContextMenu(context);
                end
            end);
            history:AddChild(elt);
        end
    end
    container:SetUserData("shownItemHistory", shownItemHistory);

    history:SetScroll(scrollValue);
end

local function DrawRaidHistory(container, options)
    local rebuild = options.rebuild;
    local reason = options.reason;
    local preserveScroll = options.preserveScroll;
    -- local command = options.command;
    if not rebuild and reason then return; end

    local widths = { 180, 70, 100, 50, 50, 50 };
    if rebuild then
        container:SetLayout("ABGP_Table");
        container:SetUserData("table", { columns = { 1.0 }, rows = { 1.0, 0 } });

        local scrollContainer = AceGUI:Create("SimpleGroup");
        scrollContainer:SetUserData("cell", { align = "fill", paddingBottom = 5 });
        scrollContainer:SetFullWidth(true);
        scrollContainer:SetFullHeight(true);
        scrollContainer:SetLayout("Flow");
        container:AddChild(scrollContainer);

        local columns = {
            { canSort = true, defaultAsc = true, name = "Raid" },
            { canSort = true, defaultAsc = false, name = "Date" },
            { canSort = true, defaultAsc = false, name = "Duration" },
            { canSort = true, defaultAsc = false, name = "Ticks", rightJustify = true },
            { canSort = true, defaultAsc = false, name = "Kills", rightJustify = true },
            { canSort = true, defaultAsc = false, name = "Wipes", rightJustify = true },
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
            if columns[i].rightJustify then
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
        container:SetUserData("raidList", scroll);

        local pagination = AceGUI:Create("ABGP_Paginator");
        pagination:SetFullWidth(true);
        pagination:SetCallback("OnRangeSet", function()
            PopulateUI({ rebuild = false });
        end);
        container:AddChild(pagination);
        container:SetUserData("pagination", pagination);

        container:SetUserData("sortCol", 2);
        container:SetUserData("sortAsc", false);
    end

    local raidList = container:GetUserData("raidList");
    local scrollValue = preserveScroll and raidList:GetUserData("statusTable").scrollvalue or 0;
    raidList:ReleaseChildren();

    local function guessRaidGroup(raid)
        local raidGroups = {};
        for player in pairs(raid.players) do
            local epgp = ABGP:GetActivePlayer(player);
            if epgp then
                raidGroups[epgp.raidGroup] = (raidGroups[epgp.raidGroup] or 0) + 1;
            end
        end

        local raidGroup, maxCount = nil, 0;
        for raidGroupCmp, count in pairs(raidGroups) do
            if count > maxCount then
                maxCount = count;
                raidGroup = raidGroupCmp;
            end
        end

        return raidGroup;
    end

    local raids = _G.ABGP_RaidInfo3.pastRaids;
    local filtered = {};
    for _, raid in ipairs(raids) do
        if not currentRaidGroup or guessRaidGroup(raid) == currentRaidGroup then
            local ticks, kills, wipes = ABGP:GetRaidStatistics(raid);
            table.insert(filtered, {
                raid = raid,
                name = raid.name,
                startTime = raid.startTime,
                stopTime = raid.stopTime,
                date = date("%m/%d/%y", raid.startTime),
                duration = SecondsToTime(raid.stopTime - raid.startTime, true),
                ticks = ticks,
                bossKills = kills,
                bossWipes = wipes,
            });
        end
    end

    local sorts = {
        -- Raid
        function(a, b) return a.name < b.name, a.name == b.name; end,

        -- Date
        function(a, b) return a.startTime < b.startTime, a.startTime == b.startTime; end,

        -- Duration
        function(a, b)
            local aDuration = a.stopTime - a.startTime;
            local bDuration = b.stopTime - b.startTime;
            return aDuration < bDuration, aDuration == bDuration;
        end,

        -- Ticks
        function(a, b) return a.ticks < b.ticks, a.ticks == b.ticks; end,

        -- Kills
        function(a, b) return a.bossKills < b.bossKills, a.bossKills == b.bossKills; end,

        -- Wipes
        function(a, b) return a.bossWipes < b.bossWipes, a.bossWipes == b.bossWipes; end,
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
    pagination:SetValues(#filtered, 100);
    if #filtered > 0 then
        local first, last = pagination:GetRange();
        local count = 0;
        for i = first, last do
            count = count + 1;
            local raid = filtered[i];
            local elt = AceGUI:Create("ABGP_RaidHistory");
            elt:SetFullWidth(true);
            elt:SetData(raid);
            elt:SetWidths(widths);
            elt:ShowBackground((count % 2) == 0);
            elt:SetCallback("OnClick", function(widget, event, button)
                if button == "RightButton" then
                    ABGP:ShowContextMenu({
                        {
                            text = "Export",
                            func = function(self, raid)
                                ABGP:ExportRaid(raid);
                            end,
                            arg1 = raid.raid,
                            notCheckable = true
                        },
                        {
                            text = "Manage",
                            func = function(self, raid)
                                ABGP:UpdateRaid(raid);
                            end,
                            arg1 = raid.raid,
                            notCheckable = true
                        },
                        {
                            text = "Delete",
                            func = function(self, raid)
                                ABGP:DeleteRaid(raid);
                            end,
                            arg1 = raid.raid,
                            notCheckable = true
                        },
                        { text = "Cancel", notCheckable = true, fontObject = "GameFontDisableSmall" },
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

    local entries = _G.ABGP_Data2.history.data;
    local deletedEntries = {};
    local deleteReferences = {};
    for _, entry in ipairs(entries) do
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
                entryMsg = ("%s to %s for %s"):format(
                    item, ABGP:ColorizeName(entry[ABGP.ItemHistoryIndex.PLAYER]), ABGP:FormatCost(entry[ABGP.ItemHistoryIndex.GP], entry[ABGP.ItemHistoryIndex.CATEGORY]));
            elseif entryType == ABGP.ItemHistoryType.BONUS then
                entryMsg = ("%s awarded %s"):format(
                    ABGP:ColorizeName(entry[ABGP.ItemHistoryIndex.PLAYER]), ABGP:FormatCost(entry[ABGP.ItemHistoryIndex.GP], entry[ABGP.ItemHistoryIndex.CATEGORY]));
            elseif entryType == ABGP.ItemHistoryType.DECAY then
                entryMsg = ("GP decayed by %d%%"):format(
                    entry[ABGP.ItemHistoryIndex.VALUE]);
            elseif entryType == ABGP.ItemHistoryType.RESET then
                entryMsg = ("%s reset to %s"):format(
                    ABGP:ColorizeName(entry[ABGP.ItemHistoryIndex.PLAYER]), ABGP:FormatCost(entry[ABGP.ItemHistoryIndex.GP], entry[ABGP.ItemHistoryIndex.CATEGORY]));
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
                                if ABGP:GetDebugOpt() then
                                    table.insert(context, {
                                        text = "Effective cost",
                                        func = function(self, arg1)
                                            local cost, decayCount = ABGP:GetEffectiveCost(entry[ABGP.ItemHistoryIndex.ID], entry[ABGP.ItemHistoryIndex.GP]);
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
                                ABGP:HistoryDeleteEntry(arg1);
                            end,
                            arg1 = entry,
                            notCheckable = true
                        });
                    end

                    table.insert(context, { text = "Cancel", notCheckable = true, fontObject = "GameFontDisableSmall" });
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
        version = 3,
        defaultWidth = 800,
        minWidth = 800,
        maxWidth = 850,
        defaultHeight = 600,
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
    for i, v in ipairs(ABGP.RaidGroupsSortedAll) do raidGroups[i] = v; end
    for k, v in pairs(ABGP.RaidGroupNamesAll) do raidGroupNames[k] = v; end
    table.insert(raidGroups, "ALL");
    raidGroupNames.ALL = "All";
    local groupSelector = AceGUI:Create("Dropdown");
    groupSelector:SetWidth(150);
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
        { value = "info", text = "Info", draw = DrawInfo },
        { value = "priority", text = "Priority", draw = DrawPriority },
        { value = "items", text = "Items", draw = DrawItems },
        { value = "gp", text = "Item History", draw = DrawItemHistory },
    };
    if _G.ABGP_RaidInfo3.pastRaids and #_G.ABGP_RaidInfo3.pastRaids > 0 then
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

    local tab = 2;
    if command then
        if command.command == ABGP.UICommands.ShowItemHistory then
            tab = 4;
        elseif command.command == ABGP.UICommands.ShowItem then
            tab = 3;
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

StaticPopupDialogs["ABGP_CONFIRM_UNAWARD"] = ABGP:StaticDialogTemplate(ABGP.StaticDialogTemplates.JUST_BUTTONS, {
    text = "Remove award of %s to %s?",
    button1 = "Yes",
    button2 = "No",
    OnAccept = function(self, data)
        ABGP:HistoryDeleteItemAward(data);
    end,
});
