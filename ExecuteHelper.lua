if select(2, UnitClass("player")) ~= "DEATHKNIGHT" then return end
-- config
local cfg = {
	["iconsize"] = 50,														--The size of the icon
	["barsize"] = {150, 8},													--The size of the bar
	["fadealpha"] = .35,													--fadealpha
	["font"] = "Interface\\Addons\\ExecuteHealper\\pixel.ttf",					--font
	["fontsize"] = 12,														--font size
	["fontflag"] = "OUTLINE",												
	-- ["point"] = {"TOP", UIParent, "TOP", 0, -350}							--position of the icon
}

-- initialize
local rune, runicP = {}, 0
local SRcount, SRHP = 0, 0
local SRbuffer = 0
local SRtarget = nil
local SRpredict = false
local SRtime = 0
local isEquipted = false
local isUnHoly = false
local myname = UnitName("player")
ExecuteHelperDB = ExecuteHelperDB or {}

for i = 1, 6 do
	rune[i] = {tp, start, duration, runeReady}
end

local function updatesource()
	for i = 1, 6 do
		rune[i].tp = GetRuneType(i)
		rune[i].start, rune[i].duration, rune[i].runeReady = GetRuneCooldown(i)
	end
	runicP = UnitPower("player")
end

local function checkSR()
	updatesource()
	local b = 0
	local cTime = GetTime()
	local HPMAX = UnitHealthMax("target")
	local HP = UnitHealth("target")
	local Rstart, Rduration
	local threshold = (isEquipted or isUnHoly) and 0.45 or 0.35
	--if (SRtime == nil) then SRtime = cTime end
	if SRtarget == UnitGUID("target") then
		local SRdps = (SRHP - HP) / (cTime - SRtime)
		SRbuffer = ((HP - SRdps * 5) / HPMAX) < threshold and SRbuffer + 1 or 0
		SRpredict = SRbuffer >= 3 and true or false
	else
		SRtarget = UnitGUID("target")
		SRHP = HP
		SRtime = cTime
		SRpredict = false
	end
	if GetSpecialization() == 1 then
		Rstart, Rduration = GetSpellCooldown(114866)
		for i = 1,6 do
			b = (rune[i].tp == 1 and rune[i].runeReady) and b + 1 or b
		end
	elseif GetSpecialization() == 3 then
		Rstart, Rduration = GetSpellCooldown(130736)
		for i = 1,6 do
			b = (rune[i].tp == 2 and rune[i].runeReady) and b + 1 or b
		end
	else
		Rstart, Rduration = GetSpellCooldown(130735)
		for i = 1,6 do
			b = (rune[i].tp == 3 and rune[i].runeReady) and b + 1 or b
		end
	end
	SRcount = b
	if SRcount == 2 and Rstart == 0 then
		SR:SetAlpha(1)
	elseif SRcount == 1 and Rduration <= 1 then
		SR:SetAlpha(0.6)
	else
		SR:SetAlpha(0.3)
	end
	if ((HP / HPMAX) < threshold or SRpredict) and Rduration <= 1 then
		SR:Show()
	else
		SR:Hide()
	end
	return SRcount
end

local function CreateShadow(f)
   if f.Shadow then return end
   f:SetBackdrop({bgFile = "Interface\\ChatFrame\\ChatFrameBackground"})
   f:SetBackdropColor(.05, .05, .05, .6)
   local Shadow = CreateFrame("Frame", nil, f)
   Shadow:SetFrameLevel(0)
   Shadow:SetPoint("TOPLEFT", -4, 4)
   Shadow:SetPoint("BOTTOMRIGHT", 4, -4)
   Shadow:SetBackdrop({edgeFile = "Interface\\Addons\\ExecuteHelper\\glowTex", edgeSize = 4})
   Shadow:SetBackdropBorderColor(0, 0, 0, 1)
   f.Shadow = Shadow
   return Shadow
end

local function SetFrame(f)
	local size = cfg.iconsize
	f:SetSize(size, size)
	CreateShadow(f)
	f.icon = f:CreateTexture(nil, "ARTWORK")
	f.icon:SetAllPoints(f)
	f.icon:SetTexCoord(.08, .92, .08, .92)
	f.text = f:CreateFontString(nil, "OVERLAY")
	f.text:SetFont(cfg.font, cfg.fontsize, cfg.fontflag)
end

