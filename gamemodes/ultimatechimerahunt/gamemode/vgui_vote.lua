local PANEL = {}
local MapList = {}
local ListCopy = {}

function PANEL:Init()

	self:SetSkin( GAMEMODE.HudSkin )
	self:ParentToHUD()
	
	self.ControlCanvas = vgui.Create( "Panel", self )
	self.ControlCanvas:MakePopup()
	self.ControlCanvas:SetKeyboardInputEnabled( false )
	
	self.lblCountDown = vgui.Create( "DLabel", self.ControlCanvas )
	self.lblCountDown:SetText( "60" )
	
	self.lblActionName = vgui.Create( "DLabel", self.ControlCanvas )
	
	self.ctrlList = vgui.Create( "DPanelList", self.ControlCanvas )
	self.ctrlList:SetDrawBackground( false )
	self.ctrlList:SetSpacing( 2 )
	self.ctrlList:SetPadding( 2 )
	self.ctrlList:EnableHorizontal( true )
	self.ctrlList:EnableVerticalScrollbar()
	
	self.Peeps = {}
	
	for i =1, game.MaxPlayers() do
	
		self.Peeps[i] = vgui.Create( "DImage", self.ctrlList:GetCanvas() )
		self.Peeps[i]:SetSize( 24, 24 )
		self.Peeps[i]:SetZPos( 1000 )
		self.Peeps[i]:SetVisible( false )
		self.Peeps[i]:SetImage( "UCH/ranks/ensign" )
	
	end

end

function PANEL:PerformLayout()
	
	local cx, cy = chat.GetChatBoxPos()
	
	self:SetPos( 0, 0 )
	self:SetSize( ScrW(), ScrH() )
	
	self.ControlCanvas:StretchToParent( 0, 0, 0, 0 )
	self.ControlCanvas:SetWide( 550 )
	self.ControlCanvas:SetTall( cy - 30 )
	self.ControlCanvas:SetPos( 0, 30 )
	self.ControlCanvas:CenterHorizontal();
	self.ControlCanvas:SetZPos( 0 )
	
	self.lblCountDown:SetFont( "FRETTA_MEDIUM_SHADOW" )
	self.lblCountDown:AlignRight()
	self.lblCountDown:SetTextColor( color_white )
	self.lblCountDown:SetContentAlignment( 6 )
	self.lblCountDown:SetWidth( 500 )
	
	self.lblActionName:SetFont( "FRETTA_LARGE_SHADOW" )
	self.lblActionName:AlignLeft()
	self.lblActionName:SetTextColor( color_white )
	self.lblActionName:SizeToContents()
	self.lblActionName:SetWidth( 500 )
	
	self.ctrlList:StretchToParent( 0, 60, 0, 0 )

end

function PANEL:ChooseMap( gamemode )

	self.lblActionName:SetText( "Which Map?" )
	self:ResetPeeps()
	self.ctrlList:Clear()
	
	local gm = MapList;
	if ( !gm ) then MsgN( "GAMEMODE MISSING, COULDN'T VOTE FOR MAP ", gamemode ) return end	
	
	for id, mapname in pairs( gm ) do
	
		local lbl = vgui.Create( "DButton", self.ctrlList )
			lbl:SetText( mapname )
			
			Derma_Hook( lbl, 	"Paint", 				"Paint", 	"GamemodeButton" )
			Derma_Hook( lbl, 	"ApplySchemeSettings", 	"Scheme", 	"GamemodeButton" )
			Derma_Hook( lbl, 	"PerformLayout", 		"Layout", 	"GamemodeButton" )
			
			lbl:SetTall( 24 )
			lbl:SetWide( 240 )
			
		lbl.WantName = mapname
		lbl.NumVotes = 0
		lbl.bgColor = Color( 100, 100, 100, 100 )
		lbl.DoClick = function() if GetGlobalFloat( "VoteEndTime", 0 ) - CurTime() <= 0 then return end RunConsoleCommand( "votemap", mapname ) end
		
		lbl.Paint = function( w, h ) -- The paint function
			surface.SetDrawColor( lbl.bgColor.r, lbl.bgColor.g, lbl.bgColor.b, lbl.bgColor.a ) -- What color do You want to paint the button (R, B, G, A)
			surface.DrawRect( 0, 0, lbl:GetWide(), lbl:GetTall() )	
		end
		
		self.ctrlList:AddItem( lbl )
	
	end
	
	ListCopy = self.ctrlList

