AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include( "shared.lua" )

function GM:ProcessResultText( result, resulttext )
	if ( resulttext == nil ) then resulttext = "" end
	
	if ( result == TEAM_BARREL ) then
		BroadcastLua( "LocalPlayer():EmitSound( \"song_antlionguard_stinger1\" )" )
		
		resulttext = "The barrels wiped out all the humans!"
	end
	
	if ( result == TEAM_HUMAN ) then
		BroadcastLua( "LocalPlayer():EmitSound( \"song_credits_2\" )" )
		
		resulttext = "The humans survived the barrel attack!"
	end
	
	if ( result == -1 ) then
		resulttext = "Draw!"-- Shouldn't actually happen
	end
	
	PrintMessage( HUD_PRINTTALK, resulttext )
	
	return resulttext
end

-- Don't start until at least one player is in game
function GM:CanStartRound( iNum )
	local humans = team.NumPlayers( TEAM_HUMAN )
	
	if ( humans > 0 ) then return true end
	
	return false
end

function GM:ResetTeams( )
	for k, v in pairs( team.GetPlayers( TEAM_BARREL ) ) do
		GAMEMODE:PlayerJoinTeam( v, TEAM_HUMAN )-- Assigns player class already
	end
end

function GM:CheckRoundEnd()
	
	-- Do checks here!
	if ( !GAMEMODE:InRound() ) then return end
	
	if( team.NumPlayers( TEAM_HUMAN ) <= 0 and team.NumPlayers( TEAM_BARREL ) > 0 ) then
		GAMEMODE:RoundEndWithResult( TEAM_BARREL )
		
		GAMEMODE:ResetTeams()
	end
	
	timer.Create( "CheckRoundEnd", 1, 0, function() GAMEMODE:CheckRoundEnd() end )
	
end

function GM:RoundTimerEnd()
	
	if ( !GAMEMODE:InRound() ) then return end
	
	if( team.NumPlayers( TEAM_HUMAN ) >= 1 ) then 
		GAMEMODE:RoundEndWithResult( TEAM_HUMAN )
	else	
		GAMEMODE:RoundEndWithResult( -1 )
	end	
	
	GAMEMODE:ResetTeams()
	
end

function GM:PlayerSpawn( ply, transition )
	if ( transition ) then return end
	
	self.BaseClass:PlayerSpawn( ply, transition )
	
	if ( team.NumPlayers( TEAM_HUMAN ) > 1 and team.NumPlayers( TEAM_BARREL ) < 1 ) then
		local randomguy = table.Random( team.GetPlayers( TEAM_HUMAN ) )
		GAMEMODE:PlayerJoinTeam( randomguy, TEAM_BARREL )
		randomguy:KillSilent()
	end
	
end

function GM:PlayerCanJoinTeam( ply, teamid )
	if ( ply:Team() == TEAM_BARREL ) then
		ply:ChatPrint( "You can not leave us!" )
		return false
	end
	
	-- Returns the base gamemode's PlayerCanJoinTeam
	return self.BaseClass:PlayerCanJoinTeam( ply, teamid )
end