# Razorpay Proguard Rules
-keep class com.razorpay.** {*;}
-dontwarn com.razorpay.**
-keepclasseswithmembers class * {
    @com.razorpay.RzpAssistType *;
}

# Preserve GSON / Network annotations if needed
-keepattributes *Annotation*
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}