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

#include "jiange-defense.h"
#include "skill.h"
#include "engine.h"
#include "standard-tricks.h"
#include "standard-basics.h"
#include "roomthread.h"
#include "client.h"

class JGJizhen : public PhaseChangeSkill
{
public:
    JGJizhen() : PhaseChangeSkill("jgjizhen")
    {
        frequency = Compulsory;
    }

    virtual QStringList triggerable(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer* &) const
    {
        if (TriggerSkill::triggerable(player) && player->getPhase() == Player::Finish) {
            foreach (ServerPlayer *p, room->getAlivePlayers()) {
                if (p->isFriendWith(player) && p->isWounded())
                    return QStringList(objectName());
            }
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        return player->hasShownSkill(this) || player->askForSkillInvoke(this);
    }

    virtual bool onPhaseChange(ServerPlayer *target) const
    {
        Room *room = target->getRoom();
        room->sendCompulsoryTriggerLog(target, objectName());

        QList<ServerPlayer *> draw_list;
        foreach (ServerPlayer *p, room->getAlivePlayers()) {
            if (p->isFriendWith(target) && p->isWounded()) {
                room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, target->objectName(), p->objectName());
                draw_list << p;
            }
        }
        room->sortByActionOrder(draw_list);
        room->drawCards(draw_list, 1);
        return false;
    }
};

class JGLingfeng : public PhaseChangeSkill
{
public:
    JGLingfeng() : PhaseChangeSkill("jglingfeng")
    {
    }

    virtual bool triggerable(const ServerPlayer *player) const
    {
        return TriggerSkill::triggerable(player) && player->getPhase() == Player::Draw;
    }

    virtual bool cost(TriggerEvent, Room *, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        return player->askForSkillInvoke(this);
    }

    virtual bool onPhaseChange(ServerPlayer *target) const
    {
        Room *room = target->getRoom();
        QList<int> cardids = room->getNCards(2, false);
        CardsMoveStruct move(cardids, NULL, Player::PlaceTable, CardMoveReason(CardMoveReason::S_REASON_SHOW, target->objectName(), objectName(), QString()));
        room->moveCardsAtomic(move, true);

        room->getThread()->delay();
        room->getThread()->delay();

        DummyCard dummy(cardids);
        room->obtainCard(target, &dummy);

        if (Sanguosha->getCard(cardids.first())->getColor() != Sanguosha->getCard(cardids.last())->getColor()) {
            QList<ServerPlayer *> players;
            foreach (ServerPlayer *p, room->getOtherPlayers(target)) {
                if (!p->isFriendWith(target))
                    players << p;
            }
            if (players.isEmpty())
                return true;

            ServerPlayer *victim = room->askForPlayerChosen(target, players, objectName(), "@jglingfeng");
            if (victim == NULL)
                victim = players.at(qrand() % players.length());

            room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, target->objectName(), victim->objectName());
            room->loseHp(victim, 1);
        }

        return true;
    }
};

class JGBiantian : public TriggerSkill
{
public:
    JGBiantian() : TriggerSkill("jgbiantian")
    {
        events << EventPhaseStart << Death;
    }

    virtual void record(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (triggerEvent == EventPhaseStart) {
            if (player->getPhase() != Player::RoundStart)
                return;
        } else if (triggerEvent == Death) {
            DeathStruct death = data.value<DeathStruct>();
            if (player != death.who)
                return;
        }
        QStringList gale_list = player->tag["gale_targets"].toStringList();
        QStringList fog_list = player->tag["fog_targets"].toStringList();
        player->tag.remove("gale_targets");
        player->tag.remove("fog_targets");
        QList<ServerPlayer *> allplayers = room->getAlivePlayers();
        foreach (ServerPlayer *p, allplayers) {
            if (gale_list.contains(p->objectName()))
                p->loseMark("@gale");
            if (fog_list.contains(p->objectName()))
                p->loseMark("@fog");
        }
    }

    virtual QStringList triggerable(TriggerEvent triggerEvent, Room *, ServerPlayer *player, QVariant &, ServerPlayer* &) const
    {
        if (triggerEvent == EventPhaseStart && TriggerSkill::triggerable(player)) {
            if (player->getPhase() == Player::Start)
                return QStringList(objectName());
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
        JudgeStruct judge;
        judge.patterns << ".|red" << ".|spade";
        judge.good = true;
        judge.reason = objectName();
        judge.who = player;
        room->judge(judge);

        if (judge.pattern == ".|red") {
            QStringList target_list = player->tag["gale_targets"].toStringList();
            foreach (ServerPlayer *p, room->getAlivePlayers()) {
                if (!p->isFriendWith(player)) {
                    target_list.append(p->objectName());
                    p->gainMark("@gale", 1);
                }
            }
            player->tag["gale_targets"] = target_list;

        } else if (judge.pattern == ".|spade") {
            QStringList target_list = player->tag["fog_targets"].toStringList();
            foreach (ServerPlayer *p, room->getAlivePlayers()) {
                if (p->isFriendWith(player)) {
                    target_list.append(p->objectName());
                    p->gainMark("@fog", 1);
                }
            }
            player->tag["fog_targets"] = target_list;
        }
        return false;
    }
};

class JGBiantianKF : public TriggerSkill
{
public:
    JGBiantianKF() : TriggerSkill("#jgbiantian-kf")
    {
        frequency = Compulsory;
        events << DamageInflicted;
    }

    virtual TriggerList triggerable(TriggerEvent , Room *room, ServerPlayer *player, QVariant &data) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        if (damage.nature == DamageStruct::Fire && player && player->isAlive()) {
            TriggerList skill_list;
            QList<ServerPlayer *> allplayers = room->getAlivePlayers();
            foreach (ServerPlayer *zhuge, allplayers) {
                QStringList target_list = zhuge->tag["gale_targets"].toStringList();
                if (target_list.contains(player->objectName()))
                    skill_list.insert(zhuge, QStringList(objectName()));
            }
            return skill_list;
        }
        return TriggerList();
    }

    virtual bool cost(TriggerEvent, Room *, ServerPlayer *, QVariant &, ServerPlayer *) const
    {
        return true;
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        LogMessage log;
        log.type = "#GalePower";
        log.from = ask_who;
        log.to << player;
        log.arg = QString::number(damage.damage);
        log.arg2 = QString::number(++damage.damage);
        room->sendLog(log);

        data = QVariant::fromValue(damage);

        return false;
    }
};

class JGBiantianDW : public TriggerSkill
{
public:
    JGBiantianDW() : TriggerSkill("#jgbiantian-dw")
    {
        frequency = Compulsory;
        events << DamageInflicted;
    }

    virtual int getPriority() const
    {
        return -2;
    }

    virtual TriggerList triggerable(TriggerEvent , Room *room, ServerPlayer *player, QVariant &data) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        if (damage.nature != DamageStruct::Thunder && player && player->isAlive()) {
            TriggerList skill_list;
            QList<ServerPlayer *> allplayers = room->getAlivePlayers();
            foreach (ServerPlayer *zhuge, allplayers) {
                QStringList target_list = zhuge->tag["fog_targets"].toStringList();
                if (target_list.contains(player->objectName()))
                    skill_list.insert(zhuge, QStringList(objectName()));
            }
            return skill_list;
        }
        return TriggerList();
    }

    virtual bool cost(TriggerEvent, Room *, ServerPlayer *, QVariant &, ServerPlayer *) const
    {
        return true;
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        LogMessage log;
        log.type = "#FogProtect";
        log.from = ask_who;
        log.to << player;
        log.arg = QString::number(damage.damage);
        if (damage.nature == DamageStruct::Normal)
            log.arg2 = "normal_nature";
        else if (damage.nature == DamageStruct::Fire)
            log.arg2 = "fire_nature";
        room->sendLog(log);

        return true;
    }
};

class JGGongshen : public PhaseChangeSkill
{
public:
    JGGongshen() : PhaseChangeSkill("jggongshen")
    {
    }

