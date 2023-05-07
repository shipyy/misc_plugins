//THIS PLUGINS IS INTENDED TO USE WITH A CRONTABS CREATED
//CRONTAB 1 -> EVERYDAY AT 00:00:00 TO RUN sm_set_sod_unix_timestamp
//CRONTAB 2 -> WITH THE EXACT SAME SCHEDULE SET IN THE AUTOSTART.CFG FOR THE FIELD 'sm_timestamp_restart'

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

#define UNIX_PATH "configs/UNIX_LOGFILE.txt"

char LogFilePath[PLATFORM_MAX_PATH];
char UNIX_CURRENTDAY_LOGFILE[PLATFORM_MAX_PATH];

ConVar ScheduleTimeStamp;
ConVar ForceRetry;
File SOD_UnixStamps;

char sSOD_UnixTimestamp[128];

public void OnPluginStart()
{
    if (!DirExists("addons/sourcemod/logs/autorestart")) {
        CreateDirectory("addons/sourcemod/logs/autorestart", 511);
    }
    BuildPath(Path_SM, LogFilePath, sizeof(LogFilePath), "logs/autorestart/autorestart.log");
    BuildPath(Path_SM, UNIX_CURRENTDAY_LOGFILE, sizeof(UNIX_CURRENTDAY_LOGFILE), "%s", UNIX_PATH);

    AutoExecConfig_SetCreateDirectory(true);
    AutoExecConfig_SetCreateFile(true);
    AutoExecConfig_SetFile("autorestart");

    ScheduleTimeStamp = AutoExecConfig_CreateConVar("sm_timestamp_restart", "060000", "specifies value of server restart in H-M-S format", _, true, 0.0, true, 240000.0);
    ForceRetry = AutoExecConfig_CreateConVar("sm_force_retry", "1", "force clients to retry after server restart", _, true, 0.0, true, 1.0);

    RegServerCmd("sm_restart_server", RestartServer, "[AutoRestart] Restarts Server");
    RegServerCmd("sm_set_sod_unix_timestamp", StartofDay, "[AutoRestart] Sets Start of Day Unix Timestamp");

    AutoExecConfig_ExecuteFile();
    AutoExecConfig_CleanFile();

    //LOAD UNIX LOGFILE AND GETS VALUE
    SOD_UnixStamps = OpenFile(UNIX_CURRENTDAY_LOGFILE, "rw");

    //FILE LOGIC
    //LOAD LAST LINE OF A FILE CONATINING THE VALUE APPENDED TO IT (WHAT IF RESTART TIME IS 00:00:00???, SERVER WOULD BE DOWN...)
    //FOR NOW THIS IS THE SOULTION I ENDED UP WITH
    //USING FILES MIGHT NOIT BE ACTUALLY POSSIBLE SINCE I BELIEVE WHEN A SERVER IS HIBERNATING IT IS NOT POSSIBLE TO "CONNECT" TO THE HANDLES CREATED
    if (SOD_UnixStamps != null) {
        char szTempLine[128];
        char szTempLine_SPLIT[6][128];
        while (!IsEndOfFile(SOD_UnixStamps) && ReadFileLine(SOD_UnixStamps, szTempLine, sizeof szTempLine)) {
            ExplodeString(szTempLine, " ", szTempLine_SPLIT, sizeof szTempLine_SPLIT, sizeof szTempLine_SPLIT[]);
        }
        Format(sSOD_UnixTimestamp, sizeof sSOD_UnixTimestamp, "%s", szTempLine_SPLIT[5]);
        TrimString(sSOD_UnixTimestamp);
    }
}

