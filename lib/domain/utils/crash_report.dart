import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

class CrashReport{
  static report(String error,String stack)async {
    try{
      if(kIsWeb){
        await FirebaseAnalytics.instance.logEvent(name: "Error",parameters: {
          "name": error,
          "stack": stack
        });
      }
      else {
        await FirebaseCrashlytics.instance.recordError(
            "$error-$stack", StackTrace.fromString(stack));
      }
    }
    catch(_){}
  }
}