import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;
using Toybox.System as Sys;
using Toybox.Activity as Activity;
using Toybox.Timer as Timer;
using Toybox.Sensor as Sensor;
using Toybox.Math;

class NutritionLoggerView extends WatchUi.View {
  // Pre-computed trig values for 30 degrees (static, never changes)
  const COS_30 = 0.866025403784; // Math.cos(Math.toRadians(30))
  const SIN_30 = 0.5;            // Math.sin(Math.toRadians(30))

  var mUpdateTimer as Timer.Timer?;
  var mHeartRate; // current heart rate (bpm)
  var mPulseOx; // blood oxygen saturation (%)
  var mTemperature; // temperature (Celsius)

  // Cached string resources (loaded once in onLayout)
  var mStrRecording as String?;
  var mStrIdle as String?;
  var mStrRPE as String?;
  var mStrWater as String?;
  var mStrElectrolytes as String?;
  var mStrFood as String?;

  // Cached layout values (computed once in onLayout)
  var mScreenRadius as Number?;
  var mArcRadius as Number?;
  var mSignRadius as Number?;
  var mSignPlusX as Float?;
  var mSignPlusY as Float?;
  var mSignMinusX as Float?;
  var mSignMinusY as Float?;

  function initialize() {
    View.initialize();
  }

  // Helper function to get color based on RPE value (0=cyan, 2=green, 4=red)
  function getRPEColor(rpeValue) {
    if (rpeValue <= 0) {
      return 0x00FFFF; // Cyan
    } else if (rpeValue == 1) {
      return 0x00FF00; // Green
    } else if (rpeValue == 2) {
      return 0xFFFF00; // Yellow
    } else if (rpeValue == 3) {
      return 0xFFA500; // Orange
    } else if (rpeValue >= 4) {
      return 0xFF0000; // Red
    }
    return 0xFFFF00; // Return yellow by default
  }

  // Load your resources here
  function onLayout(dc as Dc) as Void {
    setLayout(Rez.Layouts.MainLayout(dc));

    // Cache string resources to avoid loading on every screen refresh
    mStrRecording = WatchUi.loadResource(Rez.Strings.status_recording);
    mStrIdle = WatchUi.loadResource(Rez.Strings.status_idle);
    mStrRPE = WatchUi.loadResource(Rez.Strings.rpe);
    mStrWater = WatchUi.loadResource(Rez.Strings.counter_water);
    mStrElectrolytes = WatchUi.loadResource(Rez.Strings.counter_electrolytes);
    mStrFood = WatchUi.loadResource(Rez.Strings.counter_food);

    // Cache layout values (screen-dependent but static after layout)
    mScreenRadius = dc.getWidth() / 2;
    mArcRadius = mScreenRadius - 6;
    mSignRadius = mScreenRadius - 4;

    // Pre-compute +/- sign positions using cached trig values
    mSignPlusX = mSignRadius * (1.0 + COS_30);
    mSignPlusY = mSignRadius * (1.0 - SIN_30) + 10;
    mSignMinusX = mSignRadius * (1.0 + COS_30);
    mSignMinusY = mSignRadius * (1.0 + SIN_30) - 2;
  }

  // Called when this View is brought to the foreground. Restore
  // the state of this View and prepare it to be shown. This includes
  // loading resources into memory.
  function onShow() as Void {
    if (mUpdateTimer == null) {
      mUpdateTimer = new Timer.Timer();
    }
    // Request an update every second
    // mUpdateTimer.start(method(:tick), 1000, true);

    // Enable all sensors and start receiving events at 1 Hz
    // Requires Sensor permission (declared in manifest)
    Sensor.setEnabledSensors([
      Sensor.SENSOR_HEARTRATE,
      Sensor.SENSOR_PULSE_OXIMETRY,
      Sensor.SENSOR_TEMPERATURE
    ]);
    Sensor.enableSensorEvents(method(:onSensor));
  }

