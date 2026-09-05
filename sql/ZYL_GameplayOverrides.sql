-------------------------------------------------------------------------------
-- ZYLPVPMOD gameplay integration overrides
--
-- This file loads after every embedded BBG gameplay action.  It deliberately
-- owns the requested Team PVP / Lightweight Balance hybrid rules so later
-- upstream reordering cannot silently restore the BBG values.
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Restore vanilla unit obsolescence rules
-------------------------------------------------------------------------------

-- BBG advances the mandatory-obsolescence point of these official units.  The
-- integrated ruleset keeps BBG's other unit balance changes, but restores all
-- four obsolescence fields to their Firaxis values.  BBG Expanded units are
-- intentionally excluded because they have no vanilla value to restore.
UPDATE Units
SET MandatoryObsoleteTech = NULL,
	MandatoryObsoleteCivic = NULL,
	ObsoleteTech = NULL,
	ObsoleteCivic = NULL
WHERE UnitType IN (
	'UNIT_WARRIOR',
	'UNIT_HEAVY_CHARIOT',
	'UNIT_SWORDSMAN',
	'UNIT_ROMAN_LEGION',
	'UNIT_KONGO_SHIELD_BEARER',
	'UNIT_JAPANESE_SAMURAI',
	'UNIT_NORWEGIAN_BERSERKER',
	'UNIT_KNIGHT',
	'UNIT_ARABIAN_MAMLUK',
	'UNIT_MUSKETMAN',
	'UNIT_SPANISH_CONQUISTADOR',
	'UNIT_MAN_AT_ARMS',
	'UNIT_AZTEC_EAGLE_WARRIOR',
	'UNIT_KHMER_DOMREY',
	'UNIT_MACEDONIAN_HYPASPIST',
	'UNIT_INDIAN_VARU',
	'UNIT_MACEDONIAN_HETAIROI',
	'UNIT_PERSIAN_IMMORTAL',
	'UNIT_GEORGIAN_KHEVSURETI',
	'UNIT_MALI_MANDEKALU_CAVALRY',
	'UNIT_MAORI_TOA',
	'UNIT_SULEIMAN_JANISSARY',
	'UNIT_BYZANTINE_TAGMA',
	'UNIT_GAUL_GAESATAE',
	'UNIT_BABYLONIAN_SABUM_KIBITTUM',
	'UNIT_MAPUCHE_MALON_RAIDER',
	'UNIT_BATTERING_RAM',
	'UNIT_SIEGE_TOWER'
);

UPDATE Units
SET MandatoryObsoleteTech = 'TECH_GUNPOWDER'
WHERE UnitType IN (
	'UNIT_WARRIOR',
	'UNIT_BABYLONIAN_SABUM_KIBITTUM'
);

UPDATE Units
SET MandatoryObsoleteTech = 'TECH_REPLACEABLE_PARTS'
WHERE UnitType IN (
	'UNIT_SWORDSMAN',
	'UNIT_ROMAN_LEGION',
	'UNIT_KONGO_SHIELD_BEARER',
	'UNIT_JAPANESE_SAMURAI',
	'UNIT_NORWEGIAN_BERSERKER',
	'UNIT_MAN_AT_ARMS',
	'UNIT_MACEDONIAN_HYPASPIST',
	'UNIT_MACEDONIAN_HETAIROI',
	'UNIT_PERSIAN_IMMORTAL',
	'UNIT_GEORGIAN_KHEVSURETI',
	'UNIT_MAORI_TOA',
	'UNIT_GAUL_GAESATAE'
);

UPDATE Units
SET MandatoryObsoleteTech = 'TECH_COMBUSTION'
WHERE UnitType IN (
	'UNIT_HEAVY_CHARIOT',
	'UNIT_INDIAN_VARU'
);

UPDATE Units
SET MandatoryObsoleteTech = 'TECH_COMPOSITES'
WHERE UnitType IN (
	'UNIT_KNIGHT',
	'UNIT_ARABIAN_MAMLUK',
	'UNIT_MALI_MANDEKALU_CAVALRY',
	'UNIT_BYZANTINE_TAGMA'
);

UPDATE Units
SET MandatoryObsoleteTech = 'TECH_ADVANCED_BALLISTICS'
WHERE UnitType IN (
	'UNIT_MUSKETMAN',
	'UNIT_SPANISH_CONQUISTADOR',
	'UNIT_SULEIMAN_JANISSARY'
);

UPDATE Units
SET MandatoryObsoleteTech = 'TECH_GUIDANCE_SYSTEMS'
WHERE UnitType = 'UNIT_KHMER_DOMREY';

UPDATE Units
SET ObsoleteCivic = 'CIVIC_CIVIL_ENGINEERING'
WHERE UnitType IN (
	'UNIT_BATTERING_RAM',
	'UNIT_SIEGE_TOWER'
);

-------------------------------------------------------------------------------
-- City-founding Housing and Maya
-------------------------------------------------------------------------------

-- Team PVP / Lightweight Balance baseline: fresh-water cities stay at 5,
-- while coast-only and no-water cities increase from 3/2 to 4/3.
UPDATE GlobalParameters
SET Value = '3'
WHERE Name = 'CITY_POPULATION_NO_WATER';

UPDATE GlobalParameters
SET Value = '4'
WHERE Name = 'CITY_POPULATION_COAST';

-- Mayab ignores water-source Housing, so the 3-point no-water baseline applies
-- to every Maya city.  Make BBG's existing +1 Housing modifier affect all
-- cities instead of only the capital: Maya secondary cities therefore start
-- with 4 Housing, while the Palace still gives the capital its normal +1.
UPDATE Modifiers
SET ModifierType = 'MODIFIER_PLAYER_CITIES_ADJUST_BUILDING_HOUSING'
WHERE ModifierId = 'BBG_MAYA_CAPITAL_HOUSING';

-------------------------------------------------------------------------------
-- Technology era scaling and the early naval path
-------------------------------------------------------------------------------

-- Team PVP rule: technologies from an era earlier than the current game era
-- cost 25% less.  BBG's +30% penalty for technologies ahead of the current
-- era remains unchanged.
UPDATE GlobalParameters
SET Value = '-25'
WHERE Name = 'TECH_COST_PERCENT_CHANGE_BEFORE_GAME_ERA';

-- Make Celestial Navigation directly available after Sailing while keeping
-- this mod's embarkation unlock for every land unit.  Delete all upstream
-- prerequisites first so Astrology cannot be reintroduced by BBG/BBM layers.
DELETE FROM TechnologyPrereqs
WHERE Technology = 'TECH_CELESTIAL_NAVIGATION';

INSERT OR IGNORE INTO TechnologyPrereqs (Technology, PrereqTech) VALUES
	('TECH_CELESTIAL_NAVIGATION', 'TECH_SAILING');

UPDATE Technologies
SET EmbarkAll = 1,
	Description = 'LOC_TECH_ZYL_CELESTIAL_NAVIGATION_DESCRIPTION'
WHERE TechnologyType = 'TECH_CELESTIAL_NAVIGATION';

