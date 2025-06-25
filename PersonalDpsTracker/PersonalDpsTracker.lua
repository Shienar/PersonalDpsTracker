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
	experimentalFeatures = false
}

PDT.TotalDamage = 0
PDT.PreCombatDamage = 0
PDT.TotalDamage_Boss = 0
PDT.PreCombatDamage_Boss = 0
PDT.startTime = 0 --milliseconds
PDT.endTime = 0 --milliseconds
PDT.fightTime = function () return ((PDT.endTime-PDT.startTime)/1000) end --seconds
PDT.bossNames = { }
PDT.deadOnBoss = false

function PDT.formattedTime(s)
	local minutes, seconds = math.floor(s/60), s%60
	if seconds < 10 then return minutes..":0"..seconds end
	return minutes..":"..seconds
end

function PDT.getRawDPS(damage, duration) 
	return damage/duration
end

function PDT.formatNumber(number)
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
	
local function updateText()
	local formattedString = ""
	
	if #PDT.bossNames == 0 then
		 formattedString = PDT.savedVariables.displayText
	else
		formattedString = PDT.savedVariables.displayText_Boss
	end
	
	if PDT.TotalDamage_Boss ~= 0 then 
		formattedString = string.gsub(formattedString, "<b>", tostring(PDT.formatNumber(PDT.getRawDPS(PDT.TotalDamage_Boss, PDT.fightTime()))))
	else
		formattedString = string.gsub(formattedString, "<b>", "0k")
	end
	formattedString = string.gsub(formattedString, "<B>", tostring(PDT.formatNumber(PDT.TotalDamage_Boss)))
	if PDT.TotalDamage ~= 0 then
		formattedString = string.gsub(formattedString, "<d>", tostring(PDT.formatNumber(PDT.getRawDPS(PDT.TotalDamage, PDT.fightTime()))))
	else
		formattedString = string.gsub(formattedString, "<d>", "0k")
	end
	formattedString = string.gsub(formattedString, "<D>", tostring(PDT.formatNumber(PDT.TotalDamage)))
	formattedString = string.gsub(formattedString, "<t>", tostring(PDT.formattedTime(math.floor(PDT.fightTime()))))
			
	DpsIndicatorLabel:SetText(formattedString)
end

--A boss name could be both "Iron-Heel" or "Iron-Heel^M", so i gotta do some extra work.
local function containsVal(table, val)
	if string.find(val, "^", 1, true) ~= nil then val = string.sub(val, 1, (string.find(val, "^", 1, true) - 1)) end
	
	for k, v in pairs(table) do
		if v == val then 
			return true 
		end
	end
	return false
end


function PDT.onNewBosses(code, forceReset)
	for i = 1, 12 do
		local tempTag = "boss"..i
		if DoesUnitExist(tempTag) and containsVal(PDT.bossNames, GetUnitName(tempTag)) == false then
			PDT.bossNames[#PDT.bossNames + 1] = GetUnitName(tempTag)
		end
	end
end

function PDT.ChangePlayerCombatState(event, inCombat)
	--inCombat == true if the player just entered combat.
	--inCombat == false if the player just exited combat.
	
	PDT.activeCombat = inCombat 
	
	if inCombat then 
		PDT.deadOnBoss = false
		if PDT.startTime == 0 then PDT.startTime = GetGameTimeMilliseconds() end
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
					PDT.startTime, PDT.endTime = 0, 0
					PDT.TotalDamage, PDT.TotalDamage_Boss = 0, 0
					PDT.bossNames = { }
				else
					--player is dead but boss isn't
					PDT.deadOnBoss = true
				end
			else
				--Not a boss fight.
				--Reset variables
				PDT.startTime, PDT.endTime = 0, 0
				PDT.TotalDamage, PDT.TotalDamage_Boss = 0, 0
				PDT.bossNames = { }	
			end
		end, 500)
	end
	
end

function PDT.onRevive(code)
	--Timeline:
		--player died during boss
		--player respawned
		--player isn't in combat 2.5s later.
		--Assume boss is dead and reset variables.
	if PDT.deadOnBoss then
		zo_callLater(function ()
			PDT.deadOnBoss = false
			PDT.startTime, PDT.endTime = 0, 0
			PDT.TotalDamage, PDT.TotalDamage_Boss = 0, 0
			PDT.bossNames = { }
		end, 2500)
	end
end


