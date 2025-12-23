import Toybox.Lang;
using Toybox.System as Sys;

// Set to false for production builds to disable all debug logging
const DEBUG = true;

// Debug logging utility - only prints when DEBUG is true
function debugLog(message as String) as Void {
    if (DEBUG) {
        Sys.println(message);
    }
}
