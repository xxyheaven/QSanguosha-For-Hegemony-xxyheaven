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

#include "power.h"
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

#include "standard-shu-generals.h"
#include "standard-wei-generals.h"



class CommandSelect : public ViewAsSkill
{
public:
    CommandSelect() : ViewAsSkill("commandefect")
    {
        response_pattern = "@@commandefect!";
    }

    virtual bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const
    {
        return selected.isEmpty() || (selected.length() == 1 && to_select->isEquipped() != selected.first()->isEquipped());
    }

    virtual const Card *viewAs(const QList<const Card *> &cards) const
    {
        bool ok = false;
        if (cards.length() == 1) {
            if (cards.first()->isEquipped())
                ok = Self->isKongcheng();
            else
                ok = !Self->hasEquip();
        } else if (cards.length() == 2) {
            ok = true;
        }

        if (!ok)
            return NULL;

        DummyCard *dummy = new DummyCard;
        dummy->addSubcards(cards);
        return dummy;
    }
};

class CommandEffect : public TriggerSkill
{
public:
    CommandEffect() : TriggerSkill("commandefect")
    {
        events << EventPhaseStart;
        view_as_skill = new CommandSelect;
        global = true;
    }

    virtual void record(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &) const
    {
        if (triggerEvent == EventPhaseStart && player->getPhase() ==  Player::NotActive) {
            QList<ServerPlayer *> alls = room->getAlivePlayers();
            foreach (ServerPlayer *p, alls) {
                room->setPlayerMark(p, "JieyueExtraDraw", 0);
                if (p->getMark("command4_effect") > 0) {
                    room->setPlayerMark(p, "command4_effect", 0);

                    foreach(ServerPlayer *p, room->getAllPlayers())
                        room->filterCards(p, p->getCards("he"), false);

                    JsonArray args;
                    args << QSanProtocol::S_GAME_EVENT_UPDATE_SKILL;
                    room->doBroadcastNotify(QSanProtocol::S_COMMAND_LOG_EVENT, args);

                    room->removePlayerCardLimitation(p, "use,response", ".|.|.|hand$1");
                }
                if (p->getMark("command5_effect") > 0) {
                    room->setPlayerMark(p, "command5_effect", 0);
                    p->tag["CannotRecover"] = false;
                }
                JsonArray arg;
                arg << QSanProtocol::S_GAME_EVENT_UPDATE_ROLEBOX;
                room->doBroadcastNotify(QSanProtocol::S_COMMAND_LOG_EVENT, arg);
            }
        }
    }

    virtual QStringList triggerable(TriggerEvent , Room *, ServerPlayer *, QVariant &, ServerPlayer * &) const
    {
        return QStringList();
    }

};




ZhengbiCard::ZhengbiCard()
{
    will_throw = false;
    handling_method = Card::MethodNone;
}

bool ZhengbiCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    if (!targets.isEmpty() || to_select == Self) return false;
    if (subcardsLength() == 0) return !to_select->hasShownOneGeneral();
    return to_select->hasShownOneGeneral();
}

void ZhengbiCard::extraCost(Room *room, const CardUseStruct &card_use) const
{
    if (subcardsLength() == 0) return;
    ServerPlayer *target = card_use.to.first();
    CardMoveReason reason(CardMoveReason::S_REASON_GIVE, card_use.from->objectName(), target->objectName(), "zhengbi", QString());
    room->obtainCard(target, this, reason, true);
}

void ZhengbiCard::onEffect(const CardEffectStruct &effect) const
{
    effect.to->setFlags("ZhengbiTo");
}

class ZhengbiViewAsSkill : public ViewAsSkill
{
public:
    ZhengbiViewAsSkill() : ViewAsSkill("zhengbi")
    {
        response_pattern = "@@zhengbi";
    }

    virtual bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const
    {
        return selected.isEmpty() && to_select->getTypeId() == Card::TypeBasic;
    }

    virtual const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (cards.length() > 1) return NULL;

        ZhengbiCard *zhengbi_card = new ZhengbiCard;
        zhengbi_card->addSubcards(cards);
        return zhengbi_card;
    }
};

class Zhengbi : public TriggerSkill
{
public:
    Zhengbi() : TriggerSkill("zhengbi")
    {
        events << EventPhaseStart;
        view_as_skill = new ZhengbiViewAsSkill;
    }

    virtual bool canPreshow() const
    {
        return true;
    }

    virtual void record(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &) const
    {
        if (triggerEvent == EventPhaseStart && player->getPhase()== Player::NotActive) {
            foreach (ServerPlayer *p, room->getAlivePlayers())
                room->setPlayerProperty(p, "zhengbi_targets", QVariant());
        }
    }

    virtual QStringList triggerable(TriggerEvent triggerEvent, Room *, ServerPlayer *player, QVariant &, ServerPlayer * &) const
    {
        if (triggerEvent == EventPhaseStart && player->getPhase() == Player::Play) {
            if (TriggerSkill::triggerable(player))
                return QStringList(objectName());
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        return room->askForUseCard(player, "@@zhengbi", "@zhengbi", -1, Card::MethodNone);
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        QList<ServerPlayer *> players = room->getOtherPlayers(player);
        foreach (ServerPlayer *p, players) {
            if (p->hasFlag("ZhengbiTo")) {
                p->setFlags("-ZhengbiTo");
                if (p->hasShownOneGeneral()) {
                    if (p->isNude()) return false;
                    QList<int> to_give;

                    QList<const Card *> cards = p->getCards("he");

                    int trickId = -1;
                    foreach (const Card *c, cards) {
                        if (c->getTypeId() != Card::TypeBasic) {
                            trickId = c->getId();
                            break;
                        }
                    }
                    if (trickId != -1)
                        to_give << trickId;
                    else {
                        foreach (const Card *c, cards) {
                            to_give << c->getId();
                            if (to_give.length() > 1) break;
                        }
                    }

                    if (p->getCardCount(true) > 1) {
                        const Card *card = room->askForCard(p, "@@zhengbigive!", "@zhengbi-give:"+player->objectName(), QVariant(), Card::MethodNone);
                        if (card != NULL)
                            to_give = card->getSubcards();
                    }

                    DummyCard *dummy_card = new DummyCard(to_give);
                    dummy_card->deleteLater();

                    CardMoveReason reason(CardMoveReason::S_REASON_GIVE, p->objectName(), player->objectName(), objectName(), QString());
                    room->obtainCard(player, dummy_card, reason, true);
                } else {

                    QStringList assignee_list = player->property("zhengbi_targets").toString().split("+");
                    assignee_list << p->objectName();
                    room->setPlayerProperty(player, "zhengbi_targets", assignee_list.join("+"));

                }
            }
        }
        return false;
    }
};


class ZhengbiGive : public ViewAsSkill
{
public:
    ZhengbiGive() : ViewAsSkill("zhengbigive")
    {
        response_pattern = "@@zhengbigive!";
    }

    virtual bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const
    {
        if (selected.length() == 0)
            return true;
        else if (selected.length() == 1) {
            return (selected.first()->getTypeId() == Card::TypeBasic && to_select->getTypeId() == Card::TypeBasic);
        }
        return false;
    }

    virtual const Card *viewAs(const QList<const Card *> &cards) const
    {
        bool ok = false;
        if (cards.length() == 1)
            ok = cards.first()->getTypeId() != Card::TypeBasic;
        else if (cards.length() == 2) {
            ok = true;
            foreach (const Card *c, cards) {
                if (c->getTypeId() != Card::TypeBasic) {
                    ok = false;
                    break;
                }
            }
        }

        if (!ok) return NULL;

        DummyCard *dummy = new DummyCard;
        dummy->addSubcards(cards);
        return dummy;
    }
};

class ZhengbiTargetMod : public TargetModSkill
{
public:
    ZhengbiTargetMod() : TargetModSkill("#zhengbi-target")
    {
        pattern = "^SkillCard";
    }

    virtual int getResidueNum(const Player *from, const Card *card, const Player *to) const
    {
        if (!Sanguosha->matchExpPattern(pattern, from, card))
            return 0;

        QStringList assignee_list = from->property("zhengbi_targets").toString().split("+");
        if (to && assignee_list.contains(to->objectName()) && !to->hasShownOneGeneral())
            return 10000;
        return 0;
    }

    virtual int getDistanceLimit(const Player *from, const Card *card, const Player *to) const
    {
        if (!Sanguosha->matchExpPattern(pattern, from, card))
            return 0;

        QStringList assignee_list = from->property("zhengbi_targets").toString().split("+");
        if (to && assignee_list.contains(to->objectName()) && !to->hasShownOneGeneral())
            return 10000;
        return 0;
    }

};


FengyingCard::FengyingCard()
{
    target_fixed = true;
    will_throw = false;
}

const Card *FengyingCard::validate(CardUseStruct &card_use) const
{
    ThreatenEmperor *te = new ThreatenEmperor(Card::SuitToBeDecided, 0);
    te->addSubcards(card_use.from->getHandcards());
    te->setSkillName("fengying");
    te->setShowSkill("fengying");
    return te;
}

class Fengying : public ZeroCardViewAsSkill
{
public:
    Fengying() : ZeroCardViewAsSkill("fengying")
    {
        frequency = Limited;
        limit_mark = "@honor";
    }

