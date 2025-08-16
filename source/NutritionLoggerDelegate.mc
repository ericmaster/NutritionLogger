import Toybox.Lang;
import Toybox.WatchUi;
using Toybox.System as Sys;
using Toybox.Activity as Activity;
using Toybox.ActivityRecording as AR;

class NutritionLoggerDelegate extends WatchUi.BehaviorDelegate {
  function initialize() {
    BehaviorDelegate.initialize();
  }

  function onMenu() as Boolean {
    var app = getApp();
    var postStop = false;
    if (app.mSession != null) {
      if (app.mSession.isRecording()) {
        app.mSession.stop();
      }
      postStop = true; // Offer Save/Discard when a session exists
    }
    WatchUi.pushView(
      new Rez.Menus.MainMenu(),
      new NutritionLoggerMenuDelegate(postStop),
      WatchUi.SLIDE_UP
    );
    return true;
  }

  function onKey(keyEvent as KeyEvent) as Boolean {
    var app = getApp();
    var session = app.mSession;
    var key = keyEvent.getKey();

    // Map keys: START/ENTER toggles start/stop, UP = lap, DOWN = menu
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
          });
          app.mSession.setTimerEventListener(method(:onTimerEvent));
          app.mSession.start();
        } catch (e) {
          Sys.println("Failed to start session: " + e);
        }
        WatchUi.requestUpdate();
      } else if (session.isRecording()) {
        Sys.println("Stopping");
        // Pause
        session.stop();
        WatchUi.requestUpdate();
      } else {
        Sys.println("Resuming");
        // Resume
        session.start();
        WatchUi.requestUpdate();
      }
      return true;
    } else if (key == WatchUi.KEY_UP) {
      if (session != null && session.isRecording()) {
        session.addLap();
        Sys.println("Lap added");
        return true;
      }
    } else if (key == WatchUi.KEY_DOWN) {
      return onMenu();
    }
    return false;
  }

  // Handle timer events to refresh UI
  function onTimerEvent(
    eventType as AR.TimerEventType,
    data as Dictionary
  ) as Void {
    // For simplicity, just request UI update each event
    WatchUi.requestUpdate();
  }
}
