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

#include "generalselector.h"
#include "engine.h"
#include "serverplayer.h"
#include "banpair.h"
#include "settings.h"

#include <QFile>
#include <QTextStream>

static GeneralSelector *Selector;

GeneralSelector *GeneralSelector::getInstance()
{
    if (Selector == NULL) {
        Selector = new GeneralSelector;
        Selector->setParent(Sanguosha);
    }

    return Selector;
}

GeneralSelector::GeneralSelector()
{
    loadGeneralTable();
    loadPairTable();
}

QStringList GeneralSelector::selectGenerals(ServerPlayer *player, const QStringList &candidates)
{
    QStringList generals = candidates;
    foreach (QString name, candidates) {
        QStringList subs = Sanguosha->getConvertGenerals(name);
        if (!subs.isEmpty()) {
            generals.removeOne(name);
            subs << name;
            qShuffle(subs);
            generals << subs.first();
        }
    }
    if (m_privatePairValueTable[player].isEmpty())
        calculatePairValues(player, generals);

    QHash<QString, double> my_hash = m_privatePairValueTable[player];

    double max_score = my_hash.values().first();
    QString best_pair = my_hash.keys().first();

    foreach (const QString &key, my_hash.keys()) {
        double score = my_hash.value(key);
        if (score > max_score) {
            max_score = score;
            best_pair = key;
        }
    }

    Q_ASSERT(!best_pair.isEmpty());

    QStringList pair = best_pair.split("+");

    Q_ASSERT(pair.size() == 2);

    return pair;
}

void GeneralSelector::loadGeneralTable()
{
    QRegExp rx("(\\w+)\\s+(\\d+)");
    QFile file("ai-selector/general-value.txt");
    if (file.open(QIODevice::ReadOnly)) {
        QTextStream stream(&file);
        while (!stream.atEnd()) {
            QString line = stream.readLine();
            if (!rx.exactMatch(line))
                continue;

            //SAMPLE: huatuo 41
            QStringList texts = rx.capturedTexts();
            QString general = texts.at(1);
            int value = texts.at(2).toInt();

            m_singleGeneralTable.insert(general, value);
        }

        file.close();
    }
    foreach (const QString &pack, Config.value("LuaPackages", QString()).toString().split("+")) {
        QFile lua_file(QString("extensions/ai-selector/%1-general-value.txt").arg(pack));
        if (lua_file.exists() && lua_file.open(QIODevice::ReadOnly)) {
            QTextStream stream(&lua_file);
            while (!stream.atEnd()) {
                QString line = stream.readLine();
                if (!rx.exactMatch(line))
                    continue;

                //SAMPLE: huatuo 41
                QStringList texts = rx.capturedTexts();
                QString general = texts.at(1);
                int value = texts.at(2).toInt();

                m_singleGeneralTable.insert(general, value);
            }

            lua_file.close();
        }
    }
}

void GeneralSelector::loadPairTable()
{
    QRegExp rx("(\\w+)\\s+(\\w+)\\s+(\\d+)\\s+(\\d+)");
    QFile file("ai-selector/pair-value.txt");
    if (file.open(QIODevice::ReadOnly)) {
        QTextStream stream(&file);
        while (!stream.atEnd()) {
            QString line = stream.readLine();
            if (!rx.exactMatch(line))
                continue;

            //SAMPLE: huangyueying zhangfei                         25 24
            QStringList texts = rx.capturedTexts();
            QString first = texts.at(1);
            QString second = texts.at(2);
            int value_f = texts.at(3).toInt();
            int value_b = texts.at(4).toInt();

            QString key_f = QString("%1+%2").arg(first).arg(second);
            m_pairTable.insert(key_f, value_f);
            QString key_b = QString("%1+%2").arg(second).arg(first);
            m_pairTable.insert(key_b, value_b);
        }

        file.close();
    }
    foreach (const QString &pack, Config.value("LuaPackages", QString()).toString().split("+")) {
        QFile lua_file(QString("extensions/ai-selector/%1-pair-value.txt").arg(pack));
        if (lua_file.exists() && lua_file.open(QIODevice::ReadOnly)) {
            QTextStream stream(&lua_file);
            while (!stream.atEnd()) {
                QString line = stream.readLine();
                if (!rx.exactMatch(line))
                    continue;

                //SAMPLE: huangyueying zhangfei                         25 24
                QStringList texts = rx.capturedTexts();
                QString first = texts.at(1);
                QString second = texts.at(2);
                int value_f = texts.at(3).toInt();
                int value_b = texts.at(4).toInt();

                QString key_f = QString("%1+%2").arg(first).arg(second);
                m_pairTable.insert(key_f, value_f);
                QString key_b = QString("%1+%2").arg(second).arg(first);
                m_pairTable.insert(key_b, value_b);
            }

            lua_file.close();
        }
    }
}

