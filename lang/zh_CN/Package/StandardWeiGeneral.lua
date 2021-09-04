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

	-- 魏势力
	["#caocao"] = "魏武帝",
	["caocao"] = "曹操",
	["jianxiong"] = "奸雄",
	[":jianxiong"] = "当你受到伤害后，你可获得是此伤害的渠道的牌对应的所有实体牌。",

	["#simayi"] = "狼顾之鬼",
	["illustrator:simayi"] = "木美人",
	["simayi"] = "司马懿",
	["fankui"] = "反馈",
	[":fankui"] = "当你受到伤害后，你可获得来源的一张牌。",
	["guicai"] = "鬼才",
	[":guicai"] = "当判定结果确定前，你可打出对应的实体牌为你的一张牌且与此牌牌名相同的牌▶系统将此牌作为判定牌，将原判定牌置入弃牌堆。",
	["@guicai-card"] = CommonTranslationTable["@askforretrial"],
	["~guicai"] = "选择一张手牌→点击确定",

	["#xiahoudun"] = "独眼的罗刹",
	["illustrator:xiahoudun"] = "DH",
	["xiahoudun"] = "夏侯惇",
	["ganglie"] = "刚烈",
	[":ganglie"] = "当你受到1点伤害后，你可以判定▶若结果为：红色，你对来源造成1点伤害；黑色，你弃置来源的一张牌。",

	["#zhangliao"] = "前将军",
	["zhangliao"] = "张辽",
	["illustrator:zhangliao"] = "张帅",
	["tuxi"] = "突袭",
	[":tuxi"] = "摸牌阶段，你可令摸牌数-X并选择有手牌的X名其他角色（X至多为额定摸牌数）▶你获得这些角色的各一张手牌。",
	["@tuxi-card"] = "是否使用“突袭”，获得至多 %arg 名其他角色的手牌",
	["~tuxi"] = "选择 1-2 名其他角色→点击确定",

	["#xuchu"] = "虎痴",
	["xuchu"] = "许褚",
	["luoyi"] = "裸衣",
	[":luoyi"] = "摸牌阶段结束时，你可弃置一张牌▶当你于此回合内因执行【杀】或【决斗】的效果对一名角色造成的伤害结算开始前，若使用者为你，你令伤害值+1。",
	["#LuoyiBuff"] = "%from 的“<font color=\"yellow\"><b>裸衣</b></font>”效果被触发，伤害从 %arg 点增加至 %arg2 点",
	["@luoyi"] = "是否使用“裸衣”，选择一张牌弃置",

	["#guojia"] = "早终的先知",
	["guojia"] = "郭嘉",
	["illustrator:guojia"] = "绘聚艺堂",
	["tiandu"] = "天妒",
	[":tiandu"] = "当你的判定结果确定后，你可获得判定牌。",
	["yiji"] = "遗计",
	[":yiji"] = "当你受到伤害后，你可将牌堆顶的两张牌扣置入处理区（对你可见）▶你选择：1.将其中的一张交给一名其他角色，将另一张交给一名角色；2.将这两张牌交给一名角色。",

	["#zhenji"] = "薄幸的美人",
	["zhenji"] = "甄姬",
	["illustrator:zhenji"] = "DH",
	["luoshen"] = "洛神",
	[":luoshen"] = "准备阶段开始时，你可判定。若结果为黑色，你可重复此流程。你获得所有的黑色判定牌。",
	["#luoshen-move"] = "洛神（将此牌置于处理区）",
	["qingguo"] = "倾国",
	[":qingguo"] = "你可将一张黑色手牌当【闪】使用或打出。",

	["#xiahouyuan"] = "疾行的猎豹",
	["xiahouyuan"] = "夏侯渊",
	["shensu"] = "神速",
	[":shensu"] = "①判定阶段开始前，你可跳过此阶段和摸牌阶段并选择是你使用无对应的实体牌的普【杀】的合法目标的一名角色▶你对其使用无对应的实体牌的普【杀】。②出牌阶段开始前，你可弃置一张装备牌并选择是你使用无对应的实体牌的普【杀】的合法目标的一名角色▶你对其使用无对应的实体牌的普【杀】，跳过此阶段。",
	["@shensu1"] = "你可以跳过判定阶段和摸牌阶段发动“神速”",
	["@shensu2"] = "你可以跳过出牌阶段并弃置一张装备牌发动“神速”",
	["~shensu1"] = "选择【杀】的目标角色→点击确定",
	["~shensu2"] = "选择一张装备牌→选择【杀】的目标角色→点击确定",

	["#zhanghe"] = "料敌机先",
	["zhanghe"] = "张郃",
	["illustrator:zhanghe"] = "张帅",
	["qiaobian"] = "巧变",
	[":qiaobian"] = "①判定阶段开始前或弃牌阶段开始前，你可弃置一张手牌▶你跳过此阶段。②摸牌阶段开始前，你可弃置一张手牌▶你跳过此阶段，可选择至多两名有手牌的其他角色，获得这些角色的各一张手牌。③出牌阶段开始前，你可弃置一张手牌▶你跳过此阶段，可将一名角色的判定/装备区里的一张牌置入另一名角色的判定/装备区。",
	["@qiaobian-2"] = "你可以依次获得一至两名其他角色的各一张手牌",
	["@qiaobian-3"] = "你可以将场上的一张牌移动至另一名角色相应的区域内",
	["#qiaobian"] = "你可以弃置 1 张手牌跳过 <font color='yellow'><b> %arg </b></font> 阶段",
	["~qiaobian2"] = "选择 1-2 名其他角色→点击确定",
	["~qiaobian3"] = "选择一名角色→点击确定",
	["@qiaobian-to"] = "请选择移动【%arg】的目标角色",

	["#xuhuang"] = "周亚夫之风",
	["xuhuang"] = "徐晃",
	["illustrator:xuhuang"] = "波子",
	["duanliang"] = "断粮",
	[":duanliang"] = "你可将一张不为锦囊牌的黑色牌当【兵粮寸断】使用（无距离关系的限制），若你至目标对应的角色的距离大于2，此技能于此阶段内无效。",

	["#caoren"] = "大将军",
	["illustrator:caoren"] = "Ccat",
	["caoren"] = "曹仁",
	["jushou"] = "据守",
	[":jushou"] = "结束阶段开始时，你可摸X张牌（X为势力数），选择：1.弃置一张不为装备牌的手牌；2.使用一张对应的所有实体牌均为手牌的装备牌。若你以此法摸牌的数量大于2，叠置。",
	
	["@jushou"] = "据守：请弃置一张非装备牌；或使用一张装备牌",
	
	["#dianwei"] = "古之恶来",
	["dianwei"] = "典韦",
	["illustrator:dianwei"] = "小冷",
	["qiangxi"] = "强袭",
	[":qiangxi"] = "出牌阶段限一次，你可选择你的攻击范围内的一名角色并选择：1.失去1点体力；2.弃置一张武器牌▶你对其造成1点普通伤害。",

	["#xunyu"] = "王佐之才",
	["xunyu"] = "荀彧",
	["illustrator:xunyu"] = "LiuHeng",
	["quhu"] = "驱虎",
	[":quhu"] = "出牌阶段限一次，你可与一名体力值大于你的角色拼点。若你：赢，其对其攻击范围内你选择的一名角色造成1点普通伤害；未赢，其对你造成1点普通伤害。",
	["@quhu-damage"] = "请选择 %src 攻击范围内的一名角色",
	["jieming"] = "节命",
	[":jieming"] = "当你受到伤害后，你可令一名角色将其手牌补至X张（X为其体力上限且至多为5）。",
	["jieming-invoke"] = "你可以发动“节命”，令一名角色将手牌补至体力上限",
	["#QuhuNoWolf"] = "%from “<font color=\"yellow\"><b>驱虎</b></font>”拼点赢，由于 %to 攻击范围内没有其他角色，结算中止",

	["#caopi"] = "霸业的继承者",
	["caopi"] = "曹丕",
	["illustrator:caopi"] = "DH",
	["xingshang"] = "行殇",
	[":xingshang"] = "当其他角色死亡时，你可以获得其所有牌。",
	["fangzhu"] = "放逐",
	[":fangzhu"] = "当你受到伤害后，你可令一名其他角色选择：1.叠置▷其摸X张牌（X为你已损失的体力值）；2.弃置一张牌▷其失去1点体力。",
	["fangzhu-invoke"] = "你可以发动“放逐”，选择一名其他角色",
	["@fangzhu-discard"] = "放逐：请弃置一张牌并失去1点体力，或点“取消”叠置并摸%arg张牌",

	["#yuejin"] = "奋强突固",
	["yuejin"] = "乐进",
	["illustrator:yuejin"] = "巴萨小马",
	["xiaoguo"] = "骁果",
	[":xiaoguo"] = "其他角色的结束阶段开始时，若其存活，你可弃置一张基本牌.其选择：1.弃置一张装备牌；2.受到你造成的1点普通伤害。",
	["@xiaoguo"] = "你可以弃置一张基本牌对%src发动“骁果”",
	["@xiaoguo-discard"] = "骁果：请弃置一张装备牌，否则受到 1 点伤害",
	
	
	["#jianggan"] = "锋镝悬信",
	["jianggan"] = "蒋干",
	["illustrator:jianggan"] = "biou09",
	["weicheng"] = "伪诚",
	[":weicheng"] = "当你的手牌移至其他角色的手牌区后，若你的手牌数小于你的体力值，你可摸一张牌。",
	["daoshu"] = "盗书",
	[":daoshu"] = "出牌阶段限一次，你可以选择一种花色并选择一名有手牌的其他角色▶你获得其一张牌并记录此牌的游戏牌ID。若为此ID的牌："..
		"是你选择的花色，{你对其造成1点伤害。此技能于此阶段内的发动次数上限+1}；"..
		"不是你选择的花色，{若你的手牌均与此牌花色相同，你展示所有手牌。你将一张与此牌花色花色不同的手牌交给其}。",
	["@daoshu-give"] = "盗书：选择一张手牌交给 %dest",
	
	
}

