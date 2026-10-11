package com.izisoluciones.kiosco.izi_kiosco;

import androidx.test.rule.ActivityTestRule;
import dev.flutter.plugins.integration_test.FlutterTestRunner;
import org.junit.Rule;
import org.junit.runner.RunWith;

/**
 * Instrumentation wrapper so the Dart tests under integration_test/ can run on
 * Firebase Test Lab (gcloud firebase test android run --type instrumentation).
 * Not used by local `flutter test integration_test` runs.
 */
@RunWith(FlutterTestRunner.class)
public class MainActivityTest {
  @Rule
  public ActivityTestRule<MainActivity> rule =
      new ActivityTestRule<>(MainActivity.class, true, false);
}
