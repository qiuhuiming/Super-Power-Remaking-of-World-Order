-- ********************************************************
-- POLICY_HORSEMAN_TRAINING and POLICY_MILITARY_CASTE
-- ******************************************************** 
function SPEBattleCustomDamage(iBattleUnitType, iBattleType,
	iAttackPlayerID, iAttackUnitOrCityID, bAttackIsCity, iAttackDamage,
	iDefensePlayerID, iDefenseUnitOrCityID, bDefenseIsCity, iDefenseDamage,
	iInterceptorPlayerID, iInterceptorUnitOrCityID, bInterceptorIsCity, iInterceptorDamage)

	print("SPEBattleCustomDamage");
	local additionalDamage = 0;

	local attPlayer = Players[iAttackPlayerID]
	local defPlayer = Players[iDefensePlayerID]
	if attPlayer == nil or defPlayer == nil then
		return 0
	end

	if iBattleUnitType == GameInfoTypes["BATTLEROLE_ATTACKER"] then
		if bAttackIsCity then
			return 0
		end

		local attUnit = attPlayer:GetUnitByID(iAttackUnitOrCityID)
		if attUnit == nil then
			return 0
		end

		local attUnitCombatType = attUnit:GetUnitCombatType() 

		if attPlayer:HasPolicy(GameInfo.Policies["POLICY_HORSEMAN_TRAINING"].ID) 
		and ((attUnitCombatType == GameInfoTypes.UNITCOMBAT_MOUNTED) or (attUnitCombatType == GameInfoTypes.UNITCOMBAT_ARMOR))
		then
			additionalDamage = additionalDamage + 5
		end

		if attPlayer:HasPolicy(GameInfo.Policies["POLICY_MILITARY_CASTE"].ID) then
			if ( (attUnit:IsHasPromotion(GameInfo.UnitPromotions["PROMOTION_ARCHERY_COMBAT"].ID) ) 
			or ( (attUnitCombatType == GameInfoTypes.UNITCOMBAT_HELICOPTER) ) )
			then
				additionalDamage = additionalDamage + 5
			end

			if bDefenseIsCity then
				local defCity = defPlayer:GetCityByID(iDefenseUnitOrCityID) 
				if defCity == nil then return 0 end

				if attUnit:IsHasPromotion(GameInfo.UnitPromotions["PROMOTION_CITY_SIEGE"].ID) 
				or attUnit:GetDomainType() == DomainTypes.DOMAIN_AIR then
					additionalDamage = additionalDamage + defCity:GetMaxHitPoints() * 0.1
				end
			end
		end
	end
	return additionalDamage
end
GameEvents.BattleCustomDamage.Add(SPEBattleCustomDamage)

function SPEConquestedCity(oldOwnerID, isCapital, cityX, cityY, newOwnerID, numPop, isConquest)
    local pPlayer = Players[newOwnerID]
    local capturedPlayer = Players[oldOwnerID]
	if pPlayer == nil or capturedPlayer == nil then
	 	return
	end

	if pPlayer:HasPolicy(GameInfo.Policies["POLICY_WARRIOR_CODE"].ID) then  
		local conquestedCityPlot = Map.GetPlot(cityX, cityY)
		local pCity = conquestedCityPlot:GetPlotCity()
		if pCity == nil then return end

		local pTeam = Teams[pPlayer:GetTeam()]
		if pTeam == nil then return end

		if pTeam:IsHasTech(GameInfo.Technologies["TECH_MATHEMATICS"].ID)
		and isConquest
		and newOwnerID ~= pCity:GetOriginalOwner()
		then 
			local buildingClass = "BUILDINGCLASS_COURTHOUSE"
			local thisCivilizationType = pPlayer:GetCivilizationType()
			local buildingType = GameInfoTypes["BUILDING_COURTHOUSE"]
			
			for row in GameInfo.Civilization_BuildingClassOverrides() do

				if (GameInfoTypes[row.CivilizationType] == thisCivilizationType and row.BuildingClassType == buildingClass) then
					print("POLICY_WARRIOR_CODE: Courthouse UB!")
					buildingType = row.BuildingType
				end
			end
			print("POLICY_WARRIOR_CODE: set courthouse!")
			pCity:SetNumRealBuilding(buildingType,1)
		end 				
	end

