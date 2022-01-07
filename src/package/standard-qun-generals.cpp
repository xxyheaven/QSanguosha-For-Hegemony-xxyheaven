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

#include "standard-qun-generals.h"
#include "skill.h"
#include "standard-basics.h"
#include "standard-tricks.h"
#include "standard-shu-generals.h"
#include "engine.h"
#include "client.h"
#include "settings.h"
#include "roomthread.h"

class Jijiu : public OneCardViewAsSkill
{
public:
    Jijiu() : OneCardViewAsSkill("jijiu")
    {
        filter_pattern = ".|red";
        response_or_use = true;
    }

    virtual bool isEnabledAtPlay(const Player *) const
    {
        return false;
    }

    virtual bool isEnabledAtResponse(const Player *player, const QString &pattern) const
    {
        return pattern.contains("peach") && !player->hasFlag("Global_PreventPeach") && player->getPhase() == Player::NotActive;
    }

    virtual const Card *viewAs(const Card *originalCard) const
    {
        Peach *peach = new Peach(originalCard->getSuit(), originalCard->getNumber());
        peach->addSubcard(originalCard->getId());
        peach->setSkillName(objectName());
        peach->setShowSkill(objectName());
        return peach;
    }
};

ChuliCard::ChuliCard()
{
    will_throw = false;
    handling_method = Card::MethodNone;
}

bool ChuliCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    if (to_select == Self || targets.length() > 2 || !Self->canDiscard(to_select, "he")) return false;
    if (!to_select->hasShownOneGeneral()) return true;
    foreach (const Player *p, targets) {
        if (to_select->isFriendWith(p))
            return false;
    }
    return true;
}

void ChuliCard::use(Room *room, ServerPlayer *player, QList<ServerPlayer *> &targets) const
{
    QList<ServerPlayer *> drawers;
    targets << player;
    room->sortByActionOrder(targets);
    foreach (ServerPlayer *p, targets) {
        if (player->canDiscard(p, "he") && player->isAlive()) {
            int to_throw = room->askForCardChosen(player, p, "he", "chuli", false, Card::MethodDiscard);
            CardMoveReason reason(CardMoveReason::S_REASON_DISMANTLE, player->objectName(), p->objectName(), "chuli", QString());
            CardsMoveStruct dis_move(to_throw, NULL, Player::DiscardPile, reason);
            QList<CardsMoveOneTimeStruct> moveOneTimes = room->moveCardsSub(dis_move, true);
            bool is_spade = false;
            foreach (CardsMoveOneTimeStruct move, moveOneTimes) {
                if (move.from == p && move.reason.m_reason == CardMoveReason::S_REASON_DISMANTLE) {
                    for (int i = 0; i < move.card_ids.length(); ++i) {
                        const Card *card = Card::Parse(move.cards.at(i));
                        if (card && card->getSuit() == Card::Spade
                                && (move.from_places.at(i) == Player::PlaceHand || move.from_places.at(i) == Player::PlaceEquip)) {
                            is_spade = true;
                            break;
                        }
                    }
                }
            }
            if (is_spade)
                drawers << p;
        }
    }

    foreach (ServerPlayer *p, drawers) {
        if (p->isAlive())
            p->drawCards(1, "chuli");
    }

}

class Chuli : public ZeroCardViewAsSkill
{
public:
    Chuli() : ZeroCardViewAsSkill("chuli")
    {

    }

    virtual bool isEnabledAtPlay(const Player *player) const
    {
        return player->canDiscard(player, "he") && !player->hasUsed("ChuliCard");
    }

    virtual const Card *viewAs() const
    {
        ChuliCard *chuli_card = new ChuliCard;
        chuli_card->setShowSkill(objectName());
        return chuli_card;
    }
};

class Qingnang : public ZeroCardViewAsSkill
{
public:
    Qingnang() : ZeroCardViewAsSkill("qingnang")
    {

    }

    virtual bool isEnabledAtPlay(const Player *) const
    {
        return false;
    }

    virtual const Card *viewAs() const
    {
        return NULL;
    }
};

class Mengjin : public ZeroCardViewAsSkill
{
public:
    Mengjin() : ZeroCardViewAsSkill("mengjin")
    {

    }

    virtual bool isEnabledAtPlay(const Player *) const
    {
        return false;
    }

    virtual const Card *viewAs() const
    {
        return NULL;
    }
};

class Wushuang : public TriggerSkill
{
public:
    Wushuang() : TriggerSkill("wushuang")
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
            if (triggerEvent != TargetChosen)
                return false;

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

LijianCard::LijianCard()
{
    mute = true;
}

bool LijianCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    if (!to_select->isMale()) return false;

    Duel *duel = new Duel(Card::NoSuit, 0);
    duel->deleteLater();

    if (targets.length() == 1 && (to_select->isCardLimited(duel, Card::MethodUse) || to_select->isProhibited(targets.first(), duel)))
        return false;

    return targets.length() < 2 && to_select != Self;
}

bool LijianCard::targetsFeasible(const QList<const Player *> &targets, const Player *) const
{
    return targets.length() == 2;
}

void LijianCard::onUse(Room *room, const CardUseStruct &card_use) const
{
    ServerPlayer *diaochan = card_use.from;

    LogMessage log;
    log.from = diaochan;
    log.to << card_use.to;
    log.type = "#UseCard";
    log.card_str = toString();
    room->sendLog(log);

    QVariant data = QVariant::fromValue(card_use);
    RoomThread *thread = room->getThread();

    thread->trigger(PreCardUsed, room, diaochan, data);
    room->broadcastSkillInvoke("lijian", diaochan);

    CardMoveReason reason(CardMoveReason::S_REASON_THROW, diaochan->objectName(), QString(), "lijian", QString());
    room->moveCardTo(this, diaochan, NULL, Player::DiscardPile, reason, true);

    if (diaochan->ownSkill("lijian") && !diaochan->hasShownSkill("lijian"))
        diaochan->showGeneral(diaochan->inHeadSkills("lijian"));

    if (diaochan->hasShownSkill("huashen"))
        room->dropHuashenCardbySkillName(diaochan, "lijian");

    thread->trigger(CardUsed, room, diaochan, data);
    thread->trigger(CardFinished, room, diaochan, data);
}

void LijianCard::use(Room *room, ServerPlayer *, QList<ServerPlayer *> &targets) const
{
    ServerPlayer *to = targets.at(0);
    ServerPlayer *from = targets.at(1);

    Duel *duel = new Duel(Card::NoSuit, 0);
    duel->setSkillName(QString("_%1").arg(getSkillName()));
    if (!from->isCardLimited(duel, Card::MethodUse) && !from->isProhibited(to, duel))
        room->useCard(CardUseStruct(duel, from, to));
    else
        delete duel;
}

