#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <cstrike>
#include <ttt_shop>
#include <ttt>
#include <config_loader>
#include <multicolors>

#pragma newdecls required
#define SHORT_NAME "ClearStatus"
#define LONG_NAME "ClearStatus"
#define PLUGIN_NAME TTT_PLUGIN_NAME ... " - Items: ClearStatus"

int Price = 0;


public Plugin myinfo = 
{
	name = PLUGIN_NAME, 
	author = TTT_PLUGIN_AUTHOR, 
	description = TTT_PLUGIN_DESCRIPTION, 
	version = TTT_PLUGIN_VERSION, 
	url = TTT_PLUGIN_URL
};

public void OnPluginStart()
{
	TTT_IsGameCSGO();
	

	Price = 10;
	

	Config_Done();
}

public void OnAllPluginsLoaded()
{

	TTT_RegisterCustomItem(SHORT_NAME, LONG_NAME, Price, TTT_TEAM_TRAITOR, 0);
}

public void OnClientDisconnect(int client)
{
	
}


public Action TTT_OnItemPurchased(int client, const char[] itemshort, bool count)
{
	if (TTT_IsClientValid(client) && IsPlayerAlive(client))
	{
		if (StrEqual(itemshort, SHORT_NAME, false))
		{
			if(TTT_GetClientRole(client) == TTT_TEAM_TRAITOR)
			{
				SetEntityRenderColor(client, 0 , 0, 0, 255);
				C_PrintToChat(client, "[세탁알림] 당신은 신분세탁 했습니다. 당신의 이름을 아는자가 없다면 빨간 옷을 벗은 당신을 아무도 트레이터라고 생각하지 않을것입니다.");
			}
		}
	}
	return Plugin_Continue;
}
