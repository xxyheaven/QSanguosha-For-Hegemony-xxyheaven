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
--崔毛

--于禁
--function SmartAI:commandforenemy(self,command_index,command_from) 让敌人选军令都能用

--王平
local jianglve_skill = {}
jianglve_skill.name = "jianglve"
table.insert(sgs.ai_skills, jianglve_skill)
jianglve_skill.getTurnUseCard = function(self, inclusive)
	if self.player:getMark("@strategy") < 1 then return end
--[[
	for _, friend in ipairs(self.friends) do--和雄异相同的触发条件
		if (self:objectiveLevel(friend) == 2 or self.player:isFriendWith(friend)) and self:isWeak(friend) then
			return sgs.Card_Parse("@JianglveCard=.&jianglve")
		end
	end
  if count >=2 or self:isWeak() then
    return sgs.Card_Parse("@JianglveCard=.&jianglve")
  end
	if sgs.gameProcess() == "shu>>>" then--这个条件复制的雄异，大国？
		return sgs.Card_Parse("@JianglveCard=.&jianglve")
	end
]]--势力召唤有ai，直接自动发动
  return sgs.Card_Parse("@JianglveCard=.&jianglve")
end

sgs.ai_skill_use_func.JianglveCard= function(card, use, self)
	use.card = card
end

sgs.ai_card_intention.JianglveCard = -120
sgs.ai_use_priority.JianglveCard= 8.5

--[[
  ["#command1"] = "军令一：对你指定的角色造成1点伤害",
	["#command2"] = "军令二：摸一张牌，然后交给你两张牌",
	["#command3"] = "军令三：失去1点体力",
	["#command4"] = "军令四：本回合不能使用或打出手牌且所有非锁定技失效",
	["#command5"] = "军令五：叠置，本回合不能回复体力",
	["#command6"] = "军令六：选择一张手牌和一张装备区里的牌，弃置其余的牌",
  ]]--

sgs.ai_skill_choice["startcommand_jianglve"] = function(self, choices)
  self.player:speak(choices)
  choices = choices:split("+")
  local commands = {"command1", "command2", "command4", "command3", "command6", "command5"}--索引大小代表优先级，注意不是原顺序
  local command_value1 = table.indexOf(commands,choices[1])
  local command_value2 = table.indexOf(commands,choices[2])
  self.jianglve_index = math.min(command_value1,command_value2)--需要一些额外的标记？
  --global_room:writeToConsole("choice:".. choices[self.jianglve_index])
  return commands[self.jianglve_index]
end

sgs.ai_skill_choice["docommand_jianglve"] = function(self, choices)
  --[[if self.jianglve_index <= 4 then
    return "yes"
  end
  if self.jianglve_index == 5 then
    if self.player:getCards("he"):length() < 4 then
      return "yes"
    elseif self.player:getHp() < 3 and self:getCardsNum("Peach") == 0 and self.player:getCards("he"):length() < 6 then
      return "yes"
    else
      return "no"
    end
  end
  if self.jianglve_index == 6 then
    if not self.player:faceUp() then
      return "yes"
    elseif self.player:getHp() < 3 and self:getCardsNum("Peach") == 0 and self.player:getHandcardNum() < 3
    and math.random(1, 100) / 100 >= 50  then
      return "yes"
    else
      return "no"
    end
  end]]--
  return "yes"
end

sgs.ai_skill_playerchosen["command_jianglve"] = sgs.ai_skill_playerchosen.damage
--军令弃牌给牌需要每个军令分开写


sgs.ai_skill_choice["jianglve"] = function(self, choices)--ai势力召唤
  choices = choices:split("+")
  for _, choice in ipairs(choices) do
    global_room:writeToConsole(self.player:objectName().. ":明置选择" .. choice)
  end
  if table.contains(choices,"show_both_generals") then
    return "show_both_generals"
  end
  if table.contains(choices,"show_deputy_general") then
    return "show_deputy_general"
  end
  if table.contains(choices,"show_head_general") then
    return "show_head_general"
  end
  return choices[1]
