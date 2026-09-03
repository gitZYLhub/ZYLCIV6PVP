--==================
-- Colombia
--==================
-- Restore the Firaxis Ejército Patriota movement rule: every unit receives
-- +1 Movement from the start of the game, with no civic prerequisite.
DELETE FROM TraitModifiers
WHERE TraitType = 'TRAIT_CIVILIZATION_EJERCITO_PATRIOTA'
  AND ModifierId = 'BBG_COLUMBIA_MOVEMENT_BONUS';

INSERT OR IGNORE INTO TraitModifiers (TraitType, ModifierId) VALUES
    ('TRAIT_CIVILIZATION_EJERCITO_PATRIOTA', 'TRAIT_EJERCITO_PATRIOTA_EXTRA_MOVEMENT');

-- 17/04/23 Promote and move only on cav, spy and planes
INSERT INTO RequirementSets(RequirementSetId, RequirementSetType) VALUES
    ('BBG_COLOMBIA_UNIT_IS_CAV_SPY_PLANE_REQSET', 'REQUIREMENTSET_TEST_ANY');
INSERT INTO RequirementSetRequirements(RequirementSetId, RequirementId) VALUES
    ('BBG_COLOMBIA_UNIT_IS_CAV_SPY_PLANE_REQSET', 'UNIT_IS_LIGHT_CAVALRY'),
    ('BBG_COLOMBIA_UNIT_IS_CAV_SPY_PLANE_REQSET', 'UNIT_IS_HEAVY_CAVALRY'),
    ('BBG_COLOMBIA_UNIT_IS_CAV_SPY_PLANE_REQSET', 'REQUIRES_UNIT_IS_SPY'),
    ('BBG_COLOMBIA_UNIT_IS_CAV_SPY_PLANE_REQSET', 'REQUIRES_AIR_DOMAIN');
UPDATE Modifiers SET SubjectRequirementSetId='BBG_COLOMBIA_UNIT_IS_CAV_SPY_PLANE_REQSET' WHERE ModifierId='TRAIT_PROMOTE_NO_FINISH_MOVES';



-- cannot produce great generals
INSERT OR IGNORE INTO ExcludedGreatPersonClasses (GreatPersonClassType, TraitType) VALUES
    ( 'GREAT_PERSON_CLASS_GENERAL', 'TRAIT_LEADER_CAMPANA_ADMIRABLE' );
-- llanero support nerf
UPDATE ModifierArguments SET Value='2' WHERE ModifierId='LLANERO_ADJACENCY_STRENGTH' AND Name='Amount';
-- hacienda comes sooner, but can only be built on flat tiles
UPDATE Improvements SET PrereqCivic='CIVIC_MEDIEVAL_FAIRES' WHERE ImprovementType='IMPROVEMENT_HACIENDA';
DELETE FROM Improvement_ValidTerrains WHERE ImprovementType='IMPROVEMENT_HACIENDA' AND TerrainType='TERRAIN_PLAINS_HILLS';
DELETE FROM Improvement_ValidTerrains WHERE ImprovementType='IMPROVEMENT_HACIENDA' AND TerrainType='TERRAIN_GRASS_HILLS';

--19/12/23 Hacienda buff from rapid deploiment to mercantilism
UPDATE Adjacency_YieldChanges SET PrereqCivic='CIVIC_MERCANTILISM' WHERE ID IN ('Plantation_AdvancedHaciendaAdjacency', 'Hacienda_AdvancedHaciendaAdjacency');
UPDATE Adjacency_YieldChanges SET ObsoleteCivic='CIVIC_MERCANTILISM' WHERE ID IN ('Plantation_HaciendaAdjacency', 'Hacienda_HaciendaAdjacency');

--15/12/22 Plantation bias
INSERT INTO StartBiasResources(CivilizationType, ResourceType, Tier) VALUES
    ('CIVILIZATION_GRAN_COLOMBIA', 'RESOURCE_CITRUS', 5),
    ('CIVILIZATION_GRAN_COLOMBIA', 'RESOURCE_COFFEE', 5),
    ('CIVILIZATION_GRAN_COLOMBIA', 'RESOURCE_COCOA', 5),
    ('CIVILIZATION_GRAN_COLOMBIA', 'RESOURCE_COTTON', 5),
    ('CIVILIZATION_GRAN_COLOMBIA', 'RESOURCE_DYES', 5),
    ('CIVILIZATION_GRAN_COLOMBIA', 'RESOURCE_SILK', 5),
    ('CIVILIZATION_GRAN_COLOMBIA', 'RESOURCE_SPICES', 5),
    ('CIVILIZATION_GRAN_COLOMBIA', 'RESOURCE_SUGAR', 5),
    ('CIVILIZATION_GRAN_COLOMBIA', 'RESOURCE_TEA', 5),
    ('CIVILIZATION_GRAN_COLOMBIA', 'RESOURCE_TOBACCO', 5),
    ('CIVILIZATION_GRAN_COLOMBIA', 'RESOURCE_WINE', 5),
    ('CIVILIZATION_GRAN_COLOMBIA', 'RESOURCE_INCENSE', 5),
    --('CIVILIZATION_GRAN_COLOMBIA', 'RESOURCE_OLIVES', 5),
    ('CIVILIZATION_GRAN_COLOMBIA', 'RESOURCE_BANANAS', 5);
