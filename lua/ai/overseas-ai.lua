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
--海外版专属

--卑弥呼
local guishu_skill = {}
guishu_skill.name = "guishu"
table.insert(sgs.ai_skills, guishu_skill)
guishu_skill.getTurnUseCard = function(self)
    local spadecards = {}
    local cards = self.player:getHandcards()
    for _, id in sgs.qlist(self.player:getHandPile()) do
        cards:prepend(sgs.Sanguosha:getCard(id))
    end
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards, true)
	local trickcards = {"befriend_attacking","known_both"}--有优先顺序
    local index = 3 - self.player:getMark("GuishuCardState")
    if index == 3 then--初始状态
        index = 1
    end
    for _, card in ipairs(cards) do
		if card:getSuit() == sgs.Card_Spade then
            local guishucard = sgs.cloneCard(trickcards[index], card:getSuit(), card:getNumber())
			guishucard:setCanRecast(false)
			if not self.player:isCardLimited(guishucard, sgs.Card_MethodUse) then--提前判断,防止出现被破阵无限鬼术循环
				table.insert(spadecards, card)
			end
        end
    end
    if #spadecards == 0 then
        return
    end
    
    if trickcards[index] == "known_both" and self:getUseValue(spadecards[1]) > sgs.ai_use_value.KnownBoth then
        return--#spadecards < 2 每回合不重置
    end
    --Global_room:writeToConsole("鬼术卡类型:"..trickcards[index])
    return sgs.Card_Parse("@GuishuCard=" ..  spadecards[1]:getEffectiveId() .. ":" .. trickcards[index])
end

sgs.ai_skill_use_func.GuishuCard = function(card, use, self)
	local userstring = card:toString()
	userstring = (userstring:split(":"))[3]
    local guishucard = sgs.cloneCard(userstring, card:getSuit(), card:getNumber())
    guishucard:setCanRecast(false)
    if self.player:isCardLimited(guishucard, sgs.Card_MethodUse) then
        return
    end
    self:useCardByClassName(guishucard, use)--确保能使用
    if use.card then--and use.to and not use.to:isEmpty() 如果有use.to会使用虚拟牌，为何？
		Global_room:writeToConsole("鬼术卡使用:"..userstring)
		use.card = card
	end
end

sgs.ai_use_priority.GuishuCard = sgs.ai_use_priority.BefriendAttacking + 0.1
sgs.ai_use_value.GuishuCard = sgs.ai_use_value.BefriendAttacking

sgs.guishu_suit_value = {
	spade = 3.9
}

sgs.ai_skill_invoke.yuanyu = true

--曹真
sgs.ai_skill_invoke.sidi = function(self, data)
    if not self:willShowForDefence() then
        return false
    end
    local target = data:toPlayer()
    if not self:isFriend(target) then
        return true
    end
    local num = 0
    for _, card in sgs.qlist(target:getHandcards()) do
		if not sgs.cardIsVisible(card, target, self.player)
        or not (isCard("Peach", card, self.player) or (card:isKindOf("Analeptic") and target:getHp() == 1)) then
			num = num + 1
		end
	end
    if self:needToThrowArmor(target) then
        num = num + 1
    end
    if target:getWeapon() and target:getOffensiveHorse() then
        num = num + 1
    end
    if num == 0 then
        return false
    end
    return true
end

sgs.ai_skill_exchange.sidi = function(self,pattern,max_num,min_num,expand_pile)
    self.sidi_recover = nil
    self.sidi_skill = nil
    self.sidi_cardtype = nil

    local drivecards = {}
    local drivetypes = {}
    for _, id in sgs.qlist(self.player:getPile(expand_pile)) do--"drive"
        local card = sgs.Sanguosha:getCard(id)
        table.insert(drivecards, card)
        table.insert(drivetypes, sgs.ai_type_name[card:getTypeId() + 1])
    end

    local current = self.room:getCurrent()
    if self:isFriend(current) then
        self:sort(self.friends_noself, "hp")--从小到大排序--self.friends
        for _, friend in ipairs(self.friends_noself) do
            if self.player:isFriendWith(friend) and friend:getHp() == 1 then
                self.sidi_recover = true
                for _, c in ipairs(drivecards) do
                    if sgs.ai_type_name[c:getTypeId() + 1] == "EquipCard" then
                        return c:getId()
                    end
                end
                return drivecards[1]:getId()
            end
        end
    end
--禁卡
	if self:isEnemy(current) and (not self:willSkipPlayPhase(current) or self.player:getPile("drive"):length() > 2) then
		if getCardsNum("TrickCard", current, self.player) > (current:hasShownSkill("jizhi") and 1 or 2)
        or (current:hasShownSkills("guose|luanji|guishu") and current:getHandcardNum() > 1)
        or (current:hasShownSkill("jixi") and current:getPile("field"):length() > 1)
        or (current:hasShownSkills("qice|yigui")) then
            if table.contains(drivetypes, "TrickCard") then
                self.sidi_cardtype = "TrickCard"
            end
        end
        if current:hasShownSkills("diaodu+xiaoji|diaodu+xuanlue") then
            if table.contains(drivetypes, "EquipCard") then
                self.sidi_cardtype = "EquipCard"
            end
        end
        if (current:getHp() == 1 and self:isWeak(current) and current:getMark("GlobalBattleRoyalMode") == 0)
        or ((self:hasCrossbowEffect(current) or current:hasShownSkills(sgs.force_slash_skill))
                and getCardsNum("Slash", current, self.player) >= 1) then
            if table.contains(drivetypes, "BasicCard") then
                self.sidi_cardtype = "BasicCard"
            end
        end
        for _, friend in ipairs(self.friends) do
            if current:canSlash(friend, nil, true) and sgs.getDefenseSlash(friend, self) <= 2 then
                if table.contains(drivetypes, "BasicCard") then
                    self.sidi_cardtype = "BasicCard"
                end
                break
            end
        end
	end
--技能
	local need_limit = nil
	if current:hasShownSkill("suzhi") then
		need_limit = "suzhi"
	elseif current:hasShownSkill("jianglve") and current:getMark("@strategy") > 0 then
		need_limit = "jianglve"
	elseif current:hasShownSkill("miewu") and current:getMark("#wuku") > 0 and current:getCardCount(true) > 0 then
		if (not self.sidi_cardtype or self.sidi_cardtype ~= "TrickCard") then
			need_limit = "miewu"
		end
	elseif current:hasShownSkill("tongdu") and self:getOverflow(current) > 1 then
		need_limit = "tongdu"
	elseif current:hasShownSkill("jinwu") and current:hasShownSkill("zhuke") then
		need_limit = "jinwu"
	end
    if self:isEnemy(current) and (self.player:getPile("drive"):length() >= 2 or not self:willSkipPlayPhase(current)) then--禁技能单独考虑,例如灭吴没禁锦囊时
		local wansha_limit = true
		if current:hasShownSkill("wansha") then
			local possible_peach = 0
			for _, friend in ipairs(self.friends_noself) do
				if (self:getKnownNum(friend) == friend:getHandcardNum() and getCardsNum("Peach", friend, self.player) == 0)
					or (self:playerGetRound(friend) < self:playerGetRound(self.player)) then
				elseif sgs.card_lack[friend:objectName()]["Peach"] == 1 then
				elseif friend:getHandcardNum() > 0 or getCardsNum("Peach", friend, self.player) > 0 then
					possible_peach = possible_peach + getCardsNum("Peach", friend, self.player)
				end
			end
			if self:getCardsNum("Peach") + possible_peach <= 0 then wansha_limit = false end
		end
		local function findskill(skills)
            for _, skill in ipairs(skills:split("|")) do
                if current:hasShownSkill(skill) then
                    if skill == "miewu" and current:getMark("#wuku") == 0 then continue end
					if skill == "tongdu" and self:getOverflow(current) <= 1 then continue end
					if skill == "wansha" and not wansha_limit then continue end
					return skill
                end
            end
            return nil
        end
        local sidi_firstskills =--注意有优先顺序
                "suzhi|jinghe|miewu|jieyue|jili|tongdu|chuli|wansha|zaoyun|jinfa|yingzi_zhouyu|zhukou|boyan"
        self.sidi_skill = findskill(sidi_firstskills)
        if current:hasShownSkills(sgs.lose_equip_skill.."|diaodu") and (not self.sidi_cardtype or self.sidi_cardtype ~= "EquipCard") then
            
        end
        if current:hasShownSkills("luanji|guose|jixi|qice|yigui|guishu") and (not self.sidi_cardtype or self.sidi_cardtype ~= "TrickCard") then
            self.sidi_skill = findskill("luanji|guose|jixi|qice|yigui|guishu")
        end
        if current:hasShownSkills("paoxiao|kuanggu|kuangcai") and (not self.sidi_cardtype or self.sidi_cardtype ~= "BasicCard") then
            self.sidi_skill = findskill("paoxiao|kuanggu|kuangcai")
        end
        if current:hasShownSkill("hongfa") and current:getPile("heavenly_army"):isEmpty()
        and self.player:getPlayerNumWithSameKingdom("AI", "qun") > 1 then
            self.sidi_skill = "hongfa"
        end
        if current:hasShownSkill("jiahe") and not current:getPile("flame_map"):isEmpty() then
            self.sidi_skill = "jiahe"
        end
        if current:hasShownSkill("zisui") and current:getPile("&disloyalty"):length() > 2 then
            self.sidi_skill = "zisui"
        end
        if current:hasShownSkill("xiongnve") and current:getMark("#massacre") > (self:isWeak(current) and 1 or 3) then
            self.sidi_skill = "xiongnve"
        end
        if current:hasShownSkill("paiyi") and current:getPile("power_pile"):length() > 3 then
            self.sidi_skill = "paiyi"
        end
		if need_limit then self.sidi_skill = need_limit end
    end
