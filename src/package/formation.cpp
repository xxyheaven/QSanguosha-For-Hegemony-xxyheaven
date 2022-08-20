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

#include "formation.h"
#include "standard-basics.h"
#include "standard-tricks.h"
#include "client.h"
#include "engine.h"
#include "structs.h"
#include "gamerule.h"
#include "settings.h"
#include "json.h"
#include "roomthread.h"

class Tuntian : public TriggerSkill
{
public:
    Tuntian() : TriggerSkill("tuntian")
    {
        events << CardsMoveOneTime;
        frequency = Frequent;
    }

    virtual QStringList triggerable(TriggerEvent , Room *, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
    {
        if (TriggerSkill::triggerable(player) && player->getPhase() == Player::NotActive) {

            QVariantList move_datas = data.toList();

            foreach (QVariant move_data, move_datas) {
                CardsMoveOneTimeStruct move = move_data.value<CardsMoveOneTimeStruct>();
                if (move.from == player && (move.from_places.contains(Player::PlaceHand) || move.from_places.contains(Player::PlaceEquip))
                    && !(move.to == player && (move.to_place == Player::PlaceHand || move.to_place == Player::PlaceEquip))) {
                    return QStringList(objectName());
                }
            }
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *, QVariant &data, ServerPlayer *dengai) const
    {
        if (dengai->askForSkillInvoke(this, data)) {
            room->broadcastSkillInvoke(objectName(), dengai);
            return true;
        }

        return false;
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *, QVariant &data, ServerPlayer *dengai) const
    {
        JudgeStruct judge;
        judge.pattern = ".|heart";
        judge.good = false;
        judge.reason = "tuntian";
        judge.who = dengai;
        room->judge(judge);
        if (room->getCardPlace(judge.card->getEffectiveId()) == Player::DiscardPile && judge.isGood()
               && room->askForChoice(dengai, objectName(), "yes+no", data, "@tuntian-gotofield:::"+judge.card->objectName()) == "yes") {
            dengai->addToPile("field", judge.card);
        }

        return false;
    }
};

class TuntianDistance : public DistanceSkill
{
public:
    TuntianDistance() : DistanceSkill("#tuntian-dist")
    {
    }

    virtual int getCorrect(const Player *from, const Player *) const
    {
        if (from->hasShownSkill("tuntian"))
            return -from->getPile("field").length();
        else
            return 0;
    }
};

class Jixi : public OneCardViewAsSkill
{
public:
    Jixi() : OneCardViewAsSkill("jixi")
    {
        relate_to_place = "head";
        filter_pattern = ".|.|.|field";
        expand_pile = "field";
    }

    virtual bool isEnabledAtPlay(const Player *player) const
    {
        return !player->getPile("field").isEmpty();
    }

    virtual const Card *viewAs(const Card *originalCard) const
    {
        Snatch *shun = new Snatch(originalCard->getSuit(), originalCard->getNumber());
        shun->addSubcard(originalCard);
        shun->setSkillName(objectName());
        shun->setShowSkill(objectName());
        return shun;
    }
};

ZiliangCard::ZiliangCard()
{
    target_fixed = true;
    will_throw = false;
    handling_method = Card::MethodNone;
}

void ZiliangCard::use(Room *, ServerPlayer *source, QList<ServerPlayer *> &) const
{
    source->tag["ziliang"] = subcards.first();
}

class ZiliangVS : public OneCardViewAsSkill
{
public:
    ZiliangVS() : OneCardViewAsSkill("ziliang")
    {
        response_pattern = "@@ziliang";
        filter_pattern = ".|.|.|field";
        expand_pile = "field";
    }

    virtual const Card *viewAs(const Card *originalCard) const
    {
        ZiliangCard *c = new ZiliangCard;
        c->addSubcard(originalCard);
        c->setShowSkill(objectName());
        return c;
    }
};

class Ziliang : public TriggerSkill
{
public:
    Ziliang() : TriggerSkill("ziliang")
    {
        events << Damaged;
        relate_to_place = "deputy";
        view_as_skill = new ZiliangVS;
    }

    virtual TriggerList triggerable(TriggerEvent, Room *room, ServerPlayer *player, QVariant &) const
    {
        TriggerList skill_list;
        if (player == NULL || player->isDead()) return skill_list;
        QList<ServerPlayer *> dengais = room->findPlayersBySkillName(objectName());
        foreach (ServerPlayer *dengai, dengais) {
            if (!dengai->getPile("field").isEmpty() && dengai->isFriendWith(player))
                skill_list.insert(dengai, QStringList(objectName()));
        }
        return skill_list;
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *, QVariant &data, ServerPlayer *ask_who) const
    {
        ServerPlayer *player = ask_who;
        player->tag.remove("ziliang");
        player->tag["ziliang_aidata"] = data;
        if (room->askForUseCard(player, "@@ziliang", "@ziliang-give", -1, Card::MethodNone))
            return true;

        return false;
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *ask_who) const
    {
        ServerPlayer *dengai = ask_who;
        if (!dengai) return false;

        bool ok = false;
        int id = dengai->tag["ziliang"].toInt(&ok);

        if (!ok) return false;

        if (player == dengai) {
            LogMessage log;
            log.type = "$MoveCard";
            log.from = player;
            log.to << player;
            log.card_str = QString::number(id);
            room->sendLog(log);
        } else
            room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, dengai->objectName(), player->objectName());
        room->obtainCard(player, id);

        return false;
    }
};

HuyuanCard::HuyuanCard()
{
    will_throw = false;
    handling_method = Card::MethodNone;
}

bool HuyuanCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    if (!targets.isEmpty()) return false;
    const Card *huyuancard = Sanguosha->getCard(getEffectiveId());
    if (huyuancard->getTypeId() == Card::TypeEquip)
        return to_select->canSetEquip(Sanguosha->getCard(getEffectiveId()));
    return to_select != Self;
}

void HuyuanCard::onEffect(const CardEffectStruct &effect) const
{
    Room *room = effect.from->getRoom();
    const Card *huyuancard = Sanguosha->getCard(getEffectiveId());
    if (huyuancard->getTypeId() == Card::TypeEquip) {
        LogMessage log;
        log.type = "$ZhijianEquip";
        log.from = effect.to;
        log.card_str = QString::number(getEffectiveId());
        room->sendLog(log);
        room->moveCardTo(this, effect.from, effect.to, Player::PlaceEquip,
            CardMoveReason(CardMoveReason::S_REASON_PUT, effect.from->objectName(), "huyuan", QString()));

    } else {
        CardMoveReason reason(CardMoveReason::S_REASON_GIVE, effect.from->objectName(), effect.to->objectName(), "huyuan", QString());
        room->obtainCard(effect.to, this, reason, false);
    }
}

