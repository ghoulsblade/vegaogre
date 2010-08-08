floor	= math.floor
ceil	= math.ceil
min		= math.min
max		= math.max

function InitGuiThemes ()
	gVegaWidgetFont = CreateFont_Ogre("TrebuchetMSBold",14)
	
	GuiThemeSetDefaultParam("Text",{	font=gVegaWidgetFont,fontsize=14, textparam={r=0,g=0,b=0} })

	
	local bordermatrix_32_widemid	= MakeSpritePanelParam_BorderPartMatrix(GetPlainTextureGUIMat("window.png"),32,32,0,0, 0,0, 12,8,12, 12,8,12, 32,32, 1,1, false,false)
	local bordermatrix_32_tinymid	= MakeSpritePanelParam_BorderPartMatrix(GetPlainTextureGUIMat("window.png"),32,32,0,0, 0,0, 14,4,14, 14,4,14, 32,32, 1,1, false,false)
	local bordermatrix_16			= MakeSpritePanelParam_BorderPartMatrix(GetPlainTextureGUIMat("window.png"),16,16,0,0, 0,0, 6,4,6, 6,4,6, 16,16, 1,1, false,false)
	
	GuiThemeSetDefaultParam("Window",{	gfxparam_init 		= bordermatrix_32_tinymid, })
	
	
	local matrix_button_small	= MakeSpritePanelParam_BorderPartMatrix(GetPlainTextureGUIMat("button_small.png"),16,16,0,0, 0,0, 6,4,6, 6,4,6, 32,32, 1,1, false,false)
	GuiThemeSetDefaultParam("Button",{	gfxparam_init 		= matrix_button_small,
										gfxparam_in_down	= MakeSpritePanelParam_Mod_TexTransform(0.0,0.5,1,1,0),
										gfxparam_in_up		= MakeSpritePanelParam_Mod_TexTransform(0.5,0.0,1,1,0),
										gfxparam_out_down	= MakeSpritePanelParam_Mod_TexTransform(0.0,0.0,1,1,0),
										gfxparam_out_up		= MakeSpritePanelParam_Mod_TexTransform(0.0,0.0,1,1,0),
										margin_left= 3,
										margin_top= 3,
										margin_right= 3,
										margin_bottom= 1,
										font=gVegaWidgetFont,
										textcol={r=0,g=0,b=0},
									})
	
	
	
	local spritebutton_4x4_mods		= {	gfxparam_in_down	= MakeSpritePanelParam_Mod_TexTransform(0.0,0.5,1,1,0),
										gfxparam_in_up		= MakeSpritePanelParam_Mod_TexTransform(0.5,0.0,1,1,0),
										gfxparam_out_down	= MakeSpritePanelParam_Mod_TexTransform(0.0,0.0,1,1,0),
										gfxparam_out_up		= MakeSpritePanelParam_Mod_TexTransform(0.0,0.0,1,1,0),
										margin_left= 0,
										margin_top= 0,
										margin_right= 0,
										margin_bottom= 0,
									}

	GuiThemeSetDefaultParam("ScrollPaneV",{
		img_init_bar	= MakeSpritePanelParam_BorderPartMatrix(GetPlainTextureGUIMat("plainborder.png")		,8,8,0,0, 0,0, 3,2,3, 3,2,3, 8,8, 1,1, false,false),
		img_init_frame	= MakeSpritePanelParam_BorderPartMatrix(GetPlainTextureGUIMat("plainborder2.png")		,8,8,0,0, 0,0, 3,2,3, 3,2,3, 8,8, 1,1, false,false),
		param_btn_thumb	= tablemod({gfxparam_init = MakeSpritePanelParam_BorderPartMatrix(GetPlainTextureGUIMat("button_small_thumb.png")	,16,16,0,0, 0,0, 6,4,6, 6,4,6, 32,32, 1,1, false,false)},spritebutton_4x4_mods),
		param_btn_up	= tablemod({gfxparam_init = MakeSpritePanelParam_SingleSprite(GetPlainTextureGUIMat("button_small_up.png")			,16,16,0,0, 0,0, 16,16, 32,32)},spritebutton_4x4_mods),
		param_btn_down	= tablemod({gfxparam_init = MakeSpritePanelParam_SingleSprite(GetPlainTextureGUIMat("button_small_down.png")		,16,16,0,0, 0,0, 16,16, 32,32)},spritebutton_4x4_mods),
	})
	
end




function GuiTest_InitCrossHair ()
		--~ local w,h = 128,128
		--~ local x,y = gViewportW/2-w/2,gViewportH/2-h/2
		--~ gCrossHair = GetDesktopWidget():CreateContentChild("Image",{gfxparam_init=MakeSpritePanelParam_SingleSpriteSimple(GetPlainTextureGUIMat("crosshair01.png"),w,h)})
		--~ gCrossHair:SetPos(x,y)
end

RegisterListener("Hook_HUDStep",function () GuiTest_Step() end)

