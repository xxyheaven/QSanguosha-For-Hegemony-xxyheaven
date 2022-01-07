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
--新杀专属

--蒋干
sgs.ai_skill_invoke.weicheng = true

local daoshu_skill= {}
daoshu_skill.name = "daoshu"
table.insert(sgs.ai_skills, daoshu_skill)
daoshu_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasUsed("DaoshuCard") then return end
	if #self.enemies == 0 then return end
	return sgs.Card_Parse("@DaoshuCard=.&daoshu")
end

sgs.ai_skill_use_func.DaoshuCard = function(card, use, self)
	sgs.ai_use_priority.DaoshuCard = 2.9--合纵连横之后
	local rand = math.random(1, 7)
	if rand == 3 then
		self.daoshu_suit = 0
	elseif rand == 4 then
		self.daoshu_suit = 1
	elseif rand < 3 then
		self.daoshu_suit = 2
	else
		self.daoshu_suit = 3
	end
--保留牌中闪大概率是方块，桃大概率红心
--[[
	Card::Spade,
    Card::Club,
    Card::Heart,
    Card::Diamond
--	黑桃（sgs.Card_Spade）：0
--	草花（sgs.Card_Club）：1
--	红心（sgs.Card_Heart）：2
--	方块（sgs.Card_Diamond）：3
]]--教程有误看源码
	local known_suit = {0,0,0,0}
	self:sort(self.enemies, "handcard")
	for _, enemy in ipairs(self.enemies) do
		if not enemy:isKongcheng() and not self:doNotDiscard(enemy, "h") and self:damageIsEffective(enemy, nil, self.player) then
			known_suit[1] = getKnownCard(enemy, self.player, "spade", true, "h")
			known_suit[2] = getKnownCard(enemy, self.player, "club", true, "h")
			known_suit[3] = getKnownCard(enemy, self.player, "heart", true, "h")
			known_suit[4] = getKnownCard(enemy, self.player, "diamond", true, "h")
			for _, suit in ipairs(known_suit) do
				if suit == enemy:getHandcardNum() then--如果已知花色等于手牌数
					sgs.ai_use_priority.DaoshuCard = 5.3
					self.daoshu_suit = table.indexOf(known_suit,suit) - 1
					--Global_room:writeToConsole("已知花色:"..self.daoshu_suit)
					use.card = card
					if use.to then
						use.to:append(enemy)
					end
					return
				end
			end
		end
	end
	self:sort(self.enemies, "hp")
	for _, enemy in ipairs(self.enemies) do
		if not enemy:isKongcheng() and not self:doNotDiscard(enemy, "h") and self:damageIsEffective(enemy, nil, self.player) then
			known_suit[1] = getKnownCard(enemy, self.player, "spade", true, "h")
			known_suit[2] = getKnownCard(enemy, self.player, "club", true, "h")
			known_suit[3] = getKnownCard(enemy, self.player, "heart", true, "h")
			known_suit[4] = getKnownCard(enemy, self.player, "diamond", true, "h")
			--sgs.debugFunc(self.player, 1)
			local max_suit = math.max(known_suit[1], known_suit[2], known_suit[3], known_suit[4])
			if 3*max_suit >= enemy:getHandcardNum() then--已知花色大于等于1/3
				self.daoshu_suit = table.indexOf(known_suit,max_suit) - 1
			end
			if enemy:hasSkill("hongyan") then--针对小乔
				self.daoshu_suit = 2
			end
			--Global_room:writeToConsole("最多的花色数量:"..max_suit)
			use.card = card
			if use.to then
				use.to:append(enemy)
			end
			return
		end
	end
end

sgs.ai_skill_suit.daoshu= function(self)--有空可以增加配合合纵连横，估计需要改合纵连横的ai
	--Global_room:writeToConsole("选择花色:"..self.daoshu_suit)
	return self.daoshu_suit
end

sgs.ai_skill_cardask["@daoshu-give"] = function(self, data, pattern, target, target2)
	--Global_room:writeToConsole("盗书返还函数")
	if not target2 or target2:isDead() then return "." end
	local cards = {}
	--Global_room:writeToConsole("pattern参数:"..pattern)
	local patternt = pattern:split("|")
	--Global_room:writeToConsole("pattern花色:"..patternt[2])
	local suit = (patternt[2]):split(",")
	--Global_room:writeToConsole("盗书返还函数花色:"..table.concat(suit,","))
	for _,c in sgs.qlist(self.player:getCards("h")) do
		if table.contains(suit, c:getSuitString()) then--sgs.Sanguosha:matchExpPattern(pattern,self.player,c)
			table.insert(cards, c)
		end
	end
	if #cards == 0 then return "." end
	self:sortByUseValue(cards, true)

	local flag = string.format("%s_%s_%s", "visible", self.player:objectName(), target2:objectName())
	if not cards[1]:hasFlag("visible") then cards[1]:setFlags(flag) end--记录方便后续盗书

	return "$" .. cards[1]:getEffectiveId()
