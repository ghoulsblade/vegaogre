#include "lugre_prefix.h"
#include "lugre_luaxml.h"
#include "tinyxml.h"
#include <string>

/*
WARNING! tinyxml fails to load this xml (no childs generated)
<Mesh aaa="" aaa="xxx">
<Material>
</Material>
</Mesh>
*/

namespace Lugre {

/*
lua array manipulation from c :

lua_rawseti
          void lua_rawseti (lua_State *L, int index, int n);
Does the equivalent of t[n] = v, where t is the value at the given valid index index and v is the value at the top of the stack,
This function pops the value from the stack. The assignment is raw; that is, it does not invoke metamethods. 

lua_setfield
          void lua_setfield (lua_State *L, int index, const char *k);
Does the equivalent to t[k] = v, where t is the value at the given valid index index and v is the value at the top of the stack,
This function pops the value from the stack. As in Lua, this function may trigger a metamethod for the "newindex" event (see 2.8). 

lua_settable
          void lua_settable (lua_State *L, int index);
Does the equivalent to t[k] = v, where t is the value at the given valid index index, v is the value at the top of the stack, 
and k is the value just below the top.
This function pops both the key and the value from the stack. As in Lua, 
this function may trigger a metamethod for the "newindex" event (see 2.8). 

lua_rawset
          void lua_rawset (lua_State *L, int index);
Similar to lua_settable, but does a raw assignment (i.e., without metamethods). 

lua_pushstring
          void lua_pushstring (lua_State *L, const char *s);

lua_createtable
          void lua_createtable (lua_State *L, int narr, int nrec);
Creates a new empty table and pushes it onto the stack. The new table has space pre-allocated 
for narr array elements and nrec non-array elements. 
This pre-allocation is useful when you know exactly how many elements the table will have. 
Otherwise you can use the function lua_newtable. 

*/


extern "C" {
	#include "lua.h"
	#include "lauxlib.h"
	#include "lualib.h"
}

/** Produces an XMLTree like :    
<paragraph justify='centered'>first child<b>bold</b>another child</paragraph> 

{name="paragraph", attr={justify="centered"}, 
  "first child",
  {name="b", "bold", n=1}
  "another child",
  n=3
} 

LuaXML_SaveFile("bla.xml",LuaXML_ParseFile(filepath)[1])

for k,child in ipairs(node) do .. end  -- iterate over all childs
node[1]   -- first child
node.attr.bla  -- attribute access

comments and other definitions are ignored
*/
void LuaXML_FillNode (lua_State *L,int iTableIndex,TiXmlNode* pParent) { PROFILE
	// resize stack if neccessary
	luaL_checkstack(L, 5, "LuaXML_ParseNode : recursion too deep");
	if (!lua_istable(L,iTableIndex)) { printf("LuaXML_FillNode : no table\n"); return; }
	
	/*
		TiXmlDocument doc;
	TiXmlDeclaration * decl = new TiXmlDeclaration( "1.0", "", "" );
	TiXmlElement * element = new TiXmlElement( "Hello" );
	TiXmlText * text = new TiXmlText( "World" );
	element->LinkEndChild( text );
	doc.LinkEndChild( decl );
	doc.LinkEndChild( element );
	doc.SaveFile( "madeByHand.xml" );

	*/
	
	// name
	lua_getfield(L,iTableIndex,"name");		// afterwards : stack has 1 value = t[k] = iTableIndex["name"]
	//~ printf("LuaXML_FillNode:got name (pushed)\n");
	std::string sName = lua_tostring(L,-1);
	//~ printf("LuaXML_FillNode:name=%s\n",sName.c_str());
	lua_pop(L,1); // pop 1 elements		// afterwards stack is empty
	
	TiXmlElement* pElem = new TiXmlElement(sName.c_str());
	
	// attr
	lua_getfield(L,iTableIndex,"attr");		// afterwards : stack has 1 value = t[k] = iTableIndex["attr"]
	//~ printf("LuaXML_FillNode:attr 1\n");
	if (lua_istable(L,-1)) { // iterate over attributes
		lua_pushnil(L);  // first key		// afterwards : stack has 2 values iTableIndex["attr"],nil
		while (lua_next(L,-2) != 0) { // table is at stack idx -1		pops key and pushes key-value-pair -> stack is 3 value : iTableIndex["attr"],newk,newv
			       //~ printf("%s - %s\n",
              //~ lua_typename(L, lua_type(L, -2)),
              //~ lua_typename(L, lua_type(L, -1)));

			std::string sAttrName	= lua_tostring(L,-2);
			//~ printf("attr:name=%s\n",sAttrName.c_str());
			std::string sAttrValue	= lua_tostring(L,-1);
			//~ printf("attr:value=%s\n",sAttrValue.c_str());
			pElem->SetAttribute(sAttrName.c_str(),sAttrValue.c_str());
			lua_pop(L, 1); // removes 'value'; keeps 'key' for next iteration  // 
		} // if next returns 0 : it popped the key and pushes nothing.   ->  stack has 1 value: iTableIndex["attr"]  
	}
	//~ printf("LuaXML_FillNode:attr 2\n");
	lua_pop(L,1); // pop 1 elements		-> stack is empty now
	
	
	// n
	lua_getfield(L,iTableIndex,"n");	// stack has 1 value : iTableIndex["n"]
	int n = (int)lua_tonumber(L,-1);
	//~ printf("LuaXML_FillNode:n=%d\n",n);
	lua_pop(L,1); // pop 1 elements		stack is empty now
	
	// childs
	for (int i=1;i<=n;++i) {
		lua_rawgeti(L,iTableIndex,i); // table is at index 1			stack has 1 value : iTableIndex[i]
		//~ printf("LuaXML_FillNode:child1 %d %s\n",i,lua_typename(L, lua_type(L, -1))); 

		if (lua_isstring(L,-1)) {
			//~ printf(" LuaXML_FillNode:txt1\n");
			std::string sText = lua_tostring(L,-1);
			//~ printf(" LuaXML_FillNode:txt2 %s\n",sText.c_str());
			pElem->LinkEndChild( new TiXmlText( sText.c_str() ) );
		}
		if (lua_istable(L,-1)) {
			//~ printf(" LuaXML_FillNode:childnode1\n");
			LuaXML_FillNode(L,-1,pElem);
			//~ printf(" LuaXML_FillNode:childnode2\n");
		}
		//~ printf("LuaXML_FillNode:child2\n");
		lua_pop(L,1); // pop 1 elements		stack is empty
	}
	
	pParent->LinkEndChild( pElem );
	// stack is empty
}

void LuaXML_ParseNode (lua_State *L,TiXmlNode* pNode) { PROFILE
	if (!pNode) return;
	// resize stack if neccessary
	luaL_checkstack(L, 5, "LuaXML_ParseNode : recursion too deep");
	
	TiXmlElement* pElem = pNode->ToElement();
	if (pElem) {
		// element name
		lua_pushstring(L,"name");
		lua_pushstring(L,pElem->Value());
		lua_settable(L,-3);
		//lua_setfield(L,-2,"name");
		
		// parse attributes
		TiXmlAttribute* pAttr = pElem->FirstAttribute();
		if (pAttr) {
			lua_pushstring(L,"attr");
			lua_newtable(L);
			for (;pAttr;pAttr = pAttr->Next()) {
				lua_pushstring(L,pAttr->Name());
				lua_pushstring(L,pAttr->Value());
				//lua_setfield(L,-2,pAttr->Name());
				lua_settable(L,-3);
				
			}
			//lua_setfield(L,-2,"attr");
			lua_settable(L,-3);
		}
	}
	
	// children
	TiXmlNode *pChild = pNode->FirstChild();
	if (pChild) {
		int iChildCount = 0;
		for(;pChild;pChild = pChild->NextSibling()) {
			switch (pChild->Type()) {
				case TiXmlNode::TINYXML_DOCUMENT: break;
				case TiXmlNode::TINYXML_ELEMENT: 
					// normal element, parse recursive
					lua_newtable(L);
					LuaXML_ParseNode(L,pChild);
					lua_rawseti(L,-2,++iChildCount);
				break;
				case TiXmlNode::TINYXML_COMMENT: break;
				case TiXmlNode::TINYXML_TEXT: 
					// plaintext, push raw
					lua_pushstring(L,pChild->Value());
					lua_rawseti(L,-2,++iChildCount);
				break;
				case TiXmlNode::TINYXML_DECLARATION: break;
				case TiXmlNode::TINYXML_UNKNOWN: break;
			};
		}
		lua_pushstring(L,"n");
		lua_pushnumber(L,iChildCount);
		//lua_setfield(L,-2,"n");
		lua_settable(L,-3);
	}
}

static int LuaXML_ParseFile (lua_State *L) { PROFILE
	const char* sFileName = luaL_checkstring(L,1);
	TiXmlDocument doc(sFileName);
	doc.LoadFile();
	lua_newtable(L);
	LuaXML_ParseNode(L,&doc);
	return 1;
}

static int LuaXML_ParseString (lua_State *L) { PROFILE
	const char* sString = luaL_checkstring(L,1);
	TiXmlDocument doc;
	doc.Parse(sString,0,TIXML_DEFAULT_ENCODING);
	lua_newtable(L);
	LuaXML_ParseNode(L,&doc);
	return 1;
}

/// for lua	LuaXML_SaveFile (sFileName,xmltable)
static int	LuaXML_SaveFile (lua_State *L) { PROFILE
	std::string sFileName = luaL_checkstring(L,1);
	TiXmlDocument doc;
	LuaXML_FillNode(L,2,&doc);
	doc.SaveFile(sFileName.c_str());
	return 0;
}

/// for lua	LuaXML_SaveString (xmltable)
static int	LuaXML_SaveString (lua_State *L) { PROFILE
	TiXmlDocument doc;
	LuaXML_FillNode(L,1,&doc);
	std::string s;
	#ifdef TIXML_USE_STL
	s << doc;
	#else
	s = "<error>set TIXML_USE_STL</error>";
	#endif
	lua_pushstring(L,s.c_str());
	return 1;
}

void	RegisterLuaXML (lua_State *L) {
	lua_register(L,"LuaXML_ParseFile",LuaXML_ParseFile);
	lua_register(L,"LuaXML_ParseString",LuaXML_ParseString);
	lua_register(L,"LuaXML_SaveFile",LuaXML_SaveFile);
	lua_register(L,"LuaXML_SaveString",LuaXML_SaveString);
}

};
