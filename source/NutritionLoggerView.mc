import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;
using Toybox.System as Sys;
using Toybox.Activity as Activity;
using Toybox.Timer as Timer;
using Toybox.Sensor as Sensor;
using Toybox.Math;

class NutritionLoggerView extends WatchUi.View {
  var mUpdateTimer as Timer.Timer?;
  var mHeartRate; // current heart rate (bpm)
  var mTemperature; // temperature (Celsius)

  // Cached string resources (loaded once in onLayout)
  var mStrRecording as String?;
  var mStrIdle as String?;
  var mStrPause as String?;
  var mStrRPE as String?;
  var mStrWater as String?;
  var mStrElectrolytes as String?;
  var mStrFood as String?;
  
  // RPE difficulty labels
  var mStrRPEEasy as String?;
  var mStrRPEModerate as String?;
  var mStrRPEHard as String?;
  var mStrRPEVeryHard as String?;
  var mStrRPEMax as String?;

  // Cached layout values (computed once in onLayout)
  var mScreenRadius as Number?;
  var mArcRadius as Number?;
  var mSignRadius as Number?;
  var mSignUpperRightX as Float?;
  var mSignUpperRightY as Float?;
  var mSignLowerRightX as Float?;
  var mSignLowerRightY as Float?;

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
    mStrPause = WatchUi.loadResource(Rez.Strings.pause_action);
    mStrRPE = WatchUi.loadResource(Rez.Strings.rpe);
    mStrWater = WatchUi.loadResource(Rez.Strings.counter_water);
    mStrElectrolytes = WatchUi.loadResource(Rez.Strings.counter_electrolytes);
    mStrFood = WatchUi.loadResource(Rez.Strings.counter_food);
    
    // Cache RPE difficulty labels
    mStrRPEEasy = WatchUi.loadResource(Rez.Strings.rpe_easy);
    mStrRPEModerate = WatchUi.loadResource(Rez.Strings.rpe_moderate);
    mStrRPEHard = WatchUi.loadResource(Rez.Strings.rpe_hard);
    mStrRPEVeryHard = WatchUi.loadResource(Rez.Strings.rpe_very_hard);
    mStrRPEMax = WatchUi.loadResource(Rez.Strings.rpe_max);

    // Cache layout values (screen-dependent but static after layout)
    mScreenRadius = dc.getWidth() / 2;
    mArcRadius = mScreenRadius - 6;
    mSignRadius = mScreenRadius - 4;

