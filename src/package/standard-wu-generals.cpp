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

#include "standard-wu-generals.h"
#include "engine.h"
#include "standard-basics.h"
#include "standard-tricks.h"
#include "client.h"
#include "settings.h"
#include "json.h"
#include "roomthread.h"

ZhihengCard::ZhihengCard()
{
    target_fixed = true;
    mute = true;
}


void ZhihengCard::onUse(Room *room, const CardUseStruct &card_use) const
{
    ServerPlayer *source = card_use.from;
    if (!show_skill.isEmpty() && !(source->inHeadSkills(show_skill) ? source->hasShownGeneral1() : source->hasShownGeneral2()))
        source->showGeneral(source->inHeadSkills(this->show_skill));

    if (!show_skill.isEmpty()) room->broadcastSkillInvoke("zhiheng", source);
    SkillCard::onUse(room, card_use);
}

void ZhihengCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const
{
    if (source->isAlive())
        room->drawCards(source, subcards.length());
}

class Zhiheng : public ViewAsSkill
{
public:
    Zhiheng() : ViewAsSkill("zhiheng")
    {
    }

    virtual bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const
    {
        if (selected.length() >= Self->getMaxHp())
            return !Self->isJilei(to_select) && Self->getTreasure() && Self->getTreasure()->isKindOf("LuminousPearl")
                    && to_select != Self->getTreasure() && !selected.contains(Self->getTreasure());

        return !Self->isJilei(to_select) && selected.length() < Self->getMaxHp();
    }

    virtual const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (cards.isEmpty())
            return NULL;

        ZhihengCard *zhiheng_card = new ZhihengCard;
        zhiheng_card->addSubcards(cards);
        zhiheng_card->setSkillName(objectName());
        zhiheng_card->setShowSkill(objectName());
        return zhiheng_card;
    }

    virtual bool isEnabledAtPlay(const Player *player) const
    {
        return player->canDiscard(player, "he") && !player->hasUsed("ZhihengCard");
    }
};

class Qixi : public OneCardViewAsSkill
{
public:
    Qixi() : OneCardViewAsSkill("qixi")
    {
        response_or_use = true;
    }

    virtual bool viewFilter(const Card *to_select) const
    {
        return to_select->isBlack();
    }

    virtual const Card *viewAs(const Card *originalCard) const
    {
        Dismantlement *dismantlement = new Dismantlement(originalCard->getSuit(), originalCard->getNumber());
        dismantlement->addSubcard(originalCard->getId());
        dismantlement->setSkillName(objectName());
        dismantlement->setShowSkill(objectName());
        return dismantlement;
    }
};

class Keji : public TriggerSkill
{
public:
    Keji() : TriggerSkill("keji")
    {
        events << EventPhaseStart;
        frequency = Compulsory;
    }

    virtual QStringList triggerable(TriggerEvent , Room *, ServerPlayer *player, QVariant &, ServerPlayer * &) const
    {
        if (TriggerSkill::triggerable(player) && player->getPhase() == Player::Discard) {
            QVariantList card_list = player->tag["PhaseUsedCards"].toList();

            Card::Color color = Card::Colorless;
            bool usedcard = false;

            foreach (QVariant card_data, card_list) {
                const Card *card = card_data.value<const Card *>();
                if (card) {
                    if (!usedcard) {
                        usedcard = true;
                        color = card->getColor();
                    } else if (color != card->getColor())
                        return QStringList();
                }
            }
            return QStringList(objectName());
        }
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

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *lvmeng, QVariant &, ServerPlayer *) const
    {
        room->addPlayerMark(lvmeng, "Global_MaxcardsIncrease", 4);
        return false;
    }
};

class Mouduan : public PhaseChangeSkill
{
public:
    Mouduan() : PhaseChangeSkill("mouduan")
    {

    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *player, QVariant &, ServerPlayer* &) const
    {
        if (PhaseChangeSkill::triggerable(player) && player->getPhase() == Player::Finish) {
            QString type_name[4] = { QString(), "BasicCard", "TrickCard", "EquipCard" };
            QStringList types;
            types << "BasicCard" << "TrickCard" << "EquipCard";
            QStringList suits;
            suits << "heart" << "diamond" << "spade" << "club";

            QVariantList card_list = player->tag["PhaseUsedCards"].toList();
            foreach (QVariant card_data, card_list) {
                const Card *card = card_data.value<const Card *>();
                if (card) {
                    suits.removeOne(card->getSuitString());
                    types.removeOne(type_name[card->getTypeId()]);
                }
            }
            if (suits.isEmpty() || types.isEmpty())
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

    virtual bool onPhaseChange(ServerPlayer *lvmeng) const
    {
        Room *room = lvmeng->getRoom();
        room->askForQiaobian(lvmeng, room->getAlivePlayers(), "mouduan", "@mouduan-move", true, true);
        return false;
    }
};

KurouCard::KurouCard()
{
    target_fixed = true;
}

void KurouCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const
{
    room->loseHp(source);
    room->drawCards(source, 3);
    room->setPlayerFlag(source, "kurouInvoked");
}

class Kurou : public OneCardViewAsSkill
{
public:
    Kurou() : OneCardViewAsSkill("kurou")
    {
        filter_pattern = ".!";
    }

    virtual bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("KurouCard");
    }

    virtual const Card *viewAs(const Card *originalCard) const
    {
        KurouCard *card = new KurouCard;
        card->addSubcard(originalCard);
        card->setSkillName(objectName());
        card->setShowSkill(objectName());
        return card;
    }
};

class KurouTargetMod : public TargetModSkill
{
public:
    KurouTargetMod() : TargetModSkill("#kurou-target")
    {
    }

    virtual int getResidueNum(const Player *from, const Card *card, const Player *) const
    {
        if (!Sanguosha->matchExpPattern(pattern, from, card))
            return 0;

        if (from->hasFlag("kurouInvoked"))
            return 1;
        else
            return 0;
    }
};

Yingzi::Yingzi(const QString &owner, bool can_preshow) : DrawCardsSkill("yingzi_" + owner), m_canPreshow(can_preshow)
{
    frequency = Compulsory;
}

bool Yingzi::canPreshow() const
{
    return m_canPreshow;
}

bool Yingzi::cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
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

int Yingzi::getDrawNum(ServerPlayer *, int n) const
{
    return n + 1;
}

class YingziMaxCards : public MaxCardsSkill
{
public:
    YingziMaxCards() : MaxCardsSkill("#yingzi-maxcards")
    {
    }

