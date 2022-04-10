/********************************************************************
    Copyright (c) 2013-2015 - Mogara

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
    *********************************************************************/

#include "newsgs.h"
#include "skill.h"
#include "strategic-advantage.h"
#include "standard-basics.h"
#include "standard-tricks.h"
#include "client.h"
#include "engine.h"
#include "structs.h"
#include "gamerule.h"
#include "settings.h"
#include "roomthread.h"
#include "json.h"

class Wanggui : public TriggerSkill
{
public:
    Wanggui() : TriggerSkill("wanggui")
    {
        events << Damage << Damaged;
    }

    virtual QStringList triggerable(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
    {
        if (!TriggerSkill::triggerable(player) || !player->hasShownSkill(objectName()) || player->hasFlag("WangguiUsed")) return QStringList();
        DamageStruct damage = data.value<DamageStruct>();
        if (triggerEvent == Damage && damage.to && damage.to->hasFlag("Global_DFDebut")) return QStringList();

        if (player->hasShownAllGenerals())
            return QStringList(objectName());
        else {
            QList<ServerPlayer *> all_players = room->getAlivePlayers();
            foreach (ServerPlayer *p, all_players) {
                if (!player->isFriendWith(p) && p->hasShownOneGeneral())
                    return QStringList(objectName());
            }
        }

        return QStringList();
    }

    virtual bool cost(TriggerEvent , Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        if (player->hasShownAllGenerals()) {
            if (player->askForSkillInvoke(this, "prompt")) {
                QStringList target_list = player->tag["wanggui_target"].toStringList();
                target_list.append("self");
                player->tag["wanggui_target"] = target_list;
                room->broadcastSkillInvoke(objectName(), player);
                player->setFlags("WangguiUsed");
                return true;
            }
        } else {

            QList<ServerPlayer *> to_choose, all_players = room->getAlivePlayers();
            foreach (ServerPlayer *p, all_players) {
                if (!player->isFriendWith(p) && p->hasShownOneGeneral())
                    to_choose << p;
            }
            if (to_choose.isEmpty()) return false;

            ServerPlayer *to = room->askForPlayerChosen(player, to_choose, objectName(), "wanggui-invoke", true, true);
            if (to != NULL) {
                room->broadcastSkillInvoke(objectName(), player);
                player->setFlags("WangguiUsed");

                QStringList target_list = player->tag["wanggui_target"].toStringList();
                target_list.append(to->objectName());
                player->tag["wanggui_target"] = target_list;
                return true;
            }
        }

        return false;
    }

    virtual bool effect(TriggerEvent , Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        QStringList target_list = player->tag["wanggui_target"].toStringList();
        QString target_name = target_list.takeLast();
        player->tag["wanggui_target"] = target_list;
        if (target_name == "self") {
            QList<ServerPlayer *> to_choose, all_players = room->getAlivePlayers();
            foreach (ServerPlayer *p, all_players) {
                if (player->isFriendWith(p))
                    to_choose << p;
            }
            room->sortByActionOrder(to_choose);
            foreach (ServerPlayer *p, to_choose) {
                if (p->isAlive())
                    p->drawCards(1, objectName());
            }
        } else {
            ServerPlayer *to = NULL;
            QList<ServerPlayer *> all_players = room->getAlivePlayers();
            foreach (ServerPlayer *p, all_players) {
                if (p->objectName() == target_name) {
                    to = p;
                    break;
                }
            }

            if (to) {
                room->damage(DamageStruct(objectName(), player, to));
            }
        }
        return false;
    }
};

class Xibing : public TriggerSkill
{
public:
    Xibing() : TriggerSkill("xibing")
    {
        events << TargetChosen << EventPhaseStart;

    }

    virtual void record(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &) const
    {
        if (triggerEvent == EventPhaseStart && player->getPhase() ==  Player::NotActive) {
            QList<ServerPlayer *> alls = room->getAlivePlayers();
            foreach (ServerPlayer *p, alls) {
                room->setPlayerMark(p, "##xibing", 0);
                room->removePlayerDisableShow(p, objectName());
            }
        }
    }

    virtual TriggerList triggerable(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (triggerEvent == TargetChosen) {
            TriggerList skill_list;
            CardUseStruct use = data.value<CardUseStruct>();
            if (use.card->hasFlag("GlobalXiBing") && player->getPhase() == Player::Play && use.to.size() == 1) {
                QList<ServerPlayer *> skill_owners = room->findPlayersBySkillName(objectName());
                foreach (ServerPlayer *skill_owner, skill_owners) {
                    if (skill_owner == player) continue;
                    skill_list.insert(skill_owner, QStringList(objectName()));
                }
            }
            return skill_list;
        }

        return TriggerList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *huaxin) const
    {
        if (huaxin->askForSkillInvoke(this, QVariant::fromValue(player))) {
            room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, huaxin->objectName(), player->objectName());
            room->broadcastSkillInvoke(objectName(), huaxin);
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *huaxin) const
    {
        int x = player->getHp() - player->getHandcardNum();
        if (x > 0) {
            player->drawCards(x);
            room->setPlayerCardLimitation(player, "use", ".|.|.|hand", true);
            room->addPlayerMark(player, "##xibing");
        }

        if (huaxin->hasShownAllGenerals() && player->hasShownAllGenerals()) {
            if (doXiBing(huaxin, huaxin, true))
                doXiBing(huaxin, player, false);
        }
        return false;
    }

private:
    static bool doXiBing(ServerPlayer *huaxin, ServerPlayer *player, bool optional)
    {
        Room *room = huaxin->getRoom();
        QStringList generals, allchoices;
        allchoices << "head" << "deputy";
        if (!player->getActualGeneral1Name().contains("sujiang") && !player->isLord())
            generals << "head";

        if (player->getGeneral2() != NULL && !player->getGeneral2Name().contains("sujiang"))
            generals << "deputy";

        if (generals.isEmpty()) return false;

        if (optional) {
            generals << "cancel";
            allchoices << "cancel";
        }

        QString choice = room->askForChoice(huaxin, "xibing", generals.join("+"), QVariant(),
                                            "@xibing-hide::" + player->objectName(), allchoices.join("+"));

        if (choice == "cancel") return false;

        bool head = (choice == "head");

        player->hideGeneral(head);
        room->setPlayerDisableShow(player, head ? "h":"d", "xibing");

        return true;
    }

};

class Zhente : public TriggerSkill
{
public:
    Zhente() : TriggerSkill("zhente")
    {
        events << TargetConfirmed;
    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
    {
        if (!TriggerSkill::triggerable(player) || player->hasFlag("ZhenteUsed")) return QStringList();
        CardUseStruct use = data.value<CardUseStruct>();
        if ((use.card->getTypeId() == Card::TypeBasic || use.card->isNDTrick()) && use.card->isBlack() && use.to.contains(player)
                && (use.from && use.from != player && use.from->isAlive()))
            return QStringList(objectName());
        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        player->tag["ZhenteUsedata"] = data;
        bool invoke = player->askForSkillInvoke(this, QVariant::fromValue(use.from));
        player->tag.remove("ZhenteUsedata");
        if (invoke) {
            room->broadcastSkillInvoke(objectName(), player);
            room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, player->objectName(), use.from->objectName());
            player->setFlags("ZhenteUsed");
            return true;
        }

        return false;
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        CardUseStruct use = data.value<CardUseStruct>();

        if (use.from->isDead()) return false;

        QString prompt = "zhente-ask:" + player->objectName() + "::" + use.card->objectName();

        use.from->tag["ZhenteUsedata"] = data;
        QString choice = room->askForChoice(use.from, objectName(), "nullified+cardlimited", data, prompt);
        use.from->tag.remove("ZhenteUsedata");

        if (choice == "nullified") {
            LogMessage log;
            log.type = "#ZhiweiChoice1";
            log.from = use.from;
            log.to << player;
            log.arg = use.card->objectName();
            room->sendLog(log);

            use.nullified_list << player->objectName();
            data = QVariant::fromValue(use);
        } else if (choice == "cardlimited")  {

            LogMessage log;
            log.type = "#ZhiweiChoice2";
            log.from = use.from;

            room->sendLog(log);

            room->setPlayerCardLimitation(use.from, "use", ".|black|.|.", true);

        }

        return false;
    }
};

class Zhiwei : public TriggerSkill
{
public:
    Zhiwei() : TriggerSkill("zhiwei")
    {
        events << GeneralShown << GeneralHidden << GeneralRemoved;
    }

    virtual bool canPreshow() const
    {
        return false;
    }

