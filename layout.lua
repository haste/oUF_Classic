--[[-------------------------------------------------------------------------
  Trond A Ekseth grants anyone the right to use this work for any purpose,
  without any conditions, unless such conditions are required by law.
---------------------------------------------------------------------------]]

local texture = [[Interface\AddOns\oUF_Classic\textures\statusbar]]
local height, width = 47, 260
local UnitReactionColor = UnitReactionColor
local gray = {r = .3, g = .3, b = .3}

local menu = function(self)
	local unit = self.unit:sub(1, -2)
	local cunit = self.unit:gsub("(.)", string.upper, 1)

	if(unit == "party" or unit == "partypet") then
		ToggleDropDownMenu(1, nil, _G["PartyMemberFrame"..self.id.."DropDown"], "cursor", 0, 0)
	elseif(_G[cunit.."FrameDropDown"]) then
		ToggleDropDownMenu(1, nil, _G[cunit.."FrameDropDown"], "cursor", 0, 0)
	end
end

local classification = {
	worldboss = 'B',
	rareelite = 'R',
	elite = '+',
	rare = 'r',
	normal = '',
	trivial = 't',
}

local updateInfoString = function(self, event, unit)
	if(unit ~= self.unit) then return end

	local level = UnitLevel(unit)
	if(level == -1) then
		level = '??'
	end

	local class, rclass = UnitClass(unit)
	local color = RAID_CLASS_COLORS[rclass]
	if(not UnitIsPlayer(unit)) then
		class = UnitCreatureFamily(unit) or UnitCreatureType(unit)
	end

	local happiness
	if(unit == 'pet') then
		happiness = GetPetHappiness()
		if(happiness == 1) then
			happiness = ":<"
		elseif(happiness == 2) then
			happiness = ":|"
		elseif(happiness == 3) then
			happiness = ":D"
		end
	end

	self.Info:SetFormattedText(
		"L%s%s |cff%02x%02x%02x%s|r %s",
		level,
		classification[UnitClassification(unit)],
		color.r * 255, color.g * 255, color.b * 255,
		class,
		happiness or ''
	)
end

local siValue = function(val)
	if(val >= 1e4) then
		return ("%.1f"):format(val / 1e3):gsub('%.', 'k')
	else
		return val
	end
end

local OverrideUpdateHealth = function(self, event, unit, bar, min, max)
	local color = self.colors.health[0]
	bar:SetStatusBarColor(color.r, color.g, color.b)
	bar.bg:SetVertexColor(color.r * .5, color.g * .5, color.b * .5)

	if(UnitIsTapped(unit) and not UnitIsTappedByPlayer(unit) or not UnitIsConnected(unit)) then
		self:SetBackdropBorderColor(.3, .3, .3)
	else
		color = UnitReactionColor[UnitReaction(unit, 'player')] or gray
		self:SetBackdropBorderColor(color.r, color.g, color.b)
	end

	if(UnitIsDead(unit)) then
		bar:SetValue(0)
		bar.value:SetText"Dead"
	elseif(UnitIsGhost(unit)) then
		bar:SetValue(0)
		bar.value:SetText"Ghost"
	elseif(not UnitIsConnected(unit)) then
		bar.value:SetText"Offline"
	else
		bar.value:SetFormattedText('%s/%s', siValue(min), siValue(max))
	end
end

local PostUpdatePower = function(self, event, unit, bar, min, max)
	if(min == 0) then
		bar.value:SetText()
	elseif(UnitIsDead(unit) or UnitIsGhost(unit)) then
		bar:SetValue(0)
	elseif(not UnitIsConnected(unit)) then
		bar.value:SetText()
	else
		bar.value:SetFormattedText('%s/%s', siValue(min), siValue(max))
	end
end

local backdrop = {
	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true, tileSize = 16,
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 16,
	insets = {left = 4, right = 4, top = 4, bottom = 4},
}

