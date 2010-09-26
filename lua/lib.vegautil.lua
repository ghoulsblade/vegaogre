
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

function GetVegaDataDir () return gMainWorkingDir.."data/" end

function GetVegaHomeDataDir () 
	if (not gVegaHomeDataDir) then gVegaHomeDataDir = (GetHomePath() or ".").."/.vegastrike/" end
	return gVegaHomeDataDir
end

function GetVegaOgreHomeDataDir () 
	if (not gVegaOgreHomeDataDir) then gVegaOgreHomeDataDir = (GetHomePath() or ".").."/.vegaogre/" CreateDirIfNoExists(gVegaOgreHomeDataDir) end
	return gVegaOgreHomeDataDir
end

function GetVegaXMLVar (node,key) if (not node.var) then return end for k,v in ipairs(node.var) do if (v.name == key) then return v.value end end end
function GetJumpList (system) return explode(" ",GetVegaXMLVar(system,"jumps") or "") end

function Univ_ParseVars (node) local res = {} for k,child in ipairs(node) do if (child._name == "var") then res[child.name or "?"] = child.value end end return res end
