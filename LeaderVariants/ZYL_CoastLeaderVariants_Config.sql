-- Add one selectable inland alias beside each original coastal leader in every
-- ruleset domain where the source leader is already available.

UPDATE Players SET LeaderName = 'LOC_LEADER_HOJO_COASTAL_NAME'
WHERE LeaderType = 'LEADER_HOJO';
UPDATE Players SET LeaderName = 'LOC_LEADER_PHILIP_II_COASTAL_NAME'
WHERE LeaderType = 'LEADER_PHILIP_II';
UPDATE Players SET LeaderName = 'LOC_LEADER_WILHELMINA_COASTAL_NAME'
WHERE LeaderType = 'LEADER_WILHELMINA';

INSERT OR REPLACE INTO Players
    (Domain, CivilizationType, LeaderType, LeaderName, LeaderIcon,
     CivilizationName, CivilizationIcon, LeaderAbilityName,
     LeaderAbilityDescription, LeaderAbilityIcon, CivilizationAbilityName,
     CivilizationAbilityDescription, CivilizationAbilityIcon, Portrait,
     PortraitBackground, PlayerColor, HumanPlayable, SortIndex)
SELECT Domain, CivilizationType, 'LEADER_HOJO_INLAND',
       'LOC_LEADER_HOJO_INLAND_NAME', 'ICON_LEADER_HOJO_INLAND',
       CivilizationName, CivilizationIcon, LeaderAbilityName,
       LeaderAbilityDescription, LeaderAbilityIcon, CivilizationAbilityName,
       CivilizationAbilityDescription, CivilizationAbilityIcon, Portrait,
       PortraitBackground, PlayerColor, HumanPlayable, SortIndex
FROM Players WHERE LeaderType = 'LEADER_HOJO';

INSERT OR REPLACE INTO Players
    (Domain, CivilizationType, LeaderType, LeaderName, LeaderIcon,
     CivilizationName, CivilizationIcon, LeaderAbilityName,
     LeaderAbilityDescription, LeaderAbilityIcon, CivilizationAbilityName,
     CivilizationAbilityDescription, CivilizationAbilityIcon, Portrait,
     PortraitBackground, PlayerColor, HumanPlayable, SortIndex)
SELECT Domain, CivilizationType, 'LEADER_PHILIP_II_INLAND',
       'LOC_LEADER_PHILIP_II_INLAND_NAME', 'ICON_LEADER_PHILIP_II_INLAND',
       CivilizationName, CivilizationIcon, LeaderAbilityName,
       LeaderAbilityDescription, LeaderAbilityIcon, CivilizationAbilityName,
       CivilizationAbilityDescription, CivilizationAbilityIcon, Portrait,
       PortraitBackground, PlayerColor, HumanPlayable, SortIndex
FROM Players WHERE LeaderType = 'LEADER_PHILIP_II';

INSERT OR REPLACE INTO Players
    (Domain, CivilizationType, LeaderType, LeaderName, LeaderIcon,
     CivilizationName, CivilizationIcon, LeaderAbilityName,
     LeaderAbilityDescription, LeaderAbilityIcon, CivilizationAbilityName,
     CivilizationAbilityDescription, CivilizationAbilityIcon, Portrait,
     PortraitBackground, PlayerColor, HumanPlayable, SortIndex)
SELECT Domain, CivilizationType, 'LEADER_WILHELMINA_INLAND',
       'LOC_LEADER_WILHELMINA_INLAND_NAME', 'ICON_LEADER_WILHELMINA_INLAND',
       CivilizationName, CivilizationIcon, LeaderAbilityName,
       LeaderAbilityDescription, LeaderAbilityIcon, CivilizationAbilityName,
       CivilizationAbilityDescription, CivilizationAbilityIcon, Portrait,
       PortraitBackground, PlayerColor, HumanPlayable, SortIndex
FROM Players WHERE LeaderType = 'LEADER_WILHELMINA';

INSERT OR REPLACE INTO PlayerItems
    (Domain, CivilizationType, LeaderType, Type, Name, Description, Icon, SortIndex)
SELECT Domain, CivilizationType, 'LEADER_HOJO_INLAND', Type, Name, Description, Icon, SortIndex
FROM PlayerItems WHERE LeaderType = 'LEADER_HOJO';
INSERT OR REPLACE INTO PlayerItems
    (Domain, CivilizationType, LeaderType, Type, Name, Description, Icon, SortIndex)