end

--周夷
sgs.ai_skill_invoke.zhukou = true

sgs.ai_skill_invoke.duannian = function(self, data)
	local has_peach = false
	for _, card in sgs.qlist(self.player:getHandcards()) do
		if isCard("Peach", card, self.player) or (isCard("Analeptic", card, self.player) and self:isWeak()) then
			has_peach = true
		end
	end
	if not has_peach then
		if self.player:getHandcardNum() < self.player:getMaxHp() then
			return true
		end
		if self.player:getHandcardNum() == self.player:getMaxHp() and self:getCardsNum("Jink") == 0 then
			return true
		end
		if self.player:getHandcardNum() > self.player:getMaxHp() and self:getOverflow() > 0 and self:getCardsNum("Jink") == 0 then
			return true
		end
	end
	return false
end

sgs.ai_skill_playerchosen.lianyou = function(self, targets)
	local targetlist = sgs.QList2Table(targets)
	self:sort(targetlist, "hp", true)
	for _, target in ipairs(targetlist) do--考虑方便火烧
		if self:isFriendWith(target) and target:getHp() > 1 and self:isEnemy(target:getNextAlive()) then
			return target
		end
	end
	for _, target in ipairs(targetlist) do
		if self:isFriendWith(target) then return target end
	end
	for _, target in ipairs(targetlist) do
		if self:isFriend(target) and target:getHp() > 1 and self:isEnemy(target:getNextAlive()) then
			return target
		end
	end
	for _, target in ipairs(targetlist) do
		if self:isFriend(target) then return target end
	end
	return {}
end

--南华老仙
sgs.ai_skill_invoke.gongxiu = function(self, data)
	if self.player:getMark("gongxiuchoice") == 1 then
		local num = 0
		for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			if not self:isFriend(p) and not p:isNude() then
				num = num + 1
			end
		end
		if num == 0 or (num == 1 and self:isWeak() and not self:willSkipPlayPhase()) then
			return false
		end
	end
	return true
end

