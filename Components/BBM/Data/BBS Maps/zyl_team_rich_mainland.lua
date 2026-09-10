------------------------------------------------------------------------------
-- Team PVP Rich Mainland entry point.
--
-- This variant intentionally starts from the FFA Rich Mainland canvas and
-- generation profile.  Only the team-facing placement and continent labeling
-- differ; the shared core uses team=true for those two behaviors and
-- ffaBaseline=true for the FFA terrain/scale safeguards.
------------------------------------------------------------------------------
ZYL_RICH_MAINLAND_VARIANT = {
	id = "TEAM",
	team = true,
	ffa = false,
	ffaBaseline = true,
	-- Match the FFA map's legacy and content canvases at every height.  The
	-- shared core centers this canvas and keeps the two added columns as ocean.
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
