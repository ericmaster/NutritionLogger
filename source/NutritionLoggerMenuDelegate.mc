import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
using Toybox.ActivityRecording as AR;

class NutritionLoggerMenuDelegate extends WatchUi.MenuInputDelegate {

    var mPostStop as Boolean;

    function initialize(postStop as Boolean?) {
        MenuInputDelegate.initialize();
        mPostStop = (postStop == null) ? false : postStop;
    }

    function onMenuItem(item as Symbol) as Void {
        var app = getApp();
        if (mPostStop) {
            if (item == :item_1) { // Save
                if (app.mSession != null) {
                    var ok = app.mSession.save();
                    System.println("Save: " + ok);
                    app.mSession = null;
                    WatchUi.popView(WatchUi.SLIDE_DOWN);
                    WatchUi.requestUpdate();
                }
            } else if (item == :item_2) { // Discard
                if (app.mSession != null) {
                    var ok2 = app.mSession.discard();
                    System.println("Discard: " + ok2);
                    app.mSession = null;
                    WatchUi.popView(WatchUi.SLIDE_DOWN);
                    WatchUi.requestUpdate();
                }
            }
        } else {
            System.println("Menu item: " + item);
        }
    }

}