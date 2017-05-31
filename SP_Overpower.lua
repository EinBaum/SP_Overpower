
function SP_OP_Split(s,t)
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


SP_OP_TimeLeft = 0.0
SP_OP_CDTime = 0.0
SP_OP_Name = nil


function SP_OP_Print(msg)
	DEFAULT_CHAT_FRAME:AddMessage("[OP] "..msg, 1, 0.6, 1)
end

function SP_OP_GetSpellID(name)
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

function SP_OP_Handler(msg)
	local vars = SP_OP_Split(msg, " ")
	for k,v in vars do
		if v == "" then
			v = nil
		end
	end

	local cmd, arg = vars[1], vars[2]

	if ((cmd == nil or cmd == "") and arg == nil) then
		SP_OP_Print("Chat commands: x, y, h, w, a, reset, sound, show")
		SP_OP_Print("    Example: /op a 0.5")
		SP_OP_Print("    Example: /op y -150")
	elseif (cmd == "x") then
		if (arg ~= nil) then
			SP_OP_GS["x"] = arg
			SP_OP_SetPosition()
			SP_OP_Print("X set: " .. arg)
		else
			SP_OP_Print("Current x: "..SP_OP_GS["x"]..". To change x say: /op x [number]")
		end
	elseif (cmd == "y") then
		if (arg ~= nil) then
			SP_OP_GS["y"] = arg
			SP_OP_SetPosition()
			SP_OP_Print("Y set: " .. arg)
		else
			SP_OP_Print("Current y: "..SP_OP_GS["y"]..". To change y say: /op y [number]")
		end
	elseif (cmd == "w") then
		if (arg ~= nil) then
			SP_OP_GS["w"] = arg
			SP_OP_SetSize()
			SP_OP_Print("W(idth) set: " .. arg)
		else
			SP_OP_Print("Current width: "..SP_OP_GS["w"]..". To change w say: /op w [number]")
		end
	elseif (cmd == "h") then
		if (arg ~= nil) then
			SP_OP_GS["h"] = arg
			SP_OP_SetSize()
			SP_OP_Print("H(eight) set: " .. arg)
		else
			SP_OP_Print("Current height: "..SP_OP_GS["h"]..". To change h say: /op h [number]")
		end
	elseif (cmd == "a") then
		if (arg ~= nil) then
			SP_OP_GS["a"] = math.max(math.min(tonumber(arg), 1), 0)
			SP_OP_Print("A(lpha) set: " .. arg)
		else
			SP_OP_Print("Current alpha: "..SP_OP_GS["a"]..". To change a say: /op a [number]")
		end
	elseif (cmd == "sound") then
		if (arg ~= nil) then
			local val = "off"
			if (arg == "on") then val = "on" end
			SP_OP_GS["sound"] = val
			SP_OP_Print("Sound set: " .. val)
		else
			SP_OP_Print("Sound: "..SP_OP_GS["sound"]..". Use: /st a on|off")
		end
	elseif (cmd == "reset") then
		SP_OP_GS = nil
		SP_OP_UpdateGlobal()
		SP_OP_SetPosition()
		SP_OP_SetSize()
		SP_OP_UpdateDisplay()
		SP_OP_Frame:SetAlpha(0)
	elseif (cmd == "show") then
	end

	SP_OP_Reset("Test Name")
end

function SP_OP_SetPosition()
	SP_OP_Frame:SetPoint("CENTER", "UIParent", "CENTER", SP_OP_GS["x"], SP_OP_GS["y"])
end

function SP_OP_SetSize()
	local regions = {"SP_OP_Frame", "SP_OP_FrameShadowTime",
		"SP_OP_FrameTime", "SP_OP_FrameText"}

	for _,region in ipairs(regions) do
		getglobal(region):SetWidth(SP_OP_GS["w"])
		getglobal(region):SetHeight(SP_OP_GS["h"])
	end

	SP_OP_FrameText:SetTextHeight(SP_OP_GS["h"])
end

function SP_OP_OnLoad()
	this:RegisterEvent("ADDON_LOADED")
	this:RegisterEvent("CHAT_MSG_COMBAT_SELF_MISSES")
	this:RegisterEvent("CHAT_MSG_SPELL_SELF_DAMAGE")

	SLASH_SPOVERPOWER1 = "/op"
	SLASH_SPOVERPOWER2 = "/spop"
	SlashCmdList["SPOVERPOWER"] = SP_OP_Handler
