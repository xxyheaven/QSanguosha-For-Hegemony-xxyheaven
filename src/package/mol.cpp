/********************************************************************
    Copyright (c) 2013-2015 - Mogara

    This file is part of QSanguosha-Hegemony.

    This game is free software; you can redistribute it and/or
    modify it under the terms of the MOL General Public License as
    published by the Free Software Foundation; either version 3.0
    of the License, or (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    General Public License for more details.

    See the LICENSE file for more details.

    Mogara
    *********************************************************************/

#include "mol.h"
#include "standard-basics.h"
#include "standard-tricks.h"
#include "client.h"
#include "engine.h"
#include "structs.h"
#include "gamerule.h"
#include "settings.h"
#include "roomthread.h"
#include "json.h"



class Wuku : public TriggerSkill
{
public:
    Wuku() : TriggerSkill("wuku")
    {
        events << CardUsed << EventLoseSkill;
        frequency = Compulsory;
    }

    virtual void record(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (triggerEvent == EventLoseSkill && player && data.toString().split(":").first() == objectName()) {
            room->setPlayerMark(player, "#wuku", 0);
        }
    }

    virtual TriggerList triggerable(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (triggerEvent == CardUsed && player != NULL && player->hasShownOneGeneral()) {
            CardUseStruct use = data.value<CardUseStruct>();
            if (use.card->getTypeId() == Card::TypeEquip) {
                QList<ServerPlayer *> owners = room->findPlayersBySkillName(objectName());
                TriggerList skill_list;
                foreach (ServerPlayer *owner, owners)
                    if (owner->hasShownOneGeneral() && !player->isFriendWith(owner) && owner->getMark("#wuku") < 2)
                        skill_list.insert(owner, QStringList(objectName()));
                return skill_list;
            }
        }
        return TriggerList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *, QVariant &data, ServerPlayer *player) const
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

    virtual bool effect(TriggerEvent, Room *, ServerPlayer *, QVariant &, ServerPlayer *player) const
    {
        player->gainMark("#wuku");
        return false;
    }
};

MiewuCard::MiewuCard()
{
    will_throw = false;
}

bool MiewuCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    Card *mutable_card = Sanguosha->cloneCard(Self->tag["miewu"].toString());
    if (mutable_card) {
        mutable_card->addSubcards(subcards);
        mutable_card->setCanRecast(false);
        mutable_card->deleteLater();
    }
    return mutable_card && mutable_card->targetFilter(targets, to_select, Self) && !Self->isProhibited(to_select, mutable_card, targets);
}

bool MiewuCard::targetFixed() const
{
    Card *mutable_card = Sanguosha->cloneCard(Self->tag["miewu"].toString());
    if (mutable_card) {
        mutable_card->addSubcards(subcards);
        mutable_card->setCanRecast(false);
        mutable_card->deleteLater();
    }
    return mutable_card && mutable_card->targetFixed();
}

bool MiewuCard::targetsFeasible(const QList<const Player *> &targets, const Player *Self) const
{
    Card *mutable_card = Sanguosha->cloneCard(Self->tag["miewu"].toString());
    if (mutable_card) {
        mutable_card->addSubcards(subcards);
        mutable_card->setCanRecast(false);
        mutable_card->deleteLater();
    }

    return mutable_card && mutable_card->targetsFeasible(targets, Self);
}

const Card *MiewuCard::validate(CardUseStruct &card_use) const
{
    return validateInResponse(card_use.from);
}

const Card *MiewuCard::validateInResponse(ServerPlayer *user) const
{
    Room *room = user->getRoom();

    user->loseMark("#wuku");
    room->setPlayerFlag(user, "MiewuUsed");

    QString card_name = toString().split(":").last();   //getUserString() bug here. damn it!

    Card *c = Sanguosha->cloneCard(card_name);
    c->setSkillName("miewu");
    c->addSubcards(subcards);
    c->deleteLater();
    return c;
}

void MiewuCard::validateAfter(CardUseStruct &card_use) const
{
    validateInResponseAfter(card_use.from);
}

void MiewuCard::validateInResponseAfter(ServerPlayer *player) const
{
    player->drawCards(1, "miewu");
}

class MiewuViewAsSkill : public OneCardViewAsSkill
{
public:
    MiewuViewAsSkill() : OneCardViewAsSkill("miewu")
    {
        response_or_use = true;
    }

    virtual bool viewFilter(const Card *card) const
    {
        QString card_name = Self->tag["miewu"].toString();
        if (!card_name.isEmpty()) {
            Card *miewu_card = Sanguosha->cloneCard(card_name);
            miewu_card->addSubcard(card->getEffectiveId());
            miewu_card->setCanRecast(false);
            miewu_card->setSkillName(objectName());
            miewu_card->deleteLater();
            if (Sanguosha->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_PLAY)
                return miewu_card->isAvailable(Self);
            else if (Sanguosha->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE_USE)
                return !Self->isCardLimited(miewu_card, Card::MethodUse, Self->getHandcards().contains(card));
            else if (Sanguosha->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE)
                return !Self->isCardLimited(miewu_card, Card::MethodResponse, Self->getHandcards().contains(card));

        }
        return false;
    }

