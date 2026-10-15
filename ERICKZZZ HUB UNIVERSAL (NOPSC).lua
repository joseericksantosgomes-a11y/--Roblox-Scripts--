-- Erickzzz Universal Hub - Full Edition
local P=game:GetService("Players")
local T=game:GetService("TweenService")
local U=game:GetService("UserInputService")
local R=game:GetService("RunService")
local HS=game:GetService("HttpService")
local LP=P.LocalPlayer

local function mk(p,c,t)local o=Instance.new(c)if t then for k,v in pairs(t)do o[k]=v end end o.Parent=p return o end
local function cr(p,r)local u=Instance.new("UICorner")u.CornerRadius=UDim.new(0,r or 6)u.Parent=p return u end
local function sk(p,c,t)local s=Instance.new("UIStroke")s.Color=c s.Thickness=t or 1 s.Parent=p return s end
local function tw(o,t,d,s)T:Create(o,TweenInfo.new(d or .2,s or Enum.EasingStyle.Quart),t):Play()end
local function CC(r,g,b)return Color3.fromRGB(r,g,b)end
local function httpGet(url)
	if game.HttpGet then local ok,r=pcall(game.HttpGet,game,url)if ok then return r end end
	if syn and syn.request then local ok,r=pcall(syn.request,{Url=url,Method="GET"})if ok and r.Body then return r.Body end end
	if http_request then local ok,r=pcall(http_request,{Url=url,Method="GET"})if ok and r.Body then return r.Body end end
	if request then local ok,r=pcall(request,{Url=url,Method="GET"})if ok and r.Body then return r.Body end end
end
local function searchCat(q)
	local b=httpGet("https://catalog.roblox.com/v1/search/items/details?Category=Decals&Keyword="..HS:UrlEncode(q).."&Limit=30")
	if not b then return{}end
	local ok,d=pcall(HS.JSONDecode,HS,b)
	if not ok then return{}end
	return d.data or d.results or{}
end
local function thumb(id)return"https://www.roblox.com/asset-thumbnail/image?assetId="..id.."&width=150&height=150&format=png"end

local THEMES={
	["Default Blue"]={bg=CC(11,12,16),icons=CC(142,150,168),selectedTab=CC(108,138,255),toggleOff=CC(31,35,43),toggleOn=CC(108,138,255),buttons=CC(17,19,24),buttonsPressed=CC(33,37,46),names=CC(236,240,248),subtexts=CC(142,150,168),tabListBg=CC(17,19,24),buttonOutline=CC(31,35,43),titleBarBg=CC(17,19,24)},
	["Crimson"]={bg=CC(18,8,10),icons=CC(200,100,110),selectedTab=CC(220,50,70),toggleOff=CC(60,25,30),toggleOn=CC(220,50,70),buttons=CC(28,12,15),buttonsPressed=CC(48,20,25),names=CC(255,220,225),subtexts=CC(180,130,140),tabListBg=CC(28,12,15),buttonOutline=CC(80,35,45),titleBarBg=CC(28,12,15)},
	["Honey"]={bg=CC(18,14,4),icons=CC(200,170,90),selectedTab=CC(240,190,60),toggleOff=CC(50,40,15),toggleOn=CC(240,190,60),buttons=CC(28,22,8),buttonsPressed=CC(48,38,15),names=CC(255,240,210),subtexts=CC(190,165,110),tabListBg=CC(28,22,8),buttonOutline=CC(90,75,30),titleBarBg=CC(28,22,8)},
	["Forest Green"]={bg=CC(8,15,10),icons=CC(110,170,120),selectedTab=CC(60,180,90),toggleOff=CC(20,50,30),toggleOn=CC(60,180,90),buttons=CC(12,24,16),buttonsPressed=CC(24,44,30),names=CC(220,250,225),subtexts=CC(130,180,140),tabListBg=CC(12,24,16),buttonOutline=CC(40,80,50),titleBarBg=CC(12,24,16)},
	["Dark Mode"]={bg=CC(8,8,8),icons=CC(160,160,160),selectedTab=CC(220,220,220),toggleOff=CC(40,40,40),toggleOn=CC(220,220,220),buttons=CC(20,20,20),buttonsPressed=CC(35,35,35),names=CC(240,240,240),subtexts=CC(140,140,140),tabListBg=CC(20,20,20),buttonOutline=CC(50,50,50),titleBarBg=CC(20,20,20)},
	["Light Mode"]={bg=CC(240,240,245),icons=CC(80,80,90),selectedTab=CC(50,100,220),toggleOff=CC(200,200,210),toggleOn=CC(50,100,220),buttons=CC(225,225,235),buttonsPressed=CC(210,210,225),names=CC(30,30,40),subtexts=CC(90,90,105),tabListBg=CC(225,225,235),buttonOutline=CC(180,180,195),titleBarBg=CC(225,225,235)},
}
local A={}for k,v in pairs(THEMES["Default Blue"])do A[k]={c=v,t=0}end
local PALS={surface=CC(17,19,24),elev=CC(24,27,34),border=CC(31,35,43),borderL=CC(54,62,78),danger=CC(235,80,90),success=CC(80,210,130),accentDim=CC(50,72,150),textMut=CC(82,89,105)}

local cfg={
	uw=400,uh=459,ts=11,ss=9,bw=200,bh=50,bgMedia=nil,theme="Default Blue",
	active=false,target="NPCs",part="Head",format="Ball",size=5,transp=0.5,color=CC(108,138,255),hbTeamCheck=false,
	espActive=false,espColor=CC(255,80,80),espHighlight=false,espChams=false,espSkeleton=false,espHealth=false,espName=false,espDistance=false,espTool=false,espTeamCheck=false,
	aimActive=false,aimShowFov=true,aimFovColor="White",aimFovTransp=0.5,aimFovSize=120,aimSmooth=0.5,aimPart="Head",aimTeamCheck=true,aimWalkCheck=true,aimDeathCheck=true,
}

local gui=mk(LP:WaitForChild("PlayerGui"),"ScreenGui",{Name="EZHub",ResetOnSpawn=false,IgnoreGuiInset=true,ZIndexBehavior=Enum.ZIndexBehavior.Sibling})
local M=mk(gui,"Frame",{Name="Main",AnchorPoint=Vector2.new(.5,0),Position=UDim2.new(.5,0,.22,-30),Size=UDim2.new(0,cfg.uw,0,cfg.uh),BackgroundColor3=A.bg.c,BackgroundTransparency=A.bg.t,ClipsDescendants=true,BorderSizePixel=0})
cr(M,14)sk(M,PALS.borderL,1)
local SCALE=mk(M,"UIScale",{Scale=.8})
local BGClip=mk(M,"Frame",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,ClipsDescendants=true,BorderSizePixel=0,ZIndex=0})
cr(BGClip,14)
local BGImg=mk(BGClip,"ImageLabel",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Image="",ScaleType=Enum.ScaleType.Crop,ZIndex=0})
cr(BGImg,14)
local TB=mk(M,"Frame",{Size=UDim2.new(1,0,0,40),BackgroundColor3=A.titleBarBg.c,BackgroundTransparency=A.titleBarBg.t,BorderSizePixel=0,ZIndex=5})
cr(TB,14)
mk(TB,"Frame",{Name="Cover",Size=UDim2.new(1,0,0,14),Position=UDim2.new(0,0,1,-14),BackgroundColor3=A.titleBarBg.c,BackgroundTransparency=A.titleBarBg.t,BorderSizePixel=0,ZIndex=5})
local SB=mk(M,"Frame",{Size=UDim2.new(0,56,1,-40),Position=UDim2.new(0,0,0,40),BackgroundColor3=A.tabListBg.c,BackgroundTransparency=A.tabListBg.t,BorderSizePixel=0,ZIndex=4})
cr(SB,14)
mk(SB,"Frame",{Name="SBCover",Size=UDim2.new(0,14,1,0),Position=UDim2.new(0,42,0,0),BackgroundColor3=A.tabListBg.c,BackgroundTransparency=A.tabListBg.t,BorderSizePixel=0,ZIndex=4})
mk(SB,"Frame",{Size=UDim2.new(0,1,1,-24),Position=UDim2.new(1,-1,0,12),BackgroundColor3=PALS.border,BorderSizePixel=0,ZIndex=5})
local PL=mk(M,"Frame",{Name="PopupLayer",Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,ZIndex=9000,ClipsDescendants=false})
local CA=mk(M,"Frame",{Size=UDim2.new(1,-56,1,-40),Position=UDim2.new(0,56,0,40),BackgroundTransparency=1,ClipsDescendants=true,ZIndex=3})

local function applyTheme()
	M.BackgroundColor3=A.bg.c M.BackgroundTransparency=A.bg.t
	TB.BackgroundColor3=A.titleBarBg.c TB.BackgroundTransparency=A.titleBarBg.t
	local c=TB:FindFirstChild("Cover")if c then c.BackgroundColor3=A.titleBarBg.c c.BackgroundTransparency=A.titleBarBg.t end
	SB.BackgroundColor3=A.tabListBg.c SB.BackgroundTransparency=A.tabListBg.t
	local sc=SB:FindFirstChild("SBCover")if sc then sc.BackgroundColor3=A.tabListBg.c sc.BackgroundTransparency=A.tabListBg.t end
	for _,d in ipairs(M:GetDescendants())do
		local tt=d:GetAttribute("TT")
		if tt and (d:IsA("TextLabel")or d:IsA("TextBox"))then d.TextColor3=A[tt].c d.TextTransparency=A[tt].t end
		local bg2=d:GetAttribute("BG2")
		if bg2 and d:IsA("GuiObject")then d.BackgroundColor3=A[bg2].c d.BackgroundTransparency=A[bg2].t end
	end
end
local function TT(o,k)o:SetAttribute("TT",k)return o end
local function BG2(o,k)o:SetAttribute("BG2",k)return o end

