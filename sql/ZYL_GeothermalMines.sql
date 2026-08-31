------------------------------------------------------------------------------
-- ZYL Lightweight Balance: Geothermal Fissure mines (Gathering Storm only)
------------------------------------------------------------------------------

-- Mining unlocks Mines globally.  Listing the fissure as a valid feature lets
-- the Mine coexist with it, so the fissure and its Science yield are retained.
INSERT OR REPLACE INTO Improvement_ValidFeatures
	(ImprovementType, FeatureType, PrereqTech, PrereqCivic)
VALUES
	('IMPROVEMENT_MINE', 'FEATURE_GEOTHERMAL_FISSURE', 'TECH_MINING', NULL);