SELECT Domain, CivilizationType, 'LEADER_PHILIP_II_INLAND', Type, Name, Description, Icon, SortIndex
FROM PlayerItems WHERE LeaderType = 'LEADER_PHILIP_II';
INSERT OR REPLACE INTO PlayerItems
    (Domain, CivilizationType, LeaderType, Type, Name, Description, Icon, SortIndex)
SELECT Domain, CivilizationType, 'LEADER_WILHELMINA_INLAND', Type, Name, Description, Icon, SortIndex
FROM PlayerItems WHERE LeaderType = 'LEADER_WILHELMINA';

-- Preserve optional game-mode lobby descriptions/items when the source leader
-- has an override (the tables exist in the unified Gathering Storm config DB).
INSERT OR REPLACE INTO GameModePlayerInfoOverrides
    (GameModeType, Domain, CivilizationType, LeaderType, LeaderAbilityName,
     LeaderAbilityDescription, LeaderAbilityIcon, CivilizationAbilityName,
     CivilizationAbilityDescription, CivilizationAbilityIcon, Priority)
SELECT GameModeType, Domain, CivilizationType, 'LEADER_HOJO_INLAND',
       LeaderAbilityName, LeaderAbilityDescription, LeaderAbilityIcon,
       CivilizationAbilityName, CivilizationAbilityDescription,
       CivilizationAbilityIcon, Priority
FROM GameModePlayerInfoOverrides WHERE LeaderType = 'LEADER_HOJO';
INSERT OR REPLACE INTO GameModePlayerInfoOverrides
    (GameModeType, Domain, CivilizationType, LeaderType, LeaderAbilityName,
     LeaderAbilityDescription, LeaderAbilityIcon, CivilizationAbilityName,
     CivilizationAbilityDescription, CivilizationAbilityIcon, Priority)
SELECT GameModeType, Domain, CivilizationType, 'LEADER_PHILIP_II_INLAND',
       LeaderAbilityName, LeaderAbilityDescription, LeaderAbilityIcon,
       CivilizationAbilityName, CivilizationAbilityDescription,
       CivilizationAbilityIcon, Priority
FROM GameModePlayerInfoOverrides WHERE LeaderType = 'LEADER_PHILIP_II';
INSERT OR REPLACE INTO GameModePlayerInfoOverrides
    (GameModeType, Domain, CivilizationType, LeaderType, LeaderAbilityName,
     LeaderAbilityDescription, LeaderAbilityIcon, CivilizationAbilityName,
     CivilizationAbilityDescription, CivilizationAbilityIcon, Priority)
SELECT GameModeType, Domain, CivilizationType, 'LEADER_WILHELMINA_INLAND',
       LeaderAbilityName, LeaderAbilityDescription, LeaderAbilityIcon,
       CivilizationAbilityName, CivilizationAbilityDescription,
       CivilizationAbilityIcon, Priority
FROM GameModePlayerInfoOverrides WHERE LeaderType = 'LEADER_WILHELMINA';

INSERT OR REPLACE INTO GameModePlayerItemOverrides
    (GameModeType, Domain, CivilizationType, LeaderType, Type, Name,
     Description, Icon, SortIndex, ShouldRemove, Priority)
SELECT GameModeType, Domain, CivilizationType, 'LEADER_HOJO_INLAND', Type,
       Name, Description, Icon, SortIndex, ShouldRemove, Priority
FROM GameModePlayerItemOverrides WHERE LeaderType = 'LEADER_HOJO';
INSERT OR REPLACE INTO GameModePlayerItemOverrides
    (GameModeType, Domain, CivilizationType, LeaderType, Type, Name,
     Description, Icon, SortIndex, ShouldRemove, Priority)
SELECT GameModeType, Domain, CivilizationType, 'LEADER_PHILIP_II_INLAND', Type,
       Name, Description, Icon, SortIndex, ShouldRemove, Priority
FROM GameModePlayerItemOverrides WHERE LeaderType = 'LEADER_PHILIP_II';
INSERT OR REPLACE INTO GameModePlayerItemOverrides
    (GameModeType, Domain, CivilizationType, LeaderType, Type, Name,
     Description, Icon, SortIndex, ShouldRemove, Priority)
SELECT GameModeType, Domain, CivilizationType, 'LEADER_WILHELMINA_INLAND', Type,
       Name, Description, Icon, SortIndex, ShouldRemove, Priority
