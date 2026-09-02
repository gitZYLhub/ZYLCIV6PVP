-------------------------------------------------------------------------------
-- Optional fixed world-era durations for Rise and Fall / Gathering Storm.
-- Values are stored at Standard speed; the game scales them for Online speed.
-------------------------------------------------------------------------------

UPDATE Eras_XP1
SET GameEraMinimumTurns = CASE EraType
		WHEN 'ERA_ANCIENT' THEN 54
		WHEN 'ERA_CLASSICAL' THEN 50
		WHEN 'ERA_MEDIEVAL' THEN 50
		ELSE GameEraMinimumTurns
	END,
	GameEraMaximumTurns = CASE EraType
		WHEN 'ERA_ANCIENT' THEN 54
		WHEN 'ERA_CLASSICAL' THEN 50
		WHEN 'ERA_MEDIEVAL' THEN 50
		ELSE GameEraMaximumTurns
	END
WHERE EraType IN ('ERA_ANCIENT', 'ERA_CLASSICAL', 'ERA_MEDIEVAL');
