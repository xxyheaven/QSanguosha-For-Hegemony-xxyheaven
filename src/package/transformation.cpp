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

#include "transformation.h"
#include "standard-wu-generals.h"
#include "standard-basics.h"
#include "standard-tricks.h"
#include "client.h"
#include "engine.h"
#include "structs.h"
#include "gamerule.h"
#include "settings.h"
#include "roomthread.h"
#include "json.h"

//xunyou
class Zhiyu : public MasochismSkill
{
public:
    Zhiyu() : MasochismSkill("zhiyu")
    {
    }

    virtual bool canPreshow() const
    {
        return true;
    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *xunyu, QVariant &, ServerPlayer* &) const
    {
        if (MasochismSkill::triggerable(xunyu))
            return QStringList(objectName());
        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *xunyu, QVariant &data, ServerPlayer *) const
    {
        if (xunyu->askForSkillInvoke(this, data)) {
            room->broadcastSkillInvoke(objectName(), xunyu);
            return true;
        }
        return false;
    }

    virtual void onDamaged(ServerPlayer *xunyu, const DamageStruct &damage) const
    {
        Room *room = xunyu->getRoom();
        xunyu->drawCards(1, objectName());
        room->showAllCards(xunyu);
        bool same = true;
        bool isRed = xunyu->getHandcards().first()->isRed();
        foreach (const Card *card, xunyu->getHandcards()) {
            if (card->isRed() != isRed) {
                same = false;
                break;
            }
        }
        if (same && damage.from && !damage.from->isKongcheng() && damage.from->canDiscard(damage.from, "h"))
            room->askForDiscard(damage.from, objectName(), 1, 1);
    }
};

QiceCard::QiceCard()
{
    will_throw = false;
}

bool QiceCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    Card *mutable_card = Sanguosha->cloneCard(Self->tag["qice"].toString());
    if (mutable_card) {
        mutable_card->addSubcards(subcards);
        mutable_card->setCanRecast(false);
        mutable_card->deleteLater();
    }
    if (targets.length() >= subcards.length() && !mutable_card->isKindOf("Collateral")) return false;

    if (mutable_card->isKindOf("AllianceFeast")) {
        if (to_select->getRole() == "careerist") {
            if (subcards.length() < 2)
                return false;
        } else {
            QList<const Player *> targets;
            foreach (const Player *p, Self->getAliveSiblings())
                if (p->isFriendWith(to_select) && !Self->isProhibited(p, mutable_card))
                    targets << p;
            if (targets.length() > subcards.length() - 1) return false;
        }
    }

    return mutable_card && mutable_card->targetFilter(targets, to_select, Self) && !Self->isProhibited(to_select, mutable_card, targets);
}

bool QiceCard::targetFixed() const
{
    Card *mutable_card = Sanguosha->cloneCard(getUserString());
    if (mutable_card) {
        mutable_card->addSubcards(subcards);
        mutable_card->setCanRecast(false);
        mutable_card->deleteLater();
    }
    return mutable_card && mutable_card->targetFixed();
}

bool QiceCard::targetsFeasible(const QList<const Player *> &targets, const Player *Self) const
{
    Card *mutable_card = Sanguosha->cloneCard(Self->tag["qice"].toString());
    if (mutable_card) {
        mutable_card->addSubcards(subcards);
        mutable_card->setCanRecast(false);
        mutable_card->deleteLater();
    }
    if (mutable_card->isKindOf("Collateral")) {
        if (targets.length()/2 > subcards.length()) return false;
    } else {
        if (targets.length() > subcards.length()) return false;
    }
    return mutable_card && mutable_card->targetsFeasible(targets, Self);
}

const Card *QiceCard::validate(CardUseStruct &card_use) const
{
    ServerPlayer *source = card_use.from;

    QString c = toString().split(":").last();   //getUserString() bug here. damn it!

    Card *use_card = Sanguosha->cloneCard(c);
    use_card->setSkillName("qice");
    use_card->addSubcards(subcards);
    use_card->setCanRecast(false);
    use_card->setShowSkill("qice");

    bool available = true;

//    Room *room = source->getRoom();
//    QList<ServerPlayer *> targets;
//    if (use_card->isKindOf("AwaitExhausted")) {
//        foreach (ServerPlayer *p, room->getAlivePlayers())
//            if (!source->isProhibited(p, use_card) && source->isFriendWith(p))
//                targets << p;
//     } else if (use_card->getSubtype() == "global_effect" && !use_card->isKindOf("FightTogether")) {
//        foreach (ServerPlayer *p, room->getAlivePlayers())
//            if (!source->isProhibited(p, use_card))
//                targets << p;
//    } else if (use_card->isKindOf("FightTogether")) {
//        QStringList big_kingdoms = source->getBigKingdoms("qice", MaxCardsType::Normal);
//        QList<ServerPlayer *> bigs, smalls;
//        foreach (ServerPlayer *p, room->getAllPlayers()) {
//            if (source->isProhibited(p, use_card)) continue;
//            QString kingdom = p->objectName();
//            if (big_kingdoms.length() == 1 && big_kingdoms.first().startsWith("sgs")) { // for JadeSeal
//                if (big_kingdoms.contains(kingdom))
//                    bigs << p;
//                else
//                    smalls << p;
//            } else {
//                if (!p->hasShownOneGeneral()) {
//                    smalls << p;
//                    continue;
//                }
//                if (p->getRole() == "careerist")
//                    kingdom = "careerist";
//                else
//                    kingdom = p->getKingdom();
//                if (big_kingdoms.contains(kingdom))
//                    bigs << p;
//                else
//                    smalls << p;
//            }
//        }
//        if ((smalls.length() > 0 && smalls.length() < bigs.length() && bigs.length() > 0) || (smalls.length() > 0 && bigs.length() == 0))
//            targets = smalls;
//        else if ((smalls.length() > 0 && smalls.length() > bigs.length() && bigs.length() > 0) || (smalls.length() == 0 && bigs.length() > 0))
//            targets = bigs;
//        else if (smalls.length() == bigs.length())
//            targets = smalls;
//    } else if (use_card->getSubtype() == "aoe" && !use_card->isKindOf("BurningCamps")) {
//        foreach (ServerPlayer *p, room->getOtherPlayers(source))
//            if (!source->isProhibited(p, use_card))
//                targets << p;
//    } else if (use_card->isKindOf("BurningCamps")) {
//        QList<const Player *> players = source->getNextAlive()->getFormation();
//        foreach (const Player *p, players)
//            if (!source->isProhibited(p, use_card))
//                targets << room->findPlayerbyobjectName(p->objectName());
//    }
//    if (targets.length() > subcards.length()) return NULL;

//    foreach(ServerPlayer *to, card_use.to)
//        if (source->isProhibited(to, use_card)) {
//            available = false;
//            break;
//        }
    available = available && use_card->isAvailable(source);
    use_card->deleteLater();
    if (!available) return NULL;
    return use_card;
}

class QiceVS : public ZeroCardViewAsSkill
{
public:
    QiceVS() : ZeroCardViewAsSkill("qice")
    {
    }

    virtual const Card *viewAs() const
    {
        QString c = Self->tag["qice"].toString();
        if (c != "") {
            QiceCard *card = new QiceCard;
            card->addSubcards(Self->getHandcards());
            card->setUserString(c);
            return card;
        } else
            return NULL;
    }

    virtual bool isEnabledAtPlay(const Player *player) const
    {
        return !player->isKongcheng() && !player->hasUsed("QiceCard") && player->hasShownSkill(objectName());
    }
};

class Qice : public TriggerSkill
{
public:
    Qice() : TriggerSkill("qice")
    {
        events << CardFinished;
        guhuo_type = "t";
        view_as_skill = new QiceVS;
    }

