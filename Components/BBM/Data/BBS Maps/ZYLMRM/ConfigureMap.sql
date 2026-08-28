-- Runtime-only dimensions for Mountainous Rich Mainland.  This action is
-- guarded by the ZYLMRM_Map criterion, so other maps retain their own sizes.
UPDATE Maps SET GridWidth=58, GridHeight=36, DefaultPlayers=2, NumNaturalWonders=3, Continents=1 WHERE MapSizeType='MAPSIZE_DUEL';
UPDATE Maps SET GridWidth=60, GridHeight=48, DefaultPlayers=4, NumNaturalWonders=3, Continents=2 WHERE MapSizeType='MAPSIZE_TINY';
UPDATE Maps SET GridWidth=60, GridHeight=62, DefaultPlayers=6, NumNaturalWonders=4, Continents=3 WHERE MapSizeType='MAPSIZE_SMALL';
UPDATE Maps SET GridWidth=66, GridHeight=76, DefaultPlayers=8, NumNaturalWonders=5, Continents=4 WHERE MapSizeType='MAPSIZE_STANDARD';
UPDATE Maps SET GridWidth=70, GridHeight=88, DefaultPlayers=10, NumNaturalWonders=6, Continents=5 WHERE MapSizeType='MAPSIZE_LARGE';
UPDATE Maps SET GridWidth=72, GridHeight=94, DefaultPlayers=12, NumNaturalWonders=7, Continents=6 WHERE MapSizeType='MAPSIZE_HUGE';

-- The source balance pass reads this private lookup.  Populate it from the
-- active ruleset without changing BBG/BBM's actual start-bias rows.
CREATE TABLE IF NOT EXISTS NW_StartBias
(
	Type TEXT NOT NULL PRIMARY KEY,
	Flag INTEGER NOT NULL DEFAULT 0,
	ActiveTerrains TEXT,
	NegativeTerrains TEXT,
	ActiveFeatures TEXT,
	NegativeFeatures TEXT,
	ActiveResources TEXT,
	NegativeResources TEXT
);

INSERT OR IGNORE INTO NW_StartBias(Type, Flag)
SELECT CivilizationType, 1 FROM StartBiasTerrains
WHERE TerrainType IN ('TERRAIN_TUNDRA','TERRAIN_TUNDRA_HILLS') AND Tier = 1;
INSERT OR IGNORE INTO NW_StartBias(Type, Flag)
SELECT CivilizationType, 2 FROM StartBiasTerrains
WHERE TerrainType IN ('TERRAIN_DESERT','TERRAIN_DESERT_HILLS') AND Tier = 1;
INSERT OR IGNORE INTO NW_StartBias(Type, Flag)
SELECT CivilizationType, 3 FROM StartBiasTerrains
WHERE TerrainType IN (SELECT TerrainType FROM Terrains WHERE Mountain = 1) AND Tier = 1;
INSERT OR IGNORE INTO NW_StartBias(Type, Flag) VALUES
('LEADER_T_ROOSEVELT', 3),
('LEADER_PACHACUTI', 3);
