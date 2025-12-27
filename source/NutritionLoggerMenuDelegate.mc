import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
using Toybox.ActivityRecording as AR;
using Toybox.System as Sys;

class NutritionLoggerMenuDelegate extends WatchUi.BehaviorDelegate {
  var mPostStop as Boolean;
  var mSelectedItem as Number = 0; // 0 = Resume, 1 = Save, 2 = Discard

  function initialize(postStop as Boolean?) {
    BehaviorDelegate.initialize();
    mPostStop = postStop == null ? false : postStop;
    mSelectedItem = 0;
  }

  function onKey(keyEvent as KeyEvent) as Boolean {
    var key = keyEvent.getKey();

    if (key == WatchUi.KEY_UP) {
      // Move selection up
      mSelectedItem = (mSelectedItem - 1 + 3) % 3;
      WatchUi.requestUpdate();
      return true;
    } else if (key == WatchUi.KEY_DOWN) {
      // Move selection down
      mSelectedItem = (mSelectedItem + 1) % 3;
      WatchUi.requestUpdate();
      return true;
    } else if (key == WatchUi.KEY_ENTER) {
      // Select current item with START button
      onSelectItem();
      return true;
    } else if (key == WatchUi.KEY_ESC) {
      // BACK button - return to main view
      // Note: We don't need to set ignore flag here because BACK button doesn't trigger increments
      WatchUi.popView(WatchUi.SLIDE_DOWN);
      return true;
    }

    return false;
  }

  function onSelectItem() as Void {
    var app = getApp();
    
    if (mPostStop) {
      if (mSelectedItem == 0) {
        // Resume
        debugLog("Resume");
        
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        
        // If somehow we were paused (legacy), start again
        if (app.mSession != null && !app.mSession.isRecording()) {
          app.mSession.start();
        }
        WatchUi.requestUpdate();
      } else if (mSelectedItem == 1) {
        // Save - show confirmation
        debugLog("Save confirmation");
        var confirmView = new ConfirmationView("Save Session?", :save);
        var confirmDelegate = new ConfirmationDelegate(:save);
        WatchUi.pushView(confirmView, confirmDelegate, WatchUi.SLIDE_UP);
      } else if (mSelectedItem == 2) {
        // Discard - show confirmation
        debugLog("Discard confirmation");
        var confirmView = new ConfirmationView("Discard Session?", :discard);
        var confirmDelegate = new ConfirmationDelegate(:discard);
        WatchUi.pushView(confirmView, confirmDelegate, WatchUi.SLIDE_UP);
      }
    }
  }

  function getSelectedItem() as Number {
    return mSelectedItem;
  }
}
