-- import xmesh (vegastrike xml mesh format) to ogre (allows saving/exporting as ogre.mesh)
--~ BFXM spec (old) : http://vegastrike.svn.sourceforge.net/viewvc/vegastrike/trunk/vegastrike/objconv/mesher/BFXM%20specification.txt?revision=7726&view=markup
--~ XMESH spec (old) : http://vegastrike.svn.sourceforge.net/viewvc/vegastrike/trunk/vegastrike/objconv/xmlspec?revision=594&view=markup

kXMeshConvertBFXMConvertScriptPath = "../script/convert_bfxm.sh" -- script to call vegastrike:mesher for export from bfxm to xmesh
local iMkDirPerm = 7+7*8+7*8*8 -- drwxr-xr-x

RegisterListener("Hook_CommandLine",function ()
	local bSuccess,sError = lugrepcall(function () -- protected call, print error
		local path = gCommandLineSwitchArgs["-xmesh"]
		if path then MyXMeshConvertInitOgre() ConvertXMesh(path,gCommandLineSwitchArgs["-out"]) os.exit(0) end
	
		if gCommandLineSwitches["-xmeshtest"] then 
			MyXMeshConvertInitOgre() 
			--~ local meshname,boundrad = ConvertXMesh("/cavern/code/VegaStrike/meshertest/xmesh_plowshare/plowshare_prime.xmesh") 
			--~ local meshname,boundrad = ConvertXMesh("/cavern/code/VegaStrike/meshertest/xmesh_plowshare/2_0.xmesh") 
			--~ local meshname = "Plowshare.mesh"
			--~ TableCamViewMeshLoop(meshname,boundrad)
			
			MyMassConvert("/cavern/code/VegaStrike/data/units/vessels/","/cavern/code/vegaogre/data/units/vessels/")
			os.exit(0) 
		end
		
		if gCommandLineSwitches["-viewmesh"] then 
			MyXMeshConvertInitOgre() 
			local meshname = gCommandLineSwitchArgs["-viewmesh"] or "plowshare.mesh"
			TableCamViewMeshLoop(meshname)
			os.exit(0) 
		end
	end)
	if (not bSuccess) then print("import.xmesh error : ",sError) os.exit(0) end
end)

local function ListFiles	(path) local res = dirlist(path,false,true) table.sort(res) return res end
local function ListDirs		(path)
	local arr = dirlist(path,true,false) table.sort(arr)
	local res = {} for k,dir in ipairs(arr) do if (dir ~= "." and dir ~= ".." and dir ~= ".svn") then table.insert(res,dir) end end 
	return res
end

-- warning : mass convert expects empty destination. will delete existsing .xmesh and .bfxm files in destination
function MyMassConvert (in_folder_path,out_folder_path) 
	print("MyMassConvert",in_folder_path)
	mkdir(out_folder_path,iMkDirPerm)
	for k,dir in ipairs(ListDirs(in_folder_path)) do 
		if (dir ~= ".." and dir  ~= "." and dir ~= ".svn") then 
			--~ print("model_folder",dir)
			local bOk = true
			--~ bOk = dir >= "Mk32"
			-- Logo : "Agasicles","Agesipolis","Anaxidamus","Charillus","Convolution"
			-- TODO : flatshade : Charillus,Cultivator
			-- lib.import.xmesh.lua:312: no Material entry found  "H496","Mk32"
			for k,v in ipairs({"H496","Mk32"}) do if (dir == v) then bOk = false end end
			if (bOk) then 
				MyMassConvert_OneModelFolder(in_folder_path,out_folder_path,dir)
			end
		end
	end
	--~ MyMassConvert_OneModelFolder(in_folder_path,out_folder_path,"Admonisher")
	--~ MyMassConvert_OneModelFolder(in_folder_path,out_folder_path,"Plowshare")
	--~ MyMassConvert_OneModelFolder(in_folder_path,out_folder_path,"Llama")
end

