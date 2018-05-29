-- AI Research Grid Addon for Elder Scrolls Online
-- Author: Stormknight/LCAmethyst
-- "All" and "Relative"  functionality by His Dad
-- Dwemer Motif by rkuhnjr
-- Dwemer Motif By garkin
-- French Translation by Motsah
-- Fixes by mpavlinsky
-- Close on Esc code by Wandamey
-- Glass, Xivkyn, Ancient Orc, and Mercenary Akaviri added in by Scinutz
-- Code clean & lot of stuff reworked by Ayantir
-- AM - 4 new motifs (Pyandonean, Psijic, Fang Lair and Sapiarch) added by AssemblerManiac
-- AM - Minor code cleanup, single table now holds style buttons
-- AM - styleOrder table implemented to keep style order fixed
--      it was changing between creation of the UI and the updates of the tooltips, causing mismatched icon/tooltip data
-- AM - added Jewelry Crafting tracking


local ADDON_NAME = "AIResearchGrid"
local db

local playerName = GetUnitName("player")
local curCharacter = playerName
local currentCraft = CRAFTING_TYPE_WOODWORKING
local mergedCharacters = "#ALL"
local mergedCharactersData = {}
local showRelative = false
local relative = {}
local maxColumns
local AIRG_UI = {}
local apiVersion

local TRAIT_KNOWN = -1
local TRAIT_UNKNOWN = 0

local AIRG_STYLE_BASIC = 1
local AIRG_STYLE_CHAPTERIZED = 2
local AIRG_STYLE_CROWNSTORE = 3

local BLACKSMITHING_RESEARCH_LEVEL
local CLOTHIER_RESEARCH_LEVEL
local WOODWORKING_RESEARCH_LEVEL
local JEWELRYCRAFTING_RESEARCH_LEVEL

-- Defaults options for saved variables
local defaults = {
	showMotifs = true,
	char = {
		[playerName] = {},
	},
}

-- Index of the line in our grid for a specific trait
local gridTraits = {
	[ITEM_TRAIT_TYPE_WEAPON_POWERED] = 1,
	[ITEM_TRAIT_TYPE_WEAPON_CHARGED] = 2,
	[ITEM_TRAIT_TYPE_WEAPON_PRECISE] = 3,
	[ITEM_TRAIT_TYPE_WEAPON_INFUSED] = 4,
	[ITEM_TRAIT_TYPE_WEAPON_DEFENDING] = 5,
	[ITEM_TRAIT_TYPE_WEAPON_TRAINING] = 6,
	[ITEM_TRAIT_TYPE_WEAPON_SHARPENED] = 7,
	[ITEM_TRAIT_TYPE_WEAPON_DECISIVE] = 8,
	[ITEM_TRAIT_TYPE_WEAPON_NIRNHONED] = 9,
	[ITEM_TRAIT_TYPE_ARMOR_STURDY] = 10,
	[ITEM_TRAIT_TYPE_ARMOR_IMPENETRABLE] = 11,
	[ITEM_TRAIT_TYPE_ARMOR_REINFORCED] = 12,
	[ITEM_TRAIT_TYPE_ARMOR_WELL_FITTED] = 13,
	[ITEM_TRAIT_TYPE_ARMOR_TRAINING] = 14,
	[ITEM_TRAIT_TYPE_ARMOR_INFUSED] = 15,
	[ITEM_TRAIT_TYPE_ARMOR_PROSPEROUS] = 16,
	[ITEM_TRAIT_TYPE_ARMOR_DIVINES] = 17,
	[ITEM_TRAIT_TYPE_ARMOR_NIRNHONED] = 18,
}
local gridTraitsJC = {
	[ITEM_TRAIT_TYPE_JEWELRY_ARCANE] = 1,
	[ITEM_TRAIT_TYPE_JEWELRY_HEALTHY] = 2,
	[ITEM_TRAIT_TYPE_JEWELRY_ROBUST] = 3,
	[ITEM_TRAIT_TYPE_JEWELRY_TRIUNE] = 4,
	[ITEM_TRAIT_TYPE_JEWELRY_INFUSED] = 5,
	[ITEM_TRAIT_TYPE_JEWELRY_PROTECTIVE] = 6,
	[ITEM_TRAIT_TYPE_JEWELRY_SWIFT] = 7,
	[ITEM_TRAIT_TYPE_JEWELRY_HARMONY] = 8,
	[ITEM_TRAIT_TYPE_JEWELRY_BLOODTHIRSTY] = 9,

}

-- Display Order in tooltip
local styleChaptersLookup = {
	[1] = ITEM_STYLE_CHAPTER_AXES,
	[2] = ITEM_STYLE_CHAPTER_BELTS,
	[3] = ITEM_STYLE_CHAPTER_BOOTS,
	[4] = ITEM_STYLE_CHAPTER_BOWS,
	[5] = ITEM_STYLE_CHAPTER_CHESTS,
	[6] = ITEM_STYLE_CHAPTER_DAGGERS,
	[7] = ITEM_STYLE_CHAPTER_GLOVES,
	[8] = ITEM_STYLE_CHAPTER_HELMETS,
	[9] = ITEM_STYLE_CHAPTER_LEGS,
	[10] = ITEM_STYLE_CHAPTER_MACES,
	[11] = ITEM_STYLE_CHAPTER_SHIELDS,
	[12] = ITEM_STYLE_CHAPTER_SHOULDERS,
	[13] = ITEM_STYLE_CHAPTER_STAVES,
	[14] = ITEM_STYLE_CHAPTER_SWORDS,
}

