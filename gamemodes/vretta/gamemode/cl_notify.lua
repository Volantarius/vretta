
function GM:VoteNotification( ply, votesNeeded )
	if ( ply and IsValid(ply) ) then
		
		local NeedTxt = "" 
		
		if ( votesNeeded > 0 ) then NeedTxt = " (need "..votesNeeded.." more)" end
		
		chat.AddText( team.GetColor( ply:Team() ), ply:Nick(), Color( 255, 255, 255 ), " voted to change the gamemode", Color( 80, 255, 50 ), NeedTxt )
		
		chat.PlaySound()
		
	end
end

net.Receive( "fretta_votenotify", function( um )
	if ( GAMEMODE ) then
		GAMEMODE:VoteNotification( net.ReadEntity(), net.ReadUInt(16) )
	end
end )
