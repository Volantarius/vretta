
-- This looks like it was never used so we'll put the new gamemode vote notification here!
--[[local function CreateLeftNotify()

	local x, y = chat.GetChatBoxPos()

	g_LeftNotify = vgui.Create( "DNotify" )

	g_LeftNotify:SetPos( 32, 0 )
	g_LeftNotify:SetSize( ScrW(), y - 8 )
	g_LeftNotify:SetAlignment( 1 )
	g_LeftNotify:ParentToHUD()

end

hook.Add( "InitPostEntity", "CreateLeftNotify", CreateLeftNotify )

function GM:NotifyGMVote( name, gamemode, votesneeded )

	local dl = vgui.Create( "DLabel" )
	dl:SetFont( "FRETTA_MEDIUM_SHADOW" )
	dl:SetTextColor( Color( 255, 255, 255, 255 ) )
	dl:SetText( Format( "%s voted for %s (need %i more)", name, gamemode, votesneeded ) )
	dl:SizeToContents()
	g_LeftNotify:AddItem( dl, 5 )

end]]

function GM:VoteNotification( ply, votesNeeded )
	if ( ply and IsValid(ply) ) then
		
		local NeedTxt = "" 
		
		if ( votesNeeded > 0 ) then NeedTxt = " (need "..votesNeeded.." more)" end
		
		chat.AddText( team.GetColor( ply:Team() ), ply:Nick(), Color( 255, 255, 255 ), " voted to change the gamemode", Color( 80, 255, 50 ), NeedTxt )
		
		chat.PlaySound( "buttons/button15.wav" ) -- TODO: Make this use surface.playSound for more obnoxious tick sounds
		
	end
end

net.Receive( "fretta_votenotify", function( um )
	if ( GAMEMODE ) then
		GAMEMODE:VoteNotification( net.ReadEntity(), net.ReadUInt(16) )
	end
end )