local function mkLn(p,x1,y1,x2,y2,t,c,z)z=z or 3 local dx,dy=x2-x1,y2-y1 local l=math.sqrt(dx*dx+dy*dy)local a=math.deg(math.atan2(dy,dx))mk(p,"Frame",{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromOffset((x1+x2)/2,(y1+y2)/2),Size=UDim2.fromOffset(l,t),Rotation=a,BackgroundColor3=c,BorderSizePixel=0,ZIndex=z})for _,pt in ipairs({{x1,y1},{x2,y2}})do local d=mk(p,"Frame",{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromOffset(pt[1],pt[2]),Size=UDim2.fromOffset(t,t),BackgroundColor3=c,BorderSizePixel=0,ZIndex=z})cr(d,999)end end
local function mkCir(p,cx,cy,r,t,c,z)local f=mk(p,"Frame",{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromOffset(cx,cy),Size=UDim2.fromOffset(r*2,r*2),BackgroundTransparency=1,ZIndex=z or 3})cr(f,999)sk(f,c,t)end
local function ICON(p,kind,c,s,z)
	local f=mk(p,"Frame",{Size=UDim2.fromOffset(s,s),BackgroundTransparency=1,ZIndex=z or 2})
	local u=s/24 local t=math.max(1.6,s*.09)
	if kind=="home"then mkLn(f,3*u,10.5*u,12*u,3*u,t,c)mkLn(f,12*u,3*u,21*u,10.5*u,t,c)mkLn(f,5.5*u,9*u,5.5*u,20.5*u,t,c)mkLn(f,18.5*u,9*u,18.5*u,20.5*u,t,c)mkLn(f,5.5*u,20.5*u,18.5*u,20.5*u,t,c)mkLn(f,9.5*u,20.5*u,9.5*u,14.5*u,t,c)mkLn(f,14.5*u,20.5*u,14.5*u,14.5*u,t,c)mkLn(f,9.5*u,14.5*u,14.5*u,14.5*u,t,c)
	elseif kind=="sword"then mkLn(f,20*u,4*u,10*u,14*u,t,c)mkLn(f,20*u,4*u,17.5*u,3*u,t,c)mkLn(f,20*u,4*u,21*u,6.5*u,t,c)mkLn(f,7*u,10*u,14*u,17*u,t,c)mkLn(f,10*u,14*u,5*u,19*u,t,c)local d=mk(f,"Frame",{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromOffset(4*u,20*u),Size=UDim2.fromOffset(t*.7,t*.7),BackgroundColor3=c,BorderSizePixel=0,ZIndex=3})cr(d,999)
	elseif kind=="eye"then local e=mk(f,"Frame",{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromOffset(12*u,12*u),Size=UDim2.fromOffset(19*u,12*u),BackgroundTransparency=1,ZIndex=3})cr(e,999)sk(e,c,t)local d=mk(f,"Frame",{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromOffset(12*u,12*u),Size=UDim2.fromOffset(6*u,6*u),BackgroundColor3=c,BorderSizePixel=0,ZIndex=3})cr(d,999)
	elseif kind=="cross"then mkCir(f,12*u,12*u,6.5*u,t,c)mkCir(f,12*u,12*u,1.5*u,t,c)mkLn(f,12*u,2*u,12*u,5*u,t,c)mkLn(f,12*u,19*u,12*u,22*u,t,c)mkLn(f,2*u,12*u,5*u,12*u,t,c)mkLn(f,19*u,12*u,22*u,12*u,t,c)
	elseif kind=="cog"then mkCir(f,12*u,12*u,7.5*u,t,c)mkCir(f,12*u,12*u,2.5*u,t,c)for k=0,7 do local a=(k/8)*math.pi*2 mkLn(f,12*u+math.cos(a)*7.5*u,12*u+math.sin(a)*7.5*u,12*u+math.cos(a)*10.5*u,12*u+math.sin(a)*10.5*u,t,c)end
	elseif kind=="chev"then mkLn(f,6*u,9*u,12*u,15*u,t,c)mkLn(f,12*u,15*u,18*u,9*u,t,c)
	elseif kind=="chevL"then mkLn(f,15*u,6*u,9*u,12*u,t,c)mkLn(f,9*u,12*u,15*u,18*u,t,c)
	elseif kind=="check"then mkLn(f,5*u,12*u,10*u,17*u,t,c)mkLn(f,10*u,17*u,19*u,7*u,t,c)
	elseif kind=="circleCheck"then mkCir(f,12*u,12*u,9.5*u,t,c)mkLn(f,8*u,12*u,11*u,15*u,t,c)mkLn(f,11*u,15*u,16*u,9*u,t,c)
	elseif kind=="minus"then mkLn(f,6*u,12*u,18*u,12*u,t,c)
	elseif kind=="plus"then mkLn(f,6*u,12*u,18*u,12*u,t,c)mkLn(f,12*u,6*u,12*u,18*u,t,c)
	elseif kind=="x"then mkLn(f,6*u,6*u,18*u,18*u,t,c)mkLn(f,18*u,6*u,6*u,18*u,t,c)
	elseif kind=="trash"then mkLn(f,3*u,6*u,21*u,6*u,t,c)mkLn(f,8*u,6*u,8*u,3.5*u,t,c)mkLn(f,16*u,6*u,16*u,3.5*u,t,c)mkLn(f,8*u,3.5*u,16*u,3.5*u,t,c)mkLn(f,5*u,6*u,6.5*u,20.5*u,t,c)mkLn(f,19*u,6*u,17.5*u,20.5*u,t,c)mkLn(f,6.5*u,20.5*u,17.5*u,20.5*u,t,c)
	elseif kind=="dl"then mkLn(f,12*u,3*u,12*u,15*u,t,c)mkLn(f,7*u,10*u,12*u,15*u,t,c)mkLn(f,17*u,10*u,12*u,15*u,t,c)mkLn(f,4*u,18*u,20*u,18*u,t,c)mkLn(f,4*u,18*u,4*u,21*u,t,c)mkLn(f,20*u,18*u,20*u,21*u,t,c)mkLn(f,4*u,21*u,20*u,21*u,t,c)
	elseif kind=="save"then mkLn(f,4*u,4*u,17*u,4*u,t,c)mkLn(f,17*u,4*u,20*u,7*u,t,c)mkLn(f,20*u,7*u,20*u,20*u,t,c)mkLn(f,20*u,20*u,4*u,20*u,t,c)mkLn(f,4*u,20*u,4*u,4*u,t,c)mkLn(f,8*u,4*u,8*u,9*u,t,c)mkLn(f,8*u,9*u,16*u,9*u,t,c)mkLn(f,16*u,9*u,16*u,4*u,t,c)mkLn(f,8*u,14*u,16*u,14*u,t,c)mkLn(f,8*u,14*u,8*u,20*u,t,c)mkLn(f,16*u,14*u,16*u,20*u,t,c)
	elseif kind=="refresh"then mkLn(f,4*u,12*u,4*u,8*u,t,c)mkLn(f,4*u,8*u,8*u,4*u,t,c)mkLn(f,8*u,4*u,16*u,4*u,t,c)mkLn(f,16*u,4*u,20*u,8*u,t,c)mkLn(f,20*u,8*u,20*u,10*u,t,c)mkLn(f,8*u,20*u,16*u,20*u,t,c)mkLn(f,16*u,20*u,20*u,16*u,t,c)mkLn(f,20*u,16*u,20*u,12*u,t,c)mkLn(f,2*u,10*u,6*u,10*u,t,c)mkLn(f,2*u,10*u,2*u,6*u,t,c)
	elseif kind=="key"then mkCir(f,8*u,12*u,4*u,t,c)mkLn(f,12*u,12*u,21*u,12*u,t,c)mkLn(f,17*u,12*u,17*u,17*u,t,c)mkLn(f,20*u,12*u,20*u,16*u,t,c)
	elseif kind=="paint"then mkLn(f,4*u,18*u,4*u,14*u,t,c)mkLn(f,4*u,14*u,9*u,9*u,t,c)mkLn(f,9*u,9*u,15*u,15*u,t,c)mkLn(f,15*u,15*u,20*u,10*u,t,c)mkLn(f,20*u,10*u,20*u,6*u,t,c)mkLn(f,20*u,6*u,17*u,6*u,t,c)mkCir(f,12*u,12*u,3*u,t,c)
	end
	return f
end
local function iconHolder(p,kind,sz,z,color)local cg=mk(p,"CanvasGroup",{Size=UDim2.fromOffset(sz,sz),BackgroundTransparency=1,GroupTransparency=A.icons.t,ZIndex=z or 6})ICON(cg,kind,color or A.icons.c,sz)return cg end

-- TITLE BAR
local titleChev=iconHolder(TB,"chevL",16,7)titleChev.Position=UDim2.new(0,14,.5,-8)
local titleLbl=TT(mk(TB,"TextLabel",{Size=UDim2.new(1,-110,1,0),Position=UDim2.new(0,36,0,0),BackgroundTransparency=1,Text="ERICKZZZ UNIVERSAL HUB",Font=Enum.Font.GothamBold,TextSize=cfg.ts,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=6}),"names")
local function winBtn(x,fn,hover)
	local b=mk(TB,"TextButton",{Size=UDim2.new(0,26,0,26),Position=UDim2.new(1,x,.5,-13),BackgroundColor3=PALS.elev,BorderSizePixel=0,Text="",AutoButtonColor=false,ZIndex=6})
	cr(b,7)
	local ih=iconHolder(b,fn,20,7)ih.Position=UDim2.new(.5,-10,.5,-10)
	b.MouseEnter:Connect(function()tw(b,{BackgroundColor3=hover},.15)ih:ClearAllChildren()ICON(ih,fn,CC(255,255,255),20)end)
	b.MouseLeave:Connect(function()tw(b,{BackgroundColor3=PALS.elev},.15)ih:ClearAllChildren()ICON(ih,fn,A.icons.c,20)end)
	return b,ih
end
local minBtn,minIcon=winBtn(-60,"minus",PALS.elev)
local closeBtn=winBtn(-32,"x",PALS.danger)

AM=nil
local function closeMenu()if AM then local m=AM AM=nil m.c()end end

do
	local dg,ds,sp
	TB.InputBegan:Connect(function(i)if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then closeMenu()dg=true ds=i.Position sp=M.Position end end)
	U.InputChanged:Connect(function(i)if dg and(i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch)then local d=i.Position-ds M.Position=UDim2.new(sp.X.Scale,sp.X.Offset+d.X,sp.Y.Scale,sp.Y.Offset+d.Y)end end)
	U.InputEnded:Connect(function(i)if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dg=false end end)
end

local function makePage()
	local cg=mk(CA,"CanvasGroup",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,GroupTransparency=1,Visible=false,ZIndex=3})
	local sf=mk(cg,"ScrollingFrame",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,BorderSizePixel=0,CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollingDirection=Enum.ScrollingDirection.Y,ElasticBehavior=Enum.ElasticBehavior.WhenScrollable,ScrollBarThickness=3,ScrollBarImageColor3=PALS.borderL,ScrollBarImageTransparency=.4,ZIndex=3})
	mk(sf,"UIPadding",{PaddingTop=UDim.new(0,18),PaddingBottom=UDim.new(0,18),PaddingLeft=UDim.new(0,16),PaddingRight=UDim.new(0,14)})
	mk(sf,"UIListLayout",{Padding=UDim.new(0,12),SortOrder=Enum.SortOrder.LayoutOrder})
	return{cg=cg,sf=sf}
end
local pageMain=makePage()local pageCfg=makePage()local pageHb=makePage()
for _,p in pairs({pageMain,pageCfg,pageHb})do p.sf:GetPropertyChangedSignal("CanvasPosition"):Connect(function()if AM then closeMenu()end end)end

local TABS={};local TABI=0;local CTAB=nil
local function buildTab(id,kind)
	local i=TABI TABI+=1
	local b=mk(SB,"TextButton",{Size=UDim2.new(0,40,0,40),Position=UDim2.new(.5,-20,0,14+i*46),BackgroundTransparency=1,BorderSizePixel=0,Text="",AutoButtonColor=false,ZIndex=5})
	cr(b,8)
	local h=iconHolder(b,kind,22,6)h.Position=UDim2.new(.5,-11,.5,-11)
	TABS[id]={b=b,h=h,k=kind,a=false}
end
buildTab("main","home")buildTab("cfg","cog")buildTab("hb","sword")
local PAGES={main=pageMain,cfg=pageCfg,hb=pageHb}
local function switchTab(id)
	if CTAB==id then return end
	closeMenu()CTAB=id
	for n,t in pairs(TABS)do
		local on=n==id
		t.a=on
		if on then t.b.BackgroundColor3=A.selectedTab.c t.b.BackgroundTransparency=A.selectedTab.t t.h:ClearAllChildren()ICON(t.h,t.k,A.icons.c,22)
		else t.b.BackgroundTransparency=1 t.h:ClearAllChildren()ICON(t.h,t.k,A.icons.c,22)end
	end
	for pid,p in pairs(PAGES)do
		if pid==id then p.cg.Visible=true tw(p.cg,{GroupTransparency=0},.22)
		else tw(p.cg,{GroupTransparency=1},.15)end
	end
