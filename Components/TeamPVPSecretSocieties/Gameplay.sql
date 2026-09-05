------------------------------------------------------------------------------
-- Team PVP Balanced mod Secret Societies 3.93
--
-- This is a conflict-safe, self-contained port of the active Secret Society
-- balance from Workshop item 3475173328.  Unrelated Poland, Amani and policy
-- edits that happened to share the upstream SQL file are intentionally out of
-- scope.  Free society titles remain owned by BBG/sql/Secret_Societies.sql so
-- the refund row is inserted exactly once.
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Shared discovery and promotion timing
------------------------------------------------------------------------------
UPDATE SecretSocieties
SET DiscoverAtCityStateBaseChance = 100000
WHERE SecretSocietyType IN (
	'SECRETSOCIETY_OWLS_OF_MINERVA',
	'SECRETSOCIETY_HERMETIC_ORDER',
	'SECRETSOCIETY_VOIDSINGERS',
	'SECRETSOCIETY_SANGUINE_PACT'
);

-- ZYL LightweightBalance: investigating any Tribal Village attempts to
-- discover all four societies at the effectively guaranteed base chance.
-- The societies' existing discovery sources remain available as well.
UPDATE SecretSocieties
SET DiscoverAtGoodyHutBaseChance = 100000
WHERE SecretSocietyType IN (
	'SECRETSOCIETY_OWLS_OF_MINERVA',
	'SECRETSOCIETY_HERMETIC_ORDER',
	'SECRETSOCIETY_VOIDSINGERS',
	'SECRETSOCIETY_SANGUINE_PACT'
);

UPDATE GovernorPromotionConditions
SET EarliestGameEra = 'ERA_RENAISSANCE'
WHERE GovernorPromotionType IN (
	'GOVERNOR_PROMOTION_OWLS_OF_MINERVA_3',
	'GOVERNOR_PROMOTION_HERMETIC_ORDER_3',
	'GOVERNOR_PROMOTION_VOIDSINGERS_3',
	'GOVERNOR_PROMOTION_SANGUINE_PACT_3'
);

UPDATE GovernorPromotionConditions
SET EarliestGameEra = 'ERA_INDUSTRIAL'
WHERE GovernorPromotionType IN (
	'GOVERNOR_PROMOTION_OWLS_OF_MINERVA_4',
	'GOVERNOR_PROMOTION_HERMETIC_ORDER_4',
	'GOVERNOR_PROMOTION_VOIDSINGERS_4',
	'GOVERNOR_PROMOTION_SANGUINE_PACT_4'
);

-- The Sanguine Pact's second tier is explicitly Medieval in the integration
-- layer so it remains stable if another data pack changes the base condition.
UPDATE GovernorPromotionConditions
SET EarliestGameEra = 'ERA_MEDIEVAL'
WHERE GovernorPromotionType = 'GOVERNOR_PROMOTION_SANGUINE_PACT_2';

------------------------------------------------------------------------------
-- Owls of Minerva
------------------------------------------------------------------------------
UPDATE Buildings
SET Cost = 210,
	PrereqTech = NULL,
	PurchaseYield = 'YIELD_GOLD'
WHERE BuildingType = 'BUILDING_GILDED_VAULT';

-- The XML definition also declares Gold purchasing, but pin the effective
-- value here after the replacement building is loaded so later balance layers
-- cannot leave the Gilded Shipyard with a NULL purchase route.
UPDATE Buildings
SET PurchaseYield = 'YIELD_GOLD'
WHERE BuildingType = 'BUILDING_GILDED_Shipyard';

INSERT OR IGNORE INTO Building_YieldChanges
	(BuildingType, YieldType, YieldChange)
SELECT 'BUILDING_GILDED_VAULT', 'YIELD_GOLD', 7
WHERE EXISTS (
	SELECT 1 FROM Buildings WHERE BuildingType = 'BUILDING_GILDED_VAULT'
)
UNION ALL
SELECT 'BUILDING_GILDED_VAULT', 'YIELD_CULTURE', 3
WHERE EXISTS (
	SELECT 1 FROM Buildings WHERE BuildingType = 'BUILDING_GILDED_VAULT'
);

UPDATE Building_YieldChanges
SET YieldChange = CASE YieldType
	WHEN 'YIELD_GOLD' THEN 7
	WHEN 'YIELD_CULTURE' THEN 3
END
WHERE BuildingType = 'BUILDING_GILDED_VAULT'
  AND YieldType IN ('YIELD_GOLD', 'YIELD_CULTURE');

UPDATE Building_GreatPersonPoints
SET PointsPerTurn = 3
WHERE BuildingType = 'BUILDING_GILDED_VAULT'
  AND GreatPersonClassType = 'GREAT_PERSON_CLASS_MERCHANT';

-- BBG Bank parity: routes originating in this city receive +2 Gold and routes
-- ending here receive +1 Gold, for both domestic and international routes.
INSERT OR IGNORE INTO BuildingModifiers
	(BuildingType, ModifierId)
SELECT 'BUILDING_GILDED_VAULT', ModifierId
FROM Modifiers
WHERE ModifierId IN (
	'BBG_BANK_TRADEROUTE_FROM_DOMESTIC',
	'BBG_BANK_TRADEROUTE_TO_DOMESTIC',
	'BBG_BANK_TRADEROUTE_FROM_INTERNATIONAL',
	'BBG_BANK_TRADEROUTE_TO_INTERNATIONAL'
);

-- Several official effects identify Banks and Shipyards through these shared
-- requirement sets rather than through BuildingReplaces.  Make both sets
-- alternatives so the Gilded replacements receive every consumer of the
-- official sets (including Laissez-Faire, Cardiff power and Phoenician
-- stockpile capacity), now and in later rules that reuse the same sets.
UPDATE RequirementSets
SET RequirementSetType = 'REQUIREMENTSET_TEST_ANY'
WHERE RequirementSetId IN ('BUILDING_IS_BANK', 'BUILDING_IS_SHIPYARD');

INSERT OR IGNORE INTO Requirements
	(RequirementId, RequirementType)
VALUES
	('ZYL_TPVP_REQUIRES_CITY_HAS_GILDED_VAULT_COMPAT', 'REQUIREMENT_CITY_HAS_BUILDING'),
	('ZYL_TPVP_REQUIRES_CITY_HAS_GILDED_SHIPYARD_COMPAT', 'REQUIREMENT_CITY_HAS_BUILDING');

INSERT OR REPLACE INTO RequirementArguments
	(RequirementId, Name, Value)
VALUES
	('ZYL_TPVP_REQUIRES_CITY_HAS_GILDED_VAULT_COMPAT', 'BuildingType', 'BUILDING_GILDED_VAULT'),
	('ZYL_TPVP_REQUIRES_CITY_HAS_GILDED_SHIPYARD_COMPAT', 'BuildingType', 'BUILDING_GILDED_Shipyard');

INSERT OR IGNORE INTO RequirementSetRequirements
	(RequirementSetId, RequirementId)
SELECT 'BUILDING_IS_BANK', 'ZYL_TPVP_REQUIRES_CITY_HAS_GILDED_VAULT_COMPAT'
WHERE EXISTS (
	SELECT 1 FROM RequirementSets WHERE RequirementSetId = 'BUILDING_IS_BANK'
)
UNION ALL
SELECT 'BUILDING_IS_SHIPYARD', 'ZYL_TPVP_REQUIRES_CITY_HAS_GILDED_SHIPYARD_COMPAT'
WHERE EXISTS (
	SELECT 1 FROM RequirementSets WHERE RequirementSetId = 'BUILDING_IS_SHIPYARD'
);

-- Robber Barons uses its own Bank-or-Shipyard set in Dramatic Ages.  Extend it
-- when that optional mode has loaded the set.
INSERT OR IGNORE INTO RequirementSetRequirements
	(RequirementSetId, RequirementId)
SELECT 'BUILDING_IS_BANK_OR_SHIPYARD', 'ZYL_TPVP_REQUIRES_CITY_HAS_GILDED_VAULT_COMPAT'
WHERE EXISTS (
	SELECT 1 FROM RequirementSets WHERE RequirementSetId = 'BUILDING_IS_BANK_OR_SHIPYARD'
)
UNION ALL
SELECT 'BUILDING_IS_BANK_OR_SHIPYARD', 'ZYL_TPVP_REQUIRES_CITY_HAS_GILDED_SHIPYARD_COMPAT'
WHERE EXISTS (
	SELECT 1 FROM RequirementSets WHERE RequirementSetId = 'BUILDING_IS_BANK_OR_SHIPYARD'
);

