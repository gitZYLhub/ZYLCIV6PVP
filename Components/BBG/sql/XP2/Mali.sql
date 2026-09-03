-- 07/07/24 Mali 128973e rework

--===========================================================================
--=                                   MALI                                  =
--===========================================================================
UPDATE Units SET Combat=53 WHERE UnitType='UNIT_MALI_MANDEKALU_CAVALRY';

-- Remove the original unit/building Production penalties.  ZYLPVP does not
-- replace them with a city-wide Production penalty.
DELETE FROM TraitModifiers WHERE TraitType = 'TRAIT_CIVILIZATION_MALI_GOLD_DESERT' AND ModifierId = 'TRAIT_LESS_UNIT_PRODUCTION';
DELETE FROM TraitModifiers WHERE TraitType = 'TRAIT_CIVILIZATION_MALI_GOLD_DESERT' AND ModifierId = 'TRAIT_LESS_BUILDING_PRODUCTION';

-- The original adjacency-based City Center Faith is replaced by ZYL's flat
-- +2 Faith for City Centers founded directly on Desert or Desert Hills.
DELETE FROM TraitModifiers WHERE TraitType = 'TRAIT_CIVILIZATION_MALI_GOLD_DESERT' AND ModifierId = 'TRAIT_DESERT_CITY_CENTER_FAITH';
DELETE FROM TraitModifiers WHERE TraitType = 'TRAIT_CIVILIZATION_MALI_GOLD_DESERT' AND ModifierId = 'TRAIT_DESERT_HILLS_CITY_CENTER_FAITH';

-- No longer get Food from City Center adjacency to Desert. Keep the original
-- all-Mines -1 Production / +4 Gold ability.
DELETE FROM TraitModifiers WHERE ModifierId IN ('TRAIT_DESERT_CITY_CENTER_FOOD', 'TRAIT_DESERT_HILLS_CITY_CENTER_FOOD');

-- 30/06/25 Ability to build farms in desert
INSERT INTO Modifiers (ModifierId, ModifierType, SubjectRequirementSetId) VALUES
    ('BBG_MALI_FARM_DESERT', 'MODIFIER_PLAYER_CITIES_ADJUST_IMPROVEMENT_VALID_TERRAIN', NULL),
    ('BBG_MALI_FARM_DESERT_HILL', 'MODIFIER_PLAYER_CITIES_ADJUST_IMPROVEMENT_VALID_TERRAIN', 'BBG_UTILS_PLAYER_HAS_CIVIC_CIVIL_ENGINEERING_REQSET');
INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES
    ('BBG_MALI_FARM_DESERT', 'ImprovementType', 'IMPROVEMENT_FARM'),
    ('BBG_MALI_FARM_DESERT_HILL', 'ImprovementType', 'IMPROVEMENT_FARM'),
    ('BBG_MALI_FARM_DESERT', 'TerrainType', 'TERRAIN_DESERT'),
    ('BBG_MALI_FARM_DESERT_HILL', 'TerrainType', 'TERRAIN_DESERT_HILLS');
INSERT INTO TraitModifiers (TraitType, ModifierId) VALUES
    ('TRAIT_CIVILIZATION_MALI_GOLD_DESERT', 'BBG_MALI_FARM_DESERT'),
    ('TRAIT_CIVILIZATION_MALI_GOLD_DESERT', 'BBG_MALI_FARM_DESERT_HILL');

-- Featureless Desert and Desert Hills tiles outside City Centers gain
-- +2 Food and +1 Production.  Flat Desert excludes Floodplains and
-- Oases; those are the only ordinary features valid on that terrain.
-- BBG_REQUIRES_DISTRICT_IS_NOT_CITY_CENTER doesn't work, so creating a -2 for city center
INSERT INTO RequirementSets (RequirementSetId, RequirementSetType) VALUES
    ('BBG_PLOT_IS_DESERT_NO_CITY_CENTER_REQSET', 'REQUIREMENTSET_TEST_ALL'),
    ('BBG_PLOT_IS_DESERT_HILLS_NO_CITY_CENTER_REQSET', 'REQUIREMENTSET_TEST_ALL');