class HuyuanViewAsSkill : public OneCardViewAsSkill
{
public:
    HuyuanViewAsSkill() : OneCardViewAsSkill("huyuan")
    {
        response_pattern = "@@huyuan";
        filter_pattern = ".";
    }

    virtual const Card *viewAs(const Card *originalcard) const
    {
        HuyuanCard *first = new HuyuanCard;
        first->addSubcard(originalcard->getId());
        first->setSkillName(objectName());
        return first;
    }
};

class Huyuan : public PhaseChangeSkill
{
public:
    Huyuan() : PhaseChangeSkill("huyuan")
    {
        view_as_skill = new HuyuanViewAsSkill;
    }

    virtual bool canPreshow() const
    {
        return true;
    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *target, QVariant &, ServerPlayer* &) const
    {
        if (!PhaseChangeSkill::triggerable(target)) return QStringList();
        if (target->getPhase() == Player::Finish && !target->isNude())
            return QStringList(objectName());
        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *target, QVariant &, ServerPlayer *) const
    {
        const Card *huyuancard = room->askForUseCard(target, "@@huyuan", "@huyuan-equip", -1, Card::MethodNone);
        if (huyuancard != NULL) {
            room->setPlayerMark(target, "HuyuanCardID", huyuancard->getEffectiveId());
            return true;
        }
        return false;
    }

    virtual bool onPhaseChange(ServerPlayer *caohong) const
    {
        Room *room = caohong->getRoom();
        int id = caohong->getMark("HuyuanCardID");
        room->setPlayerMark(caohong, "HuyuanCardID", 0);
        if (Sanguosha->getCard(id)->getTypeId() != Card::TypeEquip) return false;

        QList<ServerPlayer *> targets, all_players = room->getAllPlayers();
        foreach (ServerPlayer *p, all_players) {
            if (caohong->canDiscard(p, "ej"))
                targets << p;
        }
        if (!targets.isEmpty()) {
            ServerPlayer *to_dismantle = room->askForPlayerChosen(caohong, targets, "huyuan", "@huyuan-discard", true);
            if (to_dismantle != NULL) {
                int card_id = room->askForCardChosen(caohong, to_dismantle, "ej", "huyuan", false, Card::MethodDiscard);
                room->throwCard(Sanguosha->getCard(card_id), to_dismantle, caohong);
            }
        }
        return false;
    }
};

HeyiSummon::HeyiSummon()
    : ArraySummonCard("heyi")
{
    mute = true;
}

class Heyi : public BattleArraySkill
{
public:
    Heyi() : BattleArraySkill("heyi", HegemonyMode::Formation)
    {
        events << EventPhaseStart << GeneralShown;
    }

    virtual bool canPreshow() const
    {
        return false;
    }

    virtual void record(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (triggerEvent == EventPhaseStart) {
            if (player != NULL && player->isAlive() && player->getPhase() == Player::RoundStart) {
                ServerPlayer *caohong = room->findPlayerBySkillName("heyi");
                if (caohong && caohong->isAlive() && caohong->hasShownSkill("heyi") && player->inFormationRalation(caohong)) {
                    room->doBattleArrayAnimate(caohong);
                    room->broadcastSkillInvoke(objectName(), caohong);
                }
            }
        } else if (triggerEvent == GeneralShown) {
            if (TriggerSkill::triggerable(player) && player->hasShownSkill(objectName()) && data.toBool() == player->inHeadSkills(objectName())) {
                room->doBattleArrayAnimate(player);
                room->broadcastSkillInvoke(objectName(), player);
            }
        }
    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *, QVariant &, ServerPlayer * &) const
    {
        return QStringList();
    }
};

class FeiyingVH : public ViewHasSkill
{
public:
    FeiyingVH() : ViewHasSkill("feiyingVH")
    {
        global = true;
    }

    virtual bool ViewHas(const Player *player, const QString &skill_name, const QString &flag) const
    {
        if (flag != "skill" || skill_name != "feiying") return false;
        QList<const Player *> caohongs;
        QList<const Player *> sib = player->getAliveSiblings();
        sib << player;
        if (sib.length() < 4) return false;

        foreach (const Player *p, sib)
            if (p->hasShownSkill("heyi"))
                caohongs << p;

        foreach (const Player *caohong, caohongs)
            if (caohong->getFormation().contains(player))
                return true;

        return false;
    }
};

class Feiying : public DistanceSkill
{
public:
    Feiying() : DistanceSkill("feiying")
    {
    }

    virtual int getCorrect(const Player *, const Player *to) const
    {
        if (to->hasShownSkill(objectName()))
            return 1;
        else
            return 0;
    }
};

TiaoxinCard::TiaoxinCard()
{
}

bool TiaoxinCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.isEmpty() && to_select->inMyAttackRange(Self) && to_select != Self;
}

void TiaoxinCard::onEffect(const CardEffectStruct &effect) const
{
    Room *room = effect.from->getRoom();
    bool use_slash = false;
    if (effect.to->canSlash(effect.from, NULL, false))
        use_slash = room->askForUseSlashTo(effect.to, effect.from, "@tiaoxin-slash:" + effect.from->objectName());
    if (!use_slash && effect.from->canDiscard(effect.to, "he"))
        room->throwCard(room->askForCardChosen(effect.from, effect.to, "he", "tiaoxin", false, Card::MethodDiscard), effect.to, effect.from);
}

class Tiaoxin : public ZeroCardViewAsSkill
{
public:
    Tiaoxin() : ZeroCardViewAsSkill("tiaoxin")
    {
    }

    virtual bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("TiaoxinCard");
    }

    virtual const Card *viewAs() const
    {
        TiaoxinCard *card = new TiaoxinCard;
        card->setShowSkill(objectName());
        return card;
    }
};

class Yizhi : public TriggerSkill
{
public:
    Yizhi() : TriggerSkill("yizhi")
    {
        events << GeneralShown << GeneralHidden << EventLoseSkill << DFDebut;
        relate_to_place = "deputy";
        frequency = Compulsory;
    }

    virtual bool canPreshow() const
    {
        return false;
    }