    virtual const Card *viewAs(const Card *originalCard) const
    {
        QString card_name = Self->tag["miewu"].toString();
        if (!card_name.isEmpty()) {
            MiewuCard *card = new MiewuCard;
            card->setUserString(card_name);
            card->addSubcard(originalCard);
            card->setShowSkill(objectName());
            return card;
        }
        return NULL;
    }

    virtual bool isEnabledAtPlay(const Player *player) const
    {
        return player->getMark("#wuku") > 0 && !player->hasFlag("MiewuUsed");
    }

    virtual bool isEnabledAtResponse(const Player *player, const QString &) const
    {
        return player->getMark("#wuku") > 0 && !player->hasFlag("MiewuUsed");
    }

    virtual bool isEnabledAtNullification(const ServerPlayer *player) const
    {
        return player->getMark("#wuku") > 0 && !player->hasFlag("MiewuUsed") && !player->isNude();
    }
};

class Miewu : public TriggerSkill
{
public:
    Miewu() : TriggerSkill("miewu")
    {
        guhuo_type = "btd";
        view_as_skill = new MiewuViewAsSkill;
    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *, QVariant &, ServerPlayer* &) const
    {
        return QStringList();
    }
};

GuishuCard::GuishuCard()
{
    will_throw = false;
}

bool GuishuCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    Card *mutable_card = Sanguosha->cloneCard(Self->tag["guishu"].toString());
    if (mutable_card) {
        mutable_card->addSubcards(subcards);
        mutable_card->setCanRecast(false);
        mutable_card->deleteLater();
    }
    return mutable_card && mutable_card->targetFilter(targets, to_select, Self) && !Self->isProhibited(to_select, mutable_card, targets);
}

bool GuishuCard::targetFixed() const
{
    Card *mutable_card = Sanguosha->cloneCard(getUserString());
    if (mutable_card) {
        mutable_card->addSubcards(subcards);
        mutable_card->setCanRecast(false);
        mutable_card->deleteLater();
    }
    return mutable_card && mutable_card->targetFixed();
}

bool GuishuCard::targetsFeasible(const QList<const Player *> &targets, const Player *Self) const
{
    Card *mutable_card = Sanguosha->cloneCard(Self->tag["guishu"].toString());
    if (mutable_card) {
        mutable_card->addSubcards(subcards);
        mutable_card->setCanRecast(false);
        mutable_card->deleteLater();
    }
    return mutable_card && mutable_card->targetsFeasible(targets, Self);
}

void GuishuCard::onUse(Room *room, const CardUseStruct &card_use) const
{
    ServerPlayer *source = card_use.from;
    QString card_name = toString().split(":").last();

    Card *use_card = Sanguosha->cloneCard(card_name);
    use_card->setSkillName("guishu");
    use_card->addSubcards(subcards);
    use_card->setCanRecast(false);
    use_card->setShowSkill("guishu");

    if (use_card->isAvailable(source)) {
        room->setPlayerProperty(source, "guishuprohibit", card_name);
        room->useCard(CardUseStruct(use_card, source, card_use.to));
    }
}

class GuishuViewAsSkill : public OneCardViewAsSkill
{
public:
    GuishuViewAsSkill() : OneCardViewAsSkill("guishu")
    {
        response_or_use = true;
    }

    virtual bool viewFilter(const Card *card) const
    {
        if (card->getSuit() != Card::Spade || card->isEquipped()) return false;
        QString card_name = Self->tag["guishu"].toString();
        if (!card_name.isEmpty()) {
            Card *guishu_card = Sanguosha->cloneCard(card_name);
            guishu_card->addSubcard(card->getEffectiveId());
            guishu_card->setCanRecast(false);
            guishu_card->setSkillName(objectName());
            guishu_card->deleteLater();
            return guishu_card->isAvailable(Self);
        }
        return false;
    }

    virtual const Card *viewAs(const Card *originalCard) const
    {
        QString c = Self->tag["guishu"].toString();
        if (c != "") {
            GuishuCard *card = new GuishuCard;
            card->addSubcard(originalCard);
            card->setUserString(c);
            return card;
        } else
            return NULL;
    }

    virtual bool isEnabledAtPlay(const Player *) const
    {
        return true;
    }
};

class Guishu : public TriggerSkill
{
public:
    Guishu() : TriggerSkill("guishu")
    {
        guhuo_type = "t";
        view_as_skill = new GuishuViewAsSkill;
    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *, QVariant &, ServerPlayer* &) const
    {
        return QStringList();
    }