    virtual int getFixed(const Player *target) const
    {
        if (target->hasShownSkills("yingzi_zhouyu|yingzi_sunce|yingzi_flamemap"))
            return target->getMaxHp();
        else
            return -1;
    }
};

FanjianCard::FanjianCard()
{
    will_throw = false;
    handling_method = Card::MethodNone;
}

void FanjianCard::extraCost(Room *room, const CardUseStruct &card_use) const
{
    Card::Suit suit = getSuit();
    ServerPlayer *target = card_use.to.first();
    target->setMark("FanjianSuit", int(suit));
    CardMoveReason reason(CardMoveReason::S_REASON_GIVE, card_use.from->objectName(), target->objectName(), "rende", QString());
    room->obtainCard(target, this, reason);
}

void FanjianCard::onEffect(const CardEffectStruct &effect) const
{
    ServerPlayer *target = effect.to;
    Room *room = target->getRoom();
    if (target->isAlive()) {
        Card::Suit suit = (Card::Suit) target->getMark("FanjianSuit");

        bool no_choose = target->isKongcheng();
        foreach (const Card *card, target->getEquips()) {
            if (card->getSuit() == suit)
                no_choose = false;
        }

        if (no_choose || !room->askForSkillInvoke(target, "fanjian_show", "prompt:::" + Card::Suit2String(suit)))
            room->loseHp(target);
        else {
            if (!target->isKongcheng()) {
                room->showAllCards(target);
                room->getThread()->delay(3000);
            }
            DummyCard *dummy = new DummyCard;
            foreach (const Card *card, target->getCards("he")) {
                if (card->getSuit() == suit)
                    dummy->addSubcard(card);
            }
            if (dummy->subcardsLength() > 0)
                room->throwCard(dummy, target);
            delete dummy;
        }
    }
}

class Fanjian : public OneCardViewAsSkill
{
public:
    Fanjian() : OneCardViewAsSkill("fanjian")
    {
        filter_pattern = ".|.|.|hand";
    }

    virtual bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("FanjianCard");
    }

    virtual const Card *viewAs(const Card *originalCard) const
    {
        FanjianCard *fj = new FanjianCard;
        fj->addSubcard(originalCard);
        fj->setSkillName(objectName());
        fj->setShowSkill(objectName());
        return fj;
    }
};

class Guose : public OneCardViewAsSkill
{
public:
    Guose() : OneCardViewAsSkill("guose")
    {
        filter_pattern = ".|diamond";
        response_or_use = true;
    }

    virtual const Card *viewAs(const Card *originalCard) const
    {
        Indulgence *indulgence = new Indulgence(originalCard->getSuit(), originalCard->getNumber());
        indulgence->addSubcard(originalCard->getId());
        indulgence->setSkillName(objectName());
        indulgence->setShowSkill(objectName());
        return indulgence;
    }
};

LiuliCard::LiuliCard()
{
    //mute = true;
}

bool LiuliCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    if (!targets.isEmpty())
        return false;

    QStringList available_targets = Self->property("liuli_available_targets").toString().split("+");

    if (!available_targets.contains(to_select->objectName())) return false;

    int card_id = subcards.first();
    int range_fix = 0;
    if (Self->getWeapon() && Self->getWeapon()->getId() == card_id) {
        const Weapon *weapon = qobject_cast<const Weapon *>(Self->getWeapon()->getRealCard());
        range_fix += weapon->getRange() - Self->getAttackRange(false);
    } else if (Self->getOffensiveHorse() && Self->getOffensiveHorse()->getId() == card_id) {
        range_fix += 1;
    } else if (Self->getSpecialHorse() && Self->getSpecialHorse()->getId() == card_id) {
        range_fix += 1;
    }
    int distance = Self->distanceTo(to_select, range_fix);
    if (distance == -1)
        return false;
    return distance <= Self->getAttackRange();
}

void LiuliCard::onEffect(const CardEffectStruct &effect) const
{
    effect.to->setFlags("LiuliTarget");
}

class LiuliViewAsSkill : public OneCardViewAsSkill
{
public:
    LiuliViewAsSkill() : OneCardViewAsSkill("liuli")
    {
        filter_pattern = ".!";
        response_pattern = "@@liuli";
    }

    virtual const Card *viewAs(const Card *originalCard) const
    {
        LiuliCard *liuli_card = new LiuliCard;
        liuli_card->addSubcard(originalCard);
        //liuli_card->setShowSkill(objectName());
        return liuli_card;
    }
};

class Liuli : public TriggerSkill
{
public:
    Liuli() : TriggerSkill("liuli")
    {
        events << TargetConfirming;
        view_as_skill = new LiuliViewAsSkill;
    }

    virtual bool canPreshow() const
    {
        return true;
    }

    virtual QStringList triggerable(TriggerEvent, Room *room, ServerPlayer *daqiao, QVariant &data, ServerPlayer * &) const
    {
        if (!TriggerSkill::triggerable(daqiao)) return QStringList();
        CardUseStruct use = data.value<CardUseStruct>();

        if (use.card->isKindOf("Slash") && use.to.contains(daqiao) && daqiao->canDiscard(daqiao, "he")) {
            QList<ServerPlayer *> players = room->getOtherPlayers(daqiao);
            players.removeOne(use.from);
            bool can_invoke = false;
            foreach (ServerPlayer *p, players) {
                if (use.from->canSlash(p, use.card, false) && daqiao->inMyAttackRange(p) && !use.to.contains(p)) {
                    can_invoke = true;
                    break;
                }
            }
            return can_invoke ? QStringList(objectName()) : QStringList();
        }

        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *daqiao, QVariant &data, ServerPlayer *) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        QStringList available_targets;
        QList<ServerPlayer *> players = room->getOtherPlayers(daqiao);
        players.removeOne(use.from);
        foreach (ServerPlayer *p, players) {
            if (use.from->canSlash(p, use.card, false) && !use.to.contains(p))
                available_targets << p->objectName();
        }
        room->setPlayerProperty(daqiao, "liuli_available_targets", available_targets.join("+"));
        daqiao->tag["liuli-use"] = data;
        const Card *card = room->askForUseCard(daqiao, "@@liuli", "@liuli:" + use.from->objectName(), -1, Card::MethodDiscard);
        room->setPlayerProperty(daqiao, "liuli_available_targets", QVariant());
        daqiao->tag.remove("liuli-use");
        room->setPlayerProperty(daqiao, "liuli", QString());
        if (card != NULL)
            return true;

        return false;
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *daqiao, QVariant &data, ServerPlayer *) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        QList<ServerPlayer *> players = room->getOtherPlayers(daqiao);
        foreach (ServerPlayer *p, players) {
            if (p->hasFlag("LiuliTarget")) {
                p->setFlags("-LiuliTarget");
                use.to.removeOne(daqiao);
                daqiao->slashSettlementFinished(use.card);
                use.to.append(p);
                if (use.card->hasFlag("BladeEffect"))
                    room->setPlayerDisableShow(p, "hd", "Blade");

                room->sortByActionOrder(use.to);
                data = QVariant::fromValue(use);
                room->getThread()->trigger(TargetConfirming, room, p, data);
                return true;
            }
        }

        return false;
    }
};

class Qianxun : public TriggerSkill
{
public:
    Qianxun() : TriggerSkill("qianxun")
    {
        events << TargetConfirming << BeforeCardsMove;
        frequency = Compulsory;
    }