    virtual bool canShowInPlay() const
    {
        return true;
    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (use.card->getTypeId() == Card::TypeTrick && use.card->getSkillName(true) == "qice" && player->isAlive() && player->canTransform()) {
            return QStringList(objectName());
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        if (room->askForChoice(player, "transform", "yes+no", QVariant(), "@transform-ask:::"+objectName()) == "yes") {
            room->broadcastSkillInvoke("transform", player->isMale());
            room->setPlayerProperty(player, "transformUsed", QVariant(true));
            return true;
        }

        return false;
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        room->transformDeputyGeneral(player);
        return false;
    }
};

//bianhuanhou

class Wanwei : public TriggerSkill
{
public:
    Wanwei() : TriggerSkill("wanwei")
    {
        events << BeforeCardsMove;
    }

    virtual int getPriority() const
    {
        return 6;
    }

    virtual QStringList triggerable(TriggerEvent , Room *, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
    {
        if (TriggerSkill::triggerable(player)) {
            CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
            if (move.from == player && (move.from_places.contains(Player::PlaceHand) || move.from_places.contains(Player::PlaceEquip))
                    && ((move.reason.m_reason == CardMoveReason::S_REASON_DISMANTLE && move.reason.m_playerId != move.reason.m_targetId)
                    || (move.to && move.to != player && move.to_place == Player::PlaceHand
                    && move.reason.m_reason != CardMoveReason::S_REASON_GIVE && move.reason.m_reason != CardMoveReason::S_REASON_SWAP))) {
                if (move.card_ids.length() > player->getHandcardNum() + player->getEquips().length()) return QStringList();
                return QStringList(objectName());
            }
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
        CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
        int num = move.card_ids.length();
        QList<int> result = room->askForExchange(player, objectName(), num, num, "@wanwei:::" + QString::number(num), "", ".");
        move.from_places.clear();
        foreach (int id, result) {
            move.from_places << room->getCardPlace(id);
        }
        move.card_ids = result;
        data = QVariant::fromValue(move);
        return false;
    }
};

class Yuejian : public TriggerSkill
{
public:
    Yuejian() : TriggerSkill("yuejian")
    {
        events << EventPhaseStart;
        frequency = Compulsory;
    }

    virtual bool canPreshow() const
    {
        return true;
    }

    virtual TriggerList triggerable(TriggerEvent , Room *room, ServerPlayer *player, QVariant &) const
    {
        if (player->getPhase() == Player::Discard) {
            QList<ServerPlayer *> huanghous = room->findPlayersBySkillName(objectName());
            TriggerList skill_list;
            foreach (ServerPlayer *huanghou, huanghous) {
                if (huanghou->isFriendWith(player)) {
                    bool can_invoke = true;
                    QStringList assignee_list = player->property("usecard_targets").toString().split("+");
                    foreach (ServerPlayer *to, room->getAllPlayers(true)) {
                        if (assignee_list.contains(to->objectName()) && to->hasShownOneGeneral() && !huanghou->isFriendWith(to)) {
                            can_invoke = false;
                            break;
                        }
                    }

                    if (can_invoke)
                        skill_list.insert(huanghou, QStringList(objectName()));
                }
            }
            return skill_list;
        }
        return TriggerList();
    }

    virtual bool cost(TriggerEvent, Room* room, ServerPlayer *player, QVariant &, ServerPlayer *huanghou) const
    {
        bool invoke = false;
        if (huanghou->hasShownSkill(objectName())) {
            invoke = true;
            room->sendCompulsoryTriggerLog(huanghou, objectName());
        } else
            invoke = huanghou->askForSkillInvoke(this, QVariant::fromValue(player));

        if (invoke) {
            room->broadcastSkillInvoke(objectName(), huanghou);
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        room->setPlayerFlag(player, "jianyue_keep");
        return false;
    }
};

class YuejianMaxCards : public MaxCardsSkill
{
public:
    YuejianMaxCards() : MaxCardsSkill("#yuejian-maxcard")
    {
    }

    virtual int getFixed(const Player *target) const
    {
        if (target->hasFlag("jianyue_keep"))
            return target->getMaxHp();
        return -1;
    }
};

//liguo
XiongsuanCard::XiongsuanCard()
{
    mute = true;
}

bool XiongsuanCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.isEmpty() && Self->isFriendWith(to_select);
}

void XiongsuanCard::onUse(Room *room, const CardUseStruct &card_use) const
{
    room->setPlayerMark(card_use.from, "@fierce", 0);
    room->broadcastSkillInvoke("xiongsuan", card_use.from);
    room->doSuperLightbox("lijueguosi", "xiongsuan");

    Card::onUse(room, card_use);
}

void XiongsuanCard::onEffect(const CardEffectStruct &effect) const
{
    Room *room = effect.to->getRoom();
    room->damage(DamageStruct("xiongsuan", effect.from, effect.to));
    if (effect.from->isAlive()) {
        effect.from->drawCards(3);
        if (effect.to->isAlive()) {
            QStringList limited_skills;
            QList<const Skill *> skills = effect.to->getVisibleSkillList();
            foreach (const Skill *skill, skills) {
                if (skill->getFrequency() == Skill::Limited && !skill->getLimitMark().isEmpty() && effect.to->getMark(skill->getLimitMark()) == 0)
                    limited_skills.append(skill->objectName());
            }
            if (!limited_skills.isEmpty()) {
                QString skill_name = room->askForChoice(effect.from, "xiongsuan", limited_skills.join("+"), QVariant(), "@xiongsuan-reset::"+effect.to->objectName());
                effect.to->tag["XiongsuanSkill"] = skill_name;
            }
        }
    }
}

class Xiongsuan : public OneCardViewAsSkill
{
public:
    Xiongsuan() : OneCardViewAsSkill("xiongsuan")
    {
        frequency = Limited;
        limit_mark = "@fierce";
        filter_pattern = ".|.|.|hand!";
    }

    virtual const Card *viewAs(const Card *originalCard) const
    {
        XiongsuanCard *card = new XiongsuanCard;
        card->addSubcard(originalCard);
        card->setShowSkill(objectName());
        return card;
    }

    virtual bool isEnabledAtPlay(const Player *player) const
    {
        return player->getMark("@fierce") >= 1;
    }
};

class XiongsuanReset : public TriggerSkill
{
public:
    XiongsuanReset() : TriggerSkill("#xiongsuan-reset")
    {
        events << EventPhaseChanging << EventPhaseStart;
        frequency = Compulsory;
    }

    virtual void record(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &) const
    {
        if (triggerEvent == EventPhaseStart && player->getPhase() == Player::NotActive) {
            foreach (ServerPlayer *p, room->getAllPlayers()) {
                p->tag.remove("XiongsuanSkill");
            }
        }
    }

    virtual QStringList triggerable(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        if (triggerEvent == EventPhaseChanging && data.value<PhaseChangeStruct>().to == Player::NotActive && player->isAlive()) {
            foreach (ServerPlayer *p, room->getAllPlayers()) {
                QString skill_name = p->tag["XiongsuanSkill"].toString();
                const Skill *skill = Sanguosha->getSkill(skill_name);
                if (skill && !skill->getLimitMark().isEmpty() && p->getMark(skill->getLimitMark()) == 0)
                    return QStringList(objectName());
            }
        }
        return QStringList();
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *, QVariant &, ServerPlayer *) const
    {
        foreach (ServerPlayer *p, room->getAllPlayers()) {
            QString skill_name = p->tag["XiongsuanSkill"].toString();
            const Skill *skill = Sanguosha->getSkill(skill_name);
            if (skill && !skill->getLimitMark().isEmpty() && p->getMark(skill->getLimitMark()) == 0) {
                LogMessage log;
                log.type = "#XiongsuanReset";
                log.from = p;
                log.arg = skill_name;
                room->sendLog(log);
                room->setPlayerMark(p, skill->getLimitMark(), 1);
            }
        }
        return false;
    }
};

class HuashenViewAsSkill : public ZeroCardViewAsSkill
{
public:
    HuashenViewAsSkill() : ZeroCardViewAsSkill("huashen")
    {
    }

    virtual const Card *viewAs() const
    {
        return NULL;
    }
};

//zuoci
class Huashen : public PhaseChangeSkill
{
public:
    Huashen() : PhaseChangeSkill("huashen")
    {
        view_as_skill = new HuashenViewAsSkill;
    }

    virtual bool canPreshow() const
    {
        return true;
    }

    static void AcquireGenerals(ServerPlayer *zuoci, int n, QString reason)
    {
        Room *room = zuoci->getRoom();
        QStringList huashens;
        if (!zuoci->property("Huashens").toString().isEmpty())
            huashens = zuoci->property("Huashens").toString().split("+");
        QStringList acquired = GetAvailableGenerals(zuoci, n);
        if (n > 2) {

            LogMessage log;
            log.type = "#VeiwHuashenDetail";
            log.from = zuoci;
            log.arg = acquired.join("\\, \\");
            room->doNotify(zuoci, QSanProtocol::S_COMMAND_LOG_SKILL, log.toVariant());

            LogMessage log2;
            log2.type = "#VeiwHuashen";
            log2.from = zuoci;
            log2.arg = QString::number(n);
            room->doBroadcastNotify(room->getOtherPlayers(zuoci), QSanProtocol::S_COMMAND_LOG_SKILL, log2.toVariant());

            QString general_name = room->askForGeneral(zuoci, acquired, QString(), false, reason, QVariant(), false, false);

            acquired = general_name.split("+");
        }

        LogMessage log;
        log.type = "#GetHuashenDetail";
        log.from = zuoci;
        log.arg = acquired.join("\\, \\");
        room->doNotify(zuoci, QSanProtocol::S_COMMAND_LOG_SKILL, log.toVariant());

        LogMessage log2;
        log2.type = "#GetHuashen";
        log2.from = zuoci;
        log2.arg = QString::number(acquired.length());
        room->doBroadcastNotify(room->getOtherPlayers(zuoci), QSanProtocol::S_COMMAND_LOG_SKILL, log2.toVariant());

        QStringList hidden;
        for (int i = 0; i < acquired.length(); i++) hidden << "unknown";
        foreach (ServerPlayer *p, room->getAllPlayers()) {
            if (p == zuoci)
                room->doAnimate(QSanProtocol::S_ANIMATE_HUASHEN, zuoci->objectName(), acquired.join(":"), QList<ServerPlayer *>() << p);
            else
                room->doAnimate(QSanProtocol::S_ANIMATE_HUASHEN, zuoci->objectName(), hidden.join(":"), QList<ServerPlayer *>() << p);
        }


        foreach (QString name, acquired) {
            huashens << name;
            room->handleUsedGeneral(name);
        }
        room->setPlayerProperty(zuoci, "Huashens", huashens.join("+"));
        JsonArray arg;
        arg << QSanProtocol::S_GAME_EVENT_HUASHEN << zuoci->objectName() << huashens.join("+");
        room->doBroadcastNotify(QSanProtocol::S_COMMAND_LOG_EVENT, arg);

    }

    static QStringList GetAvailableGenerals(ServerPlayer *zuoci, int n)
    {
        Room *room = zuoci->getRoom();
        QStringList available;
        foreach (QString name, Sanguosha->getLimitedGeneralNames())
            if (!name.startsWith("lord_") && !room->getUsedGeneral().contains(name))
                available << name;

        qShuffle(available);
        if (available.isEmpty()) return QStringList();
        n = qMin(n, available.length());

        return available.mid(0, n);
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

    virtual bool onPhaseChange(ServerPlayer *zuoci) const
    {
        Room *room = zuoci->getRoom();
        QStringList huashens;
        if (!zuoci->property("Huashens").toString().isEmpty())
            huashens = zuoci->property("Huashens").toString().split("+");
        if (huashens.length() < 2) {
            AcquireGenerals(zuoci, 5, objectName());
        } else {
            QString result = room->askForGeneral(zuoci, huashens, QString(), true, objectName(), QVariant(), false);

            room->dropHuashenCard(zuoci, result);

            AcquireGenerals(zuoci, 1, objectName());
        }
        return false;
    }
};

class HuashenVH : public ViewHasSkill
{
public:
    HuashenVH() : ViewHasSkill("huashen-viewhas")
    {
        global = true;
    }

    virtual bool ViewHas(const Player *zuoci, const QString &skill_name, const QString &flag) const
    {
        if (flag != "skill" || !zuoci->hasFlag("HuanshenSkillChecking")) return false;
        const Skill *skill = Sanguosha->getSkill(skill_name);

        if (skill == NULL || (skill->getFrequency() != Skill::Frequent && skill->getFrequency() != Skill::NotFrequent)
                || !skill->getRelatePlace().isEmpty() || skill->inherits("BattleArraySkill")) return false;

        QStringList huashens;
        if (!zuoci->property("Huashens").toString().isEmpty())
            huashens = zuoci->property("Huashens").toString().split("+");
        foreach (QString name, huashens) {
            const General *general = Sanguosha->getGeneral(name);
            if (general && general->hasSkill(skill_name))
                return true;
        }
        return false;
    }
};

class HuashenClear : public DetachEffectSkill
{
public:
    HuashenClear() : DetachEffectSkill("huashen")
    {
    }
    virtual void onSkillDetached(Room *room, ServerPlayer *player, QVariant &) const
    {
        QStringList huashens;
        if (!player->property("Huashens").toString().isEmpty())
            huashens = player->property("Huashens").toString().split("+");
        foreach (QString name, huashens)
            room->handleUsedGeneral("-" + name);
        JsonArray arg;
        arg << QSanProtocol::S_GAME_EVENT_HUASHEN << player->objectName() << QString();
        room->doBroadcastNotify(QSanProtocol::S_COMMAND_LOG_EVENT, arg);
        room->setPlayerProperty(player, "Huashens", QString());
    }
};

class Xinsheng : public MasochismSkill
{
public:
    Xinsheng() : MasochismSkill("xinsheng")
    {
        frequency = Frequent;
    }

    virtual bool canPreshow() const
    {
        return true;
    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *zuoci, QVariant &, ServerPlayer* &) const
    {
        if (MasochismSkill::triggerable(zuoci))
            return QStringList(objectName());
        return QStringList();
    }
    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *zuoci, QVariant &data, ServerPlayer *) const
    {
        if (zuoci->askForSkillInvoke(this, data)) {
            room->broadcastSkillInvoke(objectName(), zuoci);
            return true;
        }
        return false;
    }

    virtual void onDamaged(ServerPlayer *zuoci, const DamageStruct &) const
    {
        Huashen::AcquireGenerals(zuoci, 1, objectName());
    }
};

//shamoke

class JiliRecord : public TriggerSkill
{
public:
    JiliRecord() : TriggerSkill("#jili-record")
    {
        events << CardUsed << CardResponded << EventPhaseChanging;
        global = true;
    }

    virtual void record(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (triggerEvent == CardUsed || triggerEvent == CardResponded) {
            const Card *card = NULL;
            if (triggerEvent == CardUsed)
                card = data.value<CardUseStruct>().card;
            else if (triggerEvent == CardResponded)
                card = data.value<CardResponseStruct>().m_card;
            if (card == NULL) return;

            if (card->getTypeId() != Card::TypeSkill)
                room->addPlayerMark(player, "jili");
        } else if (triggerEvent == EventPhaseChanging) {
            PhaseChangeStruct change = data.value<PhaseChangeStruct>();
            if (change.to == Player::NotActive) {
                foreach (ServerPlayer *p, room->getAlivePlayers()) {
                    room->setPlayerMark(p, "jili", 0);
                }
            }
        }
    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *, QVariant &, ServerPlayer* &) const
    {
        return QStringList();
    }

};

class Jili : public TriggerSkill
{
public:
    Jili() : TriggerSkill("jili")
    {
        events << CardUsed << CardResponded;
    }

    virtual QStringList triggerable(TriggerEvent triggerEvent, Room *, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
    {
        if (TriggerSkill::triggerable(player)) {
            const Card *card = NULL;
            if (triggerEvent == CardUsed)
                card = data.value<CardUseStruct>().card;
            else if (triggerEvent == CardResponded)
                card = data.value<CardResponseStruct>().m_card;
            if (card == NULL) return QStringList();

            if (card->getTypeId() != Card::TypeSkill && player->getMark("jili") == player->getAttackRange()) {
                return QStringList(objectName());
            }
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
        player->drawCards(player->getAttackRange(), "jili");
        return false;
    }
};

//masu
SanyaoCard::SanyaoCard()
{
}

bool SanyaoCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    if (!targets.isEmpty()) return false;
    QList<const Player *> players = Self->getAliveSiblings();
    players << Self;
    int max = -1000;
    foreach (const Player *p, players) {
        if (max < p->getHp())
            max = p->getHp();
    }
    return to_select->getHp() == max;
}

void SanyaoCard::onEffect(const CardEffectStruct &effect) const
{
    effect.from->getRoom()->damage(DamageStruct("sanyao", effect.from, effect.to));
}

class Sanyao : public OneCardViewAsSkill
{
public:
    Sanyao() : OneCardViewAsSkill("sanyao")
    {
        filter_pattern = ".!";
    }

    virtual bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("SanyaoCard");
    }

    virtual const Card *viewAs(const Card *originalcard) const
    {
        SanyaoCard *first = new SanyaoCard;
        first->addSubcard(originalcard->getId());
        first->setSkillName(objectName());
        first->setShowSkill(objectName());
        return first;
    }
};

class Zhiman : public TriggerSkill
{
public:
    Zhiman() : TriggerSkill("zhiman")
    {
        events << DamageCaused;
    }
    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
    {
        if (TriggerSkill::triggerable(player)) {
            DamageStruct damage = data.value<DamageStruct>();
            if (damage.to && player != damage.to)
                return QStringList(objectName());
        }
        return QStringList();
    }
    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        player->tag["zhiman_data"] = data;  // for AI
        bool invoke = player->askForSkillInvoke(this, QVariant::fromValue(damage.to));
        player->tag.remove("zhiman_data");
        if (invoke) {
            room->broadcastSkillInvoke(objectName(), 1, player);
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        ServerPlayer *to = damage.to;
        LogMessage log;
        log.type = "#Zhiman";
        log.from = player;
        log.arg = objectName();
        log.to << to;
        room->sendLog(log);
        room->setPlayerMark(to, objectName(), 1);
        to->tag["zhiman_from"] = QVariant::fromValue(player);
        return true;
    }
};

class ZhimanSecond : public TriggerSkill
{
public:
    ZhimanSecond() : TriggerSkill("zhiman-second")
    {
        events << DamageComplete;
        global = true;
    }
    virtual TriggerList triggerable(TriggerEvent, Room *, ServerPlayer *player, QVariant &data) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        if (damage.to == player && player->getMark("zhiman") > 0) {
            ServerPlayer *masu = player->tag["zhiman_from"].value<ServerPlayer *>();
            if (damage.from == masu) {
                TriggerList skill_list;
                skill_list.insert(masu, QStringList(objectName()));
                return skill_list;
            }
        }
        return TriggerList();
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *to, QVariant &, ServerPlayer *player) const
    {
        to->tag.remove("zhiman_from");
        room->setPlayerMark(to, "zhiman", 0);
        if (player->canGetCard(to, "ej")) {
            int card_id = room->askForCardChosen(player, to, "ej", "zhiman", false, Card::MethodGet);
            CardMoveReason reason(CardMoveReason::S_REASON_EXTRACTION, player->objectName());
            room->obtainCard(player, Sanguosha->getCard(card_id), reason, false);
        }
        if (to->isFriendWith(player) && to->canTransform() &&
                (room->askForChoice(to, "transform", "yes+no", QVariant(), "@transform-ask:::"+objectName()) == "yes")) {
            room->setPlayerProperty(to, "transformUsed", QVariant(true));
            room->broadcastSkillInvoke("transform", to->isMale());
            room->transformDeputyGeneral(to);
        }
        return false;
    }
};

//LengTong
class Xuanlue : public TriggerSkill
{
public:
    Xuanlue() : TriggerSkill("xuanlue")
    {
        events << CardsMoveOneTime;
        frequency = Frequent;
    }