    virtual void record(TriggerEvent, Room *room, ServerPlayer *player, QVariant &) const
    {
        if (player == NULL) return;
        bool has_head_guanxing = false;
        foreach (const Skill *skill, player->getHeadSkillList(true, true)) {
            if (skill->objectName() == "guanxing")
                has_head_guanxing = true;
        }

        if (player->hasShownSkill(objectName()) && !(has_head_guanxing && player->hasShownGeneral1())) {
            room->handleAcquireDetachSkills(player, "guanxing_jiangwei!");
        } else if (player->getAcquiredSkills().contains("guanxing_jiangwei")) {
            room->handleAcquireDetachSkills(player, "-guanxing_jiangwei!");
        }
        return;
    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *, QVariant &, ServerPlayer* &) const
    {
        return QStringList();
    }
};

class GuanxingJiangwei : public PhaseChangeSkill
{
public:
    GuanxingJiangwei() : PhaseChangeSkill("guanxing_jiangwei")
    {
        frequency = Frequent;
    }

    virtual bool triggerable(const ServerPlayer *player) const
    {
        return TriggerSkill::triggerable(player) && player->getPhase() == Player::Start;
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        if (player->askForSkillInvoke(this)) {
            room->broadcastSkillInvoke(objectName(), player);
            return true;
        }
        return false;
    }

    virtual bool onPhaseChange(ServerPlayer *zhuge) const
    {
        Room *room = zhuge->getRoom();
        QList<int> guanxing = room->getNCards(qMin(5, zhuge->aliveCount()));

        LogMessage log;
        log.type = "$ViewDrawPile";
        log.from = zhuge;
        log.card_str = IntList2StringList(guanxing).join("+");
        room->doNotify(zhuge, QSanProtocol::S_COMMAND_LOG_SKILL, log.toVariant());

        room->askForGuanxing(zhuge, guanxing, Room::GuanxingBothSides);
        return false;
    }
};

TianfuSummon::TianfuSummon()
    : ArraySummonCard("tianfu")
{
}

class Tianfu : public BattleArraySkill
{
public:
    Tianfu() : BattleArraySkill("tianfu", HegemonyMode::Formation)
    {
        events << EventPhaseStart << Death << EventLoseSkill << EventAcquireSkill
            << GeneralShown << GeneralHidden << GeneralRemoved << RemoveStateChanged;
        relate_to_place = "head";
    }

    virtual bool canPreshow() const
    {
        return false;
    }

    virtual QStringList triggerable(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        if (player == NULL) return QStringList();

        if (triggerEvent == EventPhaseStart) {
            if (player->getPhase() != Player::RoundStart)
                return QStringList();
        } else if (triggerEvent == Death) {
            DeathStruct death = data.value<DeathStruct>();
            if (player != death.who)
                return QStringList();
        }

        foreach (ServerPlayer *p, room->getPlayers()) {
            if (p->getMark("tianfu_kanpo") > 0 && p->hasSkill("kanpo") && !p->hasInnateSkill("kanpo")) {
                p->setMark("tianfu_kanpo", 0);
                room->detachSkillFromPlayer(p, "kanpo", true, true);
            }
        }

        if (triggerEvent == EventLoseSkill && data.toString().split(":").first() == "tianfu")
            return QStringList();
        if (triggerEvent == GeneralHidden && player->ownSkill(this) && player->inHeadSkills(objectName()) == data.toBool())
            return QStringList();
        if (triggerEvent == GeneralRemoved && data.toString() == "jiangwei")
            return QStringList();
        if (player->aliveCount() < 4)
            return QStringList();

        ServerPlayer *current = room->getCurrent();
        if (current && current->isAlive() && current->getPhase() != Player::NotActive) {
            QList<ServerPlayer *> jiangweis = room->findPlayersBySkillName(objectName());
            foreach (ServerPlayer *jiangwei, jiangweis) {
                if (jiangwei->hasShownSkill(this) && jiangwei->inFormationRalation(current) && !jiangwei->hasInnateSkill("kanpo")) {
                    room->doBattleArrayAnimate(jiangwei);
                    jiangwei->setMark("tianfu_kanpo", 1);
                    room->attachSkillToPlayer(jiangwei, "kanpo");
                }
            }
        }

        return QStringList();
    }
};

class Shengxi : public TriggerSkill
{
public:
    Shengxi() : TriggerSkill("shengxi")
    {
        events << DamageDone << EventPhaseStart;
        frequency = Frequent;
    }

