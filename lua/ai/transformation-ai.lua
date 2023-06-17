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

---荀攸
local qice_skill = {}
qice_skill.name = "qice"
table.insert(sgs.ai_skills, qice_skill)
qice_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("QiceCard") or self.player:isKongcheng() then return end
	local handcardnum = self.player:getHandcardNum()
	self.qicenum = {}
	self.qice_to = nil

	local cardsavailable = function(use_card, hcardnum)--增加手牌数方便判断吃桃
		local target_num = 0
		if use_card:isKindOf("AllianceFeast") then
			for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
				if not p:isRemoved() and not self.player:isProhibited(p, use_card) and p:getRole() == "careerist" then
					return 2 <= hcardnum
				end
			end
			local kingdoms = {wei = 0,shu = 0,wu = 0,qun = 0}
			local kingdoms_num = {}
			for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do--计算人数最少的势力
				if not p:isRemoved() and not self.player:isProhibited(p, use_card) and p:hasShownOneGeneral()--非暗将
				and (self.player:getRole() == "careerist" or self.player:getKingdom() ~= p:getKingdom()) then
					kingdoms[p:getKingdom()] = kingdoms[p:getKingdom()] + 1
				end
			end
			for key, value in pairs(kingdoms) do
				--Global_room:writeToConsole("奇策联军国家:"..key.."|"..value)
				if key and value > 0 then
					table.insert(kingdoms_num,value)--移除没有的国别
				end
			end
			if #kingdoms_num > 0 then
				target_num = 1 + math.min(table.unpack(kingdoms_num))
				Global_room:writeToConsole("奇策联军最小目标数:".. target_num)
			end
			return false
		elseif use_card:isKindOf("AwaitExhausted") then
			for _, p in sgs.qlist(self.room:getAlivePlayers()) do
				if not p:isRemoved() and not self.player:isProhibited(p, use_card)
				and self.player:hasShownOneGeneral() and self.player:getRole() ~= "careerist"
				and p:getRole() ~= "careerist" and p:hasShownOneGeneral() and p:getKingdom() == self.player:getKingdom() then
					target_num = target_num + 1
				end
			end
		elseif use_card:getSubtype() == "global_effect" and not use_card:isKindOf("FightTogether") then
			for _, p in sgs.qlist(self.room:getAlivePlayers()) do
				if not p:isRemoved() and not self.player:isProhibited(p, use_card) then
					target_num = target_num + 1
				end
			end
		elseif use_card:getSubtype() == "aoe" and not use_card:isKindOf("BurningCamps") then
			for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
				if not p:isRemoved() and not self.player:isProhibited(p, use_card) then
					target_num = target_num + 1
				end
			end
		elseif use_card:isKindOf("BurningCamps") then
			local np = self.player:getNextAlive()
			if not self.player:isFriendWith(np) then--下家不是队友
				local players = np:getFormation()
				for _, p in sgs.qlist(players) do
					if not p:isRemoved() and not self.player:isProhibited(p, use_card) then
						target_num = target_num + 1
					end
				end
			end
		else--戮力同心暂不考虑
			target_num = 1
		end
		self.qicenum[use_card:objectName()] = target_num
		return target_num <= hcardnum
	end

--[[{联军盛宴,火烧连营,桃园结义,南蛮入侵,万箭齐发,
	远交近攻,无中生有,决斗,顺手牵羊,过河拆桥,水淹七军,
	铁索连环,以逸待劳,五谷丰登,勠力同心,调虎离山,敕令,
	借刀杀人,知己知彼,火攻,挟天子以令诸侯}
]]--按锦囊价值排序
	local trickcards = {"alliance_feast","burning_camps","god_salvation","savage_assault","archery_attack",--群体锦囊
	"befriend_attacking","ex_nihilo","duel","snatch","dismantlement","drowning",--单体锦囊
	"iron_chain","await_exhausted","amazing_grace","fight_together","lure_tiger","imperial_order",--几乎不会用到的群体锦囊
	"collateral","known_both","fire_attack","threaten_emperor"}--几乎不会用到的单体锦囊
	local available_tricks = {}
	for _,cardname in ipairs(trickcards) do
		local use_card = sgs.cloneCard(cardname)
		if cardsavailable(use_card,handcardnum) then
			table.insert(available_tricks, cardname)
		end
	end

	local has_peach = false
	local usevalue = 0
	local keepvalue = 0
	local id
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	for _,card in ipairs(cards) do
		if card:canRecast() then return end
		if isCard("Peach", card, self.player) then--有实体卡桃可回血
			has_peach = true
		end
		if card:isKindOf("ThreatenEmperor") and self.player:isBigKingdomPlayer() then--手牌多可以aoe的时候？
			return
		end
		if card:isAvailable(self.player) then
			if card:isKindOf("EquipCard") and not self:getSameEquip(card) and handcardnum > 1 then
				local use = sgs.CardUseStruct(card, self.player, self.player, true)
				self:useEquipCard(card, use)
			end
			usevalue = self:getUseValue(card) + usevalue
		end
		if not id then
			id = tostring(card:getId())
		else
			id = id .. "+" .. tostring(card:getId())
		end
	end
	self:sortByKeepValue(cards)
	for i = 1, #cards, 1 do
		if i > self:getOverflow(self.player) then
			keepvalue = self:getKeepValue(cards[i]) + keepvalue
		end
	end
	local str = "@QiceCard=" .. id .. ":"
	sgs.ai_use_priority.QiceCard = 0.05--一般在最后，考虑有挟天子的情况？
	if handcardnum == 1 then
		sgs.ai_use_priority.QiceCard = 3
	end

--策略优化？远交近攻、无中生有摸牌，鏖战或虚弱时联军盛宴和桃园回血，AOE，残血决斗，队列或鏖战火烧，敌方残血多装备水淹
--拆顺乐、装备？暂未考虑，如何能帮队友拆顺、乐？选择目标？
--还需要设置优先度
	if self.player:getMark("GlobalBattleRoyalMode") > 0 and self.player:isWounded() then--鏖战不管怎么样先回复
		local enemy_wounded = false
		local known_null = false
		for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			if not p:isRemoved() and p:isWounded() then
				enemy_wounded = true
			end
			if not p:isRemoved() and not self:isFriend(p) and getCardsNum("Nullification", p, self.player) > 0 then
				known_null = true
			end
		end
		if table.contains(available_tricks,"god_salvation") and not enemy_wounded and not known_null then
			if self.qicenum["god_salvation"] and self.qicenum["god_salvation"] == handcardnum then
				sgs.ai_use_priority.QiceCard = 3
			end
			Global_room:writeToConsole("奇策鏖战桃园")
			return sgs.Card_Parse(str .. "god_salvation")
		end
		if table.contains(available_tricks,"alliance_feast") and not known_null then
			local dummyuse = { isDummy = true, to = sgs.SPlayerList() }
			self:useCardAllianceFeast(sgs.cloneCard("alliance_feast"), dummyuse)
			if dummyuse.card then
				if self.qicenum["alliance_feast"] and self.qicenum["alliance_feast"] == handcardnum then
					sgs.ai_use_priority.QiceCard = 8
				end
				Global_room:writeToConsole("奇策鏖战联军")
				return sgs.Card_Parse(str .. "alliance_feast")
			end
		end
	end

	if not has_peach and table.contains(available_tricks,"god_salvation") then--桃园
		local cloneg = sgs.cloneCard("god_salvation")
		if self:willUseGodSalvation(cloneg) then
			if self.qicenum["god_salvation"] and self.qicenum["god_salvation"] == handcardnum then
				sgs.ai_use_priority.QiceCard = 3--调虎离山是4.9
			end
			Global_room:writeToConsole("奇策桃园")
			return sgs.Card_Parse(str .. "god_salvation")
		end
	end

	if not has_peach and table.contains(available_tricks,"alliance_feast") and self.player:getLostHp() > 1 then-- 联军
		local dummyuse = { isDummy = true, to = sgs.SPlayerList() }
		self:useCardAllianceFeast(sgs.cloneCard("alliance_feast"), dummyuse)
		if dummyuse.card then
			if self.qicenum["alliance_feast"] and self.qicenum["alliance_feast"] == handcardnum and self:getAllPeachNum() < 1 then
				sgs.ai_use_priority.QiceCard = 8--优先度是否合适？
			end
			Global_room:writeToConsole("奇策联军")
			return sgs.Card_Parse(str .. "alliance_feast")
		end
	end

	if not has_peach and table.contains(available_tricks,"burning_camps") then
		local np = self.player:getNextAlive()--鏖战等情况
		local can_burn = self:isEnemy(np) and np:getFormation():length() == #self.enemies
		local dummyuse = { isDummy = true, to = sgs.SPlayerList() }
		self:useCardBurningCamps(sgs.cloneCard("burning_camps"), dummyuse)
		if dummyuse.card and can_burn then
			if self.qicenum["burning_camps"] and self.qicenum["burning_camps"] == handcardnum then
				sgs.ai_use_priority.QiceCard = 1.5
			end
			Global_room:writeToConsole("奇策火烧1")
			return sgs.Card_Parse(str .. "burning_camps")
		end
	end

	if (table.contains(available_tricks,"archery_attack") or table.contains(available_tricks,"savage_assault")) then--万剑、南蛮
		local clonea = sgs.cloneCard("archery_attack")
		local clones = sgs.cloneCard("savage_assault")
		local zhurong = sgs.findPlayerByShownSkillName("juxiang")--小心祝融拿牌
		local caocao = sgs.findPlayerByShownSkillName("jianxiong")
		local mengda = sgs.findPlayerByShownSkillName("qiuan")
		--[[
		local caocaoAOE, mengdaAOE = false,false
		local zhurongSA = false
		if caocao and self:isFriend(caocao) and not self.player:hasSkill("jianxiong")
		and (caocao:getHp() > 1 or getCardsNum("Peach", caocao, self.player) > 0)
		and not self:willSkipPlayPhase(caocao) then
			caocaoAOE = true
		end
		if mengda and self:isFriend(mengda) and mengda:getPile("letter"):isEmpty() and not self.player:hasSkill("qiuan")
		and (mengda:getHp() > 1 or getCardsNum("Peach", mengda, self.player) > 0)
		and not self:willSkipPlayPhase(mengda) then
			mengdaAOE = true
		end
		if zhurong and self:isFriend(zhurong) and not self:willSkipPlayPhase(zhurong) then
			zhurongSA = true
		end
		if caocaoAOE or mengdaAOE then
			if self:trickIsEffective(use_card,caocao)) and self:getAoeValue(use_card) > -5 then--负5来自身份，是否合适？

			end
		end]]
		if not has_peach and self:getAoeValue(clonea) > 0
		and (not caocao or self:isFriend(caocao))
		and (not mengda or self:isFriend(mengda)) then
			if self.qicenum["archery_attack"] and self.qicenum["archery_attack"] == handcardnum then
				sgs.ai_use_priority.QiceCard = 1.5
			end
			Global_room:writeToConsole("奇策万箭")
			return sgs.Card_Parse(str .. "archery_attack")
		end
		if not has_peach and self:getAoeValue(clones) > 0
		and (not caocao or self:isFriend(caocao))
		and (not mengda or self:isFriend(mengda))
		and (not zhurong or self:isFriend(zhurong)) then
			if self.qicenum["savage_assault"] and self.qicenum["savage_assault"] == handcardnum then
				sgs.ai_use_priority.QiceCard = 1.5
			end
			Global_room:writeToConsole("奇策南蛮")
			return sgs.Card_Parse(str .. "savage_assault")
		end
	end

	if not has_peach and table.contains(available_tricks,"burning_camps") then
		local can_burn = false
		local burn_weak = 0
		local players = self.player:getNextAlive():getFormation()
		for _, p in sgs.qlist(players) do
			if p:getHp() == 1 and self:trickIsEffective(sgs.cloneCard("burning_camps"), p, self.player) then
				can_burn = true
				break
			end
			if self:isWeak(p) and self:trickIsEffective(sgs.cloneCard("burning_camps"), p, self.player) then
				burn_weak = burn_weak + 1
			end
		end
		if burn_weak > 1 or burn_weak == #self.enemies then
			can_burn = true
		end
		local dummyuse = { isDummy = true, to = sgs.SPlayerList() }
		self:useCardBurningCamps(sgs.cloneCard("burning_camps"), dummyuse)
		if dummyuse.card and can_burn then
			if self.qicenum["burning_camps"] and self.qicenum["burning_camps"] == handcardnum then
				sgs.ai_use_priority.QiceCard = 1.5
			end
			Global_room:writeToConsole("奇策火烧2")
			return sgs.Card_Parse(str .. "burning_camps")
		end
	end

	if not has_peach and table.contains(available_tricks,"duel") then
		local dummyuse = { isDummy = true, to = sgs.SPlayerList() }
		self:useCardDuel(sgs.cloneCard("duel"), dummyuse)
		if not dummyuse.to:isEmpty() then
			local enemy = dummyuse.to:first()
			if enemy:getHp() == 1 and enemy:getHandcardNum() < 2 and getCardsNum("Slash", enemy, self.player) < 1 then
				Global_room:writeToConsole("奇策决斗")
				return sgs.Card_Parse(str .. "duel")
			end
		end
	end

	if not has_peach and table.contains(available_tricks,"drowning") and self.player:getHp() > 1 then
		local dummyuse = { isDummy = true, to = sgs.SPlayerList() }
		self:useCardDrowning(sgs.cloneCard("drowning"), dummyuse)
		if not dummyuse.to:isEmpty() then
			local enemy = dummyuse.to:first()
			if (self:isWeak(enemy) or (enemy:getHp() == 1 and not enemy:hasArmorEffect("Breastplate")))
			and enemy:getEquips():length() > 3 and not enemy:hasArmorEffect("PeaceSpell") then
				Global_room:writeToConsole("奇策水淹七军")
				return sgs.Card_Parse(str .. "drowning")
			end
		end
	end

	if not has_peach and table.contains(available_tricks,"befriend_attacking") and (usevalue < 6 or handcardnum < 3) then-- 联军
		local dummyuse = { isDummy = true, to = sgs.SPlayerList() }
		self:useCardBefriendAttacking(sgs.cloneCard("befriend_attacking"), dummyuse)
		if dummyuse.card then
			Global_room:writeToConsole("奇策远交近攻")
			return sgs.Card_Parse(str .. "befriend_attacking")
		end
	end


