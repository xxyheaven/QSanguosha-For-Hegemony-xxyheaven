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

#include "standard-wei-generals.h"
#include "skill.h"
#include "engine.h"
#include "standard-basics.h"
#include "standard-tricks.h"
#include "client.h"
#include "settings.h"
#include "roomthread.h"

class Jianxiong : public MasochismSkill
{
public:
    Jianxiong() : MasochismSkill("jianxiong")
    {
        frequency = Frequent;
    }

    virtual QStringList triggerable(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        if (MasochismSkill::triggerable(player)) {
            DamageStruct damage = data.value<DamageStruct>();
            const Card *card = damage.card;
            if (damage.card == NULL)
                return QStringList();

            QList<int> table_cardids = room->getCardIdsOnTable(card);

            return (table_cardids.length() != 0 && card->getSubcards() == table_cardids) ? QStringList(objectName()) : QStringList();
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

    virtual void onDamaged(ServerPlayer *player, const DamageStruct &damage) const
    {
        player->obtainCard(damage.card);
    }
};

class Fankui : public MasochismSkill
{
public:
    Fankui() : MasochismSkill("fankui")
    {
    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *simayi, QVariant &data, ServerPlayer * &) const
    {
        if (MasochismSkill::triggerable(simayi)) {
            ServerPlayer *from = data.value<DamageStruct>().from;
            return (from && simayi->canGetCard(from, "he")) ? QStringList(objectName()) : QStringList();
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *simayi, QVariant &data, ServerPlayer *) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        if (!damage.from->isNude() && simayi->askForSkillInvoke(this, data)) {
            room->broadcastSkillInvoke(objectName(), simayi);
            room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, simayi->objectName(), damage.from->objectName());
            return true;
        }
        return false;
    }

    virtual void onDamaged(ServerPlayer *simayi, const DamageStruct &damage) const
    {
        Room *room = simayi->getRoom();
        int card_id = room->askForCardChosen(simayi, damage.from, "he", objectName(), false, Card::MethodGet);
        CardMoveReason reason(CardMoveReason::S_REASON_EXTRACTION, simayi->objectName());
        room->obtainCard(simayi, Sanguosha->getCard(card_id), reason, false);
    }
};

class Guicai : public TriggerSkill
{
public:
    Guicai() : TriggerSkill("guicai")
    {
        events << AskForRetrial;
    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *player, QVariant &, ServerPlayer * &) const
    {
        if (!TriggerSkill::triggerable(player)) return QStringList();
        if (player->isNude() && player->getHandPile().isEmpty())
            return QStringList();
        return QStringList(objectName());
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        JudgeStruct *judge = data.value<JudgeStruct *>();

        QStringList prompt_list;
        prompt_list << "@guicai-card" << judge->who->objectName()
            << objectName() << judge->reason << QString::number(judge->card->getEffectiveId());
        QString prompt = prompt_list.join(":");

        const Card *card = room->askForCard(player, "..", prompt, data, Card::MethodResponse, judge->who, true);

        if (card) {
            room->broadcastSkillInvoke(objectName(), player);
            room->retrial(card, player, judge, objectName());
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent, Room *, ServerPlayer *, QVariant &data, ServerPlayer *) const
    {
        JudgeStruct *judge = data.value<JudgeStruct *>();
        judge->updateResult();
        return false;
    }
};

class Ganglie : public TriggerSkill
{
public:
    Ganglie() : TriggerSkill("ganglie")
    {
        events << Damaged << FinishJudge;
    }

    virtual void record(TriggerEvent triggerEvent, Room *, ServerPlayer *, QVariant &data) const
    {
        if (triggerEvent == FinishJudge) {
            JudgeStruct *judge = data.value<JudgeStruct *>();
            if (judge->reason == objectName()) {
               judge->pattern = judge->card->isRed() ? "red" : (judge->card->isBlack() ? "black" : "no_suit");
            }
        }
    }

