-------------------------------------------------------------------------------
-- Team PVP Ring Mainland entry point.
--
-- The playable mainland is a closed ring (annulus): like the horizontal
-- battlefield it keeps an approximately 16-tile radial band with roughly 300
-- mainland tiles per major civilization, but the two ends of the strip are
-- joined so that the interior forms a fully enclosed shallow inner sea while
-- the outside is an outer sea with a shallow shelf and deep ocean beyond.
--
-- ringMainland selects the dedicated ring paths of the shared core: horizontal
-- stripe continents shared by both team halves, all-shallow inner sea, outer
-- sea depth, ring sea resource guarantees and (in the start assigner) angular
-- team sectors ordered north-to-south by lobby position, with first/last
-- coastal civilizations on the outer shore and the remaining coastal
-- civilizations on the inner shore.
-------------------------------------------------------------------------------
ZYL_RICH_MAINLAND_VARIANT = {
	id = "RING_TEAM",
	team = true,
	ffa = false,
	ffaBaseline = true,
	horizontalMainland = false,
	ringMainland = true,
};

include "zyl_rich_mainland_core"
