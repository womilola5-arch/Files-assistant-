fun deleteFilesPro(activity: Activity, uris: List<Uri>) {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
        // This triggers the official "Allow app to delete?" system popup
        val pendingIntent = MediaStore.createDeleteRequest(activity.contentResolver, uris)
        activity.startIntentSenderForResult(pendingIntent.intentSender, 123, null, 0, 0, 0)
    }
}
