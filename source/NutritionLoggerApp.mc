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
  var mRPE as Number = 0;
  var mCounters as Array<Number> = [0, 0, 0]; // [water, electrolytes, food]
  var mSelectedIndex as Number = -1; // -1..3

  var logger;

  function initialize() {
    AppBase.initialize();
  }

  // onStart() is called on application start up
  function onStart(state as Dictionary?) as Void {
    logger = new SensorLogging.SensorLogger({
      :accelerometer => { :enabled => true },
      :gyroscope => { :enabled => true },
    });

    Sensor.setEnabledSensors([
      Sensor.SENSOR_HEARTRATE,
      Sensor.SENSOR_PULSE_OXIMETRY,
      Sensor.SENSOR_TEMPERATURE,
    ]);
    Sensor.enableSensorEvents(method(:onSensor));

    // Sensor.registerSensorDataListener(method(""))

    Position.enableLocationEvents(
      Position.LOCATION_CONTINUOUS,
      method(:onPosition)
    );
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
    return [new NutritionLoggerView(), new NutritionLoggerDelegate()];
  }

  // Helpers
  function resetCounters() as Void {
    mRPE = 0;
    mCounters = [0, 0, 0];
    mSelectedIndex = -1; // No variable selected yet
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
      Sys.println("Failed to init Fit fields: " + e);
    }
  }

  function setFieldByIndex(idx as Number, value as Number) as Void {
    if (idx == 0 && mRPEField != null) {
      mRPEField.setData(value);
    } else if (idx == 1 && mWaterField != null) {
      mWaterField.setData(value);
    } else if (idx == 2 && mElectrolytesField != null) {
      mElectrolytesField.setData(value);
    } else if (idx == 3 && mFoodField != null) {
      mFoodField.setData(value);
    }
  }

  function onPosition(info as Position.Info) as Void {
    // System.println("Position: " + info.latitude + ", " + info.longitude);
  }

  function onSensor(sensorInfo as Sensor.Info) as Void {
    System.println("Heart Rate: " + sensorInfo.heartRate);
  }
}

function getApp() as NutritionLoggerApp {
  return Application.getApp() as NutritionLoggerApp;
}
