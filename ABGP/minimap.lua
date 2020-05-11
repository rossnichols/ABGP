local _G = _G;
local ABGP = _G.ABGP;
local LibDataBroker = _G.LibStub("LibDataBroker-1.1");
local LibDBIcon = _G.LibStub("LibDBIcon-1.0");

local CreateFrame = CreateFrame;
local table = table;

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

function ABGP:RefreshMinimapIcon()
    LibDBIcon:Refresh("ABGP", self.db.char.minimap);
end

function ABGP:OnIconCreated(event, frame, name)
    if name ~= "ABGP" then return; end

    minimapIcon = frame;
    -- frame:SetScale(5);
    frame.icon:SetSize(18, 18);
    frame.tooltip = CreateFrame("GameTooltip", "ABGPMinimapTooltip", nil, "GameTooltipTemplate");
    _G.ABGPMinimapTooltipTextLeft1:SetFontObject("GameFontNormalSmall");
end

local function ShouldOverride()
    return ABGP:HasActiveItems() and ABGP:HasHiddenItemRequests();
end

local function UpdateIcon()
    if not minimapIcon or not minimapIcon:IsVisible() then return; end

    local override = ShouldOverride();
    if override then
        minimapIcon:LockHighlight();
        if suppressTooltip then
            minimapIcon.tooltip:Hide();
        else
            minimapIcon.tooltip:SetOwner(minimapIcon, "ANCHOR_BOTTOMLEFT", 8, 8);
            minimapIcon.tooltip:SetText(("%s: Items Hidden!"):format(ABGP:ColorizeText("ABGP")), 1, 1, 1);
        end
    else
        minimapIcon:UnlockHighlight();
        minimapIcon.tooltip:Hide();
    end
end

function ABGP:MinimapOnDistOpened(data, distribution, sender)
    UpdateIcon();
end

function ABGP:MinimapOnDistClosed(data, distribution, sender)
    UpdateIcon();
end

function ABGP:MinimapOnLootFrameOpened(data)
    UpdateIcon();
end

function ABGP:MinimapOnLootFrameClosed(data)
    UpdateIcon();
end

function ABGP:OnIconClick(frame, button)
    if button == "LeftButton" then
        if ShouldOverride() then
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
        if self:IsPrivileged() then
            table.insert(context, {
                text = self:IsRaidInProgress() and "Manage Raid" or "Start Raid",
                func = function() self:ShowRaidWindow(); end,
                notCheckable = true
            });
        end
        if self:HasActiveItems() then
            table.insert(context, {
                text = "Show Open Items",
                func = function() self:ShowItemRequests(); end,
                notCheckable = true
            });
        end
        table.insert(context, { text = "Cancel", notCheckable = true });
        self:ShowContextMenu(context, frame);
    end
end

function ABGP:OnIconTooltip(tooltip)
    suppressTooltip = true;
    UpdateIcon();

    local header = ("%s v%s"):format(self:ColorizeText("ABGP"), self:GetVersion());
    tooltip:AddLine(header, 1, 1, 1);
    if ShouldOverride() then
        tooltip:AddLine("Left-click to show open items.");
    else
        tooltip:AddLine("Left-click to show the main window.");
    end
    tooltip:AddLine("Right-click for more options.");
end

function ABGP:OnIconLeave(frame)
    suppressTooltip = false;
    UpdateIcon();
end