function MyMassConvert_OneModelFolder (in_folder_path,out_folder_path,model_folder_name)
	in_folder_path = in_folder_path..model_folder_name.."/"
	out_folder_path = out_folder_path..model_folder_name.."/"
	print("MyMassConvert_OneModelFolder",in_folder_path,out_folder_path,model_folder_name)
	mkdir(out_folder_path,iMkDirPerm)
	
	
	-- check subdirs
	for k,dir in ipairs(ListDirs(in_folder_path)) do if (dir ~= "." and dir ~= ".." and dir ~= ".svn") then print("WARNING MyMassConvert_OneModelFolder: subdir",dir,out_folder_path) end end
	
	-- check files
	local file_translate = {} -- .png to .dds, prepend foldername etc
	local meshfiles = {}
	local sFilePrefix = model_folder_name.."_"
	for k,file in ipairs(ListFiles(in_folder_path)) do
		local ext = string.gsub(file,"^.*%.","")
		--~ print("MyMassConvert_OneModelFolder file",ext,file)
		if (ext == "bfxm") then
			table.insert(meshfiles,file)
		elseif (ext == "spr") then
			print("copy unchanged",file)
			CopyFile(in_folder_path..file,out_folder_path..file) -- copy unchanged
		elseif (ext == "png" or ext == "jpg" or ext == "texture" or ext == "image") then
			local newfilename = sFilePrefix..file..".dds"
			file_translate[file] = newfilename
			print("translate filename",file,newfilename)
			CopyFile(in_folder_path..file,out_folder_path..newfilename) -- copy, but change filename
		else
			print("WARNING MyMassConvert_OneModelFolder: unknown file ext",ext,file,out_folder_path)
		end
	end
	
	-- utils
	local function DeleteXMeshFiles (folderpath) 
		for k,file in ipairs(ListFiles(folderpath)) do 
			local ext = string.gsub(file,"^.*%.","")
			if (ext == "xmesh") then
				print("delete xmesh:",file)
				os.remove(folderpath..file)
			end
		end
	end
	
	-- handle meshes
	local function EscapeShellArg (s) return "'"..string.gsub(string.gsub(string.gsub(s,"%$","\\$"),"\"","\\\""),"'","\\'").."'"  end -- todo : not well tested
	for k1,meshfile in ipairs(meshfiles) do -- meshfile = bfxm, can contain multiple submeshes
		print("=====================")
		print("converting mesh file",meshfile)
		
		-- prepare files
		CopyFile(in_folder_path..meshfile,out_folder_path..meshfile) -- copy unchanged
		DeleteXMeshFiles(out_folder_path) -- clear folder before calling mesher. deletes xmesh
		
		-- call bfxm to xmesh conversion script
		ExecGetLines(kXMeshConvertBFXMConvertScriptPath.." "..EscapeShellArg(out_folder_path).." "..EscapeShellArg(meshfile))
		
		-- list submesh xmesh files (excluding LOD files)
		local submesh_xmesh_list = {}
		local firstfile = out_folder_path..meshfile..".xmesh"
		if (file_exists(firstfile)) then table.insert(submesh_xmesh_list,firstfile) end
		for i=1,99 do
			local path_submesh = out_folder_path..i.."_0.xmesh"
			if (not file_exists(path_submesh)) then break end
			table.insert(submesh_xmesh_list,path_submesh)
		end
		
		-- names
		local sMeshNameBase = string.gsub(meshfile,"%.bfxm$","")
		local szMeshName = string.gsub(sMeshNameBase,"[^a-zA-Z0-9_]","")
		local sOutPath_Mesh = out_folder_path..sMeshNameBase..".mesh"
		
		-- start mesh
		local pMesh = MeshManager_createManual(szMeshName) -- Ogre::MeshPtr
		local minx_t,miny_t,minz_t,maxx_t,maxy_t,maxz_t = 0,0,0,0,0,0
		
		-- tranform texture filenames
		local function fun_TransformTexName (s)
			local sNew = file_translate[s]
			if (sNew) then return sNew end
			print("WARNING : fun_TransformTexName : unknown file",">"..tostring(s).."<")
			return s
		end
		
		for iSubMeshIdx,path_submesh in ipairs(submesh_xmesh_list) do 
			print("path_submesh",path_submesh)
			-- import submeshes
			local sInPath_XMesh = path_submesh
			local sMatName = sMeshNameBase..iSubMeshIdx
			local sOutPath_Material = out_folder_path..sMeshNameBase..iSubMeshIdx..".material"
			
			-- convert
			local bSuccess,bounds = ConvertXMesh_SubMesh(pMesh,sInPath_XMesh,sMatName,sOutPath_Material,fun_TransformTexName)
			if (bSuccess) then
				local minx,miny,minz,maxx,maxy,maxz = unpack(bounds)
				minx_t = min(minx_t,minx) maxx_t = max(maxx_t,maxx)
				miny_t = min(miny_t,miny) maxy_t = max(maxy_t,maxy)
				minz_t = min(minz_t,minz) maxz_t = max(maxz_t,maxz)
			else
				print("warning, failed to load xmesh (blink.ani?) : ",path_submesh)
			end
		end
		
		-- export mesh
		local boundrad = max(Vector.len(minx_t,miny_t,minz_t),Vector.len(maxx_t,maxy_t,maxz_t))
		pMesh:_setBounds({minx_t,miny_t,minz_t,maxx_t,maxy_t,maxz_t},false)
		pMesh:_setBoundingSphereRadius(boundrad)
		ExportMesh(szMeshName,sOutPath_Mesh)
		
		-- delete temporary file
		DeleteXMeshFiles(out_folder_path) -- xmesh
		os.remove(out_folder_path..meshfile) -- bfxm
		--~ return
	end