local styles = {
	[ITEMSTYLE_RACIAL_BRETON]  = {stype = AIRG_STYLE_BASIC}, --Breton
	[ITEMSTYLE_RACIAL_REDGUARD]  = {stype = AIRG_STYLE_BASIC}, --Redguard
	[ITEMSTYLE_RACIAL_ORC]  = {stype = AIRG_STYLE_BASIC}, --Orc
	[ITEMSTYLE_RACIAL_DARK_ELF]  = {stype = AIRG_STYLE_BASIC}, --Dark Elf
	[ITEMSTYLE_RACIAL_NORD]  = {stype = AIRG_STYLE_BASIC}, --Nord
	[ITEMSTYLE_RACIAL_ARGONIAN]  = {stype = AIRG_STYLE_BASIC}, --Argonian
	[ITEMSTYLE_RACIAL_HIGH_ELF] =  {stype = AIRG_STYLE_BASIC}, --High Elf
	[ITEMSTYLE_RACIAL_WOOD_ELF]  = {stype = AIRG_STYLE_BASIC}, --Wood Elf
	[ITEMSTYLE_RACIAL_KHAJIIT]  = {stype = AIRG_STYLE_BASIC}, --Khajiit
	[ITEMSTYLE_AREA_ANCIENT_ELF] = {stype = AIRG_STYLE_BASIC}, --Ancient Elf
	[ITEMSTYLE_AREA_REACH] = {stype = AIRG_STYLE_BASIC}, --Reach
	[ITEMSTYLE_ENEMY_PRIMITIVE] = {stype = AIRG_STYLE_BASIC}, --Primitive
	[ITEMSTYLE_ENEMY_DAEDRIC] = {stype = AIRG_STYLE_BASIC}, --Daedric
	[ITEMSTYLE_RACIAL_IMPERIAL] = {stype = AIRG_STYLE_BASIC}, --Imperial
	[ITEMSTYLE_AREA_SOUL_SHRIVEN] = {stype = AIRG_STYLE_BASIC}, --Soul Shriven
	[ITEMSTYLE_AREA_DWEMER] = {stype = AIRG_STYLE_CHAPTERIZED, achiev = 1144}, --Dwemer
	[ITEMSTYLE_GLASS] = {stype = AIRG_STYLE_CHAPTERIZED, achiev = 1319}, --Glass
	[ITEMSTYLE_AREA_XIVKYN] = {stype = AIRG_STYLE_CHAPTERIZED, achiev = 1181}, --Xivkyn
	[ITEMSTYLE_AREA_ANCIENT_ORC] = {stype = AIRG_STYLE_CHAPTERIZED, achiev = 1341}, --Ancient Orc
	[ITEMSTYLE_AREA_AKAVIRI] = {stype = AIRG_STYLE_CHAPTERIZED, achiev = 1318}, --Akaviri
	[ITEMSTYLE_UNDAUNTED] = {stype = AIRG_STYLE_CHAPTERIZED, achiev = 1348}, --Mercenary
	[ITEMSTYLE_DEITY_MALACATH] = {stype = AIRG_STYLE_CHAPTERIZED, achiev = 1412}, --Malacath
	[ITEMSTYLE_DEITY_TRINIMAC] = {stype = AIRG_STYLE_CHAPTERIZED, achiev = 1411}, --Trinimac
	[ITEMSTYLE_ORG_OUTLAW] = {stype = AIRG_STYLE_CHAPTERIZED, achiev = 1417}, --Outlaw
	[ITEMSTYLE_ALLIANCE_EBONHEART] = {stype = AIRG_STYLE_CHAPTERIZED, achiev = 1414}, --Ebonheart
	[ITEMSTYLE_ALLIANCE_ALDMERI] = {stype = AIRG_STYLE_CHAPTERIZED, achiev = 1415}, --Aldmeri
	[ITEMSTYLE_ALLIANCE_DAGGERFALL] = {stype = AIRG_STYLE_CHAPTERIZED, achiev = 1416}, --Daggerfall
	[ITEMSTYLE_ORG_ABAHS_WATCH] = {stype = AIRG_STYLE_CHAPTERIZED, achiev = 1422}, --Abah's Watch
	[ITEMSTYLE_ORG_THIEVES_GUILD] = {stype = AIRG_STYLE_CHAPTERIZED, achiev = 1423}, --ThievesGuild
	[ITEMSTYLE_ORG_ASSASSINS] = {stype = AIRG_STYLE_CHAPTERIZED, achiev = 1424}, --Assassins League
	[ITEMSTYLE_ENEMY_DROMOTHRA] = {stype = AIRG_STYLE_CHAPTERIZED, achiev = 1659}, --DroMathra
	[ITEMSTYLE_DEITY_AKATOSH] = {stype = AIRG_STYLE_CHAPTERIZED, achiev = 1660}, --Akatosh
	[ITEMSTYLE_ORG_DARK_BROTHERHOOD] = {stype = AIRG_STYLE_CHAPTERIZED, achiev = 1661}, --Dark Brotherhood
	[ITEMSTYLE_ENEMY_MINOTAUR] = {stype = AIRG_STYLE_CHAPTERIZED, achiev = 1662}, --Minotaur
	[ITEMSTYLE_RAIDS_CRAGLORN] = {stype = AIRG_STYLE_CHAPTERIZED, achiev = 1714}, --Craglorn
	[ITEMSTYLE_ENEMY_DRAUGR] = {stype = AIRG_STYLE_CHAPTERIZED, achiev = 1715}, --Draugr
	[ITEMSTYLE_AREA_YOKUDAN] = {stype = AIRG_STYLE_CHAPTERIZED, achiev = 1713}, --Yokudan
	[ITEMSTYLE_HOLIDAY_HOLLOWJACK] = {stype = AIRG_STYLE_CHAPTERIZED, achiev = 1545}, --Hallowjack
	[ITEMSTYLE_HOLIDAY_SKINCHANGER] = {stype = AIRG_STYLE_CHAPTERIZED, achiev = 1676}, --Skinchanger
	[ITEMSTYLE_EBONY] = {stype = AIRG_STYLE_CHAPTERIZED, achiev = 1798}, --Ebony
	[ITEMSTYLE_AREA_RA_GADA] = {stype = AIRG_STYLE_CHAPTERIZED, achiev = 1797}, --Ra Gada
	[ITEMSTYLE_ENEMY_SILKEN_RING] = {stype = AIRG_STYLE_CHAPTERIZED, achiev = 1796}, --Silken Ring
	[ITEMSTYLE_ENEMY_MAZZATUN] = {stype = AIRG_STYLE_CHAPTERIZED, achiev = 1795}, --Mazzatum
	[ITEMSTYLE_HOLIDAY_GRIM_HARLEQUIN] = {stype = AIRG_STYLE_CROWNSTORE}, --Grim Harlequin
	[ITEMSTYLE_HOLIDAY_FROSTCASTER] = {stype = AIRG_STYLE_CROWNSTORE}, --Frostcaster
	[ITEMSTYLE_ORG_MORAG_TONG] = {stype = AIRG_STYLE_CHAPTERIZED, achiev = 1933}, --Morag Tong
	[ITEMSTYLE_ORG_ORDINATOR] = {stype = AIRG_STYLE_CHAPTERIZED, achiev = 1935}, --Ordinator
	[ITEMSTYLE_ORG_BUOYANT_ARMIGER] = {stype = AIRG_STYLE_CHAPTERIZED, achiev = 1934}, --Buoyant Armiger
	[ITEMSTYLE_AREA_ASHLANDER] = {stype = AIRG_STYLE_CHAPTERIZED, achiev = 1932}, --Ashlander
	[ITEMSTYLE_ORG_REDORAN] = {stype = AIRG_STYLE_CHAPTERIZED, achiev = 2022}, --Redoran
	[ITEMSTYLE_ORG_HLAALU] = {stype = AIRG_STYLE_CHAPTERIZED, achiev = 2021}, --Hlaalu
	[ITEMSTYLE_ORG_TELVANNI] = {stype = AIRG_STYLE_CHAPTERIZED, achiev = 2023}, --Telvanni
	[ITEMSTYLE_ORG_WORM_CULT] = {stype = AIRG_STYLE_CHAPTERIZED, achiev = 2120}, --Worm Cult
	[61] = {stype = AIRG_STYLE_CHAPTERIZED, achiev = 2098}, --Bloodforge
	[62] = {stype = AIRG_STYLE_CHAPTERIZED, achiev = 2097}, --Dreadhorn
	[65] = {stype = AIRG_STYLE_CHAPTERIZED, achiev = 2044}, --Apostle
	[66] = {stype = AIRG_STYLE_CHAPTERIZED, achiev = 2045}, --Ebonshadow
	[69] = {stype = AIRG_STYLE_CHAPTERIZED, achiev = 2190}, -- Fang Lair
	[71] = {stype = AIRG_STYLE_CHAPTERIZED, achiev = 2186}, -- Psijic
	[72] = {stype = AIRG_STYLE_CHAPTERIZED, achiev = 2187}, -- Sapiarch
	[75] = {stype = AIRG_STYLE_CHAPTERIZED, achiev = 2285}, -- Pyandonean
}

-- 6-28-18 AssemblerManiac - for unknown reasons, iterating the table above to create the icons doesn't keep them in a consistent order
-- force it to be correct
local styleOrder = {
	[1] = ITEMSTYLE_RACIAL_BRETON,
	[2] = ITEMSTYLE_RACIAL_REDGUARD,
	[3] = ITEMSTYLE_RACIAL_ORC,
	[4] = ITEMSTYLE_RACIAL_DARK_ELF,
	[5] = ITEMSTYLE_RACIAL_NORD,
	[6] = ITEMSTYLE_RACIAL_ARGONIAN,
	[7] = ITEMSTYLE_RACIAL_HIGH_ELF,
	[8] = ITEMSTYLE_RACIAL_WOOD_ELF,
	[9] = ITEMSTYLE_RACIAL_KHAJIIT,
	[10] = ITEMSTYLE_AREA_ANCIENT_ELF,
	[11] = ITEMSTYLE_AREA_REACH,
	[12] = ITEMSTYLE_ENEMY_PRIMITIVE,
	[13] = ITEMSTYLE_ENEMY_DAEDRIC,
	[14] = ITEMSTYLE_RACIAL_IMPERIAL,
	[15] = ITEMSTYLE_AREA_SOUL_SHRIVEN,
	[16] = ITEMSTYLE_HOLIDAY_GRIM_HARLEQUIN,
	[17] = ITEMSTYLE_HOLIDAY_FROSTCASTER,
	[18] = ITEMSTYLE_AREA_DWEMER,
	[19] = ITEMSTYLE_GLASS,
	[20] = ITEMSTYLE_AREA_XIVKYN,
	[21] = ITEMSTYLE_AREA_ANCIENT_ORC,
	[22] = ITEMSTYLE_AREA_AKAVIRI,
	[23] = ITEMSTYLE_UNDAUNTED,
	[24] = ITEMSTYLE_DEITY_MALACATH,
	[25] = ITEMSTYLE_DEITY_TRINIMAC,
	[26] = ITEMSTYLE_ORG_OUTLAW,
	[27] = ITEMSTYLE_ALLIANCE_EBONHEART,
	[28] = ITEMSTYLE_ALLIANCE_ALDMERI,
	[29] = ITEMSTYLE_ALLIANCE_DAGGERFALL,
	[30] = ITEMSTYLE_ORG_ABAHS_WATCH,
	[31] = ITEMSTYLE_ORG_THIEVES_GUILD,
	[32] = ITEMSTYLE_ORG_ASSASSINS,
	[33] = ITEMSTYLE_ENEMY_DROMOTHRA,
	[34] = ITEMSTYLE_DEITY_AKATOSH,
	[35] = ITEMSTYLE_ORG_DARK_BROTHERHOOD,
	[36] = ITEMSTYLE_ENEMY_MINOTAUR,
	[37] = ITEMSTYLE_RAIDS_CRAGLORN,
	[38] = ITEMSTYLE_ENEMY_DRAUGR,
	[39] = ITEMSTYLE_AREA_YOKUDAN,
	[40] = ITEMSTYLE_HOLIDAY_HOLLOWJACK,
	[41] = ITEMSTYLE_HOLIDAY_SKINCHANGER,
	[42] = ITEMSTYLE_EBONY,
	[43] = ITEMSTYLE_AREA_RA_GADA,
	[44] = ITEMSTYLE_ENEMY_SILKEN_RING,
	[45] = ITEMSTYLE_ENEMY_MAZZATUN,
	[46] = ITEMSTYLE_ORG_MORAG_TONG,
	[47] = ITEMSTYLE_ORG_ORDINATOR,
	[48] = ITEMSTYLE_ORG_BUOYANT_ARMIGER,
	[49] = ITEMSTYLE_AREA_ASHLANDER,
	[50] = ITEMSTYLE_ORG_REDORAN,
	[51] = ITEMSTYLE_ORG_HLAALU,
	[52] = ITEMSTYLE_ORG_TELVANNI,
	[53] = ITEMSTYLE_ORG_WORM_CULT,
	[54] = 61,
	[55] = 62,
	[56] = 65,
	[57] = 66,
	[58] = 69,
	[59] = 71,
	[60] = 72,
	[61] = 75,
	}