    virtual QStringList triggerable(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer* &) const
    {
        if (!TriggerSkill::triggerable(player) || player->getPhase() != Player::Finish)
            return QStringList();

        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            if (p->getGeneral()->objectName().contains("machine"))
                return QStringList(objectName());
        }

        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        QList<ServerPlayer *> friends, enemies, allplayers = room->getAlivePlayers();
        foreach (ServerPlayer *p, allplayers) {
            if (p->getGeneral()->objectName().contains("machine")) {
                if (player->isFriendWith(p) && p->isWounded())
                    friends << p;
                else if (!player->isFriendWith(p))
                    enemies << p;
            }
        }

        if (friends.isEmpty())
            friends = enemies;
        if (friends.isEmpty()) return false;

        ServerPlayer *target = room->askForPlayerChosen(player, friends, objectName(), "@jggongshen", true, true);
        if (target != NULL) {
            player->tag["jggongshen"] = QVariant::fromValue(target);
            return true;
        }

        return false;
    }

    virtual bool onPhaseChange(ServerPlayer *player) const
    {
        ServerPlayer *target = player->tag["jggongshen"].value<ServerPlayer *>();
        player->tag.remove("jggongshen");
        if (target != NULL) {
            Room *room = target->getRoom();
            if (player->isFriendWith(target)) {
                RecoverStruct recover;
                recover.recover = 1;
                recover.who = player;
                room->recover(target, recover);
            } else
                room->damage(DamageStruct(objectName(), player, target, 1, DamageStruct::Fire));
        }
        return false;
    }
};

class JGZhinang : public PhaseChangeSkill
{
public:
    JGZhinang() : PhaseChangeSkill("jgzhinang")
    {

    }

    virtual bool triggerable(const ServerPlayer *player) const
    {
        return TriggerSkill::triggerable(player) && player->getPhase() == Player::Start;
    }

    virtual bool cost(TriggerEvent, Room *, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        return player->askForSkillInvoke(this);
    }

    virtual bool onPhaseChange(ServerPlayer *target) const
    {
        Room *room = target->getRoom();
        QList<int> ids = room->getNCards(5);
        CardsMoveStruct move(ids, NULL, Player::PlaceTable, CardMoveReason(CardMoveReason::S_REASON_SHOW, target->objectName(), objectName(), QString()));
        room->moveCardsAtomic(move, true);

        room->getThread()->delay();
        room->getThread()->delay();


        QList<int> selected_ids;
        foreach (int id, ids) {
            const Card *c = Sanguosha->getCard(id);
            if (c->getTypeId() == Card::TypeTrick || c->getTypeId() == Card::TypeEquip) {
                selected_ids << id;
            }
        }
        if (!selected_ids.isEmpty()) {

            QList<ServerPlayer *> friends;
            foreach (ServerPlayer *p, room->getAlivePlayers()) {
                if (p->isFriendWith(target))
                    friends << p;
            }
            if (!friends.isEmpty()) {
                ServerPlayer *t = room->askForPlayerChosen(target, friends, objectName(), "@jgzhinang", true);
                if (t) {
                    CardMoveReason reason(CardMoveReason::S_REASON_GIVE, target->objectName(), objectName(), QString());
                    DummyCard dummy(selected_ids);
                    room->obtainCard(t, &dummy, reason);
                }
            }
        }
        ids = room->getCardIdsOnTable(ids);
        DummyCard dummy_throw(ids);
        dummy_throw.deleteLater();
        room->throwCard(&dummy_throw, NULL);

        return false;
    }
};

class JGJingmiao : public TriggerSkill
{
public:
    JGJingmiao() : TriggerSkill("jgjingmiao")
    {
        events << CardFinished;
        frequency = Compulsory;
    }

    virtual QStringList triggerable(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer* &ask_who) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (!use.card->isKindOf("Nullification"))
            return QStringList();
        ServerPlayer *yueying = room->findPlayerBySkillName(objectName());
        if (!yueying || player->isFriendWith(yueying))
            return QStringList();
        ask_who = yueying;
        return QStringList(objectName());
    }

    virtual bool cost(TriggerEvent, Room *, ServerPlayer *player, QVariant &, ServerPlayer *ask_who) const
    {
        return player->hasShownSkill(this) || ask_who->askForSkillInvoke(this, QVariant::fromValue(player));
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *ask_who) const
    {
        room->sendCompulsoryTriggerLog(ask_who, objectName());
        room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, ask_who->objectName(), player->objectName());

        room->loseHp(player);
        return false;
    }
};

class JGYuhuo : public TriggerSkill
{
public:
    explicit JGYuhuo(const QString &owner) : TriggerSkill("jgyuhuo_" + owner)
    {
        setObjectName("jgyuhuo_" + owner);
        events << DamageInflicted;
        frequency = Compulsory;
    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
    {
        return (TriggerSkill::triggerable(player) && data.value<DamageStruct>().nature == DamageStruct::Fire) ? QStringList(objectName()) : QStringList();
    }

    virtual bool cost(TriggerEvent, Room *, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        return player->hasShownSkill(this) || player->askForSkillInvoke(this);
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        room->notifySkillInvoked(player, objectName());
        LogMessage log;
        log.type = "#YuhuoProtect";
        log.from = player;
        log.arg = QString::number(data.value<DamageStruct>().damage);
        log.arg2 = "fire_nature";
        room->sendLog(log);
        return true;
    }
};

class JGQiwu : public TriggerSkill
{
public:
    JGQiwu() : TriggerSkill("jgqiwu")
    {
        events << CardUsed << CardResponded;
    }

    virtual QStringList triggerable(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
    {
        if (!TriggerSkill::triggerable(player)) return QStringList();
        const Card *cardstar = NULL;
        if (triggerEvent == CardUsed) {
            CardUseStruct use = data.value<CardUseStruct>();
            cardstar = use.card;
        } else {
            CardResponseStruct resp = data.value<CardResponseStruct>();
            if(resp.m_isUse)
                cardstar = resp.m_card;
        }
        if (cardstar && cardstar->getTypeId() != Card::TypeSkill && cardstar->getSuit() == Card::Club) {
            foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
                if (p->isFriendWith(player) && p->isWounded())
                    return QStringList(objectName());
            }
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        QList<ServerPlayer *> players;
        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            if (p->isFriendWith(player) && p->isWounded())
                players << p;
        }
        ServerPlayer *target = room->askForPlayerChosen(player, players, objectName(), "@jgqiwu", false, true);
        if (target != NULL) {
            player->tag[objectName()] = QVariant::fromValue(target);
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        ServerPlayer *target = player->tag[objectName()].value<ServerPlayer *>();
        player->tag.remove(objectName());
        if (target != NULL) {
            RecoverStruct rec;
            rec.recover = 1;
            rec.who = player;
            room->recover(target, rec);
        }

        return false;
    }
};

class JGTianyu : public PhaseChangeSkill
{
public:
    JGTianyu() : PhaseChangeSkill("jgtianyu")
    {

    }

    virtual QStringList triggerable(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer* &) const
    {
        if (!TriggerSkill::triggerable(player) || player->getPhase() != Player::Finish)
            return QStringList();

        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            if (!p->isFriendWith(player) && !p->isChained())
                return QStringList(objectName());
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

    virtual bool onPhaseChange(ServerPlayer *player) const
    {
        Room *room = player->getRoom();
        QList<ServerPlayer *> targets;
        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            if (!p->isFriendWith(player) && !p->isChained()) {
                targets << p;
                room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, player->objectName(), p->objectName());
            }
        }

        room->sortByActionOrder(targets);

