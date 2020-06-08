local _G = _G;
local ABGP = _G.ABGP;
local LibQuestieSerializer = _G.LibStub("LibQuestieSerializer");

local GetNumGuildMembers = GetNumGuildMembers;
local GetGuildRosterInfo = GetGuildRosterInfo;
local Ambiguate = Ambiguate;
local UnitName = UnitName;
local GetServerTime = GetServerTime;
local GetTime = GetTime;
local InCombatLockdown = InCombatLockdown;
local date = date;
local ipairs = ipairs;
local table = table;
local floor = floor;
local tonumber = tonumber;
local pairs = pairs;
local next = next;
local max = max;
local abs = abs;
local type = type;
local bit = bit;
local unpack = unpack;

local updatingNotes = false;
local checkedHistory = false;
local hasCompleteCached = false;
local hasComplete = false;
local hasActivePlayers = false;
local requestedHistoryToken;
local requestedHistoryEntries = {};
local warnedOutOfDate = {};
local invalidBaseline = -1;
local syncThreshold = 10 * 24 * 60 * 60;

function ABGP:AddDataHooks()
    local onSetNote = function(note, name, canEdit, existing, isPublic)
        if updatingNotes or not name or not canEdit or note == existing then return; end

        local player = Ambiguate(name, "short");
        local info = self:GetGuildInfo(player);
        info[isPublic and 7 or 8] = note;

        self:SendComm(self.CommTypes.GUILD_NOTES_UPDATED, {}, "GUILD");
        self:SendComm(self.CommTypes.GUILD_NOTES_UPDATED, {}, "BROADCAST");
    end;
    local onSetPublicNote = function(index, note)
        local name, _, _, _, _, _, existing = GetGuildRosterInfo(index);
        onSetNote(note, name, self:CanEditPublicNotes(), existing, true);
    end;
    local onSetOfficerNote = function(index, note)
        local name, _, _, _, _, _, _, existing = GetGuildRosterInfo(index);
        onSetNote(note, name, self:CanEditOfficerNotes(), existing, false);
    end;
    local onSetNote = function(guid, note, isPublic)
        for _, info in pairs(self:GetGuildInfo()) do
            if info[17] == guid then
                local canEdit = self[isPublic and "CanEditPublicNotes" or "CanEditOfficerNotes"](self);
                local existing = info[isPublic and 7 or 8];
                onSetNote(note, info[1], canEdit, existing, isPublic);
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
                if self:GetGuildInfo(proxy) then
                    -- The proxy is also a guild member. Ignore the proxy.
                    note = "";
                else
                    -- Treat the name extracted from the public note as the actual player name.
                    -- The name of the guild character is the proxy for holding their data.
                    player, proxy = proxy, player;
                end
            end
            if self:IsTrial(rank) then
                local trialGroup = self:GetTrialRaidGroup(publicNote);
                if trialGroup then
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
                end
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
        self:SendComm(self.CommTypes.GUILD_NOTES_UPDATED, {}, "GUILD");
        self:SendComm(self.CommTypes.GUILD_NOTES_UPDATED, {}, "BROADCAST");
    end
end

function ABGP:GetGuildIndex(player)
    for i = 1, GetNumGuildMembers() do
        local name = GetGuildRosterInfo(i);
        if name and player == Ambiguate(name, "short") then
            return i;
        end
    end

    return false;
end

function ABGP:UpdateOfficerNote(player, guildIndex)
    if not self:IsPrivileged() then return; end
    if not self:CanEditOfficerNotes() then return; end

    guildIndex = guildIndex or self:GetGuildIndex(player);
    if not guildIndex then
        self:Error("Couldn't find %s in the guild!", self:ColorizeName(player));
        return;
    end

    -- Use GetGuildInfo instead of calling the API directly to handle the guild note
    -- having already been updated before calling this function - it won't be reflected
    -- in the API call yet.
    local _, rank, _, _, _, _, publicNote, existingNote = unpack(self:GetGuildInfo(player));
    local proxy = self:CheckProxy(publicNote);
    if proxy and not self:GetGuildInfo(proxy) then
        player = proxy;
    end

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
        if not self:GetEPRaidGroup(rank) then
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

