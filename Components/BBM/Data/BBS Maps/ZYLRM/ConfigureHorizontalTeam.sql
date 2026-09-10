-- Team PVP Horizontal Rich Mainland keeps an approximately 17-by-18 mainland
-- allocation per major civilization.  Ten columns and ten rows surround
-- that land canvas with four-sided coast, islands and deep ocean.  Odd-player
-- widths are rounded up to an even number for the wrapped hex grid.
UPDATE Maps SET GridWidth=44,  GridHeight=28, DefaultPlayers=2,  NumNaturalWonders=3, Continents=1, PlateValue=3 WHERE MapSizeType='MAPSIZE_DUEL';
UPDATE Maps SET GridWidth=78,  GridHeight=28, DefaultPlayers=4,  NumNaturalWonders=3, Continents=2, PlateValue=3 WHERE MapSizeType='MAPSIZE_TINY';
UPDATE Maps SET GridWidth=112, GridHeight=28, DefaultPlayers=6,  NumNaturalWonders=4, Continents=3, PlateValue=4 WHERE MapSizeType='MAPSIZE_SMALL';
UPDATE Maps SET GridWidth=146, GridHeight=28, DefaultPlayers=8,  NumNaturalWonders=5, Continents=4, PlateValue=4 WHERE MapSizeType='MAPSIZE_STANDARD';
UPDATE Maps SET GridWidth=180, GridHeight=28, DefaultPlayers=10, NumNaturalWonders=6, Continents=5, PlateValue=5 WHERE MapSizeType='MAPSIZE_LARGE';
UPDATE Maps SET GridWidth=214, GridHeight=28, DefaultPlayers=12, NumNaturalWonders=7, Continents=6, PlateValue=6 WHERE MapSizeType='MAPSIZE_HUGE';

INSERT OR IGNORE INTO Types (Type, Kind) VALUES
('MAPSIZE_ZYL_FFA_3', 'KIND_MAPSIZE'),
('MAPSIZE_ZYL_FFA_5', 'KIND_MAPSIZE'),
('MAPSIZE_ZYL_FFA_7', 'KIND_MAPSIZE'),
('MAPSIZE_ZYL_FFA_9', 'KIND_MAPSIZE'),
('MAPSIZE_ZYL_FFA_11', 'KIND_MAPSIZE');

INSERT OR REPLACE INTO Maps
(MapSizeType, Name, Description, DefaultPlayers, NumNaturalWonders, GridWidth, GridHeight, PlateValue, Continents)
VALUES
('MAPSIZE_ZYL_FFA_3',  'LOC_ZYLRM_MAPSIZE_3_NAME',  'LOC_ZYLRM_HORIZONTAL_MAPSIZE_3_DESCRIPTION',  3, 3, 62,  28, 3, 2),
('MAPSIZE_ZYL_FFA_5',  'LOC_ZYLRM_MAPSIZE_5_NAME',  'LOC_ZYLRM_HORIZONTAL_MAPSIZE_5_DESCRIPTION',  5, 4, 96,  28, 4, 3),
('MAPSIZE_ZYL_FFA_7',  'LOC_ZYLRM_MAPSIZE_7_NAME',  'LOC_ZYLRM_HORIZONTAL_MAPSIZE_7_DESCRIPTION',  7, 5, 130, 28, 4, 4),
('MAPSIZE_ZYL_FFA_9',  'LOC_ZYLRM_MAPSIZE_9_NAME',  'LOC_ZYLRM_HORIZONTAL_MAPSIZE_9_DESCRIPTION',  9, 6, 164, 28, 5, 5),
('MAPSIZE_ZYL_FFA_11', 'LOC_ZYLRM_MAPSIZE_11_NAME', 'LOC_ZYLRM_HORIZONTAL_MAPSIZE_11_DESCRIPTION', 11, 7, 198, 28, 6, 6);

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
