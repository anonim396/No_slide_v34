#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <clientprefs>

bool g_NoSlide[MAXPLAYERS+1];

bool gB_Late;

int gI_GroundTicks[MAXPLAYERS+1];

bool gB_StuckFriction[MAXPLAYERS+1];

float gF_Tickrate = 0.0128; // 128 tickrate.

Handle g_NoslideCookie;

public Plugin myinfo =
{
	name = "No Slide",
	author = "asagi",
	description = "Stops sliding upon landing. Designed for kz/bhop maps.",
	version = "1.0",
	url = ""
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_noslide", Command_Noslide, "Toggles noslide.");
	RegConsoleCmd("sm_kz", Command_Noslide, "Toggles noslide. Alias for sm_noslide.");
	RegConsoleCmd("sm_kzmode", Command_Noslide, "Toggles noslide. Alias for sm_noslide.");
	
	g_NoslideCookie = RegClientCookie("noslide_enabled", "Noslide enabled", CookieAccess_Protected);
	
	if (gB_Late)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i))
			{
				continue;
			}

			if (!AreClientCookiesCached(i))
			{
				continue;
			}

			OnClientCookiesCached(i);
		}
	}
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	gB_Late = late;
	return APLRes_Success;
}

public void OnMapStart()
{
	gF_Tickrate = GetTickInterval();
}

public void OnClientCookiesCached(int client)
{
	if (!GetClientCookieBool(client, g_NoslideCookie, g_NoSlide[client]))
	{
		g_NoSlide[client] = false;
		SetClientCookieBool(client, g_NoslideCookie, false);
	}
}

public Action Command_Noslide(int client, int args)
{
	if (!client)
        return Plugin_Handled;

	g_NoSlide[client] = !g_NoSlide[client];

	PrintToChat(client, "Your no slide is now %s.", g_NoSlide[client] ? "Disabled" : "Enabled");

	return Plugin_Handled;
}

public Action OnPlayerRunCmd(int client, int &buttons)
{	
	if (!client)
        return Plugin_Handled;
	
	if(GetEntPropEnt(client, Prop_Send, "m_hGroundEntity") == 0)
	{
		gI_GroundTicks[client] = 0;

		return Plugin_Continue;
	}
	
	if(g_NoSlide[client] || (buttons & IN_JUMP) > 0)
	{
		return Plugin_Continue;
	}
	
	float fStamina = GetEntPropFloat(client, Prop_Send, "m_flStamina");

	if(++gI_GroundTicks[client] == 3 || (fStamina <= 350.0)) // 350.0 is a sweetspoot for me.
	{
		SetEntPropFloat(client, Prop_Send, "m_flStamina", 1320.0); // 1320.0 is highest stamina in CS:S.
		
		DataPack pack = new DataPack();
		pack.WriteCell(GetClientSerial(client));
		pack.WriteFloat(fStamina);
		
		CreateTimer((gF_Tickrate * 1), Timer_ApplyNewStamina, TIMER_FLAG_NO_MAPCHANGE);//def (gF_Tickrate * 5)
	}

	return Plugin_Continue;
}

public Action Timer_ApplyNewStamina(Handle timer, DataPack data)
{
	data.Reset();
	int iSerial = data.ReadCell();
	float fStamina = data.ReadFloat();
	delete data;

	int client = GetClientFromSerial(iSerial);

	if(client != 0)
	{
		SetEntPropFloat(client, Prop_Send, "m_flStamina", fStamina);
	}

	return Plugin_Stop;
}

public void OnClientPutInServer(int client)
{
	gI_GroundTicks[client] = 3;
	gB_StuckFriction[client] = false;

	if(!AreClientCookiesCached(client))
	{
		g_NoSlide[client] = false;
	}
}

stock void SetClientCookieBool(int client, Handle cookie, bool value)
{
	SetClientCookie(client, cookie, value ? "1" : "0");
}

stock bool GetClientCookieBool(int client, Handle cookie, bool& value)
{
	char buffer[8];
	GetClientCookie(client, cookie, buffer, sizeof(buffer));

	if (buffer[0] == '\0')
	{
		return false;
	}

	value = StringToInt(buffer) != 0;
	return true;
}
