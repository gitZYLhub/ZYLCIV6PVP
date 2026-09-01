------------------------------------------------------------------------------
-- Team PVP Rich Mainland entry point.
------------------------------------------------------------------------------
ZYL_RICH_MAINLAND_VARIANT = {
	id = "TEAM",
	team = true,
	ffa = false,
	-- Preserve the pre-expansion land/island canvas at each map height.  The
	-- shared core centers this canvas and uses all added columns as ocean.
	baseWidthsByHeight = {
		[36] = 58,
		[48] = 60,
		[62] = 60,
		[76] = 66,
		[88] = 70,
		[94] = 72,
	},
};

include "zyl_rich_mainland_core"