-- Maori: early Mana bonuses and resource harvesting
-------------------------------------------------------------------------------

-- BBG's embarked-unit movement modifier is still the correct +2 bonus; only
-- its unlock is moved forward from Shipbuilding to Sailing.
UPDATE Modifiers
SET OwnerRequirementSetId = 'BBG_UTILS_PLAYER_HAS_TECH_SAILING'
WHERE ModifierId = 'TRAIT_MAORI_EMBARKED_ABILITY';

-- Keep BBG's "unimproved Woods / Rainforest" scope and unlock its first
-- +1 Production tier at Early Empire.
UPDATE Modifiers
SET SubjectRequirementSetId = 'BBG_PLOT_HAS_FOREST_EARLY_EMPIRE'
WHERE ModifierId = 'TRAIT_MAORI_PRODUCTION_WOODS';

UPDATE Modifiers
SET SubjectRequirementSetId = 'BBG_PLOT_HAS_JUNGLE_EARLY_EMPIRE'
WHERE ModifierId = 'TRAIT_MAORI_PRODUCTION_RAINFOREST';

-- Remove Mana's vanilla ban on harvesting bonus resources.  Deleting only
-- the trait attachment leaves the shared modifier definition intact and
-- restores the normal Builder harvest actions for Maori players.
DELETE FROM TraitModifiers
WHERE TraitType = 'TRAIT_CIVILIZATION_MAORI_MANA'
	AND ModifierId = 'TRAIT_MAORI_PREVENT_HARVEST';

-------------------------------------------------------------------------------
-- Melee unit production and iron costs
-------------------------------------------------------------------------------

-- Swordsmen and their unique replacements are 10 Production cheaper and use
-- 5 fewer Iron.  The Maori Toa is handled separately: it keeps its no-Iron
-- rule and receives the requested additional 20 Production reduction.
UPDATE Units
SET Cost = 80
WHERE UnitType = 'UNIT_SWORDSMAN';

UPDATE Units
SET Cost = 100
WHERE UnitType IN (
	'UNIT_ROMAN_LEGION',
	'UNIT_KONGO_SHIELD_BEARER'
);

UPDATE Units
SET Cost = 90
WHERE UnitType IN (
	'UNIT_MACEDONIAN_HYPASPIST',
	'UNIT_PERSIAN_IMMORTAL'
);

UPDATE Units_XP2
SET ResourceCost = 10
WHERE UnitType = 'UNIT_SWORDSMAN';

UPDATE Units_XP2
SET ResourceCost = 5
WHERE UnitType IN (
	'UNIT_ROMAN_LEGION',
	'UNIT_KONGO_SHIELD_BEARER',
	'UNIT_MACEDONIAN_HYPASPIST',
	'UNIT_PERSIAN_IMMORTAL'
);

-------------------------------------------------------------------------------
-- Aztec Eagle Warrior: Swordsman unique replacement
-------------------------------------------------------------------------------

UPDATE Units
SET PrereqTech = 'TECH_IRON_WORKING',
	PrereqCivic = NULL,
	Cost = 100,
	Maintenance = 2,
	Combat = 38,
	StrategicResource = 'RESOURCE_IRON',
	MandatoryObsoleteTech = 'TECH_REPLACEABLE_PARTS'
WHERE UnitType = 'UNIT_AZTEC_EAGLE_WARRIOR';

INSERT OR IGNORE INTO Units_XP2 (UnitType, ResourceCost)
SELECT UnitType, 5
FROM Units
WHERE UnitType = 'UNIT_AZTEC_EAGLE_WARRIOR';

UPDATE Units_XP2
SET ResourceCost = 5
WHERE UnitType = 'UNIT_AZTEC_EAGLE_WARRIOR';

UPDATE UnitReplaces
SET ReplacesUnitType = 'UNIT_SWORDSMAN'
WHERE CivUniqueUnitType = 'UNIT_AZTEC_EAGLE_WARRIOR';

UPDATE UnitUpgrades
SET UpgradeUnit = 'UNIT_MAN_AT_ARMS'
WHERE Unit = 'UNIT_AZTEC_EAGLE_WARRIOR';

-- This BBG tag applies only to Ancient-era units.  CLASS_CAPTURE_WORKER is
-- deliberately retained so defeated military units can still become Builders.
DELETE FROM TypeTags
WHERE Type = 'UNIT_AZTEC_EAGLE_WARRIOR'
  AND Tag = 'CLASS_MALUS_CITY_CENTER';

INSERT OR IGNORE INTO TypeTags (Type, Tag)
SELECT UnitType, 'CLASS_CAPTURE_WORKER'
FROM Units
WHERE UnitType = 'UNIT_AZTEC_EAGLE_WARRIOR';

-- Toa is handled separately: it has no strategic-resource cost, and its
-- production cost is reduced by 20.
UPDATE Units
SET Cost = 100
WHERE UnitType = 'UNIT_MAORI_TOA';

-- Man-at-Arms and all of its unique replacements are 10 Production cheaper.
UPDATE Units
SET Cost = 150
WHERE UnitType IN (
	'UNIT_MAN_AT_ARMS',
	'UNIT_JAPANESE_SAMURAI',
	'UNIT_NORWEGIAN_BERSERKER',
	'UNIT_GEORGIAN_KHEVSURETI'
);

-------------------------------------------------------------------------------
-- Eureka and Inspiration triggers
-------------------------------------------------------------------------------

-- Political Philosophy requires meeting two city-states.
UPDATE Boosts
SET NumItems = 2
WHERE CivicType = 'CIVIC_POLITICAL_PHILOSOPHY';

-- Lightweight Balance: Archery requires owning two Slingers.
UPDATE Boosts
SET BoostClass = 'BOOST_TRIGGER_OWN_X_UNITS_OF_TYPE',
	Unit1Type = 'UNIT_SLINGER',
	NumItems = 2,
	Unit2Type = NULL,
	BuildingType = NULL,
	ImprovementType = NULL,
	BoostingTechType = NULL,
	ResourceType = NULL,
	DistrictType = NULL,
	RequiresResource = 0,
	RequirementSetId = NULL,
	GovernmentSlotType = NULL,
	BoostingCivicType = NULL,
	GovernmentTierType = NULL
WHERE TechnologyType = 'TECH_ARCHERY';

-- Lightweight Balance: Bronze Working requires three land combat units.
UPDATE Boosts
SET BoostClass = 'BOOST_TRIGGER_HAVE_X_LAND_UNITS',
	Unit1Type = NULL,
	Unit2Type = NULL,
	BuildingType = NULL,
	ImprovementType = NULL,
	BoostingTechType = NULL,
	ResourceType = NULL,
	NumItems = 3,
	DistrictType = NULL,
	RequiresResource = 0,
	RequirementSetId = NULL,
	GovernmentSlotType = NULL,
	BoostingCivicType = NULL,
	GovernmentTierType = NULL
WHERE TechnologyType = 'TECH_BRONZE_WORKING';

