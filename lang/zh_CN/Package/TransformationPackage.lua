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
	[":qice"] = "出牌阶段限一次，若此武将牌处于明置状态，你可将所有手牌当任意额定目标数下限不大于你的手牌数的普通锦囊牌使用▶你可变更。",
	["zhiyu"] = "智愚",
	[":zhiyu"] = "当你受到伤害后，你可摸一张牌▶你展示所有手牌。若你以此法展示的这些牌颜色均相同，来源弃置一张手牌。",

	["bianhuanghou"] = "卞夫人",
	["#bianhuanghou"] = "奕世之雍容",
	["illustrator:bianhuanghou"] = "雪君S",
	["wanwei"] = "挽危",
	[":wanwei"] = "当确定你因其他角色的弃置/获得而移动的牌时，若你的能被该角色弃置/获得的牌数大于X，你可将此次移动的牌改为你的X张牌（X为此次移动的牌数）。",
	["@wanwei-dismantle"] = "挽危：选择被 %src 弃置的 %arg 张牌",
	["@wanwei-extraction"] = "挽危：选择被 %src 获得的 %arg 张牌",
	["yuejian"] = "约俭",
	[":yuejian"] = "锁定技，一名角色的弃牌阶段开始时，若其与你势力相同且于此回合内未对其他势力角色使用过牌，你令其手牌上限于此回合内为X（X为其体力上限）。",

	-- 群
	["lijueguosi"] = "李傕＆郭汜",
	["#lijueguosi"] = "犯祚倾祸",
	["designer:lijueguosi"] = "千幻",
	["&lijueguosi"] = "李傕郭汜",
	["illustrator:lijueguosi"] = "旭",
	["xiongsuan"] = "凶算",
	[":xiongsuan"] = "限定技，出牌阶段，你可弃置一张手牌并选择与你势力相同的一名角色▶你对其造成1点伤害，摸三张牌，选择其一个已发动过的限定技→此回合结束前，你令此技能于此局游戏内的发动次数上限+1。",
	["@xiongsuan-reset"] = "凶算：请重置%dest的一项技能",
	["#XiongsuanReset"] = "%from 重置了限定技“%arg”",
	

	["huashencard"] = "魂",
	["#new_zuoci"] = "鬼影神道",
	["new_zuoci"] = "左慈",
	["designer:new_zuoci"] = "逍遥鱼叔",
	["illustrator:new_zuoci"] = "吕阳",
	["yigui"] = "役鬼",
	[":yigui"] = "①当你明置此武将牌后，若你未发动过此技能，你随机将武将牌堆里的两张牌扣置于武将牌上（称为“魂”）。"..
	"②当你需要使用与你于当前回合内以此法使用过的牌的牌名均不同的除【闪】外的基本牌/除【无懈可击】外的普通锦囊牌时，你可将一张“魂”置入武将牌堆▶你"..
	"使用无对应的实体牌的此基本牌/普通锦囊牌（有势力且与你以此法置入武将牌堆的“魂”代表的武将牌势力不同的角色不是你以此法使用的牌的合法目标）。",
	["jihun"] = "汲魂",
	[":jihun"] = "①当你受到伤害后，你可随机将武将牌堆里的一张牌扣置于武将牌上（称为“魂”）。"..
	"②当一名角色的濒死结算结束后，若其与你势力不同且存活，你可随机将武将牌堆里的一张牌扣置于武将牌上（称为“魂”）。",
	
	["#dropHuashenDetail"] = "%from 丢弃了“魂” %arg",
	["#GetHuashenDetail"] = "%from 获得了“魂” %arg",
	["#VeiwHuashenDetail"] = "%from 正在观看武将牌堆的 %arg",
	["#dropHuashen"] = "%from 丢弃了 %arg 张“魂”",
	["#GetHuashen"] = "%from 获得了 %arg 张“魂”",
	["#VeiwHuashen"] = "%from 正在观看武将牌堆的 %arg 张牌",



	-- 蜀
	["shamoke"] = "沙摩柯",
	["#shamoke"] = "五溪蛮王",
	["illustrator:shamoke"] = "LiuHeng",
	["designer:shamoke"] = "韩旭",
	["jili"] = "蒺藜",
	[":jili"] = "当牌被使用/打出时，若使用/打出者为你且你于当前回合内使用与打出过的牌数之和为X，你摸X张牌（X为你的攻击范围）。",

	["masu"] = "马谡",
	["#masu"] = "帷幄经谋",
	["designer:masu"] = "点点",
	["illustrator:masu"] = "蚂蚁君",
	["sanyao"] = "散谣",
	[":sanyao"] = "出牌阶段限一次，你可弃置一张牌并选择一名体力值最大的角色▶你对其造成1点普通伤害。",
	["zhiman"] = "制蛮",
	[":zhiman"] = "当你对其他角色造成伤害时，你可防止此伤害▶你获得其装备区或判定区里的一张牌。若其与你势力相同，你可令其选择是否变更。",
	["#Zhiman"] = "%from 防止了对 %to 的伤害",
	["@zhiman-ask"] = "是否令其发动变更",
	["zhiman-second"] = "制蛮",

	-- 吴
	["#lingtong"] = "豪情烈胆",
	["lingtong"] = "凌统",
	["designer:lingtong"] = "韩旭",
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
	["#lvfan"] = "忠笃亮直",
	["designer:lvfan"] = "韩旭",
	["illustrator:lvfan"] = "铭zmy",
	["diaodu"] = "调度",
	["#diaodu-draw"] = "调度",
	[":diaodu"] = "①出牌阶段开始时，你可获得与你势力相同的一名角色装备区里的一张牌▶若其：为你，你将此牌交给一名角色；不为你，你可将此牌交给另一名角色。②当一名角色使用不为【诏书】的装备牌时，若其与你势力相同，（你令）其可摸一张牌。",
	["@diaodu"] = "是否发动“调度”，获得一名同势力角色的一张装备牌",
	["@diaodu-give"] = "调度：将手牌中的【%arg】交给一名角色",
	["@diaodu-draw"] = "是否发动%src的“调度”，摸一张牌",
	["diancai"] = "典财",
	[":diancai"] = "其他角色的出牌阶段结束时，若你于此阶段内失去过至少X张牌（X为你的体力值且至少为1），你可将你的手牌补至Y张（Y为你的体力上限）▶你可变更。",

	["#lord_sunquan"] = "虎踞江东",
	["lord_sunquan"] = "君·孙权",
	["designer:lord_sunquan"] = "韩旭",
	["&lord_sunquan"] = "孙权",
	["illustrator:lord_sunquan"] = "瞌瞌一休",
	["jiahe"] = "嘉禾",
	[":jiahe"] = "君主技，锁定技，你拥有\"缘江烽火图\"。\n\n#\"缘江烽火图\"\n" ..
					"①一名吴势力角色的出牌阶段限一次，其可以将一张装备牌置于“缘江烽火图”上，称为“烽火”。\n" ..
					"②一名吴势力角色的准备阶段开始时，其角色可根据“烽火”的数量选择并获得一项技能直到回合结束:一张或以上，英姿；两张或以上，好施；三张或以上，涉猎；四张或以上，度势；五张或以上，可以额外选择一项。\n" ..
					"③当你受到渠道为【杀】或锦囊牌的伤害后，你将一张“烽火”置入弃牌堆。",	
					
	["lianzi"] = "敛资",
	[":lianzi"] = "出牌阶段限一次，你可弃置一张手牌▶你亮出牌堆顶的X张牌（X为所有吴势力角色的装备区里的牌数与“烽火”数之和），获得你以此法亮出的这些牌中的所有你以此法弃置的牌类别相同的牌。若你以此法得到的牌数大于3，你失去〖敛资〗，获得〖制衡〗。",
	["jubao"] = "聚宝",
	[":jubao"] = "锁定技，①当有牌因与其他角色的获得而移动前，你取消你的装备区里的宝物牌的此次移动。②结束阶段开始时，若有装备区里有【定澜夜明珠】的角色或弃牌堆里有【定澜夜明珠】，你摸一张牌，然后获得其一张牌。",
	["@lianzi"] = "选择并获得与你弃置的牌相同类别的牌",
	["lianzi#up"] = "牌堆",
	["lianzi#down"] = "获得",
	["flamemap"] = "缘江烽火图",
	["flame_map"] = "烽火",
	[":flamemap"] = "①一名吴势力角色的出牌阶段限一次，其可以将一张装备牌置于“缘江烽火图”上，称为“烽火”。\n" ..
					"②一名吴势力角色的准备阶段开始时，其角色可根据“烽火”的数量选择并获得一项技能直到回合结束:一张或以上，英姿；两张或以上，好施；三张或以上，涉猎；四张或以上，度势；五张或以上，可以额外选择一项。\n" ..
					"③当你受到渠道为【杀】或锦囊牌的伤害后，你将一张“烽火”置入弃牌堆。\n" ,
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