local _G = _G;
local ABGP = _G.ABGP;

local GetNumGuildMembers = GetNumGuildMembers;
local GetGuildRosterInfo = GetGuildRosterInfo;
local Ambiguate = Ambiguate;
local UnitName = UnitName;
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
    if a.priority[ABGP.ItemCategory.GOLD] ~= b.priority[ABGP.ItemCategory.GOLD] then
        return a.priority[ABGP.ItemCategory.GOLD] > b.priority[ABGP.ItemCategory.GOLD];
    else
        return a.player < b.player;
    end
end

function ABGP:RefreshFromOfficerNotes()
    local prioOld = self.Priorities;
    local prio = {};

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
                    table.insert(prio, {
                        player = player,
                        rank = rank,
                        class = class,
                        raidGroup = trialGroup,
                        altRaidGroup = trialGroup,
                        ep = 0,
                        gp = { [self.ItemCategory.GOLD] = 0, [self.ItemCategory.SILVER] = 0 },
                        priority = { [self.ItemCategory.GOLD] = 0, [self.ItemCategory.SILVER] = 0 },
                        trial = true
                    });
                end
            elseif note ~= "" and self:GetRaidGroup(rank) then
                local ep, gpS, gpG, raidGroup = note:match("^(%d+)%:(%d+)%:(%d+)%:?(%S*)$");
                if ep then
                    ep = tonumber(ep) / 1000;
                    gpS = tonumber(gpS) / 1000;
                    gpG = tonumber(gpG) / 1000;

                    if ep ~= 0 and gpS ~= 0 and gpG ~= 0 then
                        table.insert(prio, {
                            player = player,
                            proxy = proxy,
                            rank = rank,
                            class = class,
                            raidGroup = raidGroup and self.RaidGroupNamesReversed[raidGroup] or self:GetRaidGroup(rank),
                            altRaidGroup = self:GetAltRaidGroup(rank),
                            ep = ep,
                            gp = { [self.ItemCategory.GOLD] = gpG, [self.ItemCategory.SILVER] = gpS },
                            priority = { [self.ItemCategory.GOLD] = ep * 10 / gpG, [self.ItemCategory.SILVER] = ep * 10 / gpS },
                        });
                    end
                end
            end
        end
    end

    table.sort(prio, PrioritySort);

    if not self.tCompare(prioOld, prio, 2) then
        self.Priorities = prio;
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
        local ep = floor(epgp.ep * 1000 + 0.5);
        local gpS = floor(epgp.gp[self.ItemCategory.SILVER] * 1000 + 0.5);
        local gpG = floor(epgp.gp[self.ItemCategory.GOLD] * 1000 + 0.5);
        note = ("%d:%d:%d"):format(ep, gpS, gpG);
        if epgp.raidGroup ~= self:GetRaidGroup(epgp.rank) then
            note = ("%s:%s"):format(note, self.RaidGroupNames[epgp.raidGroup]);
        end

        -- Sanity check: all ranks here must be in a raid group.
        if not self:GetRaidGroup(rank) then
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

local function UpdateEPGP(player, cost, sender, skipOfficerNote)
    local epgp = ABGP:GetActivePlayer(player);
    if epgp and not epgp.trial then
        epgp.gp[cost.category] = epgp.gp[cost.category] + cost.cost;
        epgp.priority[cost.category] = epgp.ep * 10 / epgp.gp[cost.category];
        local proxy = epgp.proxy and ("[%s]"):format(epgp.proxy) or "";
        ABGP:LogVerbose("EPGP[%s] for %s%s: EP=%.3f GP=%.3f(+%d) PRIORITY=%.3f",
            cost.category, player, proxy, epgp.ep, epgp.gp[cost.category], cost.cost, epgp.priority);
        table.sort(ABGP.Priorities, PrioritySort);

        ABGP:RefreshActivePlayers();

        if sender == UnitName("player") and not ABGP:GetDebugOpt("SkipOfficerNote") and not skipOfficerNote then
            -- UpdateOfficerNote expects the name of the guild member
            -- that is being updated, which is the proxy if it's set.
            ABGP:UpdateOfficerNote(epgp.proxy or player);
        end
    end
end

function ABGP:PriorityOnItemAwarded(data, distribution, sender)
    if data.testItem then return; end
    if not data.player then return; end

    -- See if we can ML the item to the player.
    self:GiveItemViaML(data.itemLink, data.player);

    local itemName = ABGP:GetItemName(data.itemLink);
    local value = ABGP:GetItemValue(itemName);
    if not value then return; end

    local cost = self:GetEffectiveCost(data.historyId, data.cost) or data.cost;
    UpdateEPGP(data.player, cost, sender);
end

function ABGP:PriorityOnItemUnawarded(data)
    if data.testItem then return; end
    if not data.player then return; end

    local itemName = ABGP:GetItemName(data.itemLink);
    local value = ABGP:GetItemValue(itemName);
    if not value then return; end

    local cost = self:GetEffectiveCost(data.historyId, data.cost) or data.cost;
    local adjustedCost = { cost = -cost.cost, category = cost.category }; -- negative because we're undoing the GP adjustment
    UpdateEPGP(data.player, adjustedCost, data.sender, data.skipOfficerNote);
