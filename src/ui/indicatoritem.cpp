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
#include "indicatoritem.h"
#include "engine.h"

#include <QPainter>
#include <QGraphicsBlurEffect>
#include <QSequentialAnimationGroup>
#include <QPropertyAnimation>
#include <QPauseAnimation>
#include <QtMath>

#define PI double(3.141592653589793238462643383179502884)

IndicatorItem::IndicatorItem(const QPointF &start, const QPointF &real_finish, Player *player, int level)
    : start(start), finish(start), real_finish(real_finish), level(level)
{
    color = Sanguosha->getKingdomColor(player->getKingdom());
    width = player->isLord() ? 4 : 3;
}

void IndicatorItem::doAnimation()
{
    QSequentialAnimationGroup *group = new QSequentialAnimationGroup(this);

    QPropertyAnimation *animation = new QPropertyAnimation(this, "finish");
    animation->setEndValue(real_finish);
    if (level < 5)
        animation->setEasingCurve(QEasingCurve::OutExpo);
    animation->setDuration(500);

    QPropertyAnimation *pause = new QPropertyAnimation(this, "opacity");
    pause->setEndValue(0);
    if (level < 5)
        pause->setEasingCurve(QEasingCurve::InExpo);
    pause->setDuration(1000);

    group->addAnimation(animation);
    group->addAnimation(pause);

    group->start(QAbstractAnimation::DeleteWhenStopped);

    connect(group, SIGNAL(finished()), this, SLOT(deleteLater()));
}

QPointF IndicatorItem::getFinish() const
{
    return finish;
}

void IndicatorItem::setFinish(const QPointF &finish)
{
    this->finish = finish;
    update();
}

void IndicatorItem::paint(QPainter *painter, const QStyleOptionGraphicsItem *, QWidget *)
{
    if (level > 4)
    {
        painter->setRenderHint(QPainter::SmoothPixmapTransform);

        QPointF mFRs = mapFromScene(start), mFRf = mapFromScene(finish),
                mFRrf = mapFromScene(real_finish);
        double dx = mFRs.x() - mFRf.x(), dy = mFRs.y() - mFRf.y(),
               drx = mFRs.x() - mFRrf.x(), dry = mFRs.y() - mFRrf.y();

        QPixmap gline(QString("image/system/indicators/golden.png")), dragon;
        double linelength = sqrt(pow(dx, 2) + pow(dy, 2)), rlength = linelength;

        QEasingCurve easing;
        int rframe;
        if (finish != real_finish)
        {
            easing.setType(QEasingCurve::OutExpo);
            double totalength = sqrt(pow(drx, 2) + pow(dry, 2)),
                   progress = linelength / totalength, frame = progress * 0.5 * 48;
            rlength = easing.valueForProgress(progress) * totalength;
            gline = gline.scaled(round(rlength), gline.height(), Qt::IgnoreAspectRatio, Qt::SmoothTransformation);
            rframe = int(frame) % 24;
        }
        else
        {
            easing.setType(QEasingCurve::InExpo);
            double progress = 1 - painter->opacity(), frame = progress * 0.5 * 48,
                   ropacity = 1 - easing.valueForProgress(progress);
            painter->setOpacity(ropacity);
            gline = gline.scaled(round(linelength), gline.height(), Qt::IgnoreAspectRatio, Qt::SmoothTransformation);
            rframe = int(frame) % 24;
        }

        QString frameNum = QString::number(rframe);
        if (dx > 0)
            dragon.load(QString("image/system/indicators/toleft/%1.png").arg(frameNum));
        else
            dragon.load(QString("image/system/indicators/toright/%1.png").arg(frameNum));

        double rotation;
        if (dx != 0)
            rotation = atan(dy / dx) * 180 / PI;
        else
            rotation = dy > 0 ? -90 : 90;

        painter->translate(mFRs);
        painter->rotate(rotation);
        if (dx > 0)
            painter->rotate(180);
        painter->drawPixmap(0, -gline.height() / 2, gline);
        if (dx > 0)
            painter->rotate(-180);
        if (dragon.width() / 2 < rlength)
        {
            if (dx > 0)
                painter->drawPixmap(-rlength, -dragon.height() / 2 - 1, dragon);
            else
                painter->drawPixmap(-dragon.width() + rlength, -dragon.height() / 2, dragon);
        }
    }
    else
    {
        painter->setRenderHint(QPainter::Antialiasing);

        QPen pen(color);
        pen.setWidthF(width);

        int baseX = qMin(start.x(), finish.x());
        int baseY = qMin(start.y(), finish.y());

        QLinearGradient linearGrad(start - QPoint(baseX, baseY),
            finish - QPoint(baseX, baseY));
        QColor start_color(255, 255, 255, 0);
        linearGrad.setColorAt(0, start_color);
        linearGrad.setColorAt(1, color.lighter());


        QBrush brush(linearGrad);
        pen.setBrush(brush);

        painter->setPen(pen);
        painter->drawLine(mapFromScene(start), mapFromScene(finish));

        QPen pen2(QColor(200, 200, 200, 30));
        pen2.setWidth(6);
        painter->setPen(pen2);
        painter->drawLine(mapFromScene(start), mapFromScene(finish));
    }
}

QRectF IndicatorItem::boundingRect() const
{
    qreal width = qAbs(start.x() - real_finish.x());
    qreal height = qAbs(start.y() - real_finish.y());

    if (level > 4)
        return QRectF(0, 0, width, height).adjusted(-64, -64, 64, 64);
    return QRectF(0, 0, width, height).adjusted(-2, -2, 2, 2);
}

