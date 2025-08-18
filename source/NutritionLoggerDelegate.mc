import Toybox.Lang;
import Toybox.WatchUi;
using Toybox.System as Sys;
using Toybox.Activity as Activity;
using Toybox.ActivityRecording as AR;

class NutritionLoggerDelegate extends WatchUi.BehaviorDelegate {
  var mLastKeyDownAt as Number?; // for measuring press duration
  var mLastKeyCode as Number?; // track which key went down

  function initialize() {
    BehaviorDelegate.initialize();
  }

  function onMenu() as Boolean {
    // Treat Menu like UP to cycle selection
    var app = getApp();
    app.mSelectedIndex = (app.mSelectedIndex + 2) % 3;
    WatchUi.requestUpdate();
    return true;
  }

  function onKey(keyEvent as KeyEvent) as Boolean {
    var app = getApp();
    var session = app.mSession;
    var key = keyEvent.getKey();

    // Button mapping:
    // - Start/Stop (ENTER): Start/Pause/Resume activity
    // - Up/Menu: Cycle up selected counter
    // - Down: Cycle down selected counter
    // - Light: Record intake on selected counter
    // - Back/Lap: Undo last intake
    Sys.println("Key pressed: " + key);
    var isStartKey = key == WatchUi.KEY_ENTER;
    if (isStartKey) {
      if (session == null) {
        Sys.println("Starting new session");
        // Create and start a new session for Trail Running
        try {
          app.mSession = AR.createSession({
            :name => "Trail Run",
            :sport => Activity.SPORT_RUNNING,
            :subSport => Activity.SUB_SPORT_TRAIL,
            :sensorLogger => app.logger
          });
          app.resetCounters();
          app.initFitFields();
          app.mSession.setTimerEventListener(method(:onTimerEvent));
          app.mSession.start();
        } catch (e) {
          Sys.println("Failed to start session: " + e);
        }
        WatchUi.requestUpdate();
      } else if (session.isRecording()) {
        Sys.println("Pausing");
        // Pause
        session.stop();
        // Show paused menu with Resume/Save/Discard
        WatchUi.pushView(
          new Rez.Menus.MainMenu(),
          new NutritionLoggerMenuDelegate(true),
          WatchUi.SLIDE_UP
        );
        WatchUi.requestUpdate();
      } else {
        Sys.println("Resuming");
        // Resume
        session.start();
        WatchUi.requestUpdate();
      }
      return true;
    } else if (key == WatchUi.KEY_UP || key == WatchUi.KEY_MENU) {
      // Cycle up selected counter (wrap 0..2)
      app.mSelectedIndex = (app.mSelectedIndex + 2) % 3; // up = previous
      WatchUi.requestUpdate();
      return true;
    } else if (key == WatchUi.KEY_DOWN) {
      // Cycle down selected counter
      app.mSelectedIndex = (app.mSelectedIndex + 1) % 3;
      WatchUi.requestUpdate();
      return true;
    }
    // While recording, consume any other key (e.g., Back/Lap) so the app doesn't exit.
    // The short/long behavior is handled in onKeyReleased where we can measure hold time.
    if (session != null && session.isRecording()) {
      return true;
    }
    return false;
  }

  // Some devices deliver Light as KEY_POWER or only via key pressed events; also track key-down for Back timing
  function onKeyPressed(keyEvent as KeyEvent) as Boolean {
    var key = keyEvent.getKey();
    var type = keyEvent.getType();
    Sys.println("onKeyPressed key=" + key + " type=" + type);
    if (type == WatchUi.PRESS_TYPE_DOWN) {
      mLastKeyDownAt = Sys.getTimer();
      mLastKeyCode = key;
    }
    return false;
  }

  // Use release to decide short vs long Back/Lap
  function onKeyReleased(keyEvent as KeyEvent) as Boolean {
    var app = getApp();
    var session = app.mSession;
    var key = keyEvent.getKey();
    var type = keyEvent.getType();
    Sys.println("onKeyReleased key=" + key + " type=" + type);

    if (session == null || !session.isRecording()) {
      return false;
    }

    // Consider Back/Lap as the key that isn't one of our known handled ones
    var isKnown =
      key == WatchUi.KEY_ENTER ||
      key == WatchUi.KEY_UP ||
      key == WatchUi.KEY_DOWN ||
      key == WatchUi.KEY_MENU ||
      key == WatchUi.KEY_LIGHT ||
      key == WatchUi.KEY_POWER;
    if (!isKnown && mLastKeyCode != null && key == mLastKeyCode) {
      var now = Sys.getTimer();
      var downAt = mLastKeyDownAt == null ? now : mLastKeyDownAt;
      var heldMs = now - downAt;
      var LONG_MS = 600;

      if (heldMs >= LONG_MS) {
        // Long press = undo last intake
        if (app.mEventStack.size() > 0) {
          var i = app.mEventStack.size() - 1;
          var lastIdx = app.mEventStack[i];
          app.mEventStack = app.mEventStack.slice(0, i);
          var newVal = app.mCounters[lastIdx] - 1.0;
          if (newVal < 0.0) {
            newVal = 0.0;
          }
          app.mCounters[lastIdx] = newVal;
          app.setFieldByIndex(lastIdx, newVal);
          WatchUi.requestUpdate();
        }
      } else {
        // Short press = record intake
        var idx = app.mSelectedIndex;
        app.mCounters[idx] = app.mCounters[idx] + 1.0;
        app.mEventStack.add(idx);
        app.setFieldByIndex(idx, app.mCounters[idx]);
        WatchUi.requestUpdate();
      }

      // Clear state
      mLastKeyCode = null;
      mLastKeyDownAt = null;
      return true;
    }

    return false;
  }

  // Back/Lap handled in onKeyReleased; keep as no-op so system Back behavior works when idle
  function onBack() as Boolean {
    return false;
  }

  // Handle timer events to refresh UI
  function onTimerEvent(
    eventType as AR.TimerEventType,
    data as Dictionary
  ) as Void {
    // Keep developer fields updated on each tick so values are written
    var app = getApp();
    if (app.mSession != null && app.mSession.isRecording()) {
      app.setFieldByIndex(0, app.mCounters[0]);
      app.setFieldByIndex(1, app.mCounters[1]);
      app.setFieldByIndex(2, app.mCounters[2]);
    }
    // Refresh UI
    WatchUi.requestUpdate();
  }
}