    virtual QStringList triggerable(TriggerEvent triggerEvent, Room *, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
    {
        if (!TriggerSkill::triggerable(player)) return QStringList();
        if (triggerEvent == TargetConfirming) {
            CardUseStruct use = data.value<CardUseStruct>();
            if (use.card && use.card->isKindOf("Snatch") && use.to.contains(player))
                return QStringList(objectName());
        } else if (triggerEvent == BeforeCardsMove) {

            QVariantList move_datas = data.toList();
            if (move_datas.size() != 1) return QStringList();
            QVariant move_data = move_datas.first();

            CardsMoveOneTimeStruct move = move_data.value<CardsMoveOneTimeStruct>();
            if (move.to == player && move.to_place == Player::PlaceDelayedTrick && move.card_ids.size() == 1) {

                if (Sanguosha->getCard(move.card_ids.first())->isKindOf("Indulgence"))
                   return QStringList(objectName());

            }

        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        bool invoke = player->hasShownSkill(this) ? true : player->askForSkillInvoke(this);
        if (invoke) {
            if (player->getTriggerSkills().contains(this)) {
                room->broadcastSkillInvoke(objectName(), player);
            }
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        room->sendCompulsoryTriggerLog(player, objectName());
        if (triggerEvent == TargetConfirming) {
            CardUseStruct use = data.value<CardUseStruct>();
            room->cancelTarget(use, player); // Room::cancelTarget(use, player);
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

class Duoshi : public OneCardViewAsSkill
{
public:
    Duoshi() : OneCardViewAsSkill("duoshi")
    {
        filter_pattern = ".|red|.|hand";
        response_or_use = true;
    }

    virtual bool isEnabledAtPlay(const Player *player) const
    {
        return player->usedTimes("ViewAsSkill_duoshiCard") < 4;
    }

    virtual const Card *viewAs(const Card *originalcard) const
    {
        AwaitExhausted *await = new AwaitExhausted(originalcard->getSuit(), originalcard->getNumber());
        await->addSubcard(originalcard->getId());
        await->setSkillName("duoshi");
        await->setShowSkill(objectName());
        return await;
    }
};

JieyinCard::JieyinCard()
{
}

bool JieyinCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    if (!targets.isEmpty())
        return false;

    return to_select->isMale() && to_select->isWounded() && to_select != Self;
}

void JieyinCard::onEffect(const CardEffectStruct &effect) const
{
    Room *room = effect.from->getRoom();
    RecoverStruct recover;
    recover.card = this;
    recover.who = effect.from;

    QList<ServerPlayer *> targets;
    targets << effect.from << effect.to;
    room->sortByActionOrder(targets);
    foreach(ServerPlayer *target, targets)
        room->recover(target, recover, true);
}

class Jieyin : public ViewAsSkill
{
public:
    Jieyin() : ViewAsSkill("jieyin")
    {
    }

    virtual bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("JieyinCard");
    }

    virtual bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const
    {
        if (selected.length() > 1 || Self->isJilei(to_select))
            return false;

        return !to_select->isEquipped();
    }

    virtual const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (cards.length() != 2)
            return NULL;

        JieyinCard *jieyin_card = new JieyinCard();
        jieyin_card->addSubcards(cards);
        jieyin_card->setShowSkill(objectName());
        return jieyin_card;
    }
};

class Xiaoji : public TriggerSkill
{
public:
    Xiaoji() : TriggerSkill("xiaoji")
    {
        events << CardsMoveOneTime;
        frequency = Frequent;
    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *sunshangxiang, QVariant &data, ServerPlayer * &) const
    {
        if (!TriggerSkill::triggerable(sunshangxiang)) return QStringList();

        QVariantList move_datas = data.toList();
        foreach (QVariant move_data, move_datas) {
            CardsMoveOneTimeStruct move = move_data.value<CardsMoveOneTimeStruct>();
            if (move.from == sunshangxiang && move.from_places.contains(Player::PlaceEquip)) {
                return QStringList(objectName());
            }
        }

        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *sunshangxiang, QVariant &, ServerPlayer *) const
    {
        if (sunshangxiang->askForSkillInvoke(this)) {
            room->broadcastSkillInvoke(objectName(), sunshangxiang);
            return true;
        }

        return false;
    }

    virtual bool effect(TriggerEvent, Room *, ServerPlayer *sunshangxiang, QVariant &, ServerPlayer *) const
    {
        int x = 1;
        if (sunshangxiang->getPhase() == Player::NotActive) x = 3;
        sunshangxiang->drawCards(x, objectName());
        return false;
    }
};

Yinghun::Yinghun(const QString &owner) : PhaseChangeSkill("yinghun_" + owner)
{
}

QStringList Yinghun::triggerable(TriggerEvent, Room *, ServerPlayer *target, QVariant &, ServerPlayer * &) const
{
    return (PhaseChangeSkill::triggerable(target)
        && target->getPhase() == Player::Start) ? QStringList(objectName()) : QStringList();
}

bool Yinghun::cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
{
    ServerPlayer *to = room->askForPlayerChosen(player, room->getOtherPlayers(player), objectName(), "yinghun-invoke", true, true);
    if (to) {
        player->tag["yinghun_target"] = QVariant::fromValue(to);
        return true;
    }
    return false;
}

bool Yinghun::onPhaseChange(ServerPlayer *sunjian) const
{
    Room *room = sunjian->getRoom();
    ServerPlayer *to = sunjian->tag["yinghun_target"].value<ServerPlayer *>();
    if (to) {
        int x = sunjian->getLostHp();

        if (x == 1) {
            room->broadcastSkillInvoke(objectName(), 1, sunjian);

            to->drawCards(1, objectName());
            room->askForDiscard(to, objectName(), 1, 1, false, true);
        } else {
            to->setFlags("YinghunTarget");
            QString choice = room->askForChoice(sunjian, objectName(),
                "d1tx%log:" + QString::number(x) + "+dxt1%log:" + QString::number(x));
            to->setFlags("-YinghunTarget");
            if (choice.contains("d1tx")) {
                room->broadcastSkillInvoke(objectName(), (x>1)?2:1, sunjian);

                to->drawCards(1, objectName());
                if (x > 0)
                    room->askForDiscard(to, objectName(), x, x, false, true);
            } else {
                room->broadcastSkillInvoke(objectName(), (x>1)?1:2, sunjian);

                if (x > 0)
                    to->drawCards(x, objectName());

                room->askForDiscard(to, objectName(), 1, 1, false, true);
            }
        }
    }
    return false;
}

TianxiangCard::TianxiangCard()
{
}

void TianxiangCard::onEffect(const CardEffectStruct &effect) const
{
    QVariantList effect_list = effect.from->tag["tianxiangTag"].toList();
    effect_list << QVariant::fromValue(effect);
    effect.from->tag["tianxiangTag"] = effect_list;
}

class TianxiangViewAsSkill : public OneCardViewAsSkill
{
public:
    TianxiangViewAsSkill() : OneCardViewAsSkill("tianxiang")
    {
        response_pattern = "@@tianxiang";
        filter_pattern = ".|heart|.|hand!";
    }

    virtual const Card *viewAs(const Card *originalCard) const
    {
        TianxiangCard *tianxiangCard = new TianxiangCard;
        tianxiangCard->addSubcard(originalCard);
        //tianxiangCard->setShowSkill(objectName());
        return tianxiangCard;
    }
};

class Tianxiang : public TriggerSkill
{
public:
    Tianxiang() : TriggerSkill("tianxiang")
    {
        events << DamageInflicted;
        view_as_skill = new TianxiangViewAsSkill;
    }

    virtual int getPriority() const
    {
        return -2;
    }

    virtual bool canPreshow() const
    {
        return true;
    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *xiaoqiao, QVariant &, ServerPlayer* &) const
    {
        if (TriggerSkill::triggerable(xiaoqiao) && !xiaoqiao->isKongcheng() &&
                !(xiaoqiao->hasFlag("tianxiang1used") && xiaoqiao->hasFlag("tianxiang2used")))
            return QStringList(objectName());
        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *xiaoqiao, QVariant &data, ServerPlayer *) const
    {
        xiaoqiao->tag["TianxiangDamage"] = data;
        bool invoke = room->askForUseCard(xiaoqiao, "@@tianxiang", "@tianxiang-card", -1, Card::MethodDiscard);
        xiaoqiao->tag.remove("TianxiangDamage");
        return invoke;
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *xiaoqiao, QVariant &data, ServerPlayer *) const
    {
        QVariantList data_list = xiaoqiao->tag["tianxiangTag"].toList();
        if (data_list.isEmpty()) return false;
        QVariant tianxiang_data = data_list.takeLast();
        xiaoqiao->tag["tianxiangTag"] = data_list;
        CardEffectStruct effect = tianxiang_data.value<CardEffectStruct>();
        ServerPlayer *target = effect.to;
        DamageStruct damage = data.value<DamageStruct>();
        const Card *card = Sanguosha->getCard(effect.card->getEffectiveId());

        QStringList choices;

        if (!xiaoqiao->hasFlag("tianxiang1used") && damage.from && damage.from->isAlive())
            choices << QString("damage%from:%1%to:%2").arg(damage.from->objectName()).arg(target->objectName());

        if (!xiaoqiao->hasFlag("tianxiang2used"))
            choices << QString("losehp%to:%1%log:%2").arg(target->objectName()).arg(card->objectName());

        if (choices.isEmpty()) {
            room->setPlayerFlag(xiaoqiao, "tianxiang1used");
        } else {
            QString choice;
            if (choices.length() == 1)
                choice = choices.first();
            else
                choice = room->askForChoice(xiaoqiao, objectName(), choices.join("+"), data);
            if (choice.startsWith("damage")) {
                room->setPlayerFlag(xiaoqiao, "tianxiang1used");
                room->damage(DamageStruct(objectName(), damage.from, target));
                if (target->isAlive() && target->getLostHp() > 0)
                    target->drawCards(qMin(target->getLostHp(), 5), objectName());
            } else if (choice.startsWith("losehp")) {
                room->setPlayerFlag(xiaoqiao, "tianxiang2used");
                room->loseHp(target);
                int id = card->getEffectiveId();
                Player::Place place = room->getCardPlace(id);
                if (target->isAlive() && (place == Player::DiscardPile || place == Player::DrawPile))
                    target->obtainCard(card);
            }
        }
        return true;
    }
};

class HongyanFilter : public FilterSkill
{
public:
    HongyanFilter() : FilterSkill("hongyan")
    {
    }

    static WrappedCard *changeToHeart(int cardId)
    {
        WrappedCard *new_card = Sanguosha->getWrappedCard(cardId);
        new_card->setSkillName("hongyan");
        new_card->setSuit(Card::Heart);
        new_card->setModified(true);
        return new_card;
    }

    virtual bool viewFilter(const Card *to_select, ServerPlayer *player) const
    {
        Room *room = player->getRoom();
        int id = to_select->getEffectiveId();
        if (player->hasShownSkill("hongyan"))
            return to_select->getSuit() == Card::Spade
                    && (room->getCardPlace(id) == Player::PlaceEquip
                        || room->getCardPlace(id) == Player::PlaceHand || room->getCardPlace(id) == Player::PlaceJudge);

        return false;
    }

    virtual const Card *viewAs(const Card *originalCard) const
    {
        return changeToHeart(originalCard->getEffectiveId());
    }

};

class Hongyan : public TriggerSkill
{
public:
    Hongyan() : TriggerSkill("hongyan")
    {
        //events << FinishRetrial;
        frequency = Compulsory;
        view_as_skill = new HongyanFilter;
    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *, QVariant &, ServerPlayer * &) const
    {
        return QStringList();
    }

    virtual int getEffectIndex(const ServerPlayer *, const Card *) const
    {
        return -2;
    }
};

class HongyanMaxCards : public MaxCardsSkill
{
public:
    HongyanMaxCards() : MaxCardsSkill("#hongyan-maxcards")
    {
    }

    virtual int getExtra(const Player *target) const
    {
        if (target->hasShownSkill("hongyan")) {
            foreach (const Card *equip, target->getEquips()) {
                if (equip->getSuit() == Card::Heart)
                    return 1;
            }
        }
        return 0;
    }
};

TianyiCard::TianyiCard()
{
}

bool TianyiCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.isEmpty() && Self->canPindianTo(to_select);
}

void TianyiCard::onEffect(const CardEffectStruct &effect) const
{
    if (effect.from->canPindianTo(effect.to)) {
        bool success = effect.from->pindian(effect.to, "tianyi");

        if (success)
            effect.to->getRoom()->setPlayerFlag(effect.from, "TianyiSuccess");
        else
            effect.to->getRoom()->setPlayerCardLimitation(effect.from, "use", "Slash", true);
    }
}

class Tianyi : public ZeroCardViewAsSkill
{
public:
    Tianyi() : ZeroCardViewAsSkill("tianyi")
    {
    }

    virtual bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("TianyiCard") && !player->isKongcheng();
    }

    virtual const Card *viewAs() const
    {
        TianyiCard *card = new TianyiCard;
        card->setShowSkill(objectName());
        return card;
    }
};


class TianyiTargetMod : public TargetModSkill
{
public:
    TianyiTargetMod() : TargetModSkill("#tianyi-target")
    {
    }