    virtual QStringList triggerable(TriggerEvent triggerEvent, Room *, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
    {
        if (triggerEvent != Damaged || !TriggerSkill::triggerable(player)) return QStringList();
        DamageStruct damage = data.value<DamageStruct>();
        QStringList trigger_skill;
        for (int i = 1; i <= damage.damage; i++)
            trigger_skill << objectName();
        return trigger_skill;
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (player->askForSkillInvoke(this, data)) {
            DamageStruct damage = data.value<DamageStruct>();
            if (damage.from != NULL)
                room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, player->objectName(), damage.from->objectName());
            room->broadcastSkillInvoke(objectName(), player);
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *xiahou, QVariant &data, ServerPlayer *) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        ServerPlayer *from = damage.from;
        if (xiahou->isDead()) return false;

        JudgeStruct judge;
        judge.pattern = ".|heart";
        judge.good = false;
        judge.reason = objectName();
        judge.who = xiahou;

        room->judge(judge);

        if (judge.pattern == "red") {
            if (from && from->isAlive() && xiahou->isAlive())
                room->damage(DamageStruct(objectName(), xiahou, from));
        } else if (judge.pattern == "black") {
            if (from && from->isAlive() && xiahou->isAlive() && xiahou->canDiscard(from, "he")) {
                CardMoveReason reason = CardMoveReason(CardMoveReason::S_REASON_DISMANTLE, xiahou->objectName(),
                                                       from->objectName(), objectName(), NULL);
                int id = room->askForCardChosen(xiahou, from, "he", objectName(), false, Card::MethodDiscard);
                room->throwCard(Sanguosha->getCard(id), reason, from, xiahou);
            }

        }
        return false;
    }
};

Tuxi::Tuxi(const QString &owner) : DrawCardsSkill("tuxi" + owner)
{
}

QStringList Tuxi::triggerable(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
{
    if (!DrawCardsSkill::triggerable(player) || player->getPhase() != Player::Draw) return QStringList();
    if (data.toInt() < 1) return QStringList();
    QList<ServerPlayer *> other_players = room->getOtherPlayers(player);
    foreach (ServerPlayer *p, other_players) {
        if (player->canGetCard(p, "h")) {
            return QStringList(objectName());
        }
    }
    return QStringList();
}

bool Tuxi::cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
{
    QList<ServerPlayer *> to_choose;
    foreach(ServerPlayer *p, room->getOtherPlayers(player)) {
        if (player->canGetCard(p, "h"))
            to_choose << p;
    }

    int x = data.toInt();
    QList<ServerPlayer *> choosees = room->askForPlayersChosen(player, to_choose, objectName(), 0, x, "@tuxi-card:::" + QString::number(x), true);
    if (choosees.length() > 0) {
        room->sortByActionOrder(choosees);
        player->tag["tuxi_invoke"] = QVariant::fromValue(choosees);
        room->broadcastSkillInvoke(objectName(), player);
        return true;
    }

    return false;
}

int Tuxi::getDrawNum(ServerPlayer *source, int n) const
{
    Room *room = source->getRoom();
    QList<ServerPlayer *> targets = source->tag["tuxi_invoke"].value<QList<ServerPlayer *> >();
    source->tag.remove("tuxi_invoke");

    foreach (ServerPlayer *target, targets) {
        if (!source->canGetCard(target, "h")) continue;
        int card_id = room->askForCardChosen(source, target, "h", "tuxi", false, Card::MethodGet);
        CardMoveReason reason(CardMoveReason::S_REASON_EXTRACTION, source->objectName());
        room->obtainCard(source, Sanguosha->getCard(card_id), reason, false);
    }

    return n - targets.length();
}

class Luoyi : public TriggerSkill
{
public:
    Luoyi() : TriggerSkill("luoyi")
    {
        events << DrawNCards << PreCardUsed;
    }

    virtual QStringList triggerable(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        if (triggerEvent == DrawNCards) {
            if (TriggerSkill::triggerable(player) && data.toInt() > 0)
                return QStringList(objectName());
        } else {
            if (player != NULL && player->isAlive() && player->hasFlag("luoyi")) {
                CardUseStruct use = data.value<CardUseStruct>();
                if (use.card != NULL && (use.card->isKindOf("Slash") || use.card->isKindOf("Duel"))) {
                    room->setCardFlag(use.card, objectName());
                }
            }
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (player->askForSkillInvoke(this)) {
            data = data.toInt() - 1;
            room->broadcastSkillInvoke(objectName(), player);
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        room->setPlayerFlag(player, objectName());

        return false;
    }
};

class LuoyiDamage : public TriggerSkill
{
public:
    LuoyiDamage() : TriggerSkill("#luoyi-damage")
    {
        events << DamageCaused;
        frequency = Skill::Compulsory;
    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        if (player != NULL && player->isAlive() && player->hasFlag("luoyi")) {
            DamageStruct damage = data.value<DamageStruct>();
            if (damage.card != NULL && damage.card->hasFlag("luoyi") && !damage.chain && !damage.transfer && damage.by_user) {
                return QStringList(objectName());
            }
        }
        return QStringList();
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        LogMessage log;
        log.type = "#LuoyiBuff";
        log.from = player;
        log.to << damage.to;
        log.arg = QString::number(damage.damage);
        log.arg2 = QString::number(++damage.damage);
        room->sendLog(log);

        data = QVariant::fromValue(damage);

        return false;
    }
};

class Tiandu : public TriggerSkill
{
public:
    Tiandu() : TriggerSkill("tiandu")
    {
        frequency = Frequent;
        events << FinishJudge;
    }

    virtual QStringList triggerable(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        JudgeStruct *judge = data.value<JudgeStruct *>();
        if (room->getCardPlace(judge->card->getEffectiveId()) == Player::PlaceJudge && TriggerSkill::triggerable(player))
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

    virtual bool effect(TriggerEvent, Room *, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        JudgeStruct *judge = data.value<JudgeStruct *>();
        player->obtainCard(judge->card);
        return false;
    }
};

class Yiji : public MasochismSkill
{
public:
    Yiji() : MasochismSkill("yiji")
    {
        frequency = Frequent;
    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *player, QVariant &, ServerPlayer* &) const
    {
        if (TriggerSkill::triggerable(player))
            return QStringList(objectName());

        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *guojia, QVariant &data, ServerPlayer *) const
    {
        if (guojia->askForSkillInvoke(this, data)) {
            room->broadcastSkillInvoke(objectName(), guojia);
            return true;
        }

        return false;
    }

    virtual void onDamaged(ServerPlayer *guojia, const DamageStruct &) const
    {
        Room *room = guojia->getRoom();

        QList<ServerPlayer *> _guojia;
        _guojia.append(guojia);
        QList<int> yiji_cards = room->getNCards(2, false);

        CardMoveReason preview_reason(CardMoveReason::S_REASON_PREVIEW, guojia->objectName(), objectName(), QString());

        CardsMoveStruct move(yiji_cards, NULL, guojia, Player::PlaceTable, Player::PlaceHand, preview_reason);
        QList<CardsMoveStruct> moves;
        moves.append(move);
        room->notifyMoveCards(true, moves, false, _guojia);
        room->notifyMoveCards(false, moves, false, _guojia);
        QList<int> origin_yiji = yiji_cards;
        while (room->askForYiji(guojia, yiji_cards, objectName(), true, false, true, -1, room->getAlivePlayers())) {
            CardsMoveStruct move(QList<int>(), guojia, NULL, Player::PlaceHand, Player::PlaceTable, preview_reason);
            foreach (int id, origin_yiji) {
                if (room->getCardPlace(id) != Player::DrawPile) {
                    move.card_ids << id;
                    yiji_cards.removeOne(id);
                }
            }
            origin_yiji = yiji_cards;
            QList<CardsMoveStruct> moves;
            moves.append(move);
            room->notifyMoveCards(true, moves, false, _guojia);
            room->notifyMoveCards(false, moves, false, _guojia);
            if (!guojia->isAlive())
                return;
        }

        if (!yiji_cards.isEmpty()) {
            CardsMoveStruct move(yiji_cards, guojia, NULL, Player::PlaceHand, Player::PlaceTable, preview_reason);
            QList<CardsMoveStruct> moves;
            moves.append(move);
            room->notifyMoveCards(true, moves, false, _guojia);
            room->notifyMoveCards(false, moves, false, _guojia);


            foreach (int id, yiji_cards) {
                guojia->obtainCard(Sanguosha->getCard(id), false);
            }
        }
    }
};

class Luoshen : public TriggerSkill
{
public:
    Luoshen() : TriggerSkill("luoshen")
    {
        events << EventPhaseStart;
        frequency = Frequent;
    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *player, QVariant &, ServerPlayer * &) const
    {
        if (player->getPhase() == Player::Start) {
            if (TriggerSkill::triggerable(player))
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

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *zhenji, QVariant &, ServerPlayer *) const
    {
        JudgeStruct judge;
        judge.pattern = ".|black";
        judge.good = true;
        judge.reason = objectName();
        judge.who = zhenji;

        QList<int> card_list;
        do {
            room->judge(judge);
            if (judge.isGood())
                card_list.append(judge.card->getEffectiveId());
            else
                break;
        } while (zhenji->askForSkillInvoke(this, QVariant(), false));

        QList<int> subcards;
        foreach(int id, card_list)
            if (room->getCardPlace(id) == Player::PlaceJudge && !subcards.contains(id))
                subcards << id;
        if (subcards.length() != 0) {
            DummyCard dummy(subcards);
            zhenji->obtainCard(&dummy);
        }

        return false;
    }
};

class Qingguo : public OneCardViewAsSkill
{
public:
    Qingguo() : OneCardViewAsSkill("qingguo")
    {
        filter_pattern = ".|black|.|hand";
        response_pattern = "jink";
        response_or_use = true;
    }

    virtual const Card *viewAs(const Card *originalCard) const
    {
        Jink *jink = new Jink(originalCard->getSuit(), originalCard->getNumber());
        jink->setSkillName(objectName());
        jink->addSubcard(originalCard->getId());
        jink->setShowSkill(objectName());
        return jink;
    }
};

ShensuCard::ShensuCard()
{
    mute = true;
}

bool ShensuCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    Slash *slash = new Slash(NoSuit, 0);
    slash->setSkillName("shensu");
    slash->setFlags("Global_NoDistanceChecking");
    slash->deleteLater();
    return slash->targetFilter(targets, to_select, Self);
}

void ShensuCard::use(Room *, ServerPlayer *source, QList<ServerPlayer *> &targets) const
{
    if (targets.length() > 0) {
        QString index = "2";
        if (Sanguosha->currentRoomState()->getCurrentCardUsePattern().endsWith("1"))
            index = "1";

        QVariantList target_list;
        foreach (ServerPlayer *target, targets) {
            target_list << QVariant::fromValue(target);
        }

        source->tag["shensu_invoke" + index] = target_list;
        source->setFlags("shensu" + index);
    }
}

class ShensuViewAsSkill : public ViewAsSkill
{
public:
    ShensuViewAsSkill() : ViewAsSkill("shensu")
    {
    }

    virtual bool isEnabledAtPlay(const Player *) const
    {
        return false;
    }

    virtual bool isEnabledAtResponse(const Player *, const QString &pattern) const
    {
        return pattern.startsWith("@@shensu");
    }

    virtual bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const
    {
        if (Sanguosha->currentRoomState()->getCurrentCardUsePattern().endsWith("1"))
            return false;
        else
            return selected.isEmpty() && to_select->isKindOf("EquipCard") && !Self->isJilei(to_select);
    }

    virtual const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (Sanguosha->currentRoomState()->getCurrentCardUsePattern().endsWith("1")) {
            if (cards.isEmpty()) {
                ShensuCard *shensu = new ShensuCard;
                return shensu;
            }
        } else if (cards.length() == 1) {
            ShensuCard *card = new ShensuCard;
            card->addSubcards(cards);
            return card;
        }
        return NULL;
    }
};

class Shensu : public TriggerSkill
{
public:
    Shensu() : TriggerSkill("shensu")
    {
        events << EventPhaseChanging;
        view_as_skill = new ShensuViewAsSkill;
    }

    virtual bool canPreshow() const
    {
        return true;
    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *xiahouyuan, QVariant &data, ServerPlayer * &) const
    {
        if (!TriggerSkill::triggerable(xiahouyuan))
            return QStringList();
        if (!Slash::IsAvailable(xiahouyuan))
            return QStringList();

        PhaseChangeStruct change = data.value<PhaseChangeStruct>();
        if (change.to == Player::Judge && !xiahouyuan->isSkipped(Player::Judge) && !xiahouyuan->isSkipped(Player::Draw)) {
            xiahouyuan->tag.remove("shensu_invoke1");
            return QStringList(objectName());
        } else if (change.to == Player::Play && xiahouyuan->canDiscard(xiahouyuan, "he") && !xiahouyuan->isSkipped(Player::Play)) {
            xiahouyuan->tag.remove("shensu_invoke2");
            return QStringList(objectName());
        }

        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *xiahouyuan, QVariant &data, ServerPlayer *) const
    {
        PhaseChangeStruct change = data.value<PhaseChangeStruct>();
        if (change.to == Player::Judge && room->askForUseCard(xiahouyuan, "@@shensu1", "@shensu1", 1)) {
            if (xiahouyuan->hasFlag("shensu1") && xiahouyuan->tag.contains("shensu_invoke1")) {
                xiahouyuan->skip(Player::Judge);
                xiahouyuan->skip(Player::Draw);
                return true;
            }
        } else if (change.to == Player::Play && room->askForUseCard(xiahouyuan, "@@shensu2", "@shensu2", 2, Card::MethodDiscard)) {
            if (xiahouyuan->hasFlag("shensu2") && xiahouyuan->tag.contains("shensu_invoke2")) {
                xiahouyuan->skip(Player::Play);
                return true;
            }
        }
        return false;
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        PhaseChangeStruct change = data.value<PhaseChangeStruct>();
        QVariantList target_list;
        if (change.to == Player::Judge) {
            target_list = player->tag["shensu_invoke1"].toList();
            player->tag.remove("shensu_invoke1");
        } else {
            target_list = player->tag["shensu_invoke2"].toList();
            player->tag.remove("shensu_invoke2");
        }

        Slash *slash = new Slash(Card::NoSuit, 0);
        slash->setSkillName("_shensu");
        QList<ServerPlayer *> targets;
        foreach (QVariant x, target_list) {
            targets << x.value<ServerPlayer *>();
        }

        room->useCard(CardUseStruct(slash, player, targets));
        return false;
    }

    virtual int getEffectIndex(const ServerPlayer *, const Card *card) const
    {
        return card->getSubcards().length() + 1;
    }
};

QiaobianAskCard::QiaobianAskCard()
{
    mute = true;
}

bool QiaobianAskCard::targetsFeasible(const QList<const Player *> &targets, const Player *Self) const
{
    Player::Phase phase = (Player::Phase)Self->getMark("qiaobianPhase");
    if (phase == Player::Draw)
        return targets.length() <= 2 && !targets.isEmpty();
    else if (phase == Player::Play)
        return targets.length() == 2;
    return false;
}

bool QiaobianAskCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    Player::Phase phase = (Player::Phase)Self->getMark("qiaobianPhase");
    if (phase == Player::Draw)
        return targets.length() < 2 && to_select != Self && Self->canGetCard(to_select, "h");
    else if (phase == Player::Play) {
        if (targets.isEmpty())
            return (!to_select->getJudgingArea().isEmpty() || !to_select->getEquips().isEmpty());
        else if (targets.length() == 1){
            for (int i = 0; i < S_EQUIP_AREA_LENGTH; i++) {
                if (targets.first()->getEquip(i) && !to_select->getEquip(i))
                    return true;
            }
            foreach(const Card *card, targets.first()->getJudgingArea()){
                if (!Sanguosha->isProhibited(NULL, to_select, card))
                    return true;
            }

        }
    }
    return false;
}

void QiaobianAskCard::onUse(Room *room, const CardUseStruct &card_use) const
{
    CardUseStruct use = card_use;
    ServerPlayer *zhanghe = use.from;
    Player::Phase phase = (Player::Phase)zhanghe->getMark("qiaobianPhase");
    if (phase == Player::Draw) {
        if (use.to.isEmpty())
            return;

        room->sortByActionOrder(use.to);
        foreach (ServerPlayer *p, use.to) {
            room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, zhanghe->objectName(), p->objectName());
        }
        foreach (ServerPlayer *target, use.to) {
            if (zhanghe->isAlive() && target->isAlive())
                room->cardEffect(this, zhanghe, target);
        }
    } else if (phase == Player::Play) {
        if (use.to.length() != 2)
            return;

        ServerPlayer *from = use.to.first();
        ServerPlayer *to = use.to.last();

        bool can_select = false;
        QList<int> disabled_ids;
        for (int i = 0; i < S_EQUIP_AREA_LENGTH; i++) {
            if (from->getEquip(i)){
                if (!to->getEquip(i))
                    can_select = true;
                else
                    disabled_ids << from->getEquip(i)->getEffectiveId();
            }
        }

        foreach(const Card *card, from->getJudgingArea()){
            if (!Sanguosha->isProhibited(NULL, to, card))
                can_select = true;
            else
                disabled_ids << card->getEffectiveId();
        }

        if (can_select) {
            int card_id = room->askForCardChosen(zhanghe, from, "ej", "qiaobian", false, Card::MethodNone, disabled_ids);
            room->moveCardTo(Sanguosha->getCard(card_id), from, to, room->getCardPlace(card_id), CardMoveReason(CardMoveReason::S_REASON_TRANSFER, zhanghe->objectName(), "qiaobian", QString()));
        }
    }
}

void QiaobianAskCard::onEffect(const CardEffectStruct &effect) const
{
   Room *room = effect.from->getRoom();
    if (effect.from->canGetCard(effect.to, "h")) {
        int card_id = room->askForCardChosen(effect.from, effect.to, "h", "qiaobian", false, Card::MethodGet);
        CardMoveReason reason(CardMoveReason::S_REASON_EXTRACTION, effect.from->objectName());
        room->obtainCard(effect.from, Sanguosha->getCard(card_id), reason, false);
    }
}

class QiaobianAsk : public ZeroCardViewAsSkill
{
public:
    QiaobianAsk() : ZeroCardViewAsSkill("qiaobian_ask")
    {
        response_pattern = "@@qiaobian_ask";
    }

    virtual const Card *viewAs() const
    {
        return new QiaobianAskCard;
    }
};

Qiaobian::Qiaobian(const QString &owner) : TriggerSkill("qiaobian" + owner)
{
    events << EventPhaseChanging;
}

QStringList Qiaobian::triggerable(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
{
    PhaseChangeStruct change = data.value<PhaseChangeStruct>();
    room->setPlayerMark(player, "qiaobianPhase", (int)change.to);
    int index = 0;
    switch (change.to) {
        case Player::RoundStart:
        case Player::Start:
        case Player::Finish:
        case Player::NotActive: return QStringList();

        case Player::Judge: index = 1; break;
        case Player::Draw: index = 2; break;
        case Player::Play: index = 3; break;
        case Player::Discard: index = 4; break;
        case Player::PhaseNone: Q_ASSERT(false);
    }
    if (TriggerSkill::triggerable(player) && index > 0 && !player->isKongcheng() && !player->isSkipped(change.to))
        return QStringList(objectName());
    return QStringList();
}

bool Qiaobian::cost(TriggerEvent, Room *room, ServerPlayer *zhanghe, QVariant &data, ServerPlayer *) const
{
    PhaseChangeStruct change = data.value<PhaseChangeStruct>();
    static QStringList phase_strings;
    if (phase_strings.isEmpty())
        phase_strings << "round_start" << "start" << "judge" << "draw"
        << "play" << "discard" << "finish" << "not_active";
    int index = static_cast<int>(change.to);

    QString discard_prompt = QString("#qiaobian:::%1").arg(phase_strings[index]);

    if (room->askForDiscard(zhanghe, objectName(), 1, 1, true, false, discard_prompt, true)) {
        room->broadcastSkillInvoke(objectName(), zhanghe);
        return true;
    }
    return false;
}

bool Qiaobian::effect(TriggerEvent, Room *room, ServerPlayer *zhanghe, QVariant &data, ServerPlayer *) const
{
    PhaseChangeStruct change = data.value<PhaseChangeStruct>();
    zhanghe->skip(change.to);
    int index = 0;
    switch (change.to) {
        case Player::RoundStart:
        case Player::Start:
        case Player::Finish:
        case Player::NotActive: return false;

        case Player::Judge: index = 1; break;
        case Player::Draw: index = 2; break;
        case Player::Play: index = 3; break;
        case Player::Discard: index = 4; break;
        case Player::PhaseNone: Q_ASSERT(false);
    }
    if (index == 2 || index == 3) {
        QString use_prompt = QString("@qiaobian-%1").arg(index);
        room->askForUseCard(zhanghe, "@@qiaobian_ask", use_prompt, index);
    }
    return false;
}

class Duanliang : public OneCardViewAsSkill
{
public:
    Duanliang() : OneCardViewAsSkill("duanliang")
    {
        filter_pattern = "BasicCard,EquipCard|black";
        response_or_use = true;
    }

    virtual bool isEnabledAtPlay(const Player *xuhuang) const
    {
        return !xuhuang->hasFlag("DuanliangCannot");
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

class JushouSelect : public OneCardViewAsSkill
{
public:
    JushouSelect() : OneCardViewAsSkill("jushou_select")
    {
        response_pattern = "@@jushou_select!";
    }

    bool viewFilter(const Card *to_select) const
    {
        if (to_select->isEquipped()) return false;
        if (to_select->getTypeId() == Card::TypeEquip)
            return to_select->isAvailable(Self);
        return !Self->isJilei(to_select);
    }

    virtual const Card *viewAs(const Card *originalCard) const
    {
        DummyCard *select = new DummyCard;
        select->addSubcard(originalCard);
        return select;
    }
};

class Jushou : public PhaseChangeSkill
{
public:
    Jushou() : PhaseChangeSkill("jushou")
    {
        frequency = Frequent;
    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *player, QVariant &, ServerPlayer * &) const
    {
        return (PhaseChangeSkill::triggerable(player) && player->getPhase() == Player::Finish) ? QStringList(objectName()) : QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (player->askForSkillInvoke(this, data)) {
            room->broadcastSkillInvoke(objectName(), player);
            return true;
        }
        return false;
    }

    virtual bool onPhaseChange(ServerPlayer *caoren) const
    {
        Room *room = caoren->getRoom();
        QList<ServerPlayer *> to_count, players = room->getAlivePlayers();
        foreach (ServerPlayer *p, players) {
            if (!p->hasShownOneGeneral()) continue;
            bool no_friend = true;
            foreach (ServerPlayer *p2, to_count) {
                if (p2->isFriendWith(p)) {
                    no_friend = false;
                    break;
                }
            }
            if (no_friend)
                to_count << p;
        }

        int x = to_count.length();

        caoren->drawCards(x, objectName());

        const Card *card = NULL;
        foreach (int id, caoren->handCards()) {
            const Card *c = Sanguosha->getCard(id);
            if (JushouFilter(caoren, c)) {
                card = c;
                break;
            }
        }
        if (card == NULL) return false;
        const Card *to_select = room->askForCard(caoren, "@@jushou_select!", "@jushou", QVariant(), Card::MethodNone);
        if (to_select != NULL)
            card = Sanguosha->getCard(to_select->getEffectiveId());
        if (card->getTypeId() == Card::TypeEquip)
            room->useCard(CardUseStruct(card, caoren, caoren));
        else
            room->throwCard(card, caoren);
        if (x > 2)
            caoren->turnOver();
        return false;
    }

private:

    static bool JushouFilter(ServerPlayer *caoren, const Card *to_select)
    {
        if (to_select->getTypeId() == Card::TypeEquip)
            return to_select->isAvailable(caoren);
        return !caoren->isJilei(to_select);
    }
};

QiangxiCard::QiangxiCard()
{
}

bool QiangxiCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    if (!targets.isEmpty() || to_select == Self)
        return false;

    int rangefix = 0;
    if (!subcards.isEmpty() && Self->getWeapon() && Self->getWeapon()->getId() == subcards.first()) {
        const Weapon *card = qobject_cast<const Weapon *>(Self->getWeapon()->getRealCard());
        rangefix += card->getRange() - 1;
    }
    int distance = Self->distanceTo(to_select, rangefix);
    if (distance == -1)
        return false;
    return distance <= Self->getAttackRange();
}

void QiangxiCard::extraCost(Room *room, const CardUseStruct &card_use) const
{
    if (card_use.card->getSubcards().isEmpty())
        room->loseHp(card_use.from);

    SkillCard::extraCost(room, card_use);
}

void QiangxiCard::onEffect(const CardEffectStruct &effect) const
{
    effect.to->getRoom()->damage(DamageStruct("qiangxi", effect.from, effect.to));
}

class Qiangxi : public ViewAsSkill
{
public:
    Qiangxi() : ViewAsSkill("qiangxi")
    {
    }

    virtual bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("QiangxiCard");
    }

    virtual bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const
    {
        return selected.isEmpty() && to_select->isKindOf("Weapon") && !Self->isJilei(to_select);
    }

    virtual const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (cards.isEmpty()) {
            QiangxiCard *card = new QiangxiCard;
            card->setShowSkill(objectName());
            return card;
        } else if (cards.length() == 1) {
            QiangxiCard *card = new QiangxiCard;
            card->addSubcards(cards);
            card->setShowSkill(objectName());
            return card;
        } else
            return NULL;
    }

    virtual int getEffectIndex(const ServerPlayer *, const Card *card) const
    {
        return 2 - card->subcardsLength();
    }
};

QuhuCard::QuhuCard()
{
}

bool QuhuCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.isEmpty() && to_select->getHp() > Self->getHp() && Self->canPindianTo(to_select);
}

void QuhuCard::onEffect(const CardEffectStruct &effect) const
{
    if (effect.from->canPindianTo(effect.to)) {
        bool success = effect.from->pindian(effect.to, "quhu");
        Room *room = effect.to->getRoom();
        if (success) {
            QList<ServerPlayer *> players = room->getOtherPlayers(effect.to), wolves;
            foreach (ServerPlayer *player, players) {
                if (effect.to->inMyAttackRange(player))
                    wolves << player;
            }

            if (wolves.isEmpty()) {
                LogMessage log;
                log.type = "#QuhuNoWolf";
                log.from = effect.from;
                log.to << effect.to;
                room->sendLog(log);

                return;
            }

            ServerPlayer *wolf = room->askForPlayerChosen(effect.from, wolves, "quhu", QString("@quhu-damage:%1").arg(effect.to->objectName()));

            room->damage(DamageStruct("quhu", effect.to, wolf));
        } else {
            room->damage(DamageStruct("quhu", effect.to, effect.from));
        }
    }
}

class Quhu : public ZeroCardViewAsSkill
{
public:
    Quhu() : ZeroCardViewAsSkill("quhu")
    {
    }

