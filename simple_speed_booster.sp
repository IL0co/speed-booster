#include <sdktools>
#include <sourcemod>

#pragma newdecls required
#pragma semicolon 1

public Plugin myinfo = 
{
	name		= "Simple Speed Booster",
	version		= "1.0.1",
	description	= "Simple plugin to boost you speed",
	author		= "iLoco",
	url			= "https://github.com/IL0co"
}

ConVar cvar_Enable, cvar_Bonus, cvar_Delay, cvar_Flag;

bool cwEnable;
float cwBonus, cwdelay;
int cwFlags;

public void OnPluginStart()
{
	HookEvent("player_jump", PlayerJumpEvent, EventHookMode_Pre);
	
	(cvar_Enable = CreateConVar("sm_simple_booster_enable", "1", "Включён ли плагин", _, true, 0.0, true, 1.0)).AddChangeHook(OnConVarChanged);
	cwEnable = cvar_Enable.BoolValue;

	(cvar_Bonus = CreateConVar("sm_simple_booster_bonus", "15", "Бонус к скорости (юнитов/прыжок)")).AddChangeHook(OnConVarChanged);
	cwBonus = cvar_Bonus.FloatValue;

	(cvar_Delay = CreateConVar("sm_simple_booster_delay", "0.1", "Заддержка перед добавлением скорости", _, true, 0.01, true, 1.0)).AddChangeHook(OnConVarChanged);
	cwdelay = cvar_Bonus.FloatValue;

	(cvar_Flag = CreateConVar("sm_simple_booster_flag", "", "Флаг доступа")).AddChangeHook(OnConVarChanged);

	char buff[65];
	cvar_Flag.GetString(buff, sizeof(buff));
	cwFlags = ReadFlagString(buff);

	AutoExecConfig(true, "simple_speed_booster");
}

public void OnConVarChanged(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	if(cvar == cvar_Enable)
		cwEnable = cvar.BoolValue;
	else if(cvar == cvar_Bonus)
		cwBonus = cvar.FloatValue;
	else if(cvar == cvar_Delay)
		cwdelay = cvar.FloatValue;
	else if(cvar == cvar_Flag)
		cwFlags = ReadFlagString(newValue);
}

public void PlayerJumpEvent(Event event, const char[] name, bool dontBroadcast)
{
	if(!cwEnable || cwBonus == 0.0)
		return;
	
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if(!client || !IsClientInGame(client) || (cwFlags && !(GetUserFlagBits(client) & cwFlags)))
		return;

	CreateTimer(cwdelay, Timer_Delay, GetClientUserId(client));
}

public Action Timer_Delay(Handle timer, int client)
{
	RequestFrame(Frame_BonusVelocity, client);
}

void Frame_BonusVelocity(any data)
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
			float x = fCurrentSpeed / (fCurrentSpeed + cwBonus);
			iAbsVelocity[0] /= x;
			iAbsVelocity[1] /= x;
			
			TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, iAbsVelocity);
		}
	}
}