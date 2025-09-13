PDT = PDT or {}
PDT.name = "PersonalDpsTracker"

local activeCombat = false
local TotalDamage = 0
local PreCombatDamage = 0
local TotalDamage_Boss = 0
local PreCombatDamage_Boss = 0
local startTime = 0 --milliseconds
local endTime = 0 --milliseconds
local fightTime = function () return (endTime-startTime)/1000 end --seconds
local bossNames = { }
local deadOnBoss = false

local dmgTypes = {
	preCombat = {
		directDMG = 0,
		dotDMG = 0,
		martialDMG = 0,
		magicalDMG = 0,
		areaDMG = 0,
	},
	directDMG = 0,
	dotDMG = 0,
	martialDMG = 0,
	magicalDMG = 0,
	areaDMG = 0,
}
local dmgTypes_Boss = {
	preCombat = {
		directDMG = 0,
		dotDMG = 0,
		martialDMG = 0,
		magicalDMG = 0,
		areaDMG = 0,
	},
	directDMG = 0,
	dotDMG = 0,
	martialDMG = 0,
	magicalDMG = 0,
	areaDMG = 0,
}

--The IDs are documented better in an excel file within the github.
--These abilityIDs are buffed by the AOE dmg banner.
--They are stored this way to allow for a fast binary search.
--A table with these values as keys would take up a lot of space as a hash table.
local areaIDs = {
    7102,
    15959,
    17875,
    17979,
    19128,
    20245,
    20251,
    20252,
    20917,
    20919,
    20930,
    20944,
    21732,
    21753,
    21756,
    21759,
    22138,
    22139,
    22144,
    22165,
    22178,
    22181,
    22182,
    23189,
    23202,
    23208,
    23211,
    23214,
    23232,
    23239,
    23659,
    23664,
    23667,
    24327,
    24329,
    24331,
    24798,
    25091,
    25170,
    25494,
    26192,
    26859,
    26871,
    26879,
    28309,
    28591,
    28794,
    28798,
    28877,
    28995,
    29014,
    29529,
    29809,
    31540,
    31604,
    31635,
    31837,
    31842,
    32711,
    32714,
    32716,
    32720,
    32785,
    32787,
    32792,
    32794,
    32948,
    32960,
    33316,
    33497,
    34404,
    34502,
    35460,
    35713,
    36052,
    36490,
    36891,
    36901,
    38561,
    38690,
    38696,
    38722,
    38723,
    38724,
    38745,
    38754,
    38792,
    38823,
    38861,
    38891,
    38935,
    38968,
    39054,
    39056,
    39071,
    39072,
    39079,
    39080,
    39149,
    39151,
    39153,
    39299,
    40158,
    40161,
    40252,
    40267,
    40300,
    40416,
    40469,
    40473,
    41839,
    42029,
    44426,
    44432,
    44436,
    44483,
    44491,
    50992,
    57209,
    58855,
    58864,
    58879,
    59498,
    59593,
    59696,
    61273,
    61488,
    61493,
    61502,
    62522,
    62529,
    62547,
    62550,
    62598,
    62606,
    62896,
    62931,
    62971,
    63429,
    63454,
    63457,
    63471,
    63474,
    67136,
    71646,
    71658,
    75692,
    75752,
    76344,
    77186,
    80083,
    80107,
    80129,
    80172,
    80435,
    80521,
    80522,
    80526,
    80544,
    80561,
    80565,
    80865,
    83409,
    83626,
    83629,
    83631,
    83683,
    83685,
    83687,
    84355,
    84502,
    85127,
    85129,
    85131,
    85432,
    86156,
    86247,
    88783,
    88791,
    88802,
    88860,
    88863,
    89128,
    89220,
    93307,
    94411,
    94424,
    94445,
    95931,
    95955,
    97574,
    97716,
    100218,
    102094,
    102136,
    105907,
    108844,
    108936,
    114798,
    115115,
    115254,
    115572,
    116410,
    116920,
    117715,
    117809,
    117854,
    118011,
    118223,
    118266,
    118289,
    118314,
    118618,
    118720,
    118766,
    121917,
    122178,
    122392,
    122399,
    122400,
    122401,
    123082,
    124468,
    126474,
    126633,
    126718,
    126720,
    126722,
    126941,
    127791,
    127792,
    127793,
    130170,
    130406,
    133494,
    134310,
    134340,
    137184,
    137526,
    141642,
    142305,
    143944,
    143946,
    146553,
    146593,
    147694,
    154347,
    159253,
    159275,
    159386,
    159387,
    159516,
    163293,
    166788,
    167048,
    167062,
    167115,
    167607,
    167680,
    167742,
    167962,
    170989,
    170990,
    172672,
    172912,
    173734,
    175349,
    176816,
    181330,
    181331,
    183006,
    183123,
    183678,
    185407,
    185808,
    185817,
    185823,
    186370,
    189793,
    189869,
    189893,
    191078,
    193275,
    214520,
    214756,
    214889,
    214960,
    217178,
    217231,
    217348,
    217359,
    217459,
    217632,
    217679,
    220098,
    220101,
    220104,
    227072,
    229656,
    235745,
    235836,
    236163,
    236655,
    236789,
    239711,
    240131,
    243309,
    248631,
}

local function comparator(left, right, _)
    return left-right
end

local function isAreaDMG(abilityID)
    return zo_binarysearch(abilityID, areaIDs, comparator)
end