    virtual bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("QuhuCard") && !player->isKongcheng();
    }

    virtual const Card *viewAs() const
    {
        QuhuCard *card = new QuhuCard;
        card->setShowSkill(objectName());
        return card;
    }
};

class Jieming : public MasochismSkill
{
public:
    Jieming() : MasochismSkill("jieming")
    {

    }

    virtual QStringList triggerable(TriggerEvent , Room *, ServerPlayer *player, QVariant &, ServerPlayer * &) const
    {
        if (TriggerSkill::triggerable(player))
            return QStringList(objectName());

        return QStringList();
    }


    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        if (!player->isAlive())
            return false;

        ServerPlayer *target = room->askForPlayerChosen(player, room->getAlivePlayers(), objectName(), "jieming-invoke", true, true);
        if (target != NULL) {
            room->broadcastSkillInvoke(objectName(), (target == player ? 2 : 1), player);

            QStringList target_list = player->tag["jieming_target"].toStringList();
            target_list.append(target->objectName());
            player->tag["jieming_target"] = target_list;

            return true;
        }
        return false;
    }

    virtual void onDamaged(ServerPlayer *xunyu, const DamageStruct &) const
    {
        QStringList target_list = xunyu->tag["jieming_target"].toStringList();
        QString target_name = target_list.last();
        target_list.removeLast();
        xunyu->tag["jieming_target"] = target_list;

        ServerPlayer *to = NULL;

        foreach (ServerPlayer *p, xunyu->getRoom()->getPlayers()) {
            if (p->objectName() == target_name) {
                to = p;
                break;
            }
        }

        if (to != NULL) {
            int upper = qMin(5, to->getMaxHp());
            int x = upper - to->getHandcardNum();
            if (x > 0)
                to->drawCards(x);
        }
    }
};

