-- import xmesh (vegastrike xml mesh format) to ogre (allows saving/exporting as ogre.mesh)
--~ BFXM spec (old) : http://vegastrike.svn.sourceforge.net/viewvc/vegastrike/trunk/vegastrike/objconv/mesher/BFXM%20specification.txt?revision=7726&view=markup
--~ XMESH spec (old) : http://vegastrike.svn.sourceforge.net/viewvc/vegastrike/trunk/vegastrike/objconv/xmlspec?revision=594&view=markup


--[[
note : shaders : units/installation/Agricult../technique="fireglass" : 
./programs/fireglass.vp
./programs/fireglass.fp
./techniques/fireglass.technique
]]--


kXMeshConvertBFXMConvertScriptPath = "../script/convert_bfxm.sh" -- script to call vegastrike:mesher for export from bfxm to xmesh
local iMkDirPerm = 7+7*8+7*8*8 -- drwxr-xr-x

RegisterListener("Hook_CommandLine",function ()
	local bSuccess,sError = lugrepcall(function () -- protected call, print error
		local path = gCommandLineSwitchArgs["-xmesh"]
		if path then MyXMeshConvertInitOgre() ConvertXMesh(path,gCommandLineSwitchArgs["-out"]) os.exit(0) end
	
		if gCommandLineSwitches["-xmeshtest1"] then 
			local pMesh,sInPath_XMesh,sMatName,sOutPath_Material,fun_TransformTexName
			sInPath_XMesh = gCommandLineSwitchArgs["-xmeshtest1"]
			ConvertXMesh_SubMesh(pMesh,sInPath_XMesh,sMatName,sOutPath_Material,fun_TransformTexName)
		end
		if gCommandLineSwitches["-xmeshmassconvert"] then 
			gXMeshMissingTexName = {}
			gXMeshTexNameTranslate = {
				["glass.png"				]="glass.png.dds",
				["shield.bmp"				]="shield.bmp.dds",
				["EMU.png"					]="Emu_emu.png.dds",
				["combine2.bmp"				]="combine2.bmp.dds",
				["combine.bmp"				]="combine.bmp.dds",
				["combine.jpg"				]="combine.jpg.dds",
				["combine4.bmp"				]="combine4.bmp.dds",
				["shield_generic.texture"	]="shield_generic.texture.dds",
				["white.bmp"				]="white.bmp.dds",
				["AeraHull.png"				]="AeraHull2.bmp.dds",
				["Asteroid.bmp"				]="Asteroid.bmp.dds",
				["AeraHull2.bmp"			]="AeraHull2.bmp.dds",
				
				--~ ["blink.ani"				]=".dds",
				--~ ["whitelight.ani"			]=".dds",
				--~ ["shield_flicker.ani"		]=".dds",
				--~ ["shield_ripple.ani"		]=".dds",
				--~ ["streak.ani"				]=".dds",
				--~ ["greenlight.ani"			]=".dds",

			}
			MyXMeshConvertInitOgre() 
			--~ local meshname,boundrad = ConvertXMesh("/cavern/code/VegaStrike/meshertest/xmesh_plowshare/plowshare_prime.xmesh") 
			--~ local meshname,boundrad = ConvertXMesh("/cavern/code/VegaStrike/meshertest/xmesh_plowshare/2_0.xmesh") 
			--~ local meshname = "Plowshare.mesh"
			--~ TableCamViewMeshLoop(meshname,boundrad)
			local dirs = {
				--~ "units/vessels/",
				--~ "units/installations/",
				--~ "units/factions/neutral/",
				--~ "units/factions/aera/",
				--~ "units/factions/forsaken/",
				--~ "units/factions/pirates/",
				--~ "units/factions/rlaan/",
				--~ "units/cargo/",
				--~ "units/weapons/",
				--~ "units/subunits/",
				--~ "meshes/mounts/",
				--~ "cockpits/",
				--~ "meshes/nav/",
			}
			local path_orig = "/cavern/code/VegaStrike/data/"
			local path_out  = "/cavern/code/vegaogre/data/"
			for k,dir in ipairs(dirs) do 
				MyMassConvert(path_orig..dir,path_out..dir)
			end
			--~ MyMassConvert_OneModelFolder(path_orig.."units/",path_out.."units/","eject")
			MyMassConvert_OneModelFolder(path_orig.."units/",path_out.."units/","wormhole")
			
			print("=======================\ngXMeshMissingTexName ") for k,v in pairs(gXMeshMissingTexName) do print(k,v) end
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
			print("WARNING MyMassConvert_OneModelFolder: unknown file ext",ext,in_folder_path..file)
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
			local sNew = file_translate[s] or gXMeshTexNameTranslate[s]
			if (sNew) then return sNew end
			gXMeshMissingTexName[tostring(s)] = sInPath_XMesh
			print("WARNING : fun_TransformTexName : unknown file",">"..tostring(s).."<")
			return s
		end
		
		local bEmptyMesh = true
		for iSubMeshIdx,path_submesh in ipairs(submesh_xmesh_list) do 
			print("path_submesh",path_submesh)
			-- import submeshes
			local sInPath_XMesh = path_submesh
			local sMatName = sMeshNameBase..iSubMeshIdx
			local sOutPath_Material = out_folder_path..sMeshNameBase..iSubMeshIdx..".material"
			
			-- convert
			local bSuccess,bounds = ConvertXMesh_SubMesh(pMesh,sInPath_XMesh,sMatName,sOutPath_Material,fun_TransformTexName)
			if (bSuccess) then
				bEmptyMesh = false
				local minx,miny,minz,maxx,maxy,maxz = unpack(bounds)
				minx_t = min(minx_t,minx or minx_t) maxx_t = max(maxx_t,maxx or maxx_t)
				miny_t = min(miny_t,miny or miny_t) maxy_t = max(maxy_t,maxy or maxy_t)
				minz_t = min(minz_t,minz or minz_t) maxz_t = max(maxz_t,maxz or maxz_t)
			else
				print("warning, failed to load xmesh (blink.ani?) : ",path_submesh)
			end
		end
		
		-- export mesh
		if (bEmptyMesh) then
			print("warning, empty mesh",meshfile)
		else
			local boundrad = max(Vector.len(minx_t,miny_t,minz_t),Vector.len(maxx_t,maxy_t,maxz_t))
			pMesh:_setBounds({minx_t,miny_t,minz_t,maxx_t,maxy_t,maxz_t},false)
			pMesh:_setBoundingSphereRadius(boundrad)
			ExportMesh(szMeshName,sOutPath_Mesh)
		end
		
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
	InitGuiThemes()
	
	local function MyNewLight ()
		local x,y,z = Vector.random3(1000)
		UpdateWorldLight(x,y,z)
		for i=1,2 do 
			local x,y,z = Vector.random3(1000)
			Client_AddPointLight(x,y,z)
		end
		local e = .2	local r,g,b = e,e,e		Client_SetAmbientLight(r,g,b, 1)
	end
	
	MyNewLight()

	local mesh_files = {
		"Starfortress/starfortress.mesh",
		"Factory/factory.mesh",
		"AsteroidFighterBase/asteroidfighterbase.mesh",
		"Uln_Asteroid_Refinery/uln_asteroid_refinery.mesh",
		"Diplomatic_Center/diplomatic_center.mesh",
		"Uln_Commerce_Center/uln_commerce_center.mesh",
		"Relay/relay.mesh",
		"Rlaan_Star_Fortress/rlaan_star_fortress.mesh",
		"Rlaan_Medical/rlaan_medical.mesh",
		"Medical/medical.mesh",
		"Outpost/outpost.mesh",
		"Agricultural_Station/agricultural_station.mesh",
		"Shaper_Bio_Adaptation/shaper_bio_adaptation.mesh",
		"Gasmine/gasmine.mesh",
		"MiningBase/MiningBase.mesh",
		"Shipyard/Shipyard.mesh",
		"Rlaan_Mining_Base/rlaan_mining_base.mesh",
		"Commerce_Center/commerce_center.mesh",
		"Civilan_Asteroid_Shipyard/civilan_asteroid_shipyard.mesh",
		"Research/research.mesh",
		"Rlaan_Fighter_Barracks/rlaan_fighter_barracks.mesh",
		"Uln_Refinery/uln_refinery.mesh",
		"Rlaan_Commerce_Center/rlaan_commerce_center.mesh",
		"Relaysat/relaysat.mesh",
		"Fighter_Barracks/fighter_barracks.mesh",
		"Refinery/refinery.mesh",
	}
	local mesh_files2 = {
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
	
	gMeshViewerMeshName = GetHUDBaseWidget():CreateChild("Text",{text="MeshViewer",textparam={r=1,g=1,b=1}})
	gMeshViewerMeshName:SetPos(10,5)
	
	local gfx = CreateRootGfx3D() 
	local camdist = 10
	
	local function MyShowMesh (meshname) 
		--~ EnsureMeshMaterialNamePrefix("llama.mesh","llama")
		gfx:SetMesh(meshname)
		--~ gfx:SetMesh("axes.mesh")
		--~ gfx:SetMesh("llama.mesh")
		camdist = gfx:GetEntity():getBoundingRadius() * 2.5
		gMeshViewerMeshName:SetText(string.gsub(meshname,"%.mesh$",""))
	end
	local function MyShowMeshIdx (idx) 
		gCurMeshIdx = idx
		if (gCurMeshIdx < 0) then gCurMeshIdx = #mesh_files end
		if (gCurMeshIdx > #mesh_files) then gCurMeshIdx = 1 end
		local meshname = mesh_files[gCurMeshIdx] 
		if (meshname) then
			print("==============================")
			print("viewing",meshname)
			meshname = string.gsub(meshname,".*/","")
			MyShowMesh(meshname)
		end
	end
	
	MyShowMeshIdx(1)
	
	BindDown("escape", 		function () os.exit(0) end)
    BindDown("wheeldown",   function () camdist = camdist / 0.5 end)
    BindDown("wheelup",     function () camdist = camdist * 0.5 end)
    BindDown("l",    		 function () MyNewLight() end)
    BindDown("space",    	 function () MyShowMeshIdx(gCurMeshIdx+1) end)
    BindDown("backspace",     function () MyShowMeshIdx(gCurMeshIdx-1) end)
    BindDown("i",     function () RegisterIntervalStepper(500,function () MyShowMeshIdx(gCurMeshIdx+1) end) end)
		
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
	--~ local xmlmainnodes = LuaXML_ParseFile(sInPath_XMesh)
	local xmlmainnodes = LuaLoadXML(FileGetContents(sInPath_XMesh))
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
			if (sub._name == "Material"				) then 	assert(not xml_mat,	"more than one Material entry")			xml_mat = sub
		elseif (sub._name == "LOD"					) then	-- print(" todo: LOD")  ignored, can be generated by ogre if needed
		elseif (sub._name == "Logo"					) then	-- ignored, "Agasicles","Agesipolis","Anaxidamus","Charillus","Convolution"
		elseif (sub._name == "Logo"					) then	-- ignored, "Agasicles","Agesipolis","Anaxidamus","Charillus","Convolution"
		elseif (sub._name == "Frame"				) then	print("Warning: subnode mesh animation not implemented, ignored",sub._name) -- ignored, data/units/wormhole/wormhole_stable.bfxm.xmesh
		elseif (sub._name == "AnimationDefinition"	) then	print("Warning: subnode mesh animation not implemented, ignored",sub._name) -- ignored, data/units/wormhole/wormhole_stable.bfxm.xmesh
		elseif (sub._name == "Points"				) then	assert(not xml_points,	"more than one Points entry")		xml_points = sub
		elseif (sub._name == "Polygons"				) then	assert(not xml_polys,	"more than one Polygons entry")		xml_polys = sub
		else 
			print("unknown subnode:"..tostring(sub._name))
			assert(false,"unknown subnode: fatal for debug")
		end
	end
	--~ assert(xml_mat,		"no Material entry found")
	--~ assert(xml_mat,		"no Material entry found")
	if (not xml_mat) then print("WARNING: no Material entry found",sInPath_XMesh) os.exit(0) return end
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
		elseif (xml_poly._name == "Line") then
			-- wormhole : data/units/wormhole/cyl_stable.bfxm.xmesh
		else
			assert(false,"unexpected polygon entry : "..tostring(xml_poly._name))
		end
	end
	
	if (ib:GetIndexNum() == 0) then 
		print("empty submesh (lines in wormhole?)")
		return
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
	print("TODO : Mesh : reverse,forcetexture,sharevert,polygonoffset,blend,alphatest,animation,technique") -- units/installation/Agricult../technique="fireglass"
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
	
	return true,{minx or 0,miny or 0,minz or 0,maxx or 0,maxy or 0,maxz or 0}
end


-- ***** xml parser to avoid bug 

--[[
WARNING! tinyxml fails to load this xml (no childs generated)
<Mesh aaa="" aaa="xxx">
<Material>
</Material>
</Mesh>
]]--

-- LoadXML from http://lua-users.org/wiki/LuaXml
function LuaLoadXML(s)
  local function LoadXML_parseargs(s)
    local arg = {}
    string.gsub(s, "(%w+)=([\"'])(.-)%2", function (w, _, a)
  	arg[w] = a
    end)
    return arg
  end
  local stack = {}
  local top = {}
  table.insert(stack, top)
  local ni,c,name,attr, empty
  local i, j = 1, 1
  while true do
    ni,j,c,name,attr, empty = string.find(s, "<(%/?)([%w:]+)(.-)(%/?)>", i)
    if not ni then break end
    local text = string.sub(s, i, ni-1)
    if not string.find(text, "^%s*$") then
      table.insert(top, text)
    end
    if empty == "/" then  -- empty element tag
      table.insert(top, {name=name, attr=LoadXML_parseargs(attr), empty=1})
    elseif c == "" then   -- start tag
      top = {name=name, attr=LoadXML_parseargs(attr)}
      table.insert(stack, top)   -- new level
    else  -- end tag
      local toclose = table.remove(stack)  -- remove top
      top = stack[#stack]
      if #stack < 1 then
        error("nothing to close with "..name)
      end
      if toclose.name ~= name then
        error("trying to close "..toclose.name.." with "..name)
      end
      table.insert(top, toclose)
    end
    i = j+1
  end
  local text = string.sub(s, i)
  if not string.find(text, "^%s*$") then
    table.insert(stack[#stack], text)
  end
  if #stack > 1 then
    error("unclosed "..stack[stack.n].name)
  end
  return stack[1]
end




-- ***** NOTES


--[[
notes :  
NOTE : ABelt etc : multi-unit. xml file with positions of subunits
WARNING MyMassConvert_OneModelFolder: unknown file ext  ABelt   /cavern/code/VegaStrike/data/units/factions/neutral/ABelt/ABelt
WARNING MyMassConvert_OneModelFolder: unknown file ext  AField  /cavern/code/VegaStrike/data/units/factions/neutral/AField/AField
WARNING MyMassConvert_OneModelFolder: unknown file ext  AFieldBase      /cavern/code/VegaStrike/data/units/factions/neutral/AFieldBase/AFieldBase
WARNING MyMassConvert_OneModelFolder: unknown file ext  AFieldBaseSparse        /cavern/code/VegaStrike/data/units/factions/neutral/AFieldBaseSparse/AFieldBaseSparse
WARNING MyMassConvert_OneModelFolder: unknown file ext  AFieldBaseThin  /cavern/code/VegaStrike/data/units/factions/neutral/AFieldBaseThin/AFieldBaseThin
WARNING MyMassConvert_OneModelFolder: unknown file ext  AFieldJump      /cavern/code/VegaStrike/data/units/factions/neutral/AFieldJump/AFieldJump
WARNING MyMassConvert_OneModelFolder: unknown file ext  AFieldJumpSparse        /cavern/code/VegaStrike/data/units/factions/neutral/AFieldJumpSparse/AFieldJumpSparse
WARNING MyMassConvert_OneModelFolder: unknown file ext  AFieldJumpThin  /cavern/code/VegaStrike/data/units/factions/neutral/AFieldJumpThin/AFieldJumpThin
WARNING MyMassConvert_OneModelFolder: unknown file ext  AFieldSparse    /cavern/code/VegaStrike/data/units/factions/neutral/AFieldSparse/AFieldSparse
WARNING MyMassConvert_OneModelFolder: unknown file ext  AFieldThin      /cavern/code/VegaStrike/data/units/factions/neutral/AFieldThin/AFieldThin
WARNING MyMassConvert_OneModelFolder: unknown file ext  HiddenAsteroid  /cavern/code/VegaStrike/data/units/factions/neutral/HiddenAsteroid/HiddenAsteroid
WARNING MyMassConvert_OneModelFolder: unknown file ext  asteroids       /cavern/code/VegaStrike/data/units/factions/neutral/asteroids/asteroids
WARNING MyMassConvert_OneModelFolder: unknown file ext  asteroids1600gap        /cavern/code/VegaStrike/data/units/factions/neutral/asteroids1600gap/asteroids1600gap
WARNING MyMassConvert_OneModelFolder: unknown file ext  asteroids200gap /cavern/code/VegaStrike/data/units/factions/neutral/asteroids200gap/asteroids200gap
WARNING MyMassConvert_OneModelFolder: unknown file ext  asteroids400gap /cavern/code/VegaStrike/data/units/factions/neutral/asteroids400gap/asteroids400gap
WARNING MyMassConvert_OneModelFolder: unknown file ext  asteroids800gap /cavern/code/VegaStrike/data/units/factions/neutral/asteroids800gap/asteroids800gap
WARNING MyMassConvert_OneModelFolder: unknown file ext  green-nebula    /cavern/code/VegaStrike/data/units/factions/neutral/green-nebula/green-nebula
WARNING MyMassConvert_OneModelFolder: unknown file ext  nebula  /cavern/code/VegaStrike/data/units/factions/neutral/green-nebula/green-nebula.nebula
WARNING MyMassConvert_OneModelFolder: unknown file ext  alp     /cavern/code/VegaStrike/data/units/factions/neutral/nebula/neb128.alp
WARNING MyMassConvert_OneModelFolder: unknown file ext  bmp     /cavern/code/VegaStrike/data/units/factions/neutral/nebula/neb128.bmp
WARNING MyMassConvert_OneModelFolder: unknown file ext  nebula  /cavern/code/VegaStrike/data/units/factions/neutral/nebula/nebula
WARNING MyMassConvert_OneModelFolder: unknown file ext  sprite  /cavern/code/VegaStrike/data/units/factions/neutral/nebula/nebula-hud.sprite
WARNING MyMassConvert_OneModelFolder: unknown file ext  nebula  /cavern/code/VegaStrike/data/units/factions/neutral/nebula/nebula.nebula
WARNING MyMassConvert_OneModelFolder: unknown file ext  sprite  /cavern/code/VegaStrike/data/units/factions/neutral/nebula_veryhuge/nebula-hud.sprite
WARNING MyMassConvert_OneModelFolder: unknown file ext  nebula_veryhuge /cavern/code/VegaStrike/data/units/factions/neutral/nebula_veryhuge/nebula_veryhuge
WARNING MyMassConvert_OneModelFolder: unknown file ext  nebula  /cavern/code/VegaStrike/data/units/factions/neutral/nebula_veryhuge/nebula_veryhuge.nebula
WARNING MyMassConvert_OneModelFolder: unknown file ext  purple-nebula   /cavern/code/VegaStrike/data/units/factions/neutral/purple-nebula/purple-nebula
WARNING MyMassConvert_OneModelFolder: unknown file ext  nebula  /cavern/code/VegaStrike/data/units/factions/neutral/purple-nebula/purple-nebula.nebula
WARNING MyMassConvert_OneModelFolder: unknown file ext  red-nebula      /cavern/code/VegaStrike/data/units/factions/neutral/red-nebula/red-nebula
WARNING MyMassConvert_OneModelFolder: unknown file ext  nebula  /cavern/code/VegaStrike/data/units/factions/neutral/red-nebula/red-nebula.nebula


WARNING MyMassConvert_OneModelFolder: unknown file ext  AsteroidFighterBase     /cavern/code/VegaStrike/data/units/factions/aera/AsteroidFighterBase/AsteroidFighterBase
WARNING MyMassConvert_OneModelFolder: unknown file ext  old     /cavern/code/VegaStrike/data/units/factions/aera/AsteroidFighterBase/asteroidfighterbase.old
WARNING MyMassConvert_OneModelFolder: unknown file ext  bmp     /cavern/code/VegaStrike/data/units/factions/aera/AsteroidFighterBase/station.bmp
WARNING MyMassConvert_OneModelFolder: unknown file ext  MiningBase      /cavern/code/VegaStrike/data/units/factions/aera/MiningBase/MiningBase
WARNING MyMassConvert_OneModelFolder: unknown file ext  old     /cavern/code/VegaStrike/data/units/factions/aera/MiningBase/miningbase.old
WARNING MyMassConvert_OneModelFolder: unknown file ext  contraband      /cavern/code/VegaStrike/data/units/factions/aera/contraband/contraband
WARNING MyMassConvert_OneModelFolder: unknown file ext  factory /cavern/code/VegaStrike/data/units/factions/aera/factory/factory
WARNING MyMassConvert_OneModelFolder: unknown file ext  old     /cavern/code/VegaStrike/data/units/factions/aera/factory/factory.old
WARNING MyMassConvert_OneModelFolder: unknown file ext  fighter_barracks        /cavern/code/VegaStrike/data/units/factions/aera/fighter_barracks/fighter_barracks
WARNING MyMassConvert_OneModelFolder: unknown file ext  old     /cavern/code/VegaStrike/data/units/factions/aera/fighter_barracks/fighter_barracks.old
WARNING MyMassConvert_OneModelFolder: unknown file ext  bmp     /cavern/code/VegaStrike/data/units/factions/aera/fighter_barracks/station.bmp

WARNING MyMassConvert_OneModelFolder: unknown file ext  MiningBase      /cavern/code/VegaStrike/data/units/factions/pirates/MiningBase/MiningBase
WARNING MyMassConvert_OneModelFolder: unknown file ext  old     /cavern/code/VegaStrike/data/units/factions/pirates/MiningBase/miningbase.old
WARNING MyMassConvert_OneModelFolder: unknown file ext  corvette        /cavern/code/VegaStrike/data/units/factions/pirates/corvette/corvette
WARNING MyMassConvert_OneModelFolder: unknown file ext  blank   /cavern/code/VegaStrike/data/units/factions/pirates/corvette/corvette.blank
WARNING MyMassConvert_OneModelFolder: unknown file ext  template        /cavern/code/VegaStrike/data/units/factions/pirates/corvette/corvette.template
WARNING : fun_TransformTexName : unknown file   >confed/corvette.png<
WARNING MyMassConvert_OneModelFolder: unknown file ext  refinery        /cavern/code/VegaStrike/data/units/factions/pirates/refinery/refinery
WARNING MyMassConvert_OneModelFolder: unknown file ext  old     /cavern/code/VegaStrike/data/units/factions/pirates/refinery/refinery.old
WARNING : fun_TransformTexName : unknown file   >metal59t.bmp<


WARNING MyMassConvert_OneModelFolder: unknown file ext  AsteroidFighterBase     /cavern/code/VegaStrike/data/units/factions/rlaan/AsteroidFighterBase/AsteroidFighterBase
WARNING MyMassConvert_OneModelFolder: unknown file ext  MiningBase      /cavern/code/VegaStrike/data/units/factions/rlaan/MiningBase/MiningBase
WARNING : fun_TransformTexName : unknown file   >Random_Metal.png<
WARNING MyMassConvert_OneModelFolder: unknown file ext  contraband      /cavern/code/VegaStrike/data/units/factions/rlaan/contraband/contraband
WARNING MyMassConvert_OneModelFolder: unknown file ext  factory /cavern/code/VegaStrike/data/units/factions/rlaan/factory/factory
WARNING MyMassConvert_OneModelFolder: unknown file ext  fighter_barracks        /cavern/code/VegaStrike/data/units/factions/rlaan/fighter_barracks/fighter_barracks
WARNING MyMassConvert_OneModelFolder: unknown file ext  medical /cavern/code/VegaStrike/data/units/factions/rlaan/medical/medical
WARNING MyMassConvert_OneModelFolder: unknown file ext  refinery        /cavern/code/VegaStrike/data/units/factions/rlaan/refinery/refinery
WARNING MyMassConvert_OneModelFolder: unknown file ext  starfortress    /cavern/code/VegaStrike/data/units/factions/rlaan/starfortress/starfortress
WARNING MyMassConvert_OneModelFolder: unknown file ext  starfortressinner       /cavern/code/VegaStrike/data/units/factions/rlaan/starfortressinner/starfortressinner
WARNING MyMassConvert_OneModelFolder: unknown file ext  starfortressouter       /cavern/code/VegaStrike/data/units/factions/rlaan/starfortressouter/starfortressouter

]]--