        foreach (ServerPlayer *p, targets) {
            p->setChained(true);
            room->setEmotion(p, "chain");
            room->broadcastProperty(p, "chained");
            room->getThread()->trigger(ChainStateChanged, room, p);
        }
        return false;
    }
};

class JGJiguan : public TriggerSkill
{ //temp method
public:
    explicit JGJiguan(const QString &owner) : TriggerSkill("jgjiguan_" + owner)
    {
        setObjectName("jgjiguan_" + owner);
        events << TargetConfirming;
        frequency = Compulsory;
    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (use.card != NULL && use.card->objectName() == "indulgence" && use.to.contains(player) && TriggerSkill::triggerable(player))
            return QStringList(objectName());

        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        return player->hasShownSkill(this) || player->askForSkillInvoke(this);
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        room->sendCompulsoryTriggerLog(player, objectName());
        CardUseStruct use = data.value<CardUseStruct>();

        room->cancelTarget(use, player); // Room::cancelTarget(use, player);

        data = QVariant::fromValue(use);
        return false;
    }
};

class JGMojian : public PhaseChangeSkill
{
public:
    JGMojian() : PhaseChangeSkill("jgmojian")
    {
        frequency = Compulsory;
    }

    virtual bool triggerable(const ServerPlayer *target) const
    {
        return TriggerSkill::triggerable(target) && target->getPhase() == Player::Play;
    }

    virtual bool cost(TriggerEvent, Room *, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        return player->hasShownSkill(this) || player->askForSkillInvoke(this);
    }

    virtual bool onPhaseChange(ServerPlayer *player) const
    {
        QList<ServerPlayer *> targets;
        Room *room = player->getRoom();
        room->sendCompulsoryTriggerLog(player, objectName());

        ArcheryAttack *aa = new ArcheryAttack(Card::NoSuit, 0);
        aa->setSkillName("_" + objectName());

        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            if (!p->isFriendWith(player) && !player->isProhibited(p, aa))
                targets << p;
        }

        room->useCard(CardUseStruct(aa, player, targets));

        return false;
    }
};

class JGZhenwei : public DistanceSkill
{
public:
    JGZhenwei() : DistanceSkill("jgzhenwei")
    {
    }

    virtual int getCorrect(const Player *from, const Player *to) const
    {
        if (from->isFriendWith(to))
            return 0;

        foreach (const Player *p, to->getAliveSiblings()) {
            if (p->isFriendWith(to) && p != to && p->hasShownSkill(objectName()))
                return 1;
        }

        return 0;
    }
};

class JGBenlei : public PhaseChangeSkill
{
public:
    JGBenlei() : PhaseChangeSkill("jgbenlei")
    {

    }

    virtual QStringList triggerable(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer* &) const
    {
        if (TriggerSkill::triggerable(player) && player->getPhase() == Player::Start) {
            foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
                if (!p->isFriendWith(player) && p->getGeneral()->objectName().contains("machine"))
                    return QStringList(objectName());
            }
        }

        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        QList<ServerPlayer *> players, all_players = room->getAlivePlayers();
        foreach (ServerPlayer *p, all_players) {
            if (!p->isFriendWith(player) && p->getGeneral()->objectName().contains("machine"))
                players << p;
        }
        ServerPlayer *target = room->askForPlayerChosen(player, players, objectName(), "@jgbenlei", false, true);
        if (target != NULL) {
            room->broadcastSkillInvoke(objectName(), player);
            QStringList target_list = player->tag["jgbenlei_target"].toStringList();
            target_list.append(target->objectName());
            player->tag["jgbenlei_target"] = target_list;
            return true;
        }
        return false;
    }

    virtual bool onPhaseChange(ServerPlayer *player) const
    {
        Room *room = player->getRoom();
        QStringList target_list = player->tag["jgbenlei_target"].toStringList();
        QString target_name = target_list.takeLast();
        player->tag["jgbenlei_target"] = target_list;
        ServerPlayer *to = room->findPlayerbyobjectName(target_name);
        if (to)
            room->damage(DamageStruct(objectName(), player, to, 2, DamageStruct::Thunder));

        return false;
    }
};

class JGTianyun : public PhaseChangeSkill
{
public:
    JGTianyun() : PhaseChangeSkill("jgtianyun")
    {

    }

    virtual bool triggerable(const ServerPlayer *target) const
    {
        return TriggerSkill::triggerable(target) && target->getHp() > 0 && target->getPhase() == Player::Finish;
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        QList<ServerPlayer *> players;
        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            if (!p->isFriendWith(player))
                players << p;
        }

        if (players.isEmpty()) return false;

        player->tag.remove("jgtianyun");
        ServerPlayer *victim = room->askForPlayerChosen(player, players, objectName(), "@jgtianyun", true, true);

        if (victim != NULL) {
            player->tag["jgtianyun"] = QVariant::fromValue(victim);
            room->loseHp(player);
            return true;
        }

        return false;
    }

    virtual bool onPhaseChange(ServerPlayer *player) const
    {
        ServerPlayer *victim = player->tag["jgtianyun"].value<ServerPlayer *>();
        if (victim == NULL)
            return false;

        Room *room = player->getRoom();
        room->damage(DamageStruct(objectName(), player, victim, 2, DamageStruct::Fire));
        QList<const Card *> cards = victim->getEquips();
        if (!cards.isEmpty()) {
            DummyCard dummy;
            dummy.addSubcards(cards);
            room->throwCard(&dummy, victim, player);
        }
        return false;
    }
};

class JGYizhong : public TriggerSkill
{
public:
    JGYizhong() : TriggerSkill("jgyizhong")
    {
        frequency = Compulsory;
        events << SlashEffected;
    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        if (!TriggerSkill::triggerable(player) || player->getArmor() != NULL)
            return QStringList();

        SlashEffectStruct effect = data.value<SlashEffectStruct>();
        return effect.slash->isBlack() ? QStringList(objectName()) : QStringList();
    }

    virtual bool cost(TriggerEvent, Room *, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        return player->hasShownSkill(this) || player->askForSkillInvoke(this);
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        room->notifySkillInvoked(player, objectName());
        LogMessage log;
        log.type = "#SkillNullify";
        log.from = player;
        log.arg = objectName();
        log.arg2 = data.value<SlashEffectStruct>().slash->objectName();
        room->sendLog(log);
        return true;
    }
};

class JGLingyu : public PhaseChangeSkill
{
public:
    JGLingyu() : PhaseChangeSkill("jglingyu")
    {

    }

    virtual QStringList triggerable(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer* &) const
    {
        if (TriggerSkill::triggerable(player) && player->getPhase() == Player::Finish) {
            foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
                if (p->isFriendWith(player) && p->isWounded())
                    return QStringList(objectName());
            }
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        if (player->askForSkillInvoke(this)) {
            player->turnOver();
            return true;
        }
        return false;
    }

    virtual bool onPhaseChange(ServerPlayer *player) const
    {
        Room *room = player->getRoom();

        QList<ServerPlayer *> targets;

        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            if (p->isFriendWith(player) && p->isWounded()) {
                targets << p;
                room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, player->objectName(), p->objectName());
            }
        }

        room->sortByActionOrder(targets);

        foreach (ServerPlayer *p, targets) {
            RecoverStruct rec;
            rec.recover = 1;
            rec.who = player;
            room->recover(p, rec);
        }
        return false;
    }
};

class JGChiying : public TriggerSkill
{
public:
    JGChiying() : TriggerSkill("jgchiying")
    {
        events << DamageInflicted;
        frequency = Compulsory;
    }

    virtual QStringList triggerable(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer * &ask_who) const
    {
        ServerPlayer *zidan = room->findPlayerBySkillName(objectName());
        if (zidan != NULL && player != NULL && zidan->isFriendWith(player)) {
            ask_who = zidan;
            DamageStruct damage = data.value<DamageStruct>();
            if (damage.damage >= 2)
                return QStringList(objectName());
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *, ServerPlayer *, QVariant &, ServerPlayer *ask_who) const
    {
        return ask_who->hasShownSkill(objectName()) || ask_who->askForSkillInvoke(this);
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const
    {
        room->notifySkillInvoked(ask_who, objectName());
        DamageStruct damage = data.value<DamageStruct>();
        room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, ask_who->objectName(), player->objectName());
        LogMessage log;
        log.type = "#JGChiying";
        log.from = ask_who;
        log.arg = QString::number(damage.damage);
        log.arg2 = objectName();
        room->sendLog(log);
        damage.damage = 1;
        data = QVariant::fromValue(damage);
        return false;
    }
};

class JGJingfan : public DistanceSkill
{
public:
    JGJingfan() : DistanceSkill("jgjingfan")
    {
    }

