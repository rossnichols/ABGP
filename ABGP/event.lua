local _G = _G;
local ABGP = ABGP;

local pairs = pairs;

local function FindInstance(instanceId)
    for phase, instances in pairs(ABGP.Instances) do
        for id in pairs(instances) do
            if id == instanceId then
                return phase;
            end
        end
    end
end

local function FindBoss(bossId)
    for phase, bosses in pairs(ABGP.Bosses) do
        for id in pairs(bosses) do
            if id == bossId then
                return phase;
            end
        end
    end
end

function ABGP:EventOnBossKilled(bossId, name)
    self:LogDebug("%s defeated!", name);
    local phase = FindBoss(bossId);
    if phase then
        self:LogDebug("This boss is associated with phase %s (%d => %s)",
            phase, bossId, self.Bosses[phase][bossId]);
    end
end

function ABGP:EventOnZoneChanged(name, instanceId)
    self:LogDebug("Zone changed to %s!", name);
    local phase = FindInstance(instanceId);
    if phase then
        self:LogDebug("This instance is associated with phase %s (%d => %s)",
            phase, instanceId, self.Instances[phase][instanceId]);
        self.CurrentPhase = phase;
    end
end