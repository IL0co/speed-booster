#include <sdktools>
#include <sourcemod>
#include <vip_core>

#pragma newdecls required
#pragma semicolon 1

public Plugin myinfo = 
{
	name		= "[VIP] Simple Speed Booster",
	version		= "1.0.0",
	description	= "Simple plugin to boost you speed",
	author		= "iLoco",
	url			= "https://github.com/IL0co"
}

ConVar 	cvar_Enable, cvar_delay;

bool cwEnable;
float cwdelay, iBonus[MAXPLAYERS+1];

#define FEATURE_NAME "simple_speed_booster"

public void OnPluginEnd()
{
	VIP_UnregisterMe();
}

public void OnPluginStart()
{
	HookEvent("player_jump", PlayerJumpEvent, EventHookMode_Pre);
	
	(cvar_Enable = CreateConVar("sm_vip_simple_booster_enable", "1", "Включён ли плагин", _, true, 0.0, true, 1.0)).AddChangeHook(OnConVarChanged);
	cwEnable = cvar_Enable.BoolValue;

	(cvar_delay = CreateConVar("sm_vip_simple_booster_delay", "0.1", "Заддержка перед добавлением скорости", _, true, 0.01, true, 1.0)).AddChangeHook(OnConVarChanged);
	cwdelay = cvar_delay.FloatValue;

	if(VIP_IsVIPLoaded())	
	{
		VIP_OnVIPLoaded();

		for(int i = 1; i <= MaxClients; i++) if(IsClientAuthorized(i) && IsClientInGame(i) & VIP_IsClientVIP(i))	
		{
			if(VIP_GetClientFeatureStatus(i, FEATURE_NAME) == ENABLED)
				iBonus[i] = VIP_GetClientFeatureFloat(i, FEATURE_NAME);
		}
	}

	AutoExecConfig(true, "simple_speed_booster", "vip");
	LoadTranslations("vip_simple_speed_booster.phrases");
}

public void OnConVarChanged(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	if(cvar == cvar_Enable)
		cwEnable = cvar.BoolValue;
	else if(cvar == cvar_delay)
		cwdelay = cvar.FloatValue;
}

public void OnClientPostAdminCheck(int client)
{
	iBonus[client] = 0.0;
}

public void VIP_OnVIPLoaded()
{
	VIP_RegisterFeature(FEATURE_NAME, FLOAT, _, CB_VIP_OnSelectItem, CB_VIP_OnDispay);
}

public bool CB_VIP_OnDispay(int client, const char[] szFeature, char[] szDisplay, int iMaxLength)
{
	FormatEx(szDisplay, iMaxLength, "%T", "Menu. Display", client);
	VIP_AddStringToggleStatus(szDisplay, szDisplay, iMaxLength, FEATURE_NAME, client);

	return true;
}

public Action CB_VIP_OnSelectItem(int client, const char[] szFeature, VIP_ToggleState eOldStatus, VIP_ToggleState &eNewStatus)
{
	if(eNewStatus == ENABLED)
		iBonus[client] = VIP_GetClientFeatureFloat(client, FEATURE_NAME);
	else
		iBonus[client] = 0.0;

	return Plugin_Continue;
}

public void VIP_OnVIPClientRemoved(int client, const char[] szReason, int iAdmin)
{
	iBonus[client] = 0.0;
}

public void PlayerJumpEvent(Event event, const char[] name, bool dontBroadcast)
{
	if(!cwEnable)
		return;
	
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if(!client || iBonus[client] == 0.0 || !IsClientInGame(client))
		return;

	CreateTimer(cwdelay, Timer_Delay, GetClientUserId(client));
}

public Action Timer_Delay(Handle timer, int client)
{
	RequestFrame(BonusVelocity, client);
}

void BonusVelocity(any data)
{
	int client = GetClientOfUserId(data);

	if(!IsClientInGame(client)) 
		return;
	
	if(data != 0)
	{
		float iAbsVelocity[3];
		GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", iAbsVelocity);
		
		float fCurrentSpeed = SquareRoot(Pow(iAbsVelocity[0], 2.0) + Pow(iAbsVelocity[1], 2.0));
		
		if(fCurrentSpeed > 0.0)
		{
			float x = fCurrentSpeed / (fCurrentSpeed + iBonus[client]);
			iAbsVelocity[0] /= x;
			iAbsVelocity[1] /= x;
			
			TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, iAbsVelocity);
		}
	}
}