class Xingshang : public TriggerSkill
{
public:
    Xingshang() : TriggerSkill("xingshang")
    {
        events << Death;
        frequency = Frequent;
    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        DeathStruct death = data.value<DeathStruct>();
        ServerPlayer *dead = death.who;
        if (dead->isNude() || player == dead)
            return QStringList();
        return (TriggerSkill::triggerable(player) && player->isAlive()) ? QStringList(objectName()) : QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (player->askForSkillInvoke(this, data)) {
            room->broadcastSkillInvoke(objectName(), player);
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *caopi, QVariant &data, ServerPlayer *) const
    {
        DeathStruct death = data.value<DeathStruct>();
        ServerPlayer *player = death.who;
        if (player->isNude() || caopi == player)
            return false;
        DummyCard dummy(player->handCards());
        dummy.addSubcards(player->getEquips());
        if (dummy.subcardsLength() > 0) {
            CardMoveReason reason(CardMoveReason::S_REASON_RECYCLE, caopi->objectName());
            room->obtainCard(caopi, &dummy, reason, false);
        }
        return false;
    }
};

class Fangzhu : public MasochismSkill
{
public:
    Fangzhu() : MasochismSkill("fangzhu")
    {
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        ServerPlayer *to = room->askForPlayerChosen(player, room->getOtherPlayers(player), objectName(),
                "fangzhu-invoke", true, true);
        if (to != NULL) {
            room->broadcastSkillInvoke(objectName(), player);
            //player->tag["fangzhu_invoke"] = QVariant::fromValue(to);
            QStringList target_list = player->tag["fangzhu_target"].toStringList();
            target_list.append(to->objectName());
            player->tag["fangzhu_target"] = target_list;
            return true;
        }
        return false;
    }

