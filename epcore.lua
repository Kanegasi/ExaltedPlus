local faction,buln,f={},BreakUpLargeNumbers,CreateFrame("frame") f.c=FACTION_BAR_COLORS ExaltedPlusFactions={}
function f.enumfactions()
	if not f.load then for id in next,ExaltedPlusFactions do if not faction[id] then faction[id]={} end end f.load=true end
	for id in next,faction do
		v,faction[id].m,_,faction[id].rw=C_Reputation.GetFactionParagonInfo(id)
		if v then faction[id].t=faction[id].rw and math.modf(v/faction[id].m)-1 or math.modf(v/faction[id].m)
		faction[id].v=mod(v,faction[id].m) end
	end
end
function f.update(_,id,v)
	for k in ReputationFrame.paragonFramesPool:EnumerateActive() do if k.factionID then
		id=k.factionID if not faction[id] then faction[id]={} end faction[id].fr=k
		if not ExaltedPlusFactions[id] then ExaltedPlusFactions[id]=true end
	end end f.enumfactions() f.rfv=ReputationFrame:IsVisible()
	for k,v in next,StatusTrackingBarManager.bars do if v.factionID then f.wb=v end end
end
f:SetScript("OnUpdate",function(s,e)
	if not s.a then s.a=0.3 end if s.b then s.a=s.a-e else s.a=s.a+e end
	if s.a>=1 then s.a=1 s.b=true elseif s.a<=0.3 then s.a=0.3 s.b=false end
	if s.rfv then for i=1,NUM_FACTIONS_DISPLAYED do
		if s[i] then _G["ReputationBar"..i.."ReputationBar"]:SetStatusBarColor(f.c[8].r,f.c[8].g,f.c[8].b,s.a) end
	end end
	if s.wrw then f.wb.StatusBar:SetStatusBarColor(f.c[8].r,f.c[8].g,f.c[8].b,s.a) end
end)
local function gttfind(q,...)
	for i=1,select("#",...) do
		local r=select(i,...)
		if r and r.GetText and r:GetText()==q then
			return r
		end
	end
	return {SetText=function(_,t) GameTooltip:AddLine(t) GameTooltip:Show() end}
end
hooksecurefunc("EmbeddedItemTooltip_SetItemByQuestReward",function(mf,t)
	f.update() mf=GetMouseFocus()
	if mf and mf.factionID and faction[mf.factionID] and faction[mf.factionID].t then
		t=format(ARCHAEOLOGY_COMPLETION,faction[mf.factionID].t)
		gttfind(REWARDS,GameTooltip:GetRegions()):SetText(t)
	end
end)
hooksecurefunc(StatusTrackingBarManager,"UpdateBarsShown",function(_,n,r,id) f.update()
	if f.wb and f.wb:IsShown() then
		n,r,_,_,_,id=GetWatchedFactionInfo()
		if faction[id] and faction[id].rw then f.wrw=true
			f.wb.name=n.." "..faction[id].v.." / "..faction[id].m
			f.wb.StatusBar:SetAnimatedValues(faction[id].v,0,faction[id].m,r)
			f.wb.OverlayFrame.Text:SetText(n.." "..faction[id].v.." / "..faction[id].m)
		elseif id then f.wrw=nil
			r=(GetFriendshipReputation(id)) and 5 or r
			f.wb.StatusBar:SetStatusBarColor(f.c[r].r,f.c[r].g,f.c[r].b,1)
		else f.wrw=nil end
	end
end)
hooksecurefunc("ReputationFrame_Update",function(_,n,id,x,bar,row) f.update()
	for i=1,NUM_FACTIONS_DISPLAYED do
		n,_,_,_,_,_,_,_,_,_,_,_,_,id=GetFactionInfo(ReputationListScrollFrame.offset+i)
		if ExaltedPlusFactions[id] then ExaltedPlusFactions[id]=n end
		if faction[id] and faction[id].v and faction[id].fr then
			f[i]=faction[id].rw or nil
			bar=_G["ReputationBar"..i.."ReputationBar"] row=_G["ReputationBar"..i]
			bar:SetMinMaxValues(0,faction[id].m) bar:SetValue(faction[id].v)
			row.rolloverText=" "..format(REPUTATION_PROGRESS_FORMAT,buln(faction[id].v),buln(faction[id].m))
			faction[id].fr.Check:SetShown(false) faction[id].fr.Glow:SetShown(false)
			faction[id].fr.Highlight:SetShown(false) faction[id].fr.Icon:SetAlpha(f[i] and 1 or 0.3)
		else f[i]=nil end
	end
end)