-- Set the icon highlights for the currently selected character
local function UpdateMotifsUI()

	local styleItemId, styleStoreId, styleChapterId = 1, 1, 1

	local sourceData = {}
	if curCharacter == mergedCharacters then
		sourceData = mergedCharactersData
	else
		sourceData = db.char[curCharacter]
	end

	if sourceData.styles then
		for styleId, styleData in pairs(sourceData.styles) do

			if not styles[styleId].api or apiVersion >= styles[styleId].api then

				local tooltipText = ""
				local stoneItemLink = GetItemStyleMaterialLink(styleId)
				local itemName = zo_strformat(SI_TOOLTIP_ITEM_NAME, GetItemLinkName(stoneItemLink))
				local _, _, _, _, itemStyle = GetSmithingStyleItemInfo(styleId)

				if styles[styleId].stype == AIRG_STYLE_BASIC then
					if not styleData then
						AIRG_UI.StyleButtons[styleId]:SetColor(1, 0, 0, 1)
					else
						AIRG_UI.StyleButtons[styleId]:SetColor(1, 1, 1, 1)
					end

					tooltipText = zo_strformat("<<t:1>>\n<<t:2>>", GetItemStyleName(itemStyle), itemName)
					AIRG_UI.StyleButtons[styleId]:SetHandler("OnMouseEnter", function (self)
						ZO_Tooltips_ShowTextTooltip(self, TOP, tooltipText)
					end)

				elseif styles[styleId].stype == AIRG_STYLE_CROWNSTORE then

					if not styleData then
						AIRG_UI.StyleButtons[styleId]:SetColor(1, 0, 0, 1)
					else
						AIRG_UI.StyleButtons[styleId]:SetColor(1, 1, 1, 1)
					end

					tooltipText = zo_strformat("<<t:1>>\n<<t:2>>", GetItemStyleName(itemStyle), itemName)
					AIRG_UI.StyleButtons[styleId]:SetHandler("OnMouseEnter", function (self)
						ZO_Tooltips_ShowTextTooltip(self, TOP, tooltipText)
					end)

				elseif styles[styleId].stype == AIRG_STYLE_CHAPTERIZED then

					local knownCount = 0

					-- Run through the complete list in styleChaptersLookup, and look up to see which we have
					-- check how many chapters are known and build tooltip
					local chapVal		-- AM - Achieve links from styles
					chapVal = 0			-- AM - Achieve links from styles
					for chapterIndex, indexValue in ipairs(styleChaptersLookup) do
						if styleData[chapterIndex] then
							tooltipText = zo_strjoin(nil, tooltipText, "\n|cFFFFFF", GetString("SI_ITEMSTYLECHAPTER", indexValue), "|r")
							knownCount = knownCount + 1
							chapVal = chapVal + (2 ^ (chapterIndex - 1))		-- AM - Achieve links from styles
						else
							tooltipText = zo_strjoin(nil, tooltipText, "\n|c806060", GetString("SI_ITEMSTYLECHAPTER", indexValue), "|r")
						end
					end
					AIRG_UI.StyleButtons[styleId].chapVal = chapVal						-- AM - Achieve links from styles
					AIRG_UI.StyleButtons[styleId].achieve = styles[styleId].achiev		-- AM - Achieve links from styles

					if knownCount == 14 then
						AIRG_UI.StyleButtons[styleId]:SetColor(1, 1, 1, 1)
					elseif knownCount > 0 then
						AIRG_UI.StyleButtons[styleId]:SetColor(1, 1, 0, 1)
					else
						AIRG_UI.StyleButtons[styleId]:SetColor(1, 0, 0, 1)
					end

					tooltipText = zo_strjoin(nil, zo_strformat("<<t:1>> (<<2>>/14)\n<<t:3>>\n", GetItemStyleName(itemStyle), knownCount, ZO_SELECTED_TEXT:Colorize(itemName)), tooltipText)
					AIRG_UI.StyleButtons[styleId]:SetHandler("OnMouseEnter", function (self)
						ZO_Tooltips_ShowTextTooltip(self, TOP, tooltipText)
					end)

				-- AM - Achieve links from styles (next 3 lines)
				AIRG_UI.StyleButtons[styleId]:SetHandler("OnMouseUp", function (control, mButton)
					AIRG_ProcessRightClick(control, mButton)
				end)
					styleChapterId = styleChapterId + 1

				end
			end
		end
	end

end

-- Lookup the style data for the current character and send it to saved vars.
local function PopulateStyleData()

	-- Styles Wo Chapters
	db.char[curCharacter].styles = {}
	mergedCharactersData.styles = {}

	for styleId, styleData in pairs(styles) do

		if not styleData.api or apiVersion >= styleData.api then
			if styleData.stype == AIRG_STYLE_BASIC or styleData.stype == AIRG_STYLE_CROWNSTORE then
				local isStyleKnown = IsSmithingStyleKnown(styleId, 1)
				db.char[curCharacter].styles[styleId] = isStyleKnown
			elseif styleData.stype == AIRG_STYLE_CHAPTERIZED then
				db.char[curCharacter].styles[styleId] = {}
				for chapterIndex, chapterValue in ipairs(styleChaptersLookup) do
					local _, numCompleted, numRequired = GetAchievementCriterion(styleData.achiev, chapterValue)
					db.char[curCharacter].styles[styleId][chapterValue] = numCompleted == numRequired
				end
			end

			for charName, charData in pairs(db.char) do
				if charData.styles then
					if styleData.stype == AIRG_STYLE_BASIC or styleData.stype == AIRG_STYLE_CROWNSTORE then
						if not mergedCharactersData.styles[styleId] and charData.styles[styleId] then
							mergedCharactersData.styles[styleId] = true
						elseif mergedCharactersData.styles[styleId] == nil then
							mergedCharactersData.styles[styleId] = false
						end
					elseif styleData.stype == AIRG_STYLE_CHAPTERIZED then
						if not mergedCharactersData.styles[styleId] then mergedCharactersData.styles[styleId] = {} end
						for chapterIndex, chapterValue in ipairs(styleChaptersLookup) do
							if not mergedCharactersData.styles[styleId][chapterValue] and charData.styles[styleId] and charData.styles[styleId][chapterValue] then
								mergedCharactersData.styles[styleId][chapterValue] = true
							elseif mergedCharactersData.styles[styleId][chapterValue] == nil then
								mergedCharactersData.styles[styleId][chapterValue] = false
							end
						end
					end
				end
			end

		end
	end

end

local function PopulateTraitDataForCraft(craftingType)

	db.char[playerName].traits[craftingType] = {}
	for researchLineIndex = 1, GetNumSmithingResearchLines(craftingType) do

		db.char[playerName].traits[craftingType][researchLineIndex] = {}

		local _, _, numTraits = GetSmithingResearchLineInfo(craftingType, researchLineIndex)

		for traitIndex = 1, numTraits do

			local traitType, _, known = GetSmithingResearchLineTraitInfo(craftingType, researchLineIndex, traitIndex)
			local rowNum

			if craftingType ~= CRAFTING_TYPE_JEWELRYCRAFTING then
				rowNum = gridTraits[traitType]
			else
				rowNum = gridTraitsJC[traitType]
			end


			if known then
				db.char[playerName].traits[craftingType][researchLineIndex][rowNum] = TRAIT_KNOWN
			else

				local _, timeRemainingSecs = GetSmithingResearchLineTraitTimes(craftingType, researchLineIndex, traitIndex)

				if timeRemainingSecs then
					local tTargetStamp = GetTimeStamp() + timeRemainingSecs
					db.char[playerName].traits[craftingType][researchLineIndex][rowNum] = tTargetStamp
				else
					db.char[playerName].traits[craftingType][researchLineIndex][rowNum] = TRAIT_UNKNOWN
				end

			end
		end

	end

	mergedCharactersData.traits[craftingType] = {}
	for researchLineIndex = 1, GetNumSmithingResearchLines(craftingType) do

		mergedCharactersData.traits[craftingType][researchLineIndex] = {}

		local _, _, numTraits = GetSmithingResearchLineInfo(craftingType, researchLineIndex)

		for traitIndex = 1, numTraits do

			for charName, charData in pairs(db.char) do

				local traitType = GetSmithingResearchLineTraitInfo(craftingType, researchLineIndex, traitIndex)
				local rowNum
				if craftingType ~= CRAFTING_TYPE_JEWELRYCRAFTING then
					rowNum = gridTraits[traitType]
				else
					rowNum = gridTraitsJC[traitType]
				end

				if not mergedCharactersData.traits[craftingType][researchLineIndex][rowNum] then
					mergedCharactersData.traits[craftingType][researchLineIndex][rowNum] = db.char[charName].traits[craftingType][researchLineIndex][rowNum]
				elseif mergedCharactersData.traits[craftingType][researchLineIndex][rowNum] == TRAIT_UNKNOWN then
					if db.char[charName].traits[craftingType] then
						if db.char[charName].traits[craftingType][researchLineIndex] then
							if db.char[charName].traits[craftingType][researchLineIndex][rowNum] ~= TRAIT_UNKNOWN then
								mergedCharactersData.traits[craftingType][researchLineIndex][rowNum] = db.char[charName].traits[craftingType][researchLineIndex][rowNum]
							end
						end
					end
				elseif mergedCharactersData.traits[craftingType][researchLineIndex][rowNum] > TRAIT_UNKNOWN and
					db.char[charName].traits[craftingType][researchLineIndex][rowNum] > TRAIT_UNKNOWN and
					db.char[charName].traits[craftingType][researchLineIndex][rowNum] < mergedCharactersData.traits[craftingType][researchLineIndex][rowNum] then
					mergedCharactersData.traits[craftingType][researchLineIndex][rowNum] = db.char[charName].traits[craftingType][researchLineIndex][rowNum]
				end

			end
		end

	end