    virtual QStringList triggerable(TriggerEvent triggerEvent, Room *, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
    {
        if (triggerEvent == EventPhaseStart) {
            if (TriggerSkill::triggerable(player) && player->getPhase() == Player::Finish && !player->hasFlag("ShengxiDamaged"))
                return QStringList(objectName());
        } else if (triggerEvent == DamageDone) {
            DamageStruct damage = data.value<DamageStruct>();
            if (damage.from && damage.from->getPhase() != Player::NotActive && !damage.from->hasFlag("ShengxiDamaged"))
                damage.from->setFlags("ShengxiDamaged");
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

    virtual bool effect(TriggerEvent, Room *, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        player->drawCards(2, objectName());
        return false;
    }
};

class Shoucheng : public TriggerSkill
{
public:
    Shoucheng() : TriggerSkill("shoucheng")
    {
        events << CardsMoveOneTime;
        frequency = Frequent;
    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
    {
        if (!TriggerSkill::triggerable(player)) return QStringList();

        QVariantList move_datas = data.toList();

        foreach (QVariant move_data, move_datas) {
            CardsMoveOneTimeStruct move = move_data.value<CardsMoveOneTimeStruct>();
            if (move.from && move.from->isAlive() && move.from->getPhase() == Player::NotActive && (move.from->isFriendWith(player))
                && move.from_places.contains(Player::PlaceHand) && move.from->isKongcheng())
                return QStringList(objectName());

        }

        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        QVariantList move_datas = data.toList();
        QList<ServerPlayer *> targets;
        foreach (QVariant move_data, move_datas) {
            CardsMoveOneTimeStruct move = move_data.value<CardsMoveOneTimeStruct>();
            if (move.from && move.from->isAlive() && move.from->getPhase() == Player::NotActive && (move.from->isFriendWith(player))
                && move.from_places.contains(Player::PlaceHand) && move.from->isKongcheng()) {
                ServerPlayer *move_from = (ServerPlayer *)move.from;
                if (!targets.contains(move_from))
                    targets << move_from;
            }
        }
        if (targets.length() == 1) {
            ServerPlayer *target = targets.first();
            if (room->askForSkillInvoke(player, objectName(), QVariant::fromValue(target))) {
                player->broadcastSkillInvoke(objectName());
                room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, player->objectName(), target->objectName());

                QStringList target_list = player->tag["shoucheng_target"].toStringList();
                target_list.append(target->objectName());
                player->tag["shoucheng_target"] = target_list;

                return true;
            }
        } else if (targets.length() > 1) {
            QList<ServerPlayer *> choosees = room->askForPlayersChosen(player, targets, objectName(), 0, targets.length(), "@shoucheng", true);
            if (choosees.length() > 0) {

                QStringList target_list = player->tag["shoucheng_target"].toStringList();

                QStringList names;
                foreach (ServerPlayer *p, choosees) {
                    names << p->objectName();
                }

                target_list << names.join("+");

                player->tag["shoucheng_target"] = target_list;

                return true;
            }
        }
        return false;
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        QStringList target_list = player->tag["shoucheng_target"].toStringList();
        if (target_list.isEmpty()) return false;
        QStringList target_names = target_list.takeLast().split("+");
        player->tag["shoucheng_target"] = target_list;

        QList<ServerPlayer *> targets;
        foreach (QString name, target_names) {
            ServerPlayer *target = room->findPlayerbyobjectName(name);
            if (target)
                targets << target;
        }
        room->sortByActionOrder(targets);
        foreach (ServerPlayer *p, targets) {
            p->drawCards(1, objectName());
        }

        return false;
    }
};

ShangyiCard::ShangyiCard()
{

}

bool ShangyiCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.isEmpty() && (!to_select->isKongcheng() || !to_select->hasShownAllGenerals()) && to_select != Self;
}

void ShangyiCard::extraCost(Room *room, const CardUseStruct &card_use) const
{
    if (!card_use.to.isEmpty())
        room->doGongxin(card_use.to.first(), card_use.from);
}

void ShangyiCard::onEffect(const CardEffectStruct &effect) const
{
    Room *room = effect.from->getRoom();

    QStringList choices;
    if (!effect.to->isKongcheng())
        choices << "handcards";
    if (!effect.to->hasShownAllGenerals())
        choices << "hidden_general";

    if (choices.isEmpty()) return;

    room->setPlayerFlag(effect.to, "shangyiTarget");        //for AI
    QString choice = room->askForChoice(effect.from, "shangyi" , choices.join("+"), QVariant::fromValue(effect.to), "@shangyi-choose::"+effect.to->objectName(), "handcards+hidden_general");
    room->setPlayerFlag(effect.to, "-shangyiTarget");
    LogMessage log;
    log.type = "#KnownBothView";
    log.from = effect.from;
    log.to << effect.to;
    log.arg = choice;
    foreach (ServerPlayer *p, room->getOtherPlayers(effect.from, true))
        room->doNotify(p, QSanProtocol::S_COMMAND_LOG_SKILL, log.toVariant());

    if (choice.contains("handcards")) {
        QList<int> blacks;
        foreach (int card_id, effect.to->handCards()) {
            if (Sanguosha->getCard(card_id)->isBlack())
                blacks << card_id;
        }
        int to_discard = room->doGongxin(effect.from, effect.to, blacks);
        if (to_discard == -1) return;

        effect.from->tag.remove("shangyi");
        CardMoveReason reason = CardMoveReason(CardMoveReason::S_REASON_DISMANTLE, effect.from->objectName(), effect.to->objectName(), "shangyi", NULL);
        room->throwCard(Sanguosha->getCard(to_discard), reason, effect.to, effect.from);
    } else {
        QStringList list, list2;
        if (!effect.to->hasShownGeneral1()) {
            list << "head_general";
            list2 << effect.to->getActualGeneral1Name();
        }
        if (!effect.to->hasShownGeneral2()) {
            list << "deputy_general";
            list2 << effect.to->getActualGeneral2Name();
        }
        foreach (const QString &name, list) {
            LogMessage log;
            log.type = "$KnownBothViewGeneral";
            log.from = effect.from;
            log.to << effect.to;
            log.arg = Sanguosha->translate(name);
            log.arg2 = (name == "head_general" ? effect.to->getActualGeneral1Name() : effect.to->getActualGeneral2Name());
            room->doNotify(effect.from, QSanProtocol::S_COMMAND_LOG_SKILL, log.toVariant());
        }
        JsonArray arg;
        arg << "shangyi";
        arg << JsonUtils::toJsonArray(list2);
        room->doNotify(effect.from, QSanProtocol::S_COMMAND_VIEW_GENERALS, arg);
    }
}

class Shangyi : public ZeroCardViewAsSkill
{
public:
    Shangyi() : ZeroCardViewAsSkill("shangyi")
    {
    }

    virtual bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("ShangyiCard") && !player->isKongcheng();
    }

    virtual const Card *viewAs() const
    {
        ShangyiCard *c = new ShangyiCard;
        c->setShowSkill(objectName());
        return c;
    }
};

NiaoxiangSummon::NiaoxiangSummon()
    : ArraySummonCard("niaoxiang")
{
}

class Niaoxiang : public BattleArraySkill
{
public:
    Niaoxiang() : BattleArraySkill("niaoxiang", HegemonyMode::Siege)
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
                    if (player->inSiegeRelation(skill_owner, to))
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
            room->sendCompulsoryTriggerLog(ask_who, objectName(), true);
            room->broadcastSkillInvoke(objectName(), ask_who);
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent, Room *, ServerPlayer *skill_target, QVariant &data, ServerPlayer *) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        int x = use.to.indexOf(skill_target);
        QVariantList jink_list = use.from->tag["Jink_" + use.card->toString()].toList();
        if (jink_list.at(x).toInt() == 1)
            jink_list[x] = 2;
        use.from->tag["Jink_" + use.card->toString()] = jink_list;

        return false;
    }
};

class Yicheng : public TriggerSkill
{
public:
    Yicheng() : TriggerSkill("yicheng")
    {
        events << TargetConfirmed << TargetChosen;
        frequency = Frequent;
    }

