------------------------------------------------------------------------------
-- 富饶千湖 entry point.
--
-- The shared Rich Mainland core supplies rich resources, terrain features,
-- start balancing and routes.  The rich-lakes flag switches the land/climate
-- profile to Lakes and the relief profile to Ring Mainland's isolated peaks.
------------------------------------------------------------------------------
ZYL_RICH_MAINLAND_VARIANT = {
	id = "RICH_LAKES",
	team = false,
	ffa = true,
	richLakes = true,
	ringMountainProfile = true,
};

include "zyl_rich_mainland_core"
