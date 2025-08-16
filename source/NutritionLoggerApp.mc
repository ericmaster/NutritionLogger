import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
using Toybox.System as Sys;
using Toybox.Activity as Activity;
using Toybox.ActivityRecording as AR;

class NutritionLoggerApp extends Application.AppBase {
  // Global session reference
  var mSession as AR.Session?;

  function initialize() {
    AppBase.initialize();
  }

  // onStart() is called on application start up
  function onStart(state as Dictionary?) as Void {}

  // onStop() is called when your application is exiting
  function onStop(state as Dictionary?) as Void {
    // Ensure recording is properly stopped if app exits unexpectedly
    if (mSession != null && mSession.isRecording()) {
      mSession.stop();
      // Don't auto-save; let user decide next launch
    }
  }

  // Return the initial view of your application here
  function getInitialView() as [Views] or [Views, InputDelegates] {
    return [new NutritionLoggerView(), new NutritionLoggerDelegate()];
  }
}

function getApp() as NutritionLoggerApp {
  return Application.getApp() as NutritionLoggerApp;
}