local function getRawDPS(damage, duration)
	return damage/duration
end

local function formatNumber(number)
	--input examples: 134519.165 dps or 4149256 damage
	if PDT.savedVariables.formatType == 1 then
		--134,419
		--4,149,257
		return ZO_CommaDelimitNumber(math.floor(number))
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
		--134k
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

--A boss name could be both "Iron-Heel" or "Iron-Heel^M", so i gotta do some extra work.
function PDT.containsVal(table, val)
	if string.find(val, "^", 1, true) ~= nil then val = string.sub(val, 1, (string.find(val, "^", 1, true) - 1)) end
	
	for k, v in pairs(table) do
		if v == val then 
			return true 
		end
	end
	return false
end

function PDT.updateText()

	local formattedString = ""
	
	if #bossNames == 0 then
		formattedString = PDT.savedVariables.displayText
	else
		formattedString = PDT.savedVariables.displayText_Boss
	end
	
	if TotalDamage_Boss ~= 0 then 
		formattedString = string.gsub(formattedString, "<b>", tostring(formatNumber(getRawDPS(TotalDamage_Boss, fightTime()))))
	else
		formattedString = string.gsub(formattedString, "<b>", "0")
		formattedString = string.gsub(formattedString, "<B>", "0")
	end
	formattedString = string.gsub(formattedString, "<B>", tostring(formatNumber(TotalDamage_Boss)))
	
	if TotalDamage ~= 0 then
		formattedString = string.gsub(formattedString, "<d>", tostring(formatNumber(getRawDPS(TotalDamage, fightTime()))))
	else
		formattedString = string.gsub(formattedString, "<d>", "0")
		formattedString = string.gsub(formattedString, "<D>", "0")
	end
	formattedString = string.gsub(formattedString, "<D>", tostring(formatNumber(TotalDamage)))

	formattedString = string.gsub(formattedString, "<t>", tostring(ZO_FormatTime(fightTime(), TIME_FORMAT_STYLE_COLONS, TIME_FORMAT_PRECISION_SECONDS)))
			
	PersonalDpsTrackerLabel:SetText(formattedString)
end

function PDT.updateBannerText()
	if #bossNames == 0 and TotalDamage ~= 0 then
		DMGTypeBreakdownDirect:SetText("Direct: "..math.floor((dmgTypes.directDMG/TotalDamage)*100).."%")
		DMGTypeBreakdownDOT:SetText("DOT: "..math.floor((dmgTypes.dotDMG/TotalDamage)*100).."%")
		DMGTypeBreakdownMartial:SetText("Martial: "..math.floor((dmgTypes.martialDMG/TotalDamage)*100).."%")
		DMGTypeBreakdownMagical:SetText("Magic: "..math.floor((dmgTypes.magicalDMG/TotalDamage)*100).."%")
		DMGTypeBreakdownArea:SetText("Area: "..math.floor((dmgTypes.areaDMG/TotalDamage)*100).."%")
	elseif #bossNames ~= 0 and TotalDamage_Boss ~= 0 then
		DMGTypeBreakdownDirect:SetText("Direct: "..math.floor((dmgTypes_Boss.directDMG/TotalDamage_Boss)*100).."%".." ("..math.floor((dmgTypes.directDMG/TotalDamage)*100)..")")
		DMGTypeBreakdownDOT:SetText("DOT: "..math.floor((dmgTypes_Boss.dotDMG/TotalDamage_Boss)*100).."%".." ("..math.floor((dmgTypes.dotDMG/TotalDamage)*100)..")")
		DMGTypeBreakdownMartial:SetText("Martial: "..math.floor((dmgTypes_Boss.martialDMG/TotalDamage_Boss)*100).."%".." ("..math.floor((dmgTypes.martialDMG/TotalDamage)*100)..")")
		DMGTypeBreakdownMagical:SetText("Magic: "..math.floor((dmgTypes_Boss.magicalDMG/TotalDamage_Boss)*100).."%".." ("..math.floor((dmgTypes.magicalDMG/TotalDamage)*100)..")")
		DMGTypeBreakdownArea:SetText("Area: "..math.floor((dmgTypes_Boss.areaDMG/TotalDamage_Boss)*100).."%".." ("..math.floor((dmgTypes.areaDMG/TotalDamage)*100)..")")
	else
		DMGTypeBreakdownDirect:SetText("Direct: 0%")
		DMGTypeBreakdownDOT:SetText("DOT: 0%")
		DMGTypeBreakdownMartial:SetText("Martial: 0%")
		DMGTypeBreakdownMagical:SetText("Magic: 0%")
		DMGTypeBreakdownArea:SetText("Area: 0%")
	end
end

