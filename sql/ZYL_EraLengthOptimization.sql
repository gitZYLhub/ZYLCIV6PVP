-------------------------------------------------------------------------------
-- Optional world-era duration ranges for Rise and Fall / Gathering Storm.
-- Values are stored at Standard speed; the game scales them for Online speed.
-------------------------------------------------------------------------------

UPDATE Eras_XP1
SET GameEraMinimumTurns = CASE EraType
		WHEN 'ERA_ANCIENT' THEN 40
		WHEN 'ERA_CLASSICAL' THEN 50
		WHEN 'ERA_MEDIEVAL' THEN 50
		ELSE GameEraMinimumTurns
	END,
	GameEraMaximumTurns = CASE EraType
		WHEN 'ERA_ANCIENT' THEN 50
		WHEN 'ERA_CLASSICAL' THEN 60
		WHEN 'ERA_MEDIEVAL' THEN 60
		ELSE GameEraMaximumTurns
	END
WHERE EraType IN ('ERA_ANCIENT', 'ERA_CLASSICAL', 'ERA_MEDIEVAL');