end
for id,t in pairs(TABS)do
	t.b.MouseEnter:Connect(function()if CTAB~=id then t.b.BackgroundTransparency=0 t.b.BackgroundColor3=PALS.elev t.h:ClearAllChildren()ICON(t.h,t.k,A.icons.c,22)end end)
	t.b.MouseLeave:Connect(function()if CTAB~=id then t.b.BackgroundTransparency=1 t.h:ClearAllChildren()ICON(t.h,t.k,A.icons.c,22)end end)
	t.b.MouseButton1Click:Connect(function()switchTab(id)end)
end

local function stkBtn(p)local u=Instance.new("UIStroke")u.Thickness=1 u.ApplyStrokeMode=Enum.ApplyStrokeMode.Border u.Parent=p u.Color=A.buttonOutline.c u.Transparency=A.buttonOutline.t return u end

local function buildDropdown(parent,lbl,opts,def,cb)
	local h=mk(parent,"Frame",{Size=UDim2.new(1,0,0,44),BackgroundTransparency=1,ZIndex=4})
	local b=BG2(mk(h,"TextButton",{Size=UDim2.new(1,0,1,0),BackgroundColor3=A.buttons.c,BackgroundTransparency=A.buttons.t,BorderSizePixel=0,Text="",AutoButtonColor=false,ZIndex=5}),"buttons")
	cr(b,8)local bs=stkBtn(b)
	local l1=TT(mk(b,"TextLabel",{Size=UDim2.new(1,-40,0,12),Position=UDim2.new(0,12,0,6),BackgroundTransparency=1,Text=lbl,Font=Enum.Font.GothamMedium,TextSize=cfg.ss,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=6}),"subtexts")
	local v1=TT(mk(b,"TextLabel",{Size=UDim2.new(1,-40,0,18),Position=UDim2.new(0,12,0,20),BackgroundTransparency=1,Text=opts[def],Font=Enum.Font.GothamBold,TextSize=cfg.ts,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=6}),"names")
	local ch=iconHolder(b,"chev",14,6)ch.Position=UDim2.new(1,-24,.5,-7)
	local list=mk(PL,"ScrollingFrame",{Size=UDim2.new(0,0,0,0),BackgroundColor3=PALS.surface,BorderSizePixel=0,CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollingDirection=Enum.ScrollingDirection.Y,ElasticBehavior=Enum.ElasticBehavior.WhenScrollable,ScrollBarThickness=3,ScrollBarImageColor3=PALS.borderL,ScrollBarImageTransparency=.4,Visible=false,ZIndex=9001})
	cr(list,9)sk(list,PALS.borderL,1)
	mk(list,"UIPadding",{PaddingTop=UDim.new(0,4),PaddingBottom=UDim.new(0,4),PaddingLeft=UDim.new(0,4),PaddingRight=UDim.new(0,4)})
	mk(list,"UIListLayout",{Padding=UDim.new(0,2),SortOrder=Enum.SortOrder.LayoutOrder})
	local sel=def local objs={}
	local function rf()
		for i,o in ipairs(objs)do
			local on=i==sel
			o.bg.BackgroundColor3=on and A.selectedTab.c or A.buttons.c
			o.bg.BackgroundTransparency=on and A.selectedTab.t or A.buttons.t
			o.lb.TextColor3=on and A.names.c or A.subtexts.c
			o.ck.Visible=on
		end
	end
	for i,opt in ipairs(opts)do
		local ob=mk(list,"TextButton",{Size=UDim2.new(1,0,0,26),BackgroundTransparency=1,BorderSizePixel=0,Text="",AutoButtonColor=false,ZIndex=9002,LayoutOrder=i})
		local bg=mk(ob,"Frame",{Size=UDim2.new(1,0,1,0),BackgroundColor3=A.buttons.c,BorderSizePixel=0,ZIndex=9002})
		cr(bg,6)
		local lb=mk(ob,"TextLabel",{Size=UDim2.new(1,-36,1,0),Position=UDim2.new(0,12,0,0),BackgroundTransparency=1,Text=opt,Font=Enum.Font.GothamMedium,TextSize=cfg.ts,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=9003})
		local ck=iconHolder(ob,"check",14,9003)ck.Position=UDim2.new(1,-22,.5,-7)ck.Visible=false
		ob.MouseEnter:Connect(function()if i~=sel then bg.BackgroundColor3=A.buttonsPressed.c end lb.TextColor3=A.names.c end)
		ob.MouseLeave:Connect(function()rf()end)
		ob.MouseButton1Click:Connect(function()sel=i v1.Text=opt rf()cb(opt,i)closeMenu()end)
		objs[i]={bg=bg,lb=lb,ck=ck}
	end
	rf()
	local function open()
		local ma=M.AbsolutePosition local ba=b.AbsolutePosition
		local x=ba.X-ma.X local y=ba.Y-ma.Y+b.AbsoluteSize.Y+5 local w=b.AbsoluteSize.X
		local tot=4+#opts*26+math.max(0,#opts-1)*2+4
		local mh=M.AbsoluteSize.Y local hh=math.min(tot,200)
		if y+hh>mh-6 then local yU=(ba.Y-ma.Y)-hh-5 if yU>=6 then y=yU else y=math.max(6,mh-hh-6)end end
		list.Position=UDim2.fromOffset(x,y)list.Size=UDim2.new(0,w,0,0)list.CanvasPosition=Vector2.new(0,0)list.Visible=true
		tw(list,{Size=UDim2.new(0,w,0,hh)},.2)
		ch:ClearAllChildren()ICON(ch,"chev",A.icons.c,14)ch.Rotation=180
	end
	local function close()
		ch:ClearAllChildren()ICON(ch,"chev",A.icons.c,14)ch.Rotation=0
		tw(list,{Size=UDim2.new(0,list.AbsoluteSize.X,0,0)},.16)task.delay(.2,function()list.Visible=false end)
	end
	b.MouseButton1Click:Connect(function()
		closeMenu()open()
		AM={c=close,isInside=function(mx,my)
			local ap,as=list.AbsolutePosition,list.AbsoluteSize
			if mx>=ap.X and mx<=ap.X+as.X and my>=ap.Y and my<=ap.Y+as.Y then return true end
			local bp,bs=b.AbsolutePosition,b.AbsoluteSize
			if mx>=bp.X and mx<=bp.X+bs.X and my>=bp.Y and my<=bp.Y+bs.Y then return true end
			return false
		end}
	end)
	return{h=h,set=function(v)for i,o in ipairs(opts)do if o==v then sel=i v1.Text=o rf()return end end end}
end

local function buildInput(parent,ph,def,cb,lbl,numOnly)
	local h=mk(parent,"Frame",{Size=UDim2.new(1,0,0,lbl and 44 or 34),BackgroundTransparency=1,ZIndex=4})
	if lbl then TT(mk(h,"TextLabel",{Size=UDim2.new(1,0,0,12),Position=UDim2.new(0,2,0,0),BackgroundTransparency=1,Text=lbl,Font=Enum.Font.GothamMedium,TextSize=cfg.ss,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=5}),"subtexts")end
	local box=BG2(TT(mk(h,"TextBox",{Size=UDim2.new(1,0,0,32),Position=UDim2.new(0,0,0,lbl and 14 or 0),BackgroundColor3=A.buttons.c,BackgroundTransparency=A.buttons.t,BorderSizePixel=0,Text=def,PlaceholderText=ph,PlaceholderColor3=PALS.textMut,Font=Enum.Font.GothamMedium,TextSize=cfg.ts,ClearTextOnFocus=false,TextXAlignment=Enum.TextXAlignment.Center,ZIndex=5}),"names"),"buttons")
	cr(box,8)stkBtn(box)
	if numOnly then box:GetPropertyChangedSignal("Text"):Connect(function()local cl=box.Text:gsub("[^%d]","")if cl~=box.Text then box.Text=cl end end)end
	box.FocusLost:Connect(function()cb(box.Text)end)
	return{h=h,set=function(v)box.Text=tostring(v)end,get=function()return box.Text end}
end

local function buildSwitch(parent,lbl,def,cb)
	local h=BG2(mk(parent,"Frame",{Size=UDim2.new(1,0,0,48),BackgroundColor3=A.buttons.c,BackgroundTransparency=A.buttons.t,BorderSizePixel=0,ZIndex=4}),"buttons")
	cr(h,9)stkBtn(h)
	TT(mk(h,"TextLabel",{Size=UDim2.new(1,-80,0,16),Position=UDim2.new(0,14,0,8),BackgroundTransparency=1,Text=lbl,Font=Enum.Font.GothamBold,TextSize=cfg.ts,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=5}),"names")
	local st=TT(mk(h,"TextLabel",{Size=UDim2.new(1,-80,0,14),Position=UDim2.new(0,14,0,26),BackgroundTransparency=1,Text=def and "On"or"Off",TextColor3=PALS.textMut,Font=Enum.Font.GothamMedium,TextSize=cfg.ss,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=5}),"subtexts")
	local tr=mk(h,"TextButton",{Size=UDim2.fromOffset(40,22),Position=UDim2.new(1,-54,.5,-11),BorderSizePixel=0,Text="",AutoButtonColor=false,ZIndex=5})
	cr(tr,999)
	local kn=mk(tr,"Frame",{Size=UDim2.new(0,18,0,18),Position=def and UDim2.new(1,-20,.5,-9)or UDim2.new(0,2,.5,-9),BackgroundColor3=CC(255,255,255),BorderSizePixel=0,ZIndex=6})
	cr(kn,999)
	local on=def
	local function setV(v)
		on=v
		local ap=v and A.toggleOn or A.toggleOff
		tr.BackgroundColor3=ap.c tr.BackgroundTransparency=ap.t
		tw(kn,{Position=v and UDim2.new(1,-20,.5,-9)or UDim2.new(0,2,.5,-9)},.22)
		st.Text=v and "On"or"Off"st.TextColor3=v and PALS.success or PALS.textMut
	end
	setV(def)
	tr.MouseButton1Click:Connect(function()setV(not on)if cb then cb(on)end end)
	return{h=h,setOn=setV,isOn=function()return on end,setStatus=function(t,c)st.Text=t st.TextColor3=c or PALS.textMut end}
end

local function buildButton(parent,lbl,kind,dn,hl)
	local b=BG2(mk(parent,"TextButton",{Size=hl and UDim2.new(.5,-3,1,0)or UDim2.new(1,0,0,34),BackgroundColor3=A.buttons.c,BackgroundTransparency=A.buttons.t,BorderSizePixel=0,Text="",AutoButtonColor=false,ZIndex=5}),"buttons")
	cr(b,8)local s=stkBtn(b)
	if kind then local ih=iconHolder(b,kind,16,6)ih.Position=UDim2.new(0,12,.5,-8)ih:ClearAllChildren()ICON(ih,kind,dn and PALS.danger or A.icons.c,16)end
	TT(mk(b,"TextLabel",{Size=UDim2.new(1,-38,1,0),Position=UDim2.new(0,34,0,0),BackgroundTransparency=1,Text=lbl,TextColor3=dn and PALS.danger or A.names.c,Font=Enum.Font.GothamBold,TextSize=cfg.ts,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=6}),"names")
	b.MouseEnter:Connect(function()b.BackgroundColor3=A.buttonsPressed.c s.Color=dn and PALS.danger or PALS.borderL end)
	b.MouseLeave:Connect(function()b.BackgroundColor3=A.buttons.c s.Color=A.buttonOutline.c end)
	return b
