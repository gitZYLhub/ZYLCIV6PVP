-- Team PVP Tools lobby convenience: expose the Gathering Storm
-- "no natural disasters" value on the disaster-intensity slider.
UPDATE DomainRanges
SET MinimumValue = -1
WHERE Domain = 'RealismRange';
