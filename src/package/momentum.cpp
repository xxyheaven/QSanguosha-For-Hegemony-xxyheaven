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

#include "momentum.h"
#include "standard-basics.h"
#include "standard-tricks.h"
#include "standard-wu-generals.h"
#include "standard-shu-generals.h"
#include "client.h"
#include "engine.h"
#include "structs.h"
#include "roomthread.h"

Xunxun::Xunxun(const QString &owner) : PhaseChangeSkill("xunxun" + owner)
{
}

QStringList Xunxun::triggerable(TriggerEvent, Room *, ServerPlayer *lidian, QVariant &, ServerPlayer* &) const
{
    return (PhaseChangeSkill::triggerable(lidian) && lidian->getPhase() == Player::Draw) ? QStringList(objectName()) : QStringList();
}

bool Xunxun::cost(TriggerEvent, Room *room, ServerPlayer *lidian, QVariant &, ServerPlayer *) const
{
    if (lidian->askForSkillInvoke(this)) {
        room->broadcastSkillInvoke(objectName(), lidian);
        return true;
    }

    return false;
}

bool Xunxun::onPhaseChange(ServerPlayer *lidian) const
{
    Room *room = lidian->getRoom();
    room->notifySkillInvoked(lidian, objectName());

    QList<int> card_ids = room->getNCards(4);

    AskForMoveCardsStruct result = room->askForMoveCards(lidian, card_ids, QList<int>(), true, "xunxun", "", "_xunxun", 2, 2, false, false, QList<int>() << -1);

    QListIterator<int> i(result.bottom);
    i.toBack();
    while (i.hasPrevious())
        room->getDrawPile().prepend(i.previous());

    i = result.top;
    while (i.hasNext())
        room->getDrawPile().append(i.next());

    room->doBroadcastNotify(QSanProtocol::S_COMMAND_UPDATE_PILE, QVariant(room->getDrawPile().length()));
    LogMessage a;
    a.type = "#XunxunResult";
    a.from = lidian;
    room->sendLog(a);
    LogMessage b;
    b.type = "$GuanxingTop";
    b.from = lidian;
    b.card_str = IntList2StringList(result.bottom).join("+");
    room->doNotify(lidian, QSanProtocol::S_COMMAND_LOG_SKILL, b.toVariant());
    LogMessage c;
    c.type = "$GuanxingBottom";
    c.from = lidian;
    c.card_str = IntList2StringList(result.top).join("+");
    room->doNotify(lidian, QSanProtocol::S_COMMAND_LOG_SKILL, c.toVariant());
    return false;
}

class Wangxi : public TriggerSkill
{
public:
    Wangxi() : TriggerSkill("wangxi")
    {
        events << Damage << Damaged;
    }

    virtual QStringList triggerable(TriggerEvent triggerEvent, Room *, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
    {
        if (!TriggerSkill::triggerable(player)) return QStringList();
        DamageStruct damage = data.value<DamageStruct>();
        ServerPlayer *target = NULL;
        if (triggerEvent == Damage)
            target = damage.to;
        else
            target = damage.from;
        if (!target || !target->isAlive() || target == player || damage.to->hasFlag("Global_DFDebut")) return QStringList();

        QStringList trigger_list;

        for (int i = 1; i <= damage.damage; i++)
            trigger_list << objectName();

        return trigger_list;
    }

    virtual bool cost(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        ServerPlayer *target = NULL;
        if (triggerEvent == Damage)
            target = damage.to;
        else
            target = damage.from;
        if (player->askForSkillInvoke(this, QVariant::fromValue(target))) {
            room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, player->objectName(), target->objectName());
            room->broadcastSkillInvoke(objectName(), (triggerEvent == Damage) ? 2 : 1, player);
            return true;
        }

        return false;
    }

    virtual bool effect(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        ServerPlayer *target = NULL;
        if (triggerEvent == Damage)
            target = damage.to;
        else
            target = damage.from;
        QList<ServerPlayer *> players;
        players << player << target;
        room->sortByActionOrder(players);

        room->drawCards(players, 1, objectName());

        return false;
    }
};

class Hengjiang : public MasochismSkill
{
public:
    Hengjiang() : MasochismSkill("hengjiang")
    {
    }

    virtual QStringList triggerable(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
    {
        if (!TriggerSkill::triggerable(player)) return QStringList();
        ServerPlayer *current = room->getCurrent();
        if (!current || current->isDead() || current->getPhase() == Player::NotActive || current->getMaxCards() < 1) return QStringList();
        DamageStruct damage = data.value<DamageStruct>();
        QStringList trigger_skill;
        for (int i = 1; i <= damage.damage; i++)
            trigger_skill << objectName();
        return trigger_skill;
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        ServerPlayer *current = room->getCurrent();
        if (current && player->askForSkillInvoke(this, QVariant::fromValue(current))) {
            room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, player->objectName(), current->objectName());
            room->broadcastSkillInvoke(objectName(), player);
            return true;
        }

        return false;
    }

    virtual void onDamaged(ServerPlayer *target, const DamageStruct &) const
    {
        Room *room = target->getRoom();
        ServerPlayer *current = room->getCurrent();
        if (!current) return;
        room->addPlayerMark(current, "#hengjiang");
        room->addPlayerMark(target, "HengjiangInvoke");
        room->addPlayerMark(current, "Global_MaxcardsDecrease");

        return;
    }
};

class HengjiangDraw : public TriggerSkill
{
public:
    HengjiangDraw() : TriggerSkill("#hengjiang-draw")
    {
        events << CardsMoveOneTime << EventPhaseChanging << EventPhaseStart;
        frequency = Compulsory;
    }