    virtual void record(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {

         if ((triggerEvent == GeneralHidden && player->ownSkill(this) && player->inHeadSkills(objectName()) == data.toBool())
                || (triggerEvent == GeneralRemoved && data.toString() == "luyusheng")) {

             ServerPlayer *AssistTarget = player->tag["ZhiweiTarget"].value<ServerPlayer *>();
             player->tag.remove("ZhiweiTarget");

             if (AssistTarget) {
                 LogMessage log;
                 log.type = "#ZhiweiFinsh";
                 log.from = player;
                 log.to << AssistTarget;
                 log.arg = objectName();
                 room->sendLog(log);
                 room->removePlayerMark(AssistTarget, "@zhiwei");
             }
         }

    }

    virtual QStringList triggerable(TriggerEvent triggerEvent, Room *, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
    {
        if (triggerEvent == GeneralShown && TriggerSkill::triggerable(player))
            return (player->cheakSkillLocation(objectName(), data.toBool())) ? QStringList(objectName()) : QStringList();

        return QStringList();
    }

    virtual bool cost(TriggerEvent , Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        ServerPlayer *to = room->askForPlayerChosen(player, room->getOtherPlayers(player), objectName(), "zhiwei-invoke", true, true);
        if (to != NULL) {
            room->broadcastSkillInvoke(objectName(), player);

            QStringList target_list = player->tag["zhiwei_target"].toStringList();
            target_list.append(to->objectName());
            player->tag["zhiwei_target"] = target_list;
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent , Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        QStringList target_list = player->tag["zhiwei_target"].toStringList();
        QString target_name = target_list.takeLast();
        player->tag["zhiwei_target"] = target_list;

        ServerPlayer *to = NULL;
        QList<ServerPlayer *> all_players = room->getAlivePlayers();
        foreach (ServerPlayer *p, all_players) {
            if (p->objectName() == target_name) {
                to = p;
                break;
            }
        }

        if (to) {
            player->tag["ZhiweiTarget"] = QVariant::fromValue(to);
            room->addPlayerMark(to, "@zhiwei");


        }

        return false;
    }
};

class ZhiweiEffect : public TriggerSkill
{
public:
    ZhiweiEffect() : TriggerSkill("#zhiwei-effect")
    {
        events << Damage << Damaged << Death << CardsMoveOneTime;
        frequency = Compulsory;
    }

    virtual TriggerList triggerable(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        TriggerList skill_list;
        if (triggerEvent == Death && player->hasShownAllGenerals()) {
            DeathStruct death = data.value<DeathStruct>();
            ServerPlayer *dead = death.who;
            ServerPlayer *AssistTarget = player->tag["ZhiweiTarget"].value<ServerPlayer *>();
            if (AssistTarget != NULL && AssistTarget == dead) {
                skill_list.insert(player, QStringList(objectName()));
            }
        }
        if (triggerEvent == CardsMoveOneTime && player->getPhase() == Player::Discard) {
            QVariantList move_datas = data.toList();
            foreach (QVariant move_data, move_datas) {
                CardsMoveOneTimeStruct move = move_data.value<CardsMoveOneTimeStruct>();
                if (move.from == player && (move.reason.m_reason & CardMoveReason::S_MASK_BASIC_REASON) == CardMoveReason::S_REASON_DISCARD) {
                    if (move.to_place == Player::DiscardPile) {
                        QList<int> this_cards;
                        foreach (int id, move.card_ids) {
                            if (room->getCardPlace(id) == Player::DiscardPile)
                                this_cards << id;
                        }
                        if (!this_cards.isEmpty()) {
                            ServerPlayer *AssistTarget = player->tag["ZhiweiTarget"].value<ServerPlayer *>();
                            if (AssistTarget != NULL && AssistTarget->isAlive()) {
                                skill_list.insert(player, QStringList(objectName()));
                            }
                        }
                    }
                }
            }


        }
        if (triggerEvent == Damage || triggerEvent == Damaged) {
            foreach (ServerPlayer *luyusheng, room->getAllPlayers()) {
                ServerPlayer *AssistTarget = luyusheng->tag["ZhiweiTarget"].value<ServerPlayer *>();
                if (AssistTarget == player && (triggerEvent == Damage || !luyusheng->isKongcheng()))
                    skill_list.insert(luyusheng, QStringList(objectName()));
            }
        }
        return skill_list;
    }

    virtual bool cost(TriggerEvent , Room *, ServerPlayer *, QVariant &, ServerPlayer *) const
    {
        return true;
    }

    virtual bool effect(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *luyusheng) const
    {
        if (triggerEvent == Damage) {
            LogMessage log;
            log.type = "#ZhiweiEffect1";
            log.from = luyusheng;
            log.to << player;
            log.arg = objectName();
            room->sendLog(log);
            luyusheng->drawCards(1, "zhiwei");
        }
        if (triggerEvent == Damaged) {
            QList<int> all_cards = luyusheng->forceToDiscard(10086, false);
            if (all_cards.isEmpty()) return false;
            LogMessage log;
            log.type = "#ZhiweiEffect2";
            log.from = luyusheng;
            log.to << player;
            log.arg = objectName();
            room->sendLog(log);
            int index = qrand() % all_cards.length();
            int id = all_cards.at(index);
            CardMoveReason mreason(CardMoveReason::S_REASON_THROW, luyusheng->objectName(), QString(), "zhiwei", QString());
            room->throwCard(Sanguosha->getCard(id), mreason, luyusheng);

        }
        if (triggerEvent == CardsMoveOneTime) {
            QList<int> this_cards;
            QVariantList move_datas = data.toList();
            foreach (QVariant move_data, move_datas) {
                CardsMoveOneTimeStruct move = move_data.value<CardsMoveOneTimeStruct>();
                if (move.from == player && (move.reason.m_reason & CardMoveReason::S_MASK_BASIC_REASON) == CardMoveReason::S_REASON_DISCARD) {
                    if (move.to_place == Player::DiscardPile) {
                        foreach (int id, move.card_ids) {
                            if (room->getCardPlace(id) == Player::DiscardPile)
                                this_cards << id;
                        }
                    }
                }
            }

            if (!this_cards.isEmpty()) {
                ServerPlayer *AssistTarget = luyusheng->tag["ZhiweiTarget"].value<ServerPlayer *>();
                if (AssistTarget != NULL && AssistTarget->isAlive()) {
                    LogMessage log;
                    log.type = "#ZhiweiEffect3";
                    log.from = luyusheng;
                    log.to << AssistTarget;
                    log.arg = objectName();
                    room->sendLog(log);
                    DummyCard dummy(this_cards);
                    room->obtainCard(AssistTarget, &dummy);

                }
            }

        }
        if (triggerEvent == Death) {
            DeathStruct death = data.value<DeathStruct>();
            LogMessage log;
            log.type = "#ZhiweiEffect4";
            log.from = luyusheng;
            log.to << death.who;
            log.arg = objectName();
            room->sendLog(log);
            luyusheng->hideGeneral(luyusheng->getGeneralName() == "luyusheng");
        }
        return false;
    }
};

class Qiao : public TriggerSkill
{
public:
    Qiao() : TriggerSkill("qiao")
    {
        events << TargetConfirmed << EventPhaseStart;
    }

    virtual void record(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &) const
    {
         if (triggerEvent == EventPhaseStart && player->getPhase() == Player::NotActive) {
             QList<ServerPlayer *> allplayers = room->getAlivePlayers();
             foreach (ServerPlayer *p, allplayers) {
                 room->setPlayerMark(p, "QiaoUsedTimes", 0);
             }
         }
    }

    virtual QStringList triggerable(TriggerEvent triggerEvent, Room *, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
    {
        if (!TriggerSkill::triggerable(player) || triggerEvent != TargetConfirmed || player->getMark("QiaoUsedTimes") > 1)
            return QStringList();
        CardUseStruct use = data.value<CardUseStruct>();
        if (use.card->getTypeId() == Card::TypeSkill || !use.to.contains(player)) return QStringList();
        if (use.from && !player->willBeFriendWith(use.from) && !use.from->isNude())
            return QStringList(objectName());
        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        player->tag["QiaoUsedata"] = data;
        bool invoke = player->askForSkillInvoke(this, QVariant::fromValue(use.from));
        player->tag.remove("QiaoUsedata");
        if (invoke) {
            room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, player->objectName(), use.from->objectName());
            room->broadcastSkillInvoke(objectName(), player);
            room->addPlayerMark(player, "QiaoUsedTimes");
            return true;
        }

        return false;
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        ServerPlayer *use_from = use.from;
        if (player->canDiscard(use_from, "he")) {
            CardMoveReason reason = CardMoveReason(CardMoveReason::S_REASON_DISMANTLE, player->objectName(), use_from->objectName(), objectName(), QString());
            const Card *card = Sanguosha->getCard(room->askForCardChosen(player, use_from, "he", objectName(), false, Card::MethodDiscard));
            room->throwCard(card, reason, use_from, player);
        }
        room->askForDiscard(player, "qiao_discard", 1, 1, false, true, "@qiao-discard");
        return false;
    }
};

class Chengshang : public TriggerSkill
{
public:
    Chengshang() : TriggerSkill("chengshang")
    {
        events << CardFinished << EventPhaseChanging;
    }

    virtual void record(TriggerEvent triggerEvent, Room *room, ServerPlayer *, QVariant &) const
    {
         if (triggerEvent == EventPhaseChanging) {
             QList<ServerPlayer *> allplayers = room->getAlivePlayers();
             foreach (ServerPlayer *p, allplayers) {
                 room->setPlayerFlag(p, "-ChengshangUsed");
             }
         }
    }

    virtual QStringList triggerable(TriggerEvent triggerEvent, Room *, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
    {
        if (!TriggerSkill::triggerable(player) || triggerEvent != CardFinished
                || player->getPhase() != Player::Play || player->hasFlag("ChengshangUsed")) return QStringList();
        CardUseStruct use = data.value<CardUseStruct>();
        if (use.card->getTypeId() == Card::TypeSkill || !use.card->tag["GlobalCardDamagedTag"].isNull()) return QStringList();
        foreach (ServerPlayer *to, use.to) {
            if (!to->willBeFriendWith(player))
                return QStringList(objectName());
        }

        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (player->askForSkillInvoke(this, data)) {
            room->broadcastSkillInvoke(objectName(), player);
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        QList<int> drawPile = room->getDrawPile(), to_get;

        foreach (int id, drawPile) {
            const Card *card = Sanguosha->getCard(id);
            if (card->getSuit() == use.card->getSuit() && card->getNumber() == use.card->getNumber())
                to_get << id;
        }
        if (!to_get.isEmpty()) {
            DummyCard dummy(to_get);
            room->obtainCard(player, &dummy, true);
            room->setPlayerFlag(player, "ChengshangUsed");
        }

        return false;
    }
};

class Kuangcai : public TriggerSkill
{
public:
    Kuangcai() : TriggerSkill("kuangcai")
    {
        events << EventPhaseStart;
        frequency = Compulsory;
    }

    virtual QStringList triggerable(TriggerEvent triggerEvent, Room *, ServerPlayer *player, QVariant &, ServerPlayer* &) const
    {
        if (!TriggerSkill::triggerable(player)) return QStringList();
        if (triggerEvent == EventPhaseStart && player->getPhase() == Player::Discard) {
            int x = player->getCardUsedTimes("."), y = player->getMark("Global_DamagePiont_Round");
            if ((x > 0 && y == 0) || x == 0)
                return QStringList(objectName());
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        bool invoke = false;
        if (player->hasShownSkill(objectName())) {
            invoke = true;
            room->sendCompulsoryTriggerLog(player, objectName());
        } else
            invoke = player->askForSkillInvoke(this, data);

        if (invoke) {
            room->broadcastSkillInvoke(objectName(), player);
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        if (player->getCardUsedTimes(".") == 0)
            room->addPlayerMark(player, "Global_MaxcardsIncrease");
        else
            room->addPlayerMark(player, "Global_MaxcardsDecrease");
        return false;
    }
};

class KuangcaiTarget : public TargetModSkill
{
public:
    KuangcaiTarget() : TargetModSkill("#kuangcai-target")
    {
        pattern = "^SkillCard";
    }

    virtual int getResidueNum(const Player *from, const Card *card, const Player *) const
    {
        if (!Sanguosha->matchExpPattern(pattern, from, card))
            return 0;

        if (from->hasShownSkill("kuangcai") && from->getPhase() != Player::NotActive)
            return 1000;

        return 0;
    }

    virtual int getDistanceLimit(const Player *from, const Card *card, const Player *) const
    {
        if (!Sanguosha->matchExpPattern(pattern, from, card))
            return 0;

        if (from->hasShownSkill("kuangcai") && from->getPhase() != Player::NotActive)
            return 1000;

        return 0;
    }

};

class Shejian : public TriggerSkill
{
public:
    Shejian() : TriggerSkill("shejian")
    {
        events << TargetConfirmed;
    }

    virtual QStringList triggerable(TriggerEvent , Room *room, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
    {
        if (!TriggerSkill::triggerable(player) || player->isKongcheng()) return QStringList();
        QList<ServerPlayer *> allplayers = room->getAlivePlayers();
        foreach (ServerPlayer *p, allplayers) {
            if (p->getHp() <= 0)
                return QStringList();
        }
        CardUseStruct use = data.value<CardUseStruct>();
        if (use.card->getTypeId() != Card::TypeSkill && use.to.size() == 1 && use.to.contains(player)) {
            if (use.from && use.from->isAlive() && use.from != player)
                return QStringList(objectName());

        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent , Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        player->tag["ShejianUsedata"] = data;
        bool invoke = player->askForSkillInvoke(this, QVariant::fromValue(use.from));
        player->tag.remove("ShejianUsedata");
        if (invoke) {
            room->broadcastSkillInvoke(objectName(), player);
            room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, player->objectName(), use.from->objectName());
            return true;
        }

        return false;
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        QList<int> all_cards = player->forceToDiscard(10086, false);
        player->throwAllHandCards();
        CardUseStruct use = data.value<CardUseStruct>();
        if (use.from && use.from->isAlive() && player->isAlive()) {
            int x = all_cards.length();

            QStringList choices;
            choices << "damage";
            if (player->canDiscard(use.from, "he"))
                choices << "discard";

            QString choice = room->askForChoice(player, objectName(), choices.join("+"), QVariant::fromValue(use.from),
                               "@shejian-choice::"+use.from->objectName()+":"+ QString::number(x), "discard+damage");
            if (choice == "damage")
                room->damage(DamageStruct(objectName(), player, use.from));
            else if (choice == "discard") {
                int y = 0;
                if (player->canDiscard(use.from, "h"))
                    y += use.from->getHandcardNum();
                QList<const Card *> equips = use.from->getEquips();

                foreach (const Card *card, equips) {
                    if (player->canDiscard(use.from, card->getEffectiveId()))
                        y++;
                }

                x = qMin(x, y);

                if (x > 0) {
                    QStringList handle_string;
                    for (int i = 0; i < x; i++) {
                        handle_string << "he";
                    }
                    QList<int> to_throw = room->askForCardsChosen(player, use.from, handle_string, objectName());
                    CardMoveReason reason(CardMoveReason::S_REASON_DISMANTLE, player->objectName(), use.from->objectName(), QString(), QString());
                    room->moveCardsAtomic(CardsMoveStruct(to_throw, NULL, Player::DiscardPile, reason), true);
                }
            }
        }
        return false;
    }
};

class Yusui : public TriggerSkill
{
public:
    Yusui() : TriggerSkill("yusui")
    {
        events << TargetConfirmed;
    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
    {
        if (!TriggerSkill::triggerable(player) || !player->hasShownOneGeneral() || player->getHp() < 1) return QStringList();
        CardUseStruct use = data.value<CardUseStruct>();
        if (use.card->getTypeId() != Card::TypeSkill && use.card->isBlack() && use.to.contains(player)
                && (use.from && use.from->hasShownOneGeneral() && !use.from->isFriendWith(player) && use.from->isAlive()))
            return QStringList(objectName());
        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (player->askForSkillInvoke(this, QVariant::fromValue(use.from))) {
            room->broadcastSkillInvoke(objectName(), player);
            room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, player->objectName(), use.from->objectName());
            return true;
        }

        return false;
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        ServerPlayer *target = use.from;
        room->loseHp(player);

        if (target == NULL || target->isDead() || player->isDead()) return false;

        QStringList choices;
        if (target->getHp() > player->getHp()) choices << "losehp";
        if (!target->isNude()) choices << "discard";

        if (choices.isEmpty()) return false;


        QString choice =room->askForChoice(player, objectName(), choices.join("+"), data, "@yusui-choice::"+target->objectName(), "losehp+discard");

        if (choice == "losehp" && target->getHp() > player->getHp())
            room->loseHp(target, target->getHp() - player->getHp());
        else if (choice == "discard")
            room->askForDiscard(target, "yusui_discard", target->getMaxHp(), target->getMaxHp());
        return false;
    }
};

BoyanCard::BoyanCard()
{

}

bool BoyanCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.isEmpty() && to_select != Self;
}

void BoyanCard::onEffect(const CardEffectStruct &effect) const
{
    ServerPlayer *source = effect.from;
    ServerPlayer *target = effect.to;
    Room *room = source->getRoom();

    target->fillHandCards(target->getMaxHp(), "boyan");
    room->setPlayerCardLimitation(target, "use,response", ".|.|.|hand", true);
    room->addPlayerMark(target, "##boyan");

    if (source->isAlive() && target->isAlive() &&
            (room->askForChoice(source, "boyan", "yes+no", QVariant::fromValue(target),
                               "@boyan-zongheng::"+target->objectName()) == "yes")) {

        room->acquireSkill(target, "boyanzongheng", true, false);
    }


}

class BoyanViewAsSkill : public ZeroCardViewAsSkill
{
public:
    BoyanViewAsSkill() : ZeroCardViewAsSkill("boyan")
    {

    }

    const Card *viewAs() const
    {
        BoyanCard *skill_card = new BoyanCard;
        skill_card->setShowSkill(objectName());
        return skill_card;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("BoyanCard");
    }
};

class Boyan : public TriggerSkill
{
public:
    Boyan() : TriggerSkill("boyan")
    {
        events << EventPhaseStart;
        view_as_skill = new BoyanViewAsSkill;
    }

    virtual void record(TriggerEvent , Room *room, ServerPlayer *player, QVariant &) const
    {
        if (player->getPhase() == Player::NotActive) {
            room->detachSkillFromPlayer(player, "boyanzongheng", false, false, false);
            foreach (ServerPlayer *p, room->getAlivePlayers()) {
                room->setPlayerMark(p, "##boyan", 0);
            }
        }
    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *, QVariant &, ServerPlayer * &) const
    {
        return QStringList();
    }
};

BoyanZonghengCard::BoyanZonghengCard()
{

}

bool BoyanZonghengCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.isEmpty() && to_select != Self;
}

void BoyanZonghengCard::onEffect(const CardEffectStruct &effect) const
{
    ServerPlayer *target = effect.to;
    Room *room = target->getRoom();
    room->setPlayerCardLimitation(target, "use,response", ".|.|.|hand", true);
    room->addPlayerMark(target, "##boyan");
}

class BoyanZongheng : public ZeroCardViewAsSkill
{
public:
    BoyanZongheng() : ZeroCardViewAsSkill("boyanzongheng")
    {

    }

    const Card *viewAs() const
    {
        BoyanZonghengCard *skill_card = new BoyanZonghengCard;
        skill_card->setShowSkill(objectName());
        return skill_card;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("BoyanZonghengCard");
    }
};

class Jianliang : public PhaseChangeSkill
{
public:
    Jianliang() : PhaseChangeSkill("jianliang")
    {

    }

    virtual QStringList triggerable(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer* &) const
    {
        if (!PhaseChangeSkill::triggerable(player) || player->getPhase() != Player::Draw)
            return QStringList();
        QList<ServerPlayer *> players = room->getOtherPlayers(player);
        foreach(ServerPlayer *p, players) {
            if (p->getHandcardNum() < player->getHandcardNum())
                return QStringList();
        }

        return QStringList(objectName());
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        if (player->askForSkillInvoke(this)) {
            room->broadcastSkillInvoke(objectName(), player);
            return true;
        }

        return false;
    }

    virtual bool onPhaseChange(ServerPlayer *player) const
    {
        Room *room = player->getRoom();
        QList<ServerPlayer *> to_choose, all_players = room->getAlivePlayers();
        foreach (ServerPlayer *p, all_players) {
            if (player->isFriendWith(p))
                to_choose << p;
        }
        room->sortByActionOrder(to_choose);
        foreach (ServerPlayer *p, to_choose) {
            if (p->isAlive())
                p->drawCards(1, objectName());
        }
        return false;
    }
};

WeimengCard::WeimengCard()
{

}

bool WeimengCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.isEmpty() && to_select != Self && !to_select->isKongcheng();
}

void WeimengCard::onEffect(const CardEffectStruct &effect) const
{
    ServerPlayer *source = effect.from;
    ServerPlayer *target = effect.to;
    Room *room = source->getRoom();

    if (source->isAlive() && target->isAlive() && !target->isKongcheng()) {
        int max = qMin(source->getHp(), target->getHandcardNum());
        QStringList get_num;
        for (int i = 1; i <= max; get_num << QString::number(i++)) {

        }
        int num = room->askForChoice(source, "weimeng_num", get_num.join("+"), QVariant::fromValue(target),
                                     "@weimeng-num::"+target->objectName()).toInt();

        QStringList handle_string;
        for (int i = 0; i < num; i++) {
            handle_string << "h";
        }

        QList<int> to_get = room->askForCardsChosen(source, target, handle_string, "weimeng");

        CardMoveReason reason1(CardMoveReason::S_REASON_EXTRACTION, source->objectName());

        DummyCard dummy1(to_get);

        room->obtainCard(source, &dummy1, reason1, false);

        if (source->isAlive() && target->isAlive() && !source->isNude()) {
            num = qMin(num, source->getCardCount(true));

            target->setFlags("WeimengTarget");

            QString prompt = QString("@weimeng-give::%1:%2").arg(target->objectName()).arg(num);
            QList<int> ints = room->askForExchange(source, "weimeng_giveback", num, num, prompt);
            target->setFlags("-WeimengTarget");

            CardMoveReason reason(CardMoveReason::S_REASON_GIVE, source->objectName(), target->objectName(), "weimeng", QString());
            reason.m_playerId = target->objectName();

            DummyCard dummy2(ints);

            room->moveCardTo(&dummy2, target, Player::PlaceHand, reason);

        }
    }

    if (source->isAlive() && target->isAlive() &&
            (room->askForChoice(source, "weimeng", "yes+no", QVariant::fromValue(target),
                               "@weimeng-zongheng::"+target->objectName()) == "yes")) {

        room->acquireSkill(target, "weimengzongheng", true, false);
    }


}

class WeimengViewAsSkill : public ZeroCardViewAsSkill
{
public:
    WeimengViewAsSkill() : ZeroCardViewAsSkill("weimeng")
    {

    }

    const Card *viewAs() const
    {
        WeimengCard *skill_card = new WeimengCard;
        skill_card->setShowSkill(objectName());
        return skill_card;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("WeimengCard") && player->getHp() > 0;
    }
};

class Weimeng : public TriggerSkill
{
public:
    Weimeng() : TriggerSkill("weimeng")
    {
        events << EventPhaseStart;
        view_as_skill = new WeimengViewAsSkill;
    }

    virtual void record(TriggerEvent , Room *room, ServerPlayer *player, QVariant &) const
    {
        if (player->getPhase() == Player::NotActive) {
            room->detachSkillFromPlayer(player, "weimengzongheng", false, false, false);
        }
    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *, QVariant &, ServerPlayer * &) const
    {
        return QStringList();
    }
};

WeimengZonghengCard::WeimengZonghengCard()
{

}

bool WeimengZonghengCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.isEmpty() && to_select != Self && !to_select->isKongcheng();
}

void WeimengZonghengCard::onEffect(const CardEffectStruct &effect) const
{
    ServerPlayer *source = effect.from;
    ServerPlayer *target = effect.to;
    Room *room = source->getRoom();

    if (source->isDead() || target->isDead() || target->isKongcheng()) return;
    int card_id1 = room->askForCardChosen(source, target, "h", "weimeng", false, Card::MethodGet);
    CardMoveReason reason1(CardMoveReason::S_REASON_EXTRACTION, source->objectName());
    room->obtainCard(source, Sanguosha->getCard(card_id1), reason1, false);

    if (source->isDead() || target->isDead() || source->isNude()) return;

    target->setFlags("WeimengTarget");
    QString prompt = QString("@weimeng-give::%1:%2").arg(target->objectName()).arg(1);
    QList<int> ints = room->askForExchange(source, "weimeng_giveback", 1, 1, prompt);
    target->setFlags("-WeimengTarget");

    int card_id = -1;
    if (ints.isEmpty()) {
        card_id = source->getCards("he").first()->getEffectiveId();
    } else
        card_id = ints.first();

    CardMoveReason reason(CardMoveReason::S_REASON_GIVE, source->objectName(), target->objectName(), "weimeng", QString());
    reason.m_playerId = target->objectName();
    room->moveCardTo(Sanguosha->getCard(card_id), target, Player::PlaceHand, reason);

}

class WeimengZongheng : public ZeroCardViewAsSkill
{
public:
    WeimengZongheng() : ZeroCardViewAsSkill("weimengzongheng")
    {

    }

    const Card *viewAs() const
    {
        WeimengZonghengCard *skill_card = new WeimengZonghengCard;
        skill_card->setShowSkill(objectName());
        return skill_card;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("WeimengZonghengCard");
    }
};

class Weicheng : public TriggerSkill
{
public:
    Weicheng() : TriggerSkill("weicheng")
    {
        events << CardsMoveOneTime;
    }

    virtual QStringList triggerable(TriggerEvent , Room *, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
    {
        if (!TriggerSkill::triggerable(player) || player->getHp() <= player->getHandcardNum()) return QStringList();

        QVariantList move_datas = data.toList();
        foreach (QVariant move_data, move_datas) {
            CardsMoveOneTimeStruct move = move_data.value<CardsMoveOneTimeStruct>();
            if (move.from == player && move.from_places.contains(Player::PlaceHand)
                    && move.to && move.to != move.from && move.to_place == Player::PlaceHand) {
                return QStringList(objectName());
            }
        }

        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (player->askForSkillInvoke(this, data)) {
            room->broadcastSkillInvoke(objectName(), player);
            return true;
        }

        return false;
    }

    virtual bool effect(TriggerEvent, Room *, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        player->drawCards(1, objectName());
        return false;
    }
};

DaoshuCard::DaoshuCard()
{

}

bool DaoshuCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.isEmpty() && Self->canGetCard(to_select, "h") && to_select != Self;
}

void DaoshuCard::onEffect(const CardEffectStruct &effect) const
{
    ServerPlayer *source = effect.from;
    ServerPlayer *target = effect.to;
    Room *room = source->getRoom();
    Card::Suit suit = room->askForSuit(source, "daoshu");

    LogMessage log;
    log.type = "#ChooseSuit";
    log.from = source;
    log.arg = Card::Suit2String(suit);
    room->sendLog(log);

    int card_id = room->askForCardChosen(source, target, "h", "daoshu", false, Card::MethodGet);

    CardMoveReason reason(CardMoveReason::S_REASON_EXTRACTION, source->objectName());
    CardsMoveStruct daoshu_move(card_id, source, Player::PlaceHand, reason);
    QList<CardsMoveOneTimeStruct> moveOneTimes = room->moveCardsSub(daoshu_move, true);

    QList<const Card *> getcard;
    foreach (CardsMoveOneTimeStruct move, moveOneTimes) {
        if (move.from == target && move.reason.m_reason == CardMoveReason::S_REASON_EXTRACTION) {
            for (int i = 0; i < move.card_ids.length(); ++i) {
                const Card *card = Card::Parse(move.cards.at(i));
                if (card && (move.from_places.at(i) == Player::PlaceHand || move.from_places.at(i) == Player::PlaceEquip)) {
                    getcard << card;
                }
            }
        }
    }

    if (getcard.isEmpty()) return;

    bool cheak_suit = false;

    QStringList card_suits;
    card_suits << "spade" << "heart" << "club" << "diamond";

    foreach (const Card *c, getcard) {
        if (c->getSuit() == suit)
            cheak_suit = true;
        else
            card_suits.removeOne(c->getSuitString());
    }

    if (cheak_suit) {
        room->damage(DamageStruct("daoshu", source, target));
        room->addPlayerHistory(source, getClassName(), -1);
    }

    if (card_suits.length() < 4) {
        const Card *to_give = NULL;
        foreach (const Card *c, source->getHandcards()) {
            if (card_suits.contains(c->getSuitString())) {
                to_give = c;
                break;
            }
        }
        if (to_give == NULL) {
            room->showAllCards(source);
            return;
        }
        const Card *select = room->askForCard(source, ".|" + card_suits.join(",") + "|.|hand!", "@daoshu-give::" + target->objectName(),
                                              QVariant(), Card::MethodNone);
        if (select == NULL)
            select = to_give;

        CardMoveReason reason(CardMoveReason::S_REASON_GIVE, source->objectName(), target->objectName(), "daoshu", QString());
        room->obtainCard(target, select, reason, true);
    }
}

class Daoshu : public ZeroCardViewAsSkill
{
public:
    Daoshu() : ZeroCardViewAsSkill("daoshu")
    {

    }

    virtual bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("DaoshuCard");
    }

    virtual const Card *viewAs() const
    {
        DaoshuCard *card = new DaoshuCard;
        card->setShowSkill(objectName());
        return card;
    }
};

class Zhukou : public TriggerSkill
{
public:
    Zhukou() : TriggerSkill("zhukou")
    {
        events << Damage;
    }

    virtual QStringList triggerable(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
    {
        if (!TriggerSkill::triggerable(player)) return QStringList();
        DamageStruct damage = data.value<DamageStruct>();
        if (damage.flags.contains(objectName()) && !damage.to->hasFlag("Global_DFDebut")) {
            if (room->getCurrent() && room->getCurrent()->getPhase() == Player::Play) {
                if (player->getCardUsedTimes(".") > 0)
                    return QStringList(objectName());
            }
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (player->askForSkillInvoke(this, data)) {
            room->broadcastSkillInvoke(objectName(), player);
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent, Room *, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        int x = player->getCardUsedTimes(".");
        if (x > 0)
            player->drawCards(qMin(x, 5), objectName());

        return false;
    }
};


class Duannian : public TriggerSkill
{
public:
    Duannian() : TriggerSkill("duannian")
    {
        events << EventPhaseEnd;
    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *player, QVariant &, ServerPlayer* &) const
    {
        if (!TriggerSkill::triggerable(player)) return QStringList();
        if (player->getPhase() == Player::Play && !player->isKongcheng())
            return QStringList(objectName());
        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (player->askForSkillInvoke(this, data)) {
            room->broadcastSkillInvoke(objectName(), player);
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent, Room *, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        player->throwAllHandCards();
        player->fillHandCards(qMin(5, player->getMaxHp()), objectName());

        return false;
    }
};

class Lianyou : public TriggerSkill
{
public:
    Lianyou() : TriggerSkill("lianyou")
    {
        events << Death;
    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        DeathStruct death = data.value<DeathStruct>();
        return (player && player->hasSkill(objectName()) && death.who == player) ? QStringList(objectName()) : QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        ServerPlayer *victim;
        if ((victim = room->askForPlayerChosen(player, room->getOtherPlayers(player), objectName(), "@lianyou", true, true)) != NULL) {
            room->broadcastSkillInvoke(objectName(), player);

            QStringList target_list = player->tag["lianyou_target"].toStringList();
            target_list.append(victim->objectName());
            player->tag["lianyou_target"] = target_list;

            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        QStringList target_list = player->tag["lianyou_target"].toStringList();
        QString target_name = target_list.last();
        target_list.removeLast();
        player->tag["lianyou_target"] = target_list;

        ServerPlayer *target = room->findPlayerbyobjectName(target_name);
        if (target != NULL) {
            room->addPlayerMark(target, "##xinghuo");
            room->acquireSkill(target, "xinghuo", true, false);
        }
        return false;
    }
};

class Xinghuo : public TriggerSkill
{
public:
    Xinghuo() : TriggerSkill("xinghuo")
    {
        events << DamageCaused;
        frequency = Compulsory;
    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
    {
        if (TriggerSkill::triggerable(player)) {
            DamageStruct damage = data.value<DamageStruct>();
            if (damage.nature == DamageStruct::Fire)
                return QStringList(objectName());
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        bool invoke = false;
        if (player->hasShownSkill(objectName())) {
            invoke = true;
            room->sendCompulsoryTriggerLog(player, objectName());
        } else
            invoke = player->askForSkillInvoke(this, data);

        if (invoke) {
            room->broadcastSkillInvoke(objectName(), player);
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent, Room *, ServerPlayer *, QVariant &data, ServerPlayer *) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        damage.damage++;
        data = QVariant::fromValue(damage);
        return false;
    }
};

class Gongxiu : public DrawCardsSkill
{
public:
    Gongxiu() : DrawCardsSkill("gongxiu")
    {

    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        if (player->askForSkillInvoke(this)) {
            room->broadcastSkillInvoke(objectName(), player);
            return true;
        }
        return false;
    }

    virtual int getDrawNum(ServerPlayer *player, int n) const
    {
        Room *room = player->getRoom();
        int x  = player->getMaxHp();
        QList<ServerPlayer *> all_players = room->getAlivePlayers();

        QList<ServerPlayer *> to_choose;
        foreach(ServerPlayer *p, all_players) {
            if (!p->isNude())
                to_choose << p;
        }

        QStringList choices;
        if (player->getMark("gongxiuchoice") != 1)
            choices << "draw";
        if (player->getMark("gongxiuchoice") != 2 && !to_choose.isEmpty())
            choices << "discard";

        if (!choices.isEmpty()) {

            QString choice = room->askForChoice(player, "gongxiu_choose", choices.join("+"), QVariant(), "@gongxiu-choose", "draw+discard");
            if (choice == "draw") {
                room->setPlayerMark(player, "gongxiuchoice", 1);
                QList<ServerPlayer *> choosees = room->askForPlayersChosen(player, all_players, "gongxiu_draw", 1, x, "@gongxiu-draw:::" + QString::number(x));
                room->sortByActionOrder(choosees);
                foreach (ServerPlayer *target, choosees) {
                    room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, player->objectName(), target->objectName());
                }
                foreach (ServerPlayer *target, choosees) {
                    target->drawCards(1, objectName());
                }
            }
            if (choice == "discard") {
                room->setPlayerMark(player, "gongxiuchoice", 2);
                QList<ServerPlayer *> choosees = room->askForPlayersChosen(player, to_choose, "gongxiu_discard", 1, x, "@gongxiu-discard:::" + QString::number(x));
                room->sortByActionOrder(choosees);
                foreach (ServerPlayer *target, choosees) {
                    room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, player->objectName(), target->objectName());
                }
                foreach (ServerPlayer *target, choosees) {
                    room->askForDiscard(target, "gongxiu_throw", 1, 1, false, true, "@gongxiu-throw");
                }
            }
        }
        return n - 1;
    }
};

JingheCard::JingheCard()
{
    will_throw = false;
}

bool JingheCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *) const
{
    return targets.length() < subcardsLength() && to_select->hasShownOneGeneral();
}

bool JingheCard::targetsFeasible(const QList<const Player *> &targets, const Player *) const
{
    return targets.length() == subcardsLength();
}

void JingheCard::extraCost(Room *room, const CardUseStruct &card_use) const
{
    room->showCard(card_use.from, subcards);
    SkillCard::extraCost(room, card_use);
}

void JingheCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const
{
    QStringList skill_list;
    skill_list << "leiji_tianshu" << "yinbing" << "huoqi" << "guizhu"
               << "xianshou" << "lundao" << "guanyue" << "yanzheng";

    qShuffle(skill_list);

    int x = qMin(targets.length(), skill_list.length());

    skill_list = skill_list.mid(0, x);

    skill_list << "cancel";
    QStringList available = skill_list;

    QStringList target_names;
    foreach (ServerPlayer *p, targets) {
        target_names << p->objectName();
    }
    source->tag["JingheTargets"] = target_names.join("+");

    foreach (ServerPlayer *target, targets) {
        if (source->isDead() || available.length() == 1) break;
        if (target->isDead()) continue;

        QString skill_name = room->askForChoice(target, "jinghe_skill", available.join("+"),
                                                QVariant(), "@jinghe-choose", skill_list.join("+"));

        if (skill_name == "cancel") continue;

        available.removeOne(skill_name);

        room->acquireSkill(target, skill_name, true, false);

        QStringList record = target->tag["JingheSkills:"+source->objectName()].toStringList();
        record << skill_name;
        target->tag["JingheSkills:"+source->objectName()] = QVariant::fromValue(record);

    }

    source->tag.remove("JingheTargets");
}

class JingheViewAsSkill : public ViewAsSkill
{
public:
    JingheViewAsSkill() : ViewAsSkill("jinghe")
    {

    }

    virtual bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const
    {
        if (to_select->isEquipped() || selected.length() >= Self->getMaxHp()) return false;

        foreach (const Card *card, selected) {
            if (card->isKindOf("Slash") && to_select->isKindOf("Slash")) return false;
            if (card->isKindOf("Nullification") && to_select->isKindOf("Nullification")) return false;
            if (card->objectName() == to_select->objectName()) return false;
        }

        return true;
    }

    virtual bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("JingheCard");
    }

    virtual const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (!cards.isEmpty()) {
            JingheCard *card = new JingheCard;
            card->addSubcards(cards);
            card->setShowSkill(objectName());
            return card;
        }
        return NULL;
    }
};

class Jinghe : public TriggerSkill
{
public:
    Jinghe() : TriggerSkill("jinghe")
    {
        events << EventPhaseStart << Death;
        view_as_skill = new JingheViewAsSkill;
    }

    virtual void record(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (triggerEvent == EventPhaseStart) {
            if (player->getPhase() != Player::RoundStart) return;
        } else if (triggerEvent == Death) {
            DeathStruct death = data.value<DeathStruct>();
            if (player != death.who) return;
        }
        QList<ServerPlayer *> players = room->getAlivePlayers();
        foreach (ServerPlayer *p, players) {
            QStringList skills = p->tag["JingheSkills:"+player->objectName()].toStringList();
            QStringList detachList;
            foreach(QString skill_name, skills)
                detachList.append("-" + skill_name + "!");
            room->handleAcquireDetachSkills(p, detachList, true);
            p->tag["JingheSkills:"+player->objectName()] = QVariant();
        }
    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *, QVariant &, ServerPlayer* &) const
    {
        return QStringList();
    }
};

class LeijiTianshu : public TriggerSkill
{
public:
    LeijiTianshu() : TriggerSkill("leiji_tianshu")
    {
        events << CardResponded;
    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
    {
        if (!TriggerSkill::triggerable(player)) return QStringList();
        const Card *card_star = data.value<CardResponseStruct>().m_card;
        if (card_star->isKindOf("Jink")) return QStringList(objectName());
        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        ServerPlayer *target = room->askForPlayerChosen(player, room->getOtherPlayers(player), objectName(), "leiji-invoke", true, true);
        if (target) {
            player->tag["leiji-target"] = QVariant::fromValue(target);
            room->broadcastSkillInvoke(objectName(), player);
            return true;
        } else {
            player->tag.remove("leiji-target");
            return false;
        }
        return false;
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *zhangjiao, QVariant &, ServerPlayer *) const
    {
        ServerPlayer *target = zhangjiao->tag["leiji-target"].value<ServerPlayer *>();
        zhangjiao->tag.remove("leiji-target");
        if (target) {

            JudgeStruct judge;
            judge.pattern = ".|spade";
            judge.good = false;
            judge.negative = true;
            judge.reason = objectName();
            judge.who = target;

            room->judge(judge);

            if (judge.isBad())
                room->damage(DamageStruct(objectName(), zhangjiao, target, 2, DamageStruct::Thunder));
        }
        return false;
    }
};

class Yinbing : public TriggerSkill
{
public:
    Yinbing() : TriggerSkill("yinbing")
    {
        events << Predamage << HpLost;
        frequency = Compulsory;
    }

    virtual TriggerList triggerable(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (triggerEvent == Predamage && TriggerSkill::triggerable(player)) {
            DamageStruct damage = data.value<DamageStruct>();
            if (damage.card && damage.card->isKindOf("Slash") && !damage.chain && !damage.transfer) {
                TriggerList skill_list;
                skill_list.insert(player, QStringList(objectName()));
                return skill_list;
            }
        } else if (triggerEvent == HpLost) {
            QList<ServerPlayer *> owners = room->findPlayersBySkillName(objectName());
            TriggerList skill_list;
            foreach (ServerPlayer *owner, owners)
                if (player != owner)
                    skill_list.insert(owner, QStringList(objectName()));
            return skill_list;

        }
        return TriggerList();
    }

    virtual bool cost(TriggerEvent , Room *room, ServerPlayer *, QVariant &, ServerPlayer *player) const
    {
        bool invoke = false;
        if (player->hasShownSkill(objectName())) {
            invoke = true;
            room->sendCompulsoryTriggerLog(player, objectName());
        } else
            invoke = player->askForSkillInvoke(this);

        if (invoke) {
            room->broadcastSkillInvoke(objectName(), player);
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent triggerEvent, Room *room, ServerPlayer *, QVariant &data, ServerPlayer *player) const
    {
        if (triggerEvent == Predamage) {
            DamageStruct damage = data.value<DamageStruct>();
            room->loseHp(damage.to, damage.damage);
            return true;
        } else if (triggerEvent == HpLost) {
            player->drawCards(1, objectName());
        }
        return false;
    }
};

HuoqiCard::HuoqiCard()
{
}

bool HuoqiCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    if (!targets.isEmpty()) return false;
    QList<const Player *> players = Self->getAliveSiblings();
    int min_hp = Self->getHp();
    foreach (const Player *p, players) {
        if (min_hp > p->getHp())
            min_hp = p->getHp();
    }
    return to_select->getHp() == min_hp && to_select->isWounded();
}

void HuoqiCard::onEffect(const CardEffectStruct &effect) const
{
    RecoverStruct recover;
    recover.card = this;
    recover.who = effect.from;
    effect.to->getRoom()->recover(effect.to, recover);
    effect.to->drawCards(1, "huoqi");
}

class Huoqi : public OneCardViewAsSkill
{
public:
    Huoqi() : OneCardViewAsSkill("huoqi")
    {
        filter_pattern = ".!";
    }

    virtual bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("HuoqiCard");
    }

    virtual const Card *viewAs(const Card *originalcard) const
    {
        HuoqiCard *first = new HuoqiCard;
        first->addSubcard(originalcard->getId());
        first->setSkillName(objectName());
        first->setShowSkill(objectName());
        return first;
    }
};

class Guizhu : public TriggerSkill
{
public:
    Guizhu() : TriggerSkill("guizhu")
    {
        events << Dying;
    }

    virtual QStringList triggerable(TriggerEvent , Room *, ServerPlayer *player, QVariant &, ServerPlayer* &) const
    {
        if (TriggerSkill::triggerable(player) && !player->hasFlag("guizhuUsed"))
            return QStringList(objectName());
        return QStringList();
    }

    virtual bool cost(TriggerEvent , Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        if (player->askForSkillInvoke(this)) {
            room->setPlayerFlag(player, "guizhuUsed");
            room->broadcastSkillInvoke(objectName(), player);
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent , Room *, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        player->drawCards(2, objectName());
        return false;
    }
};

XianshouCard::XianshouCard()
{
}

bool XianshouCard::targetFilter(const QList<const Player *> &targets, const Player *, const Player *) const
{
    return targets.isEmpty();
}

void XianshouCard::onEffect(const CardEffectStruct &effect) const
{
    if (effect.to->isAlive())
        effect.to->drawCards(effect.to->isWounded() ? 1 : 2, "xianshou");
}

class Xianshou : public ZeroCardViewAsSkill
{
public:
    Xianshou() : ZeroCardViewAsSkill("xianshou")
    {

    }

    virtual bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("XianshouCard");
    }

    virtual const Card *viewAs() const
    {
        XianshouCard *first = new XianshouCard;
        first->setSkillName(objectName());
        first->setShowSkill(objectName());
        return first;
    }
};


class Lundao : public MasochismSkill
{
public:
    Lundao() : MasochismSkill("lundao")
    {
    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        if (MasochismSkill::triggerable(player)) {
            ServerPlayer *from = data.value<DamageStruct>().from;
            if(from && from->isAlive()) {
                int x = player->getHandcardNum(), y = from->getHandcardNum();
                if (x > y || (x < y && !from->isNude())) return QStringList(objectName());
            }
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        ServerPlayer *from = data.value<DamageStruct>().from;
        if (from && player->askForSkillInvoke(this, QVariant::fromValue(from))) {
            room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, player->objectName(), from->objectName());
            room->broadcastSkillInvoke(objectName(), player);
            return true;
        }
        return false;
    }

    virtual void onDamaged(ServerPlayer *player, const DamageStruct &damage) const
    {
        ServerPlayer *from = damage.from;
        Room *room = player->getRoom();
        if (player->getHandcardNum() < from->getHandcardNum() && player->canDiscard(from, "he")) {
            int card_id = room->askForCardChosen(player, from, "he", objectName(), false, Card::MethodDiscard);
            room->throwCard(Sanguosha->getCard(card_id), from, player);
        } else if (player->getHandcardNum() > from->getHandcardNum())
            player->drawCards(1, objectName());
    }
};

class Guanyue : public PhaseChangeSkill
{
public:
    Guanyue() : PhaseChangeSkill("guanyue")
    {
        frequency = Frequent;
    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *player, QVariant &, ServerPlayer* &) const
    {
        if (!PhaseChangeSkill::triggerable(player)) return QStringList();
        if (player->getPhase() == Player::Finish) return QStringList(objectName());
        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        if (player->askForSkillInvoke(this)) {
            room->broadcastSkillInvoke(objectName(), player);
            return true;
        }
        return false;
    }

    virtual bool onPhaseChange(ServerPlayer *player) const
    {
        Room *room = player->getRoom();
        QList<int> ids = room->getNCards(2);
        room->fillAG(ids, player);
        int card_id = room->askForAG(player, ids, false, objectName());
        room->clearAG(player);
        room->returnToTopDrawPile(ids);
        room->obtainCard(player, card_id, false);
        return false;
    }
};

class Yanzheng : public PhaseChangeSkill
{
public:
    Yanzheng() : PhaseChangeSkill("yanzheng")
    {

    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *player, QVariant &, ServerPlayer* &) const
    {
        if (!PhaseChangeSkill::triggerable(player)) return QStringList();
        if (player->getPhase() == Player::Start && player->getHandcardNum() > 1) return QStringList(objectName());
        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        QList<int> ints = room->askForExchange(player, objectName(), 1, 0, "@yanzheng", "", ".|.|.|hand");

        if (!ints.isEmpty()) {
            LogMessage log;
            log.type = "#InvokeSkill";
            log.from = player;
            log.arg = objectName();
            room->sendLog(log);
            QList<const Card *> cards = player->getHandcards();
            QList<int> to_throw;
            foreach (const Card *c, cards) {
                int id = c->getId();
                if (!ints.contains(id) && player->canDiscard(player, id))
                    to_throw << id;
            }
            CardMoveReason reason(CardMoveReason::S_REASON_THROW, player->objectName(), QString(), objectName(), QString());
            CardsMoveStruct dis_move(to_throw, NULL, Player::DiscardPile, reason);
            QList<CardsMoveOneTimeStruct> moveOneTimes = room->moveCardsSub(dis_move, true);
            int x = 0;
            foreach (CardsMoveOneTimeStruct move, moveOneTimes) {
                if (move.from == player && move.reason.m_reason == CardMoveReason::S_REASON_THROW) {
                    for (int i = 0; i < move.card_ids.length(); ++i) {
                        const Card *card = Card::Parse(move.cards.at(i));
                        if (card && (move.from_places.at(i) == Player::PlaceHand || move.from_places.at(i) == Player::PlaceEquip)) {
                            x++;
                        }
                    }
                }
            }
            room->setPlayerMark(player, "yanzhengCount", x);

            return true;
        }

        return false;
    }

    virtual bool onPhaseChange(ServerPlayer *player) const
    {
        Room *room = player->getRoom();
        int x = player->getMark("yanzhengCount");
        room->setPlayerMark(player, "yanzhengCount", 0);
        if (x == 0) return false;

        QList<ServerPlayer *> choosees = room->askForPlayersChosen(player, room->getAlivePlayers(),
                             "yanzheng_damage", 1, x, "@yanzheng-damage:::" + QString::number(x));
        if (choosees.length() > 0) {
            room->sortByActionOrder(choosees);
            foreach (ServerPlayer *target, choosees) {
                room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, player->objectName(), target->objectName());
            }
            foreach (ServerPlayer *target, choosees) {
                room->damage(DamageStruct(objectName(), player, target));
            }

        }
        return false;
    }
};

FenglveCard::FenglveCard()
{
}

bool FenglveCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.isEmpty() && Self->canPindianTo(to_select);
}

void FenglveCard::onEffect(const CardEffectStruct &effect) const
{
    ServerPlayer *source = effect.from;
    ServerPlayer *target = effect.to;
    Room *room = source->getRoom();

    if (source->canPindianTo(target)) {

        PindianStruct *pd = source->pindianStruct(target, "fenglve", NULL);

        if (source->isDead() || target->isDead()) return;

        int x1 = pd->from_number,x2 = pd->to_number;

        if (x1 > x2 && !target->isNude()) {
            QList<int> to_get;
            QList<const Card *> cards = target->getCards("hej");

            if (cards.length() > 2) {

                QStringList handle_string;

                handle_string << "hej" << "hej";

                to_get = room->askForCardsChosen(target, target, handle_string, "fenglve");

            } else {
                foreach (const Card *c, cards) {
                    to_get << c->getEffectiveId();
                }
            }
            if (!to_get.isEmpty()) {
                CardMoveReason reason(CardMoveReason::S_REASON_GIVE, target->objectName(), source->objectName(), "fenglve", QString());
                reason.m_playerId = source->objectName();
                DummyCard dummy1(to_get);
                room->obtainCard(source, &dummy1, reason, false);
            }

        } else if (x1 < x2 && !source->isNude()) {

            target->setFlags("FenglveTarget");
            QString prompt = QString("@fenglve-give1::%1").arg(target->objectName());
            QList<int> ints = room->askForExchange(source, "fenglve_give", 1, 1, prompt);
            target->setFlags("-FenglveTarget");

            int card_id = -1;
            if (ints.isEmpty()) {
                card_id = source->getCards("he").first()->getEffectiveId();
            } else
                card_id = ints.first();

            CardMoveReason reason(CardMoveReason::S_REASON_GIVE, source->objectName(), target->objectName(), "fenglve", QString());
            room->moveCardTo(Sanguosha->getCard(card_id), target, Player::PlaceHand, reason);

        }
    }

    if (source->isAlive() && target->isAlive() &&
            (room->askForChoice(source, "fenglve", "yes+no", QVariant::fromValue(target),
                               "@fenglve-zongheng::"+target->objectName()) == "yes")) {

        room->acquireSkill(target, "fenglvezongheng", true, false);
    }
}

class FenglveViewAsSkill : public ZeroCardViewAsSkill
{
public:
    FenglveViewAsSkill() : ZeroCardViewAsSkill("fenglve")
    {

    }

    virtual bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("FenglveCard") && !player->isKongcheng();
    }

    virtual const Card *viewAs() const
    {
        FenglveCard *first = new FenglveCard;
        first->setSkillName(objectName());
        first->setShowSkill(objectName());
        return first;
    }
};

class Fenglve : public TriggerSkill
{
public:
    Fenglve() : TriggerSkill("fenglve")
    {
        events << EventPhaseStart;
        view_as_skill = new FenglveViewAsSkill;
    }

    virtual void record(TriggerEvent , Room *room, ServerPlayer *player, QVariant &) const
    {
        if (player->getPhase() == Player::NotActive) {
            room->detachSkillFromPlayer(player, "fenglvezongheng", false, false, false);
        }
    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *, QVariant &, ServerPlayer * &) const
    {
        return QStringList();
    }
};

FenglveZonghengCard::FenglveZonghengCard()
{
}

bool FenglveZonghengCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.isEmpty() && Self->canPindianTo(to_select);
}

void FenglveZonghengCard::onEffect(const CardEffectStruct &effect) const
{
    ServerPlayer *source = effect.from;
    ServerPlayer *target = effect.to;
    Room *room = source->getRoom();

    if (source->canPindianTo(target)) {

        PindianStruct *pd = source->pindianStruct(target, "fenglvezongheng", NULL);

        if (source->isDead() || target->isDead()) return;

        int x1 = pd->from_number,x2 = pd->to_number;

        if (x1 > x2 && !target->isNude()) {
            int card_id = room->askForCardChosen(target, target, "hej", "fenglve");
            CardMoveReason reason(CardMoveReason::S_REASON_GIVE, target->objectName(), source->objectName(), "fenglve", QString());
            reason.m_playerId = source->objectName();
            room->moveCardTo(Sanguosha->getCard(card_id), source, Player::PlaceHand, reason);

        } else if (x1 < x2 && !source->isNude()) {
            QList<int> ints;
            if (source->getCardCount(true) < 3) {
                ints = source->forceToDiscard(2, true, false);
            } else {
                target->setFlags("FenglveTarget");
                QString prompt = QString("@fenglve-give2::%1").arg(target->objectName());
                ints = room->askForExchange(source, "fenglve_give", 2, 2, prompt);
                target->setFlags("-FenglveTarget");
            }

            if (!ints.isEmpty()) {
                CardMoveReason reason(CardMoveReason::S_REASON_GIVE, source->objectName(), target->objectName(), "fenglve", QString());
                DummyCard dummy2(ints);
                room->obtainCard(target, &dummy2, reason, false);
            }
        }
    }
}

class FenglveZongheng : public ZeroCardViewAsSkill
{
public:
    FenglveZongheng() : ZeroCardViewAsSkill("fenglvezongheng")
    {

    }