    virtual const Card *viewAs() const
    {
        return new FengyingCard;
    }

    virtual bool isEnabledAtPlay(const Player *player) const
    {
        if (player->getMark("@honor") < 1 || player->isKongcheng()) return false;
        ThreatenEmperor *te = new ThreatenEmperor(Card::SuitToBeDecided, 0);
        te->addSubcards(player->getHandcards());
        te->setSkillName(objectName());
        return !player->isProhibited(player, te) && !player->isLocked(te);
    }

    virtual int getEffectIndex(const ServerPlayer *, const Card *card) const
    {
        return card->isKindOf("ThreatenEmperor") ? 0 : -1;
    }
};

class FengyingAfter : public TriggerSkill
{
public:
    FengyingAfter() : TriggerSkill("#fengying-after")
    {
        events << CardUsed << PreCardUsed;
        frequency = Compulsory;
    }

    virtual void record(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (player != NULL && player->isAlive() && triggerEvent == PreCardUsed) {
            const Card *card = data.value<CardUseStruct>().card;
            if (card != NULL && card->getSkillName() == "fengying") {
                room->setPlayerMark(player, "@honor", 0);
                room->broadcastSkillInvoke("fengying", player);
                room->doSuperLightbox("cuiyanmaojie", "fengying");
            }
        }
    }

    virtual QStringList triggerable(TriggerEvent triggerEvent, Room *, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        if (triggerEvent != CardUsed || player == NULL || player->isDead()) return QStringList();

        const Card *card = data.value<CardUseStruct>().card;

        if (card != NULL && card->getSkillName() == "fengying")
            return QStringList(objectName());


        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *, ServerPlayer *, QVariant &, ServerPlayer *) const
    {
        return true;
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        QList<ServerPlayer *> players, all_players = room->getAlivePlayers();

        foreach (ServerPlayer *p, all_players) {
           if (p->isFriendWith(player))
               players << p;
        }
        if (players.isEmpty()) return false;
        room->sortByActionOrder(players);
        foreach (ServerPlayer *p, players)
            room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, player->objectName(), p->objectName());

        foreach (ServerPlayer *to, players) {
            if (to->isAlive()) {
                int x = to->getMaxHp() - to->getHandcardNum();
                if (x > 0)
                    to->drawCards(x);
            }
        }
        return false;
    }
};

JieyueCard::JieyueCard()
{
    will_throw = false;
    handling_method = Card::MethodNone;
}

bool JieyueCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.isEmpty() && to_select->getSeemingKingdom() != "wei" && to_select != Self;
}

void JieyueCard::onUse(Room *, const CardUseStruct &card_use) const
{
    ServerPlayer *target = card_use.to.first();

    target->setFlags("JieyueTarget");
}

class JieyueViewAsSkill : public OneCardViewAsSkill
{
public:
    JieyueViewAsSkill() : OneCardViewAsSkill("jieyue")
    {
        filter_pattern = ".|.|.|hand";
        response_pattern = "@@jieyue";
    }

    virtual const Card *viewAs(const Card *originalCard) const
    {
        JieyueCard *jieyue_card = new JieyueCard;
        jieyue_card->addSubcard(originalCard);
        return jieyue_card;
    }
};

class Jieyue : public PhaseChangeSkill
{
public:
    Jieyue() : PhaseChangeSkill("jieyue")
    {
        view_as_skill = new JieyueViewAsSkill;
    }

    virtual bool canPreshow() const
    {
        return true;
    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *player, QVariant &, ServerPlayer* &) const
    {
        if (!PhaseChangeSkill::triggerable(player) || player->isKongcheng()) return QStringList();
        if (player->getPhase() == Player::Start) return QStringList(objectName());
        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        const Card *card = room->askForUseCard(player, "@@jieyue", "@jieyue", -1, Card::MethodNone);
        if (card) {
            QList<ServerPlayer *> players = player->getRoom()->getOtherPlayers(player);
            foreach (ServerPlayer *target, players) {
                if (target->hasFlag("JieyueTarget")) {
                    room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, player->objectName(), target->objectName());
                    LogMessage log;
                    log.type = "#ChoosePlayerWithSkill";
                    log.from = player;
                    log.to << target;
                    log.arg = objectName();
                    room->sendLog(log);
                    room->notifySkillInvoked(player, objectName());
                    room->broadcastSkillInvoke(objectName(), player);
                    CardMoveReason reason(CardMoveReason::S_REASON_GIVE, player->objectName(), target->objectName(), "jieyue", QString());
                    room->obtainCard(target, card, reason, false);
                    return true;
                }
            }

        }
        return false;
    }

    virtual bool onPhaseChange(ServerPlayer *player) const
    {
        Room *room = player->getRoom();
        QList<ServerPlayer *> players = room->getOtherPlayers(player);
        foreach (ServerPlayer *p, players) {
            if (p->hasFlag("JieyueTarget")) {
                p->setFlags("-JieyueTarget");
                if (player->askCommandto("jieyue", p))
                    player->drawCards(1, "jieyue");
                else {
                    room->addPlayerMark(player, "JieyueExtraDraw");      //in gamerule
                }
            }
        }
        return false;
    }
};

JianglveCard::JianglveCard()
{
    mute = true;
    target_fixed = true;
}

void JianglveCard::onUse(Room *room, const CardUseStruct &card_use) const
{
    room->setPlayerMark(card_use.from, "@strategy", 0);
    room->broadcastSkillInvoke("jianglve", card_use.from);
    room->doSuperLightbox("wangping", "jianglve");
    SkillCard::onUse(room, card_use);
}

void JianglveCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const
{
    int index = source->startCommand("jianglve");

    QList<ServerPlayer *> alls = room->getAlivePlayers();
    room->sortByActionOrder(alls);

    /*
    // summon all lieges
    foreach(ServerPlayer *anjiang, alls) {
        if (anjiang->hasShownOneGeneral()) continue;

        QString kingdom = source->getKingdom();
        ServerPlayer *lord = NULL;

        int num = 0;
        foreach (ServerPlayer *p, room->getAllPlayers(true)) {
            if (p->getKingdom() != kingdom) continue;
            QStringList list = room->getTag(p->objectName()).toStringList();
            if (!list.isEmpty()) {
                const General *general = Sanguosha->getGeneral(list.first());
                if (general->isLord())
                    lord = p;
            }
            if (p->hasShownOneGeneral() && p->getRole() != "careerist")
                num++;
        }

        bool full = (source->getRole() == "careerist" || ((lord == NULL || !lord->hasShownGeneral1()) && num >= room->getPlayers().length() / 2));

        bool can_show = false, can_only_dupty = false;

        if (anjiang->getKingdom() == kingdom) {
            if (full) {
                if (lord == anjiang)
                    can_show = true;
            } else {
                if (anjiang->getActualGeneral1()->getKingdom() != "careerist")
                    can_show = true;
                can_only_dupty = true;
            }
        }

        anjiang->askForGeneralShow("jianglve", can_show, can_only_dupty, can_show, true);
    }

    */

    QList<ServerPlayer *> responsers, all_lieges;

    foreach(ServerPlayer *p, alls) {
        if (p->isFriendWith(source) && p != source)
            all_lieges << p;
    }

    foreach (ServerPlayer *p, all_lieges) {
        if (source->isDead()) break;
        if (p->isAlive() && p->doCommand("jianglve", index, source))
            responsers << p;
    }

    int x = 0;

    responsers.prepend(source);

    foreach(ServerPlayer *p, responsers) {
        if (p->isDead()) continue;

        room->setPlayerProperty(p, "maxhp", p->getMaxHp() + 1);

        LogMessage log;
        log.type = "#GainMaxHp";
        log.from = p;
        log.arg = QString::number(1);
        room->sendLog(log);

        if (p->canRecover()) {
            x++;
            RecoverStruct recover;
            recover.who = source;
            room->recover(p, recover);
        }
    }

    if (x > 0 && source->isAlive())
        source->drawCards(x, "jianglve");

}

class Jianglve : public ZeroCardViewAsSkill
{
public:
    Jianglve() : ZeroCardViewAsSkill("jianglve")
    {
        frequency = Limited;
        limit_mark = "@strategy";
    }

    virtual bool isEnabledAtPlay(const Player *player) const
    {
        return player->getMark("@strategy") >= 1;
    }

    virtual const Card *viewAs() const
    {
        JianglveCard *card = new JianglveCard;
        card->setShowSkill(objectName());
        return card;
    }
};

class Enyuan : public TriggerSkill
{
public:
    Enyuan() : TriggerSkill("enyuan")
    {
        events << TargetConfirmed << Damaged;
        frequency = Compulsory;
    }

