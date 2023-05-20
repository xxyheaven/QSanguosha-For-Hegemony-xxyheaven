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

#include "standard-shu-generals.h"
#include "structs.h"
#include "standard-basics.h"
#include "standard-tricks.h"
#include "client.h"
#include "engine.h"
#include "util.h"
#include "roomthread.h"
#include "json.h"

class RendeBasic : public ZeroCardViewAsSkill
{
public:
    RendeBasic() : ZeroCardViewAsSkill("rende_basic")
    {
        guhuo_type = "b";
        response_pattern = "@@rende_basic";
    }

    const Card *viewAs() const
    {
        QString rende_card = Self->tag["rende_basic"].toString();
        if (rende_card.isEmpty()) return NULL;
        Card *slash = Sanguosha->cloneCard(rende_card, Card::NoSuit, 0);
        if (slash == NULL) return NULL;
        slash->setSkillName("_rende");
        return slash;
    }

    bool isEnabledtoViewAsCard(const QString &button_name, const QList<const Card *> &) const
    {
        Card *card = Sanguosha->cloneCard(button_name, Card::NoSuit, 0);
        if (card == NULL) return false;
        card->setSkillName("_rende");
        return (!Self->isCardLimited(card, Card::MethodUse, false) && card->isAvailable(Self));
    }
};

RendeCard::RendeCard()
{
    will_throw = false;
    handling_method = Card::MethodNone;
}

bool RendeCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    QStringList rende_prop = Self->property("rende").toString().split("+");
    return targets.isEmpty() && to_select != Self && !rende_prop.contains(to_select->objectName());
}

void RendeCard::extraCost(Room *room, const CardUseStruct &card_use) const
{
    ServerPlayer *target = card_use.to.first();
    CardMoveReason reason(CardMoveReason::S_REASON_GIVE, card_use.from->objectName(), target->objectName(), "rende", QString());
    room->obtainCard(target, this, reason, false);
}

void RendeCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const
{
    QSet<QString> rende_prop = source->property("rende").toString().split("+").toSet();
    rende_prop.insert(targets.first()->objectName());
    room->setPlayerProperty(source, "rende", QStringList(rende_prop.toList()).join("+"));

    int old_value = source->getMark("rende");
    int new_value = old_value + subcards.length();
    room->setPlayerMark(source, "rende", new_value);

    if (old_value < 2 && new_value >= 2) {

        room->askForUseCard(source, "@@rende_basic", "@rende-basic");
    }
}

class RendeViewAsSkill : public ViewAsSkill
{
public:
    RendeViewAsSkill() : ViewAsSkill("rende")
    {
    }

    virtual bool viewFilter(const QList<const Card *> &, const Card *to_select) const
    {
        return !to_select->isEquipped();
    }

    virtual bool isEnabledAtPlay(const Player *) const
    {
        return true;
    }

    virtual const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (cards.isEmpty())
            return NULL;

        RendeCard *rende_card = new RendeCard;
        rende_card->addSubcards(cards);
        rende_card->setShowSkill(objectName());
        return rende_card;
    }
};

class Rende : public TriggerSkill
{
public:
    Rende() : TriggerSkill("rende")
    {
        events << EventPhaseChanging;
        view_as_skill = new RendeViewAsSkill;
    }

    virtual void record(TriggerEvent , Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (data.value<PhaseChangeStruct>().from == Player::Play) {
            room->setPlayerMark(player, "rende", 0);
            room->setPlayerProperty(player, "rende", QVariant());
        }
    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *, QVariant &, ServerPlayer * &) const
    {
        return QStringList();
    }

    virtual int getEffectIndex(const ServerPlayer *, const Card *card) const
    {
        return card->isKindOf("RendeCard") ? -1 : 0;
    }
};

class Wusheng : public OneCardViewAsSkill
{
public:
    Wusheng() : OneCardViewAsSkill("wusheng")
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

class WushengTargetMod : public TargetModSkill
{
public:
    WushengTargetMod() : TargetModSkill("#wusheng-target")
    {
    }

    virtual int getDistanceLimit(const Player *from, const Card *card, const Player *) const
    {
        if ((from->hasShownSkill("wusheng") || (from->hasShownSkill("wusheng_xh")))
                && card->getSuit() == Card::Diamond)
            return 1000;
        else
            return 0;
    }
};

class PaoxiaoTarget : public TargetModSkill
{
public:
    PaoxiaoTarget() : TargetModSkill("#paoxiao-target")
    {
    }

    virtual int getResidueNum(const Player *from, const Card *card, const Player *) const
    {
        if (!Sanguosha->matchExpPattern(pattern, from, card))
            return 0;

        if (from->hasShownSkill("paoxiao") || from->hasShownSkill("paoxiao_xh"))
            return 1000;
        else
            return 0;
    }
};

class Paoxiao : public TriggerSkill
{
public:
    Paoxiao() : TriggerSkill("paoxiao")
    {
        events << TargetChosen << CardUsed;
        frequency = Compulsory;
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

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *, QVariant &, ServerPlayer *player) const
    {
        bool invoke = false;
        if (player->hasShownSkill(objectName())) {
            invoke = true;
            room->sendCompulsoryTriggerLog(player, objectName());
        } else
            invoke = player->askForSkillInvoke(this);

        return invoke;
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

class Guanxing : public PhaseChangeSkill
{
public:
    Guanxing() : PhaseChangeSkill("guanxing")
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
        QList<int> guanxing = room->getNCards(getGuanxingNum(zhuge));

        LogMessage log;
        log.type = "$ViewDrawPile";
        log.from = zhuge;
        log.card_str = IntList2StringList(guanxing).join("+");
        room->doNotify(zhuge, QSanProtocol::S_COMMAND_LOG_SKILL, log.toVariant());

        room->askForGuanxing(zhuge, guanxing, Room::GuanxingBothSides);
        return false;
    }

    virtual int getGuanxingNum(ServerPlayer *zhuge) const
    {
        if (zhuge->inHeadSkills(this) && zhuge->hasShownGeneral1() && zhuge->hasShownSkill("yizhi")) return 5;
        return qMin(5, zhuge->aliveCount());
    }
};

class Kongcheng : public TriggerSkill
{
public:
    Kongcheng() : TriggerSkill("kongcheng")
    {
        events << TargetConfirming << BeforeCardsMove << EventPhaseStart;
        frequency = Compulsory;
    }