    virtual QStringList triggerable(TriggerEvent triggerEvent, Room *, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
    {
        if (!TriggerSkill::triggerable(player)) return QStringList();
        CardUseStruct use = data.value<CardUseStruct>();
        bool invoke = triggerEvent == TargetChosen;
        if (!invoke)
            invoke = (use.to.contains(player));

        if (invoke) {
            if (use.card->isKindOf("Slash"))
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
        player->drawCards(1);
        room->askForDiscard(player, objectName(), 1, 1, false, true);
        return false;
    }
};

class YichengFormation : public TriggerSkill
{
public:
    YichengFormation() : TriggerSkill("#yicheng-formation")
    {
        events << TargetConfirmed << TargetChosen;
        frequency = Compulsory;
    }

    virtual TriggerList triggerable(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        TriggerList skill_list;
        CardUseStruct use = data.value<CardUseStruct>();
        if (!use.card->isKindOf("Slash")) return skill_list;
        bool invoke = triggerEvent == TargetChosen;
        if (!invoke)
            invoke = (use.to.contains(player));

        if (invoke) {
            QList<ServerPlayer *> xushengs = room->findPlayersBySkillName("yicheng");
            foreach (ServerPlayer *xusheng, xushengs) {
                if (player->inFormationRalation(xusheng) && xusheng->hasShownSkill("yicheng") && xusheng != player)
                    skill_list.insert(xusheng, QStringList(objectName()));
            }
        }
        return skill_list;
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const
    {
        if (room->askForChoice(player, "yicheng", "yes+no", data, "@yicheng:" + ask_who->objectName()) == "yes") {
            LogMessage log;
            log.type = "#InvokeOthersSkill";
            log.from = player;
            log.to << ask_who;
            log.arg = "yicheng";
            room->sendLog(log);
            room->broadcastSkillInvoke("yicheng", ask_who);
            room->notifySkillInvoked(ask_who, "yicheng");

            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        player->drawCards(1, "yicheng");
        room->askForDiscard(player, "yicheng", 1, 1, false, true);
        return false;
    }
};

QianhuanCard::QianhuanCard()
{
    target_fixed = true;
    will_throw = false;
    handling_method = Card::MethodNone;
}

void QianhuanCard::use(Room *room, ServerPlayer *, QList<ServerPlayer *> &) const
{
    CardMoveReason reason(CardMoveReason::S_REASON_REMOVE_FROM_PILE, QString(), "qianhuan", QString());
    room->throwCard(Sanguosha->getCard(subcards.first()), reason, NULL);
}

class QianhuanVS : public OneCardViewAsSkill
{
public:
    QianhuanVS() : OneCardViewAsSkill("qianhuan")
    {
        filter_pattern = ".|.|.|sorcery";
        response_pattern = "@@qianhuan";
        expand_pile = "sorcery";
    }

    virtual const Card *viewAs(const Card *originalCard) const
    {
        QianhuanCard *c = new QianhuanCard;
        c->addSubcard(originalCard);
        return c;
    }
};

class Qianhuan : public TriggerSkill
{
public:
    Qianhuan() : TriggerSkill("qianhuan")
    {
        events << Damaged << TargetConfirming << BeforeCardsMove;
        view_as_skill = new QianhuanVS;
    }

    virtual bool canPreshow() const
    {
        return true;
    }

    virtual TriggerList triggerable(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        TriggerList skill_list;
        if (player == NULL) return skill_list;
        QList<ServerPlayer *> yujis = room->findPlayersBySkillName(objectName());
        if (triggerEvent == Damaged && player->isAlive()) {
            foreach (ServerPlayer *yuji, yujis) {
                if (yuji->isFriendWith(player) && !yuji->isNude() && yuji->getPile("sorcery").length() < 4)
                    skill_list.insert(yuji, QStringList(objectName()));
            }
        } else if (triggerEvent == TargetConfirming) {
            CardUseStruct use = data.value<CardUseStruct>();
            if (!use.card || !(use.card->getTypeId() == Card::TypeBasic
                || use.card->isNDTrick()) || !use.to.contains(player))
                return skill_list;
            if (use.to.length() != 1) return skill_list;
            foreach (ServerPlayer *yuji, yujis) {
                if (yuji->getPile("sorcery").isEmpty()) continue;
                if (yuji->isFriendWith(use.to.first()))
                    skill_list.insert(yuji, QStringList(objectName()));
            }
        } else if (triggerEvent == BeforeCardsMove && TriggerSkill::triggerable(player) && !player->getPile("sorcery").isEmpty()) {

            QVariantList move_datas = data.toList();
            if (move_datas.size() != 1) return skill_list;
            QVariant move_data = move_datas.first();

            CardsMoveOneTimeStruct move = move_data.value<CardsMoveOneTimeStruct>();
            if (move.to && move.to_place == Player::PlaceDelayedTrick && player->isFriendWith(move.to)) {
                skill_list.insert(player, QStringList(objectName()));
            }

        }
        return skill_list;
    }

    virtual bool cost(TriggerEvent triggerEvent, Room *room, ServerPlayer *, QVariant &data, ServerPlayer *ask_who) const
    {
        ServerPlayer *yuji = ask_who;
        if (yuji == NULL)
            return false;
        yuji->tag["qianhuan_data"] = data;

        bool invoke = false;

        if (triggerEvent == Damaged) {
            QStringList suits;
            suits << "heart" << "diamond" << "spade" << "club";
            foreach (int card_id, yuji->getPile("sorcery"))
                suits.removeOne(Sanguosha->getCard(card_id)->getSuitString());
            if (suits.isEmpty()) return false;
            const Card *to_put = room->askForCard(yuji, ".|" + suits.join(",") + "|.|.", "@qianhuan-put", data, Card::MethodNone);
            if (to_put) {
                invoke = true;
                LogMessage log;
                log.type = "#InvokeSkill";
                log.from = yuji;
                log.arg = objectName();
                room->sendLog(log);
                room->notifySkillInvoked(yuji, objectName());
                room->broadcastSkillInvoke(objectName(), yuji);
                yuji->addToPile("sorcery", to_put->getEffectiveId());
            }
        } else if (triggerEvent == TargetConfirming) {
            QString prompt;
            QStringList prompt_list;
            prompt_list << "@qianhuan-cancel";
            CardUseStruct use = data.value<CardUseStruct>();
            prompt_list << "";
            prompt_list << use.to.first()->objectName();
            prompt_list << use.card->objectName();
            prompt = prompt_list.join(":");
            if (room->askForUseCard(yuji, "@@qianhuan", prompt, -1, Card::MethodNone)) {
                room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, yuji->objectName(), use.to.first()->objectName());
                invoke = true;
            }
        } else if (triggerEvent == BeforeCardsMove) {
            QString player_name, card_name;

            QVariantList move_datas = data.toList();
            if (move_datas.size() != 1) return false;
            QVariant move_data = move_datas.first();

            CardsMoveOneTimeStruct move = move_data.value<CardsMoveOneTimeStruct>();
            if (move.to && !move.card_ids.isEmpty()) {
                player_name = move.to->objectName();
                card_name = Sanguosha->getCard(move.card_ids.first())->objectName();

            }

            QString prompt;
            QStringList prompt_list;
            prompt_list << "@qianhuan-cancel";

            prompt_list << "";
            prompt_list << player_name;
            prompt_list << card_name;
            prompt = prompt_list.join(":");
            if (room->askForUseCard(yuji, "@@qianhuan", prompt, -1, Card::MethodNone)) {
                room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, yuji->objectName(), player_name);
                invoke = true;
            }
        }

        yuji->tag.remove("qianhuan_data");

        return invoke;
    }

    virtual bool effect(TriggerEvent triggerEvent, Room *room, ServerPlayer *, QVariant &data, ServerPlayer *) const
    {

        if (triggerEvent == TargetConfirming) {
            CardUseStruct use = data.value<CardUseStruct>();
            room->cancelTarget(use, use.to.first()); // Room::cancelTarget(use, player);
            data = QVariant::fromValue(use);
        } else if (triggerEvent == BeforeCardsMove) {

            QVariantList move_datas = data.toList();
            if (move_datas.size() != 1) return false;

            QVariant move_data = move_datas.first();
            CardsMoveOneTimeStruct move = move_data.value<CardsMoveOneTimeStruct>();
            move.to = NULL;
            move.to_place = Player::DiscardPile;
            move.reason = CardMoveReason(CardMoveReason::S_REASON_NATURAL_ENTER, QString());

            move_data = QVariant::fromValue(move);
            QVariantList new_datas;
            new_datas << move_data;
            data = QVariant::fromValue(new_datas);

            return false;
        }

        return false;
    }
};

class Zhendu : public TriggerSkill
{
public:
    Zhendu() : TriggerSkill("zhendu")
    {
        events << EventPhaseStart;
    }

    virtual TriggerList triggerable(TriggerEvent, Room *room, ServerPlayer *player, QVariant &) const
    {
        TriggerList skill_list;
        if (player == NULL || player->isDead() || player->getPhase() != Player::Play) return skill_list;
        QList<ServerPlayer *> hetaihous = room->findPlayersBySkillName(objectName());
        foreach (ServerPlayer *hetaihou, hetaihous) {
            if (!hetaihou->isKongcheng() && hetaihou != player)
                skill_list.insert(hetaihou, QStringList(objectName()));
        }
        return skill_list;
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *ask_who) const
    {
        ServerPlayer *hetaihou = ask_who;
        if (hetaihou && room->askForDiscard(hetaihou, objectName(), 1, 1, true, false, "@zhendu-discard", true)) {
            room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, hetaihou->objectName(), player->objectName());
            room->broadcastSkillInvoke(objectName(), hetaihou);
            return true;
        }

        return false;
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *ask_who) const
    {
        ServerPlayer *hetaihou = ask_who;

        if (!hetaihou) return false;

        Analeptic *analeptic = new Analeptic(Card::NoSuit, 0);
        analeptic->setSkillName("_zhendu");
        if (player->isAlive() && analeptic->isAvailable(player) && room->useCard(CardUseStruct(analeptic, player, QList<ServerPlayer *>(), true))) {
            if (player->isAlive())
                room->damage(DamageStruct(objectName(), hetaihou, player));
        } else
            analeptic->deleteLater();

        return false;
    }

    virtual int getEffectIndex(const ServerPlayer *, const Card *c) const
    {
        if (c->isKindOf("Analeptic"))
            return 0;
        return -1;
    }
};

class Qiluan : public TriggerSkill
{
public:
    Qiluan() : TriggerSkill("qiluan")
    {
        events << EventPhaseChanging;
        frequency = Frequent;
    }