--回复
    local weis = {}
    for _, friend in ipairs(self.friends_noself) do--self.friends
        if self.player:isFriendWith(friend) and friend:canRecover() then
            table.insert(weis, friend)
        end
    end
    if #weis > 0 then
        local allweak = true
        for _, p in ipairs(weis) do
            if p:getHp() > 2 then--not self:isWeak(p)
                allweak = false
            end
        end
        if allweak or self.player:getMark("GlobalBattleRoyalMode") > 0 then
            self.sidi_recover = true
        end
    end

    local sidi_max = (self.sidi_recover and 1 or 0) + (self.sidi_skill and 1 or 0) + (self.sidi_cardtype and 1 or 0)
    sidi_max = math.min(sidi_max, #drivecards, max_num)
    local discards = {}
    if self.sidi_cardtype then
        for _, c in ipairs(drivecards) do
            if sgs.ai_type_name[c:getTypeId() + 1] == self.sidi_cardtype then
                table.insert(discards, c:getId())
                break
            end
        end
    else
        for _, c in ipairs(drivecards) do
            if sgs.ai_type_name[c:getTypeId() + 1] ~= "BasicCard" and #discards < sidi_max then
                table.insert(discards, c:getId())
            end
        end
    end
    for _, c in ipairs(drivecards) do
        if #discards < sidi_max and not table.contains(discards, c:getId()) then
            table.insert(discards, c:getId())
        end
    end
    return discards
end

sgs.ai_skill_exchange.sidi_put = function(self,pattern,max_num,min_num,expand_pile)
    local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
    if self.player:getPhase() <= sgs.Player_Play then
		self:sortByUseValue(cards, true)
	else
		self:sortByKeepValue(cards)
	end
	--[[
    if isCard("Peach", cards[1], self.player) or (cards[1]:isKindOf("Analeptic") and self.player:getHp() == 1) then
        return {}
    end
	--]]
	for _,acard in ipairs(cards) do
		if not sgs.Sanguosha:matchExpPattern(pattern, self.player, acard) then continue end
		if (isCard("Peach", acard, self.player) and self:getCardsNum("Peach") <= 1)
			or (acard:isKindOf("Analeptic") and self.player:getHp() == 1) then return {} end
		return acard:getEffectiveId()--只考虑cards[1]？
	end
    return {}
end

sgs.ai_skill_choice["sidi_choice"] = function(self, choices, data)
    --"cardlimit" << "skilllimit" << "recover"
    --Global_room:writeToConsole("司敌选择:" .. choices)
    choices = choices:split("+")
    if self.player:getMark("GlobalBattleRoyalMode") > 0 and self.sidi_recover and table.contains(choices, "recover") then
        return "recover"
    end
    if self.sidi_cardtype and table.contains(choices, "cardlimit") then
        return "cardlimit"
    end
    if self.sidi_skill and table.contains(choices, "skilllimit") then
        return "skilllimit"
    end
    if self.sidi_recover and table.contains(choices, "recover") then
        return "recover"
    end
    return choices[math.random(1, #choices)]
end

sgs.ai_skill_playerchosen["sidi_recover"] = function(self, targets)
    Global_room:writeToConsole("司敌恢复")
    targets = sgs.QList2Table(targets)
    if self:isFriend(targets[1]) then
        self:sort(targets, "hp")
        return targets[1]
    else
        self:sort(targets, "hp", true)
        for _, p in ipairs(targets) do
            if not p:hasShownSkills(sgs.priority_skill) and p:getHp() > 1 then
                return p
            end
        end
        return targets[1]
    end
end

sgs.ai_skill_choice["sidi_skill"] = function(self, choices, data)
    Global_room:writeToConsole("司敌禁用技能选择:" .. choices)
    choices = choices:split("+")
	local skills = {}
	local current = self.room:getCurrent()
	if current then--排除断肠的技能
		for _, sk in ipairs(choices) do
			if current:hasShownSkill(sk) then
				table.insert(skills, sk)
			end
		end
		if #skills > 0 then
			choices = skills
		end
	end
    if self.sidi_skill and table.contains(choices, self.sidi_skill) then
        Global_room:writeToConsole("司敌禁用技能:"..sgs.Sanguosha:translate(self.sidi_skill))
        return self.sidi_skill
    end
    return choices[math.random(1, #choices)]
end

sgs.ai_skill_choice["sidi_cardtype"] = function(self, choices, data)
    --"BasicCard+EquipCard+TrickCard"
    --Global_room:writeToConsole("司敌禁用牌类型选择:" .. choices)
    choices = choices:split("+")
    if self.sidi_cardtype and table.contains(choices, self.sidi_cardtype) then
        Global_room:writeToConsole("司敌禁用牌类型:"..sgs.Sanguosha:translate(self.sidi_cardtype))
        return self.sidi_cardtype
    end
    return choices[math.random(1, #choices)]
end

function sgs.ai_cardneed.sidi(to, card, self)
	return to:getHandcardNum() < 2
end

sgs.ai_need_damaged.sidi = function (self, attacker, player)

end

--廖化
sgs.ai_skill_invoke.dangxian = true

--诸葛瑾
sgs.ai_skill_cardask["@huanshi-card"] = function(self, data)
	if not (self:willShowForAttack() or self:willShowForDefence()) then return "." end
	local judge = data:toJudge()
	local cards = sgs.QList2Table(self.player:getCards("he"))
	for _, id in sgs.qlist(self.player:getHandPile()) do
		table.insert(cards, 1, sgs.Sanguosha:getCard(id))
	end

	if self:needRetrial(judge) then
		local card_id = self:getRetrialCardId(cards, judge)
		if card_id ~= -1 then
			return "$" .. card_id
		end
	end
	return "."
end

function sgs.ai_cardneed.huanshi(to, card, self)
	for _, player in sgs.qlist(self.room:getAllPlayers()) do
		if self:getFinalRetrial(to) == 1 and to:isFriendWith(player) and self:isFriend(player) then
			if player:containsTrick("lightning") then
				return not (card:getSuit() == sgs.Card_Spade and card:getNumber() >= 2 and card:getNumber() <= 9)
			end
			if self:willSkipDrawPhase(player) then
				return card:getSuit() == sgs.Card_Club
			end
			if self:willSkipPlayPhase(player) then
				return card:getSuit() == sgs.Card_Heart
			end
		end
	end
end

sgs.huanshi_suit_value = {
	heart = 3.9,
	club = 2.7
}

local hongyuan_skill = {}
hongyuan_skill.name = "hongyuan"
table.insert(sgs.ai_skills, hongyuan_skill)
hongyuan_skill.getTurnUseCard = function(self)
	if self.player:isKongcheng() or self.player:hasUsed("HongyuanCard") then return end
	return sgs.Card_Parse("@HongyuanCard=.&hongyuan")
--[[使用ViewAsSkill的写法
    local Skill = sgs.Sanguosha:getViewAsSkill("hongyuan")
    if Skill:isEnabledAtPlay(self.player) then
        local hcards = sgs.QList2Table(self.player:getHandcards())
        self:sortByUseValue(hcards, true)
        local cards = sgs.CardList()
        for _, c in ipairs(hcards) do
            if Skill:viewFilter(cards, c) then
                cards:append(c)
            end
        end
        if cards:length() > 0 then
            local hycard = Skill:viewAs(cards)
            Global_room:writeToConsole("弘援合纵:"..hycard:toString())
            return hycard
        end
    end
]]
end
--room->setPlayerProperty(source, "view_as_transferable", hongyuan_ids)
sgs.ai_skill_use_func.HongyuanCard = function(hycard, use, self)
	local targets = sgs.PlayerList()
    local friends = {}
    for _, p in ipairs(self.friends_noself) do
		if self.player:isFriendWith(p) then continue end
		if hycard:targetFilter(targets, p, self.player) then
			table.insert(friends, p)
		end
	end
	if #friends > 0 then
        local cards = sgs.QList2Table(self.player:getHandcards())
	    self:sortByUseValue(cards, true)
		local to_hongyuan = {}
		for _, acard in ipairs(cards) do
			if not acard:isTransferable() then
				table.insert(to_hongyuan, acard)
			end
		end
		local card, friend = self:getCardNeedPlayer(to_hongyuan, friends, "hongyuan")
		if card and friend then
            self.hongyuan_card_id = card:getId()
			use.card = sgs.Card_Parse("@HongyuanCard=" .. card:getId() .. "&hongyuan")
            --if use.to then use.to:append(friend) end
            --Global_room:writeToConsole("弘援合纵目标:"..sgs.Sanguosha:translate(friend:getGeneralName()).."/"..sgs.Sanguosha:translate(friend:getGeneral2Name()))
            return
		end
	end
end

sgs.ai_use_priority.HongyuanCard = 3.1
sgs.ai_card_intention.HongyuanCard = -40

sgs.ai_skill_playerchosen.hongyuan = function(self, targets)
	targets = sgs.QList2Table(targets)
    self:sort(targets, "handcard")
    for _, p in ipairs(targets) do
        if p:getHandcardNum() < self.player:getHandcardNum() then
            return p
        end
    end
	return {}
end

sgs.ai_skill_invoke.mingzhe = true

--全琮
sgs.ai_skill_playerchosen.qinzhong = function(self, targets)
	targets = sgs.QList2Table(targets)					   
    self:sort(targets, "hp")
	local target = nil
	local g1name = self.player:getActualGeneral1Name()
	local reward_num = 0
	local huxun_maxhp = 0
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		reward_num = reward_num + p:getMark("#reward")
		if p:getMaxHp() > huxun_maxhp then
			huxun_maxhp = p:getMaxHp()
		end
	end
	--按双将价值换将
	local peach_num = self:getCardsNum("Peach")
	for _, p in ipairs(targets) do
		local current_value = 0
		if p:hasShownGeneral2() then
			--断肠？
			local g2name = p:getActualGeneral2Name()
			--理论上所有高收益的武将都可以不用招附(魂姿,英魂,不屈,好施)
			if g2name == "sunce" and self.player:getHp() == 1 then target = p break end
			if g2name == "sunjian" and self.player:getLostHp() >= p:getLostHp() then
				if self.player:getMaxHp() > p:getMaxHp() then target = p break 
				elseif self.player:getMaxHp() == p:getMaxHp() and self.player:getHp() <= 1 then target = p break end
			end
			if g2name == "zhoutai" and p:getPile("scars"):length() > 3 and p:getHp() + peach_num >= 2 then target = p break end
			if g2name == "lusu" and sgs.ai_skill_invoke.haoshi(self) and self.haoshi_target then target = p break end
			if g2name == "chenpu" and huxun_maxhp > p:getMaxHp() and not self:isWeak() then target = p break end
			for name, value in pairs(sgs.general_pair_value) do
				if g1name .. "+" .. g2name == name or g2name .. "+" .. g1name == name then
					current_value = value
					Global_room:writeToConsole("亲重双将("..sgs.Sanguosha:translate(g2name)..")价值:"..tostring(value))
					break
				end
			end
			if current_value > 0 then 
				target = p 
				break 
			end
		end
	end
	
	if not target then
		self:sort(targets, "defense")
		if self.player:getActualGeneral1():getKingdom() == "careerist" and not self.player:hasShownGeneral1() then
			for _, p in ipairs(targets) do
				if p:hasShownGeneral2() then
					local g2name = p:getActualGeneral2Name()
					if sgs.general_value[g2name] and sgs.general_value[g2name] > sgs.general_value["quancong"] then
						Global_room:writeToConsole("亲重抢("..sgs.Sanguosha:translate(g2name)..")价值:"..tostring(sgs.general_value[g2name]))
					end
				end
			end
		end
		if peach_num > 0 and self:getOverflow() > 0 and self.player:hasSkill("zhaofu") and reward_num < 3 then
			return nil
		else
			if self.player:hasSkill("zhaofu") and reward_num == 3 then
				for _, p in ipairs(targets) do
					if p:getState() ~= "robot" then target = p break end
				end
			end
			--替队友转移重要的副将
			if not target then
				for _, p in ipairs(targets) do
					if (p:hasShownGeneral2() or p:getMaxHp() == 3) and self:isWeak(p) and not self:isWeak() then
						local g2name = p:getActualGeneral2Name()
						if sgs.general_value[g2name] and sgs.general_value[g2name] > sgs.general_value["quancong"] then
							Global_room:writeToConsole("亲重保存("..sgs.Sanguosha:translate(g2name)..")价值:"..tostring(sgs.general_value[g2name]))
							target = p
							break
						end
					end
				end
			end
		end
	end
	return target
end

sgs.ai_skill_use["@@zhaofu1"] = function(self, prompt, method)
    if not self:willShowForAttack() then return "." end

    local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards, true)

    local card
    for _, acard in ipairs(cards) do
		if not self:isValuableCard(acard) then
			card = acard
            break
		end
	end

    local targets = {}
	local best_targets = {}
    for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
        if p:getMark("#reward") == 0 and not self:willSkipPlayPhase(p) and (p:hasShownSkills("luanji|guishu|qice|yigui") or (p:hasShownSkill("jixi") and p:getPile("field"):length() > 1) 
			or getCardsNum("TrickCard", p, self.player) >= 2 or (getCardsNum("Peach", p, self.player) > 0 and self.player:isWounded() and p:isWounded())) then
			table.insert(best_targets, p)
		else
			table.insert(targets, p) 
		end
    end
	
	if #best_targets > 0 then targets = best_targets end

    local compare_func = function(a, b)
		return (a:getHandcardNum() + math.min(1.5, a:getHp() / 2))
            > (b:getHandcardNum() + math.min(1.5, b:getHp() / 2))
	end
    table.sort(targets, compare_func)

    local target
    for _, p in ipairs(targets) do
        if not self:willSkipPlayPhase(p) then
            target = p
            break
        end
    end

    if card and target then
        return "@ZhaofuCard=" .. card:getEffectiveId() .. "->" .. target:objectName()
    end
    return "."
end

sgs.ai_skill_invoke.zhaofu = function(self, data)
	--["zhaofu:prompt"] = "是否使用“招附”，视为使用【%arg】",
    local prompt_list = data:toString():split(":")
    local card_name = prompt_list[4]
    if not card_name or card_name == "" then return false end
	local use_card = sgs.cloneCard(card_name)
	if not use_card or not use_card:isAvailable(self.player) then return false end
	Global_room:writeToConsole("招附考虑:"..use_card:objectName())
	if use_card:isKindOf("Analeptic") then return false end
	use_card:setSkillName("zhaofu")
	use_card:setCanRecast(false)
	local dummy_use = { isDummy = true }
	self:useCardByClassName(use_card, dummy_use)
	if dummy_use.card == nil then return false end--or self:getUseValue(use_card) <= 4.5
	return true
end

sgs.ai_skill_use["@@zhaofu2"] = function(self, prompt, method)
	--["@zhaofu2"] = "是否使用“招附”，视为使用【%arg】",
    local card_name = prompt:split(":")[4]
    if not card_name or card_name == "" then return "." end
	local use_card = sgs.cloneCard(card_name)
	if not use_card or not use_card:isAvailable(self.player) then return "." end
	if not (use_card:isKindOf("BasicCard") or (use_card:isNDTrick() and not use_card:isKindOf("Nullification"))) then return "." end
	if use_card:isKindOf("Jink") or use_card:isKindOf("Analeptic") or use_card:isKindOf("Nullification") then return "." end
	if use_card:isKindOf("FireAttack") or use_card:isKindOf("KnownBoth") then return "." end
	--if use_card:isKindOf("IronChain") or use_card:isKindOf("FightTogether") then return "." end
	use_card:setSkillName("_zhaofu")--执行了“招附”的效果，使用了 雷杀[无色]
	--use_card:setSkillName("zhaofu")--发动了“招附”，使用了 雷杀[无色]
	use_card:setCanRecast(false)
	local dummy_use = { isDummy = true }
	if not use_card:targetFixed() then dummy_use.to = sgs.SPlayerList() end
	if self:getUseValue(use_card) >= 5.2--更优化的值，多个赏标记时考虑杀等缺使用者信息getMark("#reward") > 0
		or use_card:isKindOf("Duel")
		or (self.player:getMark("GlobalBattleRoyalMode") > 0 and use_card:isKindOf("Slash")) then
		Global_room:writeToConsole("招附:"..card_name)
		self:useCardByClassName(use_card, dummy_use)
		if dummy_use.card and not dummy_use.to:isEmpty() then
			local target_objectname = {}
			for _, p in sgs.qlist(dummy_use.to) do
				table.insert(target_objectname, p:objectName())
			end
			return "@ZhaofuVSCard=.&->" .. table.concat(target_objectname, "+")
		end
	end
	return "."
end

--郭淮
sgs.ai_skill_playerchosen.jingce = sgs.ai_skill_playerchosen.damage--选择目标怎样合适？

sgs.ai_skill_choice.startcommand_jingce = sgs.ai_skill_choice.startcommand_to

sgs.ai_skill_choice["docommand_jingce"] = function(self, choices, data)
  local source = data:toPlayer()
  local index = self.player:getMark("command_index")
  local is_enemy = self:isEnemy(source)
  local is_friend = self:isFriend(source)
  if index == 1 then
    if not is_enemy and not is_friend then
      return "yes"
    end
    if is_friend and not self:isWeak(source) then
      for _, p in ipairs(self.enemies) do
        if p:getHp() == 1 and self:isWeak(p) and self:isEnemy(source, p) then
          return "yes"
        end
      end
    end
  end
  if index == 5 and not self.player:faceUp() then
    return "yes"
  end
  if is_enemy then
    if index == 2 then
      return "yes"
    end
    if index == 3 and self.player:hasSkill("hongfa") and not self.player:getPile("heavenly_army"):isEmpty() then
      return "yes"
    end
    if index == 4 then
      if self.player:getMark("command4_effect") > 0 then
        return "yes"
      end
      local has_peach = false
      for _, c in sgs.qlist(self.player:getHandcards()) do
        if isCard("Peach", c, self.player) then--有实体卡桃可回血
          has_peach = true
        end
      end
      if has_peach then
        for _, p in ipairs(self.friends) do
          if p:getHp() == 1 and self:isWeak(p) and source:canSlash(self.player, nil, true) then
            return "no"
          end
        end
      end
      if not source:canSlash(self.player, nil, true) then
        return "yes"
      end
    end
    if index == 6 and self.player:getEquips():length() < 3 and self.player:getHandcardNum() < 3 then
      return "yes"
    end
  end
  return "no"
end

sgs.ai_skill_playerchosen["command_jingce"] = sgs.ai_skill_playerchosen.damage

local kenshang_skill = {}
kenshang_skill.name = "kenshang"
table.insert(sgs.ai_skills, kenshang_skill)
kenshang_skill.getTurnUseCard = function(self, inclusive)
	if not self:willShowForAttack() then return end
	self.kenshang_invoke = false
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
	if self:getCardsNum("Slash") < 2 or self.player:hasSkill("paoxiao|paoxiao_xh") or (self.player:hasSkill("baolie") and self.player:getHp() < 3) then disCrossbow = true end

	local value = 0
	local damage_num = 0
	local slash = sgs.cloneCard("slash")
	if not self.player:hasWeapon("Halberd") then--方天的距离太大,复杂情况不考虑
		for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			if self.player:inMyAttackRange(p) then continue end
			if not self:slashIsEffective(slash, p) or not self.player:canSlash(p, slash, false) or self:slashProhibit(slash, p) 
				or not self:damageIsEffective(p, sgs.DamageStruct_Normal, self.player)then continue end
			if self:isEnemy(p) then
				if self:canHit(p, self.player) then 
					value = value + 2
				else
					value = value + 1
				end
				if self:isWeak(p) then value = value + 2 end
				if sgs.isGoodTarget(p, self.enemies, self) then value = value + 1 end
			elseif self:isFriend(p) then
				if self:canHit(p, self.player) then 
					value = value - 2
				else
					value = value - 1
				end
				if self:isWeak(p) then value = value - 2 end
			end
			if self:canHit(p, self.player) then 
				damage_num = damage_num + 1
				if self:hasHeavySlashDamage(self.player, slash, p) then--因为暗涌的存在,具体多少伤害很难说
					damage_num = damage_num + 1
				end
			end
		end
	end
	if value <= 0 then
		damage_num = 1 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget, self.player, slash)
		if self:hasHeavySlashDamage(self.player) then--因为暗涌的存在,具体多少伤害很难说
			damage_num = damage_num*2
		end
	else
		self.kenshang_invoke = true
	end
	
	local hecards = self.player:getCards("he")
	for _, id in sgs.qlist(self.player:getHandPile()) do
		hecards:prepend(sgs.Sanguosha:getCard(id))
	end
	--博弈(2牌打1伤无损摸1；1牌打1伤失去技能)
	--当此【杀】结算结束后，若（曾）为此【杀】对应的实体牌的牌数：＞X，你摸X张牌；≤X，你失去〖马术〗或此技能。（X为此【杀】造成过的伤害值之和）
	if damage_num >= 2 then--准备失去技能
		local cards = {}
		for _, card in sgs.qlist(hecards) do
			if ((not isCard("Peach", card, self.player) and not isCard("ExNihilo", card, self.player)) or useAll)
				and not isCard("BefriendAttacking", card, self.player) and not isCard("AllianceFeast", card, self.player)
				and (not isCard("Crossbow", card, self.player) or disCrossbow ) then
				local suit = card:getSuitString()
				local number = card:getNumberString()
				local card_id = card:getEffectiveId()
				local card_str = ("slash:kenshang[%s:%s]=%d&kenshang"):format(suit, number, card_id)
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
	elseif not self.player:hasWeapon("Spear") then--当丈八用
		local newcards = {}
		for _, card in ipairs(hecards) do
			if not isCard("Slash", card, self.player) and not isCard("Peach", card, self.player) and not isCard("AllianceFeast", card, self.player)
			and not ((isCard("ExNihilo", card, self.player) or isCard("BefriendAttacking", card, self.player)) and self.player:getPhase() == sgs.Player_Play)
			and not ((isCard("ThreatenEmperor", card, self.player)) and card:isAvailable(self.player))
			and (not isCard("Crossbow", card, self.player) or disCrossbow ) then
				table.insert(newcards, card)
			end
		end
		if #cards <= self.player:getHp() - 1 and self.player:getHp() <= 4 and not self:hasHeavySlashDamage(self.player)
		and not self.player:hasSkills("kongcheng|paoxiao") then return end
		if #newcards < 2 then return end

		local card_id1 = newcards[1]:getEffectiveId()
		local card_id2 = newcards[2]:getEffectiveId()
		
		if newcards[1]:isBlack() and newcards[2]:isBlack() then
			local black_slash = sgs.cloneCard("slash", sgs.Card_NoSuitBlack)
			local nosuit_slash = sgs.cloneCard("slash")

			self:sort(self.enemies, "defenseSlash")
			for _, enemy in ipairs(self.enemies) do
				if self.player:canSlash(enemy) and not self:slashProhibit(nosuit_slash, enemy) and self:slashIsEffective(nosuit_slash, enemy)
					and self:canAttack(enemy) and self:slashProhibit(black_slash, enemy) and self:isWeak(enemy) then
					local redcards, blackcards = {}, {}
					for _, acard in ipairs(newcards) do
						if acard:isBlack() then table.insert(blackcards, acard) else table.insert(redcards, acard) end
					end
					if #redcards == 0 then break end

					local redcard, othercard

					self:sortByUseValue(blackcards, true)
					self:sortByUseValue(redcards, true)
					redcard = redcards[1]

					othercard = #blackcards > 0 and blackcards[1] or redcards[2]
					if redcard and othercard then
						card_id1 = redcard:getEffectiveId()
						card_id2 = othercard:getEffectiveId()
						break
					end
				end
			end
		end

		local card_str = ("slash:%s[%s:%s]=%d+%d&%s"):format("kenshang", "to_be_decided", 0, card_id1, card_id2, "kenshang")
		local slash = sgs.Card_Parse(card_str)
		assert(slash)
		return slash
	end
end

function sgs.ai_cardneed.kenshang(to, card)
	return to:getHandcardNum() < 3 or card:isKindOf("Crossbow")
end

sgs.ai_skill_invoke["_kenshang"] = function(self, data)
	if self.kenshang_invoke then return true end
	--令所有不在你攻击范围内且与此【杀】的所有目标均无对应关系的角色成为此【杀】的目标（无距离关系的限制），取消所有对应的角色在你攻击范围内的目标
	local slash = sgs.cloneCard("slash")--需要当前杀信息来判断仁王盾
	local value = 0
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if self.player:inMyAttackRange(p) then continue end
		if not self:slashIsEffective(slash, p) or not self.player:canSlash(p, slash, false) or self:slashProhibit(slash, p) 
			or not self:damageIsEffective(p, sgs.DamageStruct_Normal, self.player)then continue end
		if self:isEnemy(p) then
			if self:canHit(p, self.player) then 
				value = value + 2
			else
				value = value + 1
			end
			if self:isWeak(p) then value = value + 2 end
			if sgs.isGoodTarget(p, self.enemies, self) then value = value + 1 end
		elseif self:isFriend(p) then
			if self:canHit(p, self.player) then 
				value = value - 2
			else
				value = value - 1
			end
			if self:isWeak(p) then value = value - 2 end
		end
	end
	return value > 0
end

sgs.ai_skill_choice.kenshang = function(self, choices)
	--(kenshang +mashu_maxiumatie)
	if string.find(choices, "mashu_maxiumatie") then
		if self:getCardsNum("Slash") > 2 and not self:hasCrossbowEffect() then
			if string.find(choices, "kenshang") then return "kenshang" end
		end
		return "mashu_maxiumatie"
	end
	choices = choices:split("+")
	return choices[math.random(1, #choices)]
end

--杨修
sgs.ai_skill_invoke.danlao = function(self, data)
	local use = data:toCardUse()
    local ucard = use.card
	if ucard:isKindOf("GodSalvation") and self.player:canRecover() then
		return false
    elseif ucard:isKindOf("AmazingGrace") and self:playerGetRound(self.player) < self.room:alivePlayerCount()/2 then
		return false
	elseif ucard:isKindOf("IronChain") and self.player:isChained() then
        return false
    elseif ucard:isKindOf("AwaitExhausted") and self.player:getHandcardNum() > 2
      and self:getCardsNum({"Peach", "Jink"}) == 0 then
        return false
    elseif ucard:isKindOf("AllianceFeast") and use.from == self.player then
        return false
    elseif ucard:isKindOf("Conquering") then
        return false
    elseif ucard:isKindOf("ExNihilo") or ucard:isKindOf("BefriendAttacking") then
        return false
    elseif self:isFriend(use.from) and (ucard:isKindOf("Snatch") or ucard:isKindOf("Dismantlement") or ucard:isKindOf("LureTiger")) then
        return false
	else
		return true
	end
end

sgs.ai_skill_invoke.jilei = function(self, data)
	local damage = data:toDamage()
	return not self:isFriend(damage.from)
end

sgs.ai_skill_choice.jilei = function(self, choices, data)
	local dfrom = data:toDamage().from
    local b_limited = dfrom:getMark("##jilei+BasicCard") > 0
    local t_limited = dfrom:getMark("##jilei+TrickCard") > 0
    local e_limited = dfrom:getMark("##jilei+EquipCard") > 0
    if b_limited and t_limited then
        return "EquipCard"
    elseif b_limited and e_limited then
        return "TrickCard"
    elseif t_limited and e_limited then
        return "BasicCard"
    end
    if self:slashIsAvailable(dfrom) and not b_limited then
        for _, p in ipairs(self.friends) do
            if dfrom:inMyAttackRange(p) then
                return "BasicCard"
            end
        end
    end
    if dfrom:getHp() < 2 and getCardsNum("Peach", dfrom, self.player) > 0 and not b_limited then
		return "BasicCard"
	else
		return "TrickCard"
	end
end

--祖茂
sgs.ai_skill_exchange["yinbingx"] = function(self,pattern,max_num,min_num,expand_pile)
    local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
    self:sortByKeepValue(cards)

    local result = {}
    local m_num = math.max(self:getCardsNum("Jink") + 0.5 * self:getCardsNum("Slash"), 1)--可承受的数量
    local discardEquip = false
    for _, c in ipairs(cards) do
        if discardEquip and self.room:getCardPlace(c:getEffectiveId()) == sgs.Player_PlaceEquip then
        elseif not c:isKindOf("BasicCard") and self:getKeepValue(c) < 2.5 then--详细考虑？
            table.insert(result, c:getEffectiveId())
            if self.player:hasSkills(sgs.lose_equip_skill) and self.room:getCardPlace(c:getEffectiveId()) == sgs.Player_PlaceEquip then
                discardEquip = true
            end
        end
        if #result == m_num then
            break
        end
    end
    return result
end

sgs.ai_skill_invoke.yinbingx = false

sgs.ai_skill_invoke.juedi = true

sgs.ai_skill_choice.juedi = function(self, choices, data)
    local draw_num = self.player:getMaxHp() - self.player:getHandcardNum()
    local can_give,weak_friend = false,false
    self:sort(self.friends_noself, "hp")
    for _, p in ipairs(self.friends_noself) do
        if self.player:getHp() >= p:getHp() then--考虑盟友和队友？
            if self:isWeak(p) then
                weak_friend = true
            end
            can_give = true
        end
    end
    if weak_friend and not self:isWeak() then
        return "give"
    end
    if can_give and self.player:getPile("kerchief"):length() * 2 >= draw_num then
        return "give"
    end
    if draw_num > 1  then
        return "self"
    elseif can_give then
        return "give"
    end
	return "self"
end

sgs.ai_skill_playerchosen.juedi = function(self, targets)
    targets = sgs.QList2Table(targets)
    self:sort(targets, "hp")
    for _, p in ipairs(targets) do
        if self.player:isFriendWith(p) then--canRecover?
            return p
        end
    end
    for _, p in ipairs(targets) do
        if self:isFriend(p) then
            return p
        end
    end
    return targets[#targets]
end

--伏完
sgs.ai_skill_invoke.moukui = function(self, data)
    if not self:willShowForAttack() then return false end
	local target = data:toPlayer()
	if self:isFriend(target) then
        return self:needToThrowArmor(target)
    end
    return true
end

sgs.ai_skill_choice.moukui = function(self, choices, data)
	local target = data:toPlayer()
    Global_room:writeToConsole("谋溃目标防御值：" ..sgs.getDefenseSlash(target, self))
    if not self:isFriend(target) and self:getDangerousCard(target) then
        return "discard"
    end
    if self:isFriend(target) and self:needToThrowArmor(target) then
        return "discard"
    end
	if (self:isEnemy(target) and self:doNotDiscard(target)) or sgs.getDefenseSlash(target, self) < 2 then
		return "draw"
	end
	return "discard"
end

--陈到
sgs.ai_skill_invoke.wanglie = function(self, data)
	local ucard = data:toCardUse().card
    local num = 0
    for _, c in ipairs(self:getTurnUse()) do
        if not c:isKindOf("SkillCard") then--转化成普通卡的技能卡？
            num = num + 1
        end
    end
    if num == 0 then--需要配合调整出牌优先度
        return true
    end
    if ucard:isKindOf("Slash") and ucard:hasFlag("drank")
    and (self:getOverflow() <= 1 or num <= 1) then
        return true
    end
    return false
end
--地载有时候不触发,原因未知,难道是调虎?
--围攻时,玩家的杀触发技能顺序询问(制蛮+地载),但是不触发电脑队友的ai_skill_cardask
--但是同一回合,反过来借刀电脑队友,会询问玩家地载弃牌
--sgs.ai_skill_cardask["@dizai_discard"] = function(self, data)--
sgs.ai_skill_discard.dizai_invoke = function(self, discard_num, min_num, optional, include_equip)
	--[[
	local damage = self.room:getTag("CurrentDamageStruct"):toDamage()--造成伤害时DamageCaused,没有当前伤害信息CurrentDamageStruct
	if damage.to and self:damageIsEffective_(damage) and not self.player:isNude() then
		if not self:hasHeavySlashDamage(damage.from, damage.card, damage.to) then
			if self:cantbeHurt(damage.to, damage.from, damage.damage + 1)
				or (damage.to:isChained() and not self:isGoodChainTarget_(damage))
				or damage.to:hasArmorEffect("SilverLion") then return "." end
		end
		return self:askForDiscard("dummy_reason", 1, 1, false, true)
	end
	return {}
	--]]
	return self:askForDiscard("dummy_reason", 1, 1, false, true)
end

--田豫
sgs.ai_skill_invoke.zhenxi = function(self, data)
	if not self:willShowForAttack() then return false end
	self.zhenxichoice = nil
	local target = data:toPlayer()
	if not target then return false end
	if self:isEnemy(target) then
		local cards = self.player:getCards("he")
		cards = sgs.QList2Table(cards)
		for _, id in sgs.qlist(self.player:getHandPile()) do
			table.insert(cards, sgs.Sanguosha:getCard(id))
		end
		local card = nil
		local card_name = nil
		self:sortByUseValue(cards, true)
		local target = data:toPlayer()
		for _,acard in ipairs(cards) do
			if acard:getTypeId() == sgs.Card_TypeTrick or self:isValuableCard(acard) then continue end
			local card_suit = acard:getSuit()
			if card_suit == sgs.Card_Diamond and self:getUseValue(acard) < sgs.ai_use_value.Indulgence and (self:getOverflow(target) >= 0 or self:getOverflow() > 0) then card_name = "indulgence"
			elseif card_suit == sgs.Card_Club and self:getUseValue(acard) < sgs.ai_use_value.SupplyShortage and (target:getHandcardNum() <= 2 or self:getOverflow() > 0) then card_name = "supply_shortage"
			else continue end
			local new_card = sgs.Sanguosha:cloneCard(card_name, card_suit, acard:getNumber())
			if self:trickIsEffective(new_card, target, self.player) and not target:containsTrick(card_name) then
				local shouldUse=true

				if acard:isKindOf("Armor") then
					if not self.player:getArmor() then shouldUse = false
					elseif self.player:hasEquip(acard) and not has_armor and self:evaluateArmor() > 0 then shouldUse = false
					end
				end

				if acard:isKindOf("Weapon") then
					if not self.player:getWeapon() then shouldUse = false
					elseif self.player:hasEquip(acard) and not has_weapon then shouldUse = false
					end
				end

				if not self:willShowForAttack() then
					shouldUse = false
				end

				if shouldUse then
					card = acard
					break
				end
			end
		end
		
		if card and (self:doNotDiscard(target) or self:canHit(target, self.player)) then
			self.zhenxichoice = "usecard"
			self.zhenxi_card = card
		else
			self.zhenxichoice = "discard"
		end
	elseif self:isFriend(target) then
		self.zhenxichoice = "discard"
		return self:needToThrowArmor(target) or self:doNotDiscard(target)
	end
	return not self:isFriend(target)
end

sgs.ai_skill_choice.zhenxi = function(self, choices, data)
	local target = data:toPlayer()
	if self.zhenxichoice then return self.zhenxichoice end
	choices = choices:split("+")
	return choices[math.random(1, #choices)]
end

sgs.ai_skill_choice.zhenxi_discard = function(self, choices, data)--无目标data
    return "yes"
end

sgs.ai_skill_use["@@zhenxi_trick"] = function(self, prompt, method)
    --"@zhenxi-trick::sgs3"
	local target
    local target_name = self.player:property("zhenxi_target"):toString()
    for _, p in sgs.qlist(self.room:getAlivePlayers()) do
        if p:objectName() == target_name then--prompt:split(":")[3]
            target = p
            break
        end
    end
	
    if not target or not self:isEnemy(target) then return "." end
    local card = self.zhenxi_card or nil
    self.zhenxi_card = nil

    if not card then
        local cards = self.player:getCards("he")
        for _, id in sgs.qlist(self.player:getHandPile()) do
            cards:prepend(sgs.Sanguosha:getCard(id))
        end
        cards = sgs.QList2Table(cards)
        self:sortByUseValue(cards, true)

        local need_i = self:getOverflow(target) >= 0 and not target:containsTrick("indulgence")
                and self:trickIsEffective(sgs.cloneCard("indulgence", sgs.Card_Diamond), target, self.player)
        local need_s = target:getHandcardNum() <= 2 and not target:containsTrick("supply_shortage")
                and self:trickIsEffective(sgs.cloneCard("supply_shortage", sgs.Card_Club), target, self.player)

        for _, acard in ipairs(cards) do
            if not acard:isKindOf("TrickCard") and not self:isValuableCard(acard)
            and ((need_i and acard:getSuit() == sgs.Card_Diamond) or (need_s and acard:getSuit() == sgs.Card_Club)) then
                card = acard
                break
            end
        end
    end

    if card and target then
        local suit = card:getSuitString()
        local number = card:getNumberString()
        local card_id = card:getEffectiveId()
        local card_str
        if suit == "diamond" then
            card_str = ("indulgence:_zhenxi[diamond:%s]=%d&"):format(number, card_id)
        elseif suit == "club" then
            card_str = ("supply_shortage:_zhenxi[club:%s]=%d&"):format(number, card_id)
        end
        return card_str .. "->" .. target_name
    end
    return "."
end

sgs.ai_skill_invoke.jiansu = true

sgs.ai_skill_use["@@jiansu"] = function(self, prompt, method)
    local money_cards = {}
    local str_ids = self.player:property("jiansu_record"):toString():split("+")
    for _, str_id in ipairs(str_ids) do
      table.insert(money_cards, sgs.Sanguosha:getCard(tonumber(str_id)))
    end
    self:sortByUseValue(money_cards, true)

    local value,num = 0,0
    for _, c in ipairs(money_cards) do
        local cvalue = self:getUseValue(c)
        if value + cvalue < 10 then--参考受伤时桃的值，考虑无用牌？
        --and not isCard("Peach", c, self.player) and not isCard("AllianceFeast", c, self.player)
            value = value + cvalue
            num = num + 1
        end
    end
    self:sort(self.friends, "hp")
    for _, p in ipairs(self.friends) do
        if p:getHp() <= num and self.player:isFriendWith(p) and p:canRecover() then
            local discards = {}
            for i = 1, p:getHp(), 1 do
                table.insert(discards, money_cards[i]:getEffectiveId())
            end
            return "@JiansuCard=" .. table.concat(discards, "+") .. "->" .. p:objectName()
        end
    end
    for _, p in ipairs(self.friends) do
        if p:getHp() <= num and self:isFriend(p) and self:isWeak(p) and p:canRecover() then
            local discards = {}
            for i = 1, p:getHp(), 1 do
                table.insert(discards, money_cards[i]:getEffectiveId())
            end
            return "@JiansuCard=" .. table.concat(discards, "+") .. "->" .. p:objectName()
        end
    end
    return "."
end

--马良
local mumeng_skill = {}
mumeng_skill.name = "mumeng"
table.insert(sgs.ai_skills, mumeng_skill)
mumeng_skill.getTurnUseCard = function(self, inclusive)
    if self.player:usedTimes("ViewAsSkill_mumengCard") > 0 then return end
    local cards = self.player:getCards("h")
	for _, id in sgs.qlist(self.player:getHandPile()) do
		cards:prepend(sgs.Sanguosha:getCard(id))
	end
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards, true)

    local b_card, f_card
    for _,c in ipairs(cards) do
        if c:getSuit() == sgs.Card_Heart and not isCard("Peach", c, self.player)--桃详细考虑？
        and not c:isKindOf("BefriendAttacking") and self:getUseValue(c) < sgs.ai_use_value.BefriendAttacking then
            b_card = c
            break
        end
    end
    for _,c in ipairs(cards) do
        if c:getSuit() == sgs.Card_Heart and not isCard("Peach", c, self.player)
        and not c:isKindOf("FightTogether") and self:getUseValue(c) < sgs.ai_use_value.FightTogether then
            f_card = c
            break
        end
    end
    if b_card then--暂不考虑戮力同心"fight_together"
        local suit = b_card:getSuitString()
        local number = b_card:getNumberString()
        local card_id = b_card:getEffectiveId()
        local card_str = ("befriend_attacking:mumeng[%s:%s]=%d&mumeng"):format(suit, number, card_id)
        local skillcard = sgs.Card_Parse(card_str)

        assert(skillcard)
        return skillcard
    end
end

sgs.ai_cardneed.mumeng = function(to, card, self)
	return card:getSuit() == sgs.Card_Heart
end

sgs.mumeng_suit_value = { heart = 3.9 }

sgs.ai_skill_invoke.naman = function(self, data)
    local use = data:toCardUse()
	if use and use.card and use.from then 
		Global_room:writeToConsole("Naman:"..tostring("data"))
	else
		Global_room:writeToConsole("Naman:"..tostring("nil"))
		local use = self.player:getTag("NamanUsedata"):toCardUse()
		if use and use.card and use.from then 
			Global_room:writeToConsole("NamanUsedata:"..tostring("data"))
		end
	end
	return true
end

sgs.ai_skill_playerchosen["naman_target"] = function(self, targets)
    local use = self.player:getTag("NamanUsedata"):toCardUse()
    assert(use)
    local card = use.card
    local from = use.from
	
	if not card or not from then 
		local data = self.player:getTag("NamanUsedata")
		--type(data) == "QVariant"
		Global_room:writeToConsole("NamanUsedata:"..tostring("nil"))
		return {}
	end
	
    local is_friend = self:isFriend(from)
    local tos = sgs.QList2Table(use.to)
    local targetlist = sgs.QList2Table(targets)

    if card:isKindOf("ArcheryAttack") or card:isKindOf("SavageAssault") then
        self:sort(tos, "hp")
        for _, p in ipairs(tos) do
            if self.player:isFriendWith(p) and self:aoeIsEffective(card, p, from) then
                return p
            end
        end
        for _, p in ipairs(tos) do
            if self.player:isFriendWith(p) and self:aoeIsEffective(card, p, from) then
                return p
            end
        end
    elseif card:isKindOf("GodSalvation") then
        self:sort(tos, "hp")
        for _, p in ipairs(tos) do
            if self:isEnemy(p) and self:trickIsEffective(card, p, from) then
                return p
            end
        end
        for _, p in ipairs(tos) do
            if not self:isFriend(p) and self:trickIsEffective(card, p, from) then
                return p
            end
        end
    elseif card:isKindOf("AmazingGrace") then
        self:sort(tos, "handcard")
        for _, p in ipairs(tos) do
            if self:isEnemy(p) and self:trickIsEffective(card, p, from) then
                return p
            end
        end
        for _, p in ipairs(tos) do
            if not self:isFriend(p) and self:trickIsEffective(card, p, from) then
                return p
            end
        end
    elseif card:isKindOf("AwaitExhausted") then
        if is_friend then
            return {}
        else
            return targetlist[1]
        end
    elseif card:isKindOf("IronChain") then
        self:sort(tos, "defenseSlash")
        for _, p in ipairs(tos) do
            if self:isFriend(p) and self:trickIsEffective(card, p, from) and p:isChained() then
                return p
            end
        end
        self:sort(targetlist, "defenseSlash")
        for _, p in ipairs(targetlist) do
            if not table.contains(tos, p) and not self:isFriend(p) and self:trickIsEffective(card, p, from) and not p:isChained() then
                return p
            end
        end
    elseif card:isKindOf("FightTogether") then
        self:sort(tos, "defenseSlash")
        for _, p in ipairs(tos) do
            if self:isFriend(p) and self:trickIsEffective(card, p, from) and not p:isChained() then
                return p
            end
        end
        for _, p in ipairs(tos) do
            if not self:isFriend(p) and self:trickIsEffective(card, p, from) and p:isChained() then
                return p
            end
        end
    end

    if is_friend then--调虎离山、联军等等，考虑使用和目标敌我，太复杂。暂时简单考虑
        for _, p in ipairs(targetlist) do
            if not table.contains(tos, p)
            and ((card:isKindOf("TrickCard") and self:trickIsEffective(card, p, from))
                or (card:isKindOf("Slash") and self:slashIsEffective(card, p, from))) then
                    return p
            end
        end
    else
        for _, p in ipairs(tos) do
            if self:isEnemy(p)
            and ((card:isKindOf("TrickCard") and self:trickIsEffective(card, p, from))
                or (card:isKindOf("Slash") and self:slashIsEffective(card, p, from))) then
                    return p
            end
        end
        for _, p in ipairs(tos) do
            if not self:isFriend(p)
            and ((card:isKindOf("TrickCard") and self:trickIsEffective(card, p, from))
                or (card:isKindOf("Slash") and self:slashIsEffective(card, p, from))) then
                    return p
            end
        end
    end
    return {}
end

--华雄
sgs.ai_skill_invoke.yaowu = true

sgs.ai_skill_invoke.shiyong = function(self, data)
    if self.player:inHeadSkills("baoling") and not self.player:hasShownGeneral2() then
        return false
    end
    return math.random(0,1) > 0
end

--张春华
sgs.ai_skill_playerchosen["guojue_damage"] = sgs.ai_skill_playerchosen.damage

sgs.ai_skill_invoke.guojue = function(self, data)
	local target = data:toPlayer()
    return not self:isFriend(target)
end

sgs.ai_skill_use["@@shangshi"] = function(self, prompt, method)
	local lose_hp = self.player:getLostHp()
	local current = self.room:getCurrent()
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	local saveByUse = (self.player:getPhase() <= sgs.Player_Play and not self.player:isSkipped(sgs.Player_Play))--再考虑座次判断，如队列下家、一路盟军
	local wansha = (current:hasShownSkill("wansha") and self:isWeak() and not self:isFriend(current))
	if #self.friends_noself > 0 and self.player:getHandcardNum() >= lose_hp then
		if (self:getEnemyNumBySeat(self.player, current) < (self:isWeak() and 1 or 2))--and self.room:alivePlayerCount() > 3
		or (current:getFormation():contains(self.player) and self:playerGetRound(self.player, current) > 0)
		or (self:playerGetRound(self.player, current) < 4 and self.player:getHp() > 2) then--1v1的时候？
			saveByUse = true
		end
		if saveByUse then
			--Global_room:writeToConsole(sgs.Sanguosha:translate(string.format("SEAT(%s)",self.player:getSeat())).."按使用价值弃牌")
			self:sortByUseValue(cards, true)
		elseif (self.player:hasSkill("lirang") and #self.friends_noself > 0 and self.player:willBeFriendWith(current)
			and self.player:objectName() ~= current:objectName() and current:getPhase() <= sgs.Player_Play and not current:isSkipped(sgs.Player_Play)) then
			self:sortByUseValue(cards)
		else
			self:sortByKeepValue(cards)
		end
		local acard, afriend = self:getCardNeedPlayer(cards, self.friends_noself)
		if lose_hp == 1 then
			if acard and afriend then return "@ShangshiCard=".. acard:getEffectiveId() .. "&shangshi->" .. afriend:objectName() end
		else
			local target = nil
			local to_give = {}
			if acard and afriend then
				target = afriend
				table.insert(to_give, acard:getEffectiveId())
				for _, card in ipairs(cards) do
					if #to_give >= lose_hp then break end
					if card:getEffectiveId() == acard:getEffectiveId() then continue end
					local give_card, atarget = self:getCardNeedPlayer({card}, {afriend})
					if give_card and atarget then
						table.insert(to_give, card:getEffectiveId())
					end
				end
			end
			if not wansha then
				if not target then target = self.friends_noself[1] end
				for _, card in ipairs(cards) do
					if #to_give >= lose_hp then break end
					if table.contains(to_give, card:getEffectiveId()) then continue end
					table.insert(to_give, card:getEffectiveId())
				end
			end
			if target and #to_give == lose_hp then
				return "@ShangshiCard=" .. table.concat(to_give, "+") .. "&shangshi->" .. target:objectName()
			end
		end
	end
	Global_room:writeToConsole("伤逝弃牌")
	local card_ids = self:askForDiscard("dummy_reason", 1, 1, false, true)
	return "@ShangshiCard=".. card_ids[1]
end

sgs.ai_need_damaged.shangshi = function (self, attacker, player)
	if player:isNude() then return end
	if not player:hasShownSkill("shangshi") then return end
	local need_card = false
	local current = self.room:getCurrent()
	if self:hasCrossbowEffect(current) or current:hasShownSkill("paoxiao") or current:hasFlag("shuangxiong") then need_card = true end
	if current:hasShownSkills("jieyin|jijiu") and self:getOverflow(current) <= 0 then need_card = true end
	if self:isFriend(current, player) and need_card then return true end

	if #self.friends > 0 then
		self:sort(self.friends, "hp")
		if self.friends[1]:objectName() == player:objectName() and self:isWeak(player) and getCardsNum("Peach", player, (attacker or self.player)) == 0 then return false end
		if #self.friends > 1 and self:isWeak(self.friends[2]) then return true end
	end
	return player:getHp() > 2 and sgs.turncount > 2 and #self.friends > 1
end

--刘夫人
sgs.ai_skill_invoke.zhuidu = function(self, data)
	local target = data:toPlayer()
    return not self:isFriend(target)
end

sgs.ai_skill_discard.zhuidu_discard = function(self, discard_num, min_num, optional, include_equip)
	return self:askForDiscard("dummy_reason", 1, 1, false, true)--暂时不详细考虑
end

sgs.ai_skill_choice.zhuidu_choice = function(self, choices, data)
    local damage = data:toDamage()
    if not self:damageIsEffective_(damage) then
        return "damage"
    end
    local card = damage.card
    local original_num = damage.damage
    local from = damage.from
    local target = damage.to
    if target:hasArmorEffect("SilverLion") and (not card or not card:isKindOf("Slash") or not IgnoreArmor(from, target)) then
        return "damage"
    end
    if target:hasShownSkill("gongqing") and from:getAttackRange() < 3 then
        return "damage"
    end
    --暂时不详细考虑-1伤害
    return "throw"
end

sgs.ai_skill_invoke.shigong = function(self, data)
    if not self.player:canRecover() then
		return false
	end
	
	if HasBuquEffect(self.player) or HasNiepanEffect(self.player) then return false end
	
	local current = self.room:getCurrent()
	if self:isWeak() and self.player:inDeputySkills("shigong") 
		and current and self.player:isFriendWith(current) and current:hasShownGeneral1() and not self:isWeak(current) then
		return self:getCardsNum("Peach") + self.player:getHp() < 3
	end
	
	return self:getCardsNum("Analeptic") + self:getAllPeachNum() + self.player:getHp() < 1
end

sgs.ai_skill_choice.shigong_skill = function(self, choices, data)
    Global_room:writeToConsole("示恭技能:"..choices)
    choices = choices:split("+")
    for _, skill in ipairs(choices) do
        if string.find(sgs.priority_skill, skill) then
            return skill
        end
    end
    return choices[math.random(1,#choices)]--暂时不考虑详细配合，"cancel"的情况？
end

sgs.ai_need_damaged.shigong = function(self, attacker, player)
	local current = self.room:getCurrent()
	if not current or not player:hasShownSkill("shigong") or not player:hasShownGeneral2() then return end
	if not current:isFriendWith(player) or self:isWeak(current) or not self:isWeak(player) or player:getHp() > 1 then return end
	if self:getAllPeachNum(player) + getCardsNum("Analeptic", player, self.player) > 2 then return end
	local deputy = sgs.Sanguosha:getGeneral(player:getGeneral2Name())
	local value = 0
	if deputy:objectName() ~= "sujiang" then
		for _,skill in sgs.qlist(deputy:getVisibleSkillList(true,false)) do
			if skill:isLordSkill() then continue end
			if skill:isAttachedLordSkill()then continue end
			if skill:inherits("BattleArraySkill") then continue end
			if skill:getFrequency() == sgs.Skill_Compulsory then continue end
			if skill:getFrequency() == sgs.Skill_Limited then continue end
			if skill:getFrequency() == sgs.Skill_Wake then continue end
			if not player:inDeputySkills(skill:objectName())then continue end
			value = value + 1
			if string.find(sgs.priority_skill, skill:objectName()) then
				value = value + 2
			end
		end
	end
	if value >= 3 then return true end
	if self:getAllPeachNum(player) + getCardsNum("Analeptic", player, self.player) < 2 and value > 0 then return true end
	return false
end

--伊籍
sgs.ai_skill_playerchosen.dingke = function(self, targets)
    targets = sgs.QList2Table(targets)
    self:sort(targets, "handcard")
    for _, p in ipairs(targets) do
        if p:getPhase() == sgs.Player_NotActive and self.player:isFriendWith(p) and not self:needKongcheng(p) then
            if self.player:hasSkill("shengxi") or self.player:getHandcardNum() > 2
            or (self:needKongcheng() and self.player:getHandcardNum() <= 2)
            or (not self:isWeak() and p:getHandcardNum() < 2) then
                return p
            end
        end
    end
    local current = self.room:getCurrent()
    if not self:isFriend(current) and table.contains(targets, current) then
        return current
    end
    return {}
end

sgs.ai_skill_exchange["dingke_give"] = function(self,pattern,max_num,min_num,expand_pile)
    --缺少目标信息，无法详细判断
    local cards = self.player:getCards("h")
    cards = sgs.QList2Table(cards)
    self:sortByKeepValue(cards)
    return cards[1]:getEffectiveId()
end

sgs.ai_skill_invoke.jiyuan = function(self, data)
	local target = data:toPlayer()
    return self:isFriend(target)
end

--张翼
sgs.ai_skill_invoke.kangrui = function(self, data)
    Global_room:writeToConsole("亢锐"..data:toString())
	local prompt = data:toString():split(":")
    local friend = self.room:findPlayerbyobjectName(prompt[2])
	local target = self.room:findPlayerbyobjectName(prompt[3])
    local damagecard = {"slash","fire_slash","thunder_slash","burning_camps","savage_assault","archery_attack","duel"}
    local lowvaluecard = {"collateral","known_both","fire_attack","lure_tiger","imperial_order","iron_chain"}--"snatch","dismantlement","drowning",
    if self:isWeak(target) and table.contains(damagecard, prompt[4]) then
        return false
    end
    if friend:getMaxHp() - friend:getHandcardNum() > (table.contains(lowvaluecard, prompt[4]) and 1 or 2) then--根据牌价值考虑摸2?
        return true
    end
    if self:isEnemy(target) and self:isWeak(target) then
        if target:hasArmorEffect("SilverLion") or (target:hasShownSkill("gongqing") and friend:getAttackRange() < 3) then
            return false
        end
		local damage = {}
		damage.to = target
		damage.from = friend
		damage.damage = 2
		if not self:damageIsEffective_(damage) then
            return false
        end
        local need_slashnum = getCardsNum("Slash", target, self.player) + 1
        if target:hasSkills("wushuang|wushuang_lvlingqi") then
            need_slashnum = need_slashnum * 2
        end
        if getCardsNum("Slash", friend, self.player) > need_slashnum then
            return true
        end
    end
    return false
end

sgs.ai_skill_choice.kangrui = function(self, choices, data)
    if string.find(choices, "useduel") then
        local target = data:toPlayer()
        if target:hasArmorEffect("SilverLion") or (target:hasShownSkill("gongqing") and self.player:getAttackRange() < 3) then
            return "fillhandcards"
        end
		local damage = {}
		damage.to = target
		damage.from = self.player
		damage.damage = 2
		if not self:damageIsEffective_(damage) then
            return "fillhandcards"
        end
        local need_slashnum = getCardsNum("Slash", target, self.player) + 1
        if target:hasSkills("wushuang|wushuang_lvlingqi") then
            need_slashnum = need_slashnum * 2
        end
        if self:getCardsNum("Slash") > need_slashnum  then
            Global_room:writeToConsole("亢锐被决斗")
            return "useduel"
        end
    end
    return "fillhandcards"
end

--程普
sgs.ai_skill_invoke.huxun = true

sgs.ai_skill_choice.huxun = function(self, choices, data)
    choices = choices:split("+")
    if table.contains(choices, "gainmaxhp") then
        return "gainmaxhp"
    else--暂不考虑更需要移动乐等
        return "movecard"
    end
end

sgs.ai_skill_playerchosen.huxun = sgs.ai_skill_playerchosen.yongjin

sgs.ai_skill_transfercardchosen.huxun = sgs.ai_skill_transfercardchosen.yongjin
--[[
sgs.ai_skill_playerchosen.huxun = sgs.ai_skill_playerchosen.mouduan

sgs.ai_skill_transfercardchosen.huxun = sgs.ai_skill_transfercardchosen.mouduan
--]]
--[[
sgs.ai_skill_use["@@huxun_move"] = function(self, prompt, method)
	self:updatePlayers()
	if prompt ~= "@huxun-move" then
		return "."
	end
	local MDCard = "@HuxunMoveCard=.&->"

		self:sort(self.enemies, "defense")
		for _, friend in ipairs(self.friends) do
			if not friend:getCards("j"):isEmpty() and self:getMoveCardorTarget(friend, ".") then
				self.huxuncard = self:getMoveCardorTarget(friend, "card")
				return MDCard .. friend:objectName() .. "+" .. self:getMoveCardorTarget(friend, "target"):objectName()
			end
		end

		for _, friend in ipairs(self.friends_noself) do
			if friend:hasEquip() and friend:hasShownSkills(sgs.lose_equip_skill) and self:getMoveCardorTarget(friend, ".") then
				self.huxuncard = self:getMoveCardorTarget(friend, "card")
				return MDCard .. friend:objectName() .. "+" .. self:getMoveCardorTarget(friend, "target"):objectName()
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
			self.huxuncard = self:getMoveCardorTarget(targets[#targets], "card")
			return MDCard .. targets[#targets]:objectName() .. "+" .. self:getMoveCardorTarget(targets[#targets], "target"):objectName()
		end

		if self.player:hasEquip() and self.player:hasShownSkills(sgs.lose_equip_skill) and self:getMoveCardorTarget(self.player, ".") then
			self.huxuncard = self:getMoveCardorTarget(self.player, "card","e")
			return MDCard .. self.player:objectName() .. "+" .. self:getMoveCardorTarget(self.player, "target" ,"e"):objectName()
		end

		local friends = {}--没有敌人则简单转移队友装备
		for _, friend in ipairs(self.friends) do
			if self:getMoveCardorTarget(friend, "." ,"e") then
				table.insert(friends, friend)
			end
		end

		if #friends > 0 then
			self:sort(friends, "hp", true)
			self.huxuncard = self:getMoveCardorTarget(friends[#friends], "card")
			return MDCard .. friends[#friends]:objectName() .. "+" .. self:getMoveCardorTarget(friends[#friends], "target"):objectName()
		end

	return "."
end

sgs.ai_skill_askforag["huxun"] = function(self, card_ids)
	return self.huxuncard:getId()
end
--]]
sgs.ai_skill_exchange["yuancong_give"] = function(self,pattern,max_num,min_num,expand_pile)
    local num = self:getOverflow()
    if num > 0 then
        local cards = self.player:getCards("h")
        cards = sgs.QList2Table(cards)
        self:sortByKeepValue(cards)
        return cards[num]:getEffectiveId()
    end
    local chengpu = sgs.findPlayerByShownSkillName("yuancong")
    if chengpu then
        if self.player:getHp() > 1 and self:getCardsNum("Analeptic") > 0 then
            return self:getCard("Analeptic"):getEffectiveId()
          end
        if not self:isWeak() and self:getCardsNum("Peach") > 1 then
            return self:getCard("Peach"):getEffectiveId()
        end
        local c, friend = self:getCardNeedPlayer(sgs.QList2Table(self.player:getCards("he")), {chengpu})
        if friend and friend:objectName() == chengpu:objectName() then
            return c:getEffectiveId()
        end
        if self:getCardsNum("Slash") > 0 then
            return self:getCard("Slash"):getEffectiveId()
        end
        --考虑详细锦囊等？
    end
    return {}
end

sgs.ai_skill_use["@@yuancong_usecard"] = function(self, prompt, method)
    local cards = self.player:getCards("h")
	for _, id in sgs.qlist(self.player:getHandPile()) do
		cards:prepend(sgs.Sanguosha:getCard(id))
	end
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards)

    for _, card in ipairs(cards) do
        local dummyuse = { isDummy = true }
        if not card:targetFixed() then
            dummyuse.to = sgs.SPlayerList()
        end
        local type = card:getTypeId()
        self["use" .. sgs.ai_type_name[type + 1]](self, card, dummyuse)

        Global_room:writeToConsole("元从dummyuse:"..card:objectName())
        if dummyuse.card and not card:isKindOf("Analeptic") then--详细考虑？
            Global_room:writeToConsole("元从使用牌")
            if not card:targetFixed() then
                if dummyuse.to and not dummyuse.to:isEmpty() then
                    local target_objectname = {}
                    for _, p in sgs.qlist(dummyuse.to) do
                        table.insert(target_objectname, p:objectName())
                    end
                    return card:toString() .."->" .. table.concat(target_objectname, "+")
                else
                    return "."
                end
            end
            return card:toString()--"@YuancongUseCard=".. card:getEffectiveId()--正确写法？？
        end
    end
    return "."
end

--程昱
local shefu_skill = {}
shefu_skill.name = "shefu"
table.insert(sgs.ai_skills, shefu_skill)
shefu_skill.getTurnUseCard = function(self)
    if self.player:hasUsed("ShefuCard") then return end
    if self.player:isKongcheng() then return end

    local index = self:getOverflow()
    if index > 0 or self.player:getHandcardNum() > 2 then
        local cards = self.player:getHandcards()
        cards = sgs.QList2Table(cards)
        self:sortByUseValue(cards, true)
        if index > 1 then
            return sgs.Card_Parse("@ShefuCard=" .. cards[index]:getEffectiveId() .."&shefu")
            --for i = index, 1, -1 do--考虑已有的伏兵？
            --end
        else
            return sgs.Card_Parse("@ShefuCard=" .. cards[1]:getEffectiveId() .."&shefu")
        end
    end
end

sgs.ai_skill_use_func.ShefuCard = function(card, use, self)
	use.card = card
end

sgs.ai_use_priority.ShefuCard = 0.3

sgs.ai_skill_exchange.shefu = function(self,pattern,max_num,min_num,expand_pile)
    local use = self.player:getTag("ShefuUsedata"):toCardUse()
    local response = self.player:getTag("ShefuUsedata"):toCardResponse()
    
    if use and use.card then
        local card = use.card
        local from = use.from
        local to = use.to
		Global_room:writeToConsole("设伏use:"..card:objectName())
        if card and from and self:isEnemy(from) then--考虑详细的card类型和to目标状态？
            for _, id in sgs.qlist(self.player:getPile(expand_pile)) do--"ambush"
                local c = sgs.Sanguosha:getCard(id)
                if sgs.Sanguosha:matchExpPattern(pattern,self.player,c) then
                    return c:getEffectiveId()
                end
            end
        end
    end
	
	if response and response.m_card then
        local card = response.m_card
		Global_room:writeToConsole("设伏response:"..card:objectName())
		if card and card:getEffectiveId() ~= -1 then
			local owner = self.room:getCardOwner(card:getEffectiveId())
			if owner then
				Global_room:writeToConsole("设伏response:"..owner:objectName())
			end
		end
        local who = response.m_who--响应来源(冲阵响应时的目标),被杀出闪时的出杀的人
        --if card and who and self:isEnemy(who) and (card:isKindOf("Nullification") or card:isKindOf("Jink")) then
		if card and who and self:isFriend(who) and (card:isKindOf("Nullification") or card:isKindOf("Jink")) then--self:isFriend(who)不一定对,但是isEnemy一般是错的
            for _, id in sgs.qlist(self.player:getPile(expand_pile)) do--"ambush"
                local c = sgs.Sanguosha:getCard(id)
                if sgs.Sanguosha:matchExpPattern(pattern,self.player,c) then
                    local name = sgs.Sanguosha:translate(who:getActualGeneral1Name()).."/"..sgs.Sanguosha:translate(who:getActualGeneral2Name()).."("..sgs.Sanguosha:translate(string.format("SEAT(%s)",who:getSeat()))..")"
					Global_room:writeToConsole("设伏response:"..name)
					return c:getEffectiveId()
                end
            end
        end
    end
    return {}
end

sgs.ai_skill_exchange["shefu_remove"] = function(self,pattern,max_num,min_num,expand_pile)
    local result = {}
    local ambushcards = {}
    for _, id in sgs.qlist(self.player:getPile(expand_pile)) do
        local card = sgs.Sanguosha:getCard(id)
        table.insert(ambushcards, card)
    end
    self:sortByUseValue(ambushcards, true)
    for _, c in ipairs(ambushcards) do
        if c:getTypeId() == sgs.Card_TypeEquip and not table.contains(result, c) then
            table.insert(result, c)
        end
        if #result == min_num then
            return result
        end
    end
    for _, c in ipairs(ambushcards) do
        if c:getTypeId() == sgs.Card_TypeTrick and not table.contains(result, c) then
            table.insert(result, c)
        end
        if #result == min_num then
            return result
        end
    end
    for _, c in ipairs(ambushcards) do
        if not table.contains(result, c) then
			table.insert(result, c)
		end
        if #result == min_num then
            return result
        end
    end
end

sgs.ai_skill_invoke.benyu = function(self, data)
	local damage = data:toDamage()
	if damage.from and damage.from:getHandcardNum() >= self.player:getHandcardNum() + 4 then return true end
	if not self:willShowForMasochism() then return false end
    --local target = data:toPlayer()
	return true
end

sgs.ai_skill_choice.benyu = function(self, choices, data)
    local target = data:toPlayer()
    if target and not self:isFriend(target) then
        if self.player:getHandcardNum() >= 5 then
            Global_room:writeToConsole("贲育弃牌1:"..sgs.Sanguosha:translate(target:getGeneralName()).."/"..sgs.Sanguosha:translate(target:getGeneral2Name()))
            return "discard"
        end
        if target:getHandcardNum() > 5 then
            local difference = target:getHandcardNum() - self.player:getHandcardNum()
            if (difference > 2 and self:slashIsAvailable(target)) or not self:isWeak() or self:getCardsNum({"Peach", "Analeptic"}) > 0 then
                Global_room:writeToConsole("贲育弃牌2:"..sgs.Sanguosha:translate(target:getGeneralName()).."/"..sgs.Sanguosha:translate(target:getGeneral2Name()))
                return "discard"
            end
        end
    end
    return "draw"
end

sgs.ai_skill_discard.benyu = function(self, discard_num, min_num, optional, include_equip)
	local hand_card_num = self.player:getHandcardNum()
	if min_num > hand_card_num then return {} end
	local damage = self.room:getTag("CurrentDamageStruct"):toDamage()
	if damage.from then
		if not (self:canAttack(damage.from) and self:damageIsEffective(damage.from, sgs.DamageStruct_Normal, self.player)) then return {} end
		local v = 2
		if min_num <= 2 then v = v + 1 end
		if self:isWeak(damage.from) then v = v + 1 end
		if self:needKongcheng() and hand_card_num == min_num then v = v + 1 end
		if self:isWeak() and self.player:getHp()*2 + hand_card_num - min_num <= 4 then v = v - 1 end
		if self.player:hasSkill("lirang") and #self.friends_noself > 0 then
			v = v + min_num/2
		else
			v = v - min_num 
			local important_num = hand_card_num - min_num
			for _, card in sgs.qlist(self.player:getCards("h")) do
				if self:getKeepValue(card) >= 4.1 or self:getUseValue(card) >= 6 then
					important_num = important_num - 1
					if important_num < 0 then
						v = v - 1
					end
				end
			end
		end
		Global_room:writeToConsole("贲育伤害价值:"..tostring(v))
		if v > 0 then return self:askForDiscard("dummy_reason", discard_num, min_num, false, false) end
	end
	Global_room:writeToConsole("贲育缺来源信息")
    return {}
end

sgs.ai_skill_discard.benyu_damage = function(self, discard_num, min_num, optional, include_equip)
    --缺来源信息
    return {}
end

sgs.ai_need_damaged.benyu = function(self, attacker, player)
	if not attacker or not player:hasShownSkill("benyu") then return end
	if player:getHandcardNum() < attacker:getHandcardNum() then
		if (attacker:getHandcardNum() - player:getHandcardNum()) >= 3 then
			if self:isEnemy(attacker) then return true
			else return player:getHandcardNum() < 3 end
		end
	elseif player:getHandcardNum() > attacker:getHandcardNum() then
		if not self:canAttack(attacker,player) or not sgs.isGoodTarget(attacker, self:getEnemies(attacker), self) then return end
		if self:isWeak(attacker) then return true end
	end
end

--夏侯尚
sgs.ai_skill_playerchosen.tanfeng = function(self, targets)
	local need_skip_judge = false
	local need_skip_discard = (self:getOverflow() > 1 and not self.player:hasSkills("shensu|qiaobian") and not self.player:isSkipped(sgs.Player_Discard))
	local Nullification = false
	for _, p in ipairs(self.friends) do
		if getKnownCard(p, self.player, "Nullification") > 0 then
			Nullification = true
		end
	end
	local current = self.room:getCurrent()
	local supply_shortage = (current:containsTrick("supply_shortage") and (not self:hasWizard(self.friends) or self:hasWizard(self.enemies, true)))
	local indulgence = (current:containsTrick("indulgence") and self:getFinalRetrial() ~= 1 and self:getOverflow(current) > -1)
	if (indulgence or supply_shortage) and not Nullification and not self.player:isSkipped(sgs.Player_Judge) then
		need_skip_judge = true
	end
	if need_skip_judge or need_skip_discard then
		targets = sgs.QList2Table(targets)
		self:sort(targets, "hp", true)
		for _, p in ipairs(targets) do--优先触发卖血技能
			if self:isFriend(p) and (self:needDamagedEffects(p, self.player) or self:needToLoseHp())
				and self:damageIsEffective(p, sgs.DamageStruct_Fire, self.player)then
				return p
			end
		end
		for _, p in ipairs(targets) do
			if self:isFriend(p) and not self:damageIsEffective(p, sgs.DamageStruct_Fire, self.player) then
				return p
			end
		end
		--打没有卖血技的盟军1伤是不是有点过分……
	end
	local prevent_skip = ((self.player:hasSkill("jieyue") and self.player:getHandcardNum() > 1 and not self.player:isSkipped(sgs.Player_Draw))
						or (self.player:hasSkills("wangxi|qice|mingfa|daoshu|zaoyun") and not self.player:isSkipped(sgs.Player_Play)))
	local dis_targets = {}
	for _, p in ipairs(targets) do
		if self:isFriend(p) then
			table.insert(dis_targets, p)
		elseif self:isEnemy(p) and not self:cantbeHurt(p) and self:damageIsEffective(p, sgs.DamageStruct_Fire, self.player)
			and not self:needDamagedEffects(p, self.player) and not self:needToLoseHp(p) and not prevent_skip then
			table.insert(dis_targets, p)
		end
	end
	if not next(dis_targets) then return nil end
	return self:findPlayerToDiscard("ej", false, sgs.Card_MethodDiscard, dis_targets, false)
end

sgs.ai_skill_cardchosen.tanfeng = function(self, who, flags, method, disable_list)
	--dismantlement
	local armor = who:getArmor()
	if self:isFriend(who) then
		if armor and armor:objectName() == "Vine" then return armor:getEffectiveId() end
	else
		--不弃敌人的藤甲怎么算
		if armor and armor:objectName() == "PeaceSpell" then return armor:getEffectiveId() end
	end
	return self:askForCardChosen(who, flags, "tanfeng_dismantlement", method, disable_list)
end

sgs.ai_skill_choice.tanfeng = function(self, choices)
	--(judge+draw+play+discard+finish+cancel)
	local current = self.room:getCurrent()
	if not current then return "cancel" end
	
	if self:isFriend(current) then
		local need_skip_judge = false
		local Nullification = false
		for _, p in ipairs(self.friends) do
			if getKnownCard(p, self.player, "Nullification") > 0 then
				Nullification = true
			end
		end
		local supply_shortage = (current:containsTrick("supply_shortage") and (not self:hasWizard(self.friends) or self:hasWizard(self.enemies, true)))
		local indulgence = (current:containsTrick("indulgence") and self:getFinalRetrial() ~= 1 and self:getOverflow(current) > -1)
		if (indulgence or supply_shortage) and string.find(choices, "judge") and not Nullification and not self.player:isSkipped(sgs.Player_Judge) then
			need_skip_judge = true
		end
		local is_weak = self:isWeak() and self:damageIsEffective(self.player, sgs.DamageStruct_Fire, current) 
			and not (self:needDamagedEffects(self.player, current) or self:needToLoseHp())
		if not is_weak then
			if need_skip_judge then return "judge" end
			if self:getOverflow(current) > 0 and not current:isSkipped(sgs.Player_Discard) and string.find(choices, "discard") then return "discard" end
		end
		if self:needDamagedEffects(self.player, current) or self:needToLoseHp() then
			--神速等需要判定阶段,挟天子需要弃牌阶段
			if self:getOverflow(current) > 1 and not current:isSkipped(sgs.Player_Discard) and string.find(choices, "discard") then return "discard" end
			if string.find(choices, "finish") then return "finish" end
			if not self:hasKnownSkill("shensu", current) and string.find(choices, "judge") then return "judge" end
		end
	elseif self:isEnemy(current) then
		local need_skip_draw = (current:getMark("JieyueExtraDraw") > 0 or current:hasSkill("zisui"))and string.find(choices, "draw")and not self.player:isSkipped(sgs.Player_Draw)
		local need_skip_play = self:hasKnownSkill("wangxi|qice|mingfa|daoshu|zaoyun", current)and string.find(choices, "play")and not self.player:isSkipped(sgs.Player_Play)
		if self:needDamagedEffects(self.player, current) or self:needToLoseHp() or not self:damageIsEffective(self.player, sgs.DamageStruct_Fire, current) then
			--一回合一张拆就让他拆算了
			if need_skip_play then return "play" end
			if need_skip_draw then return "draw" end
		end
	end
	return "cancel"
end

--顾雍
local lifu_skill = {}
lifu_skill.name = "lifu"
table.insert(sgs.ai_skills, lifu_skill)
lifu_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("LifuCard") or not self:willShowForAttack() then return end
	return sgs.Card_Parse("@LifuCard=.&lifu")
end

sgs.ai_skill_use_func.LifuCard = function(card, use, self)
	self:sort(self.enemies, "handcard")
	for _, enemy in ipairs(self.enemies) do
		if enemy:getHandcardNum() <= 4 and not enemy:isRemoved() and not (enemy:hasSkill("lirang") and #self.enemies > 1) then
			use.card = sgs.Card_Parse("@LifuCard=.&lifu")
			if use.to then use.to:append(enemy) end
			return
		end
	end
end
sgs.ai_skill_invoke.lifu_view = function(self, data)
	--观看牌
	local card = data:toCard()
	if card then
		Global_room:writeToConsole("lifu_view:"..tostring(card:getClassName()))
	end
	--[[
	local flag = string.format("%s_%s_%s", "visible", self.player:objectName(), target2:objectName())
	if not cards[1]:hasFlag("visible") then cards[1]:setFlags(flag) end--记录方便后续言中
	--]]
end
sgs.ai_card_intention.LifuCard = 40

sgs.ai_skill_invoke.yanzhong = function(self, data)
	if not self:willShowForAttack() then return false end
	return self:findPlayerToDiscard("h", false, sgs.Card_MethodDiscard, nil, false)
end

sgs.ai_skill_playerchosen.yanzhong = function(self, targets)
	local rand = math.random(1, 7)
	if rand == 3 then
		self.yanzhong_suit = 0
	elseif rand == 4 then
		self.yanzhong_suit = 1
	elseif rand < 3 and self.player:isWounded() then
		self.yanzhong_suit = 2
	else
		self.yanzhong_suit = 3
	end
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
	targets = sgs.QList2Table(targets)
	self:sort(targets, "handcard")
	for _, enemy in ipairs(targets) do
		if self:isEnemy(enemy) and not enemy:isKongcheng() and not self:doNotDiscard(enemy, "h") then
			known_suit[1] = getKnownCard(enemy, self.player, "spade", true, "h")
			known_suit[2] = getKnownCard(enemy, self.player, "club", true, "h")
			known_suit[3] = getKnownCard(enemy, self.player, "heart", true, "h")
			known_suit[4] = getKnownCard(enemy, self.player, "diamond", true, "h")
			for _, suit in ipairs(known_suit) do
				if suit == enemy:getHandcardNum() then--如果已知花色等于手牌数
					self.yanzhong_suit = table.indexOf(known_suit,suit) - 1
					local suit_table = {"♠", "♣", "♥", "♦"}
					local suit_str = suit_table[(self.yanzhong_suit + 1)]
					Global_room:writeToConsole("言中已知花色:"..suit_str)
					return enemy
				end
			end
		end
	end
	for _, enemy in ipairs(targets) do
		if self:isEnemy(enemy) and not enemy:isKongcheng() and not self:doNotDiscard(enemy, "h") then
			known_suit[1] = getKnownCard(enemy, self.player, "spade", true, "h")
			known_suit[2] = getKnownCard(enemy, self.player, "club", true, "h")
			known_suit[3] = getKnownCard(enemy, self.player, "heart", true, "h")
			known_suit[4] = getKnownCard(enemy, self.player, "diamond", true, "h")
			--sgs.debugFunc(self.player, 1)
			local max_suit = math.max(known_suit[1], known_suit[2], known_suit[3], known_suit[4])
			if 3*max_suit >= enemy:getHandcardNum() then--已知花色大于等于1/3
				self.yanzhong_suit = table.indexOf(known_suit,max_suit) - 1
			end
			if enemy:hasSkill("hongyan") then--针对小乔
				self.yanzhong_suit = 2
			end
			local suit_table = {"♠", "♣", "♥", "♦"}
			local suit_str = suit_table[(self.yanzhong_suit + 1)]
			Global_room:writeToConsole("言中最多的花色:数量:"..tostring(suit_str)..":"..max_suit)
			return enemy
		end
	end
	return nil
end

sgs.ai_skill_suit.yanzhong = function(self)
	--Global_room:writeToConsole("选择花色:"..self.yanzhong_suit)
	return self.yanzhong_suit
end

--李严
sgs.ai_skill_invoke.jinwu = function(self, data)
	if not self:willShowForAttack() then return false end
	local targets = sgs.SPlayerList()
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		local slash = sgs.cloneCard("slash")
		if self.player:canSlash(p, slash, false) then
			targets:append(p)
		end
	end
	local use_to = sgs.ai_skill_playerchosen.zero_card_as_slash(self, targets)
	if use_to and self:isFriend(use_to) and self:isWeak(use_to) then return false end
	if self.player:hasSkill("zhuke") then return true end--赌造成伤害的军令
	local best_target, target
	local defense = 6
	if self:getOverflow() > 0 and #self:getTurnUse() > 0 then return false end
	for _, enemy in ipairs(self.enemies) do
		local def = sgs.getDefenseSlash(enemy, self)
		local slash = sgs.cloneCard("slash")
		local eff = self:slashIsEffective(slash, enemy) and sgs.isGoodTarget(enemy, self.enemies, self)

		if not self.player:canSlash(enemy, slash, false) then
		elseif self:slashProhibit(nil, enemy) then
		elseif eff then
			if enemy:getHp() == 1 and getCardsNum("Jink", enemy, self.player) == 0 then
				best_target = enemy
				break
			end
			if def < defense then
				best_target = enemy
				defense = def
			end
			target = enemy
		end
	end
	if not best_target and not target then return false end
	local slashes = self:getCards("Slash")--能正常杀就不用神速2
	for _, slash in ipairs(slashes) do
		if not best_target and not target then break end
		if best_target then 
			if self.player:canSlash(best_target, slash, true) 
				and self:slashIsEffective(slash, best_target) 
				and not self:slashProhibit(slash, best_target) then
				best_target = nil
			end
		end
		if target then 
			if self.player:canSlash(target, slash, true) 
				and self:slashIsEffective(slash, target) 
				and not self:slashProhibit(slash, target) then
				target = nil
			end
		end
	end
	if best_target then return true end
	if target then return math.random(1,2) > 1 end
	return false
end

sgs.ai_skill_choice.startcommand_jinwu = function(self, choices, data)
    Global_room:writeToConsole("矜武选择军令:"..choices)
    choices = choices:split("+")
    if table.contains(choices, "command1") then
        return "command1"
    end
    if table.contains(choices, "command2") then
        return "command2"
    end
    self.player:setFlags("AI_BadJinwu")
    if table.contains(choices, "command5") and not self.player:faceUp() then
        return "command5"
    end
    if table.contains(choices, "command6") and self.player:getEquips():length() <= 2 and self.player:getHandcardNum() <= 2 then
        return "command6"
    end
    if table.contains(choices, "command3") and sgs.isGoodHp(self.player,self.player) and self.player:getHandcardNum() > 4 then
        return "command3"
    end
    return choices[math.random(1,#choices)]
end

sgs.ai_skill_choice.docommand_jinwu = function(self, choices, data)
    if self.player:hasSkill("zhuke") then
        return "yes"
    end
    local index = self.player:getMark("command_index")
    if index == 1 or index == 2 then
        return "yes"
    end
    if index == 3 and sgs.isGoodHp(self.player,self.player) and self.player:getHandcardNum() > 4 then
        return "yes"
    end
    if index == 5 and not self.player:faceUp() then
        return "yes"
    end
    if index == 6 and self.player:getEquips():length() <= 2 and self.player:getHandcardNum() <= 2 then
        return "yes"
    end
    self.player:setFlags("-AI_BadJinwu")
    return "no"
end

sgs.ai_skill_playerchosen["command_jinwu"] = sgs.ai_skill_playerchosen.damage

sgs.ai_skill_playerchosen["jinwu_slash"] = sgs.ai_skill_playerchosen.zero_card_as_slash

sgs.ai_skill_invoke.zhuke = function(self, data)
--缺失执行军令技能和军令几的信息
    if self.player:hasFlag("AI_BadJinwu") then
        self.player:setFlags("-AI_BadJinwu")
        return true
    end
	return false
end

sgs.ai_skill_choice.startcommand_zhuke = function(self, choices, data)
    Global_room:writeToConsole("筑科选择军令:"..choices)
    choices = choices:split("+")
    if table.contains(choices, "command1") then
        return "command1"
    end
    if table.contains(choices, "command2") then
        return "command2"
    end
--缺失执行军令技能和军令几的信息
    if table.contains(choices, "command5") and not self.player:faceUp() then
        return "command5"
    end
    if table.contains(choices, "command6") and self.player:getEquips():length() <= 2 and self.player:getHandcardNum() <= 2 then
        return "command6"
    end
    if table.contains(choices, "command3") and sgs.isGoodHp(self.player,self.player) and self.player:getHandcardNum() > 4 then
        return "command3"
    end
    return choices[math.random(1,#choices)]
end

sgs.ai_skill_playerchosen.zhuke = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets, "hp")
	return targets[1]
end

sgs.ai_skill_choice["quanjia"] = function(self, choices, data)--quanjia势力召唤
    choices = choices:split("+")
--[[
    if table.contains(choices,"show_head_general") and self.player:inHeadSkills("rende")--君主替换
      and sgs.GetConfig("EnableLordConvertion", true) and self.player:getMark("Global_RoundCount") <= 1  then
      return "show_deputy_general"
    end
]]
    if table.contains(choices,"show_both_generals") then
      local wuhu_show_head, wuhu_show_deputy = false,false
      local xuanhuo_priority = {"paoxiao", "tieqi", "kuanggu", "liegong", "wusheng", "longdan"}
      for _, skill in ipairs(xuanhuo_priority) do--有顺序优先度
        if self.player:hasSkill(skill) then
          if self.player:inHeadSkills(skill) then
            wuhu_show_deputy = true
            break
          else
            wuhu_show_head = true
            break
          end
        end
      end
      if wuhu_show_deputy then
        return "show_deputy_general"
      end
      if wuhu_show_head then
        return "show_head_general"
      end
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

--sgs.ai_skill_invoke.jutian
sgs.ai_skill_playerchosen.jutian = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets, "handcard")
	local value = 0
	local target = nil
	for _, p in ipairs(targets) do
		if self.player:isFriendWith(p) then
			if (p:getMaxHp() - p:getHandcardNum()) >= value and p:getMaxHp() > p:getHandcardNum() then
				value = p:getMaxHp() - p:getHandcardNum()
				target = p
				self.jutianchoice = "fillhandcard"
			end
		else
			if (p:getHandcardNum() - p:getHp()) > value then
				value = p:getHandcardNum() - p:getHp()
				target = p
				self.jutianchoice = "discard"
			end
		end
	end
	if target and value > 0 then return target end
	return nil
end

sgs.ai_skill_choice.jutian_choice = function(self, choices)
	choices = choices:split("+")
    if self.jutianchoice and table.contains(choices, self.jutianchoice) then
        return self.jutianchoice
    end
    return choices[math.random(1, #choices)]
end
--公孙瓒
sgs.ai_skill_invoke.qushi = function(self, data)
	if not self:willShowForAttack() then
		return false
	end
	return true
end

sgs.ai_skill_invoke.yicong = true
sgs.ai_skill_choice.yicong = function(self, choices, data)
	choices = choices:split("+")
	if table.contains(choices, "yes") then
		--local target = data:toPlayer()--依次询问义从yes
		return "yes"
    end
	return "no"
end
--陈登
sgs.ai_skill_invoke.haokui = function(self, data)
	if not self:willShowForAttack() and not self:willShowForDefence() then
		return false
	end
	return true
end

sgs.ai_skill_playerchosen.haokui_give = function(self, targets)
	targets = sgs.QList2Table(targets)
	for _, target in ipairs(targets) do
		if self:isFriend(target) then return target end
	end
	return targets[1]
end

sgs.ai_skill_playerchosen.haokui_transform = function(self, targets)
	targets = sgs.QList2Table(targets)
	local importantsklii = {"congjian", "jijiu", "qianhuan", "yigui", "shicai", "jinghe"}--还有哪些？
	for _, target in ipairs(targets) do
		local has_important = false
		local skills = sgs.QList2Table(target:getDeputySkillList(true,true,false))
		for _, skill in ipairs(skills) do
			if table.contains(importantsklii, skill:objectName()) then--重要技能
				has_important = true
				break
			end
			if skill:getFrequency() == sgs.Skill_Limited and not (skill:getLimitMark() ~= "" and self.player:getMark(skill:getLimitMark()) == 0) then--限定技未发动
				has_important = true
				break
			end
		end
		if not has_important then return target end
	end
	return nil
end

sgs.ai_skill_choice["transform_haokui"] = function(self, choices)
	Global_room:writeToConsole("袭射变更选择")
	local importantsklii = {"congjian", "jijiu", "qianhuan", "yigui", "shicai", "jinghe"}--还有哪些？
	local skills = sgs.QList2Table(self.player:getDeputySkillList(true,true,false))
	for _, skill in ipairs(skills) do
		if table.contains(importantsklii, skill:objectName()) then--重要技能
			return "no"
		end
		if skill:getFrequency() == sgs.Skill_Limited and not (skill:getLimitMark() ~= "" and self.player:getMark(skill:getLimitMark()) == 0) then--限定技未发动
			return "no"
		end
	end
	return "yes"
end
--"@haokui-hide1"
sgs.ai_skill_invoke.haokui_hide = function(self, data)
	local str = data:toString()
	if (str == "hide1" and self.player:inHeadSkills("haokui"))
		or (str == "hide2" and self.player:inDeputySkills("haokui")) then
		return true
	end
	return false
end

sgs.ai_skill_invoke.xushi = function(self, data)
	if not self:willShowForDefence() then
		return false
	end
	--local use = self.player:getTag("qianhuan_data"):toCardUse()
	local use = data:toCardUse()
	if use.to then
		local invoke = invoke_qianhuan(self, use)
		return invoke
	end
	return true
end
--石韬
sgs.ai_view_as.jiange = function(card, player, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if (card_place ~= sgs.Player_PlaceSpecial or player:getHandPile():contains(card_id)) and not card:isKindOf("BasicCard") and not card:hasFlag("using") then
		return ("slash:jiange[%s:%s]=%d&jiange"):format(suit, number, card_id)
	end
end

local jiange_skill = {}
jiange_skill.name = "jiange"
table.insert(sgs.ai_skills, jiange_skill)
jiange_skill.getTurnUseCard = function(self, inclusive)

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
	if self:getCardsNum("Slash") < 2 or self.player:hasSkill("paoxiao|paoxiao_xh") or (self.player:hasSkill("baolie") and self.player:getHp() < 3) then disCrossbow = true end

	local hecards = self.player:getCards("he")
	for _, id in sgs.qlist(self.player:getHandPile()) do
		hecards:prepend(sgs.Sanguosha:getCard(id))
	end
	local cards = {}
	for _, card in sgs.qlist(hecards) do
		if not card:isKindOf("BasicCard")
			and ((not isCard("Peach", card, self.player) and not isCard("ExNihilo", card, self.player)) or useAll)
			and not isCard("BefriendAttacking", card, self.player) and not isCard("AllianceFeast", card, self.player)
			and (not isCard("Crossbow", card, self.player) or disCrossbow ) then
			local suit = card:getSuitString()
			local number = card:getNumberString()
			local card_id = card:getEffectiveId()
			local card_str = ("slash:jiange[%s:%s]=%d&jiange"):format(suit, number, card_id)
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

function sgs.ai_cardneed.jiange(to, card)
	return (to:getHandcardNum() < 3 and not card:isKindOf("BasicCard")) or card:isKindOf("Crossbow")
end

sgs.ai_skill_invoke.qianxue = function(self, data)
	if not self:willShowForAttack() and not self:willShowForDefence() then
		return false
	end
	--return true
	return false
end

sgs.ai_skill_cardask["@qianxue-select"] = function(self, data, pattern, target, target2, arg)
	local card_ids = self.player:property("qianxue_allCards"):toString():split("+")
	if next(card_ids) and card_ids[1] ~= "" then 
		Global_room:writeToConsole(tostring(card_ids[1]))
		Global_room:writeToConsole(tostring("allCards")) 
	end
	
	--pattern = @@qianxueselect
	--local num = tonumber(arg)
	
	--return "@ShangshiCard=".. card_ids[1]
	return "."
end

sgs.ai_skill_playerchosen.xiaolian = sgs.ai_skill_playerchosen.yongjin

sgs.ai_skill_transfercardchosen.xiaolian = sgs.ai_skill_transfercardchosen.yongjin

sgs.ai_skill_invoke.kangkai = function(self, data)
	if not self:willShowForDefence() then return false end
	if not self.player:hasShownSkill("xiaolian") then return false end--若你未发动过孝廉
	if self:isWeak() or self.player:getActualGeneral1Name() == "xunyou" then return true end
	self:sort(self.friends, "defense")
	for _, p in ipairs(self.friends) do
		if self.player:isFriendWith(p) and self:isWeak(p)then return true end
	end
	return false
end

sgs.ai_skill_playerchosen.kangkai = function(self, targets)
	targets = sgs.QList2Table(targets)
    self:sort(targets, "defense")
	return targets[1]
end

sgs.ai_skill_invoke.nizhan = function(self, data)
	if not self:willShowForAttack() then return false end
	local current = self.room:getCurrent()
    if self:isFriend(current) then
		return self:needToThrowArmor(current)
	elseif self:needLeiji(current, self.player) or not self:slashIsEffective(sgs.cloneCard("slash"), current, self.player) then
		return false
	end
	return true
end

sgs.ai_skill_exchange.nizhan_give = function(self,pattern,max_num,min_num,expand_pile)
    local target = sgs.findPlayerByShownSkillName("nizhan")
	if not target then return {} end
	if self:needToThrowArmor() then return {self.player:getArmor():getEffectiveId()} end
	if self:needDamagedEffects(self.player, target) or self:needToLoseHp(target)then return {} end
	local slash = sgs.cloneCard("slash")
	if self:isFriend(target) or (target:canSlash(self.player, slash, false) and self:slashIsEffective(slash, self.player, target) and self:canHit(self.player, target)
		and self:damageIsEffective(self.player, sgs.DamageStruct_Normal, target) and self:isWeak() and not self:slashProhibit(slash, self.player, target)) then
		local cards = self.player:getCards("he")
		cards = sgs.QList2Table(cards)
		self:sortByKeepValue(cards)
		for _,acard in ipairs(cards) do
			--if not sgs.Sanguosha:matchExpPattern(pattern, self.player, acard) then continue end
			if (isCard("Peach", acard, self.player) and self:getCardsNum("Peach") <= 1)
				or (acard:isKindOf("Analeptic") and self.player:getHp() == 1) then return {} end
			return acard:getEffectiveId()--只考虑cards[1]？
		end
	end
    return {}
end