class Lijian : public OneCardViewAsSkill
{
public:
    Lijian() : OneCardViewAsSkill("lijian")
    {
        filter_pattern = ".!";
    }

    virtual bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("LijianCard");
    }

    virtual const Card *viewAs(const Card *originalCard) const
    {
        LijianCard *lijian_card = new LijianCard;
        lijian_card->addSubcard(originalCard->getId());
        lijian_card->setShowSkill(objectName());
        return lijian_card;
    }

    virtual int getEffectIndex(const ServerPlayer *, const Card *card) const
    {
        return card->isKindOf("Duel") ? 0 : -1;
    }
};

class Biyue : public PhaseChangeSkill
{
public:
    Biyue() : PhaseChangeSkill("biyue")
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

    virtual bool onPhaseChange(ServerPlayer *diaochan) const
    {
        diaochan->drawCards(1);

        return false;
    }
};

class LuanjiViewAsSkill : public ViewAsSkill
{
public:
    LuanjiViewAsSkill() : ViewAsSkill("luanji")
    {
        response_or_use = true;
    }

    virtual bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const
    {
        QStringList luanji_suits = Self->property("luanjiUsedSuits").toString().split("+");
        return selected.length() < 2 && !to_select->isEquipped() && !luanji_suits.contains(to_select->getSuitString());
    }

    virtual const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (cards.length() == 2) {
            ArcheryAttack *aa = new ArcheryAttack(Card::SuitToBeDecided, 0);
            aa->addSubcards(cards);
            aa->setSkillName(objectName());
            aa->setShowSkill(objectName());
            return aa;
        } else
            return NULL;
    }
};

class Luanji : public TriggerSkill
{
public:
    Luanji() : TriggerSkill("luanji")
    {
        events << PreCardUsed << EventPhaseChanging;
        view_as_skill = new LuanjiViewAsSkill;
    }

    virtual void record(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (triggerEvent == PreCardUsed) {
            CardUseStruct use = data.value<CardUseStruct>();
            if (use.card && use.card->getSkillName() == objectName()) {
                QStringList luanji_suits = player->property("luanjiUsedSuits").toString().split("+");
                QList<int> ids = use.card->getSubcards();
                foreach (int id, ids) {
                    const Card *card = Sanguosha->getCard(id);
                    QString suitstr = card->getSuitString();
                    if (!luanji_suits.contains(suitstr))
                        luanji_suits << suitstr;
                }
                room->setPlayerProperty(player, "luanjiUsedSuits", luanji_suits.join("+"));


            }
        } else if (triggerEvent == EventPhaseChanging) {
            if (data.value<PhaseChangeStruct>().from == Player::Play) {
                room->setPlayerProperty(player, "luanjiUsedSuits", QVariant());
            }
        }
    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *, QVariant &, ServerPlayer* &) const
    {
        return QStringList();
    }


};

class LuanjiDraw : public TriggerSkill
{
public:
    LuanjiDraw() : TriggerSkill("#luanji-draw")
    {
        events << CardResponded;
        frequency = Compulsory;
    }