-- Lightweight Balance: Games and Recreation requires Horseback Riding.
UPDATE Boosts
SET BoostClass = 'BOOST_TRIGGER_RESEARCH_TECH',
	BoostingTechType = 'TECH_HORSEBACK_RIDING',
	Unit1Type = NULL,
	Unit2Type = NULL,
	BuildingType = NULL,
	ImprovementType = NULL,
	ResourceType = NULL,
	NumItems = 0,
	DistrictType = NULL,
	RequiresResource = 0,
	RequirementSetId = NULL,
	GovernmentSlotType = NULL,
	BoostingCivicType = NULL,
	GovernmentTierType = NULL
WHERE CivicType = 'CIVIC_GAMES_RECREATION';

-- Lightweight Balance: Recorded History requires one Library.
UPDATE Boosts
SET BoostClass = 'BOOST_TRIGGER_HAVE_X_BUILDINGS',
	BuildingType = 'BUILDING_LIBRARY',
	NumItems = 1,
	Unit1Type = NULL,
	Unit2Type = NULL,
	ImprovementType = NULL,
	BoostingTechType = NULL,
	ResourceType = NULL,
	DistrictType = NULL,
	RequiresResource = 0,
	RequirementSetId = NULL,
	GovernmentSlotType = NULL,
	BoostingCivicType = NULL,
	GovernmentTierType = NULL
WHERE CivicType = 'CIVIC_RECORDED_HISTORY';

-- Lightweight Balance: Humanism requires one Amphitheater.
UPDATE Boosts
SET BoostClass = 'BOOST_TRIGGER_HAVE_X_BUILDINGS',
	BuildingType = 'BUILDING_AMPHITHEATER',
	NumItems = 1,
	Unit1Type = NULL,
	Unit2Type = NULL,
	ImprovementType = NULL,
	BoostingTechType = NULL,
	ResourceType = NULL,
	DistrictType = NULL,
	RequiresResource = 0,
	RequirementSetId = NULL,
	GovernmentSlotType = NULL,
	BoostingCivicType = NULL,
	GovernmentTierType = NULL
WHERE CivicType = 'CIVIC_HUMANISM';

-- Team PVP: Military Tactics requires two Spearmen.
UPDATE Boosts
SET BoostClass = 'BOOST_TRIGGER_OWN_X_UNITS_OF_TYPE',
	Unit1Type = 'UNIT_SPEARMAN',
	NumItems = 2,
	Unit2Type = NULL,
	BuildingType = NULL,
	ImprovementType = NULL,
	BoostingTechType = NULL,
	ResourceType = NULL,
	DistrictType = NULL,
	RequiresResource = 0,
	RequirementSetId = NULL,
	GovernmentSlotType = NULL,
	BoostingCivicType = NULL,
	GovernmentTierType = NULL
WHERE TechnologyType = 'TECH_MILITARY_TACTICS';

-- Team PVP: Naval Tradition requires two Quadriremes.
UPDATE Boosts
SET BoostClass = 'BOOST_TRIGGER_OWN_X_UNITS_OF_TYPE',
	Unit1Type = 'UNIT_QUADRIREME',
	NumItems = 2,
	Unit2Type = NULL,
	BuildingType = NULL,
	ImprovementType = NULL,
	BoostingTechType = NULL,
	ResourceType = NULL,
	DistrictType = NULL,
	RequiresResource = 0,
	RequirementSetId = NULL,
	GovernmentSlotType = NULL,
	BoostingCivicType = NULL,
	GovernmentTierType = NULL
WHERE CivicType = 'CIVIC_NAVAL_TRADITION';

-- Team PVP: Feudalism requires five Farms.
UPDATE Boosts
SET BoostClass = 'BOOST_TRIGGER_HAVE_X_IMPROVEMENTS',
	ImprovementType = 'IMPROVEMENT_FARM',
	NumItems = 5,
	RequiresResource = 0,
	Unit1Type = NULL,
	Unit2Type = NULL,
	BuildingType = NULL,
	BoostingTechType = NULL,
	ResourceType = NULL,
	DistrictType = NULL,
	RequirementSetId = NULL,
	GovernmentSlotType = NULL,
	BoostingCivicType = NULL,
	GovernmentTierType = NULL
WHERE CivicType = 'CIVIC_FEUDALISM';

-------------------------------------------------------------------------------
-- Commercial Hub adjacency
-------------------------------------------------------------------------------

-- Each adjacent Luxury resource provides +1 Gold to a Commercial Hub or any
-- unique district that replaces it.
INSERT OR IGNORE INTO Adjacency_YieldChanges
	(ID, Description, YieldType, YieldChange, TilesRequired, AdjacentResourceClass)
VALUES
	('ZYL_COMMERCIAL_HUB_LUXURY_GOLD', 'LOC_DISTRICT_ZYL_COMMERCIAL_HUB_LUXURY_GOLD', 'YIELD_GOLD', 1, 1, 'RESOURCECLASS_LUXURY');

INSERT OR IGNORE INTO District_Adjacencies (DistrictType, YieldChangeId)
	SELECT DistrictType, 'ZYL_COMMERCIAL_HUB_LUXURY_GOLD'
	FROM Districts
	WHERE DistrictType = 'DISTRICT_COMMERCIAL_HUB'
	   OR DistrictType IN (
			SELECT CivUniqueDistrictType
			FROM DistrictReplaces
			WHERE ReplacesDistrictType = 'DISTRICT_COMMERCIAL_HUB'
	   );

-------------------------------------------------------------------------------
-- Gaul: move the existing Mine Culture bonus to the civilization
-------------------------------------------------------------------------------

-- BBG gives GAUL_MINE_CULTURE to Vercingetorix at Bronze Working.  Reuse that
-- modifier as a Gaul civilization ability at the same technology so there is only
-- one +1 Culture bonus, regardless of which leader commands Gaul.
DELETE FROM TraitModifiers
WHERE TraitType = 'TRAIT_LEADER_SUK_GALLIC_WAR'
  AND ModifierId = 'GAUL_MINE_CULTURE';

UPDATE Modifiers
SET ModifierType = 'MODIFIER_PLAYER_ADJUST_PLOT_YIELD',
	OwnerRequirementSetId = 'BBG_UTILS_PLAYER_HAS_TECH_BRONZE_WORKING',
	SubjectRequirementSetId = 'PLOT_HAS_MINE_REQUIREMENTS'
WHERE ModifierId = 'GAUL_MINE_CULTURE';

INSERT OR REPLACE INTO ModifierArguments (ModifierId, Name, Value) VALUES
	('GAUL_MINE_CULTURE', 'YieldType', 'YIELD_CULTURE'),
	('GAUL_MINE_CULTURE', 'Amount', 1);

INSERT OR IGNORE INTO TraitModifiers (TraitType, ModifierId) VALUES
	('TRAIT_CIVILIZATION_GAUL', 'GAUL_MINE_CULTURE');

-------------------------------------------------------------------------------
-- Trajan: grant the free City Center building after Foreign Trade
-------------------------------------------------------------------------------