--[[
	local useall
	for _, enemy in ipairs(self.enemies) do--有重要牌时可参考袁绍，目前暂不考虑
		if enemy:getHp() == 1 and not enemy:hasArmorEffect("Vine") and not self:hasEightDiagramEffect(enemy) and self:damageIsEffective(enemy, nil, self.player)
			and self:isWeak(enemy) and getCardsNum("Jink", enemy, self.player) + getCardsNum("Peach", enemy, self.player) + getCardsNum("Analeptic", enemy, self.player) == 0 then
			useall = true
		end
	end


	local value = 0
	local qice_trick
	for _, trick in ipairs(available_tricks) do
		local clonetrick = sgs.cloneCard(trick)
		if self:getUseValue(clonetrick) > value and self:getUseValue(clonetrick) > keepvalue and self:getUseValue(clonetrick) > usevalue and (usevalue < 6 or handcardnum == 1) then
			value = self:getUseValue(clonetrick)
			qice_trick = trick
		end
	end
	if qice_trick then
		assert(sgs.Card_Parse(str .. qice_trick))
		local dummyuse = { isDummy = true, to = sgs.SPlayerList() }
		self:useTrickCard(sgs.cloneCard(qice_trick), dummyuse)--useTrickCard通用。。
		if dummyuse.card then--解决不了ai用挟天子bug，建议去掉挟天子
			Global_room:writeToConsole("奇策一般选择")
			return sgs.Card_Parse(str .. qice_trick)
		end
	end
]]
end

--参考的身份
sgs.ai_skill_use_func.QiceCard = function(card, use, self)
	local userstring = card:toString()
	userstring = (userstring:split(":"))[3]
	local qicecard = sgs.cloneCard(userstring, card:getSuit(), card:getNumber())
	if self.player:isCardLimited(qicecard, sgs.Card_MethodUse) then
        return
    end
	self:useCardByClassName(qicecard, use)--确保锦囊能使用
	if use.card then
		Global_room:writeToConsole("奇策卡使用")
		use.card = card
	end
end

--[[旧奇策ai
	local parsed_card = {}
	if cardsavailable(sgs.Card_Parse("amazing_grace:qice[to_be_decided:0]=" .. id .."&qice")) then
		table.insert(parsed_card, sgs.Card_Parse("amazing_grace:qice[to_be_decided:0]=" .. id .."&qice"))		--五谷
	end
	if cardsavailable(sgs.Card_Parse("god_salvation:qice[to_be_decided:0]=" .. id .."&qice")) then
		table.insert(parsed_card, sgs.Card_Parse("god_salvation:qice[to_be_decided:0]=" .. id .."&qice"))		--桃园
	end
	if cardsavailable(sgs.Card_Parse("burning_camps:qice[to_be_decided:0]=" .. id .."&qice")) then
		table.insert(parsed_card, sgs.Card_Parse("burning_camps:qice[to_be_decided:0]=" .. id .."&qice"))		--火烧连营
	end
	if cardsavailable(sgs.Card_Parse("drowning:qice[to_be_decided:0]=" .. id .."&qice")) then
		table.insert(parsed_card, sgs.Card_Parse("drowning:qice[to_be_decided:0]=" .. id .."&qice"))				--水淹七军
	end
	if cardsavailable(sgs.Card_Parse("threaten_emperor:qice[to_be_decided:0]=" .. id .."&qice")) then
		table.insert(parsed_card, sgs.Card_Parse("threaten_emperor:qice[to_be_decided:0]=" .. id .."&qice"))		--挟天子以令诸侯
	end
	if cardsavailable(sgs.Card_Parse("await_exhausted:qice[to_be_decided:0]=" .. id .."&qice")) then
		table.insert(parsed_card, sgs.Card_Parse("await_exhausted:qice[to_be_decided:0]=" .. id .."&qice"))			--以逸待劳
	end
	if cardsavailable(sgs.Card_Parse("befriend_attacking:qice[to_be_decided:0]=" .. id .."&qice")) then
		table.insert(parsed_card, sgs.Card_Parse("befriend_attacking:qice[to_be_decided:0]=" .. id .."&qice"))		--远交近攻
	end
	if cardsavailable(sgs.Card_Parse("duel:qice[to_be_decided:0]=" .. id .."&qice")) then
		table.insert(parsed_card, sgs.Card_Parse("duel:qice[to_be_decided:0]=" .. id .."&qice"))				--决斗
	end
	if cardsavailable(sgs.Card_Parse("dismantlement:qice[to_be_decided:0]=" .. id .."&qice")) then
		table.insert(parsed_card, sgs.Card_Parse("dismantlement:qice[to_be_decided:0]=" .. id .."&qice"))		--过河拆桥
	end
	if cardsavailable(sgs.Card_Parse("snatch:qice[to_be_decided:0]=" .. id .."&qice")) then
		table.insert(parsed_card, sgs.Card_Parse("snatch:qice[to_be_decided:0]=" .. id .."&qice"))				--顺手牵羊
	end
	if cardsavailable(sgs.Card_Parse("ex_nihilo:qice[to_be_decided:0]=" .. id .."&qice")) then
		table.insert(parsed_card, sgs.Card_Parse("ex_nihilo:qice[to_be_decided:0]=" .. id .."&qice"))			--无中生有
	end
	if not preventdamage or not self:trickIsEffective(sgs.Card_Parse("archery_attack:qice[to_be_decided:0]=" .. id .."&qice"), caocao)
		and cardsavailable(sgs.Card_Parse("archery_attack:qice[to_be_decided:0]=" .. id .."&qice")) then
		table.insert(parsed_card, sgs.Card_Parse("archery_attack:qice[to_be_decided:0]=" .. id .."&qice"))	--万箭齐发
	end
	if not preventdamage or not self:trickIsEffective(sgs.Card_Parse("savage_assault:qice[to_be_decided:0]=" .. id .."&qice"), caocao) and
		cardsavailable(sgs.Card_Parse("savage_assault:qice[to_be_decided:0]=" .. id .."&qice")) then
		table.insert(parsed_card, sgs.Card_Parse("savage_assault:qice[to_be_decided:0]=" .. id .."&qice"))	--南蛮
	end
]]


