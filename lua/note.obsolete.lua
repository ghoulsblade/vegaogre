-- obsolete stuff, kept for reference. e.g. interesting code or similar

-- obsolete, was used to manually assemble sol-like system for testing before vega-system-file-loader was ready. 
function VegaLoadExampleSystem ()
	local solroot = VegaSpawnSystemRootLoc("sol-root-loc")
	
	-- planets
	local planets = {
		{ "sun"			,0 			,6955*10e5*km	,0},
		{ "mercury"		,0.4*au 	,2439.7*km		},
		{ "venus"		,0.7*au 	,6051.8*km		},
		{ "earth"		,1.0*au 	,6371.0*km		,bStartHere=true}, -- see also http://en.wikipedia.org/wiki/Earth
		{ "mars"		,1.5*au 	,3396.2*km		},
		-- asteroidbelt:2.3-3.3au   
		-- Asteroids range in size from hundreds of kilometres across to microscopic
		-- The asteroid belt contains tens of thousands, possibly millions, of objects over one kilometre in diameter.
		-- [46] Despite this, the total mass of the main belt is unlikely to be more than a thousandth of that of the Earth.
		-- [47] The main belt is very sparsely populated
		-- outerplanets: 
		{ "jupiter"		,5.2*au		,71492*km			},
		{ "saturn"		,9.5*au     ,60268*km			},
		{ "uranus"		,19.6*au    ,25559*km			},
		{ "neptune"		,30*au      ,24764*km			},
		-- kuiper belt: 30au-50au   pluto:39au   haumea:43.34au  makemake:45.79au
	}
	
	
	for k,o in pairs(planets) do 
		local name,d,pr,maxstations = unpack(o)
		maxstations = maxstations or 2
		local x,y,z = GetRandomOrbitFlatXY(d,0.01*d)
		--~ local x,y,z = d,0,0
		local r = 0
		local ploc = cLocation:New(solroot,x,y,z,r,"planet-loc "..name)
		RegisterMajorLoc(ploc)
		ploc.name = name
		
		local planet = cPlanet:New(ploc,0,0,0	,pr,"planetbase")
		ploc.planet = planet
		planet:SetRandomRot()
		planet.name = name
		RegisterNavTarget(planet)
		
		-- stations
		for i = 1,math.random(0,maxstations) do 
			local d = pr * (1.2 + 0.3 * math.random())
			local x,y,z = GetRandomOrbitFlatXY(d,0.01*d)
			local sloc = cLocation:New(ploc,x,y,z,0,"station-loc under "..planet.name)
			RegisterMajorLoc(sloc)
			local s = cStation:New(sloc,0,0,0	,400,"agricultural_station.mesh")
			s.orbit_master = planet
			RegisterNavTarget(s)
		end
		
		-- player ship
		if (o.bStartHere and (not gPlayerShip)) then SpawnPlayer(planet) end
	end
end


-- obsolete, was used by first generation mesh import via .obj, now replaced by xmesh import with proper material name fixes
--~ EnsureMeshMaterialNamePrefix("llama.mesh","llama")
--~ EnsureMeshMaterialNamePrefix("ruizong.mesh","ruizong")
--~ EnsureMeshMaterialNamePrefix("agricultural_station.mesh","agricultural_station")
-- see also    data/convertmaterial.lua   for adjusting the .material files
-- prefix material names at runtime
function EnsureMeshMaterialNamePrefix (meshname,prefix)
	local mesh = MeshManager_load(meshname) assert(mesh)
	--~ print("EnsureMeshMaterialNamePrefix",meshname,mesh:getNumSubMeshes())
	for i=0,mesh:getNumSubMeshes()-1 do 
		local sub = mesh:getSubMesh(i) assert(sub)
		local mat = sub:getMaterialName()
		local mat2 = EnsureMaterialNamePrefix(mat,prefix)
		sub:setMaterialName(mat2)
		--~ print("sub",i,mat2)
	end
end
function EnsureMaterialNamePrefix (matname,prefix)
	if (string.find(matname,prefix,nil,true) ~= 1) then return prefix.."_"..matname end
	return matname
end


-- obsolete, was used for location/mayorloc debug
function GetGfxHierarchyText (gfx) return GetNodeHierarchyText(gfx:GetSceneNode()) end
function GetNodeHierarchyText (node) 
	if (not node) then return "." end
	local x,y,z = node:getPosition()
	local ax,ay,az = node:_getDerivedPosition()
	return string.gsub(tostring(node:getRealAddress()),"userdata: ","").."("..x..","..y..","..z..")("..ax..","..ay..","..az.."):"..GetNodeHierarchyText(node:getParentSceneNode())
end


