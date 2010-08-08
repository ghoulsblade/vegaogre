
function GenerateBoltMesh ()
	local szMeshName = "myBoltMesh"
	local pMesh = MeshManager_createManual(szMeshName) -- 	Ogre::MeshPtr
	local msMatName = "bolttest"
	
	-- create submesh
	local sub = pMesh:createSubMesh() -- Ogre::SubMesh*
	sub:setMaterialName(msMatName)
	sub:setUseSharedVertices(false)
	
	sub:setOperationType(OT_TRIANGLE_LIST)
	
	
	
	local vb0 = cVertexBuffer:New()
	local ib = cIndexBuffer:New()
	
	local function vertex	(x,y,z,u,v)	vb0:Vertex(x,y,z,u,v) end
	local function tri		(a,b,c)		ib:MultiIndex(a,b,c) end
	-- geometry (normals ? nah..)
	local e = 1/256
	local s = 0.3
	vertex( 0, 0,-4*s,	  0*e,128*e)
	
	vertex( 0, s, 0,	200*e, 91*e)
	vertex( s, 0, 0,	200*e,128*e)
	vertex( 0,-s, 0,	200*e,160*e)
	vertex(-s, 0, 0,	200*e,128*e)
	
	vertex( 0, 0, s,	250*e,128*e)
	tri(0,1,2)
	tri(0,2,3)
	tri(0,3,4)
	tri(0,4,1)
	
	tri(5,2,1)
	tri(5,3,2)
	tri(5,4,3)
	tri(5,1,4)
	
	vb0:CheckSize()
	
	
	
	
	local vertexData = CreateVertexData()
	local indexData = CreateIndexData()
	sub:setVertexData(vertexData)
	sub:setIndexData(indexData)
	
	local vdecl = cVertexDecl:New()
	vdecl:addElement(0,VET_FLOAT3,VES_POSITION)
	--~ vdecl:addElement(0,VET_FLOAT3,VES_NORMAL)
	vdecl:addElement(0,VET_FLOAT2,VES_TEXTURE_COORDINATES)
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
	local r = 4*s
	pMesh:_setBounds({-r,-r,-r,r,r,r},false)
	pMesh:_setBoundingSphereRadius(r)
	
	vb0:Destroy()
	ib:Destroy()
	
	return szMeshName
end
