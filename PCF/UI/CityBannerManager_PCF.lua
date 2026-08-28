local g_CoolDownTime = os.clock()							-- 冷却时间(防止同一类型短时间多次触发)
local PCF_BASE_OnShutdown = OnShutdown

local CallbackDict = {};
local AuxiliaryTiming = {};
local ATnum = 0;
local RemoveTimer
-- =============================================================================
-- 定时器：皮皮凯  https://gitee.com/XPPK/pk-civ6-LuaTimer/blob/master/README.md
-- =============================================================================
local function AddTimer(TimeInSeconds, callbackFunc, loop, FuncID, Values, Needunpack)
	ATnum = ATnum + 1;
	-- 如果loop为nil
	loop = loop or false;
	FuncID = FuncID or "Func_" .. ATnum;
	
--	如果FuncID发生重复
	if AuxiliaryTiming[FuncID] ~= nil then
--		print("警告FuncID: "..FuncID, "发生重复，移除旧任务");
		RemoveTimer(FuncID)		-- 移除重复进程
	end
	AuxiliaryTiming[FuncID] = TimeInSeconds;

	-- callbackFunc插入到定时循环中
--	local function CreateLoopFunc()
--		return function()
--			AuxiliaryTiming[FuncID] = AuxiliaryTiming[FuncID] - 1;
--			if AuxiliaryTiming[FuncID] == 0 then
--				if type(Values) == "table" and Needunpack then
--					callbackFunc(unpack(Values));
--				else
--					callbackFunc(Values);
--				end
--				AuxiliaryTiming[FuncID] = TimeInSeconds;
--			end
--		end
--	end

	-- callbackFunc插入到延时触发中
	local function CreateFunc()
		return function()
			AuxiliaryTiming[FuncID] = AuxiliaryTiming[FuncID] - 1;
			if AuxiliaryTiming[FuncID] <= 0 then
				if type(Values) == "table" and Needunpack then
					callbackFunc(unpack(Values));
				else
					callbackFunc(Values);
				end
				CallbackDict[FuncID]()
			end
		end
	end

	local func = CreateFunc();
	Events.GameCoreEventPublishComplete.Add(func);

	-- 直接构造好对应的关闭循环的函数，亦或者提前关闭延迟的函数以免找不到对应func
	CallbackDict[FuncID] = function()
		Events.GameCoreEventPublishComplete.Remove(func);
		CallbackDict[FuncID] = nil;
		AuxiliaryTiming[FuncID] = nil;
	end
	return ATnum;
end

RemoveTimer = function(FuncID)
	if CallbackDict[FuncID] then 		-- 还是要检测一下否则为nil又报错
		CallbackDict[FuncID](); 
	end
end

local function RemoveAllTimer()
	local timerIds = {}
	for i, _ in pairs(CallbackDict) do
		table.insert(timerIds, i)
	end
	for _, i in ipairs(timerIds) do
		if CallbackDict[i] then
			CallbackDict[i]()
		end
	end
end

function OnTPT_ClickCitizen( playerID, cityID )
	local pSelectedCity = CityManager.GetCity(playerID, cityID)
	if pSelectedCity == nil then return end
	local tParameters	:table = {};
	tParameters[CityCommandTypes.PARAM_MANAGE_CITIZEN] = UI.GetInterfaceModeParameter(CityCommandTypes.PARAM_MANAGE_CITIZEN);
	tParameters[CityCommandTypes.PARAM_X] = pSelectedCity:GetX();
	tParameters[CityCommandTypes.PARAM_Y] = pSelectedCity:GetY();

	local tResults :table = CityManager.RequestCommand( pSelectedCity, CityCommandTypes.MANAGE, tParameters );
	
	local FuncID = "Refresh_" .. tostring(cityID)
	AddTimer(2, RefreshBanner, false, FuncID, {playerID; cityID;}, true)
end

local function OnLocalPlayerTurnBegin_PCF()
	g_CoolDownTime = os.clock() + 1
end

local function OnCityWorkerChanged_PCF(playerID, cityID)
	if playerID == Game.GetLocalPlayer() and os.clock() > g_CoolDownTime then
		local FuncID = "Refresh_" .. tostring(cityID)
		AddTimer(2, RefreshBanner, false, FuncID, {playerID; cityID;}, true)
	end
end

local function OnCityTileOwnershipChanged_PCF(playerID, cityID)
	if playerID == Game.GetLocalPlayer() and os.clock() > g_CoolDownTime then
		local FuncID = "City_" .. tostring(cityID)
		AddTimer(4, OnTPT_ClickCitizen, false, FuncID, {playerID; cityID;}, true)
	end
end

local function OnCityPopulationChanged_PCF(playerID, cityID)
	if playerID == Game.GetLocalPlayer() and os.clock() > g_CoolDownTime then
		local FuncID = "City_" .. tostring(cityID)
		AddTimer(4, OnTPT_ClickCitizen, false, FuncID, {playerID; cityID;}, true)
	end
end

local function OnPlotYieldChanged_PCF(x, y)
	if os.clock() <= g_CoolDownTime then
		return
	end
	
	local pPlot = Map.GetPlot(x, y);
	if pPlot == nil then return end
	local playerID = pPlot:GetOwner();

	if playerID == Game.GetLocalPlayer() then
		local pCity = Cities.GetPlotPurchaseCity(pPlot);
		if pCity ~= nil then
			local cityID = pCity:GetID();
			AddTimer(2, OnTPT_ClickCitizen, false, cityID, {playerID; cityID;}, true)
		end
	end
end

function OnShutdown_PCF()
	RemoveAllTimer()
	Events.LocalPlayerTurnBegin.Remove(OnLocalPlayerTurnBegin_PCF)
	Events.TurnEnd.Remove(RemoveAllTimer)
	Events.CityWorkerChanged.Remove(OnCityWorkerChanged_PCF)
	Events.CityTileOwnershipChanged.Remove(OnCityTileOwnershipChanged_PCF)
	Events.CityPopulationChanged.Remove(OnCityPopulationChanged_PCF)
	Events.PlotYieldChanged.Remove(OnPlotYieldChanged_PCF)
	if PCF_BASE_OnShutdown ~= nil then PCF_BASE_OnShutdown() end
end

Events.LocalPlayerTurnBegin.Add(OnLocalPlayerTurnBegin_PCF)
Events.TurnEnd.Add(RemoveAllTimer)
Events.CityWorkerChanged.Add(OnCityWorkerChanged_PCF)
Events.CityTileOwnershipChanged.Add(OnCityTileOwnershipChanged_PCF)
Events.CityPopulationChanged.Add(OnCityPopulationChanged_PCF)
Events.PlotYieldChanged.Add(OnPlotYieldChanged_PCF)
OnShutdown = OnShutdown_PCF
ContextPtr:SetShutdown(OnShutdown)