-- obsolete, planet only (no stations), use units.csv Cargo_Import instead
function Trade_GetTradeGoodsFilePathFromUnitType (t)
	return GetVegaDataDir().."units/"..t.Directory.."/"..string.gsub(t.Directory,".*/","")
end
--[[
local filepath = Trade_GetTradeGoodsFilePathFromUnitType(t)
local xml = filepath and file_exists(filepath) and LuaXML_ParseFile(filepath) if (not xml) then return end -- uninhabitable etc, NOTE: stations use units:csv:Cargo_Import
gTradeGoodXML = EasyXMLWrap(xml[1]) assert(gTradeGoodXML)
local xml_hold = gTradeGoodXML.Hold[1] assert(xml_hold) -- <Hold volume="100000000000">
print("xml_hold volume=",tonumber(xml_hold.volume or 1000))
for k,xml_cat in ipairs(xml_hold) do -- <Category file="Natural_Products/Food">
	local cat_file = xml_cat.file 
	local o = xml_cat.import[1] -- <import price=".75" pricestddev=".15" quantity="25" quantitystddev="25"/>
	print("+",o.price,o.pricestddev,o.quantity,o.quantitystddev,cat_file) 
end
-- note : VegaStrike/data/units/factions/planets  subfolders contain buy/sell infos		cargo,ware,price.  but apparently unused
<Upgrade file="confed_missions"/>
<Upgrade file="aera_missions"/>
<Upgrade file="iso_missions"/>
<Upgrade file="rlaan_missions"/>
<Upgrade file="standard_missions"/>
]]--


-- obsolete, testing trade info loader
function TradeInfoTest ()
	print("========= CARGO TEST")
	local myvolume = 2000
	local mycash = 87*1000*1000
	local minprofit_per_run = 150*1000
	
	local myvolume = 10*1000
	--~ local mycash = 1080*1000
	--~ local mycash = 3*1000*1000
	
	--~ local myvolume = 200
	--~ local mycash = 880*1000
	
	-- results
	local result_list = {}
	local devmult = 0
	
	-- calc sell_list
	local sell_list = {}
	for k1,t in pairs(gUnitTypes) do
		for k,trade in ipairs(GetTradeListForBaseType(t) or {}) do
			local arr = sell_list[trade.path]
			if (not arr) then arr = {{best_sell_price=trade.base_price,where="??any??"}} sell_list[trade.path] = arr end
			local best_sell_price = ceil(trade.base_price * (trade.mult_price + devmult*trade.mult_pricestddev))
			if (best_sell_price >= trade.base_price) then table.insert(arr,{best_sell_price=best_sell_price,where=t.id}) end
		end 
	end
	for k,arr in pairs(sell_list) do table.sort(arr,function (a,b) return a.best_sell_price > b.best_sell_price end) end
	
	local function ID2Ingame (id) return GetPlanetTypeInGameName(id) or id end
	
	-- see where we can buy
	for k1,t in pairs(gUnitTypes) do
		for k,trade in ipairs(GetTradeListForBaseType(t) or {}) do
			local best_sell_arr = sell_list[trade.path]
			for i=1,min(999999999,#best_sell_arr) do 
				local best_sell = best_sell_arr[i]
				local cur_best_buy_price = floor(trade.base_price * (trade.mult_price - devmult*trade.mult_pricestddev))
				local one_profit = (best_sell.best_sell_price - cur_best_buy_price)
				local quant_min = max(0,floor(trade.quant - trade.quantstddev))
				local quant_max = max(0,floor(trade.quant + trade.quantstddev))
				local quant_run = min(floor(myvolume/trade.volume),floor(mycash/cur_best_buy_price),quant_max)
				local per_run_profit = one_profit * quant_run
				local total_profit = one_profit * (trade.quant + trade.quantstddev)
				if (per_run_profit > minprofit_per_run) then 
				if ((not string.find(trade.categoryname,"^upgrades/")) and t.id ~= best_sell.where) then 
					table.insert(result_list,{
						"run:"..NiceNum(per_run_profit),
						"t:"..NiceNum(total_profit),
						"1:"..NiceNum(one_profit),
						"s1:"..NiceNum(best_sell.best_sell_price),
						"s2:"..NiceNum(trade.base_price),
						"b:"..NiceNum(cur_best_buy_price),
						"mb:"..NiceNum(cur_best_buy_price*quant_run),
						"c:"..NiceNum(trade.volume),
						quant_min.."-"..quant_max,
						pad(ID2Ingame(t.id),20).."->"..pad(ID2Ingame(best_sell.where),20),
						trade.path,
						per_run_profit=per_run_profit})
				end
				end
			end
		end
	end
	
	table.sort(result_list,function (a,b) return a.per_run_profit > b.per_run_profit end)
	for k,o in ipairs(result_list) do print(unpack(o)) end
end
