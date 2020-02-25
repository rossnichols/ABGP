ABGP.Debug = true;
-- ABGP.Verbose = true;
-- ABGP.PrivateComms = true;
ABGP.IgnoreSelfDistributed = true;
ABGP.VersionDebug = "3.2.2";
ABGP.VersionCmpDebug = "3.2.2";

function ABGP:FixupHistory()
    self.lookup = {};
    local failed = false;

    local mc = AtlasLoot.ItemDB.Storage.AtlasLootClassic_DungeonsAndRaids.MoltenCore.items;
    local ony = AtlasLoot.ItemDB.Storage.AtlasLootClassic_DungeonsAndRaids.Onyxia.items;
    local wb = AtlasLoot.ItemDB.Storage.AtlasLootClassic_DungeonsAndRaids.WorldBosses.items;
    local bwl = AtlasLoot.ItemDB.Storage.AtlasLootClassic_DungeonsAndRaids.BlackwingLair.items;
    for _, collection in ipairs({ mc, ony, wb, bwl }) do
        for _, sub in ipairs(collection) do
            if sub[1] then
                for _, item in ipairs(sub[1]) do
                    local name, link = GetItemInfo(item[2]);
                    if name then
                        self.lookup[name] = link;
                    else
                        failed = true;
                    end
                end
            end
        end
    end

    if failed then
        print("Failed to query some items!");
        return;
    end

    local p1 = ABGP_Data.p1.gpHistory;
    local p3 = ABGP_Data.p3.gpHistory;
    for _, phase in ipairs({ p1, p3 }) do
        for _, entry in ipairs(phase) do
            if self.lookup[entry.item] then
                entry.itemLink = self.lookup[entry.item];
            else
                for name, link in pairs(self.lookup) do
                    local lowered = entry.item:lower();
                    if lowered:find(name:lower(), 1, true) then
                        print(("Updating [%s] to [%s]"):format(entry.item, name));
                        entry.item = name;
                        entry.itemLink = link;
                        break;
                    end
                end
                if not entry.itemLink then
                    print(("FAILED TO FIND [%s]"):format(entry.item));
                end
            end
            local epgp = ABGP:GetActivePlayer(entry.player);
            if epgp then
                if epgp.p1 then entry.class = epgp.p1.class; end
                if epgp.p3 then entry.class = epgp.p3.class; end
            end
        end
    end
end
