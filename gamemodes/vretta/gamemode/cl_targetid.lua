local font = "FRETTA_MEDIUM"

--[[
	Override this function to determine which player's target ids should be visible
	return to disable drawing!
]]
function GM:ShouldDrawTargetID( target, localplyTeam )

end

function GM:HUDDrawTargetID()
	local tr = util.GetPlayerTrace( LocalPlayer() )
	local trace = util.TraceLine( tr )
	if ( !trace.Hit ) then return end
	if ( !trace.HitNonWorld ) then return end
	
	local text = "ERROR"
	
	local pTeam = LocalPlayer():Team()

	if ( trace.Entity:IsPlayer() ) then
		if ( pTeam ~= TEAM_SPECTATOR ) then
			GAMEMODE:ShouldDrawTargetID( trace.Entity, pTeam )
		end
		
		text = trace.Entity:Nick()
	else
		return
	end
	
	surface.SetFont( font )
	local w, h = surface.GetTextSize( text )
	
	local MouseX, MouseY = gui.MousePos()
	
	if ( MouseX == 0 && MouseY == 0 ) then
	
		MouseX = ScrW() / 2
		MouseY = ScrH() / 2
	
	end
	
	local x = MouseX
	local y = MouseY
	
	x = x - w / 2
	y = y + 64
	
	local tColor = self:GetTeamColor( trace.Entity )
	
	draw.SimpleText( text, font, x + 1, y + 1, Color( 0, 0, 0, 120 ) )
	draw.SimpleText( text, font, x + 2, y + 2, Color( 0, 0, 0, 50 ) )
	draw.SimpleText( text, font, x, y, tColor )
end