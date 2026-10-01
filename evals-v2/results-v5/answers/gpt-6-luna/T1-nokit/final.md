Added an **Attach photo** button to the workout editor. On Android, it opens the system photo picker, copies the selected image into app-private storage, and saves its path with the workout. Existing Room databases migrate to include the photo path.

Android and JVM compilation succeeded. The iOS and JVM picker buttons are placeholders and do not yet select photos.