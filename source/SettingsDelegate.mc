import Toybox.Lang;
import Toybox.WatchUi;
using Toybox.Attention as Attention;
using Toybox.Timer;

class SettingsDelegate extends WatchUi.BehaviorDelegate {
    var mSelectedItem as Number = 0; // 0=Water, 1=Electrolytes, 2=Food
    var mBackHoldTimer as Timer.Timer?;
    var mBackHeld as Boolean = false;

    function initialize() {
        BehaviorDelegate.initialize();
        mSelectedItem = 0;
        mBackHeld = false;
    }

    function onKey(keyEvent as KeyEvent) as Boolean {
        var key = keyEvent.getKey();
        var app = getApp();

        if (key == WatchUi.KEY_UP) {
            // Move selection up
            mSelectedItem = (mSelectedItem - 1 + 3) % 3;
            playTone();
            WatchUi.requestUpdate();
            return true;
        } else if (key == WatchUi.KEY_DOWN) {
            // Move selection down
            mSelectedItem = (mSelectedItem + 1) % 3;
            playTone();
            WatchUi.requestUpdate();
            return true;
        } else if (key == WatchUi.KEY_ENTER) {
            // START = Increment value by step
            adjustValue(app, 10);
            return true;
        } else if (key == WatchUi.KEY_ESC) {
            // BACK = Decrement value by step
            adjustValue(app, -10);
            return true;
        } else if (key == WatchUi.KEY_MENU) {
            // MENU button = Save and exit
            saveAndExit(app);
            return true;
        }

        return false;
    }

    function adjustValue(app as NutritionLoggerApp, delta as Number) as Boolean {
        var newValue = 0;
        var minValue = 10; // Minimum unit value
        
        if (mSelectedItem == 0) {
            newValue = app.mWaterUnit + delta;
            if (newValue < minValue) {
                // At minimum, can't decrement further - just give feedback
                if (Attention has :vibrate) {
                    Attention.vibrate([
                        new Attention.VibeProfile(25, 50),
                        new Attention.VibeProfile(0, 50),
                        new Attention.VibeProfile(25, 50)
                    ]);
                }
                return false;
            }
            app.mWaterUnit = newValue;
        } else if (mSelectedItem == 1) {
            newValue = app.mElectrolytesUnit + delta;
            if (newValue < minValue) {
                if (Attention has :vibrate) {
                    Attention.vibrate([
                        new Attention.VibeProfile(25, 50),
                        new Attention.VibeProfile(0, 50),
                        new Attention.VibeProfile(25, 50)
                    ]);
                }
                return false;
            }
            app.mElectrolytesUnit = newValue;
        } else if (mSelectedItem == 2) {
            newValue = app.mFoodUnit + delta;
            if (newValue < minValue) {
                if (Attention has :vibrate) {
                    Attention.vibrate([
                        new Attention.VibeProfile(25, 50),
                        new Attention.VibeProfile(0, 50),
                        new Attention.VibeProfile(25, 50)
                    ]);
                }
                return false;
            }
            app.mFoodUnit = newValue;
        }

        // Haptic feedback
        if (Attention has :vibrate) {
            Attention.vibrate([new Attention.VibeProfile(25, 50)]);
        }
        
        WatchUi.requestUpdate();
        return true;
    }

    function saveAndExit(app as NutritionLoggerApp) as Void {
        // Save settings to storage
        app.saveSettings();
        
        // Haptic feedback for save
        if (Attention has :vibrate) {
            Attention.vibrate([new Attention.VibeProfile(50, 100)]);
        }
        if (Attention has :playTone) {
            Attention.playTone(Attention.TONE_KEY);
        }
        
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }

    function playTone() as Void {
        if (Attention has :playTone) {
            Attention.playTone(Attention.TONE_KEY);
        }
    }

    function getSelectedItem() as Number {
        return mSelectedItem;
    }
}