    virtual bool canPreshow() const
    {
        return true;
    }

    virtual QStringList triggerable(TriggerEvent, Room *room, ServerPlayer *lengtong, QVariant &data, ServerPlayer* &) const
    {
        if (!TriggerSkill::triggerable(lengtong)) return QStringList();
        CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
        if (move.from == lengtong && move.from_places.contains(Player::PlaceEquip)) {
            QList<ServerPlayer *> other_players = room->getOtherPlayers(lengtong);
            foreach (ServerPlayer *p, other_players) {
                if (lengtong->canDiscard(p, "he"))
                    return QStringList(objectName());
            }
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *lengtong, QVariant &, ServerPlayer *) const
    {
        QList<ServerPlayer *> other_players = room->getOtherPlayers(lengtong);
        QList<ServerPlayer *> targets;
        foreach (ServerPlayer *p, other_players) {
            if (lengtong->canDiscard(p, "he"))
                targets << p;
        }
        ServerPlayer *to = room->askForPlayerChosen(lengtong, targets, objectName(), "xuanlue-invoke", true, true);
        if (to) {
            lengtong->tag["xuanlue_target"] = QVariant::fromValue(to);
            room->broadcastSkillInvoke(objectName(), lengtong);
            return true;
        } else lengtong->tag.remove("xuanlue_target");
        /*
        if (room->askForSkillInvoke(lengtong, objectName())) {
            room->broadcastSkillInvoke(objectName(), lengtong);
            return true;
        }
        */
        return false;

    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *lengtong, QVariant &, ServerPlayer *) const
    {
        ServerPlayer *to = lengtong->tag["xuanlue_target"].value<ServerPlayer *>();
        lengtong->tag.remove("xuanlue_target");
        if (to && lengtong->canDiscard(to, "he")) {
            int card_id = room->askForCardChosen(lengtong, to, "he", objectName(), false, Card::MethodDiscard);
            CardMoveReason reason = CardMoveReason(CardMoveReason::S_REASON_DISMANTLE, lengtong->objectName(), to->objectName(), objectName(), NULL);
            room->throwCard(Sanguosha->getCard(card_id), reason, to, lengtong);
        }
        /*
        QList<int> ids = room->GlobalCardChosen(lengtong, room->getOtherPlayers(lengtong), "he", objectName(), "@xuanlue", 1, 1,
            Room::OnebyOne, false, Card::MethodDiscard);
        ServerPlayer *to = room->getCardOwner(ids.first());
        CardMoveReason reason = CardMoveReason(CardMoveReason::S_REASON_DISMANTLE, lengtong->objectName(), to->objectName(), objectName(), NULL);
        room->throwCard(Sanguosha->getCard(ids.first()), reason, to, lengtong);
        */
        return false;
    }
};

YongjinCard::YongjinCard()
{
    mute = true;
}

bool YongjinCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *) const
{
    if (targets.length() == 0)
        return to_select->hasEquip();
    else if (targets.length() == 1) {
        for (int i = 0; i < S_EQUIP_AREA_LENGTH; i++) {
            if (targets.first()->getEquip(i) && !to_select->getEquip(i))
                return true;
        }
    }
    return false;
}

bool YongjinCard::targetsFeasible(const QList<const Player *> &targets, const Player *) const
{
    return targets.length() == 2;
}

void YongjinCard::onUse(Room *room, const CardUseStruct &card_use) const
{
    ServerPlayer *lingtong = card_use.from;

    QVariant data = QVariant::fromValue(card_use);
    RoomThread *thread = room->getThread();

    thread->trigger(PreCardUsed, room, lingtong, data);

    if (!lingtong->hasFlag("YongjinContinue")) {
        LogMessage log;
        log.from = lingtong;
        log.to << card_use.to;
        log.type = "#UseCard";
        log.card_str = toString();
        room->sendLog(log);

        room->broadcastSkillInvoke("yongjin", lingtong);
        room->removePlayerMark(lingtong, "@brave");
        room->doSuperLightbox("lingtong", "yongjin");

        if (lingtong->ownSkill("yongjin") && !lingtong->hasShownSkill("yongjin"))
            lingtong->showGeneral(lingtong->inHeadSkills("yongjin"));
    }
    thread->trigger(CardUsed, room, lingtong, data);
    thread->trigger(CardFinished, room, lingtong, data);
}

void YongjinCard::use(Room *room, ServerPlayer *lingtong, QList<ServerPlayer *> &targets) const
{
    ServerPlayer *from = targets.at(0);
    ServerPlayer *to = targets.at(1);
    QList<int> disabled_ids;
    bool can_select = false;
    for (int i = 0; i < S_EQUIP_AREA_LENGTH; i++) {
        const EquipCard *e_card = from->getEquip(i);
        if (e_card) {
            if (to->getEquip(i))
                disabled_ids.append(e_card->getEffectiveId());
            else
                can_select = true;
        }
    }
    if (can_select) {
        int card_id = room->askForCardChosen(lingtong, from, "e", "yongjin", false, Card::MethodNone, disabled_ids);
        room->moveCardTo(Sanguosha->getCard(card_id), from, to, Player::PlaceEquip, CardMoveReason(CardMoveReason::S_REASON_TRANSFER, lingtong->objectName(), "yongjin", QString()));
    }
    if (!lingtong->hasFlag("YongjinContinue")) {
        room->setPlayerFlag(lingtong, "YongjinContinue");
        if (room->askForUseCard(lingtong, "@@yongjin_next", "@yongjin-next", -1, Card::MethodNone))
            room->askForUseCard(lingtong, "@@yongjin_next", "@yongjin-next", -1, Card::MethodNone);
        room->setPlayerFlag(lingtong, "-YongjinContinue");
    }
}

class YongjinNext : public ZeroCardViewAsSkill
{
public:
    YongjinNext() : ZeroCardViewAsSkill("yongjin_next")
    {
        response_pattern = "@@yongjin_next";
    }

