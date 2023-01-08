#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <clientprefs>

bool g_NoSlide[MAXPLAYERS+1];

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
	
	HookEvent("player_jump", Event_PlayerJump, EventHookMode_Post);
	
	g_NoslideCookie = RegClientCookie("noslide_enabled", "Noslide enabled", CookieAccess_Protected);
	
	for (int i; ++i <= MaxClients;) {
        if (!IsClientInGame(i) || IsFakeClient(i) || !AreClientCookiesCached(i))
            continue;

        OnClientCookiesCached(i);
    }
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
	SetClientCookieBool(client, g_NoslideCookie, g_NoSlide[client]);
	PrintToChat(client, "[SM] No Slide %s.", g_NoSlide[client] ? "disabled" : "enabled");

	return Plugin_Handled;
}

public Action Event_PlayerJump(Handle event, const char[] name, bool dontBroadcast)
{	
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	//if (!g_NoSlide[client])
	//	return Plugin_Continue;
	
	if (!client)
        return Plugin_Handled;
	
	if (g_NoSlide[client])
	{
		SetEntPropFloat(client, Prop_Send, "m_flStamina", 0.0);
	}

	return Plugin_Handled;
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
