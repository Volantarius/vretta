
local vrettaSplashFonts = {"FRETTA_LARGE", "FRETTA_MEDIUM"}

local PANEL = {}

--[[---------------------------------------------------------
   Init
---------------------------------------------------------]]
function PANEL:Init()
	
	self:SetText( "" )
	self.DoClick = function() RunConsoleCommand( "seensplashlocal" ) RunConsoleCommand( "seensplash" ) self:Remove() end
	self:SetSkin( GAMEMODE.HudSkin )
	
	self.lblGamemodeName = vgui.Create( "DLabel", self )
		self.lblGamemodeName:SetText( GAMEMODE.Name )
		self.lblGamemodeName:SetFont( vrettaSplashFonts[1] )
		self.lblGamemodeName:SetColor( color_white )
		
	self.lblGamemodeAuthor = vgui.Create( "DLabel", self )
		self.lblGamemodeAuthor:SetText( "by " .. GAMEMODE.Author )
		self.lblGamemodeAuthor:SetFont( vrettaSplashFonts[2] )
		self.lblGamemodeAuthor:SetColor( color_white )
		
	self.lblServerName = vgui.Create( "DLabel", self )
		self.lblServerName:SetText( GetHostName() )
		self.lblServerName:SetFont( vrettaSplashFonts[2] )
		self.lblServerName:SetColor( color_white )
		
	self.lblIP = vgui.Create( "DLabel", self )
		self.lblIP:SetText( "0.0.0.0" )
		self.lblIP:SetFont( vrettaSplashFonts[2] )
		self.lblIP:SetColor( color_white )
		
	
	self:PerformLayout()
	
	self.FadeInTime = RealTime()
	
end

--[[---------------------------------------------------------
   PerformLayout
---------------------------------------------------------]]
function PANEL:PerformLayout()
	
	self:SetSize( ScrW(), ScrH() )
	
	local CenterY = ScrH() / 2.0
	
	self.lblGamemodeName:SizeToContents()
	self.lblGamemodeName:SetPos( ScrW()/2 - self.lblGamemodeName:GetWide()/2, CenterY - 200 - self.lblGamemodeName:GetTall() - self.lblGamemodeAuthor:GetTall() )
	
	self.lblGamemodeAuthor:SizeToContents()
	self.lblGamemodeAuthor:SetPos( ScrW()/2 - self.lblGamemodeAuthor:GetWide()/2, CenterY - 200 - self.lblGamemodeAuthor:GetTall() )
	
	self.lblServerName:SizeToContents()
	self.lblServerName:SetPos( 100, CenterY + 200 )
	
	self.lblIP:SetText( GetConVarString( "ip" )  )
	self.lblIP:SizeToContents()
	self.lblIP:SetPos( self:GetWide() - 100 - self.lblIP:GetWide(), CenterY + 200 )
	
end

--[[---------------------------------------------------------
   Paint
---------------------------------------------------------]]
function PANEL:Paint()
	local w, h = self:GetWide(), self:GetTall()
	
	local override = GAMEMODE:PaintSplashScreen( w, h )
	
	if ( !override ) then
		Derma_DrawBackgroundBlur( self )
		
		local Fade = RealTime() - self.FadeInTime
		if ( Fade < 3 ) then
		
			Fade = 1- (Fade / 3)
			surface.SetDrawColor( 0,0, 0, Fade * 255 )
			surface.DrawRect( 0, 0, w, h )
		
		end
		
		local CenterY = ScrH() / 2.0
		
		surface.SetDrawColor( 0, 0, 0, 200 )
		surface.DrawRect( 0, 0, w, CenterY - 180 )
		
		surface.DrawRect( 0, CenterY + 180, w, h - ( CenterY+ 180 ) )
	end
end

local vgui_Splash = vgui.RegisterTable( PANEL, "DButton" )

function GM:ShowSplash()

	local pnl = vgui.CreateFromTable( vgui_Splash )
	pnl:MakePopup()

end

--[[-------------------------------------------------------------------------
	PaintSplashScreen
	Return true to override default paint method
---------------------------------------------------------------------------]]
function GM:PaintSplashScreen( w, h, selectscreen )
	
	-- Customised splashscreen render here ( The center bit! )
	return false
end