-- BBG 7.4.6 delays Trajan's Column until Early Empire.  Move the existing
-- Firaxis modifier back to the earlier BBG-generated Foreign Trade requirement.
UPDATE Modifiers
SET SubjectRequirementSetId = 'BBG_UTILS_PLAYER_HAS_CIVIC_FOREIGN_TRADE_REQSET'
WHERE ModifierId = 'TRAIT_ADJUST_NON_CAPITAL_FREE_CHEAPEST_BUILDING';

-------------------------------------------------------------------------------
-- Gran Colombia: restore the original all-unit movement bonus
-------------------------------------------------------------------------------

-- BBG replaced Ejército Patriota with a military-only modifier gated behind
-- Political Philosophy.  The Firaxis grant-ability chain already exists in
-- the Gran Colombia DLC database, so only its civilization-trait attachment
-- needs to be restored.
DELETE FROM TraitModifiers
WHERE TraitType = 'TRAIT_CIVILIZATION_EJERCITO_PATRIOTA'
  AND ModifierId = 'BBG_COLUMBIA_MOVEMENT_BONUS';

INSERT OR IGNORE INTO TraitModifiers (TraitType, ModifierId) VALUES
	('TRAIT_CIVILIZATION_EJERCITO_PATRIOTA', 'TRAIT_EJERCITO_PATRIOTA_EXTRA_MOVEMENT');

-------------------------------------------------------------------------------
-- Khmer: standard Holy Site adjacency from Rivers
-------------------------------------------------------------------------------

-- BBG removes Jayavarman's river-Faith adjacency.  Restore a standard +1
-- Faith version on the Khmer civilization trait so every Khmer leader shares
-- it and the old leader modifier cannot stack with it.
DELETE FROM TraitModifiers
WHERE TraitType = 'TRAIT_LEADER_MONASTERIES_KING'
  AND ModifierId = 'TRAIT_MONASTERIES_KING_HOLY_SITE_RIVER_ADJACENCY';

INSERT OR IGNORE INTO Modifiers (ModifierId, ModifierType) VALUES
	('ZYL_KHMER_HOLY_SITE_RIVER_FAITH', 'MODIFIER_PLAYER_CITIES_RIVER_ADJACENCY');

UPDATE Modifiers
SET ModifierType = 'MODIFIER_PLAYER_CITIES_RIVER_ADJACENCY',
	OwnerRequirementSetId = NULL,
	SubjectRequirementSetId = NULL
WHERE ModifierId = 'ZYL_KHMER_HOLY_SITE_RIVER_FAITH';

INSERT OR REPLACE INTO ModifierArguments (ModifierId, Name, Value) VALUES
	('ZYL_KHMER_HOLY_SITE_RIVER_FAITH', 'Amount', 1),
	('ZYL_KHMER_HOLY_SITE_RIVER_FAITH', 'Description', 'LOC_DISTRICT_RIVER_FAITH'),
	('ZYL_KHMER_HOLY_SITE_RIVER_FAITH', 'DistrictType', 'DISTRICT_HOLY_SITE'),
	('ZYL_KHMER_HOLY_SITE_RIVER_FAITH', 'YieldType', 'YIELD_FAITH');

INSERT OR IGNORE INTO TraitModifiers (TraitType, ModifierId) VALUES
	('TRAIT_CIVILIZATION_KHMER_BARAYS', 'ZYL_KHMER_HOLY_SITE_RIVER_FAITH');

-- Poundmaker: restore outgoing Camp/Pasture Food to +1 per improvement
-------------------------------------------------------------------------------

-- The two Food modifiers use Origin=true; the separate Destination=true Gold
-- modifiers intentionally remain at +1.  The native effect counts all matching
-- improvements in the target city and has no reliable per-type count cap.
UPDATE ModifierArguments
SET Value = 1
WHERE ModifierId IN (
	'TRAIT_TRADE_FOOD_FROM_CAMPS',
	'TRAIT_TRADE_FOOD_FROM_PASTURES'
  )
  AND Name = 'Amount';

-------------------------------------------------------------------------------
-- Mali: final civilization and leader rules
-------------------------------------------------------------------------------

-- Do not restore either the original -30% unit/building penalties or BBG's
-- replacement -5% city-wide Production penalty.  The Foreign Trade city-center
-- Faith package and Banking trade-route replacement are also intentionally
-- disabled by the final rules.
DELETE FROM TraitModifiers
WHERE TraitType = 'TRAIT_CIVILIZATION_MALI_GOLD_DESERT'
  AND ModifierId IN (
	'TRAIT_LESS_UNIT_PRODUCTION',
	'TRAIT_LESS_BUILDING_PRODUCTION',
	'BBG_TRAIT_MALI_LESS_CITY_PRODUCTION',
	'BBG_MALI_FAITH_NEXT_DESERT',
	'BBG_MALI_FAITH_NEXT_DESERT_HILLS',
	'BBG_MALI_FAITH_NEXT_CAPITAL'
  );

DELETE FROM TraitModifiers
WHERE TraitType = 'TRAIT_LEADER_SAHEL_MERCHANTS'
  AND ModifierId = 'TRAIT_BBG_MANSA_FREE_TRADER_BANKS';

-- Remove the superseded featureless-Desert Faith, Desert-only Mine Gold and
-- Mansa Musa Holy Site Production modifiers if an upstream source restores
-- any of them.  The final Mine modifiers below use the Firaxis all-Mines scope.
DELETE FROM TraitModifiers
WHERE TraitType = 'TRAIT_CIVILIZATION_MALI_GOLD_DESERT'
  AND ModifierId IN (
	'TRAIT_DESERT_CITY_CENTER_FAITH',
	'TRAIT_DESERT_HILLS_CITY_CENTER_FAITH',
	'ZYL_MALI_FAITH_DESERT',
	'ZYL_MALI_FAITH_DESERT_HILLS',
	'BBG_MALI_GOLD_DESERT_MINES',
	'BBG_MALI_GOLD_DESERT_HILLS_MINES'
  );

DELETE FROM TraitModifiers
WHERE TraitType = 'TRAIT_LEADER_SAHEL_MERCHANTS'
  AND ModifierId IN (
	'BBG_MANSA_HOLY_SITE_BONUS_PRODUCTION',
	'BBG_MANSA_HOLY_SITE_BONUS_PRODUCTION_BUILDING'
  );

-- A City Center founded directly on flat Desert or Desert Hills gains a flat
-- +2 Faith.  This is deliberately not the original per-adjacent-Desert rule.
INSERT OR IGNORE INTO RequirementSets (RequirementSetId, RequirementSetType) VALUES
	('ZYL_MALI_DESERT_CITY_CENTER_REQUIREMENTS', 'REQUIREMENTSET_TEST_ALL'),
	('ZYL_MALI_DESERT_HILLS_CITY_CENTER_REQUIREMENTS', 'REQUIREMENTSET_TEST_ALL');

INSERT OR IGNORE INTO Requirements (RequirementId, RequirementType) VALUES
	('ZYL_MALI_REQUIRES_PLOT_IS_CITY_CENTER', 'REQUIREMENT_PLOT_DISTRICT_TYPE_MATCHES');