    virtual int getResidueNum(const Player *from, const Card *card, const Player *) const
    {
        if (!Sanguosha->matchExpPattern(pattern, from, card))
            return 0;

        if (from->hasFlag("TianyiSuccess"))
            return 1;
        else
            return 0;
    }

    virtual int getDistanceLimit(const Player *from, const Card *card, const Player *) const
    {
        if (!Sanguosha->matchExpPattern(pattern, from, card))
            return 0;

        if (from->hasFlag("TianyiSuccess"))
            return 1000;
        else
            return 0;
    }

    virtual int getExtraTargetNum(const Player *from, const Card *card) const
    {
        if (!Sanguosha->matchExpPattern(pattern, from, card))
            return 0;

        if (from->hasFlag("TianyiSuccess"))
            return 1;
        else
            return 0;
    }
};

class Buqu : public TriggerSkill
{
public:
    Buqu() : TriggerSkill("buqu")
    {
        events << AskForPeaches;
        frequency = Compulsory;
    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *zhoutai, QVariant &data, ServerPlayer* &) const
    {
        DyingStruct dying_data = data.value<DyingStruct>();
        if (!TriggerSkill::triggerable(zhoutai) || dying_data.who != zhoutai) return QStringList();
        if (zhoutai->getHp() < 1)
            return QStringList(objectName());

        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *zhoutai, QVariant &data, ServerPlayer *) const
    {
        bool invoke = false;
        if (zhoutai->hasShownSkill(objectName())) {
            invoke = true;
            room->sendCompulsoryTriggerLog(zhoutai, objectName());
        } else
            invoke = zhoutai->askForSkillInvoke(this, data);

        if (invoke) {
            room->broadcastSkillInvoke(objectName(), zhoutai);
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *zhoutai, QVariant &, ServerPlayer *) const
    {
        int id = room->drawCard();
        int num = Sanguosha->getCard(id)->getNumber();
        bool duplicate = false;
        foreach (int card_id, zhoutai->getPile("scars")) {
            if (Sanguosha->getCard(card_id)->getNumber() == num) {
                duplicate = true;
                break;
            }
        }
        zhoutai->addToPile("scars", id);
        if (duplicate) {
            CardMoveReason reason(CardMoveReason::S_REASON_REMOVE_FROM_PILE, QString(), objectName(), QString());
            room->throwCard(Sanguosha->getCard(id), reason, NULL);
        } else if (zhoutai->getHp() < 1) {
            RecoverStruct recover;
            recover.recover = 1 - zhoutai->getHp();
            recover.who = zhoutai;
            room->recover(zhoutai, recover);
        }
        return false;
    }
};

class Fenji : public TriggerSkill
{
public:
    Fenji() : TriggerSkill("fenji")
    {
        events << EventPhaseStart;
    }

