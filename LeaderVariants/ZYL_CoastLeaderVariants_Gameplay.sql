-- ZYLPVPMOD coastal/inland leader variants.
--
-- The inland entries remain attached to the original civilizations.  This is
-- important: all civilization traits, unique units/buildings, city lists and
-- BBG civilization-type requirements continue to see JAPAN, SPAIN and the
-- NETHERLANDS.  Only the map-placement Lua treats these three leader IDs as
-- having no coast start bias.

INSERT OR IGNORE INTO Types (Type, Kind) VALUES
    ('LEADER_HOJO_INLAND',       'KIND_LEADER'),
    ('LEADER_PHILIP_II_INLAND',  'KIND_LEADER'),
    ('LEADER_WILHELMINA_INLAND', 'KIND_LEADER');

INSERT OR IGNORE INTO Leaders
    (LeaderType, Name, OperationList, IsBarbarianLeader, InheritFrom,
     SceneLayers, Sex, SameSexPercentage)
SELECT
    'LEADER_HOJO_INLAND', 'LOC_LEADER_HOJO_INLAND_NAME', OperationList,
    IsBarbarianLeader, 'LEADER_DEFAULT', SceneLayers, Sex, SameSexPercentage
FROM Leaders WHERE LeaderType = 'LEADER_HOJO';

INSERT OR IGNORE INTO Leaders
    (LeaderType, Name, OperationList, IsBarbarianLeader, InheritFrom,
     SceneLayers, Sex, SameSexPercentage)
SELECT
    'LEADER_PHILIP_II_INLAND', 'LOC_LEADER_PHILIP_II_INLAND_NAME', OperationList,
    IsBarbarianLeader, 'LEADER_DEFAULT', SceneLayers, Sex, SameSexPercentage
FROM Leaders WHERE LeaderType = 'LEADER_PHILIP_II';

INSERT OR IGNORE INTO Leaders
    (LeaderType, Name, OperationList, IsBarbarianLeader, InheritFrom,
     SceneLayers, Sex, SameSexPercentage)
SELECT
    'LEADER_WILHELMINA_INLAND', 'LOC_LEADER_WILHELMINA_INLAND_NAME', OperationList,
    IsBarbarianLeader, 'LEADER_DEFAULT', SceneLayers, Sex, SameSexPercentage
FROM Leaders WHERE LeaderType = 'LEADER_WILHELMINA';

UPDATE Leaders SET Name = 'LOC_LEADER_HOJO_COASTAL_NAME'
WHERE LeaderType = 'LEADER_HOJO';
UPDATE Leaders SET Name = 'LOC_LEADER_PHILIP_II_COASTAL_NAME'
WHERE LeaderType = 'LEADER_PHILIP_II';
UPDATE Leaders SET Name = 'LOC_LEADER_WILHELMINA_COASTAL_NAME'
WHERE LeaderType = 'LEADER_WILHELMINA';

INSERT OR IGNORE INTO CivilizationLeaders (LeaderType, CivilizationType, CapitalName)
SELECT 'LEADER_HOJO_INLAND', CivilizationType, CapitalName
FROM CivilizationLeaders WHERE LeaderType = 'LEADER_HOJO';
INSERT OR IGNORE INTO CivilizationLeaders (LeaderType, CivilizationType, CapitalName)
SELECT 'LEADER_PHILIP_II_INLAND', CivilizationType, CapitalName
FROM CivilizationLeaders WHERE LeaderType = 'LEADER_PHILIP_II';
INSERT OR IGNORE INTO CivilizationLeaders (LeaderType, CivilizationType, CapitalName)
SELECT 'LEADER_WILHELMINA_INLAND', CivilizationType, CapitalName
FROM CivilizationLeaders WHERE LeaderType = 'LEADER_WILHELMINA';

