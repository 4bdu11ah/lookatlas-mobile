# --- flutter_local_notifications ---
# The plugin (de)serializes scheduled notifications with GSON. R8 strips the
# generic signatures GSON needs at runtime unless we keep them explicitly.
# https://pub.dev/packages/flutter_local_notifications#release-build-configuration
-keepattributes Signature
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken
-keep public class * implements java.lang.reflect.Type

# GSON generic type adapters used by the plugin's models.
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# --- purchases_flutter (RevenueCat) ---
# RevenueCat ships consumer proguard rules with its SDK, but keep its public
# surface defensively since billing failures are silent and hard to debug.
-keep class com.revenuecat.purchases.** { *; }