    virtual TriggerList triggerable(TriggerEvent , Room *room, ServerPlayer *, QVariant &data) const
    {
        TriggerList skill_list;

        if (data.value<PhaseChangeStruct>().to == Player::NotActive) {
            foreach (ServerPlayer *p, room->getAllPlayers()) {
                if (p->getMark("GlobalKilledCount") > 0 && TriggerSkill::triggerable(p)) {
                    skill_list.insert(p, QStringList(objectName()));
                }
            }
        }
        return skill_list;
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *, QVariant &, ServerPlayer *hetaihou) const
    {
        if (hetaihou && hetaihou->askForSkillInvoke(this)) {
            room->broadcastSkillInvoke(objectName(), hetaihou);
            return true;
        }

        return false;
    }

    virtual bool effect(TriggerEvent, Room *, ServerPlayer *, QVariant &, ServerPlayer *hetaihou) const
    {
        if (hetaihou)
            hetaihou->drawCards(3);
        return false;
    }
};

class Zhangwu : public TriggerSkill
{
public:
    Zhangwu() : TriggerSkill("zhangwu")
    {
        events << CardsMoveOneTime << BeforeCardsMove;
        frequency = Compulsory;
    }

    virtual QStringList triggerable(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        if (!TriggerSkill::triggerable(player)) return QStringList();

        QVariantList move_datas = data.toList();

        foreach (QVariant move_data, move_datas) {
            CardsMoveOneTimeStruct move = move_data.value<CardsMoveOneTimeStruct>();
            foreach (int id, move.card_ids) {
                if (Sanguosha->getCard(id)->isKindOf("DragonPhoenix")) {
                    if (triggerEvent == CardsMoveOneTime) {
                        if ((move.to_place == Player::DiscardPile || (move.to_place == Player::PlaceEquip && move.to != player))
                                && room->getCardPlace(id) == move.to_place)
                            return QStringList(objectName());
                    }
                    if (triggerEvent == BeforeCardsMove) {
                        if ((move.reason.m_reason & CardMoveReason::S_MASK_BASIC_REASON) == CardMoveReason::S_REASON_USE && move.reason.m_skillName.isEmpty()) return QStringList();
                        if ((move.from == player && (move.from_places[move.card_ids.indexOf(id)] == Player::PlaceHand || move.from_places[move.card_ids.indexOf(id)] == Player::PlaceEquip))
                            && (move.to != player || (move.to_place != Player::PlaceHand && move.to_place != Player::PlaceEquip)))
                            return QStringList(objectName());
                    }

                    return QStringList();
                }
            }
        }

        return QStringList();
    }

    virtual bool cost(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        bool invoke = player->hasShownSkill(this) ? true : player->askForSkillInvoke(this);
        if (invoke) {
            room->sendCompulsoryTriggerLog(player, objectName());
            room->broadcastSkillInvoke(objectName(), (triggerEvent == BeforeCardsMove) ? 1 : 2, player);
            return true;
        }

        return false;
    }

