local _G = _G;
local ABGP = _G.ABGP;

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
local max = max;
local abs = abs;

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
    self:SecureHook("GuildRosterSetPublicNote", onSetPublicNote);
    self:SecureHook("GuildRosterSetOfficerNote", onSetOfficerNote);
    self:SecureHook(_G.C_GuildInfo, "SetNote", onSetNote);
end

local function PrioritySort(a, b)
    if a.priority ~= b.priority then
        return a.priority > b.priority;
    else
        return a.player < b.player;
    end
end

function ABGP:RefreshFromOfficerNotes()
    local p1Old = self.Priorities[self.Phases.p1];
    local p3Old = self.Priorities[self.Phases.p3];
    local p1 = {};
    local p3 = {};

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

    if not self.tCompare(p1Old, p1, 2) or not self.tCompare(p3Old, p3, 2) then
        self.Priorities[self.Phases.p1] = p1;
        self.Priorities[self.Phases.p3] = p3;
        self:RefreshActivePlayers();
    end
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
        return;
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
            p1ep = floor(p1.ep * 1000 + 0.5);
            p1gp = floor(p1.gp * 1000 + 0.5);
        end
        if p3 then
            p3ep = floor(p3.ep * 1000 + 0.5);
            p3gp = floor(p3.gp * 1000 + 0.5);
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
        self:LogDebug("Officer note for %s: %s (was: %s)", player, note, existingNote);
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

            if sender == UnitName("player") and not ABGP:GetDebugOpt("SkipOfficerNote") and not skipOfficerNote then
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

    local itemLink = data.itemLink;
    local itemName = ABGP:GetItemName(itemLink);
    local value = ABGP:GetItemValue(itemName);
    if not value then return; end
    local history = _G.ABGP_Data[value.phase].gpHistory;

    local newHistoryId = data.editId;
    local _, awardDate = self:ParseHistoryId(newHistoryId);
    if not awardDate then
        awardDate = GetServerTime();
    end

    if data.oldCost or data.oldPlayer then
        if data.updateId then
            newHistoryId = data.newEditId;
            table.insert(history, 1, {
                [ABGP.ItemHistoryIndex.TYPE] = ABGP.ItemHistoryType.DELETE,
                [ABGP.ItemHistoryIndex.ID] = data.updateId,
                [ABGP.ItemHistoryIndex.DELETEDID] = data.editId,
            });
        end
        for i, entry in ipairs(history) do
            if not entry[self.ItemHistoryIndex.ID] then break; end
            if entry[self.ItemHistoryIndex.ID] == data.editId then
                if data.updateId then
                    awardDate = history[i][ABGP.ItemHistoryIndex.DATE];
                else
                    table.remove(history, i);
                end

                -- If the previous award is for the same player, then the officer note will already
                -- get updated to the proper value for the new award, and writing the officer note
                -- twice for the same player with no delay will fail.
                self:SendMessage(self.InternalEvents.ITEM_DISTRIBUTION_UNAWARDED, {
                    itemLink = value.itemLink,
                    player = entry[ABGP.ItemHistoryIndex.PLAYER],
                    gp = entry[ABGP.ItemHistoryIndex.GP],
                    skipOfficerNote = (entry[self.ItemHistoryIndex.PLAYER] == data.player),
                    sender = sender,
                });
                break;
            end
        end
    end

    if data.player then
        table.insert(history, 1, {
            [ABGP.ItemHistoryIndex.TYPE] = ABGP.ItemHistoryType.ITEM,
            [ABGP.ItemHistoryIndex.ID] = newHistoryId,
            [ABGP.ItemHistoryIndex.DATE] = awardDate,
            [ABGP.ItemHistoryIndex.PLAYER] = data.player,
            [ABGP.ItemHistoryIndex.NAME] = itemName,
            [ABGP.ItemHistoryIndex.GP] = data.cost,
        });
    end

    self:RefreshUI(self.RefreshReasons.HISTORY_UPDATED);
end

function ABGP:ProcessItemHistory(gpHistory, includeBonus, includeDecay)
    local processed = {};
    local deleted = {};
    for _, data in ipairs(gpHistory) do
        if not deleted[data[ABGP.ItemHistoryIndex.ID]] then
            local entryType = data[ABGP.ItemHistoryIndex.TYPE];
            if entryType == ABGP.ItemHistoryType.ITEM then
                table.insert(processed, data);
            elseif entryType == ABGP.ItemHistoryType.BONUS and includeBonus then
                table.insert(processed, data);
            elseif entryType == ABGP.ItemHistoryType.DECAY and includeDecay then
                table.insert(processed, data);
            elseif entryType == ABGP.ItemHistoryType.DELETE then
                deleted[data[ABGP.ItemHistoryIndex.DELETEDID]] = true;
            end
        end
    end

    -- All entries in the processed table must have a DATE field.
    table.sort(processed, function(a, b)
        return a[ABGP.ItemHistoryIndex.DATE] > b[ABGP.ItemHistoryIndex.DATE];
    end);

    return processed;
end

function ABGP:CheckItemHistory()
    for phase in pairs(self.Phases) do
        local history = self:ProcessItemHistory(_G.ABGP_Data[phase].gpHistory, true, true);
        for player, epgp in pairs(self:GetActivePlayers()) do
            if epgp[phase] then
                local calculated = 0;
                for i = #history, 1, -1 do
                    local entry = history[i];
                    local entryType = entry[self.ItemHistoryIndex.TYPE];
                    if (entryType == self.ItemHistoryType.ITEM or entryType == self.ItemHistoryType.BONUS) and
                       entry[self.ItemHistoryIndex.PLAYER] == player then
                        calculated = calculated + entry[self.ItemHistoryIndex.GP];
                    elseif entryType == self.ItemHistoryType.DECAY then
                        calculated = calculated * (1 - entry[self.ItemHistoryIndex.VALUE]);
                        calculated = max(calculated, entry[self.ItemHistoryIndex.FLOOR]);
                    end
                end

                if abs(calculated - epgp[phase].gp) > 0.001 then
                    self:Error("GP for %s in %s is wrong! Expected %.3f, got %.3f.",
                        self:ColorizeName(player), self.PhaseNames[phase], epgp[phase].gp, calculated);
                end
            end
        end
    end
end

function ABGP:HistoryUpdateCost(data, cost)
    local commData = {
        itemLink = data.itemLink,
        player = data.player,
        cost = cost,
        oldCost = data.gp,
        requestType = self.RequestTypes.MANUAL,
        editId = data.editId,
        updateId = ABGP:GetHistoryId(),
        newEditId = ABGP:GetHistoryId(),
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
        updateId = ABGP:GetHistoryId(),
        newEditId = ABGP:GetHistoryId(),
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
        updateId = ABGP:GetHistoryId(),
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
