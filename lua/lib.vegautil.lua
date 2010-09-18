

function GetDistText (d) 
	local thres = 0.5
	local u=au				if (d >= thres*u) then return sprintf("%0.2fau",d/u) end
	local u=light_minute	if (d >= thres*u) then return sprintf("%0.2fLm",d/u) end
	local u=light_second	if (d >=   0.1*u) then return sprintf("%0.2fLs",d/u) end
	local u=km				if (d >= thres*u) then return sprintf("%0.2fkm",d/u) end
	return sprintf("%0.0fm",d)
end
