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
            QList<const Player *> _targets;
            foreach (const Player *p, Self->getAliveSiblings())
                if (p->isFriendWith(to_select) && !Self->isProhibited(p, mutable_card))
                    _targets << p;
            if (_targets.length() > subcards.length() - 1) return false;
        }
    }

    if (mutable_card->isKindOf("FightTogether")) {

        QList<const Player *> _targets, all_players = Self->getAliveSiblings();
        all_players << Self;

        foreach (const Player *p, all_players) {
            if (p->isBigKingdomPlayer() == to_select->isBigKingdomPlayer()) {
                if (!Self->isProhibited(p, mutable_card))
                    _targets << p;
            }
        }
        if (_targets.length() > subcards.length()) return false;

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

void QiceCard::onUse(Room *room, const CardUseStruct &card_use) const
{
    ServerPlayer *source = card_use.from;
    QString c = toString().split(":").last();

    Card *use_card = Sanguosha->cloneCard(c);
    use_card->setSkillName("qice");
    use_card->addSubcards(subcards);
    use_card->setCanRecast(false);
    use_card->setShowSkill("qice");

    if (use_card->isAvailable(source)) {

        room->useCard(CardUseStruct(use_card, source, card_use.to));

        if (source->getMark("qicetransformUsed") ==0 && source->canTransform()) {
            if (room->askForChoice(source, "transform_qice", "yes+no", QVariant(), "@transform-ask:::qice") == "yes") {
                room->broadcastSkillInvoke("transform", source->isMale());
                room->addPlayerMark(source, "qicetransformUsed");
                room->transformDeputyGeneral(source);
            }
        }
    }
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
        guhuo_type = "t";
        view_as_skill = new QiceVS;
    }

    virtual bool canShowInPlay() const
    {
        return true;
    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *, QVariant &, ServerPlayer* &) const
    {
        return QStringList();
    }

    bool buttonEnabled(const QString &button_name, const QList<const Card *> &, const QList<const Player *> &) const
    {
        if (button_name.isEmpty()) return true;

        Card *card = Sanguosha->cloneCard(button_name, Card::NoSuit, 0);

        if (card == NULL) return false;

        card->setSkillName("qice");


        if (card->targetFixed()) {
            int x = 0;
            QList<const Player *> all, siblings = Self->getAliveSiblings();
            siblings.prepend(Self);
            foreach (const Player *p, siblings) {
                if (!Self->isProhibited(p, card))
                    all << p;
            }

            if (card->isKindOf("AwaitExhausted")) {
                foreach (const Player *p, all) {
                    if (Self->isFriendWith(p))
                        x++;
                }
            } else if (card->isKindOf("BurningCamps")) {
                QList<const Player *> players = Self->getNextAlive()->getFormation();
                foreach (const Player *p, players) {
                    if (all.contains(p))
                        x++;
                }
            }  else if (card->isKindOf("ImperialOrder")) {
                foreach (const Player *p, all) {
                    if (!p->hasShownOneGeneral())
                        x++;
                }
            } else if (card->getSubtype() == "aoe") {
                x= all.length();
                if (all.contains(Self)) x--;
            } else if (card->getSubtype() == "global_effect") {
                x = all.length();
            }

            if (x > Self->getHandcardNum()) return false;

        }

        return Skill::buttonEnabled(button_name);
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

    virtual QStringList triggerable(TriggerEvent , Room *, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
    {
        if (TriggerSkill::triggerable(player)) {
            int x = 0;
            QVariantList move_datas = data.toList();
            foreach (QVariant move_data, move_datas) {
                CardsMoveOneTimeStruct move = move_data.value<CardsMoveOneTimeStruct>();
                if (move.from == player && (move.from_places.contains(Player::PlaceHand) || move.from_places.contains(Player::PlaceEquip))
                        && ((move.reason.m_reason == CardMoveReason::S_REASON_DISMANTLE && move.reason.m_playerId != move.reason.m_targetId)
                        || (move.to && move.to != player && move.to_place == Player::PlaceHand
                        && move.reason.m_reason != CardMoveReason::S_REASON_GIVE))) {
                    for (int i = 0; i < move.card_ids.length(); ++i) {
                        if (move.from_places.at(i) == Player::PlaceHand || move.from_places.at(i) == Player::PlaceEquip) {
                            x++;
                        }
                    }
                }
            }

            if (x > 0 && x < player->getCardCount(true))
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

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        QVariantList move_datas = data.toList();
        QVariantList new_datas;

        QList<int> selected;

        foreach (QVariant move_data, move_datas) {
            CardsMoveOneTimeStruct move = move_data.value<CardsMoveOneTimeStruct>();
            if (move.from != player) {
                new_datas << move_data;
                continue;
            }
            ServerPlayer *target = NULL;
            QString prompt;

            if (move.reason.m_reason == CardMoveReason::S_REASON_DISMANTLE && move.reason.m_playerId != move.reason.m_targetId) {
                target = room->findPlayerbyobjectName(move.reason.m_playerId, true);
                prompt = "@wanwei-dismantle:";
            }

            if (move.reason.m_reason != CardMoveReason::S_REASON_GIVE && move.to && move.to != player && move.to_place == Player::PlaceHand) {
                target = (ServerPlayer *)move.to;
                prompt = "@wanwei-extraction:";
            }
            if (target == NULL) {
                new_datas << move_data;
                continue;
            }
            prompt = prompt + target->objectName() + "::";

            QList<int> card_ids;
            for (int i = 0; i < move.card_ids.length(); ++i) {
                if (move.from_places.at(i) == Player::PlaceHand || move.from_places.at(i) == Player::PlaceEquip) {
                    card_ids << i;
                }
            }

            if (card_ids.isEmpty()) {
                new_datas << move_data;
                continue;
            }

            int x = card_ids.length();

            prompt = prompt + QString::number(x);

            QStringList pattern;
            foreach (int id, selected) {
                pattern << QString("^%1").arg(id);
            }

            QList<int> ints = room->askForExchange(player, "_wanwei", x, x, prompt, QString(), pattern.join("|"));

            if (ints.length() < x) {
                ints.clear();
                foreach (const Card *card, player->getCards("he")) {
                    if (ints.length() == x) break;
                    int id = card->getEffectiveId();
                    if (!selected.contains(id))
                        ints << id;
                }
            }
            selected << ints;

            for (int i = 0; i < ints.length(); ++i) {
                move.card_ids.replace(card_ids.at(i), ints.at(i));
                move.from_places.replace(card_ids.at(i), room->getCardPlace(ints.at(i)));
            }

            new_datas << QVariant::fromValue(move);
        }
        data = QVariant::fromValue(new_datas);

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

YiguiCard::YiguiCard()
{
    will_throw = false;
}

bool YiguiCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    QString generalName = Self->tag["yigui_general"].toString();

    const General *general = Sanguosha->getGeneral(generalName);

    if (general == NULL) return false;

    Card *mutable_card = Sanguosha->cloneCard(Self->tag["yigui"].toString());
    if (mutable_card) {
        mutable_card->setSkillName("yigui");
        mutable_card->addSubcards(subcards);
        mutable_card->setCanRecast(false);
        mutable_card->deleteLater();
        mutable_card->setTag("YiguiGeneral", generalName);
    }

    return mutable_card && mutable_card->targetFilter(targets, to_select, Self) && !Self->isProhibited(to_select, mutable_card, targets);
}

bool YiguiCard::targetFixed() const
{
    Card *mutable_card = Sanguosha->cloneCard(Self->tag["yigui"].toString());
    if (mutable_card) {
        mutable_card->setSkillName("yigui");
        mutable_card->addSubcards(subcards);
        mutable_card->setCanRecast(false);
        mutable_card->deleteLater();
    }
    return mutable_card && mutable_card->targetFixed();
}

bool YiguiCard::targetsFeasible(const QList<const Player *> &targets, const Player *Self) const
{
    Card *mutable_card = Sanguosha->cloneCard(Self->tag["yigui"].toString());
    if (mutable_card) {
        mutable_card->setSkillName("yigui");
        mutable_card->addSubcards(subcards);
        mutable_card->setCanRecast(false);
        mutable_card->deleteLater();
    }

    return mutable_card && mutable_card->targetsFeasible(targets, Self);
}

const Card *YiguiCard::validate(CardUseStruct &card_use) const
{
    ServerPlayer *source = card_use.from;
    Room *room = source->getRoom();

    QStringList str = toString().split(":").last().split("+");
    if (str.length() != 2) return NULL;
    QString card_name = str.first();
    QString soul_name = str.last();

    Card *use_card = Sanguosha->cloneCard(card_name, Card::NoSuit, 0);
    use_card->setSkillName("yigui");
    use_card->setCanRecast(false);
    use_card->setShowSkill("yigui");
    use_card->setTag("YiguiGeneral", soul_name);

    bool available = true;

    available = available && use_card->isAvailable(source);
    use_card->deleteLater();
    if (!available) return NULL;

    QString classname;
    if (use_card->isKindOf("Slash"))
        classname = "Slash";
    else
        classname = use_card->getClassName();

    room->setPlayerFlag(source, "Yigui_" + classname);

    room->dropHuashenCard(source, soul_name);

    return use_card;
}

const Card *YiguiCard::validateInResponse(ServerPlayer *user) const
{
    Room *room = user->getRoom();

    QStringList str = toString().split(":").last().split("+");
    if (str.length() != 2) return NULL;
    QString card_name = str.first();
    QString soul_name = str.last();

    Card *c = Sanguosha->cloneCard(card_name, Card::NoSuit, 0);

    c->setTag("YiguiGeneral", soul_name);

    QString classname;
    if (c->isKindOf("Slash"))
        classname = "Slash";
    else
        classname = c->getClassName();

    room->setPlayerFlag(user, "Yigui_" + classname);

    c->setSkillName("yigui");
    c->deleteLater();

    room->dropHuashenCard(user, soul_name);

    return c;

}

class YiguiViewAsSkill : public ZeroCardViewAsSkill
{
public:
    YiguiViewAsSkill() : ZeroCardViewAsSkill("yigui")
    {
    }

    virtual const Card *viewAs() const
    {
        QString card_name = Self->tag["yigui"].toString();
        QString soul_name = Self->tag["yigui_general"].toString();
        if (card_name != "" && soul_name != "") {
            YiguiCard *card = new YiguiCard;
            card->setUserString(QString("%1+%2").arg(card_name).arg(soul_name));
            return card;
        } else
            return NULL;
    }

    virtual bool isEnabledAtPlay(const Player *zuoci) const
    {
        return !zuoci->property("Huashens").toString().isEmpty();
    }

    virtual bool isEnabledAtResponse(const Player *zuoci, const QString &pattern) const
    {
        if (Sanguosha->currentRoomState()->getCurrentCardUseReason() != CardUseStruct::CARD_USE_REASON_RESPONSE_USE)
            return false;

        if (zuoci->property("Huashens").toString().isEmpty()) return false;

        if (pattern == "jink" || pattern == "nullification") return false;

        if (pattern == "slash") return !zuoci->hasFlag("Yigui_Slash");

        QList<const Player *> siblings = zuoci->getAliveSiblings();
        siblings.prepend(zuoci);

        const Player *target = zuoci;
        foreach (const Player *p, siblings) {
            if (p->hasFlag("Global_Dying")) {
                target = p;
                break;
            }
        }

        if (target->hasShownOneGeneral()) {
            QStringList huashens = zuoci->tag["Huashens"].toStringList();
            bool no_same = true;
            foreach (QString name, huashens) {
                const General *general = Sanguosha->getGeneral(name);
                if (general == NULL) continue;
                if (general->getKingdoms().contains(target->getKingdom())) {
                    no_same = false;
                    break;
                }

            }
            if (no_same) return false;
        }


        if (pattern.contains("peach")) {
            if (!zuoci->hasFlag("Yigui_Peach")) {
                Peach *peach = new Peach(Card::NoSuit, 0);
                peach->setSkillName("yigui");

                if (!zuoci->isLocked(peach) && !zuoci->isProhibited(target, peach, QList<const Player *>()))
                    return true;
            }

        }
        if (pattern.contains("analeptic")) {
            if (!zuoci->hasFlag("Yigui_Analeptic")) {
                Analeptic *analeptic = new Analeptic(Card::NoSuit, 0);
                analeptic->setSkillName("yigui");

                if (!zuoci->isLocked(analeptic) && !zuoci->isProhibited(target, analeptic, QList<const Player *>()))
                    return true;
                return true;
            }

        }

        return false;
    }
};

class Yigui : public TriggerSkill
{
public:
    Yigui() : TriggerSkill("yigui")
    {
        events << EventLoseSkill << BuryVictim;
        guhuo_type = "bt";
        view_as_skill = new YiguiViewAsSkill;
    }

    bool buttonEnabled(const QString &button_name, const QList<const Card *> &, const QList<const Player *> &) const
    {
        if (button_name.isEmpty()) return true;

        QString generalName = Self->tag["yigui_general"].toString();
        const General *general = Sanguosha->getGeneral(generalName);
        if (general == NULL) return false;

        Card *card = Sanguosha->cloneCard(button_name, Card::NoSuit, 0);

        if (card == NULL) return false;

        card->setSkillName("yigui");
        card->setTag("YiguiGeneral", generalName);
        card->setCanRecast(false);

        QString classname = card->getClassName();
        if (card->isKindOf("Slash"))
            classname = "Slash";
        if (card->isKindOf("Nullification"))
            classname = "Nullification";

        if (Self->hasFlag("Yigui_" + classname)) return false;

        if (Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_PLAY)
            return !Self->isCardLimited(card, Card::MethodUse, false) && card->isAvailable(Self);
        else {
            if (Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE_USE) {
                if (Self->isCardLimited(card, Card::MethodUse, false))
                    return false;

                if (card->isKindOf("Peach") || card->isKindOf("Analeptic")) {

                    QList<const Player *> siblings = Self->getAliveSiblings();
                    siblings.prepend(Self);

                    const Player *target = Self;
                    foreach (const Player *p, siblings) {
                        if (p->hasFlag("Global_Dying")) {
                            target = p;
                            break;
                        }
                    }

                    if (Self->isProhibited(target, card, QList<const Player *>()))
                        return false;
                }


            } else
                return false;

            QString pattern = Sanguosha->currentRoomState()->getCurrentCardUsePattern();
            if (pattern.startsWith(".") || pattern.startsWith("@"))
                return false;
            if (pattern == "slash") {
                return card->isKindOf("Slash");
            } else if (pattern == "nullification") {
                return card->isKindOf("Nullification");
            } else
                return pattern.contains(button_name);
        }
        return false;
    }

    static void AcquireGenerals(ServerPlayer *zuoci, int n, QString reason)
    {
        Room *room = zuoci->getRoom();
        QStringList huashens;
        if (!zuoci->property("Huashens").toString().isEmpty())
            huashens = zuoci->property("Huashens").toString().split("+");
        QStringList acquired = GetAvailableGenerals(zuoci, n);

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

    virtual void record(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (triggerEvent == EventLoseSkill)
            if (player == NULL || data.toString().split(":").first() != objectName()) return;

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

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *, QVariant &, ServerPlayer* &) const
    {
        return QStringList();
    }
};

class YiguiShow : public TriggerSkill
{
public:
    YiguiShow() : TriggerSkill("#yigui-show")
    {
        events << GeneralShown;
        frequency = Compulsory;
    }

    virtual QStringList triggerable(TriggerEvent triggerEvent, Room *, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
    {
        if (triggerEvent == GeneralShown) {
            if (TriggerSkill::triggerable(player) && player->cheakSkillLocation("yigui", data.toBool())) {
                if ((data.toBool() && player->getMark("HaventShowGeneral") > 0)
                        || (!data.toBool() && player->getMark("HaventShowGeneral2") > 0))
                return QStringList(objectName());
            }
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent , Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        room->sendCompulsoryTriggerLog(player, "yigui");
        room->broadcastSkillInvoke("yigui");
        return true;
    }

    virtual bool effect(TriggerEvent , Room *, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        Yigui::AcquireGenerals(player, 2, "yigui");
        return false;
    }
};

class YiguiProhibit : public ProhibitSkill
{
public:
    YiguiProhibit() : ProhibitSkill("#yigui-prohibit")
    {
    }

    virtual bool isProhibited(const Player *, const Player *to, const Card *card, const QList<const Player *> &) const
    {
        if (card->getSkillName(true) == "yigui" && to->hasShownOneGeneral()) {
            QString generalName = card->tag["YiguiGeneral"].toString();
            const General *general = Sanguosha->getGeneral(generalName);
            return (general && !general->getKingdoms().contains(to->getKingdom()));
        }
        return false;
    }
};

class Jihun : public TriggerSkill
{
public:
    Jihun() : TriggerSkill("jihun")
    {
        events << QuitDying << Damaged;
    }

    virtual TriggerList triggerable(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &) const
    {
        TriggerList skill_list;
        if (triggerEvent == QuitDying && player->isAlive() && player->hasShownOneGeneral()) {
            QList<ServerPlayer *> zuocis = room->findPlayersBySkillName(objectName());
            foreach (ServerPlayer *zuoci, zuocis) {
                if (zuoci != NULL && !zuoci->isFriendWith(player) && zuoci->hasShownOneGeneral())
                    skill_list.insert(zuoci, QStringList(objectName()));
            }
            return skill_list;
        } else if (triggerEvent == Damaged && TriggerSkill::triggerable(player)) {
            skill_list.insert(player, QStringList(objectName()));
        }
        return skill_list;
    }
    virtual bool cost(TriggerEvent , Room *room, ServerPlayer *, QVariant &, ServerPlayer *player) const
    {
        if (player->askForSkillInvoke(this)) {
            room->broadcastSkillInvoke(objectName());
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent , Room *, ServerPlayer *, QVariant &, ServerPlayer *player) const
    {
        Yigui::AcquireGenerals(player, 1, objectName());
        return false;
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
        if (to->isFriendWith(player) && to->canTransform() && player->getMark("zhimantransformUsed") == 0
                && (room->askForChoice(player, "zhiman", "yes+no", QVariant(), "@zhiman-ask::"+to->objectName()) == "yes")
                && (room->askForChoice(to, "transform_zhiman", "yes+no", QVariant(), "@transform-ask:::"+objectName()) == "yes")) {
            room->addPlayerMark(player, "zhimantransformUsed");
            room->broadcastSkillInvoke("transform", to->isMale());
            room->transformDeputyGeneral(to);
        }
        return false;
    }
};

//lingtong
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

    virtual QStringList triggerable(TriggerEvent, Room *room, ServerPlayer *lingtong, QVariant &data, ServerPlayer* &) const
    {
        if (!TriggerSkill::triggerable(lingtong)) return QStringList();
        QVariantList move_datas = data.toList();
        foreach (QVariant move_data, move_datas) {
            CardsMoveOneTimeStruct move = move_data.value<CardsMoveOneTimeStruct>();
            if (move.from == lingtong && move.from_places.contains(Player::PlaceEquip)) {
                QList<ServerPlayer *> other_players = room->getOtherPlayers(lingtong);
                foreach (ServerPlayer *p, other_players) {
                    if (lingtong->canDiscard(p, "he"))
                        return QStringList(objectName());
                }
            }
        }

        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *lingtong, QVariant &, ServerPlayer *) const
    {
        QList<ServerPlayer *> other_players = room->getOtherPlayers(lingtong);
        QList<ServerPlayer *> targets;
        foreach (ServerPlayer *p, other_players) {
            if (lingtong->canDiscard(p, "he"))
                targets << p;
        }
        ServerPlayer *to = room->askForPlayerChosen(lingtong, targets, objectName(), "xuanlue-invoke", true, true);
        if (to) {
            lingtong->tag["xuanlue_target"] = QVariant::fromValue(to);
            room->broadcastSkillInvoke(objectName(), lingtong);
            return true;
        } else lingtong->tag.remove("xuanlue_target");
        /*
        if (room->askForSkillInvoke(lingtong, objectName())) {
            room->broadcastSkillInvoke(objectName(), lingtong);
            return true;
        }
        */
        return false;

    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *lingtong, QVariant &, ServerPlayer *) const
    {
        ServerPlayer *to = lingtong->tag["xuanlue_target"].value<ServerPlayer *>();
        lingtong->tag.remove("xuanlue_target");
        if (to && lingtong->canDiscard(to, "he")) {
            int card_id = room->askForCardChosen(lingtong, to, "he", objectName(), false, Card::MethodDiscard);
            CardMoveReason reason = CardMoveReason(CardMoveReason::S_REASON_DISMANTLE, lingtong->objectName(), to->objectName(), objectName(), NULL);
            room->throwCard(Sanguosha->getCard(card_id), reason, to, lingtong);
        }
        /*
        QList<int> ids = room->GlobalCardChosen(lingtong, room->getOtherPlayers(lingtong), "he", objectName(), "@xuanlue", 1, 1,
            Room::OnebyOne, false, Card::MethodDiscard);
        ServerPlayer *to = room->getCardOwner(ids.first());
        CardMoveReason reason = CardMoveReason(CardMoveReason::S_REASON_DISMANTLE, lingtong->objectName(), to->objectName(), objectName(), NULL);
        room->throwCard(Sanguosha->getCard(ids.first()), reason, to, lingtong);
        */
        return false;
    }
};

YongjinMoveCard::YongjinMoveCard()
{

}

bool YongjinMoveCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *) const
{
    if (targets.length() == 0)
        return to_select->hasEquip();
    else if (targets.length() == 1) {
        for (int i = 0; i < S_EQUIP_AREA_LENGTH; i++) {
            if (targets.first()->getEquip(i) && to_select->canSetEquip(i))
                return true;
        }
    }
    return false;
}

bool YongjinMoveCard::targetsFeasible(const QList<const Player *> &targets, const Player *) const
{
    return targets.length() == 2;
}

void YongjinMoveCard::onUse(Room *room, const CardUseStruct &card_use) const
{
    CardUseStruct use = card_use;
    ServerPlayer *lingtong = use.from;

    if (use.to.length() != 2)
        return;

    ServerPlayer *from = use.to.first();
    ServerPlayer *to = use.to.last();

    bool can_select = false;
    QList<int> disabled_ids;
    for (int i = 0; i < S_EQUIP_AREA_LENGTH; i++) {
        if (from->getEquip(i)){
            if (to->canSetEquip(i))
                can_select = true;
            else
                disabled_ids << from->getEquip(i)->getEffectiveId();
        }
    }

    if (can_select) {
        int card_id = room->askForCardChosen(lingtong, from, "e", "yongjin", false, Card::MethodNone, disabled_ids);
        room->moveCardTo(Sanguosha->getCard(card_id), from, to, room->getCardPlace(card_id),
                         CardMoveReason(CardMoveReason::S_REASON_TRANSFER, lingtong->objectName(), "yongjin", QString()));
    }
}

class YongjinMove : public ZeroCardViewAsSkill
{
public:
    YongjinMove() : ZeroCardViewAsSkill("yongjin_move")
    {
        response_pattern = "@@yongjin_move";
    }

    virtual const Card *viewAs() const
    {
        return new YongjinMoveCard;
    }
};

YongjinCard::YongjinCard()
{
    target_fixed = true;
}

void YongjinCard::onUse(Room *room, const CardUseStruct &card_use) const
{
    ServerPlayer *lingtong = card_use.from;

    QVariant data = QVariant::fromValue(card_use);
    RoomThread *thread = room->getThread();

    thread->trigger(PreCardUsed, room, lingtong, data);

    LogMessage log;
    log.from = lingtong;
    log.to << card_use.to;
    log.type = "#UseCard";
    log.card_str = toString();
    room->sendLog(log);

    room->removePlayerMark(lingtong, "@brave");
    room->doSuperLightbox("lingtong", "yongjin");

    if (lingtong->ownSkill("yongjin") && !lingtong->hasShownSkill("yongjin"))
        lingtong->showGeneral(lingtong->inHeadSkills("yongjin"));

    thread->trigger(CardUsed, room, lingtong, data);
    thread->trigger(CardFinished, room, lingtong, data);
}

void YongjinCard::use(Room *room, ServerPlayer *lingtong, QList<ServerPlayer *> &) const
{
    if (room->askForUseCard(lingtong, "@@yongjin_move", "@yongjin-next", -1, Card::MethodNone))
        if (room->askForUseCard(lingtong, "@@yongjin_move", "@yongjin-next", -1, Card::MethodNone))
            room->askForUseCard(lingtong, "@@yongjin_move", "@yongjin-next", -1, Card::MethodNone);
}

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

class Diaodu : public TriggerSkill
{
public:
    Diaodu() : TriggerSkill("diaodu")
    {
        events << EventPhaseStart << CardUsed;
    }

    virtual QStringList triggerable(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        if (triggerEvent == EventPhaseStart && player->getPhase() == Player::Play) {
            if (TriggerSkill::triggerable(player)) {
                bool can_invoke = false;
                QList<ServerPlayer *> all_players = room->getAlivePlayers();
                foreach (ServerPlayer *p, all_players) {
                    if (player->isFriendWith(p) && player->canGetCard(p, "e")) {
                        can_invoke = true;
                        break;
                    }
                }
                if (can_invoke)
                    return QStringList(objectName());
            }
        } else if (triggerEvent == CardUsed) {
            CardUseStruct use = data.value<CardUseStruct>();
            if (TriggerSkill::triggerable(player) && use.card->getTypeId() == Card::TypeEquip)
                return QStringList(objectName());
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        if (triggerEvent == EventPhaseStart) {
            QList<ServerPlayer *> targets;
            QList<ServerPlayer *> all_players = room->getAlivePlayers();
            foreach (ServerPlayer *p, all_players) {
                if (player->isFriendWith(p) && player->canGetCard(p, "e"))
                    targets << p;
            }
            ServerPlayer *victim;
            if ((victim = room->askForPlayerChosen(player, targets, objectName(), "@diaodu", true, true)) != NULL) {
                room->broadcastSkillInvoke(objectName(), player);

                QStringList target_list = player->tag["diaodu_target"].toStringList();
                target_list.append(victim->objectName());
                player->tag["diaodu_target"] = target_list;

                return true;
            }
        } else if (triggerEvent == CardUsed) {
            if (player->askForSkillInvoke(objectName())) {
                room->broadcastSkillInvoke(objectName(), player);
                return true;
            }
        }
        return false;
    }

    virtual bool effect(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        if (triggerEvent == EventPhaseStart) {
            QStringList target_list = player->tag["diaodu_target"].toStringList();
            QString target_name = target_list.last();
            target_list.removeLast();
            player->tag["diaodu_target"] = target_list;

            ServerPlayer *target = room->findPlayerbyobjectName(target_name);
            if (target != NULL) {
                int card_id = room->askForCardChosen(player, target, "e", objectName(), false, Card::MethodGet);
                const Card *card = Sanguosha->getCard(card_id);

                CardMoveReason reason(CardMoveReason::S_REASON_EXTRACTION, player->objectName());
                room->obtainCard(player, card, reason, false);

                if (room->getCardOwner(card_id) == player && room->getCardPlace(card_id) == Player::PlaceHand) {

                    QList<ServerPlayer *> targets = room->getOtherPlayers(player);
                    targets.removeOne(target);
                    ServerPlayer *victim = room->askForPlayerChosen(player, targets, "diaodu_give",
                                                                    "@diaodu-give:::" + card->objectName(), true);
                    if (victim != NULL) {
                        CardMoveReason reason2(CardMoveReason::S_REASON_GIVE, player->objectName(), victim->objectName(), "diaodu", QString());
                        room->obtainCard(victim, card, reason2, true);
                    }

                }
            }
        } else if (triggerEvent == CardUsed)
            player->drawCards(1, objectName());

        return false;
    }
};

class DiaoduDraw : public TriggerSkill
{
public:
    DiaoduDraw() : TriggerSkill("#diaodu-draw")
    {
        events << CardUsed;
        frequency = Compulsory;
    }

    virtual TriggerList triggerable(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (player != NULL && player->isAlive()) {
            CardUseStruct use = data.value<CardUseStruct>();
            if (use.card->getTypeId() == Card::TypeEquip) {
                QList<ServerPlayer *> owners = room->findPlayersBySkillName("diaodu");
                TriggerList skill_list;
                foreach (ServerPlayer *owner, owners)
                    if (owner != player && player->isFriendWith(owner) && owner->hasShownSkill("diaodu"))
                        skill_list.insert(owner, QStringList(objectName()));
                return skill_list;
            }
        }
        return TriggerList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *owner) const
    {
        if (room->askForChoice(player, "diaodu", "yes+no", data, "@diaodu-draw:" + owner->objectName()) == "yes") {
            LogMessage log;
            log.type = "#InvokeOthersSkill";
            log.from = player;
            log.to << owner;
            log.arg = "diaodu";
            room->sendLog(log);
            room->broadcastSkillInvoke("diaodu", owner);
            room->notifySkillInvoked(owner, "diaodu");

            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent, Room *, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        player->drawCards(1, "diaodu");
        return false;
    }
};



class Diancai : public TriggerSkill
{
public:
    Diancai() : TriggerSkill("diancai")
    {
        events << EventPhaseEnd;
    }

    virtual bool canPreshow() const
    {
        return true;
    }

    virtual TriggerList triggerable(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &) const
    {
        if (!(triggerEvent == EventPhaseEnd && player->getPhase() == Player::Play)) return TriggerList();
        QList<ServerPlayer *> players = room->findPlayersBySkillName(objectName());
        TriggerList skill_list;
        foreach (ServerPlayer *p, players) {
            if (TriggerSkill::triggerable(p) && p != player)
                if (p->getMark("GlobalLoseCardCount") >= qMax(p->getHp(), 1))
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

        if (ask_who->canTransform() && ask_who->getMark("diancaitransformUsed") == 0
                && room->askForChoice(ask_who, "transform_diancai", "yes+no", QVariant(), "@transform-ask:::"+objectName()) == "yes") {
            room->addPlayerMark(ask_who, "diancaitransformUsed");
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
        events << EventPhaseStart << BeforeCardsMove;
        frequency = Compulsory;
    }

    virtual QStringList triggerable(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
    {
        if (!TriggerSkill::triggerable(player)) return QStringList();
        if (triggerEvent == EventPhaseStart && player->getPhase() == Player::Finish) {
            foreach (ServerPlayer *p, room->getAlivePlayers()) {
                if (p->getTreasure() && p->getTreasure()->isKindOf("LuminousPearl"))
                    return QStringList(objectName());
            }
            foreach (int id, room->getDiscardPile()) {
                if (Sanguosha->getCard(id)->isKindOf("LuminousPearl"))
                    return QStringList(objectName());
            }
        } else if (triggerEvent == BeforeCardsMove && player->getTreasure()) {
            int treasure_id = player->getTreasure()->getEffectiveId();
            QVariantList move_datas = data.toList();
            foreach (QVariant move_data, move_datas) {
                CardsMoveOneTimeStruct move = move_data.value<CardsMoveOneTimeStruct>();
                if (move.from != player) continue;
                if (move.to && move.to != move.from && move.to_place == Player::PlaceHand
                     && move.reason.m_reason != CardMoveReason::S_REASON_GIVE) {
                    foreach (int id, move.card_ids) {
                        if (treasure_id == id)
                            return QStringList(objectName());
                    }
                }
            }
        }
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
            room->broadcastSkillInvoke(objectName(), player);
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (triggerEvent == EventPhaseStart) {
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
            if (!moves.isEmpty())
                room->moveCardsAtomic(moves, false);
        } else if (player->getTreasure()) {
            int id = player->getTreasure()->getEffectiveId();
            data = room->changeMoveData(data, QList<int>() << id);
        }
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
    ServerPlayer *sunquan = room->getLord(source->getSeemingKingdom());
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

class FlameMapVS : public OneCardViewAsSkill
{
public:
    FlameMapVS() : OneCardViewAsSkill("flamemap")
    {
        attached_lord_skill = true;
        filter_pattern = "EquipCard";
    }

    virtual bool isEnabledAtPlay(const Player *player) const
    {
        const Player *sunquan = player->getLord();
        if (!sunquan || !sunquan->hasLordSkill("jiahe") || !player->isFriendWith(sunquan))
            return false;
        return !player->hasUsed("FlameMapCard") && player->canShowGeneral();
    }

    virtual const Card *viewAs(const Card *originalCard) const
    {
        FlameMapCard *slash = new FlameMapCard;
        slash->addSubcard(originalCard);
        slash->setShowSkill("showforviewhas");
        return slash;
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
        } else if (triggerEvent == Damaged && player->hasSkill("jiahe") && !player->getPile("flame_map").isEmpty()) {
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
            return true;
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
        } else if (triggerEvent == Damaged) {
            QList<int> ids = sunquan->getPile("flame_map");
            if (!ids.isEmpty()) {
                room->fillAG(ids, sunquan);
                int id = room->askForAG(sunquan, ids, false, objectName());
                room->clearAG(sunquan);
                CardMoveReason reason(CardMoveReason::S_REASON_REMOVE_FROM_PILE, QString(), sunquan->objectName(), "flamemap", QString());
                room->throwCard(Sanguosha->getCard(id), reason, NULL);
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
            if (player->hasLordSkill(objectName(), true)) {
                if (data.toBool() == player->inHeadSkills(objectName())) {
                    room->sendCompulsoryTriggerLog(player, objectName());
                    room->broadcastSkillInvoke(objectName(), player);
                    foreach(ServerPlayer *p, room->getAlivePlayers())
                        if (p->isFriendWith(player))
                            room->attachSkillToPlayer(p, "flamemap");
                }
            } else {
                ServerPlayer *lord = room->getLord(player->getSeemingKingdom());
                 if (lord && lord->isAlive() && lord->hasLordSkill(objectName(), true))
                     room->attachSkillToPlayer(player, "flamemap");
            }
        } else if (triggerEvent == Death) {
            DeathStruct death = data.value<DeathStruct>();
            if (death.who == player && player->hasLordSkill(objectName(), true)) {
                foreach(ServerPlayer *p, room->getAlivePlayers()) {
                    room->detachSkillFromPlayer(p, "flamemap");
                }
            }
        } else if (triggerEvent == DFDebut) {
            ServerPlayer *lord = room->getLord(player->getSeemingKingdom());
            if (lord && lord->isAlive() && lord->hasLordSkill(objectName(), true) && !player->getAcquiredSkills().contains("flamemap")) {
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

    General *Zuoci = new General(this, "zuoci", "qun", 3, true, true, true);
    Zuoci->addSkill(new Huashen);
    Zuoci->addSkill(new HuashenClear);
    insertRelatedSkills("huashen", "#huashen-clear");
    Zuoci->addSkill(new Xinsheng);
    //Zuoci->addCompanion("yuji");

    General *Zuoci_new = new General(this, "new_zuoci", "qun", 3);
    Zuoci_new->addSkill(new Yigui);
    Zuoci_new->addSkill(new YiguiShow);
    Zuoci_new->addSkill(new YiguiProhibit);
    insertRelatedSkills("yigui", 2, "#yigui-show", "#yigui-prohibit");
    Zuoci_new->addSkill(new Jihun);
    Zuoci_new->addCompanion("yuji");

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
    lvfan->addSkill(new DiaoduDraw);
    lvfan->addSkill(new Diancai);
    insertRelatedSkills("diaodu", "#diaodu-draw");

    General *sunquan = new General(this, "lord_sunquan$", "wu", 4, true, true);
    sunquan->addSkill(new Jiahe);
    sunquan->addSkill(new JiaheClear);
    insertRelatedSkills("jiahe", "#jiahe-clear");
    sunquan->addSkill(new Lianzi);
    sunquan->addSkill(new Jubao);
    sunquan->addRelateSkill("zhiheng");
    sunquan->addRelateSkill("flamemap");
    sunquan->addRelateSkill("yingzi_flamemap");
    sunquan->addRelateSkill("haoshi_flamemap");
    sunquan->addRelateSkill("shelie");
    sunquan->addRelateSkill("duoshi_flamemap");
    insertRelatedSkills("haoshi_flamemap", "#haoshi_flamemap-give");

    addMetaObject<YongjinCard>();
    addMetaObject<YongjinMoveCard>();
    addMetaObject<QiceCard>();
    addMetaObject<YiguiCard>();
    addMetaObject<XiongsuanCard>();
    addMetaObject<SanyaoCard>();
    addMetaObject<LianziCard>();
    addMetaObject<FlameMapCard>();

    skills << new HuashenVH;
    skills << new YongjinMove;
    skills << new ZhimanSecond;
    skills << new FlameMap;
    skills << new Yingzi("flamemap") << new Shelie << new HaoshiFlamemap << new HaoshiFlamemapGive << new DuoshiFlamemap;
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