end
GameEvents.CityCaptureComplete.Add(SPEConquestedCity) 


-- ********************************************************
-- POLICY_BRANCH_EXPLORATION
-- ******************************************************** 
function SPEAdoptPolicyBranch( playerID, policybranchID )
	
    local pPlayer = Players[playerID]	
    if pPlayer == nil or pPlayer:IsBarbarian() then return end
	if(policybranchID == GameInfo.PolicyBranchTypes["POLICY_BRANCH_EXPLORATION"].ID) then
		for iUnit in pPlayer:Units() do
			if iUnit:IsHasPromotion(GameInfo.UnitPromotions["PROMOTION_OCEAN_IMPASSABLE"].ID) 
           			and iUnit:GetDomainType() == DomainTypes.DOMAIN_SEA
            			and iUnit:IsCombatUnit()
            			then
				print("POLICY_BRANCH_EXPLORATION: adopt")
				iUnit:SetHasPromotion(GameInfoTypes.PROMOTION_OCEAN_IMPASSABLE,false)
			end
		end	
	end
end
GameEvents.PlayerAdoptPolicyBranch.Add(SPEAdoptPolicyBranch)

function SPEPolicyUnitCreated(iPlayerID, iUnitID)

    local pPlayer = Players[iPlayerID]	
    if pPlayer == nil or pPlayer:IsBarbarian() then return end
    local pUnit = pPlayer:GetUnitByID(iUnitID)
    if pUnit == nil then return end

    if pPlayer:HasPolicyBranch(GameInfo.PolicyBranchTypes["POLICY_BRANCH_EXPLORATION"].ID) 
    and pUnit:IsHasPromotion(GameInfo.UnitPromotions["PROMOTION_OCEAN_IMPASSABLE"].ID) 
    then
        if pUnit:GetDomainType() == DomainTypes.DOMAIN_SEA
        and pUnit:IsCombatUnit()
        then 
			print("POLICY_BRANCH_EXPLORATION: create unit");
			pUnit:SetHasPromotion(GameInfoTypes.PROMOTION_OCEAN_IMPASSABLE,false)
		end
    end

end
Events.SerialEventUnitCreated.Add(SPEPolicyUnitCreated)

--POLICY_MARITIME_INFRASTRUCTURE: +50% build speed on water tiles
function SPEBuildSpeedIncrease(iPlayer, iUnit, iX, iY, iBuild, bStarting)
	local pPlayer = Players[iPlayer]
	local unit = pPlayer:GetUnitByID(iUnit)
 
	if pPlayer == nil or pPlayer:IsMinorCiv() or pPlayer:IsBarbarian() then
		return
	end
 
	if pPlayer:HasPolicy(GameInfo.Policies["POLICY_MARITIME_INFRASTRUCTURE"].ID) then 
		if GameInfo.Builds[iBuild].Water == true then
			print("SPEBuildSpeedIncrease!", iX, iY);
			Map.GetPlot(iX, iY):ChangeBuildProgress(unit:GetBuildType(),(0.5)*unit:WorkRate(),pPlayer:GetTeam())
		end
	end
end 
GameEvents.PlayerBuilding.Add(SPEBuildSpeedIncrease)

-- ********************************************************
-- POLLICY_COLLECTIVE_RULE
-- ******************************************************** 
local PolicyCollectiveRuleID = GameInfo.Policies["POLICY_COLLECTIVE_RULE"].ID
local PolicyCollectiveRuleFreeID = GameInfo.Policies["POLICY_COLLECTIVE_RULE_FREE"].ID
function SPEPlayerIntoNewEra(eTeam, eEra, bFirst)
	for iPlayer=0, GameDefines.MAX_MAJOR_CIVS-1, 1 do
		local pPlayer = Players[iPlayer]

		if pPlayer:IsAlive()
		and pPlayer:GetTeam() == eTeam
		and eEra >= GameInfo.Eras["ERA_RENAISSANCE"].ID
		and pPlayer:HasPolicy(PolicyCollectiveRuleID) 
		and not pPlayer:IsPolicyBlocked(PolicyCollectiveRuleID)
		and (not pPlayer:HasPolicy(PolicyCollectiveRuleFreeID))
		then
			print("POLLICY_COLLECTIVE_RULE: enter Renaissance, free policy");  
			pPlayer:SetHasPolicy(PolicyCollectiveRuleFreeID,true,true)
		end
	end