INSERT OR IGNORE INTO RequirementArguments (RequirementId, Name, Value) VALUES
	('ZYL_MALI_REQUIRES_PLOT_IS_CITY_CENTER', 'DistrictType', 'DISTRICT_CITY_CENTER');

INSERT OR IGNORE INTO RequirementSetRequirements (RequirementSetId, RequirementId) VALUES
	('ZYL_MALI_DESERT_CITY_CENTER_REQUIREMENTS', 'REQUIRES_PLOT_HAS_DESERT'),
	('ZYL_MALI_DESERT_CITY_CENTER_REQUIREMENTS', 'ZYL_MALI_REQUIRES_PLOT_IS_CITY_CENTER'),
	('ZYL_MALI_DESERT_HILLS_CITY_CENTER_REQUIREMENTS', 'REQUIRES_PLOT_HAS_DESERT_HILLS'),
	('ZYL_MALI_DESERT_HILLS_CITY_CENTER_REQUIREMENTS', 'ZYL_MALI_REQUIRES_PLOT_IS_CITY_CENTER');

INSERT OR IGNORE INTO Modifiers (ModifierId, ModifierType, SubjectRequirementSetId) VALUES
	('ZYL_MALI_DESERT_CITY_CENTER_FAITH', 'MODIFIER_PLAYER_ADJUST_PLOT_YIELD', 'ZYL_MALI_DESERT_CITY_CENTER_REQUIREMENTS'),
	('ZYL_MALI_DESERT_HILLS_CITY_CENTER_FAITH', 'MODIFIER_PLAYER_ADJUST_PLOT_YIELD', 'ZYL_MALI_DESERT_HILLS_CITY_CENTER_REQUIREMENTS');

INSERT OR IGNORE INTO ModifierArguments (ModifierId, Name, Value) VALUES
	('ZYL_MALI_DESERT_CITY_CENTER_FAITH', 'YieldType', 'YIELD_FAITH'),
	('ZYL_MALI_DESERT_CITY_CENTER_FAITH', 'Amount', 2),
	('ZYL_MALI_DESERT_HILLS_CITY_CENTER_FAITH', 'YieldType', 'YIELD_FAITH'),
	('ZYL_MALI_DESERT_HILLS_CITY_CENTER_FAITH', 'Amount', 2);

INSERT OR IGNORE INTO TraitModifiers (TraitType, ModifierId) VALUES
	('TRAIT_CIVILIZATION_MALI_GOLD_DESERT', 'ZYL_MALI_DESERT_CITY_CENTER_FAITH'),
	('TRAIT_CIVILIZATION_MALI_GOLD_DESERT', 'ZYL_MALI_DESERT_HILLS_CITY_CENTER_FAITH'),
	('TRAIT_CIVILIZATION_MALI_GOLD_DESERT', 'TRAIT_MALI_MINES_PRODUCTION'),
	('TRAIT_CIVILIZATION_MALI_GOLD_DESERT', 'TRAIT_MALI_MINES_GOLD');

UPDATE Modifiers
SET SubjectRequirementSetId = 'PLOT_HAS_MINE_REQUIREMENTS'
WHERE ModifierId IN ('TRAIT_MALI_MINES_PRODUCTION', 'TRAIT_MALI_MINES_GOLD');

UPDATE ModifierArguments
SET Value = -1
WHERE ModifierId = 'TRAIT_MALI_MINES_PRODUCTION'
  AND Name = 'Amount';

UPDATE ModifierArguments
SET Value = 4
WHERE ModifierId = 'TRAIT_MALI_MINES_GOLD'
  AND Name = 'Amount';

-- Seed the Firaxis values as well as updating them.  The base XML contains
-- inconsistent trailing whitespace on these IDs in some game builds.
INSERT OR REPLACE INTO ModifierArguments (ModifierId, Name, Value) VALUES
	('TRAIT_MALI_MINES_PRODUCTION', 'YieldType', 'YIELD_PRODUCTION'),
	('TRAIT_MALI_MINES_PRODUCTION', 'Amount', -1),
	('TRAIT_MALI_MINES_GOLD', 'YieldType', 'YIELD_GOLD'),
	('TRAIT_MALI_MINES_GOLD', 'Amount', 4);

UPDATE ModifierArguments
SET Value = 10
WHERE ModifierId IN (
	'SUGUBA_CHEAPER_BUILDING_PURCHASE',
	'SUGUBA_CHEAPER_DISTRICT_PURCHASE',
	'SUGUBA_CHEAPER_UNIT_PURCHASE'
  )
  AND Name = 'Amount';

-------------------------------------------------------------------------------
-- Global Oasis yield
-------------------------------------------------------------------------------

-- This is a base feature yield for every civilization, not part of Mali's
-- trait.  Keep Gold at 1 and raise Food from the Firaxis value of 3 to 4.
INSERT OR IGNORE INTO Feature_YieldChanges (FeatureType, YieldType, YieldChange) VALUES
	('FEATURE_OASIS', 'YIELD_FOOD', 4),
	('FEATURE_OASIS', 'YIELD_GOLD', 1);

UPDATE Feature_YieldChanges
SET YieldChange = 4
WHERE FeatureType = 'FEATURE_OASIS'
  AND YieldType = 'YIELD_FOOD';

UPDATE Feature_YieldChanges
SET YieldChange = 1
WHERE FeatureType = 'FEATURE_OASIS'
  AND YieldType = 'YIELD_GOLD';

-------------------------------------------------------------------------------
-- Scythia: remove a malformed duplicate ability grant
-------------------------------------------------------------------------------

-- The medieval +5 modifier is already attached to the existing
-- ABILITY_TOMYRIS_BONUS_VS_WOUNDED_UNITS below.  BBG also left a
-- MODIFIER_PLAYER_UNITS_GRANT_ABILITY row whose AbilityType was a ModifierId,
-- not a UnitAbilityType; that row can never grant anything and is a runtime
-- orphan.  Remove only the bad giver and keep the valid ability attachment.
DELETE FROM ModifierArguments
WHERE ModifierId = 'BBG_TOMYRIS_BONUS_VS_WOUNDED_UNITS_MEDIEVAL_GIVER';
DELETE FROM Modifiers
WHERE ModifierId = 'BBG_TOMYRIS_BONUS_VS_WOUNDED_UNITS_MEDIEVAL_GIVER';

-------------------------------------------------------------------------------
-- Spain: remove orphaned Mission modifier links
-------------------------------------------------------------------------------

-- BBG deletes these three legacy Modifiers, but its ImprovementModifiers
-- cleanup compares ModifierId to IMPROVEMENT_MISSION instead of comparing
-- ImprovementType.  Remove the dangling links with the intended predicate.
DELETE FROM ImprovementModifiers
WHERE ImprovementType = 'IMPROVEMENT_MISSION'
  AND ModifierId IN (
	'MISSION_NEWCONTINENT_FAITH',
	'MISSION_NEWCONTINENT_FOOD',
	'MISSION_NEWCONTINENT_PRODUCTION'
  );

