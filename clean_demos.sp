public Plugin myinfo =
{
	name = "clean_demos",
	author = "shipy",
	description = "remove demos within a certain time span when the cmd is ran",
	version = "0.0.1",
	url = "https://github.com/shipyy/misc_plugins",
}

#pragma semicolon 1
#include <sourcemod>
#include <colorlib>

char LogFilePath[PLATFORM_MAX_PATH];

public void OnPluginStart()
{
    if (!DirExists("addons/sourcemod/logs/clean_demos"))
        CreateDirectory("addons/sourcemod/logs/clean_demos", 511);
    BuildPath(Path_SM, LogFilePath, sizeof(LogFilePath), "logs/clean_demos/cleandemos.log");

    RegServerCmd("sm_clean_demos", CleanDemos, "[CleanDemos] Deletes .dem files");

}

public Action CleanDemos(int args)
{
    DirectoryListing dl;
    char sPath[128];
    char fileName_Buffer[256];
    char split_filename[256][2];
    char currentTime_formatted[32];

    //LOG START
    FormatTime(currentTime_formatted, sizeof currentTime_formatted, "%d/%m/%G %H:%M:%S", GetTime());
    LogToFile(LogFilePath, "| Began Deleting Demos | %s", currentTime_formatted);

    //RELATIVE PATH TO SOURCEMOD FOLDER
    Format(sPath, sizeof sPath, "./%s", Path_SM);
    dl = OpenDirectory(sPath);
    while( dl.GetNext(fileName_Buffer, sizeof fileName_Buffer) )
    {
        //SPLIT FILE EXTENSION
        ExplodeString(fileName_Buffer, ".", split_filename, sizeof split_filename[], sizeof split_filename);
        //FITLER .DEM FILES
        if ( StrContains(split_filename[1], "dem" , true) != -1 && StrContains(fileName_Buffer, "." , true) != -1)
        {
            //LOG EACH FILE
            LogToFile(LogFilePath, "| '%s'", fileName_Buffer);
            Format(sPath, sizeof sPath, "%s/%s", Path_SM, fileName_Buffer);
            DeleteFile(sPath);
        }
    }

    //LOG END
    FormatTime(currentTime_formatted, sizeof currentTime_formatted, "%d/%m/%G %H:%M:%S", GetTime());
    LogToFile(LogFilePath, "| Ended Deleting Demos | %s", currentTime_formatted);

    return Plugin_Handled;
}