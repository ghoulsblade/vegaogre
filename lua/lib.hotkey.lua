-- hotkey config (using modifiers etc)

gMacroList = {}
function ClearAllMacros () gMacroList = {} end
function SetMacro (keycomboname,fun) gMacroList[string.gsub(string.lower(keycomboname)," ","")] = fun end

RegisterListener("keydown",function (keycode,char,bConsumed) 
    if (not bConsumed) then TriggerMacros(keycode,char) end
end)

function GetMacroKeyComboName (keycode,char,bCtrl,bAlt,bShift) 
    local text = (keycode > 0) and GetKeyName(keycode) or ("0"..char)
    if (bCtrl   ) then text = "ctrl+"..text end
    if (bAlt    ) then text = "alt+"..text end
    if (bShift  ) then text = "shift+"..text end
    return text
end

function TriggerMacros (keycode,char) 
    local bCtrl     = gKeyPressed[key_lcontrol] or gKeyPressed[key_rcontrol]
    local bAlt      = gKeyPressed[key_lalt]     or gKeyPressed[key_ralt]    
    local bShift    = gKeyPressed[key_lshift]   or gKeyPressed[key_rshift]
    local name = GetMacroKeyComboName(keycode,char,bCtrl,bAlt,bShift)
	--~ if (TriggerConfigHotkey(keycode,char,bCtrl,bAlt,bShift)) then return end
    local macrofun = gMacroList[name]
    if (gMacroPrintAllKeyCombos) then print('to use this macro keycombo : SetMacro("'..name..'",function() MacroCmd_Say("test") end)') end
    if (not macrofun) then return end -- no macro mapped to this keycode
    
    -- protected macro call
    local success,errormsg_or_result = lugrepcall(function () job.create(macrofun) end)
    if (not success) then
        local myErrorText = "ERROR executing MACRO for keycombo "..name.." :\n"..tostring(errormsg_or_result)
        print(myErrorText)
        PlainMessageBox(myErrorText,gGuiDefaultStyleSet,gGuiDefaultStyleSet)
    end
end