    virtual bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("FenglveZonghengCard") && !player->isKongcheng();
    }

    virtual const Card *viewAs() const
    {
        FenglveZonghengCard *first = new FenglveZonghengCard;
        first->setSkillName(objectName());
        first->setShowSkill(objectName());
        return first;
    }
};


class Anyong : public TriggerSkill
{
public:
    Anyong() : TriggerSkill("anyong")
    {
        events << DamageCaused;
    }

    virtual TriggerList triggerable(TriggerEvent , Room *room, ServerPlayer *player, QVariant &data) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        if (damage.to && player != damage.to) {
            QList<ServerPlayer *> owners = room->findPlayersBySkillName(objectName());
            TriggerList skill_list;
            foreach (ServerPlayer *owner, owners)
                if (owner != damage.to && owner->isFriendWith(player) && !owner->hasFlag("anyongUsed"))
                    skill_list.insert(owner, QStringList(objectName()));
            return skill_list;
        }

        return TriggerList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *target, QVariant &data, ServerPlayer *player) const
    {
        player->tag["AnyongDamagedata"] = data;
        bool invoke = player->askForSkillInvoke(this, QVariant::fromValue(target));
        player->tag.remove("AnyongDamagedata");
        if (invoke) {
            room->setPlayerFlag(player, "anyongUsed");
            room->broadcastSkillInvoke(objectName(), player);

            return true;
        }

        return false;
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *, QVariant &data, ServerPlayer *player) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        if (damage.to->hasShownAllGenerals()) {
            room->loseHp(player);
            if (player->ownSkill("anyong"))
                room->detachSkillFromPlayer(player, "anyong", false, false, player->inHeadSkills("anyong"));
        } else if (damage.to->hasShownOneGeneral())  {
            room->askForDiscard(player, "anyong_discard", 2, 2, false, false, "@anyong-discard");
        }
        damage.damage+=damage.damage;

