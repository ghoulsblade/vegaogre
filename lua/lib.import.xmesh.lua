-- import xmesh (vegastrike xml mesh format) to ogre (allows saving/exporting as ogre.mesh)
--~ BFXM spec (old) : http://vegastrike.svn.sourceforge.net/viewvc/vegastrike/trunk/vegastrike/objconv/mesher/BFXM%20specification.txt?revision=7726&view=markup
--~ XMESH spec (old) : http://vegastrike.svn.sourceforge.net/viewvc/vegastrike/trunk/vegastrike/objconv/xmlspec?revision=594&view=markup


RegisterListener("Hook_CommandLine",function ()
	local bSuccess,sError = lugrepcall(function () -- protected call, print error
		local path = gCommandLineSwitchArgs["-xmesh"]
		if path then MyXMeshConvertInitOgre() ConvertXMesh(path,gCommandLineSwitchArgs["-out"]) os.exit(0) end
	end)
	
	if gCommandLineSwitches["-xmeshtest"] then 
		MyXMeshConvertInitOgre() 
		local meshname,boundrad = ConvertXMesh("/cavern/code/VegaStrike/meshertest/xmesh_plowshare/plowshare_prime.xmesh") 
		--~ local meshname = "Plowshare.mesh"
		TableCamViewMeshLoop(meshname,boundrad)
		os.exit(0) 
	end
	if (not bSuccess) then print("import.xmesh error : ",sError) os.exit(0) end
end)



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
	local e = .3	local r,g,b = e,e,e		Client_SetAmbientLight(r,g,b, 1)

	local gfx = CreateRootGfx3D() 
	--~ EnsureMeshMaterialNamePrefix("llama.mesh","llama")
	gfx:SetMesh(meshname)
	--~ gfx:SetMesh("axes.mesh")
	--~ gfx:SetMesh("llama.mesh")
	
	local camdist = boundrad and (boundrad*2) or 10
	BindDown("escape", 		function () os.exit(0) end)
    BindDown("wheeldown",   function () camdist = camdist / 0.5 print("camdist",camdist) end)
    BindDown("wheelup",     function () camdist = camdist * 0.5 print("camdist",camdist) end)

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