    virtual int getCorrect(const Player *from, const Player *to) const
    {
        if (from->isFriendWith(to))
            return 0;

        foreach (const Player *p, from->getAliveSiblings()) {
            if (p->isFriendWith(from) && p != from && p->hasShownSkill(objectName()))
                return -1;
        }

        return 0;
    }
};

class JGChuanyun : public PhaseChangeSkill
{
public:
    JGChuanyun() : PhaseChangeSkill("jgchuanyun")
    {
    }

    virtual QStringList triggerable(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer* &) const
    {
        if (!TriggerSkill::triggerable(player) || player->getPhase() != Player::Finish)
            return QStringList();

        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            if (p->getHp() >= player->getHp())
                return QStringList(objectName());
        }

        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        QList<ServerPlayer *> players;
        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            if (p->getHp() >= player->getHp())
                players << p;
        }

        ServerPlayer *victim = room->askForPlayerChosen(player, players, objectName(), "@jgchuanyun", true, true);
        if (victim != NULL) {
            player->tag["jgchuanyun"] = QVariant::fromValue(victim);
            return true;
        }
        return false;
    }

    virtual bool onPhaseChange(ServerPlayer *target) const
    {
        ServerPlayer *victim = target->tag["jgchuanyun"].value<ServerPlayer *>();
        target->tag.remove("jgchuanyun");
        if (victim != NULL)
            victim->getRoom()->damage(DamageStruct(objectName(), target, victim, 1));

        return false;
    }
};

class JGLeili : public TriggerSkill
{
public:
    JGLeili() : TriggerSkill("jgleili")
    {
        events << Damage;
    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
    {
        if (!TriggerSkill::triggerable(player))
            return QStringList();

        DamageStruct damage = data.value<DamageStruct>();
        if (damage.card != NULL && damage.card->isKindOf("Slash"))
            return QStringList(objectName());

        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        QList<ServerPlayer *> players;
        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            if (!p->isFriendWith(player))
                players << p;
        }
        DamageStruct damage = data.value<DamageStruct>();
        players.removeOne(damage.to);// another one

        ServerPlayer *victim = room->askForPlayerChosen(player, players, objectName(), "@jgleili", true, true);
        if (victim != NULL) {
            player->tag["jgleili"] = QVariant::fromValue(victim);
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        ServerPlayer *victim = player->tag["jgleili"].value<ServerPlayer *>();
        player->tag.remove("jgleili");
        if (victim != NULL)
            room->damage(DamageStruct(objectName(), player, victim, 1, DamageStruct::Thunder));

        return false;
    }
};

class JGFengxing : public PhaseChangeSkill
{
public:
    JGFengxing() : PhaseChangeSkill("jgfengxing")
    {

    }

    virtual bool triggerable(const ServerPlayer *target) const
    {
        return TriggerSkill::triggerable(target) && target->getPhase() == Player::Start;
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        QList<ServerPlayer *> players;
        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            if (!p->isFriendWith(player))
                players << p;
        }

        player->tag.remove("jgfengxing");
        ServerPlayer *victim = room->askForPlayerChosen(player, players, objectName(), "@jgfengxing", true/*, true*/);
        if (victim != NULL) {
            player->tag["jgfengxing"] = QVariant::fromValue(victim);
            return true;
        }
        return false;
    }

    virtual bool onPhaseChange(ServerPlayer *target) const
    {
        ServerPlayer *victim = target->tag["jgfengxing"].value<ServerPlayer *>();
        target->tag.remove("jgfengxing");
        if (victim != NULL) {
            Slash *slash = new Slash(Card::NoSuit, 0);
            slash->setSkillName("_" + objectName());
            slash->setShowSkill(objectName());
            CardUseStruct use;
            use.card = slash;
            use.from = target;
            use.to << victim;
            use.m_addHistory = false;
            victim->getRoom()->useCard(use, false);
        }
        return false;
    }
};

class JGKonghunRecord : public TriggerSkill
{
public:
    JGKonghunRecord() : TriggerSkill("#jgkonghun-record")
    {
        events << DamageDone;
        frequency = Compulsory;
    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *, QVariant &data, ServerPlayer* &ask_who) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        if (damage.from && damage.from->hasSkill("jgkonghun") && damage.reason == "jgkonghun" && !damage.transfer && !damage.chain) {
            ask_who = damage.from;
            return QStringList(objectName());
        }

        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *, ServerPlayer *, QVariant &, ServerPlayer *ask_who) const
    {
        ask_who->addMark("jgkonghun", 1);
        return false;
    }

    virtual bool effect(TriggerEvent, Room *, ServerPlayer *, QVariant &, ServerPlayer *) const
    {
        Q_ASSERT(false);
        return false;
    }
};

class JGKonghun : public PhaseChangeSkill
{
public:
    JGKonghun() : PhaseChangeSkill("jgkonghun")
    {

    }

    virtual QStringList triggerable(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer* &) const
    {
        if (!TriggerSkill::triggerable(player) || player->getPhase() != Player::Play)
            return QStringList();

        int num = 0;
        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            if (!p->isFriendWith(player))
                ++num;
        }

        if (player->getLostHp() >= num)
            return QStringList(objectName());

        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        player->setMark("jgkonghun", 0);
        return player->askForSkillInvoke(this);
    }

    virtual bool onPhaseChange(ServerPlayer *player) const
    {
        Room *room = player->getRoom();

        QList<ServerPlayer *> players;
        foreach (ServerPlayer *p, room->getAlivePlayers()) {
            if (!p->isFriendWith(player)) {
                room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, player->objectName(), p->objectName());
                players << p;
            }
        }

        room->sortByActionOrder(players);
        foreach(ServerPlayer *p, players)
            room->damage(DamageStruct(objectName(), player, p, 1, DamageStruct::Thunder));

        int n = player->getMark("jgkonghun");
        player->setMark("jgkonghun", 0);

        if (n > 0) {
            RecoverStruct rec;
            rec.recover = n;
            rec.who = player;
            room->recover(player, rec);
        }

        return false;
    }
};

class JGFanshi : public PhaseChangeSkill
{
public:
    JGFanshi() : PhaseChangeSkill("jgfanshi")
    {
        frequency = Compulsory;
    }

    virtual bool triggerable(const ServerPlayer *target) const
    {
        return TriggerSkill::triggerable(target) && target->getPhase() == Player::Finish/* && target->hasShownSkill(this)*/;
    }

    virtual bool cost(TriggerEvent, Room *, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        return player->hasShownSkill(this) || player->askForSkillInvoke(this);
    }

    virtual bool onPhaseChange(ServerPlayer *target) const
    {
        Room *room = target->getRoom();
        room->sendCompulsoryTriggerLog(target, objectName());

        room->loseHp(target);
        return false;
    }
};

class JGXuanlei : public PhaseChangeSkill
{
public:
    JGXuanlei() : PhaseChangeSkill("jgxuanlei")
    {
        frequency = Compulsory;
    }