    virtual QStringList triggerable(TriggerEvent triggerEvent, Room *, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        if (TriggerSkill::triggerable(player)) {
            if (triggerEvent == TargetConfirming && player->isKongcheng()) {
                CardUseStruct use = data.value<CardUseStruct>();
                if (use.card != NULL && (use.card->isKindOf("Slash") || use.card->isKindOf("Duel")) && use.to.contains(player)) {
                    return QStringList(objectName());
                }
            } else if (triggerEvent == BeforeCardsMove && player->getPhase() == Player::NotActive && player->isKongcheng()) {
                QVariantList move_datas = data.toList();
                foreach (QVariant move_data, move_datas) {
                    CardsMoveOneTimeStruct move = move_data.value<CardsMoveOneTimeStruct>();
                    if (move.reason.m_reason == CardMoveReason::S_REASON_GIVE || move.reason.m_reason == CardMoveReason::S_REASON_PREVIEWGIVE) {
                        if (move.to && move.to == player && move.to_place == Player::PlaceHand) {
                            return QStringList(objectName());
                        }
                    }
                }

            } else if (triggerEvent == EventPhaseStart && player->getPhase() == Player::Draw && !player->getPile("zither").isEmpty()) {
                return QStringList(objectName());
            }
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        if (player->hasShownSkill(this)) {
            room->sendCompulsoryTriggerLog(player, objectName());
            room->broadcastSkillInvoke(objectName(), player);
            return true;
        } else if (player->askForSkillInvoke(this)) {
            room->broadcastSkillInvoke(objectName(), player);
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (triggerEvent == TargetConfirming) {
            CardUseStruct use = data.value<CardUseStruct>();

            room->cancelTarget(use, player); // Room::cancelTarget(use, player);

            data = QVariant::fromValue(use);
        } else if (triggerEvent == BeforeCardsMove) {
            QVariantList move_datas = data.toList();
            QList<int> card_ids;
            foreach (QVariant move_data, move_datas) {
                CardsMoveOneTimeStruct move = move_data.value<CardsMoveOneTimeStruct>();
                if (move.reason.m_reason == CardMoveReason::S_REASON_GIVE || move.reason.m_reason == CardMoveReason::S_REASON_PREVIEWGIVE) {
                    if (move.to && move.to == player && move.to_place == Player::PlaceHand) {
                        card_ids << move.card_ids;
                    }
                }
            }

            if (!card_ids.isEmpty()) {
                CardsMoveStruct move;
                move.card_ids = card_ids;
                move.to = player;
                move.to_place = Player::PlaceSpecial;
                move.to_pile_name = "zither";
                player->pileAdd("zither", card_ids);
                data = room->changeMoveData(data, move);
            }

        } else if (triggerEvent == EventPhaseStart) {
            DummyCard *dummy = new DummyCard(player->getPile("zither"));
            CardMoveReason reason(CardMoveReason::S_REASON_EXCHANGE_FROM_PILE, player->objectName(), objectName(), QString());
            room->obtainCard(player, dummy, reason, false);
            delete dummy;
        }
        return false;
    }
};

class Longdan : public OneCardViewAsSkill
{
public:
    Longdan() : OneCardViewAsSkill("longdan")
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
            jink->setShowSkill(objectName());
            return jink;
        } else if (originalCard->isKindOf("Jink")) {
            Slash *slash = new Slash(originalCard->getSuit(), originalCard->getNumber());
            slash->addSubcard(originalCard);
            slash->setSkillName(objectName());
            slash->setShowSkill(objectName());
            return slash;
        } else
            return NULL;
    }
};

class LongdanSlash : public TriggerSkill
{
public:
    LongdanSlash() : TriggerSkill("#longdan-slash")
    {
        events << SlashMissed;
        global = true;
    }

    virtual QStringList triggerable(TriggerEvent , Room *room, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        if (player == NULL || player->isDead()) return QStringList();
        SlashEffectStruct effect = data.value<SlashEffectStruct>();
        if (effect.slash && (effect.slash->getSkillName() == "longdan" || effect.slash->getSkillName() == "longdan_xh")) {
            QList<ServerPlayer *> targets = room->getAlivePlayers();
            if (effect.to && effect.to->isAlive())
                targets.removeOne(effect.to);
            if (!targets.isEmpty())
                return QStringList(objectName());
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        SlashEffectStruct effect = data.value<SlashEffectStruct>();
        QList<ServerPlayer *> targets = room->getAlivePlayers();
        if (effect.to && effect.to->isAlive())
            targets.removeOne(effect.to);
        ServerPlayer *target = room->askForPlayerChosen(player, targets, "longdan_damage", "longdan-damage", true);
        if (target != NULL) {
            room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, player->objectName(), target->objectName());
            LogMessage log;
            log.type = "#LongdanDamage";
            log.from = player;
            log.to << target;
            log.arg = "longdan";
            room->sendLog(log);
            QStringList target_list = player->tag["longdan_damage"].toStringList();
            target_list.append(target->objectName());
            player->tag["longdan_damage"] = target_list;
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        QStringList target_list = player->tag["longdan_damage"].toStringList();
        QString target_name = target_list.last();
        target_list.removeLast();
        player->tag["longdan_damage"] = target_list;

        ServerPlayer *to = NULL;

        foreach (ServerPlayer *p, room->getPlayers()) {
            if (p->objectName() == target_name) {
                to = p;
                break;
            }
        }
        if (to != NULL && to->isAlive())
            room->damage(DamageStruct("longdan", player, to));
        return false;
    }
};

class LongdanJink : public TriggerSkill
{
public:
    LongdanJink() : TriggerSkill("#longdan-jink")
    {
        events << SlashMissed;
        global = true;
    }