    virtual void record(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
         if (triggerEvent == EventPhaseStart && player->getPhase() == Player::NotActive) {
             room->setPlayerMark(player, "#hengjiang", 0);
             foreach(ServerPlayer *p, room->getAllPlayers()) {
                 room->setPlayerMark(p, "HengjiangInvoke", 0);
             }
             room->setTag("HengjiangDiscarded", false);
         } else if (triggerEvent == CardsMoveOneTime && player->getPhase() == Player::Discard) {
             QVariantList move_datas = data.toList();
             foreach (QVariant move_data, move_datas) {
                 CardsMoveOneTimeStruct move = move_data.value<CardsMoveOneTimeStruct>();
                 if (move.from && player == move.from
                     && (move.reason.m_reason & CardMoveReason::S_MASK_BASIC_REASON) == CardMoveReason::S_REASON_DISCARD) {
                     room->setTag("HengjiangDiscarded", true);
                     break;
                 }
             }

         }
    }

    virtual TriggerList triggerable(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        TriggerList skill_list;
        if (triggerEvent == EventPhaseChanging && player->isAlive() && !room->getTag("HengjiangDiscarded").toBool()) {
            PhaseChangeStruct change = data.value<PhaseChangeStruct>();
            if (change.to != Player::NotActive) return skill_list;
            foreach (ServerPlayer *p, room->getAllPlayers()) {
                if (p->getMark("HengjiangInvoke") > 0) {
                    skill_list.insert(p, QStringList(objectName()));
                }
            }

        }
        return skill_list;
    }

    virtual bool effect(TriggerEvent, Room *, ServerPlayer *, QVariant &, ServerPlayer *ask_who) const
    {
        ask_who->drawCards(ask_who->getMark("HengjiangInvoke"));
        return false;
    }
};

class Qianxi : public TriggerSkill
{
public:
    Qianxi() : TriggerSkill("qianxi")
    {
        events << EventPhaseStart;
        frequency = Frequent;
    }

    virtual void record(TriggerEvent , Room *room, ServerPlayer *player, QVariant &) const
    {
        if (player->getPhase() == Player::NotActive) {
            QList<ServerPlayer *> allplayers = room->getAlivePlayers();
            foreach (ServerPlayer *p, allplayers) {
                room->setPlayerMark(p, "##qianxi+no_suit_red", 0);
                room->setPlayerMark(p, "##qianxi+no_suit_black", 0);
            }

        }
    }
    virtual QStringList triggerable(TriggerEvent , Room *, ServerPlayer *player, QVariant &, ServerPlayer* &) const
    {
        if (TriggerSkill::triggerable(player) && player->getPhase() == Player::Start)
            return QStringList(objectName());
        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *target, QVariant &, ServerPlayer *) const
    {
        if (target->askForSkillInvoke(this)) {
            room->broadcastSkillInvoke(objectName(), target);
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *target, QVariant &, ServerPlayer *) const
    {
        if (target->isDead()) return false;
        target->drawCards(1, objectName());
        if (target->isDead() || target->isNude()) return false;
        const Card *c = room->askForCard(target, "..!", "@qianxi-discard");
        if (c == NULL) {
            c = target->getCards("he").at(0);
            room->throwCard(c, target);
        }
        if (target->isDead()) return false;
        QString color;
        if (c->isBlack())
            color = "black";
        else if (c->isRed())
            color = "red";
        else
            return false;

        QList<ServerPlayer *> to_choose;
        foreach (ServerPlayer *p, room->getOtherPlayers(target)) {
            if (target->distanceTo(p) == 1)
                to_choose << p;
        }
        if (to_choose.isEmpty()) return false;

        ServerPlayer *victim = room->askForPlayerChosen(target, to_choose, objectName(), "@qianxi-choose:::"+color);
        room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, target->objectName(), victim->objectName());

        QString pattern = QString(".|%1|.|hand").arg(color);
        room->addPlayerMark(victim, QString("##qianxi+no_suit_%1").arg(color));
        room->setPlayerCardLimitation(victim, "use,response", pattern, true);

        LogMessage log;
        log.type = "#Qianxi";
        log.from = victim;
        log.arg = QString("no_suit_%1").arg(color);
        room->sendLog(log);

        return false;
    }
};

class Guixiu : public TriggerSkill
{
public:
    Guixiu() : TriggerSkill("guixiu")
    {
        events << GeneralShown << GeneralRemoved;
        frequency = Frequent;
    }

    virtual bool canPreshow() const
    {
        return false;
    }

