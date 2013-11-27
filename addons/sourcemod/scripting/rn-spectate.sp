/*
 * rn-spectate: Redneck's spectate/join commands in chat
 * Copyright (c) 2012, 2013  [foo] bar <foobarhl@gmail.com> | http://steamcommunity.com/id/foo-bar/
 * Contains code inspired by Bacardi (http://forums.alliedmods.net/showpost.php?p=1444036&postcount=7)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */


#include <sourcemod>
#include <smlib>

#define VERSION "0.5"

#define TEAM_WHOKNOWS	0
#define TEAM_SPECTATOR	1
#define TEAM_COMBINE	2
#define TEAM_REBELS	3

public Plugin:myinfo = {
	name = "RN-Spectate",
	author = "[foo] bar",
	description = "Chat spectate/jointeam commands and spectate limiting",
	version = VERSION,
	url = "https://github.com/foobarhl/rn_spectate",
};

new Handle:movespec[MAXPLAYERS] = INVALID_HANDLE;
new Handle:sm_movespec_delay = INVALID_HANDLE;
new Float:movespec_delay;

public OnPluginStart()
{
	CreateConVar("rn_spectate_version", VERSION, "Version of this mod", FCVAR_DONTRECORD|FCVAR_PLUGIN|FCVAR_NOTIFY);
	SetConVarString( FindConVar("rn_spectate_version"), VERSION);

	sm_movespec_delay = CreateConVar("sm_movespec_delay", "5.0", "Delay player to move spectators when alive in seconds", FCVAR_NONE, true, 0.0, true, 10.0);
	movespec_delay = GetConVarFloat(sm_movespec_delay);
	HookConVarChange(sm_movespec_delay, ConVarChanged);

	AutoExecConfig();

	AddCommandListener(PlayerSay,"say");
	AddCommandListener(PlayerSay,"say_team");
	AddCommandListener(ConsoleJoin, "jointeam");
	AddCommandListener(ConsoleJoin, "spectate");
}

public ConVarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
    if(convar == sm_movespec_delay)
    {
        movespec_delay = StringToFloat(newValue);
    }
}

public Action:PlayerSay(client, const String:cmd[], argc)
{
	if(!IsClientInGame(client))
		return Plugin_Continue;

	decl String:chattxt[192];
	if(GetCmdArgString(chattxt,sizeof(chattxt))<1){
		return(Plugin_Continue);
	}

	new startidx = 0;
	if(chattxt[strlen(chattxt)-1] == '"'){
		chattxt[strlen(chattxt)-1]='\0';
		startidx=1;
	}
	if(strcmp(cmd,"say2",false)==0){
		startidx+=4;
	}

	if(strcmp(chattxt[startidx],"join",false)==0){
		if(GetTeamClientCount(2) > GetTeamClientCount(3)){
			FakeClientCommandEx(client,"jointeam %d", TEAM_REBELS);
		} else {
			FakeClientCommandEx(client,"jointeam %d", TEAM_COMBINE);
		}
	} else if(strcmp(chattxt[startidx],"joinrebel",false)==0){
		FakeClientCommandEx(client,"jointeam %d", TEAM_REBELS);
	} else if(strcmp(chattxt[startidx],"joincombine",false)==0){
		FakeClientCommandEx(client,"jointeam %d", TEAM_COMBINE);
	} else if(strcmp(chattxt[startidx],"spectate",false)==0){
		spectate(client);
	}

	return(Plugin_Continue);
}

// based on http://forums.alliedmods.net/showpost.php?p=1444036&postcount=7 from Bacardi
public Action:ConsoleJoin(client, const String:command[], argc)
{
	if(!IsClientInGame(client))
		return Plugin_Handled;

	if(argc>=1 && StrEqual(command, "jointeam")){
		new String:arg[3];
		GetCmdArg(1, arg, sizeof(arg));
		if(StringToInt(arg)==TEAM_SPECTATOR){
			spectate(client);
			return Plugin_Handled;
		} else {
			return Plugin_Continue;
		}
	} else if(StrEqual(command, "spectate")){
		spectate(client);
		return Plugin_Handled;

	}
	return Plugin_Continue;
}

spectate(client)
{
	if(!IsClientConnected(client) || !IsClientInGame(client))
		return;

	if(movespec_delay > 1.0 && GetClientTeam(client) != TEAM_SPECTATOR && IsPlayerAlive(client)) { 
		if(movespec[client] == INVALID_HANDLE) { 
			movespec[client] = CreateTimer(movespec_delay, TimerMoveSpec, client);
			movespec_delay > 2.0 ? Client_PrintToChat(client, true, "[{G}Spectator{N}] You will be moved to spectate within %0.1f seconds", movespec_delay):0;
			return;
		}
	} else {
		ChangeClientTeam(client, TEAM_SPECTATOR);	// In HL2MP ChangeClientTeam seems to ONLY work for TEAM_SPECTATOR. 
	}
}


public Action:TimerMoveSpec(Handle:timer, any:client)
{
    if(IsClientInGame(client))
    {
        ChangeClientTeam(client, TEAM_SPECTATOR);
	Client_PrintToChat(client, true, "[{G}Spectator{N}] Type '{G}join{N}', '{G}joinrebel{N}', or '{G}joincombine{N}' to come back");
    }
    movespec[client] = INVALID_HANDLE;
}

public Action:PlayerDisconnect(Handle:event, const String:name[], bool:dontBroadcast)
{
    decl client;
    client = GetClientOfUserId(GetEventInt(event, "userid"));
    if(movespec[client] != INVALID_HANDLE)
    {
        KillTimer(movespec[client]);
        movespec[client] = INVALID_HANDLE;
    }
}  
