import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Attention;

class ConfirmationDelegate extends WatchUi.BehaviorDelegate {
    private var mAction as Symbol;

    function initialize(action as Symbol) {
        BehaviorDelegate.initialize();
        mAction = action;
    }

    function onKey(keyEvent as KeyEvent) as Boolean {
        var key = keyEvent.getKey();

        if (key == WatchUi.KEY_ENTER) {
            // Confirm the action
            executeAction();
            return true;
        } else if (key == WatchUi.KEY_ESC) {
            // Cancel - just pop back to menu
            WatchUi.popView(WatchUi.SLIDE_DOWN);
            return true;
        }

        return false;
    }

    private function executeAction() as Void {
        var app = getApp();
        
        if (mAction == :save) {
            // Show "Session Saved" message
            showStatusMessage("Session Saved");
            
            // Save the session
            if (app.mSession != null) {
                if (app.mSession.isRecording()) {
                    app.mSession.stop();
                }
                var ok = app.mSession.save();
                debugLog("Save: " + ok);
                app.mSession = null;
            }
            
            // Exit after a short delay
            System.exit();
        } else if (mAction == :discard) {
            // Show "Session Discarded" message
            showStatusMessage("Session Discarded");
            
            // Discard the session
            if (app.mSession != null) {
                if (app.mSession.isRecording()) {
                    app.mSession.stop();
                }
                var ok = app.mSession.discard();
                debugLog("Discard: " + ok);
                app.mSession = null;
            }
            
            // Exit after a short delay
            System.exit();
        }
    }

    private function showStatusMessage(message as String) as Void {
        // Create a simple view to show the status message
        var statusView = new StatusMessageView(message);
        
        // Pop the confirmation view and push status message
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        WatchUi.pushView(statusView, null, WatchUi.SLIDE_IMMEDIATE);
        
        // Play feedback
        if (Attention has :playTone) {
            Attention.playTone(Attention.TONE_SUCCESS);
        }
        if (Attention has :vibrate) {
            Attention.vibrate([new Attention.VibeProfile(100, 200)]);
        }
    }
}
