local _G = _G;
local ABGP = _G.ABGP;
local LibDataBroker = _G.LibStub("LibDataBroker-1.1");
local LibDBIcon = _G.LibStub("LibDBIcon-1.0");

local CreateFrame = CreateFrame;
local GetScreenWidth = GetScreenWidth;
local GetScreenHeight = GetScreenHeight;
local IsControlKeyDown = IsControlKeyDown;
local IsShiftKeyDown = IsShiftKeyDown;
local IsAltKeyDown = IsAltKeyDown;
local table = table;
local unpack = unpack;

local minimapIcon;
local suppressTooltip = false;

function ABGP:InitMinimapIcon()
    local obj = LibDataBroker:NewDataObject("ABGP", {
        icon = "Interface\\AddOns\\ABGP\\Assets\\lobster.tga",
        OnClick = function(frame, button) self:OnIconClick(frame, button); end,
        OnTooltipShow = function(tooltip) self:OnIconTooltip(tooltip); end,
        OnLeave = function(frame) self:OnIconLeave(frame); end,
    });
    LibDBIcon.RegisterCallback(self, "LibDBIcon_IconCreated", "OnIconCreated");
    LibDBIcon:Register("ABGP", obj, self.db.char.minimap);
end

function ABGP:OnIconCreated(event, frame, name)
    if name ~= "ABGP" then return; end

    minimapIcon = frame;
    -- frame:SetScale(5);
    frame.icon:SetSize(18, 18);
    frame.tooltip = CreateFrame("GameTooltip", "ABGPMinimapTooltip", _G.UIParent, "GameTooltipTemplate");
    _G.ABGPMinimapTooltipTextLeft1:SetFontObject("GameFontNormalSmall");
    frame.tooltip:SetScript("OnUpdate", function(self, elapsed)
        self:SetAlpha(ABGP:IsContextMenuOpen() and 0 or 1);
    end);
end

local function ShouldOverride()
    return ABGP:Get("minimapAlert") and ABGP:HasActiveItems() and ABGP:HasHiddenItemRequests();
end

local function UpdateIcon()
    if not minimapIcon or not minimapIcon:IsVisible() then return; end

    local override = ShouldOverride();
    if override then
        minimapIcon:LockHighlight();
        if suppressTooltip then
            minimapIcon.tooltip:Hide();
        else
            local offset = 7;
            local anchors = {
                [true] = {
                    [true] = { "ANCHOR_RIGHT", -offset, -offset }, -- bottomleft
                    [false] = { "ANCHOR_BOTTOMRIGHT", -offset, offset }, -- topleft
                },
                [false] = {
                    [true] = { "ANCHOR_LEFT", offset, -offset }, -- bottomright
                    [false] = { "ANCHOR_BOTTOMLEFT", offset, offset }, -- topright
                },
            };
            local left, bottom = minimapIcon:GetRect();
            local scale = minimapIcon:GetEffectiveScale();
            left, bottom = left / scale, bottom / scale;
            local anchor = anchors[left < GetScreenWidth() / 2][bottom < GetScreenHeight() / 2];
            minimapIcon.tooltip:SetOwner(minimapIcon, unpack(anchor));
            minimapIcon.tooltip:SetText(("%s: Items Hidden!"):format(ABGP:ColorizeText("ABGP")), 1, 1, 1);
        end
    else
        minimapIcon:UnlockHighlight();
        minimapIcon.tooltip:Hide();
    end
end

function ABGP:RefreshMinimapIcon()
    LibDBIcon:Refresh("ABGP", self.db.char.minimap);
    UpdateIcon();
end

function ABGP:MinimapOnDistOpened(data, distribution, sender)
    UpdateIcon();
end

function ABGP:MinimapOnDistClosed(data)
    UpdateIcon();
end

function ABGP:MinimapOnLootFrameOpened()
    UpdateIcon();
end

function ABGP:MinimapOnLootFrameClosed()
    UpdateIcon();
end

function ABGP:OnIconClick(frame, button)
    if button == "LeftButton" then
        if IsShiftKeyDown() then
            self:ShowOptionsWindow();
        elseif IsControlKeyDown() and self:IsPrivileged() then
            self:ShowRaidWindow();
        elseif ShouldOverride() then
            self:ShowItemRequests();
        else
            self:ShowMainWindow();
        end
    elseif button == "RightButton" then
        local context = {
            {
                text = "Show Window",
                func = function() self:ShowMainWindow(); end,
                notCheckable = true
            },
            {
                text = "Show Options",
                func = function() self:ShowOptionsWindow(); end,
                notCheckable = true
            },
        };
        if self:HasActiveItems() then
            table.insert(context, {
                text = "Show Open Items",
                func = function() self:ShowItemRequests(); end,
                notCheckable = true
            });
        end
        if self:IsPrivileged() then
            table.insert(context, {
                text = self:IsRaidInProgress() and "Manage Raid" or "Start Raid",
                func = function() self:ShowRaidWindow(); end,
                notCheckable = true
            });
            table.insert(context, {
                text = "Version Check",
                func = function() self:PerformVersionCheck(); end,
                notCheckable = true
            });
        end
        if self:Get("commMonitoringEnabled") then
            table.insert(context, {
                text = "Dump Addon Comms",
                func = function() self:DumpCommMonitor(true); end,
                notCheckable = true
            });
        end
        table.insert(context, { text = "Cancel", notCheckable = true, fontObject = "GameFontDisableSmall" });
        self:ShowContextMenu(context, frame);
    end
end

function ABGP:OnIconTooltip(tooltip)
    suppressTooltip = true;
    UpdateIcon();

    local header = ("%s v%s"):format(self:ColorizeText("ABGP"), self:GetVersion());
    tooltip:AddLine(header, 1, 1, 1);
    if ShouldOverride() then
        tooltip:AddLine("|cffff0000NOTE:|r There are items being distributed that are currently hidden!");
        tooltip:AddLine("|cffffffffClick|r to show open items.");
    else
        tooltip:AddLine("|cffffffffClick|r to show the main window.");
    end
    tooltip:AddLine("|cffffffffShift-click|r to show the options window.");
    if self:IsPrivileged() then
        tooltip:AddLine("|cffffffffControl-click|r to show the raid window.");
        tooltip:AddLine("|cffffffffAlt-click|r to show the import window.");
    end
    tooltip:AddLine("|cffffffffRight-click|r for more options.");
end

function ABGP:OnIconLeave(frame)
    suppressTooltip = false;
    UpdateIcon();
end
