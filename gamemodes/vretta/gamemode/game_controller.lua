--[[
	NOT FINISHED, this is newly added for non round based games.
	Not completely finished but here as a template!
]]
function GM:SetInGame( b ) SetGlobalBool( "InGameSingle", b ) end
function GM:InGame() return GetGlobalBool( "InGameSingle", false ) end

-- Check if we can start or continue to wait
function GM:CanStartSingleGame()
	return true
end

function GM:StartSingleGame()
	GAMEMODE:PreSingleStart()
end

-- Use this to add game start stuff, don't override SingleStart
function GM:OnSingleStart()
	UTIL_UnFreezeAllPlayers()
end

function GM:SingleStart()
	GAMEMODE:OnSingleStart()
end

function GM:PreSingleStart()
	
	if( CurTime() >= GAMEMODE.GetTimeLimit() ) then
		GAMEMODE:EndOfGame( true )
		return
	end
	
	if ( !GAMEMODE:CanStartSingleGame() ) then
		
		timer.Simple( 1, function() GAMEMODE:PreSingleStart() end ) -- In a second, check to see if we can start
		return
		
	end
	
	timer.Simple( GAMEMODE.RoundPreStartTime, function() GAMEMODE:SingleStart() end )
	
	GAMEMODE:ClearRoundResult()
	GAMEMODE:OnPreRoundStart( 1 )
	GAMEMODE:SetInRound( true )
	GAMEMODE:SetInGame( true )
end

