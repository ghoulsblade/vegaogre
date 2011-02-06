
-- earth: real:8light hours, vega:1:10: 48 light-minutes = 864.000.000.000 meters.  also: 
light_second = 300*1000*1000 -- 300 mio m/s
light_minute = 60*light_second -- 18.000.000.000 in meters
local vega_factor = 1/10 -- ... useme ? 
au = 150*1000*1000* 1000 * vega_factor    -- (roughly 1 earth-sun distance)
km = 1000

function rand2i (vmin,vmax) return vmin+math.random(floor(1+vmax-vmin))-1 end
function rand2f (vmin,vmax) return vmin+(vmax-vmin)*math.random() end

function ListFiles	(path) local res = dirlist(path,false,true) table.sort(res) return res end
function ListDirs	(path)
	local arr = dirlist(path,true,false) table.sort(arr)
	local res = {} for k,dir in ipairs(arr) do if (dir ~= "." and dir ~= ".." and dir ~= ".svn") then table.insert(res,dir) end end 
	return res
end

function FindFirstFileInDir (path,pattern)
	for k,filename in ipairs(ListFiles(path)) do 
		if (string.find(filename,pattern)) then return filename end
	end
end

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


function GetRandomOrbitFlatXY (d,dzmax)
	local ang = math.random()*math.pi*2
	local x,y = d*sin(ang),d*cos(ang)
	local z = (math.random()*2-1)*dzmax
	return x,y,z
end

function GetOrbitMeanRadiusFromNode (node) -- ri="-468434.7" rj="-361541" rk="433559.750000" si="-412172.000000" sj="300463.5" sk="-498163.5"
	local ri = tonumber(node.ri or "") or 0
	local rj = tonumber(node.rj or "") or 0
	local rk = tonumber(node.rk or "") or 0
	local si = tonumber(node.si or "") or 0
	local sj = tonumber(node.sj or "") or 0
	local sk = tonumber(node.sk or "") or 0
	return 0.5*(Vector.len(ri,rj,rk) + Vector.len(si,sj,sk))
end

function ImproveObjectName (name)
	if (not name) then return end
	name = string.gsub(name,"JumpTo","jump to ")
	name = string.gsub(name,"_"," ")
	return name
end