function PDT.onNewBosses(code, forceReset)
	for i = 1, 12 do
		local tempTag = "boss"..i
		if DoesUnitExist(tempTag) and PDT.containsVal(bossNames, GetUnitName(tempTag)) == false then
			bossNames[#bossNames + 1] = GetUnitName(tempTag)
		end
	end
end

local function ChangePlayerCombatState(event, inCombat)
	--inCombat == true if the player just entered combat.
	--inCombat == false if the player just exited combat.
	
	activeCombat = inCombat 
	
	if inCombat then 
		deadOnBoss = false
		if startTime == 0 then startTime = GetGameTimeMilliseconds() end
		
		 --Z'maja doesn't trigger the event, so I'm checking for bosses at the start of combat.
		PDT.onNewBosses(_, _)
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
					startTime, endTime = 0, 0
					TotalDamage, TotalDamage_Boss = 0, 0
					bossNames = { }

					dmgTypes = {
						preCombat = {
							directDMG = 0,
							dotDMG = 0,
							martialDMG = 0,
							magicalDMG = 0,
							areaDMG = 0,
						},
						directDMG = 0,
						dotDMG = 0,
						martialDMG = 0,
						magicalDMG = 0,
						areaDMG = 0,
					}
					dmgTypes_Boss = {
						preCombat = {
							directDMG = 0,
							dotDMG = 0,
							martialDMG = 0,
							magicalDMG = 0,
							areaDMG = 0,
						},
						directDMG = 0,
						dotDMG = 0,
						martialDMG = 0,
						magicalDMG = 0,
						areaDMG = 0,
					}
				else
					--player is dead but boss isn't
					deadOnBoss = true
				end
			else
				--Not a boss fight.
				--Reset variables
				startTime, endTime = 0, 0
				TotalDamage, TotalDamage_Boss = 0, 0
				bossNames = { }

				dmgTypes = {
					preCombat = {
						directDMG = 0,
						dotDMG = 0,
						martialDMG = 0,
						magicalDMG = 0,
						areaDMG = 0,
					},
					directDMG = 0,
					dotDMG = 0,
					martialDMG = 0,
					magicalDMG = 0,
					areaDMG = 0,
				}
				dmgTypes_Boss = {
					preCombat = {
						directDMG = 0,
						dotDMG = 0,
						martialDMG = 0,
						magicalDMG = 0,
						areaDMG = 0,
					},
					directDMG = 0,
					dotDMG = 0,
					martialDMG = 0,
					magicalDMG = 0,
					areaDMG = 0,
				}
			end
		end, 500)
	end
	
end

local function onRevive(code)
	--Timeline:
		--player died during boss
		--player respawned
		--player isn't in combat 2.5s later.
		--Assume boss is dead and reset variables.
	if deadOnBoss then
		zo_callLater(function ()
			deadOnBoss = false
			startTime, endTime = 0, 0
			TotalDamage, TotalDamage_Boss = 0, 0
			bossNames = { }

			dmgTypes = {
				preCombat = {
					directDMG = 0,
					dotDMG = 0,
					martialDMG = 0,
					magicalDMG = 0,
					areaDMG = 0,
				},
				directDMG = 0,
				dotDMG = 0,
				martialDMG = 0,
				magicalDMG = 0,
				areaDMG = 0,
			}
			dmgTypes_Boss = {
				preCombat = {
					directDMG = 0,
					dotDMG = 0,
					martialDMG = 0,
					magicalDMG = 0,
					areaDMG = 0,
				},
				directDMG = 0,
				dotDMG = 0,
				martialDMG = 0,
				magicalDMG = 0,
				areaDMG = 0,
			}
		end, 2500)
	end
end

