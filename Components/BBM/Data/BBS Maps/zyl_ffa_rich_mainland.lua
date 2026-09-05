------------------------------------------------------------------------------
-- FFA Rich Mainland entry point.
------------------------------------------------------------------------------
ZYL_RICH_MAINLAND_VARIANT = {
	id = "FFA",
	team = false,
	ffa = true,
	-- Legacy widths remain the denominator for the former FFA scale.  The
	-- content widths preserve the pre-barrier FFA land canvas; four additional
	-- runtime columns are reserved for the continuous deep-ocean seam.
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
	contentWidthsByHeight = {
		[34] = 58,
		[42] = 60,
		[48] = 62,
		[56] = 64,
		[62] = 66,
		[68] = 68,
		[74] = 70,
		[80] = 72,
		[84] = 74,
		[88] = 78,
		[92] = 80,
	},
};

include "zyl_rich_mainland_core"
