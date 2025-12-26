import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Position;
import Toybox.Sensor;
using Toybox.SensorLogging;
using Toybox.System as Sys;
using Toybox.Activity as Activity;
using Toybox.ActivityRecording as AR;
using Toybox.FitContributor as Fit;

class NutritionLoggerApp extends Application.AppBase {
  // Developer Fields Constants  
  // Selection indices: 0=RPE, 1=Water, 2=Electrolytes, 3=Food
  const RPE_FIELD = 0;
  const WATER_FIELD = 1;
  const ELECTROLYTES_FIELD = 2;
  const FOOD_FIELD = 3;

  // Global session reference
  var mSession as AR.Session?;
  // Developer data fields
  var mRPEField as Fit.Field?;
  var mWaterField as Fit.Field?;
  var mElectrolytesField as Fit.Field?;
  var mFoodField as Fit.Field?;

  // Counters and selection
  var mRPE as Number = 1; // Should start at 1 (RPE 3-4)
  var mCounters as Array<Number> = [0, 0, 0]; // [water, electrolytes, food]
  var mSelectedIndex as Number = 0; // 0=RPE, 1=Water, 2=Electrolytes, 3=Food (default to RPE)

  var logger as SensorLogging.SensorLogger?;
  var mDelegate as NutritionLoggerDelegate?;

  function initialize() {
    AppBase.initialize();
  }

  // onStart() is called on application start up
  function onStart(state as Dictionary?) as Void {
    // SensorLogger initialized in initSensorLogger() when recording starts
    // Sensor initialization consolidated in NutritionLoggerView.onShow()

    Position.enableLocationEvents(
      Position.LOCATION_CONTINUOUS,
      method(:onPosition)
    );
  }

  // Initialize accelerometer/gyroscope logging when recording starts
  function initSensorLogger() as Void {
    logger = new SensorLogging.SensorLogger({
      :accelerometer => { :enabled => true },
      :gyroscope => { :enabled => true },
    });
  }

  // onStop() is called when your application is exiting
  function onStop(state as Dictionary?) as Void {
    // Ensure recording is properly stopped if app exits unexpectedly
    if (mSession != null && mSession.isRecording()) {
      mSession.stop();
      // Don't auto-save; let user decide next launch
      Position.enableLocationEvents(Position.LOCATION_DISABLE, null);
    }
  }

  // Return the initial view of your application here
  function getInitialView() as [Views] or [Views, InputDelegates] {
    mDelegate = new NutritionLoggerDelegate();
    return [new NutritionLoggerView(), mDelegate];
  }

  // Helpers
  function resetCounters() as Void {
    mRPE = 1; // Should start at 1 (RPE 3-4)
    mCounters = [0, 0, 0];
    mSelectedIndex = RPE_FIELD; // Start with RPE selected (index 0)
  }

  function initFitFields() as Void {
    if (mSession == null) {
      return;
    }
    try {
      // Create developer fields written on record messages
      mRPEField = mSession.createField(
        "rate_of_perceived_exertion",
        0,
        Fit.DATA_TYPE_UINT8,
        { :mesgType => Fit.MESG_TYPE_RECORD, :units => "level" }
      );
      mWaterField = mSession.createField(
        "water_intake_count",
        1,
        Fit.DATA_TYPE_UINT8,
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
      mWaterField.setData(0);
      mElectrolytesField.setData(0);
      mFoodField.setData(0);
    } catch (e) {
      debugLog("Failed to init Fit fields: " + e);
    }
  }

  function setFieldByIndex(idx as Number, value as Number) as Void {
    if (idx == RPE_FIELD && mRPEField != null) {
      mRPEField.setData(value);
    } else if (idx == WATER_FIELD && mWaterField != null) {
      mWaterField.setData(value);
    } else if (idx == ELECTROLYTES_FIELD && mElectrolytesField != null) {
      mElectrolytesField.setData(value);
    } else if (idx == FOOD_FIELD && mFoodField != null) {
      mFoodField.setData(value);
    }
  }

  function onPosition(info as Position.Info) as Void {
    // debugLog("Position: " + info.latitude + ", " + info.longitude);
  }
}

function getApp() as NutritionLoggerApp {
  return Application.getApp() as NutritionLoggerApp;
}
