// TO USE THIS PLUGINS SOME INFORMATION AND KNOWLEDGE IS NEEDED
//https://dev.twitch.tv/docs/authentication/getting-tokens-oauth/
//
// 1. USE TWITCH DEVELOPER DASHBAORD TO SETUP AN APP AND GET
//     A. CLIENT_ID
//     B. CLIENT_SECRET
//
// 2. SETUP A JSON FILE WITH THE NAME "streamers_config.json" IN /CONFIGS/ WITH THE FOLLOWING TEMPLATE
//      THIS IS REALLY SENSITIVE INFORMATION BE CAREFUL TO NOT SHARE IT WITH ANYONE YOU DONT TRUST
//     {
//         "access_token": "",
//         "twitch_clientID": "",
//         "twitch_secret": ""
//     }

public Plugin myinfo =
{
	name        = "twitch_streams_announcements",
	author      = "shipy",
	description = "announces twitch stream which are lived based on the twitch REST api",
	version     = "0.0.1",
	url         = "https://github.com/shipyy/misc_plugins"
};

//BLACKLIST FILE PATH
#define STREAMERS_PATH "configs/streamers.txt"
#define STREAMERS_CONFIG_PATH "configs/streamers_config.json"

#pragma newdecls required
#pragma semicolon 1
#include <sourcemod>
#include <multicolors>
#include <ripext>

//32 PREDEFINED BLACKLISTED STEAMID
ArrayList g_StreamersList;
ArrayList g_StreamersList_Announced;
ArrayList g_StreamersList_IsLive;

char access_token[64];
char twitch_clientID[64];
char twitch_secret[64];

public void OnPluginStart()
{
    GetToken();
    LoadStreamersList();
}

