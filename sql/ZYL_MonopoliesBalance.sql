-- Team PVP Balanced mod 行业 1.01 balance for Industries and Corporations.
-- Products deliberately use the matching Industry value. Growth housing bonuses
-- are not changed here, so Industries/Products keep +3 and Corporations keep +6.

-- Industries
UPDATE ModifierArguments SET Value = '10' WHERE ModifierId = 'INDUSTRY_CITY_GROWTH' AND Name = 'Amount';
UPDATE ModifierArguments SET Value = '15' WHERE ModifierId = 'INDUSTRY_MILITARY_UNIT_DISCOUNT' AND Name = 'Amount';
UPDATE ModifierArguments SET Value = '15' WHERE ModifierId = 'INDUSTRY_CIVILIAN_UNIT_DISCOUNT' AND Name = 'Amount';
UPDATE ModifierArguments SET Value = '15' WHERE ModifierId = 'INDUSTRY_BUILDING_DISCOUNT' AND Name = 'Amount';
UPDATE ModifierArguments SET Value = '15' WHERE ModifierId = 'INDUSTRY_GOLD_YIELD_BONUS' AND Name = 'Amount';
UPDATE ModifierArguments SET Value = '20' WHERE ModifierId = 'INDUSTRY_FAITH_YIELD_BONUS' AND Name = 'Amount';
UPDATE ModifierArguments SET Value = '7' WHERE ModifierId = 'INDUSTRY_SCIENCE_YIELD_BONUS' AND Name = 'Amount';
UPDATE ModifierArguments SET Value = '7' WHERE ModifierId = 'INDUSTRY_CULTURE_YIELD_BONUS' AND Name = 'Amount';

-- Corporations
UPDATE ModifierArguments SET Value = '20' WHERE ModifierId = 'CORPORATION_CITY_GROWTH' AND Name = 'Amount';
UPDATE ModifierArguments SET Value = '30' WHERE ModifierId = 'CORPORATION_MILITARY_UNIT_DISCOUNT' AND Name = 'Amount';
UPDATE ModifierArguments SET Value = '30' WHERE ModifierId = 'CORPORATION_CIVILIAN_UNIT_DISCOUNT' AND Name = 'Amount';
UPDATE ModifierArguments SET Value = '30' WHERE ModifierId = 'CORPORATION_BUILDING_DISCOUNT' AND Name = 'Amount';
UPDATE ModifierArguments SET Value = '30' WHERE ModifierId = 'CORPORATION_GOLD_YIELD_BONUS' AND Name = 'Amount';
UPDATE ModifierArguments SET Value = '40' WHERE ModifierId = 'CORPORATION_FAITH_YIELD_BONUS' AND Name = 'Amount';
UPDATE ModifierArguments SET Value = '15' WHERE ModifierId = 'CORPORATION_SCIENCE_YIELD_BONUS' AND Name = 'Amount';
UPDATE ModifierArguments SET Value = '15' WHERE ModifierId = 'CORPORATION_CULTURE_YIELD_BONUS' AND Name = 'Amount';