end

--法正
sgs.ai_skill_invoke.enyuan = function(self, data)
  return true
end

sgs.ai_skill_exchange["_enyuan"] = function(self,pattern,max_num,min_num,expand_pile)
  if self.player:isKongcheng() then
    return {}
  end
  local cards = self.player:getHandcards() -- 获得所有手牌
  cards=sgs.QList2Table(cards) -- 将列表转换为表
  self:sortByUseValue(cards, true) -- 按使用价值从小到大排序
  if cards[1]:isKindOf("Peach") then
    --[[
    local fazheng = sgs.findPlayerByShownSkillName("enyuan")
    if self:isFriend(fazheng) then
      return cards[1]:getId()
    end
    ]]--
    local kingdom = self.player:getKingdom()
    --[[self.player:speak(kingdom)
    self.player:speak(sgs.Sanguosha:translate(self.player:getKingdom()))]]--
    if kingdom == "shu" then
      return {cards[1]:getId()}
    end
    return {}
  end
  return {cards[1]:getId()}
end

--从sgs.ai_skill_use.slash里复制的杀目标选择
local function getSlashtarget(self)
  local max_range = 0
  local horse_range = 0
  local current_range = self.player:getAttackRange()
  for _,card in sgs.qlist(self.player:getCards("he")) do
    if card:isKindOf("Weapon") and max_range < sgs.weapon_range[card:getClassName()] then
      max_range = sgs.weapon_range[card:getClassName()]
    end
  end
  if self:getCardsNum("OffensiveHorse") > 0 and not self.player:getOffensiveHorse() then
    horse_range = 1
  end
  --注意正负，距离增大是负修正
  local range_fix = math.min(current_range - max_range, 0) - horse_range
	local slashes = self:getCards("Slash")
  if not slashes then return nil end
	self:sortByUseValue(slashes)
	self:sort(self.enemies, "defenseSlash")
	for _, slash in ipairs(slashes) do
		for _, enemy in ipairs(self.enemies) do
			if self.player:canSlash(enemy, slash, true, range_fix) and not self:slashProhibit(slash, enemy)
				and self:slashIsEffective(slash, enemy) and sgs.isGoodTarget(enemy, self.enemies, self)
				and not (self.player:hasFlag("slashTargetFix") and not enemy:hasFlag("SlashAssignee")) then
				return enemy
			end
		end
	end
  self.need_liegong_distance = false
  for _, slash in ipairs(slashes) do--距离再修正1寻找敌人
		for _, enemy_1 in ipairs(self.enemies) do
			if self.player:canSlash(enemy_1, slash, true, range_fix-1) and not self:slashProhibit(slash, enemy_1)
				and self:slashIsEffective(slash, enemy_1) and sgs.isGoodTarget(enemy_1, self.enemies, self)
				and not (self.player:hasFlag("slashTargetFix") and not enemy_1:hasFlag("SlashAssignee")) then
          self.need_liegong_distance = true
				return enemy_1
			end
		end
	end
  return nil
end