    virtual void onDamaged(ServerPlayer *caopi, const DamageStruct &) const
    {
        //ServerPlayer *to = caopi->tag["fangzhu_invoke"].value<ServerPlayer *>();
        QStringList target_list = caopi->tag["fangzhu_target"].toStringList();
        QString target_name = target_list.last();
        target_list.removeLast();
        caopi->tag["fangzhu_target"] = target_list;
        ServerPlayer *to = NULL;
        foreach (ServerPlayer *p, caopi->getRoom()->getAllPlayers()) {
            if (p->objectName() == target_name) {
                to = p;
                break;
            }
        }

        if (to) {
            Room *room = caopi->getRoom();
            if (room->askForDiscard(to, "fangzhu_discard", 1, 1, true, true, "@fangzhu-discard:::"+QString::number(caopi->getLostHp())))
                room->loseHp(to);
            else {
                to->turnOver();
                if (caopi->isAlive() && caopi->isWounded())
                    to->drawCards(caopi->getLostHp(), objectName());
            }

        }
    }
};

Xiaoguo::Xiaoguo(const QString &owner) : PhaseChangeSkill("xiaoguo" + owner)
{
}

TriggerList Xiaoguo::triggerable(TriggerEvent , Room *room, ServerPlayer *player, QVariant &) const
{
    TriggerList skill_list;
    if (player != NULL && player->getPhase() == Player::Finish) {
        QList<ServerPlayer *> yuejins = room->findPlayersBySkillName(objectName());
        foreach (ServerPlayer *yuejin, yuejins) {
            if (yuejin != NULL && player != yuejin && !yuejin->isKongcheng())
                skill_list.insert(yuejin, QStringList(objectName()));
        }
    }
    return skill_list;
}

bool Xiaoguo::cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *ask_who) const
{
    if (room->askForCard(ask_who, ".Basic", "@xiaoguo:"+player->objectName(), QVariant(), objectName())) {
        room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, ask_who->objectName(), player->objectName());
        room->broadcastSkillInvoke(objectName(), ask_who);
        return true;
    }
    return false;
}