end

local function BuildRelative()

	local function BuildRelativeForCraft(charName, craftingType)

		relative[charName][craftingType] = {}

		for researchLineIndex = 1, GetNumSmithingResearchLines(craftingType) do

			relative[charName][craftingType][researchLineIndex] = {}
			local _, _, numTraits = GetSmithingResearchLineInfo(craftingType, researchLineIndex)

			for traitIndex = 1, numTraits do

				local traitType = GetSmithingResearchLineTraitInfo(craftingType, researchLineIndex, traitIndex)
				local rowNum
				if craftingType ~= CRAFTING_TYPE_JEWELRYCRAFTING then
					rowNum = gridTraits[traitType]
				else
					rowNum = gridTraitsJC[traitType]
				end

				local isKnownForLocalPlayer = db.char[playerName].traits[craftingType][researchLineIndex][rowNum] == TRAIT_KNOWN
				local isKnownForRelative = db.char[charName].traits[craftingType][researchLineIndex][rowNum] == TRAIT_KNOWN

				if (isKnownForLocalPlayer and not isKnownForRelative) or (isKnownForLocalPlayer and isKnownForRelative) then
					relative[charName][craftingType][researchLineIndex][rowNum] = TRAIT_KNOWN
				else
					relative[charName][craftingType][researchLineIndex][rowNum] = TRAIT_UNKNOWN
				end

				local isInResearchForRelative = db.char[charName].traits[craftingType][researchLineIndex][rowNum] > TRAIT_UNKNOWN
				if isInResearchForRelative and db.char[charName].traits[craftingType][researchLineIndex][rowNum] <= GetTimeStamp() then
					db.char[charName].traits[craftingType][researchLineIndex][rowNum] = TRAIT_KNOWN
					mergedCharactersData.traits[craftingType][researchLineIndex][rowNum] = TRAIT_KNOWN
				end

			end

		end
	end

	for charName, data in pairs(db.char) do
		if charName ~= playerName then

			relative[charName] = {}

			BuildRelativeForCraft(charName, CRAFTING_TYPE_BLACKSMITHING)
			BuildRelativeForCraft(charName, CRAFTING_TYPE_CLOTHIER)
			BuildRelativeForCraft(charName, CRAFTING_TYPE_WOODWORKING)
			BuildRelativeForCraft(charName, CRAFTING_TYPE_JEWELRYCRAFTING)

		end
	end

end

local function BuildMatrix(eventCode, arg1, arg2, arg3)

	-- Build is delayed to EVENT_PLAYER_ACTIVATED because of the ESO+ bonus which is only applied after the 1st load after OnAddonLoaded
	if eventCode == EVENT_PLAYER_ACTIVATED then

		EVENT_MANAGER:UnregisterForEvent(ADDON_NAME, EVENT_PLAYER_ACTIVATED)

		BLACKSMITHING_RESEARCH_LEVEL = GetNonCombatBonus(NON_COMBAT_BONUS_BLACKSMITHING_RESEARCH_LEVEL)
		CLOTHIER_RESEARCH_LEVEL = GetNonCombatBonus(NON_COMBAT_BONUS_CLOTHIER_RESEARCH_LEVEL)
		WOODWORKING_RESEARCH_LEVEL = GetNonCombatBonus(NON_COMBAT_BONUS_WOODWORKING_RESEARCH_LEVEL)
		JEWELRYCRAFTING_RESEARCH_LEVEL = GetNonCombatBonus(NON_COMBAT_BONUS_JEWELRYCRAFTING_RESEARCH_LEVEL)

		db.char[playerName].traits = {}
		mergedCharactersData.traits = {}

		PopulateTraitDataForCraft(CRAFTING_TYPE_BLACKSMITHING)
		PopulateTraitDataForCraft(CRAFTING_TYPE_CLOTHIER)
		PopulateTraitDataForCraft(CRAFTING_TYPE_WOODWORKING)
		PopulateTraitDataForCraft(CRAFTING_TYPE_JEWELRYCRAFTING)

		BuildRelative()
		PopulateStyleData()
		UpdateMotifsUI()

	-- EVENT_SKILLS_FULL_UPDATE handle the % time bonus when buying a new skill in realtime
	elseif eventCode == EVENT_SKILLS_FULL_UPDATE then

		local NEW_BLACKSMITHING_RESEARCH_LEVEL = GetNonCombatBonus(NON_COMBAT_BONUS_BLACKSMITHING_RESEARCH_LEVEL)
		local NEW_CLOTHIER_RESEARCH_LEVEL = GetNonCombatBonus(NON_COMBAT_BONUS_CLOTHIER_RESEARCH_LEVEL)
		local NEW_WOODWORKING_RESEARCH_LEVEL = GetNonCombatBonus(NON_COMBAT_BONUS_WOODWORKING_RESEARCH_LEVEL)
		local NEW_JEWELRYCRAFTING_RESEARCH_LEVEL = GetNonCombatBonus(NON_COMBAT_BONUS_JEWELRYCRAFTING_RESEARCH_LEVEL)

		if NEW_BLACKSMITHING_RESEARCH_LEVEL ~= BLACKSMITHING_RESEARCH_LEVEL then
			BLACKSMITHING_RESEARCH_LEVEL = NEW_BLACKSMITHING_RESEARCH_LEVEL
			PopulateTraitDataForCraft(CRAFTING_TYPE_BLACKSMITHING)
			BuildRelative()
		elseif NEW_CLOTHIER_RESEARCH_LEVEL ~= CLOTHIER_RESEARCH_LEVEL then
			CLOTHIER_RESEARCH_LEVEL = NEW_CLOTHIER_RESEARCH_LEVEL
			PopulateTraitDataForCraft(CRAFTING_TYPE_CLOTHIER)
			BuildRelative()
		elseif NEW_WOODWORKING_RESEARCH_LEVEL ~= WOODWORKING_RESEARCH_LEVEL then
			WOODWORKING_RESEARCH_LEVEL = NEW_WOODWORKING_RESEARCH_LEVEL
			PopulateTraitDataForCraft(CRAFTING_TYPE_WOODWORKING)
			BuildRelative()
		elseif NEW_JEWELRYCRAFTING_RESEARCH_LEVEL ~= JEWELRYCRAFTING_RESEARCH_LEVEL then
			JEWELRYCRAFTING_RESEARCH_LEVEL = NEW_JEWELRYCRAFTING_RESEARCH_LEVEL
			PopulateTraitDataForCraft(CRAFTING_TYPE_JEWELRYCRAFTING)
			BuildRelative()
		end

	elseif eventCode == EVENT_SMITHING_TRAIT_RESEARCH_STARTED then

		local craftingType, researchLineIndex, traitIndex = arg1, arg2, arg3
		-- Set timer started for actual char and "ALL" for craftingType, researchLineIndex, traitIndex

		local traitType = GetSmithingResearchLineTraitInfo(craftingType, researchLineIndex, traitIndex)
		local rowNum
		if craftingType ~= CRAFTING_TYPE_JEWELRYCRAFTING then
			rowNum = gridTraits[traitType]
		else
			rowNum = gridTraitsJC[traitType]
		end
		local _, timeRemainingSecs = GetSmithingResearchLineTraitTimes(craftingType, researchLineIndex, traitIndex)
		local tTargetStamp = GetTimeStamp() + timeRemainingSecs

		db.char[playerName].traits[craftingType][researchLineIndex][rowNum] = tTargetStamp

		if mergedCharactersData.traits[craftingType][researchLineIndex][rowNum] ~= TRAIT_KNOWN then
			mergedCharactersData.traits[craftingType][researchLineIndex][rowNum] = tTargetStamp
		end

		BuildRelative()

	elseif eventCode == EVENT_SMITHING_TRAIT_RESEARCH_COMPLETED then

		local craftingType, researchLineIndex, traitIndex = arg1, arg2, arg3
		-- Set research completed for actual char and "ALL" for craftingType, researchLineIndex, traitIndex

		local traitType = GetSmithingResearchLineTraitInfo(craftingType, researchLineIndex, traitIndex)
		local rowNum
		if craftingType ~= CRAFTING_TYPE_JEWELRYCRAFTING then
			rowNum = gridTraits[traitType]
		else
			rowNum = gridTraitsJC[traitType]
		end

		db.char[playerName].traits[craftingType][researchLineIndex][rowNum] = TRAIT_KNOWN
		mergedCharactersData.traits[craftingType][researchLineIndex][rowNum] = TRAIT_KNOWN

		BuildRelative()

	elseif eventCode == EVENT_SMITHING_TRAIT_RESEARCH_TIMES_UPDATED then

		if not mergedCharactersData.traits then mergedCharactersData.traits = {} end

		PopulateTraitDataForCraft(CRAFTING_TYPE_BLACKSMITHING)
		PopulateTraitDataForCraft(CRAFTING_TYPE_CLOTHIER)
		PopulateTraitDataForCraft(CRAFTING_TYPE_WOODWORKING)
		PopulateTraitDataForCraft(CRAFTING_TYPE_JEWELRYCRAFTING)

		BuildRelative()

	elseif eventCode == EVENT_STYLE_LEARNED then

		local itemStyleId, chapterIndex = arg1, arg2
		-- Set style known for actual char and "ALL" for styleIndex, chapterIndex

		if not styles[itemStyleId] then
			-- unknown style, do nothing

		elseif chapterIndex == ITEM_STYLE_CHAPTER_ALL then
			-- Learned a complete book
			if styles[itemStyleId].stype == AIRG_STYLE_BASIC or styles[itemStyleId].stype == AIRG_STYLE_CROWNSTORE then

				db.char[playerName].styles[itemStyleId] = true
				mergedCharactersData.styles[itemStyleId] = true

			elseif styles[itemStyleId].stype == AIRG_STYLE_CHAPTERIZED then
				for chapterLookupIndex in ipairs(styleChaptersLookup) do
					db.char[playerName].styles[itemStyleId][chapterLookupIndex] = true
					mergedCharactersData.styles[itemStyleId][chapterLookupIndex] = true
				end
			end
		elseif styles[itemStyleId].stype == AIRG_STYLE_CHAPTERIZED then
			local newIndexKnown
			for aiIndex, zosIndex in ipairs(styleChaptersLookup) do
				if chapterIndex == zosIndex then
					newIndexKnown = aiIndex
					break
				end
			end
			db.char[playerName].styles[itemStyleId][newIndexKnown] = true
			mergedCharactersData.styles[itemStyleId][newIndexKnown] = true
		end

		UpdateMotifsUI()

	end