-------------------------------------------------------------------------------
-- Russia: faith on Tundra adjacent to a Holy Site / Lavra
-------------------------------------------------------------------------------

-- The Lavra replaces the Holy Site, so the adjacency branch must accept both
-- district types.  A wrapper requirement lets each terrain-specific TEST_ALL
-- set consume that OR condition without broadening the bonus to the whole city.
INSERT OR IGNORE INTO RequirementSets (RequirementSetId, RequirementSetType) VALUES
	('ZYL_RUSSIA_PLOT_ADJACENT_HOLY_SITE_OR_LAVRA', 'REQUIREMENTSET_TEST_ANY'),
	('ZYL_RUSSIA_FLAT_TUNDRA_ADJACENT_HOLY_SITE_OR_LAVRA', 'REQUIREMENTSET_TEST_ALL'),
	('ZYL_RUSSIA_TUNDRA_HILLS_ADJACENT_HOLY_SITE_OR_LAVRA', 'REQUIREMENTSET_TEST_ALL');

INSERT OR IGNORE INTO Requirements (RequirementId, RequirementType) VALUES
	('ZYL_RUSSIA_REQUIRES_PLOT_ADJACENT_HOLY_SITE', 'REQUIREMENT_PLOT_ADJACENT_DISTRICT_TYPE_MATCHES'),
	('ZYL_RUSSIA_REQUIRES_PLOT_ADJACENT_LAVRA', 'REQUIREMENT_PLOT_ADJACENT_DISTRICT_TYPE_MATCHES'),
	('ZYL_RUSSIA_REQUIRES_PLOT_ADJACENT_HOLY_SITE_OR_LAVRA', 'REQUIREMENT_REQUIREMENTSET_IS_MET');

INSERT OR IGNORE INTO RequirementArguments (RequirementId, Name, Value) VALUES
	('ZYL_RUSSIA_REQUIRES_PLOT_ADJACENT_HOLY_SITE', 'DistrictType', 'DISTRICT_HOLY_SITE'),
	('ZYL_RUSSIA_REQUIRES_PLOT_ADJACENT_LAVRA', 'DistrictType', 'DISTRICT_LAVRA'),
	('ZYL_RUSSIA_REQUIRES_PLOT_ADJACENT_HOLY_SITE_OR_LAVRA', 'RequirementSetId', 'ZYL_RUSSIA_PLOT_ADJACENT_HOLY_SITE_OR_LAVRA');

-- Make repeated debug/cache loads deterministic if a prior local build used
-- these identifiers with different members.
DELETE FROM RequirementSetRequirements
WHERE RequirementSetId IN (
	'ZYL_RUSSIA_PLOT_ADJACENT_HOLY_SITE_OR_LAVRA',
	'ZYL_RUSSIA_FLAT_TUNDRA_ADJACENT_HOLY_SITE_OR_LAVRA',
	'ZYL_RUSSIA_TUNDRA_HILLS_ADJACENT_HOLY_SITE_OR_LAVRA'
);

INSERT OR IGNORE INTO RequirementSetRequirements (RequirementSetId, RequirementId) VALUES
	('ZYL_RUSSIA_PLOT_ADJACENT_HOLY_SITE_OR_LAVRA', 'ZYL_RUSSIA_REQUIRES_PLOT_ADJACENT_HOLY_SITE'),
	('ZYL_RUSSIA_PLOT_ADJACENT_HOLY_SITE_OR_LAVRA', 'ZYL_RUSSIA_REQUIRES_PLOT_ADJACENT_LAVRA'),
	('ZYL_RUSSIA_FLAT_TUNDRA_ADJACENT_HOLY_SITE_OR_LAVRA', 'ZYL_RUSSIA_REQUIRES_PLOT_ADJACENT_HOLY_SITE_OR_LAVRA'),
	('ZYL_RUSSIA_FLAT_TUNDRA_ADJACENT_HOLY_SITE_OR_LAVRA', 'REQUIRES_PLOT_HAS_TUNDRA'),
	('ZYL_RUSSIA_TUNDRA_HILLS_ADJACENT_HOLY_SITE_OR_LAVRA', 'ZYL_RUSSIA_REQUIRES_PLOT_ADJACENT_HOLY_SITE_OR_LAVRA'),
	('ZYL_RUSSIA_TUNDRA_HILLS_ADJACENT_HOLY_SITE_OR_LAVRA', 'REQUIRES_PLOT_HAS_TUNDRA_HILLS');

UPDATE Modifiers
SET SubjectRequirementSetId = 'ZYL_RUSSIA_FLAT_TUNDRA_ADJACENT_HOLY_SITE_OR_LAVRA'
WHERE ModifierId = 'TRAIT_INCREASED_TUNDRA_FAITH';

UPDATE Modifiers
SET SubjectRequirementSetId = 'ZYL_RUSSIA_TUNDRA_HILLS_ADJACENT_HOLY_SITE_OR_LAVRA'
WHERE ModifierId = 'TRAIT_INCREASED_TUNDRA_HILLS_FAITH';

UPDATE ModifierArguments
SET Value = '1'
WHERE ModifierId = 'TRAIT_INCREASED_TUNDRA_FAITH'
  AND Name = 'Amount';

UPDATE ModifierArguments
SET Value = '1'
WHERE ModifierId = 'TRAIT_INCREASED_TUNDRA_HILLS_FAITH'
  AND Name = 'Amount';

INSERT OR IGNORE INTO TraitModifiers (TraitType, ModifierId) VALUES
	('TRAIT_CIVILIZATION_MOTHER_RUSSIA', 'TRAIT_INCREASED_TUNDRA_FAITH'),
	('TRAIT_CIVILIZATION_MOTHER_RUSSIA', 'TRAIT_INCREASED_TUNDRA_HILLS_FAITH');

-------------------------------------------------------------------------------
-- France: T4 preference for every active Luxury resource
-------------------------------------------------------------------------------

-- StartBiasResources is civilization-scoped, so every French leader inherits
-- this preference.  Rebuild the Luxury rows to keep all enabled resource packs
-- at exactly T4 while preserving France's separate T4 River preference.
DELETE FROM StartBiasResources
WHERE CivilizationType = 'CIVILIZATION_FRANCE'
	AND ResourceType IN (
		SELECT ResourceType
		FROM Resources
		WHERE ResourceClassType = 'RESOURCECLASS_LUXURY'
	);

INSERT INTO StartBiasResources (CivilizationType, ResourceType, Tier)
SELECT 'CIVILIZATION_FRANCE', ResourceType, 4
FROM Resources
WHERE ResourceClassType = 'RESOURCECLASS_LUXURY';

-------------------------------------------------------------------------------
-- Catherine de Medici (Magnificence): stagger resource Culture unlocks
-------------------------------------------------------------------------------