    virtual QStringList triggerable(TriggerEvent triggerEvent, Room *, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
    {
        if (triggerEvent == GeneralShown) {
            if (TriggerSkill::triggerable(player))
                return (player->cheakSkillLocation(objectName(), data.toBool())) ? QStringList(objectName()) : QStringList();
        } else if (data.toString() == "mifuren")
            return QStringList(objectName());
        return QStringList();
    }

    virtual bool cost(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        QString event = "draw";
        if (triggerEvent == GeneralRemoved)
            event = "recover";

        if (player->askForSkillInvoke(this, QVariant::fromValue(event))) {
            room->broadcastSkillInvoke(objectName(), player);
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        if (triggerEvent == GeneralShown)
            player->drawCards(2, objectName());
        else if (triggerEvent == GeneralRemoved) {
            RecoverStruct recover;
            recover.who = player;
            room->recover(player, recover);
        }
        return false;
    }
};

CunsiCard::CunsiCard()
{
    mute = true;
}

bool CunsiCard::targetFilter(const QList<const Player *> &targets, const Player *, const Player *) const
{
    return targets.isEmpty();
}

void CunsiCard::onUse(Room *room, const CardUseStruct &card_use) const
{
    room->broadcastSkillInvoke("cunsi", card_use.from);
    room->doSuperLightbox("mifuren", "cunsi");
    SkillCard::onUse(room, card_use);
}

void CunsiCard::extraCost(Room *, const CardUseStruct &card_use) const
{
    if (card_use.from->inHeadSkills("cunsi"))
        card_use.from->removeGeneral();
    else if (card_use.from->inDeputySkills("cunsi"))
        card_use.from->removeGeneral(false);
    else if (card_use.from->hasShownSkill("huashen") && card_use.from->property("Huashens").toString().split("+").contains("mifuren"))
        card_use.from->removeGeneral(card_use.from->inHeadSkills("huashen"));
}

void CunsiCard::onEffect(const CardEffectStruct &effect) const
{
    Room *room = effect.from->getRoom();
    room->setPlayerMark(effect.from, "cunsi", 1);
    room->acquireSkill(effect.to, "yongjue", true, false);
    room->addPlayerMark(effect.to, "##yongjue");
    if (effect.to != effect.from)
        effect.to->drawCards(2, "cunsi");
}

class Cunsi : public ZeroCardViewAsSkill
{
public:
    Cunsi() : ZeroCardViewAsSkill("cunsi")
    {
    }

    virtual bool canShowInPlay() const
    {
        return true;
    }

    virtual bool isEnabledAtPlay(const Player *player) const
    {

        if (player->hasShownSkill(objectName())) {
            if (player->inHeadSkills(objectName()) && !player->isLord() && !player->getActualGeneral1Name().contains("sujiang"))
                return true;
            if (player->inDeputySkills(objectName()) && player->getGeneral2() && !player->getActualGeneral1Name().contains("sujiang"))
                return true;
        }
        if (player->hasShownSkill("huashen") && player->property("Huashens").toString().split("+").contains("mifuren")) {
            if (player->inHeadSkills("huashen") && !player->isLord() && !player->getActualGeneral1Name().contains("sujiang"))
                return true;
            if (player->inDeputySkills("huashen") && player->getGeneral2() && !player->getActualGeneral1Name().contains("sujiang"))
                return true;
        }
        return false;
    }

    virtual const Card *viewAs() const
    {
        CunsiCard *card = new CunsiCard;
        card->setShowSkill(objectName());
        return card;
    }
};

class Yongjue : public TriggerSkill
{
public:
    Yongjue() : TriggerSkill("yongjue")
    {
        events << CardFinished;
        frequency = Frequent;
    }

    virtual bool canPreshow() const
    {
        return false;
    }

    virtual TriggerList triggerable(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (player != NULL && player->isAlive() && triggerEvent == CardFinished && player->getPhase() == Player::Play) {
            CardUseStruct use = data.value<CardUseStruct>();
            if (use.card->isKindOf("Slash") && use.card->hasFlag("GlobalFirstUsedCardinPlay") && room->isAllOnPlace(use.card, Player::PlaceTable)) {
                QList<ServerPlayer *> owners = room->findPlayersBySkillName(objectName());
                TriggerList skill_list;
                foreach (ServerPlayer *owner, owners)
                    if (player->isFriendWith(owner))
                        skill_list.insert(owner, QStringList(objectName()));
                return skill_list;
            }
        }
        return TriggerList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *owner) const
    {
        if (room->askForChoice(player, objectName(), "yes+no", data, "@yongjue-choose:" + owner->objectName()) == "yes") {
            LogMessage log;
            log.type = "#InvokeOthersSkill";
            log.from = player;
            log.to << owner;
            log.arg = objectName();
            room->sendLog(log);
            room->broadcastSkillInvoke(objectName(), owner);
            room->notifySkillInvoked(owner, objectName());

            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent, Room *, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        player->obtainCard(use.card);
        return false;
    }
};

class Jiang : public TriggerSkill
{
public:
    Jiang() : TriggerSkill("jiang")
    {
        events << TargetConfirmed << TargetChosen;
        frequency = Frequent;
    }

    virtual QStringList triggerable(TriggerEvent triggerEvent, Room *, ServerPlayer *sunce, QVariant &data, ServerPlayer* &) const
    {
        if (!TriggerSkill::triggerable(sunce)) return QStringList();
        CardUseStruct use = data.value<CardUseStruct>();
        bool invoke = triggerEvent == TargetChosen;
        if (!invoke)
            invoke = (use.to.contains(sunce));

        if (invoke) {
            if (use.card->isKindOf("Duel") || (use.card->isKindOf("Slash") && use.card->isRed()))
                return QStringList(objectName());
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *sunce, QVariant &data, ServerPlayer *) const
    {
        if (sunce->askForSkillInvoke(this)) {
            CardUseStruct use = data.value<CardUseStruct>();

            int index = 1;
            if (use.from != sunce)
                index = 2;
            room->broadcastSkillInvoke(objectName(), index, sunce);
            return true;
        }

        return false;
    }

    virtual bool effect(TriggerEvent, Room *, ServerPlayer *sunce, QVariant &, ServerPlayer *) const
    {
        sunce->drawCards(1);
        return false;
    }
};

class Yingyang : public TriggerSkill
{
public:
    Yingyang() : TriggerSkill("yingyang")
    {
        events << PindianVerifying;
        frequency = Frequent;
    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *player, QVariant &, ServerPlayer* &) const
    {
        if (TriggerSkill::triggerable(player)) return QStringList(objectName());
        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *, ServerPlayer *ask_who, QVariant &data, ServerPlayer *) const
    {
        return ask_who->askForSkillInvoke(this, data);
    }

    virtual bool effect(TriggerEvent, Room* room, ServerPlayer *ask_who, QVariant &data, ServerPlayer *) const
    {
        ServerPlayer *sunce = ask_who;
        PindianStruct *pindian = data.value<PindianStruct *>();
        bool isFrom = pindian->from == sunce;

        QString choice = room->askForChoice(sunce, objectName(), "jia3+jian3", data);

        int index = 2;
        if (choice == "jia3")
            index = 1;

        room->broadcastSkillInvoke(objectName(), index, sunce);

        LogMessage log;
        log.type = "$Yingyang";
        log.from = sunce;

        if (isFrom) {
            pindian->from_number = choice == "jia3" ? qMin(pindian->from_number + 3, 13) : qMax(pindian->from_number - 3, 1);

            log.arg = QString::number(pindian->from_number);
        } else {
            pindian->to_number = choice == "jia3" ? qMin(pindian->to_number + 3, 13) : qMax(pindian->to_number - 3, 1);

            log.arg = QString::number(pindian->to_number);
        }

        room->sendLog(log);

        return false;
    }
};

class Hunshang : public TriggerSkill
{
public:
    Hunshang() : TriggerSkill("hunshang")
    {
        frequency = Compulsory;
        events << GameStart << EventPhaseStart;
        relate_to_place = "deputy";
    }

    virtual QStringList triggerable(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer* &) const
    {
        if (!TriggerSkill::triggerable(player)) return QStringList();
        if (triggerEvent == GameStart) {
            const Skill *yinghun = Sanguosha->getSkill("yinghun_sunce");
            if (yinghun != NULL && yinghun->inherits("TriggerSkill")) {
                const TriggerSkill *yinghun_trigger = qobject_cast<const TriggerSkill *>(yinghun);
                room->getThread()->addTriggerSkill(yinghun_trigger);
            }

            return QStringList();
        }
        return (player->getPhase() == Player::Start && player->getHp() == 1) ? QStringList(objectName()) : QStringList();
    }

    virtual bool cost(TriggerEvent, Room* room, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        if (player->hasShownSkill(this) || player->askForSkillInvoke(this)) {
            room->broadcastSkillInvoke(objectName(), player);
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent, Room* room, ServerPlayer *target, QVariant &, ServerPlayer *) const
    {
        room->sendCompulsoryTriggerLog(target, objectName());
        QStringList skills;
        skills << "yingzi_sunce!" << "yinghun_sunce!";
        room->handleAcquireDetachSkills(target, skills);
        target->setMark("hunshang", 1);
        return false;
    }
};

class HunshangRemove : public TriggerSkill
{
public:
    HunshangRemove() : TriggerSkill("#hunshang")
    {
        frequency = Compulsory;
        events << EventPhaseStart;
    }

    virtual bool canPreshow() const
    {
        return false;
    }

    virtual QStringList triggerable(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer * &) const
    {
        if (player != NULL && player->getPhase() == Player::NotActive && player->getMark("hunshang") > 0) {
            player->setMark("hunshang", 0);
            room->handleAcquireDetachSkills(player, "-yingzi_sunce!|-yinghun_sunce!", true);
        }
        return QStringList();
    }
};

DuanxieCard::DuanxieCard()
{
}

bool DuanxieCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.length() < qMax(1, Self->getLostHp()) && !to_select->isChained() && to_select != Self && to_select->canBeChainedBy(Self);
}

void DuanxieCard::onUse(Room *room, const CardUseStruct &card_use) const
{
    SkillCard::onUse(room, card_use);
    if (card_use.from->isAlive() && card_use.from->canBeChainedBy(card_use.from))
        room->setPlayerProperty(card_use.from, "chained", true);
}

void DuanxieCard::onEffect(const CardEffectStruct &effect) const
{
    Room *room = effect.from->getRoom();
    if (effect.to->isAlive() && !effect.to->isChained() && effect.to->canBeChainedBy(effect.from)) {
        room->setPlayerProperty(effect.to, "chained", true);
    }
}

class Duanxie : public ZeroCardViewAsSkill
{
public:
    Duanxie() : ZeroCardViewAsSkill("duanxie")
    {
    }

    virtual bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("DuanxieCard");
    }

    virtual const Card *viewAs() const
    {
        DuanxieCard *card = new DuanxieCard;
        card->setShowSkill(objectName());
        return card;
    }
};

class Fenming : public PhaseChangeSkill
{
public:
    Fenming() : PhaseChangeSkill("fenming")
    {
    }

    virtual QStringList triggerable(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer* &) const
    {
        if (PhaseChangeSkill::triggerable(player) && player->getPhase() == Player::Finish && player->isChained()) {
            foreach (ServerPlayer *p, room->getAllPlayers()) {
                if (p->isChained() && player->canDiscard(p, "he"))
                    return QStringList(objectName());
            }
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        bool invoke = player->askForSkillInvoke(this);
        if (invoke) {
            foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
                if (p->isChained())
                    room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, player->objectName(), p->objectName());
            }
            room->broadcastSkillInvoke(objectName(), player);
            return true;
        }

        return false;
    }

    virtual bool onPhaseChange(ServerPlayer *player) const
    {
        Room *room = player->getRoom();
        QList<ServerPlayer *> targets = room->getAlivePlayers();
        room->sortByActionOrder(targets);
        foreach (ServerPlayer *p, targets) {
            if (p->isChained() && player->canDiscard(p, "he") && player->isAlive()) {
                CardMoveReason reason = CardMoveReason(CardMoveReason::S_REASON_DISMANTLE, player->objectName(), p->objectName(), objectName(), NULL);
                const Card *card = Sanguosha->getCard(room->askForCardChosen(player, p, "he", objectName(), false, Card::MethodDiscard));
                room->throwCard(card, reason, p, player);
            }
        }
        return false;
    }
};

class Hengzheng : public PhaseChangeSkill
{
public:
    Hengzheng() : PhaseChangeSkill("hengzheng")
    {
        frequency = Frequent;
    }

    virtual QStringList triggerable(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer* &) const
    {
        if (PhaseChangeSkill::triggerable(player) && player->getPhase() == Player::Draw && (player->isKongcheng() || player->getHp() == 1)) {
            foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
                if (!p->isAllNude())
                    return QStringList(objectName());
            }
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        if (player->askForSkillInvoke(this)) {
            room->broadcastSkillInvoke(objectName(), player);
            room->doSuperLightbox("dongzhuo", objectName());
            return true;
        }

        return false;
    }

    virtual bool onPhaseChange(ServerPlayer *player) const
    {
        Room *room = player->getRoom();
        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            if (player->canGetCard(p, "hej")) {
                int card_id = room->askForCardChosen(player, p, "hej", objectName(), false, Card::MethodGet);
                room->obtainCard(player, card_id, false);
            }
        }
        return true;
    }
};

class Baoling : public TriggerSkill
{
public:
    Baoling() : TriggerSkill("baoling")
    {
        events << EventPhaseEnd;
        relate_to_place = "head";
        frequency = Compulsory;
    }

