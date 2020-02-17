local _G = _G;
local ABGP = ABGP;
local AceGUI = LibStub("AceGUI-3.0");

local GetNumGuildMembers = GetNumGuildMembers;
local GetGuildRosterInfo = GetGuildRosterInfo;
local GuildRosterSetOfficerNote = GuildRosterSetOfficerNote;
local Ambiguate = Ambiguate;
local UnitExists = UnitExists;
local UnitIsInMyGuild = UnitIsInMyGuild;
local UnitName = UnitName;
local IsInGuild = IsInGuild;
local CreateFrame = CreateFrame;
local date = date;
local ipairs = ipairs;
local table = table;
local floor = floor;
local tonumber = tonumber;
local unpack = unpack;

local activeWindow;
local widths = { 110, 100, 70, 70, 70 };
local ignoredClasses = {};

local function prioritySort(a, b)
	if a.priority ~= b.priority then
		return a.priority > b.priority;
	else
		return a.player < b.player;
	end
end

local function PopulateUI()
    if not activeWindow then return; end
    local container = activeWindow:GetUserData("priorities");
    container:ReleaseChildren();

    local priority = _G.ABGP_Data[ABGP.CurrentPhase].priority;
    for i, data in ipairs(priority) do
        if not ignoredClasses[data.class] then
            local elt = AceGUI:Create("ABGP_Player");
            elt:SetFullWidth(true);
            elt:SetData(data);
            elt:SetWidths(widths);
            elt:ShowBackground((i % 2) == 0);
            elt:SetHeight(24);
            elt:SetTextOffset(5);
            if data.player == UnitName("player") then
                elt.frame:RequestHighlight(true);
            end

            container:AddChild(elt);
        end
    end
end

function ABGP:PriorityOnGuildRosterUpdate()
    self:RefreshFromOfficerNotes();
    PopulateUI();
end

function ABGP:RefreshFromOfficerNotes()
	local p1 = _G.ABGP_Data["p1"].priority;
	local p3 = _G.ABGP_Data["p3"].priority;
	table.wipe(p1);
	table.wipe(p3);
	for i = 1, GetNumGuildMembers() do
		local name, rank, _, _, _, _, _, note, _, _, class = GetGuildRosterInfo(i);
		local player = Ambiguate(name, "short");
		if note ~= "" then
			local p1ep, p1gp, p3ep, p3gp = note:match("^(%d+)%:(%d+)%:(%d+)%:(%d+)$");
			if p1ep then
				p1ep = tonumber(p1ep) / 1000;
				p1gp = tonumber(p1gp) / 1000;
				p3ep = tonumber(p3ep) / 1000;
				p3gp = tonumber(p3gp) / 1000;

				if p1ep ~= 0 and p1gp ~= 0 then
					table.insert(p1, {
						player = player,
						rank = rank,
						class = class,
						ep = p1ep,
						gp = p1gp,
						priority = p1ep * 10 / p1gp
					});
				end
				if p3ep ~= 0 and p3gp ~= 0 then
					table.insert(p3, {
						player = player,
						rank = rank,
						class = class,
						ep = p3ep,
						gp = p3gp,
						priority = p3ep * 10 / p3gp
					});
				end
			end
		end
	end

	table.sort(p1, prioritySort);
	table.sort(p3, prioritySort);
end

function ABGP:PriorityOnDistAwarded(data, distribution, sender)
	local itemLink = data.itemLink;
	local player = data.player;
	local cost = data.cost;

	local itemName = self:GetItemName(itemLink);
	local value = self:GetItemValue(itemName);
	if not value then return; end

	local epgp = self:GetActivePlayer(player);
	if epgp and epgp[value.phase] then
		local db = _G.ABGP_Data[value.phase].priority;
		for _, data in ipairs(db) do
			if data.player == player then
				data.gp = data.gp + cost;
				data.priority = data.ep * 10 / data.gp;
				self:Notify("EPGP[%s] for %s: EP=%.3f GP=%.3f(+%d) RATIO=%.3f",
					value.phase, player, data.ep, data.gp, cost, data.priority);
				break;
			end
		end
		table.sort(db, prioritySort);
	end

	self:RefreshActivePlayers();

	if sender == UnitName("player") and UnitExists(player) and UnitIsInMyGuild(player) then
		self:UpdateOfficerNote(player);
	end
end

