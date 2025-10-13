import Toybox.Lang;
import Toybox.WatchUi;
using Toybox.System as Sys;
using Toybox.Activity as Activity;
using Toybox.ActivityRecording as AR;
using Toybox.Attention as Attention;

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
    debugLog("Key pressed: " + key);

    if (key == WatchUi.KEY_ENTER) {
      return onStartKey();
    } else if (key == WatchUi.KEY_ESC) {
      return onBackKey();
    }

    if (session.isRecording()){
      if (key == WatchUi.KEY_UP || key == WatchUi.KEY_MENU) {
        app.mSelectedIndex = ((app.mSelectedIndex + 5) % 5) - 1;
        WatchUi.requestUpdate();
        return true;
      } else if (key == WatchUi.KEY_DOWN) {
        app.mSelectedIndex = ((app.mSelectedIndex + 2) % 5) - 1;
        WatchUi.requestUpdate();
        return true;
      }
      // Do nothing if key is not handled
      return false;
    }
    return false;
  }

  function onStartKey() as Boolean {
    var app = getApp();
    var session = app.mSession;

    // Only react to Start/Stop (ENTER) when app is not started
    if (session == null) {
      debugLog("Starting new session");
      try {
        // Initialize accelerometer/gyroscope logging when recording starts
        app.initSensorLogger();
        app.mSession = AR.createSession({
          :name => "Trail Run",
          :sport => Activity.SPORT_RUNNING,
          :subSport => Activity.SUB_SPORT_TRAIL,
          :sensorLogger => app.logger,
        });
        app.resetCounters();
        app.mSelectedIndex = 0;
        app.initFitFields();
        app.mSession.setTimerEventListener(method(:onTimerEvent));
        app.mSession.start();
        // Sound a beep when session starts
        if (Attention has :playTone) {
          Attention.playTone(Attention.TONE_START);
        }
      } catch (e) {
        debugLog("Failed to start session: " + e);
      }
      WatchUi.requestUpdate();
      return true;
    }

    // App is started, handle counter increment
    if (session.isRecording() && app.mSelectedIndex != null) {
      if (app.mSelectedIndex == -1) {
        debugLog("Pausing");
        // Pause
        session.stop();
        // Sound a beep when session stops
        if (Attention has :playTone) {
          Attention.playTone(Attention.TONE_STOP);
        }
        // Show paused menu with Resume/Save/Discard
        WatchUi.pushView(
          new Rez.Menus.MainMenu(),
          new NutritionLoggerMenuDelegate(true),
          WatchUi.SLIDE_UP
        );
        WatchUi.requestUpdate();
      } else {
        var idx = app.mSelectedIndex;
        if (idx == app.RPE_FIELD) {
          // Increase RPE (0 - 4)
          app.mRPE = app.mRPE + 1 < 4 ? app.mRPE + 1 : 4;
          app.setFieldByIndex(app.RPE_FIELD, app.mRPE);
        } else {
          // Increment selected counter
          var counterIdx = idx - 1; // Counter index start at 0
          app.mCounters[counterIdx] = app.mCounters[counterIdx] + 1;
          app.setFieldByIndex(idx, app.mCounters[counterIdx]);
        }
        WatchUi.requestUpdate();
        return true;
      }
    }

    return false;
  }

  function onBackKey() as Boolean {
    var app = getApp();
    var session = app.mSession;

    // Only handle back key when app is started and counter is selected
    if (session.isRecording() && app.mSelectedIndex != null) {
      if (app.mSelectedIndex == -1) {
        debugLog("Pausing");
        // Pause
        session.stop();
        // Sound a beep when session stops
        if (Attention has :playTone) {
          Attention.playTone(Attention.TONE_STOP);
        }
        // Show paused menu with Resume/Save/Discard
        WatchUi.pushView(
          new Rez.Menus.MainMenu(),
          new NutritionLoggerMenuDelegate(true),
          WatchUi.SLIDE_UP
        );
        WatchUi.requestUpdate();
      } else {
        // Decrement selected counter
        var idx = app.mSelectedIndex;
        if (idx == app.RPE_FIELD) {
          // Decrease RPE (0 - 4)
          app.mRPE = app.mRPE - 1 <= 0 ? 0 : app.mRPE - 1;
          app.setFieldByIndex(app.RPE_FIELD, app.mRPE);
        } else {
          var counterIdx = idx - 1; // Counter index start at 0
          app.mCounters[counterIdx] = app.mCounters[counterIdx] - 1;
          if (app.mCounters[counterIdx] < 0) {
            app.mCounters[counterIdx] = 0;
          }
          app.setFieldByIndex(idx, app.mCounters[counterIdx]);
        }
        WatchUi.requestUpdate();
      }
      return true;
    }

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
