--[[-------------------------------------------------------------------------
  Trond A Ekseth grants anyone the right to use this work for any purpose,
  without any conditions, unless such conditions are required by law.
---------------------------------------------------------------------------]]

local _TEXTURE = [[Interface\AddOns\oUF_Classic\textures\statusbar]]

local colors = setmetatable({
	health = {.45, .73, .27},
	power = setmetatable({
		['MANA'] = {.27, .53, .73},
		['RAGE'] = {.73, .27, .27},
	}, {__index = oUF.colors.power}),
}, {__index = oUF.colors})

local siValue = function(val)
	if(val >= 1e6) then
		return ('%.1f'):format(val / 1e6):gsub('%.', 'm')
	elseif(val >= 1e4) then
		return ("%.1f"):format(val / 1e3):gsub('%.', 'k')
	else
		return val
	end
end

oUF.Tags.Methods['classic:health'] = function(unit)
	if(not UnitIsConnected(unit) or UnitIsDead(unit) or UnitIsGhost(unit)) then return end
	return siValue(UnitHealth(unit)) .. '/' .. siValue(UnitHealthMax(unit))
end
oUF.Tags.Events['classic:health'] = oUF.Tags.Events.missinghp

oUF.Tags.Methods['classic:power'] = function(unit)
	local min, max = UnitPower(unit), UnitPowerMax(unit)
	if(min == 0 or max == 0 or not UnitIsConnected(unit) or UnitIsDead(unit) or UnitIsGhost(unit)) then return end

	return siValue(min) .. '/' .. siValue(max)
end
oUF.Tags.Events['classic:power'] = oUF.Tags.Events.missingpp

local PostUpdateHealth = function(health, unit, min, max)
	local self = health:GetParent()
	if(UnitIsTapped(unit) and not UnitIsTappedByPlayer(unit) or not UnitIsConnected(unit)) then
		self:SetBackdropBorderColor(.3, .3, .3)
	else
		local r, g, b = UnitSelectionColor(unit)
		self:SetBackdropBorderColor(r, g, b)
	end

	if(UnitIsDead(unit)) then
		health:SetValue(0)
	elseif(UnitIsGhost(unit)) then
		health:SetValue(0)
	end
end

local PostUpdatePower = function(power, unit,min, max)
	if(UnitIsDead(unit) or UnitIsGhost(unit)) then
		power:SetValue(0)
	end
end

local backdrop = {
	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true, tileSize = 16,
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 16,
	insets = {left = 4, right = 4, top = 4, bottom = 4},
}

local Shared = function(self, unit, isSingle)
	self:SetScript("OnEnter", UnitFrame_OnEnter)
	self:SetScript("OnLeave", UnitFrame_OnLeave)

	self:RegisterForClicks"AnyUp"

	self:SetBackdrop(backdrop)
	self:SetBackdropColor(0, 0, 0, 1)
	self:SetBackdropBorderColor(.3, .3, .3, 1)

	-- Health bar
	local Health = CreateFrame("StatusBar", nil, self)
	Health:SetHeight(14)
	Health:SetStatusBarTexture(_TEXTURE)

	Health:SetPoint("TOP", 0, -8)
	Health:SetPoint("LEFT", 8, 0)
	Health:SetPoint('RIGHT', -90, 0)

	Health.frequentUpdates = true
	Health.colorDisconnected = true
	Health.colorTapping = true
	Health.colorSmooth = true

	Health.PostUpdate = PostUpdateHealth

	self.Health = Health

	local HealthPoints = Health:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	HealthPoints:SetPoint("LEFT", Health, "RIGHT", 2, -1)
	HealthPoints:SetPoint("RIGHT", self, -6, -1)
	HealthPoints:SetJustifyH"CENTER"
	HealthPoints:SetFont(GameFontNormal:GetFont(), 10)
	HealthPoints:SetTextColor(1, 1, 1)

	self:Tag(HealthPoints, '[dead][offline][classic:health]')

	Health.value = HealthPoints

	-- Health bar background
	local HealthBackground = Health:CreateTexture(nil, "BORDER")
	HealthBackground:SetAllPoints(Health)
	HealthBackground:SetAlpha(.5)
	HealthBackground:SetTexture(_TEXTURE)
	Health.bg = HealthBackground

	local Castbar = CreateFrame("StatusBar", nil, self)
	Castbar:SetStatusBarTexture(_TEXTURE)
	Castbar:SetStatusBarColor(.73, 0, .27, .8)
	Castbar:SetAllPoints(Health)
	Castbar:SetToplevel(true)
	self.Castbar = Castbar

	-- Unit name
	local Name = Health:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	Name:SetPoint("LEFT", 2, -1)
	Name:SetPoint("RIGHT", -2, -1)
	Name:SetJustifyH"LEFT"
	Name:SetFont(GameFontNormal:GetFont(), 11)
	Name:SetTextColor(1, 1, 1)

	self:Tag(Name, '[name]')
	self.Name = Name

	local Leader = self:CreateTexture(nil, "OVERLAY")
	Leader:SetSize(16, 16)
	Leader:SetPoint("BOTTOM", self, "TOP", 0, -7)
	self.Leader = Leader

	-- enable our colors
	self.colors = colors

	if(isSingle) then
		self:SetSize(260, 48)
	end
end