end

function ABGP:HistoryOnItemAwarded(data, distribution, sender)
    if data.testItem then return; end

    local itemLink = data.itemLink;
    local itemName = ABGP:GetItemName(itemLink);
    local value = ABGP:GetItemValue(itemName);
    if not value then return; end
    local history = _G.ABGP_Data2.history.data;

    if data.oldHistoryId then
        for _, entry in ipairs(history) do
            if entry[self.ItemHistoryIndex.ID] == data.oldHistoryId then
                -- This is the entry being replaced.
                self:HistoryDeleteEntry(entry, data.updateId);

                -- If the previous award is for the same player, then the officer note will already
                -- get updated to the proper value for the new award, and writing the officer note
                -- twice for the same player with no delay will fail.
                self:Fire(self.InternalEvents.ITEM_UNAWARDED, {
                    itemLink = value.itemLink,
                    historyId = data.oldHistoryId,
                    player = entry[ABGP.ItemHistoryIndex.PLAYER],
                    cost = { cost = entry[ABGP.ItemHistoryIndex.GP], category = entry[ABGP.ItemHistoryIndex.CATEGORY] },
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
            [ABGP.ItemHistoryIndex.DATE] = data.awarded,
            [ABGP.ItemHistoryIndex.PLAYER] = data.player,
            [ABGP.ItemHistoryIndex.ITEMID] = value.itemId,
            [ABGP.ItemHistoryIndex.GP] = data.cost.cost,
            [ABGP.ItemHistoryIndex.CATEGORY] = data.cost.category,
        });
    end

    self:Fire(self.InternalEvents.HISTORY_UPDATED);
end

function ABGP:HistoryTriggerDecay(decayTime)
    local decayValue, decayFloor = self:GetGPDecayInfo();
    table.insert(_G.ABGP_Data2.history.data, 1, {
        [self.ItemHistoryIndex.TYPE] = self.ItemHistoryType.DECAY,
        [self.ItemHistoryIndex.ID] = self:GetHistoryId(),
        [self.ItemHistoryIndex.DATE] = decayTime,
        [self.ItemHistoryIndex.VALUE] = decayValue,
        [self.ItemHistoryIndex.FLOOR] = decayFloor,
    });

    local floorText = "";
    if decayFloor ~= 0 then
        floorText = (" (floor: %d"):format(decayFloor);
    end
    self:Notify("Applied a decay of %d%%%s to EPGP.", decayValue, floorText);
    self:Notify("NOTE: this just adds the appropriate history entries for now. Officer notes are unchanged.");

    self:Fire(self.InternalEvents.HISTORY_UPDATED);
end

function ABGP:AddActivePlayer(player, proxy, addTime, ep, gpS, gpG)
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

    table.insert(_G.ABGP_Data2.history.data, 1, {
        [self.ItemHistoryIndex.TYPE] = self.ItemHistoryType.RESET,
        [self.ItemHistoryIndex.ID] = self:GetHistoryId(),
        [self.ItemHistoryIndex.DATE] = addTime,
        [self.ItemHistoryIndex.PLAYER] = player,
        [self.ItemHistoryIndex.GP] = gpS,
        [self.ItemHistoryIndex.CATEGORY] = self.ItemCategory.SILVER,
        [self.ItemHistoryIndex.NOTES] = "New active raider",
    });
    table.insert(_G.ABGP_Data2.history.data, 1, {
        [self.ItemHistoryIndex.TYPE] = self.ItemHistoryType.RESET,
        [self.ItemHistoryIndex.ID] = self:GetHistoryId(),
        [self.ItemHistoryIndex.DATE] = addTime,
        [self.ItemHistoryIndex.PLAYER] = player,
        [self.ItemHistoryIndex.GP] = gpG,
        [self.ItemHistoryIndex.CATEGORY] = self.ItemCategory.GOLD,
        [self.ItemHistoryIndex.NOTES] = "New active raider",
    });
    table.insert(self.Priorities, {
        player = player,
        ep = ep,
        gp = { [self.ItemCategory.GOLD] = gpG, [self.ItemCategory.SILVER] = gpS },
    });
    self:Notify("Inserted into EPGP system at EP=%.2f, GP[S]=%.2f, GP[G]=%.2f.", ep, gpS, gpG);

    self:RefreshActivePlayers();
    self:RebuildOfficerNotes();
    self:Fire(self.InternalEvents.HISTORY_UPDATED);
end

