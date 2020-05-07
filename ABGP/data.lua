local _G = _G;
local ABGP = ABGP;

local GetNumGuildMembers = GetNumGuildMembers;
local GetGuildRosterInfo = GetGuildRosterInfo;
local Ambiguate = Ambiguate;
local UnitName = UnitName;
local GetServerTime = GetServerTime;
local date = date;
local ipairs = ipairs;
local table = table;
local floor = floor;
local tonumber = tonumber;
local pairs = pairs;
local next = next;
local hooksecurefunc = hooksecurefunc;

local updatingNotes = false;

function ABGP:AddDataHooks()
    local onSetNote = function(note, name, canEdit, existing)
        if updatingNotes or not name or not canEdit or note == existing then return; end

        self:SendComm(self.CommTypes.OFFICER_NOTES_UPDATED, {}, "GUILD");
        self:SendComm(self.CommTypes.OFFICER_NOTES_UPDATED, {}, "BROADCAST");
    end;
    local onSetPublicNote = function(index, note)
        local name, _, _, _, _, _, existing = GetGuildRosterInfo(index);
        onSetNote(note, name, self:CanEditPublicNotes(), existing);
    end;
    local onSetOfficerNote = function(index, note)
        local name, _, _, _, _, _, _, existing = GetGuildRosterInfo(index);
        onSetNote(note, name, self:CanEditOfficerNotes(), existing);
    end;
    local onSetNote = function(guid, note, isPublic)
        for _, info in pairs(self:GetGuildInfo()) do
            if info[17] == guid then
                local canEdit = self[isPublic and "CanEditPublicNotes" or "CanEditOfficerNotes"](self);
                local existing = info[isPublic and 7 or 8];
                onSetNote(note, info[1], canEdit, existing);
                break;
            end
        end
    end;
    hooksecurefunc("GuildRosterSetPublicNote", onSetPublicNote);
    hooksecurefunc("GuildRosterSetOfficerNote", onSetOfficerNote);
    hooksecurefunc(_G.C_GuildInfo, "SetNote", onSetNote);
end

local function PrioritySort(a, b)
    if a.priority ~= b.priority then
        return a.priority > b.priority;
    else
        return a.player < b.player;
    end
end