    virtual bool effect(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        QVariantList move_datas = data.toList();

        foreach (QVariant move_data, move_datas) {
            CardsMoveOneTimeStruct move = move_data.value<CardsMoveOneTimeStruct>();
            foreach (int id, move.card_ids) {
                const Card *card = Sanguosha->getCard(id);
                if (card->isKindOf("DragonPhoenix")) {

                    if (triggerEvent == CardsMoveOneTime) {
                        player->obtainCard(card);
                    } else {
                        room->showCard(player, id);

                        CardMoveReason reason(CardMoveReason::S_REASON_PUT, player->objectName(), objectName(), QString());
                        CardsMoveStruct move2(id, NULL, Player::DrawPileBottom, reason);
                        move2.open = true;

                        data = room->changeMoveData(data, move2);

                    }
                    return false;

                }
            }
        }

        return false;
    }
};

class Zhangwu_Draw : public TriggerSkill
{
public:
    Zhangwu_Draw() : TriggerSkill("#zhangwu-draw")
    {
        frequency = Compulsory;
        events << CardsMoveOneTime;
    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
    {
        QVariantList move_datas = data.toList();

        foreach (QVariant move_data, move_datas) {
            CardsMoveOneTimeStruct move = move_data.value<CardsMoveOneTimeStruct>();

            if (player != NULL && player->isAlive() && player == move.from
                    && move.to_place == Player::DrawPileBottom && move.reason.m_skillName == "zhangwu") {
                foreach (int id, move.card_ids) {
                    if (Sanguosha->getCard(id)->isKindOf("DragonPhoenix")) {
                        return QStringList(objectName());
                    }
                }
            }
        }

        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *, ServerPlayer *, QVariant &, ServerPlayer *) const
    {
        return true;
    }

    virtual bool effect(TriggerEvent, Room *, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        player->drawCards(2, "zhangwu");
        return false;
    }
};

class Shouyue : public TriggerSkill
{
public:
    Shouyue() : TriggerSkill("shouyue$")
    {
        frequency = Compulsory;
        events << GeneralShown;
    }

    virtual bool canPreshow() const
    {
        return false;
    }

    virtual void record(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (player && player->isAlive() && player->hasLordSkill(objectName()) && data.toBool() == player->inHeadSkills(objectName())) {
            room->sendCompulsoryTriggerLog(player, objectName());
            room->broadcastSkillInvoke(objectName(), player);
        }
    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *, QVariant &, ServerPlayer * &) const
    {
        return QStringList();
    }
};

class Jizhao : public TriggerSkill
{
public:
    Jizhao() : TriggerSkill("jizhao")
    {
        events << AskForPeaches;
        frequency = Limited;
        limit_mark = "@jizhao";
    }

    virtual bool canPreshow() const
    {
        return false;
    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        if (!TriggerSkill::triggerable(player))
            return QStringList();

        if (player->getMark("@jizhao") == 0 || player->getHp() > 0)
            return QStringList();

        DyingStruct dying = data.value<DyingStruct>();
        if (dying.who != player)
            return QStringList();

        return QStringList(objectName());
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (player->askForSkillInvoke(this, data)) {
            player->broadcastSkillInvoke(objectName());
            room->doSuperLightbox("lord_liubei", objectName());
            room->setPlayerMark(player, limit_mark, 0);
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        if (player->getHandcardNum() < player->getMaxHp())
            room->drawCards(player, player->getMaxHp() - player->getHandcardNum());

        if (player->getHp() < 2) {
            RecoverStruct rec;
            rec.recover = 2 - player->getHp();
            rec.who = player;
            room->recover(player, rec);
        }

        room->handleAcquireDetachSkills(player, "-shouyue|rende");
        return false; //return player->getHp() > 0 || player->isDead();
    }
};


FormationPackage::FormationPackage()
    : Package("formation")
{
    General *dengai = new General(this, "dengai", "wei"); // WEI 015
    dengai->addSkill(new Tuntian);
    dengai->addSkill(new TuntianDistance);
    dengai->addSkill(new DetachEffectSkill("tuntian", "field"));
    dengai->addSkill(new Jixi);
    dengai->setHeadMaxHpAdjustedValue(-1);
    dengai->addSkill(new Ziliang);
    insertRelatedSkills("tuntian", 2, "#tuntian-dist", "#tuntian-clear");

    General *caohong = new General(this, "caohong", "wei"); // WEI 018
    caohong->addCompanion("caoren");
    caohong->addSkill(new Huyuan);
    caohong->addSkill(new Heyi);
    caohong->addRelateSkill("feiying");

    General *jiangwei = new General(this, "jiangwei", "shu"); // SHU 012 G
    jiangwei->addSkill(new Tiaoxin);
    jiangwei->addSkill(new Yizhi);
    jiangwei->setDeputyMaxHpAdjustedValue(-1);
    jiangwei->addSkill(new Tianfu);
    jiangwei->addRelateSkill("guanxing_jiangwei");
    jiangwei->addRelateSkill("kanpo");

    General *jiangwanfeiyi = new General(this, "jiangwanfeiyi", "shu", 3); // SHU 018
    jiangwanfeiyi->addSkill(new Shengxi);
    jiangwanfeiyi->addSkill(new Shoucheng);

    General *jiangqin = new General(this, "jiangqin", "wu"); // WU 017
    jiangqin->addCompanion("zhoutai");
    jiangqin->addSkill(new Shangyi);
    jiangqin->addSkill(new Niaoxiang);

    General *xusheng = new General(this, "xusheng", "wu"); // WU 020
    xusheng->addCompanion("dingfeng");
    xusheng->addSkill(new Yicheng);
    xusheng->addSkill(new YichengFormation);
    insertRelatedSkills("yicheng", "#yicheng-formation");

    General *yuji = new General(this, "yuji", "qun", 3); // QUN 011 G
    yuji->addSkill(new Qianhuan);
    yuji->addSkill(new DetachEffectSkill("qianhuan", "sorcery"));
    insertRelatedSkills("qianhuan", "#qianhuan-clear");

    General *hetaihou = new General(this, "hetaihou", "qun", 3, false); // QUN 020
    hetaihou->addSkill(new Zhendu);
    hetaihou->addSkill(new Qiluan);

    General *liubei = new General(this, "lord_liubei$", "shu", 4, true, true);
    liubei->addSkill(new Zhangwu);
    liubei->addSkill(new Zhangwu_Draw);
    insertRelatedSkills("zhangwu", "#zhangwu-draw");
    liubei->addSkill(new Shouyue);
    liubei->addSkill(new Jizhao);
    liubei->addRelateSkill("rende");

    addMetaObject<HuyuanCard>();
    addMetaObject<ZiliangCard>();
    addMetaObject<TiaoxinCard>();
    addMetaObject<ShangyiCard>();
    addMetaObject<HeyiSummon>();
    addMetaObject<TianfuSummon>();
    addMetaObject<NiaoxiangSummon>();
    addMetaObject<QianhuanCard>();

    skills << new Feiying << new FeiyingVH << new GuanxingJiangwei;
}

ADD_PACKAGE(Formation)


DragonPhoenix::DragonPhoenix(Suit suit, int number) : Weapon(suit, number, 2)
{
    setObjectName("DragonPhoenix");
}

class DragonPhoenixSkill : public WeaponSkill
{
public:
    DragonPhoenixSkill() : WeaponSkill("DragonPhoenix")
    {
        events << TargetChosen << Dying;
    }