    virtual TriggerList triggerable(TriggerEvent, Room *room, ServerPlayer *player, QVariant &) const
    {
        TriggerList skill_list;
        if (player == NULL || player->isDead() || player->getPhase() != Player::Finish || !player->isKongcheng()) return skill_list;
        QList<ServerPlayer *> zhoutais = room->findPlayersBySkillName(objectName());
        foreach (ServerPlayer *zhoutai, zhoutais) {
            skill_list.insert(zhoutai, QStringList(objectName()));
        }
        return skill_list;
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *ask_who) const
    {
        ServerPlayer *zhoutai = ask_who;
        if (zhoutai && zhoutai->askForSkillInvoke(this)) {
            room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, zhoutai->objectName(), player->objectName());
            room->broadcastSkillInvoke(objectName(), zhoutai);
            return true;
        }

        return false;
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *ask_who) const
    {
        player->drawCards(2, objectName());
        room->loseHp(ask_who);
        return false;
    }
};

HaoshiCard::HaoshiCard()
{
    will_throw = false;
    mute = true;
    handling_method = Card::MethodNone;
}

bool HaoshiCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    if (!targets.isEmpty() || to_select == Self)
        return false;

    return to_select->getHandcardNum() == Self->getMark("haoshi");
}

void HaoshiCard::onUse(Room *room, const CardUseStruct &card_use) const
{
    ServerPlayer *lusu = card_use.from;

    QVariant data = QVariant::fromValue(card_use);
    RoomThread *thread = room->getThread();

    thread->trigger(PreCardUsed, room, lusu, data);
    thread->trigger(CardUsed, room, lusu, data);
    thread->trigger(CardFinished, room, lusu, data);
}

void HaoshiCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const
{
    CardMoveReason reason(CardMoveReason::S_REASON_GIVE, source->objectName(),
        targets.at(0)->objectName(), "haoshi", QString());
    room->moveCardTo(this, targets.at(0), Player::PlaceHand, reason);
}

class HaoshiGiveViewAsSkill : public ViewAsSkill
{
public:
    HaoshiGiveViewAsSkill() : ViewAsSkill("haoshi_give")
    {
        response_pattern = "@@haoshi_give!";
    }

    virtual bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const
    {
        if (to_select->isEquipped())
            return false;

        int length = Self->getHandcardNum() / 2;
        return selected.length() < length;
    }

    virtual const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (cards.length() != Self->getHandcardNum() / 2)
            return NULL;

        HaoshiCard *card = new HaoshiCard;
        card->addSubcards(cards);
        return card;
    }
};

class Haoshi : public DrawCardsSkill
{
public:
    Haoshi() : DrawCardsSkill("haoshi")
    {

    }

    virtual bool canPreshow() const
    {
        return true;
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        if (player->askForSkillInvoke(this)) {
            if (player->getTriggerSkills().contains(this)) {
                room->broadcastSkillInvoke(objectName(), player);
            }
            return true;
        }
        return false;
    }

    virtual int getDrawNum(ServerPlayer *lusu, int n) const
    {
        lusu->setFlags(objectName());
        return n + 2;
    }
};

class HaoshiGive : public TriggerSkill
{
public:
    HaoshiGive() : TriggerSkill("#haoshi-give")
    {
        events << AfterDrawNCards;
        frequency = Compulsory;
    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *lusu, QVariant &, ServerPlayer * &) const
    {
        if (!lusu || !lusu->isAlive()) return QStringList();
        if (lusu->hasFlag("haoshi")) {
            if (lusu->getHandcardNum() <= 5) {
                lusu->setFlags("-haoshi");
                return QStringList();
            }
            return QStringList(objectName());
        }
        return QStringList();
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *lusu, QVariant &, ServerPlayer *) const
    {
        lusu->setFlags("-haoshi");
        QList<ServerPlayer *> other_players = room->getOtherPlayers(lusu);
        int least = 1000;
        foreach(ServerPlayer *player, other_players)
            least = qMin(player->getHandcardNum(), least);
        room->setPlayerMark(lusu, "haoshi", least);

        if (!room->askForUseCard(lusu, "@@haoshi_give!", "@haoshi-give:::"+QString::number(lusu->getHandcardNum() / 2), -1, Card::MethodNone)) {
            // force lusu to give his half cards
            ServerPlayer *beggar = NULL;
            foreach (ServerPlayer *player, other_players) {
                if (player->getHandcardNum() == least) {
                    beggar = player;
                    break;
                }
            }

            int n = lusu->getHandcardNum() / 2;
            QList<int> to_give = lusu->handCards().mid(0, n);
            HaoshiCard haoshi_card;
            haoshi_card.addSubcards(to_give);
            QList<ServerPlayer *> targets;
            targets << beggar;
            haoshi_card.use(room, lusu, targets);
        }
        return false;
    }
};

DimengCard::DimengCard()
{
}

bool DimengCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    if (to_select == Self)
        return false;

    if (targets.isEmpty())
        return true;

    if (targets.length() == 1) {
        return qAbs(to_select->getHandcardNum() - targets.first()->getHandcardNum()) == subcardsLength();
    }

    return false;
}

bool DimengCard::targetsFeasible(const QList<const Player *> &targets, const Player *) const
{
    return targets.length() == 2;
}

void DimengCard::onUse(Room *room, const CardUseStruct &card_use) const
{
    ServerPlayer *a = card_use.to.at(0);
    ServerPlayer *b = card_use.to.at(1);
    a->setFlags("DimengTarget");
    b->setFlags("DimengTarget");
    SkillCard::onUse(room, card_use);
}

void DimengCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const
{
    ServerPlayer *first = targets.at(0);
    ServerPlayer *second = targets.at(1);

    try {
        foreach (ServerPlayer *p, room->getAlivePlayers()) {
            if (p != first && p != second)
                room->doNotify(p, QSanProtocol::S_COMMAND_EXCHANGE_KNOWN_CARDS,
                JsonArray() << first->objectName() << second->objectName());
        }

        QList<int> handcards1 = first->handCards(), handcards2 = second->handCards();

        CardMoveReason reason1(CardMoveReason::S_REASON_SWAP, source->objectName(), second->objectName(), "dimeng", QString());
        CardMoveReason reason2(CardMoveReason::S_REASON_SWAP, source->objectName(), first->objectName(), "dimeng", QString());
        CardMoveReason reason3(CardMoveReason::S_REASON_NATURAL_ENTER, QString());

        QList<CardsMoveStruct> move_to_table;
        CardsMoveStruct move1(handcards1, NULL, Player::PlaceTable, reason1);
        CardsMoveStruct move2(handcards2, NULL, Player::PlaceTable, reason2);
        move_to_table.push_back(move2);
        move_to_table.push_back(move1);
        if (!move_to_table.isEmpty()) {
            room->moveCardsAtomic(move_to_table, false);

            QList<CardsMoveStruct> back_move;

            handcards1 = room->getCardIdsOnTable(handcards1);
            handcards2 = room->getCardIdsOnTable(handcards2);

            QList<ServerPlayer *> others = room->getAllPlayers(true);
            others.removeOne(first);
            others.removeOne(second);

            if (!handcards2.isEmpty()) {
                if (first->isAlive()) {

                    LogMessage log;
                    log.type = "$MoveCard";
                    log.from = first;
                    log.to << second;
                    log.card_str = IntList2StringList(handcards2).join("+");
                    room->doBroadcastNotify(targets, QSanProtocol::S_COMMAND_LOG_SKILL, log.toVariant());

                    LogMessage log2;
                    log2.type = "#MoveNCards";
                    log2.from = first;
                    log2.to << second;
                    log2.arg = QString::number(handcards2.length());
                    room->doBroadcastNotify(others, QSanProtocol::S_COMMAND_LOG_SKILL, log2.toVariant());

                    CardsMoveStruct move3(handcards2, first, Player::PlaceHand, reason2);
                    back_move.push_back(move3);
                } else {
                    CardsMoveStruct move3(handcards2, NULL, Player::DiscardPile, reason3);
                    back_move.push_back(move3);
                }
            }
            if (!handcards1.isEmpty()) {
                if (second->isAlive()) {

                    LogMessage log;
                    log.type = "$MoveCard";
                    log.from = second;
                    log.to << first;
                    log.card_str = IntList2StringList(handcards1).join("+");
                    room->doBroadcastNotify(targets, QSanProtocol::S_COMMAND_LOG_SKILL, log.toVariant());

                    LogMessage log2;
                    log2.type = "#MoveNCards";
                    log2.from = second;
                    log2.to << first;
                    log2.arg = QString::number(handcards1.length());
                    room->doBroadcastNotify(others, QSanProtocol::S_COMMAND_LOG_SKILL, log2.toVariant());

                    CardsMoveStruct move3(handcards1, second, Player::PlaceHand, reason1);
                    back_move.push_back(move3);
                } else {
                    CardsMoveStruct move3(handcards1, NULL, Player::DiscardPile, reason3);
                    back_move.push_back(move3);
                }
            }

            if (!back_move.isEmpty())
                room->moveCardsAtomic(back_move, false);
        }

        first->setFlags("-DimengTarget");
        second->setFlags("-DimengTarget");
    }
    catch (TriggerEvent triggerEvent) {
        if (triggerEvent == TurnBroken || triggerEvent == StageChange) {
            first->setFlags("-DimengTarget");
            second->setFlags("-DimengTarget");
        }
        throw triggerEvent;
    }
}

class Dimeng : public ViewAsSkill
{
public:
    Dimeng() : ViewAsSkill("dimeng")
    {
    }

    virtual bool viewFilter(const QList<const Card *> &, const Card *to_select) const
    {
        return !Self->isJilei(to_select);
    }

    virtual const Card *viewAs(const QList<const Card *> &cards) const
    {
        DimengCard *card = new DimengCard;
        card->addSubcards(cards);
        card->setShowSkill(objectName());
        return card;
    }

    virtual bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("DimengCard");
    }
};

ZhijianCard::ZhijianCard()
{
    will_throw = false;
    handling_method = Card::MethodNone;
}

bool ZhijianCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.isEmpty() && to_select != Self && to_select->canSetEquip(Sanguosha->getCard(getEffectiveId()));
}

void ZhijianCard::extraCost(Room *room, const CardUseStruct &card_use) const
{
    ServerPlayer *erzhang = card_use.from;
    room->moveCardTo(this, erzhang, card_use.to.first(), Player::PlaceEquip, CardMoveReason(CardMoveReason::S_REASON_PUT, erzhang->objectName(), "zhijian", QString()));

    LogMessage log;
    log.type = "$ZhijianEquip";
    log.from = card_use.to.first();
    log.card_str = QString::number(getEffectiveId());
    room->sendLog(log);
}

void ZhijianCard::onEffect(const CardEffectStruct &effect) const
{
    effect.from->drawCards(1, "zhijian");
}

class Zhijian : public OneCardViewAsSkill
{
public:
    Zhijian() :OneCardViewAsSkill("zhijian")
    {
        filter_pattern = "EquipCard|.|.|hand";
    }

    virtual const Card *viewAs(const Card *originalCard) const
    {
        ZhijianCard *zhijian_card = new ZhijianCard;
        zhijian_card->addSubcard(originalCard);
        zhijian_card->setShowSkill(objectName());
        return zhijian_card;
    }
};

//class GuzhengRecord : public TriggerSkill
//{
//public:
//    GuzhengRecord() : TriggerSkill("#guzheng-record")
//    {
//        events << CardsMoveOneTime;
//        frequency = Compulsory;
//    }

//    virtual QStringList triggerable(TriggerEvent, Room *room, ServerPlayer *erzhang, QVariant &data, ServerPlayer * &) const
//    {
//        if (!erzhang || !erzhang->isAlive() || !erzhang->hasSkill("guzheng")) return QStringList();
//        ServerPlayer *current = room->getCurrent();
//        CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();

//        if (erzhang == current)
//            return QStringList();

//        if (current->getPhase() == Player::Discard) {
//            QVariantList guzhengToGet = erzhang->tag["GuzhengToGet"].toList();
//            QVariantList guzhengOther = erzhang->tag["GuzhengOther"].toList();

//            if ((move.reason.m_reason & CardMoveReason::S_MASK_BASIC_REASON) == CardMoveReason::S_REASON_DISCARD) {
//                foreach (int card_id, move.card_ids) {
//                    if (move.from == current) {
//                        if (!guzhengToGet.contains(card_id))
//                            guzhengToGet << card_id;
//                    } else {
//                        if (!guzhengOther.contains(card_id))
//                            guzhengOther << card_id;
//                    }
//                }
//            }