function ABGP:RebuildOfficerNotes()
	if not self:IsPrivileged() then return; end

	for i = 1, GetNumGuildMembers() do
		local name = GetGuildRosterInfo(i);
		local player = Ambiguate(name, "short");
		self:UpdateOfficerNote(player, i, true);
    end

    self:SendComm(self.CommTypes.OFFICER_NOTES_UPDATED, {}, "GUILD");
end

function ABGP:UpdateOfficerNote(player, guildIndex, suppressComms)
	if not guildIndex and not self:IsPrivileged() then return; end
	local epgp = self:GetActivePlayer(player);

	if not guildIndex then
		for i = 1, GetNumGuildMembers() do
			local name = GetGuildRosterInfo(i);
			if player == Ambiguate(name, "short") then
				guildIndex = i;
				break;
			end
		end
	end

	if not guildIndex then
		self:Error("Couldn't find %s in the guild!", self:ColorizeName(player));
	end

	local note = "";
	if epgp then
		local p1 = epgp["p1"];
		local p3 = epgp["p3"];
		local p1ep, p1gp, p3ep, p3gp = 0, 0, 0, 0;
		if p1 then
			p1ep = floor(p1.ep * 1000);
			p1gp = floor(p1.gp * 1000);
		end
		if p3 then
			p3ep = floor(p3.ep * 1000);
			p3gp = floor(p3.gp * 1000);
		end
		note = ("%d:%d:%d:%d"):format(p1ep, p1gp, p3ep, p3gp);
	end
    GuildRosterSetOfficerNote(guildIndex, note);
    if not suppressComms then
        self:SendComm(self.CommTypes.OFFICER_NOTES_UPDATED, {}, "GUILD");
    end
end

function ABGP:ShowPriority()
    if activeWindow then return; end

    local window = AceGUI:Create("Window");
    window:SetTitle("ABGP Player Priority");
    window:SetLayout("Flow");
    window:SetWidth(500);
    window:SetHeight(600);
    local oldMinW, oldMinH = window.frame:GetMinResize();
    local oldMaxW, oldMaxH = window.frame:GetMaxResize();
    window.frame:SetMinResize(500, 300);
    window.frame:SetMaxResize(500, 750);
    window:SetCallback("OnClose", function(widget)
        widget.frame:SetMinResize(oldMinW, oldMinH);
        widget.frame:SetMaxResize(oldMaxW, oldMaxH);
        AceGUI:Release(widget);
        ABGP:CloseWindow(widget);
        activeWindow = nil;
    end);
    ABGP:OpenWindow(window);

    local phaseSelector = AceGUI:Create("Dropdown");
    phaseSelector:SetWidth(110);
    phaseSelector:SetList(ABGP.Phases);
    phaseSelector:SetValue(ABGP.CurrentPhase);
    phaseSelector:SetCallback("OnValueChanged", function(widget, event, value)
        ABGP.CurrentPhase = value;
        PopulateUI();
    end);
    window:AddChild(phaseSelector);

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
    }, classes);
    classSelector:SetMultiselect(true);
    for _, class in ipairs(classes) do
        classSelector:SetItemValue(class, not ignoredClasses[class]);
    end
    classSelector:SetCallback("OnValueChanged", function(widget, event, class, checked)
        ignoredClasses[class] = not checked;
        PopulateUI();
    end);
    classSelector:SetText("Classes");
    window:AddChild(classSelector);

    local scrollContainer = AceGUI:Create("InlineGroup");
    scrollContainer:SetFullWidth(true);
    scrollContainer:SetFullHeight(true);
    scrollContainer:SetLayout("Flow");
    window:AddChild(scrollContainer);

    local columns = { "Player", "Rank", "EP", "GP", "Priority", weights = { unpack(widths) } };
    local header = AceGUI:Create("SimpleGroup");
    header:SetFullWidth(true);
    header:SetLayout("Table");
    header:SetUserData("table", { columns = columns.weights });
    scrollContainer:AddChild(header);

    for i = 1, #columns do
        local desc = AceGUI:Create("Label");
        desc:SetText(columns[i] .. "\n");
        desc:SetFontObject(_G.GameFontHighlight);
        header:AddChild(desc);
    end

    local scroll = AceGUI:Create("ScrollFrame");
    scroll:SetFullWidth(true);
    scroll:SetFullHeight(true);
    scroll:SetLayout("List");
    scrollContainer:AddChild(scroll);
    window:SetUserData("priorities", scroll);

    activeWindow = window;
    PopulateUI();
end
