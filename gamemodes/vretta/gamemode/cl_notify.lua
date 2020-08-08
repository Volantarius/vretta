
function GM:VoteNotification( ply, votesNeeded )
	if ( ply and IsValid(ply) ) then
		
		chat.AddText( team.GetColor( ply:Team() ), ply:Nick(), Color( 255, 255, 255 ), " voted to change the gamemode", Color( 0, 220, 0 ), " (need "..votesNeeded.." more)" )
		
		chat.PlaySound()
		
		if ( votesNeeded == 0 ) then
			chat.AddText( Color( 255, 255, 255 ), "Starting gamemode vote in 10 seconds!" )
		end
		
	end
end

net.Receive( "fretta_votenotify", function( um )
	if ( GAMEMODE ) then
		GAMEMODE:VoteNotification( net.ReadEntity(), net.ReadUInt(16) )
	end
end )

function GM:TeamChangeNotification( ply, oldteam, newteam )
	if( ply && ply:IsValid() ) then
		local nick = ply:Nick()
		
		if ( LocalPlayer() == ply and nick == "unconnected" ) then return end
		
		local oldTeamColor = team.GetColor( oldteam )
		local newTeamName = team.GetName( newteam )
		local newTeamColor = team.GetColor( newteam )
		
		if( newteam == TEAM_SPECTATOR ) then
			chat.AddText( oldTeamColor, nick, color_white, " is now spectating" ) 
		else
			chat.AddText( oldTeamColor, nick, color_white, " joined ", newTeamColor, newTeamName )
		end
		
		chat.PlaySound()
	end
end

net.Receive( "fretta_teamchange", function( um )
	if ( GAMEMODE ) then
		GAMEMODE:TeamChangeNotification( net.ReadEntity(), net.ReadUInt(16), net.ReadUInt(16) )
	end
end )
