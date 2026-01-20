#include <QApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QIcon>

#include "ui/pkg_unpacker.h"

using namespace Qt::StringLiterals;

int main(int argc, char *argv[]) {
    QApplication app(argc, argv);
    app.setOrganizationDomain("shadps4.net");
    app.setOrganizationName("shadPS4");
    app.setApplicationName("ps4pkgunpacker");
    app.setApplicationVersion("1.0");
    app.setWindowIcon(QIcon::fromTheme("package-x-generic"));

    if (QQuickStyle::name().isEmpty()) {
        QQuickStyle::setStyle("org.kde.desktop");
    }

    PkgUnpacker unpacker;

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("unpacker", &unpacker);

    const QUrl url(u"qrc:/ps4pkgunpacker/src/ui/Main.qml"_s);
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
        &app, [url](QObject *obj, const QUrl &objUrl) {
            if (!obj && url == objUrl)
                QCoreApplication::exit(-1);
        }, Qt::QueuedConnection);
    engine.load(url);

    return app.exec();
}
