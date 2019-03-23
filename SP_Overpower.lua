
local version = "3.0.0"

local defaults = {
	x = 0,
	y = -161,
	w = 200,
	h = 13,
	b = 0,
	a = 1,
	s = 1,
	sound = "off"
}
local settings = {
	x = "Bar X position",
	y = "Bar Y position",
	w = "Bar width",
	h = "Bar height",
	b = "Border height",
	a = "Alpha between 0 and 1",
	s = "Bar scale",
	sound = "Sound 'on' or 'off'"
}

--------------------------------------------------------------------------------

local op_timeLeft = 0.0
local op_CDTime = 0.0

--------------------------------------------------------------------------------

StaticPopupDialogs["SP_OP_Install"] = {
	text = TEXT("Thank you for installing SP_Overpower " .. version .. "! Use the chat command /op to change the position of the timer bar."),
	button1 = TEXT(YES),
	timeout = 0,
	hideOnEscape = 1,
};

--------------------------------------------------------------------------------

local function print(msg)
	DEFAULT_CHAT_FRAME:AddMessage(msg, 1, 0.7, 0.9)
end
local function SplitString(s,t)
	local l = {n=0}
	local f = function (s)
		l.n = l.n + 1
		l[l.n] = s
	end
	local p = "%s*(.-)%s*"..t.."%s*"
	s = string.gsub(s,"^%s+","")
	s = string.gsub(s,"%s+$","")
	s = string.gsub(s,p,f)
	l.n = l.n + 1
	l[l.n] = string.gsub(s,"(%s%s*)$","")
	return l
end

--------------------------------------------------------------------------------

local function GetSpellID(name)
	local spellID = 1
	local spellName = nil
	while 1 do
		spellName = GetSpellName(spellID, BOOKTYPE_SPELL)
		if spellName == name then
			return spellID
		end
		if spellName == nil then
			return nil
		end
		spellID = spellID + 1
	end
end
local function UpdateSettings()
	if not SP_OP_GS then SP_OP_GS = {} end
	for option, value in defaults do
		if SP_OP_GS[option] == nil then
			SP_OP_GS[option] = value
		end
	end
end
local function UpdateAppearance()
	SP_OP_Frame:ClearAllPoints()
	SP_OP_Frame:SetPoint("CENTER", "UIParent", "CENTER", SP_OP_GS["x"], SP_OP_GS["y"])

	local regions = {"SP_OP_Frame", "SP_OP_FrameShadowTime",
		"SP_OP_FrameTime", "SP_OP_FrameText"}

	for _,region in ipairs(regions) do
		getglobal(region):SetWidth(SP_OP_GS["w"])
	end

	SP_OP_Frame:SetHeight(SP_OP_GS["h"])
	SP_OP_FrameText:SetHeight(SP_OP_GS["h"])

	SP_OP_FrameTime:SetHeight(SP_OP_GS["h"] - SP_OP_GS["b"])
	SP_OP_FrameShadowTime:SetHeight(SP_OP_GS["h"] - SP_OP_GS["b"])

	SP_OP_FrameText:SetFont("Fonts\\FRIZQT__.TTF", SP_OP_GS["h"])
	SP_OP_Frame:SetAlpha(SP_OP_GS["a"])
	SP_OP_Frame:SetScale(SP_OP_GS["s"])
end
local function ResetTimer(name)
	local op_spellID = GetSpellID("Overpower")
	if op_spellID == nil then
		return
	end

	local op_start, op_dur = GetSpellCooldown(op_spellID, BOOKTYPE_SPELL)
	if op_start > 0 then
		op_CDTime = op_dur - (GetTime() - op_start)
	else
		op_CDTime = 0
	end

	if op_CDTime < 4 then
		if SP_OP_GS["sound"] == "on" or SP_OP_GS["sound"] == 1 then
			PlaySoundFile("Sound\\Interface\\PlayerInviteA.wav")
		end
		op_timeLeft = 4
		SP_OP_Frame:Show()
	end
end
local function TestShow()
	ResetTimer("Test Name")
end
local function SetBarText(msg)
	SP_OP_FrameText:SetText(msg)