INSERT INTO RequirementSetRequirements (RequirementSetId, RequirementId) VALUES
    ('BBG_PLOT_IS_DESERT_NO_CITY_CENTER_REQSET', 'REQUIRES_PLOT_HAS_DESERT'),
    ('BBG_PLOT_IS_DESERT_NO_CITY_CENTER_REQSET', 'REQUIRES_PLOT_HAS_NO_FLOODPLAINS'),
    ('BBG_PLOT_IS_DESERT_NO_CITY_CENTER_REQSET', 'BBG_PLOT_HAS_NO_OASIS'),
    ('BBG_PLOT_IS_DESERT_NO_CITY_CENTER_REQSET', 'BBG_REQUIRES_DISTRICT_IS_NOT_CITY_CENTER'),
    ('BBG_PLOT_IS_DESERT_HILLS_NO_CITY_CENTER_REQSET', 'REQUIRES_PLOT_HAS_DESERT_HILLS'),
    ('BBG_PLOT_IS_DESERT_HILLS_NO_CITY_CENTER_REQSET', 'BBG_REQUIRES_DISTRICT_IS_NOT_CITY_CENTER');
INSERT INTO Requirements (RequirementId, RequirementType, Inverse) VALUES
    ('BBG_PLOT_HAS_NO_OASIS', 'REQUIREMENT_PLOT_FEATURE_TYPE_MATCHES', 1);
INSERT INTO RequirementArguments (RequirementId, Name, Value) VALUES
    ('BBG_PLOT_HAS_NO_OASIS', 'FeatureType', 'FEATURE_OASIS');
INSERT INTO Modifiers (ModifierId, ModifierType, SubjectRequirementSetId) VALUES
    ('BBG_MALI_FOOD_DESERT', 'MODIFIER_PLAYER_ADJUST_PLOT_YIELD', 'BBG_PLOT_IS_DESERT_NO_CITY_CENTER_REQSET'),
    ('BBG_MALI_FOOD_DESERT_HILLS', 'MODIFIER_PLAYER_ADJUST_PLOT_YIELD', 'BBG_PLOT_IS_DESERT_HILLS_NO_CITY_CENTER_REQSET'),
    ('ZYL_MALI_PRODUCTION_DESERT', 'MODIFIER_PLAYER_ADJUST_PLOT_YIELD', 'BBG_PLOT_IS_DESERT_NO_CITY_CENTER_REQSET'),
    ('ZYL_MALI_PRODUCTION_DESERT_HILLS', 'MODIFIER_PLAYER_ADJUST_PLOT_YIELD', 'BBG_PLOT_IS_DESERT_HILLS_NO_CITY_CENTER_REQSET');
INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES
    ('BBG_MALI_FOOD_DESERT', 'YieldType', 'YIELD_FOOD'),
    ('BBG_MALI_FOOD_DESERT', 'Amount', 2),
    ('BBG_MALI_FOOD_DESERT_HILLS', 'YieldType', 'YIELD_FOOD'),
    ('BBG_MALI_FOOD_DESERT_HILLS', 'Amount', 2),
    ('ZYL_MALI_PRODUCTION_DESERT', 'YieldType', 'YIELD_PRODUCTION'),
    ('ZYL_MALI_PRODUCTION_DESERT', 'Amount', 1),
    ('ZYL_MALI_PRODUCTION_DESERT_HILLS', 'YieldType', 'YIELD_PRODUCTION'),
    ('ZYL_MALI_PRODUCTION_DESERT_HILLS', 'Amount', 1);
