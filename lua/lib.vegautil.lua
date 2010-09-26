
-- earth: real:8light hours, vega:1:10: 48 light-minutes = 864.000.000.000 meters.  also: 
light_second = 300*1000*1000 -- 300 mio m/s
light_minute = 60*light_second -- 18.000.000.000 in meters
local vega_factor = 1/10 -- ... useme ? 
au = 150*1000*1000* 1000 * vega_factor    -- (roughly 1 earth-sun distance)
km = 1000

function GetDistText (d) 
	local thres = 0.5
	local u=au				if (d >= thres*u) then return sprintf("%0.2fau",d/u) end
	local u=light_minute	if (d >= thres*u) then return sprintf("%0.2fLm",d/u) end
	local u=light_second	if (d >=   0.1*u) then return sprintf("%0.2fLs",d/u) end
	local u=km				if (d >= thres*u) then return sprintf("%0.2fkm",d/u) end
	return sprintf("%0.0fm",d)
end

function CreateDirIfNoExists (path) mkdir(path) end