end
local function UpdateDisplay()
	if (op_timeLeft <= 0) then
		SP_OP_FrameTime:Hide()
		SP_OP_Frame:Hide()
	else
		local w = (math.min(op_timeLeft, 4 - op_CDTime) / 4 ) * SP_OP_GS["w"]
		local w2 = (op_timeLeft / 4) * SP_OP_GS["w"]
		if w > 0 then
			SP_OP_FrameTime:SetWidth(w)
			SP_OP_FrameTime:Show()
		else
			SP_OP_FrameTime:Hide()
		end
		SP_OP_FrameShadowTime:SetWidth(w2)
		SP_OP_FrameShadowTime:Show()

		SetBarText(string.sub(op_timeLeft, 1, 3))

		SP_OP_Frame:SetAlpha(SP_OP_GS["a"])
	end
end

--------------------------------------------------------------------------------

function SP_OP_OnLoad()
	this:RegisterEvent("ADDON_LOADED")
	this:RegisterEvent("CHAT_MSG_COMBAT_SELF_MISSES")
	this:RegisterEvent("CHAT_MSG_SPELL_SELF_DAMAGE")

	-- Only for Execute dodges (server bug?)
	this:RegisterEvent("CHAT_MSG_SPELL_DAMAGESHIELDS_ON_SELF")
end

function SP_OP_OnEvent()
	if (event == "ADDON_LOADED") then
		if (string.lower(arg1) == "sp_overpower") then

			if (SP_OP_GS == nil) then
				StaticPopup_Show("SP_OP_Install")
			end

			UpdateSettings()
			UpdateAppearance()
			UpdateDisplay()

			print("SP_Overpower " .. version .. " loaded. Options: /op")
		end

	elseif (event == "CHAT_MSG_COMBAT_SELF_MISSES") then
		local a,b,str = string.find(arg1, "You attack. (.+) dodges.")
		if a then
			ResetTimer(str)
		end

	elseif (event == "CHAT_MSG_SPELL_SELF_DAMAGE"
		or  event == "CHAT_MSG_SPELL_DAMAGESHIELDS_ON_SELF") then

		local a,b,_,str = string.find(arg1, "Your (.+) was dodged by (.+).")

		if a then
			ResetTimer(str)
		else
			a,b,str = string.find(arg1, "Your (.+) hits")
			if not str then a,b,str = string.find(arg1, "Your (.+) crits") end
			if not str then a,b,str = string.find(arg1, "Your (.+) is parried") end
			if not str then a,b,str = string.find(arg1, "Your (.+) missed") end
			if str == "Overpower" then
				op_timeLeft = 0
				UpdateDisplay()
			end
		end
	end
end

function SP_OP_OnUpdate(delta)
	if (op_timeLeft > 0) then
		op_timeLeft = op_timeLeft - delta
		if (op_timeLeft < 0) then
			op_timeLeft = 0
		end
	end
	UpdateDisplay()
end

--------------------------------------------------------------------------------

SLASH_SPOVERPOWER1 = "/op"
SLASH_SPOVERPOWER2 = "/overpower"

local function ChatHandler(msg)
	local vars = SplitString(msg, " ")
	for k,v in vars do
		if v == "" then
			v = nil
		end
	end
	local cmd, arg = vars[1], vars[2]
	if cmd == "reset" then
		SP_OP_GS = nil
		UpdateSettings()
		UpdateAppearance()
		print("Reset to defaults.")
	elseif settings[cmd] ~= nil then
		if arg ~= nil then
			if arg == "on" then arg = 1 end
			if arg == "off" then arg = 0 end
			local number = tonumber(arg)
			if number then
				SP_OP_GS[cmd] = number
				UpdateAppearance()
			else
				print("Error: Invalid argument")
			end
		end
		print(format("%s %s %s (%s)",
			SLASH_SPOVERPOWER1, cmd, SP_OP_GS[cmd], settings[cmd]))
	else
		for k, v in settings do
			print(format("%s %s %s (%s)",
				SLASH_SPOVERPOWER1, k, SP_OP_GS[k], v))
		end
	end
	TestShow()
end

SlashCmdList["SPOVERPOWER"] = ChatHandler