function GuiTest_Step ()
	if (gGuiTest_DragDrop_Active) then return end
	local mx,my = GetMousePos()
	local cx,cy = gViewportW/2,gViewportH/2
	local w,h = 32,32
	if (not gMouseCross) then 
		gMouseCross = GetDesktopWidget():CreateContentChild("Image",{gfxparam_init=MakeSpritePanelParam_SingleSpriteSimple(GetPlainTextureGUIMat("objmark_vorhalt.png"),w,h)})
	end
	gMouseCross:SetPos(mx-w/2,my-h/2)
	local dx,dy = (mx-cx)/cx,(my-cy)/cy
	local cam = GetMainCam()
	
	local roth = -math.pi * .5 * dx * gSecondsSinceLastFrame
	local rotv = -math.pi * .5 * dy * gSecondsSinceLastFrame
	
	local w0,x0,y0,z0 = cam:GetRot()	
	local w1,x1,y1,z1 = Quaternion.fromAngleAxis(roth,0,1,0)	w0,x0,y0,z0 = Quaternion.Mul(w0,x0,y0,z0, w1,x1,y1,z1)	
	local w1,x1,y1,z1 = Quaternion.fromAngleAxis(rotv,1,0,0)	w0,x0,y0,z0 = Quaternion.Mul(w0,x0,y0,z0, w1,x1,y1,z1)	
	--~ local w1,x1,y1,z1 = Quaternion.fromAngleAxis(rotv,1,0,0)	w0,x0,y0,z0 = Quaternion.Mul(w0,x0,y0,z0, w1,x1,y1,z1)
	cam:SetRot(Quaternion.normalise(w0,x0,y0,z0))
end

function GuiTest_DragDrop ()
	gGuiTest_DragDrop_Active = not gGuiTest_DragDrop_Active
	if (gGuiTest_DragDrop_Active) then 
		if (gCrossHair) then gCrossHair:Destroy() gCrossHair = nil end
		local s = min(gViewportW,gViewportH) s = 1024
		local w,h = s,s
		gBaseBackground = GetDesktopWidget():CreateContentChild("Image",{gfxparam_init=MakeSpritePanelParam_SingleSpriteSimple(GetTexturedMat("background_base","ocean_concourse.dds"),w,h)})
		--~ gBaseBackground = GetDesktopWidget():CreateContentChild("Image",{gfxparam_init=MakeSpritePanelParam_SingleSpriteSimple(GetTexturedMat("guibasemat","military_concourse.dds"),w,h)})
		gBaseBackground:SetPos(gViewportW/2-w/2,gViewportH/2-h/2)

		InitGuiThemes()
		--~ local widget = CreateWidgetFromXMLString(GetDesktopWidget(),"<Window x=100 y=100 w=300 h=200> <Button x=10 y=10 label='testbutton' /> </Window>")	
		--~ GetDesktopWidget():CreateContentChild("Button",{x=10, y=10, label='testbutton'})
		
		local w1 = CreateWidgetFromXMLString(GetDesktopWidget(),[[<Window x=100 y=100 w=325 h=380> <Text x=10 y=0 text='Inventory' /> </Window>]])
		local w2 = CreateWidgetFromXMLString(GetDesktopWidget(),[[<Window x=600 y=100 w=325 h=380> <Text x=10 y=0 text='Ship' /> </Window>]])
		
		local e = 50
		local s = w1:CreateContentChild("ScrollPaneV",{x=4,y=40,w=(325-8),h=(380-50)})
		local g = s:CreateContentChild("ItemGrid",{x=2,y=2,w=floor((325-4-16)/e)*e,h=floor((380-50)/e)*e})
		gMyWindow1 = w1
		gMyWindow2 = w2

		local i = 0
		local function ninc (t,addmax) for k,v in pairs(t) do t[k] = v + math.random(0,addmax) end return t end
		for img,n in pairs(ninc({
			["am_magcells.image.png"					]=3,
			["atmospheric_scrubbers.image.png"			]=2,
			["automated_factories.image.png"			]=1,
			["baakgah.image.png"						]=1,
			["biogenerators.image.png"					]=1,
			["bio_remodeler.image.png"					]=2,
			["cargo-hud.image.png"						]=1,
			["cloaking_device_aeramilspec.image.png"	]=1,
			["explosives.image.png"						]=1,
			["krystal.image.png"						]=1,
			["laser_drills.image.png"					]=4,
			["pai_wetware.image.png"					]=1,
			["repair_droid01.image.png"					]=1,
			["repulsor_beam.image.png"					]=2,
			["tractor_beam.image.png"					]=2,
			["waste_recyclers.image.png"				]=1,},6)) do 
			for k=1,n do 
				local tooltip = string.gsub(img,"%.png$","").."\n5 SomeValue\n7 SomeOtherValue\nMedPowerSlot"
				g:CreateContentChild("ItemIcon",{x=(i%6)*50, y=math.floor(i/6)*50, image=img, tooltip=tooltip })
				i = i + 1
			end
		end
		
		local ox,ex = 5,50
		local oy,ey = 40,50
		local fixslots1 = {"spec","jump","sensors","overdrive"}
		local fixslots2 = {"reactor","armor","shield","capacitor",}
		for i=1,6 do					w2:CreateContentChild("EquipSlot",{x=ox+0*ex, y=oy+(i-1)*ey, type=(i<=4) and "weapon_light" or "weapon_light_missile" }) end
		for i=1,6 do					w2:CreateContentChild("EquipSlot",{x=ox+1*ex, y=oy+(i-1)*ey, type="equip"}) end
		for i,v in ipairs(fixslots1) do	w2:CreateContentChild("EquipSlot",{x=ox+2*ex, y=oy+(i-1)*ey, type=v}) end
		for i,v in ipairs(fixslots2) do	w2:CreateContentChild("EquipSlot",{x=ox+3*ex, y=oy+(i-1)*ey, type=v}) end
	else 
		gMyWindow1:Destroy()
		gMyWindow2:Destroy()
		if (gBaseBackground) then gBaseBackground:Destroy() gBaseBackground = nil end
		GuiTest_InitCrossHair()
	end
end
