------------------------------------------------------------------------------
-- Team PVP Horizontal Rich Mainland entry point.
--
-- The playable mainland is a long east/west strip.  The shared Rich Mainland
-- systems still provide terrain, resources, wonders and final start balance,
-- while horizontalMainland selects the dedicated coast and start-band paths.
------------------------------------------------------------------------------
ZYL_RICH_MAINLAND_VARIANT = {
	id = "HORIZONTAL_TEAM",
	team = true,
	ffa = false,
	ffaBaseline = true,
	horizontalMainland = true,
};

include "zyl_rich_mainland_core"
