# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Play Core (classi referenziate da Flutter ma non incluse nel build — R8 fix)
-dontwarn com.google.android.play.core.**

# Supabase / OkHttp / Retrofit
-keep class io.github.jan.supabase.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**

# Hive
-keep class com.hivedb.** { *; }
-keepclassmembers class * extends com.hivedb.hive.HiveObject { *; }

# Google Mobile Ads
-keep class com.google.android.gms.ads.** { *; }

# Geolocator
-keep class com.baseflow.geolocator.** { *; }
