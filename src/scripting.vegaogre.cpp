#include "lugre_prefix.h"
#include <assert.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include "lugre_ogrewrapper.h"
#include "lugre_scripting.h"
#include "lugre_luabind.h"

#include "lugre_sound.h"
#include "lugre_image.h"

using namespace Lugre;

void	printdebug	(const char *szCategory, const char *szFormat, ...) { PROFILE
	va_list ap;
	va_start(ap,szFormat);
	gRobStringBuffer[0] = 0;
	vsnprintf(gRobStringBuffer,kRobStringBufferSize-1,szFormat,ap);
	cScripting::GetSingletonPtr()->LuaCall("printdebug","ss",szCategory,gRobStringBuffer);
	va_end(ap);
}

void	VegaOgre_RegisterLuaPlugin	() {
	
	class cVegaOgre_ScriptingPlugin : public cScriptingPlugin { public:
		void	RegisterLua_GlobalFunctions	(lua_State*	L) {
			//~ lua_register(L,"SomeCoolFunction",			l_SomeCoolFunction);
		}
		
		void	RegisterLua_Classes			(lua_State*	L) {
			LuaRegisterData(L);
			LuaRegisterBuilder(L);
			cSpriteManager::LuaRegister(L);
			cManualArtMaterialLoader::LuaRegister(L);
			cSprite::LuaRegister(L);
		}
	};
	
	cScripting::RegisterPlugin(new cVegaOgre_ScriptingPlugin());
}