    virtual QStringList triggerable(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer* &) const
    {
        if (!TriggerSkill::triggerable(player) || player->getPhase() != Player::Start)
            return QStringList();

        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            if (!p->isFriendWith(player) && !p->getJudgingArea().isEmpty())
                return QStringList(objectName());
        }

        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        return player->hasShownSkill(this) || player->askForSkillInvoke(this);
    }

    virtual bool onPhaseChange(ServerPlayer *player) const
    {
        Room *room = player->getRoom();
        room->sendCompulsoryTriggerLog(player, objectName());

        QList<ServerPlayer *> players;
        foreach (ServerPlayer *p, room->getAlivePlayers()) {
            if (!p->isFriendWith(player) && !p->getJudgingArea().isEmpty()) {
                room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, player->objectName(), p->objectName());
                players << p;
            }
        }

        room->sortByActionOrder(players);
        foreach(ServerPlayer *p, players)
            room->damage(DamageStruct(objectName(), player, p, 1, DamageStruct::Thunder));


        return false;
    }
};

class JGHuodi : public PhaseChangeSkill
{
public:
    JGHuodi() : PhaseChangeSkill("jghuodi")
    {

    }

    virtual QStringList triggerable(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer* &) const
    {
        if (!TriggerSkill::triggerable(player) || player->getPhase() != Player::Finish)
            return QStringList();

        foreach (ServerPlayer *p, room->getAlivePlayers()) {
            if (p->isFriendWith(player) && !p->faceUp())
                return QStringList(objectName());
        }

        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        QList<ServerPlayer *> players;
        foreach (ServerPlayer *p, room->getAlivePlayers()) {
            if (!p->isFriendWith(player))
                players << p;
        }

        player->tag.remove("jghuodi");
        ServerPlayer *victim = room->askForPlayerChosen(player, players, objectName(), "@jghuodi", true, true);
        if (victim != NULL) {
            player->tag["jghuodi"] = QVariant::fromValue(victim);
            return true;
        }
        return false;
    }

    virtual bool onPhaseChange(ServerPlayer *target) const
    {
        ServerPlayer *victim = target->tag["jghuodi"].value<ServerPlayer *>();
        target->tag.remove("jghuodi");
        if (victim != NULL)
            victim->turnOver();

        return false;
    }
};

class JGJueji : public TriggerSkill
{
public:
    JGJueji() : TriggerSkill("jgjueji")
    {
        events << DrawNCards;
        frequency = Compulsory;
    }

    virtual TriggerList triggerable(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        TriggerList m;
        ServerPlayer *zhanghe = room->findPlayerBySkillName(objectName());
        if (zhanghe != NULL && zhanghe->isAlive() && !player->isFriendWith(zhanghe) && player->isWounded() && data.toInt() > 0)
            m.insert(zhanghe, QStringList(objectName()));

        return m;
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *ask_who /* = NULL */) const
    {
        bool invoke = false;
        if (ask_who->hasShownSkill(this)) {
            room->sendCompulsoryTriggerLog(ask_who, objectName());
            invoke = true;
        } else invoke = ask_who->askForSkillInvoke(this, QVariant::fromValue(player));
        if (invoke) {
            room->broadcastSkillInvoke(objectName(), ask_who);
            room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, ask_who->objectName(), player->objectName());
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent, Room *, ServerPlayer *, QVariant &data, ServerPlayer * /* = NULL */) const
    {
        data = data.toInt() - 1;
        return false;
    }
};

class JGDidong : public PhaseChangeSkill
{
public:
    JGDidong() : PhaseChangeSkill("jgdidong")
    {

    }

    virtual bool triggerable(const ServerPlayer *player) const
    {
        return TriggerSkill::triggerable(player) && player->getPhase() == Player::Finish;
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        QList<ServerPlayer *> players;
        foreach (ServerPlayer *p, room->getAlivePlayers()) {
            if (!p->isFriendWith(player))
                players << p;
        }

        player->tag.remove("jgdidong");
        ServerPlayer *victim = room->askForPlayerChosen(player, players, objectName(), "@jgdidong", true, true);
        if (victim != NULL) {
            player->tag["jgdidong"] = QVariant::fromValue(victim);
            return true;
        }
        return false;
    }

    virtual bool onPhaseChange(ServerPlayer *target) const
    {
        ServerPlayer *victim = target->tag["jgdidong"].value<ServerPlayer *>();
        target->tag.remove("jgdidong");
        if (victim != NULL)
            victim->turnOver();

        return false;
    }
};

class JGLianyu : public PhaseChangeSkill
{
public:
    JGLianyu() : PhaseChangeSkill("jglianyu")
    {

    }

    virtual bool triggerable(const ServerPlayer *target) const
    {
        return TriggerSkill::triggerable(target) && target->getPhase() == Player::Finish;
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

        QList<ServerPlayer *> players;
        foreach (ServerPlayer *p, room->getAlivePlayers()) {
            if (!p->isFriendWith(player)) {
                room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, player->objectName(), p->objectName());
                players << p;
            }
        }

        room->sortByActionOrder(players);
        foreach(ServerPlayer *p, players)
            room->damage(DamageStruct(objectName(), player, p, 1, DamageStruct::Fire));


        return false;
    }
};

class JGTanshi : public PhaseChangeSkill
{
public:
    JGTanshi() : PhaseChangeSkill("jgtanshi")
    {
        frequency = Compulsory;
    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *player, QVariant &, ServerPlayer* &) const
    {
        if (TriggerSkill::triggerable(player) && player->getPhase() == Player::Finish && !player->isKongcheng())
            return QStringList(objectName());

        return QStringList();
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

    virtual bool onPhaseChange(ServerPlayer *target) const
    {
        target->getRoom()->askForDiscard(target, "jgtanshi_discard", 1, 1);
        return false;
    }
};

class JGTunshi : public PhaseChangeSkill
{
public:
    JGTunshi() : PhaseChangeSkill("jgtunshi")
    {
        frequency = Compulsory;
    }

    virtual QStringList triggerable(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer* &) const
    {
        if (!TriggerSkill::triggerable(player) || player->getPhase() != Player::Start)
            return QStringList();

        foreach (ServerPlayer *p, room->getAlivePlayers()) {
            if (!p->isFriendWith(player) && p->getHandcardNum() > player->getHandcardNum())
                return QStringList(objectName());
        }

        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        return player->hasShownSkill(this) || player->askForSkillInvoke(this);
    }

    virtual bool onPhaseChange(ServerPlayer *target) const
    {
        Room *room = target->getRoom();
        room->sendCompulsoryTriggerLog(target, objectName());

        QList<ServerPlayer *> players;
        foreach (ServerPlayer *p, room->getAlivePlayers()) {
            if (!p->isFriendWith(target) && p->getHandcardNum() > target->getHandcardNum()) {
                room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, target->objectName(), p->objectName());
                players << p;
            }
        }

        room->sortByActionOrder(players);

        foreach(ServerPlayer *p, players)
            room->damage(DamageStruct(objectName(), target, p));

        return false;
    }
};

class JGNailuo : public PhaseChangeSkill
{
public:
    JGNailuo() : PhaseChangeSkill("jgnailuo")
    {

    }

    virtual bool triggerable(const ServerPlayer *player) const
    {
        return TriggerSkill::triggerable(player) && player->getPhase() == Player::Finish;
    }

    virtual bool cost(TriggerEvent, Room *, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        if (player->askForSkillInvoke(this)) {
            player->turnOver();
            return true;
        }
        return false;
    }

    virtual bool onPhaseChange(ServerPlayer *player) const
    {
        Room *room = player->getRoom();

        QList<ServerPlayer *> targets;

        foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
            if (!p->isFriendWith(player)) {
                room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, player->objectName(), p->objectName());
                targets << p;
            }
        }

        room->sortByActionOrder(targets);

        foreach(ServerPlayer *p, targets)
            p->throwAllEquips();
        return false;
    }
};

class JGQinzhen : public TriggerSkill
{
public:
    JGQinzhen() : TriggerSkill("jgqinzhen")
    {
        events << EventPhaseStart;
        frequency = Compulsory;
    }