end

-- User has clicked on one of the profession buttons
-- or we just want to refresh the display with current data
local function OnCraftSelected(thisCraft)

	if not thisCraft then
		if not currentCraft then
			return
		else
			thisCraft = currentCraft
		end
	end

	db.currentCraft = thisCraft

	local filterTypeFromCraftingType = {
		[CRAFTING_TYPE_BLACKSMITHING] = ITEMFILTERTYPE_BLACKSMITHING,
		[CRAFTING_TYPE_CLOTHIER] = ITEMFILTERTYPE_CLOTHING,
		[CRAFTING_TYPE_WOODWORKING] = ITEMFILTERTYPE_WOODWORKING ,
		[CRAFTING_TYPE_JEWELRYCRAFTING] = ITEMFILTERTYPE_JEWELRYCRAFTING ,
	}

	AIRG_UI.WindowSubTitle:SetText(GetString("SI_ITEMFILTERTYPE", filterTypeFromCraftingType[thisCraft]))

	local researching
	local traitCount, alltraits, tooltiptext
	local maxLines = GetNumSmithingResearchLines(thisCraft) -- the number of columns for this profession

	currentCraft = thisCraft
	alltraits = 0
	local sourceData
	local sourceData
	if curCharacter == mergedCharacters then
		sourceData = mergedCharactersData
	else
		sourceData = db.char[curCharacter]
	end

	local thisTrait, j

	if thisCraft ~= CRAFTING_TYPE_JEWELRYCRAFTING then
		for thisTrait, j in pairs(gridTraits) do
			AIRG_UI.rowLabels[j].isJewelryCrafting = false
			AIRG_UI.rowLabels[j]:SetText(GetString("SI_ITEMTRAITTYPE", thisTrait))       -- This is the text displayed on the screen as it's a label
		end
	else
		for thisTrait, j in pairs(gridTraitsJC) do
			AIRG_UI.rowLabels[j].isJewelryCrafting = true
			AIRG_UI.rowLabels[j]:SetText(GetString("SI_ITEMTRAITTYPE", thisTrait))       -- This is the text displayed on the screen as it's a label
		end
		for j = 10, 18 do
			AIRG_UI.rowLabels[j].isJewelryCrafting = nil
			AIRG_UI.rowLabels[j]:SetText("")
		end
	end

	for i = 1, maxColumns do
		researching = false

		for j = 1, 18 do
			AIRG_UI.gridButtons[i][j]:SetColor(1, 1, 1, 0.4)
			AIRG_UI.gridButtons[i][j]:SetTexture("/esoui/art/buttons/swatchframe_down.dds")
			AIRG_UI.gridButtons[i][j]:SetMouseEnabled(false)    -- effectively disable tooltip for this grid item.
		end

		if (i > maxLines) then
			AIRG_UI.columnButtons[i]:SetHidden(true)
			AIRG_UI.columnFooters[i]:SetText("")
		else

			local name, icon, _, _ = GetSmithingResearchLineInfo(thisCraft, i)  -- Get info on that specific item
			AIRG_UI.columnButtons[i]:SetNormalTexture(icon)
			AIRG_UI.columnButtons[i]:SetHidden(false)
			AIRG_UI.columnButtons[i].text = name
			traitCount = 0

			--Check for research expiry
			for rowNum, tKnown in pairs(sourceData.traits[thisCraft][i]) do
				if (tKnown > 0 and tKnown < GetTimeStamp()) then
					sourceData.traits[thisCraft][i][rowNum] = TRAIT_KNOWN  -- Change to known
				end
			end

			if showRelative then
				-- Great! relative mode! we need to address a matter of practical usage.
				--  We need to see that we actually can research that now, because we can't research more than one item type at a time.
				--  So we need to pre-check for item research and set the colours (of the texture) appropriately
				for rowNum,tKnown in pairs(sourceData.traits[thisCraft][i]) do
					if (tKnown > 0) then  -- researching
						researching = true
					end
				end

				for rowNum, tKnown in pairs(relative[curCharacter][thisCraft][i]) do
					AIRG_UI.gridButtons[i][rowNum].Known = tKnown
					if (tKnown == TRAIT_KNOWN) then       -- Trait is known
						if researching then
							AIRG_UI.gridButtons[i][rowNum]:SetColor(0.7, 0.6, 0.6, .8)   -- Dull Reddish
						else
							AIRG_UI.gridButtons[i][rowNum]:SetColor(0.2, 1, 0.2, 1)   -- Green
							AIRG_UI.gridButtons[i][rowNum]:SetMouseEnabled(true)
						end
						tooltiptext = zo_strjoin(" ",AIRG_UI.rowLabels[rowNum]:GetText() , AIRG_UI.columnButtons[i].text)
						AIRG_UI.gridButtons[i][rowNum].tooltipText = tooltiptext
						AIRG_UI.gridButtons[i][rowNum]:SetTexture("/esoui/art/loot/loot_finesseitem.dds")
						traitCount = traitCount + 1
					end
				end

			else -- not relative
				for rowNum,tKnown in pairs(sourceData.traits[thisCraft][i]) do
					AIRG_UI.gridButtons[i][rowNum].Known = tKnown

					if (tKnown == TRAIT_KNOWN) then       -- Trait is known
						AIRG_UI.gridButtons[i][rowNum]:SetColor(0.2, 1, 0.2, 1)   -- Green
						AIRG_UI.gridButtons[i][rowNum]:SetTexture("/esoui/art/loot/loot_finesseitem.dds")
						traitCount = traitCount + 1
						tooltiptext = zo_strjoin(" ",AIRG_UI.rowLabels[rowNum]:GetText() , AIRG_UI.columnButtons[i].text)
						AIRG_UI.gridButtons[i][rowNum].tooltipText = tooltiptext
						AIRG_UI.gridButtons[i][rowNum]:SetMouseEnabled(true)
					elseif (tKnown > 0) then   -- Trait is being researched
						AIRG_UI.gridButtons[i][rowNum]:SetTexture("/esoui/art/miscellaneous/gamepad/gp_icon_timer32.dds")
						AIRG_UI.gridButtons[i][rowNum]:SetColor(0.0, .5, .75, 1)   -- Blue
						AIRG_UI.gridButtons[i][rowNum]:SetMouseEnabled(true)
					else                        -- Trait is NOT known
						AIRG_UI.gridButtons[i][rowNum]:SetColor(1, 0.2, 0.2, 1)   -- Red
						AIRG_UI.gridButtons[i][rowNum]:SetTexture("esoui/art/buttons/decline_up.dds")  --  an   "X".
					end
				end
			end  --Relative

			AIRG_UI.columnFooters[i]:SetText(traitCount)
			alltraits = alltraits + traitCount
		end
	end

	AIRG_UI.columnFooterTitle:SetText(GetString(SI_CRAFTING_COMPONENT_TOOLTIP_TRAITS) .. "(" .. tostring(alltraits) .. ")")   -- "Traits"

end

local function ToggleMainWindow()

	if AIResearchGrid:IsHidden() then
		OnCraftSelected()
	end

	SCENE_MANAGER:ToggleTopLevel(AIResearchGrid)	-- Thanks Wandamey

end

-- Invoked when the user selected a character from the dropdown box
local function OnCharacterSelect(charName)

	if charName ~= GetString(AIRG_OPTIONS_ALL) then
		curCharacter = charName
	else
		curCharacter = mergedCharacters
	end

	-- The Relative Button doesn't make sense if selecting these
	if curCharacter == mergedCharacters or curCharacter == playerName then
		AIRG_UI.btnUpdateOther:SetState(BSTATE_DISABLED)
		showRelative = false
	else
		AIRG_UI.btnUpdateOther:SetState(BSTATE_NORMAL)
	end

	UpdateMotifsUI()
	OnCraftSelected()

end

