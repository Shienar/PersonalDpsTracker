PDT = { name = "PersonalDpsTracker" }

PDT.defaults = {
	colorR = 1.0,
	colorG = 1.0,
	colorB = 1.0,
	colorA = 1.0,
	selectedText_font = "18",
	selectedFont = "ZoFontGamepad18",
	displayText = "[<t>]: <d>, <D>",
	displayText_Boss = "[<t>]: <b>, <B> (<d>, <D>)",
	formatType = 1,
	selectedFormatName = "134,419",
	selectedText_pos = "Top Left",
	selectedPos = 3,
	checked = false,
	offset_x = 0,
	offset_y = 0,
}

local PDT_activeCombat = false
local PDT_TotalDamage = 0
local PDT_PreCombatDamage = 0
local PDT_TotalDamage_Boss = 0
local PDT_PreCombatDamage_Boss = 0
local PDT_startTime = 0 --milliseconds
local PDT_endTime = 0 --milliseconds
local PDT_fightTime = function () return ((PDT_endTime-PDT_startTime)/1000) end --seconds
local PDT_bossNames = { }
local PDT_deadOnBoss = false

local function PDT_formattedTime(s)
	local minutes, seconds = math.floor(s/60), s%60
	if seconds < 10 then return minutes..":0"..seconds end
	return minutes..":"..seconds
end

local function PDT_getRawDPS(damage, duration) 
	return damage/duration
end

local function PDT_formatNumber(number)
	--input examples: 134519.165 dps or 4149256 damage
	if PDT.savedVariables.formatType == 1 then
		--134,419
		--4,149,257
		local formatted = tostring(math.floor(number))
		while true do  
			formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
			if (k==0) then break end
		end
		return formatted
	elseif PDT.savedVariables.formatType == 2 then
		--134.4k
		--4.149M
		if number < 1000000 then
			local formatted = math.floor((number/100) + 0.5)
			formatted = formatted / 10
			return formatted.."k"
		else
			local formatted = math.floor((number/1000) + 0.5)
			local formatted = formatted / 1000
			return formatted.."M"
		end
	elseif PDT.savedVariables.formatType == 3 then
		--134
		--4.1M
		if number < 1000000 then
			return math.floor(number/1000).."k"
		else
			local formatted = math.floor((number/100000) + 0.5)
			local formatted = formatted / 10
			return formatted.."M"
		end
	end
	
	return -1
end
	
local function PDT_updateText()
	local formattedString = ""
	
	if #PDT_bossNames == 0 then
		 formattedString = PDT.savedVariables.displayText
	else
		formattedString = PDT.savedVariables.displayText_Boss
	end
	
	if PDT_TotalDamage_Boss ~= 0 then 
		formattedString = string.gsub(formattedString, "<b>", tostring(PDT_formatNumber(PDT_getRawDPS(PDT_TotalDamage_Boss, PDT_fightTime()))))
	else
		formattedString = string.gsub(formattedString, "<b>", "0k")
	end
	formattedString = string.gsub(formattedString, "<B>", tostring(PDT_formatNumber(PDT_TotalDamage_Boss)))
	if PDT_TotalDamage ~= 0 then
		formattedString = string.gsub(formattedString, "<d>", tostring(PDT_formatNumber(PDT_getRawDPS(PDT_TotalDamage, PDT_fightTime()))))
	else
		formattedString = string.gsub(formattedString, "<d>", "0k")
	end
	formattedString = string.gsub(formattedString, "<D>", tostring(PDT_formatNumber(PDT_TotalDamage)))
	formattedString = string.gsub(formattedString, "<t>", tostring(PDT_formattedTime(math.floor(PDT_fightTime()))))
			
	DpsIndicatorLabel:SetText(formattedString)
end

--A boss name could be both "Iron-Heel" or "Iron-Heel^M", so i gotta do some extra work.
local function PDT_containsVal(table, val)
	if string.find(val, "^", 1, true) ~= nil then val = string.sub(val, 1, (string.find(val, "^", 1, true) - 1)) end
	
	for k, v in pairs(table) do
		if v == val then 
			return true 
		end
	end
	return false
end

