local _G = _G;
local ABGP = ABGP;

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

local function prioritySort(a, b)
	if a.ratio ~= b.ratio then
		return a.ratio > b.ratio;
	else
		return a.character < b.character;
	end
end

function ABGP:PriorityOnGuildRosterUpdate()
	self:RefreshFromOfficerNotes();
end

function ABGP:RefreshFromOfficerNotes()
	local p1 = _G.ABGP_Data["p1"].priority;
	local p3 = _G.ABGP_Data["p3"].priority;
	table.wipe(p1);
	table.wipe(p3);
	for i = 1, GetNumGuildMembers() do
		local name, rank, _, _, class, _, _, note = GetGuildRosterInfo(i);
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
						character = player,
						rank = rank,
						class = class,
						ep = p1ep,
						gp = p1gp,
						ratio = p1ep * 10 / p1gp
					});
				end
				if p3ep ~= 0 and p3gp ~= 0 then
					table.insert(p3, {
						character = player,
						rank = rank,
						class = class,
						ep = p3ep,
						gp = p3gp,
						ratio = p3ep * 10 / p3gp
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
			if data.character == player then
				data.gp = data.gp + cost;
				data.ratio = data.ep * 10 / data.gp;
				self:Notify("EPGP[%s] for %s: EP=%.3f GP=%.3f(+%d) RATIO=%.3f",
					value.phase, player, data.ep, data.gp, cost, data.ratio);
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

end