-- Create AIRG UI
local function InitUI()

	-- Set the main window subtitle
	AIRG_UI.WindowSubTitle = GetControl(AIResearchGrid, "WindowSubTitle")

	-- Nice little line under the grid
	AIRG_UI.BottomDivider = GetControl(AIResearchGrid, "BottomDivider")

	-- CREATE the DROPDOWN BOX for CHARACTER SELECT
	-- Uses code based on example from Seerah
	AIRG_UI.charDropdown = WINDOW_MANAGER:CreateControlFromVirtual("$(parent)DropdownCharacter", AIResearchGrid, "ZO_StatsDropdownRow")
	AIRG_UI.charDropdown:SetWidth(205)
	AIRG_UI.charDropdown:SetAnchor(TOPRIGHT, AIResearchGrid, TOPRIGHT, -32, 0)
	AIRG_UI.charDropdown:GetNamedChild("Dropdown"):SetWidth(200)
	AIRG_UI.charDropdown.dropdown:SetSelectedItem(curCharacter)  -- Set the current character as selected

	local function OnItemSelect(_, choiceText, choice)  --this is the callback function for when an item gets selected in the dropdown
		OnCharacterSelect(choiceText)
	end

	local entry = AIRG_UI.charDropdown.dropdown:CreateItemEntry(GetString(AIRG_OPTIONS_ALL), OnItemSelect)
	AIRG_UI.charDropdown.dropdown:AddItem(entry)

	for charName, _ in pairs(db.char) do
		local entry = AIRG_UI.charDropdown.dropdown:CreateItemEntry(charName, OnItemSelect)
		AIRG_UI.charDropdown.dropdown:AddItem(entry)
	end

	-- CREATE BUTTON FOR "Relative to" AT TOP_RIGHT
	AIRG_UI.btnUpdateOther = WINDOW_MANAGER:CreateControlFromVirtual("$(parent)ButtonUpdateOther", AIResearchGrid, "ZO_DefaultButton")

	--Attempt to adjust button size to content, but units are different. May not be fixable. leave for meantime.
	local textlen = 0
	if string.len(GetString(AIRG_OPTIONS_RELATIVE)) > string.len(GetString(AIRG_OPTIONS_RELATIVE_TO))	then
		textlen = string.len(GetString(AIRG_OPTIONS_RELATIVE))
	else
		textlen = string.len(GetString(AIRG_OPTIONS_RELATIVE_TO))
	end

	AIRG_UI.btnUpdateOther:SetDimensions(140 + textlen, 30)
	AIRG_UI.btnUpdateOther:SetAnchor(RIGHT, AIRG_UI.charDropdown, LEFT, 0, 0)
	AIRG_UI.btnUpdateOther:SetState(BSTATE_NORMAL)
	AIRG_UI.btnUpdateOther:SetMouseOverBlendMode(0)
	AIRG_UI.btnUpdateOther:SetMouseOverTexture("esoui/art/buttons/generic_highlight.dds")
	AIRG_UI.btnUpdateOther:SetClickSound("Click")
	AIRG_UI.btnUpdateOther:SetDisabledFontColor(ZO_DEFAULT_DISABLED_COLOR:UnpackRGBA())
	AIRG_UI.btnUpdateOther:SetFont("ZoFontGame")
	AIRG_UI.btnUpdateOther:SetText(GetString(AIRG_OPTIONS_RELATIVE_TO))
	AIRG_UI.btnUpdateOther:SetEnabled(false)  -- starts pointing to current character, which can't use this
	AIRG_UI.btnUpdateOther:SetHidden(false)
	-- enabled at end of function
	AIRG_UI.btnUpdateOther:SetHandler("OnClicked",
		function(self)
			showRelative = not showRelative
			if showRelative then
				self:SetText(GetString(AIRG_OPTIONS_RELATIVE))
			else
				self:SetText(GetString(AIRG_OPTIONS_RELATIVE_TO))
			end
			OnCraftSelected()
		end)

	AIRG_UI.btnUpdateOther:SetMouseEnabled(true)

	-- CREATE BUTTON FOR PROFESSION: BLACKSMITHING
	AIRG_UI.btnBlacksmithing = WINDOW_MANAGER:CreateControl("$(parent)ButtonBlacksmithing", AIResearchGrid, CT_BUTTON)
	AIRG_UI.btnBlacksmithing:SetDimensions(48, 48)
	AIRG_UI.btnBlacksmithing:SetAnchor(TOPLEFT, AIResearchGrid, TOPLEFT, 8 , 44)
	AIRG_UI.btnBlacksmithing:SetState(BSTATE_NORMAL)
	AIRG_UI.btnBlacksmithing:SetMouseOverBlendMode(0)
	AIRG_UI.btnBlacksmithing:SetHidden(false)
	AIRG_UI.btnBlacksmithing:SetEnabled(true)
	AIRG_UI.btnBlacksmithing:SetClickSound(SOUNDS.WOODWORKER_EXTRACTED_BOOSTER)
	AIRG_UI.btnBlacksmithing:SetNormalTexture("/esoui/art/icons/ability_smith_007.dds")
	AIRG_UI.btnBlacksmithing:SetMouseOverTexture("esoui/art/buttons/generic_highlight.dds")
	AIRG_UI.btnBlacksmithing:SetHandler("OnClicked", function(self) OnCraftSelected(CRAFTING_TYPE_BLACKSMITHING) end)
	AIRG_UI.btnBlacksmithing:SetHandler("OnMouseEnter", function(self) ZO_Tooltips_ShowTextTooltip(self, RIGHT, GetString(SI_ITEMFILTERTYPE13)) end)
	AIRG_UI.btnBlacksmithing:SetHandler("OnMouseExit", function (self) ZO_Tooltips_HideTextTooltip() end)

	-- CREATE BUTTON FOR PROFESSION: WOODWORKING
	AIRG_UI.btnWoodworking = WINDOW_MANAGER:CreateControl("$(parent)ButtonWoodworking", AIResearchGrid, CT_BUTTON)
	AIRG_UI.btnWoodworking:SetDimensions(48, 48)
	AIRG_UI.btnWoodworking:SetAnchor(TOPLEFT, AIRG_UI.btnBlacksmithing, BOTTOMLEFT, 0, 12)
	AIRG_UI.btnWoodworking:SetState(BSTATE_NORMAL)
	AIRG_UI.btnWoodworking:SetMouseOverBlendMode(0)
	AIRG_UI.btnWoodworking:SetHidden(false)
	AIRG_UI.btnWoodworking:SetEnabled(true)
	AIRG_UI.btnWoodworking:SetClickSound(SOUNDS.BLACKSMITH_EXTRACTED_BOOSTER)
	AIRG_UI.btnWoodworking:SetNormalTexture("/esoui/art/icons/ability_tradecraft_009.dds")
	AIRG_UI.btnWoodworking:SetMouseOverTexture("esoui/art/buttons/generic_highlight.dds")
	AIRG_UI.btnWoodworking:SetHandler("OnClicked", function(self) OnCraftSelected(CRAFTING_TYPE_WOODWORKING) end)
	AIRG_UI.btnWoodworking:SetHandler("OnMouseEnter", function(self) ZO_Tooltips_ShowTextTooltip(self, RIGHT, GetString(SI_ITEMFILTERTYPE15)) end)
	AIRG_UI.btnWoodworking:SetHandler("OnMouseExit", function (self) ZO_Tooltips_HideTextTooltip() end)

	-- CREATE BUTTON FOR PROFESSION: CLOTHING
	AIRG_UI.btnClothing = WINDOW_MANAGER:CreateControl("$(parent)ButtonClothing", AIResearchGrid, CT_BUTTON)
	AIRG_UI.btnClothing:SetDimensions(48, 48)
	AIRG_UI.btnClothing:SetAnchor(TOPLEFT, AIRG_UI.btnWoodworking, BOTTOMLEFT, 0, 12)
	AIRG_UI.btnClothing:SetState(BSTATE_NORMAL)
	AIRG_UI.btnClothing:SetMouseOverBlendMode(0)
	AIRG_UI.btnClothing:SetHidden(false)
	AIRG_UI.btnClothing:SetEnabled(true)
	AIRG_UI.btnClothing:SetClickSound(SOUNDS.CLOTHIER_EXTRACTED_BOOSTER)
	AIRG_UI.btnClothing:SetNormalTexture("/esoui/art/icons/ability_tradecraft_008.dds")
	AIRG_UI.btnClothing:SetMouseOverTexture("esoui/art/buttons/generic_highlight.dds")
	AIRG_UI.btnClothing:SetHandler("OnClicked", function(self) OnCraftSelected(CRAFTING_TYPE_CLOTHIER) end)
	AIRG_UI.btnClothing:SetHandler("OnMouseEnter", function(self) ZO_Tooltips_ShowTextTooltip(self, RIGHT, GetString(SI_ITEMFILTERTYPE14)) end)
	AIRG_UI.btnClothing:SetHandler("OnMouseExit", function (self) ZO_Tooltips_HideTextTooltip() end)

	-- CREATE BUTTON FOR PROFESSION: JEWELRY CRAFTING
	AIRG_UI.btnJewelryCrafting = WINDOW_MANAGER:CreateControl("$(parent)ButtonJewelryCrafting", AIResearchGrid, CT_BUTTON)
	AIRG_UI.btnJewelryCrafting:SetDimensions(48, 48)
	AIRG_UI.btnJewelryCrafting:SetAnchor(TOPLEFT, AIRG_UI.btnClothing, BOTTOMLEFT, 0 , 12)
	AIRG_UI.btnJewelryCrafting:SetState(BSTATE_NORMAL)
	AIRG_UI.btnJewelryCrafting:SetMouseOverBlendMode(0)
	AIRG_UI.btnJewelryCrafting:SetHidden(false)
	AIRG_UI.btnJewelryCrafting:SetEnabled(true)
	AIRG_UI.btnJewelryCrafting:SetClickSound(SOUNDS.JEWELRYCRAFTER_EXTRACTED_BOOSTER)
	AIRG_UI.btnJewelryCrafting:SetNormalTexture("/esoui/art/icons/passive_jewelerengraver.dds")
	AIRG_UI.btnJewelryCrafting:SetMouseOverTexture("esoui/art/buttons/generic_highlight.dds")
	AIRG_UI.btnJewelryCrafting:SetHandler("OnClicked", function(self) OnCraftSelected(CRAFTING_TYPE_JEWELRYCRAFTING) end)
	AIRG_UI.btnJewelryCrafting:SetHandler("OnMouseEnter", function(self) ZO_Tooltips_ShowTextTooltip(self, RIGHT, GetString(SI_ITEMFILTERTYPE24)) end)
	AIRG_UI.btnJewelryCrafting:SetHandler("OnMouseExit", function (self) ZO_Tooltips_HideTextTooltip() end)

	-- BUILD THE TRAIT LABELS ON THE LEFT-SIDE using built-in language strings
	AIRG_UI.rowLabels = {}
	for thisTrait, j in pairs(gridTraits) do
		AIRG_UI.rowLabels[j] = WINDOW_MANAGER:CreateControl("$(parent)RowLabel" .. tostring(j), AIResearchGrid, CT_LABEL)
		AIRG_UI.rowLabels[j]:SetAnchor(TOPLEFT, AIResearchGrid, TOPLEFT, 5 + 48, 28*j + 70)
		AIRG_UI.rowLabels[j]:SetText(GetString("SI_ITEMTRAITTYPE", thisTrait))       -- This is the text displayed on the screen as it's a label
		AIRG_UI.rowLabels[j]:SetDimensions(180 - 48, 24)
		AIRG_UI.rowLabels[j]:SetFont("ZoFontGame")
		AIRG_UI.rowLabels[j]:SetHorizontalAlignment(TEXT_ALIGN_RIGHT)
		AIRG_UI.rowLabels[j]:SetVerticalAlignment(TEXT_ALIGN_CENTER)
		AIRG_UI.rowLabels[j]:SetMouseEnabled(true)
		AIRG_UI.rowLabels[j].isJewelryCrafting = false
		AIRG_UI.rowLabels[j]:SetHandler("OnMouseEnter", function (self)
			if self.isJewelryCrafting == nil then
				ZO_Tooltips_HideTextTooltip()
			elseif self.isJewelryCrafting then
				ZO_Tooltips_ShowTextTooltip(self, TOP, self.tooltipTextJC)
			else
				ZO_Tooltips_ShowTextTooltip(self, TOP, self.tooltipText)
			end
		end)
		AIRG_UI.rowLabels[j]:SetHandler("OnMouseExit", function (self)
			ZO_Tooltips_HideTextTooltip()
		end)
	end

	-- Now add tooltip text to the row labels.
	-- The tooltip functionality is automatic as part of the label control.
	for j = 1, 9 do
		local tTypeW, tDescW, _ = GetSmithingResearchLineTraitInfo(CRAFTING_TYPE_BLACKSMITHING,1,j) -- weapons
		AIRG_UI.rowLabels[gridTraits[tTypeW]].tooltipText = tDescW
		local tTypeA, tDescA, _ = GetSmithingResearchLineTraitInfo(CRAFTING_TYPE_BLACKSMITHING,9,j) -- armour
		AIRG_UI.rowLabels[gridTraits[tTypeA]].tooltipText = tDescA
		local tTypeA, tDescA, _ = GetSmithingResearchLineTraitInfo(CRAFTING_TYPE_JEWELRYCRAFTING,1,j) -- jewelry
		AIRG_UI.rowLabels[gridTraitsJC[tTypeA]].tooltipTextJC = tDescA
	end

	-- BUILD THE COLUMNS & GRID
	-- Determine the maximum number of item types across all three professions. This is currently always 14
	maxColumns = math.max(GetNumSmithingResearchLines(CRAFTING_TYPE_BLACKSMITHING),
	GetNumSmithingResearchLines(CRAFTING_TYPE_CLOTHIER),
	GetNumSmithingResearchLines(CRAFTING_TYPE_WOODWORKING),
	GetNumSmithingResearchLines(CRAFTING_TYPE_JEWELRYCRAFTING))
	AIRG_UI.columnButtons = {}
	AIRG_UI.gridButtons = {}
	AIRG_UI.columnFooters = {}

	for i = 1, maxColumns do
		-- BUILD THE COLUMN BUTTONS
		AIRG_UI.columnButtons[i] = WINDOW_MANAGER:CreateControl("$(parent)HeaderButton" .. tostring(i), AIResearchGrid, CT_BUTTON)
		AIRG_UI.columnButtons[i]:SetDimensions(36, 36)
		AIRG_UI.columnButtons[i]:SetState(BSTATE_NORMAL)
		AIRG_UI.columnButtons[i]:SetAnchor(TOPLEFT, AIResearchGrid, TOPLEFT, 40*i + 150, 55)
		AIRG_UI.columnButtons[i]:SetHidden(true)
		AIRG_UI.columnButtons[i]:SetEnabled(true)
		AIRG_UI.columnButtons[i]:SetMouseOverTexture("esoui/art/buttons/generic_highlight.dds")
		AIRG_UI.columnButtons[i].text = i	-- placeholder
		AIRG_UI.columnButtons[i]:SetHandler("OnMouseEnter", function (self)
			ZO_Tooltips_ShowTextTooltip(self, TOP, self.text)
		end)
		AIRG_UI.columnButtons[i]:SetHandler("OnMouseExit", function (self)
			ZO_Tooltips_HideTextTooltip()
		end)
		-- BUILD THE GRID
		-- There are a total of 18 traits possible. 9 armour and 9 weapon (Infused, Training and Nirnhoned on both)
		AIRG_UI.gridButtons[i] = {}
		for j = 1, 18 do
			AIRG_UI.gridButtons[i][j] = WINDOW_MANAGER:CreateControl("$(parent)Button" .. tostring(i) .. "x" .. tostring(j), AIResearchGrid, CT_TEXTURE)
			AIRG_UI.gridButtons[i][j]:SetDimensions(24, 24)
			AIRG_UI.gridButtons[i][j]:SetAnchor(TOP, AIRG_UI.columnButtons[i], BOTTOM, 0, 28 * j -20)
			AIRG_UI.gridButtons[i][j]:SetTexture("/esoui/art/buttons/swatchframe_down.dds")  -- little square box
			AIRG_UI.gridButtons[i][j]:SetColor(1, 1, 1, 0.4)
			AIRG_UI.gridButtons[i][j]:SetHidden(false)
			AIRG_UI.gridButtons[i][j]:SetMouseEnabled(false)
			-- Following tooltip code uses ideas contributed by Krysstof
			AIRG_UI.gridButtons[i][j]:SetHandler("OnMouseEnter", function (self)
				--   if (self.tooltipText > 0) then      -- Check the item is being researched and has a timestamp
				if (self.Known > 0) then      -- Check the item is being researched and has a timestamp
					local tRemaining = tonumber(self.Known) - GetTimeStamp()
					local tFormatted = FormatTimeSeconds(tRemaining, TIME_FORMAT_STYLE_DESCRIPTIVE_SHORT, TIME_FORMAT_PRECISION_SECONDS, TIME_FORMAT_DIRECTION_DESCENDING)
					ZO_Tooltips_ShowTextTooltip(self, RIGHT, tFormatted)
					-- loop with "registerforupdate" once per second
					EVENT_MANAGER:RegisterForUpdate(ADDON_NAME, 1000, function()
						local tRemaining = tonumber(self.Known) - GetTimeStamp()
						local tFormatted = FormatTimeSeconds(tRemaining, TIME_FORMAT_STYLE_DESCRIPTIVE_SHORT, TIME_FORMAT_PRECISION_SECONDS, TIME_FORMAT_DIRECTION_DESCENDING)
						ZO_Tooltips_ShowTextTooltip(self, RIGHT, tFormatted)
					end)
				else
					ZO_Tooltips_ShowTextTooltip(self, RIGHT, self.tooltipText)
				end
			end)
			AIRG_UI.gridButtons[i][j]:SetHandler("OnMouseExit", function (self)
				-- unregister the update event or it keeps on displaying
				EVENT_MANAGER:UnregisterForUpdate(ADDON_NAME)
				ZO_Tooltips_HideTextTooltip()
			end)
		end

		-- BUILD THE COLUMN FOOTERS
		AIRG_UI.columnFooters[i] = WINDOW_MANAGER:CreateControl("$(parent)ColumnFooterLabel" .. tostring(i), AIResearchGrid, CT_LABEL)
		AIRG_UI.columnFooters[i]:SetAnchor(TOP, AIRG_UI.columnButtons[i], BOTTOM, 0, 516)
		AIRG_UI.columnFooters[i]:SetDimensions(36, 24)
		AIRG_UI.columnFooters[i]:SetFont("ZoFontGame")
		AIRG_UI.columnFooters[i]:SetHorizontalAlignment(TEXT_ALIGN_CENTER)
		AIRG_UI.columnFooters[i]:SetVerticalAlignment(TEXT_ALIGN_CENTER)
		AIRG_UI.columnFooters[i]:SetColor(1, 1, 0.4, 1);    -- faded yellow

	end

	-- BUILD LABEL FOR COLUMN FOOTER "TRAIT LINE"
	AIRG_UI.columnFooterTitle = WINDOW_MANAGER:CreateControl("$(parent)ColumnFooterTitleLabel", AIResearchGrid, CT_LABEL)
	AIRG_UI.columnFooterTitle:SetAnchor(TOPLEFT, AIResearchGrid, TOPLEFT, 5, 606)
	AIRG_UI.columnFooterTitle:SetDimensions(180, 24)
	AIRG_UI.columnFooterTitle:SetFont("ZoFontGame")
	AIRG_UI.columnFooterTitle:SetHorizontalAlignment(TEXT_ALIGN_RIGHT)
	AIRG_UI.columnFooterTitle:SetVerticalAlignment(TEXT_ALIGN_CENTER)
	AIRG_UI.columnFooterTitle:SetColor(1, 1, 0.4, 1);       -- faded yellow
	AIRG_UI.columnFooterTitle:SetText(GetString(SI_CRAFTING_COMPONENT_TOOLTIP_TRAITS))   -- "Traits"

	-- BUILD THE MOTIF ICONS ACROSS THE BOTTOM
	-- It's set-up inside a container frame to make hiding or showing the whole lot simpler.
	AIRG_UI.motifSection = WINDOW_MANAGER:CreateControl("$(parent)MotifSection", AIResearchGrid, CT_CONTROL)
	AIRG_UI.motifSection:SetDimensions(750, 240)
	AIRG_UI.motifSection:SetAnchor(TOP, AIRG_UI.BottomDivider, BOTTOM, 0, 10)

	AIRG_UI.StyleButtons = {}

	local yStyleAnchor = 50
	local xStyleAnchor = 1
	local xStyleAnchorAlign = 80
	local secondLine1stIndex = 16
	local thirdLine1stIndex = 31

	local styleItemCtr, styleStoreCtr, styleChapterCtr = 1, 1, 1
	local styleId, styleData

	local ctr
	for ctr = 1, #styleOrder do
		styleId = styleOrder[ctr]
		styleData = styles[styleId]