end

local function buildSlider(parent,lbl,def,cb)
	local h=mk(parent,"Frame",{Size=UDim2.new(1,0,0,44),BackgroundTransparency=1,ZIndex=4})
	TT(mk(h,"TextLabel",{Size=UDim2.new(1,-40,0,12),Position=UDim2.new(0,2,0,0),BackgroundTransparency=1,Text=lbl,Font=Enum.Font.GothamMedium,TextSize=cfg.ss,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=5}),"subtexts")
	local pct=TT(mk(h,"TextLabel",{Size=UDim2.new(0,40,0,12),Position=UDim2.new(1,-40,0,0),BackgroundTransparency=1,Text=math.floor(def*100+.5).."%",Font=Enum.Font.Code,TextSize=cfg.ss,TextXAlignment=Enum.TextXAlignment.Right,ZIndex=5}),"subtexts")
	local tr=BG2(mk(h,"TextButton",{Size=UDim2.new(1,0,0,8),Position=UDim2.new(0,0,0,26),BackgroundColor3=A.buttons.c,BackgroundTransparency=A.buttons.t,BorderSizePixel=0,Text="",AutoButtonColor=false,ZIndex=5}),"buttons")
	cr(tr,999)
	local fl=BG2(mk(tr,"Frame",{Size=UDim2.new(def,0,1,0),BackgroundColor3=A.selectedTab.c,BackgroundTransparency=A.selectedTab.t,BorderSizePixel=0,ZIndex=6}),"selectedTab")
	cr(fl,999)
	local kn=mk(tr,"Frame",{AnchorPoint=Vector2.new(.5,.5),Size=UDim2.fromOffset(14,14),Position=UDim2.new(def,0,.5,0),BackgroundColor3=CC(255,255,255),BorderSizePixel=0,ZIndex=7})
	cr(kn,999)
	local drag=false
	local function up(px)
		local ap,as=tr.AbsolutePosition,tr.AbsoluteSize
		local r=math.clamp((px-ap.X)/as.X,0,1)
		fl.Size=UDim2.new(r,0,1,0)kn.Position=UDim2.new(r,0,.5,0)
		pct.Text=math.floor(r*100+.5).."%"cb(r)
	end
	tr.InputBegan:Connect(function(i)if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then drag=true up(i.Position.X)end end)
	U.InputChanged:Connect(function(i)if drag and(i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch)then up(i.Position.X)end end)
	U.InputEnded:Connect(function(i)if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then drag=false end end)
	return{h=h,set=function(v)fl.Size=UDim2.new(v,0,1,0)kn.Position=UDim2.new(v,0,.5,0)pct.Text=math.floor(v*100+.5).."%"end,get=function()return def end}
end

local function buildAccordion(parent,lbl,kind,def)
	local h=mk(parent,"Frame",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,ZIndex=4})
	mk(h,"UIListLayout",{Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder})
	local hd=BG2(mk(h,"TextButton",{Size=UDim2.new(1,0,0,44),BackgroundColor3=A.buttons.c,BackgroundTransparency=A.buttons.t,BorderSizePixel=0,Text="",AutoButtonColor=false,ZIndex=5,LayoutOrder=1}),"buttons")
	cr(hd,9)stkBtn(hd)
	local ih=iconHolder(hd,kind,20,6)ih.Position=UDim2.new(0,14,.5,-10)
	TT(mk(hd,"TextLabel",{Size=UDim2.new(1,-60,1,0),Position=UDim2.new(0,44,0,0),BackgroundTransparency=1,Text=lbl,Font=Enum.Font.GothamBold,TextSize=cfg.ts,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=6}),"names")
	local ch=iconHolder(hd,"chev",14,6)ch.Position=UDim2.new(1,-26,.5,-7)
	local wrap=mk(h,"Frame",{Size=UDim2.new(1,0,0,0),BackgroundTransparency=1,ClipsDescendants=true,ZIndex=4,LayoutOrder=2})
	local c=mk(wrap,"Frame",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,ZIndex=4})
	mk(c,"UIListLayout",{Padding=UDim.new(0,14),SortOrder=Enum.SortOrder.LayoutOrder})
	local open=def or false
	local function applyOpen(anim)
		local targetH=open and c.AbsoluteSize.Y or 0
		if anim then tw(wrap,{Size=UDim2.new(1,0,0,targetH)},.3)
		else wrap.Size=UDim2.new(1,0,0,targetH)end
		ch.Rotation=open and 180 or 0
	end
	task.delay(.1,function()applyOpen(false)end)
	hd.MouseButton1Click:Connect(function()open=not open applyOpen(true)end)
	hd.MouseEnter:Connect(function()hd.BackgroundColor3=A.buttonsPressed.c end)
	hd.MouseLeave:Connect(function()hd.BackgroundColor3=A.buttons.c end)
	return c
end

-- COLOR PICKER
local pState={h=0,s=0,v=1,t=0,cb=nil}
local pPopup=mk(PL,"Frame",{Size=UDim2.new(1,0,1,0),BackgroundColor3=CC(0,0,0),BackgroundTransparency=.6,Visible=false,ZIndex=9400,Active=true})
local pCard=mk(pPopup,"Frame",{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.new(.5,0,.5,0),Size=UDim2.fromOffset(250,270),BackgroundColor3=PALS.surface,BorderSizePixel=0,ZIndex=9401,Active=true})
cr(pCard,12)sk(pCard,PALS.borderL,1)
local pTitle=mk(pCard,"TextLabel",{Size=UDim2.new(1,-40,0,18),Position=UDim2.new(0,15,0,12),BackgroundTransparency=1,Text="Color Editor",Font=Enum.Font.GothamBold,TextSize=cfg.ts,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=9402})
pTitle.TextColor3=A.selectedTab.c
local pClose=mk(pCard,"TextButton",{Size=UDim2.new(0,26,0,26),Position=UDim2.new(1,-36,0,8),BackgroundColor3=PALS.elev,BorderSizePixel=0,Text="",AutoButtonColor=false,ZIndex=9410})
cr(pClose,7)
local pCH=iconHolder(pClose,"x",18,9411)pCH.Position=UDim2.new(.5,-9,.5,-9)
local svH=mk(pCard,"Frame",{Size=UDim2.new(0,200,0,120),Position=UDim2.new(0,25,0,42),BackgroundTransparency=1,ZIndex=9402})
local svB=mk(svH,"Frame",{Size=UDim2.new(1,0,1,0),BackgroundColor3=CC(255,0,0),BorderSizePixel=0,ZIndex=9403})
cr(svB,7)
local wL=mk(svH,"Frame",{Size=UDim2.new(1,0,1,0),BackgroundColor3=CC(255,255,255),BorderSizePixel=0,ZIndex=9404})
cr(wL,7)
mk(wL,"UIGradient",{Rotation=0,Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(1,1)})})
local bL=mk(svH,"Frame",{Size=UDim2.new(1,0,1,0),BackgroundColor3=CC(0,0,0),BorderSizePixel=0,ZIndex=9405})
cr(bL,7)
mk(bL,"UIGradient",{Rotation=90,Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(1,0)})})
local svHandle=mk(svH,"Frame",{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.new(0,0,0,0),Size=UDim2.fromOffset(12,12),BackgroundTransparency=1,ZIndex=9406})
local svHo=mk(svHandle,"Frame",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,ZIndex=9407})
cr(svHo,999)sk(svHo,CC(255,255,255),2)
local hueS=mk(pCard,"Frame",{Size=UDim2.new(0,200,0,12),Position=UDim2.new(0,25,0,172),BorderSizePixel=0,ZIndex=9402})
cr(hueS,6)
mk(hueS,"UIGradient",{Rotation=0,Color=ColorSequence.new({ColorSequenceKeypoint.new(0,CC(255,0,0)),ColorSequenceKeypoint.new(.167,CC(255,255,0)),ColorSequenceKeypoint.new(.333,CC(0,255,0)),ColorSequenceKeypoint.new(.5,CC(0,255,255)),ColorSequenceKeypoint.new(.667,CC(0,0,255)),ColorSequenceKeypoint.new(.833,CC(255,0,255)),ColorSequenceKeypoint.new(1,CC(255,0,0))})})
local hueH=mk(hueS,"Frame",{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.new(0,0,.5,0),Size=UDim2.new(0,5,1,5),BackgroundColor3=CC(255,255,255),BorderSizePixel=0,ZIndex=9406})
cr(hueH,999)sk(hueH,CC(0,0,0,.6),1)
local trkS=mk(pCard,"Frame",{Size=UDim2.new(0,200,0,12),Position=UDim2.new(0,25,0,196),BackgroundColor3=CC(80,80,80),BorderSizePixel=0,ZIndex=9402})
cr(trkS,6)
local trkG=mk(trkS,"Frame",{Size=UDim2.new(1,0,1,0),BackgroundColor3=CC(255,255,255),BorderSizePixel=0,ZIndex=9403})
cr(trkG,6)
mk(trkG,"UIGradient",{Rotation=0,Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(1,1)})})
local trkH=mk(trkS,"Frame",{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.new(0,0,.5,0),Size=UDim2.new(0,4,1,6),BackgroundColor3=CC(255,255,255),BorderSizePixel=0,ZIndex=9406})
cr(trkH,999)sk(trkH,CC(0,0,0,.6),1)
local pvB=mk(pCard,"Frame",{Size=UDim2.new(0,38,0,26),Position=UDim2.new(0,25,0,220),BackgroundColor3=CC(255,255,255),BorderSizePixel=0,ZIndex=9403})
cr(pvB,6)sk(pvB,PALS.borderL,1)
local function h2r(h,s,v)
	local r,g,b=0,0,0
	if s==0 then r,g,b=v,v,v
	else
		local i=math.floor(h*6)local f=h*6-i
		local p=v*(1-s)local q=v*(1-f*s)local t=v*(1-(1-f)*s)
		i=i%6
		if i==0 then r,g,b=v,t,p elseif i==1 then r,g,b=q,v,p elseif i==2 then r,g,b=p,v,t elseif i==3 then r,g,b=p,q,v elseif i==4 then r,g,b=t,p,v else r,g,b=v,p,q end
	end
	return Color3.new(r,g,b)
end
local function c2h(c)
	local r,g,b=c.R,c.G,c.B
	local mx=math.max(r,g,b)local mn=math.min(r,g,b)
	local v=mx local d=mx-mn
	local s=mx==0 and 0 or d/mx
	local h=0
	if d~=0 then if mx==r then h=((g-b)/d)%6/6 elseif mx==g then h=((b-r)/d+2)/6 else h=((r-g)/d+4)/6 end end
	return h,s,v
end
local function pickerRefresh()
	local c=h2r(pState.h,pState.s,pState.v)
	svB.BackgroundColor3=Color3.fromHSV(pState.h,1,1)
	svHandle.Position=UDim2.new(pState.s,0,1-pState.v,0)
	hueH.Position=UDim2.new(pState.h,0,.5,0)
	trkH.Position=UDim2.new(pState.t,0,.5,0)
	pvB.BackgroundColor3=c pvB.BackgroundTransparency=pState.t
	if pState.cb then pcall(pState.cb,c,pState.t)end
