local NATIONAL_PARK_PROPERTY = "ZYL_CANADA_NATIONAL_PARK"

local function RefreshNationalParkPlots()
	for plotIndex = 0, Map.GetPlotCount() - 1 do
		local plot = Map.GetPlotByIndex(plotIndex)
		if plot ~= nil then
			if plot:IsNationalPark() then
				if plot:GetProperty(NATIONAL_PARK_PROPERTY) ~= 1 then
					plot:SetProperty(NATIONAL_PARK_PROPERTY, 1)
				end
			elseif plot:GetProperty(NATIONAL_PARK_PROPERTY) ~= nil then
				plot:SetProperty(NATIONAL_PARK_PROPERTY, nil)
			end
		end
	end
end

RefreshNationalParkPlots()

if Events ~= nil then
	if Events.NationalParkAdded ~= nil then
		Events.NationalParkAdded.Add(RefreshNationalParkPlots)
	end
	if Events.NationalParkRemoved ~= nil then
		Events.NationalParkRemoved.Add(RefreshNationalParkPlots)
	end
end