--	for styleId, styleData in pairs(styles) do

		if not styleData.api or apiVersion >= styleData.api then

			local stoneItemLink = GetItemStyleMaterialLink(styleId)
			local itemName = zo_strformat(SI_TOOLTIP_ITEM_NAME, GetItemLinkName(stoneItemLink))
			local stoneTexture = GetItemLinkInfo(stoneItemLink)


			if styleData.stype == AIRG_STYLE_BASIC then

				AIRG_UI.StyleButtons[styleId] = WINDOW_MANAGER:CreateControl("$(parent)StyleButton" .. tostring(styleId), AIRG_UI.motifSection, CT_TEXTURE)
				AIRG_UI.StyleButtons[styleId]:SetDimensions(40, 40)
				AIRG_UI.StyleButtons[styleId]:SetAnchor(TOPLEFT, AIRG_UI.motifSection, TOPLEFT, 40 * styleItemCtr + 40, 0)
				AIRG_UI.StyleButtons[styleId]:SetTexture(stoneTexture)
				AIRG_UI.StyleButtons[styleId]:SetMouseEnabled(true)
				AIRG_UI.StyleButtons[styleId]:SetHandler("OnMouseExit", function (self)
					ZO_Tooltips_HideTextTooltip()
				end)

				styleItemCtr = styleItemCtr + 1

			elseif styleData.stype == AIRG_STYLE_CROWNSTORE then

				AIRG_UI.StyleButtons[styleId] = WINDOW_MANAGER:CreateControl("$(parent)StyleButton" .. tostring(styleId), AIRG_UI.motifSection, CT_TEXTURE)
				AIRG_UI.StyleButtons[styleId]:SetDimensions(40, 40)
				AIRG_UI.StyleButtons[styleId]:SetAnchor(TOPLEFT, AIRG_UI.motifSection, TOPLEFT, 10, styleStoreCtr * 50 - 50)
				AIRG_UI.StyleButtons[styleId]:SetTexture(stoneTexture)
				AIRG_UI.StyleButtons[styleId]:SetMouseEnabled(true)
				AIRG_UI.StyleButtons[styleId]:SetHandler("OnMouseExit", function (self)
					ZO_Tooltips_HideTextTooltip()
				end)

				styleStoreCtr = styleStoreCtr + 1

			elseif styleData.stype == AIRG_STYLE_CHAPTERIZED then

				if styleChapterCtr == secondLine1stIndex then
					xStyleAnchor = 1
					yStyleAnchor = 90
					xStyleAnchorAlign = 80
				end

				if styleChapterCtr == thirdLine1stIndex then
					xStyleAnchor = 1
					yStyleAnchor = 130
					xStyleAnchorAlign = 100
				end

				AIRG_UI.StyleButtons[styleId] = WINDOW_MANAGER:CreateControl("$(parent)StyleButton" .. tostring(styleId), AIRG_UI.motifSection, CT_TEXTURE)
				AIRG_UI.StyleButtons[styleId]:SetDimensions(32, 32)
				AIRG_UI.StyleButtons[styleId]:SetAnchor(TOPLEFT, AIRG_UI.motifSection, TOPLEFT, 35 * xStyleAnchor + xStyleAnchorAlign, yStyleAnchor)
				AIRG_UI.StyleButtons[styleId]:SetTexture(stoneTexture)
				AIRG_UI.StyleButtons[styleId]:SetMouseEnabled(true)
				AIRG_UI.StyleButtons[styleId]:SetHandler("OnMouseExit", function (self)
					ZO_Tooltips_HideTextTooltip()
				end)

				xStyleAnchor = xStyleAnchor + 1
				styleChapterCtr = styleChapterCtr + 1

			end
		end
	end