--是否发动眩惑，顺带小判定
local function shouldUseXuanhuo(self)
  local xuanhuosklii = {"wusheng", "paoxiao", "longdan", "tieqi", "liegong", "kuanggu"}
  for _, p in sgs.qlist(self.room:getAlivePlayers()) do
    for _, skill in ipairs(xuanhuosklii) do
      if p:hasShownSkill(skill) then
        table.removeOne(xuanhuosklii,skill)
      end
    end
  end
  if #xuanhuosklii == 0 then--不太常见的没有技能可选
    return false
  end

  self.need_kaunggu_AOE = false
  if table.contains(xuanhuosklii,"kuanggu") and (self:getCardsNum("SavageAssault") + self:getCardsNum("ArcheryAttack") > 0) and
  (self.player:getOffensiveHorse() or self.player:hasShownSkills("mashu_machao|mashu_madai")
  or self:getCardsNum("OffensiveHorse") > 0 and not self.player:getOffensiveHorse()) then
    self.need_kaunggu_AOE = true
    self.player:speak("需要眩惑狂骨AOE")
    self.room:writeToConsole("需要眩惑狂骨AOE:"..self.player:objectName())
    return true
  end

  local target = getSlashtarget(self)
  if table.contains(xuanhuosklii,"liegong") and self.need_liegong_distance then
    local liubei = self.room:getLord(self.player:getKingdom())
    if liubei and liubei:hasLordSkill("shouyue") then
      self.player:speak("需要眩惑君刘备烈弓距离")
      self.room:writeToConsole("需要眩惑君刘备烈弓距离:"..self.player:objectName())
      return true
    else
      self.need_liegong_distance = false
    end
  end

  if not target then--无杀目标或无杀
    return false
  end

  if self.player:getMark("@strategy") >= 1 or self.player:getHandcardNum() > 4
   or (self.player:getHandcardNum() > 3 and self.player:getCards("e"):length() > 0) then
    self.player:speak("符合眩惑条件")
    self.room:writeToConsole("符合眩惑条件:"..self.player:objectName())
    return true
  end
  return false
end

--真君主技眩惑
local xuanhuoattach_skill = {}
xuanhuoattach_skill.name = "xuanhuoattach"
table.insert(sgs.ai_skills, xuanhuoattach_skill)
xuanhuoattach_skill.getTurnUseCard = function(self, inclusive)
  if self.player:getHandcardNum() < 2 then return end--牌不足
  if not self.player:hasUsed("XuanhuoAttachCard") and shouldUseXuanhuo(self) then
    local cards = self.player:getHandcards()
	  cards = sgs.QList2Table(cards)
	  self:sortByUseValue(cards, true) -- 按使用价值从小到大排序
    --global_room:writeToConsole("眩惑技能卡:" ..self.player:objectName())
		return sgs.Card_Parse("@XuanhuoAttachCard=" .. cards[2]:getEffectiveId())
	end
  return
end

sgs.ai_skill_use_func.XuanhuoAttachCard= function(card, use, self)
  sgs.ai_use_priority.XuanhuoAttachCard = 5
  self.player:speak("发动眩惑")
  if self.player:getMark("@strategy") >= 1 then--在王平限定技发动前
    sgs.ai_use_priority.XuanhuoAttachCard = sgs.ai_use_priority.JianglveCard + 0.1
  end
  if self.player:hasSkill("jizhi") then--使用锦囊后
    sgs.ai_use_priority.XuanhuoAttachCard = 2.8
  end
    if self.need_kaunggu_AOE then
    sgs.ai_use_priority.XuanhuoAttachCard = 3.6
  end
  if self.player:hasSkill("jili") then--使用完武器后
    sgs.ai_use_priority.XuanhuoAttachCard = 6
  end
  for _, p in ipairs(self.friends) do
    if p:hasShownSkill("yongjue") and self.player:isFriendWith(p) then
      sgs.ai_use_priority.XuanhuoAttachCard = 9.6--勇决杀的优先调整到9.5
    end
  end
	use.card = card
  return
end

sgs.ai_card_intention.XuanhuoAttachCard = -90

sgs.ai_skill_discard["xuanhuo_discard"] = function(self, discard_num, min_num, optional, include_equip)
	if self.player:getHandcardNum() < 2 then
		return {}
	else
		return self:askForDiscard("dummy_reason", 1, 1, false, true)
	end
	return {}
end

