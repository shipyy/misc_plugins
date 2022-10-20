public Plugin myinfo =
{
	name = "autorestart",
	author = "shipy",
	description = "Automatically Restart Server",
	version = "0.0.1",
	url = "https://github.com/shipyy/misc_plugins",
}

#pragma semicolon 1
#include <sourcemod>
#include <colorlib>
#include <autoexecconfig>

char LogFilePath[PLATFORM_MAX_PATH];

ConVar ScheduleTimeStamp;
ConVar ForceRetry;

public void OnPluginStart()
{
    if (!DirExists("addons/sourcemod/logs/autorestart"))
        CreateDirectory("addons/sourcemod/logs/autorestart", 511);
    BuildPath(Path_SM, LogFilePath, sizeof(LogFilePath), "logs/autorestart/autorestart.log");

    AutoExecConfig_SetCreateDirectory(true);
    AutoExecConfig_SetCreateFile(true);
    AutoExecConfig_SetFile("autorestart");

    ScheduleTimeStamp = AutoExecConfig_CreateConVar("sm_timestamp_restart", "060000", "specifies value of server restart in H-M-S format", _, true, 0.0, true, 240000.0);
    ForceRetry = AutoExecConfig_CreateConVar("sm_force_retry", "1", "force clients to retry after server restart", _, true, 0.0, true, 1.0);

    AutoExecConfig_ExecuteFile();
    AutoExecConfig_CleanFile();
}

public void OnConfigsExecuted()
{
    CreateTimer(1.0, TimeCheck, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public void Restart()
{
    //LOG TO CONSOLE
    LogAction(0, -1, "[AutoRestart] Restarting Server...");

    //LOG TO LOGFILE
    char currentTime_formatted[32];
    FormatTime(currentTime_formatted, sizeof currentTime_formatted, "%d/%m/%G %H:%M:%S", GetTime());
    LogToFile(LogFilePath, "[AutoRestart] | %s | Restarting Server...", currentTime_formatted);

    //FOR CLIENTS RETRY
    if (ForceRetry.BoolValue) {
        for(int i = 1; i <= MaxClients; i++)
            if (IsClientInGame(i) && !IsFakeClient(i))
                ClientCommand(i, "retry");
    }
    else {
        ServerCommand("_restart");
    }
}

public Action TimeCheck(Handle timer, any data)
{
    //GET CURRENT TIME
    char currentTime_formatted[32];
    FormatTime(currentTime_formatted, sizeof currentTime_formatted, "%H%M%S", GetTime());
    int currentTime = StringToInt(currentTime_formatted);

    //GET CURRENT TIME
    int restarttime = ScheduleTimeStamp.IntValue;

    //RESTART SERVER IF TIMES MATCH
    if(currentTime == restarttime)
        Restart();

    //ACCOUNT FOR SUBTRACTING WHEN RESTART TIMESTAMP IS BETWEEN 00:00.00 AND 00:05.00
    if (restarttime <= 500)
        restarttime = 240000;

    //PRINT WARNING MESSAGES IN ALL CHAT
    else if(currentTime == restarttime - 500) {
        CPrintToChatAll("{lime}PENALTE{default} | {lightblue}Daily server restart in 5 minutes...");
        PrintToConsole(0, "Daily server restart in 5 minutes...");
    }
    else if(currentTime == restarttime - 100) {
        CPrintToChatAll("{lime}PENALTE{default} | {lightblue}Daily server restart in 1 minute...");
        PrintToConsole(0, "Daily server restart in 1 minute...");
    }
    else if(currentTime >= restarttime - 70 && currentTime < restarttime ) {
        if(currentTime == restarttime - 70 ) {
            CPrintToChatAll("{lime}PENALTE{default} | {lightblue}Daily server restart in 30 seconds...");
            PrintToConsole(0, "Daily server restart in 30 seconds...");
        }
        else if(currentTime == restarttime - 45 ) {
            CPrintToChatAll("{lime}PENALTE{default} | {lightblue}Daily server restart in 5 seconds...");
            PrintToConsole(0, "Daily server restart in 5 seconds...");
        }
        else if(currentTime == restarttime - 44 ) {
            CPrintToChatAll("{lime}PENALTE{default} | {lightblue}Daily server restart in 4 seconds...");
            PrintToConsole(0, "Daily server restart in 4 seconds...");
        }
        else if(currentTime == restarttime - 43 ) {
            CPrintToChatAll("{lime}PENALTE{default} | {lightblue}Daily server restart in 3 seconds...");
            PrintToConsole(0, "Daily server restart in 3 seconds...");
        }
        else if(currentTime == restarttime - 42 ) {
            CPrintToChatAll("{lime}PENALTE{default} | {lightblue}Daily server restart in 2 seconds...");
            PrintToConsole(0, "Daily server restart in 2 seconds...");
        }
        else if(currentTime == restarttime - 41 ) {
            CPrintToChatAll("{lime}PENALTE{default} | {lightblue}Daily server restart in 1 second...");
            PrintToConsole(0, "Daily server restart in 1 second...");
        }
    }

    return Plugin_Continue;
}