    virtual QStringList triggerable(TriggerEvent triggerEvent, Room *, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
    {
        if (!TriggerSkill::triggerable(player)) return QStringList();
        if (triggerEvent == TargetConfirmed) {
            CardUseStruct use = data.value<CardUseStruct>();
            if (use.card->isKindOf("Peach") && use.from != player && use.from->isAlive())
                return QStringList(objectName());
        } else if (triggerEvent == Damaged) {
            DamageStruct damage = data.value<DamageStruct>();
            if (damage.from && damage.from->isAlive()) return QStringList(objectName());
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        ServerPlayer *target = NULL;
        if (triggerEvent == Damaged) {
            DamageStruct damage = data.value<DamageStruct>();
            target = damage.from;
        } else if (triggerEvent == TargetConfirmed) {
            CardUseStruct use = data.value<CardUseStruct>();
            target = use.from;
        }
        if (!target || target->isDead()) return false;

        bool invoke = false;
        if (player->hasShownSkill(objectName())) {
            invoke = true;
            room->sendCompulsoryTriggerLog(player, objectName());
        } else {
            invoke = player->askForSkillInvoke(this, QVariant::fromValue(target));
        }

        if (invoke) {
            room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, player->objectName(), target->objectName());
            int x = qrand()%2+1;
            if (triggerEvent == Damaged) x=x+2;
            room->broadcastSkillInvoke(objectName(), x, player);
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (triggerEvent == TargetConfirmed) {
            CardUseStruct use = data.value<CardUseStruct>();
            ServerPlayer *target = use.from;
            if (!target || target->isDead()) return false;
            target->drawCards(1, objectName());
        } else if (triggerEvent == Damaged) {
            DamageStruct damage = data.value<DamageStruct>();
            ServerPlayer *target = damage.from;
            if (!target || target->isDead()) return false;

            if (target == player) {
                room->loseHp(target);
            } else {

                QList<int> result = room->askForExchange(target, "_enyuan", 1, 0, "@enyuan-give:"+ player->objectName(), "", ".|.|.|hand");
                if (result.isEmpty())
                    room->loseHp(target);
                else {
                    DummyCard dummy(result);
                    CardMoveReason reason(CardMoveReason::S_REASON_GIVE, target->objectName(), player->objectName(), objectName(), QString());
                    reason.m_playerId = player->objectName();
                    room->obtainCard(player, &dummy, reason, false);
                }
            }

        }
        return false;
    }
};

class Xuanhuo : public TriggerSkill
{
public:
    Xuanhuo() : TriggerSkill("xuanhuo")
    {
        events << GeneralShown << GeneralHidden << EventAcquireSkill << EventLoseSkill << Death << DFDebut;
    }

    virtual bool canPreshow() const
    {
        return false;
    }

    virtual void record(TriggerEvent , Room *room, ServerPlayer *, QVariant &) const
    {
        doXuanhuoAttach(room);
    }

    virtual QStringList triggerable(TriggerEvent , Room *, ServerPlayer *, QVariant &, ServerPlayer* &) const
    {
        return QStringList();
    }

private:
    static void doXuanhuoAttach(Room *room)
    {
        QMap<ServerPlayer *, bool> xuanhuo_map;
        QList<ServerPlayer *> players = room->getAlivePlayers(), fazhengs;
        foreach(ServerPlayer *p, players) {
            if (hasShownXuanhuo(p))
                fazhengs << p;
        }
        foreach(ServerPlayer *p, players) {
            bool will_attach = false;
            foreach(ServerPlayer *fazheng, fazhengs) {
                if (fazheng != p && fazheng->isFriendWith(p)) {
                    will_attach = true;
                    break;
                }
            }
            xuanhuo_map.insert(p, will_attach);
        }
        foreach (ServerPlayer *p, xuanhuo_map.keys()) {
            bool will_attach = xuanhuo_map.value(p, false);
            if (will_attach == p->getAcquiredSkills().contains("xuanhuoattach")) continue;

            if (will_attach)
                room->attachSkillToPlayer(p, "xuanhuoattach");
            else
                room->detachSkillFromPlayer(p, "xuanhuoattach");

        }
    }

    static bool hasShownXuanhuo(ServerPlayer *player)
    {
        if (player->getAcquiredSkills("all").contains("xuanhuo")) return true;
        if (player->inHeadSkills("xuanhuo") && player->hasShownGeneral1()) return true;
        if (player->getGeneral2() && player->inDeputySkills("xuanhuo") && player->hasShownGeneral2()) return true;
        return false;
    }

};

XuanhuoAttachCard::XuanhuoAttachCard()
{
    target_fixed = true;
    handling_method = Card::MethodNone;
}

void XuanhuoAttachCard::onUse(Room *room, const CardUseStruct &card_use) const
{
    ServerPlayer *shu = card_use.from;

    ServerPlayer *fazheng = room->findPlayerBySkillName("xuanhuo");
    if (!fazheng || fazheng->isDead() || !fazheng->isFriendWith(shu)) return;

    CardUseStruct new_use = card_use;
    new_use.to << fazheng;

    QVariant data = QVariant::fromValue(card_use);
    RoomThread *thread = room->getThread();

    thread->trigger(PreCardUsed, room, shu, data);

    LogMessage log;
    log.type = "#InvokeOthersSkill";
    log.from = shu;
    log.to << fazheng;
    log.arg = "xuanhuo";
    room->sendLog(log);
    room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, shu->objectName(), fazheng->objectName());
    room->broadcastSkillInvoke("xuanhuo", fazheng);

    //room->notifySkillInvoked(fazheng, "xuanhuo");
    CardMoveReason reason(CardMoveReason::S_REASON_GIVE, shu->objectName(), fazheng->objectName(), "xuanhuo", QString());
    room->obtainCard(fazheng, this, reason, false);

    thread->trigger(CardUsed, room, shu, data);
    thread->trigger(CardFinished, room, shu, data);
}

void XuanhuoAttachCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const
{
    if (source->isNude() || !room->askForDiscard(source, "xuanhuo_discard", 1, 1, false, true, "@xuanhuo-discard")) return;

    QString all_skills = "wusheng+paoxiao+longdan+tieqi+liegong+kuanggu";
    QStringList skill_list;
    QList<const Skill *> skills;
    foreach (ServerPlayer *p, room->getAlivePlayers()) {
        if (p->hasShownGeneral1())
            skills << p->getActualGeneral1()->getVisibleSkillList();
        if (p->getGeneral2() && p->hasShownGeneral2())
            skills << p->getActualGeneral2()->getVisibleSkillList();
    }

    foreach (QString skill_name, all_skills.split("+")) {
        bool can_choose = true;
        foreach (const Skill *s, skills) {
            if (s->objectName() == skill_name || s->objectName() == skill_name + "_xh") {
                can_choose = false;
                break;
            }
        }
        if (can_choose)
            skill_list << skill_name;
    }
    if (skill_list.isEmpty()) return;
    QString skill_name = room->askForChoice(source, "xuanhuo", skill_list.join("+"), QVariant(), "@xuanhuo-choose", all_skills);
    skill_name = skill_name + "_xh";
    room->acquireSkill(source, skill_name, true, false);
    QStringList skillnames = source->tag["XuanhuoSkills"].toStringList();
    skillnames << skill_name;
    source->tag["XuanhuoSkills"] = QVariant::fromValue(skillnames);
}

class XuanhuoAttachVS : public OneCardViewAsSkill
{
public:
    XuanhuoAttachVS() : OneCardViewAsSkill("xuanhuoattach")
    {
        attached_lord_skill = true;
        filter_pattern = ".|.|.|hand";
    }

    virtual bool isEnabledAtPlay(const Player *player) const
    {
       if (player->hasUsed("XuanhuoAttachCard")) return false;
       foreach (const Player *fazheng, player->getAliveSiblings()) {
           if (fazheng->hasShownSkill("xuanhuo") && player->isFriendWith(fazheng))
               return true;
       }
       return false;
    }

    virtual const Card *viewAs(const Card *originalCard) const
    {
        XuanhuoAttachCard *rende_card = new XuanhuoAttachCard;
        rende_card->addSubcard(originalCard);
        return rende_card;
    }
};

class XuanhuoAttach : public TriggerSkill
{
public:
    XuanhuoAttach() : TriggerSkill("xuanhuoattach")
    {
        events << EventPhaseStart << GeneralShown << DFDebut;
        view_as_skill = new XuanhuoAttachVS;
        attached_lord_skill = true;
    }

    virtual void record(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &) const
    {
        if (triggerEvent == EventPhaseStart && player->getPhase() == Player::NotActive) {
            QStringList skills = player->tag["XuanhuoSkills"].toStringList();
            QStringList detachList;
            foreach(QString skill_name, skills)
                detachList.append("-" + skill_name + "!");
            room->handleAcquireDetachSkills(player, detachList, true);
            player->tag["XuanhuoSkills"] = QVariant();
        } else if (triggerEvent == GeneralShown || triggerEvent == DFDebut) {
            foreach (ServerPlayer *p, room->getAlivePlayers()) {
                QList<const Skill *> skills;
                if (p->hasShownGeneral1())
                    skills << p->getActualGeneral1()->getVisibleSkillList();
                if (p->getGeneral2() && p->hasShownGeneral2())
                    skills << p->getActualGeneral2()->getVisibleSkillList();
                QStringList xuanhuoskills = p->tag["XuanhuoSkills"].toStringList();
                QStringList detachList;
                foreach (const Skill *skill, skills) {
                    QString skill_name = skill->objectName()+"_xh";
                    if (xuanhuoskills.contains(skill_name)) {
                        xuanhuoskills.removeOne(skill_name);
                        detachList.append("-" + skill_name + "!");
                    }
                }
                room->handleAcquireDetachSkills(p, detachList, true);
                p->tag["XuanhuoSkills"] = QVariant::fromValue(xuanhuoskills);
            }
        }
    }

