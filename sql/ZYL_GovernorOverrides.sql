-------------------------------------------------------------------------------
-- ZYLPVPMOD Magnus tier-one promotions
-- Rise and Fall / Gathering Storm only.
-------------------------------------------------------------------------------

-- Left I: remove +20% Growth and move the no-population-cost Settler effect
-- here from Right I.  The existing +1 Food/+1 Production internal-route
-- effects remain on Left I.
DELETE FROM GovernorPromotionModifiers
WHERE ModifierId IN (
	'SURPLUS_LOGISTICS_EXTRA_GROWTH',
	'EXPEDITION_ADJUST_SETTLERS_CONSUME_POPULATION'
);

INSERT OR IGNORE INTO GovernorPromotionModifiers (GovernorPromotionType, ModifierId)
	SELECT 'GOVERNOR_PROMOTION_RESOURCE_MANAGER_EXPEDITION',
		'EXPEDITION_ADJUST_SETTLERS_CONSUME_POPULATION'
	WHERE EXISTS (
		SELECT 1
		FROM Modifiers
		WHERE ModifierId = 'EXPEDITION_ADJUST_SETTLERS_CONSUME_POPULATION'
	);

-- Right I: +40% Production toward Industrial Zone buildings.
UPDATE ModifierArguments
SET Value = '40'
WHERE ModifierId = 'BBG_GOVERNOR_MAGNUS_PROD_IZ'
  AND Name = 'Amount';