local function OnCombatEvent(eventCode, result, isError, abilityName, abilityGraphic, abilityActionSlotType, sourceName, sourceType, targetName, targetType, hitValue, powerType, damageType, _log, sourceUnitID, targetUnitID, abilityID, overflow)
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
		
		--This event can happen before the combat start event, so I'm accounting for the minimal amount of damage the player might deal inbetween.
		if activeCombat == false then
			PreCombatDamage = PreCombatDamage + hitValue
			
			--Record damage types for banner
			if result == ACTION_RESULT_DOT_TICK or result == ACTION_RESULT_DOT_TICK_CRITICAL then
				dmgTypes.preCombat.dotDMG = dmgTypes.preCombat.dotDMG + hitValue
			else
				dmgTypes.preCombat.directDMG = dmgTypes.preCombat.directDMG + hitValue
			end
			if damageType == DAMAGE_TYPE_BLEED or
				damageType == DAMAGE_TYPE_DISEASE or
				damageType == DAMAGE_TYPE_PHYSICAL or
				damageType == DAMAGE_TYPE_POISON then
					dmgTypes.preCombat.martialDMG = dmgTypes.preCombat.martialDMG + hitValue
			elseif damageType == DAMAGE_TYPE_MAGIC or
				damageType == DAMAGE_TYPE_SHOCK or
				damageType == DAMAGE_TYPE_FIRE or
				damageType == DAMAGE_TYPE_COLD then
					dmgTypes.preCombat.magicalDMG = dmgTypes.preCombat.magicalDMG + hitValue
			end
			if isAreaDMG(abilityID) then
				dmgTypes.preCombat.areaDMG = dmgTypes.preCombat.areaDMG + hitValue
			end

			if PDT.containsVal(bossNames, targetName) then
				PreCombatDamage_Boss = PreCombatDamage_Boss + hitValue 

				--Record damage types for banner
				if result == ACTION_RESULT_DOT_TICK or result == ACTION_RESULT_DOT_TICK_CRITICAL then
					dmgTypes_Boss.preCombat.dotDMG = dmgTypes_Boss.preCombat.dotDMG + hitValue
				else
					dmgTypes_Boss.preCombat.directDMG = dmgTypes_Boss.preCombat.directDMG + hitValue
				end
				if damageType == DAMAGE_TYPE_BLEED or
					damageType == DAMAGE_TYPE_DISEASE or
					damageType == DAMAGE_TYPE_PHYSICAL or
					damageType == DAMAGE_TYPE_POISON then
						dmgTypes_Boss.preCombat.martialDMG = dmgTypes_Boss.preCombat.martialDMG + hitValue
				elseif damageType == DAMAGE_TYPE_MAGIC or
					damageType == DAMAGE_TYPE_SHOCK or
					damageType == DAMAGE_TYPE_FIRE or
					damageType == DAMAGE_TYPE_COLD then
						dmgTypes_Boss.preCombat.magicalDMG = dmgTypes_Boss.preCombat.magicalDMG + hitValue
				end
				if isAreaDMG(abilityID) then
					dmgTypes_Boss.preCombat.areaDMG = dmgTypes_Boss.preCombat.areaDMG + hitValue
				end
			end

			if startTime == 0 then startTime = GetGameTimeMilliseconds() end
		else
			if PreCombatDamage ~= 0 then
				TotalDamage = TotalDamage + PreCombatDamage
				TotalDamage_Boss = TotalDamage_Boss + PreCombatDamage_Boss
				PreCombatDamage = 0
				PreCombatDamage_Boss = 0

				--Banner precombat damage
				dmgTypes.areaDMG = dmgTypes.areaDMG + dmgTypes.preCombat.areaDMG
				dmgTypes.directDMG = dmgTypes.directDMG + dmgTypes.preCombat.directDMG
				dmgTypes.dotDMG = dmgTypes.dotDMG + dmgTypes.preCombat.dotDMG
				dmgTypes.magicalDMG = dmgTypes.magicalDMG + dmgTypes.preCombat.magicalDMG
				dmgTypes.martialDMG = dmgTypes.martialDMG + dmgTypes.preCombat.martialDMG
				
				dmgTypes_Boss.areaDMG = dmgTypes_Boss.areaDMG + dmgTypes_Boss.preCombat.areaDMG
				dmgTypes_Boss.directDMG = dmgTypes_Boss.directDMG + dmgTypes_Boss.preCombat.directDMG
				dmgTypes_Boss.dotDMG = dmgTypes_Boss.dotDMG + dmgTypes_Boss.preCombat.dotDMG
				dmgTypes_Boss.magicalDMG = dmgTypes_Boss.magicalDMG + dmgTypes_Boss.preCombat.magicalDMG
				dmgTypes_Boss.martialDMG = dmgTypes_Boss.martialDMG + dmgTypes_Boss.preCombat.martialDMG

				dmgTypes.preCombat = {
					directDMG = 0,
					dotDMG = 0,
					martialDMG = 0,
					magicalDMG = 0,
					areaDMG = 0,
				}

				dmgTypes_Boss.preCombat = {
					directDMG = 0,
					dotDMG = 0,
					martialDMG = 0,
					magicalDMG = 0,
					areaDMG = 0,
				}
			end
			
			if startTime == 0 then startTime = GetGameTimeMilliseconds() end
			
			TotalDamage = TotalDamage + hitValue

			--Record damage types for banner
			if result == ACTION_RESULT_DOT_TICK or result == ACTION_RESULT_DOT_TICK_CRITICAL then
				dmgTypes.dotDMG = dmgTypes.dotDMG + hitValue
			else
				dmgTypes.directDMG = dmgTypes.directDMG + hitValue
			end
			if damageType == DAMAGE_TYPE_BLEED or
				damageType == DAMAGE_TYPE_DISEASE or
				damageType == DAMAGE_TYPE_PHYSICAL or
				damageType == DAMAGE_TYPE_POISON then
					dmgTypes.martialDMG = dmgTypes.martialDMG + hitValue
			elseif damageType == DAMAGE_TYPE_MAGIC or
				damageType == DAMAGE_TYPE_SHOCK or
				damageType == DAMAGE_TYPE_FIRE or
				damageType == DAMAGE_TYPE_COLD then
					dmgTypes.magicalDMG = dmgTypes.magicalDMG + hitValue
			end
			if isAreaDMG(abilityID) then
					dmgTypes.areaDMG = dmgTypes.areaDMG + hitValue
			end

			if PDT.containsVal(bossNames, targetName) then 
				TotalDamage_Boss = TotalDamage_Boss + hitValue 

				--Record damage types for banner
				if result == ACTION_RESULT_DOT_TICK or result == ACTION_RESULT_DOT_TICK_CRITICAL then
					dmgTypes_Boss.dotDMG = dmgTypes_Boss.dotDMG + hitValue
				else
					dmgTypes_Boss.directDMG = dmgTypes_Boss.directDMG + hitValue
				end
				if damageType == DAMAGE_TYPE_BLEED or
					damageType == DAMAGE_TYPE_DISEASE or
					damageType == DAMAGE_TYPE_PHYSICAL or
					damageType == DAMAGE_TYPE_POISON then
						dmgTypes_Boss.martialDMG = dmgTypes_Boss.martialDMG + hitValue
				elseif damageType == DAMAGE_TYPE_MAGIC or
					damageType == DAMAGE_TYPE_SHOCK or
					damageType == DAMAGE_TYPE_FIRE or
					damageType == DAMAGE_TYPE_COLD then
						dmgTypes_Boss.magicalDMG = dmgTypes_Boss.magicalDMG + hitValue
				end
				if isAreaDMG(abilityID) then
					dmgTypes_Boss.areaDMG = dmgTypes_Boss.areaDMG + hitValue
				end
			end
			
			endTime = GetGameTimeMilliseconds()
			
			if PDT.savedVariables.checked == false then PDT.updateText() end
			if PDT.savedVariables.banner_hidden == false then PDT.updateBannerText() end
		end
	end
