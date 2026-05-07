-dontwarn com.sun.jna.**
-keep class com.sun.jna.** { *; }
-keep interface com.sun.jna.** { *; }
-keepclassmembers class * extends com.sun.jna.** {
    <init>(...);
    public static <fields>;
    public <fields>;
    public <methods>;
}

# Evitar que tu librería de impresión se rompa
-keep class com.caysn.autoreplyprint.** { *; }