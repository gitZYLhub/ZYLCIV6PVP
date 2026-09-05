-------------------------------------------------------------------------------
-- Optional fixed world-era durations for Rise and Fall / Gathering Storm.
-- Values are stored at Standard speed; the game scales them for Online speed.
-- Online-speed result: Ancient 25, Classical 23, Medieval 23, Renaissance 21,
-- Industrial 21, Modern 20, Atomic 20, Information 20 turns.
-------------------------------------------------------------------------------

UPDATE Eras_XP1
SET GameEraMinimumTurns = CASE EraType
		WHEN 'ERA_ANCIENT' THEN 50
		WHEN 'ERA_CLASSICAL' THEN 46
		WHEN 'ERA_MEDIEVAL' THEN 46
		WHEN 'ERA_RENAISSANCE' THEN 42
		WHEN 'ERA_INDUSTRIAL' THEN 42
		WHEN 'ERA_MODERN' THEN 40
		WHEN 'ERA_ATOMIC' THEN 40
		WHEN 'ERA_INFORMATION' THEN 40
		ELSE GameEraMinimumTurns
	END,
	GameEraMaximumTurns = CASE EraType
		WHEN 'ERA_ANCIENT' THEN 50
		WHEN 'ERA_CLASSICAL' THEN 46
		WHEN 'ERA_MEDIEVAL' THEN 46
		WHEN 'ERA_RENAISSANCE' THEN 42
		WHEN 'ERA_INDUSTRIAL' THEN 42
		WHEN 'ERA_MODERN' THEN 40
		WHEN 'ERA_ATOMIC' THEN 40
		WHEN 'ERA_INFORMATION' THEN 40
		ELSE GameEraMaximumTurns
	END
WHERE EraType IN ('ERA_ANCIENT', 'ERA_CLASSICAL', 'ERA_MEDIEVAL', 'ERA_RENAISSANCE', 'ERA_INDUSTRIAL', 'ERA_MODERN', 'ERA_ATOMIC', 'ERA_INFORMATION');
