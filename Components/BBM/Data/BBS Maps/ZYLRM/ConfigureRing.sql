-- Team PVP Ring Rich Mainland keeps a 16-tile radial band with about 300
-- mainland tiles per major civilization (outer radius derived from
-- (GridWidth - 10) / 2 with a five-tile sea margin on every side; the inner
-- radius is outer minus 16, clamped at 2 so even the smallest maps keep an
-- inner sea).  Every tier is a square map.  Standard size identifiers are
-- reused for even counts; the odd-count rows are real gameplay MapSize rows
-- registered only while this map is selected.
UPDATE Maps SET GridWidth=46, GridHeight=46, DefaultPlayers=2,  NumNaturalWonders=3, Continents=1, PlateValue=3 WHERE MapSizeType='MAPSIZE_DUEL';
UPDATE Maps SET GridWidth=50, GridHeight=50, DefaultPlayers=4,  NumNaturalWonders=3, Continents=2, PlateValue=3 WHERE MapSizeType='MAPSIZE_TINY';
UPDATE Maps SET GridWidth=62, GridHeight=62, DefaultPlayers=6,  NumNaturalWonders=4, Continents=3, PlateValue=4 WHERE MapSizeType='MAPSIZE_SMALL';
UPDATE Maps SET GridWidth=74, GridHeight=74, DefaultPlayers=8,  NumNaturalWonders=5, Continents=4, PlateValue=4 WHERE MapSizeType='MAPSIZE_STANDARD';
UPDATE Maps SET GridWidth=86, GridHeight=86, DefaultPlayers=10, NumNaturalWonders=6, Continents=5, PlateValue=5 WHERE MapSizeType='MAPSIZE_LARGE';
UPDATE Maps SET GridWidth=98, GridHeight=98, DefaultPlayers=12, NumNaturalWonders=7, Continents=6, PlateValue=6 WHERE MapSizeType='MAPSIZE_HUGE';

INSERT OR IGNORE INTO Types (Type, Kind) VALUES
('MAPSIZE_ZYL_FFA_3', 'KIND_MAPSIZE'),
('MAPSIZE_ZYL_FFA_5', 'KIND_MAPSIZE'),
('MAPSIZE_ZYL_FFA_7', 'KIND_MAPSIZE'),
('MAPSIZE_ZYL_FFA_9', 'KIND_MAPSIZE'),
('MAPSIZE_ZYL_FFA_11', 'KIND_MAPSIZE');

INSERT OR REPLACE INTO Maps
(MapSizeType, Name, Description, DefaultPlayers, NumNaturalWonders, GridWidth, GridHeight, PlateValue, Continents)
VALUES
('MAPSIZE_ZYL_FFA_3',  'LOC_ZYLRM_MAPSIZE_3_NAME',  'LOC_ZYLRM_RING_MAPSIZE_3_DESCRIPTION',  3, 3, 46, 46, 3, 2),
('MAPSIZE_ZYL_FFA_5',  'LOC_ZYLRM_MAPSIZE_5_NAME',  'LOC_ZYLRM_RING_MAPSIZE_5_DESCRIPTION',  5, 4, 56, 56, 4, 3),
('MAPSIZE_ZYL_FFA_7',  'LOC_ZYLRM_MAPSIZE_7_NAME',  'LOC_ZYLRM_RING_MAPSIZE_7_DESCRIPTION',  7, 5, 68, 68, 4, 4),
('MAPSIZE_ZYL_FFA_9',  'LOC_ZYLRM_MAPSIZE_9_NAME',  'LOC_ZYLRM_RING_MAPSIZE_9_DESCRIPTION',  9, 6, 80, 80, 5, 5),
('MAPSIZE_ZYL_FFA_11', 'LOC_ZYLRM_MAPSIZE_11_NAME', 'LOC_ZYLRM_RING_MAPSIZE_11_DESCRIPTION', 11, 7, 92, 92, 6, 6);

INSERT OR REPLACE INTO Map_GreatPersonClasses
(MapSizeType, GreatPersonClassType, MaxWorldInstances)
VALUES
('MAPSIZE_ZYL_FFA_3', 'GREAT_PERSON_CLASS_PROPHET', 3),
('MAPSIZE_ZYL_FFA_5', 'GREAT_PERSON_CLASS_PROPHET', 4),
('MAPSIZE_ZYL_FFA_7', 'GREAT_PERSON_CLASS_PROPHET', 5),
('MAPSIZE_ZYL_FFA_9', 'GREAT_PERSON_CLASS_PROPHET', 6),
('MAPSIZE_ZYL_FFA_11', 'GREAT_PERSON_CLASS_PROPHET', 7);

INSERT OR REPLACE INTO Maps_XP2
(MapSizeType, CO2For1DegreeTempRise, DesertPlotCountToLabel, MountainPlotCountToLabel, LakePlotCountToLabel, SeaPlotCountToLabel, OceanPlotCountToLabel)
VALUES
('MAPSIZE_ZYL_FFA_3',  750000, 3, 3, 1, 4, 8),
('MAPSIZE_ZYL_FFA_5', 1250000, 4, 4, 1, 4, 8),
('MAPSIZE_ZYL_FFA_7', 1750000, 4, 4, 1, 5, 10),
('MAPSIZE_ZYL_FFA_9', 2250000, 5, 5, 1, 5, 10),
('MAPSIZE_ZYL_FFA_11', 2750000, 5, 5, 1, 6, 12);
