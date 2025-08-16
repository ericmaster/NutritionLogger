import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
using Toybox.System as Sys;
using Toybox.Activity as Activity;
using Toybox.ActivityRecording as AR;
using Toybox.FitContributor as Fit;

class NutritionLoggerApp extends Application.AppBase {
  // Global session reference
  var mSession as AR.Session?;
  // Developer data fields
  var mWaterField as Fit.Field?;
  var mElectrolytesField as Fit.Field?;
  var mFoodField as Fit.Field?;

  // Counters and selection
  var mCounters as Array<Float> = [0.0, 0.0, 0.0]; // [water, electrolytes, food]
  var mSelectedIndex as Number = 0; // 0..2
  var mEventStack as Array<Number> = []; // stack of indices for undo

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

  // Helpers
  function resetCounters() as Void {
    mCounters = [0.0, 0.0, 0.0];
    mSelectedIndex = 0;
    mEventStack = [];
  }

  function initFitFields() as Void {
    if (mSession == null) {
      return;
    }
    try {
      // Create developer fields written on record messages
      mWaterField = mSession.createField(
        "water_intake_count",
        1,
        Fit.DATA_TYPE_FLOAT,
        { :mesgType => Fit.MESG_TYPE_RECORD, :units => "count" }
      );
      mElectrolytesField = mSession.createField(
        "electrolytes_intake_count",
        2,
        Fit.DATA_TYPE_FLOAT,
        { :mesgType => Fit.MESG_TYPE_RECORD, :units => "count" }
      );
      mFoodField = mSession.createField(
        "food_intake_count",
        3,
        Fit.DATA_TYPE_FLOAT,
        { :mesgType => Fit.MESG_TYPE_RECORD, :units => "count" }
      );
      // Initialize to zero
      mWaterField.setData(0.0);
      mElectrolytesField.setData(0.0);
      mFoodField.setData(0.0);
    } catch (e) {
      Sys.println("Failed to init Fit fields: " + e);
    }
  }

  function setFieldByIndex(idx as Number, value as Float) as Void {
    if (idx == 0 && mWaterField != null) {
      mWaterField.setData(value);
    } else if (idx == 1 && mElectrolytesField != null) {
      mElectrolytesField.setData(value);
    } else if (idx == 2 && mFoodField != null) {
      mFoodField.setData(value);
    }
  }
}

function getApp() as NutritionLoggerApp {
  return Application.getApp() as NutritionLoggerApp;
}