-- Building prerequisites are alternatives in Civ VI (as with the two museum
-- prerequisites for a Broadcast Center).  Keep Big Ben available after a
-- Gilded Vault just as the official Secret Societies data already does for the
-- Stock Exchange, and as this component does for Seaports below.
INSERT OR IGNORE INTO BuildingPrereqs
	(Building, PrereqBuilding)
SELECT 'BUILDING_BIG_BEN', 'BUILDING_GILDED_VAULT'
WHERE EXISTS (SELECT 1 FROM Buildings WHERE BuildingType = 'BUILDING_BIG_BEN')
  AND EXISTS (SELECT 1 FROM Buildings WHERE BuildingType = 'BUILDING_GILDED_VAULT');

-- Owls tier 1: keep the envoy bonus available immediately, but delay the
-- economic policy slot until Political Philosophy has been completed.
INSERT OR IGNORE INTO RequirementSets
	(RequirementSetId, RequirementSetType)
VALUES
	('ZYL_TPVP_PLAYER_HAS_POLITICAL_PHILOSOPHY', 'REQUIREMENTSET_TEST_ALL');

INSERT OR IGNORE INTO Requirements
	(RequirementId, RequirementType)
VALUES
	('ZYL_TPVP_PLAYER_HAS_POLITICAL_PHILOSOPHY_REQUIREMENT',
	 'REQUIREMENT_PLAYER_HAS_CIVIC');

INSERT OR REPLACE INTO RequirementArguments
	(RequirementId, Name, Value)
VALUES
	('ZYL_TPVP_PLAYER_HAS_POLITICAL_PHILOSOPHY_REQUIREMENT',
	 'CivicType', 'CIVIC_POLITICAL_PHILOSOPHY');

INSERT OR IGNORE INTO RequirementSetRequirements
	(RequirementSetId, RequirementId)
VALUES
	('ZYL_TPVP_PLAYER_HAS_POLITICAL_PHILOSOPHY',
	 'ZYL_TPVP_PLAYER_HAS_POLITICAL_PHILOSOPHY_REQUIREMENT');

UPDATE Modifiers
SET OwnerRequirementSetId = 'ZYL_TPVP_PLAYER_HAS_POLITICAL_PHILOSOPHY'
WHERE ModifierId = 'GOVERNOR_PROMOTION_OWLS_OF_MINERVA_1_ECONOMIC_POLICY_SLOT';

-- Owls tier 2: grant one trade route directly on promotion.  The other route
-- comes from the first Gilded Vault, rather than once per Vault building.
INSERT OR IGNORE INTO Modifiers
	(ModifierId, ModifierType)
VALUES
	('ZYL_TPVP_OWLS_2_TRADE_ROUTE_CAPACITY',
	 'MODIFIER_PLAYER_ADJUST_TRADE_ROUTE_CAPACITY');

INSERT OR REPLACE INTO ModifierArguments
	(ModifierId, Name, Value)
VALUES
	('ZYL_TPVP_OWLS_2_TRADE_ROUTE_CAPACITY', 'Amount', 1);

INSERT OR IGNORE INTO GovernorPromotionModifiers
	(GovernorPromotionType, ModifierId)
VALUES
	('GOVERNOR_PROMOTION_OWLS_OF_MINERVA_2',
	 'ZYL_TPVP_OWLS_2_TRADE_ROUTE_CAPACITY');

-- First Gilded Vault: this player-level requirement is evaluated once for the
-- promotion's owner, so additional Vaults cannot stack another route.
INSERT OR IGNORE INTO RequirementSets
	(RequirementSetId, RequirementSetType)
VALUES
	('ZYL_TPVP_PLAYER_HAS_GILDED_VAULT', 'REQUIREMENTSET_TEST_ALL');

INSERT OR IGNORE INTO Requirements
	(RequirementId, RequirementType)
VALUES
	('ZYL_TPVP_PLAYER_HAS_GILDED_VAULT_REQUIREMENT',
	 'REQUIREMENT_PLAYER_HAS_BUILDING');

INSERT OR REPLACE INTO RequirementArguments
	(RequirementId, Name, Value)
VALUES
	('ZYL_TPVP_PLAYER_HAS_GILDED_VAULT_REQUIREMENT',
	 'BuildingType', 'BUILDING_GILDED_VAULT');

INSERT OR IGNORE INTO RequirementSetRequirements
	(RequirementSetId, RequirementId)
VALUES
	('ZYL_TPVP_PLAYER_HAS_GILDED_VAULT',
	 'ZYL_TPVP_PLAYER_HAS_GILDED_VAULT_REQUIREMENT');

INSERT OR IGNORE INTO Modifiers
	(ModifierId, ModifierType, RunOnce, Permanent, OwnerRequirementSetId)
VALUES
	('ZYL_TPVP_OWLS_FIRST_GILDED_VAULT_TRADE_ROUTE_CAPACITY',
	 'MODIFIER_PLAYER_ADJUST_TRADE_ROUTE_CAPACITY', 1, 1,
	 'ZYL_TPVP_PLAYER_HAS_GILDED_VAULT');

INSERT OR REPLACE INTO ModifierArguments
	(ModifierId, Name, Value)
VALUES
	('ZYL_TPVP_OWLS_FIRST_GILDED_VAULT_TRADE_ROUTE_CAPACITY', 'Amount', 1);

INSERT OR IGNORE INTO GovernorPromotionModifiers
	(GovernorPromotionType, ModifierId)
VALUES
	('GOVERNOR_PROMOTION_OWLS_OF_MINERVA_2',
	 'ZYL_TPVP_OWLS_FIRST_GILDED_VAULT_TRADE_ROUTE_CAPACITY');

-- Remove the upstream per-building route modifier.  The first-Vault modifier
-- above is the sole building-related route bonus for the Owls.
DELETE FROM BuildingModifiers
WHERE BuildingType = 'BUILDING_GILDED_VAULT'
	AND ModifierId = 'BUILDING_GILDED_VAULT_TRADE_ROUTE_CAPACITY';

DELETE FROM BuildingModifiers
WHERE BuildingType = 'BUILDING_GILDED_VAULT'
  AND ModifierId = 'BUILDING_GILDED_VAULT_CULTURE_MIRRORS_GOLD';

UPDATE ModifierArguments
SET Value = '1'
WHERE ModifierId = 'GOVERNOR_PROMOTION_OWLS_OF_MINERVA_3_SPY_CAPACITY'
  AND Name = 'Amount';

INSERT OR IGNORE INTO GovernorPromotionModifiers
	(GovernorPromotionType, ModifierId)
SELECT 'GOVERNOR_PROMOTION_OWLS_OF_MINERVA_3', ModifierId
FROM GovernorPromotionModifiers
WHERE GovernorPromotionType = 'GOVERNOR_PROMOTION_OWLS_OF_MINERVA_4'
  AND ModifierId IN (
	'GOVERNOR_PROMOTION_OWLS_OF_MINERVA_4_SPY_SUCCESS_GRANTS_SCIENCE',
	'GOVERNOR_PROMOTION_OWLS_OF_MINERVA_4_SPY_SUCCESS_GRANTS_CULTURE',
	'GOVERNOR_PROMOTION_OWLS_OF_MINERVA_4_SPY_SUCCESS_GRANTS_GOLD',
	'GOVERNOR_PROMOTION_OWLS_OF_MINERVA_4_SPY_SUCCESS_GRANTS_FAITH'
  );

DELETE FROM GovernorPromotionModifiers
WHERE GovernorPromotionType = 'GOVERNOR_PROMOTION_OWLS_OF_MINERVA_4'
  AND ModifierId IN (
	'GOVERNOR_PROMOTION_OWLS_OF_MINERVA_4_SPY_SUCCESS_GRANTS_SCIENCE',
	'GOVERNOR_PROMOTION_OWLS_OF_MINERVA_4_SPY_SUCCESS_GRANTS_CULTURE',
	'GOVERNOR_PROMOTION_OWLS_OF_MINERVA_4_SPY_SUCCESS_GRANTS_GOLD',
	'GOVERNOR_PROMOTION_OWLS_OF_MINERVA_4_SPY_SUCCESS_GRANTS_FAITH'
  );