    virtual bool canPreshow() const
    {
        return false;
    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *player, QVariant &, ServerPlayer * &) const
    {
        if (TriggerSkill::triggerable(player) && player->getPhase() == Player::Play && player->hasShownSkill(this))
            return (player->getActualGeneral2Name().contains("sujiang")) ? QStringList() : QStringList(objectName());

        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        room->broadcastSkillInvoke(objectName(), player);
        room->doSuperLightbox("dongzhuo", objectName());
        room->notifySkillInvoked(player, objectName());
        return true;
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        player->removeGeneral(false);
        room->setPlayerProperty(player, "maxhp", player->getMaxHp() + 3);

        LogMessage log;
        log.type = "#GainMaxHp";
        log.from = player;
        log.arg = QString::number(3);
        room->sendLog(log);

        RecoverStruct recover;
        recover.recover = 3;
        recover.who = player;
        room->recover(player, recover);

        room->handleAcquireDetachSkills(player, "-baoling|benghuai!");
        return false;
    }
};

class Benghuai : public PhaseChangeSkill
{
public:
    Benghuai() : PhaseChangeSkill("benghuai")
    {
        frequency = Compulsory;
    }

    virtual bool canPreshow() const
    {
        return false;
    }

    virtual QStringList triggerable(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer* &) const
    {
        if (!PhaseChangeSkill::triggerable(player)) return QStringList();
        if (player->getPhase() == Player::Finish) {
            QList<ServerPlayer *> players = room->getOtherPlayers(player);
            foreach(ServerPlayer *p, players)
                if (player->getHp() > p->getHp())
                    return QStringList(objectName());
        }

        return QStringList();
    }