    virtual const Card *viewAs() const
    {
        return new YongjinCard;
    }
};

class Yongjin : public ZeroCardViewAsSkill
{
public:
    Yongjin() : ZeroCardViewAsSkill("yongjin")
    {
        frequency = Limited;
        limit_mark = "@brave";
    }

    virtual const Card *viewAs() const
    {
        YongjinCard *card = new YongjinCard;
        card->setShowSkill(objectName());
        return card;
    }

    virtual bool isEnabledAtPlay(const Player *player) const
    {
        return player->getMark("@brave") >= 1;
    }
};

//lvfan
DiaoduequipCard::DiaoduequipCard()
{
    will_throw = false;
    handling_method = Card::MethodNone;
}

bool DiaoduequipCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    if (targets.isEmpty() && to_select != Self && Self->isFriendWith(to_select)) {
        const Card *card = Sanguosha->getCard(subcards.first());
        const EquipCard *equip = qobject_cast<const EquipCard *>(card->getRealCard());
        int equip_index = static_cast<int>(equip->location());
        return (!to_select->getEquip(equip_index));
    }
    return false;
}

void DiaoduequipCard::onEffect(const CardEffectStruct &effect) const
{
    ServerPlayer *player = effect.from, *to = effect.to;
    Room *room = player->getRoom();

    LogMessage log;
    log.type = "$DiaoduEquip";
    log.from = to;
    log.card_str = QString::number(getEffectiveId());
    room->sendLog(log);

    room->moveCardTo(this, player, to, Player::PlaceEquip, CardMoveReason(CardMoveReason::S_REASON_CHANGE_EQUIP, player->objectName(), "diaodu", QString()));
}

class Diaoduequip : public OneCardViewAsSkill
{
public:
    Diaoduequip() : OneCardViewAsSkill("diaodu_equip")
    {
        filter_pattern = "EquipCard!";
        response_pattern = "@@diaodu_equip";
        response_or_use = true;
    }

