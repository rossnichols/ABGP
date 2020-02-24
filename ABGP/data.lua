local _G = _G;
local ABGP = ABGP;
local AceGUI = _G.LibStub("AceGUI-3.0");

local GetNumGuildMembers = GetNumGuildMembers;
local GetGuildRosterInfo = GetGuildRosterInfo;
local GuildRosterSetOfficerNote = GuildRosterSetOfficerNote;
local Ambiguate = Ambiguate;
local UnitExists = UnitExists;
local UnitIsInMyGuild = UnitIsInMyGuild;
local UnitName = UnitName;
local GetServerTime = GetServerTime;
local date = date;
local ipairs = ipairs;
local table = table;
local floor = floor;
local tonumber = tonumber;

local function prioritySort(a, b)
    if a.priority ~= b.priority then
        return a.priority > b.priority;
    else
        return a.player < b.player;
    end
end

function ABGP:RefreshFromOfficerNotes()
    local p1 = self.Priorities[ABGP.Phases.p1];
    local p3 = self.Priorities[ABGP.Phases.p3];
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

    self:RefreshActivePlayers();
end

function ABGP:RebuildOfficerNotes()
    if not self:IsPrivileged() then return; end

    local count = 0;
    for i = 1, GetNumGuildMembers() do
        local name = GetGuildRosterInfo(i);
        local player = Ambiguate(name, "short");
        if self:UpdateOfficerNote(player, i, true) then
            count = count + 1;
        end
    end

    if count ~= 0 then
        self:Notify("Updated %d officer notes with the latest priority data!", count);
        self:SendComm(self.CommTypes.OFFICER_NOTES_UPDATED, {}, "GUILD");
    end
end

function ABGP:UpdateOfficerNote(player, guildIndex, suppressComms)
    if not guildIndex and not self:IsPrivileged() then return; end
    if not self:CanEditOfficerNotes() then return; end
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
    end
    GuildRosterSetOfficerNote(guildIndex, note);
    if not suppressComms then
        self:SendComm(self.CommTypes.OFFICER_NOTES_UPDATED, {}, "GUILD");
    end

    return (note ~= "");
end

function ABGP:PriorityOnGuildRosterUpdate()
    self:RefreshFromOfficerNotes();
    self:RefreshUI();
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
        local db = self.Priorities[value.phase];
        for _, data in ipairs(db) do
            if data.player == player then
                data.gp = data.gp + cost;
                data.priority = data.ep * 10 / data.gp;
                if self.Debug then
                    self:Notify("EPGP[%s] for %s: EP=%.3f GP=%.3f(+%d) PRIORITY=%.3f",
                        value.phase, player, data.ep, data.gp, cost, data.priority);
                end
                break;
            end
        end
        table.sort(db, prioritySort);
    end

    self:RefreshActivePlayers();

    if sender == UnitName("player") and UnitExists(player) and UnitIsInMyGuild(player) and not self.SkipOfficerNote then
        self:UpdateOfficerNote(player);
    end
end

function ABGP:HistoryOnItemAwarded(data, distribution, sender)
    local itemLink = data.itemLink;
    local itemName = ABGP:GetItemName(itemLink);
    local value = ABGP:GetItemValue(itemName);
    if not value then return; end

    local class;
    local epgp = ABGP:GetActivePlayer(data.player);
    if epgp and epgp[value.phase] then
        class = epgp[value.phase].class;
    end

    local d = date("%m/%d/%y", GetServerTime()); -- https://strftime.org/

    local history = _G.ABGP_Data[value.phase].gpHistory;
    table.insert(history, 1, {
        itemLink = itemLink,
        player = data.player,
        class = class,
        item = itemName,
        gp = data.cost,
        date = d,
    });

    self.CurrentPhase = value.phase;
end
