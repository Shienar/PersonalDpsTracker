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

--See https://github.com/Shienar/AreaDamage for more documentation.
local areaIDs = {

	-- CATEGORY: Item Set>Arena>Maelstrom Arena
	[71646] = true,			-- Winterborn | Last Checked: U47

	-- CATEGORY: Item Set>Arena>Vateshran Hollows
	[147694] = true,		-- Explosive Rebuke | Last Checked: U47

	-- CATEGORY: Item Set>Craftable
	[34502] = true,			-- Ashen Grip | Last Checked: U47
	[163293] = true,		-- Deadlands Demolisher | Last Checked: U47

	-- CATEGORY: Item Set>DLC Dungeon>Bedlam Veil
	[214756] = true,		-- Reflected Fury | Last Checked: U47
	[214520] = true,		-- Tarnished Nightmare | Last Checked: U47

	-- CATEGORY: Item Set>DLC Dungeon>Bloodroot Forge
	[97574] = true,			-- Flame Blossom | Last Checked: U47

	-- CATEGORY: Item Set>DLC Dungeon>Castle Thorn
	[141642] = true,		-- Crimson Twilight | Last Checked: U47

	-- CATEGORY: Item Set>DLC Dungeon>Coral Aerie
	[167115] = true,		-- Glacial Guardian | Last Checked: U47

	-- CATEGORY: Item Set>DLC Dungeon>Cradle of Shadows
	[84355] = true,			-- Hand of Mephala | Last Checked: U47

	-- CATEGORY: Item Set>DLC Dungeon>Depths of Malatar
	[116920] = true,		-- Auroran's Thunder | Last Checked: U47

	-- CATEGORY: Item Set>DLC Dungeon>Dread Cellar
	[159275] = true,		-- Rush of Agony | Last Checked: U47

	-- CATEGORY: Item Set>DLC Dungeon>Exiled Redoubt
	[235745] = true,		-- Jerensi's Bladestorm (Delayed) | Last Checked: U47
	[236163] = true,		-- Jerensi's Bladestorm (Initial) | Last Checked: U47
	[235836] = true,		-- Vandorallen's Resonance | Last Checked: U47

	-- CATEGORY: Item Set>DLC Dungeon>Falkreath Hold
	[97716] = true,			-- Pillar of Nirn (Initial hit only) | Last Checked: U47

	-- CATEGORY: Item Set>DLC Dungeon>Oathsworn Pit
	[214889] = true,		-- Cinders of Anthelmir | Last Checked: U47

	-- CATEGORY: Item Set>DLC Dungeon>Red Petal Bastion
	[159253] = true,		-- Thunder Caller | Last Checked: U47

	-- CATEGORY: Item Set>DLC Dungeon>Shipwright's Regret
	[167062] = true,		-- Turning Tide | Last Checked: U47

	-- CATEGORY: Item Set>DLC Dungeon>Unhallowed Grave
	[133494] = true,		-- Aegis Caller | Last Checked: U47

	-- CATEGORY: Item Set>DLC Dungeon (Monster)>Castle Thorn
	[142305] = true,		-- Lady Thorn | Last Checked: U47

	-- CATEGORY: Item Set>DLC Dungeon (Monster)>Coral Aerie
	[167048] = true,		-- Kargaeda's Storm (Kargaeda) | Last Checked: U47
	[167607] = true,		-- Kargaeda's Wind (Kargaeda) | Last Checked: U47

	-- CATEGORY: Item Set>DLC Dungeon (Monster)>Earthen Root Enclave
	[176816] = true,		-- Archdruid Devyric | Last Checked: U47

	-- CATEGORY: Item Set>DLC Dungeon (Monster)>Fang Lair
	[102094] = true,		-- Thurvokun | Last Checked: U47

	-- CATEGORY: Item Set>DLC Dungeon (Monster)>Graven Deep
	[175349] = true,		-- Euphotic Gatekeeper | Last Checked: U47

	-- CATEGORY: Item Set>DLC Dungeon (Monster)>Lair of Maarselok
	[126941] = true,		-- Maarselok | Last Checked: U47

	-- CATEGORY: Item Set>DLC Dungeon (Monster)>Lep Seclusa
	[236655] = true,		-- Orpheon the Tactician (Stunned) | Last Checked: U47
	[236789] = true,		-- Orpheon the Tactician (Immune to Stun) | Last Checked: U47

	-- CATEGORY: Item Set>DLC Dungeon (Monster)>Naj-Caldeesh
	[248631] = true,		-- Bar-Sakka | Last Checked: U47

	-- CATEGORY: Item Set>DLC Dungeon (Monster)>Red Petal Bastion
	[159516] = true,		-- Prior Thierric | Last Checked: U47

	-- CATEGORY: Item Set>DLC Dungeon (Monster)>Scalecaller Peak
	[102136] = true,		-- Z'aans | Last Checked: U47

	-- CATEGORY: Item Set>Dungeon>City of Ash I/II
	[59696] = true,			-- Embershield | Last Checked: U47

	-- CATEGORY: Item Set>Dungeon>Direfrost Keep
	[34404] = true,			-- Frostfire (The Ice Furnace) | Last Checked: U47

	-- CATEGORY: Item Set>Dungeon>Tempest Island
	[67136] = true,			-- Overwhelming Surge | Last Checked: U47

	-- CATEGORY: Item Set>Dungeon (Monster)>Arx Corinium
	[80544] = true,			-- Sellistrix (Spawn of Mephala) | Last Checked: U47

	-- CATEGORY: Item Set>Dungeon (Monster)>City of Ash I
	[83409] = true,			-- Infernal Guardian | Last Checked: U47

	-- CATEGORY: Item Set>Dungeon (Monster)>City of Ash II
	[61273] = true,			-- Valkyn Skoria (All other enemies in 5 meters) | Last Checked: U47

	-- CATEGORY: Item Set>Dungeon (Monster)>Crypt of Hearts I
	[80526] = true,			-- Ilambris | Last Checked: U47

	-- CATEGORY: Item Set>Dungeon (Monster)>Crypt of Hearts II
	[59593] = true,			-- Nerieneth | Last Checked: U47

	-- CATEGORY: Item Set>Dungeon (Monster)>Direfrost Keep
	[80561] = true,			-- Iceheart | Last Checked: U47

	-- CATEGORY: Item Set>Dungeon (Monster)>Fungal Grotto I
	[80565] = true,			-- Kragh | Last Checked: U47

	-- CATEGORY: Item Set>Dungeon (Monster)>Tempest Island
	[80521] = true,			-- Stormfist (Final Hit) | Last Checked: U47
	[80522] = true,			-- Stormfist (First 3s) | Last Checked: U47

	-- CATEGORY: Item Set>Dungeon (Monster)>Vault's of Madness
	[84502] = true,			-- Grothdarr | Last Checked: U47

	-- CATEGORY: Item Set>Dungeon (Monster)>Volenfell
	[80865] = true,			-- Tremorscale | Last Checked: U47

	-- CATEGORY: Item Set>Dungeon (Monster) >Fungal Grotto II
	[59498] = true,			-- Mephala's Web | Last Checked: U47

	-- CATEGORY: Item Set>Imperial City (Monster)
	[167742] = true,		-- Baron Thirsk | Last Checked: U47
	[166788] = true,		-- Lady Malygda (Dmg going out) | Last Checked: U47
	[167962] = true,		-- Lady Malygda (Dmg  coming back) | Last Checked: U47
	[167680] = true,		-- Nunatak | Last Checked: U47

	-- CATEGORY: Item Set>Infinite Archive>Necromancer
	[227072] = true,		-- Corpsebuster | Last Checked: U47

	-- CATEGORY: Item Set>Mythic
	[173734] = true,		-- Dov-Rha Sabatons | Last Checked: U47
	[239711] = true,		-- Mad God's Dancing Shoes (Exploding Cheese Wheel) | Last Checked: U47
	[240131] = true,		-- Mad God's Dancing Shoes (Enemies Facing You) | Last Checked: U47

	-- CATEGORY: Item Set>Overland
	[75692] = true,			-- Bahraha's Curse | Last Checked: U47
	[154347] = true,		-- Deadlands Assassin | Last Checked: U47
	[93307] = true,			-- Defiler | Last Checked: U47
	[243309] = true,		-- Mad Tinkerer | Last Checked: U47
	[57209] = true,			-- Storm Knight's Plate | Last Checked: U47
	[76344] = true,			-- Syvarra's Scales (Only the weak initial tick.) | Last Checked: U47
	[33497] = true,			-- Thunderbugs Carapace | Last Checked: U47
	[71658] = true,			-- Trinimac's Valor | Last Checked: U47
	[137526] = true,		-- Venomous Smite (Only to nearby enemies.) | Last Checked: U47

	-- CATEGORY: Item Set>PvP
	[159386] = true,		-- Dark Convergence (Whole Circle) | Last Checked: U47
	[159387] = true,		-- Dark Convergence (Inner Circle) | Last Checked: U47

	-- CATEGORY: Item Set>Trial>Aetherian Archive
	[50992] = true,			-- Defending Warrior | Last Checked: U47

	-- CATEGORY: Item Set>Trial>Dreadsail Reef
	[172672] = true,		-- Whorl of the Depths (Whirlpool) | Last Checked: U47

	-- CATEGORY: Item Set>Trial>Maw of Lorkhaj
	[75752] = true,			-- Roar of Alkosh (Initial hit only) | Last Checked: U47

	-- CATEGORY: Skill>Class>Arcanist>Herald of the Tome
	[185817] = true,		-- Abyssal Impact | Last Checked: U47
	[183006] = true,		-- Cephaliarc's Flail | Last Checked: U47
	[183123] = true,		-- Exhausting Fatecarver | Last Checked: U47
	[185808] = true,		-- Fatecarver | Last Checked: U47
	[185407] = true,		-- Fulminating Rune (6 second Detonation) | Last Checked: U47
	[186370] = true,		-- Pragmatic Fatecarver | Last Checked: U47
	[191078] = true,		-- Runebreak (The Imperfect Ring Synergy) | Last Checked: U47
	[185823] = true,		-- Tentacular Dread | Last Checked: U47
	[189869] = true,		-- The Languid Eye | Last Checked: U47
	[189793] = true,		-- The Unblinking Eye | Last Checked: U47

	-- CATEGORY: Skill>Class>Arcanist>Soldier of Apocrypha
	[183678] = true,		-- Gibbering Shield (Difficult to test.) | Last Checked: U47
	[193275] = true,		-- Sanctum of the Abyssal Sea (Difficult to test.) | Last Checked: U47

	-- CATEGORY: Skill>Class>Dragonknight>Ardent Flame
	[28995] = true,			-- Dragonknight Standard | Last Checked: U47
	[20930] = true,			-- Engulfing Flames (Initial Conal Hit) | Last Checked: U47
	[20917] = true,			-- Fiery Breath (Initial Conal Hit) | Last Checked: U47
	[20944] = true,			-- Noxious Breath (Initial Conal Hit) | Last Checked: U47
	[32960] = true,			-- Shifting Standard | Last Checked: U47
	[32948] = true,			-- Standard of Might | Last Checked: U47

	-- CATEGORY: Skill>Class>Dragonknight>Draconic Power
	[20252] = true,			-- Burning Talons (Initial Hit) | Last Checked: U47
	[20251] = true,			-- Choking Talons | Last Checked: U47
	[20245] = true,			-- Dark Talons | Last Checked: U47
	[32792] = true,			-- Deep Breath (Initial Hit) | Last Checked: U47
	[32794] = true,			-- Deep Breath (Delayed Hit) | Last Checked: U47
	[29014] = true,			-- Dragon Leap | Last Checked: U47
	[32785] = true,			-- Draw Essence (Initial Hit) | Last Checked: U47
	[32787] = true,			-- Draw Essence (Delayed Hit) | Last Checked: U47
	[32716] = true,			-- Ferocious Leap | Last Checked: U47
	[31837] = true,			-- Inhale (Initial Hit) | Last Checked: U47
	[31842] = true,			-- Inhale (Delayed Hit) | Last Checked: U47
	[32720] = true,			-- Take Flight | Last Checked: U47

	-- CATEGORY: Skill>Class>Dragonknight>Earthen Heart
	[17979] = true,			-- Corrosive Armor (DMG to Nearby Enemies) | Last Checked: U47
	[32711] = true,			-- Eruption (DOT) | Last Checked: U47
	[32714] = true,			-- Eruption (Initial Hit) | Last Checked: U47
	[15959] = true,			-- Magma Armor (DMG to Nearby Enemies) | Last Checked: U47
	[17875] = true,			-- Magma Shell (DMG to Nearby Enemies) | Last Checked: U47
	[134340] = true,		-- Stone Giant (Initial Hit) | Last Checked: U47
	[134310] = true,		-- Stonefist (Initial Hit) | Last Checked: U47

	-- CATEGORY: Skill>Class>Necromancer>Bone Tyrant
	[115115] = true,		-- Death Scythe | Last Checked: U47
	[118314] = true,		-- Ghostly Embrace (First Circle On-Hit) | Last Checked: U47
	[143944] = true,		-- Ghostly Embrace (Second Circle On-Hit) | Last Checked: U47
	[143946] = true,		-- Ghostly Embrace (Third Circle On-hit) | Last Checked: U47
	[118223] = true,		-- Hungry Scythe | Last Checked: U47
	[118720] = true,		-- Pummeling Goliath | Last Checked: U47
	[118618] = true,		-- Pure Agony (Agony Totem Synergy) | Last Checked: U47
	[118289] = true,		-- Ravenous Goliath | Last Checked: U47
	[118266] = true,		-- Ruinous Scythe | Last Checked: U47

	-- CATEGORY: Skill>Class>Necromancer>Grave Lord
	[117854] = true,		-- Avid Boneyard | Last Checked: U47
	[117715] = true,		-- Blighted Skeletal Detonation | Last Checked: U47
	[115254] = true,		-- Boneyard | Last Checked: U47
	[124468] = true,		-- Deathbolt (Skeletal Arcanist AOE Dmg) | Last Checked: U47
	[118766] = true,		-- Detonating Siphon (DOT) | Last Checked: U47
	[123082] = true,		-- Detonating Siphon (Terminatiing Explosion) | Last Checked: U47
	[122178] = true,		-- Frozen Colossus (Hits 1-3) | Last Checked: U47
	[122392] = true,		-- Glacial Colossus (Hits 1-3) | Last Checked: U47
	[220098] = true,		-- Grave Lord's Sacrifice ("Buffed 3rd skull hit base morph.") | Last Checked: U47
	[220101] = true,		-- Grave Lord's Sacrifice (Buffed 3rd venom skull hit.) | Last Checked: U47
	[220104] = true,		-- Grave Lord's Sacrifice (Buffed 3rd ricochet skull hit.) | Last Checked: U47
	[115572] = true,		-- Grave Robber (Boneyard Synergy) | Last Checked: U47
	[118011] = true,		-- Mystic Siphon | Last Checked: U47
	[122399] = true,		-- Pestilent Colossus (Hit 1) | Last Checked: U47
	[122400] = true,		-- Pestilent Colossus (Hit 2) | Last Checked: U47
	[122401] = true,		-- Pestilent Colossus (Hit 3) | Last Checked: U47
	[116410] = true,		-- Shocking Siphon | Last Checked: U47
	[117809] = true,		-- Unnerving Boneyard | Last Checked: U47

	-- CATEGORY: Skill>Class>Nightblade>Assassination
	[25494] = true,			-- Lotus Fan (Initial Hit) | Last Checked: U47

	-- CATEGORY: Skill>Class>Nightblade>Shadow
	[108936] = true,		-- Corrossive Drain (From Dark Shade Skill) | Last Checked: U47
	[36052] = true,			-- Twisting Path | Last Checked: U47
	[36490] = true,			-- Veil of Blades | Last Checked: U47

	-- CATEGORY: Skill>Class>Nightblade>Siphoning
	[33316] = true,			-- Drain Power | Last Checked: U47
	[36901] = true,			-- Power Extraction | Last Checked: U47
	[36891] = true,			-- Sap Essence | Last Checked: U47
	[25091] = true,			-- Soul Shred (Initial Hit) | Last Checked: U47
	[35460] = true,			-- Soul Tether (Initial Hit) | Last Checked: U47

	-- CATEGORY: Skill>Class>Sorcerer>Daedric Summoning
	[24329] = true,			-- Daedric Prey | Last Checked: U47
	[29809] = true,			-- Atronach Lightning Strike (Every 2s - Charged Atronach) | Last Checked: U47
	[23667] = true,			-- Summon Charged Atronach (Initial Hit) | Last Checked: U47
	[24327] = true,			-- Daedric Curse | Last Checked: U47
	[23664] = true,			-- Greater Storm Atronach (Initial Hit) | Last Checked: U47
	[24331] = true,			-- Haunting Curse (Same ID for both ticks.) | Last Checked: U47
	[23659] = true,			-- Summon Storm Atronach (Initial Hit) | Last Checked: U47
	[29529] = true,			-- Summon Unstable Clannfear (Tailswipe) | Last Checked: U47
	[108844] = true,		-- Summon Unstable Familiar (Every 2s) | Last Checked: U47
	[77186] = true,			-- Summon Volatile Familiar (Every 2s) | Last Checked: U47

	-- CATEGORY: Skill>Class>Sorcerer>Dark Magic
	[28309] = true,			-- Shattering Spines | Last Checked: U47
	[80435] = true,			-- Suppression Field | Last Checked: U47

	-- CATEGORY: Skill>Class>Sorcerer>Storm Calling
	[23214] = true,			-- Boundless Storm | Last Checked: U47
	[44491] = true,			-- Endless Fury (Only to other enemies nearby) | Last Checked: U47
	[114798] = true,		-- Energy Overload (Heavy Attacks) | Last Checked: U47
	[23232] = true,			-- Hurricane | Last Checked: U47
	[23208] = true,			-- Lightning Flood | Last Checked: U47
	[23211] = true,			-- Lightning Form | Last Checked: U47
	[23189] = true,			-- Lightning Splash | Last Checked: U47
	[23202] = true,			-- Liquid Lightning | Last Checked: U47
	[44483] = true,			-- Mage's Fury (Only to other enemies nearby) | Last Checked: U47
	[19128] = true,			-- Mage's Wrath (20% Explosion) | Last Checked: U47
	[24798] = true,			-- Overload (Heavy Attacks) | Last Checked: U47
	[7102] = true,			-- Power Overload (Heavy Attacks) | Last Checked: U47
	[23239] = true,			-- Streak | Last Checked: U47

	-- CATEGORY: Skill>Class>Templar>Aedric Spear
	[44432] = true,			-- Biting Jabs | Last Checked: U47
	[22181] = true,			-- Blazing Shield (Max reflected damage increases.) | Last Checked: U47
	[26871] = true,			-- Blazing Spear (Initial Hit) | Last Checked: U47
	[26879] = true,			-- Blazing Spear (DOT) | Last Checked: U47
	[22139] = true,			-- Crescent Sweep (Initial Hit) | Last Checked: U47
	[62606] = true,			-- Crescent Sweep (Every 2s) | Last Checked: U47
	[22144] = true,			-- Everlasting Sweep (Initial Hit) | Last Checked: U47
	[62598] = true,			-- Everlasting Sweep (Every 2s) | Last Checked: U47
	[22165] = true,			-- Explosive Charge | Last Checked: U47
	[26859] = true,			-- Luminous Shards (Initial Hit) | Last Checked: U47
	[95955] = true,			-- Luminous Shards (DOT) | Last Checked: U47
	[44426] = true,			-- Puncturing Strikes | Last Checked: U47
	[44436] = true,			-- Puncturing Sweep | Last Checked: U47
	[22138] = true,			-- Radial Sweep (Initial Hit) | Last Checked: U47
	[62550] = true,			-- Radial Sweep (Every 2s) | Last Checked: U47
	[22182] = true,			-- Radiant Ward (Initial Hit) | Last Checked: U47
	[26192] = true,			-- Spear Shards (Initial Hit) | Last Checked: U47
	[95931] = true,			-- Spear Shards (DOT) | Last Checked: U47
	[22178] = true,			-- Sun Shield (Initial Hit) | Last Checked: U47

	-- CATEGORY: Skill>Class>Templar>Dawn's Wrath
	[31604] = true,			-- Gravity Crush (Solar Prison synergy) | Last Checked: U47
	[21753] = true,			-- Nova (Caster DOT) | Last Checked: U47
	[21732] = true,			-- Reflective Light (Only the initial hit.) | Last Checked: U47
	[100218] = true,		-- Solar Barrage (Every 2s) | Last Checked: U47
	[21759] = true,			-- Solar Distrubance (Caster DOT) | Last Checked: U47
	[21756] = true,			-- Solar Prison (Caster DOT) | Last Checked: U47
	[31540] = true,			-- Supernova (Nova synergy) | Last Checked: U47
	[127791] = true,		-- Unstable Core (First Hit) | Last Checked: U47
	[127792] = true,		-- Unstable Core (Second Hit) | Last Checked: U47
	[127793] = true,		-- Unstable Core (Third Hit) | Last Checked: U47

	-- CATEGORY: Skill>Class>Templar>Restoring Light
	[80172] = true,			-- Ritual of Retribution | Last Checked: U47

	-- CATEGORY: Skill>Class>Warden>Animal Companions
	[89128] = true,			-- Crushing Swipe (Feral Guardian attack) | Last Checked: U47
	[89220] = true,			-- Crushing Swipe (Wild Guardian attack) | Last Checked: U47
	[105907] = true,		-- Crushing Swipe (Eternal Guardian attack) | Last Checked: U47
	[94424] = true,			-- Deep Fissure (1st hit) | Last Checked: U47
	[181331] = true,		-- Deep Fissure (2nd hit) | Last Checked: U47
	[130170] = true,		-- Growing Swarm (Every 2s to nearby enemies) | Last Checked: U47
	[94411] = true,			-- Scorch (1st hit) | Last Checked: U47
	[181330] = true,		-- Scorch (2nd hit) | Last Checked: U47
	[94445] = true,			-- Subterranean Assault (1st & 2nd hit.) | Last Checked: U47

	-- CATEGORY: Skill>Class>Warden>Winter's Embrace
	[86156] = true,			-- Arctic Blast (Initial Hit) | Last Checked: U47
	[130406] = true,		-- Arctic Blast (Every 2s to enemies hit.) | Last Checked: U47
	[88791] = true,			-- Gripping Shards | Last Checked: U47
	[88783] = true,			-- Impaing Shards | Last Checked: U47
	[88860] = true,			-- Northern Storm | Last Checked: U47
	[88863] = true,			-- Permafrost | Last Checked: U47
	[86247] = true,			-- Sleet Storm | Last Checked: U47
	[88802] = true,			-- Winter's Revenge | Last Checked: U47

	-- CATEGORY: Skill>Guild>Fighters Guild
	[35713] = true,			-- Dawnbreaker (Initial Hit) | Last Checked: U47
	[40158] = true,			-- Dawnbreaker of Smiting (Initial Hit) | Last Checked: U47
	[40161] = true,			-- Flawless Dawnbreaker (Initial Hit) | Last Checked: U47
	[40300] = true,			-- Silver Shards (All 3 bolts are affected.) | Last Checked: U47

	-- CATEGORY: Skill>Guild>Mages Guild
	[63454] = true,			-- Ice Comet (DOT) | Last Checked: U47
	[63457] = true,			-- Ice Comet  (Initial hit) | Last Checked: U47
	[63429] = true,			-- Meteor (DOT) | Last Checked: U47
	[172912] = true,		-- Meteor (Initial hit) | Last Checked: U47
	[40469] = true,			-- Scalding Rune (Initial Hit Only) | Last Checked: U47
	[63471] = true,			-- Shooting Star (DOT) | Last Checked: U47
	[63474] = true,			-- Shooting Star (Initial hit) | Last Checked: U47
	[40473] = true,			-- Volcanic Rune | Last Checked: U47

	-- CATEGORY: Skill>Guild>Undaunted
	[85432] = true,			-- Combustion (Damage from Orb Synergy.) | Last Checked: U47
	[42029] = true,			-- Mystic Orb | Last Checked: U47
	[39299] = true,			-- Necrotic Orb | Last Checked: U47
	[126720] = true,		-- Shadow Silk (Initial hit) | Last Checked: U47
	[80107] = true,			-- Shadow Sillk (After 10s) | Last Checked: U47
	[80129] = true,			-- Tangling Webs (After 10s) | Last Checked: U47
	[126722] = true,		-- Tangling Webs (Initial hit) | Last Checked: U47
	[80083] = true,			-- Trapping Webs (After 10s) | Last Checked: U47
	[126718] = true,		-- Trapping Webs (Initial Hit) | Last Checked: U47

	-- CATEGORY: Skill>PvP>Assault
	[40267] = true,			-- Anti-Cavalry Caltrops | Last Checked: U47
	[38561] = true,			-- Caltrops | Last Checked: U47
	[61493] = true,			-- Inevitable Detonation | Last Checked: U47
	[61488] = true,			-- Magicka Detonation | Last Checked: U47
	[61502] = true,			-- Proximity Detonation | Last Checked: U47
	[40252] = true,			-- Razor Caltrops | Last Checked: U47

	-- CATEGORY: Skill>Scribing
	[217231] = true,		-- Elemental Explosion (Initial Hit) | Last Checked: U47
	[217178] = true,		-- Smash (Initial Hit) | Last Checked: U47
	[217459] = true,		-- Soul Burst (Initial Hit) | Last Checked: U47
	[217632] = true,		-- Torch (Initial hit) | Last Checked: U47
	[217679] = true,		-- Trample (Initial Hit) | Last Checked: U47
	[217348] = true,		-- Traveling Knife (Multi-Target Script) | Last Checked: U47
	[217359] = true,		-- Traveling Knife (Between You and Them) | Last Checked: U47
	[229656] = true,		-- Ulfsild's Contingency (Initial Hit) | Last Checked: U47
	[214960] = true,		-- Vault | Last Checked: U47

	-- CATEGORY: Skill>Weapon>Bow
	[38724] = true,			-- Acid Spray (Initial Hit Only) | Last Checked: U47
	[38696] = true,			-- Arrow Barrage | Last Checked: U47
	[38722] = true,			-- Arrow Spray | Last Checked: U47
	[38723] = true,			-- Bombard | Last Checked: U47
	[38690] = true,			-- Endless Hail | Last Checked: U47
	[28877] = true,			-- Volley | Last Checked: U47

	-- CATEGORY: Skill>Weapon>Destruction Staff
	[62912] = true,			-- Blockade of Fire | Last Checked: U47
	[62951] = true,			-- Blockade of Frost | Last Checked: U47
	[62990] = true,			-- Blockade of Storms | Last Checked: U47
	[83683] = true,			-- Eye of Flame | Last Checked: U47
	[83685] = true,			-- Eye of Frost | Last Checked: U47
	[83687] = true,			-- Eye of Lightning | Last Checked: U47
	[85127] = true,			-- Fiery Rage | Last Checked: U47
	[28794] = true,			-- Fire Impulse | Last Checked: U47
	[39149] = true,			-- Fire Ring | Last Checked: U47
	[83626] = true,			-- Fire Storm | Last Checked: U47
	[170989] = true,		-- Flame Pulsar | Last Checked: U47
	[28798] = true,			-- Frost Impulse | Last Checked: U47
	[170990] = true,		-- Frost Pulsar | Last Checked: U47
	[39151] = true,			-- Frost Ring | Last Checked: U47
	[83629] = true,			-- Ice Storm | Last Checked: U47
	[85129] = true,			-- Icy Rage | Last Checked: U47
	[146553] = true,		-- Shock Impulse | Last Checked: U47
	[39153] = true,			-- Shock Ring | Last Checked: U47
	[146593] = true,		-- Storm Pulsar | Last Checked: U47
	[83631] = true,			-- Thunder Storm | Last Checked: U47
	[85131] = true,			-- Thunderous Rage | Last Checked: U47
	[39054] = true,			-- Unstable Wall of Fire (DOT) | Last Checked: U47
	[39056] = true,			-- Unstable Wall of Fire (Explosion) | Last Checked: U47
	[39071] = true,			-- Unstable Wall of Frost (DOT) | Last Checked: U47
	[39072] = true,			-- Unstable Wall of Frost (Explosion) | Last Checked: U47
	[39079] = true,			-- Unstable Wall of Storms (DOT) | Last Checked: U47
	[39080] = true,			-- Unstable Wall of Storms (Explosion) | Last Checked: U47
	[62896] = true,			-- Wall of Fire | Last Checked: U47
	[62931] = true,			-- Wall of Frost | Last Checked: U47
	[62971] = true,			-- Wall of Storms | Last Checked: U47

	-- CATEGORY: Skill>Weapon>Dual Wield
	[62522] = true,			-- Blade Cloak | Last Checked: U47
	[62547] = true,			-- Deadly Cloak | Last Checked: U47
	[62529] = true,			-- Quick Cloak | Last Checked: U47
	[38861] = true,			-- Steel Tornado | Last Checked: U47
	[38891] = true,			-- Whirling Blades | Last Checked: U47
	[28591] = true,			-- Whirlwind | Last Checked: U47

	-- CATEGORY: Skill>Weapon>Two-Handed
	[38754] = true,			-- Brawler | Last Checked: U47
	[38745] = true,			-- Carve (Initial Hit Only) | Last Checked: U47
	[20919] = true,			-- Cleave | Last Checked: U47
	[38823] = true,			-- Reverse Slice | Last Checked: U47
	[38792] = true,			-- Stampede (Initial Hit) | Last Checked: U47
	[126474] = true,		-- Stampede (DOT) | Last Checked: U47

	-- CATEGORY: Skill>World>Soul Magic
	[40416] = true,			-- Shatter Soul (Ending explosion) | Last Checked: U47
	[45584] = true,			-- Soul Shatter (Passive) | Last Checked: U47

	-- CATEGORY: Skill>World>Vampire
	[38968] = true,			-- Blood Mist (Every 2s) | Last Checked: U47
	[38935] = true,			-- Swarming Scion (Bat AOE) | Last Checked: U47

	-- CATEGORY: Skill>World>Werewolf
	[137184] = true,		-- Brutal Carnage (Recast DMG) | Last Checked: U47
	[58864] = true,			-- Claws of Anguish (Initial Hit) | Last Checked: U47
	[58879] = true,			-- Claws of Life (Initial Hit) | Last Checked: U47

}

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
		DMGTypeBreakdownDirect:SetText("Direct: "..math.floor((dmgTypes_Boss.directDMG/TotalDamage_Boss)*100).."%".." ("..math.floor((dmgTypes.directDMG/TotalDamage)*100).."%)")
		DMGTypeBreakdownDOT:SetText("DOT: "..math.floor((dmgTypes_Boss.dotDMG/TotalDamage_Boss)*100).."%".." ("..math.floor((dmgTypes.dotDMG/TotalDamage)*100).."%)")
		DMGTypeBreakdownMartial:SetText("Martial: "..math.floor((dmgTypes_Boss.martialDMG/TotalDamage_Boss)*100).."%".." ("..math.floor((dmgTypes.martialDMG/TotalDamage)*100).."%)")
		DMGTypeBreakdownMagical:SetText("Magic: "..math.floor((dmgTypes_Boss.magicalDMG/TotalDamage_Boss)*100).."%".." ("..math.floor((dmgTypes.magicalDMG/TotalDamage)*100).."%)")
		DMGTypeBreakdownArea:SetText("Area: "..math.floor((dmgTypes_Boss.areaDMG/TotalDamage_Boss)*100).."%".." ("..math.floor((dmgTypes.areaDMG/TotalDamage)*100).."%)")
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
			if areaIDs[abilityID] then
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
				if areaIDs[abilityID] then
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
			if areaIDs[abilityID] then
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
				if areaIDs[abilityID] then
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
	local bannerSection = {type = LibHarvensAddonSettings.ST_SECTION,label = "(BETA) Damage Types",}
	
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
			"Note: When two percentages are visible, the leftmost one is for boss damage and the rightmost one is for overall damage.",
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