import Toybox.Graphics;
import Toybox.WatchUi;
using Toybox.System as Sys;
using Toybox.Activity as Activity;
using Toybox.Timer as Timer;
using Toybox.Sensor as Sensor;
using Toybox.Math;

class NutritionLoggerView extends WatchUi.View {
  var mUpdateTimer as Timer.Timer?;
  var mHeartRate; // current heart rate (bpm)

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

    // Enable heart rate sensor and start receiving events at 1 Hz
    // Requires Sensor permission (declared in manifest)
    Sensor.setEnabledSensors([Sensor.SENSOR_HEARTRATE]);
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
    Sys.println(isRec ? "Recording" : "Idle");

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

    // Start button hint
    var screenRadius = dc.getWidth() / 2;
    var arcRadius = screenRadius - 6;
    var arcStart = 22; // degrees
    var arcEnd = 38; // degrees
    dc.setPenWidth(2);
    dc.drawArc(
      screenRadius,
      screenRadius,
      arcRadius,
      Graphics.ARC_COUNTER_CLOCKWISE,
      arcStart,
      arcEnd
    );

    // Back button hint
    if (isRec) {
      arcStart = 322; // degrees
      arcEnd = 338; // degrees
      dc.drawArc(
        screenRadius,
        screenRadius,
        arcRadius,
        Graphics.ARC_COUNTER_CLOCKWISE,
        arcStart,
        arcEnd
      );
    }

    if (drawSign) {
      var signRadius = screenRadius - 4;
      dc.drawText(
        signRadius * (1.0 + Math.cos(Math.toRadians(30))),
        signRadius * (1.0 - Math.sin(Math.toRadians(30))) + 10,
        Graphics.FONT_TINY,
        "+",
        Graphics.TEXT_JUSTIFY_RIGHT|Graphics.TEXT_JUSTIFY_VCENTER
      );

      dc.drawText(
        signRadius * (1.0 + Math.cos(Math.toRadians(30))),
        signRadius * (1.0 + Math.sin(Math.toRadians(30))) - 2,
        Graphics.FONT_TINY,
        "-",
        Graphics.TEXT_JUSTIFY_RIGHT|Graphics.TEXT_JUSTIFY_VCENTER
      );
    }

    var status = isRec ? Rez.Strings.status_recording : Rez.Strings.status_idle;
    if (isRec) {
      dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
    }
    dc.drawText(
      dc.getWidth() / 2,
      y,
      Graphics.FONT_XTINY,
      WatchUi.loadResource(status),
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
    // Display Heart Rate
    var hrStr = "-- bpm";
    if (mHeartRate != null) {
      var hrFormat = mHeartRate.format("%.0f");
      hrStr = Lang.format("$1$ bpm", [hrFormat]);
    }
    dc.drawText(
      dc.getWidth() / 2,
      y,
      Graphics.FONT_SMALL,
      hrStr,
      Graphics.TEXT_JUSTIFY_CENTER
    );
    y += 40;

    // Custom variables section
    var labels = [
      WatchUi.loadResource(Rez.Strings.rpe),
      WatchUi.loadResource(Rez.Strings.counter_water),
      WatchUi.loadResource(Rez.Strings.counter_electrolytes),
      WatchUi.loadResource(Rez.Strings.counter_food),
    ];
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
    // Stop receiving sensor events and disable heart rate sensor
    Sensor.enableSensorEvents(null);
    // Prefer disabling only HR to avoid affecting other sensors
    Sensor.disableSensorType(Sensor.SENSOR_HEARTRATE);
    mHeartRate = null;
  }

  function tick() as Void {
    WatchUi.requestUpdate();
  }

  // Sensor callback (invoked ~1 Hz when enabled)
  function onSensor(info as Sensor.Info) as Void {
    // Some devices may omit fields; guard with 'has'
    if (info has :heartRate && info.heartRate != null) {
      mHeartRate = info.heartRate;
      WatchUi.requestUpdate();
    }
  }
}
