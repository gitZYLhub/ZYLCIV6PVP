------------------------------------------------------------------------------
-- ZYL LightweightBalance: removable luxury and strategic resources
------------------------------------------------------------------------------
-- Luxury resources grant Gold and strategic resources grant Production.  The
-- prerequisite follows the technology used to reveal/develop the resource.
-- City-center settlement behavior is unchanged; this only adds Builder
-- harvest actions.
INSERT OR REPLACE INTO Resource_Harvests
	(ResourceType, YieldType, Amount, PrereqTech)
SELECT
	Resources.ResourceType,
	CASE Resources.ResourceClassType
		WHEN 'RESOURCECLASS_STRATEGIC' THEN 'YIELD_PRODUCTION'
		WHEN 'RESOURCECLASS_LUXURY' THEN 'YIELD_GOLD'
	END,
	CASE Resources.ResourceClassType
		WHEN 'RESOURCECLASS_STRATEGIC' THEN 20
		WHEN 'RESOURCECLASS_LUXURY' THEN 40
	END,
	CASE
		WHEN Resources.ResourceClassType = 'RESOURCECLASS_STRATEGIC'
			THEN Resources.PrereqTech
		WHEN EXISTS (
			SELECT 1
			FROM Improvement_ValidResources
			WHERE ResourceType = Resources.ResourceType
			  AND ImprovementType = 'IMPROVEMENT_PLANTATION'
		) THEN 'TECH_IRRIGATION'
		WHEN EXISTS (
			SELECT 1
			FROM Improvement_ValidResources
			WHERE ResourceType = Resources.ResourceType
			  AND ImprovementType IN ('IMPROVEMENT_PASTURE', 'IMPROVEMENT_CAMP')
		) THEN 'TECH_ANIMAL_HUSBANDRY'
		WHEN EXISTS (
			SELECT 1
			FROM Improvement_ValidResources
			WHERE ResourceType = Resources.ResourceType
			  AND ImprovementType IN ('IMPROVEMENT_MINE', 'IMPROVEMENT_QUARRY')
		) THEN 'TECH_MINING'
		WHEN EXISTS (
			SELECT 1
			FROM Improvement_ValidResources
			WHERE ResourceType = Resources.ResourceType
			  AND ImprovementType = 'IMPROVEMENT_FISHING_BOATS'
		) THEN 'TECH_SAILING'
		ELSE Resources.PrereqTech
	END
FROM Resources
WHERE Resources.ResourceClassType IN (
	'RESOURCECLASS_STRATEGIC',
	'RESOURCECLASS_LUXURY'
)
  -- Monopoly/Great Merchant exclusives are not map resources and must not
  -- receive Builder harvest actions.
  AND Resources.ResourceType NOT IN (
	'RESOURCE_CINNAMON',
	'RESOURCE_CLOVES',
	'RESOURCE_COSMETICS',
	'RESOURCE_JEANS',
	'RESOURCE_PERFUME',
	'RESOURCE_TOYS'
  );