local func = function(settings, self, unit)
	self.menu = menu

	self:SetScript("OnEnter", UnitFrame_OnEnter)
	self:SetScript("OnLeave", UnitFrame_OnLeave)

	self:RegisterForClicks"anyup"
	self:SetAttribute("*type2", "menu")

	self:SetBackdrop(backdrop)
	self:SetBackdropColor(0, 0, 0, 1)
	self:SetBackdropBorderColor(.3, .3, .3, 1)

	-- Health bar
	local hp = CreateFrame"StatusBar"
	hp:SetWidth(width - 90)
	hp:SetHeight(14)
	hp:SetStatusBarTexture(texture)

	hp:SetParent(self)
	hp:SetPoint("TOP", 0, -8)
	hp:SetPoint("LEFT", 8, 0)

	self.Health = hp
	-- We have to override for now...
	self.OverrideUpdateHealth = OverrideUpdateHealth

	local hpp = hp:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	hpp:SetPoint("LEFT", hp, "RIGHT", 2, 0)
	hpp:SetPoint("RIGHT", self, -6, 0)
	hpp:SetJustifyH"CENTER"
	hpp:SetFont(GameFontNormal:GetFont(), 10)
	hpp:SetTextColor(1, 1, 1)

	hp.value = hpp

	-- Health bar background
	local hpbg = hp:CreateTexture(nil, "BORDER")
	hpbg:SetAllPoints(hp)
	hpbg:SetTexture(texture)
	hp.bg = hpbg

	-- Unit name
	local name = hp:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	name:SetPoint("LEFT", 2, -1)
	name:SetPoint("RIGHT", -2, 0)
	name:SetJustifyH"LEFT"
	name:SetFont(GameFontNormal:GetFont(), 11)
	name:SetTextColor(1, 1, 1)

	self.Name = name

	if(settings.size ~= 'small') then
		-- Power bar
		local pp = CreateFrame"StatusBar"
		pp:SetWidth(width - 90)
		pp:SetHeight(14)
		pp:SetStatusBarTexture(texture)

		pp:SetParent(self)
		pp:SetPoint("BOTTOM", 0, 8)
		pp:SetPoint("LEFT", 8, 0)

		self.Power = pp

		-- Power bar background
		local ppbg = pp:CreateTexture(nil, "BORDER")
		ppbg:SetAllPoints(pp)
		ppbg:SetTexture(texture)
		pp.bg = ppbg

		local ppp = hp:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		ppp:SetPoint("LEFT", pp, "RIGHT", 2, 0)
		ppp:SetPoint("RIGHT", self, -6, 0)
		ppp:SetJustifyH"CENTER"
		ppp:SetFont(GameFontNormal:GetFont(), 10)
		ppp:SetTextColor(1, 1, 1)

		pp.value = ppp
		self.PostUpdatePower = PostUpdatePower

		-- Info string
		local info = pp:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		info:SetPoint("LEFT", 2, -1)
		info:SetPoint("RIGHT", -2, 0)
		info:SetJustifyH"LEFT"
		info:SetFont(GameFontNormal:GetFont(), 11)
		info:SetTextColor(1, 1, 1)

		self.Info = info
		self.UNIT_LEVEL = updateInfoString
		self:RegisterEvent"UNIT_LEVEL"

		if(unit == "pet") then
			self.UNIT_HAPPINESS = updateInfoString
			self:RegisterEvent"UNIT_HAPPINESS"
		end
	end

	if(unit ~= 'player') then
		-- Buffs
		local buffs = CreateFrame("Frame", nil, self)
		buffs:SetPoint("BOTTOM", self, "TOP")
		buffs:SetHeight(17)
		buffs:SetWidth(width)

		buffs.size = 17
		buffs.num = math.floor(width / buffs.size + .5)

		self.Buffs = buffs

		-- Debuffs
		local debuffs = CreateFrame("Frame", nil, self)
		debuffs:SetPoint("TOP", self, "BOTTOM")
		debuffs:SetHeight(20)
		debuffs:SetWidth(width)

		debuffs.initialAnchor = "TOPLEFT"
		debuffs.size = 20
		debuffs.showDebuffType = true
		debuffs.num = math.floor(width / debuffs.size + .5)

		self.Debuffs = debuffs
	else
		self:RegisterEvent"PLAYER_UPDATE_RESTING"
		self.PLAYER_UPDATE_RESTING = function(self)
			if(IsResting()) then
				self:SetBackdropBorderColor(.3, .3, .8)
			else
				local color = UnitReactionColor[UnitReaction(unit, 'player')]
				self:SetBackdropBorderColor(color.r, color.g, color.b)
			end
		end
	end

	local leader = self:CreateTexture(nil, "OVERLAY")
	leader:SetHeight(16)
	leader:SetWidth(16)
	leader:SetPoint("BOTTOM", self, "TOP", 0, -5)
	leader:SetTexture[[Interface\GroupFrame\UI-Group-LeaderIcon]]
	self.Leader = leader

	-- Range fading on party
	if(not unit) then
		self.Range = true
		self.inRangeAlpha = 1
		self.outsideRangeAlpha = .5
	end
end

oUF:RegisterStyle("Classic", setmetatable({
	["initial-width"] = width,
	["initial-height"] = height,
}, {__call = func}))

oUF:RegisterStyle("Classic - Small", setmetatable({
	["initial-width"] = width,
	["initial-height"] = height - 16,
	["size"] = 'small',
}, {__call = func}))

-- hack to get our level information updated.
oUF:RegisterSubTypeMapping"UNIT_LEVEL"
oUF:SetActiveStyle"Classic"

local player = oUF:Spawn"player"
player:SetPoint("CENTER", -200, -380)

local pet = oUF:Spawn"pet"
pet:SetPoint('TOP', player, 'BOTTOM', 0, -16)

local target = oUF:Spawn"target"
target:SetPoint("CENTER", 200, -380)

local party = oUF:Spawn("header", "oUF_Party")
party:SetPoint("TOPLEFT", 30, -30)
party:SetManyAttributes(
	"showParty", true,
	"yOffset", -40,
	"xOffset", -40,
	'maxColumns', 2,
	'unitsPerColumn', 2,
	'columnAnchorPoint', 'LEFT',
	'columnSpacing', 15
)
party:Show()

oUF:SetActiveStyle"Classic - Small"

local tot = oUF:Spawn"targettarget"
tot:SetPoint("CENTER", 0, -250)