UPDATE ModifierArguments
SET Value = '150'
WHERE ModifierId IN (
	'GOVERNOR_PROMOTION_OWLS_OF_MINERVA_4_SPY_SUCCESS_GRANTS_SCIENCE',
	'GOVERNOR_PROMOTION_OWLS_OF_MINERVA_4_SPY_SUCCESS_GRANTS_CULTURE',
	'GOVERNOR_PROMOTION_OWLS_OF_MINERVA_4_SPY_SUCCESS_GRANTS_GOLD',
	'GOVERNOR_PROMOTION_OWLS_OF_MINERVA_4_SPY_SUCCESS_GRANTS_FAITH'
)
  AND Name = 'Percent';

UPDATE ModifierArguments
SET Value = '5'
WHERE ModifierId = 'GOVERNOR_PROMOTION_OWLS_OF_MINERVA_4_GOLD_INTEREST'
  AND Name = 'Percent';

-- Gilded Shipyard: one Coal per turn after Coal is visible.
-- Remove the superseded threshold-by-adjacency modifiers if a player is
-- upgrading an existing cached database from an earlier Team PVP build.
DELETE FROM BuildingModifiers
WHERE BuildingType = 'BUILDING_GILDED_Shipyard'
  AND ModifierId LIKE 'ZYL_TPVP_GILDED_SHIPYARD_ADJ_%';

DELETE FROM ModifierArguments
WHERE ModifierId LIKE 'ZYL_TPVP_GILDED_SHIPYARD_ADJ_%';

DELETE FROM Modifiers
WHERE ModifierId LIKE 'ZYL_TPVP_GILDED_SHIPYARD_ADJ_%';

DELETE FROM RequirementSetRequirements
WHERE RequirementSetId LIKE 'ZYL_TPVP_HARBOR_ADJ_%'
   OR RequirementId LIKE 'ZYL_TPVP_REQUIRES_HARBOR_ADJ_%'
   OR RequirementId = 'ZYL_TPVP_REQUIRES_HARBOR_DISTRICT';

DELETE FROM RequirementArguments
WHERE RequirementId LIKE 'ZYL_TPVP_REQUIRES_HARBOR_ADJ_%'
   OR RequirementId = 'ZYL_TPVP_REQUIRES_HARBOR_DISTRICT';

DELETE FROM Requirements
WHERE RequirementId LIKE 'ZYL_TPVP_REQUIRES_HARBOR_ADJ_%'
   OR RequirementId = 'ZYL_TPVP_REQUIRES_HARBOR_DISTRICT';

DELETE FROM RequirementSets
WHERE RequirementSetId LIKE 'ZYL_TPVP_HARBOR_ADJ_%';

-- The Team PVP modifier below is the single Coal source for the replacement;
-- remove any copied BBG row from an older integration before attaching it.
DELETE FROM BuildingModifiers
WHERE BuildingType = 'BUILDING_GILDED_Shipyard'
  AND ModifierId = 'COAL_FROM_SHIPYARD_BBG';

INSERT OR IGNORE INTO RequirementSets
	(RequirementSetId, RequirementSetType)
VALUES
	('ZYL_TPVP_PLAYER_CAN_SEE_COAL', 'REQUIREMENTSET_TEST_ALL');

INSERT OR IGNORE INTO RequirementSetRequirements
	(RequirementSetId, RequirementId)
SELECT 'ZYL_TPVP_PLAYER_CAN_SEE_COAL', 'REQUIRES_PLAYER_CAN_SEE_COAL'
WHERE EXISTS (
	SELECT 1 FROM Requirements WHERE RequirementId = 'REQUIRES_PLAYER_CAN_SEE_COAL'
);

INSERT OR IGNORE INTO Modifiers
	(ModifierId, ModifierType, SubjectRequirementSetId)
VALUES
	(
		'ZYL_TPVP_GILDED_SHIPYARD_COAL',
		'MODIFIER_PLAYER_ADJUST_FREE_RESOURCE_IMPORT_EXTRACTION',
		'ZYL_TPVP_PLAYER_CAN_SEE_COAL'
	);

INSERT OR REPLACE INTO ModifierArguments
	(ModifierId, Name, Value)
VALUES
	('ZYL_TPVP_GILDED_SHIPYARD_COAL', 'ResourceType', 'RESOURCE_COAL'),
	('ZYL_TPVP_GILDED_SHIPYARD_COAL', 'Amount', 1);

INSERT OR IGNORE INTO BuildingModifiers
	(BuildingType, ModifierId)
SELECT 'BUILDING_GILDED_Shipyard', 'ZYL_TPVP_GILDED_SHIPYARD_COAL'
WHERE EXISTS (
	SELECT 1 FROM Buildings WHERE BuildingType = 'BUILDING_GILDED_Shipyard'
);

-- Future-proof direct building parity: copy every modifier currently attached
-- to the regular Shipyard.  Coal is excluded because the equivalent Gilded
-- modifier above is already attached and must not stack a second copy.
INSERT OR IGNORE INTO BuildingModifiers
	(BuildingType, ModifierId)
SELECT 'BUILDING_GILDED_Shipyard', ModifierId
FROM BuildingModifiers
WHERE BuildingType = 'BUILDING_SHIPYARD'
  AND ModifierId <> 'COAL_FROM_SHIPYARD_BBG';

-- Keep the Gilded Shipyard in parity with the regular Shipyard's BBG
-- Fishery bonus.  The building XML is loaded immediately before this file,
-- while the BBG modifier is loaded earlier in the integrated package.
INSERT OR IGNORE INTO BuildingModifiers
	(BuildingType, ModifierId)
SELECT 'BUILDING_GILDED_Shipyard', 'BBG_SHIPYARD_FISHERY_PRODUCTION'
WHERE EXISTS (
	SELECT 1 FROM Buildings WHERE BuildingType = 'BUILDING_GILDED_Shipyard'
)
  AND EXISTS (
	SELECT 1 FROM Modifiers WHERE ModifierId = 'BBG_SHIPYARD_FISHERY_PRODUCTION'
);

-- Military Research: +1 Science from the Gilded Shipyard as well as the
-- regular Shipyard.  The regular BBG modifier is intentionally left intact.
INSERT OR IGNORE INTO Modifiers (ModifierId, ModifierType)
VALUES
	('ZYL_TPVP_MILITARYRESEARCH_GILDED_SHIPYARD_SCIENCE',
	 'MODIFIER_PLAYER_CITIES_ADJUST_BUILDING_YIELD_CHANGE');

INSERT OR REPLACE INTO ModifierArguments (ModifierId, Name, Value)
VALUES
	('ZYL_TPVP_MILITARYRESEARCH_GILDED_SHIPYARD_SCIENCE', 'BuildingType', 'BUILDING_GILDED_Shipyard'),
	('ZYL_TPVP_MILITARYRESEARCH_GILDED_SHIPYARD_SCIENCE', 'YieldType', 'YIELD_SCIENCE'),
	('ZYL_TPVP_MILITARYRESEARCH_GILDED_SHIPYARD_SCIENCE', 'Amount', 1);

INSERT OR IGNORE INTO PolicyModifiers (PolicyType, ModifierId)
SELECT 'POLICY_MILITARY_RESEARCH',
	'ZYL_TPVP_MILITARYRESEARCH_GILDED_SHIPYARD_SCIENCE'
WHERE EXISTS (
	SELECT 1 FROM Policies WHERE PolicyType = 'POLICY_MILITARY_RESEARCH'
);

-- Cardiff: its suzerain bonus applies +1 Production and +1 Gold to every
-- Harbor building, including the Gilded Shipyard replacement.
INSERT OR IGNORE INTO Modifiers
	(ModifierId, ModifierType, SubjectRequirementSetId)
VALUES
	('ZYL_TPVP_CARDIFF_GILDED_SHIPYARD_PRODUCTION_ATTACH',
	 'MODIFIER_ALL_PLAYERS_ATTACH_MODIFIER', 'PLAYER_IS_SUZERAIN'),
	('ZYL_TPVP_CARDIFF_GILDED_SHIPYARD_PRODUCTION',
	 'MODIFIER_PLAYER_CITIES_ADJUST_BUILDING_YIELD_CHANGE', NULL),
	('ZYL_TPVP_CARDIFF_GILDED_SHIPYARD_GOLD_ATTACH',
	 'MODIFIER_ALL_PLAYERS_ATTACH_MODIFIER', 'PLAYER_IS_SUZERAIN'),
	('ZYL_TPVP_CARDIFF_GILDED_SHIPYARD_GOLD',
	 'MODIFIER_PLAYER_CITIES_ADJUST_BUILDING_YIELD_CHANGE', NULL);