end

local function fragmentChange(oldState, newState)
	if newState == SCENE_FRAGMENT_SHOWN then
		PersonalDpsTracker:SetHidden(PDT.savedVariables.checked)
		DMGTypeBreakdown:SetHidden(PDT.savedVariables.banner_hidden)
	elseif newState == SCENE_FRAGMENT_HIDDEN then
		PersonalDpsTracker:SetHidden(true)
		DMGTypeBreakdown:SetHidden(true)
	end
end

function PDT.Initialize()

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
		selectedPos = 3,
		checked = false,
		offset_x = 0,
		offset_y = 0,

		banner_hidden = true,
		banner_offset_x = 0,
		banner_offset_y = 0,
	}

	activeCombat = IsUnitInCombat("player")
	
	--Load and apply saved variables
	PDT.savedVariables = ZO_SavedVars:NewAccountWide("PDTSavedVariables", 1, nil, PDT.defaults, GetWorldName())
	PersonalDpsTracker:SetHidden(PDT.savedVariables.checked)
	PersonalDpsTrackerLabel:SetColor(PDT.savedVariables.colorR, PDT.savedVariables.colorG, PDT.savedVariables.colorB)
	PersonalDpsTrackerLabel:SetAlpha(PDT.savedVariables.colorA)
	PersonalDpsTrackerLabel:SetFont(PDT.savedVariables.selectedFont)
	PersonalDpsTracker:ClearAnchors()
	PersonalDpsTracker:SetAnchor(PDT.savedVariables.selectedPos, GuiRoot, PDT.savedVariables.selectedPos, PDT.savedVariables.offset_x, PDT.savedVariables.offset_y)
	
	DMGTypeBreakdown:SetHidden(PDT.savedVariables.banner_hidden)
	DMGTypeBreakdown:ClearAnchors()
	DMGTypeBreakdown:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, PDT.savedVariables.banner_offset_x, PDT.savedVariables.banner_offset_y)
			
	HUD_FRAGMENT:RegisterCallback("StateChange", fragmentChange)
	
	--Settings
	local settings = LibHarvensAddonSettings:AddAddon("Personal Dps Tracker")
	local areSettingsDisabled = false
	
	local generalSection = {type = LibHarvensAddonSettings.ST_SECTION,label = "General",}
	local textSection = {type = LibHarvensAddonSettings.ST_SECTION,label = "Text",}
	local positionSection = {type = LibHarvensAddonSettings.ST_SECTION,label = "Position",}
	local bannerSection = {type = LibHarvensAddonSettings.ST_SECTION,label = "Banner Damage Types",}
	
	local changeCounter = 0
	local changeCounter_Banner = 0
	
	local toggle = {
        type = LibHarvensAddonSettings.ST_CHECKBOX, --setting type
        label = "Hide Tracker?", 
        tooltip = "Disables the tracker when set to \"On\"",
        default = PDT.defaults.checked,
        setFunction = function(state) 
            PDT.savedVariables.checked = state
			PersonalDpsTracker:SetHidden(state)
			
			if state == false then
				PDT.updateText()

				--Hide UI 5 seconds after most recent change. multiple changes can be queued.
				PersonalDpsTracker:SetHidden(false)
				changeCounter = changeCounter + 1
				local changeNum = changeCounter
				zo_callLater(function()
					if changeNum == changeCounter then
						changeCounter = 0
						if SCENE_MANAGER:GetScene("hud"):GetState() == SCENE_HIDDEN or PDT.savedVariables.checked then
							PersonalDpsTracker:SetHidden(true)
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
			PDT.savedVariables.selectedPos = PDT.defaults.selectedPos
			PDT.savedVariables.checked = PDT.defaults.checked
			PDT.savedVariables.offset_x = PDT.defaults.offset_x
			PDT.savedVariables.offset_y = PDT.defaults.offset_y

			PDT.savedVariables.banner_hidden = PDT.defaults.banner_hidden
			PDT.savedVariables.banner_offset_x = PDT.defaults.banner_offset_x
			PDT.savedVariables.banner_offset_y = PDT.defaults.banner_offset_y
			
			PersonalDpsTracker:SetHidden(PDT.savedVariables.checked)
			PersonalDpsTrackerLabel:SetColor(PDT.savedVariables.colorR, PDT.savedVariables.colorG, PDT.savedVariables.colorB)
			PersonalDpsTrackerLabel:SetAlpha(PDT.savedVariables.colorA)
			PersonalDpsTrackerLabel:SetFont(PDT.savedVariables.selectedFont)
			PersonalDpsTracker:ClearAnchors()
			PersonalDpsTracker:SetAnchor(PDT.savedVariables.selectedPos, GuiRoot, PDT.savedVariables.selectedPos, PDT.savedVariables.offset_x, PDT.savedVariables.offset_y)
			
			DMGTypeBreakdown:SetHidden(PDT.savedVariables.banner_hidden)
			DMGTypeBreakdown:ClearAnchors()
			DMGTypeBreakdown:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, PDT.savedVariables.banner_offset_x, PDT.savedVariables.banner_offset_y)
			
			
			PDT.savedVariables.displayText = PDT.defaults.displayText
			PDT.savedVariables.displayText_Boss = PDT.defaults.displayText_Boss
			
			PDT.savedVariables.formatType = PDT.defaults.formatType
			PDT.savedVariables.selectedFormatName = PDT.defaults.selectedFormatName
			PDT.updateText()
			
			--Hide UI 5 seconds after most recent change. multiple changes can be queued.
			PersonalDpsTracker:SetHidden(false)
			changeCounter = changeCounter + 1
			local changeNum = changeCounter
			zo_callLater(function()
				if changeNum == changeCounter then
					changeCounter = 0
					if SCENE_MANAGER:GetScene("hud"):GetState() == SCENE_HIDDEN or PDT.savedVariables.checked then
						PersonalDpsTracker:SetHidden(true)
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
			
			PDT.updateText()
			
			--Hide UI 5 seconds after most recent change. multiple changes can be queued.
			PersonalDpsTracker:SetHidden(false)
			changeCounter = changeCounter + 1
			local changeNum = changeCounter
			zo_callLater(function()
				if changeNum == changeCounter then
					changeCounter = 0
					if SCENE_MANAGER:GetScene("hud"):GetState() == SCENE_HIDDEN or PDT.savedVariables.checked then
						PersonalDpsTracker:SetHidden(true)
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
			
			PDT.updateText()
			
			--Hide UI 5 seconds after most recent change. multiple changes can be queued.
			PersonalDpsTracker:SetHidden(false)
			changeCounter = changeCounter + 1
			local changeNum = changeCounter
			zo_callLater(function()
				if changeNum == changeCounter then
					changeCounter = 0
					if SCENE_MANAGER:GetScene("hud"):GetState() == SCENE_HIDDEN or PDT.savedVariables.checked then
						PersonalDpsTracker:SetHidden(true)
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
			PersonalDpsTracker:SetHidden(false)
			changeCounter = changeCounter + 1
			local changeNum = changeCounter
			zo_callLater(function()
				if changeNum == changeCounter then
					changeCounter = 0
					if SCENE_MANAGER:GetScene("hud"):GetState() == SCENE_HIDDEN or PDT.savedVariables.checked then
						PersonalDpsTracker:SetHidden(true)
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
			PersonalDpsTrackerLabel:SetColor(PDT.savedVariables.colorR, PDT.savedVariables.colorG, PDT.savedVariables.colorB)
			PersonalDpsTrackerLabel:SetAlpha(PDT.savedVariables.colorA)
        
			--Hide UI 5 seconds after most recent change. multiple changes can be queued.
			PersonalDpsTracker:SetHidden(false)
			changeCounter = changeCounter + 1
			local changeNum = changeCounter
			zo_callLater(function()
				if changeNum == changeCounter then
					changeCounter = 0
					if SCENE_MANAGER:GetScene("hud"):GetState() == SCENE_HIDDEN or PDT.savedVariables.checked then
						PersonalDpsTracker:SetHidden(true)
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
			PersonalDpsTrackerLabel:SetFont(item.data)
			PDT.savedVariables.selectedText_font = name
			PDT.savedVariables.selectedFont = item.data
			
			--Hide UI 5 seconds after most recent change. multiple changes can be queued.
			PersonalDpsTracker:SetHidden(false)
			changeCounter = changeCounter + 1
			local changeNum = changeCounter
			zo_callLater(function()
				if changeNum == changeCounter then
					changeCounter = 0
					if SCENE_MANAGER:GetScene("hud"):GetState() == SCENE_HIDDEN or PDT.savedVariables.checked then
						PersonalDpsTracker:SetHidden(true)
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
	
	PDT.currentlyChangingPosition = false
	local repositionUI = {
		type = LibHarvensAddonSettings.ST_CHECKBOX,
		label = "Joystick Reposition",
		tooltip = "When enabled, you will be able to freely move around the UI with your right joystick.\n\nSet this to OFF after configuring position.",
		getFunction = function() return PDT.currentlyChangingPosition end,
		setFunction = function(value) 
			PDT.currentlyChangingPosition = value
			if value == true then
				PersonalDpsTracker:SetHidden(false)
				EVENT_MANAGER:RegisterForUpdate(PDT.name.."AdjustUI", 10,  function() 
					if PDT.savedVariables.selectedPos ~= 3 then PDT.savedVariables.selectedPos = 3 end
					local posX, posY = GetGamepadRightStickX(true), GetGamepadRightStickY(true)
					if posX ~= 0 or posY ~= 0 then 
						PDT.savedVariables.offset_x = PDT.savedVariables.offset_x + 10*posX
						PDT.savedVariables.offset_y = PDT.savedVariables.offset_y - 10*posY

						if PDT.savedVariables.offset_x < 0 then PDT.savedVariables.offset_x = 0 end
						if PDT.savedVariables.offset_y < 0 then PDT.savedVariables.offset_y = 0 end
						if PDT.savedVariables.offset_x > (GuiRoot:GetWidth() - 20) then PDT.savedVariables.offset_x = (GuiRoot:GetWidth() - 20) end
						if PDT.savedVariables.offset_y >(GuiRoot:GetHeight() - 20) then PDT.savedVariables.offset_y = (GuiRoot:GetHeight() - 20) end

						PersonalDpsTracker:ClearAnchors()
						PersonalDpsTracker:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, PDT.savedVariables.offset_x, PDT.savedVariables.offset_y)
					end 
				end)
			else
				EVENT_MANAGER:UnregisterForUpdate(PDT.name.."AdjustUI")
				--Hide UI 5 seconds after most recent change. multiple changes can be queued.
				PersonalDpsTracker:SetHidden(false)
				changeCounter = changeCounter + 1
				local changeNum = changeCounter
				zo_callLater(function()
					if changeNum == changeCounter then
						changeCounter = 0
						if SCENE_MANAGER:GetScene("hud"):GetState() == SCENE_HIDDEN or PDT.savedVariables.checked then
							PersonalDpsTracker:SetHidden(true)
						end
					end
				end, 5000)
			end
		end,
		default = PDT.currentlyChangingPosition
	}

	--x position offset
	local slider_x = {
        type = LibHarvensAddonSettings.ST_SLIDER,
        label = "X Offset",
        tooltip = "",
        setFunction = function(value)
			PDT.savedVariables.offset_x = value
			if PDT.savedVariables.selectedPos ~= 3 then PDT.savedVariables.selectedPos = 3 end
			
			PersonalDpsTracker:ClearAnchors()
			PersonalDpsTracker:SetAnchor(PDT.savedVariables.selectedPos, GuiRoot, PDT.savedVariables.selectedPos, PDT.savedVariables.offset_x, PDT.savedVariables.offset_y)
			
			--Hide UI 5 seconds after most recent change. multiple changes can be queued.
			PersonalDpsTracker:SetHidden(false)
			changeCounter = changeCounter + 1
			local changeNum = changeCounter
			zo_callLater(function()
				if changeNum == changeCounter then
					changeCounter = 0
					if SCENE_MANAGER:GetScene("hud"):GetState() == SCENE_HIDDEN or PDT.savedVariables.checked then
						PersonalDpsTracker:SetHidden(true)
					end
				end
			end, 5000)
		end,
        getFunction = function()
            return PDT.savedVariables.offset_x
        end,
        default = 0,
        min = 0,
        max = GuiRoot:GetWidth(),
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
			if PDT.savedVariables.selectedPos ~= 3 then PDT.savedVariables.selectedPos = 3 end
			
			PersonalDpsTracker:ClearAnchors()
			PersonalDpsTracker:SetAnchor(PDT.savedVariables.selectedPos, GuiRoot, PDT.savedVariables.selectedPos, PDT.savedVariables.offset_x, PDT.savedVariables.offset_y)
			
			--Hide UI 5 seconds after most recent change. multiple changes can be queued.
			PersonalDpsTracker:SetHidden(false)
			changeCounter = changeCounter + 1
			local changeNum = changeCounter
			zo_callLater(function()
				if changeNum == changeCounter then
					changeCounter = 0
					if SCENE_MANAGER:GetScene("hud"):GetState() == SCENE_HIDDEN or PDT.savedVariables.checked then
						PersonalDpsTracker:SetHidden(true)
					end
				end
			end, 5000)
		end,
        getFunction = function()
            return PDT.savedVariables.offset_y
        end,
        default = 0,
        min = 0,
        max = GuiRoot:GetHeight(),
        step = 5,
        unit = "", --optional unit
        format = "%d", --value format
        disable = function() return areSettingsDisabled end,
    }

	local toggle_dmgTypes = {
        type = LibHarvensAddonSettings.ST_CHECKBOX, --setting type
        label = "Hide Damage Type Breakdown?",
        tooltip = "Disables the damagetype breakdown for banner focus scripts when set to \"On\"\n\n"..
			"Note: When two percentages are visible, the leftmost one is for boss damage and the rightmost one is for overal damage.",
        default = PDT.defaults.banner_hidden,
        setFunction = function(state) 
            PDT.savedVariables.banner_hidden = state
			DMGTypeBreakdown:SetHidden(state)
			
			if state == false then
				PDT.updateBannerText()

				--Hide UI 5 seconds after most recent change. multiple changes can be queued.
				DMGTypeBreakdown:SetHidden(false)
				changeCounter_Banner = changeCounter_Banner + 1
				local changeNum = changeCounter_Banner
				zo_callLater(function()
					if changeNum == changeCounter_Banner then
						changeCounter_Banner = 0
						if SCENE_MANAGER:GetScene("hud"):GetState() == SCENE_HIDDEN or PDT.savedVariables.banner_hidden then
							DMGTypeBreakdown:SetHidden(true)
						end
					end
				end, 5000)
			end
        end,
        getFunction = function() 
            return PDT.savedVariables.banner_hidden
        end,
        disable = function() return areSettingsDisabled end,
    }

	PDT.currentlyChangingBannerPosition = false
	local dmgTypes_reposition = {
		type = LibHarvensAddonSettings.ST_CHECKBOX,
		label = "Joystick Reposition",
		tooltip = "When enabled, you will be able to freely move around the UI with your right joystick.\n\nSet this to OFF after configuring position.",
		getFunction = function() return PDT.currentlyChangingBannerPosition end,
		setFunction = function(value) 
			PDT.currentlyChangingBannerPosition = value
			if value == true then
				DMGTypeBreakdown:SetHidden(false)
				EVENT_MANAGER:RegisterForUpdate(PDT.name.."AdjustDMGTypeUI", 10,  function() 
					local posX, posY = GetGamepadRightStickX(true), GetGamepadRightStickY(true)
					if posX ~= 0 or posY ~= 0 then 
						PDT.savedVariables.banner_offset_x = PDT.savedVariables.banner_offset_x + 10*posX
						PDT.savedVariables.banner_offset_y = PDT.savedVariables.banner_offset_y - 10*posY

						if PDT.savedVariables.banner_offset_x < 0 then PDT.savedVariables.banner_offset_x = 0 end
						if PDT.savedVariables.banner_offset_y < 0 then PDT.savedVariables.banner_offset_y = 0 end
						if PDT.savedVariables.banner_offset_x > (GuiRoot:GetWidth() - 20) then PDT.savedVariables.banner_offset_x = (GuiRoot:GetWidth() - 20) end
						if PDT.savedVariables.banner_offset_y >(GuiRoot:GetHeight() - 20) then PDT.savedVariables.banner_offset_y = (GuiRoot:GetHeight() - 20) end

						DMGTypeBreakdown:ClearAnchors()
						DMGTypeBreakdown:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, PDT.savedVariables.banner_offset_x, PDT.savedVariables.banner_offset_y)
					end 
				end)
			else
				EVENT_MANAGER:UnregisterForUpdate(PDT.name.."AdjustDMGTypeUI")
				--Hide UI 5 seconds after most recent change. multiple changes can be queued.
				DMGTypeBreakdown:SetHidden(false)
				changeCounter_Banner = changeCounter_Banner + 1
				local changeNum = changeCounter_Banner
				zo_callLater(function()
					if changeNum == changeCounter_Banner then
						changeCounter_Banner = 0
						if SCENE_MANAGER:GetScene("hud"):GetState() == SCENE_HIDDEN or PDT.savedVariables.checked then
							DMGTypeBreakdown:SetHidden(true)
						end
					end
				end, 5000)
			end
		end,
		default = PDT.currentlyChangingBannerPosition
	}

	local dmgTypes_x_offset = {
		type = LibHarvensAddonSettings.ST_SLIDER,
        label = "X Offset",
        tooltip = "",
        setFunction = function(value)
			PDT.savedVariables.banner_offset_x = value
			
			DMGTypeBreakdown:ClearAnchors()
			DMGTypeBreakdown:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, PDT.savedVariables.banner_offset_x, PDT.savedVariables.banner_offset_y)
			
			--Hide UI 5 seconds after most recent change. multiple changes can be queued.
			DMGTypeBreakdown:SetHidden(false)
			changeCounter_Banner = changeCounter_Banner + 1
			local changeNum = changeCounter_Banner
			zo_callLater(function()
				if changeNum == changeCounter_Banner then
					changeCounter_Banner = 0
					if SCENE_MANAGER:GetScene("hud"):GetState() == SCENE_HIDDEN or PDT.savedVariables.banner_hidden then
						DMGTypeBreakdown:SetHidden(true)
					end
				end
			end, 5000)
		end,
        getFunction = function()
            return PDT.savedVariables.banner_offset_x
        end,
        default = 0,
        min = 0,
        max = GuiRoot:GetWidth(),
        step = 5,
        unit = "", --optional unit
        format = "%d", --value format
        disable = function() return areSettingsDisabled end,
	}

	local dmgTypes_y_offset = {
		type = LibHarvensAddonSettings.ST_SLIDER,
        label = "Y Offset",
        tooltip = "",
        setFunction = function(value)
			PDT.savedVariables.banner_offset_y = value
			
			DMGTypeBreakdown:ClearAnchors()
			DMGTypeBreakdown:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, PDT.savedVariables.banner_offset_x, PDT.savedVariables.banner_offset_y)
			
			--Hide UI 5 seconds after most recent change. multiple changes can be queued.
			DMGTypeBreakdown:SetHidden(false)
			changeCounter_Banner = changeCounter_Banner + 1
			local changeNum = changeCounter_Banner
			zo_callLater(function()
				if changeNum == changeCounter_Banner then
					changeCounter_Banner = 0
					if SCENE_MANAGER:GetScene("hud"):GetState() == SCENE_HIDDEN or PDT.savedVariables.banner_hidden then
						DMGTypeBreakdown:SetHidden(true)
					end
				end
			end, 5000)
		end,
        getFunction = function()
            return PDT.savedVariables.banner_offset_y
        end,
        default = 0,
        min = 0,
        max = GuiRoot:GetHeight(),
        step = 5,
        unit = "", --optional unit
        format = "%d", --value format
        disable = function() return areSettingsDisabled end,
	}

	settings:AddSettings({generalSection, toggle, resetDefaults, 
				textSection, editText, editText_Boss, formatNumber, dropdown_font, color, 
				positionSection, repositionUI, slider_x, slider_y,
				bannerSection, toggle_dmgTypes, dmgTypes_reposition, dmgTypes_x_offset, dmgTypes_y_offset
				})
	
	PDT.onNewBosses(_, _)
	
	PDT.updateText()
	
	EVENT_MANAGER:RegisterForEvent(PDT.name, EVENT_PLAYER_COMBAT_STATE, ChangePlayerCombatState)
	EVENT_MANAGER:RegisterForEvent(PDT.name, EVENT_COMBAT_EVENT, OnCombatEvent)
	EVENT_MANAGER:RegisterForEvent(PDT.name, EVENT_BOSSES_CHANGED, PDT.onNewBosses)
	EVENT_MANAGER:RegisterForEvent(PDT.name, EVENT_PLAYER_ALIVE, onRevive)
end

function PDT.OnAddOnLoaded(event, addonName)
	if addonName == PDT.name then
		PDT.Initialize()
		EVENT_MANAGER:UnregisterForEvent(PDT.name, EVENT_ADD_ON_LOADED)
	end
end

EVENT_MANAGER:RegisterForEvent(PDT.name, EVENT_ADD_ON_LOADED, PDT.OnAddOnLoaded)