import Toybox.Lang;
import Toybox.WatchUi;
using Toybox.System as Sys;
using Toybox.Activity as Activity;
using Toybox.ActivityRecording as AR;
using Toybox.Attention as Attention;
using Toybox.Timer;

class NutritionLoggerDelegate extends WatchUi.BehaviorDelegate {
  var mLastKeyDownAt as Number?; // for measuring press duration
  var mHoldTimer as Timer.Timer?;
  var mHoldTriggered as Boolean = false;
  var mIgnoreNextRelease as Boolean = false;
  var mKeyProcessing as Boolean = false; // flag to prevent double key processing

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
    // Debug log to see which keys are actually received
    debugLog("Debug - Key Pressed: " + key + " (Light=" + WatchUi.KEY_LIGHT + ")"); 
    debugLog("Key pressed: " + key);

    if (key == WatchUi.KEY_ENTER) {
      return onStartKey();
    } else if (key == WatchUi.KEY_ESC) {
      return onBackKey();
    }

    if (session != null && session.isRecording()){
      if (key == WatchUi.KEY_UP || key == WatchUi.KEY_MENU) {
        // Cycle up: 0->3->2->1->0
        app.mSelectedIndex = (app.mSelectedIndex + 3) % 4;
        // Play selection tone
        if (Attention has :playTone) {
          Attention.playTone(Attention.TONE_KEY);
        }
        WatchUi.requestUpdate();
        return true;
      } else if (key == WatchUi.KEY_DOWN) {
        // Cycle down: 0->1->2->3->0
        app.mSelectedIndex = (app.mSelectedIndex + 1) % 4;
        // Play selection tone
        if (Attention has :playTone) {
          Attention.playTone(Attention.TONE_KEY);
        }
        WatchUi.requestUpdate();
        return true;
      }
      // Do nothing if key is not handled
      return false;
    }
    return false;
  }



  // Handle key release for short vs long press
  function onKeyReleased(evt as KeyEvent) as Boolean {
    var app = getApp();
    if (app.mSession != null && app.mSession.isRecording() && evt.getKey() == WatchUi.KEY_ENTER) {
      
      // Stop hold timer if it's running
      if (mHoldTimer != null) {
        mHoldTimer.stop();
        mHoldTimer = null;
      }

      // Check if we should ignore this release (e.g. just started session)
      if (mIgnoreNextRelease) {
        mIgnoreNextRelease = false;
        mLastKeyDownAt = null;
        mKeyProcessing = false; // Reset processing flag
        return true;
      }

      // If hold logic didn't trigger (Short Press), then Increment
      if (!mHoldTriggered) {
        incrementCounter(app);
      }
      
      // Reset state
      mHoldTriggered = false;
      mLastKeyDownAt = null;
      mKeyProcessing = false; // Reset processing flag
      return true;
    }
    return false;
  }

  // Timer callback for Long Press (Hold)
  function onHoldTimer() as Void {
    var app = getApp();
    // Only if session is still recording
    if (app.mSession != null && app.mSession.isRecording()) {
        mHoldTriggered = true;
        decrementCounter(app); // Execute undo immediately
        debugLog("Hold Action Triggered (Decrement)");
    }
  }

  function incrementCounter(app as NutritionLoggerApp) as Boolean {
      var idx = app.mSelectedIndex;
      if (idx == app.RPE_FIELD) {
        // Increase RPE (0 - 4)
        app.mRPE = app.mRPE + 1 < 4 ? app.mRPE + 1 : 4;
        app.setFieldByIndex(app.RPE_FIELD, app.mRPE);
      } else {
        // Increment selected counter (Water, Electrolytes, Food)
        var counterIdx = idx - 1; // Water=1->0, Electrolytes=2->1, Food=3->2
        app.mCounters[counterIdx] = app.mCounters[counterIdx] + 1;
        app.setFieldByIndex(idx, app.mCounters[counterIdx]);
      }
      
      // Haptic feedback - short pulse
      if (Attention has :vibrate) {
        Attention.vibrate([new Attention.VibeProfile(50, 100)]);
      }
      // Audio feedback
      if (Attention has :playTone) {
        Attention.playTone(Attention.TONE_START);
      }
      
      WatchUi.requestUpdate();
      return true;
  }

  function decrementCounter(app as NutritionLoggerApp) as Boolean {
      var idx = app.mSelectedIndex;
      if (idx == app.RPE_FIELD) {
        // Decrease RPE (0 - 4)
        app.mRPE = app.mRPE - 1 <= 0 ? 0 : app.mRPE - 1;
        app.setFieldByIndex(app.RPE_FIELD, app.mRPE);
      } else {
        // Decrement selected counter
        var counterIdx = idx - 1; // Water=1->0, Electrolytes=2->1, Food=3->2
        app.mCounters[counterIdx] = app.mCounters[counterIdx] - 1;
        if (app.mCounters[counterIdx] < 0) {
          app.mCounters[counterIdx] = 0;
        }
        app.setFieldByIndex(idx, app.mCounters[counterIdx]);
      }
      
      // Haptic feedback - double pulse for undo/decrement
      if (Attention has :vibrate) {
        Attention.vibrate([
          new Attention.VibeProfile(50, 100),
          new Attention.VibeProfile(0, 50),
          new Attention.VibeProfile(50, 100)
        ]);
      }
      // Audio feedback
      if (Attention has :playTone) {
        Attention.playTone(Attention.TONE_RESET);
      }
      
      WatchUi.requestUpdate();
      return true;
  }

  function onStartKey() as Boolean {
    var app = getApp();
    if (app.mSession == null) {
      // Start new session
      debugLog("Starting new session");
      try {
        app.initSensorLogger();
        app.mSession = AR.createSession({
          :name => "Trail Run",
          :sport => Activity.SPORT_RUNNING,
          :subSport => Activity.SUB_SPORT_TRAIL,
          :sensorLogger => app.logger,
        });
        app.resetCounters();
        app.mSelectedIndex = app.RPE_FIELD; 
        app.initFitFields();
        app.mSession.setTimerEventListener(method(:onTimerEvent));
        app.mSession.start();
        if (Attention has :playTone) {
          Attention.playTone(Attention.TONE_START);
        }
        mIgnoreNextRelease = true;
      } catch (e) {
        debugLog("Failed to start session: " + e);
        mIgnoreNextRelease = false;
      }
      WatchUi.requestUpdate();
      return true;
    }
    // If running, we let onKeyReleased handle the Short/Long press logic
    if (app.mSession.isRecording()) {
      // Prevent re-entry if we're already processing this key press
      if (mKeyProcessing) {
        return true;
      }
      
      mKeyProcessing = true;
      mLastKeyDownAt = Sys.getTimer();
      mHoldTriggered = false;
      mHoldTimer = new Timer.Timer();
      mHoldTimer.start(method(:onHoldTimer), 1000, false);
      return true;
    }

    return false;
  }

  function onBackKey() as Boolean {
    var app = getApp();
    var session = app.mSession;

    if (session != null && session.isRecording()) {
        debugLog("Opening Menu (background recording)");
        // Push custom menu view WITH delegate we can access
        var menuDelegate = new NutritionLoggerMenuDelegate(true);
        var menuView = new NutritionLoggerMenuView(menuDelegate);
        WatchUi.pushView(
          menuView,
          menuDelegate,
          WatchUi.SLIDE_UP
        );
        WatchUi.requestUpdate();
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
