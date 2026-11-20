import 'package:flutter/foundation.dart';

const bmFlavor = 'bk';
const bmVersion = String.fromEnvironment('BM_BUILD', defaultValue: '1.0.19+6');
const bmPlatform = kIsWeb ? 'web' : 'android';