    virtual bool isEnabledAtPlay(const Player *) const
    {
        return false;
    }

    virtual const Card *viewAs(const Card *originalcard) const
    {
        if (Self->hasEquip(originalcard)) {
            DiaoduequipCard *first = new DiaoduequipCard;
            first->addSubcard(originalcard->getId());
            return first;
        }
        return originalcard;
    }
};

DiaoduCard::DiaoduCard()
{
    target_fixed = true;
    mute = true;
}

void DiaoduCard::onUse(Room *room, const CardUseStruct &card_use) const
{
    room->broadcastSkillInvoke("diaodu", card_use.from);

    CardUseStruct new_use = card_use;
    new_use.to << card_use.from;
    if (card_use.from->getRole() != "careerist")
        foreach (ServerPlayer *p, room->getOtherPlayers(card_use.from))
            if (card_use.from->isFriendWith(p))
                new_use.to << p;
    room->sortByActionOrder(new_use.to);

    Card::onUse(room, new_use);
}

void DiaoduCard::onEffect(const CardEffectStruct &effect) const
{
    Room *room = effect.to->getRoom();
    room->askForUseCard(effect.to, "@@diaodu_equip", "@Diaodu-distribute", -1, Card::MethodUse);
}

class Diaodu : public ZeroCardViewAsSkill
{
public:
    Diaodu() : ZeroCardViewAsSkill("diaodu")
    {
    }
    virtual bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("DiaoduCard");
    }
    virtual const Card *viewAs() const
    {
        DiaoduCard *dd = new DiaoduCard;
        dd->setShowSkill(objectName());
        return dd;
    }
};

class Diancai : public TriggerSkill
{
public:
    Diancai() : TriggerSkill("diancai")
    {
        events << CardsMoveOneTime << EventPhaseEnd << EventPhaseStart;
    }

    virtual bool canPreshow() const
    {
        return true;
    }

    virtual void record(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (triggerEvent == EventPhaseStart) {
            if (player->getPhase() == Player::NotActive)
                foreach (ServerPlayer *p, room->getAlivePlayers())
                    p->setMark(objectName(), 0);
            return;
        }
        if (!(triggerEvent == CardsMoveOneTime && room->getCurrent() && room->getCurrent()->getPhase() == Player::Play))
            return;

        CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
        if (move.from == player && (move.from_places.contains(Player::PlaceHand) || move.from_places.contains(Player::PlaceEquip))
                && !(move.to == player && (move.to_place == Player::PlaceHand || move.to_place == Player::PlaceEquip)))
            player->setMark(objectName(), player->getMark(objectName()) + move.card_ids.length());
    }

    virtual TriggerList triggerable(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &) const
    {
        if (!(triggerEvent == EventPhaseEnd && player->getPhase() == Player::Play)) return TriggerList();
        QList<ServerPlayer *> players = room->findPlayersBySkillName(objectName());
        TriggerList skill_list;
        foreach (ServerPlayer *p, players) {
            if (TriggerSkill::triggerable(p) && p != player)
                if (p->getMark(objectName()) >= qMax(p->getHp(), 1))
                    skill_list.insert(p, QStringList(objectName()));
        }
        return skill_list;
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *, QVariant &, ServerPlayer *ask_who) const
    {
        if (ask_who->askForSkillInvoke(this)) {
            room->broadcastSkillInvoke(objectName(), ask_who);
            return true;
        }
        return false;
    }
    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *, QVariant &, ServerPlayer *ask_who) const
    {
        if (ask_who->getHandcardNum() < ask_who->getMaxHp())
            ask_who->drawCards(ask_who->getMaxHp() - ask_who->getHandcardNum(), objectName());

        if (ask_who->canTransform() && room->askForChoice(ask_who, "transform", "yes+no", QVariant(), "@transform-ask:::"+objectName()) == "yes") {
            room->setPlayerProperty(ask_who, "transformUsed", QVariant(true));
            room->broadcastSkillInvoke("transform", ask_who->isMale());
            room->transformDeputyGeneral(ask_who);
        }
        return false;
    }
};