    virtual bool onPhaseChange(ServerPlayer *dongzhuo) const
    {
        Room *room = dongzhuo->getRoom();
        room->sendCompulsoryTriggerLog(dongzhuo, objectName());
        room->broadcastSkillInvoke(objectName(), dongzhuo);

        QString result = room->askForChoice(dongzhuo, "benghuai", "hp+maxhp");
        if (result == "hp")
            room->loseHp(dongzhuo);
        else
            room->loseMaxHp(dongzhuo);

        return false;
    }
};

class Chuanxin : public TriggerSkill
{
public:
    Chuanxin() : TriggerSkill("chuanxin")
    {
        events << DamageCaused;
    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
    {
        if (!TriggerSkill::triggerable(player)) return QStringList();
        DamageStruct damage = data.value<DamageStruct>();
        if (!damage.to || !damage.to->hasShownOneGeneral()) return QStringList();
        if (!damage.card || !(damage.card->isKindOf("Slash") || damage.card->isKindOf("Duel"))) return QStringList();
        if (player->getPhase() != Player::Play) return QStringList();
        if (player->willBeFriendWith(damage.to)) return QStringList();
        if (damage.transfer || damage.chain) return QStringList();
        if (damage.to->getActualGeneral2Name().contains("sujiang")) return QStringList();
        return QStringList(objectName());
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (player->askForSkillInvoke(this, data)) {
            room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, player->objectName(), data.value<DamageStruct>().to->objectName());
            room->broadcastSkillInvoke(objectName(), player);
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *, QVariant &data, ServerPlayer *) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        QStringList choices;
        if (damage.to->hasEquip())
            choices << "discard";
        choices << "remove";
        QString choice = room->askForChoice(damage.to, objectName(), choices.join("+"), data, "@chuanxin-choose", "discard+remove");
        if (choice == "discard") {
            damage.to->throwAllEquips();
            room->loseHp(damage.to);
        } else
            damage.to->removeGeneral(false);

        return true;
    }
};

FengshiSummon::FengshiSummon()
    : ArraySummonCard("fengshi")
{
}

class Fengshi : public BattleArraySkill
{
public:
    Fengshi() : BattleArraySkill("fengshi", HegemonyMode::Siege)
    {
        events << TargetChosen;
    }

    virtual bool canPreshow() const
    {
        return false;
    }

