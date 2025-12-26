import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class ConfirmationView extends WatchUi.View {
    private var mMessage as String;
    private var mAction as Symbol;

    function initialize(message as String, action as Symbol) {
        View.initialize();
        mMessage = message;
        mAction = action;
    }

    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.MainLayout(dc));
    }

    function onUpdate(dc as Dc) as Void {
        // Clear screen
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        // Draw confirmation message
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            dc.getWidth() / 2,
            dc.getHeight() / 2 - 40,
            Graphics.FONT_MEDIUM,
            mMessage,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );

        // Draw action buttons
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            dc.getWidth() / 2,
            dc.getHeight() / 2 + 10,
            Graphics.FONT_SMALL,
            "START = Confirm",
            Graphics.TEXT_JUSTIFY_CENTER
        );

        dc.drawText(
            dc.getWidth() / 2,
            dc.getHeight() / 2 + 35,
            Graphics.FONT_SMALL,
            "BACK = Cancel",
            Graphics.TEXT_JUSTIFY_CENTER
        );
    }

    function getAction() as Symbol {
        return mAction;
    }
}
