-- Shared private lookup used by the Rich Mainland balance pass.  It is built
-- only while either ZYL Rich Mainland map is selected and does not alter BBG or
-- BBM's actual start-bias rows.
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