local function UpdateEPGP(itemLink, player, cost, sender, phase, skipOfficerNote)
    local epgp = ABGP:GetActivePlayer(player);
    if epgp and epgp[phase] then
        local phaseEPGP = epgp[phase];
        if not epgp.trial then
            phaseEPGP.gp = phaseEPGP.gp + cost;
            phaseEPGP.priority = phaseEPGP.ep * 10 / phaseEPGP.gp;
            local proxy = epgp.proxy and ("[%s]"):format(epgp.proxy) or "";
            ABGP:LogVerbose("EPGP[%s] for %s%s: EP=%.3f GP=%.3f(+%d) PRIORITY=%.3f",
                phase, player, proxy, phaseEPGP.ep, phaseEPGP.gp, cost, phaseEPGP.priority);
            table.sort(ABGP.Priorities[phase], PrioritySort);

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

    local itemName = ABGP:GetItemName(data.itemLink);
    local value = ABGP:GetItemValue(itemName);
    if not value then return; end

    local cost = self:GetEffectiveCost(data.historyId, data.cost, value.phase) or data.cost;
    UpdateEPGP(data.itemLink, data.player, cost, sender, value.phase);
end

function ABGP:PriorityOnItemUnawarded(data)
    if data.testItem then return; end
    if not data.player then return; end

    local itemName = ABGP:GetItemName(data.itemLink);
    local value = ABGP:GetItemValue(itemName);
    if not value then return; end

    local cost = self:GetEffectiveCost(data.historyId, data.cost, value.phase) or data.cost;
    cost = -cost; -- negative because we're undoing the GP adjustment
    UpdateEPGP(data.itemLink, data.player, cost, data.sender, value.phase, data.skipOfficerNote);
end

function ABGP:HistoryOnItemAwarded(data, distribution, sender)
    if data.testItem then return; end

    local itemLink = data.itemLink;
    local awardDate = data.awarded;
    local itemName = ABGP:GetItemName(itemLink);
    local value = ABGP:GetItemValue(itemName);
    if not value then return; end
    local history = _G.ABGP_Data[value.phase].gpHistory;

    if data.oldHistoryId then
        for i, entry in ipairs(history) do
            if entry[self.ItemHistoryIndex.ID] == data.oldHistoryId then
                -- This is the entry being replaced.
                local _, deleteDate = self:ParseHistoryId(data.updateId);
                table.insert(history, 1, {
                    [ABGP.ItemHistoryIndex.TYPE] = ABGP.ItemHistoryType.DELETE,
                    [ABGP.ItemHistoryIndex.ID] = data.updateId,
                    [ABGP.ItemHistoryIndex.DATE] = deleteDate,
                    [ABGP.ItemHistoryIndex.DELETEDID] = data.oldHistoryId,
                });

                -- If the previous award is for the same player, then the officer note will already
                -- get updated to the proper value for the new award, and writing the officer note
                -- twice for the same player with no delay will fail.
                self:Fire(self.InternalEvents.ITEM_DISTRIBUTION_UNAWARDED, {
                    itemLink = value.itemLink,
                    historyId = data.oldHistoryId,
                    phase = value.phase,
                    player = entry[ABGP.ItemHistoryIndex.PLAYER],
                    cost = entry[ABGP.ItemHistoryIndex.GP],
                    skipOfficerNote = (entry[self.ItemHistoryIndex.PLAYER] == data.player),
                    sender = sender,
                });
                break;
            end
        end
    end

    if data.player and self:GetActivePlayer(data.player) then
        table.insert(history, 1, {
            [ABGP.ItemHistoryIndex.TYPE] = ABGP.ItemHistoryType.ITEM,
            [ABGP.ItemHistoryIndex.ID] = data.historyId,
            [ABGP.ItemHistoryIndex.DATE] = awardDate,
            [ABGP.ItemHistoryIndex.PLAYER] = data.player,
            [ABGP.ItemHistoryIndex.NAME] = itemName,
            [ABGP.ItemHistoryIndex.GP] = data.cost,
        });
    end

    self:Fire(self.InternalEvents.HISTORY_UPDATED);