    // Pre-compute hint text positions using trig values
    // COS(30°) ≈ 0.866, SIN(30°) = 0.5
    mSignUpperRightX = mSignRadius * (1.0 + 0.866025403784);
    mSignUpperRightY = mSignRadius * (1.0 - 0.5);
    mSignLowerRightX = mSignRadius * (1.0 + 0.866025403784);
    mSignLowerRightY = mSignRadius * (1.0 + 0.5) - 10;
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
      Sensor.SENSOR_TEMPERATURE
    ]);
    Sensor.enableSensorEvents(method(:onSensor));
  }

  // Update the view
  function onUpdate(dc as Dc) as Void {
    // Call the parent onUpdate function to redraw the layout
    View.onUpdate(dc);

    var app = getApp();
    var y = 8;
    var isRec = app.mSession != null && app.mSession.isRecording();
    debugLog(isRec ? "Recording" : "Idle");

    // HINTS RENDER
    if (isRec) {
      if (app.mSelectedIndex == app.RPE_FIELD) {
        dc.setColor(getRPEColor(app.mRPE), Graphics.COLOR_TRANSPARENT);
      } else {
        dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
      }
      mUpdateTimer.start(method(:tick), 1000, true);
    } else {
      dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
      mUpdateTimer.stop();
    }

    // Start button hint (always visible)
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

    // When idle (not recording)
    // show play icon hint near START button for starting a new session
    // show gear icon hint near UP button for settings
    if (!isRec) {
      // Draw Play icon near START button (upper right) indicating "Start Session"
      dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
      var playX = mSignUpperRightX - 8;
      var playY = mSignUpperRightY + 4;
      // Draw filled triangle pointing right
      dc.fillPolygon([
        [playX, playY],
        [playX, playY + 12],
        [playX + 10, playY + 6]
      ]);

      dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
      dc.setPenWidth(2);
      
      // Draw arc near UP button (left side, same position as during recording)
      dc.drawArc(
        mScreenRadius,
        mScreenRadius,
        mArcRadius,
        Graphics.ARC_COUNTER_CLOCKWISE,
        172,
        188
      );
      
      // Draw gear icon next to UP button arc
      // Position gear icon at the center of the arc (180 degrees = left side)
      var gearX = 20;
      var gearY = mScreenRadius;
      var gearRadius = 5;
      
      // Draw gear wheel (circle with notches)
      dc.drawCircle(gearX, gearY, gearRadius);
      dc.fillCircle(gearX, gearY, 2); // center dot
      
      // Draw gear teeth (8 lines extending outward)
      // Cardinal directions
      dc.drawLine(gearX, gearY - gearRadius, gearX, gearY - gearRadius - 3);
      dc.drawLine(gearX, gearY + gearRadius, gearX, gearY + gearRadius + 3);
      dc.drawLine(gearX - gearRadius, gearY, gearX - gearRadius - 3, gearY);
      dc.drawLine(gearX + gearRadius, gearY, gearX + gearRadius + 3, gearY);
      
      // Diagonals (approx at 45 degrees)
      // Radius 5 -> ~3.5 offset (use 4)
      // Outer 8 -> ~5.6 offset (use 6)
      dc.drawLine(gearX - 4, gearY - 4, gearX - 6, gearY - 6);
      dc.drawLine(gearX + 4, gearY - 4, gearX + 6, gearY - 6);
      dc.drawLine(gearX - 4, gearY + 4, gearX - 6, gearY + 6);
      dc.drawLine(gearX + 4, gearY + 4, gearX + 6, gearY + 6);
    }
    
    // Show button hint text near START and Back buttons (Increment/Decrement or Menu)
    if (isRec) {
      var isMenuSelected = app.mSelectedIndex == app.MENU_FIELD;
      
      // Back button hint (only show when not on MENU)
      if (!isMenuSelected) {
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

      dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
      
      if (isMenuSelected) {
        dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
        // Draw hamburger menu icon for START button when MENU is selected
        dc.setPenWidth(2);
        var menuIconWidth = 12;
        var menuIconX = mSignUpperRightX - menuIconWidth;
        var menuIconY = mSignUpperRightY + 10;
        
        // Three horizontal lines
        dc.drawLine(menuIconX, menuIconY - 3, menuIconX + menuIconWidth, menuIconY - 3);
        dc.drawLine(menuIconX, menuIconY, menuIconX + menuIconWidth, menuIconY);
        dc.drawLine(menuIconX, menuIconY + 3, menuIconX + menuIconWidth, menuIconY + 3);
      } else {
        // Draw plus sign for increment (data fields)
        dc.drawText(
          mSignUpperRightX,
          mSignUpperRightY,
          Graphics.FONT_XTINY,
          "+",
          Graphics.TEXT_JUSTIFY_RIGHT
        );
        
        // Draw minus sign for decrement
        dc.drawText(
          mSignLowerRightX,
          mSignLowerRightY,
          Graphics.FONT_XTINY,
          "-",
          Graphics.TEXT_JUSTIFY_RIGHT
        );
      }

      dc.drawArc(
        mScreenRadius,
        mScreenRadius,
        mArcRadius,
        Graphics.ARC_COUNTER_CLOCKWISE,
        172,
        188
      );

      dc.drawArc(
        mScreenRadius,
        mScreenRadius,
        mArcRadius,
        Graphics.ARC_COUNTER_CLOCKWISE,
        202,
        218
      );

      var arrowUp = [
        [10, mScreenRadius + 6],
        [16, mScreenRadius - 6],
        [22, mScreenRadius + 6],
      ];
      dc.fillPolygon(arrowUp);

      var arrowDown = [
        [24, mScreenRadius + 52],
        [30, mScreenRadius + 64],
        [36, mScreenRadius + 52],
      ];
      dc.fillPolygon(arrowDown);
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
    y += 18;

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
    var distStr = "0m";
    if (dist != null) {
      if (dist > 1000) {
        distStr = Lang.format("$1$km", [(dist / 1000).format("%.2f")]);
      } else {
        distStr = Lang.format("$1$m", [dist.format("%.2f")]);
      }
    }
    //Display Altitude
    var altStr = "0m";
    if (info.altitude != null) {
      var altFormat = info.altitude.format("%.2f");
      altStr = Lang.format("$1$m", [altFormat]);
    }
    dc.drawText(
      dc.getWidth() / 2,
      y,
      Graphics.FONT_SMALL,
      distStr + " / " + altStr,
      Graphics.TEXT_JUSTIFY_CENTER
    );
    y += 28;
    // Display Heart Rate and Temperature on one line
    var hrStr = mHeartRate != null ? mHeartRate.format("%.0f") : "--";
    var tempStr = mTemperature != null ? mTemperature.format("%.1f") + "°" : "--°";
    var vitalsStr = hrStr + " bpm | " + tempStr;
    dc.drawText(
      dc.getWidth() / 2,
      y,
      Graphics.FONT_SMALL,
      vitalsStr,
      Graphics.TEXT_JUSTIFY_CENTER
    );
    y += 34;

    // Custom variables section (using cached labels)
    // 5 items: RPE, Water, Electrolytes, Food, Menu
    var labels = [mStrRPE, mStrWater, mStrElectrolytes, mStrFood, "MENU"];
    var i = 0;
    var x_center = dc.getWidth() / 2;
    while (i < 5) {
      var name = labels[i];
      var line = "";
      var color = Graphics.COLOR_LT_GRAY;
      var font = Graphics.FONT_TINY;
      var y_gap = i * 24;
      
      // Build display string based on item type
      if (i == app.MENU_FIELD) {
        // Menu state - show menu indicator
        line = ">>> " + name + " <<<";
      } else if (i == app.RPE_FIELD) {
        // RPE with range and difficulty label
        var rpeRange = (app.mRPE * 2 + 1).toString() + "-" + (app.mRPE * 2 + 2).toString();
        var rpeDifficulty = "";
        if (app.mRPE == 0) {
          rpeDifficulty = mStrRPEEasy;
        } else if (app.mRPE == 1) {
          rpeDifficulty = mStrRPEModerate;
        } else if (app.mRPE == 2) {
          rpeDifficulty = mStrRPEHard;
        } else if (app.mRPE == 3) {
          rpeDifficulty = mStrRPEVeryHard;
        } else {
          rpeDifficulty = mStrRPEMax;
        }
        line = name + ": " + rpeRange + " (" + rpeDifficulty + ")";
      } else {
        // Water, Electrolytes, Food - display stored intake values directly
        var intakeIdx = i - 1; // Water=1->0, Electrolytes=2->1, Food=3->2
        var intakeValue = app.mIntake[intakeIdx];
        var unit = "";
        
        if (intakeIdx == 0) {
          unit = "ml";
        } else if (intakeIdx == 1) {
          unit = "mg";
        } else {
          unit = "kcal";
        }
        
        line = name + ": " + intakeValue.format("%.0f") + unit;
      }
      
      // Highlight selected item
      if (i == app.mSelectedIndex) {
        y_gap = i * 24 - 3;
        font = Graphics.FONT_SMALL;
        if (isRec) {
          if (i == app.RPE_FIELD) {
            color = getRPEColor(app.mRPE);
          } else {
            color = Graphics.COLOR_YELLOW;
          }
        } else {
          color = Graphics.COLOR_WHITE;
        }
      }
      
      // Draw the line
      dc.setColor(color, Graphics.COLOR_TRANSPARENT);
      dc.drawText(
        x_center,
        y + y_gap,
        font,
        line,
        Graphics.TEXT_JUSTIFY_CENTER
      );
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