-- Base-game and DLC products
UPDATE ModifierArguments SET Value = '15' WHERE ModifierId = 'PRODUCT_BUILDING_DISCOUNT_GYPSUM' AND Name = 'Amount';
UPDATE ModifierArguments SET Value = '15' WHERE ModifierId = 'PRODUCT_BUILDING_DISCOUNT_MARBLE' AND Name = 'Amount';
UPDATE ModifierArguments SET Value = '15' WHERE ModifierId = 'PRODUCT_MILITARY_UNIT_DISCOUNT_CITRUS' AND Name = 'Amount';
UPDATE ModifierArguments SET Value = '15' WHERE ModifierId = 'PRODUCT_MILITARY_UNIT_DISCOUNT_COTTON' AND Name = 'Amount';
UPDATE ModifierArguments SET Value = '15' WHERE ModifierId = 'PRODUCT_MILITARY_UNIT_DISCOUNT_IVORY' AND Name = 'Amount';
UPDATE ModifierArguments SET Value = '15' WHERE ModifierId = 'PRODUCT_MILITARY_UNIT_DISCOUNT_TOBACCO' AND Name = 'Amount';
UPDATE ModifierArguments SET Value = '15' WHERE ModifierId = 'PRODUCT_MILITARY_UNIT_DISCOUNT_WHALES' AND Name = 'Amount';
UPDATE ModifierArguments SET Value = '10' WHERE ModifierId = 'PRODUCT_CITY_GROWTH_COCOA' AND Name = 'Amount';
UPDATE ModifierArguments SET Value = '10' WHERE ModifierId = 'PRODUCT_CITY_GROWTH_HONEY' AND Name = 'Amount';
UPDATE ModifierArguments SET Value = '10' WHERE ModifierId = 'PRODUCT_CITY_GROWTH_SALT' AND Name = 'Amount';
UPDATE ModifierArguments SET Value = '10' WHERE ModifierId = 'PRODUCT_CITY_GROWTH_SUGAR' AND Name = 'Amount';
UPDATE ModifierArguments SET Value = '7' WHERE ModifierId = 'PRODUCT_CULTURE_YIELD_BONUS_COFFEE' AND Name = 'Amount';
UPDATE ModifierArguments SET Value = '7' WHERE ModifierId = 'PRODUCT_CULTURE_YIELD_BONUS_SILK' AND Name = 'Amount';
UPDATE ModifierArguments SET Value = '7' WHERE ModifierId = 'PRODUCT_CULTURE_YIELD_BONUS_SPICES' AND Name = 'Amount';
UPDATE ModifierArguments SET Value = '7' WHERE ModifierId = 'PRODUCT_CULTURE_YIELD_BONUS_WINE' AND Name = 'Amount';
UPDATE ModifierArguments SET Value = '15' WHERE ModifierId = 'PRODUCT_GOLD_YIELD_BONUS_DIAMONDS' AND Name = 'Amount';
UPDATE ModifierArguments SET Value = '15' WHERE ModifierId = 'PRODUCT_GOLD_YIELD_BONUS_JADE' AND Name = 'Amount';
UPDATE ModifierArguments SET Value = '15' WHERE ModifierId = 'PRODUCT_GOLD_YIELD_BONUS_SILVER' AND Name = 'Amount';
UPDATE ModifierArguments SET Value = '15' WHERE ModifierId = 'PRODUCT_GOLD_YIELD_BONUS_TRUFFLES' AND Name = 'Amount';
UPDATE ModifierArguments SET Value = '20' WHERE ModifierId = 'PRODUCT_FAITH_YIELD_BONUS_AMBER' AND Name = 'Amount';
UPDATE ModifierArguments SET Value = '20' WHERE ModifierId = 'PRODUCT_FAITH_YIELD_BONUS_DYES' AND Name = 'Amount';
UPDATE ModifierArguments SET Value = '20' WHERE ModifierId = 'PRODUCT_FAITH_YIELD_BONUS_INCENSE' AND Name = 'Amount';
UPDATE ModifierArguments SET Value = '20' WHERE ModifierId = 'PRODUCT_FAITH_YIELD_BONUS_PEARLS' AND Name = 'Amount';
UPDATE ModifierArguments SET Value = '7' WHERE ModifierId = 'PRODUCT_SCIENCE_YIELD_BONUS_MERCURY' AND Name = 'Amount';
UPDATE ModifierArguments SET Value = '7' WHERE ModifierId = 'PRODUCT_SCIENCE_YIELD_BONUS_TEA' AND Name = 'Amount';
UPDATE ModifierArguments SET Value = '7' WHERE ModifierId = 'PRODUCT_SCIENCE_YIELD_BONUS_TURTLES' AND Name = 'Amount';
UPDATE ModifierArguments SET Value = '15' WHERE ModifierId = 'PRODUCT_CIVILIAN_UNIT_DISCOUNT_FURS' AND Name = 'Amount';
UPDATE ModifierArguments SET Value = '15' WHERE ModifierId = 'PRODUCT_CIVILIAN_UNIT_DISCOUNT_OLIVES' AND Name = 'Amount';

-- Products added by the embedded BBG Expanded resource set
UPDATE ModifierArguments SET Value = '7' WHERE ModifierId = 'PRODUCT_SCIENCE_YIELD_BONUS_P0K_PENGUINS' AND Name = 'Amount';
UPDATE ModifierArguments SET Value = '20' WHERE ModifierId = 'PRODUCT_FAITH_YIELD_BONUS_CVS_POMEGRANATES' AND Name = 'Amount';
UPDATE ModifierArguments SET Value = '7' WHERE ModifierId = 'PRODUCT_SCIENCE_YIELD_BONUS_P0K_PAPYRUS' AND Name = 'Amount';
UPDATE ModifierArguments SET Value = '10' WHERE ModifierId = 'PRODUCT_CITY_GROWTH_MAPLE' AND Name = 'Amount';
UPDATE ModifierArguments SET Value = '15' WHERE ModifierId = 'PRODUCT_GOLD_YIELD_BONUS_P0K_OPAL' AND Name = 'Amount';
UPDATE ModifierArguments SET Value = '7' WHERE ModifierId = 'PRODUCT_CULTURE_YIELD_BONUS_P0K_PLUMS' AND Name = 'Amount';
