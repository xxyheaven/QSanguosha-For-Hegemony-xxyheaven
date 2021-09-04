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
                room->setPlayerMark(p, "#xibing", 0);
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
            room->addPlayerTip(player, "#xibing");
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
        if (player->askForSkillInvoke(this, QVariant::fromValue(use.from))) {
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

        QString choice = room->askForChoice(use.from, objectName(), "nullified+cardlimited", data, prompt);

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
        if (use.from && (!player->hasShownOneGeneral() || (use.from->hasShownOneGeneral() && !player->isFriendWith(use.from))) && !use.from->isNude()) {
            return QStringList(objectName());
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (player->askForSkillInvoke(this, QVariant::fromValue(use.from))) {
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
        if (!TriggerSkill::triggerable(player) || triggerEvent != CardFinished || !player->hasShownOneGeneral()
                || player->getPhase() != Player::Play || player->hasFlag("ChengshangUsed")) return QStringList();
        CardUseStruct use = data.value<CardUseStruct>();
        if (use.card->getTypeId() == Card::TypeSkill || !use.card->tag["GlobalCardDamagedTag"].isNull()) return QStringList();
        foreach (ServerPlayer *to, use.to) {
            if (to->isAlive() && to->hasShownOneGeneral() && !to->isFriendWith(player))
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
            if (x > 0 && y == 0)
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
        if (player->askForSkillInvoke(this, QVariant::fromValue(use.from))) {
            room->broadcastSkillInvoke(objectName(), player);
            room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, player->objectName(), use.from->objectName());
            return true;
        }

        return false;
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        player->throwAllHandCards();
        CardUseStruct use = data.value<CardUseStruct>();
        if (use.from && use.from->isAlive())
            room->damage(DamageStruct(objectName(), player, use.from));
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
                && (use.from && !use.from->isFriendWith(player) && use.from->isAlive()))
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

bool BoyanCard::targetFilter(const QList<const Player *> &targets, const Player *, const Player *) const
{
    return targets.isEmpty();
}

void BoyanCard::onEffect(const CardEffectStruct &effect) const
{
    ServerPlayer *target = effect.to;
    target->fillHandCards(target->getMaxHp(), "boyan");
    target->getRoom()->setPlayerCardLimitation(target, "use,response", ".|.|.|hand", true);
}

class Boyan : public ZeroCardViewAsSkill
{
public:
    Boyan() : ZeroCardViewAsSkill("boyan")
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


    addMetaObject<BoyanCard>();
}