local function PDT_onNewBosses(code, forceReset)
	for i = 1, 12 do
		local tempTag = "boss"..i
		if DoesUnitExist(tempTag) and PDT_containsVal(PDT_bossNames, GetUnitName(tempTag)) == false then
			PDT_bossNames[#PDT_bossNames + 1] = GetUnitName(tempTag)
		end
	end
end

local function PDT_ChangePlayerCombatState(event, inCombat)
	--inCombat == true if the player just entered combat.
	--inCombat == false if the player just exited combat.
	
	PDT_activeCombat = inCombat 
	
	if inCombat then 
		PDT_deadOnBoss = false
		if PDT_startTime == 0 then PDT_startTime = GetGameTimeMilliseconds() end
		
		 --Z'maja doesn't trigger the event, so I'm checking for bosses at the start of combat.
		PDT_onNewBosses(_, _)
	else
		zo_callLater(function ()
			local totalBossHP, totalMaxBossHP = 0, 0
			for i = 1, 12 do
				local bossTag = "boss"..i
				if DoesUnitExist(bossTag) then
					local bossHP, maxBossHP, _ = GetUnitPower(bossTag, COMBAT_MECHANIC_FLAGS_HEALTH)
					totalBossHP = totalBossHP + bossHP
					totalMaxBossHP = totalMaxBossHP + maxBossHP
				end
			end
			
			if totalMaxBossHP > 0 then
				local ratio = totalBossHP/totalMaxBossHP
				if ratio <= 0 or ratio >= 1 then
					--Boss is dead or reset (group wipe)
					--Reset variables
					PDT_startTime, PDT_endTime = 0, 0
					PDT_TotalDamage, PDT_TotalDamage_Boss = 0, 0
					PDT_bossNames = { }
				else
					--player is dead but boss isn't
					PDT_deadOnBoss = true
				end
			else
				--Not a boss fight.
				--Reset variables
				PDT_startTime, PDT_endTime = 0, 0
				PDT_TotalDamage, PDT_TotalDamage_Boss = 0, 0
				PDT_bossNames = { }	
			end
		end, 500)
	end
	
end

local function PDT_onRevive(code)
	--Timeline:
		--player died during boss
		--player respawned
		--player isn't in combat 2.5s later.
		--Assume boss is dead and reset variables.
	if PDT_deadOnBoss then
		zo_callLater(function ()
			PDT_deadOnBoss = false
			PDT_startTime, PDT_endTime = 0, 0
			PDT_TotalDamage, PDT_TotalDamage_Boss = 0, 0
			PDT_bossNames = { }
		end, 2500)
	end
end

local function PDT_OnCombatEvent(eventCode, result, isError, abilityName, abilityGraphic, abilityActionSlotType, sourceName, sourceType, targetName, targetType, hitValue, powerType, damageType, _log, sourceUnitID, targetUnitID, abilityID, overflow)
	if (sourceType == 1 or sourceType == 2)  and (targetType == 0 or targetType == 4) and 
		( result == ACTION_RESULT_DOT_TICK or
		  result == ACTION_RESULT_DOT_TICK_CRITICAL  or
		  result == ACTION_RESULT_CRITICAL_DAMAGE or
		  result == ACTION_RESULT_DAMAGE or
		  result == ACTION_RESULT_BLOCKED_DAMAGE or
		  result == ACTION_RESULT_DAMAGE_SHIELDED or
		  result == ACTION_RESULT_PRECISE_DAMAGE or
		  result == ACTION_RESULT_WRECKING_DAMAGE
		)
	then
		--Damage from player to NPC or player pet to NPCs
		
		--This event can happen before the combat event, so I'm accounting for the minimal amount of damage the player might deal inbetween.
		if PDT_activeCombat == false then
			PDT_PreCombatDamage = PDT_PreCombatDamage + hitValue
			if PDT_containsVal(PDT_bossNames, targetName) then PDT_PreCombatDamage_Boss = PDT_PreCombatDamage_Boss + hitValue end
			if PDT_startTime == 0 then PDT_startTime = GetGameTimeMilliseconds() end
		else 
			if PDT_PreCombatDamage ~= 0 then
				PDT_TotalDamage = PDT_TotalDamage + PDT_PreCombatDamage
				PDT_TotalDamage_Boss = PDT_TotalDamage_Boss + PDT_PreCombatDamage_Boss
				PDT_PreCombatDamage = 0
				PDT_PreCombatDamage_Boss = 0
			end
			
			if PDT_startTime == 0 then PDT_startTime = GetGameTimeMilliseconds() end
			
			PDT_TotalDamage = PDT_TotalDamage + hitValue
			if PDT_containsVal(PDT_bossNames, targetName) then PDT_TotalDamage_Boss = PDT_TotalDamage_Boss + hitValue end
			
			PDT_endTime = GetGameTimeMilliseconds()
			
			PDT_updateText()
		end
	end
end

local function PDT_fragmentChange(oldState, newState)
	if newState == SCENE_FRAGMENT_SHOWN then
		DpsIndicator:SetHidden(PDT.savedVariables.checked)
	elseif newState == SCENE_FRAGMENT_HIDDEN then
		DpsIndicator:SetHidden(true)
	end
end

function PDT.Initialize()
	PDT_activeCombat = IsUnitInCombat("player")
	
	--Load and apply saved variables
	PDT.savedVariables = ZO_SavedVars:NewAccountWide("PDTSavedVariables", 1, nil, PDT.defaults, GetWorldName())
	DpsIndicator:SetHidden(PDT.savedVariables.checked)
	DpsIndicatorLabel:SetColor(PDT.savedVariables.colorR, PDT.savedVariables.colorG, PDT.savedVariables.colorB)
	DpsIndicatorLabel:SetAlpha(PDT.savedVariables.colorA)
	DpsIndicatorLabel:SetFont(PDT.savedVariables.selectedFont)
	DpsIndicator:ClearAnchors()
	DpsIndicator:SetAnchor(PDT.savedVariables.selectedPos, GuiRoot, PDT.savedVariables.selectedPos, PDT.savedVariables.offset_x, PDT.savedVariables.offset_y)
	DpsIndicatorLabel:ClearAnchors()
	DpsIndicatorLabel:SetAnchor(PDT.savedVariables.selectedPos, DpsIndicator, PDT.savedVariables.selectedPos, PDT.savedVariables.offset_x, PDT.savedVariables.offset_y)
	
	HUD_FRAGMENT:RegisterCallback("StateChange", PDT_fragmentChange)
	
	--Settings
	local settings = LibHarvensAddonSettings:AddAddon("Personal Dps Tracker")
	local areSettingsDisabled = false
	
	local generalSection = {type = LibHarvensAddonSettings.ST_SECTION,label = "General",}
	local textSection = {type = LibHarvensAddonSettings.ST_SECTION,label = "Text",}
	local positionSection = {type = LibHarvensAddonSettings.ST_SECTION,label = "Position",}
	
	local changeCounter = 0
	
	local toggle = {
        type = LibHarvensAddonSettings.ST_CHECKBOX, --setting type
        label = "Hide Tracker?", 
        tooltip = "Disables the tracker when set to \"On\"",
        default = PDT.defaults.checked,
        setFunction = function(state) 
            PDT.savedVariables.checked = state
			DpsIndicator:SetHidden(state)
			
			if state ==  false then
				--Hide UI 5 seconds after most recent change. multiple changes can be queued.
				DpsIndicator:SetHidden(false)
				changeCounter = changeCounter + 1
				local changeNum = changeCounter
				zo_callLater(function()
					if changeNum == changeCounter then
						changeCounter = 0
						if SCENE_MANAGER:GetScene("hud"):GetState() == SCENE_HIDDEN or PDT.savedVariables.checked then
							DpsIndicator:SetHidden(true)
						end
					end
				end, 5000)
			end
        end,
        getFunction = function() 
            return PDT.savedVariables.checked
        end,
        disable = function() return areSettingsDisabled end,
    }
	
	local resetDefaults = {
        type = LibHarvensAddonSettings.ST_BUTTON,
        label = "Reset Defaults",
        tooltip = "",
        buttonText = "RESET",
        clickHandler = function(control, button)
			PDT.savedVariables.colorR = PDT.defaults.colorR
			PDT.savedVariables.colorG = PDT.defaults.colorG
			PDT.savedVariables.colorB = PDT.defaults.colorB
			PDT.savedVariables.colorA = PDT.defaults.colorA
			PDT.savedVariables.selectedText_font = PDT.defaults.selectedText_font
			PDT.savedVariables.selectedFont = PDT.defaults.selectedFont
			PDT.savedVariables.selectedText_pos = PDT.defaults.selectedText_pos
			PDT.savedVariables.selectedPos = PDT.defaults.selectedPos
			PDT.savedVariables.checked = PDT.defaults.checked
			PDT.savedVariables.offset_x = PDT.defaults.offset_x
			PDT.savedVariables.offset_y = PDT.defaults.offset_y
			
			DpsIndicator:SetHidden(PDT.savedVariables.checked)
			DpsIndicatorLabel:SetColor(PDT.savedVariables.colorR, PDT.savedVariables.colorG, PDT.savedVariables.colorB)
			DpsIndicatorLabel:SetAlpha(PDT.savedVariables.colorA)
			DpsIndicatorLabel:SetFont(PDT.savedVariables.selectedFont)
			DpsIndicator:ClearAnchors()
			DpsIndicator:SetAnchor(PDT.savedVariables.selectedPos, GuiRoot, PDT.savedVariables.selectedPos, PDT.savedVariables.offset_x, PDT.savedVariables.offset_y)
			DpsIndicatorLabel:ClearAnchors()
			DpsIndicatorLabel:SetAnchor(PDT.savedVariables.selectedPos, DpsIndicator, PDT.savedVariables.selectedPos, PDT.savedVariables.offset_x, PDT.savedVariables.offset_y)
        
			PDT.savedVariables.displayText = PDT.defaults.displayText
			PDT.savedVariables.displayText_Boss = PDT.defaults.displayText_Boss
			
			PDT.savedVariables.formatType = PDT.defaults.formatType
			PDT.savedVariables.selectedFormatName = PDT.defaults.selectedFormatName
			PDT_updateText()
			
			--Hide UI 5 seconds after most recent change. multiple changes can be queued.
			DpsIndicator:SetHidden(false)
			changeCounter = changeCounter + 1
			local changeNum = changeCounter
			zo_callLater(function()
				if changeNum == changeCounter then
					changeCounter = 0
					if SCENE_MANAGER:GetScene("hud"):GetState() == SCENE_HIDDEN or PDT.savedVariables.checked then
						DpsIndicator:SetHidden(true)
					end
				end
			end, 5000)
		end,
        disable = function() return areSettingsDisabled end,
    }
	
    local editText = {
        type = LibHarvensAddonSettings.ST_EDIT,
        label = "Display Text",
        tooltip = "This setting lets you modify the display text.\n\n"..
					"This text will display when you aren't fighting a boss.\n\n"..
					"<d> will be replaced with your overall DPS\n"..
					"<D> will be replaced with your overall damage\n"..
					"<b> will be replaced with your boss DPS\n"..
					"<B> will be replaced with your overall damage to bosses\n"..
					"<t> will be replaced with the fight time\n",
        default = PDT.defaults.displayText,
        setFunction = function(value)
            PDT.savedVariables.displayText = value
			
			PDT_updateText()
			
			--Hide UI 5 seconds after most recent change. multiple changes can be queued.
			DpsIndicator:SetHidden(false)
			changeCounter = changeCounter + 1
			local changeNum = changeCounter
			zo_callLater(function()
				if changeNum == changeCounter then
					changeCounter = 0
					if SCENE_MANAGER:GetScene("hud"):GetState() == SCENE_HIDDEN or PDT.savedVariables.checked then
						DpsIndicator:SetHidden(true)
					end
				end
			end, 5000)
        end,
        getFunction = function()
            return PDT.savedVariables.displayText
        end,
        disable = function() return areSettingsDisabled end,
    }
	
	local editText_Boss = {
        type = LibHarvensAddonSettings.ST_EDIT,
        label = "Display Text (Boss)",
        tooltip = "This setting lets you modify the display text.\n\n"..
					"This text will display when you are fighting a boss.\n\n"..
					"<d> will be replaced with your overall DPS\n"..
					"<D> will be replaced with your overall damage\n"..
					"<b> will be replaced with your boss DPS\n"..
					"<B> will be replaced with your overall damage to bosses\n"..
					"<t> will be replaced with the fight time\n",
        default = PDT.defaults.displayText_Boss,
        setFunction = function(value)
            PDT.savedVariables.displayText_Boss = value
			
			PDT_updateText()
			
			--Hide UI 5 seconds after most recent change. multiple changes can be queued.
			DpsIndicator:SetHidden(false)
			changeCounter = changeCounter + 1
			local changeNum = changeCounter
			zo_callLater(function()
				if changeNum == changeCounter then
					changeCounter = 0
					if SCENE_MANAGER:GetScene("hud"):GetState() == SCENE_HIDDEN or PDT.savedVariables.checked then
						DpsIndicator:SetHidden(true)
					end
				end
			end, 5000)
        end,
        getFunction = function()
            return PDT.savedVariables.displayText_Boss
        end,
        disable = function() return areSettingsDisabled end,
    }
	
	local formatNumber = {
        type = LibHarvensAddonSettings.ST_DROPDOWN,
        label = "Format Number",
        tooltip = "Change the way that this addon will display large numbers.\n\n"..
					"1: 134419 becomes 134,419 and 4149257 becomes 4,149,257\n\n"..
					"2: 134419 becomes 134.4k and 4149257 becomes 4.149M\n\n"..
					"3: 134419 becomes 134k and 4149257 becomes 4.1M",
        setFunction = function(combobox, name, item)
			PDT.savedVariables.selectedFormatName = item.name
			PDT.savedVariables.formatType = item.data
			
			--Hide UI 5 seconds after most recent change. multiple changes can be queued.
			DpsIndicator:SetHidden(false)
			changeCounter = changeCounter + 1
			local changeNum = changeCounter
			zo_callLater(function()
				if changeNum == changeCounter then
					changeCounter = 0
					if SCENE_MANAGER:GetScene("hud"):GetState() == SCENE_HIDDEN or PDT.savedVariables.checked then
						DpsIndicator:SetHidden(true)
					end
				end
			end, 5000)
        end,
        getFunction = function()
            return PDT.savedVariables.selectedFormatName
        end,
        default = PDT.defaults.selectedFormatName,
        items = {
            {
                name = "134,419",
                data = 1
            },
            {
                name = "134.4k",
                data = 2
            },
            {
                name = "134k",
                data = 3
            },
        },
        disable = function() return areSettingsDisabled end,
    }
	
    local color = {
        type = LibHarvensAddonSettings.ST_COLOR,
        label = "Text Color",
        tooltip = "Change the text color of the dps tracker.",
        setFunction = function(...) --newR, newG, newB, newA
            PDT.savedVariables.colorR, PDT.savedVariables.colorG, PDT.savedVariables.colorB, PDT.savedVariables.colorA = ...
			DpsIndicatorLabel:SetColor(PDT.savedVariables.colorR, PDT.savedVariables.colorG, PDT.savedVariables.colorB)
			DpsIndicatorLabel:SetAlpha(PDT.savedVariables.colorA)
        
			--Hide UI 5 seconds after most recent change. multiple changes can be queued.
			DpsIndicator:SetHidden(false)
			changeCounter = changeCounter + 1
			local changeNum = changeCounter
			zo_callLater(function()
				if changeNum == changeCounter then
					changeCounter = 0
					if SCENE_MANAGER:GetScene("hud"):GetState() == SCENE_HIDDEN or PDT.savedVariables.checked then
						DpsIndicator:SetHidden(true)
					end
				end
			end, 5000)
		end,
        default = {PDT.defaults.colorR, PDT.defaults.colorG, PDT.defaults.colorB, PDT.defaults.colorA},
        getFunction = function()
            return PDT.savedVariables.colorR, PDT.savedVariables.colorG, PDT.savedVariables.colorB, PDT.savedVariables.colorA
        end,
        disable = function() return areSettingsDisabled end,
    }
	
    local dropdown_font = {
        type = LibHarvensAddonSettings.ST_DROPDOWN,
        label = "Font Size",
        tooltip = "Change the size of the dps tracker.",
        setFunction = function(combobox, name, item)
			DpsIndicatorLabel:SetFont(item.data)
			PDT.savedVariables.selectedText_font = name
			PDT.savedVariables.selectedFont = item.data
			
			--Hide UI 5 seconds after most recent change. multiple changes can be queued.
			DpsIndicator:SetHidden(false)
			changeCounter = changeCounter + 1
			local changeNum = changeCounter
			zo_callLater(function()
				if changeNum == changeCounter then
					changeCounter = 0
					if SCENE_MANAGER:GetScene("hud"):GetState() == SCENE_HIDDEN or PDT.savedVariables.checked then
						DpsIndicator:SetHidden(true)
					end
				end
			end, 5000)
        end,
        getFunction = function()
            return PDT.savedVariables.selectedText_font
        end,
        default = PDT.defaults.selectedText_font,
        items = {
            {
                name = "18",
                data = "ZoFontGamepad18"
            },
            {
                name = "20",
                data = "ZoFontGamepad20"
            },
            {
                name = "22",
                data = "ZoFontGamepad22"
            },
            {
                name = "25",
                data = "ZoFontGamepad25"
            },
            {
                name = "34",
                data = "ZoFontGamepad34"
            },
            {
                name = "36",
                data = "ZoFontGamepad36"
            },
            {
                name = "42",
                data = "ZoFontGamepad42"
            },
            {
                name = "54",
                data = "ZoFontGamepad54"
            },
            {
                name = "61",
                data = "ZoFontGamepad61"
            },
        },
        disable = function() return areSettingsDisabled end,
    }
	
	
    local dropdown_pos = {
        type = LibHarvensAddonSettings.ST_DROPDOWN,
        label = "Tracker Position",
        tooltip = "",
        setFunction = function(combobox, name, item)
			PDT.savedVariables.selectedText_pos = name
			PDT.savedVariables.selectedPos = item.data
			
			DpsIndicator:ClearAnchors()
			DpsIndicator:SetAnchor(PDT.savedVariables.selectedPos, GuiRoot, PDT.savedVariables.selectedPos, PDT.savedVariables.offset_x, PDT.savedVariables.offset_y)
			DpsIndicatorLabel:ClearAnchors()
			DpsIndicatorLabel:SetAnchor(PDT.savedVariables.selectedPos, DpsIndicator, PDT.savedVariables.selectedPos, PDT.savedVariables.offset_x, PDT.savedVariables.offset_y)
        
			--Hide UI 5 seconds after most recent change. multiple changes can be queued.
			DpsIndicator:SetHidden(false)
			changeCounter = changeCounter + 1
			local changeNum = changeCounter
			zo_callLater(function()
				if changeNum == changeCounter then
					changeCounter = 0
					if SCENE_MANAGER:GetScene("hud"):GetState() == SCENE_HIDDEN or PDT.savedVariables.checked then
						DpsIndicator:SetHidden(true)
					end
				end
			end, 5000)
		end,
        getFunction = function()
            return PDT.savedVariables.selectedText_pos
        end,
        default = PDT.defaults.selectedText_pos,
        items = {
            {
                name = "Top Left",
                data = 3
            },
			{
                name = "Top",
                data = 1
            },
            {
                name = "Top Right",
                data = 9
            },
			{
                name = "Left",
                data = 2
            },
			{
                name = "Center",
                data = 128
            },
			{
                name = "Right",
                data = 8
            },
			{
                name = "Bottom Left",
                data = 6
            },
			{
                name = "Bottom",
                data = 4
            },
			{
                name = "Bottom Right",
                data = 12
            },
        },
        disable = function() return areSettingsDisabled end,
    }
	
	--x position offset
	local slider_x = {
        type = LibHarvensAddonSettings.ST_SLIDER,
        label = "X Offset",
        tooltip = "",
        setFunction = function(value)
			PDT.savedVariables.offset_x = value
			
			DpsIndicator:ClearAnchors()
			DpsIndicator:SetAnchor(PDT.savedVariables.selectedPos, GuiRoot, PDT.savedVariables.selectedPos, PDT.savedVariables.offset_x, PDT.savedVariables.offset_y)
			DpsIndicatorLabel:ClearAnchors()
			DpsIndicatorLabel:SetAnchor(PDT.savedVariables.selectedPos, DpsIndicator, PDT.savedVariables.selectedPos, PDT.savedVariables.offset_x, PDT.savedVariables.offset_y)
        
			--Hide UI 5 seconds after most recent change. multiple changes can be queued.
			DpsIndicator:SetHidden(false)
			changeCounter = changeCounter + 1
			local changeNum = changeCounter
			zo_callLater(function()
				if changeNum == changeCounter then
					changeCounter = 0
					if SCENE_MANAGER:GetScene("hud"):GetState() == SCENE_HIDDEN or PDT.savedVariables.checked then
						DpsIndicator:SetHidden(true)
					end
				end
			end, 5000)
		end,
        getFunction = function()
            return PDT.savedVariables.offset_x
        end,
        default = 0,
        min = -750,
        max = 750,
        step = 5,
        unit = "", --optional unit
        format = "%d", --value format
        disable = function() return areSettingsDisabled end,
    }
	
	--y position offset
	local slider_y = {
        type = LibHarvensAddonSettings.ST_SLIDER,
        label = "Y Offset",
        tooltip = "",
        setFunction = function(value)
			PDT.savedVariables.offset_y = value
			
			DpsIndicator:ClearAnchors()
			DpsIndicator:SetAnchor(PDT.savedVariables.selectedPos, GuiRoot, PDT.savedVariables.selectedPos, PDT.savedVariables.offset_x, PDT.savedVariables.offset_y)
			DpsIndicatorLabel:ClearAnchors()
			DpsIndicatorLabel:SetAnchor(PDT.savedVariables.selectedPos, DpsIndicator, PDT.savedVariables.selectedPos, PDT.savedVariables.offset_x, PDT.savedVariables.offset_y)
        
			--Hide UI 5 seconds after most recent change. multiple changes can be queued.
			DpsIndicator:SetHidden(false)
			changeCounter = changeCounter + 1
			local changeNum = changeCounter
			zo_callLater(function()
				if changeNum == changeCounter then
					changeCounter = 0
					if SCENE_MANAGER:GetScene("hud"):GetState() == SCENE_HIDDEN or PDT.savedVariables.checked then
						DpsIndicator:SetHidden(true)
					end
				end
			end, 5000)
		end,
        getFunction = function()
            return PDT.savedVariables.offset_y
        end,
        default = 0,
        min = -750,
        max = 750,
        step = 5,
        unit = "", --optional unit
        format = "%d", --value format
        disable = function() return areSettingsDisabled end,
    }
	
	settings:AddSettings({generalSection, toggle, resetDefaults, textSection, editText, editText_Boss, formatNumber, dropdown_font, color, positionSection, dropdown_pos, slider_x, slider_y})
	
	PDT_onNewBosses(_, _)
	
	PDT_updateText()
	
	EVENT_MANAGER:RegisterForEvent(PDT.name, EVENT_PLAYER_COMBAT_STATE, PDT_ChangePlayerCombatState)
	EVENT_MANAGER:RegisterForEvent(PDT.name, EVENT_COMBAT_EVENT, PDT_OnCombatEvent)
	EVENT_MANAGER:RegisterForEvent(PDT.name, EVENT_BOSSES_CHANGED, PDT_onNewBosses)
	EVENT_MANAGER:RegisterForEvent(PDT.name, EVENT_PLAYER_ALIVE, PDT_onRevive)
end

function PDT.OnAddOnLoaded(event, addonName)
	if addonName == PDT.name then
		PDT.Initialize()
		EVENT_MANAGER:UnregisterForEvent(PDT.name, EVENT_ADD_ON_LOADED)
	end
end

EVENT_MANAGER:RegisterForEvent(PDT.name, EVENT_ADD_ON_LOADED, PDT.OnAddOnLoaded)