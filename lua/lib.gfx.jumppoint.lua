local kRenderQueueGroup_JumpPoint = RENDER_QUEUE_7 -- two after default

function JumpPointGfx_Init (gfx,r)
	gfx:SetMesh(CreateJumpPointMesh(r))
	gfx:GetEntity():setRenderQueueGroup(kRenderQueueGroup_JumpPoint)
	SetDiffuse("jumppointmat",0,0, 0,0,0, 1)
end

function JumpPointGfx_Step (gfx)
	gfx:SetOrientation(GetMainCam():GetRot())
end

function CreateJumpPointMeshGeometry ()
	local vb0 = cVertexBuffer:New()
	local ib = cIndexBuffer:New()
	
	local function vertex	(x,y,z,u,v,r,g,b,a)	vb0:Vertex(x,y,z,u,v,r,g,b,a) end
	local function tri		(a,b,c)		ib:MultiIndex(a,b,c) end
	
	
	local rbase0 = 0
	local rbase1 = 410
	local zlen = -200
	local sin = math.sin
	local cos = math.cos
	local pi = math.pi
	local waverep = 5
	local wavestr = 0.01
	
	local izsegs = 52 -- "down" the tunnel
	local radsegs = 51
	local vc_per_z = radsegs+1 -- (start and end have same pos but different texcoords : two vertices)
	for iz = 0,izsegs do 
		local u = iz/izsegs
		local u_inv = 1 - u
		local z = zlen * u
		local usinus = sin(u*waverep*pi*2)
		local r = u * rbase0 + u_inv * rbase1 * ( 1 + wavestr * usinus)  -- todo : * sinus?
		for iv = 0,radsegs do 
			local v = iv/radsegs
			local ang = v*pi*2
			local x,y = r*sin(ang),r*cos(ang)
			vertex(x,y,z,u,v + usinus * 0.05, 1,1,1,u)
		end
		if (iz < izsegs) then 
			local i0 = iz * vc_per_z
			local i1 = i0 + vc_per_z
			for i = 0,radsegs-1 do 
				tri(i0+i  ,i1+i+1,i1+i)
				tri(i0+i+1,i1+i+1,i0+i)
				
				tri(i0+i  ,i1+i,i1+i+1)
				tri(i0+i+1,i0+i,i1+i+1)
			end
		end
	end
	
	-- geometry (normals ? nah..)
	
	vb0:CheckSize()
	return vb0,ib,math.max(zlen,rbase0,rbase1)
end

function CreateJumpPointMesh (r,msMatName,szMeshName,...)
	msMatName = "jumppointmat"
	--~ msMatName = "basewhitenolighting"
	--~ msMatName = msMatName or "basewhitenolighting" -- "hyperspeedmat" -- 
	szMeshName = szMeshName or "myJumpPointMesh"
	local pMesh = MeshManager_createManual(szMeshName) -- 	Ogre::MeshPtr
	
	-- create submesh
	local sub = pMesh:createSubMesh() -- Ogre::SubMesh*
	sub:setMaterialName(msMatName)
	sub:setUseSharedVertices(false)
	
	sub:setOperationType(OT_TRIANGLE_LIST)
	
	local vb0,ib,r = CreateJumpPointMeshGeometry(...)
	
	local vertexData = CreateVertexData()
	local indexData = CreateIndexData()
	sub:setVertexData(vertexData)
	sub:setIndexData(indexData)
	
	local vdecl = cVertexDecl:New()
	vdecl:addElement(0,VET_FLOAT3,VES_POSITION)
	--~ vdecl:addElement(0,VET_FLOAT3,VES_NORMAL)
	vdecl:addElement(0,VET_FLOAT2,VES_TEXTURE_COORDINATES)
	vdecl:addElement(0,VET_FLOAT4,VES_DIFFUSE)
	--~  TODO : if (bUseColors)		offset += decl.addElement(0, offset, VET_COLOUR, VES_DIFFUSE).getSize()      autoorganize position!!!
	
	vertexData:setVertexDecl(vdecl:GetOgreVertexDecl())
	vertexData:createAndBindVertexBuffer(vb0:GetVertexSize(),vb0:GetVertexNum(),HBU_STATIC_WRITE_ONLY,false,0) -- (iVertexSize,iNumVerts,iUsage,bUseShadowBuffer=false,iBindIndex=0)
	indexData:createAndBindIndexBuffer(IT_32BIT,ib:GetIndexNum(),HBU_STATIC_WRITE_ONLY) -- (iIndexType,iNumIndexes,iUsage,bUseShadowBuffer=false)
	
	vertexData:setVertexStart(0)
	indexData:setIndexStart(0)
	vertexData:setVertexCount(vb0:GetVertexNum())
	indexData:setIndexCount(ib:GetIndexNum())
	
	vertexData:writeToVertexBuffer(vb0:GetFIFO(),0)
	indexData:writeToIndexBuffer(ib:GetFIFO()) 
	
	--~ calculate bounds,  todo : calc for whole mesh, not only for this submesh
	pMesh:_setBounds({-r,-r,-r,r,r,r},false)
	pMesh:_setBoundingSphereRadius(r)
	
	vb0:Destroy()
	ib:Destroy()
	
	return szMeshName
end
