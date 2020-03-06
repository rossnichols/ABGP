local _G = _G;
local ABGP = ABGP;
local AceGUI = _G.LibStub("AceGUI-3.0");

local GetNumGuildMembers = GetNumGuildMembers;
local GetGuildRosterInfo = GetGuildRosterInfo;
local GuildRosterSetOfficerNote = GuildRosterSetOfficerNote;
local Ambiguate = Ambiguate;
local UnitName = UnitName;
local GetServerTime = GetServerTime;
local date = date;
local ipairs = ipairs;
local table = table;
local floor = floor;
local tonumber = tonumber;
local select = select;
local pairs = pairs;

local function PrioritySort(a, b)
    if a.priority ~= b.priority then
        return a.priority > b.priority;
    else
        return a.player < b.player;
    end
end

function ABGP:RefreshFromOfficerNotes()
    local needsUpdate = false;
    local p1 = self.Priorities[self.Phases.p1];
    local p3 = self.Priorities[self.Phases.p3];
    table.wipe(p1);
    table.wipe(p3);

    for i = 1, GetNumGuildMembers() do
        local name, rank, _, _, _, _, _, note, _, _, class = GetGuildRosterInfo(i);
        if name then
            local player = Ambiguate(name, "short");
            local epgp = self:GetActivePlayer(player, true);
            local p1New, p3New;
            if self:IsTrial(rank) then
                table.insert(p1, {
                    player = player,
                    rank = rank,
                    class = class,
                    ep = 0,
                    gp = 0,
                    priority = 0,
                    trial = true
                });
                table.insert(p3, {
                    player = player,
                    rank = rank,
                    class = class,
                    ep = 0,
                    gp = 0,
                    priority = 0,
                    trial = true
                });
            elseif note ~= "" then
                local p1ep, p1gp, p3ep, p3gp = note:match("^(%d+)%:(%d+)%:(%d+)%:(%d+)$");
                if p1ep then
                    p1ep = tonumber(p1ep) / 1000;
                    p1gp = tonumber(p1gp) / 1000;
                    p3ep = tonumber(p3ep) / 1000;
                    p3gp = tonumber(p3gp) / 1000;

                    if p1gp ~= 0 then
                        table.insert(p1, {
                            player = player,
                            rank = rank,
                            class = class,
                            ep = p1ep,
                            gp = p1gp,
                            priority = p1ep * 10 / p1gp
                        });
                    end
                    if p3gp ~= 0 then
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
    end

    table.sort(p1, PrioritySort);
    table.sort(p3, PrioritySort);
    self:RefreshActivePlayers();
end

function ABGP:RebuildOfficerNotes()
    if not self:IsPrivileged() then return; end

    local count = 0;
    for i = 1, GetNumGuildMembers() do
        local name = GetGuildRosterInfo(i);
        if name then
            local player = Ambiguate(name, "short");
            if self:UpdateOfficerNote(player, i, true) then
                count = count + 1;
            end
        end
    end

    if count == 0 then
        self:Notify("Everything already up to date!");
    else
        self:Notify("Updated %d officer notes with the latest priority data!", count);
        self:SendComm(self.CommTypes.OFFICER_NOTES_UPDATED, {}, "GUILD");
    end
end

function ABGP:UpdateOfficerNote(player, guildIndex, suppressComms)
    if not guildIndex and not self:IsPrivileged() then return; end
    if not self:CanEditOfficerNotes() then return; end
    local epgp = self:GetActivePlayer(player, true);

    if not guildIndex then
        for i = 1, GetNumGuildMembers() do
            local name = GetGuildRosterInfo(i);
            if name and player == Ambiguate(name, "short") then
                guildIndex = i;
                break;
            end
        end
    end

    if not guildIndex then
        self:Error("Couldn't find %s in the guild!", self:ColorizeName(player));
    end

    local _, rank, _, _, _, _, _, existingNote = GetGuildRosterInfo(guildIndex);
    local note = "";
    if epgp and not self:IsTrial(rank) then
        local p1 = epgp[ABGP.Phases.p1];
        local p3 = epgp[ABGP.Phases.p3];
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
    elseif not existingNote:match("^(%d+)%:(%d+)%:(%d+)%:(%d+)$") then
        note = existingNote;
    end

    if note ~= existingNote then
        GuildRosterSetOfficerNote(guildIndex, note);
        if not suppressComms then
            self:SendComm(self.CommTypes.OFFICER_NOTES_UPDATED, {}, "GUILD");
        end
    end

    return (note ~= existingNote);
end

function ABGP:PriorityOnGuildRosterUpdate()
    self:RefreshFromOfficerNotes();
end

function ABGP:PriorityOnItemAwarded(data, distribution, sender)
    local itemLink = data.itemLink;
    local player = data.player;
    local cost = data.cost;

    local itemName = self:GetItemName(itemLink);
    local value = self:GetItemValue(itemName);
    if not value then return; end

    local epgp = self:GetActivePlayer(player);
    if epgp and epgp[value.phase] then
		local data = epgp[value.phase];
		if not data.trial then
			data.gp = data.gp + cost;
			data.priority = data.ep * 10 / data.gp;
			if self.Debug then
				self:Notify("EPGP[%s] for %s: EP=%.3f GP=%.3f(+%d) PRIORITY=%.3f",
					value.phase, player, data.ep, data.gp, cost, data.priority);
			end
            table.sort(self.Priorities[value.phase], PrioritySort);

            self:RefreshActivePlayers();

            if sender == UnitName("player") and not self.IgnoreSelfDistributed then
                -- Use player name from epgp table in case the player was an alt
                self:UpdateOfficerNote(epgp.player);
            end
		end
    end
end

function ABGP:HistoryOnItemAwarded(data, distribution, sender)
    if sender == UnitName("player") and self.IgnoreSelfDistributed then
        return;
    end

    local itemLink = data.itemLink;
    local itemName = ABGP:GetItemName(itemLink);
    local value = ABGP:GetItemValue(itemName);
    if not value then return; end

    local d = date("%m/%d/%y", GetServerTime()); -- https://strftime.org/

    local history = _G.ABGP_Data[value.phase].gpHistory;
    table.insert(history, 1, {
        itemLink = itemLink,
        player = data.player,
        item = itemName,
        gp = data.cost,
        date = d,
    });

    self:RefreshUI();
end


_G.ABGP_ItemAuditLog = {};
for phase in pairs(ABGP.Phases) do
    _G.ABGP_ItemAuditLog[phase] = {};
end

function ABGP:TrimAuditLog(threshold)
    local current = GetServerTime();
    for _, phaseLog in pairs(_G.ABGP_ItemAuditLog) do
        local i = 1;
        while i <= #phaseLog do
            local age = current - phaseLog[i].time;
            if age >= threshold then
                table.remove(phaseLog, i);
            else
                i = i + 1;
            end
        end
    end
end

function ABGP:AuditItemDistribution(item)
    local time = GetServerTime();
    local value = item.data.value;
    if value and #item.distributions > 0 then
        local players = {};
        for _, distrib in ipairs(item.distributions) do
            if not distrib.trashed then
                players[distrib.player] = true;
            end
        end
        for _, request in ipairs(item.requests) do
            if not players[request.player] then
                table.insert(_G.ABGP_ItemAuditLog[value.phase], 1, {
                    itemLink = item.itemLink,
                    time = time,
                    request = request,
                });
            end
        end
        for _, distrib in ipairs(item.distributions) do
            table.insert(_G.ABGP_ItemAuditLog[value.phase], 1, {
                itemLink = item.itemLink,
                time = time,
                distribution = distrib,
            });
        end
    end
end
