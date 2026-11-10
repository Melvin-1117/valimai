# Proguard rules for Valimai Flutter Android Application

# Flutter Engine & Embedding
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.**  { *; }
-dontwarn io.flutter.embedding.**

# Keep standard models and JNI entry points
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-ignorewarnings

