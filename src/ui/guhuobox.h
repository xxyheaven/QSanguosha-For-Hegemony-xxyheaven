#ifndef GUHUOBOX
#define GUHUOBOX

#include "graphicsbox.h"
#include "carditem.h"
#include "title.h"

class QScrollBar;

class GuhuoBox : public GraphicsBox
{
    Q_OBJECT

public:
    GuhuoBox(const QString& skill_name, const QString& flags, bool playonly = true);
    QString getSkillName()const
    {
        return skill_name;
    }

signals:
    void onButtonClick();

public slots:
    void popup();
    void reply();
    void clear();

    void scrollBarValueChanged(int newValue);

protected:
    virtual QRectF boundingRect() const;

    bool isButtonEnable(const QString &card) const;
    bool isButtonVisible(const QString &card) const;

    QString translate(const QString &option) const;

    virtual void wheelEvent(QGraphicsSceneWheelEvent *event);

    bool play_only;
    QString flags;
    QString skill_name;

    QList<CardItem *> generalItems;
    QList<CardItem *> buttons;

    QList<Title*> titles;

    static const int topBlankWidth;
    static const int bottomBlankWidth;
    static const int interval;
    static const int outerBlankWidth;

    static const int titleWidth;

private:
    int maxcardcount, maxrow, scale;

    QScrollBar *m_vScrollBar;
    int m_oldScrollValue;

    void createCardItem(const QString &cardname, const QPointF &pos);
    void onGeneralItemClicked();
    void updateCardItems();
};

#endif // GUHUOBOX

