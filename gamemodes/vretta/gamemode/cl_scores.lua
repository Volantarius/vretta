
include( "vgui/vgui_scoreboard.lua" )


function GM:GetScoreboard()

	if ( IsValid( g_ScoreBoard ) ) then
		g_ScoreBoard:Remove()
	end
	
	g_ScoreBoard = vgui.Create( "FrettaScoreboard" )
	self:CreateScoreboard( g_ScoreBoard )
	
	return g_ScoreBoard
	
end

function GM:ScoreboardShow()
	
	-- This sets the scoreboard to be VISIBLE
	
	GAMEMODE:GetScoreboard():SetVisible( true )
	GAMEMODE:PositionScoreboard( GAMEMODE:GetScoreboard() )
	
end

function GM:ScoreboardHide()
	
	-- This sets the scoreboard to be NOT visible
	GAMEMODE:GetScoreboard():SetVisible( false )
	
end

function GM:AddScoreboardAvatar( ScoreBoard )

	local f = function( ply ) 	
		local av = vgui.Create( "AvatarImage", ScoreBoard )
			av:SetSize( 32, 32 )
			av:SetPlayer( ply )
			return av
	end
	
	ScoreBoard:AddColumn( "", 32, f, 360 ) -- Avatar

end

function GM:AddScoreboardSpacer( ScoreBoard, iSize )
	ScoreBoard:AddColumn( "", 16 ) -- Gap
end

function GM:AddScoreboardName( ScoreBoard )

	local f = function( ply ) return ply:Name() end
	ScoreBoard:AddColumn( "Name", nil, f, 10, nil, 4, 4 )

end

function GM:AddScoreboardKills( ScoreBoard )

	local f = function( ply ) return ply:Frags() end
	ScoreBoard:AddColumn( "Kills", 80, f, 0.5, nil, 6, 6 )

end

function GM:AddScoreboardDeaths( ScoreBoard )

	local f = function( ply ) return ply:Deaths() end
	ScoreBoard:AddColumn( "Deaths", 80, f, 0.5, nil, 6, 6 )

end

function GM:AddScoreboardPing( ScoreBoard )

	local f = function( ply ) return ply:Ping() end
	ScoreBoard:AddColumn( "Ping", 80, f, 0.1, nil, 6, 6 )

end

function GM:AddScoreboardMute( ScoreBoard )

	local f = function( ply ) 	
		local muter = vgui.Create( "DImageButton", ScoreBoard )
			muter:SetSize( 32, 32 )
			
			if ( ply:IsMuted() ) then
				muter:SetImage( "icon32/muted.png" )
			else
				muter:SetImage( "icon32/unmuted.png" )
			end
			
			muter.DoClick = function()
				local muted = ply:IsMuted()

				ply:SetMuted( not muted )

				if ( not muted ) then
					muter:SetImage( "icon32/muted.png" )
				else
					muter:SetImage( "icon32/unmuted.png" )
				end
			end
			
			return muter
	end
	
	ScoreBoard:AddColumn( "", 32, f, 5 )
end

-- THESE SHOULD BE THE ONLY FUNCTION YOU NEED TO OVERRIDE
function GM:PositionScoreboard( ScoreBoard )
	
	-- Larger default size that isn't tiny, also doesn't need to always be changed on gamemodes!
	ScoreBoard:SetSize( ScrW() - (ScrW() / 3), ScrH() - 100 )
	ScoreBoard:SetPos( (ScrW() - ScoreBoard:GetWide()) / 2, 50 )
	
end

function GM:AddScoreboardWantsChange( ScoreBoard )

	local f = function( ply ) 
					if ( ply:GetNWBool( "WantsVote", false ) ) then 
						local lbl = vgui.Create( "DLabel" )
							lbl:SetFont( "Marlett" )
							lbl:SetText( "a" )
							lbl:SetTextColor( Color( 100, 255, 0 ) )
							lbl:SetContentAlignment( 5 )
						return lbl
					end					
				end
				
	ScoreBoard:AddColumn( "", 16, f, 2, nil, 6, 6 )

end

function GM:CreateScoreboard( ScoreBoard )

	-- This makes it so that it's behind chat & hides when you're in the menu
	-- Disable this if you want to be able to click on stuff on your scoreboard
	ScoreBoard:ParentToHUD()
	
	ScoreBoard:SetRowHeight( 32 )

	ScoreBoard:SetAsBullshitTeam( TEAM_SPECTATOR )
	ScoreBoard:SetAsBullshitTeam( TEAM_CONNECTING )
	ScoreBoard:SetShowScoreboardHeaders( GAMEMODE.TeamBased )
	
	if ( GAMEMODE.TeamBased ) then
		ScoreBoard:SetAsBullshitTeam( TEAM_UNASSIGNED )
		ScoreBoard:SetHorizontal( true )	
	end
	
	ScoreBoard:SetSkin( GAMEMODE.HudSkin )

	self:AddScoreboardAvatar( ScoreBoard )		-- 1
	self:AddScoreboardWantsChange( ScoreBoard )	-- 2
	self:AddScoreboardName( ScoreBoard )		-- 3
	self:AddScoreboardKills( ScoreBoard )		-- 4
	self:AddScoreboardDeaths( ScoreBoard )		-- 5
	self:AddScoreboardPing( ScoreBoard )		-- 6
	self:AddScoreboardMute( ScoreBoard )		-- 7
	
	-- Here we sort by these columns (and descending), in this order. You can define up to 4
	ScoreBoard:SetSortColumns( { 4, true, 5, false, 3, false } )

end
