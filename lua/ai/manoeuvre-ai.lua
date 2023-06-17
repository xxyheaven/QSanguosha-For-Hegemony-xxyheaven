--[[********************************************************************
	Copyright (c) 2013-2015 Mogara

  This file is part of QSanguosha-Hegemony.

  This game is free software; you can redistribute it and/or
  modify it under the terms of the GNU General Public License as
  published by the Free Software Foundation; either version 3.0
  of the License, or (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
  General Public License for more details.

  See the LICENSE file for more details.

  Mogara
*********************************************************************]]
--纵横捭阖

--华歆
sgs.ai_skill_invoke.wanggui = true

sgs.ai_skill_playerchosen.wanggui = sgs.ai_skill_playerchosen.damage

sgs.ai_need_damaged.wanggui = function(self, attacker, player)
  if not player:hasShownSkill("wanggui") or player:hasFlag("WangguiUsed") then
    return false
  end
  if player:hasShownAllGenerals() and self.player:getPlayerNumWithSameKingdom("AI", player:getKingdom()) > 2 then
    return true
  end
  if player:hasShownOneGeneral() then
    for _, p in ipairs(self:getEnemies(player)) do
      if p:getHp() == 1 and self:isWeak(p) then
        return true
      end
    end
  end
	return false
end

sgs.ai_skill_invoke.xibing =  function(self, data)
  self.xibing_skill = nil
  if not self:willShowForDefence() then
    return false
  end
  local target = data:toPlayer()
  if not target then
    return false
  end
  local draw_count = target:getHp() - target:getHandcardNum()
  if self:isFriend(target) and (draw_count > 1) then
    return true
  end
	local eachother_shown = target:hasShownAllGenerals() and self.player:hasShownAllGenerals()
  if target:hasShownAllGenerals() then--发动技能后双亮
    if (self.player:hasShownGeneral1() and self.player:inDeputySkills("xibing") and self.player:canShowGeneral("d"))
    or (self.player:hasShownGeneral2() and self.player:inHeadSkills("xibing") and self.player:canShowGeneral("h")) then
      eachother_shown = true
    end
  end
  local xibing_firstskills = --注意有优先顺序
              "paiyi|suzhi|shilu|huaiyi|luanji|yigui|paoxiao|kuangcai|diaodu|xuanhuo|"..
              "jixi|qice|zaoyun|jinfa|"..
							"jizhi|tieqi|kuanggu|jili|tongdu|"..
							"xiaoji|guose|xuanlue|"..
							"wansha|jianchu|qianhuan|"..
							"zhukou|boyan|guishu|miewu"
  if self:isEnemy(target) and eachother_shown then
    local skills = (xibing_firstskills):split("|")
    for _, skill in ipairs(skills) do
      if target:hasSkill(skill) then
        self.xibing_skill = skill
        return true
      end
    end
  end
  if target:hasShownSkill("buqu") and target:getPile("scars"):length() > 4 and self:isFriend(target) and eachother_shown then
    self.xibing_skill = "buqu"
    return true
  end
  local not_firstskill = true
  for _, p in ipairs(self.enemies) do
    if p:hasShownSkills(xibing_firstskills) and p:hasShownAllGenerals() then
      not_firstskill = false
    end
  end
  if not_firstskill then
    local xibing_secondskills = "|duanliang|qiangxi|juejue|daoshu|wusheng|shengxi|sanyao|"..
              "zhiheng|qixi|kurou|fanjian|keji|duoshi|tianyi|dimeng|ganlu|"..
              "shuangxiong|lijian|lirang|chuanxin|xiongsuan|weidi|midao|baolie"
    if self:isEnemy(target) and eachother_shown then
      local skills = (xibing_secondskills):split("|")
      for _, skill in ipairs(skills) do
        if target:hasSkill(skill) then
          self.xibing_skill = skill
          return true
        end
      end
    end
  end

  if not self:isFriend(target) and (draw_count > 0 and draw_count < (self:slashIsAvailable(target) and 3 or 2)) then
    return true
  end
  if draw_count <= 0 then
    return true
  end
  return false
end

sgs.ai_skill_choice.xibing = function(self, choices, data)
  choices = choices:split("+")
  if not self.xibing_skill and table.contains(choices,"cancel") then
    return "cancel"
  end
  self.room:writeToConsole("息兵暗置技能:"..sgs.Sanguosha:translate(self.xibing_skill))
  local current = self.room:getCurrent()
  if table.contains(choices,"cancel") then
    if #choices == 1 then
      return "cancel"
    end
    if self.player:hasSkill("tuntian") and not self.player:getPile("field"):isEmpty() then
      if self.player:inDeputySkills("tuntian") then
        return "head"
      else
        return "deputy"
      end
    end
    if self.player:hasSkill("paiyi") and not self.player:getPile("power_pile"):isEmpty() then
      return "deputy"
    end
    if self.player:hasSkill("xiongnve") and self.player:getMark("#massacre") > 0 then
      return "deputy"
    end
    if self.player:hasSkill("zisui") and not self.player:getPile("&disloyalty"):isEmpty() then
      if self.player:getPile("&disloyalty"):length() >= self.player:getMaxHp() then
        return "head"
      end
      return "deputy"
    end
    if self.player:hasSkill("sidi") and not self.player:getPile("drive"):isEmpty() then
      if self.player:inDeputySkills("sidi") then
        return "head"
      else
        return "deputy"
      end
    end

    local xibing_defenseskills = "yiji|fankui|ganglie|fangzhu|qingguo|shicai|zhaoxin"
    if self.player:hasSkill("jieming") and self:getJiemingDrawNum(self.player) >= 2 then
      xibing_defenseskills = "jieming|" .. xibing_defenseskills
    end
    if current:canSlash(self.player, nil, true) and not self.player:hasSkills(xibing_defenseskills) then
      if self.player:inDeputySkills("xibing") and table.contains(choices,"head") then--暗无防御将
        return "head"
      else
        return "deputy"
      end
    end
    --[[
		if self.player:inDeputySkills("xibing") and table.contains(choices,"deputy") then--暗着可以发动息兵
			return "deputy"
		else
			return "head"
		end
	--]]
		if self.player:inHeadSkills("wanggui") and table.contains(choices,"deputy") then--望归威慑
			return "deputy"
		elseif self.player:inDeputySkills("wanggui") and table.contains(choices,"head") then
			return "head"
		end
  else
    if table.contains(choices,"head") then
      if current:inHeadSkills(self.xibing_skill) then
        return "head"
      end
      return "deputy"
    end
    return "deputy"
  end
	return choices[#choices]
end

--陆郁生
sgs.ai_skill_invoke.zhente = function(self, data)
  if self.player:hasSkill("guzheng") then
    local lord_sunquan = self.room:getLord(self.player:getKingdom())
    if lord_sunquan and lord_sunquan:getPile("flame_map"):length() > 1 then
      return true
    end
    for _, p in ipairs(self.friends_noself) do
      if p:hasShownSkills(sgs.drawcard_skill) then
        return true
      end
    end
  end
  if not self:willShowForDefence() then
    return false
  end
  local target = data:toPlayer()
  local use = self.player:getTag("ZhenteUsedata"):toCardUse()
  local card = use.card
  if target and self:isFriend(target) then
    if (card:isKindOf("IronChain") or card:isKindOf("FightTogether") or card:isKindOf("FireAttack") or card:isKindOf("NatureSlash"))
      and not self.player:isChained() then
        return true
    elseif card:isKindOf("Slash") or card:isKindOf("Duel") or card:isKindOf("Drowning")
      or card:isKindOf("BurningCamps") or card:isKindOf("SavageAssault") or card:isKindOf("ArcheryAttack") then
        return true
    else
      return false
    end
  end
  return true
end

sgs.ai_skill_choice.zhente = function(self, choices, data)
  local use = data:toCardUse()
  local luyusheng = sgs.findPlayerByShownSkillName("zhente")
  if luyusheng and use.to:contains(luyusheng) and self:isEnemy(luyusheng) then
    if getKnownCard(self.player, self.player, "black", true, "h") == 0 then
      return "cardlimited"
    end
    local black_count = 0
    for _ ,c in sgs.qlist(self.player:getHandcards()) do
      if c:isAvailable(self.player) and c:isBlack() then
        black_count = black_count + 1
      end
    end
    if black_count > 1 and self:getOverflow() > 0 and self.player:getPhase() <= sgs.Player_Play then
      return "nullified"
    else
      return "cardlimited"
    end
  end
  --[[
  if luyusheng and use.to:contains(luyusheng) and self:isFriend(luyusheng) then
    return "nullified"
  end]]
	return "nullified"
end

sgs.ai_skill_playerchosen.zhiwei = function(self, targets)
  local current = self.room:getCurrent()
  if current:objectName() ~= self.player:objectName()
  and (current:hasShownSkill("yigui") and #(current:property("Huashens"):toString():split("+")) > 3
      or (current:getHandcardNum() > 3 and (current:hasShownSkill("luanji") or self:hasCrossbowEffect(current)
          or (current:hasShownSkill("shuangxiong") and current:hasFlag("shuangxiong"))))) then
    return current
  end
  targets = sgs.QList2Table(targets)
  self:sort(targets, "hp", true)
  for _, p in ipairs(targets) do
    if self.player:isFriendWith(p) and p:hasShownSkills(sgs.priority_skill) then
      return p
    end
  end
  for _, p in ipairs(targets) do
    if self:isFriend(p) and p:hasShownSkills(sgs.priority_skill) then
      return p
    end
  end
  for _, p in ipairs(targets) do
    if self:isFriend(p) then
      return p
    end
  end
  return targets[1]
end

--宗预
sgs.ai_skill_invoke.qiao =	function(self, data)
	if not self:willShowForDefence() then
		return false
	end
	local target = data:toPlayer()
	if not target or self:isFriend(target) or target:isNude() then
		return false
	end
	local use = self.player:getTag("QiaoUsedata"):toCardUse()
	local card = use.card
	
	if card:isKindOf("ImperialOrder") then
		if (self.player:inHeadSkills("jianxiong") or self.player:inHeadSkills("rende")
			or self.player:inHeadSkills("zhiheng") or self.player:inHeadSkills("guidao"))--君主替换
    		and sgs.GetConfig("EnableLordConvertion", true) and self.player:getMark("Global_RoundCount") <= 1 then
    		return false
		end	
		if sgs.GetConfig("RewardTheFirstShowingPlayer", true) then
			local reward = true
			for _, p in sgs.qlist(self.room:getAlivePlayers()) do
				if p:hasShownOneGeneral() then
					reward = false
					break
				end
			end
			if reward then return true end
		end
		return false
	end
	if self.player:getCardCount(true) == 1 then
		if card:isKindOf("Drowning") then return false end
		if card:isKindOf("FireAttack") and self:getLeastHandcardNum() == 0 then return true end
		if card:isKindOf("Collateral") or card:isKindOf("Dismantlement") or card:isKindOf("Snatch") or self:needToThrowArmor() then return true end
		if self.player:getHandcardNum() == 1 then
			if isCard("Peach", self.player:getHandcards():first(), self.player) and self.player:getHp() <= 1
				and not (card:isKindOf("Slash") and self:hasHeavySlashDamage(use.from, card, self.player) and self:getCardsNum("Peach") < 2) then
				return false
			end
			if self:getCardsNum("Slash","h") == 1 then
				if self:isWeak() and (card:isKindOf("SavageAssault") or card:isKindOf("Duel")) then return false end
			end
			if self:getCardsNum("Jink","h") == 1 then
				if card:isKindOf("Slash") and not self:canHit(self.player, target) then
					if self:hasHeavySlashDamage(use.from, card, self.player) or self:isWeak() then return false end
				elseif card:isKindOf("ArcheryAttack") then return false end
			end
			if self:getLeastHandcardNum() > 0 or not self:isWeak() then return true end
		end
	end
	if ((self.player:getHandcardNum() <= 2 or self:doNotDiscard(self.player, "he")) and (self:needKongcheng() or self:getLeastHandcardNum() > 0)
		and self:getCardsNum("Peach","h") <= ((self:getLeastHandcardNum() > 0) and (self.player:getHandcardNum()-1) or 0))
		or (self.player:hasSkill("lirang") and #self.friends_noself > 0) or self.player:isNude() or self:getOverflow() > 0 or self:getDangerousCard(target) then
		return true
	end
	return false
end
--气傲自弃牌
sgs.ai_skill_discard["qiao_discard"] = function(self)
	local use = self.player:getTag("QiaoUsedata"):toCardUse()
	local card = use.card
	
	if not card then return self:askForDiscard("dummy_reason", 1, 1, false, true) end
	
	if card:isKindOf("Drowning") and self.player:getEquips():length() == 1 then--水淹不弃唯一装备
		return self:askForDiscard("dummy_reason", 1, 1, false, false)
	elseif card:isKindOf("FireAttack") and (self:getLeastHandcardNum() > 0 or self.player:getHandcardNum() == 1) then--火攻考虑弃手牌
		return self:askForDiscard("dummy_reason", 1, 1, false, false)
	elseif card:isKindOf("Collateral") and self.player:getWeapon() then--借刀扔刀
		return {self.player:getWeapon():getEffectiveId()}
	elseif card:isKindOf("Snatch") and self.player:getCardCount(true) == 2 then--顺手弃价值更高的
		local cards = self:askForDiscard("dummy_reason", 2, 2, false, true)
		self:sortByUseValue(cards, true)
		return {cards[2]:getEffectiveId()}
	end
	return self:askForDiscard("dummy_reason", 1, 1, false, true)
end

sgs.ai_skill_invoke.chengshang = true

--祢衡
sgs.ai_skill_invoke.kuangcai = function(self, data)
  if self.player:getCardUsedTimes(".") == 0 then
    return true
  end
  return false
end

function sgs.ai_cardneed.kuangcai(to, card, self)
	return card:isKindOf("Slash") or card:isKindOf("Analeptic") or card:isKindOf("Halberd") or to:hasWeapon("Spear")
end

sgs.kuangcai_keep_value = {
	Peach = 6,
	Analeptic = 5.8,
	Jink = 5.7,
	FireSlash = 5.6,
	Slash = 5.4,
	ThunderSlash = 5.5,
	ExNihilo = 4.7,
	BefriendAttacking = 5
}--复制的咆哮，是否合理？

sgs.ai_skill_invoke.shejian = function(self, data)
	if not self:willShowForDefence() then
		return false
	end
	local use = self.player:getTag("ShejianUsedata"):toCardUse()
	local card = use.card
	if card:isKindOf("Slash") and self:hasHeavySlashDamage(use.from, card, self.player) and not self:canHit(self.player, use.from) then
		return false
	end
	local target = data:toPlayer()
	if not target then
		if self:getCardsNum("Peach","h") == 0 and self.player:getHandcardNum() < 2 and (self:needKongcheng() or (self.player:hasSkill("lirang") and #self.friends_noself > 0)) then
			return true
		end
		return false
	elseif self:isFriend(target) then
		if self:getCardsNum("Peach","h") > 0 or self.player:hasShownOneGeneral() or self:isWeak(target) then return false end
		if not self.player:hasShownOneGeneral() and self:isWeak() and self.player:getHp() <= 1 and self:getCardsNum("Peach","h") == 0 and self:getCardsNum("Analeptic","h") == 0 then
			if self:isWeak(target) and getCardsNum("Peach", target, self.player) == 0 then return false end
			if card:isKindOf("Slash") and self:getCardsNum("Jink","h") > 0 then return false end
			if self:isWeak(target) or self.player:getHandcardNum() <= 2 then
				self.shejianchoice = "discard"
			else
				self.shejianchoice = "damage"
			end
			return true
		end
		return false
	elseif self:canAttack(target) or self:needKongcheng() then
		if self:hasCrossbowEffect(target) and sgs.Slash_IsAvailable(target) and getCardsNum("Slash", target, self.player) > 1 then
			if getCardsNum("Slash", target, self.player) > self:getCardsNum("Jink","h") or self:canHit(self.player, target) then
				self.shejianchoice = "discard"
				return true
			end
		end
		if card:isKindOf("Slash") and self:getCardsNum("Jink","h") > 0 and not self:canHit(self.player, use.from) then return false end
		if self:isWeak() and self:getCardsNum("Analeptic","h") + self:getCardsNum("Peach","h") > 0 then return false end
		--[[
		if (self.player:getHandcardNum() < ((self:needKongcheng() or self.player:hasSkill("lirang")) and 4 or 3) and self:getCardsNum("Peach","h") == 0)
			and target:getHp() <= (self.player:hasSkill("congjian") and 2 or 1) and self:isWeak(target) then
			return true
		end
		--]]
		local v = 0
		if self.player:hasSkill("lirang") and #self.friends_noself > 0 then
			if self.player:getHandcardNum() > 3 then
				v = 2 - self.player:getHandcardNum()
			else
				v = v - self.player:getHandcardNum()/2
			end
			if self:needKongcheng() then v = v + 1 end
		else
			if self:needKongcheng() then v = 1
			else v = v - self.player:getHandcardNum() end
			for _, card in sgs.qlist(self.player:getCards("h")) do
				if self:getKeepValue(card) >= 4.1 or self:getUseValue(card) >= 6 then
					if isCard("Peach", card, self.player) then
						v = v - 3
					else
						v = v - 2
					end
				end
			end
		end
		if self:getCardsNum("Peach","h") == 0 and card:isKindOf("FireAttack") then
			v = v + 1
		end
		if self:canAttack(target) then
			v = v + 2
			if self.player:hasSkill("congjian") then v = v + 2 end
			if self:isWeak(target) then v = v + 1 end
			if v > 0 then 
				self.shejianchoice = "damage"
				Global_room:writeToConsole("舌剑伤害价值:"..tostring(v))
			end
		end
		if v <= 0 then
			v = v + math.min(self.player:getHandcardNum(), target:getCardCount(true))
			self.shejianchoice = "discard"
			Global_room:writeToConsole("舌剑弃牌价值:"..tostring(v))
		end
		return v > 0
	end
	return false
end

sgs.ai_skill_choice["shejian"] = function(self, choices)
	choices = choices:split("+")
	if self.shejianchoice and table.contains(choices,self.shejianchoice) then
		return self.shejianchoice
	end
	return choices[1]
end

function sgs.ai_cardneed.shejian(to, card, self)
	return to:isKongcheng() and not self:needKongcheng(to)
end

--冯熙
sgs.ai_skill_invoke.yusui =  function(self, data)
  if not self:willShowForDefence() then
    return false
  end
  self.yusui_target = data:toPlayer()
  if not self.yusui_target or not self:isEnemy(self.yusui_target)--暂不考虑自杀，参考SmartAI:SuicidebyKurou()
  or (self.player:getHp() == 1 and self:getCardsNum({"Peach", "Analeptic"}) == 0) then
    return false
  end
  local can_losehp = not self.yusui_target:hasSkill("hongfa") or self.yusui_target:getPile("heavenly_army"):isEmpty()
  if (self.yusui_target:getHp() - math.max(self.player:getHp()-1, 1) > 1 and can_losehp)
  or (self.yusui_target:getHandcardNum() >= self.yusui_target:getMaxHp() and self.yusui_target:getHandcardNum() <= self.yusui_target:getMaxHp() + 2) then
    return true
  end
	return false
end

sgs.ai_skill_choice.yusui = function(self, choices, data)--没有来源的data，暂时用self
  choices = choices:split("+")
  local can_losehp = not self.yusui_target:hasSkill("hongfa") or self.yusui_target:getPile("heavenly_army"):isEmpty()
	if self:hasCrossbowEffect(self.yusui_target) and sgs.Slash_IsAvailable(self.yusui_target) and getCardsNum("Slash", self.yusui_target, self.player) > 1 then
		self.yusui_target = nil
		return "discard"
	end
  if (self.yusui_target:getHp() - self.player:getHp() > 1) and can_losehp then
    self.yusui_target = nil
    return "losehp"
  end
  if (self.yusui_target:getHandcardNum() >= self.yusui_target:getMaxHp()) then
    self.yusui_target = nil
    return "discard"
  end
  if (self.yusui_target:getHp() - self.player:getHp() == 1) and can_losehp then--自己会掉1血
    self.yusui_target = nil
    return "losehp"
  end
  return choices[math.random(1,#choices)]
end

sgs.ai_trick_prohibit.yusui = function(self, card, to, from)
  
end

local boyan_skill = {}
boyan_skill.name = "boyan"
table.insert(sgs.ai_skills, boyan_skill)
boyan_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("BoyanCard") then return end
	return sgs.Card_Parse("@BoyanCard=.&boyan")
end

sgs.ai_skill_use_func.BoyanCard = function(card, use, self)
  local target
  self:sort(self.friends_noself, "handcard")
  for _, f in ipairs(self.friends_noself) do
    if (f:getMaxHp() - f:getHandcardNum()) >= (3 - (self:isWeak(f) and 1 or 0)) then
      target = f--给队友补牌优先度调低？
      break
    end
  end
  if not target then
    self:sort(self.enemies, "hp")
    for _, p in ipairs(self.enemies) do
      if p:getMaxHp() - p:getHandcardNum() < 2 and self:isWeak(p) and self.player:canSlash(p, nil, true) then
        target = p
        break
      end
    end
  end
  if not target then
    self:sort(self.enemies, "handcard", true)
    if #self.enemies > 0 and (self.enemies[1]:getMaxHp() - self.enemies[1]:getHandcardNum() < 2) then
      target = self.enemies[1]
    end
  end
  if not target and #self.friends_noself > 1 then
    target = self.friends_noself[1]
  end
  if target then
    Global_room:writeToConsole("驳言目标:"..sgs.Sanguosha:translate(target:getGeneralName()).."/"..sgs.Sanguosha:translate(target:getGeneral2Name()))
	  use.card = card
    if use.to then
      use.to:append(target)
    end
  end
end

sgs.ai_use_priority.BoyanCard = 5--优先度多少合适？

sgs.ai_skill_choice.boyan = function(self, choices, data)
  local target = data:toPlayer()
  if self:isFriend(target) then
    return "yes"
  end
  return "no"
end

local boyanzongheng_skill = {}
boyanzongheng_skill.name = "boyanzongheng"
table.insert(sgs.ai_skills, boyanzongheng_skill)
boyanzongheng_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("BoyanZonghengCard") then return end
	return sgs.Card_Parse("@BoyanZonghengCard=.&boyanzongheng")
end

sgs.ai_skill_use_func.BoyanZonghengCard = function(card, use, self)
  local target
  self:sort(self.enemies, "hp")
  for _, p in ipairs(self.enemies) do
    if self:isWeak(p) and self.player:canSlash(p, nil, true) and not p:isKongcheng() then
      target = p
      break
    end
  end
  if not target and #self.enemies > 0 then
    self:sort(self.enemies, "handcard" , true)
    target = self.enemies[1]
  end
  if target then
    Global_room:writeToConsole("驳言纵横目标:"..sgs.Sanguosha:translate(target:getGeneralName()).."/"..sgs.Sanguosha:translate(target:getGeneral2Name()))
	  use.card = card
    if use.to then
      use.to:append(target)
    end
  end
end

sgs.ai_use_priority.BoyanZonghengCard = 5

--邓芝
sgs.ai_skill_invoke.jianliang = true

local weimeng_skill = {}
weimeng_skill.name = "weimeng"
table.insert(sgs.ai_skills, weimeng_skill)
weimeng_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("WeimengCard") then return end
	return sgs.Card_Parse("@WeimengCard=.&weimeng")
end

sgs.ai_skill_use_func.WeimengCard = function(card, use, self)
  local target
  local _, friend = self:getCardNeedPlayer(sgs.QList2Table(self.player:getCards("he")))
  if friend and friend:getHandcardNum() > 1 then
    target = friend
  end
  if not target then
    self:sort(self.friends_noself, "handcard", true)
    for _, f in ipairs(self.friends_noself) do
      if f:getHandcardNum() > 2 or (self:isWeak(f) and not f:isKongcheng()) then
        target = f
        break
      end
    end
  end
  if not target then
    self:sort(self.enemies, "handcard", true)--优先破坏敌人防御？
    for _, p in ipairs(self.enemies) do
      if not p:isKongcheng() then
        target = p
        break
      end
    end
  end
  if target then
    Global_room:writeToConsole("危盟目标:"..sgs.Sanguosha:translate(target:getGeneralName()).."/"..sgs.Sanguosha:translate(target:getGeneral2Name()))
	  use.card = card
    if use.to then
      use.to:append(target)
    end
  end
end

sgs.ai_use_priority.WeimengCard = 5

sgs.ai_skill_choice.weimeng_num = function(self, choices, data)--简单考虑只取最大值
  choices = choices:split("+")
  return choices[#choices]
end

sgs.ai_skill_exchange["weimeng_giveback"] = function(self,pattern,max_num,min_num,expand_pile)
  local weimeng_give = {}
  local to
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if p:hasFlag("WeimengTarget") then
			to = p
			break
		end
	end
  local visibleflag = string.format("%s_%s_%s", "visible", self.player:objectName(), to:objectName())

  local function weiming_insert(card)--判断并防止重复
    local c_id = card:getEffectiveId()
    if #weimeng_give < max_num and not table.contains(weimeng_give, c_id) then
      if not card:hasFlag("visible") then card:setFlags(visibleflag) end--记录已知牌
      table.insert(weimeng_give, c_id)
    end
  end

  local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards,true)
  if self:isFriend(to) then
    if self.player:getHp() > 1 and self:isWeak(to) and self:getCardsNum("Analeptic") > 0 then
      weiming_insert(self:getCard("Analeptic"))
    end
    if not self:isWeak() and self:isWeak(to) and self:getCardsNum("Peach") > 0 then
      weiming_insert(self:getCard("Peach"))
    end
    local c, friend = self:getCardNeedPlayer(cards, {to})
    if friend and friend:objectName() == to:objectName() then
      weiming_insert(c)
    end
    if self:getCardsNum("Jink") > 1 then
      weiming_insert(self:getCard("Jink"))
    end
    if self:getCardsNum("Slash") > 1 and not self:hasCrossbowEffect() then
      weiming_insert(self:getCard("Slash"))
    end
  end

  for _, c in ipairs(cards) do
    weiming_insert(c)
  end
	return weimeng_give
end

sgs.ai_skill_choice.weimeng = function(self, choices, data)
  local target = data:toPlayer()
  if self:isFriend(target) then
    return "yes"
  end
  return "no"
end

local weimengzongheng_skill = {}
weimengzongheng_skill.name = "weimengzongheng"
table.insert(sgs.ai_skills, weimengzongheng_skill)
weimengzongheng_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("WeimengZonghengCard") then return end
	return sgs.Card_Parse("@WeimengZonghengCard=.&weimengzongheng")
end

sgs.ai_skill_use_func.WeimengZonghengCard = function(card, use, self)
  local target
  local _, friend = self:getCardNeedPlayer(sgs.QList2Table(self.player:getCards("he")))
  if friend and not friend:isKongcheng() then
    target = friend
  end
  if not target then
    self:sort(self.friends_noself, "hp")
    for _, f in ipairs(self.friends_noself) do
      if self:isWeak(f) and not f:isKongcheng() then
        target = f
        break
      end
    end
  end
  if not target then
    self:sort(self.enemies, "hp")
    for _, p in ipairs(self.enemies) do
      if not p:isKongcheng() then
        target = p
        break
      end
    end
  end
  if target then
    Global_room:writeToConsole("危盟纵横目标:"..sgs.Sanguosha:translate(target:getGeneralName()).."/"..sgs.Sanguosha:translate(target:getGeneral2Name()))
	  use.card = card
    if use.to then
      use.to:append(target)
    end
  end
end

sgs.ai_use_priority.WeimengZonghengCard = 5

--荀谌
local fenglve_skill = {}
fenglve_skill.name = "fenglve"
table.insert(sgs.ai_skills, fenglve_skill)
fenglve_skill.getTurnUseCard = function(self)
	if self:willShowForAttack() and not self.player:hasUsed("FenglveCard") and not self.player:isKongcheng() then
    return sgs.Card_Parse("@FenglveCard=.&fenglve")
  end
end

sgs.ai_skill_use_func.FenglveCard = function(FLCard, use, self)
	if #self.enemies == 0 and #self.friends_noself == 0 then return end
  self.fenglve_card = nil
  sgs.ai_use_priority.FenglveCard = 0.5--是否合适？
	local max_card = self:getMaxNumberCard()
	local max_point = max_card:getNumber()
	if self.player:hasShownSkill("yingyang") then max_point = math.min(max_point + 3, 13) end

  self:sort(self.friends_noself, "handcard", true)
  for _, friend in ipairs(self.friends_noself) do--拆判定区多于1的队友
    if not friend:isKongcheng() and friend:getJudgingArea():length() > (self:needToThrowArmor(friend) and 0 or 1) then
      local friend_min_card = self:getMinNumberCard(friend)
      local friend_number = friend_min_card and friend_min_card:getNumber() or 100
      if friend_min_card and friend:hasShownSkill("yingyang") then friend_number = math.max(friend_number - 3, 1) end
      if max_point> friend_number then
        local hcards = sgs.QList2Table(self.player:getHandcards())
        self:sortByUseValue(hcards,true)
        for _, c in ipairs(hcards) do
          if c:getNumber() + (self.player:hasShownSkill("yingyang") and 3 or 0) > friend_number then
            sgs.ai_use_priority.FenglveCard = 4.2
            Global_room:writeToConsole("锋略队友1:"..sgs.Sanguosha:translate(friend:getGeneralName()).."/"..sgs.Sanguosha:translate(friend:getGeneral2Name()))
            self.fenglve_card = c:getEffectiveId()
            use.card = FLCard
            if use.to then
              use.to:append(friend)
              return
            end
          end
        end
      end
      if not friend_min_card and max_point > 8 then
        sgs.ai_use_priority.FenglveCard = 4.2--顺之后
        Global_room:writeToConsole("锋略队友2:"..sgs.Sanguosha:translate(friend:getGeneralName()).."/"..sgs.Sanguosha:translate(friend:getGeneral2Name()))
        self.fenglve_card = max_card:getEffectiveId()
        use.card = FLCard
        if use.to then
          use.to:append(friend)
          return
        end
      end
    end
  end

  if #self.enemies == 0 then return end
  local notlose = self:getOverflow() > 1
  if self.player:getCardCount(true) < (self:needToThrowArmor() and 2 or 1) and not self:isValuableCard(max_card) then
    notlose = true
  end
	self:sort(self.enemies, "handcard")
	for _, enemy in ipairs(self.enemies) do
		if not enemy:isKongcheng() and enemy:getCardCount(true) > 2 then
			local enemy_max_card = self:getMaxNumberCard(enemy)
			local enemy_number = enemy_max_card and enemy_max_card:getNumber() or 100
			if enemy_max_card and enemy:hasShownSkill("yingyang") then enemy_number = math.min(enemy_number + 3, 13) end
			local allknown = false
			if self:getKnownNum(enemy) == enemy:getHandcardNum() then
				allknown = true
			end
			if (not enemy_max_card and (max_point > 11)) or notlose
				or (max_point > enemy_number and not allknown and max_point > 10)
				or (max_point > enemy_number and allknown) then
          if notlose or (max_point > enemy_number and allknown) or max_point > 11 then
            sgs.ai_use_priority.FenglveCard = 5
          end
					self.fenglve_card = max_card:getEffectiveId()
					use.card = FLCard
					if use.to then
            use.to:append(enemy)
            return
          end
			end
		end
	end
end

function sgs.ai_skill_pindian.fenglve(minusecard, self, requestor)
  local max_card = self:getMaxNumberCard()
  if not self:isFriend(requestor) and self.player:getCardCount(true) < 5 then
    local max_point = max_card:getNumber()
    for _, card in sgs.qlist(self.player:getHandcards()) do
			local point = card:getNumber()
			if point > max_point then
				max_point = point
				max_card = card
			end
		end
  end
  if self:isFriend(requestor) and (self.player:getJudgingArea():length() > 0 or self:needToThrowArmor()) then
    return self:getMinNumberCard()
  end
	return max_card
end

sgs.ai_cardneed.fenglve = sgs.ai_cardneed.bignumber

sgs.ai_choicemade_filter.pindian.fenglve = function(self, player, promptlist)
	local target
	for _, p in sgs.qlist(self.room:getOtherPlayers(player)) do
		if p:objectName() == promptlist[5] then
			target = p
			break
		end
	end
	if target:getJudgingArea():length() == 0 and target:getCardCount(true) >= 2 and target:getHandcardNum() >= 1 then
		local target_str = sgs.Sanguosha:translate(target:getActualGeneral1Name()).."/"..sgs.Sanguosha:translate(target:getActualGeneral2Name())
		local player_card_number = sgs.Sanguosha:getCard(promptlist[4]):getNumber()
		local target_card_number = sgs.Sanguosha:getCard(promptlist[6]):getNumber()
		Global_room:writeToConsole("锋略目标:"..target_str.."("..tostring(player_card_number)..":"..tostring(target_card_number)..")")
		if target_card_number >= 10 then
			sgs.updateIntention(target, player, 20*(14 - target_card_number))
		elseif target_card_number <= 4 then
			sgs.updateIntention(target, player, 20*(4-target_card_number))
		end
	end
end

--一次交给2牌用默认策略可否？参考军令2

sgs.ai_skill_exchange["fenglve_give"] = function(self,pattern,max_num,min_num,expand_pile)
  local fenglve_give = {}
  local to
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if p:hasFlag("FenglveTarget") then
			to = p
			break
		end
	end
  local visibleflag = string.format("%s_%s_%s", "visible", self.player:objectName(), to:objectName())

  local function fenglve_insert(card)--判断并防止重复
    local c_id = card:getEffectiveId()
    if #fenglve_give < max_num and not table.contains(fenglve_give, c_id) then
      if not card:hasFlag("visible") then card:setFlags(visibleflag) end--记录已知牌
      table.insert(fenglve_give, c_id)
    end
  end

  if self:isFriend(to) and self:isWeak(to) then
    if self.player:getHp() > 1 and self:getCardsNum("Analeptic") > 0 then
      fenglve_insert(self:getCard("Analeptic"))
    end
    if not self:isWeak() and self:getCardsNum("Peach") > 0 then
      fenglve_insert(self:getCard("Peach"))
    end
    if self:getCardsNum("Jink") > 1 then
      fenglve_insert(self:getCard("Jink"))
    end
  end
  local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards,true)
  for _, c in ipairs(cards) do
    fenglve_insert(c)
  end
	return fenglve_give
end

sgs.ai_skill_choice.fenglve = function(self, choices, data)
  local target = data:toPlayer()
  if not self:isEnemy(target) then--其他情况？
    return "yes"
  end
  return "no"
end

local fenglvezongheng_skill = {}
fenglvezongheng_skill.name = "fenglvezongheng"
table.insert(sgs.ai_skills, fenglvezongheng_skill)
fenglvezongheng_skill.getTurnUseCard = function(self)
	if self:willShowForAttack() and not self.player:hasUsed("FenglveZonghengCard") and not self.player:isKongcheng() then
    return sgs.Card_Parse("@FenglveZonghengCard=.&fenglvezongheng")
  end
end

sgs.ai_skill_use_func.FenglveZonghengCard = function(FLCard, use, self)
	if #self.enemies == 0 and #self.friends_noself == 0 then return end
  sgs.ai_use_priority.FenglveZonghengCard = 0.5
	local max_card = self:getMaxNumberCard()
	local max_point = max_card:getNumber()
	if self.player:hasShownSkill("yingyang") then max_point = math.min(max_point + 3, 13) end

  if #self.friends_noself > 0 then
    self:sort(self.friends_noself, "handcard", true)
  end
  for _, friend in ipairs(self.friends_noself) do--拆队友乐，判断闪电？
    if not friend:isKongcheng() and friend:containsTrick("indulgence") and self:getOverflow(friend) > 0 then
      local friend_min_card = self:getMinNumberCard(friend)
      local friend_number = friend_min_card and friend_min_card:getNumber() or 100
      if friend_min_card and friend:hasShownSkill("yingyang") then friend_number = math.max(friend_number - 3, 1) end
      if max_point> friend_number then
        local hcards = sgs.QList2Table(self.player:getHandcards())
        self:sortByUseValue(hcards, true)
        for _, c in ipairs(hcards) do
          if c:getNumber() + (self.player:hasShownSkill("yingyang") and 3 or 0) > friend_number then
            sgs.ai_use_priority.FenglveCard = 4.2
            self.fenglve_card = c:getEffectiveId()
            use.card = FLCard
            if use.to then
              use.to:append(friend)
              return
            end
          end
        end
      end
      if not friend_min_card and max_point > 9 then
        sgs.ai_use_priority.FenglveCard = 4.2--顺之后
        self.fenglve_card = max_card:getEffectiveId()
        use.card = FLCard
        if use.to then
          use.to:append(friend)
          return
        end
      end
    end
  end

  if #self.enemies == 0 then return end
  local notlose = false
  if self.player:getCardCount(true) < (self:needToThrowArmor() and 2 or 1) and not self:isValuableCard(max_card) then
    notlose = true
  end
	self:sort(self.enemies, "handcard")
	for _, enemy in ipairs(self.enemies) do
		if not enemy:isKongcheng() and enemy:getCardCount(true) > 1 then
			local enemy_max_card = self:getMaxNumberCard(enemy)
			local enemy_number = enemy_max_card and enemy_max_card:getNumber() or 100
			if enemy_max_card and enemy:hasShownSkill("yingyang") then enemy_number = math.min(enemy_number + 3, 13) end
			local allknown = false
			if self:getKnownNum(enemy) == enemy:getHandcardNum() then
				allknown = true
			end
			if (not enemy_max_card and (max_point > 12)) or notlose
				or (max_point > enemy_number and not allknown and max_point > 11)
				or (max_point > enemy_number and allknown) then
          if notlose or (max_point > enemy_number and allknown) then
            sgs.ai_use_priority.FenglveZonghengCard = 5
          end
					self.fenglvezongheng_card = max_card:getEffectiveId()
					use.card = FLCard
					if use.to then
            use.to:append(enemy)
            return
          end
			end
		end
	end
end

function sgs.ai_skill_pindian.fenglvezongheng(minusecard, self, requestor)
  local max_card = self:getMaxNumberCard()
  if not self:isFriend(requestor) and self.player:getCardCount(true) < 4 then
    local max_point = max_card:getNumber()
    for _, card in sgs.qlist(self.player:getHandcards()) do
			local point = card:getNumber()
			if point > max_point then
				max_point = point
				max_card = card
			end
		end
  end
  if self:isFriend(requestor) and (self.player:getJudgingArea():length() > 0 or self:needToThrowArmor()) then
    return self:getMinNumberCard()
  end
	return max_card
end

sgs.ai_cardneed.fenglvezongheng = sgs.ai_cardneed.bignumber

sgs.ai_skill_invoke.anyong =  function(self, data)
  if not self:willShowForAttack() then
    return false
  end
  local damageStruct = self.player:getTag("AnyongDamagedata"):toDamage()
  if not self:damageIsEffective_(damageStruct) then
    return false
  end
  local card = damageStruct.card
  local original_num = damageStruct.damage
  local from = damageStruct.from
  local target = damageStruct.to--data:toPlayer()新源码的data有问题
  if not target or (self:isFriend(target) and not target:isChained()) then
    return false
  end

  local function damageCount(tp,num,chained)
    local n = num
    if tp:hasShownSkill("mingshi") and not from:hasShownAllGenerals() then
      n = n - 1
    end
    if tp:getMark("##xiongnve_avoid") > 0 then
      n = n - 1
    end
    local gongqing_avoid = false
    if tp:hasShownSkill("gongqing") then
      if from:getAttackRange() < 3 then
        gongqing_avoid = true
      end
      if from:getAttackRange() > 3 then
        n = n + 1
      end
    end
    if (tp:hasArmorEffect("SilverLion") and (not card or not card:isKindOf("Slash") or not IgnoreArmor(from, tp)))
    or gongqing_avoid or (tp:hasSkill("qiuan") and tp:getPile("letter"):isEmpty()) then
      n = 1
    else
      if not chained then--初次加伤，非传导伤害
        n = n * 2
      end
      if damageStruct.nature == sgs.DamageStruct_Fire and (tp:hasArmorEffect("Vine")) then--暗涌增加伤害时机在藤甲前
        n = n + 1
      end
    end
    Global_room:writeToConsole("暗涌预测伤害:"..sgs.Sanguosha:translate(string.format("SEAT(%s)",tp:getSeat()))..n)
    return n
  end

  local anyong_damage = damageCount(target ,original_num)
  if target:hasArmorEffect("Breastplate") and anyong_damage >= target:getHp() then
    return false
  end

  local allshown_invoke = target:hasShownAllGenerals()
                      and (self.player:getHp() > 1 or (self:getCardsNum("Peach") + self:getCardsNum("Analeptic")) > 0)
  local oneshown_invoke = not target:hasShownAllGenerals() and target:hasShownOneGeneral()
                      and (self.player:getHandcardNum() < 2 or self:getOverflow() > 1 or self.player:hasSkill("lirang"))
  local chained_invoke = false

  if target:isChained() and damageStruct.nature ~= sgs.DamageStruct_Normal then
    local tDamageNum = damageCount(target ,original_num)--考虑初次传导伤害
    local enemy_dnum = self:isEnemy(target) and tDamageNum or 0
    local friend_dnum = self:isFriend(target) and tDamageNum or 0
    local neutrality_dum = (not self:isFriend(target) and not self:isEnemy(target)) and tDamageNum or 0

    for _, p in sgs.qlist(self.room:getOtherPlayers(target)) do
      if p:isChained() then
        damageStruct.to = p
        if self:damageIsEffective_(damageStruct) then
          if from:hasSkill("xinghuo") and damageStruct.nature == sgs.DamageStruct_Fire then--xinghuo是预置加伤可连续传导
            tDamageNum = tDamageNum + 1
          end
          damageStruct.damage = tDamageNum
          local damage_num = damageCount(p, tDamageNum, true)
          if self:isEnemy(p) then
            enemy_dnum = enemy_dnum + damage_num
          elseif self:isFriend(p) then
            friend_dnum = friend_dnum + damage_num
          else
            neutrality_dum = neutrality_dum + damage_num
          end
        end
      end
    end
    if enemy_dnum > 3 and enemy_dnum + neutrality_dum > friend_dnum then
      chained_invoke = true
    end
  end

  if chained_invoke or (not self:isFriend(target) and not target:hasShownOneGeneral() and anyong_damage > 1)
  or (self:isEnemy(target) and anyong_damage > 1 and ((self:isWeak(target) and target:getHp() == 1)
      or oneshown_invoke or (anyong_damage > 2 and allshown_invoke))) then
    return true
  end
	return false
end

--羊祜
sgs.ai_skill_invoke.deshao = function(self, data)
  if not self:willShowForDefence() then
    return false
  end
  local target = data:toPlayer()
  --暂时用不到
  --local use = self.player:getTag("DeshaoUsedata"):toCardUse()
  --local card = use.card
  if target and self:isFriend(target) then
    if self:needToThrowArmor(target) then
      return true
    end
    return false
  end
  return true
end

local mingfa_skill = {}
mingfa_skill.name = "mingfa"
table.insert(sgs.ai_skills, mingfa_skill)
mingfa_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("MingfaCard") then return end
	return sgs.Card_Parse("@MingfaCard=.&mingfa")
end

sgs.ai_skill_use_func.MingfaCard = function(card, use, self)
  local target

  local compare_func = function(a, b)
    local amax = self:getOverflow(a,true)
    local bmax = self:getOverflow(b,true)
    if amax == bmax then
      return a:getHandcardNum() < b:getHandcardNum()
    else
      return amax < bmax
    end
	end

  table.sort(self.enemies, compare_func)
  if math.min(self.player:getHandcardNum(), self:getOverflow(self.player,true)) < 2 then--牌少时摸牌
    Global_room:writeToConsole("明伐牌少时")
    self.enemies = sgs.reverse(self.enemies)
  end
  if #self.enemies == 0 then
    local targets = {}
    for _, p in sgs.qlist(self.room:getAlivePlayers()) do
      if not self.player:willBeFriendWith(p) and p:getMark("##mingfa") < 1 then
        table.insert(targets, p)
      end
    end
    table.sort(targets, compare_func)
    if math.min(self.player:getHandcardNum(), self:getOverflow(self.player,true)) < 2 then--牌少时摸牌
      targets = sgs.reverse(targets)
    end
    target = targets[1]
  else
    for _, p in ipairs(self.enemies) do
      if p:getMark("##mingfa") < 1 then
        target = p
        break
      end
    end
  end
  if target and self:isFriend(target) and
  (math.min(self.player:getHandcardNum(), self:getOverflow(self.player,true))
    > math.min(target:getHandcardNum() + 1, self:getOverflow(target,true))) then
    target = nil
  end
  if target then
    Global_room:writeToConsole("明伐目标:"..sgs.Sanguosha:translate(target:getGeneralName()).."/"..sgs.Sanguosha:translate(target:getGeneral2Name()))
	  use.card = card
    if use.to then
      use.to:append(target)
    end
  end
end

sgs.ai_use_priority.MingfaCard = 0.5

sgs.ai_skill_choice.mingfa = function(self, choices, data)
  local target = data:toPlayer()
  if self:isFriend(target) then
    return "yes"
  end
  return "no"
end

local mingfazongheng_skill = {}
mingfazongheng_skill.name = "mingfazongheng"
table.insert(sgs.ai_skills, mingfazongheng_skill)
mingfazongheng_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("MingfaZonghengCard") or self.player:isNude() then return end
  local target

  local compare_func = function(a, b)
    local amax = self:getOverflow(a,true)
    local bmax = self:getOverflow(b,true)
    if amax == bmax then
      return a:getHandcardNum() < b:getHandcardNum()
    else
      return amax < bmax
    end
	end

  table.sort(self.enemies, compare_func)
  if #self.enemies == 0 then
    local targets = {}
    for _, p in sgs.qlist(self.room:getAlivePlayers()) do
      if not self.player:isFriendWith(p) and p:getMark("##mingfa") < 1 then
        table.insert(targets, p)
      end
    end
    table.sort(targets, compare_func)
    target = targets[1]
  else
    for _, p in ipairs(self.enemies) do
      if p:getMark("##mingfa") < 1 then
        target = p
        break
      end
    end
  end
  if target and self:isEnemy(target) and--有确定目标才弃牌
  (math.min(self.player:getHandcardNum(), self:getOverflow(self.player,true))
    > math.min(target:getHandcardNum() + 1, self:getOverflow(target,true))
    or self:getOverflow() > 0) then
    self.qzzh_target = target
    local cards = self.player:getCards("he")
    cards = sgs.QList2Table(cards)
    self:sortByUseValue(cards, true)
    return sgs.Card_Parse("@MingfaZonghengCard=" .. cards[1]:getEffectiveId() .."&mingfazongheng")
  end
end

sgs.ai_skill_use_func.MingfaZonghengCard = function(card, use, self)
  if self.qzzh_target then
    local target = self.qzzh_target
    self.qzzh_target = nil
    Global_room:writeToConsole("明伐纵横目标:"..sgs.Sanguosha:translate(target:getGeneralName()).."/"..sgs.Sanguosha:translate(target:getGeneral2Name()))
	  use.card = card
    if use.to then
      use.to:append(target)
    end
  end
end

sgs.ai_use_priority.MingfaZonghengCard = 2