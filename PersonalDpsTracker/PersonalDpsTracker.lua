PDT = { name = "PersonalDpsTracker" }

PDT.TotalDamage = 0
PDT.PreCombatDamage = 0
PDT.startTime = 0 --milliseconds
PDT.endTime = 0 --milliseconds
PDT.fightTime = function () return ((PDT.endTime-PDT.startTime)/1000) end --seconds
PDT.rawDPS = function () return PDT.TotalDamage/PDT.fightTime() end
PDT.formattedDPS = function() 
	local formatted = string.format("%.1f", PDT.rawDPS())
	while true do  
		formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
		if (k==0) then break end
	end
  return formatted
end

PDT.defaults = {
	colorR = 1.0,
	colorG = 1.0,
	colorB = 1.0,
	colorA = 1.0,
	selectedText_font = "18",
	selectedFont = "ZoFontGamepad18",
	selectedText_pos = "Top Left",
	selectedPos = 3,
	checked = false,
	offset_x = 0,
	offset_y = 0,
}

function PDT.ChangePlayerCombatState(event, inCombat)
	--inCombat == true if the player just entered combat.
	--inCombat == false if the player just exited combat.

	PDT.activeCombat = inCombat 
	
	
	if inCombat then 
		if PDT.startTime == 0 then PDT.startTime = GetGameTimeMilliseconds() end
	else
		--Reset variables
		PDT.startTime, PDT.endTime = 0, 0
		PDT.TotalDamage = 0 
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
		--Damage from player to NPC or player pet to NPC
		
		--This event can happen before the combat event, so I'm accounting for the minimal amount of damage the player might deal inbetween.
		if PDT.activeCombat == false then
			PDT.PreCombatDamage = PDT.PreCombatDamage + hitValue
			if PDT.startTime == 0 then PDT.startTime = GetGameTimeMilliseconds() end
		else 
			if PDT.PreCombatDamage ~= 0 then
				PDT.TotalDamage = PDT.TotalDamage + PDT.PreCombatDamage
				PDT.PreCombatDamage = 0
			end
			
			if PDT.startTime == 0 then PDT.startTime = GetGameTimeMilliseconds() end
			PDT.TotalDamage = PDT.TotalDamage + hitValue
			PDT.endTime = GetGameTimeMilliseconds()
			
			DpsIndicatorLabel:SetText("DPS: "..PDT.formattedDPS())
			
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
	
	--[[local colorR, colorG, colorB, colorA = PDT.savedVariables.colorR, PDT.savedVariables.colorG, PDT.savedVariables.colorB, PDT.savedVariables.colorA
	local selectedText_font = PDT.savedVariables.selectedText_font
	local selectedFont = PDT.savedVariables.selectedFont
	local selectedText_pos = PDT.savedVariables.selectedText_pos
	local selectedPos = PDT.savedVariables.selectedPos
	local checked = PDT.savedVariables.checked
	local offset_x, offset_y = PDT.savedVariables.offset_x, PDT.savedVariables.offset_y]]
	
	local generalSection = {type = LibHarvensAddonSettings.ST_SECTION,label = "General",}
	local fontSection = {type = LibHarvensAddonSettings.ST_SECTION,label = "Font",}
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
        end,
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
        min = -250,
        max = 250,
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
        min = -250,
        max = 250,
        step = 5,
        unit = "", --optional unit
        format = "%d", --value format
        disable = function() return areSettingsDisabled end,
    }
	
	settings:AddSettings({generalSection, toggle, resetDefaults, fontSection, dropdown_font, color, positionSection, dropdown_pos, slider_x, slider_y})
	
	EVENT_MANAGER:RegisterForEvent(PDT.name, EVENT_PLAYER_COMBAT_STATE, PDT.ChangePlayerCombatState)
	EVENT_MANAGER:RegisterForEvent(PDT.name, EVENT_COMBAT_EVENT, PDT.OnCombatEvent)
end

function PDT.OnAddOnLoaded(event, addonName)
	if addonName == PDT.name then
		PDT.Initialize()
		EVENT_MANAGER:UnregisterForEvent(PDT.name, EVENT_ADD_ON_LOADED)
	end
end

EVENT_MANAGER:RegisterForEvent(PDT.name, EVENT_ADD_ON_LOADED, PDT.OnAddOnLoaded)