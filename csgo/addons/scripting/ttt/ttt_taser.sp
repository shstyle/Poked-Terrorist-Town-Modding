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

#define SHORT_NAME "taser"
#define SHORT_NAME_T "taser_t"
#define SHORT_NAME_D "taser_d"
#define LONG_NAME "Taser"

#define PLUGIN_NAME TTT_PLUGIN_NAME ... " - Items: Taser"

int g_iDPrice = 0;
int g_iIPrice = 0;
int g_iTPrice = 0;

int g_iDPrio = 0; 
int g_iIPrio = 0;
int g_iTPrio = 0;

int g_iDCount = 0;
int g_iDPCount[MAXPLAYERS + 1] =  { 0, ... };

int g_iICount = 0;
int g_iIPCount[MAXPLAYERS + 1] =  { 0, ... };

int g_iTCount = 0;
int g_iTPCount[MAXPLAYERS + 1] =  { 0, ... };

bool g_bTaser[MAXPLAYERS + 1] =  { false, ... };

int g_iDamage = 0;
int g_iCreditsTaserHurtTraitor;

bool g_bOnSpawn = false;

bool g_bBroadcastTaserResult = false;

char g_sConfigFile[PLATFORM_MAX_PATH] = "";
char g_sPluginTag[PLATFORM_MAX_PATH] = "";

int g_iTDamage = 100;

bool g_bInflictor = true;

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
	
	LoadTranslations("ttt.phrases");
	
	BuildPath(Path_SM, g_sConfigFile, sizeof(g_sConfigFile), "configs/ttt/config.cfg");
	Config_Setup("TTT", g_sConfigFile);
	g_iCreditsTaserHurtTraitor = Config_LoadInt("ttt_hurt_traitor_with_taser", 2000, "The amount of credits an innocent or detective will recieve for discovering a traitor with their zues/taser.");
	
	Config_LoadString("ttt_plugin_tag", "{orchid}[{green}T{darkred}T{blue}T{orchid}]{lightgreen} %T", "The prefix used in all plugin messages (DO NOT DELETE '%T')", g_sPluginTag, sizeof(g_sPluginTag));
	
	Config_Done();
	
	BuildPath(Path_SM, g_sConfigFile, sizeof(g_sConfigFile), "configs/ttt/taser.cfg");
	Config_Setup("TTT-Taser", g_sConfigFile);
	
	g_iDPrice = Config_LoadInt("ta_detective_price", 9000, "The amount of credits a taser costs as detective. 0 to disable.");
	g_iIPrice = Config_LoadInt("ta_innocent_price", 9000, "The amount of credits a taser costs as innocent. 0 to disable.");
	g_iTPrice = Config_LoadInt("ta_traitor_price", 0, "The amount of credits a taser costs as traitor. 0 to disable.");
	
	g_iDPrio = Config_LoadInt("ta_detective_sort_prio", 0, "The sorting priority of the taser (Detective) in the shop menu.");
	g_iIPrio = Config_LoadInt("ta_innocent_sort_prio", 0, "The sorting priority of the taser (Innocent) in the shop menu.");
	g_iTPrio = Config_LoadInt("ta_traitor_sort_prio", 0, "The sorting priority of the taser (Traitor) in the shop menu.");
	
	g_iDCount = Config_LoadInt("ta_detective_count", 1, "The amount of usages for tasers per round as detective. 0 to disable.");
	g_iICount = Config_LoadInt("ta_innocent_count", 1, "The amount of usages for tasers per round as innocent. 0 to disable.");
	g_iTCount = Config_LoadInt("ta_traitor_count", 1, "The amount of usages for tasers per round as traitor. 0 to disable.");
	
	g_iDamage = Config_LoadInt("ta_damage", 0, "The amount of damage a taser deals for detectives and innocents");
	g_iTDamage = Config_LoadInt("ta_traitor_damage", 0, "The amount of damage a taser deals for traitors");
	
	g_bOnSpawn = Config_LoadBool("ta_give_taser_spawn", true, "Give the Detective a taser when he spawns?");

	g_bBroadcastTaserResult = Config_LoadBool("ta_broadcast_taser_result", false, "When set to true the results of the taser message will be printed to everyone instead of the client that tased");
	
	g_bInflictor = Config_LoadBool("ta_barrel_fix", true, "Prevent bug with taser and a explosive barrel");
	
	Config_Done();
	
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("item_equip", Event_ItemEquip);
	
	LateLoadAll();
}