    virtual QStringList triggerable(TriggerEvent , Room *room, ServerPlayer *, QVariant &data, ServerPlayer * &zhaoyun) const
    {
        SlashEffectStruct effect = data.value<SlashEffectStruct>();
        if (effect.jink && (effect.jink->getSkillName() == "longdan" || effect.jink->getSkillName() == "longdan_xh")) {
            if (effect.to && effect.to->isAlive()) {
                QList<ServerPlayer *> players = room->getOtherPlayers(effect.to);
                foreach (ServerPlayer *p, players) {
                    if (p->isWounded()) {
                        zhaoyun = effect.to;
                        return QStringList(objectName());
                    }
                }

            }
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *zhaoyun) const
    {
        QList<ServerPlayer *> players = room->getOtherPlayers(zhaoyun), targets;
        foreach (ServerPlayer *p, players) {
            if (player != p && p->isWounded())
                targets << p;
        }
        if (targets.isEmpty()) return false;
        ServerPlayer *target = room->askForPlayerChosen(zhaoyun, targets, "longdan_recover", "longdan-recover", true);
        if (target != NULL) {
            LogMessage log;
            log.type = "#LongdanRecover";
            log.from = zhaoyun;
            log.to << target;
            log.arg = "longdan";
            room->sendLog(log);
            room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, zhaoyun->objectName(), target->objectName());
            QStringList target_list = zhaoyun->tag["longdan_recover"].toStringList();
            target_list.append(target->objectName());
            zhaoyun->tag["longdan_recover"] = target_list;
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *, QVariant &, ServerPlayer *player) const
    {
        QStringList target_list = player->tag["longdan_recover"].toStringList();
        QString target_name = target_list.last();
        target_list.removeLast();
        player->tag["longdan_recover"] = target_list;

        ServerPlayer *to = NULL;

        foreach (ServerPlayer *p, room->getPlayers()) {
            if (p->objectName() == target_name) {
                to = p;
                break;
            }
        }
        if (to != NULL && to->isAlive()) {
            RecoverStruct recover;
            recover.who = player;
            room->recover(to, recover);
        }
        return false;
    }
};

class LongdanDraw : public TriggerSkill
{
public:
    LongdanDraw() : TriggerSkill("#longdan-draw")
    {
        events << CardUsed << CardResponded;
        frequency = Compulsory;
        global = true;
    }

    virtual QStringList triggerable(TriggerEvent triggerEvent, Room *, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        const Card *card = NULL;
        if (triggerEvent == CardUsed)
            card = data.value<CardUseStruct>().card;
        else
            card = data.value<CardResponseStruct>().m_card;

        if (card != NULL && (card->getSkillName() == "longdan" || card->getSkillName() == "longdan_xh")) {
            if (player && player->isAlive() && player->hasSkill(card->getSkillName())
                    && player->enjoyingSkill("shouyue") && player->getSeemingKingdom() == "shu")
                return QStringList(objectName());
        }

        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *zhaoyun, QVariant &, ServerPlayer *) const
    {
        LogMessage log;
        log.type = "#LongdanDraw";
        log.from = zhaoyun;
        log.arg = "longdan";
        room->sendLog(log);
        room->notifySkillInvoked(zhaoyun, "longdan");
        return true;
    }

