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

    Format(sPath, sizeof sPath, "./%s", Path_SM);

    dl = OpenDirectory(sPath);
    while( dl.GetNext(fileName_Buffer, sizeof fileName_Buffer) )
    {
        ExplodeString(fileName_Buffer, ".", split_filename, sizeof split_filename[], sizeof split_filename);
        if ( StrContains(split_filename[1], "dem" , true) != -1 && StrContains(fileName_Buffer, "." , true) != -1) {
            LogToFile(LogFilePath, " | Deleting File %s", fileName_Buffer);
            Format(sPath, sizeof sPath, "%s/%s", Path_SM, fileName_Buffer);
            DeleteFile(sPath);
        }
    }

    return Plugin_Handled;
}