end

local function CleanSV()

	if not db.styleId then

		for charName, charData in pairs(db.char) do
			if charData.id then
				charData.styles = {}
				for styleId, styleData in pairs(styles) do
					if styleData.stype == AIRG_STYLE_CHAPTERIZED then
						charData.styles[styleId] = {false, false, false, false, false, false, false, false, false, false, false, false, false, false}
					else
						charData.styles[styleId] = false
					end
				end
				charData.StyleSingle = nil
				charData.StyleChapter = nil
				charData.StyleStore = nil
			end
		end

		db.char[mergedCharacters] = nil
		db.styleId = true

	end

end

local function OnAddonLoaded(_, addonName)

	-- Only initialize our own addon
	if ADDON_NAME == addonName then

		SLASH_COMMANDS["/airg"] = ToggleMainWindow

		-- Load the saved variables
		db = ZO_SavedVars:NewAccountWide("AIRG_SavedVariables", 4, nil, defaults)

		if db.currentCraft then
			currentCraft = db.currentCraft
		end

		-- Register Keybinding
		ZO_CreateStringId("SI_BINDING_NAME_TOGGLE_AIRG", GetString(AIRG_KEYBIND_TOGGLE))

		apiVersion = GetAPIVersion()

		-- Character renamed
		if NAME_CHANGE:DidNameChange() then
			db.char[GetUnitName("player")] = db.char[NAME_CHANGE:GetOldCharacterName()]
			db.char[NAME_CHANGE:GetOldCharacterName()] = nil
		end

		-- Add id to protect
		for i = 1, GetNumCharacters() do
			local name, _, _, _, _, _, characterId = GetCharacterInfo(i)
			name = zo_strformat(SI_UNIT_NAME, name)
			if db.char[name] and not db.char[name].id then
				db.char[name].id = characterId
			end
		end

		-- No id = Char deleted
		for charName, charData in pairs(db.char) do
			if charName ~= mergedCharacters and charName ~= GetUnitName("player") and not charData.id then
				db.char[charName] = nil
			end
		end

		-- UI set-up. Create frames, position labels & buttons etc
		InitUI()

		CleanSV()

		EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_SMITHING_TRAIT_RESEARCH_TIMES_UPDATED, BuildMatrix)
		EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_SMITHING_TRAIT_RESEARCH_STARTED, BuildMatrix)
		EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_SMITHING_TRAIT_RESEARCH_COMPLETED, BuildMatrix)

		EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_SKILLS_FULL_UPDATE, BuildMatrix)

		EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_PLAYER_ACTIVATED, BuildMatrix)
		EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_STYLE_LEARNED, BuildMatrix)

		SCENE_MANAGER:RegisterTopLevel(AIResearchGrid, false)		-- enables close on Esc
		EVENT_MANAGER:UnregisterForEvent(ADDON_NAME, EVENT_ADD_ON_LOADED)

	end

end

function AIRG_ToggleMainWindow()
	ToggleMainWindow()
end

-- AM - Achieve links from styles - added this function
function AIRG_ProcessRightClick(control, mButton)
	if control == nil or mButton ~= MOUSE_BUTTON_INDEX_RIGHT then
		return
	end

	-- just in case this somehow gets called when the motif has no chapters (1-14, ebony, frostcaster, etc.)
	if control.chapVal == nil then
		d("This Motif has no chapters")
		return
	end

	-- we're now pretty sure it's a motif icon, put up a menu

	zo_callLater(function()
		ClearMenu()
		AddCustomMenuItem("Paste Achieve", function()
			local motifStr = "|H1:achievement:" .. control.achieve .. ":" .. control.chapVal .. ":0|h|h"
			ZO_ChatWindowTextEntryEditBox:SetText(ZO_ChatWindowTextEntryEditBox:GetText() .. " " .. motifStr)

			end, MENU_ADD_OPTION_LABEL)
		ShowMenu(control)
		end, 50
		)
end
-- AM - Achieve links from styles - new function end

EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_ADD_ON_LOADED, OnAddonLoaded)