end

function PANEL:ResetPeeps()

	for i=1, game.MaxPlayers() do
		self.Peeps[i]:SetPos( math.random( 0, 600 ), -24 )
		self.Peeps[i]:SetVisible( false )
		self.Peeps[i].strVote = nil
	end

end

function PANEL:FindWantBar( name )

	if #ListCopy:GetItems() == 0 then return end
	for k, v in pairs( ListCopy:GetItems() ) do
		if ( v.WantName == name ) then return v end
	end

end

function PANEL:PeepThink( peep, ent )

	if ( !IsValid( ent ) ) then 
		peep:SetVisible( false )
		return
	end
	
	peep:SetTooltip( ent:Nick() )
	peep:SetMouseInputEnabled( true )
	
	if ( !peep.strVote ) then
		peep:SetVisible( true )
		peep:SetPos( math.random( 0, 600 ), -24 )
		if ( ent == LocalPlayer() ) then
			peep:SetImage( "UCH/ranks/colonel" )
		end
	end

	peep.strVote = ent:GetNWString( "Wants", "" )
	local bar = self:FindWantBar( peep.strVote ) 
	if ( IsValid( bar ) ) then
		bar.NumVotes = bar.NumVotes + 1
		local vCurrentPos = Vector( peep.x, peep.y, 0 )
		local vNewPos = Vector( (bar.x + bar:GetWide()) - 16 * bar.NumVotes - 4, bar.y + ( bar:GetTall() * 0.5 - 12 ), 0 )
	
		if ( !peep.CurPos || peep.CurPos != vNewPos ) then
		
			peep:MoveTo( vNewPos.x, vNewPos.y, 0.2 )
			peep.CurPos = vNewPos
			
		end
		
	end

end

function PANEL:Think()

	local Seconds = GetGlobalFloat( "VoteEndTime", 0 ) - CurTime()
	if ( Seconds < 0 ) then Seconds = 0 end
	
	self.lblCountDown:SetText( Format( "%i", Seconds ) )
	
	for k, v in pairs( self.ctrlList:GetItems() ) do
		v.NumVotes = 0
	end
	
	for i=1, game.MaxPlayers() do
		self:PeepThink( self.Peeps[i], player.GetByID(i) )
	end

end

function PANEL:Paint( w, h )

	Derma_DrawBackgroundBlur( self )
		
	local CenterY = ScrH() / 2.0
	local CenterX = ScrW() / 2.0
	
	surface.SetDrawColor( 0, 0, 0, 200 );
	surface.DrawRect( 0, 0, ScrW(), ScrH() );
	
end

function PANEL:FlashItem( itemname )

	local bar = PANEL:FindWantBar( itemname )
	if ( !IsValid( bar ) ) then return end
	
	timer.Simple( 0.0, function() bar.bgColor = Color(0, 255, 255, 100) surface.PlaySound( "hl1/fvox/blip.wav" ) end )
	timer.Simple( 0.2, function() bar.bgColor = Color(100, 100, 100, 100) end )
	timer.Simple( 0.4, function() bar.bgColor = Color(0, 255, 255, 100) surface.PlaySound( "hl1/fvox/blip.wav" ) end )
	timer.Simple( 0.6, function() bar.bgColor = Color(100, 100, 100, 100) end )
	timer.Simple( 0.8, function() bar.bgColor = Color(0, 255, 255, 100) surface.PlaySound( "hl1/fvox/blip.wav" ) end )
	timer.Simple( 1.0, function() bar.bgColor = Color(100, 100, 100, 100) end )

end

derma.DefineControl( "VoteScreen", "", PANEL, "DPanel" )

function ChangingGamemode( map )

	PANEL:FlashItem( map )

end

function ReceiveMapList()

	MapList = net.ReadTable();

end
net.Receive("MapList", ReceiveMapList)