end

function ABGP:HistoryTriggerDecay(decayTime)
    local decayValue, decayFloor = self:GetGPDecayInfo();
    for phase in pairs(self.Phases) do
        table.insert(_G.ABGP_Data[phase].gpHistory, 1, {
            [self.ItemHistoryIndex.TYPE] = self.ItemHistoryType.DECAY,
            [self.ItemHistoryIndex.ID] = self:GetHistoryId(),
            [self.ItemHistoryIndex.DATE] = decayTime,
            [self.ItemHistoryIndex.VALUE] = decayValue,
            [self.ItemHistoryIndex.FLOOR] = decayFloor,
        });
    end

    -- TODO: this code is flawed because it doesn't handle
    -- any EP/GP awarded after the decay date.
    -- for phase, prio in pairs(self.Priorities) do
    --     for _, epgp in ipairs(prio) do
    --         if not epgp.trial then
    --             epgp.ep = epgp.ep * (1 - decayValue);
    --             epgp.ep = max(epgp.ep, decayFloor);
    --             epgp.gp = epgp.gp * (1 - decayValue);
    --             epgp.gp = max(epgp.gp, decayFloor);
    --         end
    --     end
    -- end

    -- self:RefreshActivePlayers();
    -- self:RebuildOfficerNotes();

    local floorText = "";
    if decayFloor ~= 0 then
        floorText = (" (floor: %d"):format(decayFloor);
    end
    self:Notify("Applied a decay of %d%%%s to EPGP.",
        floor(decayValue * 100 + 0.5), floorText);
    self:Notify("NOTE: this just adds the appropriate history entries for now. Officer notes are unchanged.");
end

function ABGP:AddActivePlayer(player, proxy, p1ep, p1gp, p3ep, p3gp)
    if proxy then
        self:Notify("Adding %s into the EPGP system, proxied by %s.", self:ColorizeName(player), self:ColorizeName(proxy));
        _G.GuildRosterSetPublicNote(self:GetGuildIndex(proxy), ("ABGP Proxy: %s"):format(player));
    else
        self:Notify("Adding %s into the EPGP system.", self:ColorizeName(player));
        local publicNote = self:GetGuildInfo(player)[7];
        if publicNote:find("^ABGP") then
            _G.GuildRosterSetPublicNote(self:GetGuildIndex(player), "");
        end
    end

    if p1ep ~= 0 and p1gp ~= 0 then
        table.insert(_G.ABGP_Data[self.Phases.p1].gpHistory, 1, {
            [self.ItemHistoryIndex.TYPE] = self.ItemHistoryType.BONUS,
            [self.ItemHistoryIndex.ID] = self:GetHistoryId(),
            [self.ItemHistoryIndex.DATE] = GetServerTime(),
            [self.ItemHistoryIndex.PLAYER] = player,
            [self.ItemHistoryIndex.GP] = p1gp,
        });
        table.insert(self.Priorities[self.Phases.p1], {
            player = player,
            ep = p1ep,
            gp = p1gp,
        });
        self:Notify("Inserted into %s at EP=%f and GP=%f.", self.PhaseNames[self.Phases.p1], p1ep, p1gp);
    end

    if p3ep ~= 0 and p3gp ~= 0 then
        table.insert(_G.ABGP_Data[self.Phases.p3].gpHistory, 1, {
            [self.ItemHistoryIndex.TYPE] = self.ItemHistoryType.BONUS,
            [self.ItemHistoryIndex.ID] = self:GetHistoryId(),
            [self.ItemHistoryIndex.DATE] = GetServerTime(),
            [self.ItemHistoryIndex.PLAYER] = player,
            [self.ItemHistoryIndex.GP] = p3gp,
        });
        table.insert(self.Priorities[self.Phases.p3], {
            player = player,
            ep = p3ep,
            gp = p3gp,
        });
        self:Notify("Inserted into %s at EP=%f and GP=%f.", self.PhaseNames[self.Phases.p3], p3ep, p3gp);
    end

    self:RefreshActivePlayers();
    self:RebuildOfficerNotes();
end