    bool buttonEnabled(const QString &button_name, const QList<const Card *> &, const QList<const Player *> &) const
    {
        if (button_name.isEmpty()) return true;

        QStringList card_names;
        card_names << "befriend_attacking" << "known_both";

        if (!card_names.contains(button_name) || Self->property("guishuprohibit").toString() == button_name)
            return false;

        return Skill::buttonEnabled(button_name);
    }

};

class Yuanyu : public TriggerSkill
{
public:
    Yuanyu() : TriggerSkill("yuanyu")
    {
        events << DamageInflicted;
        frequency = Compulsory;
    }

    virtual int getPriority() const
    {
        return -2;
    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
    {
        if (!TriggerSkill::triggerable(player)) return QStringList();
        DamageStruct damage = data.value<DamageStruct>();
        if (damage.from && !player->isAdjacentTo(damage.from))
            return QStringList(objectName());
        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        bool invoke = false;
        if (player->hasShownSkill(this)) {
            room->sendCompulsoryTriggerLog(player, objectName());
            invoke = true;
        } else invoke = player->askForSkillInvoke(this, data);
        if (invoke) {
            room->broadcastSkillInvoke(objectName(), player);
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent, Room *, ServerPlayer *, QVariant &, ServerPlayer *) const
    {
        return true;
    }
};

class Sidi : public TriggerSkill
{
public:
    Sidi() : TriggerSkill("sidi")
    {
        events << Damaged << EventPhaseStart;
    }

    virtual void record(TriggerEvent , Room *room, ServerPlayer *player, QVariant &) const
    {
        if (player->getPhase() == Player::NotActive) {
            room->setPlayerMark(player, "#sidi+BasicCard", 0);
            room->setPlayerMark(player, "#sidi+EquipCard", 0);
            room->setPlayerMark(player, "#sidi+TrickCard", 0);

            QStringList skill_list = player->property("sidi_skills").toString().split("+");
            room->setPlayerProperty(player, "sidi_skills", QVariant());
            foreach (QString skill_name, skill_list) {
                room->setPlayerMark(player, "#sidi+" + skill_name, 0);
            }


        }
    }

    virtual TriggerList triggerable(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &) const
    {
        TriggerList skill_list;
        if (player == NULL || player->isDead()) return skill_list;
        if (triggerEvent == Damaged && player->getSeemingKingdom() == "wei" && !player->isNude()) {
            QList<ServerPlayer *> caozhens = room->findPlayersBySkillName(objectName());
            foreach (ServerPlayer *caozhen, caozhens) {
                skill_list.insert(caozhen, QStringList(objectName()));
            }
        } else if (triggerEvent == EventPhaseStart && player->getPhase() == Player::RoundStart
                   && player->getSeemingKingdom() != "wei") {
            QList<ServerPlayer *> caozhens = room->findPlayersBySkillName(objectName());
            foreach (ServerPlayer *caozhen, caozhens) {
                if (!caozhen->getPile("drive").isEmpty())
                    skill_list.insert(caozhen, QStringList(objectName()));
            }
        }
        return skill_list;
    }

    virtual bool cost(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *ask_who) const
    {
        bool invoke = false;
        if (triggerEvent == Damaged) {
            if (ask_who->askForSkillInvoke(this, QVariant::fromValue(player))) {
                room->broadcastSkillInvoke(objectName(), ask_who);
                room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, ask_who->objectName(), player->objectName());
                invoke = true;
            }
        } else if (triggerEvent == EventPhaseStart) {
            QList<int> ints = room->askForExchange(ask_who, objectName(), 3, 0, "@sidi-remove::"+player->objectName(), "drive");
            if (!ints.isEmpty()) {
                invoke = true;
                LogMessage log;
                log.type = "#InvokeSkill";
                log.from = ask_who;
                log.arg = objectName();
                room->sendLog(log);
                room->notifySkillInvoked(ask_who, objectName());
                room->broadcastSkillInvoke(objectName(), ask_who);
                room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, ask_who->objectName(), player->objectName());
                CardMoveReason reason(CardMoveReason::S_REASON_REMOVE_FROM_PILE, QString(), ask_who->objectName(), objectName(), QString());
                DummyCard dummy(ints);
                room->throwCard(&dummy, reason, NULL);
                room->setPlayerMark(ask_who, "sidi_times", ints.length());
            }

        }

        return invoke;
    }