    virtual TriggerList triggerable(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        TriggerList skill_list;
        CardUseStruct use = data.value<CardUseStruct>();
        QList<ServerPlayer *> skill_owners = room->findPlayersBySkillName(objectName());
        foreach (ServerPlayer *skill_owner, skill_owners) {
            if (BattleArraySkill::triggerable(skill_owner) && skill_owner->hasShownSkill(this)
                && use.card != NULL && use.card->isKindOf("Slash")) {
                QStringList targets;
                foreach (ServerPlayer *to, use.to) {
                    if (player->inSiegeRelation(skill_owner, to) && to->canDiscard(to, "e"))
                        targets << to->objectName();
                }
                if (!targets.isEmpty())
                    skill_list.insert(skill_owner, QStringList(objectName() + "->" + targets.join("+")));
            }
        }
        return skill_list;
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *skill_target, QVariant &, ServerPlayer *ask_who) const
    {
        if (ask_who != NULL && ask_who->hasShownSkill(this)) {
            room->doBattleArrayAnimate(ask_who, skill_target);
            room->broadcastSkillInvoke(objectName(), ask_who);
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *skill_target, QVariant &, ServerPlayer *ask_who) const
    {
        room->sendCompulsoryTriggerLog(ask_who, objectName(), true);
        if (!room->askForCard(skill_target, ".|.|.|equipped!", "@fengshi-discard:" + ask_who->objectName())) {
            QList<const Card *> equips_candiscard;
            foreach (const Card *e, skill_target->getEquips()) {
                if (skill_target->canDiscard(skill_target, e->getEffectiveId()))
                    equips_candiscard << e;
            }

            const Card *rand_c = equips_candiscard.at(qrand() % equips_candiscard.length());
            room->throwCard(rand_c, skill_target);
        }
        return false;
    }
};

class Wuxin : public PhaseChangeSkill
{
public:
    Wuxin() : PhaseChangeSkill("wuxin")
    {
        frequency = Frequent;
    }

    virtual bool canPreshow() const
    {
        return false;
    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *player, QVariant &, ServerPlayer* &) const
    {
        if (!PhaseChangeSkill::triggerable(player)) return QStringList();
        if (player->getPhase() == Player::Draw) return QStringList(objectName());

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
        int num = player->getPlayerNumWithKingdom();
        if (player->hasLordSkill("hongfa"))
            num = num+player->getPile("heavenly_army").length();

        QList<int> guanxing = room->getNCards(num);

        LogMessage log;
        log.type = "$ViewDrawPile";
        log.from = player;
        log.card_str = IntList2StringList(guanxing).join("+");
        room->doNotify(player, QSanProtocol::S_COMMAND_LOG_SKILL, log.toVariant());

        room->askForGuanxing(player, guanxing, Room::GuanxingUpOnly);

        return false;
    }
};

class HuangjinSymbolViewAsSkill : public OneCardViewAsSkill
{
public:
    HuangjinSymbolViewAsSkill() : OneCardViewAsSkill("huangjinsymbol")
    {
        //attached_lord_skill = true;
        expand_pile = "heavenly_army,%heavenly_army";
        filter_pattern = ".|.|.|heavenly_army,%heavenly_army";
    }

    virtual bool isEnabledAtPlay(const Player *player) const
    {
        const Player *zhangjiao = player->getLord();
        if (!zhangjiao || !zhangjiao->hasLordSkill("hongfa")
            || zhangjiao->getPile("heavenly_army").isEmpty() || !player->isFriendWith(zhangjiao))
            return false;
        return Slash::IsAvailable(player);
    }

    virtual bool isEnabledAtResponse(const Player *player, const QString &pattern) const
    {
        const Player *zhangjiao = player->getLord();
        if (!zhangjiao || !zhangjiao->hasLordSkill("hongfa")
            || zhangjiao->getPile("heavenly_army").isEmpty() || !player->isFriendWith(zhangjiao))
            return false;
        return pattern == "slash";
    }

    virtual const Card *viewAs(const Card *originalCard) const
    {
        Slash *slash = new Slash(originalCard->getSuit(), originalCard->getNumber());
        slash->addSubcard(originalCard);
        slash->setSkillName("huangjinsymbol");
        return slash;
    }
};

class HuangjinSymbol : public TriggerSkill
{
public:
    HuangjinSymbol() : TriggerSkill("huangjinsymbol")
    {
        events << PreHpLost;
        view_as_skill = new HuangjinSymbolViewAsSkill;
        attached_lord_skill = true;
    }

    virtual QStringList triggerable(TriggerEvent , Room *, ServerPlayer *player, QVariant &, ServerPlayer* &) const
    {
        if (player == NULL || player->isDead() || !player->hasLordSkill("hongfa") || player->getPile("heavenly_army").isEmpty())
            return QStringList();
        return QStringList(objectName());
    }

    virtual bool cost(TriggerEvent , Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        if (player->askForSkillInvoke(objectName(), "prevent")) {
            room->broadcastSkillInvoke(objectName(), 3);
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent , Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        QList<int> ints = room->askForExchange(player, "huangjinsymbol", 1, 1, "@huangjinsymbol-discard", "heavenly_army");
        int id = -1;
        if (ints.isEmpty())
            id = player->getPile("heavenly_army").first();
        else
            id = ints.first();

        CardMoveReason reason(CardMoveReason::S_REASON_REMOVE_FROM_PILE, QString(), objectName(), QString());
        room->throwCard(Sanguosha->getCard(id), reason, NULL);
        return true;
    }

    virtual int getEffectIndex(const ServerPlayer *, const Card *card) const
    {
        if (card->isKindOf("Slash"))
            return qrand()%2+4;
        return -1;
    }
};

class HuangjinSymbolCompulsory : public PhaseChangeSkill
{
public:
    HuangjinSymbolCompulsory() : PhaseChangeSkill("#huangjinsymbol-compulsory")
    {
        frequency = Compulsory;
    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *player, QVariant &, ServerPlayer* &) const
    {
        if (player == NULL || player->isDead() || !player->hasLordSkill("hongfa")) return QStringList();
        if (player->getPhase() == Player::Start && player->getPile("heavenly_army").isEmpty())
            return QStringList(objectName());
        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        room->sendCompulsoryTriggerLog(player, "huangjinsymbol");
        room->broadcastSkillInvoke("huangjinsymbol", qrand()%2+1, player);
        return true;
    }

    virtual bool onPhaseChange(ServerPlayer *player) const
    {
        int num = player->getPlayerNumWithKingdom();
        QList<int> tianbing = player->getRoom()->getNCards(num);
        player->addToPile("heavenly_army", tianbing);
        return false;
    }
};

class Hongfa : public TriggerSkill
{
public:
    Hongfa() : TriggerSkill("hongfa$")
    {
        events << GeneralShown << Death << DFDebut; // HongfaSlash
        frequency = Compulsory;
    }