function PDT.OnCombatEvent(eventCode, result, isError, abilityName, abilityGraphic, abilityActionSlotType, sourceName, sourceType, targetName, targetType, hitValue, powerType, damageType, _log, sourceUnitID, targetUnitID, abilityID, overflow)
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
		if PDT.activeCombat == false then
			PDT.PreCombatDamage = PDT.PreCombatDamage + hitValue
			if containsVal(PDT.bossNames, targetName) then PDT.PreCombatDamage_Boss = PDT.PreCombatDamage_Boss + hitValue end
			if PDT.startTime == 0 then PDT.startTime = GetGameTimeMilliseconds() end
		else 
			if PDT.PreCombatDamage ~= 0 then
				PDT.TotalDamage = PDT.TotalDamage + PDT.PreCombatDamage
				PDT.TotalDamage_Boss = PDT.TotalDamage_Boss + PDT.PreCombatDamage_Boss
				PDT.PreCombatDamage = 0
				PDT.PreCombatDamage_Boss = 0
			end
			
			if PDT.startTime == 0 then PDT.startTime = GetGameTimeMilliseconds() end
			
			PDT.TotalDamage = PDT.TotalDamage + hitValue
			if containsVal(PDT.bossNames, targetName) then PDT.TotalDamage_Boss = PDT.TotalDamage_Boss + hitValue end
			
			PDT.endTime = GetGameTimeMilliseconds()
			
			updateText()
		end
	end
end

function PDT.Initialize()
	PDT.activeCombat = IsUnitInCombat("player")
	
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
	
	
	--Settings
	local settings = LibHarvensAddonSettings:AddAddon("Personal Dps Tracker")
	local areSettingsDisabled = false
	
	local generalSection = {type = LibHarvensAddonSettings.ST_SECTION,label = "General",}
	local textSection = {type = LibHarvensAddonSettings.ST_SECTION,label = "Text",}
	local positionSection = {type = LibHarvensAddonSettings.ST_SECTION,label = "Position",}
	
	local toggle = {
        type = LibHarvensAddonSettings.ST_CHECKBOX, --setting type
        label = "Hide Tracker?", 
        tooltip = "Disables the tracker when set to \"On\"",
        default = PDT.defaults.checked,
        setFunction = function(state) 
            PDT.savedVariables.checked = state
			DpsIndicator:SetHidden(state)
        end,
        getFunction = function() 
            return PDT.savedVariables.checked
        end,
        disable = function() return areSettingsDisabled end,
    }
	
	local experimental = {
        type = LibHarvensAddonSettings.ST_CHECKBOX, --setting type
        label = "Enable experimental features.", 
        tooltip = "Some features require testing on console before I can ensure their quality, so I'm giving you the choice to enable/disable them.\n\n"..
					"Note: Enabling experimental features may cause issues with this addon and your game.\n\n"..
					"Current features being tested:\n"..
					"- N/A (This option currently has no effect)",
        default = PDT.defaults.experimentalFeatures,
        setFunction = function(state) 
            PDT.savedVariables.experimentalFeatures = state
        end,
        getFunction = function() 
            return PDT.savedVariables.experimentalFeatures
        end,
        disable = function() return areSettingsDisabled end,
    }
	
	local resetDefaults = {
        type = LibHarvensAddonSettings.ST_BUTTON,
        label = "Reset Defaults",
        tooltip = "",
        buttonText = "RESET",
        clickHandler = function(control, button)
			PDT.savedVariables.experimentalFeatures = PDT.defaults.experimentalFeatures
		
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
			updateText()
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
			
			updateText()
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
			
			updateText()
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
	
	settings:AddSettings({generalSection, toggle, experimental, resetDefaults, textSection, editText, editText_Boss, formatNumber, dropdown_font, color, positionSection, dropdown_pos, slider_x, slider_y})
	
	PDT.onNewBosses(_, _)
	
	updateText()
	
	
	EVENT_MANAGER:RegisterForEvent(PDT.name, EVENT_PLAYER_COMBAT_STATE, PDT.ChangePlayerCombatState)
	EVENT_MANAGER:RegisterForEvent(PDT.name, EVENT_COMBAT_EVENT, PDT.OnCombatEvent)
	EVENT_MANAGER:RegisterForEvent(PDT.name, EVENT_BOSSES_CHANGED, PDT.onNewBosses)
	EVENT_MANAGER:RegisterForEvent(PDT.name, EVENT_PLAYER_ALIVE, PDT.onRevive)
end

function PDT.OnAddOnLoaded(event, addonName)
	if addonName == PDT.name then
		PDT.Initialize()
		EVENT_MANAGER:UnregisterForEvent(PDT.name, EVENT_ADD_ON_LOADED)
	end
end

EVENT_MANAGER:RegisterForEvent(PDT.name, EVENT_ADD_ON_LOADED, PDT.OnAddOnLoaded)