    virtual bool effect(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *ask_who) const
    {
        if (triggerEvent == Damaged) {
            QList<int> ints = room->askForExchange(player, "sidi_put", 1, 1, "@sidi-put:"+ask_who->objectName());
            ask_who->addToPile("drive", ints);
        } else if (triggerEvent == EventPhaseStart) {
            int x = ask_who->getMark("sidi_times");
            room->setPlayerMark(ask_who, "sidi_times", 0);

            QStringList choices;
            choices << "cardlimit" << "skilllimit" << "recover";
            QStringList all_choices = choices;

            for (int i = 0; i < x; i++) {
                if (player->isDead() || ask_who->isDead() || choices.isEmpty()) break;
                QString choice = room->askForChoice(ask_who, "sidi_choice", choices.join("+"), QVariant(),
                                   "@sidi-choice::"+ player->objectName(), all_choices.join("+"));

                choices.removeOne(choice);

                if (choice == "recover") {
                    QList<ServerPlayer *> players = room->getAlivePlayers(), weis;
                    foreach (ServerPlayer *p, players) {
                        if (p->getSeemingKingdom() == "wei" && p->canRecover())
                            weis << p;
                    }
                    if (!weis.isEmpty()) {
                        ServerPlayer *to = room->askForPlayerChosen(player, weis, "sidi_recover", "@sidi-recover");
                        RecoverStruct recover;
                        recover.who = player;
                        room->recover(to, recover);
                    }
                }
                if (choice == "cardlimit") {
                    QString cardtype = room->askForChoice(ask_who, "sidi_cardtype", "BasicCard+EquipCard+TrickCard",
                                                         QVariant(), "@sidi-cardtype::"+player->objectName());
                    room->setPlayerCardLimitation(player, "use", cardtype, true);
                    room->addPlayerTip(player, "#sidi+"+cardtype);
                }
                if (choice == "skilllimit") {
                    QStringList skill_names;
                    if (player->hasShownGeneral1()) {
                        foreach (const Skill *skill, player->getActualGeneral1()->getVisibleSkillList()) {
                            skill_names << skill->objectName();
                        }
                    }
                    if (player->getGeneral2() && player->hasShownGeneral2()) {
                        foreach (const Skill *skill, player->getActualGeneral2()->getVisibleSkillList()) {
                            skill_names << skill->objectName();
                        }
                    }
                    if (!skill_names.isEmpty()) {
                        QString skill_name = room->askForChoice(ask_who, "sidi_skill", skill_names.join("+"),
                                                             QVariant(), "@sidi-skill::"+player->objectName());
                        room->addPlayerTip(player, "#sidi+" + skill_name);


                        QStringList assignee_list = player->property("sidi_skills").toString().split("+");
                        assignee_list << skill_name;
                        room->setPlayerProperty(player, "sidi_skills", assignee_list.join("+"));
                    }

                }
            }
        }

        return false;
    }
};

class SidiInvalidity : public InvaliditySkill
{
public:
    SidiInvalidity() : InvaliditySkill("#sidi-invalidity")
    {

    }

    virtual bool isSkillValid(const Player *target, const Skill *skill) const
    {
        QStringList sidi_list = target->property("sidi_skills").toString().split("+");
        return !sidi_list.contains(skill->objectName());
    }
};


class Dangxian : public TriggerSkill
{
public:
    Dangxian() : TriggerSkill("dangxian")
    {
        events << GeneralShown << EventPhaseStart;
        frequency = Compulsory;
    }