sgs.ai_skill_choice["transform_qice"] = function(self, choices)
	Global_room:writeToConsole("奇策变更选择")
	local importantsklii = {"yiji", "guicai", "fangzhu", "luoshen", "jieming", "jieyue", "shicai", "wanggui", "sidi"}--还有哪些？
	local skills = sgs.QList2Table(self.player:getDeputySkillList(true,true,false))
	for _, skill in ipairs(skills) do
		if table.contains(importantsklii, skill:objectName()) then--重要技能
			return "no"
		end
		if skill:objectName() == "qice" and not (self.player:getActualGeneral1():getKingdom() == "careerist" and self:isWeak()) then--换自己
			return "no"
		end
		if skill:getFrequency() == sgs.Skill_Limited and not (skill:getLimitMark() ~= "" and self.player:getMark(skill:getLimitMark()) == 0) then--限定技未发动
			return "no"
		end
	end
	local g2name = self.player:getActualGeneral2Name()
	if g2name:match("sujiang") or (sgs.general_value[g2name] and sgs.general_value[g2name] < 7) then
		return "yes"
	end
	choices = choices:split("+")
	return choices[math.random(1,#choices)]
end

sgs.ai_skill_invoke.zhiyu = function(self, data)
	if not self:willShowForMasochism() then return false end
	local damage = data:toDamage()
	local from = damage.from
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	local first
	local difcolor = false
	for _, card in ipairs(cards)  do
		if not first then first = card end
		if (first:isRed() and card:isBlack()) or (card:isRed() and first:isBlack()) then
			difcolor = true
			break
		end
	end
	if not difcolor and from then
		if self:isFriend(from) and not from:isKongcheng() then
			return false
		elseif not self:isFriend(from) then
			if self:doNotDiscard(from, "h") and not from:isKongcheng() then return false end
			return true
		end
	end
	return true
end

--卞皇后
--[[旧ai
sgs.ai_skill_invoke.wanwei = function(self, data)
	if not self:willShowForDefence() then return false end
	local move = data:toMoveOneTime()
	local target = move.to
	if self:isFriend(target) then return false end
	self.wanwei = {}
	local cards = sgs.QList2Table(self.player:getCards("e"))
	local hcards = sgs.QList2Table(self.player:getHandcards())
	table.insertTable(cards, hcards)
	self:sortByUseValue(cards)
	for i = 1, move.card_ids:length(), 1 do
		table.insert(self.wanwei, card[i]:getEffectiveId())
	end
	return true
end

sgs.ai_skill_exchange.wanwei = function(self)
	if not self:willShowForDefence() then return {} end
	local target = self.player:getTag("wanwei"):toPlayer()
	if not self:isFriend(target) then
		return self:askForDiscard("dummy_reason", 1, 1, false, true)
	else
		if self:isWeak(target) and not self:isWeak() and self:getCardsNum("Peach") > 0 then
			for _, c in sgs.qlist(self.player:getHandcards()) do
				if c:isKindOf("Peach") then return { c:getEffectiveId() } end
			end
		end
	end
	return {}
end

sgs.ai_skill_discard.wanwei = function(self)
	if not self:willShowForDefence() then return {} end
	return self:askForDiscard("dummy_reason", 1, 1, false, true)
end
--]]

sgs.ai_skill_invoke.wanwei = true

sgs.ai_skill_exchange["_wanwei"] = function(self,pattern,max_num,min_num,expand_pile)
	local result = {}
	local cards = self.player:getCards("he")
	cards=sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	for _, c in ipairs(cards) do
		table.insert(result, c:getId())
		if #result == max_num then
			return result
		end
	end
	return result
end

sgs.ai_skill_invoke.yuejian = function(self, data)
	local target = self.room:getCurrent()
	if target:getHandcardNum() > target:getMaxCards() and target:isWounded() then return true end
	return false
end

--李傕＆郭汜
local xiongsuan_skill = {}
xiongsuan_skill.name = "xiongsuan"
table.insert(sgs.ai_skills, xiongsuan_skill)
xiongsuan_skill.getTurnUseCard = function(self)
	--Global_room:writeToConsole("进入凶算")
	--不考虑自杀了
	if self.player:getMark("@fierce") < 1 or not self.player:canDiscard(self.player, "h") then return end
	if self.player:getMark("Global_TurnCount") < 2 and not self.player:hasShownOneGeneral() then return end
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards, true)
	for _, acard in ipairs(cards) do
		if not self:isValuableCard(acard) then
			return sgs.Card_Parse("@XiongsuanCard=".. acard:getEffectiveId() .."&xiongsuan")
		end
	end
end

sgs.ai_skill_use_func.XiongsuanCard = function(card, use, self)
	--Global_room:writeToConsole("使用凶算")
	local target
	for _, friend in ipairs(self.friends) do
		if self:isFriendWith(friend) and friend:hasSkill("xiongyi") and friend:getMark("@arise") < 1 and friend:getHp() > 1 then
			self.xiongsuan_skill = "xiongyi"
			target = friend
			break
		end
	end
	for _, friend in ipairs(self.friends) do--复制的乱舞触发条件
		if self:isFriendWith(friend) and friend:hasSkill("luanwu") and friend:getMark("@chaos") < 1 and friend:getHp() > 1 then
			local good, bad = 0, 0
			local alive = self.room:alivePlayerCount()
			if good < alive/4 then break end

			for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
				if player:isRemoved() then
					continue
				end
				local hp = math.max(player:getHp(), 1)
				if getCardsNum("Analeptic", player, self.player) > 0 then
					if self:isFriend(player) then good = good + 1.0 / hp
					else bad = bad + 1.0 / hp
					end
				end

				local has_slash = (getCardsNum("Slash", player, self.player) > 0)
				local can_slash = false
				if not can_slash then
					for _, p in sgs.qlist(self.room:getOtherPlayers(player)) do
						if player:distanceTo(p) <= player:getAttackRange() then can_slash = true break end
					end
				end
				if not has_slash or not can_slash then
					if self:isFriend(player) then good = good + math.max(getCardsNum("Peach", player, self.player), 1)
					else bad = bad + math.max(getCardsNum("Peach", player, self.player), 1)
					end
				end

				if getCardsNum("Jink", player, self.player) == 0 then
					local lost_value = 0
					if player:hasShownSkills(sgs.masochism_skill) then lost_value = player:getHp() / 2 end
					if self:isFriend(player) then bad = bad + (lost_value + 1) / hp
					else good = good + (lost_value + 1) / hp
					end
				end
			end
			if good > bad and not target then
				self.xiongsuan_skill = "luanwu"
				target = friend
				break
			end
		end
	end
	if not target then--大部分参考苦肉，暂未考虑给无限定技的队友
		local can_xiongsuan = false
		if (self.player:getHp() > 3 and self:getOverflow(self.player, false) < 2)
		or (self.player:getHp() > 2 and self:getOverflow(self.player, false) < -1)
		or (self.player:getHp() == 1 and self:getCardsNum("Analeptic") >= 1) then
			can_xiongsuan = true
		end
		local slash = sgs.cloneCard("slash")
		if self:hasCrossbowEffect(self.player) and self.player:getHp() > 1 then
			for _, enemy in ipairs(self.enemies) do
				if enemy:hasShownOneGeneral() then
					if self.player:canSlash(enemy, nil, true) and self:slashIsEffective(slash, enemy)
						and not (enemy:hasShownSkill("kongcheng") and enemy:isKongcheng())
						and not (enemy:hasShownSkills("fankui") and self.player:hasWeapon("Crossbow"))
						and sgs.isGoodTarget(enemy, self.enemies, self) and not self:slashProhibit(slash, enemy) then
							can_xiongsuan = true
					end
				end
			end
		end
		if self.player:getHp() > 1 and
			((self.player:hasSkill("luanji") and self:getAoeValue(sgs.cloneCard("archery_attack")) > 0)
			or (self.player:hasSkill("shuangxiong") and self.player:hasFlag("shuangxiong"))) then--攻击技能
			can_xiongsuan = true
		end
		if self.player:hasSkills("qianhuan|jihun|bushi|chenglve") and self:getCardsNum("Peach") >= 1 then--卖血技能
			can_xiongsuan = true
		end
		if self.player:hasSkill("congjian") then
			can_xiongsuan = false
		end
		if self.player:hasSkill("yuanyu") then
			can_xiongsuan = true
		end
		if can_xiongsuan then
			self.xiongsuan_skill = "xiongsuan"
			target = self.player
		end
	end
	if target then
		use.card = card
		if use.to then
			use.to:append(target)
			--Global_room:writeToConsole("使用凶算目标:"..target:objectName().." 技能:"..self.xiongsuan_skill)
		end
	end
end

sgs.ai_skill_choice.xiongsuan = function(self, choices, data)
	return self.xiongsuan_skill
end

sgs.ai_card_intention.XiongsuanCard = -40
sgs.ai_use_priority.XiongsuanCard = 6.8--复制的苦肉优先度

--左慈
---[[旧技能
sgs.ai_skill_invoke.huashen = function(self, data)
	local huashens = self.player:getTag("Huashens"):toList()
	if huashens:length() < 2 then return true end
	local names = {}
	for _, q in sgs.qlist(huashens) do
		table.insert(names, q:toString())
	end
	g1 = sgs.Sanguosha:getGeneral(names[1])
	g2 = sgs.Sanguosha:getGeneral(names[2])
	return self:getHuashenPairValue(g1, g2) < 6
end

sgs.ai_skill_invoke["xinsheng"] = function(self, data)
	return true
end
--]]
sgs.ai_skill_choice.huashen = function(self, choice, data)
	local head = self.player:inHeadSkills("huashen") or self.player:inHeadSkills("xinsheng")
	local names = choice:split("+")
	local max_point = 0
	local pair = ""

	for _, name1 in ipairs(names) do
		local g1 = sgs.Sanguosha:getGeneral(name1)
		if not g1 then continue end
		--[[
		for _, skill in sgs.qlist(g1:getVisibleSkillList(true, head)) do
			if skill:getFrequency() == sgs.Skill_Limited and skill:getLimitMark() ~= "" and self.player:getMark(skill:getLimitMark()) == 0 and self.player:hasSkill(skill:objectName()) then
				ajust1 = ajust1 - 1
			end
		end
		--]]
		for _, name2 in ipairs(names) do
			local g2 = sgs.Sanguosha:getGeneral(name2)
			if not g2 or g1:getKingdom() ~= g2:getKingdom() or name1 == name2 then continue end
			local points = self:getHuashenPairValue(g1, g2)
			max_point = math.max(max_point, points)
			if max_point == points then pair = name1 .. "+" .. name2 end
		end
	end
	self.player:speak("结果是：" .. pair)
	return pair
end

function SmartAI:getHuashenPairValue(g1, g2)
	local player= self.player
	local current_value = 0
	for name, value in pairs(sgs.general_pair_value) do
		if g1:objectName() .. "+" .. g2:objectName() == name or g2:objectName() .. "+" .. g1:objectName() == name then
			current_value = value
			break
		end
	end
	local oringin_g1 = 3
	local oringin_g2 = 3
	for name, value in pairs(sgs.general_value) do
		if g1:objectName() == name then oringin_g1 = value end
		if g2:objectName() == name then oringin_g2 = value end
	end

	if current_value == 0 then
		local oringin_g1 = 3
		local oringin_g2 = 3
		for name, value in pairs(sgs.general_value) do
			if g1:objectName() == name then oringin_g1 = value end
			if g2:objectName() == name then oringin_g2 = value end
		end
		current_value = oringin_g1 + oringin_g2
	end

	local skills = {}
	for _, skill in sgs.qlist(g1:getVisibleSkillList(true, player:inHeadSkills("huashen"))) do
		table.insert(skills, skill:objectName())
		if skill:getFrequency() == sgs.Skill_Limited and skill:getLimitMark() ~= "" and player:getMark(skill:getLimitMark()) == 0 then
			current_value = current_value - 1
		end
	end
	for _, skill in sgs.qlist(g2:getVisibleSkillList(true, player:inHeadSkills("huashen"))) do
		table.insert(skills, skill:objectName())
		if skill:getFrequency() == sgs.Skill_Limited and skill:getLimitMark() ~= "" and player:getMark(skill:getLimitMark()) == 0 then
			current_value = current_value - 1
		end
	end

	if g1:isCompanionWith(g2:objectName()) and player:getMark("CompanionEffect") == 0 then
		current_value = current_value - 0.5
	end

	for _, skill in ipairs(skills) do
		if sgs.cardneed_skill:match(skill) then
			if player:getHandcardNum() < 3 then
				current_value = current_value - 0.4
			elseif player:getHandcardNum() < 5 then
				current_value = current_value + 0.5
			end
		end
		if sgs.masochism_skill:match(skill) then
			if player:getHp() < 2 then
				current_value = current_value - 0.3
			end
			for i = 1, player:getHp() - 3, 1 do
				current_value = current_value + 0.6
			end
			for i = 1, self:getCardsNum("Peach"), 1 do
				current_value = current_value + 0.15
			end
			for i = 1, self:getCardsNum("Analeptic"), 1 do
				current_value = current_value + 0.1
			end
		end
		if sgs.lose_equip_skill:match(skill) then
			if self:getCardsNum("EquipCard") < 2 then
				current_value = current_value - 0.3
			end
			for i = 1, self:getCardsNum("EquipCard"), 1 do
				current_value = current_value + 0.1
			end
			for _, p in sgs.qlist(self.room:getOtherPlayers(player)) do
				if self:isFriend(p) then
					if self:hasKnownSkill("duoshi", p) then
						current_value = current_value + 0.4
					end
					if self:hasKnownSkill("zhijian", p) then
						current_value = current_value + 0.3
					end
				end
			end
		end
		if skill == "jizhi" then
			for i = 1, self:getCardsNum("TrickCard"), 1 do
				current_value = current_value + 0.1
			end
		end
	end
	player:speak(g1:objectName() .. "+" .. g2:objectName() .. "的组合得分是：" .. current_value)
	return current_value
end

sgs.ai_skill_choice.xinsheng = function(self, choice, data)
	return sgs.ai_skill_choice["huashen"](self, choice, data)
end

local yigui_skill = {}
yigui_skill.name = "yigui"
table.insert(sgs.ai_skills, yigui_skill)
yigui_skill.getTurnUseCard = function(self)
	if not self.player:hasShownSkill("yigui") then return end
	if self.player:property("Huashens"):toString() == "" then return end
	local huashens = self.player:property("Huashens"):toString():split("+");
--[[
	if (Self->hasFlag("Yigui_" + classname)) return false;
	QString card_name = Self->tag["yigui"].toString();
    QString soul_name = Self->tag["yigui_general"].toString();
	card->setUserString(QString("%1+%2").arg(card_name).arg(soul_name));
]]
--[[{联军盛宴,火烧连营,桃园结义,南蛮入侵,万箭齐发,
	远交近攻,无中生有,决斗,顺手牵羊,过河拆桥,水淹七军,
	铁索连环,以逸待劳,五谷丰登,勠力同心,调虎离山,敕令,
	借刀杀人,知己知彼,火攻,挟天子以令诸侯}
]]--按锦囊价值排序
	local trickcards = {"alliance_feast","burning_camps","god_salvation","savage_assault","archery_attack",--群体锦囊
	"befriend_attacking","ex_nihilo","duel","snatch","dismantlement","drowning",--单体锦囊
	"iron_chain","await_exhausted","amazing_grace","fight_together","lure_tiger","imperial_order",--几乎不会用到的群体锦囊
	"collateral","known_both","fire_attack","threaten_emperor"}--几乎不会用到的单体锦囊

	self.yigui_to = nil
	local soul_name
	local class_string
	local str = "@YiguiCard=.&" .. ":"
	local yigui_kingdom = {["wei"] = {}, ["shu"] = {}, ["wu"] = {}, ["qun"] = {}, ["careerist"] = {}, ["double"] = {}}
	for _, name in ipairs(huashens) do
		local general = sgs.Sanguosha:getGeneral(name)
		if not general:isDoubleKingdoms() then
			table.insert(yigui_kingdom[general:getKingdom()],name)
		else
			table.insert(yigui_kingdom["double"],name)
		end
	end

	local weak_count, wounded_count = 0,0
	for _, p in ipairs(self.friends) do
		if self.player:isFriendWith(p) and not p:isRemoved() and self:isWeak(p) then
			weak_count = weak_count + 1
		end
		if self.player:isFriendWith(p) and not p:isRemoved() and p:isWounded() then
			wounded_count = wounded_count + 1
		end
	end
	if #yigui_kingdom[self.player:getKingdom()] > 0 and not self.player:hasFlag("Yigui_GodSalvation") then
		if (#yigui_kingdom[self.player:getKingdom()] < 3 and (weak_count > 1 or wounded_count > 2))
		or (#yigui_kingdom[self.player:getKingdom()] >=3 and wounded_count > 1) then
			soul_name = yigui_kingdom[self.player:getKingdom()][1]
			class_string = "god_salvation"
			Global_room:writeToConsole("役鬼桃园")
			return sgs.Card_Parse(str .. class_string .. "+" .. soul_name)
		end
	end

	local kingdoms = {wei = 0, shu = 0, wu = 0, qun = 0, careerist = 0}--计算势力的人数，正是敌人，负是队友
	local kingdom_players = {wei = {}, shu = {}, wu = {}, qun = {}, careerist = {}}--各国家成员
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if not p:isRemoved() and p:hasShownOneGeneral() then--非暗将和掉虎
			local p_kingdom = p:getKingdom()
			if p_kingdom == "god" then
				p_kingdom = "careerist"
			end
			kingdoms[p_kingdom] = kingdoms[p_kingdom] + (self:isFriend(p) and -1 or 1)
			table.insert(kingdom_players[p_kingdom], p)
		end
	end
	local max_friend_kingom
	local max_enemy_kingdom = "careerist"--防止空值，同时可以进攻野心家，全是暗将的情况？
	local f_num, e_num = 0,0
	for key, value in pairs(kingdoms) do
		--Global_room:writeToConsole("役鬼国家数:"..key.."|"..value)
		if key and value > e_num then
			max_enemy_kingdom = key
			e_num = value
		end
		if key and self.player:getKingdom() ~= key and value < f_num then
			max_friend_kingom = key
			f_num = value
		end
	end

	local function getYiguiTargetByKingdom(kingdom, key, inverse)
		kingdom = kingdom or "careerist"
		key = key or "hp"
		if #kingdom_players[kingdom] > 0 then
			self:sort(kingdom_players[kingdom], key, inverse)
			return kingdom_players[kingdom][1]
		end
		return nil
	end

	local function getYiguiAoeValue(AOE_name,kingdom,kingdom2)--甚至可以加上判断暗将桃园、五谷
		if not (AOE_name == "archery_attack" or AOE_name == "savage_assault") then
			return -1
		end
		kingdom = kingdom or "unknown"
		kingdom2 = kingdom2 or kingdom
		local clone_trick = sgs.cloneCard(AOE_name)
		if clone_trick:isKindOf("SavageAssault") then
			local menghuo = sgs.findPlayerByShownSkillName("huoshou")
			if menghuo and not self:isFriend(menghuo) and menghuo:hasSkill("zhiman") then
				return 0
			end
		end
		local value = 0
		if kingdom == "unknown" then
			for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
				if not p:isRemoved() and not p:hasShownOneGeneral() and self:aoeIsEffective(clone_trick, p, self.player) then
					if self:evaluateKingdom(p) == "unknown"then
						value = value + 0.5
					elseif string.find(self:evaluateKingdom(p), self.player:getKingdom()) then
						value = value - 1
					else
						value = value + 1
					end
				end
			end
		else
			for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
				if not p:isRemoved() and p:hasShownOneGeneral() and (p:getKingdom() == kingdom or p:getKingdom() == kingdom2)
				and self:aoeIsEffective(clone_trick, p, self.player) then--非暗将和掉虎
					value = value +  (kingdoms[p:getKingdom()] >= 0 and 1 or -1 )
				end
				if not p:isRemoved() and not p:hasShownOneGeneral() and self:aoeIsEffective(clone_trick, p, self.player) then
					if self:evaluateKingdom(p) == "unknown"then
						value = value + 0.5
					elseif string.find(self:evaluateKingdom(p), self.player:getKingdom()) then
						value = value - 1
					else
						value = value + 1
					end
				end
			end
		end
		return value
	end

	if #yigui_kingdom["double"] > 0 then
		for _, name in ipairs(yigui_kingdom["double"]) do
			local general = sgs.Sanguosha:getGeneral(name)
			local double_kingdoms = general:getKingdoms()
			if kingdoms[double_kingdoms[1]] >= 0 and kingdoms[double_kingdoms[2]] >= 0
			and kingdoms[double_kingdoms[1]] + kingdoms[double_kingdoms[2]] >= kingdoms[max_enemy_kingdom] then
				if not self.player:hasFlag("Yigui_ArcheryAttack") then
					class_string = "archery_attack"
					if getYiguiAoeValue(class_string,double_kingdoms[1],double_kingdoms[2]) >0 then
						soul_name = name
						Global_room:writeToConsole("役鬼双势力万箭")
						return sgs.Card_Parse(str .. class_string .. "+" .. soul_name)
					end
				end
				if not self.player:hasFlag("Yigui_SavageAssault") then
					class_string = "savage_assault"
					if getYiguiAoeValue(class_string,double_kingdoms[1],double_kingdoms[2]) >0 then
						soul_name = name
						Global_room:writeToConsole("役鬼双势力南蛮")
						return sgs.Card_Parse(str .. class_string .. "+" .. soul_name)
					end
				end
			end
			if table.contains(double_kingdoms,self.player:getKingdom()) then
				table.removeOne(double_kingdoms,self.player:getKingdom())
				if not self.player:hasFlag("Yigui_AllianceFeast") and
					((math.abs(kingdoms[double_kingdoms[1]]) >= self.player:getLostHp() and self.player:getLostHp() > 1)
					or (kingdoms[double_kingdoms[1]] < 0 and self.player:isWounded())) then
						local to = getYiguiTargetByKingdom(double_kingdoms[1], "handcard")
						if to then
							self.yigui_to = sgs.SPlayerList()
							self.yigui_to:append(to)
							soul_name = name
							class_string = "alliance_feast"
							Global_room:writeToConsole("役鬼双势力联军")
							return sgs.Card_Parse(str .. class_string .. "+" .. soul_name)
						end
				end
			end
		end
	end
	if not self.player:hasFlag("Yigui_BurningCamps") and #yigui_kingdom[max_enemy_kingdom] > 0 then
		local np = self.player:getNextAlive()--最大敌人是下家队列的情况
		if np:getKingdom() == max_enemy_kingdom and np:getFormation():length() == kingdoms[max_enemy_kingdom] then
			local dummyuse = { isDummy = true, to = sgs.SPlayerList() }
			self:useCardBurningCamps(sgs.cloneCard("burning_camps"), dummyuse)
			if dummyuse.card then
				soul_name = yigui_kingdom[max_enemy_kingdom][1]
				class_string = "burning_camps"
				Global_room:writeToConsole("役鬼火烧1")
				return sgs.Card_Parse(str .. class_string .. "+" .. soul_name)
			end
		end
	end
	if #yigui_kingdom[max_enemy_kingdom] > 0 and not self.player:hasFlag("Yigui_ArcheryAttack") then
		class_string = "archery_attack"
		if getYiguiAoeValue(class_string,max_enemy_kingdom) >0 then
			soul_name = yigui_kingdom[max_enemy_kingdom][1]
			Global_room:writeToConsole("役鬼万箭")
			return sgs.Card_Parse(str .. class_string .. "+" .. soul_name)
		end
	end
	if #yigui_kingdom[max_enemy_kingdom] > 0 and not self.player:hasFlag("Yigui_SavageAssault") then
		class_string = "savage_assault"
		if getYiguiAoeValue(class_string,max_enemy_kingdom) >0 then
			soul_name = yigui_kingdom[max_enemy_kingdom][1]
			Global_room:writeToConsole("役鬼南蛮")
			return sgs.Card_Parse(str .. class_string .. "+" .. soul_name)
		end
	end
	if not self.player:hasFlag("Yigui_BurningCamps") then
		local np = self.player:getNextAlive()
		local np_kingdom = np:getKingdom()
		if np_kingdom == "god" then np_kingdom = "careerist" end
		if #yigui_kingdom[np_kingdom] > 0 then
			local can_burn = false
			local burn_weak = 0
			local players = np:getFormation()
			for _, p in sgs.qlist(players) do
				if p:getHp() == 1 and self:trickIsEffective(sgs.cloneCard("burning_camps"), p, self.player) then
					can_burn = true
					break
				end
				if self:isWeak(p) and self:trickIsEffective(sgs.cloneCard("burning_camps"), p, self.player) then
					burn_weak = burn_weak + 1
				end
			end
			if burn_weak > 1 or burn_weak == #self.enemies then--能否包含鏖战的情况？
				can_burn = true
			end
			local dummyuse = { isDummy = true, to = sgs.SPlayerList() }
			self:useCardBurningCamps(sgs.cloneCard("burning_camps"), dummyuse)
			if dummyuse.card and can_burn then
				soul_name = yigui_kingdom[np_kingdom][1]
				class_string = "burning_camps"
				Global_room:writeToConsole("役鬼火烧2")
				return sgs.Card_Parse(str .. class_string .. "+" .. soul_name)
			end
		end
	end
	if self.player:hasFlag("Yigui_ArcheryAttack") and self.player:hasFlag("Yigui_SavageAssault") and not self.player:hasFlag("Yigui_Duel") then
		local dummyuse = { isDummy = true, to = sgs.SPlayerList() }
		self:useCardDuel(sgs.cloneCard("duel"), dummyuse)
		if not dummyuse.to:isEmpty() then
			local duel_t = dummyuse.to:first()
			if duel_t:getHp() == 1 and #yigui_kingdom[duel_t:getKingdom()] > 0 then
				soul_name = yigui_kingdom[duel_t:getKingdom()][1]
				class_string = "duel"
				self.yigui_to = dummyuse.to
				Global_room:writeToConsole("役鬼决斗")
				return sgs.Card_Parse(str .. class_string .. "+" .. soul_name)
			end
		end
	end
	if not self.player:hasFlag("Yigui_BefriendAttacking") then
		if max_friend_kingom and #yigui_kingdom[max_friend_kingom] > 0 and (self.player:getHandcardNum() < 3 or #yigui_kingdom[max_friend_kingom] > 1) then
			local to = getYiguiTargetByKingdom(max_friend_kingom, "handcard")
			if to then
				self.yigui_to = sgs.SPlayerList()
				self.yigui_to:append(to)
				soul_name = yigui_kingdom[max_friend_kingom][1]
				class_string = "befriend_attacking"
				Global_room:writeToConsole("役鬼远交近攻1")
				return sgs.Card_Parse(str .. class_string .. "+" .. soul_name)
			end
		end
		for key, value in pairs(kingdoms) do
			if #yigui_kingdom[key] > 1 and value > 0 and key ~= max_enemy_kingdom then
				local to = getYiguiTargetByKingdom(key, "handcard")
				if to then
					self.yigui_to = sgs.SPlayerList()
					self.yigui_to:append(to)
					soul_name = yigui_kingdom[key][1]
					class_string = "befriend_attacking"
					Global_room:writeToConsole("役鬼远交近攻2")
					return sgs.Card_Parse(str .. class_string .. "+" .. soul_name)
				end
			end
		end
		if #yigui_kingdom[max_enemy_kingdom] > kingdoms[max_enemy_kingdom] and #yigui_kingdom[max_enemy_kingdom] > 0 then
			local to = getYiguiTargetByKingdom(max_enemy_kingdom, "handcard")
			if to then
				self.yigui_to = sgs.SPlayerList()
				self.yigui_to:append(to)
				soul_name = yigui_kingdom[max_enemy_kingdom][1]
				class_string = "befriend_attacking"
				Global_room:writeToConsole("役鬼远交近攻3")
				return sgs.Card_Parse(str .. class_string .. "+" .. soul_name)
			end
		end
	end
--进攻型简单的ai，挟天子、桃、酒、拆、顺暂缺
	if soul_name and class_string then
		return sgs.Card_Parse(str .. class_string .. "+" .. soul_name)
	end
end

sgs.ai_skill_use_func.YiguiCard = function(card, use, self)
	local userstring = card:toString()
	userstring = (userstring:split(":"))[3]
	userstring = (userstring:split("+"))[1]
	Global_room:writeToConsole("役鬼卡使用:"..userstring)
	if self.player:isCardLimited(sgs.cloneCard(userstring), sgs.Card_MethodUse) then
        Global_room:writeToConsole("役鬼卡Limited:"..userstring)
		return
    end
	use.card = card
	if use.to and self.yigui_to then--部分锦囊需要手选目标，决斗、远交近攻等
		use.to = self.yigui_to--Plist和SPlist的区别，需要targetFilter只能用sgs.PlayerList()
		self.yigui_to = nil
	end
end

sgs.ai_use_priority.YiguiCard = 2.8

function sgs.ai_cardsview.yigui(self, class_name, player)
	if not player:hasShownSkill("yigui") then return end
	if player:property("Huashens"):toString() == "" then return end
	local huashens = player:property("Huashens"):toString():split("+");
	if class_name == "Peach" or class_name == "Analeptic" then
		local soul_name
		local class_string
		local dying = self.room:getCurrentDyingPlayer()
		if dying then
			for _, name in ipairs(huashens) do
				local general = sgs.Sanguosha:getGeneral(name)
				if not general:isDoubleKingdoms() and general:getKingdom() == dying:getKingdom() then
					soul_name = name
					Global_room:writeToConsole("役鬼救人单势力:" .. soul_name)
					break
				end
			end
			if not soul_name then
				for _, name in ipairs(huashens) do
					local general = sgs.Sanguosha:getGeneral(name)
					if general:isDoubleKingdoms() and table.contains(general:getKingdoms(),dying:getKingdom()) then
						soul_name = name
						Global_room:writeToConsole("役鬼救人双势力:" .. soul_name)
						break
					end
				end
			end
			if dying:objectName() == player:objectName() then
				if not player:hasFlag("Yigui_Analeptic") then
					class_string = "analeptic"
				elseif not player:hasFlag("Yigui_Peach") then
					class_string = "peach"
				end
			else
				if not player:hasFlag("Yigui_Peach") then
					class_string = "peach"
				end
			end
			if soul_name and class_string then
				return "@YiguiCard=.&" .. ":".. class_string .. "+" .. soul_name
			end
		end
	end
end

sgs.ai_skill_invoke.jihun = true

--沙摩柯
sgs.ai_skill_invoke.jili = function(self, data)
	if not self:willShowForAttack() and not self:willShowForDefence() then return false end
	return true
end

--[[沙摩柯武器优先度调整]]--
function SmartAI:shamokeUseWeaponPriority(card)
	local class_name = card:getClassName()
	local v = self:getUsePriority(card)
	if self.player:hasSkill("jili") and not self.player:isKongcheng()
	and card:isKindOf("Weapon") and not card:isKindOf("Crossbow") then
		local hcards = self.player:getHandcards()
		hcards = sgs.QList2Table(hcards)
		self:sortByUsePriority(hcards)
		local firstcard = hcards[1]
		if self.player:getCardUsedTimes(".") + self.player:getCardRespondedTimes(".") + 2 == sgs.weapon_range[class_name] + sgs.Sanguosha:correctAttackRange(self.player,true,false)
		and v ~= self:getUsePriority(firstcard) then--防止无限自增死循环，防止两把武器相同距离死循环
			if not (firstcard:isKindOf("Weapon") and sgs.weapon_range[class_name] == sgs.weapon_range[firstcard:getClassName()]) then
				v = self:getUsePriority(firstcard) + 0.1
				--Global_room:writeToConsole("装备的优先度调整:")
				--Global_room:writeToConsole(v)
			end
		end
	end
	return v
end

sgs.ai_cardneed.jili = sgs.ai_cardneed.weapon

--马谡
sgs.ai_skill_invoke.zhiman = function(self, data)
	local damage = self.player:getTag("zhiman_data"):toDamage()
	local target = damage.to
	local can_get = self:findPlayerToDiscard("ej", false, sgs.Card_MethodGet, nil, true)
	if self:isFriend(target) and (table.contains(can_get, target) or not self:needToLoseHp(target, self.player)) then
		return true
	end
	if not self:isFriend(target) and not self:damageIsEffective_(damage) then
		return true
	end
	if not self:isFriend(target) and damage.damage > 1 and not target:hasArmorEffect("SilverLion") then
		return false
	end
	if table.contains(can_get, target) and not self:isWeak(target) then--可以优化？
		return true
	end
	if self:hasKnownSkill(sgs.masochism_skill, target) and self.player:canGetCard(target, "e")
	and self:needDamagedEffects(target, self.player) and not self:isWeak(target) then
		Global_room:writeToConsole("制蛮防止卖血")
		return true
	end
	return false
end

sgs.ai_choicemade_filter.skillInvoke.zhiman = function(self, player, promptlist)
	local damage = self.room:getTag("CurrentDamageStruct"):toDamage()
	if damage.from and damage.to then
		if promptlist[#promptlist] == "yes" then
			if not damage.to:hasEquip() and damage.to:getJudgingArea():isEmpty() then
				sgs.updateIntention(damage.from, damage.to, -40)
			end
		elseif self:canAttack(damage.to) then
			sgs.updateIntention(damage.from, damage.to, 30)
		end
	end
end

sgs.ai_skill_choice.zhiman = function(self, choices)
	Global_room:writeToConsole("制蛮命令变更")
	return "yes"
end

sgs.ai_skill_choice["transform_zhiman"] = function(self, choices)
	Global_room:writeToConsole("制蛮变更选择")
	if sgs.ai_AOE_data then--变更只能一次，判断aoe保留变更。是否命令变更没有信息判断，只能放这在
		local use = sgs.ai_AOE_data:toCardUse()
		local save_transform = false
		for _, p in sgs.qlist(use.to) do
			if self.player:isFriendWith(p) and self:playerGetRound(p) > self:playerGetRound(self.player) then
				local p_skills = sgs.QList2Table(p:getDeputySkillList(true,true,false))
				for _, skill in ipairs(p_skills) do
					if skill:getFrequency() == sgs.Skill_Limited and (skill:getLimitMark() ~= "" and p:getMark(skill:getLimitMark()) == 0) then--限定技已发动
						save_transform = true
						break
					end
				end
				if p:getActualGeneral2Name():match("sujiang") then
					save_transform = true
				end
			end
			if save_transform then
				Global_room:writeToConsole("制蛮保留变更")
				return "no"
			end
		end
	end
	local importantsklii = {"xuanhuo", "paoxiao", "kuanggu", "tieqi", "jizhi", "shengxi",  "jili", "tongdu"}
	local skills = sgs.QList2Table(self.player:getDeputySkillList(true,true,false))
	for _, skill in ipairs(skills) do
		if table.contains(importantsklii, skill:objectName()) then--重要技能
			return "no"
		end
		if skill:getFrequency() == sgs.Skill_Limited and not (skill:getLimitMark() ~= "" and self.player:getMark(skill:getLimitMark()) == 0) then--限定技未发动
			return "no"
		end
	end
	if self.player:hasSkills("paoxiao+wusheng") then
		return "no"
	end
	if self.player:hasSkill("congcha") then
		local congcha_draw = true
		for _, p in sgs.qlist(self.room:getAlivePlayers()) do
			if not p:hasShownOneGeneral() then
				congcha_draw = false
				break
			end
		end
		if congcha_draw then
			return "no"
		end
	end
	return "yes"
--[[
	choices = choices:split("+")
	return choices[math.random(1,#choices)]
]]
end

sgs.ai_choicemade_filter.cardChosen.zhiman = function(self, player, promptlist)
	local intention = 10
	local id = promptlist[3]
	local card = sgs.Sanguosha:getCard(id)
	local target = self.room:findPlayerbyobjectName(promptlist[5])
	if self:needToThrowArmor(target) and self.room:getCardPlace(id) == sgs.Player_PlaceEquip and card:isKindOf("Armor") then
		intention = -intention
	elseif self:doNotDiscard(target) then intention = -intention
	elseif self:hasKnownSkill(sgs.lose_equip_skill, target) and not target:getEquips():isEmpty() and
		self.room:getCardPlace(id) == sgs.Player_PlaceEquip and card:isKindOf("EquipCard") then
			intention = -intention
	elseif self.room:getCardPlace(id) == sgs.Player_PlaceJudge then
		intention = -intention
	end
	sgs.updateIntention(player, target, intention)
end

local sanyao_skill = {}
sanyao_skill.name = "sanyao"
table.insert(sgs.ai_skills, sanyao_skill)
sanyao_skill.getTurnUseCard = function(self)
	if not self:willShowForAttack() then return end
	if self.player:hasUsed("SanyaoCard") then return end
	if self.player:isNude() then return end
	return sgs.Card_Parse("@SanyaoCard=.&sanyao")
end

sgs.ai_skill_use_func.SanyaoCard = function(card, use, self)
	local targets = sgs.SPlayerList()
	local maxhp = 0
    for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if maxhp < p:getHp() then maxhp = p:getHp() end
	end
    for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if p:getHp() == maxhp and not p:isRemoved() then--调虎离山无法zhiman
			targets:append(p)
		end
	end
	local target
	if self.player:getMark("zhimantransformUsed") == 0 then--增加优先变将
		for _, p in sgs.qlist(targets) do
			if self.player:isFriendWith(p) then
				if p:getActualGeneral2Name():match("sujiang") then
					target = p
					Global_room:writeToConsole("散谣优先变更无副将")
					break
				end
				local skills = sgs.QList2Table(p:getDeputySkillList(true,true,false))
				for _, skill in ipairs(skills) do
					if skill:getFrequency() == sgs.Skill_Limited and (skill:getLimitMark() ~= "" and p:getMark(skill:getLimitMark()) == 0) then--限定技已发动
						target = p
						break
					end
				end
				if target then
					Global_room:writeToConsole("散谣优先变更限定技")
					break
				end
			end
		end
	end
	if not target then
		target = self:findPlayerToDiscard("ej", false, sgs.Card_MethodGet, targets)
	end
	if not target then
		for _, p in sgs.qlist(targets) do
			if self:isEnemy(p) and self:isWeak(p) then target = p break end
		end
	end
	if not target then
		for _, p in sgs.qlist(targets) do
			if not self:isFriend(p) and self:getDangerousCard(p) and self.player:canGetCard(p, self:getDangerousCard(p)) then
				target = p
				break
			end
		end
	end
	if not target then
		for _, p in sgs.qlist(targets) do
			if self:isEnemy(p) and not self:hasKnownSkill(sgs.masochism_skill, p) and self:getOverflow() > 0 then target = p break end
		end
	end

	if self:needToThrowArmor() then
		use.card = sgs.Card_Parse("@SanyaoCard=" .. self.player:getArmor():getId() .. "&sanyao")
		if targets:length() == 0 then use.card = nil return end
		if use.to then
			if target then
				use.to:append(target)
			else
				use.to:append(targets:first())
			end
			return
		end
	else
		if not target then use.card = nil return end
		local cards = sgs.QList2Table(self.player:getCards("he"))
		self:sortByUseValue(cards,true)

		local card_id
		for _, c in ipairs(cards) do
			if c:isKindOf("Lightning") and not isCard("Peach", c, self.player) and not self:willUseLightning(c) then
				card_id = c:getEffectiveId()
				break
			end
		end

		if not card_id then
			for _, c in ipairs(cards) do
				if not isCard("Peach", c, self.player)
					and (c:isKindOf("AmazingGrace") or c:isKindOf("GodSalvation") and not self:willUseGodSalvation(c)) then
					card_id = c:getEffectiveId()
					break
				end
			end
		end
		if not card_id then
			for _, c in ipairs(cards) do
				if (not isCard("Peach", c, self.player) or self:getCardsNum("Peach") > 1)
						and (not isCard("Jink", c, self.player) or self:getCardsNum("Jink") > 1 or self:isWeak())
					or self.player:getMark("GlobalBattleRoyalMode") > 0 then
					card_id = c:getEffectiveId()
					break
				end
			end
		end
		if card_id then
			use.card = sgs.Card_Parse("@SanyaoCard=" .. card_id .. "&sanyao")
			if use.to then
				if use.to:isEmpty() then use.to:append(target) return end
			end
		end
	end
end

--凌统
sgs.ai_skill_playerchosen.xuanlue = function(self, targets)
	if not (self:willShowForAttack() or self:willShowForDefence()) then return nil end
	return self:findPlayerToDiscard()
end

sgs.ai_choicemade_filter.cardChosen.xuanlue = function(self, player, promptlist)
	local intention = 10
	local id = promptlist[3]
	local card = sgs.Sanguosha:getCard(id)
	local target = self.room:findPlayerbyobjectName(promptlist[5])
	if self:needToThrowArmor(target) and self.room:getCardPlace(id) == sgs.Player_PlaceEquip and card:isKindOf("Armor") then
		intention = -intention
	elseif self:doNotDiscard(target) then intention = -intention
	elseif self:hasKnownSkill(sgs.lose_equip_skill, target) and not target:getEquips():isEmpty() and
		self.room:getCardPlace(id) == sgs.Player_PlaceEquip and card:isKindOf("EquipCard") then
			intention = -intention
	elseif self:getOverflow(target) > 2 then intention = 0
	end
	sgs.updateIntention(player, target, intention)
end

sgs.xuanlue_keep_value = {--相当于过河拆桥
	Weapon = 3.44,
	Armor = 3.45,
	OffensiveHorse = 3.44,
	DefensiveHorse = 3.44,
	SixDragons = 3.45,
	Treasure = 3.45
}

sgs.ai_cardneed.xuanlue = sgs.ai_cardneed.equip

local yongjin_skill = {}
yongjin_skill.name = "yongjin"
table.insert(sgs.ai_skills, yongjin_skill)
yongjin_skill.getTurnUseCard = function(self)
	if self.player:getMark("@brave") < 1 then return end
	return sgs.Card_Parse("@YongjinCard=.&")
end

sgs.ai_skill_use_func.YongjinCard = function(card, use, self)
	--Global_room:writeToConsole("进入函数勇进")
	self:updatePlayers()
	local equip_count = 0
	local OffensiveHorse_needcount, Armor_needcount, DefensiveHorse_needcount, Weapon_needcount, Treasure_needcount =0,0,0,0,0
	local OffensiveHorse_count, Armor_count, DefensiveHorse_count, Weapon_count, Treasure_count =0,0,0,0,0
	for _, who in sgs.qlist(self.room:getAlivePlayers()) do--君曹操马得单独判断
		if self:isFriend(who) then
			if not who:getOffensiveHorse() then
				OffensiveHorse_needcount = OffensiveHorse_needcount + 1
			end
			if not who:getArmor() then
				Armor_needcount = Armor_needcount + 1
			end
			if not who:getDefensiveHorse() then
				DefensiveHorse_needcount = DefensiveHorse_needcount + 1
			end
			if not who:getWeapon() then
				Weapon_needcount = Weapon_needcount + 1
			end
			if not who:getTreasure() then
				Treasure_needcount = Treasure_needcount + 1
			end
		else
			if who:getOffensiveHorse() then
				OffensiveHorse_count = OffensiveHorse_count + 1
			end
			if who:getArmor() then
				Armor_count = Armor_count + 1
			end
			if who:getDefensiveHorse() then
				DefensiveHorse_count = DefensiveHorse_count + 1
			end
			if who:getWeapon() then
				Weapon_count = Weapon_count + 1
			end
			if who:getTreasure() then
				Treasure_count = Treasure_count + 1
			end
		end
	end
	equip_count = equip_count + math.min(OffensiveHorse_needcount,OffensiveHorse_count)
	equip_count = equip_count + math.min(Armor_needcount,Armor_count)
	equip_count = equip_count + math.min(DefensiveHorse_needcount,DefensiveHorse_count)
	equip_count = equip_count + math.min(Weapon_needcount,Weapon_count)
	equip_count = equip_count + math.min(Treasure_needcount,Treasure_count)

	local weak_count = 0
	local hasSilverLion = false
	for _, p in ipairs(self.friends) do
		if self:isWeak(p) then
			weak_count = weak_count + 1
		end
	end
	for _, player in sgs.qlist(self.room:getAlivePlayers()) do
		if player:getArmor() and player:getArmor():isKindOf("SilverLion") then
			hasSilverLion = true
		end
	end
	if equip_count > 2 or (hasSilverLion and weak_count > 1) or (self.player:getHp() == 1 and equip_count > 1) then
		use.card = sgs.Card_Parse("@YongjinCard=.&yongjin")
	end
end

sgs.ai_use_priority.YongjinCard = 10--优先度多少合适？
sgs.ai_skill_playerchosen.yongjin = function(self, _targets, max_num, min_num)

	self:sort(self.enemies, "defense")
		for _, friend in ipairs(self.friends_noself) do
			if friend:hasEquip() and friend:hasShownSkills(sgs.lose_equip_skill) and self:getMoveCardorTarget(friend, ".", "e") then
				return {friend, self:getMoveCardorTarget(friend, "target", "e")}
			end
		end

		local targets = {}
		for _, enemy in sgs.qlist(self.room:getAlivePlayers()) do
			if not self.player:isFriendWith(enemy) and self:getMoveCardorTarget(enemy, "." ,"e") then
				table.insert(targets, enemy)
			end
		end

		if #targets > 0 then
			self:sort(targets, "defense")
			return {targets[#targets], self:getMoveCardorTarget(targets[#targets], "target", "e")}
		end

		if self.player:hasEquip() and self.player:hasShownSkills(sgs.lose_equip_skill) and self:getMoveCardorTarget(self.player, ".", "e") then
			return {self.player, self:getMoveCardorTarget(self.player, "target" ,"e")}
		end

		local friends = {}--没有敌人则简单转移队友装备
		for _, friend in ipairs(self.friends) do
			if self:getMoveCardorTarget(friend, "." ,"e") then
				table.insert(friends, friend)
			end
		end

		if #friends > 0 then
			self:sort(friends, "hp", true)
			return {friends[#friends], self:getMoveCardorTarget(friends[#friends], "target", "e")}
		end

	return {}
end

sgs.ai_skill_transfercardchosen.yongjin = function(self, targets, equipArea, judgingArea)
	return self:getMoveCardorTarget(targets:first(), "card", "e")
end
--[[
sgs.ai_skill_use["@@yongjin_move"] = function(self, prompt, method)
	if prompt ~= "@yongjin-next" then
		return "."
	end
	local YJMoveCard = "@YongjinMoveCard=.&->"

		for _, friend in ipairs(self.friends_noself) do
			if friend:hasEquip() and friend:hasShownSkills(sgs.lose_equip_skill) and self:getMoveCardorTarget(friend, "." ,"e") then
				return YJMoveCard .. friend:objectName() .. "+" .. self:getMoveCardorTarget(friend, "target" ,"e"):objectName()
			end
		end

		local targets = {}
		for _, enemy in sgs.qlist(self.room:getAlivePlayers()) do
			if not self.player:isFriendWith(enemy) and self:getMoveCardorTarget(enemy, "." ,"e") then
				table.insert(targets, enemy)
			end
		end

		if #targets > 0 then
			self:sort(targets, "defense")
			return YJMoveCard .. targets[#targets]:objectName() .. "+" .. self:getMoveCardorTarget(targets[#targets], "target" ,"e"):objectName()
		end

		if self.player:hasEquip() and self:getMoveCardorTarget(self.player, "." ,"e") then--没有目标给自己的武器，但是好像不会给敌人再给回自己的高级操作
			return YJMoveCard .. self.player:objectName() .. "+" .. self:getMoveCardorTarget(self.player, "target" ,"e"):objectName()
		end

		for _, friend in ipairs(self.friends_noself) do--再没有目标把队友的武器给自己
			if friend:hasEquip() then
				return YJMoveCard .. friend:objectName() .. "+" .. self.player:objectName()
			end
		end
	return "."
end
--]]
--吕范
--[[旧调度
local diaodu_skill = {}
diaodu_skill.name = "diaodu"
table.insert(sgs.ai_skills, diaodu_skill)
diaodu_skill.getTurnUseCard = function(self,room,player,data)
	if self.player:hasUsed("DiaoduCard") then return end
	if #self.friends_noself == 0 then return end
	return sgs.Card_Parse("@DiaoduCard=.&diaodu")
end

sgs.ai_skill_use_func.DiaoduCard = function(card, use, self)
	use.card = nil
	for _, card in sgs.qlist(self.player:getCards("h")) do
		if card:isKindOf("Weapon") and not self.player:getWeapon() then
			use.card = card
		end
		if card:isKindOf("Armor") and not self.player:getArmor() then
			use.card = card
		end
		if card:isKindOf("OffensiveHorse") and not self.player:getOffensiveHorse() then
			use.card = card
		end
		if card:isKindOf("DefensiveHorse") and not self.player:getDefensiveHorse() then
			use.card = card
		end
		if card:isKindOf("Treasure") and not self.player:getTreasure() then
			use.card = card
		end
		if use.card then return end
	end
	use.card = card
end

sgs.ai_skill_use["@@diaodu_equip"] = function(self, prompt)
	local id

	if self:needToThrowArmor() then
		for _, p in ipairs(self.friends_noself) do
			if self.player:isFriendWith(p) and not p:getArmor() then
				return ("@DiaoduequipCard=" .. self.player:getArmor():getEffectiveId() .. "&diaoduequip->" .. p:objectName())
			end
		end
	end
	for _, p in ipairs(self.friends_noself) do
		if not self.player:isFriendWith(p) then continue end
		for _, card in sgs.qlist(self.player:getCards("h")) do
			if card:isKindOf("Weapon") and self.player:getWeapon() then
				return "@DiaoduequipCard=" .. self.player:getWeapon():getEffectiveId() .. "&diaoduequip->" .. p:objectName()
			end
			if card:isKindOf("Armor") and self.player:getArmor() and not (self.player:getArmor():isKindOf("PeaceSpell") and self:isWeak()) then
				return "@DiaoduequipCard=" .. self.player:getArmor():getEffectiveId() .. "&diaoduequip->" .. p:objectName()
			end
			if card:isKindOf("OffensiveHorse") and self.player:getOffensiveHorse() then
				return "@DiaoduequipCard=" .. self.player:getOffensiveHorse():getEffectiveId() .. "&diaoduequip->" .. p:objectName()
			end
			if card:isKindOf("DefensiveHorse") and self.player:getDefensiveHorse() then
				return "@DiaoduequipCard=" .. self.player:getDefensiveHorse():getEffectiveId() .. "&diaoduequip->" .. p:objectName()
			end
			if card:isKindOf("Treasure") and self.player:getTreasure() and (not self.player:getArmor():isKindOf("WoodenOx") and self.player:getPile("wooden_ox"):length() > 1) then
				return "@DiaoduequipCard=" .. self.player:getTreasure():getEffectiveId() .. "&diaoduequip->" .. p:objectName()
			end
		end
	end
	if self.player:hasSkills(sgs.lose_equip_skill) then
		for _, card in sgs.qlist(self.player:getCards("e")) do
			for _, p in ipairs(self.friends_noself) do
				if not self.player:isFriendWith(p) then continue end
				if card:isKindOf("Armor") and not p:getArmor() and not(card:isKindOf("PeaceSpell") and self:isWeak()) then
					return ("@DiaoduequipCard=" .. self.player:getArmor():getEffectiveId() .. "&diaoduequip->" .. p:objectName())
				end
				if card:isKindOf("OffensiveHorse") and not p:getOffensiveHorse() then
					return ("@DiaoduequipCard=" .. self.player:getOffensiveHorse():getEffectiveId() .. "&diaoduequip->" .. p:objectName())
				end
				if card:isKindOf("DefensiveHorse") and not p:getDefensiveHorse() then
					return ("@DiaoduequipCard=" .. self.player:getDefensiveHorse():getEffectiveId() .. "&diaoduequip->" .. p:objectName())
				end
				if card:isKindOf("Treasure") and not p:getTreasure() and (not self.player:getArmor():isKindOf("WoodenOx") and self.player:getPile("wooden_ox"):length() > 1) then
					return ("@DiaoduequipCard=" .. self.player:getTreasure():getEffectiveId() .. "&diaoduequip->" .. p:objectName())
				end
				if card:isKindOf("Weapon") and not p:getWeapon() then
					return ("@DiaoduequipCard=" .. self.player:getWeapon():getEffectiveId() .. "&diaoduequip->" .. p:objectName())
				end
			end
		end
	end
	for _, card in sgs.qlist(self.player:getCards("e")) do
		for _, p in ipairs(self.friends_noself) do
			if not self.player:isFriendWith(p) or not self:hasKnownSkill(sgs.need_equip_skill .. "|" .. sgs.lose_equip_skill, p) then continue end
			if card:isKindOf("Armor") and not p:getArmor() and not(card:isKindOf("PeaceSpell") and self:isWeak()) then
				return ("@DiaoduequipCard=" .. self.player:getArmor():getEffectiveId() .. "&diaoduequip->" .. p:objectName())
			end
			if card:isKindOf("OffensiveHorse") and not p:getOffensiveHorse() then
				return ("@DiaoduequipCard=" .. self.player:getOffensiveHorse():getEffectiveId() .. "&diaoduequip->" .. p:objectName())
			end
			if card:isKindOf("DefensiveHorse") and not p:getDefensiveHorse() then
				return ("@DiaoduequipCard=" .. self.player:getDefensiveHorse():getEffectiveId() .. "&diaoduequip->" .. p:objectName())
			end
			if card:isKindOf("Treasure") and not p:getTreasure() and (not self.player:getArmor():isKindOf("WoodenOx") and self.player:getPile("wooden_ox"):length() > 1) then
				return ("@DiaoduequipCard=" .. self.player:getTreasure():getEffectiveId() .. "&diaoduequip->" .. p:objectName())
			end
			if card:isKindOf("Weapon") and not p:getWeapon() then
				return ("@DiaoduequipCard=" .. self.player:getWeapon():getEffectiveId() .. "&diaoduequip->" .. p:objectName())
			end
		end
	end

	for _, card in sgs.qlist(self.player:getCards("h")) do
		if card:isKindOf("EquipCard") then
			local dummy_use = {isDummy = true}
			self:useEquipCard(card, dummy_use)
			if dummy_use.card and dummy_use.card:getEffectiveId() == card:getEffectiveId() then
				return card:toString()
			end
		end
	end
	return "."
end
]]--
sgs.ai_skill_invoke.diaodu = function(self, data)
	--if not self:willShowForAttack() then return false end
	return true
end

sgs.ai_skill_playerchosen.diaodu = function(self, targets)--还可以细化条件，装备转移？
	if targets:length() > 1 then
		for _, hcard in sgs.qlist(self.player:getCards("h")) do
			if hcard:isKindOf("EquipCard") and self:getSameEquip(hcard) then--重复先拿自己
				return self.player
			end
		end
		for _,p in sgs.qlist(targets) do
			if p:hasSkills(sgs.lose_equip_skill) then
				return p
			end
		end
	end
	for _,p in sgs.qlist(targets) do
		if self:needToThrowArmor(p) then
			return p
		end
	end
	if self.player:getEquips():length() == 1 and self.player:hasTreasure("WoodenOx") and self.player:getPile("wooden_ox"):length() > 0 then
		return {}
	end
	return {}
end

sgs.ai_skill_cardchosen.diaodu = function(self, who, flags, method, disable_list)
	self.diaodu_id = nil
	if who:objectName() == self.player:objectName() then--指针是可以判定等于的，severplayer类型，但是who是否会是player类型？
		for _, hcard in sgs.qlist(self.player:getCards("h")) do
			if hcard:isKindOf("EquipCard") and self:getSameEquip(hcard) then
				self.diaodu_id = self:getSameEquip(hcard):getEffectiveId()
				return self.diaodu_id
			end
		end
	end
	self.diaodu_id = self:askForCardChosen(who, flags, "diaodu_snatch", method, disable_list)
	return self.diaodu_id
end

sgs.ai_skill_playerchosen["diaodu_give"] = function(self, targets, max_num, min_num)
	local diaodu_card
	if self.diaodu_id then
		diaodu_card = sgs.Sanguosha:getCard(self.diaodu_id)
	end
	for _,p in sgs.qlist(targets) do
		if p:hasSkills(sgs.lose_equip_skill) and self:isFriend(p) and not self:willSkipPlayPhase(p) then
			return p
		end
	end
	local AssistTarget = self:AssistTarget()
	if AssistTarget and targets:contains(AssistTarget) and not self:willSkipPlayPhase(AssistTarget) and self:isFriendWith(AssistTarget) then
		return AssistTarget
	end
	if diaodu_card then
		if diaodu_card:isKindOf("EquipCard") and self:getSameEquip(diaodu_card) then--重复装备
			for _,p in sgs.qlist(targets) do
				if self:isFriendWith(p) and not self:willSkipPlayPhase(p) and not self:getSameEquip(diaodu_card, p)
				and self:playerGetRound(p, self.player) < self.room:alivePlayerCount() / 2 then
					return p
				end
			end
		end
		--[[
		local c, friend = self:getCardNeedPlayer({diaodu_card})--这样给装备是否合适？
		if c and friend and self:isFriendWith(friend) and self:isFriendWith(friend) and targets:contains(friend) then
		return friend
		end]]
	end
	if min_num > 0 then
		for _,p in sgs.qlist(targets) do
			if self:isFriendWith(p) then
				return p
			end
		end
	end
	return {}
end

sgs.ai_skill_choice["diaodu"] = function(self, choices, data)
	return "yes"
end

sgs.ai_skill_invoke.diancai = function(self, data)
	if not self:willShowForDefence() then return false end
	return true
end

sgs.ai_skill_choice["transform_diancai"] = function(self, choices)
	--Global_room:writeToConsole("典财变更选择")
	local importantsklii = {"xiaoji", "xuanlue", "tianxiang", "guose", "yingzi_zhouyu", "zhukou"}--还有哪些？
	local skills = sgs.QList2Table(self.player:getDeputySkillList(true,true,false))
	for _, skill in ipairs(skills) do
		if table.contains(importantsklii, skill:objectName()) then--重要技能
			Global_room:writeToConsole("典财重要技能")
			return "no"
		end
		if skill:objectName() == "diancai" and not self:isWeak() then--换自己
			Global_room:writeToConsole("典财换自己")
			return "no"
		end
		if skill:getFrequency() == sgs.Skill_Limited and not (skill:getLimitMark() ~= "" and self.player:getMark(skill:getLimitMark()) == 0) then--限定技未发动
			Global_room:writeToConsole("典财限定技能")
			return "no"
		end
	end
	if self.player:hasSkill("keshou") then
		local no_friend = true
		for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			if self.player:isFriendWith(p) then
				no_friend = false
				break
		  	end
		end
		if no_friend then
			return "no"
		end
	end
	if self.player:hasSkills("keshou|hunshang") and self:isWeak() and sgs.findPlayerByShownSkillName("buqu") then
		return "no"
	end
	if self.player:inDeputySkills("buqu") then
		return self.player:getPile("scars"):length() <= 4 and "no" or "yes"
	end
	if self.player:hasSkill("congcha") then
		local congcha_draw = true
		for _, p in sgs.qlist(self.room:getAlivePlayers()) do
			if not p:hasShownOneGeneral() then
				congcha_draw = false
				break
			end
		end
		if congcha_draw then
			return "no"
		end
	end

	local g2name = self.player:getActualGeneral2Name()
	if g2name:match("sujiang") then
		Global_room:writeToConsole("典财无副将")
		return "yes"
	end
	if (sgs.general_value[g2name] and sgs.general_value[g2name] < 7) then--or self.player:inDeputySkills("yinghun_sunjian")
		Global_room:writeToConsole("典财副将值小于7")
		return "yes"
	end
	Global_room:writeToConsole("典财随机选择：" .. choices)
	choices = choices:split("+")
	return choices[math.random(1,#choices)]
end

--君孙权
local lianzi_skill = {}
lianzi_skill.name = "lianzi"
table.insert(sgs.ai_skills, lianzi_skill)
lianzi_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("LianziCard") or self.player:isKongcheng() then return end
	local num = self.player:getPile("flame_map"):length()
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if p:hasShownOneGeneral() and p:getKingdom() == "wu" and p:getRole() ~= "careerist" then
			num = num + p:getEquips():length()
		end
	end
	if num >= 3 then
		local hcards = sgs.QList2Table(self.player:getHandcards())
		self:sortByUseValue(hcards, true)
		return sgs.Card_Parse("@LianziCard=" .. hcards[1]:getEffectiveId() .. "&lianzi")
	end
end

sgs.ai_skill_use_func.LianziCard = function(card, use, self)
	use.card = card
end

sgs.ai_skill_invoke.jubao = true

sgs.ai_skill_cardchosen.jubao = function(self, who, flags, method, disable_list)
	if who:hasSkills(sgs.lose_equip_skill) and self:isFriend(who) then
		return self:askForCardChosen(who, "e", "jubao_snatch", method, disable_list)
	end
	if not self:isFriend(who) then
		if self:isWeak(who) and who:getHandcardNum() <= 2 then
			return self:askForCardChosen(who, "h", "jubao_snatch", method, disable_list)
		end
		return who:getTreasure():getId()
	end
	if self.player:objectName() == who:objectName() then
		if self:needToThrowArmor() then
			return who:getArmor():getId()
		end
		return who:getTreasure():getId()
	end
	return self:askForCardChosen(who, flags, "jubao_snatch", method, disable_list)
end

--缘江烽火图【缘江】
local flamemap_skill = {}
flamemap_skill.name = "flamemap"
table.insert(sgs.ai_skills, flamemap_skill)
flamemap_skill.getTurnUseCard = function(self)
	local cards = {}
	for _, c in sgs.qlist(self.player:getCards("he")) do
		if c:isKindOf("EquipCard") then table.insert(cards, c) end
	end
	if #cards == 0 then return end
	local sunquan = self.room:getLord(self.player:getKingdom())
	if not self.player:hasLordSkill("jiahe") and (not sunquan or not sunquan:hasLordSkill("jiahe")) then return end--AI加入野心家后发动会导致闪退
	if not self.player:hasUsed("FlameMapCard") then
		return sgs.Card_Parse("@FlameMapCard=.&showforviewhas")
	end
end

sgs.ai_skill_use_func.FlameMapCard = function(card,use,self)
	local sunquan = self.room:getLord(self.player:getKingdom())
	if not sunquan or not sunquan:hasLordSkill("jiahe") then return end
	local full = (sunquan:getPile("flame_map"):length() >= 5)
	sgs.ai_use_priority.FlameMapCard = 0
	if self.player:hasSkills(sgs.lose_equip_skill) then
		--Global_room:writeToConsole("烽火弃置装备技能")
		for _, hcard in sgs.qlist(self.player:getCards("h")) do
			if hcard:isKindOf("EquipCard") and self:getSameEquip(hcard) then
				--Global_room:writeToConsole("弃置装备技能有相同武器：" .. self:getSameEquip(hcard):getLogName())
				local dummy_use = {isDummy = true}
				self:useEquipCard(hcard, dummy_use)
				if dummy_use.card and dummy_use.card:isKindOf("EquipCard") then
					sgs.ai_use_priority.FlameMapCard = 20
					--Global_room:writeToConsole("弃置装备技能有相同武器2：" .. self:getSameEquip(hcard):getLogName())
					use.card = sgs.Card_Parse("@FlameMapCard=" .. self:getSameEquip(hcard):getEffectiveId() .. "&showforviewhas")
					return
				end
			end
		end
		if self:needToThrowArmor() then
			sgs.ai_use_priority.FlameMapCard = 20
			--self.player:speak("有返回：" .. self.player:getArmor():getLogName())
			use.card = sgs.Card_Parse("@FlameMapCard=" .. self.player:getArmor():getEffectiveId() .. "&showforviewhas")
			return
		end
		if self.player:getOffensiveHorse() then
			--self.player:speak("有返回：" .. self.player:getOffensiveHorse():getLogName())
			use.card = sgs.Card_Parse("@FlameMapCard=" .. self.player:getOffensiveHorse():getEffectiveId() .. "&showforviewhas")
			return
		end
		if self.player:getWeapon() then
			--self.player:speak("有返回：" .. self.player:getWeapon():getLogName())
			use.card = sgs.Card_Parse("@FlameMapCard=" .. self.player:getWeapon():getEffectiveId() .. "&showforviewhas")
			return
		end
		if self.player:getArmor() and not(self.player:getArmor():isKindOf("PeaceSpell") and self:isWeak()) then
			--self.player:speak("有返回：" .. self.player:getArmor():getLogName())
			use.card = sgs.Card_Parse("@FlameMapCard=" .. self.player:getArmor():getEffectiveId() .. "&showforviewhas")
			return
		end
		if self.player:getDefensiveHorse() then
			--self.player:speak("有返回：" .. self.player:getDefensiveHorse():getLogName())
			use.card = sgs.Card_Parse("@FlameMapCard=" .. self.player:getDefensiveHorse():getEffectiveId() .. "&showforviewhas")
			return
		end
	else
		if self.player:hasEquip() then
			if self:needToThrowArmor() then
				sgs.ai_use_priority.FlameMapCard = 20
				--self.player:speak("有返回：" .. self.player:getArmor():getLogName())
				use.card = sgs.Card_Parse("@FlameMapCard=" .. self.player:getArmor():getEffectiveId() .. "&showforviewhas")
				return
			end
			if self.player:getArmor() and self:evaluateArmor(self.player:getArmor()) < -5 then
				sgs.ai_use_priority.FlameMapCard = 20
				--self.player:speak("有返回：" .. self.player:getArmor():getLogName())
				use.card = sgs.Card_Parse("@FlameMapCard=" .. self.player:getArmor():getEffectiveId() .. "&showforviewhas")
				return
			end
		end
		for _, hcard in sgs.qlist(self.player:getCards("h")) do
			if hcard:isKindOf("EquipCard") then
				local dummy_use = {isDummy = true}
				self:useEquipCard(hcard, dummy_use)
				if not dummy_use.card then
					if self.room:getCardPlace(hcard:getEffectiveId()) == sgs.Player_PlaceHand then
						sgs.ai_use_priority.FlameMapCard = 20
						--self.player:speak("有返回：" .. card:getLogName())
						use.card = sgs.Card_Parse("@FlameMapCard=" .. hcard:getEffectiveId() .. "&showforviewhas")
						return
					end
				else
					-- and not self:getSameEquip(hcard):isKindOf("LuminousPearl") 夜明珠不放？
					if dummy_use.card:isKindOf("EquipCard") and self:getSameEquip(hcard) then
						sgs.ai_use_priority.FlameMapCard = 20
						--self.player:speak("有返回：" .. self:getSameEquip(hcard):getLogName())
						use.card = sgs.Card_Parse("@FlameMapCard=" .. self:getSameEquip(hcard):getEffectiveId() .. "&showforviewhas")
						return
					end
				end
			end
		end
		if self.player:hasEquip() and not full then
			if self.player:getOffensiveHorse() then
				--self.player:speak("有返回：" .. self.player:getOffensiveHorse():getLogName())
				use.card = sgs.Card_Parse("@FlameMapCard=" .. self.player:getOffensiveHorse():getEffectiveId() .. "&showforviewhas")
				return
			end
			if self.player:getWeapon() then
				--self.player:speak("有返回：" .. self.player:getWeapon():getLogName())
				use.card = sgs.Card_Parse("@FlameMapCard=" .. self.player:getWeapon():getEffectiveId() .. "&showforviewhas")
				return
			end
			if not self:isWeak() then
				if self.player:getArmor() then
					--self.player:speak("有返回：" .. self.player:getArmor():getLogName())
					use.card = sgs.Card_Parse("@FlameMapCard=" .. self.player:getArmor():getEffectiveId() .. "&showforviewhas")
					return
				end
				if self.player:getDefensiveHorse() then
					--self.player:speak("有返回：" .. self.player:getDefensiveHorse():getLogName())
					use.card = sgs.Card_Parse("@FlameMapCard=" .. self.player:getDefensiveHorse():getEffectiveId() .. "&showforviewhas")
					return
				end
			end
		end
	end
end
sgs.ai_use_value.FlameMapCard = 10

--缘江烽火图【宏图】
sgs.ai_skill_choice.flamemap = function(self, choices)
	--英姿、好施、涉猎、度势
	--初步策略：手牌十分充裕选度势，其次优先级：好施，涉猎，英姿，如果能选择两项则必选度势（0张手牌，没额外摸牌技选好施+英姿）
	--界限突破英姿变为锁定技并获得手牌上限效果，损失血量过大或有其他摸牌技能，优先考虑英姿

	choices = choices:split("+")
	local sunquan = self.room:getLord(self.player:getKingdom())
	local n = sunquan:getPile("flame_map"):length()

	local congcha_draw = false
	if self.player:hasSkill("congcha") then--不臣新加入的摸牌技能
		congcha_draw = true
		for _, p in sgs.qlist(self.room:getAlivePlayers()) do
			if not p:hasShownOneGeneral() then
				congcha_draw = false
				break
			end
		end
	end

	if self.player:hasSkill("haoshi") and table.contains(choices, "haoshi_flamemap") then
		if sgs.ai_skill_invoke.haoshi(self) and self.haoshi_target and self.haoshi_flamemap_target then
			return "haoshi_flamemap"--有目标时双好施,给完一次半数后超过5会给两次牌
		else
			table.removeOne(choices, "haoshi_flamemap")--复杂情况不考虑
		end
	end

	if n > 4 and table.contains(choices, "haoshi_flamemap") and
	self.player:getHandcardNum() > 3 and sgs.ai_skill_invoke.haoshi_flamemap(self) then--手牌大于3时触发好施必定有队友
		return "haoshi_flamemap"--手牌充裕时好施给队友
	end

	if self.player:isKongcheng() and not (self.player:hasSkills("yingzi_zhouyu|yingzi_sunce|haoshi") or self.player:hasTreasure("JadeSeal") or congcha_draw) then
		table.removeOne(choices, "duoshi_flamemap")--0张手牌，没额外摸牌技移除度势
	end

	if self.player:hasSkill("duoshi") and self.player:getHandcardNum() < 4
	and not (self.player:hasSkills("yingzi_zhouyu|yingzi_sunce|yingzi_flamemap|haoshi|haoshi_flamemap|shelie") or self.player:hasTreasure("JadeSeal") or congcha_draw) then
		table.removeOne(choices, "duoshi_flamemap")--已有度势，没额外摸牌技和手牌少时移除度势
	end

	if n > 4 and table.contains(choices, "duoshi_flamemap") and not self.player:hasSkill("duoshi") then
		return "duoshi_flamemap"--能选择两项则必选度势
	end

	if table.contains(choices, "yingzi_flamemap") and table.contains(choices, "haoshi_flamemap")  then
		if self.player:hasSkills("yingzi_zhouyu|yingzi_sunce") --已有英姿且能好施，0手牌或有目标
		and sgs.ai_skill_invoke.haoshi_flamemap(self) then
			return "haoshi_flamemap"
		end
		if self.player:getLostHp() < 2 and (self.player:hasTreasure("JadeSeal") or congcha_draw)--血量健康有玉玺且能好施
		and sgs.ai_skill_invoke.haoshi_flamemap(self) then
			return "haoshi_flamemap"
		end
		if (self.player:getLostHp() > (self:willSkipPlayPhase() and 0 or 1)
			and not (self.player:hasSkill("keji") or self.player:getMaxCards() > 3))--需要手牌上限
		or self.player:hasSkills("yingzi_zhouyu|yingzi_sunce")--已有英姿，不适合好施
		or self.player:hasTreasure("JadeSeal")--已有玉玺，不适合好施
		or congcha_draw then--聪察摸牌，不适合好施
			return "yingzi_flamemap"
		end
	end

	if table.contains(choices, "haoshi_flamemap") and sgs.ai_skill_invoke.haoshi_flamemap(self) then
		return "haoshi_flamemap"
	end

	if n > 4 and table.contains(choices, "yingzi_flamemap") and
		self.player:getHandcardNum() > 3 and sgs.ai_skill_invoke.haoshi_flamemap(self) then--宁可好施英姿，避免好施涉猎
		return "yingzi_flamemap"
	end

	if table.contains(choices, "shelie") and sgs.ai_skill_invoke.shelie(self) then
		return "shelie"
	end

	if table.contains(choices, "yingzi_flamemap") then
		return "yingzi_flamemap"
	end

	if table.contains(choices, "duoshi_flamemap") then
		return "duoshi_flamemap"
	end
end

--缘江烽火图【烽火】：藏专属装备坑下其他君主，把定澜夜明珠放到烽火里面的话赶紧放出来，技能修改
sgs.ai_skill_askforag.flamemap = function(self, card_ids)
	for _, id in ipairs(card_ids) do
		local card = sgs.Sanguosha:getCard(id)
		if card:isKindOf("LuminousPearl") then
			return id
		elseif card:isKindOf("DragonPhoenix") then
			local lord = self.room:getLord("shu")
			if not lord or self:isFriend(lord) then
				return id
			end
		elseif card:isKindOf("PeaceSpell") then
			local lord = self.room:getLord("qun")
			if not lord or self:isFriend(lord) then
				return id
			end
		elseif card:isKindOf("SixDragons") then
			local lord = self.room:getLord("wei")
			if not lord or self:isFriend(lord) then
				return id
			end
		else
			return id
		end
	end
	return card_ids[1]
end

sgs.ai_skill_invoke.yingzi_flamemap = function(self, data)
	return true
end


--好施，复杂情况不考虑双好施
sgs.ai_skill_invoke.haoshi_flamemap = sgs.ai_skill_invoke.haoshi
--[[
sgs.ai_skill_invoke.haoshi_flamemap = function(self, data)
	if self.player:hasSkills("haoshi") then
		if sgs.ai_skill_invoke.haoshi(self) and self.haoshi_target then
			return true--双好施且有目标
		else
			return false--双好施一个不发动
		end
	end
	return sgs.ai_skill_invoke.haoshi(self)
end
]]--


--涉猎
sgs.ai_skill_invoke.shelie = function(self, data)
	if self.player:hasSkills("haoshi|haoshi_flamemap") and self.player:getHandcardNum() < 2 then return false end
	local extra = 0
	if self.player:hasTreasure("JadeSeal") then
		extra = extra+1
	end
	if self.player:hasSkill("yingzi_zhouyu") then
		extra = extra+1
	end
	if self.player:hasSkill("yingzi_sunce") then
		extra = extra+1
	end
	if self.player:hasSkill("yingzi_flamemap") then
		extra = extra+1
	end
	if sgs.ai_skill_invoke.haoshi(self) then
		if self.player:hasSkill("haoshi") then
			extra = extra+2
		end
		if self.player:hasSkill("haoshi_flamemap") then
			extra = extra+2
		end
	end
	if self.player:hasSkill("congcha") then
		local congcha_draw = true
		for _, p in sgs.qlist(self.room:getAlivePlayers()) do
			if not p:hasShownOneGeneral() then
				congcha_draw = false
				break
			end
		end
		if congcha_draw then
		extra = extra+2
		end
	end
	if extra > 1 then return false end
	return true
end

sgs.ai_skill_movecards.shelie = function(self, upcards, downcards, min_num, max_num)
	local upcards_copy, enableds, down = table.copyFrom(upcards), table.copyFrom(upcards), {}
	while #enableds ~= 0 do
		local card = self:askForAG(enableds, false, "shelie")
		for _, card_id in ipairs(upcards_copy) do
		    if sgs.Sanguosha:getCard(card_id):getSuit() == sgs.Sanguosha:getCard(card):getSuit() then
			    table.removeOne(enableds, card_id)
			end
		end
		table.removeOne(upcards_copy, card)
		table.insert(down, card)
	end
	return upcards_copy, down
end

--度势
local duoshi_flamemap_skill = {}
duoshi_flamemap_skill.name = "duoshi_flamemap"
table.insert(sgs.ai_skills, duoshi_flamemap_skill)
duoshi_flamemap_skill.getTurnUseCard = function(self, inclusive)
	local DuoTime = 1
	if self.player:hasSkills("hongyan|yingzi_zhouyu|yingzi_sunce|yingzi_flamemap|haoshi|haoshi_flamemap") then
		DuoTime = 2
	end
	for _, player in ipairs(self.friends) do
		if player:hasShownSkills("xiaoji|xuanlue|diaodu") then
			DuoTime = 2
			break
		end
	end
	if self.player:hasSkills("xiaoji|xuanlue|diaodu") then
		DuoTime = 2
		for _,card in sgs.qlist(self.player:getCards("he")) do
			if card:isKindOf("EquipCard") then
				DuoTime = DuoTime + 1
			end
		  end
	end
	if self.player:getHandcardNum() > 4 then
		DuoTime = DuoTime + 1
	end

	if self.player:usedTimes("ViewAsSkill_duoshi_flamemapCard") >= DuoTime or self:getOverflow() < 0 then return end
	if self.player:usedTimes("ViewAsSkill_duoshi_flamemapCard") >= 4 then return end

	if sgs.turncount <= 1 and #self.friends_noself == 0 and not self:isWeak() and self:getOverflow() <= 0 then return end
	local cards = self.player:getCards("h")
	for _, id in sgs.qlist(self.player:getHandPile()) do
		cards:prepend(sgs.Sanguosha:getCard(id))
	end
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards, true)
	for _, card in ipairs(cards) do
		if self:getUseValue(card) >= 4.5 and card:isAvailable(self.player) then
			local dummy_use = {isDummy = true}
			if not card:targetFixed() then dummy_use.to = sgs.SPlayerList() end
			if card:isKindOf("EquipCard") then
				self:useEquipCard(card, dummy_use)
			else
				self:useCardByClassName(card, dummy_use)
			end
			if dummy_use.card and self:getUsePriority(card) >= 2.8 then
				return
			end
		end
	end

	if (self:hasCrossbowEffect() or self:getCardsNum("Crossbow") > 0) and self:getCardsNum("Slash") > 0 then
		self:sort(self.enemies, "defense")
		for _, enemy in ipairs(self.enemies) do
			local inAttackRange = self.player:distanceTo(enemy) == 1 or self.player:distanceTo(enemy) == 2 and self:getCardsNum("OffensiveHorse") > 0 and not self.player:getOffensiveHorse()
			if inAttackRange  and sgs.isGoodTarget(enemy, self.enemies, self) then
				local slashes = self:getCards("Slash")
				local slash_count = 0
				for _, slash in ipairs(slashes) do
					if not self:slashProhibit(slash, enemy) and self:slashIsEffective(slash, enemy) then
						slash_count = slash_count + 1
					end
				end
				if slash_count >= enemy:getHp() then return end
			end
		end
	end

	local red_card
	if self.player:getHandcardNum() <= 1 then return end
	self:sortByUseValue(cards, true)

	for _, card in ipairs(cards) do
		if card:isRed() then
			local shouldUse = true
			if card:isKindOf("Slash") then
				local dummy_use = { isDummy = true }
				if self:getCardsNum("Slash") == 1 then
					self:useBasicCard(card, dummy_use)
					if dummy_use.card then shouldUse = false end
				end
			end

			if self:getUseValue(card) > sgs.ai_use_value.AwaitExhausted and card:isKindOf("TrickCard") then
				local dummy_use = { isDummy = true }
				self:useTrickCard(card, dummy_use)
				if dummy_use.card then shouldUse = false end
			end

			if shouldUse and not card:isKindOf("Peach") then
				red_card = card
				break
			end

		end
	end

	if red_card then
		local card_id = red_card:getEffectiveId()
		local card_str = string.format("await_exhausted:duoshi_flamemap[%s:%d]=%d&duoshi_flamemap",red_card:getSuitString(), red_card:getNumber(), red_card:getEffectiveId())
		local await = sgs.Card_Parse(card_str)
		assert(await)
		return await
	end
end


--夜明珠
local LuminousPearl_skill = {}
LuminousPearl_skill.name = "LuminousPearl"
table.insert(sgs.ai_skills, LuminousPearl_skill)
LuminousPearl_skill.getTurnUseCard = function(self)
	--有一个BUG:玩家带着夜明珠开五谷托管,AI和玩家可以分别用一次制衡
	--问题在于玩家使用的时候记录的P:hasUsed("ZhihengLPCard"),AI用的时候记录的P:hasUsed("ZhihengCard")
	--因为源码是视为拥有制衡,带着夜明珠可以查到P:hasSkill("zhiheng")为true,AI仍可以调用制衡的getTurnUseCard使用ZhihengCard
	--且AI进入ai_skill_use_func.ZhihengLPCard后不能使用use.card = sgs.Card_Parse("@ZhihengLPCard=" .. table.concat(use_cards, "+") .. "&LuminousPearl")
	if self.player:hasUsed("ZhihengCard") then return end--发动制衡后,有夜明珠也不能再次制衡
	if (self.player:inHeadSkills("zhiheng") and self.player:hasShownGeneral1()) or 
		(self.player:inDeputySkills("zhiheng") and self.player:hasShownGeneral2()) then return end--明置武将牌上的制衡后,不能使用夜明珠
	if self.player:hasTreasure("LuminousPearl") and not self.player:hasUsed("ZhihengLPCard") then
		return sgs.Card_Parse("@ZhihengLPCard=.LuminousPearl")
	end
end

sgs.ai_use_priority.LuminousPearl = 5.7
sgs.ai_keep_value.LuminousPearl = 4.2

sgs.ai_skill_use_func.ZhihengLPCard = sgs.ai_skill_use_func.ZhihengCard
sgs.ai_use_value.ZhihengLPCard = sgs.ai_use_value.ZhihengCard
sgs.ai_use_priority.ZhihengLPCard = 2.71
sgs.dynamic_value.benefit.ZhihengLPCard = sgs.dynamic_value.benefit.ZhihengCard

--变更武将相关
function sgs.readGeneralValuefromtxt()--读入ai-selector/general-value.txt
	local singlevalue = {}
	local filename = "?../../ai-selector/general-value.txt"
	for line in io.lines(filename) do
		local w, n = string.match(line, "^(%w+)"), string.match(line, "(%d+)$")
		if string.find(line,"_") then
			w = string.match(line, "^(%w+_%w+)")
		end
		if w and n then
			--Global_room:writeToConsole(w.."|"..n)
			singlevalue[w] = tonumber(n)
		end
	end
	return singlevalue
end

function sgs.readGeneralPairValuefromtxt()--读入ai-selector/pair-value.txt
	local value = {}
	local filename = "?../../ai-selector/pair-value.txt"
	for line in io.lines(filename) do
		local ww, nn = string.match(line, "^(%w+%s+%w+)"), string.match(line, "(%d+%s+%d+)$")
		if string.find(line,"_") then
			ww = string.match(line, "^(%w+_%w+%s+%w+)")
		end
		if string.find(line,"_*_") then
			ww = string.match(line, "^(%w+_%w+%s+%w+_%w+)")
		end
		if ww and nn then
			--Global_room:writeToConsole(ww.."|"..nn)
			local g1,g2 = string.match(ww, "^(%w+)"), string.match(ww, "(%w+)$")
			local v1,v2 = string.match(nn, "^(%d+)"), string.match(nn, "(%d+)$")
			value[g1.."+"..g2] = math.max(tonumber(v1),tonumber(v2))
		end
	end
	return value
end

--[[lua拓展的选将值
Config.value("LuaPackages", QString()).toString().split("+")
QString("extensions/ai-selector/%1-general-value.txt").arg(pack)
]]

function SmartAI:getGeneralValue(player, position)
	local general
	if position then
		general = player:getGeneral()
	else
		general = player:getGeneral2()
	end
	if general:objectName() == "anjiang" then
		if self.player:objectName() ~= player:objectName() then return 3 end
	else
		if position then
			general = player:getActualGeneral1()
		else
			general = player:getActualGeneral2()
		end
	end
	local ajust = 0
	for _, skill in sgs.qlist(general:getVisibleSkillList(true, position)) do
		if skill:getFrequency() == sgs.Skill_Limited and skill:getLimitMark() ~= "" and player:getMark(skill:getLimitMark()) == 0 then
            ajust = ajust - 1
		end
	end
	for name, value in pairs(sgs.general_value) do
		if general:objectName() == name then
			return value + ajust
		end
	end
	return 3
end

function SmartAI:needToTransform()
	local g1 = self.player:getActualGeneral1()
	local g2 = self.player:getActualGeneral2()
	local current_value = 0
	for name, value in pairs(sgs.general_pair_value) do
		if g1:objectName() .. "+" .. g2:objectName() == name or g2:objectName() .. "+" .. g1:objectName() == name then
			current_value = value
			break
		end
	end
	local oringin_g1 = 3
	local oringin_g2 = 3
	for name, value in pairs(sgs.general_value) do
		if g1:objectName() == name then oringin_g1 = value end
		if g2:objectName() == name then oringin_g2 = value end
	end
	if current_value == 0 then current_value = oringin_g1 + oringin_g2 end
	local g2_v = current_value - (oringin_g2 - self:getGeneralValue(self.player, false)) - oringin_g1
	return g2_v < 3
end

sgs.ai_skill_invoke.transform = function(self, data)
	return self:needToTransform()
end

sgs.ai_skill_choice.transform = function(self, generals)
	Global_room:writeToConsole("开始变更副将！！")
--[[
	for name, value in pairs(sgs.general_value) do
		Global_room:writeToConsole("单将表:"..sgs.Sanguosha:translate(name).."|"..value)
	end

	for pairname, value in pairs(sgs.general_pair_value) do
		Global_room:writeToConsole("配对表:"..pairname .."|".. value)
	end
]]
	generals = generals:split("+")
	for _, g2name in ipairs(generals) do
		if not sgs.general_value[g2name] then
			sgs.general_value[g2name] = 5
		end
	end

	local g1name = self.player:getActualGeneral1Name()
	local choice
	local pairvalue = 0
	local pairchoice
	for _, g2name in ipairs(generals) do
		local value_revise = 0
		local deputy = sgs.Sanguosha:getGeneral(g2name)
		if deputy:getMaxHpHead() > deputy:getMaxHpDeputy() then--有额外的副将技
			value_revise = 1
		elseif deputy:getMaxHpDeputy() >= 5 then--关羽价值8
			value_revise = -4
		end
		Global_room:writeToConsole("当前可选武将:"..sgs.Sanguosha:translate(g2name).."|"..(sgs.general_value[g2name] + value_revise))
		for pairname, value in pairs(sgs.general_pair_value) do
			if (g1name .. "+" .. g2name == pairname or g2name .. "+" .. g1name == pairname) then
				value = value + value_revise
				if value < 10 and #generals > 0 then--去掉不合适匹配武将
					table.removeOne(generals, g2name)
				elseif pairname == "xunyou+xiahouyuan" or pairname == "lvfan+sunjian"
				or pairname == "masu+menghuo" or pairname == "masu+zhurong" then--单独去掉一些选将配对值
					continue
				elseif value > pairvalue then
					Global_room:writeToConsole("与主将配对:"..pairname.."|"..value)
					pairvalue = value
					pairchoice = g2name
				end
			end
		end
	end
	local singlevalue = 0
	local singlechoice
	for _, g2name in ipairs(generals) do
		local value_revise = 0
		local deputy = sgs.Sanguosha:getGeneral(g2name)
		if deputy:getMaxHpHead() > deputy:getMaxHpDeputy() then--有额外的副将技
			value_revise = 1
		elseif deputy:getMaxHpDeputy() >= 5 then--关羽价值8
			value_revise = -4
		end
		if self:isWeak() and (g2name == "pangtong" or g2name == "xushu" or g2name == "zhoutai" or g2name == "sunce" or g2name == "lukang") then
			if sgs.general_value[g2name] and sgs.general_value[g2name] + 2 + value_revise > singlevalue then
				singlevalue = sgs.general_value[g2name] + 2 + value_revise
				singlechoice = g2name--残血优先选庞统和周泰等，"zhoutai"和"xiaoqiao"本身就很高，是否去掉？
			end
		end
		if sgs.general_value[g2name] and sgs.general_value[g2name] + value_revise > singlevalue then
			singlevalue = sgs.general_value[g2name] + value_revise
			singlechoice = g2name
		end
	end
	if pairchoice and sgs.general_value[g1name] and sgs.general_value[g1name] + singlevalue + 5 <= pairvalue then
		choice = pairchoice--无法解决选将配对值不适合变将的情况，如荀攸+夏侯渊，和配对值为5的情况。只能单独去除
	else
		choice = singlechoice
	end
	if choice then
		Global_room:writeToConsole("变更副将选择:"..sgs.Sanguosha:translate(choice))
		return choice
	end
	Global_room:writeToConsole("随机变更副将！！")
	return generals[math.random(1,#generals)]
end