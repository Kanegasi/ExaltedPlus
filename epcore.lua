local factions,buln,frame={},BreakUpLargeNumbers,CreateFrame("frame")
ExaltedPlusFactions={}
function frame.enumfactions()
	if not frame.loaded then
		frame.loaded=true
		for id in pairs(ExaltedPlusFactions) do
			factions[id]={}
		end
	end
	for id,faction in pairs(factions) do
		value,faction.max,_,faction.reward=C_Reputation.GetFactionParagonInfo(id)
		if value then
			faction.timesdone=faction.reward and math.modf(value/faction.max)-1 or math.modf(value/faction.max)
			faction.value=mod(value,faction.max)
		end
	end
end
function frame.update()
	for _,row in ReputationFrame.ScrollBox:EnumerateFrames() do
		if row.factionID then
			if C_Reputation.IsFactionParagon(row.factionID) then
				if not factions[row.factionID] then
					factions[row.factionID]={}
				end
				factions[row.factionID].row=row
			else
				ExaltedPlusFactions[row.factionID]=nil
			end
		end
	end
	frame.enumfactions()
	frame.repframevis=ReputationFrame:IsVisible()
	for _,bar in pairs(StatusTrackingBarManager.bars) do
		if bar.factionID then
			frame.watchbar=bar
		end
	end
end
frame:SetScript("OnUpdate",function(self,elapsed)
	if not self.alpha then
		self.alpha=0.3
	end
	if self.reverse then
		self.alpha=self.alpha-elapsed
	else
		self.alpha=self.alpha+elapsed
	end
	if self.alpha>=1 then
		self.alpha=1
		self.reverse=true
	elseif self.alpha<=0.3 then
		self.alpha=0.3
		self.reverse=false
	end
	if self.repframevis then
		for _,faction in pairs(factions) do
			if faction.reward then
				local red,green,blue=faction.row.Container.ReputationBar:GetStatusBarColor()
				faction.row.Container.ReputationBar:SetStatusBarColor(red,green,blue,self.alpha)
			end
		end
	end
	if self.pulsewatchbar then
		local red,green,blue=frame.watchbar.StatusBar:GetStatusBarColor()
		frame.watchbar.StatusBar:SetStatusBarColor(red,green,blue,self.alpha)
	end
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
hooksecurefunc("EmbeddedItemTooltip_SetItemByQuestReward",function()
	frame.update()
	local mf=GetMouseFocus()
	if mf and mf.factionID and factions[mf.factionID] and factions[mf.factionID].timesdone then
		local text=format(ARCHAEOLOGY_COMPLETION,factions[mf.factionID].timesdone)
		gttfind(REWARDS,GameTooltip:GetRegions()):SetText(text)
	end
end)
hooksecurefunc(StatusTrackingBarManager,"UpdateBarsShown",function(_,n,r,id)
	frame.update()
	if frame.watchbar and frame.watchbar:IsShown() then
		local factionName,reaction,_,_,_,factionID=GetWatchedFactionInfo()
		if factions[factionID] and factions[factionID].reward then
			frame.pulsewatchbar=true
			local bartext=factionName.." "..factions[factionID].value.." / "..factions[factionID].max
			frame.watchbar.name=bartext
			frame.watchbar:SetBarText(bartext)
			frame.watchbar:SetBarValues(factions[factionID].value,0,factions[factionID].max,reaction)
		else
			frame.pulsewatchbar=nil
			local red,green,blue=frame.watchbar.StatusBar:GetStatusBarColor()
			frame.watchbar.StatusBar:SetStatusBarColor(red,green,blue,1)
		end
	end
end)
hooksecurefunc("ReputationFrame_InitReputationRow",function(row)
	frame.update()
	if row.factionID and factions[row.factionID] and factions[row.factionID].value and factions[row.factionID].max then
		ExaltedPlusFactions[row.factionID]=GetFactionInfo(row.index)
		row.rolloverText=" "..format(REPUTATION_PROGRESS_FORMAT,buln(factions[row.factionID].value),buln(factions[row.factionID].max))
		row.Container.ReputationBar:SetMinMaxValues(0,factions[row.factionID].max)
		row.Container.ReputationBar:SetValue(factions[row.factionID].value)
		row.Container.Paragon.Check:SetShown(false)
		row.Container.Paragon.Glow:SetShown(false)
		row.Container.Paragon.Highlight:SetShown(false)
		row.Container.Paragon.Icon:SetAlpha(factions[row.factionID].reward and 1 or 0.3)
	end
end)