//            erzhang->tag["GuzhengToGet"] = guzhengToGet;
//            erzhang->tag["GuzhengOther"] = guzhengOther;
//        }

//        return QStringList();
//    }
//};

// GuzhengCard::GuzhengCard()
// {
//     target_fixed = true;
//     will_throw = false;
//     handling_method = Card::MethodNone;
// }
// 
// void GuzhengCard::use(Room *, ServerPlayer *source, QList<ServerPlayer *> &) const
// {
//     source->tag["guzheng_card"] = subcards.first();
// }
// 
// class GuzhengVS : public OneCardViewAsSkill
// {
// public:
//     GuzhengVS() : OneCardViewAsSkill("guzheng")
//     {
//         response_pattern = "@@guzheng";
//     }
// 
//     virtual bool viewFilter(const Card *to_select) const
//     {
//         QStringList l = Self->property("guzheng_toget").toString().split("+");
//         QList<int> li = StringList2IntList(l);
//         return li.contains(to_select->getId());
//     }
// 
//     virtual const Card *viewAs(const Card *originalCard) const
//     {
//         GuzhengCard *gz = new GuzhengCard;
//         gz->addSubcard(originalCard);
//         // gz->setShowSkill("guzheng");  // Don't setShowSkill here!!!!!!!!!!!! This is the cost of the skill
//         return gz;
//     }
// };

class Guzheng : public TriggerSkill
{
public:
    Guzheng() : TriggerSkill("guzheng")
    {
        events << EventPhaseEnd << CardsMoveOneTime << EventPhaseChanging;
        //view_as_skill = new GuzhengVS;
    }

    virtual void record(TriggerEvent triggerEvent, Room *, ServerPlayer *current, QVariant &data) const
    {
        if (triggerEvent == CardsMoveOneTime && current->isAlive() && current->getPhase() == Player::Discard) {

            QVariantList move_datas = data.toList();
            foreach (QVariant move_data, move_datas) {

                CardsMoveOneTimeStruct move = move_data.value<CardsMoveOneTimeStruct>();

                QVariantList guzhengToGet = current->tag["GuzhengToGet"].toList();
                QVariantList guzhengOther = current->tag["GuzhengOther"].toList();

                if ((move.reason.m_reason & CardMoveReason::S_MASK_BASIC_REASON) == CardMoveReason::S_REASON_DISCARD) {
                    foreach (int card_id, move.card_ids) {
                        if (move.from == current) {
                            if (!guzhengToGet.contains(card_id))
                                guzhengToGet << card_id;
                        } else {
                            if (!guzhengOther.contains(card_id))
                                guzhengOther << card_id;
                        }
                    }
                }

                current->tag["GuzhengToGet"] = guzhengToGet;
                current->tag["GuzhengOther"] = guzhengOther;

            }

        } else if (triggerEvent == EventPhaseChanging) {
            PhaseChangeStruct change = data.value<PhaseChangeStruct>();
            if (change.from == Player::Discard || change.to == Player::Discard) {
                current->tag.remove("GuzhengToGet");
                current->tag.remove("GuzhengOther");
            }
        }

    }
    virtual TriggerList triggerable(TriggerEvent e, Room *room, ServerPlayer *player, QVariant &) const
    {
        TriggerList skill_list;
        if (player == NULL || player->isDead() || e != EventPhaseEnd || player->getPhase() != Player::Discard) return skill_list;
        QVariantList guzheng_cardsToGet = player->tag["GuzhengToGet"].toList();

        QList<int> cardsToGet;
        foreach (QVariant card_data, guzheng_cardsToGet) {
            int card_id = card_data.toInt();
            if (room->getCardPlace(card_id) == Player::DiscardPile)
                cardsToGet << card_id;
        }

        if (cardsToGet.isEmpty()) return skill_list;

        QList<ServerPlayer *> erzhangs = room->findPlayersBySkillName(objectName());

        foreach (ServerPlayer *erzhang, erzhangs) {
            if (erzhang == player) continue;
            skill_list.insert(erzhang, QStringList(objectName()));
        }

        return skill_list;
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *erzhang) const
    {
        QVariantList guzheng_cardsToGet = player->tag["GuzhengToGet"].toList();
        QVariantList guzheng_cardsOther = player->tag["GuzhengOther"].toList();

        QList<int> cardsToGet;
        foreach (QVariant card_data, guzheng_cardsToGet) {
            int card_id = card_data.toInt();
            if (room->getCardPlace(card_id) == Player::DiscardPile)
                cardsToGet << card_id;
        }
        QList<int> cardsOther;
        foreach (QVariant card_data, guzheng_cardsOther) {
            int card_id = card_data.toInt();
            if (room->getCardPlace(card_id) == Player::DiscardPile)
                cardsOther << card_id;
        }

        QList<int> cards = cardsToGet + cardsOther;

        QString cardsList = IntList2StringList(cards).join("+");
        room->setPlayerProperty(erzhang, "guzheng_allCards", cardsList);
        QString toGetList = IntList2StringList(cardsToGet).join("+");
        room->setPlayerProperty(erzhang, "guzheng_toget", toGetList);

        QList<int> result = room->notifyChooseCards(erzhang, cards, objectName(), Player::PlaceTable, Player::PlaceTable, 1, 0, "@guzheng:" + player->objectName(), IntList2StringList(cardsToGet).join(","));

        if (result.length() > 0) {
            LogMessage log;
            log.type = "#InvokeSkill";
            log.from = erzhang;
            log.arg = objectName();
            room->sendLog(log);
            room->notifySkillInvoked(erzhang, objectName());
            room->broadcastSkillInvoke(objectName(), erzhang);
            int to_back = result.first();
            player->obtainCard(Sanguosha->getCard(to_back));
            cards.removeOne(to_back);
            erzhang->tag["GuzhengCards"] = IntList2VariantList(cards);
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *, QVariant &data, ServerPlayer *erzhang) const
    {
        QList<int> cards = VariantList2IntList(erzhang->tag["GuzhengCards"].toList());
        erzhang->tag.remove("GuzhengCards");
        if (!cards.isEmpty() && room->askForChoice(erzhang, objectName(), "yes+no", data, "@guzheng-obtain") == "yes") {
            DummyCard dummy(cards);
            room->obtainCard(erzhang, &dummy);
        }

        return false;
    }
};

class Duanbing : public TriggerSkill
{
public:
    Duanbing() : TriggerSkill("duanbing")
    {
        events << TargetSelected;
    }

    virtual bool canPreshow() const
    {
        return true;
    }