        data = QVariant::fromValue(damage);
        return false;
    }
};

class Guowu : public TriggerSkill
{
public:
    Guowu() : TriggerSkill("guowu")
    {
        events << EventPhaseStart << EventPhaseChanging;
    }

    virtual void record(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &) const
    {
        if (triggerEvent == EventPhaseChanging)
            room->setPlayerMark(player, "#guowu", 0);
    }

    virtual QStringList triggerable(TriggerEvent triggerEvent, Room *, ServerPlayer *player, QVariant &, ServerPlayer * &) const
    {
        if (triggerEvent == EventPhaseStart && TriggerSkill::triggerable(player)) {
            if (player->getPhase() == Player::Play && !player->isKongcheng())
                return QStringList(objectName());
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent , Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        if (player->askForSkillInvoke(this)) {
            room->broadcastSkillInvoke(objectName(), player);
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent , Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        room->showAllCards(player);
        QList<const Card *> handcards = player->getHandcards();
        QStringList types;
        foreach (const Card *card, handcards) {
            QString type_name = card->getType();
            if (!types.contains(type_name))
                types << type_name;
        }
        int x = types.length();
        room->setPlayerMark(player, "#guowu", x);
        if (x > 0) {
            int id = room->getRandomCardInPile("Slash", false);
            if (id > -1)
                player->obtainCard(Sanguosha->getCard(id));
        }
        return false;
    }
};

class GuowuEffect : public TriggerSkill
{
public:
    GuowuEffect() : TriggerSkill("#guowu-effect")
    {
        events << TargetChoosing;
    }

    virtual QStringList triggerable(TriggerEvent , Room *room, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        if (player->getMark("#guowu") > 2) {
            CardUseStruct use = data.value<CardUseStruct>();
            if ((use.card->isKindOf("Slash") || use.card->isNDTrick())) {
                QList<ServerPlayer *> targets = room->getUseExtraTargets(use);
                if (!targets.isEmpty())
                    return QStringList(objectName());

            }
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent , Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        QList<ServerPlayer *> targets = room->getUseExtraTargets(use);
        if (!targets.isEmpty()) {

            player->tag["GuowuUsedata"] = data;        //for AI

            QList<ServerPlayer *> choosees = room->askForPlayersChosen(player, targets, objectName(),
                    0, 2, "@guowu-add:::" + use.card->objectName());

            player->tag.remove("GuowuUsedata");        //for AI

            if (choosees.length() > 0) {

                LogMessage log;
                log.type = "$AddCardTarget";
                log.from = player;
                log.to = choosees;
                log.card_str = use.card->toString();
                log.arg = "guowu";
                room->sendLog(log);

                QStringList target_list = player->tag["guowu_target"].toStringList();

                QStringList names;
                foreach (ServerPlayer *p, choosees) {
                    room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, player->objectName(), p->objectName());
                    names << p->objectName();
                }

                target_list << names.join("+");

                player->tag["guowu_target"] = target_list;

                room->removePlayerMark(player, "#guowu");

                return true;
            }


        }
        return false;
    }

    virtual bool effect(TriggerEvent , Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        QStringList target_list = player->tag["guowu_target"].toStringList();
        if (target_list.isEmpty()) return false;
        QStringList target_names = target_list.takeLast().split("+");
        player->tag["guowu_target"] = target_list;

        QList<ServerPlayer *> targets;
        foreach (QString name, target_names) {
            ServerPlayer *target = room->findPlayerbyobjectName(name);
            if (target)
                targets << target;
        }
        CardUseStruct use = data.value<CardUseStruct>();
        use.to << targets;
        room->sortByActionOrder(use.to);
        data = QVariant::fromValue(use);

        return false;
    }
};

class GuowuTargetMod : public TargetModSkill
{
public:
    GuowuTargetMod() : TargetModSkill("#guowu-targetmod")
    {
        pattern = "^SkillCard";
    }

    virtual int getDistanceLimit(const Player *from, const Card *card, const Player *) const
    {
        if (!Sanguosha->matchExpPattern(pattern, from, card))
            return 0;

        if (from->getMark("#guowu") > 1)
            return 1000;
        else
            return 0;
    }
};

class WushuangLvlingqi : public TriggerSkill
{
public:
    WushuangLvlingqi() : TriggerSkill("wushuang_lvlingqi")
    {
        events << TargetChosen << TargetConfirmed << CardFinished;
        frequency = Compulsory;
    }

    virtual QStringList triggerable(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
    {
        if (player == NULL)
            return QStringList();
        CardUseStruct use = data.value<CardUseStruct>();
        if (triggerEvent == TargetChosen) {
            if (use.card && (use.card->isKindOf("Slash") || use.card->isKindOf("Duel"))) {
                if (TriggerSkill::triggerable(player)) {
                    QStringList targets;
                    foreach(ServerPlayer *to, use.to)
                        targets << to->objectName();
                    if (!targets.isEmpty())
                        return QStringList(objectName() + "->" + targets.join("+"));
                }
            }
        } else if (triggerEvent == TargetConfirmed) {
            if (!use.to.contains(player))
                return QStringList();

            if (use.card && use.card->isKindOf("Duel") && TriggerSkill::triggerable(player)) {
                return QStringList(objectName() + "->" + use.from->objectName());
            }
        } else if (triggerEvent == CardFinished) {
            if (use.card->isKindOf("Duel")) {
                foreach (ServerPlayer *lvbu, room->getAllPlayers()) {
                    if (lvbu->getMark("WushuangTarget") > 0)
                        room->setPlayerMark(lvbu, "WushuangTarget", 0);
                }
            }
            return QStringList();
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *target, QVariant &data, ServerPlayer *ask_who) const
    {
        ask_who->tag["WushuangData"] = data; // for AI
        ask_who->tag["WushuangTarget"] = QVariant::fromValue(target); // for AI
        bool invoke = false;
        if (ask_who->hasShownSkill(this)) {
            room->sendCompulsoryTriggerLog(ask_who, objectName());
            invoke = true;
        } else invoke = ask_who->askForSkillInvoke(this, QVariant::fromValue(target));

        ask_who->tag.remove("WushuangData");
        if (invoke) {
            room->broadcastSkillInvoke(objectName(), ask_who);
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent triggerEvent, Room *room, ServerPlayer *target, QVariant &data, ServerPlayer *ask_who) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (use.card->isKindOf("Slash")) {
            if (triggerEvent != TargetChosen) return false;
            int x = use.to.indexOf(target);
            QVariantList jink_list = ask_who->tag["Jink_" + use.card->toString()].toList();
            if (jink_list.at(x).toInt() == 1)
                jink_list[x] = 2;
            ask_who->tag["Jink_" + use.card->toString()] = jink_list;
        } else if (use.card->isKindOf("Duel"))
            room->setPlayerMark(ask_who, "WushuangTarget", 1);

        return false;
    }
};

ZhuangrongCard::ZhuangrongCard()
{
    target_fixed = true;
}

void ZhuangrongCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const
{
    room->acquireSkill(source, "wushuang_lvlingqi", true, false);
}

class ZhuangrongViewAsSkill : public OneCardViewAsSkill
{
public:
    ZhuangrongViewAsSkill() : OneCardViewAsSkill("zhuangrong")
    {
        filter_pattern = "TrickCard!";
    }

    virtual bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("ZhuangrongCard");
    }

    virtual const Card *viewAs(const Card *originalCard) const
    {
        ZhuangrongCard *first = new ZhuangrongCard;
        first->addSubcard(originalCard->getId());
        first->setSkillName(objectName());
        first->setShowSkill(objectName());
        return first;
    }
};

class Zhuangrong : public TriggerSkill
{
public:
    Zhuangrong() : TriggerSkill("zhuangrong")
    {
        events << EventPhaseChanging;
        view_as_skill = new ZhuangrongViewAsSkill;
    }

    virtual void record(TriggerEvent , Room *room, ServerPlayer *player, QVariant &) const
    {
        room->detachSkillFromPlayer(player, "wushuang_lvlingqi", false, false, false);
    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *, QVariant &, ServerPlayer * &) const
    {
        return QStringList();
    }
};

class Shenwei : public DrawCardsSkill
{
public:
    Shenwei() : DrawCardsSkill("shenwei")
    {
        relate_to_place = "head";
        frequency = Compulsory;
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        bool invoke = false;
        if (player->hasShownSkill(objectName())) {
            invoke = true;
            room->sendCompulsoryTriggerLog(player, objectName());
        } else
            invoke = player->askForSkillInvoke(this);

        if (invoke) {
            room->broadcastSkillInvoke(objectName(), player);
            return true;
        }
        return false;
    }

    virtual int getDrawNum(ServerPlayer *, int n) const
    {
        return n + 2;
    }
};

class ShenweiMaxCards : public MaxCardsSkill
{
public:
    ShenweiMaxCards() : MaxCardsSkill("#shenwei-maxcards")
    {
    }

    virtual int getExtra(const Player *target) const
    {
        if (target->hasShownSkills("shenwei"))
            return 2;
        else
            return 0;
    }
};

class Mingde : public TriggerSkill
{
public:
    Mingde() : TriggerSkill("mingde")
    {
        events << TargetChosen;
    }

    virtual TriggerList triggerable(TriggerEvent , Room *, ServerPlayer *player, QVariant &data) const
    {
        TriggerList skill_list;
        CardUseStruct use = data.value<CardUseStruct>();
        if (player && player->isAlive() && use.card->getTypeId() != Card::TypeSkill && use.card->isBlack()) {
            ServerPlayer *yanghu = NULL;
            foreach (ServerPlayer *to, use.to) {
                if (to->isAlive()) {
                    if (yanghu == NULL) {
                        yanghu = to;
                    } else if (yanghu != to)
                        return skill_list;
                }
            }
            if (yanghu && yanghu != player && TriggerSkill::triggerable(yanghu) && yanghu->canDiscard(player, "he")) {
                int x = 0, y = 0;
                if (yanghu->hasShownGeneral1()) x++;
                if (yanghu->hasShownGeneral2()) x++;
                if (player->hasShownGeneral1()) y++;
                if (player->hasShownGeneral2()) y++;
                if (x >= y)
                    skill_list.insert(yanghu, QStringList(objectName()));
            }
        }
        return skill_list;
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *yanghu) const
    {
        yanghu->tag["MingdeUsedata"] = data;
        bool invoke = yanghu->askForSkillInvoke(this, QVariant::fromValue(player));
        yanghu->tag.remove("MingdeUsedata");

        if (invoke) {
            room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, yanghu->objectName(), player->objectName());
            room->broadcastSkillInvoke(objectName(), yanghu);
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *yanghu) const
    {
        if (yanghu->canDiscard(player, "he")) {
            int id = room->askForCardChosen(yanghu, player, "he", objectName(), false, Card::MethodDiscard);
            room->throwCard(id, player, yanghu);
        }
        return false;
    }
};

QizhanCard::QizhanCard()
{
}

bool QizhanCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.isEmpty() && !Self->willBeFriendWith(to_select);
}

void QizhanCard::onEffect(const CardEffectStruct &effect) const
{
    ServerPlayer *source = effect.from;
    ServerPlayer *target = effect.to;
    Room *room = source->getRoom();

    QStringList target_list = source->tag["QizhanTarget"].toStringList();
    target_list.append(target->objectName());
    source->tag["QizhanTarget"] = target_list;
    room->addPlayerMark(target, "##qizhan");

    if (source->isAlive() && target->isAlive() &&
            (room->askForChoice(source, "qizhan", "yes+no", QVariant::fromValue(target),
                               "@qizhan-zongheng::"+target->objectName()) == "yes")) {

        room->acquireSkill(target, "qizhanzongheng", true, false);
    }
}

class QizhanViewAsSkill : public ZeroCardViewAsSkill
{
public:
    QizhanViewAsSkill() : ZeroCardViewAsSkill("qizhan")
    {

    }

    virtual bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("QizhanCard");
    }

    virtual const Card *viewAs() const
    {
        QizhanCard *first = new QizhanCard;
        first->setSkillName(objectName());
        first->setShowSkill(objectName());
        return first;
    }
};

class Qizhan : public TriggerSkill
{
public:
    Qizhan() : TriggerSkill("qizhan")
    {
        events << EventPhaseStart;
        view_as_skill = new QizhanViewAsSkill;
    }