end

StaticPopupDialogs["SP_OP_Install"] = {
	text = TEXT("Thank you for installing SP_Overpower 2.0! Use the chat command /op to change the position of the timer bar."),
	button1 = TEXT(YES),
	timeout = 0,
	hideOnEscape = 1,
};

function SP_OP_UpdateGlobal()
	if not SP_OP_GS then SP_OP_GS = {} end
	if not SP_OP_GS["x"] then SP_OP_GS["x"] = 0 end
	if not SP_OP_GS["y"] then SP_OP_GS["y"] = -135 end
	if not SP_OP_GS["w"] then SP_OP_GS["w"] = 300 end
	if not SP_OP_GS["h"] then SP_OP_GS["h"] = 15 end
	if not SP_OP_GS["a"] then SP_OP_GS["a"] = 1 end
	if not SP_OP_GS["sound"] then SP_OP_GS["sound"] = "on" end
end

function SP_OP_OnEvent()
	if (event == "ADDON_LOADED") then
		if (string.lower(arg1) == "sp_overpower") then

			if (SP_OP_GS == nil) then
				StaticPopup_Show("SP_OP_Install")
			end

			SP_OP_UpdateGlobal()
			SP_OP_SetPosition()
			SP_OP_SetSize()
			SP_OP_UpdateDisplay()
			SP_OP_Frame:SetAlpha(0)

			SP_OP_Print("SP_Overpower 2.0 loaded. Options: /op")
		end

	elseif (event == "CHAT_MSG_COMBAT_SELF_MISSES") then
		local a,b,str = string.find(arg1, "You attack. (.+) dodges.")
		if a then
			SP_OP_Reset(str)
		end

	elseif (event == "CHAT_MSG_SPELL_SELF_DAMAGE") then

		local a,b,_,str = string.find(arg1, "Your (.+) was dodged by (.+).")

		if a then
			SP_OP_Reset(str)
		else
			a,b,str = string.find(arg1, "Your (.+) hits")
			if not str then a,b,str = string.find(arg1, "Your (.+) crits") end
			if not str then a,b,str = string.find(arg1, "Your (.+) is parried") end
			if not str then a,b,str = string.find(arg1, "Your (.+) missed") end
			if str == "Overpower" then
				SP_OP_TimeLeft = 0
				SP_OP_UpdateDisplay()
			end
		end
	end
end

function SP_OP_OnUpdate(delta)
	if (SP_OP_TimeLeft > 0) then

		SP_OP_TimeLeft = SP_OP_TimeLeft - delta
		if (SP_OP_TimeLeft < 0) then
			SP_OP_TimeLeft = 0
		end

		SP_OP_UpdateDisplay()
	end
end

function SP_OP_Reset(name)
	local op_spellID = SP_OP_GetSpellID("Overpower")
	if op_spellID == nil then
		return
	end

	local op_start, op_dur = GetSpellCooldown(op_spellID, BOOKTYPE_SPELL)
	if op_start > 0 then
		SP_OP_CDTime = op_dur - (GetTime() - op_start)
	else
		SP_OP_CDTime = 0
	end

	if SP_OP_CDTime < 4 then
		SP_OP_TimeLeft = 4
		SP_OP_Name = name

		if SP_OP_GS["sound"] == "on" then
			PlaySoundFile("Sound\\Interface\\PlayerInviteA.wav")
		end
	end
end
function SP_OP_Display(msg)
	SP_OP_FrameText:SetText(msg)
end
function SP_OP_UpdateDisplay()
	if (SP_OP_TimeLeft <= 0) then
		SP_OP_FrameTime:Hide()
		SP_OP_Frame:SetAlpha(0)
	else
		local w = (math.min(SP_OP_TimeLeft, 4 - SP_OP_CDTime) / 4 ) * SP_OP_GS["w"]
		local w2 = (SP_OP_TimeLeft / 4) * SP_OP_GS["w"]
		if w > 0 then
			SP_OP_FrameTime:SetWidth(w)
			SP_OP_FrameTime:Show()
		else
			SP_OP_FrameTime:Hide()
		end
		SP_OP_FrameShadowTime:SetWidth(w2)
		SP_OP_FrameShadowTime:Show()

		SP_OP_Display(string.sub(SP_OP_TimeLeft, 1, 3))

		SP_OP_Frame:SetAlpha(SP_OP_GS["a"])
	end
end





