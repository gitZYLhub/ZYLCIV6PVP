--==================
-- Sweden
--==================
-- +50% prod to uiniversity replacement in secret societies
INSERT OR IGNORE INTO TraitModifiers (TraitType , ModifierId)
        VALUES
        ('TRAIT_CIVILIZATION_NOBEL_PRIZE' , 'NOBEL_PRIZE_ALCHEMICAL_SOCIETY_BOOST' );
INSERT OR IGNORE INTO Modifiers (ModifierId , ModifierType , SubjectRequirementSetId)
        VALUES
        ('NOBEL_PRIZE_ALCHEMICAL_SOCIETY_BOOST' , 'MODIFIER_PLAYER_CITIES_ADJUST_BUILDING_PRODUCTION' , null);
INSERT OR IGNORE INTO ModifierArguments (ModifierId , Name , Value)
        VALUES
        ('NOBEL_PRIZE_ALCHEMICAL_SOCIETY_BOOST' , 'BuildingType' , 'BUILDING_ALCHEMICAL_SOCIETY'),
        ('NOBEL_PRIZE_ALCHEMICAL_SOCIETY_BOOST' , 'Amount'       , '50');

--==================
-- Free Secret Society titles
--==================
-- Selecting a society promotion normally consumes one Governor Title. Attach
-- the base-game Governor Title grant to every society tier so the spent title
-- is immediately refunded. This includes tier 1: joining a society therefore
-- leaves the discovery title available for a normal Governor, matching
-- ZYL_LightweightBalance. INSERT OR IGNORE keeps repeated database loads safe.
INSERT OR IGNORE INTO GovernorPromotionModifiers
        (GovernorPromotionType, ModifierId)
SELECT GovernorPromotionType, 'CIVIC_GRANT_PLAYER_GOVERNOR_POINTS'
FROM GovernorPromotions
WHERE GovernorPromotionType IN (
        'GOVERNOR_PROMOTION_OWLS_OF_MINERVA_1',
        'GOVERNOR_PROMOTION_OWLS_OF_MINERVA_2',
        'GOVERNOR_PROMOTION_OWLS_OF_MINERVA_3',
        'GOVERNOR_PROMOTION_OWLS_OF_MINERVA_4',
        'GOVERNOR_PROMOTION_HERMETIC_ORDER_1',
        'GOVERNOR_PROMOTION_HERMETIC_ORDER_2',
        'GOVERNOR_PROMOTION_HERMETIC_ORDER_3',
        'GOVERNOR_PROMOTION_HERMETIC_ORDER_4',
        'GOVERNOR_PROMOTION_VOIDSINGERS_1',
        'GOVERNOR_PROMOTION_VOIDSINGERS_2',
        'GOVERNOR_PROMOTION_VOIDSINGERS_3',
        'GOVERNOR_PROMOTION_VOIDSINGERS_4',
        'GOVERNOR_PROMOTION_SANGUINE_PACT_1',
        'GOVERNOR_PROMOTION_SANGUINE_PACT_2',
        'GOVERNOR_PROMOTION_SANGUINE_PACT_3',
        'GOVERNOR_PROMOTION_SANGUINE_PACT_4'
)
  AND EXISTS (
        SELECT 1
        FROM Modifiers
        WHERE ModifierId = 'CIVIC_GRANT_PLAYER_GOVERNOR_POINTS'
  );
