AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include( "shared.lua" )

-- Don't start until at least one player is in game
function GM:CanStartRound( iNum )
	local humans = team.NumPlayers( TEAM_HUMAN )
	
	if ( humans > 0 ) then return true end
	
	return false
end

function GM:OnRoundStart( num )
	UTIL_UnFreezeAllPlayers()
end

function GM:ResetTeams( )
	for k, v in pairs( team.GetPlayers( TEAM_BARREL ) ) do
		GAMEMODE:PlayerJoinTeam( v, TEAM_HUMAN )
		player_manager.SetPlayerClass( v, "Human" )
	end
end

function GM:CheckRoundEnd()
	
	// Do checks here!
	if ( !GAMEMODE:InRound() ) then return end
	
	if( team.NumPlayers( TEAM_HUMAN ) <= 0 and team.NumPlayers( TEAM_BARREL ) > 0 ) then
		PrintMessage( HUD_PRINTTALK, "The barrels wiped out all the humans!" )
		BroadcastLua( "LocalPlayer():EmitSound( \"song_antlionguard_stinger1\" )" )
		GAMEMODE:RoundEndWithResult( TEAM_BARREL )
		
		GAMEMODE:ResetTeams()
	end
	
	timer.Create( "CheckRoundEnd", 1, 0, function() GAMEMODE:CheckRoundEnd() end )
	
end

function GM:RoundTimerEnd()
	
	if ( !GAMEMODE:InRound() ) then return end
	
	if( team.NumPlayers( TEAM_HUMAN ) >= 1 ) then 
		PrintMessage( HUD_PRINTTALK, "The humans survived the barrel attack!" )
		BroadcastLua( "LocalPlayer():EmitSound( \"song_credits_2\" )" )
		GAMEMODE:RoundEndWithResult( TEAM_HUMAN )
	else
		PrintMessage( HUD_PRINTTALK, "Game draw" ) // this should never happen	
		GAMEMODE:RoundEndWithResult( ROUND_RESULT_DRAW )
	end	
	
	GAMEMODE:ResetTeams()
	
end


function GM:PlayerSpawn( ply )
	
	self.BaseClass:PlayerSpawn( ply )
	
	if ( team.NumPlayers( TEAM_HUMAN ) > 1 and team.NumPlayers( TEAM_BARREL ) < 1 ) then
		local randomguy = table.Random( team.GetPlayers( TEAM_HUMAN ) )
		--randomguy:SetTeam( TEAM_BARREL ) -- Don't ever use this function, this is used internally. Below will correctly assign the team without issues
		GAMEMODE:PlayerJoinTeam( randomguy, TEAM_BARREL )
		randomguy:KillSilent()
	end
	
end