end
local svD,hD,tD=false,false,false
svB.InputBegan:Connect(function(i)if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then svD=true local ap,as=svB.AbsolutePosition,svB.AbsoluteSize pState.s=math.clamp((i.Position.X-ap.X)/as.X,0,1)pState.v=1-math.clamp((i.Position.Y-ap.Y)/as.Y,0,1)pickerRefresh()end end)
hueS.InputBegan:Connect(function(i)if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then hD=true local ap,as=hueS.AbsolutePosition,hueS.AbsoluteSize pState.h=math.clamp((i.Position.X-ap.X)/as.X,0,1)pickerRefresh()end end)
trkS.InputBegan:Connect(function(i)if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then tD=true local ap,as=trkS.AbsolutePosition,trkS.AbsoluteSize pState.t=math.clamp((i.Position.X-ap.X)/as.X,0,1)pickerRefresh()end end)
U.InputChanged:Connect(function(i)
	if i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch then
		if svD then local ap,as=svB.AbsolutePosition,svB.AbsoluteSize pState.s=math.clamp((i.Position.X-ap.X)/as.X,0,1)pState.v=1-math.clamp((i.Position.Y-ap.Y)/as.Y,0,1)pickerRefresh()end
		if hD then local ap,as=hueS.AbsolutePosition,hueS.AbsoluteSize pState.h=math.clamp((i.Position.X-ap.X)/as.X,0,1)pickerRefresh()end
		if tD then local ap,as=trkS.AbsolutePosition,trkS.AbsoluteSize pState.t=math.clamp((i.Position.X-ap.X)/as.X,0,1)pickerRefresh()end
	end
end)
U.InputEnded:Connect(function(i)if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then svD=false hD=false tD=false end end)
local function openPicker(t,c,tp,cb)
	pState.cb=cb
	local h,s,v=c2h(c)
	pState.h=h pState.s=s pState.v=v pState.t=tp or 0
	pTitle.Text=t pPopup.Visible=true
	pickerRefresh()
end
pClose.MouseButton1Click:Connect(function()pPopup.Visible=false end)
pPopup.InputBegan:Connect(function(i)if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then local ap,as=pCard.AbsolutePosition,pCard.AbsoluteSize local mx,my=i.Position.X,i.Position.Y if not(mx>=ap.X and mx<=ap.X+as.X and my>=ap.Y and my<=ap.Y+as.Y)then pPopup.Visible=false end end end)

-- ============================================================
--  MAIN PAGE
-- ============================================================
do
	local sf=pageMain.sf
	local function featureCard(kind,title,desc)
		local card=BG2(mk(sf,"Frame",{Size=UDim2.new(1,0,0,72),BackgroundColor3=A.buttons.c,BackgroundTransparency=A.buttons.t,BorderSizePixel=0,ZIndex=4}),"buttons")
		cr(card,9)stkBtn(card)
		local ih=BG2(mk(card,"Frame",{Size=UDim2.fromOffset(32,32),Position=UDim2.new(0,14,.5,-16),BackgroundColor3=A.buttonsPressed.c,BackgroundTransparency=A.buttonsPressed.t,BorderSizePixel=0,ZIndex=5}),"buttonsPressed")
		cr(ih,8)
		local iinner=mk(ih,"Frame",{Size=UDim2.fromOffset(20,20),Position=UDim2.new(.5,-10,.5,-10),BackgroundTransparency=1,ZIndex=6})
		ICON(iinner,kind,A.selectedTab.c,20)
		TT(mk(card,"TextLabel",{Size=UDim2.new(1,-62,0,16),Position=UDim2.new(0,58,0,12),BackgroundTransparency=1,Text=title,Font=Enum.Font.GothamBold,TextSize=cfg.ts,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=5}),"names")
		TT(mk(card,"TextLabel",{Size=UDim2.new(1,-62,0,36),Position=UDim2.new(0,58,0,32),BackgroundTransparency=1,Text=desc,Font=Enum.Font.Gotham,TextSize=cfg.ss,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,ZIndex=5}),"subtexts")
	end
	featureCard("key","100% Keyless","This script is 100% keyless. No key needed.")
	featureCard("circleCheck","Everything You Want","Hitbox, ESP, Aimbot and more.")
	featureCard("eye","Smart ESP","See enemies through walls with full customization.")
	featureCard("cross","Precision Aimbot","Smooth aiming with FOV and filters.")
	local big=TT(mk(sf,"TextLabel",{Size=UDim2.new(1,0,0,64),BackgroundTransparency=1,Text="Everything You Want Erickzzz Universal Hub Has It.",Font=Enum.Font.GothamBold,TextSize=math.min(cfg.ts+2,100),TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Center,TextYAlignment=Enum.TextYAlignment.Center,ZIndex=4}),"names")
	big.TextColor3=A.selectedTab.c big.TextTransparency=0
	local uh=TT(mk(sf,"TextLabel",{Size=UDim2.new(1,0,0,18),BackgroundTransparency=1,Text="UPDATE LOGS",Font=Enum.Font.GothamBold,TextSize=cfg.ss,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=4}),"subtexts")
	local updates={
		{"v4.0","ESP completo, Aimbot, Sword icon, Team Checks"},
		{"v3.7","Smart Hitbox universal"},
		{"v3.0","Theme system"},
	}
	for _,up in ipairs(updates)do
		local row=BG2(mk(sf,"Frame",{Size=UDim2.new(1,0,0,50),BackgroundColor3=A.buttons.c,BackgroundTransparency=A.buttons.t,BorderSizePixel=0,ZIndex=4}),"buttons")
		cr(row,8)stkBtn(row)
		local ver=TT(mk(row,"TextLabel",{Size=UDim2.new(0,44,1,0),Position=UDim2.new(0,14,0,0),BackgroundTransparency=1,Text=up[1],Font=Enum.Font.GothamBold,TextSize=cfg.ts,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center,ZIndex=5}),"names")
		ver.TextColor3=A.selectedTab.c
		TT(mk(row,"TextLabel",{Size=UDim2.new(1,-66,1,0),Position=UDim2.new(0,58,0,0),BackgroundTransparency=1,Text=up[2],Font=Enum.Font.Gotham,TextSize=cfg.ss,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center,ZIndex=5}),"subtexts")
	end
end

-- ============================================================
--  ESP LOGIC
-- ============================================================
local espTracked={}
local HL_ESP="__ESP_HL"local CH_ESP="__ESP_CHAM"local BG_ESP="__ESP_BG"
local FOV_COLORS={White=CC(255,255,255),Red=CC(255,60,60),Green=CC(60,255,60),Blue=CC(60,120,255),Cyan=CC(0,255,255),Magenta=CC(255,0,255),Yellow=CC(255,255,0),Orange=CC(255,150,0)}
local fovCircle
do
	local c=mk(gui,"Frame",{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.new(.5,0,.5,0),Size=UDim2.new(0,cfg.aimFovSize,0,cfg.aimFovSize),BackgroundTransparency=1,BorderSizePixel=0,Visible=false,ZIndex=5})
	cr(c,999)sk(c,CC(255,255,255),2)
	fovCircle={f=c,s=c:FindFirstChildOfClass("UIStroke")}
end
local function updateFov()
	fovCircle.f.Size=UDim2.new(0,cfg.aimFovSize,0,cfg.aimFovSize)
	fovCircle.s.Color=FOV_COLORS[cfg.aimFovColor]or CC(255,255,255)
	fovCircle.s.Transparency=cfg.aimFovTransp
	fovCircle.f.Visible=cfg.aimActive and cfg.aimShowFov
end
local function sameTeam(m)local p=P:GetPlayerFromCharacter(m)if not p then return false end return p.Team~=nil and p.Team==LP.Team end
local function clearESP(m)
	if not m then return end
	local h=m:FindFirstChild(HL_ESP)if h then h:Destroy()end
	local c=m:FindFirstChild(CH_ESP)if c then c:Destroy()end
	local b=m:FindFirstChild(BG_ESP)if b then b:Destroy()end
	local d=espTracked[m]
	if d and d.c then for _,x in ipairs(d.c)do if x.Connected then x:Disconnect()end end end
	espTracked[m]=nil
