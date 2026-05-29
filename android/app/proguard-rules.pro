# =============================================================================
# Flutter
# =============================================================================
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }

# =============================================================================
# Kotlin metadata — required for reflective lookups by some plugins
# =============================================================================
-keep class kotlin.Metadata { *; }
-keepattributes *Annotation*, InnerClasses, Signature, Exceptions, EnclosingMethod

# =============================================================================
# Android framework reflection (Parcelable / Serializable / enums)
# =============================================================================
-keepclassmembers class * implements android.os.Parcelable {
    public static final ** CREATOR;
}
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# =============================================================================
# ML Kit (text recognition for card / IBAN scanning)
# =============================================================================
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.** { *; }
-keep class com.google.mlkit.vision.text.chinese.** { *; }
-keep class com.google.mlkit.vision.text.japanese.** { *; }
-keep class com.google.mlkit.vision.text.korean.** { *; }
-keep class com.google.mlkit.vision.text.devanagari.** { *; }
-dontwarn com.google.mlkit.**

# =============================================================================
# flutter_secure_storage
# =============================================================================
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# =============================================================================
# in_app_purchase (Google Play Billing) — MethodChannel target classes & the
# Billing client itself reflect on these names.
# =============================================================================
-keep class io.flutter.plugins.inapppurchase.** { *; }
-keep class com.android.billingclient.api.** { *; }
-keep class com.android.vending.billing.** { *; }
-keep interface com.android.billingclient.api.** { *; }
-dontwarn com.android.billingclient.**

# =============================================================================
# Google Pay / Wallet (used by MainActivity savePasses)
# =============================================================================
-keep class com.google.android.gms.pay.** { *; }
-keep class com.google.android.gms.wallet.** { *; }

# =============================================================================
# Firebase + Crashlytics
# =============================================================================
-keep class com.google.firebase.** { *; }
-keep class com.google.firebase.crashlytics.** { *; }
-keepattributes SourceFile,LineNumberTable
-keep class * extends java.lang.Exception
-dontwarn com.google.firebase.**

# =============================================================================
# flutter_local_notifications (boot receivers + scheduled notifications)
# =============================================================================
-keep class com.dexterous.** { *; }
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-dontwarn com.dexterous.**

# Gson (used by flutter_local_notifications for payload serialization)
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer
-keepclassmembers,allowobfuscation class * {
    @com.google.gson.annotations.SerializedName <fields>;
}
-keepattributes Signature

# =============================================================================
# Hive — type adapters are registered by name; R8 may strip them otherwise
# =============================================================================
-keep class hive.** { *; }
-keep class * extends hive.TypeAdapter { *; }

# =============================================================================
# OkHttp / Conscrypt (transitive deps from Firebase / Play Services)
# =============================================================================
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn org.conscrypt.**
-dontwarn org.bouncycastle.**
-dontwarn org.openjsse.**

# =============================================================================
# Flutter embedding optional dependencies — referenced by FlutterPlayStoreSplit*
# and PlayStoreDeferredComponentManager but unused because this app does not
# ship deferred Play feature modules. Safe to strip; warnings only.
# =============================================================================
-dontwarn com.google.android.play.core.**
-dontwarn javax.xml.stream.**