local function checkEquipt()
	local count = 0
	local Head = GetInventoryItemID("player", GetInventorySlotInfo("HeadSlot"))
	local Sldr = GetInventoryItemID("player", GetInventorySlotInfo("ShoulderSlot"))
	local Chst = GetInventoryItemID("player", GetInventorySlotInfo("ChestSlot"))
	local Hand = GetInventoryItemID("player", GetInventorySlotInfo("HandsSlot"))
	local Legs = GetInventoryItemID("player", GetInventorySlotInfo("LegsSlot"))
	if Head == 96571 or Head == 95227 or Head == 95827 then count = count + 1 end
	if Sldr == 96573 or Sldr == 95229 or Sldr == 95829 then count = count + 1 end
	if Chst == 96569 or Chst == 95225 or Chst == 95825 then count = count + 1 end
	if Hand == 96570 or Hand == 95226 or Hand == 95826 then count = count + 1 end
	if Legs == 96572 or Legs == 95228 or Legs == 95828 then count = count + 1 end
	--DEFAULT_CHAT_FRAME:AddMessage("|cff558484ExecuteHelper|r : "..count)
	if count >= 4 then
		isEquipted = true
	else
		isEquipted = false
	end
end

local function checkSpec()
	local currentSpec = GetSpecialization()
	if currentSpec == 3 then
		isUnHoly = true
	else
		isUnholy = false
	end
end

-- main
local Anchor = CreateFrame("Frame", "ExecuteHelperAnchor", UIParent)
Anchor:SetSize(cfg.iconsize, cfg.iconsize)
Anchor:SetPoint(ExecuteHelperDB.x and "CENTER" or "TOP", UIParent, ExecuteHelperDB.x and "BOTTOMLEFT" or "TOP", ExecuteHelperDB.x or 0, ExecuteHelperDB.y or -350)
CreateShadow(Anchor)
Anchor.text = Anchor:CreateFontString(nil, "OVERLAY")
Anchor.text:SetFont(cfg.font, cfg.fontsize, cfg.fontflag)
Anchor.text:SetAllPoints(Anchor)
Anchor.text:SetText("Drag")
Anchor:SetMovable(true)
Anchor:EnableMouse(true)
Anchor:RegisterForDrag("LeftButton")
Anchor:Hide()
Anchor:SetScript("OnDragStart", function(self) self:StartMoving() end)
Anchor:SetScript("OnDragStop", function(self)
	self:StopMovingOrSizing()
	ExecuteHelperDB.x, ExecuteHelperDB.y = self:GetCenter()
end)

local ExecuteHelper = CreateFrame("Frame", "ExecuteHelper", UIParent)
ExecuteHelper:SetPoint("TOPLEFT", Anchor)
ExecuteHelper:SetSize(cfg.iconsize, cfg.iconsize)
ExecuteHelper:RegisterEvent("PLAYER_ENTERING_WORLD")
ExecuteHelper:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
ExecuteHelper:Hide()

ExecuteHelper:SetScript("OnEvent", function(self, event, ...)
	if event == "PLAYER_ENTERING_WORLD" then
		--DEFAULT_CHAT_FRAME:AddMessage("|cff558484ExecuteHelper|r: Hello World" )
		PlayerGUID = UnitGUID("player")
		cfg.fontsize = 20*768/string.match(GetCVar("gxResolution"), "%d+x(%d+)")/UIParent:GetEffectiveScale()
		self:UnregisterEvent("PLAYER_ENTERING_WORLD")
		SR = MySoulReaperFrame or CreateFrame("Frame", "MySoulReaperFrame", self)  --SoulReaper SpellID:114866
		SR:SetPoint("TOPLEFT", self)
		SetFrame(SR)
		SR:SetSize(cfg.iconsize, cfg.iconsize)
		SR.icon = SR:CreateTexture(nil, "ARTWORK")
		SR.icon:SetAllPoints(SR)
		SR.icon:SetTexCoord(.08, .92, .08, .92)
		SR:Hide()
		SR.icon:SetTexture(select(3, GetSpellInfo(114866)))
		self:RegisterEvent("PLAYER_REGEN_ENABLED")
		self:RegisterEvent("PLAYER_REGEN_DISABLED")
		self:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
	end
	
	if event == "PLAYER_REGEN_ENABLED" then 
		SR:Hide()
		self:Hide() 	
		self:SetScript("OnUpdate", nil)
		collectgarbage("collect")
	end
	
	if event == "PLAYER_REGEN_DISABLED" then
		Anchor:Hide()
		self:Show()
		checkEquipt()
		checkSpec()
		self:SetScript("OnUpdate", function(self, elapsed)
			self.elapsed = (self.elapsed or 0.1) - elapsed
			if self.elapsed <= 0 then
				checkSR()
			end
		end)
	end
	
	if event == "COMBAT_LOG_EVENT_UNFILTERED" then
		local _, eventName, _, sourceGUID, _, _, _, _, _, _, _, spellId = ...
		
		if sourceGUID ~= PlayerGUID then return end
		
		if eventName == "SPELL_CAST_SUCCESS" and (spellId == 114866 or spellId == 130736) then
			SR:Hide()
		end
	end
end)

SlashCmdList["ExecuteHelper"] = function() if Anchor:IsVisible() then Anchor:Hide() else Anchor:Show() end end
SLASH_ExecuteHelper1 = "/ExecuteHelper"
