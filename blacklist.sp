#include <sourcemod>
#pragma newdecls required
#pragma semicolon 1

//BLACKLIST FILE PATH
#define BLACKLIST_PATH "configs/blacklist.txt"

//32 PREDEFINED BLACKLISTED STEAMID
ArrayList g_Blacklist;

public Plugin myinfo =
{
	name        = "Blacklist",
	author      = "shipy",
	description = "blacklist steamid's",
	version     = "0.0.1",
	url         = "https://github.com/shipyy/misc_plugins"
};

public void OnMapStart()
{
    PrintToConsole(0, "[BlackList] Loading Blacklist...");
    LoadBlackList();
}

public void LoadBlackList()
{
    char sPath[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, sPath, sizeof sPath, "%s", BLACKLIST_PATH);
    File blacklist = OpenFile(sPath, "r");

    char line[128];
    g_Blacklist = new ArrayList(32);

    if (blacklist != null) {

        while (!IsEndOfFile(blacklist) && ReadFileLine(blacklist, line, sizeof line)) {

            if (StrContains(line, "//", false) == 0 || IsNullString(line) || strlen(line) == 0)
                continue;

            TrimString(line);

            g_Blacklist.PushString(line);
        }

        PrintToConsole(0, "[Blacklist] Printing Blacklist...");
        char tempid[32];
        for(int i = 0; i < g_Blacklist.Length; i++)
        {
            g_Blacklist.GetString(i, tempid, sizeof tempid);
            PrintToConsole(0, "%s", tempid);
        }

    }
    else {
        LogError("Blacklist path [%s] not found", BLACKLIST_PATH);
    }
}

public void OnClientPostAdminCheck(int client)
{
    char client_steamid[32];
    GetClientAuthId(client, AuthId_Steam2, client_steamid, MAX_NAME_LENGTH, true);

    if (g_Blacklist.Length != 0)
        if(g_Blacklist.FindString(client_steamid) != -1) {
            PrintToConsole(0, "[BlackList] Client (%s) Connected Found in Blacklist!", client_steamid);
            KickClient(client, "No.");
        }

}

public void OnPluginEnd()
{
    delete g_Blacklist;
}

public void OnMapEnd()
{
    delete g_Blacklist;
}