INSERT OR REPLACE INTO ModifierArguments (ModifierId, Name, Value)
VALUES
	('ZYL_TPVP_CARDIFF_GILDED_SHIPYARD_PRODUCTION_ATTACH', 'ModifierId',
	 'ZYL_TPVP_CARDIFF_GILDED_SHIPYARD_PRODUCTION'),
	('ZYL_TPVP_CARDIFF_GILDED_SHIPYARD_PRODUCTION', 'BuildingType', 'BUILDING_GILDED_Shipyard'),
	('ZYL_TPVP_CARDIFF_GILDED_SHIPYARD_PRODUCTION', 'YieldType', 'YIELD_PRODUCTION'),
	('ZYL_TPVP_CARDIFF_GILDED_SHIPYARD_PRODUCTION', 'Amount', 1),
	('ZYL_TPVP_CARDIFF_GILDED_SHIPYARD_GOLD_ATTACH', 'ModifierId',
	 'ZYL_TPVP_CARDIFF_GILDED_SHIPYARD_GOLD'),
	('ZYL_TPVP_CARDIFF_GILDED_SHIPYARD_GOLD', 'BuildingType', 'BUILDING_GILDED_Shipyard'),
	('ZYL_TPVP_CARDIFF_GILDED_SHIPYARD_GOLD', 'YieldType', 'YIELD_GOLD'),
	('ZYL_TPVP_CARDIFF_GILDED_SHIPYARD_GOLD', 'Amount', 1);

INSERT OR IGNORE INTO TraitModifiers (TraitType, ModifierId)
SELECT 'MINOR_CIV_CARDIFF_TRAIT',
	'ZYL_TPVP_CARDIFF_GILDED_SHIPYARD_PRODUCTION_ATTACH'
WHERE EXISTS (
	SELECT 1 FROM Traits WHERE TraitType = 'MINOR_CIV_CARDIFF_TRAIT'
)
UNION ALL
SELECT 'MINOR_CIV_CARDIFF_TRAIT',
	'ZYL_TPVP_CARDIFF_GILDED_SHIPYARD_GOLD_ATTACH'
WHERE EXISTS (
	SELECT 1 FROM Traits WHERE TraitType = 'MINOR_CIV_CARDIFF_TRAIT'
);

-- Trade City-State medium-tier building bonus: official data names the two
-- base buildings directly, so clone the +4 Gold effect for both replacements.
INSERT OR IGNORE INTO Modifiers
	(ModifierId, ModifierType, SubjectRequirementSetId)
VALUES
	('ZYL_TPVP_TRADE_MEDIUM_GILDED_VAULT_ATTACH',
	 'MODIFIER_ALL_PLAYERS_ATTACH_MODIFIER', 'PLAYER_HAS_MEDIUM_INFLUENCE'),
	('ZYL_TPVP_TRADE_MEDIUM_GILDED_VAULT_GOLD',
	 'MODIFIER_PLAYER_CITIES_ADJUST_BUILDING_YIELD_CHANGE', NULL),
	('ZYL_TPVP_TRADE_MEDIUM_GILDED_SHIPYARD_ATTACH',
	 'MODIFIER_ALL_PLAYERS_ATTACH_MODIFIER', 'PLAYER_HAS_MEDIUM_INFLUENCE'),
	('ZYL_TPVP_TRADE_MEDIUM_GILDED_SHIPYARD_GOLD',
	 'MODIFIER_PLAYER_CITIES_ADJUST_BUILDING_YIELD_CHANGE', NULL);

INSERT OR REPLACE INTO ModifierArguments
	(ModifierId, Name, Value)
VALUES
	('ZYL_TPVP_TRADE_MEDIUM_GILDED_VAULT_ATTACH', 'ModifierId',
	 'ZYL_TPVP_TRADE_MEDIUM_GILDED_VAULT_GOLD'),
	('ZYL_TPVP_TRADE_MEDIUM_GILDED_VAULT_GOLD', 'YieldType', 'YIELD_GOLD'),
	('ZYL_TPVP_TRADE_MEDIUM_GILDED_VAULT_GOLD', 'BuildingType', 'BUILDING_GILDED_VAULT'),
	('ZYL_TPVP_TRADE_MEDIUM_GILDED_VAULT_GOLD', 'Amount', 4),
	('ZYL_TPVP_TRADE_MEDIUM_GILDED_VAULT_GOLD', 'CityStatesOnly', 1),
	('ZYL_TPVP_TRADE_MEDIUM_GILDED_SHIPYARD_ATTACH', 'ModifierId',
	 'ZYL_TPVP_TRADE_MEDIUM_GILDED_SHIPYARD_GOLD'),
	('ZYL_TPVP_TRADE_MEDIUM_GILDED_SHIPYARD_GOLD', 'YieldType', 'YIELD_GOLD'),
	('ZYL_TPVP_TRADE_MEDIUM_GILDED_SHIPYARD_GOLD', 'BuildingType', 'BUILDING_GILDED_Shipyard'),
	('ZYL_TPVP_TRADE_MEDIUM_GILDED_SHIPYARD_GOLD', 'Amount', 4),
	('ZYL_TPVP_TRADE_MEDIUM_GILDED_SHIPYARD_GOLD', 'CityStatesOnly', 1);

INSERT OR IGNORE INTO TraitModifiers
	(TraitType, ModifierId)
SELECT 'MINOR_CIV_TRADE_TRAIT', 'ZYL_TPVP_TRADE_MEDIUM_GILDED_VAULT_ATTACH'
WHERE EXISTS (SELECT 1 FROM Traits WHERE TraitType = 'MINOR_CIV_TRADE_TRAIT')
UNION ALL
SELECT 'MINOR_CIV_TRADE_TRAIT', 'ZYL_TPVP_TRADE_MEDIUM_GILDED_SHIPYARD_ATTACH'
WHERE EXISTS (SELECT 1 FROM Traits WHERE TraitType = 'MINOR_CIV_TRADE_TRAIT');

------------------------------------------------------------------------------
-- Hermetic Order and Ley Lines
------------------------------------------------------------------------------
UPDATE Buildings
SET Cost = 180,
	PrereqTech = NULL,
	PurchaseYield = NULL
WHERE BuildingType = 'BUILDING_ALCHEMICAL_SOCIETY';

-- These are also the Ethiopia Pack defaults, but Team PVP explicitly pins
-- them. Keep the values here so a preceding balance component cannot silently
-- change the intended 4 Science / 2 Production profile.
INSERT OR IGNORE INTO Building_YieldChanges
	(BuildingType, YieldType, YieldChange)
SELECT 'BUILDING_ALCHEMICAL_SOCIETY', 'YIELD_SCIENCE', 4
WHERE EXISTS (
	SELECT 1 FROM Buildings WHERE BuildingType = 'BUILDING_ALCHEMICAL_SOCIETY'
)
UNION ALL
SELECT 'BUILDING_ALCHEMICAL_SOCIETY', 'YIELD_PRODUCTION', 2
WHERE EXISTS (
	SELECT 1 FROM Buildings WHERE BuildingType = 'BUILDING_ALCHEMICAL_SOCIETY'
);

UPDATE Building_YieldChanges
SET YieldChange = CASE YieldType
	WHEN 'YIELD_SCIENCE' THEN 4
	WHEN 'YIELD_PRODUCTION' THEN 2
END
WHERE BuildingType = 'BUILDING_ALCHEMICAL_SOCIETY'
  AND YieldType IN ('YIELD_SCIENCE', 'YIELD_PRODUCTION');

INSERT OR REPLACE INTO Resource_YieldChanges
	(ResourceType, YieldType, YieldChange)
SELECT 'RESOURCE_LEY_LINE', 'YIELD_SCIENCE', 1
WHERE EXISTS (
	SELECT 1 FROM Resources WHERE ResourceType = 'RESOURCE_LEY_LINE'
)
UNION ALL
SELECT 'RESOURCE_LEY_LINE', 'YIELD_PRODUCTION', 2
WHERE EXISTS (
	SELECT 1 FROM Resources WHERE ResourceType = 'RESOURCE_LEY_LINE'
);

UPDATE Resources
SET Frequency = 10
WHERE ResourceType = 'RESOURCE_LEY_LINE';

DELETE FROM Resource_ValidTerrains
WHERE ResourceType = 'RESOURCE_LEY_LINE'
  AND TerrainType IN (
	'TERRAIN_SNOW',
	'TERRAIN_SNOW_HILLS',
	'TERRAIN_DESERT_HILLS',
	'TERRAIN_DESERT',
	'TERRAIN_GRASS_HILLS',
	'TERRAIN_PLAINS_HILLS',
	'TERRAIN_TUNDRA_HILLS'
  );