    virtual bool effect(TriggerEvent, Room *, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        player->drawCards(1, "longdan");
        return false;
    }
};

Mashu::Mashu(const QString &owner) : DistanceSkill("mashu_" + owner)
{
}

int Mashu::getCorrect(const Player *from, const Player *) const
{
    if (from->hasSkill(objectName()) && from->hasShownSkill(this))
        return -1;
    else
        return 0;
}

Tieqi::Tieqi(const QString &owner) : TriggerSkill("tieqi" + owner)
{
    events << TargetChosen;
}

QStringList Tieqi::triggerable(TriggerEvent , Room *, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
{
    CardUseStruct use = data.value<CardUseStruct>();
    if (TriggerSkill::triggerable(player) && use.card != NULL && use.card->isKindOf("Slash")) {
        ServerPlayer *target = use.to.at(use.index);
        if (target != NULL)
            return QStringList(objectName() + "->" + target->objectName());
    }
    return QStringList();
}

bool Tieqi::cost(TriggerEvent, Room *room, ServerPlayer *skill_target, QVariant &, ServerPlayer *player) const
{
    if (player->askForSkillInvoke(this, QVariant::fromValue(skill_target))) {
        room->broadcastSkillInvoke(objectName(), player);
        room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, player->objectName(), skill_target->objectName());
        return true;
    }
    return false;
}

bool Tieqi::effect(TriggerEvent, Room *room, ServerPlayer *target, QVariant &data, ServerPlayer *player) const
{
    CardUseStruct use = data.value<CardUseStruct>();
    QVariantList jink_list = player->tag["Jink_" + use.card->toString()].toList();

    QStringList all_patterns;
    all_patterns << ".|spade" << ".|club" << ".|heart" << ".|diamond";

    JudgeStruct judge;
    judge.pattern = ".";
    judge.patterns = all_patterns;
    judge.good = true;
    judge.reason = "tieqi";
    judge.who = player;
    judge.play_animation = false;

    room->judge(judge);

    if (player->enjoyingSkill("shouyue") && player->getSeemingKingdom() == "shu") {

        LogMessage log;
        log.type = "#TieqiAllSkills";
        log.from = player;
        log.to << target;
        log.arg = "tieqi";
        room->sendLog(log);

        if (target->hasShownGeneral1())
            room->setPlayerMark(target, "skill_invalidity_head", 1);
        if (target->getGeneral2() && target->hasShownGeneral2())
            room->setPlayerMark(target, "skill_invalidity_deputy", 1);

        foreach(ServerPlayer *p, room->getAllPlayers())
            room->filterCards(p, p->getCards("he"), true);

        JsonArray args;
        args << QSanProtocol::S_GAME_EVENT_UPDATE_SKILL;
        room->doBroadcastNotify(QSanProtocol::S_COMMAND_LOG_EVENT, args);

    } else if (target->hasShownOneGeneral()) {
        QString choice = "head_general";

        if (player->getAI()) {
            QStringList choices;
            if (target->hasShownGeneral1())
                choices << "head_general";

            if (target->getGeneral2() && target->hasShownGeneral2())
                choices << "deputy_general";

            choice = room->askForChoice(player, "tieqi", choices.join("+"), QVariant::fromValue(target));
        } else {
            QStringList generals;
            if (target->hasShownGeneral1()) {
                QString g = target->getGeneral()->objectName();
                if (g.contains("anjiang"))
                    g.append("_head");
                generals << g;
            }

            if (target->getGeneral2() && target->hasShownGeneral2()) {
                QString g = target->getGeneral2()->objectName();
                if (g.contains("anjiang"))
                    g.append("_deputy");
                generals << g;
            }

            QString general = generals.first();
            if (generals.length() == 2)
                general = room->askForGeneral(player, generals.join("+"), generals.first(), true, "tieqi", QVariant::fromValue(target));

            if (general == target->getGeneral()->objectName() || general == "anjiang_head")
                choice = "head_general";
            else
                choice = "deputy_general";

        }
        LogMessage log;
        log.type = choice == "head_general" ? "#TieqiHeadSkills" : "#TieqiDeputySkills";
        log.from = player;
        log.to << target;
        log.arg = "tieqi";
        room->sendLog(log);

        QString mark_name = choice == "head_general" ? "skill_invalidity_head" : "skill_invalidity_deputy";

        room->setPlayerMark(target, mark_name, 1);

        foreach(ServerPlayer *p, room->getAllPlayers())
            room->filterCards(p, p->getCards("he"), true);

        JsonArray args;
        args << QSanProtocol::S_GAME_EVENT_UPDATE_SKILL;
        room->doBroadcastNotify(QSanProtocol::S_COMMAND_LOG_EVENT, args);

    }

    int index = use.to.indexOf(target);

    if (target->isAlive() && all_patterns.contains(judge.pattern)
            && !room->askForCard(target, judge.pattern, "@tieji-discard:::" + judge.pattern.mid(2), QVariant::fromValue(use))) {
        LogMessage log;
        log.type = "#NoJink";
        log.from = target;
        room->sendLog(log);
        jink_list[index] = 0;
    }

    player->tag["Jink_" + use.card->toString()] = jink_list;
    return false;
}

class Jizhi : public TriggerSkill
{
public:
    Jizhi() : TriggerSkill("jizhi")
    {
        frequency = Frequent;
        events << CardUsed;
    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        if (!TriggerSkill::triggerable(player))
            return QStringList();
        CardUseStruct use = data.value<CardUseStruct>();
        if (use.card != NULL && use.card->isNDTrick()) {
            if (!use.card->isVirtualCard() || use.card->getSubcards().isEmpty())
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

    virtual bool effect(TriggerEvent, Room *, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        player->drawCards(1, objectName());
        return false;
    }
};

class Qicai : public TargetModSkill
{
public:
    Qicai() : TargetModSkill("qicai")
    {
        pattern = "TrickCard";
    }

    virtual int getDistanceLimit(const Player *from, const Card *card, const Player *) const
    {
        if (!Sanguosha->matchExpPattern(pattern, from, card))
            return 0;

        if (from->hasShownSkill("qicai"))
            return 1000;
        else
            return 0;
    }
};

class Liegong : public TriggerSkill
{
public:
    Liegong() : TriggerSkill("liegong")
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

class LiegongTargetMod : public TargetModSkill
{
public:
    LiegongTargetMod() : TargetModSkill("#liegong-target")
    {
    }

    virtual int getDistanceLimit(const Player *from, const Card *, const Player *to) const
    {
        if ((from->hasShownSkill("liegong") || from->hasShownSkill("liegong_xh")) && to && from->getHandcardNum() >= to->getHandcardNum())
            return 10000;
        else
            return 0;
    }
};

class LiegongRange : public AttackRangeSkill
{
public:
    LiegongRange() : AttackRangeSkill("#liegong-for-lord")
    {
    }

    virtual int getExtra(const Player *target, bool) const
    {
        if (target->enjoyingSkill("shouyue") && target->getSeemingKingdom() == "shu") {
            int x = 0;
            if (target->hasShownSkill("liegong")) x++;
            if (target->hasShownSkill("liegong_xh")) x++;
            return x;
        }
        return 0;
    }
};

class Kuanggu : public TriggerSkill
{
public:
    Kuanggu() : TriggerSkill("kuanggu")
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

class Lianhuan : public OneCardViewAsSkill
{
public:
    Lianhuan() : OneCardViewAsSkill("lianhuan")
    {
        filter_pattern = ".|club|.|hand";
        response_or_use = true;
    }

    virtual const Card *viewAs(const Card *originalCard) const
    {
        IronChain *chain = new IronChain(originalCard->getSuit(), originalCard->getNumber());
        chain->addSubcard(originalCard);
        chain->setSkillName(objectName());
        chain->setShowSkill(objectName());
        return chain;
    }
};

class Niepan : public TriggerSkill
{
public:
    Niepan() : TriggerSkill("niepan")
    {
        events << AskForPeaches;
        frequency = Limited;
        limit_mark = "@nirvana";
    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *target, QVariant &data, ServerPlayer * &) const
    {
        if (TriggerSkill::triggerable(target) && target->getMark("@nirvana") > 0) {
            DyingStruct dying_data = data.value<DyingStruct>();

            if (target->getHp() > 0)
                return QStringList();

            if (dying_data.who != target)
                return QStringList();
            return QStringList(objectName());
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *pangtong, QVariant &data, ServerPlayer *) const
    {
        if (pangtong->askForSkillInvoke(this, data)) {
            room->broadcastSkillInvoke(objectName(), pangtong);
            room->doSuperLightbox("pangtong", objectName());
            room->setPlayerMark(pangtong, "@nirvana", 0);
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *pangtong, QVariant &, ServerPlayer *) const
    {
        pangtong->throwAllHandCardsAndEquips();
        QList<const Card *> tricks = pangtong->getJudgingArea();
        foreach (const Card *trick, tricks) {
            CardMoveReason reason(CardMoveReason::S_REASON_NATURAL_ENTER, pangtong->objectName());
            room->throwCard(trick, reason, NULL);
        }

        RecoverStruct recover;
        recover.recover = qMin(3, pangtong->getMaxHp()) - pangtong->getHp();
        room->recover(pangtong, recover);

        pangtong->drawCards(3);

        if (pangtong->isChained())
            room->setPlayerProperty(pangtong, "chained", false);

        if (!pangtong->faceUp())
            pangtong->turnOver();

        return false; //return pangtong->getHp() > 0 || pangtong->isDead();
    }
};

class Huoji : public OneCardViewAsSkill
{
public:
    Huoji() : OneCardViewAsSkill("huoji")
    {
        filter_pattern = ".|red|.|hand";
        response_or_use = true;
    }

    virtual const Card *viewAs(const Card *originalCard) const
    {
        FireAttack *fire_attack = new FireAttack(originalCard->getSuit(), originalCard->getNumber());
        fire_attack->addSubcard(originalCard->getId());
        fire_attack->setSkillName(objectName());
        fire_attack->setShowSkill(objectName());
        return fire_attack;
    }
};

class Bazhen : public ViewHasSkill
{
public:
    Bazhen() : ViewHasSkill("bazhen")
    {
    }
    virtual bool ViewHas(const Player *player, const QString &skill_name, const QString &flag) const
    {
        if (flag == "armor" && skill_name == "EightDiagram" && player->isAlive() && player->hasShownSkill("bazhen") && !player->getArmor())
            return true;
        return false;
    }
};

/*
class Bazhen : public TriggerSkill
{
public:
    Bazhen() : TriggerSkill("bazhen")
    {
        frequency = Compulsory;
        events << CardAsked;
    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        if (!TriggerSkill::triggerable(player))
            return QStringList();

        QString pattern = data.toStringList().first();
        if (pattern != "jink")
            return QStringList();

        if (!player->tag["Qinggang"].toStringList().isEmpty() || player->getMark("Armor_Nullified") > 0
            || player->getMark("Equips_Nullified_to_Yourself") > 0)
            return QStringList();

        if (player->hasArmorEffect("bazhen"))
            return QStringList("EightDiagram");

        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *, ServerPlayer *, QVariant &, ServerPlayer *) const
    {
        return false;
    }
};
*/

class Kanpo : public OneCardViewAsSkill
{
public:
    Kanpo() : OneCardViewAsSkill("kanpo")
    {
        filter_pattern = ".|black|.|hand";
        response_pattern = "nullification";
        response_or_use = true;
    }

    virtual const Card *viewAs(const Card *originalCard) const
    {
        Card *ncard = new Nullification(originalCard->getSuit(), originalCard->getNumber());
        ncard->addSubcard(originalCard);
        ncard->setSkillName(objectName());
        ncard->setShowSkill(objectName());
        return ncard;
    }

    virtual bool isEnabledAtNullification(const ServerPlayer *player) const
    {
        return !(player->isKongcheng() && player->getHandPile().isEmpty());
    }
};

SavageAssaultAvoid::SavageAssaultAvoid(const QString &avoid_skill) : TriggerSkill("#sa_avoid_" + avoid_skill), avoid_skill(avoid_skill)
{
    events << CardEffected;
    frequency = Compulsory;
}

QStringList SavageAssaultAvoid::triggerable(TriggerEvent, Room *, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
{
    if (!player || !player->isAlive() || !player->hasSkill(avoid_skill)) return QStringList();
    CardEffectStruct effect = data.value<CardEffectStruct>();
    if (effect.card->isKindOf("SavageAssault"))
        return QStringList(objectName());

    return QStringList();
}

bool SavageAssaultAvoid::cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
{
    if (player->hasShownSkill(avoid_skill)) {
        room->sendCompulsoryTriggerLog(player, avoid_skill);
        room->broadcastSkillInvoke(avoid_skill, 1, player);
        return true;
    }
    if (player->askForSkillInvoke(avoid_skill)) {
        room->broadcastSkillInvoke(avoid_skill, 1, player);
        player->showGeneral(player->inHeadSkills(avoid_skill));
        return true;
    }
    return false;
}

bool SavageAssaultAvoid::effect(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
{
    LogMessage log;
    log.type = "#SkillNullify";
    log.from = player;
    log.arg = avoid_skill;
    log.arg2 = "savage_assault";
    room->sendLog(log);

    return true;
}

class Huoshou : public TriggerSkill
{
public:
    Huoshou() : TriggerSkill("huoshou")
    {
        events << TargetChosen << ConfirmDamage << CardFinished;
        frequency = Compulsory;
    }

    virtual QStringList triggerable(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer * &ask_who) const
    {
        if (player == NULL) return QStringList();
        if (triggerEvent == TargetChosen) {
            CardUseStruct use = data.value<CardUseStruct>();
            if (use.card->isKindOf("SavageAssault") && use.index == 0) {
                ServerPlayer *menghuo = room->findPlayerBySkillName(objectName());
                if (TriggerSkill::triggerable(menghuo) && use.from != menghuo) {
                    ask_who = menghuo;
                    return QStringList(objectName());
                }
            }
        } else if (triggerEvent == ConfirmDamage && !room->getTag("HuoshouSource").isNull()) {
            DamageStruct damage = data.value<DamageStruct>();
            if (!damage.card || !damage.card->isKindOf("SavageAssault"))
                return QStringList();

            ServerPlayer *menghuo = room->getTag("HuoshouSource").value<ServerPlayer *>();
            damage.from = menghuo->isAlive() ? menghuo : NULL;
            damage.by_user = false;
            data = QVariant::fromValue(damage);
        } else if (triggerEvent == CardFinished) {
            CardUseStruct use = data.value<CardUseStruct>();
            if (use.card->isKindOf("SavageAssault"))
                room->removeTag("HuoshouSource");
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *, QVariant &, ServerPlayer *ask_who) const
    {
        bool invoke = ask_who->hasShownSkill(this) ? true : ask_who->askForSkillInvoke(this);
        if (invoke) {
            room->broadcastSkillInvoke(objectName(), 2, ask_who);
            return true;
        }

        return false;
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *, QVariant &, ServerPlayer *ask_who) const
    {
        room->sendCompulsoryTriggerLog(ask_who, objectName());
        room->setTag("HuoshouSource", QVariant::fromValue(ask_who));

        return false;
    }
};

class Zaiqi : public TriggerSkill
{
public:
    Zaiqi() : TriggerSkill("zaiqi")
    {
        events << EventPhaseEnd;
    }

    virtual QStringList triggerable(TriggerEvent, Room *room, ServerPlayer *menghuo, QVariant &, ServerPlayer* &) const
    {
        if (!TriggerSkill::triggerable(menghuo) || menghuo->getPhase() != Player::Discard) return QStringList();

        QVariantList discardpile = room->getTag("GlobalRoundDisCardPile").toList();
        foreach (QVariant card_data, discardpile) {
            int card_id = card_data.toInt();
            if (Sanguosha->getCard(card_id)->isRed())
                return QStringList(objectName());
        }

        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        int x = 0;
        QVariantList discardpile = room->getTag("GlobalRoundDisCardPile").toList();
        foreach (QVariant card_data, discardpile) {
            int card_id = card_data.toInt();
            if (Sanguosha->getCard(card_id)->isRed())
                x++;
        }

        QList<ServerPlayer *> targets, allplayers = room->getAlivePlayers();

        foreach (ServerPlayer *p, allplayers) {
            if (player->isFriendWith(p))
                targets << p;
        }

        if (!targets.isEmpty()) {

            QList<ServerPlayer *> choosees = room->askForPlayersChosen(player, targets, objectName(),
                    0, x, "@zaiqi-target:::" + QString::number(x), true);

            if (choosees.length() > 0) {
                room->broadcastSkillInvoke(objectName(), player);
                QStringList target_list = player->tag["zaiqi_target"].toStringList();
                QStringList names;
                foreach (ServerPlayer *p, choosees) {
                    names << p->objectName();
                }
                target_list << names.join("+");
                player->tag["zaiqi_target"] = target_list;

                return true;
            }
        }

        return false;
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        QStringList target_list = player->tag["zaiqi_target"].toStringList();
        if (target_list.isEmpty()) return false;
        QStringList target_names = target_list.takeLast().split("+");
        player->tag["zaiqi_target"] = target_list;

        QList<ServerPlayer *> targets;
        foreach (QString name, target_names) {
            ServerPlayer *target = room->findPlayerbyobjectName(name);
            if (target)
                targets << target;
        }

        room->sortByActionOrder(targets);

        foreach (ServerPlayer *p, targets) {
            QStringList choices;
            choices << "drawcard";
            if (player->isAlive() && player->canRecover())
                choices << "recover";

            QString choice = room->askForChoice(p, "zaiqi", choices.join("+"), QVariant(),
                    "@zaiqi-choice:"+player->objectName(), "drawcard+recover");

            if (choice == "drawcard")
                p->drawCards(1, objectName());
            else {
                RecoverStruct recover;
                recover.who = p;
                room->recover(player, recover);
            }
        }
        return false;
    }
};

class Juxiang : public TriggerSkill
{
public:
    Juxiang() : TriggerSkill("juxiang")
    {
        events << CardFinished;
        frequency = Compulsory;
    }

    virtual TriggerList triggerable(TriggerEvent , Room *room, ServerPlayer *player, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (use.card->isKindOf("SavageAssault") && room->isAllOnPlace(use.card, Player::PlaceTable)) {
            QList<ServerPlayer *> zhurongs = room->findPlayersBySkillName(objectName());
            TriggerList skill_list;
            foreach (ServerPlayer *zhurong, zhurongs)
                if (zhurong != player)
                    skill_list.insert(zhurong, QStringList(objectName()));
            return skill_list;
        }
        return TriggerList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *, QVariant &data, ServerPlayer *zhurong) const
    {
        bool invoke = false;
        if (zhurong->hasShownSkill(objectName())) {
            invoke = true;
            room->sendCompulsoryTriggerLog(zhurong, objectName());
        } else
            invoke = zhurong->askForSkillInvoke(this, data);

        if (invoke) {
            room->broadcastSkillInvoke(objectName(), zhurong);
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent, Room *, ServerPlayer *, QVariant &data, ServerPlayer *zhurong) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        zhurong->obtainCard(use.card);
        return false;
    }
};

class Lieren : public TriggerSkill
{
public:
    Lieren() : TriggerSkill("lieren")
    {
        events << Damage;
    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *zhurong, QVariant &data, ServerPlayer* &) const
    {
        if (!TriggerSkill::triggerable(zhurong)) return QStringList();
        DamageStruct damage = data.value<DamageStruct>();
        if (damage.card && damage.card->isKindOf("Slash") && zhurong->canPindianTo(damage.to)
            && !damage.chain && !damage.transfer && !damage.to->hasFlag("Global_DFDebut"))
            return QStringList(objectName());
        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *zhurong, QVariant &data, ServerPlayer *) const
    {
        if (zhurong->askForSkillInvoke(this, data)) {
            DamageStruct damage = data.value<DamageStruct>();
            room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, zhurong->objectName(), damage.to->objectName());
            room->broadcastSkillInvoke(objectName(), zhurong);
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *zhurong, QVariant &data, ServerPlayer *) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        ServerPlayer *target = damage.to;
        if (target != NULL && zhurong->canPindianTo(target)) {
            bool success = zhurong->pindian(target, objectName());
            if (!success) return false;

            if (zhurong->canGetCard(target, "he")) {
                int card_id = room->askForCardChosen(zhurong, target, "he", objectName(), false, Card::MethodGet);
                CardMoveReason reason(CardMoveReason::S_REASON_EXTRACTION, zhurong->objectName());
                room->obtainCard(zhurong, Sanguosha->getCard(card_id), reason, false);
            }
        }
        return false;
    }
};

class Xiangle : public TriggerSkill
{
public:
    Xiangle() : TriggerSkill("xiangle")
    {
        events << TargetConfirmed;
        frequency = Compulsory;
    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (use.card->isKindOf("Slash") && TriggerSkill::triggerable(player))
            return QStringList(objectName());
        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (player->hasShownSkill(this) || player->askForSkillInvoke(this, data)) {
            room->broadcastSkillInvoke(objectName(), player);
            return true;
        }

        return false;
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *liushan, QVariant &data, ServerPlayer *) const
    {
        room->sendCompulsoryTriggerLog(liushan, objectName());
        CardUseStruct use = data.value<CardUseStruct>();

        QVariant dataforai = QVariant::fromValue(liushan);
        if (!room->askForCard(use.from, ".Basic", "@xiangle-discard:" + liushan->objectName(), dataforai)) {
            use.nullified_list << liushan->objectName();
            data = QVariant::fromValue(use);
        }

        return false;
    }
};

FangquanCard::FangquanCard()
{
    m_skillName = "_fangquan";
    mute = true;
}

bool FangquanCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.isEmpty() && to_select != Self;
}

void FangquanCard::onEffect(const CardEffectStruct &effect) const
{
    Room *room = effect.from->getRoom();
    ServerPlayer *player = effect.to;

    LogMessage log;
    log.type = "#Fangquan";
    log.to << player;
    room->sendLog(log);

    player->gainAnExtraTurn();
}

class FangquanAsk : public OneCardViewAsSkill
{
public:
    FangquanAsk() : OneCardViewAsSkill("fangquan_ask")
    {
        filter_pattern = ".|.|.|hand!";
        response_pattern = "@@fangquan_ask";
    }

    virtual const Card *viewAs(const Card *originalCard) const
    {
        FangquanCard *fangquan = new FangquanCard;
        fangquan->addSubcard(originalCard);
        return fangquan;
    }
};

class FangquanAfter : public TriggerSkill
{
public:
    FangquanAfter() : TriggerSkill("#fangquan-after")
    {
        events << EventPhaseChanging;
        frequency = Compulsory;
    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        PhaseChangeStruct change = data.value<PhaseChangeStruct>();
        if (change.to == Player::NotActive && player->hasFlag("fangquanInvoked") && !player->isKongcheng()) {
            return QStringList(objectName());
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        room->sendCompulsoryTriggerLog(player, "fangquan");
        room->broadcastSkillInvoke("fangquan", 2, player);
        return true;
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *liushan, QVariant &, ServerPlayer *) const
    {
        room->askForUseCard(liushan, "@@fangquan_ask", "@fangquan-discard", -1, Card::MethodDiscard);
        return false;
    }

};

class Fangquan : public TriggerSkill
{
public:
    Fangquan() : TriggerSkill("fangquan")
    {
        events << EventPhaseChanging;
    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        if (!TriggerSkill::triggerable(player)) return QStringList();
        PhaseChangeStruct change = data.value<PhaseChangeStruct>();
        return (change.to != Player::Play || player->isSkipped(Player::Play)) ? QStringList() : QStringList(objectName());
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        if (player->askForSkillInvoke(this)) {
            player->skip(Player::Play);
            room->broadcastSkillInvoke(objectName(), 1, player);
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent, Room *, ServerPlayer *liushan, QVariant &, ServerPlayer *) const
    {
        liushan->setFlags("fangquanInvoked");
        return false;
    }
};

class Shushen : public TriggerSkill
{
public:
    Shushen() : TriggerSkill("shushen")
    {
        events << HpRecover;
    }

    virtual bool canPreshow() const
    {
        return true;
    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        if (TriggerSkill::triggerable(player)) {

            QStringList trigger_list;
            RecoverStruct recover = data.value<RecoverStruct>();
            for (int i = 1; i <= recover.recover; i++) {
                trigger_list << objectName();
            }

            return trigger_list;
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        ServerPlayer *target = room->askForPlayerChosen(player, room->getOtherPlayers(player), objectName(), "shushen-invoke", true, true);
        if (target != NULL) {
            room->broadcastSkillInvoke(objectName(), player);

            QStringList target_list = player->tag["shushen_target"].toStringList();
            target_list.append(target->objectName());
            player->tag["shushen_target"] = target_list;

            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent, Room *, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        QStringList target_list = player->tag["shushen_target"].toStringList();
        QString target_name = target_list.last();
        target_list.removeLast();
        player->tag["shushen_target"] = target_list;

        ServerPlayer *to = NULL;

        foreach (ServerPlayer *p, player->getRoom()->getPlayers()) {
            if (p->objectName() == target_name) {
                to = p;
                break;
            }
        }
        if (to != NULL)
            to->drawCards(1);
        return false;
    }
};

class Shenzhi : public PhaseChangeSkill
{
public:
    Shenzhi() : PhaseChangeSkill("shenzhi")
    {
        frequency = Frequent;
    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *player, QVariant &, ServerPlayer * &) const
    {
        if (!PhaseChangeSkill::triggerable(player))
            return QStringList();
        if (player->getPhase() != Player::Start || player->isKongcheng())
            return QStringList();
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

    virtual bool onPhaseChange(ServerPlayer *ganfuren) const
    {
        int handcard_num = 0;
        foreach (const Card *card, ganfuren->getHandcards()) {
            if (!ganfuren->isJilei(card))
                handcard_num++;
        }
        ganfuren->throwAllHandCards();
        if (handcard_num >= ganfuren->getHp()) {
            RecoverStruct recover;
            recover.who = ganfuren;
            ganfuren->getRoom()->recover(ganfuren, recover);
        }
        return false;
    }
};

void StandardPackage::addShuGenerals()
{
    General *liubei = new General(this, "liubei", "shu"); // SHU 001
    liubei->addCompanion("guanyu");
    liubei->addCompanion("zhangfei");
    liubei->addCompanion("ganfuren");
    liubei->addSkill(new Rende);

    General *guanyu = new General(this, "guanyu", "shu", 5); // SHU 002
    guanyu->addSkill(new Wusheng);
    guanyu->addCompanion("zhangfei");

    General *zhangfei = new General(this, "zhangfei", "shu"); // SHU 003
    zhangfei->addSkill(new Paoxiao);
    zhangfei->addSkill(new PaoxiaoTarget);
    insertRelatedSkills("paoxiao", "#paoxiao-target");

    General *zhugeliang = new General(this, "zhugeliang", "shu", 3); // SHU 004
    zhugeliang->addCompanion("huangyueying");
    zhugeliang->addCompanion("jiangwei");
    zhugeliang->addCompanion("jiangwanfeiyi");
    zhugeliang->addSkill(new Guanxing);
    zhugeliang->addSkill(new Kongcheng);
    zhugeliang->addSkill(new DetachEffectSkill("kongcheng", "zither"));
    related_skills.insertMulti("kongcheng", "#kongcheng-clear");

    General *zhaoyun = new General(this, "zhaoyun", "shu"); // SHU 005
    zhaoyun->addCompanion("liushan");
    zhaoyun->addSkill(new Longdan);

    General *machao = new General(this, "machao", "shu"); // SHU 006
    machao->addSkill(new Mashu("machao"));
    machao->addSkill(new Tieqi);

    General *huangyueying = new General(this, "huangyueying", "shu", 3, false); // SHU 007
    huangyueying->addSkill(new Jizhi);
    huangyueying->addSkill(new Qicai);

    General *huangzhong = new General(this, "huangzhong", "shu"); // SHU 008
    huangzhong->addCompanion("weiyan");
    huangzhong->addSkill(new Liegong);

    General *weiyan = new General(this, "weiyan", "shu"); // SHU 009
    weiyan->addSkill(new Kuanggu);

    General *pangtong = new General(this, "pangtong", "shu", 3); // SHU 010
    pangtong->addSkill(new Lianhuan);
    pangtong->addSkill(new Niepan);

    General *wolong = new General(this, "wolong", "shu", 3); // SHU 011
    wolong->addCompanion("huangyueying");
    wolong->addCompanion("pangtong");
    wolong->addSkill(new Bazhen);
    wolong->addSkill(new Huoji);
    wolong->addSkill(new Kanpo);

    General *liushan = new General(this, "liushan", "shu", 3); // SHU 013
    liushan->addSkill(new Xiangle);
    liushan->addSkill(new Fangquan);
    liushan->addSkill(new FangquanAfter);
    insertRelatedSkills("fangquan", "#fangquan-after");

    General *menghuo = new General(this, "menghuo", "shu"); // SHU 014
    menghuo->addCompanion("zhurong");
    menghuo->addSkill(new SavageAssaultAvoid("huoshou"));
    menghuo->addSkill(new Huoshou);
    menghuo->addSkill(new Zaiqi);
    insertRelatedSkills("huoshou", "#sa_avoid_huoshou");

    General *zhurong = new General(this, "zhurong", "shu", 4, false); // SHU 015
    zhurong->addSkill(new SavageAssaultAvoid("juxiang"));
    zhurong->addSkill(new Juxiang);
    zhurong->addSkill(new Lieren);
    insertRelatedSkills("juxiang", "#sa_avoid_juxiang");

    General *ganfuren = new General(this, "ganfuren", "shu", 3, false); // SHU 016
    ganfuren->addSkill(new Shushen);
    ganfuren->addSkill(new Shenzhi);

    addMetaObject<RendeCard>();
    addMetaObject<FangquanCard>();

    skills << new RendeBasic << new WushengTargetMod << new LongdanSlash << new LongdanJink
           << new LongdanDraw << new LiegongTargetMod << new LiegongRange << new FangquanAsk;
}