  // Update the view
  function onUpdate(dc as Dc) as Void {
    // Call the parent onUpdate function to redraw the layout
    View.onUpdate(dc);

    var app = getApp();
    var y = 10;
    var isRec = app.mSession != null && app.mSession.isRecording();
    var drawSign = false;
    debugLog(isRec ? "Recording" : "Idle");

    // HINTS RENDER
    if (isRec) {
      if (app.mSelectedIndex == -1) {
        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
      } else {
        drawSign = true;
        if (app.mSelectedIndex == app.RPE_FIELD) {
          dc.setColor(getRPEColor(app.mRPE), Graphics.COLOR_TRANSPARENT);
        }
        else {
          dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
        }
      }
      mUpdateTimer.start(method(:tick), 1000, true);
    } else {
      dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
      mUpdateTimer.stop();
    }

    // Start button hint (using cached values)
    var arcStart = 22; // degrees
    var arcEnd = 38; // degrees
    dc.setPenWidth(2);
    dc.drawArc(
      mScreenRadius,
      mScreenRadius,
      mArcRadius,
      Graphics.ARC_COUNTER_CLOCKWISE,
      arcStart,
      arcEnd
    );

    // Back button hint
    if (isRec) {
      arcStart = 322; // degrees
      arcEnd = 338; // degrees
      dc.drawArc(
        mScreenRadius,
        mScreenRadius,
        mArcRadius,
        Graphics.ARC_COUNTER_CLOCKWISE,
        arcStart,
        arcEnd
      );
    }

    if (drawSign) {
      // Use pre-computed positions for +/- signs
      dc.drawText(
        mSignPlusX,
        mSignPlusY,
        Graphics.FONT_TINY,
        "+",
        Graphics.TEXT_JUSTIFY_RIGHT|Graphics.TEXT_JUSTIFY_VCENTER
      );

      dc.drawText(
        mSignMinusX,
        mSignMinusY,
        Graphics.FONT_TINY,
        "-",
        Graphics.TEXT_JUSTIFY_RIGHT|Graphics.TEXT_JUSTIFY_VCENTER
      );
    }

    var status = isRec ? mStrRecording : mStrIdle;
    if (isRec) {
      dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
    }
    dc.drawText(
      dc.getWidth() / 2,
      y,
      Graphics.FONT_XTINY,
      status,
      Graphics.TEXT_JUSTIFY_CENTER
    );
    y += 25;

    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
    var info = Activity.getActivityInfo();
    var dist = info.elapsedDistance != null ? info.elapsedDistance : 0; // meters
    var tt = info.timerTime; // ms
    var et = info.elapsedTime; // ms
    var timeMs = info.timerState == Activity.TIMER_STATE_STOPPED ? et : tt;
    var secs = timeMs == null ? 0 : (timeMs / 1000).toNumber();
    var h = (secs / 3600).format("%02d");
    var m = ((secs % 3600) / 60).format("%02d");
    var s = (secs % 60).format("%02d");
    var timeStr = Lang.format("$1$:$2$:$3$", [h, m, s]);
    dc.drawText(
      dc.getWidth() / 2,
      y,
      Graphics.FONT_MEDIUM,
      timeStr,
      Graphics.TEXT_JUSTIFY_CENTER
    );
    y += 35;
    // Display distance
    var distStr = "0 m";
    if (dist != null) {
      if (dist > 1000) {
        distStr = Lang.format("$1$ km", [(dist / 1000).format("%.2f")]);
      } else {
        distStr = Lang.format("$1$ m", [dist.format("%.2f")]);
      }
    }
    //Display Altitude
    var altStr = "0 m";
    if (info.altitude != null) {
      var altFormat = info.altitude.format("%.2f");
      altStr = Lang.format("$1$ m", [altFormat]);
    }
    dc.drawText(
      dc.getWidth() / 2,
      y,
      Graphics.FONT_SMALL,
      distStr + " / " + altStr,
      Graphics.TEXT_JUSTIFY_CENTER
    );
    y += 30;
    // Display Heart Rate, SpO2, and Temperature on one line
    var hrStr = mHeartRate != null ? mHeartRate.format("%.0f") : "--";
    var spo2Str = mPulseOx != null ? mPulseOx.format("%.0f") + "%" : "--%";
    var tempStr = mTemperature != null ? mTemperature.format("%.1f") + "°" : "--°";
    var vitalsStr = hrStr + " bpm | " + spo2Str + " | " + tempStr;
    dc.drawText(
      dc.getWidth() / 2,
      y,
      Graphics.FONT_SMALL,
      vitalsStr,
      Graphics.TEXT_JUSTIFY_CENTER
    );
    y += 40;

    // Custom variables section (using cached labels)
    var labels = [mStrRPE, mStrWater, mStrElectrolytes, mStrFood];
    var i = 0;
    while (i < 4) {
      var name = labels[i];
      var val = i == app.RPE_FIELD ? app.mRPE : app.mCounters[i - 1]; // Counters index start at 0
      var line = "";
      var color = Graphics.COLOR_LT_GRAY;
      if (i == app.RPE_FIELD) {
        line =
          name +
          ": " +
          (app.mRPE * 2 + 1).toString() +
          "-" +
          (app.mRPE * 2 + 2).toString();
        if (i == app.mSelectedIndex && isRec) {
          color = getRPEColor(app.mRPE);
        }
      } else {
        line = name + ": " + val.format("%.0f");
        if (i == app.mSelectedIndex) {
          if (isRec) {
            color = Graphics.COLOR_YELLOW;
          }
          else {
            color = Graphics.COLOR_WHITE;
          }
        }
      }
      // If not recording, display as disabled
      dc.setColor(color, Graphics.COLOR_TRANSPARENT);
      dc.drawText(
        dc.getWidth() / 2,
        y,
        Graphics.FONT_SMALL,
        line,
        Graphics.TEXT_JUSTIFY_CENTER
      );
      y += 25;
      i += 1;
    }
  }

  // Called when this View is removed from the screen. Save the
  // state of this View here. This includes freeing resources from
  // memory.
  function onHide() as Void {
    if (mUpdateTimer != null) {
      mUpdateTimer.stop();
      mUpdateTimer = null;
    }
    // Stop receiving sensor events and disable all sensors
    Sensor.enableSensorEvents(null);
    Sensor.setEnabledSensors([]);
    mHeartRate = null;
    mPulseOx = null;
    mTemperature = null;
  }

  function tick() as Void {
    WatchUi.requestUpdate();
  }

  // Sensor callback (invoked ~1 Hz when enabled)
  function onSensor(info as Sensor.Info) as Void {
    var needsUpdate = false;

    // Heart rate
    if (info has :heartRate && info.heartRate != null) {
      mHeartRate = info.heartRate;
      needsUpdate = true;
    }

    // Pulse oximetry (SpO2)
    if (info has :oxygenSaturation && info.oxygenSaturation != null) {
      mPulseOx = info.oxygenSaturation;
      needsUpdate = true;
    }

    // Temperature
    if (info has :temperature && info.temperature != null) {
      mTemperature = info.temperature;
      needsUpdate = true;
    }

    if (needsUpdate) {
      WatchUi.requestUpdate();
    }
  }
}
