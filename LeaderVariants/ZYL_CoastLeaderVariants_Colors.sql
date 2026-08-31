INSERT OR REPLACE INTO PlayerColors
    (Type, Usage, PrimaryColor, SecondaryColor,
     Alt1PrimaryColor, Alt1SecondaryColor,
     Alt2PrimaryColor, Alt2SecondaryColor,
     Alt3PrimaryColor, Alt3SecondaryColor)
SELECT 'LEADER_HOJO_INLAND', Usage, PrimaryColor, SecondaryColor,
       Alt1PrimaryColor, Alt1SecondaryColor,
       Alt2PrimaryColor, Alt2SecondaryColor,
       Alt3PrimaryColor, Alt3SecondaryColor
FROM PlayerColors WHERE Type = 'LEADER_HOJO';

INSERT OR REPLACE INTO PlayerColors
    (Type, Usage, PrimaryColor, SecondaryColor,
     Alt1PrimaryColor, Alt1SecondaryColor,
     Alt2PrimaryColor, Alt2SecondaryColor,
     Alt3PrimaryColor, Alt3SecondaryColor)
SELECT 'LEADER_PHILIP_II_INLAND', Usage, PrimaryColor, SecondaryColor,
       Alt1PrimaryColor, Alt1SecondaryColor,
       Alt2PrimaryColor, Alt2SecondaryColor,
       Alt3PrimaryColor, Alt3SecondaryColor
FROM PlayerColors WHERE Type = 'LEADER_PHILIP_II';

INSERT OR REPLACE INTO PlayerColors
    (Type, Usage, PrimaryColor, SecondaryColor,
     Alt1PrimaryColor, Alt1SecondaryColor,
     Alt2PrimaryColor, Alt2SecondaryColor,
     Alt3PrimaryColor, Alt3SecondaryColor)
SELECT 'LEADER_WILHELMINA_INLAND', Usage, PrimaryColor, SecondaryColor,
       Alt1PrimaryColor, Alt1SecondaryColor,
       Alt2PrimaryColor, Alt2SecondaryColor,
       Alt3PrimaryColor, Alt3SecondaryColor
FROM PlayerColors WHERE Type = 'LEADER_WILHELMINA';
