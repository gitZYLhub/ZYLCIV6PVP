local Suk_UI_InUse = Modding.IsModActive("805cc499-c534-4e0a-bdce-32fb3c53ba38")        -- 不能和 Sukritact's Simple UI Adjustments 一起用

BASE_CityBanner_UpdateRangeStrike = CityBanner.UpdateRangeStrike
BASE_UpdateInfo = CityBanner.UpdateInfo
CSB_BASE_OnShutdown = OnShutdown
local CanCityStrikeButtonRevoke = false

if not Suk_UI_InUse then
    function CityBanner.UpdateRangeStrike(self)

        BASE_CityBanner_UpdateRangeStrike(self)

        local tBanner = self.m_Instance

        if tBanner.CityStrike ~= nil then
            if CanCityStrikeButtonRevoke then
                tBanner.CityStrike:SetAnchor("C,B")
                tBanner.CityStrike:SetOffsetVal(0, -6)

                tBanner.CityStrikeButton:SetAnchor("C,B")
                tBanner.CityStrikeButton:SetOffsetVal(0, 10)
            else
                tBanner.CityStrike:SetAnchor("R,C")
                tBanner.CityStrike:SetOffsetVal(-32, 0)

                tBanner.CityStrikeButton:SetAnchor("L,C")
                tBanner.CityStrikeButton:SetOffsetVal(6, 0)
            end
        end
    end

    function CityBanner.UpdateInfo(self, pCity)
        BASE_UpdateInfo(self, pCity)
        local kChildren = self.m_Instance.CityInfoStack:GetChildren()
        for i, kChild in ipairs(kChildren) do
            local pCityReligion = pCity:GetReligion();
            local activePantheon = pCityReligion:GetActivePantheon();
            if activePantheon >= 0 then
                if kChild:GetToolTipString() == Locale.Lookup("LOC_HUD_CITY_PANTHEON_TT", GameInfo.Beliefs[activePantheon].Name) then
                    kChild:SetToolTipString(kChild:GetToolTipString() .. '[NEWLINE]' .. Locale.Lookup(GameInfo.Beliefs[activePantheon].Description));
                end
            end
        end

        local pCityReligion = pCity:GetReligion();
        local eMajorityReligion = self.m_eMajorityReligion;
        if (eMajorityReligion > 0) then
			local activePantheon = pCityReligion:GetActivePantheon();
			if (activePantheon >= 0) then
				local instance = self.m_InfoIconIM:GetInstance();
				instance.Icon:SetIcon("ICON_" .. GameInfo.Religions[0].ReligionType);
				instance.Icon:SetColor(COLOR_HOLY_SITE);
				instance.Button:SetTexture("Banner_TypeSlot_Religion");
				instance.Button:SetToolTipString(Locale.Lookup("LOC_HUD_CITY_PANTHEON_TT", GameInfo.Beliefs[activePantheon].Name).. '[NEWLINE]' .. Locale.Lookup(GameInfo.Beliefs[activePantheon].Description));
				instance.Button:RegisterCallback( Mouse.eLClick, OnReligionIconClicked );
				instance.Button:SetVoid1(pCity:GetOwner());
				instance.Button:SetVoid2(pCity:GetID());
			end
            self:Resize()
        end

    end

end

function OnTPT_Settings_Toggle_CSB(ParameterId, Value)
    if ParameterId == "CityStrikeButton_Back" then
        CanCityStrikeButtonRevoke = Value
        RefreshPlayerBanners(Game.GetLocalPlayer())
        return
    end
end

function OnShutdown_CSB()
	LuaEvents.TPT_Settings_Toggle.Remove(OnTPT_Settings_Toggle_CSB)
	if CSB_BASE_OnShutdown ~= nil then CSB_BASE_OnShutdown() end
end

LuaEvents.TPT_Settings_Toggle.Add(OnTPT_Settings_Toggle_CSB)
OnShutdown = OnShutdown_CSB
ContextPtr:SetShutdown(OnShutdown)