    virtual TriggerList triggerable(TriggerEvent , Room *, ServerPlayer *, QVariant &) const
    {
        return TriggerList();
    }
};


class WushengXH : public OneCardViewAsSkill
{
public:
    WushengXH() : OneCardViewAsSkill("wusheng_xh")
    {
        response_or_use = true;
    }

    virtual bool isEnabledAtPlay(const Player *player) const
    {
        return Slash::IsAvailable(player);
    }

    virtual bool isEnabledAtResponse(const Player *, const QString &pattern) const
    {
        return pattern == "slash";
    }

    virtual bool viewFilter(const Card *card) const
    {
        if (!card->isRed() && (Self->getSeemingKingdom() != "shu" || !Self->enjoyingSkill("shouyue")))
            return false;

        if (Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_PLAY) {
            Slash *slash = new Slash(Card::SuitToBeDecided, -1);
            slash->addSubcard(card->getEffectiveId());
            slash->deleteLater();
            return slash->isAvailable(Self);
        }
        return true;
    }

    virtual const Card *viewAs(const Card *originalCard) const
    {
        Card *slash = new Slash(originalCard->getSuit(), originalCard->getNumber());
        slash->addSubcard(originalCard->getId());
        slash->setSkillName(objectName());
        slash->setShowSkill(objectName());
        return slash;
    }
};


class PaoxiaoXH : public TriggerSkill
{
public:
    PaoxiaoXH() : TriggerSkill("paoxiao_xh")
    {
        events << TargetChosen << CardUsed;
        frequency = Compulsory;
    }

    virtual bool canPreshow() const
    {
        return false;
    }

    virtual QStringList triggerable(TriggerEvent triggerEvent, Room *, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
    {
        if (!TriggerSkill::triggerable(player)) return QStringList();
        CardUseStruct use = data.value<CardUseStruct>();
        if (triggerEvent == TargetChosen && player->enjoyingSkill("shouyue") && player->getSeemingKingdom() == "shu") {
            if (use.card != NULL && use.card->isKindOf("Slash")) {
                ServerPlayer *target = use.to.at(use.index);
                if (target != NULL)
                    return QStringList(objectName() + "->" + target->objectName());
            }
        } else if (triggerEvent == CardUsed) {
            if (use.card && use.card->isKindOf("Slash") && player->getCardUsedTimes("Slash") == 2)
                return QStringList(objectName());
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *, ServerPlayer *, QVariant &, ServerPlayer *) const
    {
        return true;
    }

    virtual bool effect(TriggerEvent triggerEvent, Room *, ServerPlayer *target, QVariant &data, ServerPlayer *) const
    {
        if (triggerEvent == TargetChosen) {
            CardUseStruct use = data.value<CardUseStruct>();
            target->addQinggangTag(use.card);
        } else if (triggerEvent == CardUsed)
            target->drawCards(1, objectName());
        return false;
    }
};

class LongdanXH : public OneCardViewAsSkill
{
public:
    LongdanXH() : OneCardViewAsSkill("longdan_xh")
    {
        response_or_use = true;
    }

    virtual bool viewFilter(const Card *to_select) const
    {
        const Card *card = to_select;

        switch (Sanguosha->currentRoomState()->getCurrentCardUseReason()) {
            case CardUseStruct::CARD_USE_REASON_PLAY: {
                return card->isKindOf("Jink");
            }
            case CardUseStruct::CARD_USE_REASON_RESPONSE:
            case CardUseStruct::CARD_USE_REASON_RESPONSE_USE: {
                QString pattern = Sanguosha->currentRoomState()->getCurrentCardUsePattern();
                if (pattern == "slash")
                    return card->isKindOf("Jink");
                else if (pattern == "jink")
                    return card->isKindOf("Slash");
            }
            default:
                return false;
        }
    }

    virtual bool isEnabledAtPlay(const Player *player) const
    {
        return Slash::IsAvailable(player);
    }

    virtual bool isEnabledAtResponse(const Player *, const QString &pattern) const
    {
        return pattern == "jink" || pattern == "slash";
    }

    virtual const Card *viewAs(const Card *originalCard) const
    {
        if (originalCard->isKindOf("Slash")) {
            Jink *jink = new Jink(originalCard->getSuit(), originalCard->getNumber());
            jink->addSubcard(originalCard);
            jink->setSkillName(objectName());
            return jink;
        } else if (originalCard->isKindOf("Jink")) {
            Slash *slash = new Slash(originalCard->getSuit(), originalCard->getNumber());
            slash->addSubcard(originalCard);
            slash->setSkillName(objectName());
            return slash;
        } else
            return NULL;
    }
};

class LiegongXH : public TriggerSkill
{
public:
    LiegongXH() : TriggerSkill("liegong_xh")
    {
        events << TargetChosen;
    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (TriggerSkill::triggerable(player) && use.card != NULL && use.card->isKindOf("Slash")) {
            ServerPlayer *target = use.to.at(use.index);
            if (target != NULL && target->getHp() >= player->getHp())
                return QStringList(objectName() + "->" + target->objectName());
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *skill_target, QVariant &, ServerPlayer *player) const
    {
        if (player->askForSkillInvoke(this, QVariant::fromValue(skill_target))) {
            room->broadcastSkillInvoke(objectName(), player);
            room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, player->objectName(), skill_target->objectName());
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *target, QVariant &data, ServerPlayer *huangzhong) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        QString choice = room->askForChoice(huangzhong, objectName(), "nojink+adddamage", data, "@liegong-choice::"+ target->objectName());
        if (choice == "nojink") {
            QVariantList jink_list = huangzhong->tag["Jink_" + use.card->toString()].toList();
            doLiegong(target, use, jink_list);
            huangzhong->tag["Jink_" + use.card->toString()] = jink_list;
        } else if (choice == "adddamage") {
            QStringList AddDamage_List = use.card->tag["AddDamage_List"].toStringList();
            AddDamage_List << target->objectName();
            use.card->setTag("AddDamage_List", AddDamage_List);
        }
        return false;
    }

private:
    static void doLiegong(ServerPlayer *target, CardUseStruct use, QVariantList &jink_list)
    {
        int index = use.to.indexOf(target);
        LogMessage log;
        log.type = "#NoJink";
        log.from = target;
        target->getRoom()->sendLog(log);
        jink_list[index] = 0;
    }
};

class KuangguXH : public TriggerSkill
{
public:
    KuangguXH() : TriggerSkill("kuanggu_xh")
    {
        events << Damage;
    }

    virtual QStringList triggerable(TriggerEvent , Room *, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        if (TriggerSkill::triggerable(player)) {
            DamageStruct damage = data.value<DamageStruct>();
            if (damage.flags.contains("kuanggu")) {
                QStringList skill_list;
                for (int i = 0; i < damage.damage; i++)
                    skill_list << objectName();
                return skill_list;
            }
        }
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

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        if (player->isWounded() && room->askForChoice(player, objectName(), "recover+draw") == "recover") {
            RecoverStruct recover;
            recover.who = player;
            room->recover(player, recover);
        } else
            player->drawCards(1, objectName());

        return false;
    }
};

GanluCard::GanluCard()
{
}

bool GanluCard::targetsFeasible(const QList<const Player *> &targets, const Player *) const
{
    return targets.length() == 2;
}

bool GanluCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    switch (targets.length()) {
    case 0: return !to_select->getEquips().isEmpty();
    case 1: {
        int n1 = targets.first()->getEquips().length();
        int n2 = to_select->getEquips().length();
        return qAbs(n1 - n2) <= Self->getLostHp();
    }
    default:
        return false;
    }
}

void GanluCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const
{
    LogMessage log;
    log.type = "#GanluSwap";
    log.from = source;
    log.to = targets;
    room->sendLog(log);

    ServerPlayer *first = targets.at(0), *second = targets.at(1);

    QList<int> equips1, equips2;
    foreach(const Card *equip, first->getEquips())
        equips1.append(equip->getId());
    foreach(const Card *equip, second->getEquips())
        equips2.append(equip->getId());

    CardMoveReason reason1(CardMoveReason::S_REASON_SWAP, source->objectName(), second->objectName(), "ganlu", QString());
    CardMoveReason reason2(CardMoveReason::S_REASON_SWAP, source->objectName(), first->objectName(), "ganlu", QString());
    CardMoveReason reason3(CardMoveReason::S_REASON_NATURAL_ENTER, QString());

    QList<CardsMoveStruct> move_to_table;
    CardsMoveStruct move1(equips1, NULL, Player::PlaceTable, reason1);
    CardsMoveStruct move2(equips2, NULL, Player::PlaceTable, reason2);
    move_to_table.push_back(move2);
    move_to_table.push_back(move1);
    if (!move_to_table.isEmpty()) {
        room->moveCardsAtomic(move_to_table, false);

        QList<CardsMoveStruct> back_move;

        if (first->isAlive()) {
            CardsMoveStruct move3(room->getCardIdsOnTable(equips2), first, Player::PlaceEquip, reason2);
            back_move.push_back(move3);
        } else {
            CardsMoveStruct move3(room->getCardIdsOnTable(equips2), NULL, Player::DiscardPile, reason3);
            back_move.push_back(move3);
        }
        if (second->isAlive()) {
            CardsMoveStruct move3(room->getCardIdsOnTable(equips1), second, Player::PlaceEquip, reason1);
            back_move.push_back(move3);
        } else {
            CardsMoveStruct move3(room->getCardIdsOnTable(equips1), NULL, Player::DiscardPile, reason3);
            back_move.push_back(move3);
        }

        if (!back_move.isEmpty())
            room->moveCardsAtomic(back_move, false);
    }
}

class Ganlu : public ZeroCardViewAsSkill
{
public:
    Ganlu() : ZeroCardViewAsSkill("ganlu")
    {
    }

