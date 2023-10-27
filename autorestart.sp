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
ConVar AnnounceTimes;
File SOD_UnixStamps;
ArrayList AnnounceTimes_List_Seconds;
ArrayList AnnounceTimes_List_Unconverted;

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
    AnnounceTimes = AutoExecConfig_CreateConVar("sm_announce_times", "5M/1M/30S/5S/4S/3S/2S/1S", "when to announce remaining time for restart");

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

    AnnounceTimes_List_Unconverted = new ArrayList(8);
    AnnounceTimes_List_Seconds = new ArrayList(8);
}

public void OnConfigsExecuted()
{
    SetupAnnouncementTimes();

    CreateTimer(1.0, TimeCheck, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

void SetupAnnouncementTimes()
{
    //GET STRING FROM CFG
    char UnfilteredAnnounceTimes[256];
    AnnounceTimes.GetString(UnfilteredAnnounceTimes, sizeof UnfilteredAnnounceTimes);

    //ALLOW 15 MAX ANNOUNCE TIMES
    char UnfilteredAnnounceTimes_ExplodedString[15][8];
    ExplodeString(UnfilteredAnnounceTimes, "/", UnfilteredAnnounceTimes_ExplodedString, sizeof UnfilteredAnnounceTimes_ExplodedString, sizeof UnfilteredAnnounceTimes_ExplodedString[]);

    //TRANSFORM SPLIT STRINGS INTO ARRAYLIST AND FILTER DUPLICATES
    for(int i = 0; i < 15; i++) {
        if ( strcmp(UnfilteredAnnounceTimes[i], "", false) == 0 )
            break;

        //IF THE VALUES IS NEW ADD IT
        if ( AnnounceTimes_List_Unconverted.FindString(UnfilteredAnnounceTimes_ExplodedString[i]) == -1) {
            AnnounceTimes_List_Unconverted.PushString(UnfilteredAnnounceTimes_ExplodedString[i]);
        }
    }

    //CONVERT ALL TIMES TO SECONDS
    char temp_string[8];
    char last_char;
    for(int i = 0; i < AnnounceTimes_List_Unconverted.Length; i++)
    {
        AnnounceTimes_List_Unconverted.GetString(i, temp_string, sizeof temp_string);

        if ( strcmp(temp_string, "", false) == 0 )
            break;

        //REMOVE LAST CHAR
        last_char = temp_string[strlen(temp_string) - 1];
        ReplaceString(temp_string, sizeof temp_string, temp_string[strlen(temp_string) - 1], "", false);

        //CONVERT TIME TO SECONDS & ONLY ADD IF NOT DUPLICATE
        if ( AnnounceTimes_List_Seconds.FindValue(StringToInt(temp_string)) == -1) {
            AnnounceTimes_List_Seconds.Push(ConvertAnnounceTimesToSeconds(StringToInt(temp_string), last_char));
        }
    }

}

void AnnounceTime(int current_time, int restart_time)
{
    int time_diff = restart_time - current_time;
    if ( AnnounceTimes_List_Seconds.FindValue(time_diff) != -1 ) {
        CPrintToChatAll("{lime}PTS{default} | {lightblue}Daily server restart in %s", FormattedTime(time_diff));
        PrintToConsole(0, "Daily server restart in %s", FormattedTime(time_diff));
    }
}

void Restart(bool hibernating = false)
{
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
    int SOD = GetTime();

    //REMOVE EXTRA TIME FORM THE SOD TIMESTAMP
    SOD -= ( SOD  % 10 );

    if( ScheduleTimeStamp.IntValue == 0 ) {
        LogToFile(UNIX_CURRENTDAY_LOGFILE, "%d", SOD);
    }

    ServerCommand("_restart");
}

public Action TimeCheck(Handle timer, any data)
{
    //GetTime() RETURNS TIMESTAMP IN UNIX (SECONDS)
    int currentTime = GetTime();

    //GET RESTART TIME
    int restarttime = ScheduleTimeStamp.IntValue;

    //CALCULATE THE VALUE OF THE UNIX TIMESTAMP OF THE FUTURE RESTART BASED ON THE UNIX TIMESTAMP OF THE BEGINNING OF THE CURRENT DAY
    if ( restarttime <= 5960 ) {
        restarttime = StringToInt(sSOD_UnixTimestamp) + ConvertToSeconds(restarttime, 1);
    }
    else {
        restarttime = StringToInt(sSOD_UnixTimestamp) + ConvertToSeconds(restarttime, 2);
    }

    //RESTART IF TIMES ALIGN
    if ( currentTime == restarttime )
        Restart();

    AnnounceTime(currentTime, restarttime);

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

    //REMOVE EXTRA TIME FORM THE SOD TIMESTAMP
    SOD -= ( SOD  % 10 );

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

public int ConvertAnnounceTimesToSeconds(int value, int type)
{
    switch ( type ) {
        case 'D':
            return value * 86400 ;
        case 'H':
            return value * 3600 ;
        case 'M':
            return value * 60 ;
        case 'S':
            return value;
        default:
            return value;
    }
}

char[] FormattedTime(int time)
{
    char final_string[32];

    char szDays[16];
    char szHours[16];
    char szMinutes[16];
    char szSeconds[16];

    int days = time / 86400;
    int hours = (time - (days * 86400)) / 3600;
    int minutes = (time - (days * 86400) - (hours * 3600)) / 60;
    int seconds = (time - (days * 86400) - (hours * 3600) - (minutes * 60));

    //DAYS
    if ( days == 0 )
        Format(szDays, 16, "0");
    else if ( days > 1 )
        Format(szDays, 16, "%d Days", days);
    else if ( days == 1 )
        Format(szDays, 16, "%d Day", days);

    //HOURS
    if ( hours == 0 )
        Format(szHours, 16, "0");
    if ( hours > 1 )
        Format(szHours, 16, "%d Hours", hours);
    else if ( hours == 1 )
        Format(szHours, 16, "%d Hour", hours);

    //MINUTES
    if ( minutes == 0 )
        Format(szMinutes, 16, "0");
    if ( minutes > 1 )
        Format(szMinutes, 16, "%d Minutes", minutes);
    else if ( minutes == 1 )
        Format(szMinutes, 16, "%d Minute", minutes);

    //SECONDS
    if ( seconds == 0 )
        Format(szSeconds, 16, "0");
    if ( seconds > 1 )
        Format(szSeconds, 16, "%d Seconds", seconds);
    else if ( seconds == 1 )
        Format(szSeconds, 16, "%d Second", seconds);

    if (days > 0) {
        Format(final_string, sizeof final_string, "%s", szDays);
        if ( hours > 0 )
            Format(final_string, sizeof final_string, "%s %s...", szDays, szHours);
        if ( minutes > 0 )
            Format(final_string, sizeof final_string, "%s %s %s...", szDays, szHours, szMinutes);
        if ( seconds > 0 )
            Format(final_string, sizeof final_string, "%s %s %d %s", szDays, szHours, szMinutes, szSeconds);
    }
    else if (hours > 0) {
        Format(final_string, sizeof final_string, "%s...", szHours);
        if ( minutes > 0 )
            Format(final_string, sizeof final_string, "%s %s...", szHours, szMinutes);
        if( seconds > 0 )
            Format(final_string, sizeof final_string, "%s %s %s...", szHours, szMinutes, szSeconds);
    }
    else if ( minutes > 0 ) {
        Format(final_string, sizeof final_string, "%s...", szMinutes);
        if( seconds > 0 )
            Format(final_string, sizeof final_string, "%s %s...", szMinutes, szSeconds);
    }
    else {
        Format(final_string, sizeof final_string, "%s...", szSeconds);
    }

    ReplaceString(final_string, sizeof final_string, " 0 ", " ", false);

    return final_string;
}