UPDATE Adjacency_YieldChanges
SET YieldChange = 1
WHERE ID IN (
	'LeyLine_Culture',
	'LeyLine_Faith',
	'LeyLine_Gold',
	'LeyLine_Production',
	'LeyLine_Science'
);

INSERT OR IGNORE INTO District_Adjacencies
	(DistrictType, YieldChangeId)
SELECT 'DISTRICT_SEOWON', 'LeyLine_Science'
WHERE EXISTS (
	SELECT 1 FROM Districts WHERE DistrictType = 'DISTRICT_SEOWON'
)
  AND EXISTS (
	SELECT 1 FROM Adjacency_YieldChanges WHERE ID = 'LeyLine_Science'
);

UPDATE ModifierArguments
SET Value = 'YIELD_FOOD'
WHERE ModifierId = 'HERMETIC_ORDER_GREAT_ADMIRAL_LEY_LINE_SCIENCE'
  AND Name = 'YieldType';

UPDATE ModifierArguments
SET Value = 'YIELD_PRODUCTION'
WHERE ModifierId = 'HERMETIC_ORDER_GREAT_GENERAL_LEY_LINE_SCIENCE'
  AND Name = 'YieldType';

UPDATE ModifierArguments
SET Value = '2'
WHERE ModifierId = 'HERMETIC_ORDER_GREAT_MERCHANT_LEY_LINE_GOLD'
  AND Name = 'Amount';

-- ZYL LightweightBalance: Ley Lines may be removed for Gold, or improved by
-- a Farm without consuming the Ley Line resource.
INSERT OR REPLACE INTO Resource_Harvests
	(ResourceType, YieldType, Amount, PrereqTech)
SELECT 'RESOURCE_LEY_LINE', 'YIELD_GOLD', 40, NULL
WHERE EXISTS (
	SELECT 1 FROM Resources WHERE ResourceType = 'RESOURCE_LEY_LINE'
);

INSERT OR REPLACE INTO Improvement_ValidResources
	(ImprovementType, ResourceType, MustRemoveFeature)
SELECT 'IMPROVEMENT_FARM', 'RESOURCE_LEY_LINE', 0
WHERE EXISTS (
	SELECT 1 FROM Improvements WHERE ImprovementType = 'IMPROVEMENT_FARM'
)
  AND EXISTS (
	SELECT 1 FROM Resources WHERE ResourceType = 'RESOURCE_LEY_LINE'
);

------------------------------------------------------------------------------
-- Voidsingers
------------------------------------------------------------------------------
UPDATE ModifierArguments
SET Value = CASE ModifierId
	WHEN 'GOVERNOR_PROMOTION_VOIDSINGERS_2_GOLD_FROM_FAITH' THEN '10'
	WHEN 'GOVERNOR_PROMOTION_VOIDSINGERS_2_SCIENCE_FROM_FAITH' THEN '10'
	WHEN 'GOVERNOR_PROMOTION_VOIDSINGERS_2_CULTURE_FROM_FAITH' THEN '10'
END
WHERE Name = 'Amount'
  AND ModifierId IN (
	'GOVERNOR_PROMOTION_VOIDSINGERS_2_GOLD_FROM_FAITH',
	'GOVERNOR_PROMOTION_VOIDSINGERS_2_SCIENCE_FROM_FAITH',
	'GOVERNOR_PROMOTION_VOIDSINGERS_2_CULTURE_FROM_FAITH'
  );

UPDATE Building_YieldChanges
SET YieldChange = 3
WHERE BuildingType = 'BUILDING_OLD_GOD_OBELISK'
  AND YieldType = 'YIELD_FAITH';

UPDATE Units
SET Cost = 60,
	BaseMoves = 6,
	CostProgressionParam1 = 15
WHERE UnitType = 'UNIT_CULTIST';

UPDATE Units_MODE
SET ActionCharges = 1
WHERE UnitType = 'UNIT_CULTIST';

UPDATE ModifierArguments
SET Value = '10'
WHERE ModifierId = 'SPREAD_DISSENT_LOYALTY_DAMAGE'
  AND Name = 'Amount';

-- Relics of the Void are the relic rows requiring the Voidsingers governor.
UPDATE GreatWork_YieldChanges
SET YieldChange = 2
WHERE YieldType = 'YIELD_FAITH'
  AND GreatWorkType IN (
	SELECT GreatWorkType
	FROM GreatWorks_MODE
	WHERE RequiredGovernor = 'GOVERNOR_VOIDSINGERS'
  );

INSERT OR IGNORE INTO Modifiers
	(ModifierId, ModifierType)
VALUES
	('ZYL_TPVP_VOIDSINGER_RELIC_SCIENCE', 'MODIFIER_PLAYER_CITIES_ADJUST_GREATWORK_YIELD'),
	('ZYL_TPVP_VOIDSINGER_RELIC_CULTURE', 'MODIFIER_PLAYER_CITIES_ADJUST_GREATWORK_YIELD'),
	('ZYL_TPVP_VOIDSINGER_RELIC_PRODUCTION', 'MODIFIER_PLAYER_CITIES_ADJUST_GREATWORK_YIELD');

INSERT OR REPLACE INTO ModifierArguments
	(ModifierId, Name, Value)
VALUES
	('ZYL_TPVP_VOIDSINGER_RELIC_SCIENCE', 'GreatWorkObjectType', 'GREATWORKOBJECT_RELIC'),
	('ZYL_TPVP_VOIDSINGER_RELIC_SCIENCE', 'YieldType', 'YIELD_SCIENCE'),
	('ZYL_TPVP_VOIDSINGER_RELIC_SCIENCE', 'YieldChange', 2),
	('ZYL_TPVP_VOIDSINGER_RELIC_CULTURE', 'GreatWorkObjectType', 'GREATWORKOBJECT_RELIC'),
	('ZYL_TPVP_VOIDSINGER_RELIC_CULTURE', 'YieldType', 'YIELD_CULTURE'),
	('ZYL_TPVP_VOIDSINGER_RELIC_CULTURE', 'YieldChange', 2),
	('ZYL_TPVP_VOIDSINGER_RELIC_PRODUCTION', 'GreatWorkObjectType', 'GREATWORKOBJECT_RELIC'),
	('ZYL_TPVP_VOIDSINGER_RELIC_PRODUCTION', 'YieldType', 'YIELD_PRODUCTION'),
	('ZYL_TPVP_VOIDSINGER_RELIC_PRODUCTION', 'YieldChange', 1);

INSERT OR IGNORE INTO GovernorPromotionModifiers
	(GovernorPromotionType, ModifierId)
VALUES
	('GOVERNOR_PROMOTION_VOIDSINGERS_3', 'ZYL_TPVP_VOIDSINGER_RELIC_SCIENCE'),
	('GOVERNOR_PROMOTION_VOIDSINGERS_3', 'ZYL_TPVP_VOIDSINGER_RELIC_CULTURE'),
	('GOVERNOR_PROMOTION_VOIDSINGERS_3', 'ZYL_TPVP_VOIDSINGER_RELIC_PRODUCTION');

------------------------------------------------------------------------------
-- Sanguine Pact
------------------------------------------------------------------------------
-- Tier 1 vampire mobility and road-building. Vampires return to their
-- original 2 base movement; Sanguine Pact tier 2 adds the extra point.
UPDATE Units
SET BaseMoves = 2
WHERE UnitType = 'UNIT_VAMPIRE';

-- Do not inherit the upstream placeholder (+0 at tier 3) if another copy of
-- that source was loaded before this integration layer.
DELETE FROM GovernorPromotionModifiers
WHERE ModifierId = 'SECRET_SOCIETY_VAMPIRE_ADDMOVE_TEAMPVP';

DELETE FROM ModifierArguments
WHERE ModifierId = 'SECRET_SOCIETY_VAMPIRE_ADDMOVE_TEAMPVP';

DELETE FROM Modifiers
WHERE ModifierId = 'SECRET_SOCIETY_VAMPIRE_ADDMOVE_TEAMPVP';

INSERT OR IGNORE INTO Route_ValidBuildUnits (RouteType, UnitType)
VALUES
	('ROUTE_ANCIENT_ROAD', 'UNIT_VAMPIRE'),
	('ROUTE_MEDIEVAL_ROAD', 'UNIT_VAMPIRE'),
	('ROUTE_INDUSTRIAL_ROAD', 'UNIT_VAMPIRE'),
	('ROUTE_MODERN_ROAD', 'UNIT_VAMPIRE');