sgs.ai_skill_choice.xuanhuo = function(self, choices)
  choices = choices:split("+")
  local xuanhuosklii = {"wusheng", "paoxiao", "longdan", "tieqi", "liegong", "kuanggu"}
  local has_wusheng = self.player:hasSkill("wusheng")
  local has_paoxiao = self.player:hasSkill("paoxiao")
  local has_longdan = self.player:hasSkill("longdan")
  local has_tieqi = self.player:hasSkill("tieqi")
  local has_liegong = self.player:hasSkill("liegong")
  local has_kuanggu = self.player:hasSkill("kuanggu")
  local has_qianxi = self.player:hasSkill("qianxi")
  local has_Crossbow = self:getCardsNum("Crossbow") > 0
  local has_yongjue = false

  for _, p in ipairs(self.friends) do
    if p:hasShownSkill("yongjue") and self.player:isFriendWith(p) then
      has_yongjue = true
      break
    end
  end

  local need_tieqi = false
  local can_liegong = false
  local can_kuanggu = false
  local lord_longdan = false

  local target = getSlashtarget(self)
  if table.contains(choices,"tieqi") then
    local skills_name = (sgs.masochism_skill .. "|" .. sgs.save_skill .. "|" .. sgs.defense_skill .. "|"
					.. sgs.wizard_skill):split("|")
					--[[ .. "|" .. sgs.usefull_skill]]--更新技能名单
	  for _, skill_name in ipairs(skills_name) do
		  local skill = sgs.Sanguosha:getSkill(skill_name)
		  if target:hasShownSkill(skill_name) and skill and skill:getFrequency() ~= sgs.Skill_Compulsory then
        need_tieqi = true--有需要铁骑的技能
        break
      end
	  end
  end
  if table.contains(choices,"liegong") and (target:getHandcardNum() >= self.player:getHp() or target:getHandcardNum() <= self.player:getAttackRange()) then
    can_liegong = true--符合烈弓发动条件
  end
  if table.contains(choices,"kuanggu") and (self.player:hasShownSkills("mashu_machao|mashu_madai") or self.player:distanceTo(target) < 2
  or (self.player:distanceTo(target) == 2 and self:getCardsNum("OffensiveHorse") > 0 and not self.player:getOffensiveHorse())) then
    can_kuanggu = true--有马术或-1马或距离为1
  end
  if table.contains(choices,"longdan") then
    local liubei = self.room:getLord(self.player:getKingdom())
    if liubei and liubei:hasLordSkill("shouyue") then
      lord_longdan = true--有君刘备
    end
  end

  for _, choice in ipairs(choices) do
    --global_room:writeToConsole(self.player:objectName().. ":可选技能" .. choice) and not self:getCardsNum("Crossbow") > 0
  end
  global_room:writeToConsole(self.player:objectName() .. ":选取技能")

  if self.need_liegong_distance then
    return "liegong"--或需要眩惑君刘备烈弓距离
  end
  if self.need_kaunggu_AOE then
    return "kuanggu"--或需要眩惑狂骨AOE
  end

  --已有双技能的情况
  if has_kuanggu and (has_tieqi or has_liegong or has_qianxi) then--魏延和马超兄弟/黄忠
    if has_Crossbow then
      if table.contains(choices,"wusheng") then
        return "wusheng"
      elseif table.contains(choices,"longdan") then
        return "longdan"
      end
    elseif table.contains(choices,"paoxiao") then
      return "paoxiao"
    end
  end
  if (has_wusheng or has_longdan) and (has_paoxiao or has_Crossbow) then--关张和赵张
    if can_kuanggu then
      return "kuanggu"
    elseif need_tieqi then
      return "tieqi"
    elseif can_liegong then
      return "liegong"
    end
  end
  if has_kuanggu and has_paoxiao then--魏延和张飞
    if table.contains(choices,"wusheng") then
      return "wusheng"
    elseif lord_longdan then
      return "longdan"
    elseif need_tieqi then
      return "tieqi"
    elseif can_liegong then
      return "liegong"
    end
  end
  if (has_paoxiao or has_Crossbow) and (has_tieqi or has_liegong or has_qianxi) then--张飞和马超兄弟/黄忠
    if can_kuanggu then
      return "kuanggu"
    elseif table.contains(choices,"wusheng") then
      return "wusheng"
    elseif table.contains(choices,"longdan") then
      return "longdan"
    end
  end
  if (has_wusheng or has_longdan) and (has_tieqi or has_liegong or has_qianxi) then--关/赵和马超兄弟/黄忠
    if has_Crossbow and can_kuanggu then
      return "kuanggu"
    elseif table.contains(choices,"paoxiao") then
      return "paoxiao"
    elseif can_kuanggu then
      return "kuanggu"
    end
  end
  if (has_wusheng or has_longdan) and has_kuanggu then--关/赵和魏延
    if has_Crossbow and need_tieqi then
      return "tieqi"
    elseif has_Crossbow and can_liegong then
      return "liegong"
    elseif has_Crossbow and not can_liegong then
      return "tieqi"
    elseif table.contains(choices,"paoxiao") then
      return "paoxiao"
    elseif need_tieqi then
      return "tieqi"
    elseif can_liegong then
      return "liegong"
    end
  end

  --单技能的情况
  if (has_tieqi or has_liegong or has_qianxi) then--马超兄弟/黄忠
    if has_Crossbow and can_kuanggu then
      return "kuanggu"
    elseif can_kuanggu and self.player:getHp() <=2 then
      return "kuanggu"
    elseif table.contains(choices,"paoxiao") and (has_yongjue or self:getCardsNum("Slash") >= 2) then--咆哮
        return "paoxiao"
    else
      return "kuanggu"
    end
  end
  if(has_paoxiao or has_Crossbow) then--张飞
    if (has_yongjue or self:getCardsNum("Slash") >= 2)  then
      if can_kuanggu and self:getCardsNum("Slash") > 2 then
        return "kuanggu"
      elseif need_tieqi then
        return "tieqi"
      elseif can_liegong then
        return "liegong"
      elseif table.contains(choices,"tieqi") then--烈弓再找不到目标
        return "tieqi"
      end
    elseif table.contains(choices,"wusheng") then
      return "wusheng"
    elseif table.contains(choices,"longdan") then
      return "longdan"
    end
  end
  if (has_wusheng or has_longdan) then--关/赵
    if has_Crossbow and can_kuanggu then
      return "kuanggu"
    elseif table.contains(choices,"paoxiao") then
      return "paoxiao"
    end
  end
  if has_kuanggu then--魏延
    if has_Crossbow and (self.player:distanceTo(target) < 2
    or (self.player:distanceTo(target) == 2 and self:getCardsNum("OffensiveHorse") > 0 and not self.player:getOffensiveHorse())) then
      if table.contains(choices,"wusheng") then
        return "wusheng"
      elseif lord_longdan then
        return "longdan"
      end
    elseif self.player:getHp() <=2 then
      if need_tieqi then
        return "tieqi"
      elseif can_liegong then
        return "liegong"
      elseif table.contains(choices,"tieqi") then--烈弓再找不到目标
        return "tieqi"
      end
    elseif table.contains(choices,"paoxiao") and (has_yongjue or self:getCardsNum("Slash") >= 2) then--咆哮
      return "paoxiao"
    end
  end

  --普通的技能选择顺序
  if table.contains(choices,"paoxiao") and (has_yongjue or self:getCardsNum("Slash") >= 2) then--咆哮
    return "paoxiao"
  end
  if can_kuanggu and ((has_Crossbow and self:getCardsNum("Slash") > 2) or (self.player:getHp() < 2 and target:isKongcheng())) then
    return "kuanggu"
  end
  if need_tieqi then
    return "tieqi"
  end
  if can_liegong then
    return "liegong"
  end
  if table.contains(choices,"tieqi") then--烈弓再找不到目标
    return "tieqi"
  end
  if lord_longdan then
    return "longdan"
  end
  if table.contains(choices,"wusheng") then
    return "wusheng"
  end
  if table.contains(choices,"longdan") then--ai不会优先使用龙胆杀伤害或回复，暂不考虑
    return "longdan"
  end

  return choices[1]