-- Copy the final, post-BBG leader traits so the variants track the integrated
-- balance package instead of freezing vanilla ability rows.
INSERT OR IGNORE INTO LeaderTraits (LeaderType, TraitType)
SELECT 'LEADER_HOJO_INLAND', TraitType
FROM LeaderTraits WHERE LeaderType = 'LEADER_HOJO';
INSERT OR IGNORE INTO LeaderTraits (LeaderType, TraitType)
SELECT 'LEADER_PHILIP_II_INLAND', TraitType
FROM LeaderTraits WHERE LeaderType = 'LEADER_PHILIP_II';
INSERT OR IGNORE INTO LeaderTraits (LeaderType, TraitType)
SELECT 'LEADER_WILHELMINA_INLAND', TraitType
FROM LeaderTraits WHERE LeaderType = 'LEADER_WILHELMINA';

INSERT OR IGNORE INTO LeaderQuotes (LeaderType, Quote, QuoteAudio)
SELECT 'LEADER_HOJO_INLAND', Quote, QuoteAudio
FROM LeaderQuotes WHERE LeaderType = 'LEADER_HOJO';
INSERT OR IGNORE INTO LeaderQuotes (LeaderType, Quote, QuoteAudio)
SELECT 'LEADER_PHILIP_II_INLAND', Quote, QuoteAudio
FROM LeaderQuotes WHERE LeaderType = 'LEADER_PHILIP_II';
INSERT OR IGNORE INTO LeaderQuotes (LeaderType, Quote, QuoteAudio)
SELECT 'LEADER_WILHELMINA_INLAND', Quote, QuoteAudio
FROM LeaderQuotes WHERE LeaderType = 'LEADER_WILHELMINA';

INSERT OR IGNORE INTO HistoricalAgendas (LeaderType, AgendaType)
SELECT 'LEADER_HOJO_INLAND', AgendaType
FROM HistoricalAgendas WHERE LeaderType = 'LEADER_HOJO';
INSERT OR IGNORE INTO HistoricalAgendas (LeaderType, AgendaType)
SELECT 'LEADER_PHILIP_II_INLAND', AgendaType
FROM HistoricalAgendas WHERE LeaderType = 'LEADER_PHILIP_II';
INSERT OR IGNORE INTO HistoricalAgendas (LeaderType, AgendaType)
SELECT 'LEADER_WILHELMINA_INLAND', AgendaType
FROM HistoricalAgendas WHERE LeaderType = 'LEADER_WILHELMINA';

INSERT OR IGNORE INTO FavoredReligions (LeaderType, CivilizationType, ReligionType)
SELECT 'LEADER_HOJO_INLAND', CivilizationType, ReligionType
FROM FavoredReligions WHERE LeaderType = 'LEADER_HOJO';
INSERT OR IGNORE INTO FavoredReligions (LeaderType, CivilizationType, ReligionType)
SELECT 'LEADER_PHILIP_II_INLAND', CivilizationType, ReligionType
FROM FavoredReligions WHERE LeaderType = 'LEADER_PHILIP_II';
INSERT OR IGNORE INTO FavoredReligions (LeaderType, CivilizationType, ReligionType)
SELECT 'LEADER_WILHELMINA_INLAND', CivilizationType, ReligionType
FROM FavoredReligions WHERE LeaderType = 'LEADER_WILHELMINA';

INSERT OR IGNORE INTO AgendaPreferredLeaders (AgendaType, LeaderType, PercentageChance)
SELECT AgendaType, 'LEADER_HOJO_INLAND', PercentageChance
FROM AgendaPreferredLeaders WHERE LeaderType = 'LEADER_HOJO';
INSERT OR IGNORE INTO AgendaPreferredLeaders (AgendaType, LeaderType, PercentageChance)
SELECT AgendaType, 'LEADER_PHILIP_II_INLAND', PercentageChance
FROM AgendaPreferredLeaders WHERE LeaderType = 'LEADER_PHILIP_II';
INSERT OR IGNORE INTO AgendaPreferredLeaders (AgendaType, LeaderType, PercentageChance)
SELECT AgendaType, 'LEADER_WILHELMINA_INLAND', PercentageChance
FROM AgendaPreferredLeaders WHERE LeaderType = 'LEADER_WILHELMINA';