    virtual void record(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (player == NULL) return;
        if (triggerEvent == GeneralShown) {
            if (player->hasLordSkill(objectName())) {
                if (data.toBool()) {
                    room->sendCompulsoryTriggerLog(player, objectName());
                    room->broadcastSkillInvoke(objectName(), 1, player);
                    foreach(ServerPlayer *p, room->getAlivePlayers())
                        if (p->isFriendWith(player))
                            room->attachSkillToPlayer(p, "huangjinsymbol");
                }
            } else {
                ServerPlayer *lord = room->getLord(player->getSeemingKingdom());
                 if (lord && lord->isAlive() && lord->hasLordSkill(objectName()))
                     room->attachSkillToPlayer(player, "huangjinsymbol");
            }
        } else if (triggerEvent == Death) {
            DeathStruct death = data.value<DeathStruct>();
            if (death.who == player && player->hasLordSkill(objectName())) {
                foreach(ServerPlayer *p, room->getAlivePlayers()) {
                    room->detachSkillFromPlayer(p, "huangjinsymbol");
                }
            }
        } else if (triggerEvent == DFDebut) {
            ServerPlayer *lord = room->getLord(player->getSeemingKingdom());
            if (lord && lord->isAlive() && lord->hasLordSkill(objectName()) && !player->getAcquiredSkills().contains("huangjinsymbol")) {
                room->attachSkillToPlayer(player, "huangjinsymbol");
            }
        }
        return;
    }

    virtual QStringList triggerable(TriggerEvent , Room *, ServerPlayer *, QVariant &, ServerPlayer* &) const
    {
        return QStringList();
    }

};

WendaoCard::WendaoCard()
{
    target_fixed = true;
}

void WendaoCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const
{
    const Card *tpys = NULL;
    foreach (ServerPlayer *p, room->getAlivePlayers()) {
        foreach (const Card *card, p->getEquips()) {
            if (Sanguosha->getCard(card->getEffectiveId())->isKindOf("PeaceSpell")) {
                //room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, source->objectName(), p->objectName());
                tpys = Sanguosha->getCard(card->getEffectiveId());
                break;
            }
        }
        if (tpys != NULL)
            break;
    }
    if (tpys == NULL)
        foreach (int id, room->getDiscardPile()) {
        if (Sanguosha->getCard(id)->isKindOf("PeaceSpell")) {
            tpys = Sanguosha->getCard(id);
            break;
        }
    }

    if (tpys == NULL)
        return;

    source->obtainCard(tpys, true);
}

class Wendao : public OneCardViewAsSkill
{
public:
    Wendao() : OneCardViewAsSkill("wendao")
    {

    }

    virtual bool viewFilter(const Card *to_select) const
    {
        return to_select->isRed() && !Self->isJilei(to_select) && !to_select->isKindOf("PeaceSpell");
    }

    virtual bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("WendaoCard");
    }

    virtual const Card *viewAs(const Card *originalCard) const
    {
        WendaoCard *card = new WendaoCard;
        card->addSubcard(originalCard);
        card->setShowSkill(objectName());
        return card;
    }
};

MomentumPackage::MomentumPackage()
    : Package("momentum")
{
    General *lidian = new General(this, "lidian", "wei", 3); // WEI 017
    lidian->addCompanion("yuejin");
    lidian->addSkill(new Xunxun);
    lidian->addSkill(new Wangxi);

    General *zangba = new General(this, "zangba", "wei", 4); // WEI 023
    zangba->addCompanion("zhangliao");
    zangba->addSkill(new Hengjiang);
    zangba->addSkill(new HengjiangDraw);
    insertRelatedSkills("hengjiang", "#hengjiang-draw");

    General *madai = new General(this, "madai", "shu", 4); // SHU 019
    madai->addCompanion("machao");
    madai->addSkill(new Mashu("madai"));
    madai->addSkill(new Qianxi);

    General *mifuren = new General(this, "mifuren", "shu", 3, false); // SHU 021
    mifuren->addSkill(new Guixiu);
    mifuren->addSkill(new Cunsi);
    mifuren->addRelateSkill("yongjue");

    General *sunce = new General(this, "sunce", "wu", 4); // WU 010
    sunce->addCompanion("zhouyu");
    sunce->addCompanion("taishici");
    sunce->addCompanion("daqiao");
    sunce->addSkill(new Jiang);
    sunce->addSkill(new Yingyang);
    sunce->addSkill(new Hunshang);
    sunce->addSkill(new HunshangRemove);
    insertRelatedSkills("hunshang", "#hunshang");
    sunce->setDeputyMaxHpAdjustedValue(-1);
    sunce->addRelateSkill("yingzi_sunce");
    sunce->addRelateSkill("yinghun_sunce");

    General *chenwudongxi = new General(this, "chenwudongxi", "wu", 4); // WU 023
    chenwudongxi->addSkill(new Duanxie);
    chenwudongxi->addSkill(new Fenming);

    General *dongzhuo = new General(this, "dongzhuo", "qun", 4); // QUN 006
    dongzhuo->addSkill(new Hengzheng);
    dongzhuo->addSkill(new Baoling);
    dongzhuo->addRelateSkill("benghuai");

    General *zhangren = new General(this, "zhangren", "qun", 4); // QUN 024
    zhangren->addSkill(new Chuanxin);
    zhangren->addSkill(new Fengshi);

    General *lord_zhangjiao = new General(this, "lord_zhangjiao$", "qun", 4, true, true);
    lord_zhangjiao->addSkill(new Wuxin);
    lord_zhangjiao->addSkill(new Hongfa);
    lord_zhangjiao->addSkill(new Wendao);
    lord_zhangjiao->addRelateSkill("huangjinsymbol");
    insertRelatedSkills("huangjinsymbol", "#huangjinsymbol-compulsory");

    skills << new Yongjue << new Benghuai << new HuangjinSymbol << new HuangjinSymbolCompulsory << new Yinghun("sunce") << new Yingzi("sunce");

    addMetaObject<CunsiCard>();
    addMetaObject<DuanxieCard>();
    addMetaObject<FengshiSummon>();
    addMetaObject<WendaoCard>();
}

ADD_PACKAGE(Momentum)

PeaceSpell::PeaceSpell(Suit suit, int number)
: Armor(suit, number)
{
    setObjectName("PeaceSpell");
}

class PeaceSpellSkill : public ArmorSkill
{
public:
    PeaceSpellSkill() : ArmorSkill("PeaceSpell")
    {
        events << CardsMoveOneTime;
        frequency = Compulsory;
    }