local DoAuras = function(self)
	-- Buffs
	local Buffs = CreateFrame("Frame", nil, self)
	Buffs:SetPoint("BOTTOM", self, "TOP")
	Buffs:SetPoint'LEFT'
	Buffs:SetPoint'RIGHT'
	Buffs:SetHeight(17)

	Buffs.size = 17
	Buffs.num = math.floor(self:GetWidth() / Buffs.size + .5)

	self.Buffs = Buffs

	-- Debuffs
	local Debuffs = CreateFrame("Frame", nil, self)
	Debuffs:SetPoint("TOP", self, "BOTTOM")
	Debuffs:SetPoint'LEFT'
	Debuffs:SetPoint'RIGHT'
	Debuffs:SetHeight(20)

	Debuffs.initialAnchor = "TOPLEFT"
	Debuffs.size = 20
	Debuffs.showDebuffType = true
	Debuffs.num = math.floor(self:GetWidth() / Debuffs.size + .5)

	self.Debuffs = Debuffs
end

local DoPower = function(self)
	-- Power bar
	local Power = CreateFrame("StatusBar", nil, self)
	Power:SetHeight(14)
	Power:SetStatusBarTexture(_TEXTURE)

	Power:SetPoint("BOTTOM", 0, 8)
	Power:SetPoint("LEFT", 8, 0)
	Power:SetPoint('RIGHT', -90, 0)

	Power.colorPower = true
	Power.frequentUpdates = true

	self.Power = Power

	-- Power bar background
	local PowerBackground = Power:CreateTexture(nil, "BORDER")
	PowerBackground:SetAllPoints(Power)
	PowerBackground:SetAlpha(.5)
	PowerBackground:SetTexture(_TEXTURE)
	Power.bg = PowerBackground

	local PowerPoints = Power:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	PowerPoints:SetPoint("LEFT", Power, "RIGHT", 2, -1)
	PowerPoints:SetPoint("RIGHT", self, -6, -1)
	PowerPoints:SetJustifyH"CENTER"
	PowerPoints:SetFont(GameFontNormal:GetFont(), 10)
	PowerPoints:SetTextColor(1, 1, 1)

	self:Tag(PowerPoints, '[classic:power]')

	Power.value = PowerPoints

	Power.PostUpdate = PostUpdatePower

	-- Info string
	local Info = Power:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	Info:SetPoint("LEFT", 2, -1)
	Info:SetPoint("RIGHT", -2, -1)
	Info:SetJustifyH"LEFT"
	Info:SetFont(GameFontNormal:GetFont(), 11)
	Info:SetTextColor(1, 1, 1)

	self:Tag(Info, 'L[level][shortclassification] [raidcolor][smartclass]')
	self.Info = Info
end

local UnitSpecific = {
	target = function(self, ...)
		Shared(self, ...)

		DoAuras(self)
		DoPower(self)
	end,

	targettarget = function(self, unit, isSingle)
		Shared(self, unit, isSingle)

		DoAuras(self)

		if(isSingle) then
			self:SetHeight(32)
		end
	end,
}

do
	local PLAYER_UPDATE_RESTING = function(self)
		if(IsResting()) then
			self:SetBackdropBorderColor(.3, .3, .8)
		else
			local r, g, b = UnitSelectionColor(self.unit)
			self:SetBackdropBorderColor(r, g, b)
		end
	end

	UnitSpecific.player = function(self, ...)
		Shared(self, ...)

		DoPower(self)

		self:RegisterEvent("PLAYER_UPDATE_RESTING", PLAYER_UPDATE_RESTING)
	end
end

do
	local range = {
		insideAlpha = 1,
		outsideAlpha = .5,
	}

	UnitSpecific.party = function(self, ...)
		Shared(self, ...)

		DoAuras(self)
		DoPower(self)

		self.Range = range
	end
end

oUF:RegisterStyle("Classic", Shared)
for unit,layout in next, UnitSpecific do
	-- Capitalize the unit name, so it looks better.
	oUF:RegisterStyle('Classic - ' .. unit:gsub("^%l", string.upper), layout)
end

-- A small helper to change the style into a unit specific, if it exists.
local spawnHelper = function(self, unit, ...)
	if(UnitSpecific[unit]) then
		self:SetActiveStyle('Classic - ' .. unit:gsub("^%l", string.upper))
	else
		self:SetActiveStyle'Classic'
	end

	local object = self:Spawn(unit)
	object:SetPoint(...)
	return object
end

oUF:Factory(function(self)
	local player = spawnHelper(self, 'player', "CENTER", -200, -380)
	spawnHelper(self, 'pet', 'TOP', player, 'BOTTOM', 0, -16)
	spawnHelper(self, 'target', "CENTER", 200, -380)
	spawnHelper(self, 'targettarget', "CENTER", 0, -250)

	self:SetActiveStyle'Classic - Party'
	local party = self:SpawnHeader(nil, nil, 'raid,party',
		'showParty', true,
		'yOffset', -40,
		'xOffset', -40,
		'maxColumns', 2,
		'unitsPerColumn', 2,
		'columnAnchorPoint', 'LEFT',
		'columnSpacing', 15,

		'oUF-initialConfigFunction', [[
			self:SetWidth(260)
			self:SetHeight(48)
		]]
	)
	party:SetPoint("TOPLEFT", 30, -30)
end)