function ABGP:AddTrial(player, raidGroup)
    local raidGroupName = self.RaidGroupNames[raidGroup];
    self:Notify("Adding %s as a trial for the %s raid group.", self:ColorizeName(player), raidGroupName);
    _G.GuildRosterSetPublicNote(self:GetGuildIndex(player), ("ABGP Raid Group: %s"):format(raidGroupName));
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

    table.sort(processed, function(a, b)
        return a[ABGP.ItemHistoryIndex.DATE] > b[ABGP.ItemHistoryIndex.DATE];
    end);

    return processed;
end

function ABGP:GetEffectiveCost(id, gp, phase)
    if gp == 0 then return 0, 0; end
    local history = self:ProcessItemHistory(_G.ABGP_Data[phase].gpHistory, false, true);
    local cost = 0;
    local decayCount = 0;

    for i = #history, 1, -1 do
        local entry = history[i];
        if entry[self.ItemHistoryIndex.ID] == id then
            cost = gp;
        elseif cost ~= 0 and entry[self.ItemHistoryIndex.TYPE] == self.ItemHistoryType.DECAY then
            cost = cost * (1 - entry[self.ItemHistoryIndex.VALUE]);
            cost = max(cost, entry[self.ItemHistoryIndex.FLOOR]);
            decayCount = decayCount + 1;
        end
    end

    if cost == 0 then
        return false;
    end
    return cost, decayCount;
end

function ABGP:BreakdownHistory(history)
    local types = {};
    for _, entry in pairs(history) do
        types[entry[self.ItemHistoryIndex.TYPE]] = (types[entry[self.ItemHistoryIndex.TYPE]] or 0) + 1;
    end

    local typesSorted = {
        self.ItemHistoryType.ITEM,
        self.ItemHistoryType.BONUS,
        self.ItemHistoryType.DECAY,
        self.ItemHistoryType.DELETE,
    };

    local typeNames = {
        [self.ItemHistoryType.ITEM] = "item award(s)",
        [self.ItemHistoryType.BONUS] = "gp award(s)",
        [self.ItemHistoryType.DECAY] = "decay trigger(s)",
        [self.ItemHistoryType.DELETE] = "deletion(s)",
    };

    local out = {};
    for _, entryType in ipairs(typesSorted) do
        if types[entryType] then
            table.insert(out, ("%d %s"):format(types[entryType], typeNames[entryType]));
        end
    end
    return table.concat(out, ", ");
end

function ABGP:HistoryOnActivePlayersRefreshed()
    hasCompleteCached = false;
    hasActivePlayers = true;
    if not checkedHistory then
        self:HistoryOnGuildRosterUpdate();
    end
end

function ABGP:HistoryOnUpdate()
    hasCompleteCached = false;
end

function ABGP:HasCompleteHistory(shouldPrint)
    if hasCompleteCached and not shouldPrint then return hasComplete; end

    hasComplete = true;
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

                if abs(calculated - epgp[phase].gp) > 0.0015 then
                    hasComplete = false;
                    if shouldPrint then
                        self:Notify("Incomplete %s history for %s: expected %.3f, calculated %.3f.",
                            self.PhaseNames[phase], self:ColorizeName(player), epgp[phase].gp, calculated);
                    end
                end
            end
        end
    end

    if hasComplete and shouldPrint then self:Notify("GP history is complete!"); end
    hasCompleteCached = true;
    return hasComplete;
end

function ABGP:HasValidBaseline(phase)
    return _G.ABGP_DataTimestamp.gpHistory[phase] ~= invalidBaseline;
end

function ABGP:HasValidBaselines()
    for phase in pairs(self.Phases) do
        if not self:HasValidBaseline(phase) then return false; end
    end
    return true;
end

local function BuildSyncHashData(phase, now)
    local hash = 0;
    local syncCount = 0;

    local gpHistory = _G.ABGP_Data[phase].gpHistory;
    local baseline = _G.ABGP_DataTimestamp.gpHistory[phase];
    if baseline == invalidBaseline then return hash, syncCount; end

    for _, entry in ipairs(gpHistory) do
        local id = entry[ABGP.ItemHistoryIndex.ID];
        local player, date = ABGP:ParseHistoryId(id);
        if now - date > syncThreshold then break; end

        hash = bit.bxor(hash, LibQuestieSerializer:Hash(id));
        syncCount = syncCount + 1;
    end

    return hash, syncCount;