INSERT OR IGNORE INTO AiLists
    (ListType, LeaderType, AgendaType, System, MinDifficulty, MaxDifficulty)
SELECT ListType, 'LEADER_HOJO_INLAND', AgendaType, System, MinDifficulty, MaxDifficulty
FROM AiLists WHERE LeaderType = 'LEADER_HOJO';
INSERT OR IGNORE INTO AiLists
    (ListType, LeaderType, AgendaType, System, MinDifficulty, MaxDifficulty)
SELECT ListType, 'LEADER_PHILIP_II_INLAND', AgendaType, System, MinDifficulty, MaxDifficulty
FROM AiLists WHERE LeaderType = 'LEADER_PHILIP_II';
INSERT OR IGNORE INTO AiLists
    (ListType, LeaderType, AgendaType, System, MinDifficulty, MaxDifficulty)
SELECT ListType, 'LEADER_WILHELMINA_INLAND', AgendaType, System, MinDifficulty, MaxDifficulty
FROM AiLists WHERE LeaderType = 'LEADER_WILHELMINA';

INSERT OR IGNORE INTO LoadingInfo
    (LeaderType, ForegroundImage, BackgroundImage, EraText, LeaderText,
     PlayDawnOfManAudio, DawnOfManLeaderId, DawnOfManEraId)
SELECT 'LEADER_HOJO_INLAND', ForegroundImage, BackgroundImage, EraText, LeaderText,
       PlayDawnOfManAudio, DawnOfManLeaderId, DawnOfManEraId
FROM LoadingInfo WHERE LeaderType = 'LEADER_HOJO';
INSERT OR IGNORE INTO LoadingInfo
    (LeaderType, ForegroundImage, BackgroundImage, EraText, LeaderText,
     PlayDawnOfManAudio, DawnOfManLeaderId, DawnOfManEraId)
SELECT 'LEADER_PHILIP_II_INLAND', ForegroundImage, BackgroundImage, EraText, LeaderText,
       PlayDawnOfManAudio, DawnOfManLeaderId, DawnOfManEraId
FROM LoadingInfo WHERE LeaderType = 'LEADER_PHILIP_II';
INSERT OR IGNORE INTO LoadingInfo
    (LeaderType, ForegroundImage, BackgroundImage, EraText, LeaderText,
     PlayDawnOfManAudio, DawnOfManLeaderId, DawnOfManEraId)
SELECT 'LEADER_WILHELMINA_INLAND', ForegroundImage, BackgroundImage, EraText, LeaderText,
       PlayDawnOfManAudio, DawnOfManLeaderId, DawnOfManEraId
FROM LoadingInfo WHERE LeaderType = 'LEADER_WILHELMINA';

INSERT OR IGNORE INTO LeaderInfo (LeaderType, Header, Caption, SortIndex)
SELECT 'LEADER_HOJO_INLAND', Header, Caption, SortIndex
FROM LeaderInfo WHERE LeaderType = 'LEADER_HOJO';
INSERT OR IGNORE INTO LeaderInfo (LeaderType, Header, Caption, SortIndex)
SELECT 'LEADER_PHILIP_II_INLAND', Header, Caption, SortIndex
FROM LeaderInfo WHERE LeaderType = 'LEADER_PHILIP_II';
INSERT OR IGNORE INTO LeaderInfo (LeaderType, Header, Caption, SortIndex)
SELECT 'LEADER_WILHELMINA_INLAND', Header, Caption, SortIndex
FROM LeaderInfo WHERE LeaderType = 'LEADER_WILHELMINA';

INSERT OR IGNORE INTO DuplicateLeaders (LeaderType, OtherLeaderType) VALUES
    ('LEADER_HOJO',       'LEADER_HOJO_INLAND'),
    ('LEADER_PHILIP_II',  'LEADER_PHILIP_II_INLAND'),
    ('LEADER_WILHELMINA', 'LEADER_WILHELMINA_INLAND');