end

function MyXMeshConvertInitOgre ()
	print("MyXMeshConvertInitOgre...")
	SetOgreInputOptions(gbHideMouse,gbGrabInput)
	local bAutoCreateWindow = false
	local bAutoCreateWindow = true -- window needed due to texture-loading (vram) ?
	if (not InitOgre("VegaOgre",gOgrePluginPathOverride or lugre_detect_ogre_plugin_path(),gBinPath,bAutoCreateWindow)) then os.exit(0) end
	CollectOgreResLocs()
    SetCursorBaseOffset(0,0)
    Client_RenderOneFrame() -- first frame rendered with ogre, needed for init of viewport size
    gViewportW,gViewportH = GetViewportSize()
	print("MyXMeshConvertInitOgre done.")
end

function TableCamViewMeshLoop (meshname,boundrad)
	local x,y,z = Vector.random3(1000)
	UpdateWorldLight(x,y,z)
	local e = .5	local r,g,b = e,e,e		Client_SetAmbientLight(r,g,b, 1)

	local mesh_files = {
	"Sickle/sickle.mesh",
	"Leonidas/yavok.mesh",
	"Sartre/sartre.mesh",
	"Shizu/shizu.mesh",
	"Thales/thales.mesh",
	"Dirge/dirge.mesh",
	"Goddard/goddard.mesh",
	"Vigilance/vigilance.mesh",
	"Kahan/kahan.mesh",
	"Lancelot/lancelot.mesh",
	"Ox/ox.mesh",
	"Ox/ox_new.mesh",
	"Hyena/hyena.mesh",
	"Xuanzong/Xuanzong.mesh",
	"Franklin/franklin.mesh",
	"Gaozong/gaozong.mesh",
	"GTIO/gtio.mesh",
	"Emu/emu.mesh",
	"Ancestor/ancestor.mesh",
	"Plowshare/plowshare.mesh",
	"Anaxidamus/anaxidamus.mesh",
	"Cultivator/cultivator.mesh",
	"Quicksilver/quicksilver.mesh",
	"Agasicles/agasicles.mesh",
	"Charillus/Charillus.mesh",
	"Bell/bell.mesh",
	"Clydesdale/clydesdale.mesh",
	"Ct2000/ct2000.mesh",
	"Hidalgo/hidalgo.mesh",
	"Mule/mule.mesh",
	"Hawking/hawking.mesh",
	"Seaxbane/seaxbane.mesh",
	"Progeny/progeny.mesh",
	"Koala/koala.mesh",
	"Shizong/Shizong-Hi.mesh",
	"Derivative/Derivative.mesh",
	"Diligence/diligence.mesh",
	"Robin/robin.mesh",
	"Gawain/gawain.mesh",
	"Dostoevsky/dostoevsky.mesh",
	"MacGyver/macgyver.mesh",
	"Dodo/dodo.mesh",
	"Dodo/skatecargo.mesh",
	"Pacifier/pacifier.mesh",
	"Nicander/nicander.mesh",
	"Schroedinger/schroedinger.mesh",
	"Agesipolis/agesipolis.mesh",
	"Kafka/kafka.mesh",
	"Regret/regret.mesh",
	"Redeemer/redeemer.mesh",
	"Convolution/convolution.mesh",
	"Hammer/hammer.mesh",
	"Gleaner/ishmael.mesh",
	"Areus/areus.mesh",
	"Ruizong/ruizong.mesh",
	"Entourage/entourage.mesh",
	"Admonisher/admonisher.mesh",
	"Determinant/determinant.mesh",
	"Ariston/ariston.mesh",
	"Beholder/beholder.mesh",
	"Zhuangzong/zhuangzong.mesh",
	"Vendetta/vendetta.mesh",
	"Midwife/midwife.mesh",
	"Archimedes/archimedes.mesh",
	"Tridacna/tridacna.mesh",
	"Kierkegaard/kierkegaard.mesh",
	"Tesla/tesla.mesh",
	"Watson/Watson_f.mesh",
	"Watson/watson.mesh",
	"Yeoman/stoic.mesh",
	"Jackal/jackal.mesh",
	"Taizong/taizong.mesh",
	"Llama/llama.mesh",
	"Shundi/shundi.mesh",
	"Shenzong/shenzong.mesh",
	"Knight/knight.mesh",
	}
	table.sort(mesh_files)
	
	local gfx = CreateRootGfx3D() 
	--~ EnsureMeshMaterialNamePrefix("llama.mesh","llama")
	gfx:SetMesh(meshname)
	--~ gfx:SetMesh("axes.mesh")
	--~ gfx:SetMesh("llama.mesh")
	
	gNextMeshIndex = 1
	
	local camdist = boundrad and (boundrad*2) or 10
	BindDown("escape", 		function () os.exit(0) end)
    BindDown("wheeldown",   function () camdist = camdist / 0.5 print("camdist",camdist) end)
    BindDown("wheelup",     function () camdist = camdist * 0.5 print("camdist",camdist) end)
    BindDown("space",     function ()
		local meshname = mesh_files[gNextMeshIndex] 
		gNextMeshIndex = gNextMeshIndex + 1
		if (gNextMeshIndex > #mesh_files) then gNextMeshIndex = 1 end
		if (meshname) then
			print("==============================")
			print("viewing",meshname)
			meshname = string.gsub(meshname,".*/","")
			gfx:SetMesh(meshname)
		end
	end)

    while (Client_IsAlive()) do 
		gViewportW,gViewportH = GetViewportSize()
		LugreStep()
		InputStep() -- generate mouse_left_drag_* and mouse_left_click_single events 
		GUIStep() -- generate mouse_enter, mouse_leave events (might adjust cursor -> before CursorStep)
		ToolTipStep() -- needs mouse_enter, should be after GUIStep
		CursorStep()
		
		local speedfactor = 0.01
		local ox,oy,oz = 0,0,1
		StepTableCam(GetMainCam(),gKeyPressed[key_mouse_left],speedfactor,true)
		StepThirdPersonCam(GetMainCam(),camdist,ox,oy,oz)
		
		Client_RenderOneFrame()
		Client_USleep(1) -- just 1 millisecond, but gives other processes a chance to do something
    end
end




function ConvertXMesh (sInPath_XMesh,sOutPath)
	-- names
	local sModelName = "Plowshare"
	local sOgreNameSuffix = sModelName.."01"
	local tex_prefix = sModelName.."_"
	local sMatName = "myXMeshConvertMat"..sOgreNameSuffix
	local szMeshName = "myXMeshConvertMesh"..sOgreNameSuffix
	local sOutPath_Material = sOutPath..sModelName..".material"
	sOutPath = sOutPath or "../data/units/vessels/"..sModelName.."/"
	--~ sOutPath = "../data/units/vessels/"..sModelName.."/subtest/"
	
	-- fun_TransformTexName
	local bAssumeTextureDDS = true
	local function fun_TransformTexName (s)
		local sOld = s
		if (bAssumeTextureDDS) then  -- vegastrike texture filenames/extensions are wrong, assume dds format for .png files, as ogre cannot handle the error
			s = string.gsub(s,"%..*$",".dds") -- replace file ending by .dds
		end
		local res = tex_prefix..s 
		print("TransformTexName",sOld,res)
		if (1 == 1) then
			--~ local imgpath = string.gsub(sInPath_XMesh,"[^/]+$","")..sOld
			local imgpath = res
			--~ local folder = sInPath_XMesh
			print("attempting to load image",imgpath)
			local img = CreateOgreImage() 
			local bSuccess,sErrMsg = img:load(imgpath)
			if (not bSuccess) then print("Warning! error loading image:",imgpath,sErrMsg) else print("load image ok") end
			if (not bSuccess) then assert(false,"Warning! error loading image:",imgpath,sErrMsg) end -- debug exit
		end
		return res 
	end
	
	-- start mesh
	local pMesh = MeshManager_createManual(szMeshName) -- Ogre::MeshPtr
	
	-- convert
	local bSuccess,bounds = ConvertXMesh_SubMesh(pMesh,sInPath_XMesh,sMatName,sOutPath_Material,fun_TransformTexName)
	if (not bSuccess) then return end -- blink.ani , shield_flicker.ani
	
	-- calc bounds
	-- TODO : calc bounds for whole mesh, not only for this submesh
	local minx,miny,minz,maxx,maxy,maxz = unpack(bounds)
	local boundrad = max(Vector.len(minx,miny,minz),Vector.len(maxx,maxy,maxz))
	pMesh:_setBounds({minx,miny,minz,maxx,maxy,maxz},false)
	pMesh:_setBoundingSphereRadius(boundrad)
	
	local sFileName = sOutPath..sModelName..".mesh"
	ExportMesh(szMeshName,sFileName)
	return szMeshName,boundrad
end


function ConvertXMesh_SubMesh (pMesh,sInPath_XMesh,sMatName,sOutPath_Material,fun_TransformTexName)
	print("ConvertXMesh",sInPath_XMesh)
	local xmlmainnodes = LuaXML_ParseFile(sInPath_XMesh)
	assert(xmlmainnodes,"failed to load '"..tostring(sInPath_XMesh).."'")
	local xml = xmlmainnodes[1]
	assert(xml,"xml main node missing")
	assert(not xmlmainnodes[2],"more than one xml main node")
	xml = EasyXMLWrap(xml)
	local xml_mesh = xml	assert(xml_mesh._name == "Mesh")
	local xml_mat
	local xml_points
	local xml_polys
	local bDebug = true
	
	-- TODO : lights. but not loadable in ogre
	if (xml_mesh.texture == "blink.ani") then print("mesh is metadata only "..xml_mesh.texture) return end
	-- TODO if (xml_mesh.animation == "shield_flicker.ani") then sMatName = "ship_shield" end
	
	-- check entries on first hierarchy level
	for k,sub in ipairs(xml) do
		print("subnode:",sub._name)
			if (sub._name == "Material"		) then 	assert(not xml_mat,	"more than one Material entry")			xml_mat = sub
		elseif (sub._name == "LOD"			) then	-- print(" todo: LOD")  ignored, can be generated by ogre if needed
		elseif (sub._name == "Logo"			) then	-- ignored, "Agasicles","Agesipolis","Anaxidamus","Charillus","Convolution"
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
	
	-- expected attributes
	local function MyAttrCheck (attr,eattr,txt) for k,v in pairs(attr) do if (not eattr[k]) then eattr[k] = true print("Unexpected Attribute",k,txt) end end end
	
	-- points
	if (bDebug) then print("scanning points...") end
	local points = {}
	local eattr_point_location = {x=true,y=true,z=true,s=true,t=true}
	local eattr_point_normal = {i=true,j=true,k=true}
	for k1,xml_point in ipairs(xml_points) do 
		assert(xml_point._name == "Point")
		local p = {}
		table.insert(points,p)
		for k2,sub in ipairs(xml_point) do 
				if (sub._name == "Location") then 	for k,v in pairs(sub._attr) do p[k] = v end	MyAttrCheck(sub._attr,eattr_point_location,"Point.Location")
				--~ assert((not sub.s) or (tonumber(sub.s) == 0),"debug-assert : non-zero value for unknown Point.Location attribute s")
				--~ assert((not sub.t) or (tonumber(sub.t) == 0),"debug-assert : non-zero value for unknown Point.Location attribute t")
			elseif (sub._name == "Normal") then 	for k,v in pairs(sub._attr) do p[k] = v end MyAttrCheck(sub._attr,eattr_point_normal,"Point.Normal")
			else
				print("unexpected point-attribute:",sub._name)
				assert(false,"unexpected point-attribute: fatal for debug")
			end
		end
		--~ local txt = {} for k,v in pairs(p) do table.insert(txt,tostring(k).."="..tostring(v)) end txt = table.concat(txt,",") print(k1,txt)
	end
	
	-- prepare ogre geometry buffers
	local vb = cVertexBuffer:New()
	local ib = cIndexBuffer:New()
	local vc = 0
	
	-- search if a vertex already exists or create a new one if not
	local known_vertex = {}
	local minx,miny,minz
	local maxx,maxy,maxz
	local function GetCreateVertexIdx (x,y,z, nx,ny,nz, u,v)
		minx = min(minx or x,x)
		miny = min(miny or y,y)
		minz = min(minz or z,z)
		maxx = max(maxx or x,x)
		maxy = max(maxy or y,y)
		maxz = max(maxz or z,z)
		local name = table.concat({x,y,z, nx,ny,nz, u,v},",")
		local cache = known_vertex[name]
		if (cache) then return cache end
		vb:Vertex(x,y,z, nx,ny,nz, u,v)
		local idx = vc
		vc = vc + 1
		known_vertex[name] = idx
		return idx
	end
	
	-- polys (vertexbuffer gets filled here)
	if (bDebug) then print("scanning polygons...") end
	local polys = {}
	local eattr_poly_tri = {flatshade=true}
	local eattr_poly_vertex = {point=true,s=true,t=true}
	local s = tonumber(xml_mesh.scale) or 1 -- scale
	for k1,xml_poly in ipairs(xml_polys) do 
		if (bDebug and (k1 % 500) == 1) then print("scanning polygons "..k1.."/"..#xml_polys) end
		if (xml_poly._name == "Tri") then
			assert(#xml_poly == 3,"expected 3 vertices! "..#xml_poly)
			if (xml_poly.flatshade ~= "0") then print("warning: Tri.flatshade not supported") end
			--~ if (xml_poly.flatshade ~= "0") then assert(false,"debug-assert: Tri.flatshade not supported") end
			MyAttrCheck(xml_poly._attr,eattr_poly_tri,"Polygons.Tri")
			for k2,xml_vertex in ipairs(xml_poly) do
				assert(xml_vertex._name == "Vertex")
				MyAttrCheck(xml_vertex._attr,eattr_poly_vertex,"Polygons.Tri.Vertex")
				local pointidx = tonumber(xml_vertex.point)
				local point = points[pointidx+1] assert(point)
				-- add vertex to buffer
				ib:Index(GetCreateVertexIdx((point.x or 0)*s,(point.y or 0)*s,(point.z or 0)*s, 
											point.i or 0,point.j or 0,point.k or 1, 
											xml_vertex.s or 0,xml_vertex.t or 0))
			end
		elseif (xml_poly._name == "Quad") then
			assert(#xml_poly == 4,"expected 4 vertices! "..#xml_poly)
			if (xml_poly.flatshade ~= "0") then print("warning: Quad.flatshade not supported") end
			--~ if (xml_poly.flatshade ~= "0") then assert(false,"debug-assert: Quad.flatshade not supported") end
			MyAttrCheck(xml_poly._attr,eattr_poly_tri,"Polygons.Quad")
			local vertex_idx_list = {}
			for k2,xml_vertex in ipairs(xml_poly) do
				assert(xml_vertex._name == "Vertex")
				MyAttrCheck(xml_vertex._attr,eattr_poly_vertex,"Polygons.Quad.Vertex")
				local pointidx = tonumber(xml_vertex.point)
				local point = points[pointidx+1] assert(point)
				-- add vertex to buffer
				vertex_idx_list[k2] = GetCreateVertexIdx((point.x or 0)*s,(point.y or 0)*s,(point.z or 0)*s, 
											point.i or 0,point.j or 0,point.k or 1, 
											xml_vertex.s or 0,xml_vertex.t or 0)
			end
			ib:Index(vertex_idx_list[1])
			ib:Index(vertex_idx_list[2])
			ib:Index(vertex_idx_list[3])
			ib:Index(vertex_idx_list[1])
			ib:Index(vertex_idx_list[3])
			ib:Index(vertex_idx_list[4])
		elseif (xml_poly._name == "Trifan") then
			assert(#xml_poly >= 4,"expected >= 3 vertices! "..#xml_poly)
			if (xml_poly.flatshade ~= "0") then print("warning: Trifan.flatshade not supported") end
			--~ if (xml_poly.flatshade ~= "0") then assert(false,"debug-assert: Trifan.flatshade not supported") end
			MyAttrCheck(xml_poly._attr,eattr_poly_tri,"Polygons.Trifan")
			local vertex_idx_list = {}
			for k2,xml_vertex in ipairs(xml_poly) do
				assert(xml_vertex._name == "Vertex")
				MyAttrCheck(xml_vertex._attr,eattr_poly_vertex,"Polygons.Trifan.Vertex")
				local pointidx = tonumber(xml_vertex.point)
				local point = points[pointidx+1] assert(point)
				-- add vertex to buffer
				vertex_idx_list[k2] = GetCreateVertexIdx((point.x or 0)*s,(point.y or 0)*s,(point.z or 0)*s, 
											point.i or 0,point.j or 0,point.k or 1, 
											xml_vertex.s or 0,xml_vertex.t or 0)
			end
			for i = 2,#vertex_idx_list do 
				ib:Index(vertex_idx_list[1])
				ib:Index(vertex_idx_list[i-1])
				ib:Index(vertex_idx_list[i])
			end
		else
			assert(false,"unexpected polygon entry : "..tostring(xml_poly._name))
		end
	end
	
	
	
	-- create material
	if (bDebug) then print("creating material...") end
	assert(MaterialManager_create,"recompile executable file, code was added 28.01.2011 and only compiled on linux at the time")
	local pMat	= MaterialManager_create(sMatName) assert(pMat)
	--~ local pTec	= pMat:createTechnique() assert(pTec)
	--~ local pPas	= pTec:createPass() assert(pPas)
	--~ local pTex	= pPas:createTextureUnitState() assert(pTex)
	local pTec	= pMat:getTechnique(0) assert(pTec)
	local pPas	= pTec:getPass(0) assert(pPas)
	local pTex	= pPas:createTextureUnitState() assert(pTex)
	assert(pMat:getName() == sMatName)
	
	-- apply global properties
	pTex:setTextureName(fun_TransformTexName(xml_mesh.texture or xml_mesh.animation or ""),TEX_TYPE_2D)
	local s = tonumber(xml_mat.power) if (s) then pMat:setShininess(s) end
	-- TODO : <Mesh  scale="1.0" reverse="0" forcetexture="0" sharevert="0" polygonoffset="0.0" blend="ONE ZERO" alphatest="0.0" texture="wayfarer.png"  texture1="wayfarerPPL.jpg" >
	-- TODO : <Material power="60.000000" cullface="1" reflect="1" lighting="1" usenormals="1">
	local eattr_mesh = {scale=true,reverse=true,forcetexture=true,sharevert=true,polygonoffset=true,blend=true,alphatest=true,texture=true,texture1=true}
	local eattr_mat = {power=true,cullface=true,reflect=true,lighting=true,usenormals=true}
	MyAttrCheck(xml_mesh._attr,eattr_mesh,"Mesh")
	MyAttrCheck(xml_mat._attr,eattr_mat,"Material")
	print("TODO : Mesh : texture1 (createTextureUnitState())")
	print("TODO : Mesh : reverse,forcetexture,sharevert,polygonoffset,blend,alphatest,animation")
	print("TODO : Material : cullface,reflect,lighting,usenormals")
	
	-- apply material-sub-properties (colors)
	local eattr_mat_prop = {Red=true,Green=true,Blue=true,Alpha=true}
	for k1,xml_matprop in ipairs(xml_mat) do
		MyAttrCheck(xml_matprop._attr,eattr_mat_prop,"Material."..tostring(xml_matprop._name))
		local r = tonumber(xml_matprop.Red	)
		local g = tonumber(xml_matprop.Green)
		local b = tonumber(xml_matprop.Blue	)
		local a = tonumber(xml_matprop.Alpha)
		print(xml_matprop._name,r,g,b,a)
		
			if (xml_matprop._name == "Ambient"	) then pMat:setAmbient(			r or 0,g or 0,b or 0)
		elseif (xml_matprop._name == "Diffuse"	) then pMat:setDiffuse(			r or 1,g or 1,b or 1,a or 1)
		elseif (xml_matprop._name == "Specular"	) then pMat:setSpecular(		r or 0,g or 0,b or 0,a or 0)
		elseif (xml_matprop._name == "Emissive"	) then pMat:setSelfIllumination(r or 0,g or 0,b or 0)
		else 
			print("unexpected material-attribute:",xml_matprop._name)
			assert(false,"unexpected material-attribute: fatal for debug")
		end
	end
	
	-- export material
	local bExportDefaults = false
	assert(pMat:MaterialSerializer_Export(sOutPath_Material,bExportDefaults))
	print("MaterialSerializer_Export ok")
	
	-- create submesh
	vb:CheckSize()
	if (bDebug) then print("creating submesh...") end
	local sub = pMesh:createSubMesh() -- Ogre::SubMesh*
	sub:setMaterialName(sMatName)
	sub:setUseSharedVertices(false)
	sub:setOperationType(OT_TRIANGLE_LIST)
	
	local vertexData = CreateVertexData()
	local indexData = CreateIndexData()
	sub:setVertexData(vertexData)
	sub:setIndexData(indexData)
	
	local vdecl = cVertexDecl:New()
	vdecl:addElement(0,VET_FLOAT3,VES_POSITION)
	vdecl:addElement(0,VET_FLOAT3,VES_NORMAL)
	vdecl:addElement(0,VET_FLOAT2,VES_TEXTURE_COORDINATES)
	--~  TODO : if (bUseColors)		offset += decl.addElement(0, offset, VET_COLOUR, VES_DIFFUSE).getSize()      autoorganize position!!!
	
	vertexData:setVertexDecl(vdecl:GetOgreVertexDecl())
	vertexData:createAndBindVertexBuffer(vb:GetVertexSize(),vb:GetVertexNum(),HBU_STATIC_WRITE_ONLY,false,0) -- (iVertexSize,iNumVerts,iUsage,bUseShadowBuffer=false,iBindIndex=0)
	indexData:createAndBindIndexBuffer(IT_32BIT,ib:GetIndexNum(),HBU_STATIC_WRITE_ONLY) -- (iIndexType,iNumIndexes,iUsage,bUseShadowBuffer=false)
	
	vertexData:setVertexStart(0)
	indexData:setIndexStart(0)
	vertexData:setVertexCount(vb:GetVertexNum())
	indexData:setIndexCount(ib:GetIndexNum())
	
	vertexData:writeToVertexBuffer(vb:GetFIFO(),0)
	indexData:writeToIndexBuffer(ib:GetFIFO()) 
	
	vb:Destroy()
	ib:Destroy()
	
	-- test material
	if (1 == 2) then 
		print("Material Test load ...",sOutPath_Material)
		assert(pMat:load())
		--~ print("Material Test load test 2",sMatName) -- had segfault later when trying to load dds with .png as filename
		--~ local clone_name,errmsg = CloneMaterial(sMatName)
		--~ assert(clone_name,errmsg)
		print("Material Test load ok")
		--~ assert(pMat:load())
		--~ MaterialManager_load(sMatName)
	end
	
	if (bDebug) then print("xmesh submesh convert finished.") end
	
	return true,{minx,miny,minz,maxx,maxy,maxz}
end
