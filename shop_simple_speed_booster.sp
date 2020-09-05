#include <sdktools>
#include <sourcemod>
#include <shop>

#pragma newdecls required
#pragma semicolon 1

public Plugin myinfo = 
{
	name		= "[SHOP] Simple Speed Booster",
	version		= "1.0.0",
	description	= "Simple plugin to boost you speed",
	author		= "iLoco",
	url			= "https://github.com/IL0co"
}

ConVar cvar_Enable, cvar_Bonus, cvar_Delay, cvar_Price, cvar_SellPrice, cvar_Duration;
ItemId gItemId;

bool cwEnable;
float cwdelay, iBonus[MAXPLAYERS+1];

#define CATEGORY "abilities"
#define ITEM 	 "simple_speed_booster"

public void OnPluginEnd()
{
	Shop_UnregisterMe();
}

public void OnPluginStart()
{
	HookEvent("player_jump", PlayerJumpEvent, EventHookMode_Pre);
	
	(cvar_Enable = CreateConVar("sm_shop_simple_booster_enable", "1", "Включён ли плагин", _, true, 0.0, true, 1.0)).AddChangeHook(OnConVarChanged);
	cwEnable = cvar_Enable.BoolValue;

	(cvar_Bonus = CreateConVar("sm_shop_simple_booster_bonus", "15", "Бонус к скорости (юнитов/прыжок)")).AddChangeHook(OnConVarChanged);

	(cvar_Delay = CreateConVar("sm_shop_simple_booster_delay", "0.1", "Заддержка перед добавлением скорости", _, true, 0.01, true, 1.0)).AddChangeHook(OnConVarChanged);
	cwdelay = cvar_Bonus.FloatValue;

	(cvar_Price = CreateConVar("sm_shop_simple_booster_price", "500", "Цена покупки")).AddChangeHook(OnConVarChanged);
	(cvar_SellPrice = CreateConVar("sm_shop_simple_booster_sell_price", "200", "Цена продажи")).AddChangeHook(OnConVarChanged);
	(cvar_Duration = CreateConVar("sm_shop_simple_booster_duration", "72000", "Длительность в секундах")).AddChangeHook(OnConVarChanged);

	if(Shop_IsStarted()) 
		Shop_Started();

	AutoExecConfig(true, "simple_speed_booster", "shop");
	LoadTranslations("shop_simple_speed_booster.phrases");
}

public void OnConVarChanged(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	if(cvar == cvar_Enable)
		cwEnable = cvar.BoolValue;
	else if(cvar == cvar_Delay)
		cwdelay = cvar.FloatValue;
	else if(cvar == cvar_Price)
		Shop_SetItemPrice(gItemId, cvar.IntValue);
	else if(cvar == cvar_SellPrice)
		Shop_SetItemSellPrice(gItemId, cvar.IntValue);
	else if(cvar == cvar_Duration)
		Shop_SetItemValue(gItemId, cvar.IntValue);
}

public void OnClientPostAdminCheck(int client)
{
	iBonus[client] = 0.0;
}

public void Shop_Started()
{
	CategoryId category_id = Shop_RegisterCategory(CATEGORY, CATEGORY, "", CB_Shop_OnCategoryDisplay);

	if(Shop_StartItem(category_id, ITEM))
	{
		Shop_SetInfo(ITEM, "", cvar_Price.IntValue, cvar_SellPrice.IntValue, Item_Togglable, cvar_Duration.IntValue);
		Shop_SetCallbacks(CB_Shop_OnItemRegistered, CB_Shop_OnItemUsed, _, CB_Shop_OnItemDisplay);
		Shop_EndItem();
	}
}

public bool CB_Shop_OnCategoryDisplay(int client, CategoryId category_id, const char[] category, const char[] name, char[] buffer, int maxlen)
{
	FormatEx(buffer, maxlen, "%T", "Menu. Category Display", client);
	return true;
}

public bool CB_Shop_OnItemDisplay(int client, CategoryId category_id, const char[] category, ItemId item_id, const char[] item, ShopMenu menu, bool &disabled, const char[] name, char[] buffer, int maxlen)
{
	FormatEx(buffer, maxlen, "%T", "Menu. Item Display", client);
	return true;
}

public void CB_Shop_OnItemRegistered(CategoryId category_id, const char[] category, const char[] item, ItemId item_id)
{
	gItemId = item_id;
}

public ShopAction CB_Shop_OnItemUsed(int client, CategoryId category_id, const char[] category, ItemId item_id, const char[] item, bool isOn, bool elapsed)
{
	if(!isOn)
		iBonus[client] = cvar_Bonus.FloatValue;
	else	
		iBonus[client] = 0.0;

	if(isOn || elapsed)
		return Shop_UseOff;
		
	return Shop_UseOn;
}


public void PlayerJumpEvent(Event event, const char[] name, bool dontBroadcast)
{
	if(!cwEnable)
		return;
	
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if(!client || !IsClientInGame(client) || iBonus[client] == 0.0)
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
			float x = fCurrentSpeed / (fCurrentSpeed + iBonus[client]);
			iAbsVelocity[0] /= x;
			iAbsVelocity[1] /= x;
			
			TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, iAbsVelocity);
		}
	}
}