public void OnConfigsExecuted()
{
    CreateTimer(1.0, TimeCheck, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

void Restart(bool hibernating = false)
{
    int SOD = GetTime();

    //LOG TO CONSOLE
    LogAction(0, -1, "Restarting Server...");

    //LOG TO LOGFILE
    char currentTime_formatted[32];
    FormatTime(currentTime_formatted, sizeof currentTime_formatted, "%d/%m/%G %H:%M:%S", GetTime());
    if ( hibernating )
        LogToFile(LogFilePath, "[AutoRestart] | %s | Forcing Restart, Server was hibernating...", currentTime_formatted);
    else
        LogToFile(LogFilePath, "[AutoRestart] | %s | Restarting Server...", currentTime_formatted);

    //FOR CLIENTS RETRY
    if (ForceRetry.BoolValue) {
        for(int i = 1; i <= MaxClients; i++)
            if (IsClientInGame(i) && !IsFakeClient(i))
                ClientCommand(i, "retry");
    }

    //ADD START OF DAY UNIX TIMESTAMP TO FILE
    //EVERYDAY AT 00:00:00 GET THE UNIX TIMESTAMP THAT CORRESPONDS TO IT (SAVE IT ON A FILE?, PROBABLY SINCE RESTART RELOADS PROGRAM VALUES U DUMB CUNT!)
    if( ScheduleTimeStamp.IntValue == 0 ) {
        LogToFile(UNIX_CURRENTDAY_LOGFILE, "%d", SOD);
    }

    ServerCommand("_restart");
}

public Action TimeCheck(Handle timer, any data)
{
    //GetTime() RETURNS TIMESTAMP IN UNIX (SECONDS)
    int currentTime = GetTime();

    //ADD START OF DAY UNIX TIMESTAMP TO FILE
    //EVERYDAY AT 00:00:00 GET THE UNIX TIMESTAMP THAT CORRESPONDS TO IT (SAVE IT ON A FILE?, PROBABLY SINCE RESTART RELOADS PROGRAM VALUES U DUMB CUNT!)
    if( ScheduleTimeStamp.IntValue == 0 ) {
        LogToFile(UNIX_CURRENTDAY_LOGFILE, "%d", currentTime);
    }

    //GET RESTART TIME
    int restarttime = ScheduleTimeStamp.IntValue;

    //CALCULATE THE VALUE OF THE UNIX TIMESTAMP OF THE FUTURE RESTART BASED ON THE UNIX TIMESTAMP OF THE BEGINNING OF THE CURRENT DAY
    if ( restarttime <= 5960 ) {
        restarttime = StringToInt(sSOD_UnixTimestamp) + ConvertToSeconds(restarttime, 1);
    }
    else {
        restarttime = StringToInt(sSOD_UnixTimestamp) + ConvertToSeconds(restarttime, 2);
    }

    if ( currentTime == restarttime )
        Restart();

    //CHECK FOR 5 MINUTES
    if ( currentTime == restarttime - 360 ) {
        CPrintToChatAll("{lime}PTS{default} | {lightblue}Daily server restart in 5 minutes...");
        PrintToConsole(0, "Daily server restart in 5 minutes...");
    }
    //CHECK FOR 1 MINUTES
    if ( currentTime == restarttime - 60 ) {
        CPrintToChatAll("{lime}PTS{default} | {lightblue}Daily server restart in 1 minute...");
        PrintToConsole(0, "Daily server restart in 1 minute...");
    }
    //CHECK FOR 30 SECONDS
    if ( currentTime == restarttime - 30 ) {
        CPrintToChatAll("{lime}PTS{default} | {lightblue}Daily server restart in 30 seconds...");
        PrintToConsole(0, "Daily server restart in 30 seconds...");
    }
    //CHECK FOR 5 SECONDS
    if ( currentTime == restarttime - 5 ) {
        CPrintToChatAll("{lime}PTS{default} | {lightblue}Daily server restart in 5 seconds...");
        PrintToConsole(0, "Daily server restart in 5 seconds...");
    }
    //CHECK FOR 4 SECONDS
    if ( currentTime == restarttime - 4 ) {
        CPrintToChatAll("{lime}PTS{default} | {lightblue}Daily server restart in 4 seconds...");
        PrintToConsole(0, "Daily server restart in 4 seconds...");
    }
    //CHECK FOR 3 SECONDS
    if ( currentTime == restarttime - 3 ) {
        CPrintToChatAll("{lime}PTS{default} | {lightblue}Daily server restart in 3 seconds...");
        PrintToConsole(0, "Daily server restart in 3 seconds...");
    }
    //CHECK FOR 2 SECONDS
    if ( currentTime == restarttime - 2 ) {
        CPrintToChatAll("{lime}PTS{default} | {lightblue}Daily server restart in 2 seconds...");
        PrintToConsole(0, "Daily server restart in 2 seconds...");
    }
    //CHECK FOR 1 SECOND
    if ( currentTime == restarttime - 1 ) {
        CPrintToChatAll("{lime}PTS{default} | {lightblue}Daily server restart in 1 second...");
        PrintToConsole(0, "Daily server restart in 1 second...");
    }

    return Plugin_Continue;
}

public Action RestartServer(int args)
{
    if(GetClientCount() == 0)
        Restart(true);
    else
        Restart();

    return Plugin_Handled;
}

public Action StartofDay(int args)
{
    //WRITE TIMESTAMP TO UNIX TIMESTAMP FILES
    int SOD = GetTime();

    LogToFile(UNIX_CURRENTDAY_LOGFILE, "%d", SOD);

    return Plugin_Handled;
}

public int ConvertToSeconds(int value, int type)
{
    //TYPE
    //1 - MINUTES/SECONDS
    //2 - HOURS/MINUTES/SECONDS

    switch (type) {
        case 1: return ( ( (value / 100) * 60 ) + value % 100 );
        case 2: return ( ( (value / 10000) * 3600 ) + ( ((value % 10000)/100) * 60 ) + ( value % 100 ));
    }

    return -1;
}