//lord_sunquan
LianziCard::LianziCard()
{
    target_fixed = true;
    will_throw = true;
}

void LianziCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const
{
    int x = source->getPile("flame_map").length();
    foreach (ServerPlayer *p, room->getAllPlayers()) {
        if (p->getSeemingKingdom() == "wu")
            x = x + p->getEquips().length();
    }

    QList<int> ids = room->getNCards(x);
    if (x == 0) return;

    CardsMoveStruct move(ids, source, Player::PlaceTable,
        CardMoveReason(CardMoveReason::S_REASON_TURNOVER, source->objectName(), "lianzi", QString()));
    room->moveCardsAtomic(move, true);

    room->getThread()->delay();
    room->getThread()->delay();

    Card::CardType type = Sanguosha->getCard(this->getEffectiveId())->getTypeId();

    QList<int> card_to_throw;
    QList<int> card_to_gotback;
    for (int i = 0; i < x; i++) {
        if (Sanguosha->getCard(ids[i])->getTypeId() == type)
            card_to_gotback << ids[i];
        else
            card_to_throw << ids[i];
    }
    if (!card_to_gotback.isEmpty()) {
        DummyCard dummy2(card_to_gotback);
        CardMoveReason reason(CardMoveReason::S_REASON_GOTBACK, source->objectName());
        room->obtainCard(source, &dummy2, reason);
    }
    if (!card_to_throw.isEmpty()) {
        DummyCard dummy(card_to_throw);
        CardMoveReason reason(CardMoveReason::S_REASON_NATURAL_ENTER, source->objectName(), "lianzi", QString());
        room->throwCard(&dummy, reason, NULL);
    }
    if (card_to_gotback.length() > 3)
        room->handleAcquireDetachSkills(source, "-lianzi|zhiheng");
}

class Lianzi : public OneCardViewAsSkill
{
public:
    Lianzi() : OneCardViewAsSkill("lianzi")
    {
        filter_pattern = ".|.|.|hand!";
    }

    virtual bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("LianziCard");
    }

    virtual const Card *viewAs(const Card *originalcard) const
    {
        LianziCard *first = new LianziCard;
        first->addSubcard(originalcard->getId());
        first->setSkillName(objectName());
        first->setShowSkill(objectName());
        return first;
    }
};

class Jubao : public TriggerSkill
{
public:
    Jubao() : TriggerSkill("jubao")
    {
        events << EventPhaseStart;
        frequency = Compulsory;
    }

    virtual QStringList triggerable(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer* &) const
    {
        if (player->getPhase() == Player::Finish && TriggerSkill::triggerable(player)) {
            foreach (ServerPlayer *p, room->getAlivePlayers()) {
                if (p->getTreasure() && p->getTreasure()->isKindOf("LuminousPearl"))
                    return QStringList(objectName());
            }
            foreach (int id, room->getDiscardPile()) {
                if (Sanguosha->getCard(id)->isKindOf("LuminousPearl"))
                    return QStringList(objectName());
            }
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        if (player->hasShownSkill(this) || player->askForSkillInvoke(this)) {
            room->broadcastSkillInvoke(objectName(), player);
            return true;
        }
        return false;
    }
    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        room->sendCompulsoryTriggerLog(player, objectName());
        player->drawCards(1, objectName());
        QList<CardsMoveStruct> moves;
        foreach (ServerPlayer *p, room->getAlivePlayers()) {
            if (p->getTreasure() && p->getTreasure()->isKindOf("LuminousPearl") && player->canGetCard(p, "he")) {
                int card_id = room->askForCardChosen(player, p, "he", objectName(), false, Card::MethodGet);
                CardMoveReason reason(CardMoveReason::S_REASON_EXTRACTION, player->objectName());
                CardsMoveStruct move(card_id, player, Player::PlaceHand, reason);
                moves.append(move);
            }
        }
        if (!moves.isEmpty()) room->moveCardsAtomic(moves, false);
        return false;
    }
};

class JubaoCardFixed : public FixCardSkill
{
public:
    JubaoCardFixed() : FixCardSkill("#jubao-treasure")
    {
    }
    virtual bool isCardFixed(const Player *from, const Player *to, const QString &flags, Card::HandlingMethod method) const
    {
        if (from != to && method == Card::MethodGet && to->hasShownSkill(this) && (flags.contains("t")))
            return true;

        return false;
    }
};

FlameMapCard::FlameMapCard()
{
    target_fixed = true;
}

void FlameMapCard::onUse(Room *room, const CardUseStruct &card_use) const
{
    ServerPlayer *source = card_use.from;
    if (Sanguosha->getCard(subcards.first())->hasFlag("flame_map")) {
        room->setCardFlag((subcards.first()), "-flame_map");
        CardMoveReason reason = CardMoveReason(CardMoveReason::S_REASON_REMOVE_FROM_PILE, source->objectName());
        CardsMoveStruct move(subcards, source, NULL, Player::PlaceSpecial, Player::PlaceTable, reason);
        move.from_pile_name = "flame_map";
        room->moveCardsAtomic(move, true);
        QList<int> new_list = room->getCardIdsOnTable(subcards);
        if (!new_list.isEmpty()) {
            CardsMoveStruct move2(new_list, source, NULL, Player::PlaceTable, Player::DiscardPile, reason);
            room->moveCardsAtomic(move2, true);
        }
    }
    else {
        ServerPlayer *sunquan = room->getLord(source->getKingdom());
        LogMessage log;
        log.type = "#InvokeOthersSkill";
        log.from = source;
        log.to << sunquan;
        log.arg = "flamemap";
        room->sendLog(log);
        room->notifySkillInvoked(source, "flamemap");
        room->broadcastSkillInvoke("flamemap", qrand() % 2 + 1, sunquan);
        room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, source->objectName(), sunquan->objectName());
        room->setCardFlag((subcards.first()), "flame_map");
        sunquan->addToPile("flame_map", subcards, true, room->getAllPlayers(), CardMoveReason(CardMoveReason::S_REASON_UNKNOWN, source->objectName()));
    }
}

class FlameMapVS : public OneCardViewAsSkill
{
public:
    FlameMapVS() : OneCardViewAsSkill("flamemap")
    {
        attached_lord_skill = true;
    }

    virtual bool viewFilter(const QList<const Card *> &, const Card *to_select) const
    {
        if (Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_PLAY)
            return to_select->isKindOf("EquipCard");
        return Self->getPile("flame_map").contains(to_select->getEffectiveId());
    }

    virtual bool isEnabledAtPlay(const Player *player) const
    {
        const Player *sunquan = player->getLord();
        if (!sunquan || !sunquan->hasLordSkill("jiahe") || !player->isFriendWith(sunquan))
            return false;
        return !player->hasUsed("FlameMapCard") && player->canShowGeneral();
    }

    virtual bool isEnabledAtResponse(const Player *, const QString &pattern) const
    {
        return pattern.startsWith("@@flamemap");
    }

    virtual const Card *viewAs(const Card *originalCard) const
    {
        FlameMapCard *slash = new FlameMapCard;
        slash->addSubcard(originalCard);
        slash->setShowSkill("showforviewhas");
        return slash;
    }

    virtual QString getExpandPile() const
    {
        if (Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_PLAY)
            return QString();
        return "flame_map";
    }
};

class FlameMap : public TriggerSkill
{
public:
    FlameMap() : TriggerSkill("flamemap")
    {
        events << Damaged << EventPhaseStart << EventPhaseChanging;
        view_as_skill = new FlameMapVS;
        attached_lord_skill = true;

    }