-- Keep the base game's vampire healing effects at their intended values:
-- passive healing is reduced by 5 (halving the normal 10 HP) and pillaging
-- restores an additional 50 HP.
INSERT OR IGNORE INTO ModifierArguments (ModifierId, Name, Value)
VALUES
	('SECRET_SOCIETIES_DISABLE_VAMPIRE_NORMAL_HEALING', 'Amount', -5),
	('SECRET_SOCIETIES_DISABLE_VAMPIRE_NORMAL_HEALING', 'Type', 'ALL'),
	('SECRET_SOCIETIES_ENABLE_VAMPIRE_PILLAGE_HEALING', 'Amount', 50),
	('SECRET_SOCIETIES_ENABLE_VAMPIRE_PILLAGE_HEALING', 'Key', 'HEAL_ON_PILLAGE');

UPDATE ModifierArguments
SET Value = '-5'
WHERE ModifierId = 'SECRET_SOCIETIES_DISABLE_VAMPIRE_NORMAL_HEALING'
	AND Name = 'Amount';

UPDATE ModifierArguments
SET Value = 'ALL'
WHERE ModifierId = 'SECRET_SOCIETIES_DISABLE_VAMPIRE_NORMAL_HEALING'
	AND Name = 'Type';

UPDATE ModifierArguments
SET Value = '50'
WHERE ModifierId = 'SECRET_SOCIETIES_ENABLE_VAMPIRE_PILLAGE_HEALING'
	AND Name = 'Amount';

UPDATE ModifierArguments
SET Value = 'HEAL_ON_PILLAGE'
WHERE ModifierId = 'SECRET_SOCIETIES_ENABLE_VAMPIRE_PILLAGE_HEALING'
	AND Name = 'Key';

-- Killing an enemy restores 10 HP, matching the Combat Department's
-- post-combat healing value while scoping the effect to Vampire units.
INSERT OR IGNORE INTO Modifiers
	(ModifierId, ModifierType, SubjectRequirementSetId)
VALUES
	('ZYL_TPVP_SANGUINE_VAMPIRE_HEAL_FROM_COMBAT_ATTACH',
	 'MODIFIER_PLAYER_UNITS_ATTACH_MODIFIER',
	 'THIS_UNIT_IS_A_VAMPIRE'),
	('ZYL_TPVP_SANGUINE_VAMPIRE_HEAL_FROM_COMBAT',
	 'MODIFIER_PLAYER_UNIT_ADJUST_HEAL_FROM_COMBAT',
	 NULL);

INSERT OR REPLACE INTO ModifierArguments (ModifierId, Name, Value)
VALUES
	('ZYL_TPVP_SANGUINE_VAMPIRE_HEAL_FROM_COMBAT_ATTACH', 'ModifierId',
	 'ZYL_TPVP_SANGUINE_VAMPIRE_HEAL_FROM_COMBAT'),
	('ZYL_TPVP_SANGUINE_VAMPIRE_HEAL_FROM_COMBAT', 'Amount', 10);

-- Advanced pillaging is a tier-1 ability (and must not remain on tier 3).
DELETE FROM GovernorPromotionModifiers
WHERE GovernorPromotionType IN (
	'GOVERNOR_PROMOTION_SANGUINE_PACT_1',
	'GOVERNOR_PROMOTION_SANGUINE_PACT_3'
)
	AND ModifierId = 'SECRET_SOCIETY_VAMPIRES_ADVANCED_PILLAGING';

INSERT OR IGNORE INTO GovernorPromotionModifiers
	(GovernorPromotionType, ModifierId)
VALUES
	('GOVERNOR_PROMOTION_SANGUINE_PACT_1', 'SECRET_SOCIETY_VAMPIRES_ADVANCED_PILLAGING'),
	('GOVERNOR_PROMOTION_SANGUINE_PACT_1', 'ZYL_TPVP_SANGUINE_VAMPIRE_HEAL_FROM_COMBAT_ATTACH');

-- Tier 1: +15% Production toward Encampments and their buildings, and
-- +1 Production from Barracks and Stables.
INSERT OR IGNORE INTO Modifiers (ModifierId, ModifierType)
VALUES
	('ZYL_TPVP_SANGUINE_ENCAMPMENT_PRODUCTION', 'MODIFIER_PLAYER_CITIES_ADJUST_DISTRICT_PRODUCTION'),
	('ZYL_TPVP_SANGUINE_ENCAMPMENT_BUILDING_PRODUCTION', 'MODIFIER_PLAYER_CITIES_ADJUST_BUILDING_PRODUCTION'),
	('ZYL_TPVP_SANGUINE_BARRACKS_PRODUCTION', 'MODIFIER_PLAYER_CITIES_ADJUST_BUILDING_YIELD_CHANGE'),
	('ZYL_TPVP_SANGUINE_STABLE_PRODUCTION', 'MODIFIER_PLAYER_CITIES_ADJUST_BUILDING_YIELD_CHANGE'),
	('ZYL_TPVP_SANGUINE_ARMORY_PRODUCTION', 'MODIFIER_PLAYER_CITIES_ADJUST_BUILDING_YIELD_CHANGE'),
	('ZYL_TPVP_SANGUINE_MILITARY_ACADEMY_PRODUCTION', 'MODIFIER_PLAYER_CITIES_ADJUST_BUILDING_YIELD_CHANGE'),
	('ZYL_TPVP_SANGUINE_MILITARY_POLICY_SLOT', 'MODIFIER_PLAYER_CULTURE_ADJUST_GOVERNMENT_SLOTS_MODIFIER');

INSERT OR IGNORE INTO Modifiers
	(ModifierId, ModifierType, SubjectRequirementSetId)
VALUES
	('ZYL_TPVP_SANGUINE_VAMPIRE_MOVEMENT', 'MODIFIER_PLAYER_UNITS_ADJUST_MOVEMENT', 'THIS_UNIT_IS_A_VAMPIRE');

INSERT OR REPLACE INTO ModifierArguments (ModifierId, Name, Value)
VALUES
	('ZYL_TPVP_SANGUINE_ENCAMPMENT_PRODUCTION', 'DistrictType', 'DISTRICT_ENCAMPMENT'),
	('ZYL_TPVP_SANGUINE_ENCAMPMENT_PRODUCTION', 'Amount', 15),
	('ZYL_TPVP_SANGUINE_ENCAMPMENT_BUILDING_PRODUCTION', 'DistrictType', 'DISTRICT_ENCAMPMENT'),
	('ZYL_TPVP_SANGUINE_ENCAMPMENT_BUILDING_PRODUCTION', 'Amount', 15),
	('ZYL_TPVP_SANGUINE_BARRACKS_PRODUCTION', 'BuildingType', 'BUILDING_BARRACKS'),
	('ZYL_TPVP_SANGUINE_BARRACKS_PRODUCTION', 'YieldType', 'YIELD_PRODUCTION'),
	('ZYL_TPVP_SANGUINE_BARRACKS_PRODUCTION', 'Amount', 1),
	('ZYL_TPVP_SANGUINE_STABLE_PRODUCTION', 'BuildingType', 'BUILDING_STABLE'),
	('ZYL_TPVP_SANGUINE_STABLE_PRODUCTION', 'YieldType', 'YIELD_PRODUCTION'),
	('ZYL_TPVP_SANGUINE_STABLE_PRODUCTION', 'Amount', 1),
	('ZYL_TPVP_SANGUINE_ARMORY_PRODUCTION', 'BuildingType', 'BUILDING_ARMORY'),
	('ZYL_TPVP_SANGUINE_ARMORY_PRODUCTION', 'YieldType', 'YIELD_PRODUCTION'),
	('ZYL_TPVP_SANGUINE_ARMORY_PRODUCTION', 'Amount', 2),
	('ZYL_TPVP_SANGUINE_MILITARY_ACADEMY_PRODUCTION', 'BuildingType', 'BUILDING_MILITARY_ACADEMY'),
	('ZYL_TPVP_SANGUINE_MILITARY_ACADEMY_PRODUCTION', 'YieldType', 'YIELD_PRODUCTION'),
	('ZYL_TPVP_SANGUINE_MILITARY_ACADEMY_PRODUCTION', 'Amount', 4),
	('ZYL_TPVP_SANGUINE_MILITARY_POLICY_SLOT', 'GovernmentSlotType', 'SLOT_MILITARY'),
	('ZYL_TPVP_SANGUINE_VAMPIRE_MOVEMENT', 'Amount', 1);

INSERT OR IGNORE INTO GovernorPromotionModifiers
	(GovernorPromotionType, ModifierId)
