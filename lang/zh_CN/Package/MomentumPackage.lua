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

-- translation for Hegemony Momentum Package

return {
	["momentum"] = "君临天下·势",
	["momentum_equip"] = "君临天下·势",

	["#lidian"] = "深明大义",
	["lidian"] = "李典",
	["illustrator:lidian"] = "张帅",
	["xunxun"] = "恂恂",
	[":xunxun"] = "摸牌阶段开始时，你可将牌堆顶的四张牌扣置入处理区（对你可见）▶你将其中两张牌置于牌堆顶，将其余的牌置于牌堆底。",
	["@xunxun"] = "请拖拽排列卡牌",
	["xunxun#up"] = "置于牌堆底",
	["xunxun#down"] = "置于牌堆顶",
	["#XunxunResult"] = "%from 的“<font color=\"yellow\"><b>恂恂</b></font>”结果：<font color=\"yellow\"><b>2</b></font> 上 <font color=\"yellow\"><b>2</b></font> 下",
	["wangxi"] = "忘隙",
	[":wangxi"] = "当你对其他角色造成1点伤害后，或受到其他角色造成的1点伤害后，若其存活，你可令你与其各摸一张牌。",

	["#zangba"] = "节度青徐",
	["zangba"] = "臧霸",
	["illustrator:zangba"] = "HOOO",
	["hengjiang"] = "横江",
	[":hengjiang"] = "当你受到1点伤害后，若当前回合角色的手牌上限大于0，你可令其手牌上限于此回合内-1→此回合结束前，若其存活且{其未于弃牌阶段内弃置过其牌或跳过弃牌阶段}，你摸一张牌。",
	["@hengjiang"] = "横江",
	["#HengjiangDraw"] = "%from 未于弃牌阶段内弃置牌，触发 %to 的“%arg”效果",
	["#hengjiang-draw"] = "横江（摸牌）",

	["#madai"] = "临危受命",
	["madai"] = "马岱",
	["illustrator:madai"] = "Thinking",
	["mashu_madai"] = "马术",
	["qianxi"] = "潜袭",
	[":qianxi"] = "准备阶段开始时，你可判定，令距离为1的一名角色于此回合内使用或打出的牌对应的所有实体牌不能均是其手牌区里的与结果颜色相同的牌。",
	["#Qianxi"] = "由于“<font color=\"yellow\"><b>潜袭</b></font>”效果，%from 本回合不能使用或打出 %arg 手牌",
	["@qianxi_red"] = "潜袭（红色）",
	["@qianxi_black"] = "潜袭（黑色）",

	["#mifuren"] = "乱世沉香",
	["mifuren"] = "糜夫人",
	["illustrator:mifuren"] = "木美人",
	["guixiu"] = "闺秀",
	[":guixiu"] = "当你明置此武将牌后，你可摸两张牌。当你移除此武将牌后，你回复1点体力。",
	["guixiu:draw"] = "是否发动“闺秀”，摸两张牌",
	["guixiu:recover"] = "是否发动“闺秀”，回复1点体力",
	["cunsi"] = "存嗣",
	[":cunsi"] = "出牌阶段，若此武将牌处于明置状态，你可移除此武将牌并选择一名角色▶其获得〖勇决〗。若其不为你，其摸两张牌。",
	["yongjue"] = "勇决",
	[":yongjue"] = "当一名角色于出牌阶段内使用的【杀】结算结束后，若其与你势力相同，且此【杀】为其于此阶段内使用过的第一张牌，你令其选择是否获得此【杀】对应的所有实体牌。",
	["@yongjue-choose"] = "是否发动%src的“勇决”，收回你使用的【杀】",
	
	["#sunce"] = "江东的小霸王",
	["sunce"] = "孙策",
	["illustrator:sunce"] = "木美人",
	["jiang"] = "激昂",
	[":jiang"] = "①当【决斗】或红色【杀】指定第一个目标后，若使用者为你，你可摸一张牌。②当你成为【决斗】或红色【杀】的目标后，你可摸一张牌。",
	["yingyang"] = "鹰扬",
	[":yingyang"] = "当你拼点的牌亮出后，你可选择：1.令此牌的点数于此次拼点结算结束之前+3；2.令此牌的点数于此次拼点结算结束之前-3。",
	["jia3"] = "+3",
	["jian3"] = "-3",
	["$Yingyang"] = "%from 的拼点牌点数视为 %arg",
	["hunshang"] = "魂殇",
	[":hunshang"] = "副将技，①此武将牌上单独的阴阳鱼个数-1。②准备阶段开始时，若你的体力值为1，你于此回合内拥有〖英姿〗和〖英魂〗。",
	["yingzi_sunce"] = "英姿",
	["yinghun_sunce"] = "英魂",
	["#yinghun_sunce"] = "英魂 对 %to",
	["yinghun_sunce:d1tx"] = "令其摸 1 张牌，然后弃置 %log 张牌",
	["yinghun_sunce:dxt1"] = "令其摸 %log 张牌，然后弃置 1 张牌",

	["#chenwudongxi"] = "壮怀激烈",
	["chenwudongxi"] = "陈武＆董袭",
	["&chenwudongxi"] = "陈武董袭",
	["illustrator:chenwudongxi"] = "地狱许",
	["duanxie"] = "断绁",
	[":duanxie"] = "出牌阶段限一次，你可令一名不处于连环状态的其他角色横置。你横置。",
	["fenming"] = "奋命",
	[":fenming"] = "结束阶段开始时，若你处于连环状态，你可选择所有处于连环状态的角色，弃置这些角色的各一张牌。",
	["@fengming"] = "你处于连环状态，须弃置一张牌",

	["#dongzhuo"] = "魔王",
	["dongzhuo"] = "董卓",
	["illustrator:dongzhuo"] = "巴萨小马",
	["hengzheng"] = "横征",
	[":hengzheng"] = "摸牌阶段开始时，若你的体力值为1或你没有手牌，且有区域里有牌的其他角色，你可令额定摸牌数改为0并选择所有其他角色▶你获得这些角色各自区域里的一张牌。",
	["baoling"] = "暴凌",
	[":baoling"] = "主将技，锁定技，出牌阶段结束时，若此武将牌处于明置状态且你有副将，你移除副将的武将牌，加3点体力上限，回复3点体力，获得〖崩坏〗。",
	["benghuai"] = "崩坏",
	[":benghuai"] = "锁定技，结束阶段开始时，若你不是体力值最小的角色，你选择：1.失去1点体力；2.减1点体力上限。",
	["benghuai:hp"] = "减少体力" ,
	["benghuai:maxhp"] = "减少上限" ,

	["#zhangren"] = "索命神射",
	["zhangren"] = "张任",
	["illustrator:zhangren"] = "DH",
	["chuanxin"] = "穿心",
	[":chuanxin"] = "当你于出牌阶段内因执行你使用的【杀】或【决斗】的效果而对一名角色造成伤害时，若其与你势力不同或若你明置后会与其势力不同，且其有副将，你可防止此伤害▶其选择：1.弃置装备区里的所有牌▶其失去1点体力；2.{移除副将的武将牌。若此武将牌上标识的姓名为“周泰”且其体力值为0，其进入濒死状态。}。",
	["@chuanxin-choose"] = "穿心：请选择弃置所有装备并失去1点体力或移除副将",
	["chuanxin:discard"] = "弃置装备",
	["chuanxin:remove"] = "移除副将",
	["fengshi"] = "锋矢",
	[":fengshi"] = "阵法技，当【杀】指定目标后，若使用者是你为围攻角色的围攻关系中的一名围攻角色且此目标对应的角色是此围攻关系中的被围攻角色，你令此目标对应的角色弃置装备区里的一张牌。",
	["@fengshi-discard"] = "%src 的“锋矢”被触发，你需弃置装备区里的一张牌。" ,
	["FengshiSummon"] = "锋矢",

	["#lord_zhangjiao"] = "时代的先驱",
	["lord_zhangjiao"] = "张角-君",
	["&lord_zhangjiao"] = "张角" ,
	["illustrator:lord_zhangjiao"] = "青骑士",
	["wuxin"] = "悟心",
	[":wuxin"] = "摸牌阶段开始时，你可观看牌堆顶的X张牌（X为群势力角色数）并可改变这些牌的顺序。",
	["hongfa"] = "弘法",
	[":hongfa"] = "君主技，锁定技，①你拥有\"黄巾天兵符\"；" ..
				  "②准备阶段开始时，若没有“天兵”，你将牌堆顶的X张牌置于武将牌上（均称为“天兵”）（X为群势力角色数）。",
	["heavenly_army"] = "天兵",
	
	["huangjinsymbol"] = "黄巾天兵符",
	[":huangjinsymbol"] = "①你执行的效果中的\"群势力角色数\"+X（X为\"天兵\"数）。" ..
				          "②当你的失去体力结算开始前，若有“天兵”，你可终止此失去体力流程.你将一张“天兵”置入弃牌堆。" ..
				          "③与你势力相同的角色可以将一张\"天兵\"当【杀】使用或打出。",
	
	["&huangjinsymbol"] = "你可以将一张\"天兵\"当【杀】使用或打出。",
	["#HongfaTianbing"] = "%from 发动了“<font color=\"yellow\"><b>黄巾天兵符</b></font>”的效果，令群势力角色数%arg",
	["wendao"] = "问道",
	[":wendao"] = "出牌阶段限一次，你可弃置一张红色牌▶你获得弃牌堆里或一名角色的装备区里的【太平要术】。",
	["@huangjinsymbol-prevent"] = "你可以发动“弘法”，移去一张“天兵”，防止此次失去体力",
	["@hongfa-tianbing"] = "<font color='#ffcc33'><b>%src</b></font> 你可以发动“弘法”，令“群势力角色数”+X",
	["~hongfa2"] = "选择X张\"天兵\"→点击确定",

	["PeaceSpell"] = "太平要术",
	[":PeaceSpell"] = "装备牌·防具\n\n技能：\n" ..
					"1. 锁定技，当你受到属性伤害时，你防止此伤害。\n" ..
					"2. 锁定技，与你势力相同的角色的手牌上限＋X（X为与你势力相同的角色数）。\n" ..
					"3. 锁定技，当你失去装备区里的【太平要术】后，若你的体力值大于1，你失去1点体力，然后摸两张牌。\n" ,
	["#PeaceSpellNatureDamage"] = "【<font color=\"yellow\"><b>太平要术</b></font>】的效果被触发，防止了 %from 对 %to 造成的 %arg 点 %arg2 伤害" ,
	["#PeaceSpellLost"] = "%from 失去了装备区中的【<font color=\"yellow\"><b>太平要术</b></font>】，须失去1点体力并摸两张牌" ,
}