-- BBG grants +1 Culture to all three improved resource classes at
-- Craftsmanship.  Keep that timing for Luxuries, but move Bonus resources to
-- Feudalism and Strategic resources to Castles.  Dedicated ZYL requirement
-- sets make the final ownership explicit without changing the separate
-- Theater Square adjacency bonus.
INSERT OR IGNORE INTO RequirementSets (RequirementSetId, RequirementSetType) VALUES
	('ZYL_MAGNIFICENCE_IMPROVED_LUXURY_CRAFTSMANSHIP', 'REQUIREMENTSET_TEST_ALL'),
	('ZYL_MAGNIFICENCE_IMPROVED_BONUS_FEUDALISM', 'REQUIREMENTSET_TEST_ALL'),
	('ZYL_MAGNIFICENCE_IMPROVED_STRATEGIC_CASTLES', 'REQUIREMENTSET_TEST_ALL');

-- Make repeated debug/cache loads deterministic if an older local build used
-- one of these identifiers with different members.
DELETE FROM RequirementSetRequirements
WHERE RequirementSetId IN (
	'ZYL_MAGNIFICENCE_IMPROVED_LUXURY_CRAFTSMANSHIP',
	'ZYL_MAGNIFICENCE_IMPROVED_BONUS_FEUDALISM',
	'ZYL_MAGNIFICENCE_IMPROVED_STRATEGIC_CASTLES'
);

INSERT OR IGNORE INTO RequirementSetRequirements (RequirementSetId, RequirementId) VALUES
	('ZYL_MAGNIFICENCE_IMPROVED_LUXURY_CRAFTSMANSHIP', 'BBG_REQUIRES_PLOT_HAS_IMPROVED_LUXURY'),
	('ZYL_MAGNIFICENCE_IMPROVED_LUXURY_CRAFTSMANSHIP', 'BBG_UTILS_PLAYER_HAS_CIVIC_CRAFTSMANSHIP_REQUIREMENT'),
	('ZYL_MAGNIFICENCE_IMPROVED_BONUS_FEUDALISM', 'BBG_REQUIRES_PLOT_HAS_IMPROVED_BONUS'),
	('ZYL_MAGNIFICENCE_IMPROVED_BONUS_FEUDALISM', 'BBG_UTILS_PLAYER_HAS_CIVIC_FEUDALISM_REQUIREMENT'),
	('ZYL_MAGNIFICENCE_IMPROVED_STRATEGIC_CASTLES', 'REQUIRES_PLOT_HAS_IMPROVED_STRATEGIC'),
	('ZYL_MAGNIFICENCE_IMPROVED_STRATEGIC_CASTLES', 'BBG_UTILS_PLAYER_HAS_TECH_CASTLES_REQUIREMENT');

UPDATE Modifiers
SET SubjectRequirementSetId = 'ZYL_MAGNIFICENCE_IMPROVED_LUXURY_CRAFTSMANSHIP'
WHERE ModifierId = 'BBG_MAGNIFICENCE_CULTURE_ON_LUX';

UPDATE Modifiers
SET SubjectRequirementSetId = 'ZYL_MAGNIFICENCE_IMPROVED_BONUS_FEUDALISM'
WHERE ModifierId = 'BBG_MAGNIFICENCE_CULTURE_ON_BONUS';

UPDATE Modifiers
SET SubjectRequirementSetId = 'ZYL_MAGNIFICENCE_IMPROVED_STRATEGIC_CASTLES'
WHERE ModifierId = 'BBG_MAGNIFICENCE_CULTURE_ON_STRAT';

-------------------------------------------------------------------------------
-- Suleiman (the Magnificent): keep the two combat modifiers mutually exclusive
-------------------------------------------------------------------------------

-- The base +4 modifier applies when the opponent is outside a Golden/Heroic
-- Age.  BBG's separate +2 modifier is the complementary Golden/Heroic-Age
-- case; applying the non-Golden requirement to both would incorrectly stack
-- the two modifiers to +6 in Normal/Dark-Age matchups.
UPDATE Modifiers
SET SubjectRequirementSetId = 'OPPONENT_IS_IN_GOLDEN_AGE_REQUIREMENTS'
WHERE ModifierId = 'BBG_SULEIMAN_COMBAT_BUFF';

-------------------------------------------------------------------------------
-- Repair malformed BBG ModifierArguments updates
-------------------------------------------------------------------------------