    virtual QStringList triggerable(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
    {
        if (triggerEvent == DamageInflicted) {
            DamageStruct damage = data.value<DamageStruct>();
            if (damage.from && damage.from->ingoreArmor(player)) return QStringList();
            if (ArmorSkill::triggerable(player) && damage.nature != DamageStruct::Normal)
                return QStringList(objectName());
        } else if (triggerEvent == CardsMoveOneTime && player && player->isAlive()) {

            if (!player->tag["Qinggang"].toStringList().isEmpty() || player->getMark("Armor_Nullified") > 0
                || player->getMark("Equips_Nullified_to_Yourself") > 0)
                return QStringList();

            QVariantList move_datas = data.toList();

            foreach (QVariant move_data, move_datas) {
                CardsMoveOneTimeStruct move = move_data.value<CardsMoveOneTimeStruct>();
                if (move.from != player || !move.from_places.contains(Player::PlaceEquip)) continue;

                QString source_name = move.reason.m_playerId;
                ServerPlayer *source = room->findPlayerbyobjectName(source_name);
                if (source && source->ingoreArmor(player)) continue;

                for (int i = 0; i < move.card_ids.size(); i++) {
                    if (move.from_places[i] != Player::PlaceEquip) continue;
                    const Card *card = Sanguosha->getEngineCard(move.card_ids[i]);
                    if (card->objectName() == objectName())
                        return QStringList(objectName());
                }
            }

        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (triggerEvent == CardsMoveOneTime) return true;
        return ArmorSkill::cost(room, player, data);
    }

    virtual bool effect(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (triggerEvent == DamageInflicted) {
            DamageStruct damage = data.value<DamageStruct>();

            LogMessage l;
            l.type = "#PeaceSpellNatureDamage";
            l.from = damage.from;
            l.to << damage.to;
            l.arg = QString::number(damage.damage);
            switch (damage.nature) {
                case DamageStruct::Normal: l.arg2 = "normal_nature"; break;
                case DamageStruct::Fire: l.arg2 = "fire_nature"; break;
                case DamageStruct::Thunder: l.arg2 = "thunder_nature"; break;
            }

            room->sendLog(l);
            room->setEmotion(damage.to, "armor/peacespell");
            return true;
        } else {
            LogMessage l;
            l.type = "#PeaceSpellLost";
            l.from = player;

            room->sendLog(l);
            room->notifySkillInvoked(player, objectName());
            room->setEmotion(player, "armor/peacespell");

            player->drawCards(2, "PeaceSpell");

            if (player->isAlive() && player->getHp() > 1)
                room->loseHp(player);
        }
        return false;
    }
};

class PeaceSpellSkillDecrease : public ArmorSkill
{
public:
    PeaceSpellSkillDecrease() : ArmorSkill("#PeaceSpell-decrease")
    {
        events << DamageInflicted;
        frequency = Compulsory;
    }

    virtual int getPriority() const
    {
        return -3;
    }

    virtual QStringList triggerable(TriggerEvent , Room *, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        if (damage.from && damage.from->ingoreArmor(player)) return QStringList();
        if (player->hasArmorEffect("PeaceSpell") && damage.nature != DamageStruct::Normal)
            return QStringList("PeaceSpell");
        return QStringList();
    }

    virtual bool cost(TriggerEvent , Room *, ServerPlayer *, QVariant &, ServerPlayer *) const
    {
        return false;
    }

    virtual bool effect(TriggerEvent , Room *, ServerPlayer *, QVariant &, ServerPlayer *) const
    {
        return false;
    }
};

class PeaceSpellSkillMaxCards : public MaxCardsSkill
{
public:
    PeaceSpellSkillMaxCards() : MaxCardsSkill("#PeaceSpell-max")
    {
    }

    virtual int getExtra(const Player *target) const
    {
        if (!target->hasArmorEffect("PeaceSpell")) return 0;

        QList<const Player *> targets = target->getAliveSiblings();
        targets << target;

        int n = 0;
        foreach (const Player *p, targets) {
            if (target->isFriendWith(p)) {
                n++;
            }
        }

        if (target->hasLordSkill("hongfa") && target->hasShownGeneral1() && !target->getPile("heavenly_army").isEmpty())
            n = n + target->getPile("heavenly_army").length();

        return n;
    }
};

MomentumEquipPackage::MomentumEquipPackage() : Package("momentum_equip", CardPack)
{
    PeaceSpell *dp = new PeaceSpell;
    dp->setParent(this);

    skills << new PeaceSpellSkill << new PeaceSpellSkillDecrease << new PeaceSpellSkillMaxCards;
    insertRelatedSkills("PeaceSpell", 2, "#PeaceSpell-decrease", "#PeaceSpell-max");
}

ADD_PACKAGE(MomentumEquip)
