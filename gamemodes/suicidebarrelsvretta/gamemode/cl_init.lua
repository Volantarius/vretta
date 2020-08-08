include( 'shared.lua' )

-- Only show id's from same teams
-- Vretta only function!
function GM:ShouldDrawTargetID( target, localplyTeam )
	if ( target:Team() ~= localplyTeam ) then
		return
	end
end