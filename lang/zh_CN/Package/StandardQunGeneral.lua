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
	-- 群雄
	["#huatuo"] = "神医",
	["huatuo"] = "华佗",
	["chuli"] = "除疠",
	
	[":chuli"] = "出牌阶段限一次，若你有能弃置的牌，你可选择不包括两名势力相同的角色在内的任意数量的角色和任意数量的没有势力的角色合计一至三名有牌的其他角色▶你弃置一张牌，弃置这些角色的各一张牌。若你的以此法被弃置的牌为黑桃，你摸一张牌。因执行发动此次〖除疠〗的效果而被你弃置的牌为黑桃的角色各摸一张牌。",
	["jijiu"] = "急救",
	[":jijiu"] = "你于回合外可将一张红色牌当【桃】使用。",

	["#lvbu"] = "武的化身",
	["lvbu"] = "吕布",
	["illustrator:lvbu"] = "LiuHeng",
	["wushuang"] = "无双",
	[":wushuang"] = "锁定技，①当【杀】指定目标后，若使用者是你，你将此目标对应的角色抵消此【杀】的方式改为依次使用两张【闪】。②当【决斗】指定目标后，你将此目标对应的角色因执行此【决斗】的效果而响应此【决斗】的方式改为依次打出两张【杀】。③当你成为【决斗】的目标后，你将使用者因执行此【决斗】的效果而响应此【决斗】的方式改为依次打出两张【杀】。",
	["@wushuang-slash-1"] = "%src 对你【决斗】，你须连续打出两张【杀】",
	["@wushuang-slash-2"] = "%src 对你【决斗】，你须再打出一张【杀】",

	["#diaochan"] = "绝世的舞姬",
	["diaochan"] = "貂蝉",
	["illustrator:diaochan"] = "LiuHeng",
	["lijian"] = "离间",
	[":lijian"] = "出牌阶段限一次，你可弃置一张牌并选择一名是无使用者且无对应的实体牌的【决斗】的合法目标的其他男性角色A和一名能对A使用无对应的实体牌的【决斗】的其他男性角色B▶B对A使用无对应的实体牌的【决斗】。",
	["biyue"] = "闭月",
	[":biyue"] = "结束阶段开始时，你可摸一张牌。",

	["#yuanshao"] = "高贵的名门",
	["yuanshao"] = "袁绍",
	["illustrator:yuanshao"] = "SoniaTang",
	["luanji"] = "乱击",
	[":luanji"] = "你可将两张与所有你于此回合内因发动此技能使用的牌对应的所有的实体牌的花色均不相同的两张手牌当【万箭齐发】使用→当因执行此【万箭齐发】的效果而被打出的【闪】结算结束后，若此【闪】的打出者与你势力相同，其可摸一张牌。",
	["#luanji-draw"] = "乱击[摸牌]",
	["@luanji-draw"] = "乱击：是否摸一张牌",
	["#LuanjiDraw"] = "%from 响应“%arg”的效果，可以摸一张牌",

	["#yanliangwenchou"] = "虎狼兄弟",
	["yanliangwenchou"] = "颜良＆文丑",
	["&yanliangwenchou"] = "颜良文丑",
	["shuangxiong"] = "双雄",
	[":shuangxiong"] = "摸牌阶段开始时，你可令额定摸牌数改为0▶你判定→当判定结果确定后，你获得判定牌→你于此回合内可将一张与此结果颜色不同的手牌当【决斗】使用。",
	["#shuangxiong"] = "双雄（获得判定牌）",

	["#jiaxu"] = "冷酷的毒士",
	["jiaxu"] = "贾诩",
	["wansha"] = "完杀",
	[":wansha"] = "锁定技，当一名角色于你的回合内进入濒死状态后，你令除其外的其他角色于此濒死结算结束之前不能使用【桃】。",
	["weimu"] = "帷幕",
	[":weimu"] = "锁定技，当你成为黑色普通锦囊牌的目标时，你取消此目标。当黑色延时锦囊牌对应的实体牌移至你的判定区前，你将此次移动的目标区域改为弃牌堆。",
	["luanwu"] = "乱武",
	[":luanwu"] = "限定技，出牌阶段，你可选择所有其他角色，这些角色各需对距离最小的另一名角色使用【杀】，否则失去1点体力。",
	["@chaos"] = "乱武",
	["@luanwu-slash"] = "请使用一张【杀】响应“乱武”",
	["#WanshaOne"] = "%from 的“%arg”被触发，只有 %from 才能救 %from",
	["#WanshaTwo"] = "%from 的“%arg”被触发，只有 %from 和 %to 才能救 %to",

	["#pangde"] = "人马一体",
	["pangde"] = "庞德",
	["illustrator:pangde"] = "LiuHeng",
	["mashu_pangde"] = "马术",
	["jianchu"] = "鞬出",
	[":jianchu"] = "当【杀】指定目标后，若使用者为你，你可弃置其一张牌▶若以此法被弃置的牌：为装备牌，此【杀】于对此目标进行的使用结算中不是其使用【闪】的合法目标；不为装备牌，其获得此【杀】对应的所有实体牌。",

	["#zhangjiao"] = "天公将军",
	["zhangjiao"] = "张角",
	["illustrator:zhangjiao"] = "LiuHeng",
	["leiji"] = "雷击",
	[":leiji"] = "当【闪】被使用/打出时，若使用/打出者为你，你可令一名其他角色判定。若结果为黑桃，你对其造成2点雷电伤害。",
	["leiji-invoke"] = "你可以发动“雷击”，选择一名其他角色",
	["guidao"] = "鬼道",
	[":guidao"] = "当判定结果确定前，你可打出对应的实体牌是你的一张黑色牌且非转化的牌▶系统将此牌作为判定牌。你获得原判定牌。",
	["@guidao-card"] = CommonTranslationTable["@askforretrial"],
	["~guidao"] = "选择一张黑色牌→点击确定",

	["#caiwenji"] = "异乡的孤女",
	["caiwenji"] = "蔡文姬",
	["illustrator:caiwenji"] = "SoniaTang",
	["beige"] = "悲歌",
	[":beige"] = "当一名角色受到渠道为【杀】的伤害后，若其存活，你可弃置一张牌▶其判定。若结果为：红桃，其回复1点体力；方块，其摸两张牌；梅花，来源弃置两张牌；黑桃，来源叠置。",
	["@beige"] = "你可以弃置一张牌发动“悲歌”",
	["duanchang"] = "断肠",
	[":duanchang"] = "锁定技，当你死亡时，若杀死你的角色不为你，你令其失去你选择的其一张武将牌的所有技能。",
	["@duanchang"] = "断肠",
	["#DuanchangLoseHeadSkills"] = "%from 的“%arg”被触发， %to 失去所有主将技能",
	["#DuanchangLoseDeputySkills"] = "%from 的“%arg”被触发， %to 失去所有副将技能",

	["#mateng"] = "驰骋西陲",
	["mateng"] = "马腾",
	["illustrator:mateng"] = "DH",
	["mashu_mateng"] = "马术",
	["xiongyi"] = "雄异",
	[":xiongyi"] = "限定技，出牌阶段，你可令与你势力相同的所有角色各摸三张牌。若你的势力是角色数最小的势力，你回复1点体力。",
	["@arise"] = "雄异",

	["#kongrong"] = "凛然重义",
	["kongrong"] = "孔融",
	["illustrator:kongrong"] = "苍月白龙",
	["mingshi"] = "名士",
	[":mingshi"] = "锁定技，当你受到伤害时，若来源有暗置的武将牌，你令伤害值-1。",
	["lirang"] = "礼让",
	[":lirang"] = "当你的牌因弃置而移至弃牌堆后，你可将其中的至少一张牌交给其他角色。",
	["@lirang-distribute"] = "礼让：你可将弃置的牌任意分配给其他角色",
	["#lirang"] = "礼让",
	["#Mingshi"] = "%from 的“<font color=\"yellow\"><b>名士</b></font>”被触发，伤害从 %arg 点减少至 %arg2 点",

	["#jiling"] = "仲家的主将",
	["jiling"] = "纪灵",
	["illustrator:jiling"] = "樱花闪乱",
	["shuangren"] = "双刃",
	[":shuangren"] = "出牌阶段开始时，你可与一名角色拼点。若你：赢，你对与其势力相同的一名角色使用无对应的实体牌的普【杀】；未赢，你结束出牌阶段。",
	["@shuangren"] = "你可以发动“双刃”",

	["#tianfeng"] = "河北瑰杰",
	["tianfeng"] = "田丰",
	["illustrator:tianfeng"] = "地狱许",
	["sijian"] = "死谏",
	[":sijian"] = "当你失去手牌后，若你没有手牌，你可弃置一名其他角色的一张牌。",
	["sijian-invoke"] = "你可以发动“死谏”<br/> <b>操作提示</b>: 选择一名有牌的其他角色→点击确定<br/>",
	["suishi"] = "随势",
	[":suishi"] = "锁定技，①当其他角色因受到伤害而进入濒死状态时，若来源与你势力相同，你摸一张牌。②当其他角色死亡时，若其与你势力相同，你失去1点体力。",

	["#panfeng"] = "联军上将",
	["panfeng"] = "潘凤",
	["illustrator:panfeng"] = "Yi章",
	["kuangfu"] = "狂斧",
	[":kuangfu"] = "当你因执行你使用的【杀】的效果而对一名角色造成伤害后，你可选择：1.将其装备区里的一张牌置入你的装备区；2.弃置其装备区里的一张牌。",
	["#kuangfu"] = "狂斧 %log",
	["kuangfu:throw"] = "弃置",
	["kuangfu:move"] = "移动到自己的装备区",
	["kuangfu_equip"] = "狂斧",
	["kuangfu_equip:0"] = "武器牌",
	["kuangfu_equip:1"] = "防具牌",
	["kuangfu_equip:2"] = "+1坐骑",
	["kuangfu_equip:3"] = "-1坐骑",
	["kuangfu_equip:4"] = "宝物牌",

	["#zoushi"] = "惑心之魅",
	["zoushi"] = "邹氏",
	["illustrator:zoushi"] = "Tuu.",
	["huoshui"] = "祸水",
	[":huoshui"] = "锁定技，其他角色于你的回合内不能明置武将牌。",
	["qingcheng"] = "倾城",
	[":qingcheng"] = "出牌阶段，你可弃置一张黑色牌并选择一名所有武将牌均处于明置状态的其他角色▶其暗置你选择的其一张不为君主武将牌且不为士兵牌的武将牌，若你以此法弃置的牌为装备牌，你可令另一名所有武将牌均处于明置状态的其他角色暗置你选择的其一张不为君主武将牌且不为士兵牌的武将牌。",
	["qingcheng-second"] = "倾城：你可以再暗置另一名角色的一张武将牌",
}