-- Moksha's local +2 Great Prophet points are already supplied by
-- BBG_MOKSHA_PROPHET_POINTS.  A separate, unbound city-attach chain in the
-- upstream governor file was dead code and has been removed there rather than
-- being activated here (which would duplicate the promotion's intended bonus).

-- Ambiorix's culture-on-training modifier stores its percentage in
-- UnitProductionPercent, not Amount.  The upstream update therefore leaves
-- the vanilla 20% value in place despite both BBG descriptions saying 25%.
UPDATE ModifierArguments
SET Value = '25'
WHERE ModifierId = 'TRAIT_GRANT_CULTURE_UNIT_TRAINED'
  AND Name = 'UnitProductionPercent';

-- The Ferris Wheel, Aquatics Center, and Stadium statements compare Name to
-- a ModifierId, so they update zero rows.  Address every modifier directly.
UPDATE ModifierArguments
SET Value = '6'
WHERE ModifierId = 'FERRIS_WHEEL_TOURISM'
  AND Name = 'Amount';

UPDATE ModifierArguments
SET Value = '6'
WHERE ModifierId = 'AQUATICS_CENTER_WONDER_TOURISM'
  AND Name = 'Amount';

UPDATE ModifierArguments
SET Value = '6'
WHERE ModifierId = 'STADIUM_10_POPULATION_TOURISM'
  AND Name = 'Amount';

UPDATE ModifierArguments
SET Value = '15'
WHERE ModifierId = 'STADIUM_20_POPULATION_TOURISM'
  AND Name = 'Amount';

-- Clancy Fernando's Information-era Great Admiral movement aura is the only
-- era copy whose grant-ability argument is mislabeled ModifierId instead of
-- AbilityType.  The target value is a UnitAbility, so the typo leaves his
-- passive +1 naval movement aura inactive.
UPDATE ModifierArguments
SET Name = 'AbilityType'
WHERE ModifierId = 'GREATPERSON_MOVEMENT_AOE_INFORMATION_SEA'
  AND Name = 'ModifierId'
  AND Value = 'ABILITY_GREAT_ADMIRAL_MOVEMENT';

-- Ngazargamu's three upstream statements omit the Name predicate and set both
-- Amount and UnitDomain to 10.  Restore the land-domain selector while
-- keeping the intended 10% discount per Encampment building.
UPDATE ModifierArguments
SET Value = '10'
WHERE ModifierId IN (
	'MINOR_CIV_CARTHAGE_BARRACKS_STABLE_PURCHASE_BONUS',
	'MINOR_CIV_CARTHAGE_ARMORY_PURCHASE_BONUS',
	'MINOR_CIV_CARTHAGE_MILITARY_ACADEMY_PURCHASE_BONUS'
)
  AND Name = 'Amount';

UPDATE ModifierArguments
SET Value = 'DOMAIN_LAND'
WHERE ModifierId IN (
	'MINOR_CIV_CARTHAGE_BARRACKS_STABLE_PURCHASE_BONUS',
	'MINOR_CIV_CARTHAGE_ARMORY_PURCHASE_BONUS',
	'MINOR_CIV_CARTHAGE_MILITARY_ACADEMY_PURCHASE_BONUS'
)
  AND Name = 'UnitDomain';

-------------------------------------------------------------------------------
-- Repair Golden-Age dedication modifiers missing their age requirement
-------------------------------------------------------------------------------

-- CommemorationModifiers are granted whenever the dedication is selected.
-- Golden-Age rewards therefore need an explicit owner requirement; ordinary
-- and Dark-Age selections should grant only their Era Score quests.
UPDATE Modifiers
SET OwnerRequirementSetId = 'PLAYER_HAS_GOLDEN_AGE'
WHERE ModifierId IN (
	'BBG_APPEAL_WYWH',
	'BBG_AUTOMATON_GDR_PROD'
);

-------------------------------------------------------------------------------
-- Johannesburg: put yield arguments on the modifiers that change city yields
-------------------------------------------------------------------------------

-- BBG's nine suzerain attach modifiers correctly point at their corresponding
-- city-yield modifiers, but Amount and YieldType were accidentally inserted on
-- the attach layer.  Attach modifiers consume only ModifierId; the inner
-- MODIFIER_PLAYER_CITIES_ADJUST_CITY_YIELD_CHANGE rows need the yield arguments.
DELETE FROM ModifierArguments
WHERE ModifierId IN (
	'BBG_MINOR_CIV_JOHANNESBURG_UNIQUE_INFLUENCE_BONUS_LUX',
	'BBG_MINOR_CIV_JOHANNESBURG_UNIQUE_INFLUENCE_BONUS_BONUS',
	'BBG_MINOR_CIV_JOHANNESBURG_UNIQUE_INFLUENCE_BONUS_STRAT',
	'BBG_MINOR_CIV_JOHANNESBURG_UNIQUE_INFLUENCE_BONUS_LUX_BALLISTICS',
	'BBG_MINOR_CIV_JOHANNESBURG_UNIQUE_INFLUENCE_BONUS_BONUS_BALLISTICS',
	'BBG_MINOR_CIV_JOHANNESBURG_UNIQUE_INFLUENCE_BONUS_STRAT_BALLISTICS',
	'BBG_MINOR_CIV_JOHANNESBURG_UNIQUE_INFLUENCE_BONUS_LUX_INDUS',
	'BBG_MINOR_CIV_JOHANNESBURG_UNIQUE_INFLUENCE_BONUS_BONUS_INDUS',
	'BBG_MINOR_CIV_JOHANNESBURG_UNIQUE_INFLUENCE_BONUS_STRAT_INDUS'
)
  AND Name IN ('Amount', 'YieldType');

INSERT OR REPLACE INTO ModifierArguments (ModifierId, Name, Value) VALUES
	('BBG_MINOR_CIV_JOHANNESBURG_PRODUCTION_LUX', 'Amount', '1'),
	('BBG_MINOR_CIV_JOHANNESBURG_PRODUCTION_LUX', 'YieldType', 'YIELD_PRODUCTION'),
	('BBG_MINOR_CIV_JOHANNESBURG_PRODUCTION_BONUS', 'Amount', '1'),
	('BBG_MINOR_CIV_JOHANNESBURG_PRODUCTION_BONUS', 'YieldType', 'YIELD_PRODUCTION'),
	('BBG_MINOR_CIV_JOHANNESBURG_PRODUCTION_STRAT', 'Amount', '1'),
	('BBG_MINOR_CIV_JOHANNESBURG_PRODUCTION_STRAT', 'YieldType', 'YIELD_PRODUCTION'),
	('BBG_MINOR_CIV_JOHANNESBURG_PRODUCTION_LUX_BALLISTICS', 'Amount', '1'),
	('BBG_MINOR_CIV_JOHANNESBURG_PRODUCTION_LUX_BALLISTICS', 'YieldType', 'YIELD_PRODUCTION'),
	('BBG_MINOR_CIV_JOHANNESBURG_PRODUCTION_BONUS_BALLISTICS', 'Amount', '1'),
	('BBG_MINOR_CIV_JOHANNESBURG_PRODUCTION_BONUS_BALLISTICS', 'YieldType', 'YIELD_PRODUCTION'),
	('BBG_MINOR_CIV_JOHANNESBURG_PRODUCTION_STRAT_BALLISTICS', 'Amount', '1'),
	('BBG_MINOR_CIV_JOHANNESBURG_PRODUCTION_STRAT_BALLISTICS', 'YieldType', 'YIELD_PRODUCTION'),
	('BBG_MINOR_CIV_JOHANNESBURG_PRODUCTION_LUX_INDUS', 'Amount', '1'),
	('BBG_MINOR_CIV_JOHANNESBURG_PRODUCTION_LUX_INDUS', 'YieldType', 'YIELD_PRODUCTION'),
	('BBG_MINOR_CIV_JOHANNESBURG_PRODUCTION_BONUS_INDUS', 'Amount', '1'),
	('BBG_MINOR_CIV_JOHANNESBURG_PRODUCTION_BONUS_INDUS', 'YieldType', 'YIELD_PRODUCTION'),
	('BBG_MINOR_CIV_JOHANNESBURG_PRODUCTION_STRAT_INDUS', 'Amount', '1'),
	('BBG_MINOR_CIV_JOHANNESBURG_PRODUCTION_STRAT_INDUS', 'YieldType', 'YIELD_PRODUCTION');

-------------------------------------------------------------------------------
-- Remove stale arguments left behind after upstream ModifierType conversions
-------------------------------------------------------------------------------

-- France's civilization-wide spy promotion now attaches a per-city trained-
-- unit modifier.  The -1 experience argument belongs to that child modifier;
-- the attach layer consumes only ModifierId.
DELETE FROM ModifierArguments
WHERE ModifierId = 'UNIQUE_LEADER_SPIES_START_PROMOTED'
  AND Name = 'Amount';

-- BBG converted both Chichen Itza rows from attach modifiers into direct plot-
-- yield modifiers.  Their direct Amount/YieldType arguments are valid, while
-- the old ModifierId links are no longer part of the modifier signature.
DELETE FROM ModifierArguments
WHERE ModifierId IN (
	'CHICHEN_ITZA_JUNGLE_CULTURE',
	'CHICHEN_ITZA_JUNGLE_PRODUCTION'
)
  AND Name = 'ModifierId';

-------------------------------------------------------------------------------
-- Work Ethic: increase Shrine and Temple Production
-------------------------------------------------------------------------------

UPDATE ModifierArguments
SET Value = '3'
WHERE ModifierId = 'WORK_ETHIC_SHRINE_PRODUCTION_MODIFIER'
  AND Name = 'Amount';

UPDATE ModifierArguments
SET Value = '5'
WHERE ModifierId = 'WORK_ETHIC_TEMPLE_PRODUCTION_MODIFIER'
  AND Name = 'Amount';
