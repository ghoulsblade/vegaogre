
function InitGuiThemes ()
	gVegaWidgetFont = CreateFont_Ogre("TrebuchetMSBold",14)
	
	local bordermatrix_32_widemid	= MakeSpritePanelParam_BorderPartMatrix(GetPlainTextureGUIMat("window.png"),32,32,0,0, 0,0, 12,8,12, 12,8,12, 32,32, 1,1, false,false)
	local bordermatrix_32_tinymid	= MakeSpritePanelParam_BorderPartMatrix(GetPlainTextureGUIMat("window.png"),32,32,0,0, 0,0, 14,4,14, 14,4,14, 32,32, 1,1, false,false)
	local bordermatrix_16			= MakeSpritePanelParam_BorderPartMatrix(GetPlainTextureGUIMat("window.png"),16,16,0,0, 0,0, 6,4,6, 6,4,6, 16,16, 1,1, false,false)
	
	GuiThemeSetDefaultParam("Window",{	gfxparam_init 		= bordermatrix_32_tinymid, })
	
	
	
	local matrix_button_small	= MakeSpritePanelParam_BorderPartMatrix(GetPlainTextureGUIMat("button_small.png"),16,16,0,0, 0,0, 6,4,6, 6,4,6, 32,32, 1,1, false,false)
	GuiThemeSetDefaultParam("Text",{	font=gVegaWidgetFont,fontsize=14, textparam={r=0,g=0,b=0} })
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
end

function GuiTest_DragDrop ()
	InitGuiThemes()
	--~ local widget = CreateWidgetFromXMLString(GetDesktopWidget(),"<Window x=100 y=100 w=300 h=200> <Button x=10 y=10 label='testbutton' /> </Window>")	
	--~ GetDesktopWidget():CreateContentChild("Button",{x=10, y=10, label='testbutton'})
	
	local w1 = CreateWidgetFromXMLString(GetDesktopWidget(),[[<Window x=100 y=100 w=320 h=400> <Text x=10 y=0 text='Inventory' /> </Window>]])
	local w2 = CreateWidgetFromXMLString(GetDesktopWidget(),[[<Window x=600 y=100 w=320 h=400> <Text x=10 y=0 text='Ship' /> </Window>]])
	
	local i = 0
	for img,n in pairs({
		["am_magcells.image.png"					]=3,
		["atmospheric_scrubbers.image.png"			]=2,
		["automated_factories.image.png"			]=1,
		["baakgah.image.png"						]=1,
		["biogenerators.image.png"					]=1,
		["bio_remodeler.image.png"					]=2,
		["cargo-hud.image.png"						]=1,
		["cloaking_device_aeramilspec.image.png"	]=1,
		["explosives.image.png"						]=4,
		["krystal.image.png"						]=1,
		["laser_drills.image.png"					]=5,
		["pai_wetware.image.png"					]=1,
		["repair_droid01.image.png"					]=1,
		["repulsor_beam.image.png"					]=2,
		["tractor_beam.image.png"					]=2,
		["waste_recyclers.image.png"				]=1,}) do 
		for k=1,n do 
			local tooltip = string.gsub(img,"%.png$","").."\n5 SomeValue\n7 SomeOtherValue\nMedPowerSlot"
			w1:CreateContentChild("ItemIcon",{x=5+(i%6)*50, y=40+math.floor(i/6)*50, image=img, tooltip=tooltip })
			i = i + 1
		end
	end
	
	local ox,ex = 5,50
	local oy,ey = 40,50
	local fixslots1 = {"spec","jump","sensors","overdrive"}
	local fixslots2 = {"reactor","armor","shield","capacitor",}
	for i=1,6 do					w2:CreateContentChild("EquipSlot",{x=ox+0*ex, y=oy+(i-1)*ey, type=(i<=4) and "weapon_light" or "weapon_light_missile" }) end
	for i=1,7 do					w2:CreateContentChild("EquipSlot",{x=ox+1*ex, y=oy+(i-1)*ey, type="equip"}) end
	for i,v in ipairs(fixslots1) do	w2:CreateContentChild("EquipSlot",{x=ox+2*ex, y=oy+(i-1)*ey, type=v}) end
	for i,v in ipairs(fixslots2) do	w2:CreateContentChild("EquipSlot",{x=ox+3*ex, y=oy+(i-1)*ey, type=v}) end
	
end