end



--武圣
sgs.ai_view_as.wusheng_xh = function(card, player, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if (card_place ~= sgs.Player_PlaceSpecial or player:getHandPile():contains(card_id)) and (player:getLord() and player:getLord():hasShownSkill("shouyue") or card:isRed()) and not card:isKindOf("Peach") and not card:hasFlag("using") then
		return ("slash:wusheng_xh[%s:%s]=%d&wusheng_xh"):format(suit, number, card_id)
	end
end

local wusheng_xh_skill = {}
wusheng_xh_skill.name = "wusheng_xh"
table.insert(sgs.ai_skills, wusheng_xh_skill)
wusheng_xh_skill.getTurnUseCard = function(self, inclusive)

	self:sort(self.enemies, "defense")
	local useAll = false
	for _, enemy in ipairs(self.enemies) do
		if enemy:getHp() == 1 and not enemy:hasArmorEffect("EightDiagram") and self.player:distanceTo(enemy) <= self.player:getAttackRange() and self:isWeak(enemy)
			and getCardsNum("Jink", enemy, self.player) + getCardsNum("Peach", enemy, self.player) + getCardsNum("Analeptic", enemy, self.player) == 0 then
			useAll = true
			break
		end
	end

	local disCrossbow = false
	if self:getCardsNum("Slash") < 2 or self.player:hasSkill("paoxiao") then disCrossbow = true end

	local hecards = self.player:getCards("he")
	for _, id in sgs.qlist(self.player:getHandPile()) do
		hecards:prepend(sgs.Sanguosha:getCard(id))
	end
	local cards = {}
	for _, card in sgs.qlist(hecards) do
		if (self.player:getLord() and self.player:getLord():hasShownSkill("shouyue") or card:isRed()) and not card:isKindOf("Slash")
			and ((not isCard("Peach", card, self.player) and not isCard("ExNihilo", card, self.player)) or useAll)
			and (not isCard("Crossbow", card, self.player) or disCrossbow ) then
			local suit = card:getSuitString()
			local number = card:getNumberString()
			local card_id = card:getEffectiveId()
			local card_str = ("slash:wusheng_xh[%s:%s]=%d&wusheng_xh"):format(suit, number, card_id)
			local slash = sgs.Card_Parse(card_str)
			assert(slash)
			if self:slashIsAvailable(self.player, slash) then
				table.insert(cards, slash)
			end
		end
	end

	if #cards == 0 then return end

	self:sortByUsePriority(cards)
	return cards[1]
end

sgs.ai_suit_priority.wusheng_xh= "club|spade|diamond|heart"

--咆哮
sgs.ai_skill_invoke.paoxiao_xh = function(self, data)
	return true
end

--龙胆
local longdan_xh_skill = {}
longdan_xh_skill.name = "longdan_xh"
table.insert(sgs.ai_skills, longdan_xh_skill)
longdan_xh_skill.getTurnUseCard = function(self)
	local cards = sgs.QList2Table(self.player:getHandcards())
	for _, id in sgs.qlist(self.player:getHandPile()) do
		table.insert(cards, sgs.Sanguosha:getCard(id))
	end
	local jink_card

	self:sortByUseValue(cards,true)

	for _,card in ipairs(cards)  do
		if card:isKindOf("Jink") then
			jink_card = card
			break
		end
	end

	if not jink_card then return nil end
	local suit = jink_card:getSuitString()
	local number = jink_card:getNumberString()
	local card_id = jink_card:getEffectiveId()
	local card_str = ("slash:longdan_xh[%s:%s]=%d&longdan_xh"):format(suit, number, card_id)
	local slash = sgs.Card_Parse(card_str)
	assert(slash)

	return slash
end

sgs.ai_view_as.longdan_xh = function(card, player, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card_place == sgs.Player_PlaceHand or player:getHandPile():contains(card_id) then
		if card:isKindOf("Jink") then
			return ("slash:longdan_xh[%s:%s]=%d&longdan_xh"):format(suit, number, card_id)
		elseif card:isKindOf("Slash") then
			return ("jink:longdan_xh[%s:%s]=%d&longdan_xh"):format(suit, number, card_id)
		end
	end
end

--铁骑
sgs.ai_skill_invoke.tieqi_xh = function(self, data)
	local target = data:toPlayer()
	if self:isFriend(target) then return false end
	return true
end

sgs.ai_skill_choice.tieqi_xh = function(self, choices, data)
	local target = data:toPlayer()
	if self:isFriend(target) then return "deputy_general" end

	if target:hasShownOneGeneral() then
		if (target:hasShownGeneral1()) and not (target:getGeneral2() and target:hasShownGeneral2()) then
			return "head_general"
		end
		if not (target:hasShownGeneral1()) and (target:getGeneral2() and target:hasShownGeneral2()) then
			return "deputy_general"
		end
		if (target:hasShownGeneral1()) and (target:getGeneral2() and target:hasShownGeneral2()) then
			if target:getMark("skill_invalidity_deputy") > 0 then
				return "head_general"
			end
			if target:getMark("skill_invalidity_head") > 0 then
				return "deputy_general"
			end
			local skills_name = (sgs.masochism_skill .. "|" .. sgs.save_skill .. "|" .. sgs.defense_skill .. "|"
					.. sgs.wizard_skill):split("|")
					--[[ .. "|" .. sgs.usefull_skill]]--更新技能名单
			for _, skill_name in ipairs(skills_name) do
				local skill = sgs.Sanguosha:getSkill(skill_name)
				if target:inHeadSkills(skill_name) and skill and skill:getFrequency() ~= sgs.Skill_Compulsory then
					return "head_general"
				end
			end
			return "deputy_general"
		end
	end
	return "deputy_general"
end

--烈弓
sgs.ai_skill_invoke.liegong_xh = function(self, data)
	local target = data:toPlayer()
	return not self:isFriend(target)
end

--狂骨
sgs.ai_skill_invoke.kuanggu_xh = function(self, data)
	return true
end

sgs.ai_skill_choice.kuanggu_xh = function(self, choices)
	if self.player:getHp() <= 2 or not self:slashIsAvailable() or self.player:getMark("GlobalBattleRoyalMode") > 0 then
		return "recover"
	end
	return "draw"
end

--吴国太
--[[
  local _skill = {}
_skill.name = ""
table.insert(sgs.ai_skills, _skill)
_skill.getTurnUseCard = function(self, inclusive)
	
end
]]--

--陆抗
sgs.ai_skill_invoke.keshou = function(self, data)
  local no_friend = true
  for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if self:isFriendWith(p) then
      no_friend = false
      break
    end
	end
  if self.player:getHp() < 3 or self.player:getHandcardNum() > 3 or no_friend or self.player:getMark("GlobalBattleRoyalMode") > 0 then
    return true
  end
  return false
end

sgs.ai_skill_cardask["@keshou"] = function(self, data, pattern, target, target2)
	if self.player:getHandcardNum() < 2 then--缺手牌
    return "."
  end

  if self.player:hasSkill("tianxiang") then--配合小乔
    for _,card in sgs.qlist(self.player:getHandcards()) do
      if card:getSuit() == sgs.Card_Heart or (self.player:hasSkill("hongyan") and card:getSuit() == sgs.Card_Spade) then
        return "."
      end
    end
  end
 
    local cards = self.player:getHandcards() -- 获得所有手牌
    cards=sgs.QList2Table(cards) -- 将列表转换为表
    local keshou_cards = {}
    if self.player:getHandcardNum() == 2  then--两张手牌的情况
      if cards[1]:sameColorWith(cards[2]) and not cards[1]:isKindOf("Peach") and not cards[2]:isKindOf("Peach") then
        table.insert(keshou_cards, cards[1]:getId())
        table.insert(keshou_cards, cards[2]:getId())
        return "$" .. table.concat(keshou_cards, "+")
      end
    else--三张及以上手牌
      self:sortByKeepValue(cards) -- 按保留值排序
      if cards[1]:sameColorWith(cards[2]) and not cards[1]:isKindOf("Peach") and not cards[2]:isKindOf("Peach") then
        table.insert(keshou_cards, cards[1]:getId())
        table.insert(keshou_cards, cards[2]:getId())
        return "$" .. table.concat(keshou_cards, "+")
      elseif cards[1]:sameColorWith(cards[3]) and not cards[1]:isKindOf("Peach") and not cards[3]:isKindOf("Peach") then
        table.insert(keshou_cards, cards[1]:getId())
        table.insert(keshou_cards, cards[3]:getId())
        return "$" .. table.concat(keshou_cards, "+")
      elseif cards[2]:sameColorWith(cards[3]) and not cards[2]:isKindOf("Peach") and not cards[3]:isKindOf("Peach") then
        table.insert(keshou_cards, cards[2]:getId())
        table.insert(keshou_cards, cards[3]:getId())
        return "$" .. table.concat(keshou_cards, "+")
      end
    end
  return "."
end

sgs.ai_skill_invoke.zhuwei= function(self, data)
    if not self:willShowForDefence() then
		  return false
  	end
    return true
end

sgs.ai_skill_choice.zhuwei = function(self, choices, data)
  local target = self.room:getCurrent()
  if self:isFriend(target) then
    return "yes"
  else
    return "no"
  end
end

--张绣
sgs.ai_skill_playerchosen.fudi_damage = sgs.ai_skill_playerchosen.damage

sgs.ai_skill_exchange.fudi= function(self,pattern,max_num,min_num,expand_pile)
    if not self:willShowForMasochism() or self.player:isKongcheng() then
        return {}
    end

    local cards = self.player:getHandcards() -- 获得所有手牌
    cards=sgs.QList2Table(cards) -- 将列表转换为表
    self:sortByKeepValue(cards) -- 按保留值排序
    if cards[1]:isKindOf("Peach") then
        return {}
    end
	
	local from = self.player:getTag("FudiTarget"):toPlayer()
	
	local x = self.player:getHp()

	local targets = sgs.SPlayerList()
	
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if not from:isFriendWith(p) or p:getHp() < x then
			continue
		end
		if p:getHp() > x then
			targets = sgs.SPlayerList()
		end
		x = p:getHp()
		targets:append(p)
	end
	
	if targets:isEmpty() then return {} end
	
	for _, target in sgs.qlist(targets) do
		if self:isEnemy(target) and self:damageIsEffective(target, nil, self.player) and not self:getDamagedEffects(target, self.player)
			and not self:needToLoseHp(target, self.player) then
			return cards[1]:getId()
		end
	end
	for _, target in sgs.qlist(targets) do
		if self:isFriend(target) and self:damageIsEffective(target, nil, self.player)
			and (self:getDamagedEffects(target, self.player) or self:needToLoseHp(target, self.player, nil, true)) then
			return cards[1]:getId()
		end
	end
	
  return {}
end

function sgs.ai_slash_prohibit.fudi(self, from, to)
	if self:isFriend(to, from) then return false end
	if to:isKongcheng()  then return false end
  if from:getHp() >= 3 or (to:getHp() - from:getHp() > 1) then return false end
  if from:hasShownSkill("tieqi") then return false end
  self:sort(self.friends_noself,"hp", true)
  for _, friend in ipairs(self.friends_noself) do
    if friend:getHp() > from:getHp() and from:isFriendWith(friend) and friend:isAlive() then
      if friend:getHp() >=3 or (friend:getHandcardNum() + friend:getHp() > 4) then
        return false
      end
    end
  end
	return (from:getHandcardNum() + from:getHp()) - math.min(to:getHp(), to:getHandcardNum()) < 4
end

sgs.ai_skill_invoke.congjian = function(self, data)
  if self.player:getPhase() ~= sgs.Player_NotActive then
    return false
  end
  local target = data:toDamage().to
	return not self:isFriend(target)
end

--袁术
sgs.ai_skill_invoke.yongsi = function(self, data)
    if not self:willShowForAttack() then
		return false
	end
    return true
end

--君曹操
sgs.ai_skill_cardask["@elitegeneralflag"] = function(self)
	
	
	
	
	
	
	
	
	
	
	return "."
end
