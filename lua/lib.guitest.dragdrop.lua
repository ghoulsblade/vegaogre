
function GuiTest_DragDrop ()
	print("GuiTest_DragDrop")
	local bordermatrix_32_widemid	= MakeSpritePanelParam_BorderPartMatrix(GetPlainTextureGUIMat("window.png"),32,32,0,0, 0,0, 12,8,12, 12,8,12, 32,32, 1,1, false,false)
	local bordermatrix_32_tinymid	= MakeSpritePanelParam_BorderPartMatrix(GetPlainTextureGUIMat("window.png"),32,32,0,0, 0,0, 14,4,14, 14,4,14, 32,32, 1,1, false,false)
	local bordermatrix_16			= MakeSpritePanelParam_BorderPartMatrix(GetPlainTextureGUIMat("window.png"),16,16,0,0, 0,0, 6,4,6, 6,4,6, 16,16, 1,1, false,false)
	
	local m_window = bordermatrix_32_tinymid
	
	--~ local params = {
		--~ gfxparam_init		= bordermatrix		
		--~ margin_left			= 12,
		--~ margin_top			= 12,
		--~ margin_right		= 12,
		--~ margin_bottom		= 12,
	--~ }

	--~ local d = GetDesktopWidget():CreateChild("Border",params)
	
	--~ local w = d:CreateContentChild("Border",params)
	--~ w:SetLeftTop(0,0)
	--~ w:SetSize(100,100)

	
	
	--~ local widget = CreateWidgetFromXMLString(GetDesktopWidget(),"<UOText x=20 y=20 text='abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890' />")
	--~ local widget = CreateWidgetFromXMLString(GetDesktopWidget(),"<UOButton x=20 y=50 gump_id_normal=2015 gump_id_pressed=2016 />")
	
	--~ local texname,w,h,xoff,yoff = kGUITest_BorderTestTex,80,80,0,0
	--~ local u0,v0,w0,w1,w2,h0,h1,h2, tcx,tcy = 0,0, 4,8,4, 4,8,4, 32,32
	
	GuiThemeSetDefaultParam("Button",{	gfxparam_init 		= MakeSpritePanelParam_BorderPartMatrix(GetPlainTextureGUIMat("button_small.png"),16,16,0,0, 0,0, 6,4,6, 6,4,6, 32,32, 1,1, false,false),
										gfxparam_in_down	= MakeSpritePanelParam_Mod_TexTransform(0.0,0.5,1,1,0),
										gfxparam_in_up		= MakeSpritePanelParam_Mod_TexTransform(0.5,0.0,1,1,0),
										gfxparam_out_down	= MakeSpritePanelParam_Mod_TexTransform(0.0,0.0,1,1,0),
										gfxparam_out_up		= MakeSpritePanelParam_Mod_TexTransform(0.0,0.0,1,1,0),
										margin_left= 3,
										margin_top= 3,
										margin_right= 3,
										margin_bottom= 1,
										font=CreateFont_Ogre("TrebuchetMSBold",14),
										textcol={r=0,g=0,b=0},
									})
	
	GuiThemeSetDefaultParam("Window",{	gfxparam_init 		= m_window,
									})
								
	local widget = CreateWidgetFromXMLString(GetDesktopWidget(),"<Window x=100 y=100 w=300 h=200>"..
																"<Button x=10 y=10 label='testbutton' />"..
																"</Window>")	
	
	
	
	
	--~ local widget = CreateWidgetFromXMLString(GetDesktopWidget(),"<Button x=110 y=20 label='ghouly on the run!' />")
	
	
	--~ local widget = CreateWidgetFromXMLString(GetDesktopWidget(),"<UOButton x=20 y=50 gump_id_normal=2015 gump_id_pressed=2016>"..
																--~ "<UOText x=10 y=5 text='hello world !!!11eins!elf!' /></UOButton>")
end