end

function ABGP:HistoryOnEnteringWorld(isInitialLogin)
    -- Only check history on the initial login.
    if not isInitialLogin then checkedHistory = true; end
end

function ABGP:HistoryTriggerSync(target, token, now)
    local privileged = self:CanEditOfficerNotes() and not self:GetDebugOpt("AvoidHistorySend");
    local upToDate = self:HasCompleteHistory(self:GetDebugOpt());

    local now = now or GetServerTime();
    for phase in pairs(self.Phases) do
        local gpHistory = _G.ABGP_Data[phase].gpHistory;
        local baseline = _G.ABGP_DataTimestamp.gpHistory[phase];
        local canSendHistory = privileged and baseline ~= invalidBaseline;
        local commData = {
            version = self:GetVersion(),
            phase = phase,
            token = token or GetTime(),
            baseline = baseline,
            archivedCount = 0,
            now = now,
        };

        local syncCount = 0;
        if canSendHistory then
            commData.ids = {};
            for _, entry in ipairs(gpHistory) do
                local id = entry[self.ItemHistoryIndex.ID];
                local player, date = self:ParseHistoryId(id);
                if now - date > syncThreshold then break; end

                commData.ids[id] = true;
                syncCount = syncCount + 1;
            end
        else
            commData.hash, syncCount = BuildSyncHashData(phase, now);
        end

        commData.archivedCount = #gpHistory - syncCount;
        if target then
            self:LogDebug("Sending %s history sync to %s: %d synced (ids), %d archived",
                self.PhaseNames[phase], self:ColorizeName(target), syncCount, commData.archivedCount);
            self:SendComm(self.CommTypes.HISTORY_SYNC, commData, "WHISPER", target);
        else
            self:LogDebug("Sending %s history sync: %d synced (%s), %d archived",
                self.PhaseNames[phase], syncCount, commData.hash and "hash" or "ids", commData.archivedCount);
            self:SendComm(self.CommTypes.HISTORY_SYNC, commData, "GUILD");
        end
    end
end

function ABGP:HistoryTriggerRebuild()
    table.wipe(warnedOutOfDate);
    for phase in pairs(self.Phases) do
        _G.ABGP_DataTimestamp.gpHistory[phase] = invalidBaseline;
    end
    self:HistoryTriggerSync();
end

function ABGP:HistoryOnGuildRosterUpdate()
    if self:Get("outsider") or not self:Get("syncEnabled") then return; end
    if checkedHistory or not hasActivePlayers or InCombatLockdown() then return; end
    checkedHistory = true;
    hasCompleteCached = false;

    self:HistoryTriggerSync();
end

local function WarnOutOfDate(phase, sender)
    if not warnedOutOfDate[phase] then
        warnedOutOfDate[phase] = true;
        _G.StaticPopup_Show("ABGP_HISTORY_OUT_OF_DATE", ABGP.PhaseNames[phase], ABGP:ColorizeName(sender), {
            phase = phase,
            sender = sender,
        });
    end
end