    virtual void record(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (triggerEvent == EventPhaseChanging) {
            PhaseChangeStruct change = data.value<PhaseChangeStruct>();
            if (change.to == Player::NotActive) {
                QStringList skills = player->tag["FlamemapSkills"].toStringList();
                QStringList detachList;
                foreach(QString skill_name, skills)
                    detachList.append("-" + skill_name);
                room->handleAcquireDetachSkills(player, detachList, true);
                player->tag["FlamemapSkills"] = QVariant();
            }
        }
    }

    virtual TriggerList triggerable(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        TriggerList skill_list;
        if (player == NULL || player->isDead()) return skill_list;
        if (triggerEvent == EventPhaseStart && player->getPhase() == Player::Start) {
            QList<ServerPlayer *> sunquans = room->findPlayersBySkillName(objectName());
            foreach (ServerPlayer *sunquan, sunquans) {
                if (sunquan->hasShownSkill("jiahe") && !sunquan->getPile("flame_map").isEmpty() && sunquan->isFriendWith(player))
                    skill_list.insert(sunquan, QStringList(objectName()));
            }
        } else if (triggerEvent == Damaged && TriggerSkill::triggerable(player) && !player->getPile("flame_map").isEmpty()) {
            DamageStruct damage = data.value<DamageStruct>();
            if (damage.card != NULL)
                skill_list.insert(player, QStringList(objectName()));
        }
        return skill_list;
    }

    virtual bool cost(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        if (triggerEvent == EventPhaseStart)
            return true;
        else {
            room->sendCompulsoryTriggerLog(player, objectName());
            room->broadcastSkillInvoke(objectName(), qrand() % 2 + 3, player);
            QList<int> ids = player->getPile("flame_map");
            if (!ids.isEmpty()) {
                if (!room->askForUseCard(player, "@@flamemap!", "@flamemap", -1, Card::MethodNone, false)) {
                    room->setCardFlag(ids.first(), "-flame_map");
                    CardMoveReason reason = CardMoveReason(CardMoveReason::S_REASON_REMOVE_FROM_PILE, player->objectName());
                    CardsMoveStruct move(ids.first(), player, NULL, Player::PlaceSpecial, Player::PlaceTable, reason);
                    move.from_pile_name = "flame_map";
                    room->moveCardsAtomic(move, true);
                    QList<int> new_list = room->getCardIdsOnTable(ids);
                    if (!new_list.isEmpty()) {
                        CardsMoveStruct move2(new_list, player, NULL, Player::PlaceTable, Player::DiscardPile, reason);
                        room->moveCardsAtomic(move2, true);
                    }
                }
            }
        }
        return false;
    }

    virtual bool effect(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *sunquan) const
    {
        if (triggerEvent == EventPhaseStart) {
            int n = sunquan->getPile("flame_map").length();
            QStringList skill_list;
            if (n > 0)
                skill_list << "yingzi_flamemap";
            if (n > 1)
                skill_list << "haoshi_flamemap";
            if (n > 2)
                skill_list << "shelie";
            if (n > 3)
                skill_list << "duoshi_flamemap";
            QString all_choices = "yingzi_flamemap+haoshi_flamemap+shelie+duoshi_flamemap+cancel";
            if (!skill_list.isEmpty()) {
                skill_list << "cancel";
                QString skill1 = room->askForChoice(player, objectName(), skill_list.join("+"), QVariant(), "@flamemap-choose", all_choices);
                if (skill1 == "cancel") return false;
                QStringList acquired_skills;
                acquired_skills << skill1 + "!";
                skill_list.removeOne(skill1);
                if (n > 4) {
                    QString skill2 = room->askForChoice(player, objectName(), skill_list.join("+"), QVariant(), "@flamemap-choose", all_choices);
                    if (skill2 != "cancel")
                        acquired_skills << skill2 + "!";
                }
                player->tag["FlamemapSkills"] = QVariant::fromValue(acquired_skills);
                LogMessage log;
                log.type = "#InvokeOthersSkill";
                log.from = player;
                log.to << sunquan;
                log.arg = objectName();
                room->sendLog(log);
                room->notifySkillInvoked(player, objectName());
                room->handleAcquireDetachSkills(player, acquired_skills);
            }
        }
        return false;
    }
};

class Jiahe : public TriggerSkill
{
public:
    Jiahe() : TriggerSkill("jiahe$")
    {
        events << GeneralShown << Death << DFDebut;
        frequency = Compulsory;
    }

    virtual void record(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (player == NULL) return;
        if (triggerEvent == GeneralShown) {
            if (player->hasLordSkill(objectName())) {
                if (data.toBool() == player->inHeadSkills(objectName())) {
                    room->sendCompulsoryTriggerLog(player, objectName());
                    room->broadcastSkillInvoke(objectName(), player);
                    foreach(ServerPlayer *p, room->getAlivePlayers())
                        if (p->isFriendWith(player))
                            room->attachSkillToPlayer(p, "flamemap");
                }
            } else {
                ServerPlayer *lord = room->getLord(player->getKingdom());
                 if (lord && lord->isAlive() && lord->hasLordSkill(objectName()))
                     room->attachSkillToPlayer(player, "flamemap");
            }
        } else if (triggerEvent == Death) {
            DeathStruct death = data.value<DeathStruct>();
            if (death.who == player && player->hasLordSkill(objectName())) {
                foreach(ServerPlayer *p, room->getAlivePlayers()) {
                    room->detachSkillFromPlayer(p, "flamemap");
                }
            }
        } else if (triggerEvent == DFDebut) {
            ServerPlayer *lord = room->getLord(player->getKingdom());
            if (lord && lord->isAlive() && lord->hasLordSkill(objectName()) && !player->getAcquiredSkills().contains("flamemap")) {
                room->attachSkillToPlayer(player, "flamemap");
            }
        }
        return;
    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *, QVariant &, ServerPlayer* &) const
    {
        return QStringList();
    }
};

class JiaheClear : public DetachEffectSkill
{
public:
    JiaheClear() : DetachEffectSkill("jiahe")
    {
    }
    virtual void onSkillDetached(Room *room, ServerPlayer *sunquan, QVariant &) const
    {
        foreach(ServerPlayer *p, room->getAlivePlayers()) {
            room->detachSkillFromPlayer(p, "flamemap");
        }
        sunquan->clearOnePrivatePile("flame_map");
    }
};

class HaoshiFlamemap : public DrawCardsSkill
{
public:
    HaoshiFlamemap() : DrawCardsSkill("haoshi_flamemap")
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

class HaoshiFlamemapGive : public TriggerSkill
{
public:
    HaoshiFlamemapGive() : TriggerSkill("#haoshi_flamemap-give")
    {
        events << AfterDrawNCards;
        frequency = Compulsory;
    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *lusu, QVariant &, ServerPlayer * &) const
    {
        if (!lusu || !lusu->isAlive()) return QStringList();
        if (lusu->hasFlag("haoshi_flamemap")) {
            if (lusu->getHandcardNum() <= 5) {
                lusu->setFlags("-haoshi_flamemap");
                return QStringList();
            }
            return QStringList(objectName());
        }
        return QStringList();
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *lusu, QVariant &, ServerPlayer *) const
    {
        lusu->setFlags("-haoshi_flamemap");
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
            HaoshiCard skill_card;
            skill_card.addSubcards(to_give);
            QList<ServerPlayer *> targets;
            targets << beggar;
            skill_card.use(room, lusu, targets);
        }
        return false;
    }
};

class Shelie : public PhaseChangeSkill
{
public:
    Shelie() : PhaseChangeSkill("shelie")
    {
        frequency = Frequent;
    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *shenlvmeng, QVariant &, ServerPlayer* &) const
    {
        return (PhaseChangeSkill::triggerable(shenlvmeng) && shenlvmeng->getPhase() == Player::Draw) ? QStringList(objectName()) : QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *shenlvmeng, QVariant &, ServerPlayer *) const
    {
        if (shenlvmeng->askForSkillInvoke(this)) {
            room->broadcastSkillInvoke(objectName(), shenlvmeng);
            return true;
        }

        return false;
    }

