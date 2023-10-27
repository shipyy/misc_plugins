public Plugin myinfo =
{
	name        = "remainingtime",
	author      = "shipy",
	description = "prints to all clients time to a certain epoch timestamp",
	version     = "0.0.1",
	url         = "https://github.com/shipyy/misc_plugins"
};

#pragma newdecls required
#pragma semicolon 1
#include <sourcemod>
#include <multicolors>

public void OnMapStart()
{
    //CREATE TIMER FOR QUALIFIERS REMAINING TIME
    //FINAL DATE IN EPOCH TIME (SECONDS) == 1698710400
    CreateTimer(300.0, QualifiersRemainingTime, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
}

public Action QualifiersRemainingTime(Handle timer)
{
    int remaining_time = 1698710400 - GetTime();
    char szRemainingTimeFormatted[32];
    FormatTimeFloat(0, remaining_time * 1.0, szRemainingTimeFormatted, sizeof szRemainingTimeFormatted);

    char szFinal[128];
    Format(szFinal, sizeof szFinal, "{lime}Torneio | {yellow}%s{darkred} para o qualificador acabar!", szRemainingTimeFormatted);

    CPrintToChatAll("%s", szFinal);

    return Plugin_Handled;
}

public void FormatTimeFloat(int client, float time, char[] string, int length)
{
    char szDays[16];
    char szHours[16];
    char szMinutes[16];
    char szSeconds[16];

    int time_rounded = RoundToZero(time);

    int days = time_rounded / 86400;
    int hours = (time_rounded - (days * 86400)) / 3600;
    int minutes = (time_rounded - (days * 86400) - (hours * 3600)) / 60;
    int seconds = (time_rounded - (days * 86400) - (hours * 3600) - (minutes * 60));

    // 00:00:00:00
    // 00:00:00
    // 00:00

    //SECONDS
    if (seconds < 10)
        Format(szSeconds, 16, "0%d", seconds);
    else
        Format(szSeconds, 16, "%d", seconds);

    //MINUTES
    if (minutes < 10)
        Format(szMinutes, 16, "0%d", minutes);
    else
        Format(szMinutes, 16, "%d", minutes);

    //HOURS
    if (hours < 10)
        Format(szHours, 16, "0%d", hours);
    else
        Format(szHours, 16, "%d", hours);

    //DAYS
    Format(szDays, 16, "%d", days);

    if (days > 0) {
        Format(string, length, "%sd %sh %sm %ss", szDays, szHours, szMinutes, szSeconds);
    }
    else {
        if (hours > 0) {
            Format(string, length, "%sh %sm %ss", szHours, szMinutes, szSeconds);
        }
        else {
            Format(string, length, "%sm %ss", szMinutes, szSeconds);
        }
    }
}