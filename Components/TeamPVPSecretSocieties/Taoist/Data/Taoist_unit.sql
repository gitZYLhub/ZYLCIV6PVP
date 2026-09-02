-- Taoist_unit
-- Author: pen
-- DateCreated: 2023/6/8 10:33:21
--------------------------------------------------------------
insert or replace into Types
(Type,												Kind)
values
('UNIT_TAOIST',										'KIND_UNIT');

insert or replace into Units
(UnitType,			Name,					Description,					Cost,	BaseMoves,	BaseSightRange,		Domain,			CanCapture,	CanRetreatWhenCaptured,	CanTrain,	FormationClass,				PromotionClass,					AdvisorType,		PurchaseYield,		PseudoYieldType,CostProgressionModel,				CostProgressionParam1,	CanEarnExperience,	TraitType)
values
('UNIT_TAOIST',		'LOC_UNIT_TAOIST_NAME',	'LOC_UNIT_TAOIST_DESCRIPTION',	150,	3,			1,					'DOMAIN_LAND',	1,			0,						0,			'FORMATION_CLASS_SUPPORT',	null,							'ADVISOR_GENERIC',	'YIELD_GOLD',		null,			'COST_PROGRESSION_PREVIOUS_COPIES',	50,						0,					null);

insert or replace into Units_MODE
(UnitType,					ActionCharges)
values
-- The reference entry used 0, which left a newly granted detector with no
-- usable operation.  One initial charge is required for its copied UI action.
('UNIT_TAOIST',				1);

-- Great-Person-style protection: captured Taoists retreat to the capital
-- instead of converting into the optional Earth Engineer unit.
UPDATE Units
SET CanCapture = 0,
	CanRetreatWhenCaptured = 1
WHERE UnitType = 'UNIT_TAOIST';

-- Do not let the optional fifth-society package's Earth Engineer conversion
-- override the Great-Person-style retreat used by the integrated package.
DELETE FROM UnitCaptures
WHERE CapturedUnitType = 'UNIT_TAOIST';

insert or replace into UnitAiInfos
(UnitType,					AiType)
values
('UNIT_TAOIST',				'UNITTYPE_CIVILIAN'),
('UNIT_TAOIST',				'UNITAI_EXPLORE');

insert or replace into GovernorPromotionModifiers
(GovernorPromotionType,					ModifierId)
values
('GOVERNOR_PROMOTION_HERMETIC_ORDER_2',	'HERMETIC_BUILDING_GAIN_TAOIST'),
-- This immediate rank-up grant is intentionally separate from the existing
-- first-Alchemical-Society grant above, so both rewards can fire once.
('GOVERNOR_PROMOTION_HERMETIC_ORDER_2',	'HERMETIC_ORDER_2_GAIN_TAOIST'),
('GOVERNOR_PROMOTION_HERMETIC_ORDER_1',	'HERMETIC_GAIN_TAOIST');

insert or replace into Modifiers
(ModifierId,							ModifierType,									RunOnce,	Permanent,	SubjectRequirementSetId,			OwnerStackLimit,	SubjectStackLimit)
values
('HERMETIC_BUILDING_GAIN_TAOIST',		'MODIFIER_PLAYER_GRANT_UNIT_IN_CAPITAL',		1,			1,			'TAOIST_HAS_BUILDING_REQUIREMENTS',	1,					1),
('HERMETIC_ORDER_2_GAIN_TAOIST',		'MODIFIER_PLAYER_GRANT_UNIT_IN_CAPITAL',		1,			1,			null,							1,					1),
('HERMETIC_GAIN_TAOIST',				'MODIFIER_PLAYER_GRANT_UNIT_IN_CAPITAL',		1,			1,			'TAOIST_HAS_CIVIC_REQUIREMENTS',	1,					1);

insert or replace into ModifierArguments
(ModifierId,							Name,					value)
values
('HERMETIC_BUILDING_GAIN_TAOIST',		'UnitType',				'UNIT_TAOIST'),
('HERMETIC_BUILDING_GAIN_TAOIST',		'Amount',				1),
('HERMETIC_BUILDING_GAIN_TAOIST',		'AllowUniqueOverride',	0),
('HERMETIC_ORDER_2_GAIN_TAOIST',		'UnitType',				'UNIT_TAOIST'),
('HERMETIC_ORDER_2_GAIN_TAOIST',		'Amount',				1),
('HERMETIC_ORDER_2_GAIN_TAOIST',		'AllowUniqueOverride',	0),
('HERMETIC_GAIN_TAOIST',				'UnitType',				'UNIT_TAOIST'),
('HERMETIC_GAIN_TAOIST',				'Amount',				1),
('HERMETIC_GAIN_TAOIST',				'AllowUniqueOverride',	0);

insert or replace into Tags 
(Tag,					Vocabulary)
values
('CLASS_TAOIST',		'ABILITY_CLASS');

insert or replace into TypeTags
(Type,										Tag)
values
('UNIT_TAOIST',								'CLASS_LANDCIVILIAN'),	
('UNIT_TAOIST',								'CLASS_TAOIST');

insert or replace into TypeProperties
(Type,					Name,						Value,		PropertyType)
values
('UNIT_TAOIST',			'CAN_TELEPORT_TO_CITY',		1,			'PROPERTYTYPE_IDENTITY');

insert or replace into RequirementSets (RequirementSetId,RequirementSetType)
values
('TAOIST_HAS_CIVIC_REQUIREMENTS',				'REQUIREMENTSET_TEST_ALL'),
('TAOIST_HAS_BUILDING_REQUIREMENTS',			'REQUIREMENTSET_TEST_ALL');

insert or replace into RequirementSetRequirements (RequirementSetId,RequirementId)
values
('TAOIST_HAS_CIVIC_REQUIREMENTS',				'TAOIST_HAS_CIVIC'),
('TAOIST_HAS_BUILDING_REQUIREMENTS',			'TAOIST_HAS_BUILDING_ALCHEMICAL_SOCIETY');

insert or replace into Requirements (RequirementId,RequirementType)
values
('TAOIST_HAS_CIVIC',						'REQUIREMENT_PLAYER_HAS_CIVIC'),
('TAOIST_HAS_BUILDING_ALCHEMICAL_SOCIETY',	'REQUIREMENT_PLAYER_HAS_BUILDING');

insert or replace into RequirementArguments(RequirementId,Name,Value)
values
('TAOIST_HAS_CIVIC',						'CivicType',	'CIVIC_FOREIGN_TRADE'),
('TAOIST_HAS_BUILDING_ALCHEMICAL_SOCIETY',	'BuildingType',	'BUILDING_ALCHEMICAL_SOCIETY');