void GeneralSelector::calculatePairValues(const ServerPlayer *player, const QStringList &_candidates)
{
    // preference
    QStringList kingdoms = Sanguosha->getKingdoms();
    kingdoms.removeAll("god");
    qShuffle(kingdoms);
    if (qrand() % 2 == 0) {
        const int index = kingdoms.indexOf("qun");
        if (index != -1 && index != kingdoms.size() - 1)
            qSwap(kingdoms[index], kingdoms[index + 1]);
    }

    QStringList candidates = _candidates;
    if (!player->getGeneralName().isEmpty()) {
        foreach (const QString &candidate, _candidates) {
            if (BanPair::isBanned(player->getGeneralName(), candidate))
                candidates.removeOne(candidate);
        }
    }
    foreach (const QString &first, candidates) {
        const General *general = Sanguosha->getGeneral(first);
        if (general->isDoubleKingdoms()) continue;
        calculateDeputyValue(player, first, candidates, kingdoms);
    }
}

void GeneralSelector::calculateDeputyValue(const ServerPlayer *player, const QString &first, const QStringList &_candidates, const QStringList &kingdom_list)
{
    QStringList candidates = _candidates;
    foreach (const QString &candidate, _candidates) {
        if (BanPair::isBanned(first, candidate)) {
            m_privatePairValueTable[player][QString("%1+%2").arg(first, candidate)] = -100;
            candidates.removeOne(candidate);
        }
    }
    foreach (const QString &second, candidates) {
        if (first == second) continue;
        QString key = QString("%1+%2").arg(first, second);
        if (m_pairTable.contains(key))
            m_privatePairValueTable[player][key] = m_pairTable.value(key);
        else {
            const General *general1 = Sanguosha->getGeneral(first);
            const General *general2 = Sanguosha->getGeneral(second);
            Q_ASSERT(general1 && general2);
            QString kingdom = general1->getKingdom();

            if ((kingdom != "careerist" && !general2->getKingdoms().contains(kingdom)) || general2->isLord() || general2->getKingdoms().contains("careerist")) continue;
            const double general2_value = m_singleGeneralTable.value(second, 0);
            double v = m_singleGeneralTable.value(first, 0) + general2_value;

            if (!kingdom_list.isEmpty())
                v += (kingdom_list.indexOf(kingdom) - 1);

            const int max_hp = general1->getMaxHpHead() + general2->getMaxHpDeputy();
            if (max_hp % 2) v -= 1;

            if (general1->isCompanionWith(second)) v += 3;

            if (general1->isFemale()) 
            {
                if ("wu" == kingdom)
                    v -= 0.5;
                else if (kingdom != "qun")
                    v += 0.5;
            } 
            else if ("qun" == kingdom)
                v += 0.5;

            if (general1->hasSkill("baoling") && general2_value > 6) v -= 5;//董卓
            if (general1->hasSkill("cunsi"))        v -= 2;//糜夫人副
            if (general1->hasSkill("jianglve"))     v -= 2;//王平副
            if (general1->hasSkill("qingyin"))      v -= 1;//刘巴副
            if (general1->hasSkill("enyuan"))       v += 0.5;//法正主
            if (general1->hasSkill("tianxiang"))    v += 0.5;//小乔主
            if (general1->hasSkill("xiaoji"))       v += 1;//孙尚香主
            if (general1->hasSkill("diancai"))      v += 0.5;//吕范主
            if (general1->hasSkill("qice"))         v += 0.5;//荀攸主
            if (general1->hasSkill("xishe"))        v += 0.5;//黄祖主

            if (max_hp < 8) {
                QSet<QString> need_high_max_hp_skills;
                need_high_max_hp_skills << "zhiheng" << "zaiqi" << "kurou";
                foreach (const Skill *skill, general1->getVisibleSkills() + general2->getVisibleSkills()) {
                    if (need_high_max_hp_skills.contains(skill->objectName())) v -= 5;
                }
            }

            if (Config.value("EnableLordConvertion", true).toBool() && qrand() % 3 > 0)//设置君主替换同时3分之2的概率
            {
                if (general1->hasSkill("rende"))        v += 10;    //刘备 m_singleGeneralTable.value("lord_liubei", 0)
                if (general1->hasSkill("guidao"))       v += 10;    //张角 m_singleGeneralTable.value("lord_zhangjiao", 0)
                if (general1->hasSkill("zhiheng"))      v += 10;    //孙权 m_singleGeneralTable.value("lord_sunquan", 0)
                if (general1->hasSkill("jianxiong"))    v += 10;    //曹操 m_singleGeneralTable.value("lord_caocao", 0)
            }

            m_privatePairValueTable[player][key] = v;
        }
    }
}
