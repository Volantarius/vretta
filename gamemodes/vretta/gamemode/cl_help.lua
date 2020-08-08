
local Help = nil 
function GM:ShowHelp()

	if ( !IsValid( Help ) ) then
	
		Help = vgui.CreateFromTable( vgui_Splash )
		Help:SetHeaderText( GAMEMODE.Name or "Untitled Gamemode" )
		Help:SetHoverText( GAMEMODE.Help or "No Help Avaliable" )
		
		Help.lblFooterText.Think = function( panel ) 
										local tl = GAMEMODE:GetGameTimeLeft()
										if ( tl == -1 ) then return end
										if( GetGlobalBool( "IsEndOfGame", false ) ) then panel:SetText( "Game has ended..." ) return end
										if( GAMEMODE.RoundBased && CurTime() > GAMEMODE:GetTimeLimit() ) then panel:SetText( "Game will end after this round" ) return end
										
										panel:SetText( "Time Left: " .. util.ToMinutesSeconds( tl ) ) 
									end

		if ( GetConVar( "fretta_voting" ):GetInt() != 0 ) then
			local btn = Help:AddSelectButton( "Vote For Change", function() RunConsoleCommand( "voteforchange" ) end )
			btn.m_colBackground = Color( 255, 200, 100 )
			btn:SetDisabled( LocalPlayer():GetNWBool( "WantsVote" ) ) 
		end
		
		if ( GAMEMODE.TeamBased ) then
			local btn = Help:AddSelectButton( "Change Team", function() GAMEMODE:ShowTeam() end )
			btn.m_colBackground = Color( 120, 255, 100 )
		end
		
		if ( !GAMEMODE.TeamBased && GAMEMODE.AllowSpectating ) then
		
			if ( LocalPlayer():Team() == TEAM_SPECTATOR ) then
			
				local btn = Help:AddSelectButton( "Join Game", function() RunConsoleCommand( "changeteam", TEAM_UNASSIGNED ) end )
				btn.m_colBackground = Color( 120, 255, 100 )
			
			else
		
				local btn = Help:AddSelectButton( "Spectate", function() RunConsoleCommand( "changeteam", TEAM_SPECTATOR ) end )
				btn.m_colBackground = Color( 200, 200, 200 )
				
			end
		end
		
		if ( IsValid( LocalPlayer() ) ) then
		
			local TeamID = LocalPlayer():Team()
			local Classes = team.GetClass( TeamID )
			if ( Classes && #Classes > 1 ) then
				local btn = Help:AddSelectButton( "Change Class", function() GAMEMODE:ShowClassChooser( LocalPlayer():Team() ) end )
				btn.m_colBackground = Color( 120, 255, 100 )
			end
		
		end
				
		Help:AddCancelButton()
		
		if ( GAMEMODE.SelectModel ) then
		
			local function CreateModelPanel()
					
				local pnl = vgui.Create( "DGrid" )
				
				pnl:SetCols( 6 )
				pnl:SetColWide( 66 )
				pnl:SetRowHeight( 66 )
				
				-- Updated the list to use the player manager list
				for name, model in SortedPairs( player_manager.AllValidModels() ) do
					
					local icon = vgui.Create( "SpawnIcon" )
					icon.DoClick = function() surface.PlaySound( "ui/buttonclickrelease.wav" ) RunConsoleCommand( "cl_vretta_playermodel", name ) end
					icon.PaintOver = function() if ( GetConVar("cl_vretta_playermodel"):GetString() == name ) then surface.SetDrawColor( Color( 255, 210 + math.sin(RealTime()*10)*40, 0 ) ) surface.DrawOutlinedRect( 4, 4, icon:GetWide()-8, icon:GetTall()-8 ) surface.DrawOutlinedRect( 3, 3, icon:GetWide()-6, icon:GetTall()-6 ) end end
					icon:SetModel( model )
					icon:SetSize( 64, 64 )
					icon:SetTooltip( name )
					
					pnl:AddItem( icon )
					
				end
				
				return pnl
				
			end
			
			Help:AddPanelButton( "icon16/user.png", "Choose Player Model", CreateModelPanel )
		
		end
		
		if ( GAMEMODE.SelectColor ) then
		
			local function CreateColorPanel()
				-- Use the new color mixer panel
				
				local plycol = vgui.Create( "DColorMixer" )
				plycol:SetAlphaBar( false )
				plycol:SetPalette( false )
				plycol:SetVector( Vector( GetConVar("cl_vretta_playercolor"):GetString() ) )
				plycol:SetSize( 320, 256 )
				
				plycol.ValueChanged = function () RunConsoleCommand( "cl_vretta_playercolor", tostring( plycol:GetVector() ) ) end
				
				return plycol
			end
			
			Help:AddPanelButton( "icon16/application_view_tile.png", "Choose Player Color", CreateColorPanel )
			
		end

	end
	
	Help:MakePopup()
	Help:NoFadeIn()
	
end

-- Moved from cl_gmchanger.lua
local ClassChooser = nil
cl_classsuicide = CreateConVar( "cl_classsuicide", "0", { FCVAR_ARCHIVE } )

function GM:ShowClassChooser( TEAMID )
	
	if ( !GAMEMODE.SelectClass ) then return end
	if ( ClassChooser ) then ClassChooser:Remove() end
	
	ClassChooser = vgui.CreateFromTable( vgui_Splash )
	ClassChooser:SetHeaderText( "Choose Class" )
	ClassChooser:SetHoverText( "What class do you want to be?" )
	
	Classes = team.GetClass( TEAMID )
	
	for k, v in SortedPairs( Classes ) do
		
		local displayname = v
		local Class = baseclass.Get( v )
		if ( Class && Class.DisplayName ) then
			displayname = Class.DisplayName
		end
		
		local description = "Click to spawn as " .. displayname
		
		if( Class and Class.Description ) then
			description = Class.Description
		end
		
		local func = function() if( cl_classsuicide:GetBool() ) then RunConsoleCommand( "kill" ) end RunConsoleCommand( "changeclass", k, LocalPlayer(), false ) end
		
		local btn = ClassChooser:AddSelectButton( displayname, func, description )
		btn.m_colBackground = team.GetColor( TEAMID )
		
	end
	
	ClassChooser:AddCancelButton()
	ClassChooser:MakePopup()
	ClassChooser:NoFadeIn()
	
end