sgs.ai_skill_choice.gongxiu_choose = function(self, choices)
	choices = choices:split("+")
	if table.contains(choices, "discard") and table.contains(choices, "draw") then
		if #self.friends >= math.max(2, self.player:getMaxHp()) then
			return "draw"
		else
			return "discard"
		end
	end
	return choices[math.random(1, #choices)]
end

sgs.ai_skill_playerchosen.gongxiu_draw = function(self, targets, max_num, min_num)
	local result = {}
	local targetlist = sgs.QList2Table(targets)
	self:sort(targetlist, "handcard")
	for _, target in ipairs(targetlist) do
		if self:isFriendWith(target) and #result < max_num then
			table.insert(result, target)
			table.removeOne(targetlist, target)--防止重复
		end
	end
	for _, target in ipairs(targetlist) do
		if self:isFriend(target) and #result < max_num then
			table.insert(result, target)
			table.removeOne(targetlist, target)
		end
	end
	return result
end

sgs.ai_skill_playerchosen.gongxiu_discard = function(self, targets, max_num, min_num)
	local result = {}
	local targetlist = sgs.QList2Table(targets)
	self:sort(targetlist, "handcard")
	for _, target in ipairs(targetlist) do
		if self:isEnemy(target) and #result < max_num then
			table.insert(result, target)
			table.removeOne(targetlist, target)--防止重复
		end
	end
	for _, target in ipairs(targetlist) do
		if not self:isFriend(target) and #result < max_num then
			table.insert(result, target)
			table.removeOne(targetlist, target)
		end
	end
	return result
end

local jinghe_skill = {}
jinghe_skill.name = "jinghe"
table.insert(sgs.ai_skills, jinghe_skill)
jinghe_skill.getTurnUseCard = function(self, inclusive)
	if self.player:isKongcheng() or self.player:hasUsed("JingheCard") then return end
	local jinghe_show = {}
	local num = math.min(#self.friends, self.player:getMaxHp())

	local function canJingheShow(to_select)
		for _, id in ipairs(jinghe_show) do
			local selected = sgs.Sanguosha:getCard(id)
			if to_select:isKindOf("Slash") and selected:isKindOf("Slash") then
				return false
			end
			if to_select:isKindOf("Nullification") and selected:isKindOf("Nullification") then
				return false
			end
			if to_select:objectName() == selected:objectName() then
				return false
			end
		end
		return true
	end

	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards, true)
	for _, c in ipairs(cards) do
		if #jinghe_show < num and canJingheShow(c) then
			table.insert(jinghe_show, c:getId())
		end
	end
	return sgs.Card_Parse("@JingheCard=" .. table.concat(jinghe_show, "+") .."&jinghe")
end

sgs.ai_skill_use_func.JingheCard = function(card, use, self)
	use.card = card
	if use.to then
		for _, p in ipairs(self.friends) do
			if self.player:isFriendWith(p) and p:hasShownOneGeneral() and use.to:length() < card:subcardsLength() then
				use.to:append(p)
			end
		end
		for _, p in ipairs(self.friends) do
			if not use.to:contains(p) and p:hasShownOneGeneral() and use.to:length() < card:subcardsLength() then
				use.to:append(p)
			end
		end
	end
end

sgs.ai_card_intention.JingheCard = -90
sgs.ai_use_priority.JingheCard = 9.23--远交近攻和无中生有之后，更详细的判断？如配合敕令

sgs.ai_skill_choice.jinghe_skill = function(self, choices, data)
	--"leiji_tianshu+yinbing+huoqi+guizhu+xianshou+lundao+guanyue+yanzheng+cancel"
	Global_room:writeToConsole("共修选择"..self.player:objectName()..":"..choices)
	local current = self.room:getCurrent()
	local objnames = current:getTag("JingheTargets"):toString():split("+")
	local targets = {}
	for _, friend in ipairs(self.friends_noself) do
		if table.contains(objnames, friend:objectName()) and self:playerGetRound(friend) > self:playerGetRound(self.player) then--判断位次
			table.insert(targets, friend)
		end
	end

	choices = choices:split("+")
	table.removeOne(choices, "cancel")
	if table.contains(choices, "yanzheng") then
		if self.player:objectName() == current:objectName() and #choices > 1 then
			table.removeOne(choices, "yanzheng")
		end
	end
	if table.contains(choices, "leiji_tianshu") then
		if self.player:hasSkills(sgs.wizard_skill) then
			return "leiji_tianshu"
		end
		for _, p in ipairs(targets) do
			if p:hasSkills(sgs.wizard_skill) and #choices > 1 then
				table.removeOne(choices, "leiji_tianshu")
			end
		end
	end
	if table.contains(choices, "yinbing")then
		if self:hasCrossbowEffect() or self:getCardsNum("Crossbow") > 0 then
			return "yinbing"
		end
		for _, p in ipairs(targets) do
			if (self:hasCrossbowEffect(p) or getKnownCard(p, self.player, "Crossbow", false) > 0) and #choices > 1 then
				table.removeOne(choices, "yinbing")
			end
		end
	end
	if table.contains(choices, "yinbing")then
		if self.player:hasSkills(sgs.force_slash_skill) then
			return "yinbing"
		end
		for _, p in ipairs(targets) do
			if p:hasSkills(sgs.force_slash_skill) and #choices > 1 then
				table.removeOne(choices, "yinbing")
			end
		end
	end
	if table.contains(choices, "guizhu") then
		if self.player:hasSkills("jijiu|zhendu|xishe") then
			return "guizhu"
		end
		for _, p in ipairs(targets) do
			if p:hasSkills("jijiu|zhendu|xishe") and #choices > 1 then
				table.removeOne(choices, "guizhu")
			end
		end
	end
	if table.contains(choices, "yanzheng") then
		local yanzheng_card = sgs.ai_skill_exchange.yanzheng(self)
		if #yanzheng_card > 0 and not self:isWeak() then
			return "yanzheng"
		end
	end
	if table.contains(choices, "huoqi") then
		local min_hp = 99
		for _, p in sgs.qlist(self.room:getAlivePlayers()) do
			if p:getHp() < min_hp then
				min_hp = p:getHp()
			end
		end
		if self.player:getHp() == min_hp and self.player:isWounded() then
			return "huoqi"
		end
	end
	if table.contains(choices, "xianshou") and not self.player:isWounded() then
		return "xianshou"
	end
	if table.contains(choices, "lundao") and self.player:getHandcardNum() < 3 then
		return "lundao"
	end
	if table.contains(choices, "guanyue") then
		return "guanyue"
	end
	return choices[math.random(1, #choices)]
end

--雷击
sgs.ai_skill_playerchosen.leiji_tianshu = function(self, targets)
	self:updatePlayers()
	if not self:willShowForAttack() then return nil end
	local getCmpValue = function(enemy)
		local value = 0
		local damage = {}
		damage.to = enemy
		damage.from = self.player
		damage.nature = sgs.DamageStruct_Thunder
		damage.damage = 2
		if not self:damageIsEffective_(damage) then return 99 end
		if enemy:hasShownSkill("hongyan") then return 99 end
		if self:cantbeHurt(enemy, self.player, 2) or self:objectiveLevel(enemy) < 3
			or (enemy:isChained() and not self:isGoodChainTarget_(damage)) then return 100 end
		if not sgs.isGoodTarget(enemy, self.enemies, self) then value = value + 50 end
		if enemy:hasArmorEffect("SilverLion") then value = value + 20 end
		if enemy:hasShownSkills(sgs.exclusive_skill) then value = value + 10 end
		if enemy:hasShownSkills(sgs.masochism_skill) then value = value + 5 end
		if enemy:isChained() and self:isGoodChainTarget_(damage) and #(self:getChainedEnemies(self.player)) > 1 then value = value - 25 end
		if enemy:isLord() then value = value - 5 end
		value = value + enemy:getHp() + sgs.getDefenseSlash(enemy, self) * 0.01
		return value
	end

	local cmp = function(a, b)
		return getCmpValue(a) < getCmpValue(b)
	end

	local enemies = self.enemies
	table.sort(enemies, cmp)
	for _, enemy in ipairs(enemies) do
		if getCmpValue(enemy) < 100 then return enemy end
	end
end

function sgs.ai_slash_prohibit.leiji_tianshu(self, from, to, card)
	if self:isFriend(to, from) then return false end
	if not to:hasSkills(sgs.wizard_harm_skill) then return false end
	if from:hasShownSkills("tieqi|tieqi_xh") then return false end
	if from:hasShownSkill("jianchu") and (to:hasEquip() or to:getCardCount(true) == 1) then
		return false
	end
	if (to:getMark("#qianxi+no_suit_red") + to:getMark("#qianxi+no_suit_black") > 0) and (not self:hasEightDiagramEffect(to) or IgnoreArmor(from, to)) then
		return false
	end
	local hcard = to:getHandcardNum()
	if from:hasShownSkill("liegong") and (hcard >= from:getHp() or hcard <= from:getAttackRange()) then return false end
	if (from:getHp() >= 4 and (getCardsNum("Peach", from, to) > 0 or from:hasShownSkill("ganglie"))) or from:hasShownSkill("hongyan") and #self.friends == 1 then
		return false
	end
	if sgs.card_lack[to:objectName()]["Jink"] == 2 then return true end
	if getKnownCard(to, Global_room:getCurrent(), "Jink", true) >= 1 or (self:hasSuit("spade", true, to) and hcard >= 2) or hcard >= 4 then return true end
	if self:hasEightDiagramEffect(to) then return true end
end

--阴兵
sgs.ai_skill_invoke.yinbing = true

function sgs.ai_cardneed.yinbing(to, card, self)
	return card:isKindOf("Axe") or (self:hasCrossbowEffect(to) and isCard("Slash", card, to))
end

--活气
local huoqi_skill = {}
huoqi_skill.name = "huoqi"
table.insert(sgs.ai_skills, huoqi_skill)
huoqi_skill.getTurnUseCard = function(self)
	if self.player:isKongcheng() or self.player:hasUsed("HuoqiCard") then return end
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards, true)
	local card_str = ("@HuoqiCard=%d&huoqi"):format(cards[1]:getId())
	return sgs.Card_Parse(card_str)
end

sgs.ai_skill_use_func.HuoqiCard = function(card, use, self)
	local target = nil
	local min_hp = 99
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if p:getHp() < min_hp then
			min_hp = p:getHp()
		end
	end
	for _, friend in ipairs(self.friends) do
		if self.player:isFriendWith(friend) and friend:getHp() == min_hp and friend:isWounded() then
			target = friend
		end
	end
	if not target then
		for _, friend in ipairs(self.friends) do
			if self:isFriend(friend) and friend:getHp() == min_hp and friend:isWounded() then
				target = friend
			end
		end
	end
	if target then
		use.card = card
		if use.to then
			use.to:append(target)
		end
	end
end

sgs.ai_use_priority.HuoqiCard = 4.2
sgs.ai_card_intention.HuoqiCard = -100

--鬼助
sgs.ai_skill_invoke.guizhu = true

--仙授
local xianshou_skill = {}
xianshou_skill.name = "xianshou"
table.insert(sgs.ai_skills, xianshou_skill)
xianshou_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("XianshouCard") then return end
	return sgs.Card_Parse("@XianshouCard=.&xianshou")
end

sgs.ai_skill_use_func.XianshouCard = function(card, use, self)
	local target
	self:sort(self.friends, "handcard")
	for _, p in ipairs(self.friends) do
		if self.player:isFriendWith(p) and not p:isWounded() then
			target = p
		end
	end
	if not target then
		for _, p in ipairs(self.friends) do
			if self:isFriend(p) and not p:isWounded() then
				target = p
			end
		end
	end
	if not target then
		target = self.friends[1]
	end
	if target then
		use.card = card
		if use.to then
			use.to:append(target)
		end
	end
end

sgs.ai_card_intention.XianshouCard = -20
sgs.ai_use_priority.XianshouCard = 5

--论道
sgs.ai_skill_invoke.lundao =  function(self, data)
	local target = data:toPlayer()
	if target and self:isFriend(target) and target:getHandcardNum() > self.player:getHandcardNum() and not self:needToThrowArmor(target) then
	  return false
	end
	return true
end

--观月
sgs.ai_skill_invoke.guanyue = true

--[[默认ai是sortByCardNeed，和使用值相关，是否用保留值？
sgs.ai_skill_askforag.guanyue = function(self, card_ids)
	local cards = {}
	for _, id in ipairs(card_ids) do
		table.insert(cards, sgs.Sanguosha:getCard(id))
	end
	self:sortByKeepValue(cards)
	return cards[1]:getEffectiveId()
end
]]

--言政
sgs.ai_skill_exchange.yanzheng = function(self,pattern,max_num,min_num,expand_pile)
	if self.player:isKongcheng() then
		return {}
	end
	local can_yanzheng = false
	local valuable_num = 0
	local enemy_weak = 0
	local discard_num = self.player:getHandcardNum() - 1
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards)
	for _, card in ipairs(cards) do
		if (isCard("BefriendAttacking", card, self.player) or isCard("ExNihilo", card, self.player) or isCard("ThreatenEmperor", card, self.player))
		and card:isAvailable(self.player) then
			valuable_num = valuable_num + 1
		end
		if self:hasCrossbowEffect() and isCard("Slash", card, self.player) then
			valuable_num = valuable_num + 1
		end
	end
	for _, card in ipairs(cards) do
		if (isCard("AllianceFeast", card, self.player) or isCard("Peach", card, self.player)) and card:isAvailable(self.player) then
			valuable_num = valuable_num + 1
			if self:isWeak() and valuable_num > 1 then
				valuable_num = valuable_num + 1
			end
		end
	end
	if #self.enemies > 0 then
		for _, p in ipairs(self.enemies) do
			if p:getHp() == 1 and self:isWeak(p) then
				enemy_weak = enemy_weak + 1
			end
		end
		if self.player:hasSkill("lirang") or (valuable_num < 2) or (valuable_num < 3 and enemy_weak > 0)
		and (discard_num <= #self.enemies + 2 or (discard_num >= enemy_weak and enemy_weak > 1)) then
			can_yanzheng = true
		end
	end
	if can_yanzheng then
		return {cards[1]:getEffectiveId()}--使用值最大的一张，table形式方便调用
	end
	return {}
end

sgs.ai_skill_playerchosen.yanzheng_damage = function(self, targets, max_num, min_num)
	local result = {}
	local targetlist = sgs.QList2Table(targets)
	self:sort(targetlist, "hp")
	for _, target in ipairs(targetlist) do
		if self:isEnemy(target) and #result < max_num then
			table.insert(result, target)
			table.removeOne(targetlist, target)--防止重复
		end
	end
	for _, target in ipairs(targetlist) do
		if not self:isFriend(target) and #result < max_num then
			table.insert(result, target)
			table.removeOne(targetlist, target)
		end
	end
	return result
end

function sgs.ai_cardneed.yanzheng(to, card, self)
	return to:getHandcardNum() < 2
end