    virtual int getPriority() const
    {
        return -2;
    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
    {
        if (player == NULL || player->isDead()) return QStringList();
        CardResponseStruct response = data.value<CardResponseStruct>();
        const Card *card_star = response.m_card;
        QVariant m_data = response.m_data;
        if (card_star->isKindOf("Jink") && m_data.canConvert<CardEffectStruct>()) {
            CardEffectStruct effect = m_data.value<CardEffectStruct>();
            if (effect.card && effect.card->getSkillName() == "luanji" && effect.from && player->isFriendWith(effect.from))
                return QStringList(objectName());
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        LogMessage log;
        log.type = "#LuanjiDraw";
        log.from = player;
        log.arg = "luanji";
        room->sendLog(log);
        return room->askForChoice(player, "luanji_draw", "yes+no", QVariant(), "@luanji-draw") == "yes";
    }

    virtual bool effect(TriggerEvent, Room *, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        player->drawCards(1, "luanji");
        return false;
    }
};

class ShuangxiongViewAsSkill : public OneCardViewAsSkill
{
public:
    ShuangxiongViewAsSkill() :OneCardViewAsSkill("shuangxiong")
    { //Client::updateProperty() / RoomScene::detachSkill()
        response_or_use = true;
    }

    virtual bool isEnabledAtPlay(const Player *player) const
    {
        return player->getMark("#shuangxiong+no_suit_red") + player->getMark("#shuangxiong+no_suit_black") > 0;
    }

    virtual bool viewFilter(const Card *card) const
    {
        if (card->isEquipped()) return false;

        if (card->isRed())
            return Self->getMark("#shuangxiong+no_suit_red") > 0;

        if (card->isBlack())
            return Self->getMark("#shuangxiong+no_suit_black") > 0;

        return false;
    }

    virtual const Card *viewAs(const Card *originalCard) const
    {
        Duel *duel = new Duel(originalCard->getSuit(), originalCard->getNumber());
        duel->addSubcard(originalCard);
        //duel->setShowSkill("shuangxiong"); // use ShuangxiongViewAsSkill don't cause showing general
        duel->setSkillName("_shuangxiong");
        return duel;
    }
};

class Shuangxiong : public TriggerSkill
{
public:
    Shuangxiong() : TriggerSkill("shuangxiong")
    {
        events << EventPhaseStart;
        view_as_skill = new ShuangxiongViewAsSkill;
    }

    virtual bool canPreshow() const
    {
        return true;
    }

    virtual void record(TriggerEvent , Room *room, ServerPlayer *player, QVariant &) const
    {
        if (player->getPhase() ==  Player::NotActive) {
            room->setPlayerMark(player, "#shuangxiong+no_suit_red", 0);
            room->setPlayerMark(player, "#shuangxiong+no_suit_black", 0);
            if (player->hasFlag("shuangxiong")) {
                room->setPlayerFlag(player, "-shuangxiong");
                if (player->hasFlag("shuangxiong_attachskill")) {
                    room->setPlayerFlag(player, "-shuangxiong_attachskill");
                    room->detachSkillFromPlayer(player, "shuangxiong", true, true);
                }
            }
        }
    }

    virtual QStringList triggerable(TriggerEvent , Room *, ServerPlayer *player, QVariant &, ServerPlayer* &) const
    {
        if (player->getPhase() == Player::Draw && TriggerSkill::triggerable(player))
            return QStringList(objectName());
        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *shuangxiong, QVariant &, ServerPlayer *) const
    {
        if (shuangxiong->askForSkillInvoke(this)) {
            room->broadcastSkillInvoke(objectName(), 1, shuangxiong);
            return true;
        }

        return false;
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *shuangxiong, QVariant &, ServerPlayer *) const
    {
        room->setPlayerFlag(shuangxiong, "shuangxiong");

        JudgeStruct judge;
        judge.good = true;
        judge.play_animation = false;
        judge.reason = objectName();
        judge.who = shuangxiong;
        judge.patterns << ".|red" << ".|black";
        room->judge(judge);

        QString pattern = "#shuangxiong+no_suit_red";
        if (judge.pattern == ".|red")
            pattern = "#shuangxiong+no_suit_black";

        room->addPlayerTip(shuangxiong, pattern);

        if (!shuangxiong->hasSkill(objectName(), true)) {
            room->setPlayerFlag(shuangxiong, "shuangxiong_attachskill");
            room->attachSkillToPlayer(shuangxiong, objectName());
        }

        return true;
    }

    virtual int getEffectIndex(const ServerPlayer *, const Card *) const
    {
        return 2;
    }
};

class ShuangxiongGet : public TriggerSkill
{
public:
    ShuangxiongGet() : TriggerSkill("#shuangxiong")
    {
        events << FinishJudge;
        frequency = Compulsory;
    }

    virtual bool canPreshow() const
    {
        return false;
    }

    virtual QStringList triggerable(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
    {
        if (player != NULL) {
            JudgeStruct *judge = data.value<JudgeStruct *>();
            if (judge->reason == "shuangxiong" && room->getCardPlace(judge->card->getEffectiveId()) == Player::PlaceJudge)
                    return QStringList(objectName());
        }
        return QStringList();
    }

    virtual bool effect(TriggerEvent, Room *, ServerPlayer *, QVariant &data, ServerPlayer *) const
    {
        JudgeStruct *judge = data.value<JudgeStruct *>();
        judge->who->obtainCard(judge->card);

        return false;
    }
};

class Wansha : public TriggerSkill
{ // Gamerule::effect (AskForPeaches)
public:
    Wansha() : TriggerSkill("wansha")
    {
        events << Dying;
        frequency = Compulsory;
    }

    virtual QStringList triggerable(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer* &) const
    {
        if (TriggerSkill::triggerable(player)) {
            if (room->getCurrent() == player && player->isAlive() && player->getPhase() != Player::NotActive) {
                return QStringList(objectName());
            }
        }
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

    virtual bool effect(TriggerEvent triggerEvent, Room *room, ServerPlayer *jiaxu, QVariant &data, ServerPlayer *) const
    {
        if (triggerEvent == Dying) {
            DyingStruct dying = data.value<DyingStruct>();
            room->notifySkillInvoked(jiaxu, objectName());

            LogMessage log;
            log.from = jiaxu;
            log.arg = objectName();
            if (jiaxu != dying.who) {
                log.type = "#WanshaTwo";
                log.to << dying.who;
            } else {
                log.type = "#WanshaOne";
            }
            room->sendLog(log);
        }
        return false;
    }
};

LuanwuCard::LuanwuCard()
{
    target_fixed = true;
    mute = true;
}

void LuanwuCard::onUse(Room *room, const CardUseStruct &card_use) const
{
    room->setPlayerMark(card_use.from, "@chaos", 0);
    room->broadcastSkillInvoke("luanwu", card_use.from);
    room->doSuperLightbox("jiaxu", "luanwu");

    CardUseStruct new_use = card_use;
    new_use.to << room->getOtherPlayers(card_use.from);

    Card::onUse(room, new_use);
}

void LuanwuCard::onEffect(const CardEffectStruct &effect) const
{
    Room *room = effect.to->getRoom();

    QList<ServerPlayer *> players = room->getOtherPlayers(effect.to);
    QList<int> distance_list;
    int nearest = 1000;
    foreach (ServerPlayer *player, players) {
        int distance = effect.to->distanceTo(player);
        distance_list << distance;
        if (distance != -1)
            nearest = qMin(nearest, distance);
    }

    QList<ServerPlayer *> luanwu_targets;
    for (int i = 0; i < distance_list.length(); i++) {
        if (distance_list[i] == nearest && effect.to->canSlash(players[i], NULL, false))
            luanwu_targets << players[i];
    }

    if (luanwu_targets.isEmpty() || !room->askForUseSlashTo(effect.to, luanwu_targets, "@luanwu-slash"))
        room->loseHp(effect.to);
}

class Luanwu : public ZeroCardViewAsSkill
{
public:
    Luanwu() : ZeroCardViewAsSkill("luanwu")
    {
        frequency = Limited;
        limit_mark = "@chaos";
    }

    virtual const Card *viewAs() const
    {
        LuanwuCard *card = new LuanwuCard;
        card->setShowSkill(objectName());
        return card;
    }

    virtual bool isEnabledAtPlay(const Player *player) const
    {
        return player->getMark("@chaos") >= 1;
    }
};

class Weimu : public TriggerSkill
{
public:
    Weimu() : TriggerSkill("weimu")
    {
        events << TargetConfirming << BeforeCardsMove;
        frequency = Compulsory;
    }

    virtual QStringList triggerable(TriggerEvent triggerEvent, Room *, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
    {
        if (!TriggerSkill::triggerable(player)) return QStringList();
        if (triggerEvent == TargetConfirming) {
            CardUseStruct use = data.value<CardUseStruct>();
            if (!use.card || !use.card->isNDTrick() || !use.card->isBlack()) return QStringList();
            if (use.to.contains(player))
                return QStringList(objectName());
        } else if (triggerEvent == BeforeCardsMove) {

            QVariantList move_datas = data.toList();
            if (move_datas.size() != 1) return QStringList();
            QVariant move_data = move_datas.first();

            CardsMoveOneTimeStruct move = move_data.value<CardsMoveOneTimeStruct>();
            if (move.to == player && move.to_place == Player::PlaceDelayedTrick && move.card_ids.size() == 1) {

                if (Sanguosha->getCard(move.card_ids.first())->isBlack())
                   return QStringList(objectName());

            }

        }
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

class Jianchu : public TriggerSkill
{
public:
    Jianchu() : TriggerSkill("jianchu")
    {
        events << TargetChosen;
    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (TriggerSkill::triggerable(player) && use.card != NULL && use.card->isKindOf("Slash")) {
            QStringList targets;
            foreach (ServerPlayer *to, use.to) {
                if (player->canDiscard(to, "he"))
                    targets << to->objectName();
            }
            if (!targets.isEmpty())
                return QStringList(objectName() + "->" + targets.join("+"));
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

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *target, QVariant &data, ServerPlayer *pangde) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        QVariantList jink_list = pangde->tag["Jink_" + use.card->toString()].toList();

        int to_throw = room->askForCardChosen(pangde, target, "he", objectName(), false, Card::MethodDiscard);

        CardMoveReason reason(CardMoveReason::S_REASON_DISMANTLE, pangde->objectName(), target->objectName(), QString(), QString());

        CardsMoveStruct dis_move(to_throw, NULL, Player::DiscardPile, reason);

        QList<CardsMoveOneTimeStruct> moveOneTimes = room->moveCardsSub(dis_move, true);

        QList<const Card *> thrown;
        foreach (CardsMoveOneTimeStruct move, moveOneTimes) {
            if (move.from == target && move.reason.m_reason == CardMoveReason::S_REASON_DISMANTLE) {
                for (int i = 0; i < move.card_ids.length(); ++i) {
                    const Card *card = Card::Parse(move.cards.at(i));
                    if (card && (move.from_places.at(i) == Player::PlaceHand || move.from_places.at(i) == Player::PlaceEquip)) {
                        thrown << card;
                    }
                }
            }
        }

        if (!thrown.isEmpty()) {
            bool no_jink = false, get_card = false;
            foreach (const Card *card, thrown) {
                if (card->getTypeId() == Card::TypeEquip)
                    no_jink = true;
                else
                    get_card = true;
            }

            if (no_jink)
                doLiegong(target, use, jink_list);

            if (get_card && room->isAllOnPlace(use.card, Player::PlaceTable))
                target->obtainCard(use.card);
        }

        pangde->tag["Jink_" + use.card->toString()] = jink_list;
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

class Leiji : public TriggerSkill
{
public:
    Leiji() : TriggerSkill("leiji")
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

class Guidao : public TriggerSkill
{
public:
    Guidao() : TriggerSkill("guidao")
    {
        events << AskForRetrial;
    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *target, QVariant &, ServerPlayer * &) const
    {
        if (!TriggerSkill::triggerable(target))
            return QStringList();

        if (target->isKongcheng() && target->getHandPile().isEmpty()) {
            bool has_black = false;
            for (int i = 0; i < 4; i++) {
                const EquipCard *equip = target->getEquip(i);
                if (equip && equip->isBlack()) {
                    has_black = true;
                    break;
                }
            }
            return (has_black) ? QStringList(objectName()) : QStringList();
        }
        return QStringList(objectName());
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        JudgeStruct *judge = data.value<JudgeStruct *>();

        QStringList prompt_list;
        prompt_list << "@guidao-card" << judge->who->objectName()
            << objectName() << judge->reason << QString::number(judge->card->getEffectiveId());
        QString prompt = prompt_list.join(":");

        const Card *card = room->askForCard(player, ".|black", prompt, data, Card::MethodResponse, judge->who, true);

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

            QStringList card_list = player->tag["guidao_cards"].toStringList();
            card_list.append(card->toString());
            player->tag["guidao_cards"] = card_list;

            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        QStringList card_list = player->tag["guidao_cards"].toStringList();

        if (card_list.isEmpty()) return false;

        QString card_str = card_list.takeLast();
        player->tag["guidao_cards"] = card_list;

        const Card *card = Card::Parse(card_str);
        if (card) {

            JudgeStruct *judge = data.value<JudgeStruct *>();

            room->retrial(card, player, judge, objectName(), true);

            judge->updateResult();
        }
        return false;
    }
};

class Beige : public TriggerSkill
{
public:
    Beige() : TriggerSkill("beige")
    {
        events << Damaged;
    }

    virtual TriggerList triggerable(TriggerEvent , Room *room, ServerPlayer *player, QVariant &data) const
    {
        TriggerList skill_list;
        if (player == NULL) return skill_list;

        DamageStruct damage = data.value<DamageStruct>();
        if (damage.card == NULL || !damage.card->isKindOf("Slash") || damage.to->isDead())
            return skill_list;

        QList<ServerPlayer *> caiwenjis = room->findPlayersBySkillName(objectName());
        foreach(ServerPlayer *caiwenji, caiwenjis)
            if (!caiwenji->isNude())
                skill_list.insert(caiwenji, QStringList(objectName()));

        return skill_list;
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *, QVariant &data, ServerPlayer *ask_who) const
    {
        ServerPlayer *caiwenji = ask_who;

        if (caiwenji != NULL) {
            caiwenji->tag["beige_data"] = data;
            bool invoke = room->askForDiscard(caiwenji, objectName(), 1, 1, true, true, "@beige", true);
            caiwenji->tag.remove("beige_data");

            if (invoke) {
                room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, caiwenji->objectName(), data.value<DamageStruct>().to->objectName());
                room->broadcastSkillInvoke(objectName(), caiwenji);
                return true;
            }
        }
        return false;
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const
    {
        ServerPlayer *caiwenji = ask_who;
        if (caiwenji == NULL) return false;
        DamageStruct damage = data.value<DamageStruct>();

        QStringList all_patterns;
        all_patterns << ".|spade" << ".|club" << ".|heart" << ".|diamond";
        JudgeStruct judge;
        judge.good = true;
        judge.patterns = all_patterns;
        judge.play_animation = false;
        judge.who = player;
        judge.reason = objectName();

        room->judge(judge);

        int index = all_patterns.indexOf(judge.pattern);

        if (index < 0) return false;

        Card::Suit suit = (Card::Suit)(index);
        switch (suit) {
            case Card::Heart: {
                RecoverStruct recover;
                recover.who = caiwenji;
                room->recover(player, recover);

                break;
            }
            case Card::Diamond: {
                player->drawCards(2);
                break;
            }
            case Card::Club: {
                if (damage.from && damage.from->isAlive())
                    room->askForDiscard(damage.from, "beige_discard", 2, 2, false, true);

                break;
            }
            case Card::Spade: {
                if (damage.from && damage.from->isAlive())
                    damage.from->turnOver();

                break;
            }
            default:
                break;
        }
        return false;
    }
};

class Duanchang : public TriggerSkill
{
public:
    Duanchang() : TriggerSkill("duanchang")
    {
        events << Death;
        frequency = Compulsory;
    }

    virtual bool canPreshow() const
    {
        return false;
    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
    {
        if (player == NULL || !player->hasSkill(objectName())) return QStringList();
        DeathStruct death = data.value<DeathStruct>();
        if (death.who != player)
            return QStringList();

        if (death.damage && death.damage->from) {
            ServerPlayer *target = death.damage->from;
            if (target->isAlive() && !(target->getGeneral()->objectName().contains("sujiang") && target->getGeneral2()->objectName().contains("sujiang")))
                return QStringList(objectName());
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        room->broadcastSkillInvoke(objectName(), player);
        return true;
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        room->sendCompulsoryTriggerLog(player, objectName());

        DeathStruct death = data.value<DeathStruct>();
        ServerPlayer *target = death.damage->from;
        room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, player->objectName(), target->objectName());
        QString choice = "head_general";

        if (player->getAI()) {
            QStringList choices;
            if (!target->getGeneral()->objectName().contains("sujiang"))
                choices << "head_general";

            if (!target->getGeneral2()->objectName().contains("sujiang"))
                choices << "deputy_general";

            choice = room->askForChoice(player, objectName(), choices.join("+"), QVariant::fromValue(target));
        } else {
            QStringList generals;
            if (!target->getGeneral()->objectName().contains("sujiang")) {
                QString g = target->getGeneral()->objectName();
                if (g.contains("anjiang"))
                    g.append("_head");
                generals << g;
            }

            if (target->getGeneral2() && !target->getGeneral2()->objectName().contains("sujiang")) {
                QString g = target->getGeneral2()->objectName();
                if (g.contains("anjiang"))
                    g.append("_deputy");
                generals << g;
            }

            QString general = generals.first();
            if (generals.length() == 2)
                general = room->askForGeneral(player, generals.join("+"), generals.first(), true, objectName(), QVariant::fromValue(target));

            if (general == target->getGeneral()->objectName() || general == "anjiang_head")
                choice = "head_general";
            else
                choice = "deputy_general";

        }
        LogMessage log;
        log.type = choice == "head_general" ? "#DuanchangLoseHeadSkills" : "#DuanchangLoseDeputySkills";
        log.from = player;
        log.to << target;
        log.arg = objectName();
        room->sendLog(log);

        QStringList duanchangList = target->property("Duanchang").toString().split(",");
        if (choice == "head_general" && !duanchangList.contains("head"))
            duanchangList << "head";
        else if (choice == "deputy_general" && !duanchangList.contains("deputy"))
            duanchangList << "deputy";
        room->setPlayerProperty(target, "Duanchang", duanchangList.join(","));

        QList<const Skill *> skills = choice == "head_general" ? target->getActualGeneral1()->getVisibleSkillList()
            : target->getActualGeneral2()->getVisibleSkillList();
        foreach (const Skill *skill, skills)
            if (!skill->isAttachedLordSkill())
                room->detachSkillFromPlayer(target, skill->objectName(), !target->hasShownSkill(skill), false, choice == "head_general" ? true : false);

        if (death.damage->from->isAlive())
            death.damage->from->gainMark("@duanchang");

        return false;
    }
};

XiongyiCard::XiongyiCard()
{
    mute = true;
    target_fixed = true;
}

void XiongyiCard::onUse(Room *room, const CardUseStruct &card_use) const
{
    room->setPlayerMark(card_use.from, "@arise", 0);
    room->broadcastSkillInvoke("xiongyi", card_use.from);
    room->doSuperLightbox("mateng", "xiongyi");
    SkillCard::onUse(room, card_use);
}

void XiongyiCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const
{
    QList<ServerPlayer *> targets;
    foreach (ServerPlayer *p, room->getAllPlayers()) {
        if (p->isFriendWith(source)) {
            targets << p;
        }
    }
    room->sortByActionOrder(targets);
    Card::use(room, source, targets);

    bool invoke = true;
    int num = source->getPlayerNumWithKingdom();
    foreach (ServerPlayer *p, room->getAlivePlayers()) {
        if (p->hasShownOneGeneral() && p->getPlayerNumWithKingdom() < num) {
            invoke = false;
            break;
        }
    }

    if (invoke && source->isWounded()) {
        RecoverStruct recover;
        recover.who = source;
        room->recover(source, recover);
    }
}

void XiongyiCard::onEffect(const CardEffectStruct &effect) const
{
    effect.to->drawCards(3);
}

class Xiongyi : public ZeroCardViewAsSkill
{
public:
    Xiongyi() : ZeroCardViewAsSkill("xiongyi")
    {
        frequency = Limited;
        limit_mark = "@arise";
    }

    virtual bool isEnabledAtPlay(const Player *player) const
    {
        return player->getMark("@arise") >= 1;
    }

    virtual const Card *viewAs() const
    {
        XiongyiCard *card = new XiongyiCard;
        card->setShowSkill(objectName());
        return card;
    }
};

class Mingshi : public TriggerSkill
{
public:
    Mingshi() : TriggerSkill("mingshi")
    {
        events << DamageInflicted;
        frequency = Compulsory;
    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
    {
        if (!TriggerSkill::triggerable(player)) return QStringList();
        DamageStruct damage = data.value<DamageStruct>();
        if (damage.from && !damage.from->hasShownAllGenerals())
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

    virtual bool effect(TriggerEvent, Room *, ServerPlayer *, QVariant &data, ServerPlayer *) const
    {
        DamageStruct damage = data.value<DamageStruct>();

        --damage.damage;
        if (damage.damage < 1)
            return true;
        data = QVariant::fromValue(damage);

        return false;
    }
};

LirangGiveCard::LirangGiveCard()
{
    will_throw = false;
    handling_method = Card::MethodNone;
}

void LirangGiveCard::onUse(Room *, const CardUseStruct &card_use) const
{
    QStringList targets = card_use.from->tag["lirang_target"].toStringList();
    QStringList cards = card_use.from->tag["lirang_get"].toStringList();
    targets << card_use.to.first()->objectName();
    cards.append((IntList2StringList(this->getSubcards())).join("+"));
    card_use.from->tag["lirang_target"] = targets;
    card_use.from->tag["lirang_get"] = cards;
}

class LirangGive : public ViewAsSkill
{
public:
    LirangGive() : ViewAsSkill("liranggive")
    {
        expand_pile = "#lirang";
        response_pattern = "@@liranggive";
    }

    virtual bool viewFilter(const QList<const Card *> &, const Card *to_select) const
    {
        return Self->getPile("#lirang").contains(to_select->getId());
    }

    virtual const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (cards.isEmpty()) return NULL;
        LirangGiveCard *Lirang_card = new LirangGiveCard;
        Lirang_card->addSubcards(cards);
        return Lirang_card;
    }
};

class Lirang : public TriggerSkill
{
public:
    Lirang() : TriggerSkill("lirang")
    {
        events << CardsMoveOneTime;
    }

    virtual QStringList triggerable(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
    {
        if (!TriggerSkill::triggerable(player)) return QStringList();

        QVariantList move_datas = data.toList();
        foreach (QVariant move_data, move_datas) {
            CardsMoveOneTimeStruct move = move_data.value<CardsMoveOneTimeStruct>();
            if (move.from == player && (move.reason.m_reason & CardMoveReason::S_MASK_BASIC_REASON) == CardMoveReason::S_REASON_DISCARD) {
                if (move.to_place == Player::DiscardPile) {
                    QList<int> this_cards;

                    for (int i = 0; i < move.card_ids.length(); ++i) {
                        int id = move.card_ids.at(i);
                        if ((move.from_places.at(i) == Player::PlaceHand || move.from_places.at(i) == Player::PlaceEquip) &&
                                room->getCardPlace(id) == Player::DiscardPile)
                            this_cards << id;
                    }

                    if (!this_cards.isEmpty()) {
                        return QStringList(objectName());
                    }
                }
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

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        QList<int> cards;
        QVariantList move_datas = data.toList();
        foreach (QVariant move_data, move_datas) {

            CardsMoveOneTimeStruct move = move_data.value<CardsMoveOneTimeStruct>();
            if (move.from == player && move.to_place == Player::DiscardPile
                    && (move.reason.m_reason & CardMoveReason::S_MASK_BASIC_REASON) == CardMoveReason::S_REASON_DISCARD) {

                for (int i = 0; i < move.card_ids.length(); ++i) {
                    int id = move.card_ids.at(i);
                    if ((move.from_places.at(i) == Player::PlaceHand || move.from_places.at(i) == Player::PlaceEquip) &&
                            room->getCardPlace(id) == Player::DiscardPile)
                        cards << id;
                }
            }

        }

        QList<CardsMoveStruct> moves;

        while (!cards.isEmpty() && player->isAlive()) {

            room->notifyMoveToPile(player, cards, objectName(), Player::PlaceTable, true, true);

            const Card *use = room->askForUseCard(player, "@@liranggive", "@lirang-distribute", -1, Card::MethodNone);

            room->notifyMoveToPile(player, cards, objectName(), Player::DiscardPile, false, false);

            if (use == NULL) break;

            QStringList targets = player->tag["lirang_target"].toStringList();
            QStringList cards_get = player->tag["lirang_get"].toStringList();
            QList<int> get = StringList2IntList(cards_get.last().split("+"));
            ServerPlayer *target = NULL;
            foreach (ServerPlayer *p, room->getAlivePlayers()) {
                if (p->objectName() == targets.last())
                    target = p;
            }
            targets.removeLast();
            cards_get.removeLast();
            player->tag["lirang_target"] = targets;
            player->tag["lirang_get"] = cards_get;

            CardMoveReason reason(CardMoveReason::S_REASON_PREVIEWGIVE, player->objectName(), target->objectName(), objectName(), QString());
            CardsMoveStruct move(get, target, Player::PlaceHand, reason);
            moves.append(move);

            foreach (int id, get)
                cards.removeOne(id);
        }

        room->moveCardsAtomic(moves, true);

        return false;
    }
};

class Shuangren : public PhaseChangeSkill
{
public:
    Shuangren() : PhaseChangeSkill("shuangren")
    {
    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *jiling, QVariant &, ServerPlayer * &) const
    {
        if (!TriggerSkill::triggerable(jiling)) return QStringList();
        if (jiling->getPhase() == Player::Play && !jiling->isKongcheng()) {
            Room *room = jiling->getRoom();
            bool can_invoke = false;
            QList<ServerPlayer *> other_players = room->getOtherPlayers(jiling);
            foreach (ServerPlayer *player, other_players) {
                if (jiling->canPindianTo(player)) {
                    can_invoke = true;
                    break;
                }
            }

            return can_invoke ? QStringList(objectName()) : QStringList();
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *jiling, QVariant &, ServerPlayer *) const
    {
        QList<ServerPlayer *> targets;
        foreach (ServerPlayer *p, room->getOtherPlayers(jiling)) {
            if (jiling->canPindianTo(p))
                targets << p;
        }
        ServerPlayer *victim;
        if ((victim = room->askForPlayerChosen(jiling, targets, "shuangren", "@shuangren", true, true)) != NULL) {
            room->broadcastSkillInvoke(objectName(), jiling);

            QStringList target_list = jiling->tag["shuangren_target"].toStringList();
            target_list.append(victim->objectName());
            jiling->tag["shuangren_target"] = target_list;

            return true;
        }
        return false;
    }

    virtual bool onPhaseChange(ServerPlayer *jiling) const
    {
        Room *room = jiling->getRoom();
        QStringList target_list = jiling->tag["shuangren_target"].toStringList();
        QString target_name = target_list.last();
        target_list.removeLast();
        jiling->tag["shuangren_target"] = target_list;

        ServerPlayer *target = room->findPlayerbyobjectName(target_name);
        if (target != NULL && jiling->canPindianTo(target)) {
            bool success = jiling->pindian(target, objectName());
            if (success) {
                QList<ServerPlayer *> targets;
                foreach (ServerPlayer *p, room->getAlivePlayers()) {
                    if (jiling->canSlash(p, NULL, false) && (p->isFriendWith(target) || target == p))
                        targets << p;
                }
                if (targets.isEmpty()) return false;

                ServerPlayer *slasher = room->askForPlayerChosen(jiling, targets, "shuangren-slash", "@dummy-slash");
                Slash *slash = new Slash(Card::NoSuit, 0);
                slash->setSkillName("_shuangren");
                room->useCard(CardUseStruct(slash, jiling, slasher), false);
            } else
                jiling->setFlags("Global_PlayPhaseTerminated");
        }
        return false;
    }

    virtual int getEffectIndex(const ServerPlayer *, const Card *) const
    {
        return 0;
    }
};

class Sijian : public TriggerSkill
{
public:
    Sijian() : TriggerSkill("sijian")
    {
        events << CardsMoveOneTime;
    }

    virtual QStringList triggerable(TriggerEvent, Room *room, ServerPlayer *tianfeng, QVariant &data, ServerPlayer * &) const
    {
        if (!TriggerSkill::triggerable(tianfeng) || !tianfeng->isKongcheng()) return QStringList();

        QVariantList move_datas = data.toList();
        foreach (QVariant move_data, move_datas) {
            CardsMoveOneTimeStruct move = move_data.value<CardsMoveOneTimeStruct>();
            if (move.from == tianfeng && move.from_places.contains(Player::PlaceHand)) {
                QList<ServerPlayer *> other_players = room->getOtherPlayers(tianfeng);

                foreach (ServerPlayer *p, other_players) {
                    if (tianfeng->canDiscard(p, "he"))
                        return QStringList(objectName());
                }
            }
        }



        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *tianfeng, QVariant &, ServerPlayer *) const
    {
        QList<ServerPlayer *> other_players = room->getOtherPlayers(tianfeng);
        QList<ServerPlayer *> targets;
        foreach (ServerPlayer *p, other_players) {
            if (tianfeng->canDiscard(p, "he"))
                targets << p;
        }
        ServerPlayer *to = room->askForPlayerChosen(tianfeng, targets, objectName(), "sijian-invoke", true, true);
        if (to) {
            tianfeng->tag["sijian_target"] = QVariant::fromValue(to);
            room->broadcastSkillInvoke(objectName(), tianfeng);
            return true;
        } else tianfeng->tag.remove("sijian_target");
        return false;
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *tianfeng, QVariant &, ServerPlayer *) const
    {
        ServerPlayer *to = tianfeng->tag["sijian_target"].value<ServerPlayer *>();
        tianfeng->tag.remove("sijian_target");
        if (to && tianfeng->canDiscard(to, "he")) {
            int card_id = room->askForCardChosen(tianfeng, to, "he", objectName(), false, Card::MethodDiscard);
            room->throwCard(card_id, to, tianfeng);
        }
        return false;
    }
};

class Suishi : public TriggerSkill
{
public:
    Suishi() : TriggerSkill("suishi")
    {
        events << Dying << Death;
        frequency = Compulsory;
    }

    virtual QStringList triggerable(TriggerEvent triggerEvent, Room *, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
    {
        if (!TriggerSkill::triggerable(player)) return QStringList();
        ServerPlayer *target = NULL;
        if (triggerEvent == Dying) {
            DyingStruct dying = data.value<DyingStruct>();
            if (dying.damage && dying.damage->from)
                target = dying.damage->from;
            if (dying.who != player && target && target->isFriendWith(player))
                return QStringList(objectName());
        } else if (triggerEvent == Death) {
            DeathStruct death = data.value<DeathStruct>();
            target = death.who;
            if (target && target->isFriendWith(player))
                return QStringList(objectName());
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        bool invoke = player->hasShownSkill(this) ? true : player->askForSkillInvoke(this, (int)triggerEvent);
        if (invoke) {
            if (triggerEvent == Dying)
                room->broadcastSkillInvoke(objectName(), 1, player);
            else if (triggerEvent == Death)
                room->broadcastSkillInvoke(objectName(), 2, player);
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        room->sendCompulsoryTriggerLog(player, objectName());
        if (triggerEvent == Dying)
            player->drawCards(1);
        else if (triggerEvent == Death)
            room->loseHp(player);
        return false;
    }
};

class Kuangfu : public TriggerSkill
{
public:
    Kuangfu() : TriggerSkill("kuangfu")
    {
        events << Damage;
        frequency = Frequent;
    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *panfeng, QVariant &data, ServerPlayer* &) const
    {
        if (!TriggerSkill::triggerable(panfeng)) return QStringList();
        DamageStruct damage = data.value<DamageStruct>();
        ServerPlayer *target = damage.to;
        if (damage.card && damage.card->isKindOf("Slash") && target->hasEquip() && !damage.chain && !damage.transfer && !damage.to->hasFlag("Global_DFDebut")) {
            QStringList equiplist;
            for (int i = 0; i < 5; i++) {
                if (!target->getEquip(i)) continue;
                if (panfeng->canDiscard(target, target->getEquip(i)->getEffectiveId()) || panfeng->getEquip(i) == NULL)
                    return QStringList(objectName());
            }
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *panfeng, QVariant &data, ServerPlayer *) const
    {
        if (panfeng->askForSkillInvoke(this, data)) {
            room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, panfeng->objectName(), data.value<DamageStruct>().to->objectName());
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *panfeng, QVariant &data, ServerPlayer *) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        ServerPlayer *target = damage.to;

        QList<int> disable_equiplist, equiplist;
        for (int i = 0; i < 5; i++) {
            if (target->getEquip(i) && !panfeng->canDiscard(target, target->getEquip(i)->getEffectiveId()) && panfeng->getEquip(i))
                disable_equiplist << target->getEquip(i)->getEffectiveId();
            if (target->getEquip(i) && panfeng->getEquip(i))
                equiplist << target->getEquip(i)->getEffectiveId();
        }
        int card_id = room->askForCardChosen(panfeng, target, "e", objectName(), false, Card::MethodNone, disable_equiplist);
        const Card *card = Sanguosha->getCard(card_id);

        QStringList choicelist;
        if (panfeng->canDiscard(target, card_id))
            choicelist << "throw";
        if (!equiplist.contains(card_id))
            choicelist << "move";

        QString choice = room->askForChoice(panfeng, "kuangfu", choicelist.join("+"));

        if (choice.contains("move")) {
            room->broadcastSkillInvoke(objectName(), 2, panfeng);
            room->moveCardTo(card, panfeng, Player::PlaceEquip);
        } else {
            room->broadcastSkillInvoke(objectName(), 1, panfeng);
            room->throwCard(card, target, panfeng);
        }

        return false;
    }
};

class Huoshui : public TriggerSkill
{
public:
    Huoshui() : TriggerSkill("huoshui")
    {
        events << GeneralShown << GeneralHidden << GeneralRemoved << EventPhaseStart << Death << EventAcquireSkill << EventLoseSkill;
        frequency = Compulsory;
    }

    void doHuoshui(Room *room, ServerPlayer *zoushi, bool set) const
    {
        if (set && !zoushi->tag["huoshui"].toBool()) {
            foreach(ServerPlayer *p, room->getOtherPlayers(zoushi))
                room->setPlayerDisableShow(p, "hd", "huoshui");

            zoushi->tag["huoshui"] = true;
        } else if (!set && zoushi->tag["huoshui"].toBool()) {
            foreach(ServerPlayer *p, room->getOtherPlayers(zoushi))
                room->removePlayerDisableShow(p, "huoshui");

            zoushi->tag["huoshui"] = false;
        }
    }

    virtual TriggerList triggerable(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        TriggerList r;
        if (player == NULL)
            return r;
        if (triggerEvent != Death && !player->isAlive())
            return r;
        ServerPlayer *c = room->getCurrent();
        if (c == NULL || (triggerEvent != EventPhaseStart && c->getPhase() == Player::NotActive) || c != player)
            return r;

        if ((triggerEvent == GeneralShown || triggerEvent == EventPhaseStart || triggerEvent == EventAcquireSkill) && !player->hasShownSkill(this))
            return r;
        if ((triggerEvent == GeneralShown || triggerEvent == GeneralHidden) && (!player->ownSkill(this) || player->inHeadSkills(this) != data.toBool()))
            return r;
        if (triggerEvent == GeneralRemoved && data.toString() != "zoushi")
            return r;
        if (triggerEvent == EventPhaseStart && !(player->getPhase() == Player::RoundStart || player->getPhase() == Player::NotActive))
            return r;
        if (triggerEvent == Death && (data.value<DeathStruct>().who != player || !player->hasShownSkill(this)))
            return r;
        if ((triggerEvent == EventAcquireSkill || triggerEvent == EventLoseSkill) && data.toString().split(":").first() != objectName())
            return r;

        bool set = false;
        if (triggerEvent == GeneralShown || triggerEvent == EventAcquireSkill || (triggerEvent == EventPhaseStart && player->getPhase() == Player::RoundStart))
            set = true;

        doHuoshui(room, player, set);

        return r;
    }
};

QingchengCard::QingchengCard()
{
    handling_method = Card::MethodDiscard;
}

bool QingchengCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    if ((to_select->isLord() || to_select->getGeneralName().contains("sujiang")) && to_select->getGeneral2() != NULL && to_select->getGeneral2Name().contains("sujiang")) return false;
    return targets.isEmpty() && to_select != Self && to_select->hasShownAllGenerals();
}

void QingchengCard::extraCost(Room *room, const CardUseStruct &card_use) const
{
    if (subcardsLength() > 0 && Sanguosha->getCard(getEffectiveId())->getTypeId() == Card::TypeEquip)
        room->setCardFlag(this, "QingchengEquip");
    SkillCard::extraCost(room, card_use);
}

void QingchengCard::onEffect(const CardEffectStruct &effect) const
{
    ServerPlayer *player = effect.from, *to = effect.to;

    Room *room = player->getRoom();
    QStringList choices;
    if (!to->isLord() && !to->getGeneralName().contains("sujiang"))
        choices << to->getGeneral()->objectName();
    if (to->getGeneral2() != NULL && !to->getGeneral2Name().contains("sujiang"))
        choices << to->getGeneral2()->objectName();

    if (choices.length() == 0)
        return;
    QString choice = choices.first();
    if (choices.length() == 2)
        choice = room->askForGeneral(player, choices, QString(), true, "qingcheng");

    to->hideGeneral(choice == to->getGeneral()->objectName());

    if (hasFlag("QingchengEquip")) {
        QList<ServerPlayer *> other_players = room->getOtherPlayers(player), targets;
        foreach (ServerPlayer *p, other_players) {
            if (to == p || !p->hasShownAllGenerals() || p->getGeneral2() == NULL) continue;
            bool head = !p->isLord() && !p->getGeneralName().contains("sujiang");
            bool deputy = !p->getGeneral2Name().contains("sujiang");
            if (head || deputy)
                targets << p;
        }
        to = room->askForPlayerChosen(player, targets, "qingcheng_second", "qingcheng-second", true);
        if (to != NULL) {
            room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, player->objectName(), to->objectName());
            LogMessage log;
            log.type = "#QingchengSecond";
            log.from = player;
            log.to << to;
            log.arg = "qingcheng";
            room->sendLog(log);

            QStringList choices;
            if (!to->isLord() && !to->getGeneralName().contains("sujiang"))
                choices << to->getGeneral()->objectName();
            if (to->getGeneral2() != NULL && !to->getGeneral2Name().contains("sujiang"))
                choices << to->getGeneral2()->objectName();

            if (choices.length() == 0)
                return;
            QString choice = choices.first();
            if (choices.length() == 2)
                choice = room->askForGeneral(player, choices, QString(), true, "qingcheng");

            to->hideGeneral(choice == to->getGeneral()->objectName());
        }
    }
}

class Qingcheng : public OneCardViewAsSkill
{
public:
    Qingcheng() : OneCardViewAsSkill("qingcheng")
    {
        filter_pattern = ".|black!";
    }

    virtual bool isEnabledAtPlay(const Player *) const
    {
        return true;
    }

    virtual const Card *viewAs(const Card *originalcard) const
    {
        QingchengCard *first = new QingchengCard;
        first->addSubcard(originalcard->getId());
        first->setShowSkill(objectName());
        return first;
    }
};

void StandardPackage::addQunGenerals()
{
    General *huatuo = new General(this, "huatuo", "qun", 3); // QUN 001
    huatuo->addSkill(new Jijiu);
    huatuo->addSkill(new Chuli);

    General *lvbu = new General(this, "lvbu", "qun", 5); // QUN 002
    lvbu->addCompanion("diaochan");
    lvbu->addSkill(new Wushuang);

    General *diaochan = new General(this, "diaochan", "qun", 3, false); // QUN 003
    diaochan->addSkill(new Lijian);
    diaochan->addSkill(new Biyue);

    General *yuanshao = new General(this, "yuanshao", "qun"); // QUN 004
    yuanshao->addCompanion("yanliangwenchou");
    yuanshao->addSkill(new Luanji);
    yuanshao->addSkill(new LuanjiDraw);
    insertRelatedSkills("luanji", "#luanji-draw");

    General *yanliangwenchou = new General(this, "yanliangwenchou", "qun"); // QUN 005
    yanliangwenchou->addSkill(new Shuangxiong);
    yanliangwenchou->addSkill(new ShuangxiongGet);
    insertRelatedSkills("shuangxiong", "#shuangxiong");

    General *jiaxu = new General(this, "jiaxu", "qun", 3); // QUN 007
    jiaxu->addSkill(new Wansha);
    jiaxu->addSkill(new Luanwu);
    jiaxu->addSkill(new Weimu);

    General *pangde = new General(this, "pangde", "qun"); // QUN 008
    pangde->addSkill(new Mashu("pangde"));
    pangde->addSkill(new Jianchu);

    General *zhangjiao = new General(this, "zhangjiao", "qun", 3); // QUN 010
    zhangjiao->addSkill(new Leiji);
    zhangjiao->addSkill(new Guidao);

    General *caiwenji = new General(this, "caiwenji", "qun", 3, false); // QUN 012
    caiwenji->addSkill(new Beige);
    caiwenji->addSkill(new Duanchang);

    General *mateng = new General(this, "mateng", "qun"); // QUN 013
    mateng->addSkill(new Mashu("mateng"));
    mateng->addSkill(new Xiongyi);

    General *kongrong = new General(this, "kongrong", "qun", 3); // QUN 014
    kongrong->addSkill(new Mingshi);
    kongrong->addSkill(new Lirang);

    General *jiling = new General(this, "jiling", "qun"); // QUN 015
    jiling->addSkill(new Shuangren);
    jiling->addSkill(new SlashNoDistanceLimitSkill("shuangren"));
    insertRelatedSkills("shuangren", "#shuangren-slash-ndl");

    General *tianfeng = new General(this, "tianfeng", "qun", 3); // QUN 016
    tianfeng->addSkill(new Sijian);
    tianfeng->addSkill(new Suishi);

    General *panfeng = new General(this, "panfeng", "qun"); // QUN 017
    panfeng->addSkill(new Kuangfu);

    General *zoushi = new General(this, "zoushi", "qun", 3, false); // QUN 018
    zoushi->addSkill(new Huoshui);
    zoushi->addSkill(new Qingcheng);

    addMetaObject<ChuliCard>();
    addMetaObject<LijianCard>();
    addMetaObject<LirangGiveCard>();
    addMetaObject<LuanwuCard>();
    addMetaObject<XiongyiCard>();
    addMetaObject<QingchengCard>();

    skills << new Qingnang << new Mengjin << new LirangGive;
}