    virtual bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("GanluCard");
    }

    virtual const Card *viewAs() const
    {
        GanluCard *card = new GanluCard;
        card->setShowSkill(objectName());
        return card;
    }
};

class Buyi : public TriggerSkill
{
public:
    Buyi() : TriggerSkill("buyi")
    {
        events << QuitDying;

    }

    virtual TriggerList triggerable(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        DyingStruct dying = data.value<DyingStruct>();
        if (player->isAlive() && player->getHp() > 0 && dying.damage && dying.damage->from && dying.damage->from->isAlive()) {
            TriggerList skill_list;
            QList<ServerPlayer *> wuguotais = room->findPlayersBySkillName(objectName());
            foreach (ServerPlayer *wuguotai, wuguotais) {
                if (wuguotai != NULL && wuguotai->isFriendWith(player) && !wuguotai->hasFlag("BuyiUsed"))
                    skill_list.insert(wuguotai, QStringList(objectName()));
            }
            return skill_list;
        }
        return TriggerList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *, QVariant &data, ServerPlayer *wuguotai) const
    {
        DyingStruct dying = data.value<DyingStruct>();
        if (dying.damage && dying.damage->from && dying.damage->from->isAlive() && wuguotai->askForSkillInvoke(this, QVariant::fromValue(dying.damage->from))) {
            room->broadcastSkillInvoke(objectName(), wuguotai);
            room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, wuguotai->objectName(), dying.damage->from->objectName());
            room->setPlayerFlag(wuguotai, "BuyiUsed");
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *wuguotai) const
    {
        DyingStruct dying = data.value<DyingStruct>();
        if (dying.damage && dying.damage->from && dying.damage->from->isAlive()) {
            if (!wuguotai->askCommandto(objectName(), dying.damage->from)) {
                RecoverStruct recover;
                recover.who = wuguotai;
                room->recover(player, recover);
            }
        }
        return false;
    }
};


class KeshouViewAsSkill : public ViewAsSkill
{
public:
    KeshouViewAsSkill() : ViewAsSkill("keshou")
    {
        response_pattern = "@@keshou";
    }

    virtual bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const
    {
        if (Self->isJilei(to_select)) return false;
        if (selected.isEmpty())
            return true;
        else if (selected.length() == 1)
            return to_select->sameColorWith(selected.first());
        return false;
    }

    virtual const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (cards.length() != 2) return NULL;

        DummyCard *discard = new DummyCard;
        discard->addSubcards(cards);
        return discard;
    }
};

class Keshou : public TriggerSkill
{
public:
    Keshou() : TriggerSkill("keshou")
    {
        events << DamageInflicted;
        view_as_skill = new KeshouViewAsSkill;
    }

    virtual bool canPreshow() const
    {
        return true;
    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *player, QVariant &, ServerPlayer* &) const
    {
        if (TriggerSkill::triggerable(player) && player->getCardCount(true) > 1)
            return QStringList(objectName());
        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        const Card *card = room->askForCard(player, "@@keshou", "@keshou", data, Card::MethodNone);
        if (card) {
            room->broadcastSkillInvoke(objectName(), player);
            room->throwCard(card, player, NULL, objectName());
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        damage.damage--;

        bool no_friend = true;

        QList<ServerPlayer *> alls = room->getOtherPlayers(player);
        foreach (ServerPlayer *p, alls) {
            if (p->isFriendWith(player)) {
                no_friend = false;
                break;
            }
        }

        if (no_friend) {
            JudgeStruct judge;
            judge.pattern = ".|red";
            judge.good = true;
            judge.reason = objectName();
            judge.who = player;
            room->judge(judge);

            if (judge.isGood())
                player->drawCards(1, objectName());
        }

        data = QVariant::fromValue(damage);

        if (damage.damage <= 0)
            return true;

        return false;
    }
};

class Zhuwei : public TriggerSkill
{
public:
    Zhuwei() : TriggerSkill("zhuwei")
    {
        events << FinishJudge << EventPhaseStart;
    }

    virtual void record(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &) const
    {
        if (triggerEvent == EventPhaseStart && player->getPhase() ==  Player::NotActive) {
            QList<ServerPlayer *> alls = room->getAlivePlayers();
            foreach (ServerPlayer *p, alls) {
                room->setPlayerMark(p, "#zhuwei", 0);
            }
        }
    }

    virtual QStringList triggerable(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        if (triggerEvent != FinishJudge || !TriggerSkill::triggerable(player)) return QStringList();
        JudgeStruct *judge = data.value<JudgeStruct *>();
        if (room->getCardPlace(judge->card->getEffectiveId()) == Player::PlaceJudge && isDamageCard(judge->card))
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

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        JudgeStruct *judge = data.value<JudgeStruct *>();
        player->obtainCard(judge->card);

        ServerPlayer *current = room->getCurrent();
        if (current != NULL && current->isAlive() && current->getPhase() != Player::NotActive) {
            if (room->askForChoice(player, objectName(), "yes+no", data, "@zhuwei-choose:" + current->objectName()) == "yes") {
                room->addPlayerMark(current, "#zhuwei");

                LogMessage log;
                log.type = "#ZhuweiBuff";
                log.from = player;
                log.to << current;
                room->sendLog(log);

            }
        }

        return false;
    }

private:
    static bool isDamageCard(const Card *card)
    {
        return card->isKindOf("Slash") || card->isKindOf("SavageAssault") || card->isKindOf("ArcheryAttack")
                || card->isKindOf("Duel") || card->isKindOf("FireAttack") || card->isKindOf("BurningCamps")
                || card->isKindOf("Drowning");
    }
};

class ZhuweiTargetMod : public TargetModSkill
{
public:
    ZhuweiTargetMod() : TargetModSkill("#zhuwei-target")
    {
    }

    virtual int getResidueNum(const Player *from, const Card *card, const Player *) const
    {
        if (!Sanguosha->matchExpPattern(pattern, from, card))
            return 0;
        return from->getMark("#zhuwei");
    }
};

class ZhuweiMaxCards : public MaxCardsSkill
{
public:
    ZhuweiMaxCards() : MaxCardsSkill("#zhuwei-maxcard")
    {
    }

    virtual int getExtra(const Player *target) const
    {
        return target->getMark("#zhuwei");
    }
};

class Fudi : public MasochismSkill
{
public:
    Fudi() : MasochismSkill("fudi")
    {
    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *zhangxiu, QVariant &data, ServerPlayer * &) const
    {
        if (MasochismSkill::triggerable(zhangxiu) && !zhangxiu->isKongcheng()) {
            ServerPlayer *from = data.value<DamageStruct>().from;
            return (from && zhangxiu != from && from->isAlive()) ? QStringList(objectName()) : QStringList();
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        ServerPlayer *from = data.value<DamageStruct>().from;
        player->tag["FudiTarget"] = QVariant::fromValue(from); // for AI
        QList<int> result = room->askForExchange(player, objectName(), 1, 0, "@fudi-give:"+ from->objectName(), "", ".|.|.|hand");
        player->tag.remove("FudiTarget");
        if (!result.isEmpty()) {
            LogMessage l;
            l.type = "#InvokeSkill";
            l.from = player;
            l.arg = objectName();
            room->sendLog(l);
            room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, player->objectName(), from->objectName());
            room->broadcastSkillInvoke(objectName(), player);
            room->notifySkillInvoked(player, objectName());

            DummyCard dummy(result);
            CardMoveReason reason(CardMoveReason::S_REASON_GIVE, player->objectName(), from->objectName(), objectName(), QString());
            room->obtainCard(from, &dummy, reason, false);

            return true;
        }
        return false;
    }

