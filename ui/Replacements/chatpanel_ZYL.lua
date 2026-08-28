-- =================================================================================
-- Import base file
-- =================================================================================

local files = {
    "chatpanel_MPH.lua",
    "ChatPanel.lua"
}


for _, file in ipairs(files) do
    include(file)
    if Initialize then
        print("Loading " .. file .. " as base file");
        break
    end
end

-- ===========================================================================
-- 读取数据
-- ===========================================================================
function GetLocalBlackListString()
    local result = '\n\nSteamID\t备注'
	local ids = UserConfiguration.GetValue("ZYL_MPS_BLACKLIST_IDS") or ""
	for steamID in string.gmatch(ids, "[^|]+") do
		local desc = UserConfiguration.GetValue("ZYL_MPS_BLACKLIST_DESC_" .. steamID) or ""
		result = result .. '\n' .. steamID .. '\t' .. desc
	end
    return result
end

-- ===========================================================================
-- 数据复制到剪贴板
-- ===========================================================================
function OnOutputButton()
	local TextCopy = Locale.Lookup("{1_Time : datetime full}", os.time());
    Controls.CopyBlackListButton:SetToolTipString("已于"..TextCopy.."复制到剪贴板")
	TextCopy = TextCopy..GetLocalBlackListString()
	UIManager:SetClipboardString(TextCopy)
	return;
end

function TPT_LateInitialize()
	Controls.BlackListPanelButton:RegisterCallback(Mouse.eLClick, function() LuaEvents.Open_BlackListOanel() end);
	Controls.CopyBlackListButton:RegisterCallback(Mouse.eLClick, OnOutputButton);
end
TPT_LateInitialize()
