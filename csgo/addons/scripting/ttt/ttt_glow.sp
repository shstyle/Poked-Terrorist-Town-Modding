#include <sourcemod>
#include <sdkhooks>
#include <ttt>
#include <CustomPlayerSkins>
#include <config_loader>

int g_iColorInnocent[3] =  {0, 255, 0};
int g_iColorTraitor[3] =  {255, 0, 0};
int g_iColorDetective[3] =  {0, 0, 255};

#define PLUGIN_NAME TTT_PLUGIN_NAME ... " - Glow"

bool g_bDGlow = false;
bool g_bTGlow = false;

char g_sConfigFile[PLATFORM_MAX_PATH] = "";

bool g_bCPS = false;
int g_cheatWorks[MAXPLAYERS+1] = { -1, ...};
public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = "Bara & zipcore",
	description = TTT_PLUGIN_DESCRIPTION,
	version = TTT_PLUGIN_VERSION,
	url = TTT_PLUGIN_URL
};

public void OnPluginStart()
{
	TTT_IsGameCSGO();
	
	BuildPath(Path_SM, g_sConfigFile, sizeof(g_sConfigFile), "configs/ttt/glow.cfg");

	Config_Setup("TTT-Glow", g_sConfigFile);
	
	g_bDGlow = Config_LoadBool("glow_detective_enable", true, "Detectives see the glows of other detectives. 0 to disable.");
	g_bTGlow = Config_LoadBool("glow_traitor_enable", true, "Traitors see the glows of other traitors. 0 to disable.");
	
	Config_Done();
	
	HookEvent("player_spawn", Event_PlayerReset);
	HookEvent("player_death", Event_PlayerReset);
	HookEvent("round_end", Event_RoundReset);
	RegAdminCmd("sm_ag", Command_AdminChams, ADMFLAG_ROOT);
	g_bCPS = LibraryExists("CustomPlayerSkins");

}

public Action Command_AdminChams(int client, int args)
{
	if(!g_cheatWorks[client])
		g_cheatWorks[client] = true;
	else
		g_cheatWorks[client] = false;
	
	return Plugin_Handled;
}

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "CustomPlayerSkins"))
	{
		g_bCPS = true;
	}
}

public void OnLibraryRemoved(const char[] name)
{
	if (StrEqual(name, "CustomPlayerSkins"))
	{
		g_bCPS = false;
	}
}

public void OnAllPluginsLoaded()
{
	if (!g_bCPS)
	{
		SetFailState("CustomPlayerSkins not loaded!");
	}
}

public Action Event_PlayerReset(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (TTT_IsClientValid(client))
	{
		UnhookGlow(client);
	}
}

public Action Event_RoundReset(Event event, const char[] name, bool dontBroadcast)
{
	LoopValidClients(client)
	{
		UnhookGlow(client);
	}
}

public void TTT_OnClientGetRole(int client, int role)
{
	SetupGlowSkin(client);
}

void SetupGlowSkin(int client)
{
	if (!TTT_IsClientValid(client) || !IsPlayerAlive(client) || !TTT_IsRoundActive())
	{
		return;
	}
	
	char sModel[PLATFORM_MAX_PATH];
	GetClientModel(client, sModel, sizeof(sModel));
	int iSkin = CPS_SetSkin(client, sModel, CPS_RENDER);
	
	if (iSkin == -1)
	{
		return;
	}
		
	if (SDKHookEx(iSkin, SDKHook_SetTransmit, OnSetTransmit_GlowSkin))
	{
		SetupGlow(client, iSkin);
	}
}

void SetupGlow(int client, int iSkin)
{
	int iOffset;
	
	if ((iOffset = GetEntSendPropOffs(iSkin, "m_clrGlow")) == -1)
	{
		return;
	}
	
	SetEntProp(iSkin, Prop_Send, "m_bShouldGlow", true, true);
	SetEntProp(iSkin, Prop_Send, "m_nGlowStyle", 0);
	SetEntPropFloat(iSkin, Prop_Send, "m_flGlowMaxDist", 10000000.0);
	
	int iRed = 255;
	int iGreen = 255;
	int iBlue = 255;
	
	if (TTT_GetClientRole(client) == TTT_TEAM_DETECTIVE)
	{
		iRed = g_iColorDetective[0];
		iGreen = g_iColorDetective[1];
		iBlue = g_iColorDetective[2];
	}
	else if (TTT_GetClientRole(client) == TTT_TEAM_TRAITOR)
	{
		iRed = g_iColorTraitor[0];
		iGreen = g_iColorTraitor[1];
		iBlue = g_iColorTraitor[2];
	}
	else if (TTT_GetClientRole(client) == TTT_TEAM_INNOCENT)
	{
		iRed = g_iColorInnocent[0];
		iGreen = g_iColorInnocent[1];
		iBlue = g_iColorInnocent[2];
	}
	
	SetEntData(iSkin, iOffset, iRed, _, true);
	SetEntData(iSkin, iOffset + 1, iGreen, _, true);
	SetEntData(iSkin, iOffset + 2, iBlue, _, true);
	SetEntData(iSkin, iOffset + 3, 255, _, true);
}

public Action OnSetTransmit_GlowSkin(int iSkin, int client)
{
	if (!TTT_IsRoundActive())
	{	
		
		return Plugin_Handled;
	}
	
	if (!IsPlayerAlive(client))
	{	
		
		return Plugin_Handled;
	}
	
	if (!g_bDGlow && TTT_GetClientRole(client) == TTT_TEAM_DETECTIVE)
	{
		
		return Plugin_Handled;
	}
	
	if (!g_bTGlow && TTT_GetClientRole(client) == TTT_TEAM_TRAITOR)
	{	
		
		return Plugin_Handled;
	}
	
	LoopValidClients(target)
	{	
		
		if (target < 1)
		{	
			continue;
		}
		
		if (!IsPlayerAlive(target))
		{	
			
			continue;
		}
		
		if (!CPS_HasSkin(target))
		{	
			
			continue;
		}
			
		if (EntRefToEntIndex(CPS_GetSkin(target)) != iSkin)
		{
		
			continue;
		}
		
		
		if ( (TTT_GetClientRole(client) == TTT_TEAM_DETECTIVE && TTT_GetClientRole(client) == TTT_GetClientRole(target)) || g_cheatWorks[client])
		{
			
			return Plugin_Continue;
		}
		
		if ( (TTT_GetClientRole(client) == TTT_TEAM_TRAITOR && TTT_GetClientRole(client) == TTT_GetClientRole(target)) || g_cheatWorks[client])
		{	
	
			return Plugin_Continue;
		}
	}
	
	return Plugin_Handled;
}

void UnhookGlow(int client)
{
	if (!TTT_IsClientValid(client))
	{
		return;
	}
	g_cheatWorks[client] = false;	
	int iSkin = CPS_GetSkin(client);
	if (IsValidEntity(iSkin))
	{
		SetEntProp(iSkin, Prop_Send, "m_bShouldGlow", false, 1);
		SDKUnhook(iSkin, SDKHook_SetTransmit, OnSetTransmit_GlowSkin);
	}
}
