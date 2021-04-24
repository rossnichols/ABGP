local _G = _G;
local ABGP = _G.ABGP;

local GetNumGuildMembers = GetNumGuildMembers;
local GetGuildRosterInfo = GetGuildRosterInfo;
local GetServerTime = GetServerTime;
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
local date = date;

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

local function UpdateEPGP(player, cost)
    local epgp = ABGP:GetActivePlayer(player);
    if epgp and not epgp.trial then
        epgp.gp[cost.category] = epgp.gp[cost.category] + cost.cost;
        epgp.priority[cost.category] = epgp.ep * 10 / epgp.gp[cost.category];
        local proxy = epgp.proxy and ("[%s]"):format(epgp.proxy) or "";
        ABGP:LogVerbose("EPGP[%s] for %s%s: EP=%.3f GP=%.3f(+%d) PRIORITY=%.3f",
            cost.category, player, proxy, epgp.ep, epgp.gp[cost.category], cost.cost, epgp.priority);
        table.sort(ABGP.Priorities, PrioritySort);

        ABGP:RefreshActivePlayers();
        return true;
    end

    return false;
end

function ABGP:HistoryTriggerDecay(decayTime)
    local decayValue, decayFloor = self:GetGPDecayInfo();
    self:AddHistoryEntry(self.ItemHistoryType.GPDECAY, {
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

    self:AddHistoryEntry(self.ItemHistoryType.GPRESET, {
        [self.ItemHistoryIndex.DATE] = addTime,
        [self.ItemHistoryIndex.PLAYER] = player,
        [self.ItemHistoryIndex.GP] = gpS,
        [self.ItemHistoryIndex.CATEGORY] = self.ItemCategory.SILVER,
        [self.ItemHistoryIndex.NOTES] = "New active raider",
    }, true);
    self:AddHistoryEntry(self.ItemHistoryType.GPRESET, {
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
end

function ABGP:AddHistoryEntry(entryType, entry, skipEvent)
    entry[self.ItemHistoryIndex.TYPE] = entryType;
    entry[self.ItemHistoryIndex.ID] = self:GetHistoryId();

    if not entry[self.ItemHistoryIndex.DATE] then
        local _, entryDate = self:ParseHistoryId(entry[self.ItemHistoryIndex.ID]);
        entry[self.ItemHistoryIndex.DATE] = entryDate;
    end

    table.insert(_G.ABGP_Data2.history.data, 1, entry);

    self:HistoryBroadcastEntries({ [entry[self.ItemHistoryIndex.ID]] = entry });

    if not skipEvent then
        self:UpdateHistory();
    end

    return entry;
end

function ABGP:UpdateHistory()
    self:Fire(self.InternalEvents.HISTORY_UPDATED);
end

function ABGP:AddTrial(player, raidGroup, proxy)
    local raidGroupName = self.RaidGroupNames[raidGroup];
    if proxy then
        self:Notify("Adding %s (proxied by %s) as a trial for the %s raid group.", self:ColorizeName(player), self:ColorizeName(proxy), raidGroupName);
        _G.GuildRosterSetPublicNote(self:GetGuildIndex(proxy), ("ABGP RG:%s P:%s"):format(raidGroupName, player));
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
            if entryType == ABGP.ItemHistoryType.GPITEM then
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

function ABGP:GetMispricedAwards(timeLen)
    timeLen = timeLen or 30 * 24 * 60 * 60;
    local history = self:ProcessItemHistory(_G.ABGP_Data2.history.data, false);
    local endTime = GetServerTime() - timeLen;

    for i, entry in ipairs(history) do
        if entry[self.ItemHistoryIndex.DATE] < endTime then break; end

        local gp = entry[self.ItemHistoryIndex.GP];
        local cat = entry[self.ItemHistoryIndex.CATEGORY];
        local itemLink = entry[self.ItemHistoryIndex.ITEMLINK];
        local value = self:GetItemValue(self:GetItemId(itemLink));
        if value and gp ~= 0 and (gp ~= value.gp or cat ~= value.category) then
            local entryMsg = ("%s to %s for %s on %s now costs %s"):format(
                value.itemLink,
                self:ColorizeName(entry[self.ItemHistoryIndex.PLAYER]),
                self:FormatCost(entry[self.ItemHistoryIndex.GP], entry[self.ItemHistoryIndex.CATEGORY]),
                date("%m/%d/%y", entry[self.ItemHistoryIndex.DATE]),
                self:FormatCost(value.gp, value.category));
            self:Notify(entryMsg);
        end
    end
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
        elseif cost ~= 0 and entry[self.ItemHistoryIndex.TYPE] == self.ItemHistoryType.GPDECAY then
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
    -- ITEMTODO: kind of expensive to refresh item values if you get non-item history entries
    self:RefreshItemValues();
    hasCompleteCached = false;
end

function ABGP:CalculateCurrentGP(player, category, history)
    history = history or self:ProcessItemHistory(_G.ABGP_Data2.history.data, true);
    local gp = 0;
    for i = #history, 1, -1 do
        local entry = history[i];
        local entryType = entry[self.ItemHistoryIndex.TYPE];
        if (entryType == self.ItemHistoryType.GPITEM or entryType == self.ItemHistoryType.GPBONUS) and
           entry[self.ItemHistoryIndex.PLAYER] == player and
           entry[self.ItemHistoryIndex.CATEGORY] == category then
            gp = gp + entry[self.ItemHistoryIndex.GP];
            -- print("adding", entry[self.ItemHistoryIndex.GP], "=>", gp);
        elseif entryType == self.ItemHistoryType.GPDECAY then
            gp = gp * (1 - (entry[self.ItemHistoryIndex.VALUE] * 0.01));
            gp = max(gp, entry[self.ItemHistoryIndex.FLOOR]);
            -- print("decaying", "=>", gp);
        elseif entryType == self.ItemHistoryType.GPRESET and
               entry[self.ItemHistoryIndex.PLAYER] == player and
               entry[self.ItemHistoryIndex.CATEGORY] == category then
            gp = entry[self.ItemHistoryIndex.GP];
            -- print("resetting", entry[self.ItemHistoryIndex.GP], "=>", gp);
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

function ABGP:HistoryAwardItem(data, testItem, skipOfficerNote)
    local commData = {
        itemLink = data.itemLink,
        selectedItem = data.selectedItem,
        player = data.player,
        cost = data.cost,
        roll = data.roll,
        requestType = data.requestType,
        override = data.override,
        count = data.count,
        testItem = testItem,
    };
    self:SendComm(self.CommTypes.ITEM_AWARDED, commData, "BROADCAST");

    if not testItem then
        local itemLink = data.selectedItem or data.itemLink;
        local tokenLink = data.selectedItem and data.itemLink or nil;
        local entry = self:AddHistoryEntry(self.ItemHistoryType.GPITEM, {
            [self.ItemHistoryIndex.DATE] = data.awarded,
            [self.ItemHistoryIndex.PLAYER] = data.player,
            [self.ItemHistoryIndex.ITEMLINK] = itemLink,
            [self.ItemHistoryIndex.TOKENLINK] = tokenLink,
            [self.ItemHistoryIndex.GP] = data.cost.cost,
            [self.ItemHistoryIndex.CATEGORY] = data.cost.category,
        });

        if data.cost.category and data.cost.cost ~= 0 then
            local cost = {
                cost = entry[self.ItemHistoryIndex.GP],
                category = entry[self.ItemHistoryIndex.CATEGORY]
            };
            cost = self:GetEffectiveCost(entry[self.ItemHistoryIndex.ID], cost) or cost;
            if UpdateEPGP(data.player, cost) and not skipOfficerNote and not self:GetDebugOpt("SkipOfficerNote") then
                local epgp = ABGP:GetActivePlayer(data.player);
                -- UpdateOfficerNote expects the name of the guild member
                -- that is being updated, which is the proxy if it's set.
                ABGP:UpdateOfficerNote(epgp.proxy or data.player);
            end
        end
    end
end

function ABGP:HistoryUpdateItemAward(entry, player, cost, selectedItem)
    local samePlayer = (entry[ABGP.ItemHistoryIndex.PLAYER] == player);
    local itemLink = entry[self.ItemHistoryIndex.TOKENLINK] or entry[self.ItemHistoryIndex.ITEMLINK];

    -- Remove old entry.
    self:HistoryDeleteItemAward(entry, samePlayer);

    -- Add new entry.
    self:HistoryAwardItem({
        itemLink = itemLink,
        selectedItem = selectedItem,
        awarded = entry[self.ItemHistoryIndex.DATE],
        requestType = self.RequestTypes.MANUAL,
        player = player,
        cost = cost,
        updated = true,
    }, false, samePlayer);

    if samePlayer then
        -- We suppressed updating officer note above. Do it now.
        local epgp = ABGP:GetActivePlayer(player);
        if epgp and not epgp.trial then
            -- UpdateOfficerNote expects the name of the guild member
            -- that is being updated, which is the proxy if it's set.
            ABGP:UpdateOfficerNote(epgp.proxy or player);
        end
    end
end

function ABGP:HistoryDeleteItemAward(entry, skipOfficerNote)
    local player = entry[ABGP.ItemHistoryIndex.PLAYER];
    local commData = {
        itemLink = entry[self.ItemHistoryIndex.ITEMLINK],
        player = player
    };
    self:SendComm(self.CommTypes.ITEM_UNAWARDED, commData, "BROADCAST");

    self:HistoryDeleteEntry(entry);

    if entry[self.ItemHistoryIndex.CATEGORY] and entry[self.ItemHistoryIndex.GP] ~= 0 then
        local cost = {
            cost = entry[self.ItemHistoryIndex.GP],
            category = entry[self.ItemHistoryIndex.CATEGORY]
        };
        cost = self:GetEffectiveCost(entry[self.ItemHistoryIndex.ID], cost) or cost;
        cost.cost = -cost.cost;
        if UpdateEPGP(player, cost) and not skipOfficerNote and not self:GetDebugOpt("SkipOfficerNote") then
            local epgp = ABGP:GetActivePlayer(player);
            -- UpdateOfficerNote expects the name of the guild member
            -- that is being updated, which is the proxy if it's set.
            ABGP:UpdateOfficerNote(epgp.proxy or player);
        end
    end
end

function ABGP:HistoryDeleteEntry(entry)
    self:AddHistoryEntry(self.ItemHistoryType.DELETE, {
        [ABGP.ItemHistoryIndex.DELETEDID] = entry[ABGP.ItemHistoryIndex.ID],
    });
end
