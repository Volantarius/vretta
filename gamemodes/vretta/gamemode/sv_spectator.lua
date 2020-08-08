-- table.FindNext could get removed so heres a similar thing
local function tableFindNext( tbl, cValue )
	
	local cInd = -1
	
	if ( cValue ) then
		for k, v in ipairs( tbl ) do
			
			if ( v == cValue ) then
				if ( k == #tbl ) then
					cInd = 1
					return tbl[cInd]
				else
					cInd = k + 1
					return tbl[cInd]
				end
			end
			
		end
	else
		return tbl[1]
	end
	
	return tbl[1]
	
end

--[[---------------------------------------------------------
   Name: gamemode:GetValidSpectatorModes( Player ply )
   Desc: Gets a table of the allowed spectator modes (OBS_MODE_INEYE, etc)
		 Player is the player object of the spectator
---------------------------------------------------------]]
function GM:GetValidSpectatorModes( ply )

	-- Note: Override this and return valid modes per player/team

	return GAMEMODE.ValidSpectatorModes

end

--[[---------------------------------------------------------
   Name: gamemode:GetValidSpectatorEntityNames( Player ply )
   Desc: Returns a table of entities that can be spectated (player etc)
---------------------------------------------------------]]
function GM:GetValidSpectatorEntityNames( ply )

	-- Note: Override this and return valid entity names per player/team

	return GAMEMODE.ValidSpectatorEntities

end

--[[---------------------------------------------------------
   Name: gamemode:IsValidSpectator( Player ply )
   Desc: Is our player spectating - and valid?
---------------------------------------------------------]]
function GM:IsValidSpectator( pl )

	if ( !IsValid( pl ) ) then return false end
	if ( pl:Team() != TEAM_SPECTATOR && !pl:IsObserver() ) then return false end
	
	return true

end

--[[---------------------------------------------------------
   Name: gamemode:IsValidSpectatorTarget( Player pl, Entity ent )
   Desc: Checks to make sure a spectated entity is valid.
		 By default, you can change GM.CanOnlySpectate own team if you want to
		 prevent players from spectating the other team.
---------------------------------------------------------]]
function GM:IsValidSpectatorTarget( pl, ent )
	
	if ( !IsValid( ent ) ) then return false end
	if ( ent == pl ) then return false end
	--if ( !table.HasValue( GAMEMODE:GetValidSpectatorEntityNames( pl ), ent:GetClass() ) ) then return false end
	if ( ent:IsPlayer() && !ent:Alive() ) then return false end
	if ( ent:IsPlayer() && ent:IsObserver() ) then return false end
	if ( pl:Team() != TEAM_SPECTATOR && ent:IsPlayer() && GAMEMODE.CanOnlySpectateOwnTeam && pl:Team() != ent:Team() ) then return false end
	
	return true
end

--[[---------------------------------------------------------
   Name: gamemode:GetSpectatorTargets( Player pl )
   Desc: Returns a table of entities the player can spectate.
---------------------------------------------------------]]
function GM:GetSpectatorTargets( pl )

	local t = {}
	for k, v in ipairs( GAMEMODE:GetValidSpectatorEntityNames( pl ) ) do
		t = table.Merge( t, ents.FindByClass( v ) )
	end
	
	return t

end

--[[---------------------------------------------------------
   Name: gamemode:StartEntitySpectate( Player pl )
   Desc: Called when we start spectating.
---------------------------------------------------------]]
function GM:StartEntitySpectate( pl )

	local CurrentSpectateEntity = pl:GetObserverTarget()
	
	if ( GAMEMODE:IsValidSpectatorTarget( pl, CurrentSpectateEntity ) ) then
		pl:SpectateEntity( CurrentSpectateEntity )
		return
	end
	
	local targets = GAMEMODE:GetSpectatorTargets( pl )
	
	if ( ( #targets == 1 and table.HasValue(targets, pl) ) or #targets == 0 ) then
		GAMEMODE:ChangeObserverMode( pl, OBS_MODE_ROAMING )
		return
	end
	
	local randomInd = 0
	local found = false
	
	for i=1, #targets do
		
		randomInd = math.random( 1, #targets - i - 1 )
		
		if ( GAMEMODE:IsValidSpectatorTarget( pl, targets[randomInd] ) ) then
			pl:SpectateEntity( targets[randomInd] )
			found = true
			return
		end
		
		table.remove( targets, randomInd )
		
	end
	
	if ( not found ) then
		GAMEMODE:ChangeObserverMode( pl, OBS_MODE_ROAMING )
	end
	
end

--[[---------------------------------------------------------
   Name: gamemode:NextEntitySpectate( Player pl )
   Desc: Called when we want to spec the next entity.
---------------------------------------------------------]]
function GM:NextEntitySpectate( pl )

	local cTarget = pl:GetObserverTarget()
	
	local targets = GAMEMODE:GetSpectatorTargets( pl )
	
	if ( ( #targets == 1 and table.HasValue(targets, pl) ) or #targets == 0 ) then
		GAMEMODE:ChangeObserverMode( pl, OBS_MODE_ROAMING )
		return
	end
	
	local found = false
	local cIndex = -1
	
	for k, v in ipairs(targets) do
		
		if ( cIndex ~= -1 and GAMEMODE:IsValidSpectatorTarget( pl, targets[k] ) ) then
			pl:SpectateEntity( targets[k] )
			found = true
			return
		end
		
		if ( v == cTarget ) then
			cIndex = k
		end
		
	end
	
	if ( not found ) then
		
		for i=1, cIndex do
			
			if ( GAMEMODE:IsValidSpectatorTarget( pl, targets[i] ) ) then
				pl:SpectateEntity( targets[i] )
				found = true
				return
			end
			
		end
		
	end
	
	if ( not found ) then
		GAMEMODE:ChangeObserverMode( pl, OBS_MODE_ROAMING )
	end
	
end

--[[---------------------------------------------------------
   Name: gamemode:PrevEntitySpectate( Player pl )
   Desc: Called when we want to spec the previous entity.
---------------------------------------------------------]]
function GM:PrevEntitySpectate( pl )

	local cTarget = pl:GetObserverTarget()
	
	local targets = GAMEMODE:GetSpectatorTargets( pl )
	
	if ( ( #targets == 1 and table.HasValue(targets, pl) ) or #targets == 0 ) then
		GAMEMODE:ChangeObserverMode( pl, OBS_MODE_ROAMING )
		return
	end
	
	local found = false
	local cIndex = -1
	
	for k=#targets, 1, -1 do
		
		if ( cIndex ~= -1 and GAMEMODE:IsValidSpectatorTarget( pl, targets[k] ) ) then
			pl:SpectateEntity( targets[k] )
			found = true
			return
		end
		
		if ( targets[k] == cTarget ) then
			cIndex = k
		end
		
	end
	
	if ( cIndex == 1 ) then
		cIndex = #targets
	end
	
	if ( not found ) then
		
		for i=cIndex, 1, -1 do
			
			if ( GAMEMODE:IsValidSpectatorTarget( pl, targets[i] ) ) then
				pl:SpectateEntity( targets[i] )
				found = true
				return
			end
			
		end
		
	end
	
	if ( not found ) then
		GAMEMODE:ChangeObserverMode( pl, OBS_MODE_ROAMING )
	end

end

--[[---------------------------------------------------------
   Name: gamemode:ChangeObserverMode( Player pl, Number mode )
   Desc: Change the observer mode of a player.
---------------------------------------------------------]]
function GM:ChangeObserverMode( pl, mode )
	
	local modeCl = pl:GetInfoNum( "cl_spec_mode", OBS_MODE_ROAMING )
	
	-- If mode is -1 we will use the player's spec mode
	if ( mode < 1 or mode > OBS_MODE_ROAMING or mode == nil ) then
		mode = math.Clamp( modeCl, OBS_MODE_FIXED, OBS_MODE_ROAMING )
	end
	
	if ( modeCl ~= mode ) then
		pl:ConCommand( "cl_spec_mode "..mode )
	end
	
	if ( mode == OBS_MODE_IN_EYE || mode == OBS_MODE_CHASE ) then
		GAMEMODE:StartEntitySpectate( pl, mode )
	end
	
	pl:Spectate( mode )
	pl:SpectateEntity( nil )
	
end

--[[---------------------------------------------------------
   Name: gamemode:BecomeObserver( Player pl )
   Desc: Called when we first become a spectator.
---------------------------------------------------------]]
function GM:BecomeObserver( pl )
	
	local mode = pl:GetInfoNum( "cl_spec_mode", OBS_MODE_CHASE )
	
	local modes = GAMEMODE:GetValidSpectatorModes( pl )
	
	if ( !table.HasValue( modes, mode ) ) then
		mode = tableFindNext( modes, mode ) -- Will get the first valid spectator mode
	end
	
	GAMEMODE:ChangeObserverMode( pl, mode )

end

local function spec_mode( pl, cmd, args )
	
	if ( !GAMEMODE:IsValidSpectator( pl ) ) then return end
	
	local mode = pl:GetObserverMode()
	local modes = GAMEMODE:GetValidSpectatorModes( pl )
	
	if ( !table.HasValue( modes, mode ) ) then
		GAMEMODE:ChangeObserverMode( pl, -1 ) -- Return to player's chosen spec mode
		return
	end
	
	local nextmode = tableFindNext( modes, mode )
	
	GAMEMODE:ChangeObserverMode( pl, nextmode )
	
end

concommand.Add( "spec_mode",  spec_mode )

local function spec_next( pl, cmd, args )
	
	local mode = pl:GetObserverMode()
	
	if ( !GAMEMODE:IsValidSpectator( pl ) ) then return end
	
	if ( !table.HasValue( GAMEMODE:GetValidSpectatorModes( pl ), mode ) ) then
		GAMEMODE:ChangeObserverMode( pl, -1 ) -- Return to player's chosen spec mode
		return
	end
	
	GAMEMODE:NextEntitySpectate( pl )

end

concommand.Add( "spec_next",  spec_next )

local function spec_prev( pl, cmd, args )
	
	local mode = pl:GetObserverMode()
	
	if ( !GAMEMODE:IsValidSpectator( pl ) ) then return end
	
	if ( !table.HasValue( GAMEMODE:GetValidSpectatorModes( pl ), mode ) ) then
		GAMEMODE:ChangeObserverMode( pl, -1 ) -- Return to player's chosen spec mode
		return
	end
	
	GAMEMODE:PrevEntitySpectate( pl )

end

concommand.Add( "spec_prev",  spec_prev )