function ABGP:AddTrial(player, raidGroup, proxy)
    local raidGroupName = self.RaidGroupNames[raidGroup];
    if proxy then
        self:Notify("Adding %s (proxied by %s) as a trial for the %s raid group.", self:ColorizeName(player), self:ColorizeName(proxy), raidGroupName);
        _G.GuildRosterSetPublicNote(self:GetGuildIndex(proxy), ("ABGP RG:%s P:%s"):format(raidGroupName, proxy));
    else
        self:Notify("Adding %s as a trial for the %s raid group.", self:ColorizeName(player), raidGroupName);
        _G.GuildRosterSetPublicNote(self:GetGuildIndex(player), ("ABGP Raid Group: %s"):format(raidGroupName));
    end
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

function ABGP:GetEffectiveCost(id, cost)
    if cost.cost == 0 then return cost, 0; end
    local history = self:ProcessItemHistory(_G.ABGP_Data2.history.data, true);
    local effectiveCost = 0;
    local decayCount = 0;

    for i = #history, 1, -1 do
        local entry = history[i];
        if entry[self.ItemHistoryIndex.ID] == id then
            effectiveCost = cost.cost;
        elseif cost ~= 0 and entry[self.ItemHistoryIndex.TYPE] == self.ItemHistoryType.DECAY then
            effectiveCost = effectiveCost * (1 - (entry[self.ItemHistoryIndex.VALUE] * 0.01));
            effectiveCost = max(effectiveCost, entry[self.ItemHistoryIndex.FLOOR]);
            decayCount = decayCount + 1;
        end
    end

    if effectiveCost == 0 then
        return false;
    end
    return { cost = effectiveCost, category = cost.category }, decayCount;
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

function ABGP:CalculateCurrentGP(player, category, history)
    history = history or self:ProcessItemHistory(_G.ABGP_Data2.history.data, true);
    local gp = 0;
    for i = #history, 1, -1 do
        local entry = history[i];
        local entryType = entry[self.ItemHistoryIndex.TYPE];
        if (entryType == self.ItemHistoryType.ITEM or entryType == self.ItemHistoryType.BONUS) and
           entry[self.ItemHistoryIndex.PLAYER] == player and
           entry[self.ItemHistoryIndex.CATEGORY] == category then
            gp = gp + entry[self.ItemHistoryIndex.GP];
            -- print("adding", entry[self.ItemHistoryIndex.GP]);
        elseif entryType == self.ItemHistoryType.DECAY then
            gp = gp * (1 - (entry[self.ItemHistoryIndex.VALUE] * 0.01));
            gp = max(gp, entry[self.ItemHistoryIndex.FLOOR]);
            -- print("decaying");
        elseif entryType == self.ItemHistoryType.RESET and
               entry[self.ItemHistoryIndex.PLAYER] == player and
               entry[self.ItemHistoryIndex.CATEGORY] == category then
            gp = entry[self.ItemHistoryIndex.GP];
            -- print("resetting", entry[self.ItemHistoryIndex.GP]);
        end
    end

    return gp;
end

function ABGP:HasCompleteHistory(shouldPrint)
    if hasCompleteCached and not shouldPrint then return hasComplete; end

    hasComplete = true;
    local history = self:ProcessItemHistory(_G.ABGP_Data2.history.data, true);
    for category in pairs(self.ItemCategory) do
        for player, epgp in pairs(self:GetActivePlayers()) do
            if not epgp.trial then
                local calculated = self:CalculateCurrentGP(player, category, history);
                if abs(calculated - epgp.gp[category]) > 0.0015 then
                    hasComplete = false;
                    if shouldPrint then
                        self:Notify("Incomplete %s history for %s: expected %.3f, calculated %.3f.",
                            self.ItemCategoryNames[category], self:ColorizeName(player), epgp.gp[category], calculated);
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

function ABGP:HistoryUpdateItemAward(data, player, cost)
    local commData = {
        itemLink = data.itemLink,
        oldHistoryId = data.historyId,
        awarded = data.awarded,
        player = player,
        cost = cost,
        requestType = self.RequestTypes.MANUAL,
        updateId = ABGP:GetHistoryId(),
        historyId = ABGP:GetHistoryId(),
    };
    self:SendComm(self.CommTypes.ITEM_AWARDED, commData, "BROADCAST");
end

function ABGP:HistoryDeleteItemAward(data)
    local commData = {
        itemLink = data.itemLink,
        oldHistoryId = data.historyId,
        updateId = ABGP:GetHistoryId(),
    };
    self:SendComm(self.CommTypes.ITEM_AWARDED, commData, "BROADCAST");
end

function ABGP:HistoryDeleteEntry(entry, deleteId)
    if not deleteId then deleteId = self:GetHistoryId(); end
    local history = _G.ABGP_Data2.history.data;

    local _, deleteDate = self:ParseHistoryId(deleteId);
    table.insert(history, 1, {
        [ABGP.ItemHistoryIndex.TYPE] = ABGP.ItemHistoryType.DELETE,
        [ABGP.ItemHistoryIndex.ID] = deleteId,
        [ABGP.ItemHistoryIndex.DATE] = deleteDate,
        [ABGP.ItemHistoryIndex.DELETEDID] = entry[ABGP.ItemHistoryIndex.ID],
    });

    self:Fire(self.InternalEvents.HISTORY_UPDATED);
end
