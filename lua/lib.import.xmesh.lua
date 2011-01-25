-- import xmesh (vegastrike xml mesh format) to ogre (allows saving/exporting as ogre.mesh)
--~ BFXM spec (old) : http://vegastrike.svn.sourceforge.net/viewvc/vegastrike/trunk/vegastrike/objconv/mesher/BFXM%20specification.txt?revision=7726&view=markup
--~ XMESH spec (old) : http://vegastrike.svn.sourceforge.net/viewvc/vegastrike/trunk/vegastrike/objconv/xmlspec?revision=594&view=markup

RegisterListener("Hook_CommandLine",function ()
	local bSuccess,sError = lugrepcall(function () -- protected call, print error
		local path = gCommandLineSwitchArgs["-xmesh"]
		if path then ConvertXMesh(path,gCommandLineSwitchArgs["-out"]) os.exit(0) end
		
		if gCommandLineSwitches["-xmeshtest"] then ConvertXMesh("/cavern/code/VegaStrike/meshertest/xmesh_plowshare/plowshare_prime.xmesh") os.exit(0) end
	end)
	if (not bSuccess) then print("import.xmesh error : ",sError) os.exit(0) end
end)

function ConvertXMesh (inpath,outpath)
	print("ConvertXMesh",inpath,outpath)
	local xmlmainnodes = LuaXML_ParseFile(inpath)
	assert(xmlmainnodes,"failed to load '"..tostring(inpath).."'")
	local xml = xmlmainnodes[1]
	assert(xml,"xml main node missing")
	assert(not xmlmainnodes[2],"more than one xml main node")
	xml = EasyXMLWrap(xml)
	local xml_mesh = xml	assert(xml_mesh._name == "Mesh")
	local xml_mat
	local xml_points
	local xml_polys
	
	-- check entries on first hierarchy level
	for k,sub in ipairs(xml) do
		print("subnode:",sub._name)
			if (sub._name == "Material"		) then 	assert(not xml_mat,	"more than one Material entry")			xml_mat = sub
		elseif (sub._name == "LOD"			) then	print(" todo: LOD")
		elseif (sub._name == "Points"		) then	assert(not xml_points,	"more than one Points entry")		xml_points = sub
		elseif (sub._name == "Polygons"		) then	assert(not xml_polys,	"more than one Polygons entry")		xml_polys = sub
		else 
			print("unknown subnode:"..tostring(sub._name))
			assert(false,"unknown subnode: fatal for debug")
		end
	end
	assert(xml_mat,		"no Material entry found")
	assert(xml_points,	"no Points entry found")
	assert(xml_polys,	"no Polygons entry found")
	
	-- points
	local points = {}
	for k1,point in ipairs(xml_points) do 
		assert(point._name == "Point")
		local p = {}
		--~ <Location x="-12.366974" y="-5.367156" z="-2.585358" s="0.000000" t="0.000000"/>
		--~ <Normal i="0.476627" j="0.857523" k="-0.193598"/>
		for k2,sub in ipairs(point) do 
				if (sub._name == "Location") then 	for k,v in pairs(sub._attr) do p[k] = v end	
				assert((not sub.s) or (tonumber(sub.s) == 0),"debug-assert : non-zero value for unknown Point.Location attribute s")
				assert((not sub.t) or (tonumber(sub.t) == 0),"debug-assert : non-zero value for unknown Point.Location attribute t")
			elseif (sub._name == "Normal") then 	for k,v in pairs(sub._attr) do p[k] = v end	
			else
				print("unexpected point-attribute:",sub._name)
				assert(false,"unexpected point-attribute: fatal for debug")
			end
		end
		
		table.insert(points,p)
		--~ local txt = {} for k,v in pairs(p) do table.insert(txt,tostring(k).."="..tostring(v)) end txt = table.concat(txt,",") print(k1,txt)
	end
	
	
	-- polys
	local polys = {}
	for k1,poly in ipairs(xml_polys) do 
		assert(poly._name == "Tri")
		assert(#poly == 3,"expected 3 vertices! "..#poly)
		if (poly.flatshade ~= "0") then print("warning: Tri.flatshade not supported") end
		if (poly.flatshade ~= "0") then assert(false,"debug-assert: Tri.flatshade not supported") end
		local p = {}
		for k2,vertex in ipairs(poly) do
			assert(vertex._name == "Vertex")
			local pointidx = tonumber(vertex.point)
			local where = "["..k1..","..k2..","..pointidx.."]"
			local point = points[pointidx+1] assert(point)
			-- todo : s/t in poly overrides s/t in point creating a new vertex ? not sure on the meaning of them, suspected texcoords.  Point.Location.t/s seem to always be zero
			--~ assert(point.s == vertex.s,where.." s!=s:"..point.s.."~"..vertex.s)
			--~ assert(point.t == vertex.t,where.." t!=t:"..point.t.."~"..vertex.t)
			--~ <Polygons>
			--~ <Tri flatshade="0">
				--~ <Vertex point="0" s="0.724862" t="0.822618"/>
		end
	end
end