    virtual TriggerList triggerable(TriggerEvent, Room *room, ServerPlayer *player, QVariant &) const
    {
        TriggerList skill_list;
        if (player == NULL || player->isDead() || player->getPhase() != Player::Play) return skill_list;
        QList<ServerPlayer *> liubeis = room->findPlayersBySkillName(objectName());
        foreach (ServerPlayer *liubei, liubeis) {
            if (liubei->isFriendWith(player))
                skill_list.insert(liubei, QStringList(objectName()));
        }
        return skill_list;
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *ask_who) const
    {
        bool invoke = false;
        if (ask_who->hasShownSkill(objectName())) {
            invoke = true;
            room->sendCompulsoryTriggerLog(ask_who, objectName());
        } else
            invoke = ask_who->askForSkillInvoke(this, QVariant::fromValue(player));

        if (invoke) {
            room->broadcastSkillInvoke(objectName(), ask_who);
            room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, ask_who->objectName(), player->objectName());
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        room->addPlayerMark(player, "GlobalSlashResidue-PhaseClear");
        return false;
    }
};

class JGZhenxi : public TriggerSkill
{
public:
    JGZhenxi() : TriggerSkill("jgzhenxi")
    {
        events << Damaged << EventPhaseChanging;
        frequency = Compulsory;
    }

    virtual void record(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (triggerEvent == EventPhaseChanging && data.value<PhaseChangeStruct>().from == Player::Draw) {
            room->setPlayerMark(player, "#jgzhenxi", 0);
        }
    }

    virtual TriggerList triggerable(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &) const
    {
        TriggerList skill_list;
        if (triggerEvent == Damaged) {
            if (player == NULL || player->isDead()) return skill_list;
            QList<ServerPlayer *> caozhens = room->findPlayersBySkillName(objectName());
            foreach (ServerPlayer *caozhen, caozhens) {
                if (caozhen->isFriendWith(player))
                    skill_list.insert(caozhen, QStringList(objectName()));
            }
        }
        return skill_list;
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *ask_who) const
    {
        bool invoke = false;
        if (ask_who->hasShownSkill(objectName())) {
            invoke = true;
            room->sendCompulsoryTriggerLog(ask_who, objectName());
        } else
            invoke = ask_who->askForSkillInvoke(this, QVariant::fromValue(player));

        if (invoke) {
            room->broadcastSkillInvoke(objectName(), ask_who);
            room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, ask_who->objectName(), player->objectName());
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        room->addPlayerMark(player, "#jgzhenxi");
        return false;
    }
};

class JGZhenxiDraw : public DrawCardsSkill
{
public:
    JGZhenxiDraw() : DrawCardsSkill("#jgzhenxi-draw")
    {
        frequency = Compulsory;
    }

    virtual QStringList triggerable(TriggerEvent , Room *, ServerPlayer *player, QVariant &, ServerPlayer* &) const
    {
        if (player->getMark("#jgzhenxi") > 0)
            return QStringList(objectName());

        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        room->sendSkillEffectTriggerLog(player, "jgzhenxi");
        return true;
    }

    virtual int getDrawNum(ServerPlayer *player, int n) const
    {
        return n + player->getMark("#jgzhenxi");
    }
};

class JGXiaorui : public TriggerSkill
{
public:
    JGXiaorui() : TriggerSkill("jgxiaorui")
    {
        events << Damage;
        frequency = Compulsory;
    }

    virtual TriggerList triggerable(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        TriggerList skill_list;
        if (player == NULL || player->isDead() || player->getPhase() != Player::Play) return skill_list;
        DamageStruct damage = data.value<DamageStruct>();
        if (damage.card && damage.card->isKindOf("Slash")) {
            QList<ServerPlayer *> guanyus = room->findPlayersBySkillName(objectName());
            foreach (ServerPlayer *guanyu, guanyus) {
                if (guanyu->isFriendWith(player))
                    skill_list.insert(guanyu, QStringList(objectName()));
            }
        }
        return skill_list;
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *ask_who) const
    {
        bool invoke = false;
        if (ask_who->hasShownSkill(objectName())) {
            invoke = true;
            room->sendCompulsoryTriggerLog(ask_who, objectName());
        } else
            invoke = ask_who->askForSkillInvoke(this, QVariant::fromValue(player));

        if (invoke) {
            room->broadcastSkillInvoke(objectName(), ask_who);
            room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, ask_who->objectName(), player->objectName());
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        room->addPlayerMark(player, "GlobalSlashResidue-PhaseClear");
        return false;
    }
};

class JGHuchen : public TriggerSkill
{
public:
    JGHuchen() : TriggerSkill("jghuchen")
    {
        events << DrawNCards << DeathFinished;
    }

