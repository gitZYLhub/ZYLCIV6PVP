-- ============================================================================
-- ZYL 伟人改动（NFP/Babylon 伟人部分）
-- 加载顺序：260000035（Criteria: ZYLPVP_BBG_Babylon）
-- 配套文本：lang/ZYL_GreatPeople_Text.xml（LOC_ZYL_GREATPERSON_*_ACTIVE）
-- ============================================================================

-- ========== 张衡：删除"数学"尤里卡，只保留天文导航/工程；新增图书馆 +1 生产力 ==========
DELETE FROM GreatPersonIndividualActionModifiers
WHERE GreatPersonIndividualType='GREAT_PERSON_INDIVIDUAL_ZHANG_HENG'
  AND ModifierId='GREAT_PERSON_INDIVIDUAL_BOOST_OR_GRANT_MATHEMATICS';

INSERT INTO Modifiers (ModifierId, ModifierType)
VALUES ('ZYL_GREATPERSON_LIBRARIES_PRODUCTION','MODIFIER_PLAYER_CITIES_ADJUST_BUILDING_YIELD_CHANGE');
INSERT INTO ModifierArguments (ModifierId, Name, Value) VALUES
 ('ZYL_GREATPERSON_LIBRARIES_PRODUCTION','BuildingType','BUILDING_LIBRARY'),
 ('ZYL_GREATPERSON_LIBRARIES_PRODUCTION','YieldType','YIELD_PRODUCTION'),
 ('ZYL_GREATPERSON_LIBRARIES_PRODUCTION','Amount','1');
INSERT INTO GreatPersonIndividualActionModifiers (GreatPersonIndividualType, ModifierId, AttachmentTargetType)
VALUES ('GREAT_PERSON_INDIVIDUAL_ZHANG_HENG','ZYL_GREATPERSON_LIBRARIES_PRODUCTION','GREAT_PERSON_ACTION_ATTACHMENT_TARGET_DISTRICT_IN_TILE');

-- ========== 伊本·法德兰：删除通往城邦商路信仰 +2，只保留贸易路线容量 ==========
DELETE FROM GreatPersonIndividualActionModifiers
WHERE GreatPersonIndividualType='GREAT_PERSON_INDIVIDUAL_IBN_FADLAN'
  AND ModifierId='GREATPERSON_CITY_STATE_TRADE_FAITH';