public void OnConfigsExecuted()
{
    CreateTimer(60.0, CheckOnlineStreams, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
    CreateTimer(300.0, announce_stream, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action announce_stream(Handle timer, any data)
{
    int index_to_announce;
    char streamer_name[32];

    //CHECK IF THERE ATLEAST ONE STREAMER THAT IS LIVE THAT HAS NOT BEEN ANNOUNCED
    bool check = false;
    for(int i = 0; i < g_StreamersList.Length; i++)
    {
        if ( g_StreamersList_IsLive.Get(i) && !g_StreamersList_Announced.Get(i) ) {
            check = true;
        }

        //IF A STREAMER IS NOT LIVE JUST SET ANNOUNCED TO 1
        if ( !g_StreamersList_IsLive.Get(i) )
            g_StreamersList_Announced.Set(i, true);
    }

    // if ( g_StreamersList_IsLive.FindValue(true) != -1 && g_StreamersList_Announced.FindValue(false) != -1)
    if ( check )
    {
        index_to_announce = GetRandomInt(0,4);

        //IF THE RANDOM SELECTED STREAMER IS ONLINE AND HAS NOT BEEN ANNOUNCED
        if ( g_StreamersList_IsLive.Get(index_to_announce) && !g_StreamersList_Announced.Get(index_to_announce) )
        {
            g_StreamersList.GetString(index_to_announce, streamer_name, sizeof streamer_name);
            g_StreamersList_Announced.Set(index_to_announce, true);

            CPrintToChatAll("{purple}STREAMERS{default} | {lightblue}%s is streaming! Check them out @twitch.tv/%s", streamer_name, streamer_name);
        }
        //IF THE RANDOM SELECTED STREAMER IS ONLINE AND HAS BEEN ANNOUNCED
        else if ( g_StreamersList_IsLive.Get(index_to_announce) && g_StreamersList_Announced.Get(index_to_announce) )
        {
            //GET NEW STREAMER TO ANNOUNCE
            index_to_announce = GetRandomInt(0,4);
            while( g_StreamersList_IsLive.Get(index_to_announce) && g_StreamersList_Announced.Get(index_to_announce) || !g_StreamersList_IsLive.Get(index_to_announce)) {
                index_to_announce = GetRandomInt(0,4);
            }

            g_StreamersList.GetString(index_to_announce, streamer_name, sizeof streamer_name);
            g_StreamersList_Announced.Set(index_to_announce, true);

            CPrintToChatAll("{purple}STREAMERS{default} | {lightblue}%s is streaming! Check them out @twitch.tv/%s", streamer_name, streamer_name);
        }
        //IF STREAMER IS NOT ONLINE
        else if ( !g_StreamersList_IsLive.Get(index_to_announce) )
        {
            //GET NEW STREAMER TO ANNOUNCE
            index_to_announce = GetRandomInt(0,4);
            while( g_StreamersList_IsLive.Get(index_to_announce) && g_StreamersList_Announced.Get(index_to_announce) || !g_StreamersList_IsLive.Get(index_to_announce)) {
                index_to_announce = GetRandomInt(0,4);
            }

            g_StreamersList.GetString(index_to_announce, streamer_name, sizeof streamer_name);
            g_StreamersList_Announced.Set(index_to_announce, true);

            CPrintToChatAll("{purple}STREAMERS{default} | {lightblue}%s is streaming! Check them out @twitch.tv/%s", streamer_name, streamer_name);
        }
    }
    //IF THERE NO LIVE STREAMERS RESET ANNOUNCEMENTS
    else {
        for(int i = 0; i < g_StreamersList_Announced.Length; i++)
        {
            g_StreamersList_Announced.Set(i, false);

            //IF A STREAMER IS NOT LIVE JUST SET ANNOUNCED TO 1
            if ( !g_StreamersList_IsLive.Get(i) ) {
                g_StreamersList_Announced.Set(i, true);
            }
        }

        //GET NEW STREAMER TO ANNOUNCE
        index_to_announce = GetRandomInt(0,4);

        //DO SAME HAS IN THE OTHER CASE
        //IF THE RANDOM SELECTED STREAMER IS ONLINE AND HAS BEEN ANNOUNCED
        if ( g_StreamersList_IsLive.Get(index_to_announce) && g_StreamersList_Announced.Get(index_to_announce) )
        {
            //GET NEW STREAMER TO ANNOUNCE
            index_to_announce = GetRandomInt(0,4);

            //GET A NEW STREAMER IF THE RANDOM CHOSEN ONE IS LIVE AND HAS ALREADY BEEN ANOUNCED OR IF THEY ARE SIMPLY NOT LIVE
            while( g_StreamersList_IsLive.Get(index_to_announce) && g_StreamersList_Announced.Get(index_to_announce) || !g_StreamersList_IsLive.Get(index_to_announce)) {
                index_to_announce = GetRandomInt(0,4);
            }

            g_StreamersList.GetString(index_to_announce, streamer_name, sizeof streamer_name);
            g_StreamersList_Announced.Set(index_to_announce, true);

            CPrintToChatAll("{purple}STREAMERS{default} | {lightblue}%s is streaming! Check them out @twitch.tv/%s", streamer_name, streamer_name);
        }
        //IF THE RANDOM SELECTED STREAMER IS ONLINE AND HAS NOT BEEN ANNOUNCED
        else if ( g_StreamersList_IsLive.Get(index_to_announce) && !g_StreamersList_Announced.Get(index_to_announce) )
        {
            g_StreamersList.GetString(index_to_announce, streamer_name, sizeof streamer_name);
            g_StreamersList_Announced.Set(index_to_announce, true);

            CPrintToChatAll("{purple}STREAMERS{default} | {lightblue}%s is streaming! Check them out @twitch.tv/%s", streamer_name, streamer_name);
        }
        //IF STREAMER IS NOT ONLINE
        else if ( !g_StreamersList_IsLive.Get(index_to_announce) )
        {
            //GET NEW STREAMER TO ANNOUNCE
            index_to_announce = GetRandomInt(0,4);

            //GET A NEW STREAMER IF THE RANDOM CHOSEN ONE IS LIVE AND HAS ALREADY BEEN ANOUNCED OR IF THEY ARE SIMPLY NOT LIVE
            while( g_StreamersList_IsLive.Get(index_to_announce) && g_StreamersList_Announced.Get(index_to_announce) || !g_StreamersList_IsLive.Get(index_to_announce)) {
                index_to_announce = GetRandomInt(0,4);
            }

            g_StreamersList.GetString(index_to_announce, streamer_name, sizeof streamer_name);
            g_StreamersList_Announced.Set(index_to_announce, true);

            CPrintToChatAll("{purple}STREAMERS{default} | {lightblue}%s is streaming! Check them out @twitch.tv/%s", streamer_name, streamer_name);
        }
    }

    return Plugin_Handled;
}

public void LoadStreamersList()
{
    char sPath[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, sPath, sizeof sPath, "%s", STREAMERS_PATH);
    File streamerslist = OpenFile(sPath, "r");

    char line[128];
    g_StreamersList = new ArrayList(32);
    g_StreamersList_Announced = new ArrayList();
    g_StreamersList_IsLive = new ArrayList();

    if (streamerslist != null) {

        while (!IsEndOfFile(streamerslist) && ReadFileLine(streamerslist, line, sizeof line)) {

            if (StrContains(line, "//", false) == 0 || IsNullString(line) || strlen(line) == 0)
                continue;

            TrimString(line);

            g_StreamersList.PushString(line);
            g_StreamersList_Announced.Push(false);
            g_StreamersList_IsLive.Push(false);
        }

        PrintToConsole(0, "[STREAMS] Printing StreamerList...");
        char tempid[32];
        for(int i = 0; i < g_StreamersList.Length; i++)
        {
            g_StreamersList.GetString(i, tempid, sizeof tempid);
            PrintToConsole(0, "%s", tempid);
        }
        PrintToConsole(0, "..................................");

        CloseHandle(streamerslist);
    }
    else {
        LogError("[STREAMERS] StreamersList path [%s] not found", STREAMERS_PATH);
    }

}

void GetToken()
{
    char sPath[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, sPath, sizeof sPath, "%s", STREAMERS_CONFIG_PATH);

    JSONObject json_data = JSONObject.FromFile(sPath);

    json_data.GetString("access_token", access_token, sizeof access_token);
    json_data.GetString("twitch_clientID", twitch_clientID, sizeof twitch_clientID);
    json_data.GetString("twitch_secret", twitch_secret, sizeof twitch_secret);

    if ( strcmp(access_token, "", false) != 0 ) {
        HTTPRequest request = new HTTPRequest("https://id.twitch.tv/oauth2/validate");

        request.SetHeader("Authorization", "Bearer %s", access_token);

        request.Get(OnTokenReceived);

        PrintToServer("[STREAMERS] Token Successfully Obtained");
    }
    else {
        RefreshToken();
    }
}

void OnTokenReceived(HTTPResponse response, any value)
{
    if (response.Status != HTTPStatus_OK) {
        RefreshToken();

        return;
    }

    JSONObject json_data = view_as<JSONObject>(response.Data);
    json_data.GetString("access_token", access_token, sizeof access_token);
}

void RefreshToken()
{
    JSONObject params = new JSONObject();
    params.SetString("client_id", twitch_clientID);
    params.SetString("client_secret", twitch_secret);
    params.SetString("grant_type", "client_credentials");

    HTTPRequest request = new HTTPRequest("https://id.twitch.tv/oauth2/token");
    request.Post(params, OnRefreshTokenReceived);
}

void OnRefreshTokenReceived(HTTPResponse response, any value)
{
    if (response.Status != HTTPStatus_OK) {
        JSONObject json_error = view_as<JSONObject>(response.Data);

        char error[2048];
        json_error.ToString(error, sizeof error);

        PrintToServer("[STREAMERS] %s", error);

        return;
    }

    //GET JSON OBJECTS/ARRAYS
    JSONObject json_data = view_as<JSONObject>(response.Data);
    JSONObject new_json_data = new JSONObject();

    json_data.GetString("access_token", access_token, sizeof access_token);

    new_json_data.SetString("access_token", access_token);
    new_json_data.SetString("twitch_clientID", twitch_clientID);
    new_json_data.SetString("twitch_secret", twitch_secret);

    char sPath[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, sPath, sizeof sPath, "%s", STREAMERS_CONFIG_PATH);

    new_json_data.ToFile(sPath);

    PrintToServer("[STREAMERS] Token Successfully Refreshed");
}

public Action CheckOnlineStreams(Handle timer, any data)
{
    char streamer_name[32];
    char uri[1024];

    for(int i = 0; i < g_StreamersList_Announced.Length; i++)
    {
        g_StreamersList.GetString(i, streamer_name, sizeof streamer_name);

        Format(uri, sizeof uri, "https://api.twitch.tv/helix/streams?user_login=%s", streamer_name);

        HTTPRequest request = new HTTPRequest(uri);

        request.SetHeader("Authorization", "Bearer %s", access_token);
        request.SetHeader("Client-Id", "%s", twitch_clientID);

        request.Get(OnTodoReceived, i);
    }

    return Plugin_Handled;
}

void OnTodoReceived(HTTPResponse response, any index_to_check)
{
    if (response.Status != HTTPStatus_OK) {
        JSONObject json_error = view_as<JSONObject>(response.Data);

        char error[2048];
        json_error.ToString(error, sizeof error);

        PrintToServer("[STREAMERS] %s", error);

        return;
    }

    //GET JSON OBJECTS/ARRAYS
    JSONObject json_data = view_as<JSONObject>(response.Data);
    JSONArray stream_data = view_as<JSONArray>(json_data.Get("data"));

    //IF NO DATA FROM THIS STREAM RECEIVED
    if ( stream_data.Length != 0 ) {
        g_StreamersList_IsLive.Set(index_to_check, true);
    }
    else {
        g_StreamersList_IsLive.Set(index_to_check, false);
    }

}