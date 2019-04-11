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

-- translation for Standard General Package

return {
	["transformation"] = "君临天下·变",
	["transformation_equip"] = "君临天下·变",

	--魏
	["#xunyou"] = "曹魏的谋主",
	["xunyou"] = "荀攸",
	["designer:xunyou"] = "淬毒",
	["illustrator:xunyou"] = "心中一凛",
	["qice"] = "奇策",
	[":qice"] = "出牌阶段限一次，若此武将牌处于明置状态，你可将所有手牌当任意额定目标数下限不大于你的手牌数的普通锦囊牌使用→当此牌结算完成后，你可变更。",
	["zhiyu"] = "智愚",
	[":zhiyu"] = "当你受到伤害后，你可摸一张牌▶你展示所有手牌。若你以此法展示的这些牌颜色均相同，来源弃置一张手牌。",

	["bianhuanghou"] = "卞夫人",
	["#bianhuanghou"] = "奕世之雍容",
	["illustrator:bianhuanghou"] = "雪君S",
	["wanwei"] = "挽危",
	[":wanwei"] = "当确定你因其他角色的弃置/获得而移动的牌时，若你的能被该角色弃置/获得的牌数大于X，你可将此次移动的牌改为你的X张牌（X为此次移动的牌数）。",
	["@wanwei"] = "挽危：请选择你要失去的 %arg 张牌",
	["yuejian"] = "约俭",
	[":yuejian"] = "锁定技，一名角色的弃牌阶段开始时，若其与你势力相同且于此回合内未对与你势力不同的角色使用过牌，你令其手牌上限于此回合内为X（X为其体力上限）。",

	-- 群
	["lijueguosi"] = "李傕＆郭汜",
	["#lijueguosi"] = "犯祚倾祸",
	["&lijueguosi"] = "李傕郭汜",
	["illustrator:lijueguosi"] = "旭",
	["xiongsuan"] = "凶算",
	[":xiongsuan"] = "限定技，出牌阶段，你可弃置一张手牌并选择与你势力相同的一名角色▶你对其造成1点伤害，摸三张牌，选择其一个已发动过的限定技→此回合结束前，你令此技能于此局游戏内的发动次数上限+1。",
	["@xiongsuan-reset"] = "凶算：请重置%dest的一项技能",
	["#XiongsuanReset"] = "%from 重置了限定技“%arg”",
	
	["#zuoci"] = "谜之仙人",
	["zuoci"] = "左慈",
	["illustrator:zuoci"] = "吕阳",
	["huashen"] = "化身",
	["huashencard"] = "化身",
	[":huashen"] = "准备阶段开始时，若“化身”数：小于2，你可随机观看武将牌堆里的五张牌，并将其中两张作为“化身”；大于1，你可将一张“化身”置入武将牌堆并获得一张“化身”。你能发动“化身”上的未带有技能标签的触发类技能，这些技能均会增加“展示并将此‘化身’置入武将牌堆并令所有‘化身’的技能于此时机无效”的消耗。",
	["xinsheng"] = "新生",
	[":xinsheng"] = "当你受到伤害后，你可获得一张“化身”。",
	["#dropHuashenDetail"] = "%from 丢弃了“化身牌” %arg",
	["#GetHuashenDetail"] = "%from 获得了“化身牌” %arg",
	["#VeiwHuashenDetail"] = "%from 正在观看武将牌堆的 %arg",
	["#dropHuashen"] = "%from 丢弃了 %arg 张“化身牌”",
	["#GetHuashen"] = "%from 获得了 %arg 张“化身牌”",
	["#VeiwHuashen"] = "%from 正在观看武将牌堆的 %arg 张牌",

	-- 蜀
	["shamoke"] = "沙摩柯",
	["#shamoke"] = "五溪蛮王",
	["illustrator:shamoke"] = "LiuHeng",
	["jili"] = "蒺藜",
	[":jili"] = "当牌被使用/打出时，若使用/打出者为你且你于当前回合内使用与打出过的牌数之和为X，你摸X张牌（X为你的攻击范围）。",

	["masu"] = "马谡",
	["#masu"] = "帷幄经谋",
	["illustrator:masu"] = "蚂蚁君",
	["sanyao"] = "散谣",
	[":sanyao"] = "出牌阶段限一次，你可弃置一张牌并选择一名体力值最大的角色▶你对其造成1点普通伤害。",
	["zhiman"] = "制蛮",
	[":zhiman"] = "当你对其他角色造成伤害时，你可防止此伤害▶你获得其装备区或判定区里的一张牌。若其与你势力相同，其可变更。",
	["#Zhiman"] = "%from 防止了对 %to 的伤害",
	["zhiman-second"] = "制蛮",

	-- 吴
	["#lingtong"] = "豪情烈胆",
	["lingtong"] = "凌统",
	["illustrator:lingtong"] = "F.源",
	["xuanlue"] = "旋略",
	[":xuanlue"] = "当你失去装备区里的牌后，你可弃置一名其他角色的一张牌。",
	["xuanlue-invoke"] = "你可以发动“旋略”，弃置一名角色一张牌",
	["yongjin"] = "勇进",
	[":yongjin"] = "限定技，出牌阶段，你可将一名角色的装备区里的一张牌置入另一名角色的装备区▶你可将一名角色的装备区里的一张牌置入另一名角色的装备区▷你可将一名角色的装备区里的一张牌置入另一名角色的装备区。",
	["@brave"] = "勇",
	["@yongjin-next"] = "勇进：你可以移动场上的一张装备牌",
	["~yongjin_next"] = "选择一名装备区有牌的角色→选择装备牌移动的目标角色→点确定",

	["lvfan"] = "吕范",
	["#lvfan"] = "忠篆亮直",
	["illustrator:lvfan"] = "铭zmy",
	["diaodu"] = "调度",
	["diaoduequip"] = "调度",
	[":diaodu"] = "出牌阶段限一次，你可令与你势力相同的所有角色选择：1.使用装备牌；2.将装备区里的一张牌置入与你势力相同的一名角色的装备区。",
	["@Diaodu-distribute"] = "使用一张装备牌，或将装备区一张牌移动至另一名同势力角色的装备区",
	["~diaodu_equip"] = "选择一张手牌中的装备牌，或选择装备区的一张牌和一名与你同势力的其他角色",
	["$DiaoduEquip"] = "%from 被装备了 %card",
	["diancai"] = "典财",
	[":diancai"] = "其他角色的出牌阶段结束时，若你于此阶段内失去过至少X张牌（X为你的体力值且至少为1），你可将你的手牌补至Y张（Y为你的体力上限）▶你可变更。",

	["#lord_sunquan"] = "虎踞江东",
	["lord_sunquan"] = "孙权-君",
	["&lord_sunquan"] = "孙权",
	["illustrator:lord_sunquan"] = "瞌瞌一休",
	["jiahe"] = "嘉禾",
	[":jiahe"] = "君主技，锁定技，你拥有“缘江烽火图”。",
	["lianzi"] = "敛资",
	[":lianzi"] = "出牌阶段限一次，你可弃置一张手牌▶你亮出牌堆顶的X张牌（X为所有吴势力角色的装备区里的牌数与“烽火”数之和），获得你以此法亮出的这些牌中的所有你以此法弃置的牌类别相同的牌。若你以此法得到的牌数大于3，你失去〖敛资〗，获得〖制衡〗。",
	["jubao"] = "聚宝",
	[":jubao"] = "锁定技，①其他角色不能获得你的装备区里的宝物牌。②结束阶段开始时，若有装备区里有【定澜夜明珠】的角色或弃牌堆里有【定澜夜明珠】，你摸一张牌，然后获得其一张牌。",
	["@lianzi"] = "选择并获得与你弃置的牌相同类别的牌",
	["lianzi#up"] = "牌堆",
	["lianzi#down"] = "获得",
	["flamemap"] = "缘江烽火图",
	["flame_map"] = "烽火",
	[":flamemap"] = "①一名吴势力角色的出牌阶段限一次，其可以将一张装备牌置于“缘江烽火图”上，称为“烽火”。\n" ..
					"②一名吴势力角色的准备阶段开始时，其角色可根据“烽火”的数量选择并获得一项技能直到回合结束:一张或以上，英姿；两张或以上，好施；三张或以上，涉猎；四张或以上，度势；五张或以上，可以额外选择一项。\n" ..
					"③当你受到渠道为【杀】或锦囊牌的伤害后，你将一张“烽火”置入弃牌堆\n" ,
	["&flamemap"] = "出牌阶段限一次，你可以将一张装备牌置于“缘江烽火图”上，称为“烽火”。",
	["@flamemap"] = "缘江烽火图：请选择要弃置的“烽火”",
	["@flamemap-choose"] = "缘江烽火图：请选择要获得的技能",
	["yingzi_flamemap"] = "英姿",
	["haoshi_flamemap"] = "好施",
	["duoshi_flamemap"] = "度势",
	
	["#haoshi_flamemap-give"] = "好施[给牌]",
	
	["shelie"] = "涉猎",
	[":shelie"] = "摸牌阶段开始时，你可令额定摸牌数改为0▶你亮出牌堆顶的五张牌，获得其中每种花色的牌各一张。",
	["@shelie"] = "请选择每种花色的牌各一张，其余的弃置",
	["shelie#up"] = "置入弃牌堆",
	["shelie#down"] = "获得的牌",

	["LuminousPearl"] = "定澜夜明珠",
	[":LuminousPearl"] = "装备牌·宝物\n\n技能：\n" ..
	                     "锁定技，若你：没有〖制衡〗，你拥有〖制衡〗；有〖制衡〗，你将你的〖制衡〗改为{出牌阶段限一次，你可弃置至少一张牌，摸等量的牌。}。",
	["zhihenglp"] = "制衡",

	["transform"] = "变更",
	["@transform-ask"] = "%arg：是否变更副将",
	["GameRule:ShowGeneral"] = "选择需要明置的武将",
}