    virtual void onDamaged(ServerPlayer *zhangxiu, const DamageStruct &damage) const
    {
        ServerPlayer *from = damage.from;
        Room *room = zhangxiu->getRoom();

        if (!from || from->isDead()) return;
        QList<ServerPlayer *> targets;
        int x = zhangxiu->getHp();
        foreach (ServerPlayer *p, room->getAlivePlayers()) {
            if (p->isFriendWith(from)) {
                if (p->getHp() < x) continue;
                if (p->getHp() > x)
                    targets.clear();
                x = p->getHp();
                targets << p;
            }
        }
        if (targets.isEmpty()) return;

        ServerPlayer *target = room->askForPlayerChosen(zhangxiu, targets, "fudi_damage", "@fudi-damage");
        room->damage(DamageStruct(objectName(), zhangxiu, target, 1));
    }
};

class Congjian : public TriggerSkill
{
public:
    Congjian() : TriggerSkill("congjian")
    {
        events << DamageInflicted << DamageCaused;
        frequency = Compulsory;
    }

    virtual QStringList triggerable(TriggerEvent triggerEvent, Room *, ServerPlayer *player, QVariant &, ServerPlayer* &) const
    {
        if (!TriggerSkill::triggerable(player)) return QStringList();
        bool not_active = (player->getPhase() == Player::NotActive);

        if ((triggerEvent == DamageCaused && not_active) || (triggerEvent == DamageInflicted && !not_active))
            return QStringList(objectName());
        return QStringList();
    }

    virtual bool cost(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        bool invoke = false;
        if (player->hasShownSkill(objectName())) {
            invoke = true;
            room->sendCompulsoryTriggerLog(player, objectName());
        } else
            invoke = player->askForSkillInvoke(this, data);

        if (invoke) {
            DamageStruct damage = data.value<DamageStruct>();
            if (damage.reason != "fudi") {
                int n = qrand()%2+1;
                if (triggerEvent == DamageCaused)
                    n+=2;
                room->broadcastSkillInvoke(objectName(), n, player);
            }


            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent, Room *, ServerPlayer *, QVariant &data, ServerPlayer *) const
    {
        DamageStruct damage = data.value<DamageStruct>();

        damage.damage ++;
        data = QVariant::fromValue(damage);

        return false;
    }
};

WeidiCard::WeidiCard()
{

}

bool WeidiCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.isEmpty() && to_select != Self && to_select->hasFlag("WeidiHadDrawCards");
}

void WeidiCard::onEffect(const CardEffectStruct &effect) const
{
    ServerPlayer *player = effect.from, *to = effect.to;
    Room *room = player->getRoom();

    if (player->askCommandto("weidi", to) || player == to || to->isKongcheng()) return;

    DummyCard *cards = to->wholeHandCards();
    cards->deleteLater();
    CardMoveReason reason(CardMoveReason::S_REASON_EXTRACTION, player->objectName());
    room->moveCardTo(cards, player, Player::PlaceHand, reason);

    int x = qMin(cards->subcardsLength(), player->getCardCount(true));

    if (x > 0 && player->isAlive() && to->isAlive()) {
        to->setFlags("WeidiTarget");
        QList<int> result = room->askForExchange(player, "weidi_give", x, x, QString("@weidi-return:%1::%2").arg(to->objectName()).arg(x), "", ".");
        to->setFlags("-WeidiTarget");
        DummyCard dummy(result);
        CardMoveReason return_reason = CardMoveReason(CardMoveReason::S_REASON_GIVE, player->objectName());
        room->moveCardTo(&dummy, to, Player::PlaceHand, return_reason);
    }

}


class Weidi : public ZeroCardViewAsSkill
{
public:
    Weidi() : ZeroCardViewAsSkill("weidi")
    {
    }

    virtual bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("WeidiCard");
    }

    virtual const Card *viewAs() const
    {
        WeidiCard *card = new WeidiCard;
        card->setShowSkill(objectName());
        return card;
    }
};


class WeidiRecord : public TriggerSkill
{
public:
    WeidiRecord() : TriggerSkill("weidi_record")
    {
        events << EventPhaseStart << CardsMoveOneTime;
        global = true;
    }

    virtual void record(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (triggerEvent == EventPhaseStart && (player->getPhase() == Player::RoundStart || player->getPhase() == Player::NotActive)) {
            QList<ServerPlayer *> players = room->getAlivePlayers();
            foreach (ServerPlayer *p, players) {
                room->setPlayerFlag(p, "-WeidiHadDrawCards");
            }
        } else if (triggerEvent == CardsMoveOneTime) {
            QVariantList move_datas = data.toList();
            foreach (QVariant move_data, move_datas) {
                CardsMoveOneTimeStruct move = move_data.value<CardsMoveOneTimeStruct>();
                if (move.from == NULL && (move.from_places.contains(Player::DrawPileBottom) || move.from_places.contains(Player::DrawPile) || move.from_places.contains(Player::PlaceJudge))
                    && (move.to == player && move.to_place == Player::PlaceHand)) {
                    room->setPlayerFlag(player, "WeidiHadDrawCards");
                }
            }

        }
    }

    virtual QStringList triggerable(TriggerEvent , Room *, ServerPlayer *, QVariant &, ServerPlayer* &) const
    {
        return QStringList();
    }
};



class Yongsi : public TriggerSkill
{
public:
    Yongsi() : TriggerSkill("yongsi")
    {
        frequency = Compulsory;
        events << TargetConfirmed;
    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (TriggerSkill::triggerable(player) && use.card->isKindOf("KnownBoth") && !player->isKongcheng())
            return QStringList(objectName());

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
            room->broadcastSkillInvoke(objectName(), 2, player);
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent , Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        room->showAllCards(player);

        return false;
    }
};

class YongsiViewHas : public ViewHasSkill
{
public:
    YongsiViewHas() : ViewHasSkill("#yongsi-viewhas")
    {
    }
    virtual bool ViewHas(const Player *player, const QString &skill_name, const QString &flag) const
    {
        if (flag == "treasure" && skill_name == "JadeSeal" && player->isAlive() && player->hasShownSkill("yongsi")) {
            QList<const Player *> sibs = player->getAliveSiblings();
            sibs << player;
            foreach(const Player *sib, sibs)
                if (sib->getTreasure() != NULL && sib->getTreasure()->isKindOf("JadeSeal"))
                    return false;
            return true;
        }
        return false;
    }
};

class Jianan : public TriggerSkill
{
public:
    Jianan() : TriggerSkill("jianan$")
    {
        frequency = Compulsory;
        events << GeneralShown;
    }

    virtual bool canPreshow() const
    {
        return false;
    }

    virtual void record(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (triggerEvent != GeneralShown) return;
        if (player && player->isAlive() && player->hasLordSkill(objectName()) && data.toBool()) {
            room->sendCompulsoryTriggerLog(player, objectName());
            room->broadcastSkillInvoke(objectName(), player);
        }
    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *, QVariant &, ServerPlayer * &) const
    {
        return QStringList();
    }
};


class EliteGeneralFlag : public TriggerSkill
{
public:
    EliteGeneralFlag() : TriggerSkill("elitegeneralflag")
    {
        events << EventPhaseStart << Death;
        global = true;
    }

    virtual void record(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (player != room->getLord("wei", true)) return;

        if (triggerEvent == EventPhaseStart) {
            if (player->getPhase() != Player::RoundStart) return;
        } else if (triggerEvent == Death) {
            DeathStruct death = data.value<DeathStruct>();
            if (player != death.who) return;
        }
        QList<ServerPlayer *> players = room->getAlivePlayers();
        foreach (ServerPlayer *p, players) {
            room->removePlayerDisableShow(p, objectName());
            QStringList skills = p->tag["JiananSkills"].toStringList();
            QStringList detachList;
            foreach(QString skill_name, skills)
                detachList.append("-" + skill_name + "!");
            room->handleAcquireDetachSkills(p, detachList, true);
            p->tag["JiananSkills"] = QVariant();
        }
    }