    virtual QStringList triggerable(TriggerEvent triggerEvent, Room *, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
    {
        if (!TriggerSkill::triggerable(player)) return QStringList();
        if (triggerEvent == GeneralShown) {
            if (player->cheakSkillLocation(objectName(), data.toBool())) {
                if ((data.toBool() && player->getMark("HaventShowGeneral") > 0)
                        || (!data.toBool() && player->getMark("HaventShowGeneral2") > 0))
                return QStringList(objectName());
            }
        } else if (triggerEvent == EventPhaseStart && player->getPhase() == Player::RoundStart) {
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

    virtual bool effect(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        if (triggerEvent == GeneralShown) {
            room->addPlayerMark(player, "@firstshow");
        } else if (triggerEvent == EventPhaseStart) {
            player->insertPhase(Player::Play);
        }
        return false;
    }
};

class Huanshi : public TriggerSkill
{
public:
    Huanshi() : TriggerSkill("huanshi")
    {
        events << AskForRetrial;
    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        if (!TriggerSkill::triggerable(player)) return QStringList();
        JudgeStruct *judge = data.value<JudgeStruct *>();
        if (!player->isFriendWith(judge->who)) return QStringList();
        if (player->isNude() && player->getHandPile().isEmpty()) return QStringList();
        return QStringList(objectName());
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        JudgeStruct *judge = data.value<JudgeStruct *>();

        QStringList prompt_list;
        prompt_list << "@huanshi-card" << judge->who->objectName()
            << objectName() << judge->reason << QString::number(judge->card->getEffectiveId());
        QString prompt = prompt_list.join(":");

        const Card *card = room->askForCard(player, "..", prompt, data, Card::MethodResponse, judge->who, true);

        if (card) {
            LogMessage log;
            log.type = "#InvokeSkill";
            log.from = player;
            log.arg = objectName();
            room->sendLog(log);

            LogMessage log2;
            log2.card_str = card->toString();
            log2.from = player;
            log2.type = QString("#%1_Resp").arg(card->getClassName());
            room->sendLog(log2);

            room->notifySkillInvoked(player, objectName());
            room->broadcastSkillInvoke(objectName(), player);

            int id = card->getEffectiveId();
            bool isHandcard = (room->getCardOwner(id) == player && room->getCardPlace(id) == Player::PlaceHand);

            CardMoveReason reason(CardMoveReason::S_REASON_RESPONSE, player->objectName(), objectName(), QString());

            room->moveCardTo(card, NULL, Player::PlaceTable, reason);

            CardResponseStruct resp(card, judge->who, false);
            resp.m_isHandcard = isHandcard;
            resp.m_data = data;
            QVariant _data = QVariant::fromValue(resp);
            room->getThread()->trigger(CardResponded, room, player, _data);

            QStringList card_list = player->tag["huanshi_cards"].toStringList();
            card_list.append(card->toString());
            player->tag["huanshi_cards"] = card_list;

            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        QStringList card_list = player->tag["huanshi_cards"].toStringList();

        if (card_list.isEmpty()) return false;

        QString card_str = card_list.takeLast();
        player->tag["huanshi_cards"] = card_list;

        const Card *card = Card::Parse(card_str);
        if (card) {
            JudgeStruct *judge = data.value<JudgeStruct *>();
            room->retrial(card, player, judge, objectName(), false);
            judge->updateResult();
        }
        return false;
    }
};


HongyuanCard::HongyuanCard()
{
    will_throw = false;
}

bool HongyuanCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    if (!targets.isEmpty() || to_select == Self)
        return false;
    if (!Self->hasShownOneGeneral())
        return !to_select->hasShownOneGeneral();
    return !to_select->isFriendWith(Self);
}

void HongyuanCard::extraCost(Room *room, const CardUseStruct &card_use) const
{
    ServerPlayer *target = card_use.to.first();
    if (target->hasShownOneGeneral())
        setFlags("hongyuanwilldraw");
    CardMoveReason reason(CardMoveReason::S_REASON_GIVE, card_use.from->objectName(), target->objectName(), "transfer", QString());
    room->obtainCard(target, this, reason);
}

void HongyuanCard::use(Room *, ServerPlayer *source, QList<ServerPlayer *> &) const
{
    if (hasFlag("hongyuanwilldraw"))
        source->drawCards(1, "transfer");
}

class HongyuanViewAsSkill : public OneCardViewAsSkill
{
public:
    HongyuanViewAsSkill() : OneCardViewAsSkill("hongyuan")
    {
        filter_pattern = ".|.|.|hand";
    }

    virtual bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("HongyuanCard");
    }

    virtual const Card *viewAs(const Card *originalCard) const
    {
        HongyuanCard *card = new HongyuanCard;
        card->addSubcard(originalCard);
        card->setSkillName(objectName());
        card->setShowSkill(objectName());
        return card;
    }
};

class Hongyuan : public TriggerSkill
{
public:
    Hongyuan() : TriggerSkill("hongyuan")
    {
        events << BeforeCardsMove;
        view_as_skill = new HongyuanViewAsSkill;
    }

    virtual QStringList triggerable(TriggerEvent , Room *room, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
    {
        if (TriggerSkill::triggerable(player)) {
            QVariantList move_datas = data.toList();
            foreach (QVariant move_data, move_datas) {
                CardsMoveOneTimeStruct move = move_data.value<CardsMoveOneTimeStruct>();
                if (move.to == player && move.to_place == Player::PlaceHand && move.reason.m_reason == CardMoveReason::S_REASON_DRAW
                        && move.reason.m_skillName == "transfer") {
                    QList<ServerPlayer *> all_players = room->getOtherPlayers(player);
                    foreach (ServerPlayer *p, all_players) {
                        if (player->isFriendWith(p))
                            return QStringList(objectName());
                    }
                }
            }
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        QList<ServerPlayer *> to_choose, all_players = room->getOtherPlayers(player);
        foreach (ServerPlayer *p, all_players) {
            if (player->isFriendWith(p))
                to_choose << p;
        }
        if (to_choose.isEmpty()) return false;

        ServerPlayer *to = room->askForPlayerChosen(player, to_choose, objectName(), "hongyuan-invoke", true, true);
        if (to != NULL) {
            room->broadcastSkillInvoke(objectName(), player);

            QStringList target_list = player->tag["hongyuan_target"].toStringList();
            target_list.append(to->objectName());
            player->tag["hongyuan_target"] = target_list;
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        QStringList target_list = player->tag["hongyuan_target"].toStringList();
        QString target_name = target_list.takeLast();
        player->tag["hongyuan_target"] = target_list;

        ServerPlayer *to = room->findPlayerbyobjectName(target_name);

        if (to) {
            QVariantList move_datas = data.toList();
            QVariantList new_datas;
            foreach (QVariant move_data, move_datas) {
                CardsMoveOneTimeStruct move = move_data.value<CardsMoveOneTimeStruct>();
                if (move.to == player && move.to_place == Player::PlaceHand && move.reason.m_reason == CardMoveReason::S_REASON_DRAW
                        && move.reason.m_skillName == "transfer") {
                    move.to = to;
                }
                new_datas << QVariant::fromValue(move);
            }
            data = QVariant::fromValue(new_datas);
        }
        return false;
    }
};

class Mingzhe : public TriggerSkill
{
public:
    Mingzhe() : TriggerSkill("mingzhe")
    {
        events  << CardsMoveOneTime << CardUsed << CardResponded;
        frequency = Frequent;
    }

    virtual QStringList triggerable(TriggerEvent triggerEvent, Room *, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        if (!TriggerSkill::triggerable(player) || player->getPhase() != Player::NotActive) return QStringList();
        if (triggerEvent == CardUsed || triggerEvent == CardResponded) {
            const Card *cardstar = NULL;
            if (triggerEvent == CardUsed) {
                CardUseStruct use = data.value<CardUseStruct>();
                cardstar = use.card;
            } else {
                CardResponseStruct resp = data.value<CardResponseStruct>();
                cardstar = resp.m_card;
            }
            if (cardstar && cardstar->getTypeId() != Card::TypeSkill && cardstar->isRed())
                return QStringList(objectName());

        } else if (triggerEvent == CardsMoveOneTime) {
            QVariantList move_datas = data.toList();
            QStringList trigger_list;
            foreach (QVariant move_data, move_datas) {
                CardsMoveOneTimeStruct move = move_data.value<CardsMoveOneTimeStruct>();
                if (move.from == player && move.from_places.contains(Player::PlaceEquip)) {
                    for (int i = 0; i < move.card_ids.length(); ++i) {
                        const Card *card = Card::Parse(move.cards.at(i));
                        if (card && card->isRed() && move.from_places.at(i) == Player::PlaceEquip) {
                            trigger_list << objectName();
                        }
                    }
                }
            }

            return trigger_list;
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
        player->drawCards(1, objectName());
        return false;
    }
};

class Qinzhong : public PhaseChangeSkill
{
public:
    Qinzhong() : PhaseChangeSkill("qinzhong")
    {
        relate_to_place = "deputy";
    }

    virtual QStringList triggerable(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer* &) const
    {
        if (!PhaseChangeSkill::triggerable(player)) return QStringList();
        if (player->getPhase() == Player::RoundStart) {
            QList<ServerPlayer *> allplayers = room->getOtherPlayers(player);
            foreach (ServerPlayer *p, allplayers) {
                if (p->isFriendWith(player) && p->getGeneral2())
                    return QStringList(objectName());
            }
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        QList<ServerPlayer *> to_choose, all_players = room->getOtherPlayers(player);
        foreach (ServerPlayer *p, all_players) {
            if (player->isFriendWith(p) && p->getGeneral2())
                to_choose << p;
        }
        if (to_choose.isEmpty()) return false;

        ServerPlayer *to = room->askForPlayerChosen(player, to_choose, objectName(), "qinzhong-invoke", true, true);
        if (to != NULL) {
            room->broadcastSkillInvoke(objectName(), player);

            QStringList target_list = player->tag["qinzhong_target"].toStringList();
            target_list.append(to->objectName());
            player->tag["qinzhong_target"] = target_list;
            return true;
        }
        return false;
    }

    virtual bool onPhaseChange(ServerPlayer *player) const
    {
        QStringList target_list = player->tag["qinzhong_target"].toStringList();
        QString target_name = target_list.takeLast();
        player->tag["qinzhong_target"] = target_list;
        Room *room = player->getRoom();
        ServerPlayer *target = room->findPlayerbyobjectName(target_name);
        if (target == NULL) return false;

        QString name1 = player->getActualGeneral2Name();
        QString name2 = target->getActualGeneral2Name();

        player->removeGeneral(false);
        target->removeGeneral(false);

        if (!name2.contains("sujiang"))
            room->transformDeputyGeneral(player, name2);

        if (!name1.contains("sujiang"))
            room->transformDeputyGeneral(target, name1);

        return false;
    }
};

ZhaofuCard::ZhaofuCard()
{
}

bool ZhaofuCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.isEmpty() && to_select != Self && to_select->getMark("#reward") == 0;
}

void ZhaofuCard::onEffect(const CardEffectStruct &effect) const
{
    QVariantList effect_list = effect.from->tag["zhaofuTag"].toList();
    effect_list << QVariant::fromValue(effect);
    effect.from->tag["zhaofuTag"] = effect_list;
}

ZhaofuVSCard::ZhaofuVSCard()
{
    will_throw = false;
}

bool ZhaofuVSCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    Card *mutable_card = Sanguosha->cloneCard(Self->property("zhaofucard").toString(), Card::NoSuit, 0);
    if (mutable_card) {
        mutable_card->setSkillName("_zhaofu");
        mutable_card->setCanRecast(false);
        mutable_card->deleteLater();
    }

    return mutable_card && mutable_card->targetFilter(targets, to_select, Self) && !Self->isProhibited(to_select, mutable_card, targets);
}

bool ZhaofuVSCard::targetFixed() const
{
    Card *mutable_card = Sanguosha->cloneCard(Self->property("zhaofucard").toString(), Card::NoSuit, 0);
    if (mutable_card) {
        mutable_card->setSkillName("_zhaofu");
        mutable_card->setCanRecast(false);
        mutable_card->deleteLater();
    }
    return mutable_card && mutable_card->targetFixed();
}

bool ZhaofuVSCard::targetsFeasible(const QList<const Player *> &targets, const Player *Self) const
{
    Card *mutable_card = Sanguosha->cloneCard(Self->property("zhaofucard").toString(), Card::NoSuit, 0);
    if (mutable_card) {
        mutable_card->setSkillName("_zhaofu");
        mutable_card->setCanRecast(false);
        mutable_card->deleteLater();
    }
    return mutable_card && mutable_card->targetsFeasible(targets, Self);
}

void ZhaofuVSCard::onUse(Room *, const CardUseStruct &card_use) const
{
    ServerPlayer *source = card_use.from;
    QVariantList use_list = source->tag["zhaofuUseTag"].toList();
    use_list << QVariant::fromValue(card_use);
    source->tag["zhaofuUseTag"] = use_list;
}

class ZhaofuViewAsSkill : public ViewAsSkill
{
public:
    ZhaofuViewAsSkill() : ViewAsSkill("zhaofu")
    {

    }

    virtual bool isEnabledAtPlay(const Player *) const
    {
        return false;
    }

    virtual bool isEnabledAtResponse(const Player *, const QString &pattern) const
    {
        return pattern.startsWith("@@zhaofu");
    }

    virtual bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const
    {
        if (Sanguosha->currentRoomState()->getCurrentCardUsePattern().endsWith("1"))
            return selected.isEmpty() && !Self->isJilei(to_select);
        else
            return false;
    }

    virtual const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (Sanguosha->currentRoomState()->getCurrentCardUsePattern().endsWith("1")) {
            if (cards.length() == 1) {
                ZhaofuCard *zhaofuCard = new ZhaofuCard;
                zhaofuCard->addSubcards(cards);
                return zhaofuCard;
            }
        } else if (cards.isEmpty()) {
            return new ZhaofuVSCard;
        }
        return NULL;
    }
};

class Zhaofu : public TriggerSkill
{
public:
    Zhaofu() : TriggerSkill("zhaofu")
    {
        events << EventPhaseStart << CardFinished;
        view_as_skill = new ZhaofuViewAsSkill;
    }

    virtual bool canPreshow() const
    {
        return true;
    }

    virtual TriggerList triggerable(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        TriggerList skill_list;
        if (triggerEvent == EventPhaseStart && TriggerSkill::triggerable(player)) {
            if (player->getPhase() == Player::Play && !player->isNude()) {
                QList<ServerPlayer *> allplayers = room->getAlivePlayers();
                int x = 0;
                bool has_target = false;
                foreach (ServerPlayer *p, allplayers) {
                    if (p->getMark("#reward") > 0) {
                        x++;
                    } else if (p != player)
                        has_target = true;
                }

                if (has_target && x < 3)
                    skill_list.insert(player, QStringList(objectName()));
            }
        } else if (triggerEvent == CardFinished && player->getMark("#reward") > 0) {
            CardUseStruct use = data.value<CardUseStruct>();
            if (use.card->getTypeId() == Card::TypeBasic || use.card->isNDTrick()) {
                Card *new_card = Sanguosha->cloneCard(use.card->objectName(), Card::NoSuit, 0);
                new_card->setSkillName("_zhaofu");
                new_card->deleteLater();

                QList<ServerPlayer *> owners = room->findPlayersBySkillName(objectName());
                foreach (ServerPlayer *owner, owners) {
                    if (new_card->isAvailable(owner))
                        skill_list.insert(owner, QStringList(objectName()));
                }
            }

        }
        return skill_list;
    }

    virtual bool cost(TriggerEvent triggerEvent, Room *room, ServerPlayer *target, QVariant &data, ServerPlayer *player) const
    {
        if (triggerEvent == EventPhaseStart) {
            return room->askForUseCard(player, "@@zhaofu1", "@zhaofu1", -1, Card::MethodDiscard);
        } else if (triggerEvent == CardFinished) {
            CardUseStruct use = data.value<CardUseStruct>();
            if (use.card->targetFixed()) {
                if (player->askForSkillInvoke(objectName(), "prompt:::"+use.card->objectName())) {
                    room->broadcastSkillInvoke(objectName(), player);
                    room->removePlayerMark(target, "#reward");

                    QVariantList use_list = player->tag["zhaofuUseTag"].toList();
                    use_list << QVariant::fromValue(CardUseStruct());
                    player->tag["zhaofuUseTag"] = use_list;

                    return true;
                }
            } else {
                room->setPlayerProperty(player, "zhaofucard", use.card->objectName());
                bool invoke = room->askForUseCard(player, "@@zhaofu2", "@zhaofu2:::"+use.card->objectName(), -1, Card::MethodNone);
                room->setPlayerProperty(player, "zhaofucard", QVariant());
                if (invoke) {
                    LogMessage log;
                    log.type = "#InvokeSkill";
                    log.from = player;
                    log.arg = objectName();
                    room->sendLog(log);
                    room->notifySkillInvoked(player, objectName());
                    room->broadcastSkillInvoke(objectName(), player);
                    room->removePlayerMark(target, "#reward");
                    return true;
                }
            }
        }

        return false;
    }

    virtual bool effect(TriggerEvent triggerEvent, Room *room, ServerPlayer *, QVariant &data, ServerPlayer *player) const
    {
        if (triggerEvent == EventPhaseStart) {
            QVariantList data_list = player->tag["zhaofuTag"].toList();
            QVariant zhaofu_data = data_list.takeLast();
            CardEffectStruct effect = zhaofu_data.value<CardEffectStruct>();
            ServerPlayer *target = effect.to;
            if (target)
                room->addPlayerTip(target, "#reward");
        } else if (triggerEvent == CardFinished) {
            CardUseStruct use = data.value<CardUseStruct>();
            QVariantList data_list = player->tag["zhaofuUseTag"].toList();
            QVariant zhaofu_data = data_list.takeLast();
            CardUseStruct zhaofu_use = zhaofu_data.value<CardUseStruct>();

            Card *zhaofu_card = Sanguosha->cloneCard(use.card->objectName(), Card::NoSuit, 0);
            if (zhaofu_card) {
                zhaofu_card->setSkillName("_zhaofu");
                zhaofu_card->setCanRecast(false);
                zhaofu_card->deleteLater();
            }

            room->useCard(CardUseStruct(zhaofu_card, player, zhaofu_use.to));


        }
        return false;
    }

    virtual int getEffectIndex(const ServerPlayer *, const Card *card) const
    {
        return (card->getTypeId() == Card::TypeSkill) ? -1 : 0;
    }
};







MOLPackage::MOLPackage()
    : Package("MOL")
{
    General *duyu = new General(this, "duyu", "qun");
    duyu->addSkill(new Wuku);
    duyu->addSkill(new Miewu);



    addMetaObject<MiewuCard>();
}

OverseasPackage::OverseasPackage()
    : Package("overseas")
{
    General *beimihu = new General(this, "beimihu", "qun", 3, false);
    beimihu->addSkill(new Guishu);
    beimihu->addSkill(new Yuanyu);

    General *caozhen = new General(this, "caozhen", "wei");
    caozhen->addSkill(new Sidi);
    caozhen->addSkill(new SidiInvalidity);
    caozhen->addSkill(new DetachEffectSkill("sidi", "drive"));
    insertRelatedSkills("sidi", 2, "#sidi-invalidity", "#sidi-clear");
    caozhen->addCompanion("caopi");

    General *liaohua = new General(this, "liaohua", "shu");
    liaohua->addSkill(new Dangxian);

    General *zhugejin = new General(this, "zhugejin", "wu", 3);
    zhugejin->addSkill(new Huanshi);
    zhugejin->addSkill(new Hongyuan);
    zhugejin->addSkill(new Mingzhe);

    General *quancong = new General(this, "quancong", "wu");
    quancong->addSkill(new Qinzhong);
    quancong->addSkill(new Zhaofu);


    zhugejin->addCompanion("sunquan");



    addMetaObject<GuishuCard>();
    addMetaObject<HongyuanCard>();
    addMetaObject<ZhaofuCard>();
    addMetaObject<ZhaofuVSCard>();
}