FROM GameModePlayerItemOverrides WHERE LeaderType = 'LEADER_WILHELMINA';

-- Keep compatibility with Firaxis true-start-location maps.  These maps use
-- leader whitelists and fixed leader positions instead of procedural biases.
INSERT OR REPLACE INTO MapLeaders (Map, LeaderType)
SELECT Map, 'LEADER_HOJO_INLAND'
FROM MapLeaders WHERE LeaderType = 'LEADER_HOJO';
INSERT OR REPLACE INTO MapLeaders (Map, LeaderType)
SELECT Map, 'LEADER_PHILIP_II_INLAND'
FROM MapLeaders WHERE LeaderType = 'LEADER_PHILIP_II';
INSERT OR REPLACE INTO MapLeaders (Map, LeaderType)
SELECT Map, 'LEADER_WILHELMINA_INLAND'
FROM MapLeaders WHERE LeaderType = 'LEADER_WILHELMINA';

INSERT INTO MapStartPositions (Map, Plot, Type, Value)
SELECT source.Map, source.Plot, source.Type, 'LEADER_HOJO_INLAND'
FROM MapStartPositions source
WHERE source.Type = 'LEADER' AND source.Value = 'LEADER_HOJO'
  AND NOT EXISTS (
      SELECT 1 FROM MapStartPositions target
      WHERE target.Map = source.Map AND target.Plot = source.Plot
        AND target.Type = source.Type AND target.Value = 'LEADER_HOJO_INLAND'
  );
INSERT INTO MapStartPositions (Map, Plot, Type, Value)
SELECT source.Map, source.Plot, source.Type, 'LEADER_PHILIP_II_INLAND'
FROM MapStartPositions source
WHERE source.Type = 'LEADER' AND source.Value = 'LEADER_PHILIP_II'
  AND NOT EXISTS (
      SELECT 1 FROM MapStartPositions target
      WHERE target.Map = source.Map AND target.Plot = source.Plot
        AND target.Type = source.Type AND target.Value = 'LEADER_PHILIP_II_INLAND'
  );
INSERT INTO MapStartPositions (Map, Plot, Type, Value)
SELECT source.Map, source.Plot, source.Type, 'LEADER_WILHELMINA_INLAND'
FROM MapStartPositions source
WHERE source.Type = 'LEADER' AND source.Value = 'LEADER_WILHELMINA'
  AND NOT EXISTS (
      SELECT 1 FROM MapStartPositions target
      WHERE target.Map = source.Map AND target.Plot = source.Plot
        AND target.Type = source.Type AND target.Value = 'LEADER_WILHELMINA_INLAND'
  );

INSERT INTO DuplicateLeaders (Domain, LeaderType, OtherLeaderType)
SELECT DISTINCT p.Domain, 'LEADER_HOJO', 'LEADER_HOJO_INLAND'
FROM Players p
WHERE p.LeaderType = 'LEADER_HOJO'
  AND NOT EXISTS (
      SELECT 1 FROM DuplicateLeaders d
      WHERE d.Domain = p.Domain
        AND d.LeaderType = 'LEADER_HOJO'
        AND d.OtherLeaderType = 'LEADER_HOJO_INLAND'
  );
INSERT INTO DuplicateLeaders (Domain, LeaderType, OtherLeaderType)
SELECT DISTINCT p.Domain, 'LEADER_PHILIP_II', 'LEADER_PHILIP_II_INLAND'
FROM Players p
WHERE p.LeaderType = 'LEADER_PHILIP_II'
  AND NOT EXISTS (
      SELECT 1 FROM DuplicateLeaders d
      WHERE d.Domain = p.Domain
        AND d.LeaderType = 'LEADER_PHILIP_II'
        AND d.OtherLeaderType = 'LEADER_PHILIP_II_INLAND'
  );
INSERT INTO DuplicateLeaders (Domain, LeaderType, OtherLeaderType)
SELECT DISTINCT p.Domain, 'LEADER_WILHELMINA', 'LEADER_WILHELMINA_INLAND'
FROM Players p
WHERE p.LeaderType = 'LEADER_WILHELMINA'
  AND NOT EXISTS (
      SELECT 1 FROM DuplicateLeaders d
      WHERE d.Domain = p.Domain
        AND d.LeaderType = 'LEADER_WILHELMINA'
        AND d.OtherLeaderType = 'LEADER_WILHELMINA_INLAND'
  );