    virtual void record(TriggerEvent , Room *room, ServerPlayer *player, QVariant &) const
    {
        if (player->getPhase() == Player::NotActive) {
            room->detachSkillFromPlayer(player, "qizhanzongheng", false, false, false);
            room->setPlayerMark(player, "##qizhan", 0);
            QList<ServerPlayer *> players = room->getAlivePlayers();
            foreach (ServerPlayer *p, players) {
                QStringList target_list = p->tag["QizhanTarget"].toStringList();
                target_list.removeAll(player->objectName());
                p->tag["QizhanTarget"] = target_list;
            }
        }
    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *, QVariant &, ServerPlayer * &) const
    {
        return QStringList();
    }
};

class QizhanEffect : public TriggerSkill
{
public:
    QizhanEffect() : TriggerSkill("#qizhan-effect")
    {
        events << EventPhaseChanging;
    }

    virtual TriggerList triggerable(TriggerEvent , Room *room, ServerPlayer *player, QVariant &data) const
    {
        TriggerList skill_list;
        PhaseChangeStruct change = data.value<PhaseChangeStruct>();
        if (change.to == Player::NotActive && player->isAlive()) {
            QList<ServerPlayer *> players = room->getAlivePlayers();
            foreach (ServerPlayer *p, players) {
                QStringList target_list = p->tag["QizhanTarget"].toStringList();
                if (target_list.contains(player->objectName()) && player->getHandcardNum() < p->getHandcardNum()) {
                    skill_list.insert(p, QStringList(objectName()));
                }
            }
        }
        return skill_list;
    }