public void OnClientDisconnect(int client)
{
	ResetTaser(client);
}

public void OnClientPutInServer(int client)
{
	HookClient(client);
}

public void LateLoadAll()
{
	LoopValidClients(i)
	{
		LateLoadClient(i);
	}
}
public void LateLoadClient(int client)
{
	HookClient(client);
}

public void HookClient(int client)
{
	SDKHook(client, SDKHook_TraceAttack, OnTraceAttack);
	SDKHook(client, SDKHook_WeaponDrop, OnWeaponDrop);
}

public void TTT_OnClientGetRole(int client, int role)
{
	if (role == TTT_TEAM_DETECTIVE && g_bOnSpawn)
	{
		if (g_bTaser[client])
		{
			return;
		}
		
		GivePlayerItem(client, "weapon_taser");
		g_iDPCount[client]++;
	}
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if (TTT_IsClientValid(client))
	{
		ResetTaser(client);
	}
}

public Action Event_ItemEquip(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	char sWeapon[32];
	event.GetString("item", sWeapon, sizeof(sWeapon));
	
	if (StrContains(sWeapon, "taser", false) != -1)
	{
		g_bTaser[client] = true;
	}
}

public Action OnWeaponDrop(int client, int weapon)
{
	if (weapon == -1)
	{
		return;
	}
	
	char sWeapon[32];
	GetEntityClassname(weapon, sWeapon, sizeof(sWeapon));
	
	if (StrContains(sWeapon, "taser", false) != -1)
	{
		g_bTaser[client] = false;
	}
}

public void OnAllPluginsLoaded()
{
	TTT_RegisterCustomItem(SHORT_NAME_D, LONG_NAME, g_iDPrice, TTT_TEAM_DETECTIVE, g_iDPrio);
	TTT_RegisterCustomItem(SHORT_NAME, LONG_NAME, g_iIPrice, TTT_TEAM_INNOCENT, g_iIPrio);
	TTT_RegisterCustomItem(SHORT_NAME_T, LONG_NAME, g_iTPrice, TTT_TEAM_TRAITOR, g_iTPrio);
}

public Action TTT_OnItemPurchased(int client, const char[] itemshort, bool count)
{
	if (TTT_IsClientValid(client) && IsPlayerAlive(client))
	{
		if (StrEqual(itemshort, SHORT_NAME, false) || StrEqual(itemshort, SHORT_NAME_D, false) || StrEqual(itemshort, SHORT_NAME_T, false))
		{
			int role = TTT_GetClientRole(client);
			
			if (role == TTT_TEAM_DETECTIVE && g_iDPCount[client] >= g_iDCount)
			{
				CPrintToChat(client, g_sPluginTag, "TaserMax", client, g_iDCount);
				return Plugin_Stop;
			}
			else if (role == TTT_TEAM_INNOCENT && g_iIPCount[client] >= g_iICount)
			{
				CPrintToChat(client, g_sPluginTag, "TaserMax", client, g_iICount);
				return Plugin_Stop;
			}
			else if (role == TTT_TEAM_TRAITOR && g_iTPCount[client] >= g_iTCount)
			{
				CPrintToChat(client, g_sPluginTag, "TaserMax", client, g_iTCount);
				return Plugin_Stop;
			}
			
			if (g_bTaser[client])
			{
				CPrintToChat(client, g_sPluginTag, "AlreadyTaser", client);
				return Plugin_Stop;
			}
				
			GivePlayerItem(client, "weapon_taser");
			g_bTaser[client] = true;
			
			if (count)
			{
				if (role == TTT_TEAM_DETECTIVE)
				{
					g_iDPCount[client]++;
				}
				else if (role == TTT_TEAM_INNOCENT)
				{
					g_iIPCount[client]++; 
				}
				else if (role == TTT_TEAM_TRAITOR)
				{
					g_iTPCount[client]++;
				}
				
			}
		}
	}
	return Plugin_Continue;
}