function ABGP:HistoryOnSync(data, distribution, sender)
    if self:Get("outsider") or not self:Get("syncEnabled") then return; end
    if sender == UnitName("player") or InCombatLockdown() then return; end
    if self:GetCompareVersion() ~= data.version then return; end

    if data.token ~= requestedHistoryToken then
        table.wipe(requestedHistoryEntries);
        requestedHistoryToken = data.token;
    end

    local senderIsPrivileged = self:CanEditOfficerNotes(sender) and not data.notPrivileged;
    local history = _G.ABGP_Data[data.phase].gpHistory;
    local baseline = _G.ABGP_DataTimestamp.gpHistory[data.phase];
    local canSendHistory = self:CanEditOfficerNotes() and not self:GetDebugOpt("AvoidHistorySend") and baseline ~= invalidBaseline;
    local now = data.now;

    -- Compute the archivedCount and hash (if necessary).
    local hash, syncCount = 0, 0;
    if data.hash and canSendHistory then
        hash, syncCount = BuildSyncHashData(data.phase, now);
    else
        for _, entry in ipairs(history) do
            local id = entry[self.ItemHistoryIndex.ID];
            local player, date = self:ParseHistoryId(id);
            if now - date > syncThreshold then break; end

            syncCount = syncCount + 1;
        end
    end
    local archivedCount = #history - syncCount;

    -- First evaluate the baseline and archivedCount to see if the data is out of date.
    -- We can only initiate history replacements if privileged, and we'll only accept
    -- possible history replacements from privileged senders.
    if canSendHistory then
        if data.baseline < baseline then
            -- The sender has an older baseline. They need a history replacement.
            self:LogDebug("Sending history replace init to %s (old baseline) [%s]",
                self:ColorizeName(sender), self.PhaseNames[data.phase]);
            self:SendComm(self.CommTypes.HISTORY_REPLACE_INITIATION, {
                phase = data.phase,
            }, "WHISPER", sender);
        elseif data.baseline == baseline and data.archivedCount < archivedCount then
            -- The sender has fewer archived entries than us. They need a history replacement.
            self:LogDebug("Sending history replace init to %s (fewer archived) [%s]",
                self:ColorizeName(sender), self.PhaseNames[data.phase]);
            self:SendComm(self.CommTypes.HISTORY_REPLACE_INITIATION, {
                phase = data.phase,
            }, "WHISPER", sender);
        end
    end

    if senderIsPrivileged then
        if data.baseline > baseline then
            -- The sender has a newer baseline. We need a history replacement.
            _G.ABGP_DataTimestamp.gpHistory[data.phase] = invalidBaseline;
            self:LogDebug("Updated baseline found from %s [%s]",
                self:ColorizeName(sender), self.PhaseNames[data.phase]);
            WarnOutOfDate(data.phase, sender);
        elseif data.baseline == baseline and data.archivedCount > archivedCount then
            -- The sender has more archived entries than us. We need a history replacement.
            _G.ABGP_DataTimestamp.gpHistory[data.phase] = invalidBaseline;
            self:LogDebug("More archived entries found from %s [%s]",
                self:ColorizeName(sender), self.PhaseNames[data.phase]);
            WarnOutOfDate(data.phase, sender);
        end
    end

    -- A deeper sync check should only occur if the baselines and archivedCounts match.
    local checkRecent = data.baseline == baseline and data.archivedCount == archivedCount;
    if not checkRecent then return; end

    if data.hash and canSendHistory then
        -- The sender sent a hash of their recent entries. If our hash is different,
        -- we'll deliver them a sync and they can request whatever they need.
        if data.hash ~= hash then
            self:HistoryTriggerSync(sender, data.token, now);
        end
    elseif data.ids and senderIsPrivileged then
        -- The sender sent ids. We'll go through them looking for entries we need,
        -- and entries to send if we're allowed to do so.
        local merge = {};
        local sendCount, requestCount = 0, 0;
        for i, entry in ipairs(history) do
            local id = entry[self.ItemHistoryIndex.ID];
            local player, date = self:ParseHistoryId(id);
            if now - date > syncThreshold then break; end

            if data.ids[id] then
                -- We both have this entry.
                data.ids[id] = nil;
            elseif canSendHistory then
                -- Sender doesn't have this entry.
                merge[id] = entry;
                sendCount = sendCount + 1;
            end
        end

        -- At this point, anything left in data.ids represents entries
        -- the sender has but we don't. Request those if they exist,
        -- and send any we have they're missing. Remove ones we've
        -- already requested for this token.
        for id in pairs(data.ids) do
            if requestedHistoryEntries[id] then
                -- We already requested this entry from someone.
                data.ids[id] = nil;
            else
                -- We need to request this id.
                requestedHistoryEntries[id] = true;
                requestCount = requestCount + 1;
            end
        end
        if sendCount > 0 or requestCount > 0 then
            self:LogDebug("Sending %d to / requesting %d history entries from %s [%s]",
                sendCount, requestCount, self:ColorizeName(sender), self.PhaseNames[data.phase]);
            self:SendComm(self.CommTypes.HISTORY_MERGE, {
                phase = data.phase,
                baseline = baseline,
                merge = merge,
                requested = data.ids,
                now = now,
            }, "WHISPER", sender);
        end
    end