function ABGP:RefreshFromOfficerNotes()
    local p1 = self.Priorities[self.Phases.p1];
    local p3 = self.Priorities[self.Phases.p3];
    table.wipe(p1);
    table.wipe(p3);

    for i = 1, GetNumGuildMembers() do
        local name, rank, _, _, _, _, publicNote, note, _, _, class = GetGuildRosterInfo(i);
        if name then
            local player = Ambiguate(name, "short");
            local proxy = self:CheckProxy(publicNote);
            if proxy then
                -- Treat the name extracted from the public note as the actual player name.
                -- The name of the guild character is the proxy for holding their data.
                player, proxy = proxy, player;
            end
            if self:IsTrial(rank) then
                local trialGroup = self:GetTrialRaidGroup(publicNote);
                table.insert(p1, {
                    player = player,
                    rank = rank,
                    class = class,
                    epRaidGroup = trialGroup,
                    gpRaidGroup = trialGroup,
                    ep = 0,
                    gp = 0,
                    priority = 0,
                    trial = true
                });
                table.insert(p3, {
                    player = player,
                    rank = rank,
                    class = class,
                    epRaidGroup = trialGroup,
                    gpRaidGroup = trialGroup,
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
                            proxy = proxy,
                            rank = rank,
                            class = class,
                            epRaidGroup = self:GetEPRaidGroup(rank),
                            gpRaidGroup = self:GetGPRaidGroup(rank, self.Phases.p1),
                            ep = p1ep,
                            gp = p1gp,
                            priority = p1ep * 10 / p1gp
                        });
                    end
                    if p3gp ~= 0 then
                        table.insert(p3, {
                            player = player,
                            proxy = proxy,
                            rank = rank,
                            class = class,
                            epRaidGroup = self:GetEPRaidGroup(rank),
                            gpRaidGroup = self:GetGPRaidGroup(rank, self.Phases.p3),
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
            if self:UpdateOfficerNote(player, i) then
                count = count + 1;
            end
        end
    end

    if count == 0 then
        self:Notify("Everything already up to date!");
    else
        self:Notify("Updated %d officer notes with the latest priority data!", count);
        self:SendComm(self.CommTypes.OFFICER_NOTES_UPDATED, {}, "GUILD");
        self:SendComm(self.CommTypes.OFFICER_NOTES_UPDATED, {}, "BROADCAST");
    end
end

function ABGP:UpdateOfficerNote(player, guildIndex)
    if not self:IsPrivileged() then return; end
    if not self:CanEditOfficerNotes() then return; end

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

    local _, rank, _, _, _, _, publicNote, existingNote = GetGuildRosterInfo(guildIndex);
    player = self:CheckProxy(publicNote) or player;

    local epgp = self:GetActivePlayer(player);
    local note = "";
    if epgp and not epgp.trial then
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

        -- Sanity check: all ranks here must be in a raid group.
        if not self:GetGPRaidGroup(rank, next(self.Phases)) then
            self:Error("%s is rank %s which is not part of a raid group!", player, rank);
            note = "";
        end
    end

    if note ~= existingNote then
        updatingNotes = true;
        _G.GuildRosterSetOfficerNote(guildIndex, note);
        self:LogVerbose("Officer note for %s: %s", player, note);
        updatingNotes = false;
    end

    return (note ~= existingNote);
end

function ABGP:PriorityOnGuildRosterUpdate()
    self:RefreshFromOfficerNotes();
end

local function UpdateEPGP(itemLink, player, cost, sender, skipOfficerNote)
    local itemName = ABGP:GetItemName(itemLink);
    local value = ABGP:GetItemValue(itemName);
    if not value then return; end

    local epgp = ABGP:GetActivePlayer(player);
    if epgp and epgp[value.phase] then
		local phaseEPGP = epgp[value.phase];
		if not epgp.trial then
			phaseEPGP.gp = phaseEPGP.gp + cost;
            phaseEPGP.priority = phaseEPGP.ep * 10 / phaseEPGP.gp;
            local proxy = epgp.proxy and ("[%s]"):format(epgp.proxy) or "";
            ABGP:LogVerbose("EPGP[%s] for %s%s: EP=%.3f GP=%.3f(+%d) PRIORITY=%.3f",
                value.phase, player, proxy, phaseEPGP.ep, phaseEPGP.gp, cost, phaseEPGP.priority);
            table.sort(ABGP.Priorities[value.phase], PrioritySort);

            ABGP:RefreshActivePlayers();

            if sender == UnitName("player") and not ABGP:GetDebug("IgnoreSelfDistributed") and not skipOfficerNote then
                -- UpdateOfficerNote expects the name of the guild member
                -- that is being updated, which is the proxy if it's set.
                ABGP:UpdateOfficerNote(epgp.proxy or player);
            end
		end
    end
end

function ABGP:PriorityOnItemAwarded(data, distribution, sender)
    if data.testItem then return; end
    if not data.player then return; end

    UpdateEPGP(data.itemLink, data.player, data.cost, sender);
end

function ABGP:PriorityOnItemUnawarded(data)
    local cost = -data.gp; -- negative because we're undoing the GP adjustment
    UpdateEPGP(data.itemLink, data.player, cost, data.sender, data.skipOfficerNote);
end

function ABGP:HistoryOnItemAwarded(data, distribution, sender)
    if data.testItem then return; end
    if sender == UnitName("player") and self:GetDebug("IgnoreSelfDistributed") then return; end

    local itemLink = data.itemLink;
    local itemName = ABGP:GetItemName(itemLink);
    local value = ABGP:GetItemValue(itemName);
    if not value then return; end

    local d = date("%m/%d/%y", GetServerTime()); -- https://strftime.org/
    local history = _G.ABGP_Data[value.phase].gpHistory;

    for i, entry in ipairs(history) do
        if not entry.editId then break; end
        if entry.editId == data.editId then
            table.remove(history, i);
            entry.skipOfficerNote = (entry.player == data.player);
            self:SendMessage(self.InternalEvents.ITEM_DISTRIBUTION_UNAWARDED, entry);
            break;
        end
    end

    if data.player then
        table.insert(history, 1, {
            itemLink = itemLink,
            player = data.player,
            item = itemName,
            gp = data.cost,
            date = d,
            sender = sender,
            editId = data.editId,
        });
    end

    self:RefreshUI(self.RefreshReasons.HISTORY_UPDATED);
end

function ABGP:HistoryUpdateCost(data, cost)
    local commData = {
        itemLink = data.itemLink,
        player = data.player,
        cost = cost,
        oldCost = data.gp,
        requestType = self.RequestTypes.MANUAL,
        editId = data.editId,
    };
    self:SendComm(self.CommTypes.ITEM_DISTRIBUTION_AWARDED, commData, "BROADCAST");
    self:HistoryOnItemAwarded(commData, nil, UnitName("player"));
    self:PriorityOnItemAwarded(commData, nil, UnitName("player"));

    commData.value = data.value;
    ABGP:AuditItemUpdate(commData);
end

function ABGP:HistoryUpdatePlayer(data, player)
    local commData = {
        itemLink = data.itemLink,
        player = player,
        oldPlayer = data.player,
        cost = data.gp,
        requestType = self.RequestTypes.MANUAL,
        editId = data.editId,
    };
    self:SendComm(self.CommTypes.ITEM_DISTRIBUTION_AWARDED, commData, "BROADCAST");
    self:HistoryOnItemAwarded(commData, nil, UnitName("player"));
    self:PriorityOnItemAwarded(commData, nil, UnitName("player"));

    commData.value = data.value;
    ABGP:AuditItemUpdate(commData);
end

function ABGP:HistoryDelete(data)
    local commData = {
        itemLink = data.itemLink,
        oldPlayer = data.player,
        cost = data.gp,
        editId = data.editId,
    };
    self:SendComm(self.CommTypes.ITEM_DISTRIBUTION_AWARDED, commData, "BROADCAST");
    self:HistoryOnItemAwarded(commData, nil, UnitName("player"));
    self:PriorityOnItemAwarded(commData, nil, UnitName("player"));

    commData.value = data.value;
    ABGP:AuditItemUpdate(commData);
end

function ABGP:TrimAuditLog(threshold)
    threshold = threshold or 0;

    _G.ABGP_ItemAuditLog = _G.ABGP_ItemAuditLog or {};
    for phase in pairs(ABGP.PhasesAll) do
        _G.ABGP_ItemAuditLog[phase] = _G.ABGP_ItemAuditLog[phase] or {};
    end

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

function ABGP:AuditItemUpdate(update)
    local time = GetServerTime();
    local value = update.value;
    table.insert(_G.ABGP_ItemAuditLog[value.phase], 1, {
        itemLink = update.itemLink,
        time = time,
        update = update,
    });
end