void ResetTaser(int client)
{
	g_iDPCount[client] = 0;
	g_iIPCount[client] = 0;
	g_iTPCount[client] = 0;

	g_bTaser[client] = false;
}

public Action OnTraceAttack(int iVictim, int &iAttacker, int &inflictor, float &damage, int &damagetype, int &ammotype, int hitbox, int hitgroup)
{
	if (!TTT_IsRoundActive())
	{
		return Plugin_Continue;
	}
	
	if (IsWorldDamage(iAttacker, damagetype))
	{
		return Plugin_Continue;
	}
	
	if (!TTT_IsClientValid(iVictim) || !TTT_IsClientValid(iAttacker))
	{
		return Plugin_Continue;
	}
	
	if (g_bInflictor && iAttacker != inflictor)
	{
		return Plugin_Continue;
	}
	
	char sWeapon[64];
	int iRole = TTT_GetClientRole(iVictim);
	int iARole = TTT_GetClientRole(iAttacker);
	GetClientWeapon(iAttacker, sWeapon, sizeof(sWeapon));
	if (StrContains(sWeapon, "taser", false) != -1)
	{
		if (iRole == TTT_TEAM_TRAITOR)
		{
			TTT_LogString("-> [%N (Traitor) was tased by %N] - TRAITOR DETECTED", iVictim, iAttacker, iVictim);
			if(iARole == TTT_TEAM_DETECTIVE)
			{
				SetEntityRenderColor(iVictim, 255,  0, 0, 255);
				CPrintToChat(iVictim, "[증명됨] 당신은 트레이터로 판별되었습니다. 다른 사람들은 당신이 트레이터임을 알아볼 수 있습니다. 빨리 도망치십시오.");
			}
			if (g_bBroadcastTaserResult)
			{
				CPrintToChatAll(g_sPluginTag, "You tased a Traitor", "ko", iAttacker, iVictim);
			}
			else
			{
				CPrintToChat(iAttacker, g_sPluginTag, "You hurt a Traitor", iVictim, iVictim);
			}
			
			TTT_SetClientCredits(iAttacker, TTT_GetClientCredits(iAttacker) + g_iCreditsTaserHurtTraitor);
		}
		else if (iRole == TTT_TEAM_DETECTIVE)
		{
			
		}
		else if (iRole == TTT_TEAM_INNOCENT)
		{
			if(iARole == TTT_TEAM_DETECTIVE)
			{
				
				SetEntityRenderColor(iVictim, 0 , 255, 0, 255);
				CPrintToChat(iVictim, "[증명됨] 당신은 이노센트임이 증명되었습니다.");
				
			}
			TTT_LogString("-> [%N (Innocent) was tased by %N]", iVictim, iAttacker, iVictim);
			
			if (g_bBroadcastTaserResult)
			{
				CPrintToChatAll(g_sPluginTag, "You tased an Innocent", "ko", iAttacker, iVictim);
			}
			else
			{
				CPrintToChat(iAttacker,  g_sPluginTag, "You hurt an Innocent", iVictim, iVictim);
			}
		}
		
		if (iARole != TTT_TEAM_TRAITOR)
		{
			if (g_iDamage == 0)
			{
				return Plugin_Handled;
			}
			else if (g_iDamage > 0)
			{
				damage = g_iDamage + 0.0;
				return Plugin_Changed;
			}
		}
		else
		{
			damage = g_iTDamage + 0.0;
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}