function ConvertXMesh (inpath,outpath)
	local sModelName = "Plowshare"
	--~ local sOutPath = "../data/units/vessels/"..sModelName.."/subtest/"
	local sOutPath = "../data/units/vessels/"..sModelName.."/"
	local sOgreNameSuffix = sModelName.."01"
	local bAssumeTextureDDS = true
	
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
	local bDebug = true
	
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
				assert((not sub.s) or (tonumber(sub.s) == 0),"debug-assert : non-zero value for unknown Point.Location attribute s")
				assert((not sub.t) or (tonumber(sub.t) == 0),"debug-assert : non-zero value for unknown Point.Location attribute t")
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
		assert(xml_poly._name == "Tri")
		assert(#xml_poly == 3,"expected 3 vertices! "..#xml_poly)
		if (xml_poly.flatshade ~= "0") then print("warning: Tri.flatshade not supported") end
		if (xml_poly.flatshade ~= "0") then assert(false,"debug-assert: Tri.flatshade not supported") end
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
	end
	
	-- names
	local szMeshName = "myXMeshConvertMesh"..sOgreNameSuffix
	local msMatName = "myXMeshConvertMat"..sOgreNameSuffix
	
	
	-- create material
	if (bDebug) then print("creating material...") end
	local tex_prefix = sModelName.."_"
	local function TransformTexName (s)
		local sOld = s
		if (bAssumeTextureDDS) then  -- vegastrike texture filenames/extensions are wrong, assume dds format for .png files, as ogre cannot handle the error
			s = string.gsub(s,"%..*$",".dds") -- replace file ending by .dds
		end
		local res = tex_prefix..s 
		print("TransformTexName",sOld,res)
		if (1 == 1) then
			--~ local imgpath = string.gsub(inpath,"[^/]+$","")..sOld
			local imgpath = res
			--~ local folder = inpath
			print("attempting to load image",imgpath)
			local img = CreateOgreImage() 
			local bSuccess,sErrMsg = img:load(imgpath)
			if (not bSuccess) then print("Warning! error loading image:",imgpath,sErrMsg) else print("load image ok") end
			if (not bSuccess) then assert(false,"Warning! error loading image:",imgpath,sErrMsg) end -- debug exit
		end
		return res 
	end
	assert(MaterialManager_create,"recompile executable file, code was added 28.01.2011 and only compiled on linux at the time")
	local pMat	= MaterialManager_create(msMatName) assert(pMat)
	--~ local pTec	= pMat:createTechnique() assert(pTec)
	--~ local pPas	= pTec:createPass() assert(pPas)
	--~ local pTex	= pPas:createTextureUnitState() assert(pTex)
	local pTec	= pMat:getTechnique(0) assert(pTec)
	local pPas	= pTec:getPass(0) assert(pPas)
	local pTex	= pPas:createTextureUnitState() assert(pTex)
	assert(pMat:getName() == msMatName)
	--~ assert(pMat:load())
	--~ MaterialManager_load(msMatName)
	
	-- apply global properties
	pTex:setTextureName(TransformTexName(xml_mesh.texture or ""),TEX_TYPE_2D)
	local s = tonumber(xml_mat.power) if (s) then pMat:setShininess(s) end
	-- TODO : <Mesh  scale="1.0" reverse="0" forcetexture="0" sharevert="0" polygonoffset="0.0" blend="ONE ZERO" alphatest="0.0" texture="wayfarer.png"  texture1="wayfarerPPL.jpg" >
	-- TODO : <Material power="60.000000" cullface="1" reflect="1" lighting="1" usenormals="1">
	local eattr_mesh = {scale=true,reverse=true,forcetexture=true,sharevert=true,polygonoffset=true,blend=true,alphatest=true,texture=true,texture1=true}
	local eattr_mat = {power=true,cullface=true,reflect=true,lighting=true,usenormals=true}
	MyAttrCheck(xml_mesh._attr,eattr_mesh,"Mesh")
	MyAttrCheck(xml_mat._attr,eattr_mat,"Material")
	print("TODO : Mesh : reverse,forcetexture,sharevert,polygonoffset,blend,alphatest, texture1")
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
	local sMaterialOutPath = sOutPath..sModelName..".material"
	assert(pMat:MaterialSerializer_Export(sMaterialOutPath,bExportDefaults))
	print("MaterialSerializer_Export ok")
	
	
	-- create mesh
	if (bDebug) then print("creating mesh...") end
	vb:CheckSize()
	local pMesh = MeshManager_createManual(szMeshName) -- Ogre::MeshPtr
	
	-- create submesh
	local sub = pMesh:createSubMesh() -- Ogre::SubMesh*
	sub:setMaterialName(msMatName)
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
	
	-- bounds : todo : calc for whole mesh, not only for this submesh
	pMesh:_setBounds({minx,miny,minz,maxx,maxy,maxz},false)
	local boundrad = max(abs(minx),abs(miny),abs(minz),abs(maxx),abs(maxy),abs(maxz))
	pMesh:_setBoundingSphereRadius(boundrad)
	
	vb:Destroy()
	ib:Destroy()
	
	local sFileName = sOutPath..sModelName..".mesh"
	ExportMesh(szMeshName,sFileName)
	
	print("Material Test load ...",sMaterialOutPath)
	assert(pMat:load())
	--~ print("Material Test load test 2",msMatName) -- had segfault later when trying to load dds with .png as filename
	--~ local clone_name,errmsg = CloneMaterial(msMatName)
	--~ assert(clone_name,errmsg)
	print("Material Test load ok")
	
	if (bDebug) then print("xmesh convert finished.") end
	
	return szMeshName,boundrad
end
