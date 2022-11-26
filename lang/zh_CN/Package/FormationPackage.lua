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

-- translation for Hegemony Formation Package

return {
	["formation"] = "君临天下·阵",
	["formation_equip"] = "君临天下·阵",

	["#dengai"] = "矫然的壮士",
	["dengai"] = "邓艾",
	["designer:dengai"] = "KayaK（淬毒）",
	["illustrator:dengai"] = "Amo",
	["tuntian"] = "屯田",
	[":tuntian"] = "①当你于回合外失去牌后，你可判定。若结果不为红桃，你可将弃牌堆里的此判定牌置于武将牌上（称为“田”）。②你至其他角色的距离-X（X为“田”数）。",
	["@tuntian-gotofield"] = "屯田：是否将判定牌【%arg】作为“田”" ,
	["field"] = "田",
	["#tuntian-dist"] = "屯田" ,
	["jixi"] = "急袭",
	[":jixi"] = "主将技，①此武将牌上单独的阴阳鱼个数-1。②出牌阶段，你可使用对应的实体牌为你的一张“田”的【顺手牵羊】（若〖屯田②〗有效，你于使用此牌时的合法性检测中至其他角色的距离+1）。",
	["ziliang"] = "资粮",
	[":ziliang"] = "副将技，当一名角色受到伤害后，若其与你势力相同，你可将一张“田”交给该角色。",
	["@ziliang-give"] = "你可以发动“资粮”，将一张“田”交给受到伤害的角色",
	["~ziliang"] = "选择一张\"田\"→点击确定",

	["#caohong"] = "魏之福将",
	["caohong"] = "曹洪",
	["designer:caohong"] = "韩旭（淬毒）",
	["illustrator:caohong"] = "YellowKiss",
	["huyuan"] = "护援",
	[":huyuan"] = "结束阶段开始时，你可选择：1.将一张非装备牌交给一名角色；2.{将一张装备牌置入一名角色的装备区▶你可弃置一名角色装备区或判定区里的一张牌}。",
	["@huyuan-equip"] = "你可以发动“护援”，将一张非装备牌交给一名角色，或将一张装备牌置入一名角色的装备区",
	["@huyuan-discard"] = "护援：可弃置场上的一张牌",
	["heyi"] = "鹤翼",
	[":heyi"] = "阵法技，与你处于同一队列的角色拥有〖飞影〗。",
	["HeyiSummon"] = "鹤翼",
	["#heyi_feiying"] = "飞影",
	["feiying"] = "飞影",
	[":feiying"] = "锁定技，其他角色至你的距离+1。",

	["#jiangwei"] = "龙的衣钵",
	["jiangwei"] = "姜维",
	["designer:jiangwei"] = "KayaK（淬毒）",
	["illustrator:jiangwei"] = "木美人",
	["tiaoxin"] = "挑衅",
	[":tiaoxin"] = "出牌阶段限一次，你可选择攻击范围内有你的一名角色，其需对你使用【杀】，否则你弃置其一张牌。",
	["@tiaoxin-slash"] = "%src 对你发动“挑衅”，请对其使用一张【杀】",
	["yizhi"] = "遗志",
	[":yizhi"] = "副将技，①此武将牌上单独的阴阳鱼个数-1；②若你的主将的武将牌：有〖观星〗且处于明置状态，此〖观星〗改为{准备阶段开始时，你可将牌堆顶的五张牌扣置入处理区（对你可见）▶你将其中任意数量的牌置于牌堆顶，将其余的牌置于牌堆底。}；没有〖观星〗或处于暗置状态，你拥有〖观星〗。",
	["tianfu"] = "天覆",
	[":tianfu"] = "主将技，阵法技，若有与当前回合角色处于同一队列的角色，你拥有〖看破〗。",
	["TianfuSummon"] = "天覆",
	["guanxing_jiangwei"] = "观星",

	["#jiangwanfeiyi"] = "社稷股肱",
	["jiangwanfeiyi"] = "蒋琬＆费祎",
	["designer:jiangwanfeiyi"] = "淬毒",
	["&jiangwanfeiyi"] = "蒋琬费祎",
	["illustrator:jiangwanfeiyi"] = "cometrue",
	["shengxi"] = "生息",
	[":shengxi"] = "结束阶段开始时，若你于此回合内未造成过伤害，你可摸两张牌。",
	["shoucheng"] = "守成",
	[":shoucheng"] = "当牌移动后，你可令其中至少一名于此次移动中失去过手牌且与你势力相同且不是当前回合角色且没有手牌的角色各摸一张牌。",
	["@shoucheng"] = "是否使用“守成”，选择令其摸牌的角色",

	["#jiangqin"] = "祁奚之器",
	["jiangqin"] = "蒋钦",
	["designer:jiangqin"] = "淬毒",
	["illustrator:jiangqin"] = "天空之城",
	["shangyi"] = "尚义",
	[":shangyi"] = "出牌阶段限一次，你可令一名其他角色观看你的手牌.你选择：1.观看其手牌并可弃置其中的一张黑色牌；2.观看其所有暗置的武将牌。",
	["@shangyi-choose"] = "请选择观看%dest的手牌或者武将牌",
	["shangyi:hidden_general"] = "观看武将",
	["shangyi:handcards"] = "观看手牌",
	["niaoxiang"] = "鸟翔",
	[":niaoxiang"] = "阵法技，当【杀】指定目标后，若使用者是你且此目标对应的角色与你相邻且未与任何角色处于同一队列或使用者是你为围攻角色的围攻关系中的一名围攻角色且此目标对应的角色是此围攻关系中的被围攻角色，使用者将此目标对应的角色抵消此【杀】的方式改为依次使用两张【闪】。",
	["NiaoxiangSummon"] = "鸟翔",

	["#xusheng"] = "江东的铁壁",
	["xusheng"] = "徐盛",
	["designer:xusheng"] = "淬毒",
	["illustrator:xusheng"] = "天信",
	["yicheng"] = "疑城",
	[":yicheng"] = "①当【杀】指定第一个目标后，若使用者为你或与你处于同一队列，（你令）其可摸一张牌▶其弃置一张牌。"..
		"②当一名角色成为【杀】的目标后，若其为你或与你处于同一队列，（你令）其可摸一张牌▶其弃置一张牌。",
	["@yicheng"] = "是否发动%src的“疑城”，摸一张牌并弃置一张牌",
	["#yicheng-formation"] = "疑城",

	["#yuji"] = "魂绕左右",
	["yuji"] = "于吉",
	["designer:yuji"] = "淬毒",
	["illustrator:yuji"] = "G.G.G.",
	["qianhuan"] = "千幻",
	[":qianhuan"] = "①当一名角色受到伤害后，若其与你势力相同且其存活且：有“幻”，你可将与所有“幻”花色均不相同的一张牌置于武将牌上（称为“幻”）；没有“幻”，你可将一张牌置于武将牌上（称为“幻”）。②当一名角色成为基本牌或普通锦囊牌的目标时，若其与你势力相同且目标对应的角色数为1，你可将一张“幻”置入弃牌堆▶你取消此目标。③当延时锦囊牌对应的实体牌移至一名角色的判定区前，若其与你势力相同，你可将一张“幻”置入弃牌堆▶你将此次移动的目标区域改为弃牌堆。",
	["@qianhuan-put"] = "是否发动技能“千幻”，将一张与所有“幻”花色均不同的牌置为“幻”" ,
	["sorcery"] = "幻",
	["@qianhuan-cancel"] = "你可以发动“千幻”，取消【%arg】的目标 %dest",

	["#hetaihou"] = "弄权之蛇蝎",
	["hetaihou"] = "何太后",
	["designer:hetaihou"] = "淬毒",
	["illustrator:hetaihou"] = "KayaK&木美人",
	["zhendu"] = "鸩毒",
	[":zhendu"] = "其他角色的出牌阶段开始时，若其存活，你可弃置一张手牌▶其使用无对应的实体牌的【酒】（使用方法①）▷你对其造成1点普通伤害。",
	["@zhendu-discard"] = "你可以弃置一张手牌发动“鸩毒”",
	["qiluan"] = "戚乱",
	[":qiluan"] = "一名角色的回合结束前，若你于此回合内杀死过角色，你可摸三张牌。",

	["#lord_liubei"] = "龙横蜀汉",
	["lord_liubei"] = "君·刘备",
	["designer:lord_liubei"] = "韩旭",
	["&lord_liubei"] = "刘备" ,
	["illustrator:lord_liubei"] = "LiuHeng",
	["zhangwu"] = "章武",
	["#zhangwu-draw"] = "章武[摸牌]",
	[":zhangwu"] = "锁定技，①当【飞龙夺凤】移至弃牌堆或其他角色的装备区后，你获得此【飞龙夺凤】。②当你并非因使用【飞龙夺凤】而失去【飞龙夺凤】前，你展示此【飞龙夺凤】，将此【飞龙夺凤】的此次移动的目标区域改为牌堆底→此【飞龙夺凤】移至牌堆底后，你摸两张牌。",
	["shouyue"] = "授钺",
	[":shouyue"] = "君主技，锁定技，你拥有\"五虎将大旗\"。\n\n#\"五虎将大旗\"\n" ..
					"存活的蜀势力角色拥有的〖武圣〗、〖咆哮〗、〖龙胆〗、〖铁骑〗和〖烈弓〗分别改为：\n" ..
					"武圣①——当你需要使用/打出普【杀】时，你可使用/打出对应的实体牌为你的一张牌的普【杀】。\n" ..
					"咆哮——增加“③当【杀】指定目标后，若使用者为你，你令此目标对应的角色的防具技能无效。”\n" ..  --remove the detail of Qinggang-like effect
					"龙胆——增加“③当因〖龙胆〗转化的普【杀】或【闪】被使用/打出时，若使用/打出者为你，你摸一张牌。”\n" ..
					"烈弓——增加“③你的攻击范围+1。”\n" ..
					"铁骑——当【杀】指定目标后，若使用者为你，你可判定▶你令此目标对应的角色的所有处于明置状态的武将牌的未带有“锁定技”标签的武将技能于当前回合内无效。其选择：1.弃置与结果花色相同的一张牌；2.令此【杀】于对此目标进行的使用结算中不是其使用【闪】的合法目标。",
	["jizhao"] = "激诏",
	[":jizhao"] = "限定技，当你处于濒死状态时，你可将你的手牌补至X张（X为你的体力上限），将体力回复至2点，失去〖授钺〗并获得〖仁德〗。",
	["@jizhao"] = "激诏",

	["DragonPhoenix"] = "飞龙夺凤",
	[":DragonPhoenix"] = "装备牌·武器\n\n技能：\n" ..
					"1.当【杀】指定目标后，若使用者为你，你可令此目标对应的角色弃置一张牌。\n" ..
					"2.当一名角色因执行你使用的【杀】的效果而受到你造成的伤害而进入濒死状态后，你可获得其一张手牌。\n" ,
	["@dragonphoenix-discard"] = "受到【飞龙夺凤】效果影响，请弃置一张牌",

	["DragonPhoenix:revive"] = "你可以点击下方确定按钮，从未使用的武将牌中选择与你势力相同的一张武将牌重新加入游戏。",
}