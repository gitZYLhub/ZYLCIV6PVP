-- Reuse every installed localization (including Civilopedia and diplomacy
-- lines) by cloning source tags to the new leader IDs.
INSERT OR REPLACE INTO LocalizedText (Language, Tag, Text, Gender, Plurality)
SELECT Language, replace(Tag, 'LEADER_HOJO', 'LEADER_HOJO_INLAND'),
       Text, Gender, Plurality
FROM LocalizedText
WHERE instr(Tag, 'LEADER_HOJO') > 0
  AND instr(Tag, 'LEADER_HOJO_INLAND') = 0
  AND instr(Tag, 'LEADER_HOJO_COASTAL') = 0;
INSERT OR REPLACE INTO LocalizedText (Language, Tag, Text, Gender, Plurality)
SELECT Language, replace(Tag, 'LEADER_PHILIP_II', 'LEADER_PHILIP_II_INLAND'),
       Text, Gender, Plurality
FROM LocalizedText
WHERE instr(Tag, 'LEADER_PHILIP_II') > 0
  AND instr(Tag, 'LEADER_PHILIP_II_INLAND') = 0
  AND instr(Tag, 'LEADER_PHILIP_II_COASTAL') = 0;
INSERT OR REPLACE INTO LocalizedText (Language, Tag, Text, Gender, Plurality)
SELECT Language, replace(Tag, 'LEADER_WILHELMINA', 'LEADER_WILHELMINA_INLAND'),
       Text, Gender, Plurality
FROM LocalizedText
WHERE instr(Tag, 'LEADER_WILHELMINA') > 0
  AND instr(Tag, 'LEADER_WILHELMINA_INLAND') = 0
  AND instr(Tag, 'LEADER_WILHELMINA_COASTAL') = 0;

-- Keep the installed localization of each personal name in every language.
-- Chinese receives native suffixes below; other locales get a short English
-- qualifier instead of falling back to an untranslated full name.
INSERT OR REPLACE INTO LocalizedText (Language, Tag, Text, Gender, Plurality)
SELECT Language, 'LOC_LEADER_HOJO_COASTAL_NAME', Text || ' (Coastal)', Gender, Plurality
FROM LocalizedText WHERE Tag = 'LOC_LEADER_HOJO_NAME';
INSERT OR REPLACE INTO LocalizedText (Language, Tag, Text, Gender, Plurality)
SELECT Language, 'LOC_LEADER_HOJO_INLAND_NAME', Text || ' (Inland)', Gender, Plurality
FROM LocalizedText WHERE Tag = 'LOC_LEADER_HOJO_NAME';
INSERT OR REPLACE INTO LocalizedText (Language, Tag, Text, Gender, Plurality)
SELECT Language, 'LOC_LEADER_PHILIP_II_COASTAL_NAME', Text || ' (Coastal)', Gender, Plurality
FROM LocalizedText WHERE Tag = 'LOC_LEADER_PHILIP_II_NAME';
INSERT OR REPLACE INTO LocalizedText (Language, Tag, Text, Gender, Plurality)
SELECT Language, 'LOC_LEADER_PHILIP_II_INLAND_NAME', Text || ' (Inland)', Gender, Plurality
FROM LocalizedText WHERE Tag = 'LOC_LEADER_PHILIP_II_NAME';
INSERT OR REPLACE INTO LocalizedText (Language, Tag, Text, Gender, Plurality)
SELECT Language, 'LOC_LEADER_WILHELMINA_COASTAL_NAME', Text || ' (Coastal)', Gender, Plurality
FROM LocalizedText WHERE Tag = 'LOC_LEADER_WILHELMINA_NAME';
INSERT OR REPLACE INTO LocalizedText (Language, Tag, Text, Gender, Plurality)
SELECT Language, 'LOC_LEADER_WILHELMINA_INLAND_NAME', Text || ' (Inland)', Gender, Plurality
FROM LocalizedText WHERE Tag = 'LOC_LEADER_WILHELMINA_NAME';

INSERT OR REPLACE INTO LocalizedText (Language, Tag, Text) VALUES
    ('en_US', 'LOC_LEADER_HOJO_COASTAL_NAME',       'Hojo Tokimune (Coastal)'),
    ('en_US', 'LOC_LEADER_HOJO_INLAND_NAME',        'Hojo Tokimune (Inland)'),
    ('en_US', 'LOC_LEADER_PHILIP_II_COASTAL_NAME',  'Philip II (Coastal)'),
    ('en_US', 'LOC_LEADER_PHILIP_II_INLAND_NAME',   'Philip II (Inland)'),
    ('en_US', 'LOC_LEADER_WILHELMINA_COASTAL_NAME', 'Wilhelmina (Coastal)'),
    ('en_US', 'LOC_LEADER_WILHELMINA_INLAND_NAME',  'Wilhelmina (Inland)'),
    ('zh_Hans_CN', 'LOC_LEADER_HOJO_COASTAL_NAME',       '北条时宗（海岸）'),
    ('zh_Hans_CN', 'LOC_LEADER_HOJO_INLAND_NAME',        '北条时宗（内陆）'),
    ('zh_Hans_CN', 'LOC_LEADER_PHILIP_II_COASTAL_NAME',  '腓力二世（海岸）'),
    ('zh_Hans_CN', 'LOC_LEADER_PHILIP_II_INLAND_NAME',   '腓力二世（内陆）'),
    ('zh_Hans_CN', 'LOC_LEADER_WILHELMINA_COASTAL_NAME', '威廉明娜（海岸）'),
    ('zh_Hans_CN', 'LOC_LEADER_WILHELMINA_INLAND_NAME',  '威廉明娜（内陆）'),
    ('zh_Hant_HK', 'LOC_LEADER_HOJO_COASTAL_NAME',       '北條時宗（海岸）'),
    ('zh_Hant_HK', 'LOC_LEADER_HOJO_INLAND_NAME',        '北條時宗（內陸）'),
    ('zh_Hant_HK', 'LOC_LEADER_PHILIP_II_COASTAL_NAME',  '腓力二世（海岸）'),
    ('zh_Hant_HK', 'LOC_LEADER_PHILIP_II_INLAND_NAME',   '腓力二世（內陸）'),
    ('zh_Hant_HK', 'LOC_LEADER_WILHELMINA_COASTAL_NAME', '威廉明娜（海岸）'),
    ('zh_Hant_HK', 'LOC_LEADER_WILHELMINA_INLAND_NAME',  '威廉明娜（內陸）');