    virtual QStringList triggerable(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (TriggerSkill::triggerable(player) && use.card != NULL && use.card->isKindOf("Slash")) {
            QList<ServerPlayer *> targets = room->getUseExtraTargets(use);
            foreach (ServerPlayer *p, targets) {
                if (player->distanceTo(p) == 1)
                    return QStringList(objectName());
            }
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        QList<ServerPlayer *> available_targets, targets = room->getUseExtraTargets(use);
        foreach (ServerPlayer *p, targets) {
            if (player->distanceTo(p) == 1)
                available_targets << p;
        }
        if (available_targets.isEmpty()) return false;

        ServerPlayer *target = room->askForPlayerChosen(player, available_targets, objectName(), "duanbing-invoke", true, true);
        if (target) {
            player->tag["duanbing-target"] = QVariant::fromValue(target);
            room->broadcastSkillInvoke(objectName(), player);
            return true;
        } else {
            player->tag.remove("duanbing-target");
            return false;
        }
        return false;
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        ServerPlayer *target = player->tag["duanbing-target"].value<ServerPlayer *>();
        player->tag.remove("duanbing-target");
        if (target) {
            use.to.append(target);
            room->sortByActionOrder(use.to);
            data = QVariant::fromValue(use);
        }
        return false;
    }
};

FenxunCard::FenxunCard()
{
}

bool FenxunCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.isEmpty() && to_select != Self;
}

void FenxunCard::onEffect(const CardEffectStruct &effect) const
{
    Room *room = effect.from->getRoom();
    effect.from->tag["FenxunTarget"] = QVariant::fromValue(effect.to);
    room->setFixedDistance(effect.from, effect.to, 1);
}

class FenxunViewAsSkill : public OneCardViewAsSkill
{
public:
    FenxunViewAsSkill() : OneCardViewAsSkill("fenxun")
    {
        filter_pattern = ".!";
    }

    virtual bool isEnabledAtPlay(const Player *player) const
    {
        return player->canDiscard(player, "he") && !player->hasUsed("FenxunCard");
    }

    virtual const Card *viewAs(const Card *originalcard) const
    {
        FenxunCard *first = new FenxunCard;
        first->addSubcard(originalcard->getId());
        first->setSkillName(objectName());
        first->setShowSkill(objectName());
        return first;
    }
};

class Fenxun : public TriggerSkill
{
public:
    Fenxun() : TriggerSkill("fenxun")
    {
        events << EventPhaseChanging << Death;
        view_as_skill = new FenxunViewAsSkill;
    }

    virtual QStringList triggerable(TriggerEvent triggerEvent, Room *room, ServerPlayer *dingfeng, QVariant &data, ServerPlayer* &) const
    {
        if (dingfeng == NULL || dingfeng->tag["FenxunTarget"].value<ServerPlayer *>() == NULL) return QStringList();
        if (triggerEvent == EventPhaseChanging) {
            PhaseChangeStruct change = data.value<PhaseChangeStruct>();
            if (change.to != Player::NotActive)
                return QStringList();
        } else if (triggerEvent == Death) {
            DeathStruct death = data.value<DeathStruct>();
            if (death.who != dingfeng)
                return QStringList();
        }
        ServerPlayer *target = dingfeng->tag["FenxunTarget"].value<ServerPlayer *>();

        if (target) {
            room->setFixedDistance(dingfeng, target, -1);
            dingfeng->tag.remove("FenxunTarget");
        }
        return QStringList();
    }
};

void StandardPackage::addWuGenerals()
{
    General *sunquan = new General(this, "sunquan", "wu"); // WU 001
    sunquan->addCompanion("zhoutai");
    sunquan->addSkill(new Zhiheng);

    General *ganning = new General(this, "ganning", "wu"); // WU 002
    ganning->addSkill(new Qixi);

    General *lvmeng = new General(this, "lvmeng", "wu"); // WU 003
    lvmeng->addSkill(new Keji);
    lvmeng->addSkill(new Mouduan);

    General *huanggai = new General(this, "huanggai", "wu"); // WU 004
    huanggai->addSkill(new Kurou);
    huanggai->addSkill(new KurouTargetMod);
    insertRelatedSkills("kurou", "#kurou-target");

    General *zhouyu = new General(this, "zhouyu", "wu", 3); // WU 005
    zhouyu->addCompanion("huanggai");
    zhouyu->addCompanion("xiaoqiao");
    zhouyu->addSkill(new Yingzi);
    zhouyu->addSkill(new Fanjian);

    General *daqiao = new General(this, "daqiao", "wu", 3, false); // WU 006
    daqiao->addCompanion("xiaoqiao");
    daqiao->addSkill(new Guose);
    daqiao->addSkill(new Liuli);

    General *luxun = new General(this, "luxun", "wu", 3); // WU 007
    luxun->addSkill(new Qianxun);
    luxun->addSkill(new Duoshi);

    General *sunshangxiang = new General(this, "sunshangxiang", "wu", 3, false); // WU 008
    sunshangxiang->addSkill(new Jieyin);
    sunshangxiang->addSkill(new Xiaoji);

    General *sunjian = new General(this, "sunjian", "wu", 5); // WU 009
    sunjian->addSkill(new Yinghun);

    General *xiaoqiao = new General(this, "xiaoqiao", "wu", 3, false); // WU 011
    xiaoqiao->addSkill(new Tianxiang);
    xiaoqiao->addSkill(new Hongyan);
    xiaoqiao->addSkill(new HongyanMaxCards);
    insertRelatedSkills("hongyan", "#hongyan-maxcards");

    General *taishici = new General(this, "taishici", "wu"); // WU 012
    taishici->addSkill(new Tianyi);
    taishici->addSkill(new TianyiTargetMod);
    insertRelatedSkills("tianyi", "#tianyi-target");

    General *zhoutai = new General(this, "zhoutai", "wu");
    zhoutai->addSkill(new Buqu);
    zhoutai->addSkill(new DetachEffectSkill("buqu", "scars"));
    insertRelatedSkills("buqu", "#buqu-clear");
    zhoutai->addSkill(new Fenji);

    General *lusu = new General(this, "lusu", "wu", 3); // WU 014
    lusu->addSkill(new Haoshi);
    lusu->addSkill(new HaoshiGive);
    lusu->addSkill(new Dimeng);
    insertRelatedSkills("haoshi", "#haoshi-give");

    General *erzhang = new General(this, "erzhang", "wu", 3); // WU 015
    erzhang->addSkill(new Zhijian);
    erzhang->addSkill(new Guzheng);
    //erzhang->addSkill(new GuzhengRecord);
    //insertRelatedSkills("guzheng", "#guzheng-record");

    General *dingfeng = new General(this, "dingfeng", "wu"); // WU 016
    dingfeng->addSkill(new Duanbing);
    dingfeng->addSkill(new Fenxun);

    addMetaObject<ZhihengCard>();
    addMetaObject<KurouCard>();
    addMetaObject<FanjianCard>();
    addMetaObject<LiuliCard>();
    addMetaObject<JieyinCard>();
    addMetaObject<TianxiangCard>();
    addMetaObject<TianyiCard>();
    addMetaObject<HaoshiCard>();
    addMetaObject<DimengCard>();
    addMetaObject<ZhijianCard>();
    addMetaObject<FenxunCard>();
    //    addMetaObject<GuzhengCard>();

    skills << new YingziMaxCards << new HaoshiGiveViewAsSkill;
}
