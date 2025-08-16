import Toybox.Graphics;
import Toybox.WatchUi;
using Toybox.System as Sys;
using Toybox.Activity as Activity;
using Toybox.Timer as Timer;
using Toybox.Sensor as Sensor;

class NutritionLoggerView extends WatchUi.View {

    var mUpdateTimer as Timer.Timer?;
    var mHeartRate; // current heart rate (bpm)

    function initialize() {
        View.initialize();
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
        var isRec = (app.mSession != null && app.mSession.isRecording());
        if (isRec) {
            mUpdateTimer.start(method(:tick), 1000, true);
        }
        else {
            mUpdateTimer.stop();
        }
        Sys.println(isRec ? "Recording" : "Idle");
        var status = isRec ? Rez.Strings.status_recording : Rez.Strings.status_idle;
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth()/2, y, Graphics.FONT_XTINY, WatchUi.loadResource(status), Graphics.TEXT_JUSTIFY_CENTER);
        y += 30;

        var info = Activity.getActivityInfo();
        Sys.println("Serialized info: " + 
            "\n\tAltitude: " + info.altitude + 
            "\n\tElapsedDistance: " + info.elapsedDistance
        );
        Sys.println("Elapsed Time:" + info.elapsedTime);
        Sys.println("ElapsedDistance: " + info.elapsedDistance);
        var dist = (info.currentLocation != null && info.elapsedDistance != null) ? info.elapsedDistance : 0; // meters
        var tt = info.timerTime; // ms
        var et = info.elapsedTime; // ms
        var timeMs = (info.timerState == Activity.TIMER_STATE_STOPPED) ? et : tt;
        var secs = (timeMs == null) ? 0 : (timeMs / 1000).toNumber();
        var h = (secs / 3600).toNumber();
        var m = ((secs % 3600) / 60).toNumber();
        var s = (secs % 60).toNumber();
        var timeStr = Lang.format("$1$:$2$:$3$", [h, m, s]);
        dc.drawText(dc.getWidth()/2, y, Graphics.FONT_MEDIUM, timeStr, Graphics.TEXT_JUSTIFY_CENTER);
        y += 40;
        // Display distance
        var distStr = "0 m";
        if (dist != null) {
            if (dist > 1000) {
                distStr = Lang.format("$1$ km", [(dist/1000).format("%.2f")]);
            }
            else {
                distStr = Lang.format("$1$ m", [dist.format("%.2f")]);
            }
        }
        //Display Altitude
        var altStr = "0 m";
        if (info.altitude != null) {
            var altFormat = info.altitude.format("%.2f");
            altStr = Lang.format("$1$ m", [altFormat]);
        }
        dc.drawText(dc.getWidth()/2, y, Graphics.FONT_SMALL, distStr + " / " + altStr, Graphics.TEXT_JUSTIFY_CENTER);
        y += 30;
        // Display Heart Rate
        var hrStr = "-- bpm";
        if (mHeartRate != null) {
            var hrFormat = mHeartRate.format("%.0f");
            hrStr = Lang.format("$1$ bpm", [hrFormat]);
        }
        dc.drawText(dc.getWidth()/2, y, Graphics.FONT_SMALL, hrStr, Graphics.TEXT_JUSTIFY_CENTER);
        y += 30;
        // Hints
        // dc.drawText(dc.getWidth()/2, dc.getHeight()-40, Graphics.FONT_XTINY, WatchUi.loadResource(Rez.Strings.hint_controls), Graphics.TEXT_JUSTIFY_CENTER);
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
