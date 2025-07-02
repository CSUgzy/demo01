# Flutter相关规则
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-keep class io.flutter.plugin.editing.** { *; }

# LeanCloud相关规则
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.avos.** { *; }
-keep class cn.leancloud.** { *; }
-dontwarn cn.leancloud.**
-keep class com.alibaba.fastjson.** { *; }
-dontwarn com.alibaba.fastjson.**

# 图片选择库保留
-keep class androidx.core.app.CoreComponentFactory { *; }
-keep class io.flutter.plugins.imagepicker.** { *; }

# 保留Kotlin相关内容
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**
-keepclassmembers class **$WhenMappings {
    <fields>;
}

# 保留JavaScript接口
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# 保留所有本地方法
-keepclasseswithmembernames,includedescriptorclasses class * {
    native <methods>;
}

# 保留R类中的静态字段，包括通过libs中的*aar引入的资源id
-keepclassmembers class **.R$* {
    public static <fields>;
}

# Keep your model classes
-keep class com.liangshiyiyou.app.models.** { *; }

# Keep Kotlin Metadata
-keepattributes *Annotation*, InnerClasses
-dontnote kotlinx.serialization.SerializationKt
-keep,includedescriptorclasses class com.liangshiyiyou.app.**$$serializer { *; }
-keepclassmembers class com.liangshiyiyou.app.** {
    *** Companion;
}
-keepclasseswithmembers class com.liangshiyiyou.app.** {
    kotlinx.serialization.KSerializer serializer(...);
}

# For Android support libraries
-keep class androidx.** { *; }
-keep interface androidx.** { *; }
-keep class com.google.android.material.** { *; }

# For enumeration classes
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# For serializable classes
-keepnames class * implements java.io.Serializable
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    !static !transient <fields>;
    !private <fields>;
    !private <methods>;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
} 