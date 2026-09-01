-- Runtime-only dimensions for Team PVP Rich Mainland.  This action is
-- guarded by its map criterion, so other maps retain their own sizes.
UPDATE Maps SET GridWidth=64, GridHeight=36, DefaultPlayers=2, NumNaturalWonders=3, Continents=1 WHERE MapSizeType='MAPSIZE_DUEL';
UPDATE Maps SET GridWidth=66, GridHeight=48, DefaultPlayers=4, NumNaturalWonders=3, Continents=2 WHERE MapSizeType='MAPSIZE_TINY';
UPDATE Maps SET GridWidth=66, GridHeight=62, DefaultPlayers=6, NumNaturalWonders=4, Continents=3 WHERE MapSizeType='MAPSIZE_SMALL';
UPDATE Maps SET GridWidth=72, GridHeight=76, DefaultPlayers=8, NumNaturalWonders=5, Continents=4 WHERE MapSizeType='MAPSIZE_STANDARD';
UPDATE Maps SET GridWidth=78, GridHeight=88, DefaultPlayers=10, NumNaturalWonders=6, Continents=5 WHERE MapSizeType='MAPSIZE_LARGE';
UPDATE Maps SET GridWidth=80, GridHeight=94, DefaultPlayers=12, NumNaturalWonders=7, Continents=6 WHERE MapSizeType='MAPSIZE_HUGE';
