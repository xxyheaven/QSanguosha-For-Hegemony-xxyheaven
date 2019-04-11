#include "selectbox.h"
#include "button.h"
#include "engine.h"
#include "standard.h"
#include "clientplayer.h"
#include "skin-bank.h"
#include "roomscene.h"
#include "stylehelper.h"

#include <QPropertyAnimation>
#include <QGraphicsSceneMouseEvent>

const int SelectBox::defaultButtonHeight = 26;
const int SelectBox::interval = 30;
const int SelectBox::defaultBoundingWidth = 400;

SelectBox::SelectBox(const QString &skillname, const QStringList &options)
{
    this->skill_name = skillname;
    this->options = options;
    RoomSceneInstance->current_select_box = this;

    foreach (const QString &card_name, options) {
        QSanButton *button = new QSanButton(this, getButtonWidth(card_name), translate(card_name));
        button->setObjectName(card_name);

        buttons[card_name] = button;

        button->setEnabled(isButtonEnable(card_name));

        QString original_tooltip = QString(":%1").arg(title);
        QString tooltip = Sanguosha->translate(original_tooltip);
        if (tooltip == original_tooltip) {
            original_tooltip = QString(":%1").arg(card_name);
            tooltip = Sanguosha->translate(original_tooltip);
        }
        connect(button, &QSanButton::clicked, this, &SelectBox::reply);
        if (tooltip != original_tooltip)
            button->setToolTip(tooltip);
    }

    const QRectF rect = boundingRect();
    setPos(RoomSceneInstance->tableCenterPos().x() - rect.width() / 2, RoomSceneInstance->tableCenterPos().y()*2 - 230);

    setFlag(QGraphicsItem::ItemIsMovable, false);
    show();
    int x = interval;

    foreach (const QString &card_name, options) {
        QPointF apos;
        apos.setX(x);
        x += (interval + getButtonWidth(card_name));
        apos.setY(0);
        buttons[card_name]->setPos(apos);
    }
}

QRectF SelectBox::boundingRect() const
{
    int n = options.length();
    int allbuttonswidth = 0;
    foreach (const QString &card_name, options) {
        int buttonwidth = getButtonWidth(card_name);
        allbuttonswidth += buttonwidth;
    }
    return QRectF(0, 0, (allbuttonswidth + (n+1)*interval), defaultButtonHeight);
}

bool SelectBox::isButtonEnable(const QString &card_name) const
{
    const Skill *skill = Sanguosha->getSkill(skill_name);
    if (skill == NULL)
        return false;
    return skill->buttonEnabled(card_name);
}

int SelectBox::getButtonWidth(const QString &card_name) const
{
    //IQSanComponentSkin::QSanShadowTextFont textfont = G_COMMON_LAYOUT.m_choiceInfoFont;
    //QString fontname = textfont.m_fontName;
    //QString fontname = "wqy-microhei";
    //QFont font = StyleHelper::getFontByFileName(fontname + ".ttc");
    //font.setPixelSize(textfont.m_fontSize.width());
    //QFontMetrics fontMetrics(font);
    QFontMetrics fontMetrics(Button::defaultFont());
    int width = fontMetrics.width(translate(card_name));
    // Otherwise it would look compact
    width += 28;
    return width;
}

void SelectBox::buttonFilter(const Card *card, const QList<const Player *> &target)
{
    RoomSceneInstance->setOkButton(false);
    const Skill *skill = Sanguosha->getSkill(skill_name);
    if (skill == NULL) return;
    QList<const Card *> selected;
    if (card) {
        foreach (int id, card->getSubcards()) {
            selected << Sanguosha->getCard(id);
        }
    }
    foreach(QSanButton *button, buttons.values())
        button->setEnabled(skill->buttonEnabled(button->objectName(), selected, target));
}

void SelectBox::reply()
{
    QString choice = sender()->objectName();
    Self->tag[skill_name] = choice;
    emit onButtonClick();
    clear();
}

void SelectBox::clear()
{
    RoomSceneInstance->current_select_box = NULL;

    if (sender() != NULL && Self->tag[skill_name] == sender()->objectName() && Sanguosha->getViewAsSkill(skill_name) != NULL) {
        RoomSceneInstance->getDasboard()->updatePending();
        RoomSceneInstance->doOkButton();
    }

    if (!isVisible())
        return;

    foreach(QSanButton *button, buttons.values())
        button->deleteLater();

    buttons.values().clear();

    disappear();
    deleteLater();
}

QString SelectBox::translate(const QString &option) const
{
    QString title = QString("%1:%2").arg(skill_name).arg(option);
    QString translated = Sanguosha->translate(title);
    if (translated == title)
        translated = Sanguosha->translate(option);
    return translated;
}
