--[[-------------------------------------------------------------------------
  Trond A Ekseth grants anyone the right to use this work for any purpose,
  without any conditions, unless such conditions are required by law.
---------------------------------------------------------------------------]]

local texture = [[Interface\AddOns\oUF_Classic\textures\statusbar]]
local height, width = 47, 260
local gray = {.3, .3, .3}

local colors = setmetatable({
	health = {.45, .73, .27},
	power = setmetatable({
		['MANA'] = {.27, .53, .73},
		['RAGE'] = {.73, .27, .27},
	}, {__index = oUF.colors.power}),
}, {__index = oUF.colors})

local menu = function(self)
	local unit = self.unit:sub(1, -2)
	local cunit = self.unit:gsub("(.)", string.upper, 1)

	if(unit == "party" or unit == "partypet") then
		ToggleDropDownMenu(1, nil, _G["PartyMemberFrame"..self.id.."DropDown"], "cursor", 0, 0)
	elseif(_G[cunit.."FrameDropDown"]) then
		ToggleDropDownMenu(1, nil, _G[cunit.."FrameDropDown"], "cursor", 0, 0)
	end
end

if(not oUF.Tags['[happiness]']) then
	oUF.Tags['[happiness]'] = function(unit)
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

		return happiness or ''
	end
end

local siValue = function(val)
	if(val >= 1e4) then
		return ("%.1f"):format(val / 1e3):gsub('%.', 'k')
	else
		return val
	end
end

local PostUpdateHealth = function(self, event, unit, bar, min, max)
	if(UnitIsTapped(unit) and not UnitIsTappedByPlayer(unit) or not UnitIsConnected(unit)) then
		self:SetBackdropBorderColor(.3, .3, .3)
	else
		local r, g, b = UnitSelectionColor(unit)
		self:SetBackdropBorderColor(r, g, b)
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

	hp.frequentUpdates = true
	hp.colorDisconnected = true
	hp.colorTapping = true
	hp.colorHappiness = true
	hp.colorSmooth = true

	self.Health = hp
	self.PostUpdateHealth = PostUpdateHealth

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
	hpbg:SetAlpha(.5)
	hpbg:SetTexture(texture)
	hp.bg = hpbg

	if(unit ~= 'targettarget') then
		local cb = CreateFrame"StatusBar"
		cb:SetStatusBarTexture(texture)
		cb:SetStatusBarColor(.73, 0, .27, .8)
		cb:SetParent(self)
		cb:SetAllPoints(hp)
		cb:SetToplevel(true)
		self.Castbar = cb
	end

	-- Unit name
	local name = hp:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	name:SetPoint("LEFT", 2, -1)
	name:SetPoint("RIGHT", -2, 0)
	name:SetJustifyH"LEFT"
	name:SetFont(GameFontNormal:GetFont(), 11)
	name:SetTextColor(1, 1, 1)

	self:Tag(name, '[name]')
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

		pp.colorPower = true
		pp.frequentUpdates = true

		self.Power = pp

		-- Power bar background
		local ppbg = pp:CreateTexture(nil, "BORDER")
		ppbg:SetAllPoints(pp)
		ppbg:SetAlpha(.5)
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

		self:Tag(info, 'L[level][shortclassification] [raidcolor][smartclass]')
		self.Info = info
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
		self:RegisterEvent("PLAYER_UPDATE_RESTING", function(self)
			if(IsResting()) then
				self:SetBackdropBorderColor(.3, .3, .8)
			else
				local r, g, b = UnitSelectionColor(unit)
				self:SetBackdropBorderColor(r, g, b)
			end
		end)
	end

	local leader = self:CreateTexture(nil, "OVERLAY")
	leader:SetHeight(16)
	leader:SetWidth(16)
	leader:SetPoint("BOTTOM", self, "TOP", 0, -5)
	leader:SetTexture[[Interface\GroupFrame\UI-Group-LeaderIcon]]
	self.Leader = leader

	-- enable our colors
	self.colors = colors

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

oUF:SetActiveStyle"Classic"

-- :Spawn(unit, frame_name, isPet) --isPet is only used on headers.
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