bool Xiaoguo::effect(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *ask_who) const
{
    if (!room->askForCard(player, ".Equip", "@xiaoguo-discard", QVariant()))
        room->damage(DamageStruct("xiaoguo", ask_who, player));

    return false;
}

bool Xiaoguo::onPhaseChange(ServerPlayer *) const
{
    return false;
}

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
        CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
        if (move.from == player && move.from_places.contains(Player::PlaceHand)
                && move.to && move.to != move.from && move.to_place == Player::PlaceHand
                && move.reason.m_reason != CardMoveReason::S_REASON_SWAP) {
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

    int card_id = room->askForCardChosen(source, target, "h", "daoshu", false, Card::MethodGet);
    const Card *card = Sanguosha->getCard(card_id);
    CardMoveReason reason(CardMoveReason::S_REASON_EXTRACTION, source->objectName());
    room->obtainCard(source, card, reason, true);

    QString suit_str = card->getSuitString();
    if (suit == card->getSuit()) {
        room->damage(DamageStruct("daoshu", source, target));
        room->addPlayerHistory(source, getClassName(), -1);
    } else {
        const Card *to_give = NULL;
        foreach (const Card *c, source->getHandcards()) {
            if (c->getSuitString() != suit_str) {
                to_give = c;
                break;
            }
        }
        if (to_give == NULL) {
            room->showAllCards(source);
            return;
        }
        room->setPlayerProperty(source, "DaoshuSuit", suit_str);
        const Card *select = room->askForCard(source, ".|^" + suit_str + "|.|hand!", "@daoshu-give::" + target->objectName()
                                              + ":" + suit_str, QVariant(), Card::MethodNone);
        room->setPlayerProperty(source, "DaoshuSuit", QVariant());

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

void StandardPackage::addWeiGenerals()
{
    General *caocao = new General(this, "caocao", "wei"); // WEI 001
    caocao->addCompanion("dianwei");
    caocao->addCompanion("xuchu");
    caocao->addSkill(new Jianxiong);

    General *simayi = new General(this, "simayi", "wei", 3); // WEI 002
    simayi->addSkill(new Fankui);
    simayi->addSkill(new Guicai);

    General *xiahoudun = new General(this, "xiahoudun", "wei"); // WEI 003
    xiahoudun->addCompanion("xiahouyuan");
    xiahoudun->addSkill(new Ganglie);

    General *zhangliao = new General(this, "zhangliao", "wei"); // WEI 004
    zhangliao->addSkill(new Tuxi);

    General *xuchu = new General(this, "xuchu", "wei"); // WEI 005
    xuchu->addSkill(new Luoyi);
    xuchu->addSkill(new LuoyiDamage);
    insertRelatedSkills("luoyi", "#luoyi-damage");

    General *guojia = new General(this, "guojia", "wei", 3); // WEI 006
    guojia->addSkill(new Tiandu);
    guojia->addSkill(new Yiji);

    General *zhenji = new General(this, "zhenji", "wei", 3, false); // WEI 007
    zhenji->addSkill(new Qingguo);
    zhenji->addSkill(new Luoshen);

    General *xiahouyuan = new General(this, "xiahouyuan", "wei"); // WEI 008
    xiahouyuan->addSkill(new Shensu);

    General *zhanghe = new General(this, "zhanghe", "wei"); // WEI 009
    zhanghe->addSkill(new Qiaobian);

    General *xuhuang = new General(this, "xuhuang", "wei"); // WEI 010
    xuhuang->addSkill(new Duanliang);

    General *caoren = new General(this, "caoren", "wei"); // WEI 011
    caoren->addSkill(new Jushou);

    General *dianwei = new General(this, "dianwei", "wei"); // WEI 012
    dianwei->addSkill(new Qiangxi);

    General *xunyu = new General(this, "xunyu", "wei", 3); // WEI 013
    xunyu->addSkill(new Quhu);
    xunyu->addSkill(new Jieming);

    General *caopi = new General(this, "caopi", "wei", 3); // WEI 014
    caopi->addCompanion("zhenji");
    caopi->addSkill(new Xingshang);
    caopi->addSkill(new Fangzhu);

    General *yuejin = new General(this, "yuejin", "wei", 4); // WEI 016
    yuejin->addSkill(new Xiaoguo);

    General *jianggan = new General(this, "jianggan", "wei", 3); // WEI EXTRA
    jianggan->addSkill(new Weicheng);
    jianggan->addSkill(new Daoshu);

    addMetaObject<ShensuCard>();
    addMetaObject<QiaobianAskCard>();
    addMetaObject<QiangxiCard>();
    addMetaObject<QuhuCard>();
    addMetaObject<DaoshuCard>();

    skills << new JushouSelect << new QiaobianAsk;
}
