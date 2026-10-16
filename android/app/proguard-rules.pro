# Keep WorkManager / Room reflective pieces used by Google Mobile Ads (release R8).
-keep class androidx.work.impl.WorkDatabase { *; }
-keep class androidx.work.impl.WorkDatabase_Impl { *; }
-keep class androidx.work.impl.** { *; }
