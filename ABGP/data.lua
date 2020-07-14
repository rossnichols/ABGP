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
local max = max;
local unpack = unpack;
local abs = abs;

local updatingNotes = false;
local hasCompleteCached = false;
local hasComplete = false;
local hasActivePlayers = false;
local checkedHistory = false;

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
            elseif note ~= "" and self:GetEPRaidGroup(rank) then
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
                self:HistoryDeleteEntry(value.phase, entry, data.updateId);

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

    if data.player then
        table.insert(history, 1, {
            [ABGP.ItemHistoryIndex.TYPE] = ABGP.ItemHistoryType.ITEM,
            [ABGP.ItemHistoryIndex.ID] = data.historyId,
            [ABGP.ItemHistoryIndex.DATE] = awardDate,
            [ABGP.ItemHistoryIndex.PLAYER] = data.player,
            [ABGP.ItemHistoryIndex.ITEMID] = value.itemId,
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

    self:Fire(self.InternalEvents.HISTORY_UPDATED);
end

function ABGP:AddActivePlayer(player, proxy, addTime, p1ep, p1gp, p3ep, p3gp)
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
            [self.ItemHistoryIndex.TYPE] = self.ItemHistoryType.RESET,
            [self.ItemHistoryIndex.ID] = self:GetHistoryId(),
            [self.ItemHistoryIndex.DATE] = addTime,
            [self.ItemHistoryIndex.PLAYER] = player,
            [self.ItemHistoryIndex.GP] = p1gp,
            [self.ItemHistoryIndex.NOTES] = "New active raider",
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
            [self.ItemHistoryIndex.TYPE] = self.ItemHistoryType.RESET,
            [self.ItemHistoryIndex.ID] = self:GetHistoryId(),
            [self.ItemHistoryIndex.DATE] = addTime,
            [self.ItemHistoryIndex.PLAYER] = player,
            [self.ItemHistoryIndex.GP] = p3gp,
            [self.ItemHistoryIndex.NOTES] = "New active raider",
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
    self:Fire(self.InternalEvents.HISTORY_UPDATED);
end

function ABGP:AddTrial(player, raidGroup)
    local raidGroupName = self.RaidGroupNames[raidGroup];
    self:Notify("Adding %s as a trial for the %s raid group.", self:ColorizeName(player), raidGroupName);
    _G.GuildRosterSetPublicNote(self:GetGuildIndex(player), ("ABGP Raid Group: %s"):format(raidGroupName));
end

function ABGP:ProcessItemHistory(gpHistory, includeNonItems)
    local processed = {};
    local deleted = {};
    for _, data in ipairs(gpHistory) do
        if not deleted[data[ABGP.ItemHistoryIndex.ID]] then
            local entryType = data[ABGP.ItemHistoryIndex.TYPE];
            if entryType == ABGP.ItemHistoryType.ITEM then
                table.insert(processed, data);
            elseif entryType == ABGP.ItemHistoryType.DELETE then
                deleted[data[ABGP.ItemHistoryIndex.DELETEDID]] = true;
            elseif includeNonItems then
                table.insert(processed, data);
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
    local history = self:ProcessItemHistory(_G.ABGP_Data[phase].gpHistory, true);
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

function ABGP:CalculateCurrentGP(player, phase, history)
    history = history or self:ProcessItemHistory(_G.ABGP_Data[phase].gpHistory, true);
    local gp = 0;
    for i = #history, 1, -1 do
        local entry = history[i];
        local entryType = entry[self.ItemHistoryIndex.TYPE];
        if (entryType == self.ItemHistoryType.ITEM or entryType == self.ItemHistoryType.BONUS) and
           entry[self.ItemHistoryIndex.PLAYER] == player then
            gp = gp + entry[self.ItemHistoryIndex.GP];
        elseif entryType == self.ItemHistoryType.DECAY then
            gp = gp * (1 - entry[self.ItemHistoryIndex.VALUE]);
            gp = max(gp, entry[self.ItemHistoryIndex.FLOOR]);
        elseif entryType == self.ItemHistoryType.RESET and
               entry[self.ItemHistoryIndex.PLAYER] == player then
            gp = entry[self.ItemHistoryIndex.GP];
        end
    end

    return gp;
end

function ABGP:HasCompleteHistory(shouldPrint)
    if hasCompleteCached and not shouldPrint then return hasComplete; end

    hasComplete = true;
    for phase in pairs(self.Phases) do
        local history = self:ProcessItemHistory(_G.ABGP_Data[phase].gpHistory, true);
        for player, epgp in pairs(self:GetActivePlayers()) do
            if epgp[phase] then
                local calculated = self:CalculateCurrentGP(player, phase, history);
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

function ABGP:HistoryOnEnteringWorld(isInitialLogin)
    -- Only check history on the initial login.
    if not isInitialLogin then checkedHistory = true; end
end

function ABGP:HistoryOnGuildRosterUpdate()
    if checkedHistory or not hasActivePlayers then return; end
    checkedHistory = true;
    hasCompleteCached = false;

    self:TriggerInitialSync();
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

function ABGP:HistoryDeleteItemAward(data)
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

function ABGP:HistoryDeleteEntry(phase, entry, deleteId)
    if not deleteId then deleteId = self:GetHistoryId(); end
    local history = _G.ABGP_Data[phase].gpHistory;

    local _, deleteDate = self:ParseHistoryId(deleteId);
    table.insert(history, 1, {
        [ABGP.ItemHistoryIndex.TYPE] = ABGP.ItemHistoryType.DELETE,
        [ABGP.ItemHistoryIndex.ID] = deleteId,
        [ABGP.ItemHistoryIndex.DATE] = deleteDate,
        [ABGP.ItemHistoryIndex.DELETEDID] = entry[ABGP.ItemHistoryIndex.ID],
    });

    self:Fire(self.InternalEvents.HISTORY_UPDATED);
end