end

function ABGP:HistoryOnReplaceInit(data, distribution, sender)
    if not self:CanEditOfficerNotes(sender) then return; end

    -- The sender has determined our history is out of date and wants to give us theirs.
    -- At this point our history should not be considered as valid for sending to others.
    _G.ABGP_DataTimestamp.gpHistory[data.phase] = invalidBaseline;

    self:LogDebug("History replace init received from %s [%s]",
        self:ColorizeName(sender), self.PhaseNames[data.phase]);
    WarnOutOfDate(data.phase, sender);
end

function ABGP:HistoryOnReplaceRequest(data, distribution, sender)
    -- The sender is asking for our entire history.
    self:LogDebug("Sending history replacement to %s [%s]",
        self:ColorizeName(sender), self.PhaseNames[data.phase]);

    local history = _G.ABGP_Data[data.phase].gpHistory;
    if self:GetDebugOpt("AvoidHistorySend") then history = nil; end

    self:SendComm(self.CommTypes.HISTORY_REPLACE, {
        phase = data.phase,
        baseline = _G.ABGP_DataTimestamp.gpHistory[data.phase],
        history = history,
    }, "WHISPER", sender);
end

function ABGP:HistoryOnReplace(data, distribution, sender)
    if not self:CanEditOfficerNotes(sender) then return; end
    if not data.history then
        -- This shouldn't really happen - the "notPrivileged" field
        -- prevents us from asking for history from people with the
        -- debug option AvoidHistorySend enabled.
        self:Error("%s declined sending their full history!", ABGP:ColorizeName(sender));
        return;
    end

    local baseline = _G.ABGP_DataTimestamp.gpHistory[data.phase];
    if data.baseline < baseline then
        -- This can only happen if we somehow get a new history from two people?
        self:Error("Received full history from %s, but it's out of date!", ABGP:ColorizeName(sender));
        return;
    end

    _G.ABGP_DataTimestamp.gpHistory[data.phase] = data.baseline;
    _G.ABGP_Data[data.phase].gpHistory = data.history;
    self:Fire(self.InternalEvents.HISTORY_UPDATED);

    self:Notify("Received complete %s history from %s! Breakdown: %s.",
        ABGP.PhaseNames[data.phase], self:ColorizeName(sender), self:BreakdownHistory(data.history));
    local upToDate = self:HasCompleteHistory(self:GetDebugOpt());
    if upToDate then
        self:Notify("You're now up to date!");
    end
end

local function RequestFullHistory(data)
    -- We're asking the sender for their full history.

    ABGP:SendComm(ABGP.CommTypes.HISTORY_REPLACE_REQUEST, {
        phase = data.phase,
    }, "WHISPER", data.sender);
    ABGP:Notify("Requesting full item history for %s from %s! This could take a little while.",
        ABGP.PhaseNames[data.phase], ABGP:ColorizeName(data.sender));
end