    virtual bool cost(TriggerEvent, Room *, ServerPlayer *, QVariant &, ServerPlayer *) const
    {
        return true;
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *yanghu) const
    {
        LogMessage log;
        log.type = "#QizhanEffect";
        log.from = yanghu;
        log.to << player;
        log.arg = "qizhan";
        room->sendLog(log);
        room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, yanghu->objectName(), player->objectName());
        room->damage(DamageStruct("qizhan", yanghu, player));
        if (yanghu->isAlive() && player->isAlive() && yanghu->canGetCard(player, "h")) {
            int card_id = room->askForCardChosen(yanghu, player, "h", "qizhan", false, Card::MethodGet);
            CardMoveReason reason(CardMoveReason::S_REASON_EXTRACTION, yanghu->objectName());
            room->obtainCard(yanghu, Sanguosha->getCard(card_id), reason, false);
        }
        return false;
    }
};

QizhanZonghengCard::QizhanZonghengCard()
{
}

bool QizhanZonghengCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.isEmpty() && !Self->isFriendWith(to_select);
}

void QizhanZonghengCard::onEffect(const CardEffectStruct &effect) const
{
    ServerPlayer *source = effect.from;
    ServerPlayer *target = effect.to;
    Room *room = source->getRoom();

    QStringList target_list = source->tag["QizhanTarget"].toStringList();
    target_list.append(target->objectName());
    source->tag["QizhanTarget"] = target_list;
    room->addPlayerMark(target, "##qizhan");
}

