------------------------------------------------------------------------------
-- FFA Rich Mainland entry point.
------------------------------------------------------------------------------
ZYL_RICH_MAINLAND_VARIANT = {
	id = "FFA",
	team = false,
	ffa = true,
	-- Preserve the pre-expansion land/island canvas at each map height.  The
	-- shared core centers this canvas and uses all added columns as ocean.
	baseWidthsByHeight = {
		[34] = 52,
		[42] = 54,
		[48] = 56,
		[56] = 58,
		[62] = 60,
		[68] = 62,
		[74] = 64,
		[80] = 66,
		[84] = 68,
		[88] = 70,
		[92] = 72,
	},
};

include "zyl_rich_mainland_core"