VALUES
	('GOVERNOR_PROMOTION_SANGUINE_PACT_1', 'ZYL_TPVP_SANGUINE_ENCAMPMENT_PRODUCTION'),
	('GOVERNOR_PROMOTION_SANGUINE_PACT_1', 'ZYL_TPVP_SANGUINE_ENCAMPMENT_BUILDING_PRODUCTION'),
	('GOVERNOR_PROMOTION_SANGUINE_PACT_1', 'ZYL_TPVP_SANGUINE_BARRACKS_PRODUCTION'),
	('GOVERNOR_PROMOTION_SANGUINE_PACT_1', 'ZYL_TPVP_SANGUINE_STABLE_PRODUCTION'),
	('GOVERNOR_PROMOTION_SANGUINE_PACT_2', 'ZYL_TPVP_SANGUINE_ARMORY_PRODUCTION'),
	('GOVERNOR_PROMOTION_SANGUINE_PACT_2', 'ZYL_TPVP_SANGUINE_MILITARY_POLICY_SLOT'),
	('GOVERNOR_PROMOTION_SANGUINE_PACT_2', 'ZYL_TPVP_SANGUINE_VAMPIRE_MOVEMENT'),
	('GOVERNOR_PROMOTION_SANGUINE_PACT_3', 'ZYL_TPVP_SANGUINE_MILITARY_ACADEMY_PRODUCTION');

INSERT OR IGNORE INTO ModifierArguments
	(ModifierId, Name, Value)
SELECT 'SANGUINE_PACT_VAMPIRE_COMBAT_STRENGTH_FROM_PROPERTY', 'Max', 3
WHERE EXISTS (
	SELECT 1
	FROM Modifiers
	WHERE ModifierId = 'SANGUINE_PACT_VAMPIRE_COMBAT_STRENGTH_FROM_PROPERTY'
);

UPDATE ModifierArguments
SET Value = '3'
WHERE ModifierId = 'SANGUINE_PACT_VAMPIRE_COMBAT_STRENGTH_FROM_PROPERTY'
  AND Name = 'Max';

UPDATE ModifierArguments
SET Value = '0'
WHERE ModifierId = 'SANGUINE_PACT_VAMPIRE_BARB_COMBAT_STRENGTH_FROM_PROPERTY'
  AND Name = 'Max';

UPDATE ModifierArguments
SET Value = '-2'
WHERE ModifierId = 'SECRET_SOCIETY_INTIMIDATE_ADJACENT_ENEMIES_MODIFIER'
  AND Name = 'Amount';

-- Vampires inherit the melee anti-anti-cavalry bonus.  Team PVP offsets half
-- of it so Vampires have only +5 instead of +10 versus anti-cavalry units.
INSERT OR IGNORE INTO Types
	(Type, Kind)
VALUES
	('ABILITY_ZYL_TPVP_VAMPIRE_ANTI_ANTI_CAVALRY', 'KIND_ABILITY');

INSERT OR IGNORE INTO TypeTags
	(Type, Tag)
VALUES
	('ABILITY_ZYL_TPVP_VAMPIRE_ANTI_ANTI_CAVALRY', 'CLASS_VAMPIRE');

INSERT OR IGNORE INTO UnitAbilities
	(UnitAbilityType, Name, Description)
VALUES
	(
		'ABILITY_ZYL_TPVP_VAMPIRE_ANTI_ANTI_CAVALRY',
		'LOC_ABILITY_ZYL_TPVP_VAMPIRE_ANTI_ANTI_CAVALRY_NAME',
		'LOC_ABILITY_ZYL_TPVP_VAMPIRE_ANTI_ANTI_CAVALRY_DESCRIPTION'
	);

INSERT OR IGNORE INTO Modifiers
	(ModifierId, ModifierType, SubjectRequirementSetId)
VALUES
	(
		'ZYL_TPVP_VAMPIRE_ANTI_ANTI_CAVALRY',
		'MODIFIER_UNIT_ADJUST_COMBAT_STRENGTH',
		'ANTI_SPEAR_OPPONENT_REQUIREMENTS'
	);

INSERT OR REPLACE INTO ModifierArguments
	(ModifierId, Name, Value)
VALUES
	('ZYL_TPVP_VAMPIRE_ANTI_ANTI_CAVALRY', 'Amount', -5);

INSERT OR IGNORE INTO UnitAbilityModifiers
	(UnitAbilityType, ModifierId)
VALUES
	('ABILITY_ZYL_TPVP_VAMPIRE_ANTI_ANTI_CAVALRY', 'ZYL_TPVP_VAMPIRE_ANTI_ANTI_CAVALRY');

INSERT OR REPLACE INTO ModifierStrings
	(ModifierId, Context, Text)
VALUES
	(
		'ZYL_TPVP_VAMPIRE_ANTI_ANTI_CAVALRY',
		'Preview',
		'LOC_ABILITY_ZYL_TPVP_VAMPIRE_ANTI_ANTI_CAVALRY_MODIFIER'
	);

-- Castle caps are 2/3/4 at tiers 2/3/4.
DELETE FROM GovernorPromotionModifiers
WHERE GovernorPromotionType IN (
	'GOVERNOR_PROMOTION_SANGUINE_PACT_2',
	'GOVERNOR_PROMOTION_SANGUINE_PACT_3',
	'GOVERNOR_PROMOTION_SANGUINE_PACT_4'
)
  AND ModifierId IN (
	'SECRET_SOCIETY_GRANT_ONE_VAMPIRE_BUILD',
	'SECRET_SOCIETY_GRANT_TWO_VAMPIRE_BUILDS'
  );

INSERT OR IGNORE INTO GovernorPromotionModifiers
	(GovernorPromotionType, ModifierId)
VALUES
	('GOVERNOR_PROMOTION_SANGUINE_PACT_2', 'SECRET_SOCIETY_GRANT_TWO_VAMPIRE_BUILDS'),
	('GOVERNOR_PROMOTION_SANGUINE_PACT_3', 'SECRET_SOCIETY_GRANT_ONE_VAMPIRE_BUILD'),
	('GOVERNOR_PROMOTION_SANGUINE_PACT_4', 'SECRET_SOCIETY_GRANT_ONE_VAMPIRE_BUILD');

UPDATE Improvements
SET CanBuildOutsideTerritory = 0
WHERE ImprovementType = 'IMPROVEMENT_VAMPIRE_CASTLE';

-- Vampire Castles clear their tile on completion, like districts.  Permit
-- construction on removable features and normal resources here; the paired
-- gameplay script removes both without awarding harvest yields.
INSERT OR IGNORE INTO Improvement_ValidFeatures
	(ImprovementType, FeatureType)
SELECT
	'IMPROVEMENT_VAMPIRE_CASTLE',
	FeatureType
FROM Features
WHERE Removable = 1;

INSERT OR IGNORE INTO Improvement_ValidResources
	(ImprovementType, ResourceType, MustRemoveFeature)
SELECT
	'IMPROVEMENT_VAMPIRE_CASTLE',
	ResourceType,
	0
FROM Resources
WHERE ResourceClassType IN (
	'RESOURCECLASS_BONUS',
	'RESOURCECLASS_LUXURY',
	'RESOURCECLASS_STRATEGIC'
);

DELETE FROM UnitRetreats_XP1
WHERE UnitRetreatType = 'UNIT_RETREAT_VAMPIRE_TO_CASTLE'
  AND UnitType = 'UNIT_VAMPIRE'
  AND ImprovementType = 'IMPROVEMENT_VAMPIRE_CASTLE';

-- Remove the base game's globally attached dynamic copy-yields effect.  The
-- fixed castle yields and explicit adjacencies below avoid the multiplayer
-- perspective/reload desynchronization in that effect.
DELETE FROM GameModifiers
WHERE ModifierId = 'SECRET_SOCIETIES_ATTACH_PLAYER_CASTLES_GAIN_ADJACENT_YIELDS';

INSERT OR REPLACE INTO Improvement_YieldChanges
	(ImprovementType, YieldType, YieldChange)
VALUES
	('IMPROVEMENT_VAMPIRE_CASTLE', 'YIELD_FOOD', 9),
	('IMPROVEMENT_VAMPIRE_CASTLE', 'YIELD_PRODUCTION', 5),
	('IMPROVEMENT_VAMPIRE_CASTLE', 'YIELD_FAITH', 0),
	('IMPROVEMENT_VAMPIRE_CASTLE', 'YIELD_GOLD', 0),
	('IMPROVEMENT_VAMPIRE_CASTLE', 'YIELD_CULTURE', 0),
	('IMPROVEMENT_VAMPIRE_CASTLE', 'YIELD_SCIENCE', 0);