INSERT INTO TraitModifiers (TraitType, ModifierId) VALUES
    ('TRAIT_CIVILIZATION_MALI_GOLD_DESERT', 'BBG_MALI_FOOD_DESERT'),
    ('TRAIT_CIVILIZATION_MALI_GOLD_DESERT', 'BBG_MALI_FOOD_DESERT_HILLS'),
    ('TRAIT_CIVILIZATION_MALI_GOLD_DESERT', 'ZYL_MALI_PRODUCTION_DESERT'),
    ('TRAIT_CIVILIZATION_MALI_GOLD_DESERT', 'ZYL_MALI_PRODUCTION_DESERT_HILLS');

--===========================================================================
--=                                 SUGUBA                                  =
--===========================================================================

-- Cheaper purchase
-- Restore the original 10% purchase discount.
UPDATE ModifierArguments SET Value=10 WHERE ModifierId IN ('SUGUBA_CHEAPER_BUILDING_PURCHASE', 'SUGUBA_CHEAPER_DISTRICT_PURCHASE');
UPDATE ModifierArguments SET Value=10 WHERE ModifierId='SUGUBA_CHEAPER_UNIT_PURCHASE' AND Name='Amount';

-- Normal adj from HS, City center, Rivers, Oasis and Gov Plaza
INSERT INTO Adjacency_YieldChanges(ID, Description, YieldType, YieldChange, AdjacentFeature) VALUES
    ('BBG_SUGUBA_OASIS', 'LOC_SUGUBA_OASIS_GOLD', 'YIELD_GOLD', 1, 'FEATURE_OASIS');
INSERT INTO Adjacency_YieldChanges(ID, Description, YieldType, YieldChange, AdjacentRiver) VALUES
    ('BBG_SUGUBA_RIVER', 'LOC_SUGUBA_RIVER_GOLD', 'YIELD_GOLD', 1, 1);
INSERT INTO Adjacency_YieldChanges(ID, Description, YieldType, YieldChange, AdjacentDistrict) VALUES
    ('BBG_SUGUBA_CITY_CENTER', 'LOC_DISTRICT_CITY_CENTER_GOLD', 'YIELD_GOLD', 1, 'DISTRICT_CITY_CENTER');
INSERT INTO District_Adjacencies(DistrictType, YieldChangeId) VALUES
    ('DISTRICT_SUGUBA', 'BBG_SUGUBA_OASIS'),
    ('DISTRICT_SUGUBA', 'BBG_SUGUBA_RIVER'),
    ('DISTRICT_SUGUBA', 'BBG_SUGUBA_CITY_CENTER');
DELETE FROM District_Adjacencies WHERE DistrictType = 'DISTRICT_SUGUBA' AND YieldChangeId = 'River_Gold';

UPDATE Adjacency_YieldChanges SET YieldChange=1 WHERE ID='Holy_Site_Gold';


--===========================================================================
--=                                 MANSA                                   =
--===========================================================================

-- Delete gold from traderoute based on number of desert tile in origin
DELETE FROM TraitModifiers WHERE ModifierId='TRADE_ROUTE_GOLD_DESERT_ORIGIN';

-- Keep Firaxis' original GOLDEN_AGE_TRADE_ROUTE modifier: Mansa Musa gains
-- one permanent Trade Route capacity each time he enters a Golden Age.

-- Holy site +1 to Suguba / Sundiata is excluded in LP/Sundiata.sql
-- remove the classic +1 and give +2 on the Mansa one
INSERT INTO ExcludedAdjacencies(TraitType, YieldChangeId) VALUES
    ('TRAIT_LEADER_SAHEL_MERCHANTS', 'Holy_Site_Gold');
INSERT INTO Adjacency_YieldChanges(ID, Description, YieldType, YieldChange, AdjacentDistrict) VALUES
    ('BBG_SUGUBA_HOLY_SITE_MANSA', 'LOC_BBG_SUGUBA_HOLY_SITE_MANSA', 'YIELD_GOLD', 2, 'DISTRICT_HOLY_SITE');
INSERT INTO District_Adjacencies(DistrictType, YieldChangeId) VALUES
    ('DISTRICT_SUGUBA', 'BBG_SUGUBA_HOLY_SITE_MANSA');

