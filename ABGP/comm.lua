local AceSerializer = LibStub("AceSerializer-3.0");
local LibCompress = LibStub("LibCompress");
local AddonEncodeTable = LibCompress:GetAddonEncodeTable();

local function GetBroadcastChannel()
    if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
        return "INSTANCE_CHAT";
    elseif GetNumGroupMembers() > 0 and IsInRaid() then
        return "RAID";
    elseif IsInGroup() then
        return "PARTY";
    else
        return "WHISPER", UnitName("player");
    end
end

ABGP.CommTypes = {
    ITEM_REQUEST = "ABGP_ITEM_REQUEST",
    -- itemLink: item link string
    -- role: "ms" or "os"
    -- notes: string or nil
    -- equipped: array of item link strings

    ITEM_PASS = "ABGP_ITEM_PASS",
    -- itemLink: item link string

    ITEM_DISTRIBUTION_OPENED = "ABGP_ITEM_DISTRIBUTION_OPENED",
    -- itemLink: item link string

    ITEM_DISTRIBUTION_CLOSED = "ABGP_ITEM_DISTRIBUTION_CLOSED",
    -- itemLink: item link string
};

function ABGP:SendComm(data, distribution, target)
    data.version = GetAddOnMetadata("ABGP", "Version");

    local serialized = AceSerializer:Serialize(data);
    local compressed = LibCompress:Compress(serialized);
    local payload = AddonEncodeTable:Encode(compressed);

    if distribution == "BROADCAST" then
        distribution, target = GetBroadcastChannel();
    end

    self:SendCommMessage("ABGP", payload, distribution, target);
end

function ABGP:OnCommReceived(prefix, payload, distribution, sender)
    local compressed = AddonEncodeTable:Decode(payload);
    local serialized = LibCompress:Decompress(compressed);
    local _, data = AceSerializer:Deserialize(serialized);

    if self.Debug then
        self:Notify("COMM >>>");
        self:Notify("Data from %s via %s:", sender, distribution);
        for k, v in pairs(data) do
            if type(v) == "table" then v = table.concat(v, ", "); end
            self:Notify("%s: %s", k, v);
        end
        self:Notify("<<< COMM");
    end

    self:SendMessage(data.type, data, distribution, sender);
end