    virtual QStringList triggerable(TriggerEvent triggerEvent, Room *, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
    {
        if (!TriggerSkill::triggerable(player)) return QStringList();
        if (triggerEvent == DrawNCards && player->getMark("#jghuchen") > 0) {
            return QStringList(objectName());
        } else if (triggerEvent == DeathFinished) {
            DeathStruct death = data.value<DeathStruct>();
            if (death.damage && death.damage->from == player && !player->isFriendWith(death.who))
                return QStringList(objectName());
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent , Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
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

    virtual bool effect(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (triggerEvent == DrawNCards)
            data = data.toInt() + player->getMark("#jghuchen");
        else if (triggerEvent == DeathFinished) {
            room->addPlayerMark(player, "#jghuchen");
        }
        return false;
    }
};

class JGTianjiang : public TriggerSkill
{
public:
    JGTianjiang() : TriggerSkill("jgtianjiang")
    {
        events << Damage << EventPhaseStart;
        frequency = Compulsory;
    }

    virtual void record(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &) const
    {
         if (triggerEvent == EventPhaseStart && player->getPhase() == Player::NotActive) {
             QList<ServerPlayer *> allplayers = room->getAlivePlayers();
             foreach (ServerPlayer *p, allplayers) {
                 p->tag.remove("jgtianjiang_invoked");
             }
         }
    }

    virtual TriggerList triggerable(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        TriggerList skill_list;
        if (triggerEvent == Damage) {
            if (player == NULL || player->isDead()) return skill_list;
            DamageStruct damage = data.value<DamageStruct>();
            if (damage.card && damage.card->isKindOf("Slash")) {
                QList<ServerPlayer *> guanyus = room->findPlayersBySkillName(objectName());
                foreach (ServerPlayer *guanyu, guanyus) {
                    if (guanyu->isFriendWith(player)) {
                        QStringList target_list = guanyu->tag["jgtianjiang_invoked"].toStringList();
                        if (!target_list.contains(player->objectName()))
                            skill_list.insert(guanyu, QStringList(objectName()));
                    }
                }
            }
        }
        return skill_list;
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *ask_who) const
    {
        bool invoke = false;
        if (ask_who->hasShownSkill(objectName())) {
            invoke = true;
            room->sendCompulsoryTriggerLog(ask_who, objectName());
        } else
            invoke = ask_who->askForSkillInvoke(this, QVariant::fromValue(player));

        if (invoke) {
            room->broadcastSkillInvoke(objectName(), ask_who);
            room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, ask_who->objectName(), player->objectName());
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent, Room *, ServerPlayer *player, QVariant &, ServerPlayer *ask_who) const
    {
        QStringList target_list = ask_who->tag["jgtianjiang_invoked"].toStringList();
        target_list.append(player->objectName());
        ask_who->tag["jgtianjiang_invoked"] = target_list;

        player->drawCards(1, objectName());
        return false;
    }
};

class JGFengjian : public TriggerSkill
{
public:
    JGFengjian() : TriggerSkill("jgfengjian")
    {
        events << Damage << EventPhaseStart;
        frequency = Compulsory;
    }

    virtual void record(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &) const
    {
         if (triggerEvent == EventPhaseStart && player->getPhase() == Player::NotActive) {
             room->setPlayerProperty(player, "jgfengjian_targets", QVariant());
            room->setPlayerMark(player, "##jgfengjian", 0);
         }
    }

    virtual QStringList triggerable(TriggerEvent triggerEvent, Room *, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
    {
        if (triggerEvent == Damage && TriggerSkill::triggerable(player)) {
            DamageStruct damage = data.value<DamageStruct>();
            if (damage.to && damage.to->isAlive())
                return QStringList(objectName());
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        if (damage.to == NULL || damage.to->isDead()) return false;
        bool invoke = false;
        if (player->hasShownSkill(objectName())) {
            invoke = true;
            room->sendCompulsoryTriggerLog(player, objectName());
        } else
            invoke = player->askForSkillInvoke(this, QVariant::fromValue(damage.to));

        if (invoke) {
            room->broadcastSkillInvoke(objectName(), player);
            room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, player->objectName(), damage.to->objectName());
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        if (damage.to && damage.to->isAlive()) {
            QStringList assignee_list = damage.to->property("jgfengjian_targets").toString().split("+");
            assignee_list << player->objectName();
            room->setPlayerProperty(damage.to, "jgfengjian_targets", assignee_list.join("+"));
            room->addPlayerMark(damage.to, "##jgfengjian");
        }
        return false;
    }
};

class JGFengjianProhibit : public ProhibitSkill
{
public:
    JGFengjianProhibit() : ProhibitSkill("#jgfengjian-prohibit")
    {
    }

    virtual bool isProhibited(const Player *from, const Player *to, const Card *card, const QList<const Player *> &) const
    {
        if (from && to && card->getTypeId() != Card::TypeSkill) {
            QStringList assignee_list = from->property("jgfengjian_targets").toString().split("+");
            return assignee_list.contains(to->objectName());
        }
        return false;
    }
};

JGKedingCard::JGKedingCard()
{

}

bool JGKedingCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    QStringList available_targets = Self->property("jgkeding_available_targets").toString().split("+");
    return targets.length() < subcardsLength() && available_targets.contains(to_select->objectName());
}

bool JGKedingCard::targetsFeasible(const QList<const Player *> &targets, const Player *) const
{
    return targets.length() == subcardsLength();
}

void JGKedingCard::use(Room *, ServerPlayer *source, QList<ServerPlayer *> &targets) const
{
    QStringList target_list = source->tag["jgkeding_target"].toStringList();

    QStringList names;
    foreach (ServerPlayer *p, targets) {
        names << p->objectName();
    }

    target_list << names.join("+");

    source->tag["jgkeding_target"] = target_list;
}

class JGKedingViewAsSkill : public ViewAsSkill
{
public:
    JGKedingViewAsSkill() : ViewAsSkill("jgkeding")
    {
        response_pattern = "@@jgkeding";
    }

    virtual bool viewFilter(const QList<const Card *> &, const Card *to_select) const
    {
        return !Self->isJilei(to_select) && !to_select->isEquipped();
    }

    virtual const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (cards.isEmpty()) return NULL;
        JGKedingCard *skill_card = new JGKedingCard;
        skill_card->addSubcards(cards);
        return skill_card;
    }
};

class JGKeding : public TriggerSkill
{
public:
    JGKeding() : TriggerSkill("jgkeding")
    {
        events << TargetSelected;
        view_as_skill = new JGKedingViewAsSkill;
    }

    virtual QStringList triggerable(TriggerEvent , Room *room, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        if (TriggerSkill::triggerable(player) && !player->isKongcheng()) {
            CardUseStruct use = data.value<CardUseStruct>();
            if (use.card->isKindOf("Slash") || use.card->isNDTrick()) {
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
        QStringList available_targets;
        QList<ServerPlayer *> targets = room->getUseExtraTargets(use);
        foreach (ServerPlayer *p, targets) {
            available_targets << p->objectName();
        }
        room->setPlayerProperty(player, "jgkeding_available_targets", available_targets.join("+"));
        player->tag["jgkeding-use"] = data;
        const Card *card = room->askForUseCard(player, "@@jgkeding", "@jgkeding:::" + use.card->objectName(), -1, Card::MethodDiscard);
        room->setPlayerProperty(player, "jgkeding_available_targets", QVariant());
        player->tag.remove("jgkeding-use");
        if (card != NULL)
            return true;

        return false;
    }

    virtual bool effect(TriggerEvent , Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        QStringList target_list = player->tag["jgkeding_target"].toStringList();
        if (target_list.isEmpty()) return false;
        QStringList target_names = target_list.takeLast().split("+");
        player->tag["jgkeding_target"] = target_list;

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

class JGLongwei : public TriggerSkill
{
public:
    JGLongwei() : TriggerSkill("jglongwei")
    {
        events << AskForPeaches;
    }

    virtual QStringList triggerable(TriggerEvent , Room *, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
    {
        if (!TriggerSkill::triggerable(player) || player->getMaxHp() < 2) return QStringList();
        DyingStruct dying_data = data.value<DyingStruct>();
        if (dying_data.who->getHp() > 0 || dying_data.who->isDead() || !dying_data.who->isFriendWith(player))
            return QStringList();
        return QStringList(objectName());
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        DyingStruct dying_data = data.value<DyingStruct>();
        if (player->askForSkillInvoke(this, QVariant::fromValue(dying_data.who))) {
            room->broadcastSkillInvoke(objectName(), player);
            room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, player->objectName(), dying_data.who->objectName());
            room->loseMaxHp(player);
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        DyingStruct dying_data = data.value<DyingStruct>();
        if (dying_data.who->getHp() < 1) {
            RecoverStruct recover;
            recover.recover = 1 - dying_data.who->getHp();
            recover.who = player;
            room->recover(dying_data.who, recover);
        }
        return false;
    }
};

class JGBashi : public TriggerSkill
{
public:
    JGBashi() : TriggerSkill("jgbashi")
    {
        events << TargetConfirming;
    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        if (!TriggerSkill::triggerable(player) || !player->faceUp()) return QStringList();
        CardUseStruct use = data.value<CardUseStruct>();
        if ((use.card->isKindOf("Slash") || use.card->isNDTrick()) && use.from != player && use.to.contains(player))
            return QStringList(objectName());

        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (player->askForSkillInvoke(this, data)) {
            room->broadcastSkillInvoke(objectName(), player);
            player->turnOver();
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        room->cancelTarget(use, player); // Room::cancelTarget(use, player);
        data = QVariant::fromValue(use);
        return false;
    }
};

class JGDanjing : public TriggerSkill
{
public:
    JGDanjing() : TriggerSkill("jgdanjing")
    {
        events << Dying;
    }

    virtual QStringList triggerable(TriggerEvent , Room *, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
    {
        if (TriggerSkill::triggerable(player) && player->getHp() > 1 && !player->isRemoved()) {
            DyingStruct dying = data.value<DyingStruct>();
            if (dying.who && dying.who->isFriendWith(player) && dying.who->getHp() < 1)
            return QStringList(objectName());
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent , Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        if (player->askForSkillInvoke(this)) {
            room->broadcastSkillInvoke(objectName(), player);
            room->loseHp(player);
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent , Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        DyingStruct dying = data.value<DyingStruct>();
        if (dying.who && dying.who->isAlive()) {
            Peach *peach = new Peach(Card::NoSuit, 0);
            peach->setSkillName("_jgdanjing");
            peach->setFlags("UsedBySecondWay");
            room->useCard(CardUseStruct(peach, player, dying.who), false);
        }
        return false;
    }
};

class JGTongjun : public AttackRangeSkill
{
public:
    JGTongjun() : AttackRangeSkill("jgtongjun")
    {
    }

    virtual int getExtra(const Player *target, bool) const
    {
        if (target->enjoyingSkill(objectName(), true, true) && target->getGeneral()->objectName().contains("machine")) {
            return 1;
        }
        return 0;
    }
};

JGJiaoxieCard::JGJiaoxieCard()
{

}

bool JGJiaoxieCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.length() < 2 && !to_select->isFriendWith(Self) && to_select->getGeneral()->objectName().contains("machine") && !to_select->isNude();
}

void JGJiaoxieCard::onEffect(const CardEffectStruct &effect) const
{
    ServerPlayer *source = effect.from;
    ServerPlayer *target = effect.to;
    Room *room = source->getRoom();

    if (source->isAlive() && target->isAlive() && !target->isNude()) {
        QList<int> result = room->askForExchange(target, "jgjiaoxie_give", 1, 1, QString("@jgjiaoxie:%1").arg(source->objectName()), "", ".");
        DummyCard dummy(result);
        CardMoveReason reason = CardMoveReason(CardMoveReason::S_REASON_GIVE, target->objectName());
        room->moveCardTo(&dummy, source, Player::PlaceHand, reason);
    }
}

class JGJiaoxie : public ZeroCardViewAsSkill
{
public:
    JGJiaoxie() : ZeroCardViewAsSkill("jgjiaoxie")
    {

    }

    virtual bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("JGJiaoxieCard");
    }

    virtual const Card *viewAs() const
    {
        JGJiaoxieCard *skillcard = new JGJiaoxieCard;
        skillcard->setShowSkill(objectName());
        return skillcard;
    }
};

class JGShuailing : public TriggerSkill
{
public:
    JGShuailing() : TriggerSkill("jgshuailing")
    {
        events << EventPhaseStart;
        frequency = Compulsory;
    }

    virtual TriggerList triggerable(TriggerEvent, Room *room, ServerPlayer *player, QVariant &) const
    {
        TriggerList skill_list;
        if (player == NULL || player->isDead() || player->getPhase() != Player::Draw) return skill_list;
        QList<ServerPlayer *> zhangliaos = room->findPlayersBySkillName(objectName());
        foreach (ServerPlayer *zhangliao, zhangliaos) {
            if (zhangliao->isFriendWith(player))
                skill_list.insert(zhangliao, QStringList(objectName()));
        }
        return skill_list;
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *ask_who) const
    {
        bool invoke = false;
        if (ask_who->hasShownSkill(objectName())) {
            invoke = true;
            room->sendCompulsoryTriggerLog(ask_who, objectName());
        } else
            invoke = ask_who->askForSkillInvoke(this, QVariant::fromValue(player));

        if (invoke) {
            room->broadcastSkillInvoke(objectName(), ask_who);
            room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, ask_who->objectName(), player->objectName());
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        JudgeStruct judge;
        judge.pattern = ".|black";
        judge.good = true;
        judge.reason = objectName();
        judge.who = player;
        room->judge(judge);
        if (judge.isGood() && room->getCardPlace(judge.card->getEffectiveId()) == Player::DiscardPile)
            player->obtainCard(judge.card);
        return false;
    }
};


JiangeDefensePackage::JiangeDefensePackage()
    : Package("jiange-defense")
{

    General *liubei = new General(this, "jg_liubei", "shu", 5, true, true);
    liubei->addSkill(new JGJizhen);
    liubei->addSkill(new JGLingfeng);
    liubei->addSkill(new JGQinzhen);

    General *guanyu = new General(this, "jg_guanyu", "shu", 5, true, true);
    guanyu->addSkill(new JGXiaorui);
    guanyu->addSkill(new JGHuchen);
    guanyu->addSkill(new JGTianjiang);

    General *zhaoyun = new General(this, "jg_zhaoyun", "shu", 5, true, true);
    zhaoyun->addSkill(new JGFengjian);
    zhaoyun->addSkill(new JGFengjianProhibit);
    insertRelatedSkills("jgfengjian", "#jgfengjian-prohibit");
    zhaoyun->addSkill(new JGKeding);
    zhaoyun->addSkill(new JGLongwei);

    General *zhuge = new General(this, "jg_zhuge", "shu", 4, true, true);
    zhuge->addSkill(new JGBiantian);
    zhuge->addSkill(new JGBiantianDW);
    zhuge->addSkill(new JGBiantianKF);
    insertRelatedSkills("jgbiantian", 2, "#jgbiantian-dw", "#jgbiantian-kf");
    zhuge->addSkill("bazhen");

    General *yueying = new General(this, "jg_yueying", "shu", 4, false, true);
    yueying->addSkill(new JGGongshen);
    yueying->addSkill(new JGZhinang);
    yueying->addSkill(new JGJingmiao);

    General *pangtong = new General(this, "jg_pangtong", "shu", 4, true, true);
    pangtong->addSkill(new JGYuhuo("pangtong"));
    pangtong->addSkill(new JGQiwu);
    pangtong->addSkill(new JGTianyu);

    General *qinglong = new General(this, "jg_qinglong_machine", "shu", 4, true, true);
    qinglong->addSkill(new JGJiguan("qinglong"));
    qinglong->addSkill(new JGMojian);

    General *baihu = new General(this, "jg_baihu_machine", "shu", 4, true, true);
    baihu->addSkill(new JGJiguan("baihu"));
    baihu->addSkill(new JGZhenwei);
    baihu->addSkill(new JGBenlei);

    General *zhuque = new General(this, "jg_zhuque_machine", "shu", 5, false, true);
    zhuque->addSkill(new JGJiguan("zhuque"));
    zhuque->addSkill(new JGYuhuo("zhuque"));
    zhuque->addSkill(new JGTianyun);

    General *xuanwu = new General(this, "jg_xuanwu_machine", "shu", 5, true, true);
    xuanwu->addSkill(new JGJiguan("xuanwu"));
    xuanwu->addSkill(new JGYizhong);
    xuanwu->addSkill(new JGLingyu);

    //------------------------------------------------------------------------------------

    General *xiahoudun = new General(this, "jg_xiahoudun", "wei", 5, true, true);
    xiahoudun->addSkill(new JGBashi);
    xiahoudun->addSkill(new JGDanjing);
    xiahoudun->addSkill(new JGTongjun);

    General *zhangliao = new General(this, "jg_zhangliao", "wei", 5, true, true);
    zhangliao->addSkill(new JGJiaoxie);
    zhangliao->addSkill(new JGShuailing);

    General *caozhen = new General(this, "jg_caozhen", "wei", 5, true, true);
    caozhen->addSkill(new JGChiying);
    caozhen->addSkill(new JGJingfan);
    caozhen->addSkill(new JGZhenxi);
    caozhen->addSkill(new JGZhenxiDraw);
    insertRelatedSkills("jgzhenxi", "#jgzhenxi-draw");

    General *xiahou = new General(this, "jg_xiahou", "wei", 4, true, true);
    xiahou->addSkill(new JGChuanyun);
    xiahou->addSkill(new JGLeili);
    xiahou->addSkill(new JGFengxing);

    General *sima = new General(this, "jg_sima", "wei", 5, true, true);
    sima->addSkill(new JGKonghun);
    sima->addSkill(new JGKonghunRecord);
    insertRelatedSkills("jgkonghun", "#jgkonghun-record");
    sima->addSkill(new JGFanshi);
    sima->addSkill(new JGXuanlei);

    General *zhanghe = new General(this, "jg_zhanghe", "wei", 4, true, true);
    zhanghe->addSkill(new JGHuodi);
    zhanghe->addSkill(new JGJueji);

    General *bian = new General(this, "jg_bian_machine", "wei", 4, true, true);
    bian->addSkill(new JGJiguan("bian"));
    bian->addSkill(new JGDidong);

    General *suanni = new General(this, "jg_suanni_machine", "wei", 3, true, true);
    suanni->addSkill(new JGJiguan("suanni"));
    suanni->addSkill(new JGLianyu);

    General *taotie = new General(this, "jg_chiwen_machine", "wei", 5, true, true);
    taotie->addSkill(new JGJiguan("chiwen"));
    taotie->addSkill(new JGTanshi);
    taotie->addSkill(new JGTunshi);

    General *yazi = new General(this, "jg_yazi_machine", "wei", 5, true, true);
    yazi->addSkill(new JGJiguan("yazi"));
    yazi->addSkill(new JGNailuo);

    addMetaObject<JGKedingCard>();
    addMetaObject<JGJiaoxieCard>();
}

ADD_PACKAGE(JiangeDefense)