    virtual QStringList triggerable(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer* &) const
    {
        if (triggerEvent != EventPhaseStart || player == NULL || player->isDead()) return QStringList();
        if (player->getPhase() == Player::Start && player->getSeemingKingdom() == "wei" && player->hasShownOneGeneral()) {
            if (getAvailableGenerals(player).isEmpty() || player->isNude()) return QStringList();
            ServerPlayer *lord = room->getLord("wei");
            if (lord != NULL && lord->hasLordSkill("jianan") && lord->hasShownGeneral1())
                return QStringList(objectName());
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        if (room->askForCard(player, "..", "@elitegeneralflag", QVariant(), objectName())) {
            ServerPlayer *lord = room->getLord("wei");
            if (lord)
                room->broadcastSkillInvoke(objectName(), lord);
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        ServerPlayer *lord = room->getLord("wei");
        if (lord == NULL) return false;
        QStringList generals = getAvailableGenerals(player);
        bool head;
        if (generals.isEmpty()) return false;
        if (generals.length() == 1) head = (generals.first() == "head");
        else head = (room->askForChoice(player, "jianan_hide", generals.join("+"), data, "@jianan-hide") == "head");

        player->hideGeneral(head);
        room->setPlayerDisableShow(player, head?"h":"d", objectName());

        QStringList all_skills, skills = getAvailableSkills(room);
        all_skills << "tuxi" << "qiaobian" << "xiaoguo" << "jieyue" << "duanliang";

        if (skills.isEmpty()) return false;
        QString skill_name = room->askForChoice(player, "jianan_skill", skills.join("+"), data, "@jianan-skill", all_skills.join("+"))+"_egf";

        room->acquireSkill(player, skill_name, true, false);
        QStringList skill_list = player->tag["JiananSkills"].toStringList();
        skill_list << skill_name;
        player->tag["JiananSkills"] = QVariant::fromValue(skill_list);

        return false;
    }

    static QStringList getAvailableSkills(Room *room)
    {
        QStringList skills;
        skills << "tuxi" << "qiaobian" << "xiaoguo" << "jieyue" << "duanliang";
        QStringList _skills = skills;
        QList<ServerPlayer *> players = room->getAlivePlayers();
        foreach (ServerPlayer *p, players) {
            foreach (QString skill, _skills) {
                if ((p->hasSkill(skill, true) && p->hasShownSkill(skill)) || (p->hasSkill(skill+"_egf", true) && p->hasShownSkill(skill+"_egf"))) {
                    skills.removeOne(skill);
                }
            }
        }
        return skills;
    }

    static QStringList getAvailableGenerals(ServerPlayer *wei)
    {
        QStringList generals;
        if (!wei->hasShownGeneral1() || (wei->hasShownAllGenerals() && !wei->getActualGeneral1Name().contains("sujiang") && !wei->isLord()))
            generals << "head";

        if (!wei->hasShownGeneral2() || (wei->hasShownAllGenerals() && !wei->getActualGeneral2Name().contains("sujiang")))
            generals << "deputy";

        return generals;
    }
};



HuibianCard::HuibianCard()
{
}

bool HuibianCard::targetsFeasible(const QList<const Player *> &targets, const Player *) const
{
    return targets.length() == 2;
}

bool HuibianCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *) const
{
    switch (targets.length()) {
    case 0: return to_select->getSeemingKingdom() == "wei";
    case 1: {
        return to_select->getSeemingKingdom() == "wei" && to_select->isWounded();
    }
    default:
        return false;
    }
}

void HuibianCard::onUse(Room *room, const CardUseStruct &card_use) const
{
    ServerPlayer *source = card_use.from;

    LogMessage log;
    log.from = source;
    log.to << card_use.to;
    log.type = "#UseCard";
    log.card_str = toString();
    room->sendLog(log);

    QVariant data = QVariant::fromValue(card_use);
    RoomThread *thread = room->getThread();

    thread->trigger(PreCardUsed, room, source, data);

    if (source->ownSkill("huibian") && !source->hasShownSkill("huibian"))
        source->showGeneral(source->inHeadSkills("huibian"));

    thread->trigger(CardUsed, room, source, data);
    thread->trigger(CardFinished, room, source, data);
}

void HuibianCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const
{
    ServerPlayer *first = targets.at(0), *second = targets.at(1);

    room->damage(DamageStruct("huibian", source, first));

    first->drawCards(2, "huibian");

    if (second->isAlive() && second->canRecover()) {
        RecoverStruct recover;
        recover.who = source;
        room->recover(second, recover);
    }
}

class Huibian : public ZeroCardViewAsSkill
{
public:
    Huibian() : ZeroCardViewAsSkill("huibian")
    {
    }

    virtual bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("HuibianCard");
    }

    virtual const Card *viewAs() const
    {
        HuibianCard *card = new HuibianCard;
        card->setShowSkill(objectName());
        return card;
    }
};

class Zongyu : public TriggerSkill
{
public:
    Zongyu() : TriggerSkill("zongyu")
    {
        events << CardsMoveOneTime;
    }

    virtual QStringList triggerable(TriggerEvent , Room *room, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        if (!TriggerSkill::triggerable(player) || (!player->getOffensiveHorse() && !player->getDefensiveHorse())) return QStringList();
        QVariantList move_datas = data.toList();
        foreach (QVariant move_data, move_datas) {
            CardsMoveOneTimeStruct move = move_data.value<CardsMoveOneTimeStruct>();
            int six_dragons = -1;
            foreach (int id, move.card_ids) {
                if (Sanguosha->getCard(id)->isKindOf("SixDragons")) {
                    six_dragons = id;
                    break;
                }
            }

            if (six_dragons == -1 || move.to_place != Player::PlaceEquip || move.to == NULL || move.to == player) continue;

            if (room->getCardOwner(six_dragons)->objectName() == move.to->objectName() && room->getCardPlace(six_dragons) == Player::PlaceEquip)
                return QStringList(objectName() + "->" + move.to->objectName());

        }

        return QStringList();
    }

    virtual bool cost(TriggerEvent , Room *room, ServerPlayer *target, QVariant &, ServerPlayer *player) const
    {
        if (player->askForSkillInvoke(this)) {
            if (target)
                room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, player->objectName(), target->objectName());
            room->broadcastSkillInvoke(objectName());
            return true;
        }

        return false;
    }

    virtual bool effect(TriggerEvent , Room *room, ServerPlayer *second, QVariant &, ServerPlayer *first) const
    {
        if (first->isDead() || second->isDead()) return false;
        QList<int> equips1, equips2;
        foreach(const Card *equip, first->getEquips())
            if (equip->isKindOf("Horse"))
                equips1.append(equip->getId());

        foreach(const Card *equip, second->getEquips())
            if (equip->isKindOf("Horse"))
                equips2.append(equip->getId());

        if (equips1.isEmpty() && equips2.isEmpty()) return false;

        LogMessage log;
        log.type = "#ZongyuSwap";
        log.from = first;
        log.to << second;
        room->sendLog(log);

        CardMoveReason reason1(CardMoveReason::S_REASON_SWAP, first->objectName(), second->objectName(), "zongyu", QString());
        CardMoveReason reason2(CardMoveReason::S_REASON_SWAP, first->objectName(), first->objectName(), "zongyu", QString());
        CardMoveReason reason3(CardMoveReason::S_REASON_NATURAL_ENTER, QString());

        QList<CardsMoveStruct> move_to_table;
        CardsMoveStruct move1(equips1, NULL, Player::PlaceTable, reason1);
        CardsMoveStruct move2(equips2, NULL, Player::PlaceTable, reason2);
        move_to_table.push_back(move2);
        move_to_table.push_back(move1);
        if (!move_to_table.isEmpty()) {
            room->moveCardsAtomic(move_to_table, false);

            QList<CardsMoveStruct> back_move;

            if (first->isAlive()) {
                CardsMoveStruct move3(room->getCardIdsOnTable(equips2), first, Player::PlaceEquip, reason2);
                back_move.push_back(move3);
            } else {
                CardsMoveStruct move3(room->getCardIdsOnTable(equips2), NULL, Player::DiscardPile, reason3);
                back_move.push_back(move3);
            }
            if (second->isAlive()) {
                CardsMoveStruct move3(room->getCardIdsOnTable(equips1), second, Player::PlaceEquip, reason1);
                back_move.push_back(move3);
            } else {
                CardsMoveStruct move3(room->getCardIdsOnTable(equips1), NULL, Player::DiscardPile, reason3);
                back_move.push_back(move3);
            }

            if (!back_move.isEmpty())
                room->moveCardsAtomic(back_move, false);
        }

        return false;
    }
};



class ZongyuCompulsory : public TriggerSkill
{
public:
    ZongyuCompulsory() : TriggerSkill("#zongyu-compulsory")
    {
        frequency = Compulsory;
        events << CardUsed;
    }

    virtual QStringList triggerable(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        if (player == NULL || player->isDead() || !player->hasSkill("zongyu")) return QStringList();
        CardUseStruct use = data.value<CardUseStruct>();
        if (use.card != NULL && use.card->isKindOf("Horse") && room->isAllOnPlace(use.card, Player::PlaceTable)) {
            foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
                foreach (const Card *card, p->getEquips()) {
                    if (Sanguosha->getCard(card->getEffectiveId())->isKindOf("SixDragons"))
                        return QStringList(objectName());
                }
            }

            foreach (int id, room->getDiscardPile()) {
                if (Sanguosha->getCard(id)->isKindOf("SixDragons"))
                    return QStringList(objectName());
            }
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        bool invoke = false;
        if (player->hasShownSkill("zongyu")) {
            invoke = true;
            room->sendCompulsoryTriggerLog(player, "zongyu");
        } else
            invoke = player->askForSkillInvoke("zongyu", data);

        if (invoke) {
            room->broadcastSkillInvoke("zongyu", player);

            CardUseStruct use = data.value<CardUseStruct>();

            CardMoveReason reason(CardMoveReason::S_REASON_NATURAL_ENTER, player->objectName(), "zongyu", QString());
            room->throwCard(use.card, reason, NULL);


            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        if (player->isDead()) return false;

        const Card *six_dragons = NULL;
        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            foreach (const Card *card, p->getEquips()) {
                if (Sanguosha->getCard(card->getEffectiveId())->isKindOf("SixDragons")) {
                    six_dragons = Sanguosha->getCard(card->getEffectiveId());
                    break;
                }
            }
            if (six_dragons != NULL)
                break;
        }
        if (six_dragons == NULL)
            foreach (int id, room->getDiscardPile()) {
            if (Sanguosha->getCard(id)->isKindOf("SixDragons")) {
                six_dragons = Sanguosha->getCard(id);
                break;
            }
        }

        if (six_dragons == NULL) return false;
        room->moveCardTo(six_dragons, player, Player::PlaceEquip, CardMoveReason(CardMoveReason::S_REASON_PUT, player->objectName(), "zongyu", QString()));
        return false;
    }
};