INSERT OR IGNORE INTO Adjacency_YieldChanges
	(ID, Description, YieldType, YieldChange, TilesRequired, AdjacentTerrain)
VALUES
	('ZYL_TPVP_VC_TUNDRA_HILLS', 'Placeholder', 'YIELD_PRODUCTION', 1, 1, 'TERRAIN_TUNDRA_HILLS'),
	('ZYL_TPVP_VC_PLAINS_HILLS', 'Placeholder', 'YIELD_PRODUCTION', 1, 1, 'TERRAIN_PLAINS_HILLS'),
	('ZYL_TPVP_VC_GRASS_HILLS', 'Placeholder', 'YIELD_PRODUCTION', 1, 1, 'TERRAIN_GRASS_HILLS'),
	('ZYL_TPVP_VC_DESERT_HILLS', 'Placeholder', 'YIELD_PRODUCTION', 1, 1, 'TERRAIN_DESERT_HILLS');

INSERT OR IGNORE INTO Adjacency_YieldChanges
	(ID, Description, YieldType, YieldChange, TilesRequired, AdjacentFeature)
VALUES
	('ZYL_TPVP_VC_FOREST', 'Placeholder', 'YIELD_PRODUCTION', 1, 1, 'FEATURE_FOREST'),
	('ZYL_TPVP_VC_JUNGLE', 'Placeholder', 'YIELD_PRODUCTION', 1, 1, 'FEATURE_JUNGLE');

INSERT OR IGNORE INTO Adjacency_YieldChanges
	(ID, Description, YieldType, YieldChange, TilesRequired, AdjacentResourceClass)
VALUES
	('ZYL_TPVP_VC_BONUS_RESOURCE', 'Placeholder', 'YIELD_PRODUCTION', 1, 1, 'RESOURCECLASS_BONUS'),
	('ZYL_TPVP_VC_LUXURY_RESOURCE', 'Placeholder', 'YIELD_PRODUCTION', 1, 1, 'RESOURCECLASS_LUXURY'),
	('ZYL_TPVP_VC_STRATEGIC_RESOURCE', 'Placeholder', 'YIELD_PRODUCTION', 1, 1, 'RESOURCECLASS_STRATEGIC');

INSERT OR IGNORE INTO Adjacency_YieldChanges
	(ID, Description, YieldType, YieldChange, TilesRequired, AdjacentImprovement)
VALUES
	('ZYL_TPVP_VC_MINE', 'Placeholder', 'YIELD_PRODUCTION', 1, 1, 'IMPROVEMENT_MINE'),
	('ZYL_TPVP_VC_LUMBER_MILL', 'Placeholder', 'YIELD_PRODUCTION', 1, 1, 'IMPROVEMENT_LUMBER_MILL'),
	('ZYL_TPVP_VC_FISHING_BOATS', 'Placeholder', 'YIELD_PRODUCTION', 1, 1, 'IMPROVEMENT_FISHING_BOATS'),
	('ZYL_TPVP_VC_PASTURE', 'Placeholder', 'YIELD_PRODUCTION', 1, 1, 'IMPROVEMENT_PASTURE'),
	('ZYL_TPVP_VC_PLANTATION', 'Placeholder', 'YIELD_PRODUCTION', 1, 1, 'IMPROVEMENT_PLANTATION'),
	('ZYL_TPVP_VC_QUARRY', 'Placeholder', 'YIELD_PRODUCTION', 1, 1, 'IMPROVEMENT_QUARRY'),
	('ZYL_TPVP_VC_CAMP', 'Placeholder', 'YIELD_PRODUCTION', 1, 1, 'IMPROVEMENT_CAMP');

-- Only create district rows for districts that exist in the current DLC set.
INSERT OR IGNORE INTO Adjacency_YieldChanges
	(ID, Description, YieldType, YieldChange, TilesRequired, AdjacentDistrict)
SELECT
	'ZYL_TPVP_VC_DISTRICT_' || DistrictType,
	'Placeholder',
	CASE
		WHEN DistrictType IN ('DISTRICT_HOLY_SITE', 'DISTRICT_LAVRA') THEN 'YIELD_FAITH'
		WHEN DistrictType IN (
			'DISTRICT_HARBOR',
			'DISTRICT_ROYAL_NAVY_DOCKYARD',
			'DISTRICT_COTHON',
			'DISTRICT_COMMERCIAL_HUB',
			'DISTRICT_SUGUBA'
		) THEN 'YIELD_GOLD'
		WHEN DistrictType IN ('DISTRICT_THEATER', 'DISTRICT_ACROPOLIS') THEN 'YIELD_CULTURE'
		WHEN DistrictType IN (
			'DISTRICT_INDUSTRIAL_ZONE',
			'DISTRICT_HANSA',
			'DISTRICT_OPPIDUM'
		) THEN 'YIELD_PRODUCTION'
		ELSE 'YIELD_SCIENCE'
	END,
	CASE
		WHEN DistrictType IN (
			'DISTRICT_HARBOR',
			'DISTRICT_ROYAL_NAVY_DOCKYARD',
			'DISTRICT_COTHON',
			'DISTRICT_COMMERCIAL_HUB',
			'DISTRICT_SUGUBA'
		) THEN 2
		ELSE 1
	END,
	1,
	DistrictType
FROM Districts
WHERE DistrictType IN (
	'DISTRICT_HOLY_SITE',
	'DISTRICT_LAVRA',
	'DISTRICT_HARBOR',
	'DISTRICT_ROYAL_NAVY_DOCKYARD',
	'DISTRICT_COTHON',
	'DISTRICT_COMMERCIAL_HUB',
	'DISTRICT_SUGUBA',
	'DISTRICT_THEATER',
	'DISTRICT_ACROPOLIS',
	'DISTRICT_INDUSTRIAL_ZONE',
	'DISTRICT_HANSA',
	'DISTRICT_OPPIDUM',
	'DISTRICT_CAMPUS',
	'DISTRICT_OBSERVATORY',
	'DISTRICT_SEOWON'
);

INSERT OR IGNORE INTO Improvement_Adjacencies
	(ImprovementType, YieldChangeId)
VALUES
	('IMPROVEMENT_VAMPIRE_CASTLE', 'ZYL_TPVP_VC_TUNDRA_HILLS'),
	('IMPROVEMENT_VAMPIRE_CASTLE', 'ZYL_TPVP_VC_PLAINS_HILLS'),
	('IMPROVEMENT_VAMPIRE_CASTLE', 'ZYL_TPVP_VC_GRASS_HILLS'),
	('IMPROVEMENT_VAMPIRE_CASTLE', 'ZYL_TPVP_VC_DESERT_HILLS'),
	('IMPROVEMENT_VAMPIRE_CASTLE', 'ZYL_TPVP_VC_FOREST'),
	('IMPROVEMENT_VAMPIRE_CASTLE', 'ZYL_TPVP_VC_JUNGLE'),
	('IMPROVEMENT_VAMPIRE_CASTLE', 'ZYL_TPVP_VC_BONUS_RESOURCE'),
	('IMPROVEMENT_VAMPIRE_CASTLE', 'ZYL_TPVP_VC_LUXURY_RESOURCE'),
	('IMPROVEMENT_VAMPIRE_CASTLE', 'ZYL_TPVP_VC_STRATEGIC_RESOURCE'),
	('IMPROVEMENT_VAMPIRE_CASTLE', 'ZYL_TPVP_VC_MINE'),
	('IMPROVEMENT_VAMPIRE_CASTLE', 'ZYL_TPVP_VC_LUMBER_MILL'),
	('IMPROVEMENT_VAMPIRE_CASTLE', 'ZYL_TPVP_VC_FISHING_BOATS'),
	('IMPROVEMENT_VAMPIRE_CASTLE', 'ZYL_TPVP_VC_PASTURE'),
	('IMPROVEMENT_VAMPIRE_CASTLE', 'ZYL_TPVP_VC_PLANTATION'),
	('IMPROVEMENT_VAMPIRE_CASTLE', 'ZYL_TPVP_VC_QUARRY'),
	('IMPROVEMENT_VAMPIRE_CASTLE', 'ZYL_TPVP_VC_CAMP');

INSERT OR IGNORE INTO Improvement_Adjacencies
	(ImprovementType, YieldChangeId)
SELECT 'IMPROVEMENT_VAMPIRE_CASTLE', ID
FROM Adjacency_YieldChanges
WHERE ID LIKE 'ZYL_TPVP_VC_DISTRICT_%';