    virtual QStringList triggerable(TriggerEvent triggerEvent, Room *, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
    {
        if (!WeaponSkill::triggerable(player)) return QStringList();
        if (triggerEvent == TargetChosen) {
            CardUseStruct use = data.value<CardUseStruct>();
            if (use.card != NULL && use.card->isKindOf("Slash")) {
                QStringList targets;
                foreach (ServerPlayer *to, use.to) {
                    if (!to->isNude())
                        targets << to->objectName();
                }
                if (!targets.isEmpty())
                    return QStringList(objectName() + "->" + targets.join("+"));
            }
        } else if (triggerEvent == Dying) {
            DyingStruct dying = data.value<DyingStruct>();
            ServerPlayer *target = dying.who;
            if (dying.damage && dying.damage->from == player && dying.damage->card && dying.damage->card->isKindOf("Slash")
                    && !dying.damage->chain && !dying.damage->transfer) {
                if (player->canGetCard(target, "h"))
                    return QStringList(objectName() + "->" + target->objectName());
            }
        }

        return QStringList();
    }

    virtual bool cost(TriggerEvent , Room *room, ServerPlayer *player, QVariant &, ServerPlayer *ask_who) const
    {
        if (ask_who->askForSkillInvoke(this, QVariant::fromValue(player))) {
            room->setEmotion(ask_who, "weapon/dragonphoenix");
            room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, ask_who->objectName(), player->objectName());
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *ask_who) const
    {
        if (triggerEvent == TargetChosen)
            room->askForDiscard(player, objectName(), 1, 1, false, true, "@dragonphoenix-discard");
        else if (triggerEvent == Dying) {
            int card_id = room->askForCardChosen(ask_who, player, "h", objectName(), false, Card::MethodGet);
            CardMoveReason reason(CardMoveReason::S_REASON_EXTRACTION, ask_who->objectName());
            room->obtainCard(ask_who, Sanguosha->getCard(card_id), reason, false);
        }
        return false;
    }
};

//class DragonPhoenixSkill2 : public WeaponSkill
//{
//public:
//    DragonPhoenixSkill2() : WeaponSkill("#DragonPhoenix")
//    {
//        events << BuryVictim;
//    }

//    virtual int getPriority() const
//    {
//        return -4;
//    }

//    virtual bool triggerable(const ServerPlayer *target) const
//    {
//        return target != NULL;
//    }

//    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
//    {
//        if (!room->getMode().endsWith('p')) return false;

//        DeathStruct death = data.value<DeathStruct>();
//        DamageStruct *damage = death.damage;
//        if (!damage || !damage->card || !damage->card->isKindOf("Slash")) return false;
//        ServerPlayer *dfowner = damage->from;

//        if (!dfowner || !dfowner->hasWeapon("DragonPhoenix") || dfowner->getRole() == "careerist" || !dfowner->hasShownOneGeneral()) return false;

//        if (!room->getLord(dfowner->getKingdom()) && !(dfowner->getPlayerNumWithKingdom(true) < room->getPlayers().length() / 2)) return false;

//        int num = dfowner->getPlayerNumWithKingdom();

//        foreach (ServerPlayer *p, room->getAlivePlayers()) {
//            if (p->hasShownOneGeneral() && !dfowner->isFriendWith(p) && p->getPlayerNumWithKingdom() <= num) {
//                return false;
//            }
//        }

//        QStringList generals = Sanguosha->getLimitedGeneralNames(true);
//        foreach (QString name, room->getUsedGeneral())
//            if (generals.contains(name)) generals.removeAll(name);

//        QStringList avaliable_generals;

//        foreach (const QString &general, generals) {
//            if (Sanguosha->getGeneral(general)->getKingdom() != dfowner->getKingdom())
//                continue;

//            bool continue_flag = false;
//            foreach (ServerPlayer *p, room->getAlivePlayers()) {
//                QStringList generals_of_player = room->getTag(p->objectName()).toStringList();
//                if (generals_of_player.contains(general)) {
//                    continue_flag = true;
//                    break;
//                }
//            }

//            if (continue_flag)
//                continue;

//            avaliable_generals << general;
//        }

//        if (avaliable_generals.isEmpty()) return false;

//        bool invoke = room->askForSkillInvoke(dfowner, "DragonPhoenix", data) &&
//                (room->askForChoice(player, "DragonPhoenix_revive", "yes+no", data, "@DragonPhoenix-choose:" + dfowner->objectName()) == "yes");
//        if (invoke) {
//            room->setEmotion(dfowner, "weapon/dragonphoenix");
//            room->setPlayerProperty(player, "Duanchang", QVariant());
//            QString to_change = room->askForGeneral(player, avaliable_generals, QString(), true, "DragonPhoenix", dfowner->getKingdom());

//            if (!to_change.isEmpty()) {
//                room->doDragonPhoenix(player, to_change, QString(), false, dfowner->getKingdom(), true, "h");
//                room->setPlayerProperty(player, "hp", 2);

//                player->setChained(false);
//                room->broadcastProperty(player, "chained");

//                player->setFaceUp(true);
//                room->broadcastProperty(player, "faceup");

//                player->drawCards(1, "revive");
//            }
//        }
//        return false;
//    }
//};


FormationEquipPackage::FormationEquipPackage() : Package("formation_equip", CardPack)
{
    DragonPhoenix *dp = new DragonPhoenix();
    dp->setParent(this);

    skills << new DragonPhoenixSkill;
    //insertRelatedSkills("DragonPhoenix", "#DragonPhoenix");
}

ADD_PACKAGE(FormationEquip)