class QizhanZongheng : public OneCardViewAsSkill
{
public:
    QizhanZongheng() : OneCardViewAsSkill("qizhanzongheng")
    {
        filter_pattern = ".!";
    }

    virtual bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("QizhanZonghengCard");
    }

    virtual const Card *viewAs(const Card *originalCard) const
    {
        QizhanZonghengCard *first = new QizhanZonghengCard;
        first->addSubcard(originalCard);
        return first;
    }
};











ManoeuvrePackage::ManoeuvrePackage()
    : Package("manoeuvre")
{
    General *huaxin = new General(this, "huaxin", "wei", 3);
    huaxin->addSkill(new Wanggui);
    huaxin->addSkill(new Xibing);

    General *luyusheng = new General(this, "luyusheng", "wu", 3, false);
    luyusheng->addSkill(new Zhente);
    luyusheng->addSkill(new Zhiwei);
    luyusheng->addSkill(new ZhiweiEffect);
    insertRelatedSkills("zhiwei", "#zhiwei-effect");

    General *zongyux = new General(this, "zongyux", "shu", 3);
    zongyux->addSkill(new Qiao);
    zongyux->addSkill(new Chengshang);

    General *miheng = new General(this, "miheng", "qun", 3);
    miheng->addSkill(new Kuangcai);
    miheng->addSkill(new KuangcaiTarget);
    miheng->addSkill(new Shejian);
    insertRelatedSkills("kuangcai", "#kuangcai-target");

    General *fengxi = new General(this, "fengxi", "wu", 3);
    fengxi->addSkill(new Yusui);
    fengxi->addSkill(new Boyan);

    General *dengzhi = new General(this, "dengzhi", "shu", 3);
    dengzhi->addSkill(new Jianliang);
    dengzhi->addSkill(new Weimeng);

    General *xunchen = new General(this, "xunchen", "qun", 3);
    xunchen->addSkill(new Fenglve);
    xunchen->addSkill(new Anyong);

    General *yanghu = new General(this, "yanghu", "wei", 3);
    yanghu->addSkill(new Mingde);
    yanghu->addSkill(new Qizhan);
    yanghu->addSkill(new QizhanEffect);
    insertRelatedSkills("qizhan", "#qizhan-effect");

    addMetaObject<BoyanCard>();
    addMetaObject<BoyanZonghengCard>();
    addMetaObject<WeimengCard>();
    addMetaObject<WeimengZonghengCard>();
    addMetaObject<FenglveCard>();
    addMetaObject<FenglveZonghengCard>();
    addMetaObject<QizhanCard>();
    addMetaObject<QizhanZonghengCard>();

    skills << new BoyanZongheng << new WeimengZongheng << new FenglveZongheng << new QizhanZongheng;
}