    virtual bool onPhaseChange(ServerPlayer *shenlvmeng) const
    {
        Room *room = shenlvmeng->getRoom();
        room->notifySkillInvoked(shenlvmeng, objectName());

        QList<int> card_ids = room->getNCards(5);

        QSet<Card::Suit> suits;
        foreach(int card_id, card_ids)
            suits << Sanguosha->getCard(card_id)->getSuit();

        AskForMoveCardsStruct result = room->askForMoveCards(shenlvmeng, card_ids, QList<int>(), true, objectName(), "differentsuit", "_"+objectName(), suits.size(), 0, false, true);
        QList<int> selected = result.bottom;
        DummyCard *dummy = new DummyCard(selected);
        room->obtainCard(shenlvmeng, dummy, true);
        QList<int> card_to_throw = result.top;
        dummy = new DummyCard(card_to_throw);
        CardMoveReason reason(CardMoveReason::S_REASON_NATURAL_ENTER, shenlvmeng->objectName(), "shelie", QString());
        room->throwCard(dummy, reason, NULL);
        dummy->deleteLater();
        return true;
    }
};

class DuoshiFlamemap : public OneCardViewAsSkill
{
public:
    DuoshiFlamemap() : OneCardViewAsSkill("duoshi_flamemap")
    {
        filter_pattern = ".|red|.|hand";
        response_or_use = true;
    }

    virtual bool isEnabledAtPlay(const Player *player) const
    {
        return player->usedTimes("ViewAsSkill_duoshi_flamemapCard") < 4;
    }

    virtual const Card *viewAs(const Card *originalcard) const
    {
        AwaitExhausted *await = new AwaitExhausted(originalcard->getSuit(), originalcard->getNumber());
        await->addSubcard(originalcard->getId());
        await->setSkillName("duoshi_flamemap");
        await->setShowSkill(objectName());
        return await;
    }
};

TransformationPackage::TransformationPackage()
    : Package("transformation")
{
    General *Xunyou = new General(this, "xunyou", "wei", 3); // Wei
    Xunyou->addSkill(new Qice);
    Xunyou->addSkill(new Zhiyu);
    Xunyou->addCompanion("xunyu");

    General *Bianhuanghou = new General(this, "bianhuanghou", "wei", 3, false);
    Bianhuanghou->addSkill(new Wanwei);
    Bianhuanghou->addSkill(new Yuejian);
    Bianhuanghou->addSkill(new YuejianMaxCards);
    insertRelatedSkills("yuejian", "#yuejian-maxcard");
    Bianhuanghou->addCompanion("caocao");

    General *Liguo = new General(this, "lijueguosi", "qun"); // Qun
    Liguo->addSkill(new Xiongsuan);
    Liguo->addSkill(new XiongsuanReset);
    insertRelatedSkills("xiongsuan", "#xiongsuan-reset");
    Liguo->addCompanion("jiaxu");

    General *Zuoci = new General(this, "zuoci", "qun", 3);
    Zuoci->addSkill(new Huashen);
    Zuoci->addSkill(new HuashenClear);
    insertRelatedSkills("huashen", "#huashen-clear");
    Zuoci->addSkill(new Xinsheng);
    Zuoci->addCompanion("yuji");

    General *Shamoke = new General(this, "shamoke", "shu"); // Shu
    Shamoke->addSkill(new Jili);
    Shamoke->addSkill(new JiliRecord);
    insertRelatedSkills("jili", "#jili-record");

    General *Masu = new General(this, "masu", "shu", 3);
    Masu->addSkill(new Sanyao);
    Masu->addSkill(new Zhiman);

    General *Lingtong = new General(this, "lingtong", "wu"); // Wu
    Lingtong->addSkill(new Xuanlue);
    Lingtong->addSkill(new Yongjin);
    Lingtong->addCompanion("ganning");

    General *lvfan = new General(this, "lvfan", "wu", 3);
    lvfan->addSkill(new Diaodu);
    lvfan->addSkill(new Diancai);

    General *sunquan = new General(this, "lord_sunquan$", "wu", 4, true, true);
    sunquan->addSkill(new Jiahe);
    sunquan->addSkill(new JiaheClear);
    insertRelatedSkills("jiahe", "#jiahe-clear");
    sunquan->addSkill(new Lianzi);
    sunquan->addSkill(new Jubao);
    sunquan->addSkill(new JubaoCardFixed);
    insertRelatedSkills("jubao", "#jubao-treasure");
    sunquan->addRelateSkill("zhiheng");
    sunquan->addRelateSkill("flamemap");
    sunquan->addRelateSkill("yingzi_flamemap");
    sunquan->addRelateSkill("haoshi_flamemap");
    sunquan->addRelateSkill("shelie");
    sunquan->addRelateSkill("duoshi_flamemap");
    insertRelatedSkills("haoshi_flamemap", "#haoshi_flamemap-give");

    addMetaObject<YongjinCard>();
    addMetaObject<DiaoduequipCard>();
    addMetaObject<DiaoduCard>();
    addMetaObject<QiceCard>();
    addMetaObject<XiongsuanCard>();
    addMetaObject<SanyaoCard>();
    addMetaObject<LianziCard>();
    addMetaObject<FlameMapCard>();

    skills << new HuashenVH;
    skills << new Diaoduequip << new YongjinNext;
    skills << new ZhimanSecond;
    skills << new FlameMap;
    skills << new Yingzi("flamemap", false) << new Shelie << new HaoshiFlamemap << new HaoshiFlamemapGive << new DuoshiFlamemap;
}

ADD_PACKAGE(Transformation)

LuminousPearl::LuminousPearl(Suit suit, int number) : Treasure(suit, number)
{
    setObjectName("LuminousPearl");
}

void LuminousPearl::onUninstall(ServerPlayer *player) const
{
    Treasure::onUninstall(player);
    player->getRoom()->addPlayerHistory(player, "ZhihengLPCard", 0);
}

class LuminousPearlSkill : public ViewAsSkill
{
public:
    LuminousPearlSkill() : ViewAsSkill("LuminousPearl")
    {
    }

    virtual bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const
    {
        return !Self->isJilei(to_select) && selected.length() < Self->getMaxHp() && to_select != Self->getTreasure();
    }

    virtual const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (cards.isEmpty())
            return NULL;

        ZhihengLPCard *zhiheng_card = new ZhihengLPCard;
        zhiheng_card->addSubcards(cards);
        return zhiheng_card;
    }

    virtual bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("ZhihengLPCard") && ((!player->ownSkill("zhiheng") && !player->getAcquiredSkills().contains("zhiheng"))
                || !((player->inHeadSkills("zhiheng") && player->hasShownGeneral1()) || (player->inDeputySkills("zhiheng") && player->hasShownGeneral2()))) ;
    }
};

class ZhihengVH : public ViewHasSkill
{
public:
    ZhihengVH() : ViewHasSkill("zhiheng-viewhas")
    {
        global = true;
    }
    virtual bool ViewHas(const Player *player, const QString &skill_name, const QString &flag) const
    {
        if (flag == "skill" && skill_name == "zhiheng" && player->hasTreasure("LuminousPearl")) return true;
        return false;
    }
};

ZhihengLPCard::ZhihengLPCard()
{
    target_fixed = true;
    mute = true;
}

void ZhihengLPCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const
{
    if (source->isAlive())
        room->drawCards(source, subcards.length());
}

TransformationEquipPackage::TransformationEquipPackage() : Package("transformation_equip", CardPack)
{
    LuminousPearl *np = new LuminousPearl();
    np->setParent(this);

    addMetaObject<ZhihengLPCard>();

    skills << new LuminousPearlSkill << new ZhihengVH;
}

ADD_PACKAGE(TransformationEquip)
