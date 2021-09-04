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

--王平

--法正
sgs.ai_skill_invoke.enyuan = function(self, data)
	--[[if not self:willShowForDefence() then
    return false
  end]]--
  local from = data:toPlayer()
  --[[if not from then return false end]]--
	return not self:isFriend(from)
end

sgs.ai_skill_exchange.enyuan = function(self,pattern,max_num,min_num,expand_pile)
  if self.player:isKongcheng() then
    return {}
end
  local cards = self.player:getHandcards() -- 获得所有手牌
  cards=sgs.QList2Table(cards) -- 将列表转换为表
  self:sortByKeepValue(cards) -- 按保留值排序
  if cards[1]:isKindOf("Peach") then
    local fazheng = sgs.findPlayerByShownSkillName("enyuan")
    if self:isFriend(fazheng) then
      return cards[1]:getId()
    end
    return {}
  end
  return cards[1]:getId()
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
  if self.player:getHp() < 3 or self.player:getHandcardNum() > 3 or no_friend then
    return true
  end
  return false
end

sgs.ai_skill_cardask["@keshou"] = function(self, data, pattern, target, target2)
	if self.player:getHandcardNum() < 2 then--缺手牌
    return "."
  end
    local cards = self.player:getHandcards() -- 获得所有手牌
    cards=sgs.QList2Table(cards) -- 将列表转换为表
    if self.player:getHandcardNum() == 2  then--两张手牌的情况
      if cards[1]:sameColorWith(cards[2]) and not cards[1]:isKindOf("Peach") and not cards[2]:isKindOf("Peach") then
        return "$" .. table.concat(cards, "+")
      end
    else--三张及以上手牌
      self:sortByKeepValue(cards) -- 按保留值排序
      local keshou_cards = {}
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

sgs.ai_skill_invoke.congjian = function(self, data)
  if self:getPhase() ~= sgs.Player_NotActive then
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