NewSGSPackage::NewSGSPackage()
    : Package("newsgs")
{
    General *jianggan = new General(this, "jianggan", "wei", 3);
    jianggan->addSkill(new Weicheng);
    jianggan->addSkill(new Daoshu);

    General *zhouyi = new General(this, "zhouyi", "wu", 3, false);
    zhouyi->addSkill(new Zhukou);
    zhouyi->addSkill(new Duannian);
    zhouyi->addSkill(new Lianyou);
    zhouyi->addRelateSkill("xinghuo");

    General *nanhualaoxian = new General(this, "nanhualaoxian", "qun");
    nanhualaoxian->addSkill(new Gongxiu);
    nanhualaoxian->addSkill(new Jinghe);
    nanhualaoxian->addRelateSkill("leiji_tianshu");
    nanhualaoxian->addRelateSkill("yinbing");
    nanhualaoxian->addRelateSkill("huoqi");
    nanhualaoxian->addRelateSkill("guizhu");
    nanhualaoxian->addRelateSkill("xianshou");
    nanhualaoxian->addRelateSkill("lundao");
    nanhualaoxian->addRelateSkill("guanyue");
    nanhualaoxian->addRelateSkill("yanzheng");

    General *lvlingqi = new General(this, "lvlingqi", "qun", 4, false);
    lvlingqi->setHeadMaxHpAdjustedValue();
    lvlingqi->addSkill(new Guowu);
    lvlingqi->addSkill(new GuowuEffect);
    lvlingqi->addSkill(new GuowuTargetMod);
    insertRelatedSkills("guowu", 2, "#guowu-effect", "#guowu-targetmod");
    lvlingqi->addSkill(new Zhuangrong);
    lvlingqi->addRelateSkill("wushuang_lvlingqi");
    lvlingqi->addSkill(new Shenwei);
    lvlingqi->addSkill(new ShenweiMaxCards);
    insertRelatedSkills("shenwei", "#shenwei-maxcards");


    addMetaObject<DaoshuCard>();
    addMetaObject<JingheCard>();
    addMetaObject<HuoqiCard>();
    addMetaObject<XianshouCard>();
    addMetaObject<ZhuangrongCard>();



    skills << new Xinghuo << new LeijiTianshu << new Yinbing << new Huoqi << new Guizhu << new Xianshou << new Lundao
           << new Guanyue << new Yanzheng << new WushuangLvlingqi;
}