function ABGP:HistoryOnMerge(data, distribution, sender)
    local baseline = _G.ABGP_DataTimestamp.gpHistory[data.phase];
    if data.baseline ~= baseline then return; end
    local canSendHistory = self:CanEditOfficerNotes() and not self:GetDebugOpt("AvoidHistorySend") and baseline ~= invalidBaseline;

    local history = _G.ABGP_Data[data.phase].gpHistory;
    local now = data.now;

    if data.requested and next(data.requested) and canSendHistory then
        -- The sender is requesting history entries.
        local merge = {};
        local sendCount = 0;
        for _, entry in ipairs(history) do
            local id = entry[self.ItemHistoryIndex.ID];
            if data.requested[id] then
                -- Sender wants this entry.
                merge[id] = entry;
                sendCount = sendCount + 1;
            end
        end
        if sendCount > 0 then
            self:LogDebug("Sending %d history entries to %s [%s]",
                sendCount, self:ColorizeName(sender), self.PhaseNames[data.phase]);
            self:SendComm(self.CommTypes.HISTORY_MERGE, {
                phase = data.phase,
                baseline = baseline,
                merge = merge,
                now = now,
            }, "WHISPER", sender);
        end
    end

    if data.merge and next(data.merge) and self:CanEditOfficerNotes(sender) then
        -- The sender is sharing entries. First remove the ones we already have.
        for _, entry in ipairs(history) do
            local id = entry[self.ItemHistoryIndex.ID];
            data.merge[id] = nil;
        end

        -- At this point, data.merge contains entries we don't have.
        if next(data.merge) then
            local mergeCount = 0;
            for _, entry in pairs(data.merge) do
                table.insert(history, 1, entry);
                mergeCount = mergeCount + 1;
            end

            if mergeCount > 0 then
                table.sort(history, function(a, b)
                    local _, aDate = self:ParseHistoryId(a[self.ItemHistoryIndex.ID]);
                    local _, bDate = self:ParseHistoryId(b[self.ItemHistoryIndex.ID]);

                    return aDate > bDate;
                end);
                self:Fire(self.InternalEvents.HISTORY_UPDATED);

                self:Notify("Received %d item history entries for %s from %s! Breakdown: %s.",
                    mergeCount, self.PhaseNames[data.phase], self:ColorizeName(sender), self:BreakdownHistory(data.merge));
                local upToDate = self:HasCompleteHistory(self:GetDebugOpt());
                if upToDate then
                    self:Notify("You're now up to date!");
                end
            end
        end
    end
end

function ABGP:CommitHistory(phase)
    if not self:GetDebugOpt("AvoidHistorySend") then
        _G.ABGP_DataTimestamp.gpHistory[phase] = GetServerTime();
    end
end

function ABGP:HistoryUpdateCost(data, cost)
    local commData = {
        itemLink = data.itemLink,
        player = data.player,
        cost = cost,
        requestType = self.RequestTypes.MANUAL,
        oldHistoryId = data.historyId,
        awarded = data.awarded,
        updateId = ABGP:GetHistoryId(),
        historyId = ABGP:GetHistoryId(),
    };
    self:SendComm(self.CommTypes.ITEM_AWARDED, commData, "BROADCAST");
    self:HistoryOnItemAwarded(commData, nil, UnitName("player"));
    self:PriorityOnItemAwarded(commData, nil, UnitName("player"));

    commData.value = data.value;
end

function ABGP:HistoryUpdatePlayer(data, player)
    local commData = {
        itemLink = data.itemLink,
        player = player,
        cost = data.gp,
        requestType = self.RequestTypes.MANUAL,
        oldHistoryId = data.historyId,
        awarded = data.awarded,
        updateId = ABGP:GetHistoryId(),
        historyId = ABGP:GetHistoryId(),
    };
    self:SendComm(self.CommTypes.ITEM_AWARDED, commData, "BROADCAST");
    self:HistoryOnItemAwarded(commData, nil, UnitName("player"));
    self:PriorityOnItemAwarded(commData, nil, UnitName("player"));

    commData.value = data.value;
end

function ABGP:HistoryDelete(data)
    local commData = {
        itemLink = data.itemLink,
        oldPlayer = data.player,
        cost = data.gp,
        oldHistoryId = data.historyId,
        updateId = ABGP:GetHistoryId(),
    };
    self:SendComm(self.CommTypes.ITEM_AWARDED, commData, "BROADCAST");
    self:HistoryOnItemAwarded(commData, nil, UnitName("player"));
    self:PriorityOnItemAwarded(commData, nil, UnitName("player"));

    commData.value = data.value;
end

StaticPopupDialogs["ABGP_HISTORY_OUT_OF_DATE"] = ABGP:StaticDialogTemplate(ABGP.StaticDialogTemplates.JUST_BUTTONS, {
    exclusive = false,
    multiple = true,
    text = "Your history for %s is out of date! Sync from %s?",
    button1 = "Yes",
    button2 = "No",
    OnAccept = function(self, data)
        RequestFullHistory(data);
    end,
});
