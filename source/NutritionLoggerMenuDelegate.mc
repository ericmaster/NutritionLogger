import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
using Toybox.ActivityRecording as AR;
using Toybox.System as Sys;

class NutritionLoggerMenuDelegate extends WatchUi.MenuInputDelegate {
  var mPostStop as Boolean;

  function initialize(postStop as Boolean?) {
    MenuInputDelegate.initialize();
    mPostStop = postStop == null ? false : postStop;
  }

  function onMenuItem(item as Symbol) as Void {
    var app = getApp();
    Sys.println("mPostStop: " + mPostStop);
    if (mPostStop) {
      if (item == :item_1) {
        Sys.println("Resume");
        // Resume
        if (app.mSession != null && !app.mSession.isRecording()) {
          app.mSession.start();
        }
        WatchUi.requestUpdate();
      } else if (item == :item_2) {
        // Save
        if (app.mSession != null) {
          var ok = app.mSession.save();
          System.println("Save: " + ok);
          app.mSession = null;
        }
        System.exit();
      } else if (item == :item_3) {
        // Discard
        if (app.mSession != null) {
          var ok2 = app.mSession.discard();
          System.println("Discard: " + ok2);
          app.mSession = null;
        }
        System.exit();
      }
    } else {
      Sys.println("Else");
      // Idle menu: Close app
      if (item == :item_2 || item == :item_3) {
        System.println("Closing app");
        System.exit();
      }
    }
  }
}