class JieyueEGFViewAsSkill : public OneCardViewAsSkill
{
public:
    JieyueEGFViewAsSkill() : OneCardViewAsSkill("jieyue_egf")
    {
        filter_pattern = ".|.|.|hand";
        response_pattern = "@@jieyue_egf";
    }

    virtual const Card *viewAs(const Card *originalCard) const
    {
        JieyueCard *jieyue_card = new JieyueCard;
        jieyue_card->addSubcard(originalCard);
        return jieyue_card;
    }
};

class JieyueEGF : public PhaseChangeSkill
{
public:
    JieyueEGF() : PhaseChangeSkill("jieyue_egf")
    {
        view_as_skill = new JieyueEGFViewAsSkill;
    }

    virtual bool canPreshow() const
    {
        return true;
    }

    virtual QStringList triggerable(TriggerEvent , Room *, ServerPlayer *player, QVariant &, ServerPlayer* &) const
    {
        if (!PhaseChangeSkill::triggerable(player) || player->isKongcheng()) return QStringList();
        if (player->getPhase() == Player::Start) return QStringList(objectName());
        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        const Card *card = room->askForUseCard(player, "@@jieyue_egf", "@jieyue", -1, Card::MethodNone);
        if (card) {
            QList<ServerPlayer *> players = player->getRoom()->getOtherPlayers(player);
            foreach (ServerPlayer *target, players) {
                if (target->hasFlag("JieyueTarget")) {
                    room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, player->objectName(), target->objectName());
                    LogMessage log;
                    log.type = "#ChoosePlayerWithSkill";
                    log.from = player;
                    log.to << target;
                    log.arg = objectName();
                    room->sendLog(log);
                    room->notifySkillInvoked(player, objectName());
                    room->broadcastSkillInvoke(objectName(), player);
                    CardMoveReason reason(CardMoveReason::S_REASON_GIVE, player->objectName(), target->objectName(), "jieyue", QString());
                    room->obtainCard(target, card, reason, false);
                    return true;
                }
            }

        }
        return false;
    }

    virtual bool onPhaseChange(ServerPlayer *player) const
    {
        QList<ServerPlayer *> players = player->getRoom()->getOtherPlayers(player);
        foreach (ServerPlayer *p, players) {
            if (p->hasFlag("JieyueTarget")) {
                p->setFlags("-JieyueTarget");
                if (player->askCommandto("jieyue", p))
                    player->drawCards(1, "jieyue");
                else {
                    player->getRoom()->addPlayerMark(player, "JieyueExtraDraw");
                }
            }
        }
        return false;
    }
};

class DuanliangEGF : public OneCardViewAsSkill
{
public:
    DuanliangEGF() : OneCardViewAsSkill("duanliang_egf")
    {
        filter_pattern = "BasicCard,EquipCard|black";
        response_or_use = true;
    }

    virtual bool isEnabledAtPlay(const Player *xuhuang) const
    {
        return !xuhuang->hasFlag("DuanliangEGFCannot");
    }

    virtual const Card *viewAs(const Card *originalCard) const
    {
        SupplyShortage *shortage = new SupplyShortage(originalCard->getSuit(), originalCard->getNumber());
        shortage->setSkillName(objectName());
        shortage->setShowSkill(objectName());
        shortage->addSubcard(originalCard);
        shortage->setFlags("Global_NoDistanceChecking");
        return shortage;
    }
};

class SixDragonsSkill : public DistanceSkill
{
public:
    SixDragonsSkill() :DistanceSkill("SixDragons")
    {
    }

    virtual int getCorrect(const Player *from, const Player *to) const
    {
        int corrent = 0;
        if (from->getMark("Equips_Nullified_to_Yourself") == 0) {
            foreach (const Card *card, from->getEquips()) {
                if (Sanguosha->getCard(card->getEffectiveId())->isKindOf("SixDragons")) {
                    corrent = corrent -1;
                }
            }
        }
        if (to->getMark("Equips_Nullified_to_Yourself") == 0) {
            foreach (const Card *card, to->getEquips()) {
                if (Sanguosha->getCard(card->getEffectiveId())->isKindOf("SixDragons")) {
                    corrent = corrent +1;
                }
            }
        }
        return corrent;
    }
};

PowerPackage::PowerPackage()
    : Package("power")
{
    General *cuiyanmaojie = new General(this, "cuiyanmaojie", "wei", 3);
    cuiyanmaojie->addSkill(new Zhengbi);
    cuiyanmaojie->addSkill(new ZhengbiTargetMod);
    cuiyanmaojie->addSkill(new Fengying);
    cuiyanmaojie->addSkill(new FengyingAfter);
    insertRelatedSkills("zhengbi", "#zhengbi-target");
    insertRelatedSkills("fengying", "#fengying-after");
    cuiyanmaojie->addCompanion("caopi");

    General *yujin = new General(this, "yujin", "wei");
    yujin->addSkill(new Jieyue);
    yujin->addCompanion("xiahoudun");

    General *wangping = new General(this, "wangping", "shu");
    wangping->addSkill(new Jianglve);
    wangping->addCompanion("jiangwanfeiyi");

    General *fazheng = new General(this, "fazheng", "shu", 3);
    fazheng->addSkill(new Enyuan);
    fazheng->addSkill(new Xuanhuo);
    fazheng->addRelateSkill("wusheng_xh");
    fazheng->addRelateSkill("paoxiao_xh");
    fazheng->addRelateSkill("longdan_xh");
    fazheng->addRelateSkill("tieqi_xh");
    fazheng->addRelateSkill("liegong_xh");
    fazheng->addRelateSkill("kuanggu_xh");
    fazheng->addCompanion("liubei");

    General *wuguotai = new General(this, "wuguotai", "wu", 3, false);
    wuguotai->addSkill(new Ganlu);
    wuguotai->addSkill(new Buyi);
    wuguotai->addCompanion("sunjian");

    General *lukang = new General(this, "lukang", "wu", 3);
    lukang->addSkill(new Keshou);
    lukang->addSkill(new Zhuwei);
    lukang->addSkill(new ZhuweiTargetMod);
    lukang->addSkill(new ZhuweiMaxCards);
    insertRelatedSkills("zhuwei", 2, "#zhuwei-target", "#zhuwei-maxcard");
    lukang->addCompanion("luxun");

    General *zhangxiu = new General(this, "zhangxiu", "qun");
    zhangxiu->addSkill(new Fudi);
    zhangxiu->addSkill(new Congjian);
    zhangxiu->addCompanion("jiaxu");

    General *yuanshu = new General(this, "yuanshu", "qun");
    yuanshu->addSkill(new Weidi);
    yuanshu->addSkill(new Yongsi);
    yuanshu->addSkill(new YongsiViewHas);
    insertRelatedSkills("yongsi", "#yongsi-viewhas");
    yuanshu->addCompanion("jiling");

    General *caocao = new General(this, "lord_caocao$", "wei", 4, true, true);
    caocao->addSkill(new Jianan);
    caocao->addSkill(new Huibian);
    caocao->addSkill(new Zongyu);
    caocao->addSkill(new ZongyuCompulsory);
    caocao->addRelateSkill("elitegeneralflag");
    caocao->addRelateSkill("tuxi_egf");
    caocao->addRelateSkill("qiaobian_egf");
    caocao->addRelateSkill("xiaoguo_egf");
    caocao->addRelateSkill("jieyue_egf");
    caocao->addRelateSkill("duanliang_egf");
    insertRelatedSkills("zongyu", "#zongyu-compulsory");

    addMetaObject<ZhengbiCard>();
    addMetaObject<FengyingCard>();
    addMetaObject<JieyueCard>();
    addMetaObject<JianglveCard>();
    addMetaObject<XuanhuoAttachCard>();
    addMetaObject<GanluCard>();
    addMetaObject<WeidiCard>();
    addMetaObject<HuibianCard>();

    skills << new CommandEffect << new ZhengbiGive << new XuanhuoAttach << new WeidiRecord << new EliteGeneralFlag
           << new WushengXH << new PaoxiaoXH << new LongdanXH << new Tieqi("_xh") << new LiegongXH << new KuangguXH
           << new Tuxi("_egf") << new Qiaobian("_egf") << new Xiaoguo("_egf") << new JieyueEGF << new DuanliangEGF;
}

ADD_PACKAGE(Power)

PowerEquipPackage::PowerEquipPackage() : Package("power_equip", CardPack)
{
    Horse *horse = new SixDragons(Card::Heart, 13, 0);
    horse->setObjectName("SixDragons");
    horse->setParent(this);

    skills << new SixDragonsSkill;
}

ADD_PACKAGE(PowerEquip)