end
local function buildESP(m)
	if m==LP.Character then return end
	clearESP(m)
	local data={c={},labels={}}
	if cfg.espHighlight then
		local h=Instance.new("Highlight")
		h.Name=HL_ESP h.FillColor=cfg.espColor h.OutlineColor=cfg.espColor
		h.FillTransparency=.6 h.OutlineTransparency=0
		h.DepthMode=Enum.HighlightDepthMode.Occluded
		h.Adornee=m h.Parent=m
		data.hl=h
	end
	if cfg.espChams then
		local ch=Instance.new("Highlight")
		ch.Name=CH_ESP ch.FillColor=cfg.espColor ch.OutlineColor=cfg.espColor
		ch.FillTransparency=.85 ch.OutlineTransparency=0
		ch.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
		ch.Adornee=m ch.Parent=m
		data.cham=ch
	end
	local head=m:FindFirstChild("Head")or m:FindFirstChild("UpperTorso")or m:FindFirstChild("Torso")
	if head and head:IsA("BasePart")then
		local bg=Instance.new("BillboardGui")
		bg.Name=BG_ESP bg.Size=UDim2.new(0,220,0,60)bg.StudsOffset=Vector3.new(0,2.5,0)
		bg.AlwaysOnTop=true bg.Adornee=head bg.Parent=head
		data.bg=bg
		local lbl=mk(bg,"TextLabel",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",Font=Enum.Font.GothamBold,TextSize=12,TextColor3=cfg.espColor,TextStrokeTransparency=0,TextStrokeColor3=CC(0,0,0),ZIndex=1})
		data.labels.info=lbl
	end
	table.insert(data.c,m.AncestryChanged:Connect(function()if not m.Parent then clearESP(m)end end))
	local hum=m:FindFirstChildOfClass("Humanoid")
	if hum then table.insert(data.c,hum.Died:Connect(function()clearESP(m)end))end
	espTracked[m]=data
end
local function updateESP()
	for m,data in pairs(espTracked)do
		if not m.Parent then clearESP(m)
		else
			if data.hl then data.hl.FillColor=cfg.espColor data.hl.OutlineColor=cfg.espColor end
			if data.cham then data.cham.FillColor=cfg.espColor data.cham.OutlineColor=cfg.espColor end
			if data.labels and data.labels.info then
				local parts={}
				local hum=m:FindFirstChildOfClass("Humanoid")
				if cfg.espName then local p=P:GetPlayerFromCharacter(m)table.insert(parts,p and p.Name or m.Name)end
				if cfg.espHealth and hum then table.insert(parts,string.format("HP:%d/%d",math.floor(hum.Health),math.floor(hum.MaxHealth)))end
				if cfg.espTool then local t=m:FindFirstChildOfClass("Tool")if t then table.insert(parts,"["..t.Name.."]")end end
				if cfg.espDistance then local h=m:FindFirstChild("Head")if h then local cam=workspace.CurrentCamera local d=(h.Position-cam.CFrame.Position).Magnitude table.insert(parts,string.format("%dm",math.floor(d+.5)))end end
				data.labels.info.Text=table.concat(parts,"  ")
				data.labels.info.TextColor3=cfg.espColor
				data.bg.Enabled=(#parts>0)
			end
		end
	end
end
local function applyESP()
	if not cfg.espActive then
		for m in pairs(espTracked)do clearESP(m)end
		return
	end
	for m in pairs(espTracked)do clearESP(m)end
	for _,o in ipairs(workspace:GetDescendants())do
		if o:IsA("Humanoid")then
			local m=o.Parent
			if m and m:IsA("Model")and m~=LP.Character then
				if not(cfg.espTeamCheck and sameTeam(m))then buildESP(m)end
			end
		end
	end
	for _,p in ipairs(P:GetPlayers())do
		if p~=LP and p.Character then
			if not(cfg.espTeamCheck and sameTeam(p.Character))then buildESP(p.Character)end
		end
	end
end

-- AIMBOT
local DrawingAPI=rawget(_G,"Drawing")
local skelData={}
local BONES_R15={{"Head","UpperTorso"},{"UpperTorso","LowerTorso"},{"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},{"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},{"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},{"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"}}
local BONES_R6={{"Head","Torso"},{"Torso","Left Arm"},{"Torso","Right Arm"},{"Torso","Left Leg"},{"Torso","Right Leg"}}
local function clearSkel(m)local d=skelData[m]if d then for _,l in ipairs(d.lines)do pcall(function()l:Remove()end)end end skelData[m]=nil end
local function createSkel(m)
	if not DrawingAPI or m==LP.Character then return end
	clearSkel(m)
	local bones= m:FindFirstChild("UpperTorso")and BONES_R15 or(m:FindFirstChild("Torso")and BONES_R6)
	if not bones then return end
	local lines={}
	for i=1,#bones do local l=DrawingAPI.new("Line")l.Thickness=1 l.Transparency=1 l.Visible=false table.insert(lines,l)end
	skelData[m]={lines=lines,bones=bones}
end
local function updateSkel()
	if not DrawingAPI then return end
	if not cfg.espSkeleton then for m in pairs(skelData)do clearSkel(m)end return end
	local cam=workspace.CurrentCamera
	for m,data in pairs(skelData)do
		if not m.Parent then clearSkel(m)
		else
			local skip=false
			if cfg.espTeamCheck then local p=P:GetPlayerFromCharacter(m)skip=p and p.Team==LP.Team end
			for i,b in ipairs(data.bones)do
				local a1=m:FindFirstChild(b[1])local a2=m:FindFirstChild(b[2])
				local l=data.lines[i]
				if a1 and a2 and a1:IsA("BasePart")and a2:IsA("BasePart")and not skip then
					local p1,on1=cam:WorldToViewportPoint(a1.Position)
					local p2,on2=cam:WorldToViewportPoint(a2.Position)
					if on1 and on2 then l.From=Vector2.new(p1.X,p1.Y)l.To=Vector2.new(p2.X,p2.Y)l.Color=cfg.espColor l.Visible=true else l.Visible=false end
				else l.Visible=false end
			end
		end
	end
end
local function getAimPart(m)
	if cfg.aimPart=="Head"then return m:FindFirstChild("Head")end
	return m:FindFirstChild("UpperTorso")or m:FindFirstChild("Torso")
end
local function isValidAim(m)
	if m==LP.Character or not m.Parent then return false end
	local hum=m:FindFirstChildOfClass("Humanoid")
	if not hum then return false end
	local p=P:GetPlayerFromCharacter(m)
	local npc=not p
	if cfg.target=="NPCs"and not npc then return false end
	if cfg.target=="Players"and npc then return false end
	if cfg.aimTeamCheck and p and p.Team==LP.Team then return false end
	if cfg.aimWalkCheck and hum.MoveDirection.Magnitude>.1 then return false end
	if cfg.aimDeathCheck and hum.Health<=0 then return false end
	local part=getAimPart(m)
	return part and part:IsA("BasePart")
end
local function findAimTarget()
	local cam=workspace.CurrentCamera
	local center=Vector2.new(cam.ViewportSize.X/2,cam.ViewportSize.Y/2)
	local best=nil local bd=cfg.aimFovSize/2
	for _,o in ipairs(workspace:GetDescendants())do
		if o:IsA("Humanoid")then
			local m=o.Parent
			if m and m:IsA("Model")and isValidAim(m)then
				local p=getAimPart(m)
				if p then
					local scr,on=cam:WorldToViewportPoint(p.Position)
					if on then
						local d=(Vector2.new(scr.X,scr.Y)-center).Magnitude
						if d<bd then bd=d best=p end
					end
				end
			end
		end
	end
	return best
end

-- ============================================================
--  HITBOX PAGE
-- ============================================================
local targetDD,partDD,formatDD,sizeInput,transpInput
local espColorBtn
local aimFovColorDD,aimTranspSlider,aimFovSizeInput,aimSmoothSlider,aimPartDD
local hbSwitch
do
	local sf=pageHb.sf
	local accHb=buildAccordion(sf,"Hitbox Expander","sword",true)
	targetDD=buildDropdown(accHb,"Target Type",{"NPCs","Players","Both"},3,function(v)cfg.target=v if cfg.active then rebuildAll()end end)
	partDD=buildDropdown(accHb,"Hitbox Part",{"Head","UpperTorso","Torso","HumanoidRootPart","LowerTorso","Any"},1,function(v)cfg.part=v if cfg.active then rebuildAll()end end)
	formatDD=buildDropdown(accHb,"Shape",{"Ball","Block","Cylinder"},2,function(v)cfg.format=v if cfg.active then applyAll()end end)
	local hclr=BG2(mk(accHb,"TextButton",{Size=UDim2.new(1,0,0,38),BackgroundColor3=A.buttons.c,BackgroundTransparency=A.buttons.t,BorderSizePixel=0,Text="",AutoButtonColor=false,ZIndex=4}),"buttons")
	cr(hclr,8)stkBtn(hclr)
	local hSw=mk(hclr,"Frame",{Size=UDim2.fromOffset(22,22),Position=UDim2.new(0,10,.5,-11),BackgroundColor3=cfg.color,BorderSizePixel=0,ZIndex=5})
	cr(hSw,6)sk(hSw,PALS.borderL,1)
	TT(mk(hclr,"TextLabel",{Size=UDim2.new(1,-60,1,0),Position=UDim2.new(0,40,0,0),BackgroundTransparency=1,Text="Hitbox Color",Font=Enum.Font.GothamMedium,TextSize=cfg.ts,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=5}),"names")
	hclr.MouseButton1Click:Connect(function()openPicker("Hitbox Color",cfg.color,0,function(c)cfg.color=c hSw.BackgroundColor3=c if cfg.active then applyAll()end end)end)
	local row=mk(accHb,"Frame",{Size=UDim2.new(1,0,0,34),BackgroundTransparency=1,ZIndex=4})
	mk(row,"UIListLayout",{Padding=UDim.new(0,8),FillDirection=Enum.FillDirection.Horizontal})
	sizeInput=buildInput(row,"5","5",function(v)cfg.size=math.clamp(tonumber(v)or 5,1,200)if cfg.active then applyAll()end end,nil,true)
	transpInput=buildInput(row,"0.5","0.5",function(v)cfg.transp=math.clamp(tonumber(v)or.5,0,1)if cfg.active then applyAll()end end,nil,true)
	sizeInput.h.Size=UDim2.new(.5,-4,1,0)
	transpInput.h.Size=UDim2.new(.5,-4,1,0)
	transpInput.h.Position=UDim2.new(.5,4,0,0)
	buildSwitch(accHb,"Team Check",cfg.hbTeamCheck,function(on)cfg.hbTeamCheck=on if cfg.active then rebuildAll()end end)
	hbSwitch=buildSwitch(accHb,"Hitbox Expander",false,function(on)setHitboxActive(on)end)
	_G.__hbSwitch=hbSwitch

	-- ESP
	local accEsp=buildAccordion(sf,"ESP","eye",false)
	espColorBtn=BG2(mk(accEsp,"TextButton",{Size=UDim2.new(1,0,0,38),BackgroundColor3=A.buttons.c,BackgroundTransparency=A.buttons.t,BorderSizePixel=0,Text="",AutoButtonColor=false,ZIndex=4}),"buttons")
	cr(espColorBtn,8)stkBtn(espColorBtn)
	local eSw=mk(espColorBtn,"Frame",{Size=UDim2.fromOffset(22,22),Position=UDim2.new(0,10,.5,-11),BackgroundColor3=cfg.espColor,BorderSizePixel=0,ZIndex=5})
	cr(eSw,6)sk(eSw,PALS.borderL,1)
	TT(mk(espColorBtn,"TextLabel",{Size=UDim2.new(1,-60,1,0),Position=UDim2.new(0,40,0,0),BackgroundTransparency=1,Text="ESP Color",Font=Enum.Font.GothamMedium,TextSize=cfg.ts,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=5}),"names")
	espColorBtn.MouseButton1Click:Connect(function()openPicker("ESP Color",cfg.espColor,0,function(c)cfg.espColor=c eSw.BackgroundColor3=c end)end)
	buildSwitch(accEsp,"ESP Toggle",cfg.espActive,function(on)cfg.espActive=on applyESP()if DrawingAPI and on and cfg.espSkeleton then for _,o in ipairs(workspace:GetDescendants())do if o:IsA("Humanoid")then local m=o.Parent if m and m:IsA("Model")then createSkel(m)end end end end if not on then for m in pairs(skelData)do clearSkel(m)end end end)
	buildSwitch(accEsp,"Highlight",cfg.espHighlight,function(on)cfg.espHighlight=on if cfg.espActive then applyESP()end end)
	buildSwitch(accEsp,"Chams (Through Walls)",cfg.espChams,function(on)cfg.espChams=on if cfg.espActive then applyESP()end end)
	buildSwitch(accEsp,"Skeleton",cfg.espSkeleton,function(on)cfg.espSkeleton=on if DrawingAPI then if on then for _,o in ipairs(workspace:GetDescendants())do if o:IsA("Humanoid")then local m=o.Parent if m and m:IsA("Model")then createSkel(m)end end end else for m in pairs(skelData)do clearSkel(m)end end end end)
	buildSwitch(accEsp,"Health ESP",cfg.espHealth,function(on)cfg.espHealth=on end)
	buildSwitch(accEsp,"Name ESP",cfg.espName,function(on)cfg.espName=on end)
	buildSwitch(accEsp,"Distance ESP",cfg.espDistance,function(on)cfg.espDistance=on end)
	buildSwitch(accEsp,"Tool ESP",cfg.espTool,function(on)cfg.espTool=on end)
	buildSwitch(accEsp,"Team Check",cfg.espTeamCheck,function(on)cfg.espTeamCheck=on if cfg.espActive then applyESP()end end)

	-- AIMBOT
	local accAim=buildAccordion(sf,"Aimbot","cross",false)
	buildSwitch(accAim,"Show FOV",cfg.aimShowFov,function(on)cfg.aimShowFov=on updateFov()end)
	buildSwitch(accAim,"Aimbot Toggle",cfg.aimActive,function(on)cfg.aimActive=on updateFov()end)
	aimFovColorDD=buildDropdown(accAim,"FOV Color",{"White","Red","Green","Blue","Cyan","Magenta","Yellow","Orange"},1,function(v)cfg.aimFovColor=v updateFov()end)
	aimTranspSlider=buildSlider(accAim,"FOV Transparency",cfg.aimFovTransp,function(v)cfg.aimFovTransp=v updateFov()end)
	aimFovSizeInput=buildInput(accAim,"120",""..cfg.aimFovSize,function(v)cfg.aimFovSize=math.clamp(tonumber(v)or 120,20,800)aimFovSizeInput.set(cfg.aimFovSize)updateFov()end,"FOV Size",true)
	aimSmoothSlider=buildSlider(accAim,"Smoothness",cfg.aimSmooth,function(v)cfg.aimSmooth=v end)
	aimPartDD=buildDropdown(accAim,"Aimbot Part",{"Head","Torso"},1,function(v)cfg.aimPart=v end)
	buildSwitch(accAim,"Team Check",cfg.aimTeamCheck,function(on)cfg.aimTeamCheck=on end)
	buildSwitch(accAim,"Walk Check",cfg.aimWalkCheck,function(on)cfg.aimWalkCheck=on end)
	buildSwitch(accAim,"Death Check",cfg.aimDeathCheck,function(on)cfg.aimDeathCheck=on end)
end

-- ============================================================
--  CONFIGS PAGE
-- ============================================================
do
	local sf=pageCfg.sf
	local function header(txt,col)
		TT(mk(sf,"TextLabel",{Size=UDim2.new(1,0,0,22),BackgroundTransparency=1,Text=txt,TextColor3=col or PALS.textMut,Font=Enum.Font.GothamBold,TextSize=cfg.ss,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Bottom,ZIndex=4}),"subtexts")
	end
	header("CONFIGURATIONS")
	local saveBox=buildInput(sf,"Name...","",function()end,"Configuration Name")
	local saveBtn=buildButton(sf,"SAVE CONFIGURATION","save",false)
	saveBtn.MouseButton1Click:Connect(function()end)
	header("THEME")
	buildDropdown(sf,"Built-in Theme",{"Default Blue","Crimson","Honey","Forest Green","Dark Mode","Light Mode"},1,function(name)
		cfg.theme=name
		local t=THEMES[name]
		if t then for k,v in pairs(t)do A[k].c=v A[k].t=0 end applyTheme()end
	end)
	header("BACKGROUND MEDIA")
	local bgPrev=BG2(mk(sf,"TextButton",{Size=UDim2.new(1,0,0,90),BackgroundColor3=A.buttons.c,BackgroundTransparency=A.buttons.t,BorderSizePixel=0,Text="",AutoButtonColor=false,ZIndex=4}),"buttons")
	cr(bgPrev,8)stkBtn(bgPrev)
	local prevImg=mk(bgPrev,"ImageLabel",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Image="",ScaleType=Enum.ScaleType.Crop,ZIndex=5})
	cr(prevImg,8)
	local prevLbl=TT(mk(bgPrev,"TextLabel",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="Click to Select Background",Font=Enum.Font.GothamBold,TextSize=cfg.ts,TextXAlignment=Enum.TextXAlignment.Center,ZIndex=6}),"names")
	bgPrev.MouseButton1Click:Connect(function()openSearchPopup(function(id)prevImg.Image=thumb(id)BGImg.Image=thumb(id)prevLbl.Text=""end)end)
	local bgRow=mk(sf,"Frame",{Size=UDim2.new(1,0,0,32),BackgroundTransparency=1,ZIndex=4})
	mk(bgRow,"UIListLayout",{Padding=UDim.new(0,6),FillDirection=Enum.FillDirection.Horizontal})
	local clrBtn=buildButton(bgRow,"CLEAR","trash",true,true)
	clrBtn.MouseButton1Click:Connect(function()prevImg.Image=""BGImg.Image=""prevLbl.Text="Click to Select Background"end)
	header("UI SIZE")
	local r1=mk(sf,"Frame",{Size=UDim2.new(1,0,0,44),BackgroundTransparency=1,ZIndex=4})
	mk(r1,"UIListLayout",{Padding=UDim.new(0,6),FillDirection=Enum.FillDirection.Horizontal})
	local uwIn=buildInput(r1,"400",""..cfg.uw,function(v)cfg.uw=math.clamp(tonumber(v)or cfg.uw,200,1000)M.Size=UDim2.new(0,cfg.uw,0,cfg.uh)uwIn.set(cfg.uw)end,"Width (200-1000)",true)
	uwIn.h.Size=UDim2.new(.5,-3,1,0)
	local uhIn=buildInput(r1,"459",""..cfg.uh,function(v)cfg.uh=math.clamp(tonumber(v)or cfg.uh,200,1000)M.Size=UDim2.new(0,cfg.uw,0,cfg.uh)uhIn.set(cfg.uh)end,"Height (200-1000)",true)
	uhIn.h.Size=UDim2.new(.5,-3,1,0)uhIn.h.Position=UDim2.new(.5,3,0,0)
	local r2=mk(sf,"Frame",{Size=UDim2.new(1,0,0,44),BackgroundTransparency=1,ZIndex=4})
	mk(r2,"UIListLayout",{Padding=UDim.new(0,6),FillDirection=Enum.FillDirection.Horizontal})
	local tsIn=buildInput(r2,"11",""..cfg.ts,function(v)cfg.ts=math.clamp(tonumber(v)or cfg.ts,10,100)tsIn.set(cfg.ts)end,"Text Size (10-100)",true)
	tsIn.h.Size=UDim2.new(.5,-3,1,0)
	local ssIn=buildInput(r2,"9",""..cfg.ss,function(v)cfg.ss=math.clamp(tonumber(v)or cfg.ss,10,100)ssIn.set(cfg.ss)end,"Subtext Size (10-100)",true)
	ssIn.h.Size=UDim2.new(.5,-3,1,0)ssIn.h.Position=UDim2.new(.5,3,0,0)
	header("RESET",PALS.danger)
	local rb=buildButton(sf,"RESET EVERYTHING","refresh",true)
	rb.MouseButton1Click:Connect(function()
		for k,v in pairs(THEMES["Default Blue"])do A[k].c=v A[k].t=0 end
		cfg.theme="Default Blue"cfg.uw=400 cfg.uh=459 cfg.ts=11 cfg.ss=9
		cfg.size=5 cfg.transp=.5 cfg.color=CC(108,138,255)
		cfg.espActive=false cfg.espColor=CC(255,80,80)
		cfg.aimActive=false cfg.aimFovColor="White"cfg.aimFovTransp=.5 cfg.aimFovSize=120 cfg.aimSmooth=.5
		M.Size=UDim2.new(0,400,0,459)
		BGImg.Image=""
		if prevImg then prevImg.Image=""prevLbl.Text="Click to Select Background"end
		applyTheme()updateFov()
	end)
end

-- ============================================================
--  SEARCH POPUP
-- ============================================================
local searchPopup
local function doSearch(q)
	for _,c in ipairs(searchPopup.results:GetChildren())do if c:IsA("Frame")or c:IsA("TextLabel")then c:Destroy()end end
	if q==""then return end
	local list=searchCat(q)
	if #list==0 then TT(mk(searchPopup.results,"TextLabel",{Size=UDim2.new(1,0,0,26),BackgroundTransparency=1,Text="- no results -",TextColor3=PALS.textMut,Font=Enum.Font.Gotham,TextSize=cfg.ss,ZIndex=9605}),"subtexts")return end
	for i,item in ipairs(list)do
		local id=item.id or item.assetId
		if id then
			local row=mk(searchPopup.results,"Frame",{Size=UDim2.new(1,0,0,56),BackgroundColor3=PALS.surface,BorderSizePixel=0,ZIndex=9604,LayoutOrder=i})
			cr(row,8)sk(row,PALS.border)
			local th=mk(row,"ImageLabel",{Size=UDim2.new(0,46,0,46),Position=UDim2.new(0,5,.5,-23),BackgroundColor3=PALS.surface,BorderSizePixel=0,Image=thumb(id),ScaleType=Enum.ScaleType.Crop,ZIndex=9605})
			cr(th,6)
			TT(mk(row,"TextLabel",{Size=UDim2.new(1,-130,0,16),Position=UDim2.new(0,58,0,8),BackgroundTransparency=1,Text=(item.name or item.Name or"Unnamed"):sub(1,30),Font=Enum.Font.GothamMedium,TextSize=cfg.ts,TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd,ZIndex=9605}),"names")
			local sb=TT(mk(row,"TextLabel",{Size=UDim2.new(1,-130,0,12),Position=UDim2.new(0,58,0,26),BackgroundTransparency=1,Text="ID: "..id,Font=Enum.Font.Code,TextSize=cfg.ss,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=9605}),"subtexts")
			local sel=mk(row,"TextButton",{Size=UDim2.new(0,64,0,26),Position=UDim2.new(1,-70,.5,-13),BackgroundColor3=A.selectedTab.c,BorderSizePixel=0,Text="Select",TextColor3=CC(255,255,255),Font=Enum.Font.GothamBold,TextSize=cfg.ts,AutoButtonColor=false,ZIndex=9606})
			cr(sel,6)
			sel.MouseButton1Click:Connect(function()if searchPopup.pick then searchPopup.pick(id)end searchPopup.hide()end)
		end
	end
end
searchPopup=(function()
	local root=mk(PL,"Frame",{Size=UDim2.new(1,0,1,0),BackgroundColor3=CC(0,0,0),BackgroundTransparency=.7,Visible=false,ZIndex=9600,Active=true})
	local card=mk(root,"Frame",{AnchorPoint=Vector2.new(.5,.5),Position=UDim2.new(.5,0,.5,0),Size=UDim2.fromOffset(290,290),BackgroundColor3=PALS.surface,BorderSizePixel=0,ZIndex=9601,Active=true})
	cr(card,14)sk(card,PALS.borderL,1)
	local hdr=mk(card,"Frame",{Size=UDim2.new(1,0,0,34),BackgroundColor3=PALS.elev,BorderSizePixel=0,ZIndex=9602})
	cr(hdr,14)
	mk(hdr,"Frame",{Size=UDim2.new(1,0,0,12),Position=UDim2.new(0,0,1,-12),BackgroundColor3=PALS.elev,BorderSizePixel=0,ZIndex=9602})
	TT(mk(hdr,"TextLabel",{Size=UDim2.new(1,-40,1,0),Position=UDim2.new(0,12,0,0),BackgroundTransparency=1,Text="Select Background",Font=Enum.Font.GothamBold,TextSize=cfg.ts,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=9603}),"names")
	local cx=mk(hdr,"TextButton",{Size=UDim2.new(0,24,0,24),Position=UDim2.new(1,-30,.5,-12),BackgroundColor3=PALS.danger,BorderSizePixel=0,Text="X",TextColor3=CC(255,255,255),Font=Enum.Font.GothamBold,TextSize=12,AutoButtonColor=false,ZIndex=9604})
	cr(cx,7)
	cx.MouseButton1Click:Connect(function()root.Visible=false end)
	local sb=mk(card,"TextBox",{Size=UDim2.new(1,-108,0,30),Position=UDim2.new(0,12,0,42),BackgroundColor3=PALS.elev,BorderSizePixel=0,Text="",PlaceholderText="Search images...",PlaceholderColor3=PALS.textMut,TextColor3=A.names.c,Font=Enum.Font.GothamMedium,TextSize=cfg.ts,ClearTextOnFocus=false,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=9603})
	cr(sb,8)sk(sb,PALS.borderL,1)
	mk(sb,"UIPadding",{PaddingLeft=UDim.new(0,10)})
	local sBtn=mk(card,"TextButton",{Size=UDim2.new(0,78,0,30),Position=UDim2.new(1,-90,0,42),BackgroundColor3=A.selectedTab.c,BorderSizePixel=0,Text="Search",TextColor3=CC(255,255,255),Font=Enum.Font.GothamBold,TextSize=cfg.ts,AutoButtonColor=false,ZIndex=9603})
	cr(sBtn,8)
	sBtn.MouseButton1Click:Connect(function()doSearch(sb.Text)end)
	sb.FocusLost:Connect(function(e)if e then doSearch(sb.Text)end end)
	local results=mk(card,"ScrollingFrame",{Size=UDim2.new(1,-20,1,-90),Position=UDim2.new(0,10,0,80),BackgroundTransparency=1,BorderSizePixel=0,CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollingDirection=Enum.ScrollingDirection.Y,ElasticBehavior=Enum.ElasticBehavior.WhenScrollable,ScrollBarThickness=3,ScrollBarImageColor3=PALS.borderL,ScrollBarImageTransparency=.4,ZIndex=9603})
	mk(results,"UIListLayout",{Padding=UDim.new(0,6),SortOrder=Enum.SortOrder.LayoutOrder})
	root.InputBegan:Connect(function(i)if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then local ap,as=card.AbsolutePosition,card.AbsoluteSize local mx,my=i.Position.X,i.Position.Y if not(mx>=ap.X and mx<=ap.X+as.X and my>=ap.Y and my<=ap.Y+as.Y)then root.Visible=false end end end)
	return{root=root,results=results,hide=function()root.Visible=false end,show=function(cb)
		searchPopup.pick=cb root.Visible=true
		for _,c in ipairs(results:GetChildren())do if c:IsA("Frame")or c:IsA("TextLabel")then c:Destroy()end end
	end}
end)()
local function openSearchPopup(cb)searchPopup.show(cb)end

-- ============================================================
--  HITBOX LOGIC
-- ============================================================
local HB_NAME="HB_Erick"
local tracked={}
local queue={}
local CANDIDATES={"Head","UpperTorso","Torso","HumanoidRootPart","LowerTorso"}
local function isPlayerChar(m)return P:GetPlayerFromCharacter(m)~=nil end
local function isCharModel(m)
	if typeof(m)~="Instance"or not m:IsA("Model")or not m.Parent then return false end
	if m==LP.Character then return false end
	if m:FindFirstChildOfClass("Humanoid")then return true end
	local h=m:FindFirstChild("Head")
	if h and h:IsA("BasePart")then
		local c=0
		for _,ch in ipairs(m:GetChildren())do if ch:IsA("BasePart")then c+=1 if c>=2 then return true end end end
	end
	return false
end
local function shouldTrack(m)
	if not isCharModel(m)then return false end
	local hum=m:FindFirstChildOfClass("Humanoid")
	if hum and hum.Health<=0 then return false end
	local isP=isPlayerChar(m)
	if cfg.target=="NPCs"and isP then return false end
	if cfg.target=="Players"and not isP then return false end
	if cfg.hbTeamCheck and isP then local p=P:GetPlayerFromCharacter(m)if p and p.Team==LP.Team then return false end end
	return true
end
local function getPart(m)
	if cfg.part=="Any"then for _,c in ipairs(m:GetChildren())do if c:IsA("BasePart")then return c end end return end
	local p=m:FindFirstChild(cfg.part)if p and p:IsA("BasePart")then return p end
	for _,n in ipairs(CANDIDATES)do local f=m:FindFirstChild(n)if f and f:IsA("BasePart")then return f end end
	for _,c in ipairs(m:GetChildren())do if c:IsA("BasePart")then return c end end
end
local function partType()
	if cfg.format=="Ball"then return Enum.PartType.Ball end
	if cfg.format=="Cylinder"then return Enum.PartType.Cylinder end
	return Enum.PartType.Block
end
function applyHitbox(m)
	local part=getPart(m)if not part then return end
	local hb=m:FindFirstChild(HB_NAME)
	local nn=false
	if not hb or not hb:IsA("Part")then if hb then hb:Destroy()end nn=true
	elseif hb.Shape~=partType()then hb:Destroy()nn=true end
	if nn then
		hb=Instance.new("Part")
		hb.Name=HB_NAME hb.Shape=partType()hb.Material=Enum.Material.ForceField
		hb.Color=cfg.color hb.CanCollide=false hb.CanQuery=true hb.CanTouch=true
		hb.Massless=true hb.CastShadow=false hb.Anchored=part.Anchored
		hb.CFrame=part.CFrame hb.Parent=m
		if not part.Anchored then local w=Instance.new("WeldConstraint")w.Part0=hb w.Part1=part w.Parent=hb end
	end
	hb.Color=cfg.color
	local sz=Vector3.new(cfg.size,cfg.size,cfg.size)
	if hb.Size~=sz then hb.Size=sz end
	if hb.Transparency~=cfg.transp then hb.Transparency=cfg.transp end
	if part.Anchored then hb.CFrame=part.CFrame end
end
local function removeHB(m)
	if not m then return end
	local hb=m:FindFirstChild(HB_NAME)if hb then hb:Destroy()end
	local d=tracked[m]
	if d then for _,c in ipairs(d)do if c.Connected then c:Disconnect()end end end
	tracked[m]=nil
end
local function updateStatus()
	local c=0 for _ in pairs(tracked)do c+=1 end
	if _G.__hbSwitch then
		if cfg.active then _G.__hbSwitch.setStatus("Active - "..c.." target"..(c==1 and""or"s"),PALS.success)
		else _G.__hbSwitch.setStatus("Inactive",PALS.textMut)end
	end
end
local function track(m)
	if tracked[m]then return end
	if not shouldTrack(m)then return end
	local c={}
	local h=m:FindFirstChildOfClass("Humanoid")
	if h then table.insert(c,h.Died:Connect(function()removeHB(m)updateStatus()end))end
	table.insert(c,m.ChildRemoved:Connect(function(ch)if ch.Name==cfg.part or ch.Name=="Head"then removeHB(m)updateStatus()end end))
	table.insert(c,m.AncestryChanged:Connect(function()if not m.Parent then removeHB(m)updateStatus()end end))
	tracked[m]=c
	if cfg.active then applyHitbox(m)updateStatus()end
end
local function queueTrack(m)
	if tracked[m]or queue[m]then return end
	queue[m]=true
	task.defer(function()
		task.wait(.1)queue[m]=nil
		if m.Parent and shouldTrack(m)then track(m)end
	end)
end
local function scanAll()
	for _,o in ipairs(workspace:GetDescendants())do
		if o:IsA("Humanoid")then local m=o.Parent if m and m:IsA("Model")then queueTrack(m)end
		elseif o:IsA("Model")then local h=o:FindFirstChild("Head")if h and h:IsA("BasePart")and not o:FindFirstChildOfClass("Humanoid")then queueTrack(o)end end
	end
	for _,p in ipairs(P:GetPlayers())do if p~=LP and p.Character then queueTrack(p.Character)end end
end
function rebuildAll()
	for m in pairs(tracked)do removeHB(m)end
	tracked={}
	if not cfg.active then updateStatus()return end
	scanAll()
end
function applyAll()
	for m in pairs(tracked)do applyHitbox(m)end
end
workspace.DescendantAdded:Connect(function(o)
	if not cfg.active then return end
	if o:IsA("Humanoid")then local m=o.Parent if m and m:IsA("Model")then queueTrack(m)end
	elseif o:IsA("Model")then task.defer(function()if o.Parent and o:FindFirstChild("Head")and not o:FindFirstChildOfClass("Humanoid")then queueTrack(o)end end)end
end)
P.PlayerAdded:Connect(function(plr)
	plr.CharacterAdded:Connect(function(c)
		if cfg.active then queueTrack(c)end
		if cfg.espActive and not(cfg.espTeamCheck and plr.Team==LP.Team)then buildESP(c)end
		if DrawingAPI and cfg.espSkeleton then createSkel(c)end
	end)
end)
for _,p in ipairs(P:GetPlayers())do
	if p~=LP then
		p.CharacterAdded:Connect(function(c)
			if cfg.active then queueTrack(c)end
			if cfg.espActive and not(cfg.espTeamCheck and p.Team==LP.Team)then buildESP(c)end
			if DrawingAPI and cfg.espSkeleton then createSkel(c)end
		end)
	end
end
LP.CharacterAdded:Connect(function()
	if cfg.active then task.wait(.3)rebuildAll()end
	if cfg.espActive then task.wait(.3)applyESP()end
end)
function setHitboxActive(on)
	cfg.active=on
	if on then
		task.wait(.05)scanAll()updateStatus()
		task.delay(.5,function()if cfg.active then scanAll()updateStatus()end end)
	else
		local l={}for m in pairs(tracked)do table.insert(l,m)end
		for _,m in ipairs(l)do removeHB(m)end
		tracked={}updateStatus()
	end
end

-- ============================================================
--  WIRING
-- ============================================================
U.InputBegan:Connect(function(i,gpe)if gpe then return end if not AM then return end if i.UserInputType~=Enum.UserInputType.MouseButton1 and i.UserInputType~=Enum.UserInputType.Touch then return end if not AM.isInside(i.Position.X,i.Position.Y)then local m=AM AM=nil m.c()end end)
local min=false
minBtn.MouseButton1Click:Connect(function()
	closeMenu()
	if min then
		tw(M,{Size=UDim2.new(0,cfg.uw,0,cfg.uh)},.28)
		task.delay(.3,function()SB.Visible=true CA.Visible=true local c=TB:FindFirstChild("Cover")if c then c.Visible=true end end)
		minIcon:ClearAllChildren()ICON(minIcon,"minus",A.icons.c,20)
	else
		SB.Visible=false CA.Visible=false
		local c=TB:FindFirstChild("Cover")if c then c.Visible=false end
		tw(M,{Size=UDim2.new(0,cfg.uw,0,40)},.28)
		minIcon:ClearAllChildren()ICON(minIcon,"plus",A.icons.c,20)
	end
	min=not min
end)
closeBtn.MouseButton1Click:Connect(function()
	if cfg.active then cfg.active=false local l={}for m in pairs(tracked)do table.insert(l,m)end for _,m in ipairs(l)do removeHB(m)end tracked={}end
	if cfg.espActive then cfg.espActive=false for m in pairs(espTracked)do clearESP(m)end end
	if DrawingAPI then for m in pairs(skelData)do clearSkel(m)end end
	closeMenu()
	if fovCircle then fovCircle.f:Destroy()end
	tw(SCALE,{Scale=.85},.18)
	tw(M,{Position=UDim2.new(.5,0,.22,-30)},.2)
	task.wait(.2)gui:Destroy()
end)

-- Render loop
R.RenderStepped:Connect(function()
	updateFov()
	if cfg.espActive then updateESP()end
	if cfg.espSkeleton and DrawingAPI then updateSkel()end
	if cfg.aimActive then
		local t=findAimTarget()
		if t then
			local cam=workspace.CurrentCamera
			local org=cam.CFrame.Position
			local dir=(t.Position-org).Unit
			local goal=CFrame.new(org,org+dir)
			local sm=math.clamp(cfg.aimSmooth,.01,1)
			cam.CFrame=cam.CFrame:Lerp(goal,sm)
		end
	end
end)

switchTab("main")
updateFov()
tw(SCALE,{Scale=1},.55,Enum.EasingStyle.Back,Enum.EasingDirection.Out)
tw(M,{Position=UDim2.new(.5,0,.22,0)},.45,Enum.EasingStyle.Quint,Enum.EasingDirection.Out)
warn("[EZ Hub] Loaded successfully")