import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
using Toybox.ActivityRecording as AR;
using Toybox.System as Sys;

class NutritionLoggerMenuDelegate extends WatchUi.BehaviorDelegate {
  var mPostStop as Boolean;
  var mSelectedItem as Number = 0; // 0 = Save, 1 = Discard, 2 = Settings

  function initialize(postStop as Boolean?) {
    BehaviorDelegate.initialize();
    mPostStop = postStop == null ? false : postStop;
    mSelectedItem = 0;
  }

  function onKey(keyEvent as KeyEvent) as Boolean {
    var key = keyEvent.getKey();

    if (key == WatchUi.KEY_UP) {
      // Move selection up (3 items)
      mSelectedItem = (mSelectedItem - 1 + 3) % 3;
      WatchUi.requestUpdate();
      return true;
    } else if (key == WatchUi.KEY_DOWN) {
      // Move selection down (3 items)
      mSelectedItem = (mSelectedItem + 1) % 3;
      WatchUi.requestUpdate();
      return true;
    } else if (key == WatchUi.KEY_ENTER) {
      // Select current item with START button
      onSelectItem();
      return true;
    } else if (key == WatchUi.KEY_ESC) {
      // BACK button - does nothing (consistent with settings)
      return true;
    } else if (key == WatchUi.KEY_MENU) {
      // MENU button - return to main view
      WatchUi.popView(WatchUi.SLIDE_DOWN);
      return true;
    }

    return false;
  }

  function onSelectItem() as Void {\n    if (mPostStop) {\n      if (mSelectedItem == 0) {
        // Save - show confirmation
        debugLog("Save confirmation");
        var confirmView = new ConfirmationView("Save Session?", :save);
        var confirmDelegate = new ConfirmationDelegate(:save);
        WatchUi.pushView(confirmView, confirmDelegate, WatchUi.SLIDE_UP);
      } else if (mSelectedItem == 1) {
        // Discard - show confirmation
        debugLog("Discard confirmation");
        var confirmView = new ConfirmationView("Discard Session?", :discard);
        var confirmDelegate = new ConfirmationDelegate(:discard);
        WatchUi.pushView(confirmView, confirmDelegate, WatchUi.SLIDE_UP);
      } else if (mSelectedItem == 2) {
        // Settings - open settings view
        debugLog("Opening Settings from menu");
        var settingsDelegate = new SettingsDelegate();
        var settingsView = new SettingsView(settingsDelegate);
        WatchUi.pushView(settingsView, settingsDelegate, WatchUi.SLIDE_UP);
      }
    }
  }

  function getSelectedItem() as Number {
    return mSelectedItem;
  }
}