end
GameEvents.TeamSetEra.Add(SPEPlayerIntoNewEra)

function SPEPlayerAdoptPolicy(playerID, policyID)
	if(policyID == PolicyCollectiveRuleID) then
		local pPlayer = Players[playerID]
		if pPlayer == nil or pPlayer:IsMinorCiv() or pPlayer:IsBarbarian() then
			return
		end

		local eEra = pPlayer:GetCurrentEra()
		if pPlayer:IsAlive()
		and eEra >= GameInfo.Eras["ERA_RENAISSANCE"].ID
		and not pPlayer:IsPolicyBlocked(PolicyCollectiveRuleID)
		and (not pPlayer:HasPolicy(PolicyCollectiveRuleFreeID))
		then
			print("POLLICY_COLLECTIVE_RULE: adopt after Renaissance, free policy"); 
			pPlayer:SetHasPolicy(PolicyCollectiveRuleFreeID,true,true)
		end
	end
end
GameEvents.PlayerAdoptPolicy.Add(SPEPlayerAdoptPolicy)

--POLICY_CITIZENSHIP: +25 production when founding a new city
function SPEPlayerCityFounded(iPlayer,cityX, cityY)
	local pPlayer = Players[iPlayer]
	if pPlayer == nil or pPlayer:IsMinorCiv() or pPlayer:IsBarbarian() then
		return
	end
	local cityPlot = Map.GetPlot(cityX, cityY)
	local pCity = cityPlot:GetPlotCity()
	if pCity == nil then return end

	if pPlayer:HasPolicy(GameInfo.Policies["POLICY_CITIZENSHIP"].ID) 
	and not pPlayer:IsPolicyBlocked(GameInfo.Policies["POLICY_CITIZENSHIP"].ID)
	then 
		local bonus=GameInfo.GameSpeeds[Game.GetGameSpeedType()].ConstructPercent/100
		bonus = math.floor(bonus * 25)
		pCity:SetOverflowProduction(pCity:GetOverflowProduction() + bonus)
		print("SPEPlayerCityFounded:",bonus)	
	end
end
GameEvents.PlayerCityFounded.Add(SPEPlayerCityFounded)

-- POLICY_MERITOCRACY: gain culture and research when finishing a building
function SPECityBuildingCompleted(iPlayer, iCity, iBuilding, bGold, bFaithOrCulture)
	local pPlayer = Players[iPlayer]
	if pPlayer == nil or pPlayer:IsMinorCiv() or pPlayer:IsBarbarian() then
	 	return
	end
	local iBuildingClass = GameInfo.Buildings[iBuilding].BuildingClass
	local isWonder = GameInfo.BuildingClasses[iBuildingClass].MaxGlobalInstances
	if pPlayer:HasPolicy(GameInfo.Policies["POLICY_MERITOCRACY"].ID) 
	and not pPlayer:IsPolicyBlocked(GameInfo.Policies["POLICY_MERITOCRACY"].ID)
	and bGold == false
	and bFaithOrCulture == false
	and isWonder  == -1
	then 
		local bonus = GameInfo.GameSpeeds[Game.GetGameSpeedType()].ConstructPercent/100
		local pCost = GameInfo.Buildings[iBuilding].Cost
		bonus = math.floor(bonus * pCost * 0.1)
		pPlayer:ChangeJONSCulture(bonus)
		pPlayer:ChangeOverflowResearch(bonus)
		print("SPECityBuildingCompleted:",bonus)	
	end
end
GameEvents.CityConstructed.Add(SPECityBuildingCompleted)

print('SP8PolicyEffects: Check Pass')