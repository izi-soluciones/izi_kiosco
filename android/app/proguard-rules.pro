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

# SDK de impresora Masung/SAT (IP1000)
# Solo se conservan los paquetes usados; el jar contiene clases de escritorio
# (java.awt) que no existen en Android y nunca se ejecutan.
-keep class com.printsdk.cmd.** { *; }
-keep class com.printsdk.usbsdk.** { *; }
-dontwarn java.awt.**
-dontwarn javax.imageio.**
-dontwarn javax.swing.**