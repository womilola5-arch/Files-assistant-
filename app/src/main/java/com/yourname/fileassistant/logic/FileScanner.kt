class FileScanner(private val context: Context) {
    fun getForgottenFiles(): List<TrackedFile> {
        val foundFiles = mutableListOf<TrackedFile>()
        val sixMonthsAgo = System.currentTimeMillis() - (180L * 24 * 60 * 60 * 1000)

        val projection = arrayOf(
            MediaStore.Files.FileColumns._ID,
            MediaStore.Files.FileColumns.DISPLAY_NAME,
            MediaStore.Files.FileColumns.SIZE,
            MediaStore.Files.FileColumns.DATE_ADDED
        )

        // Querying for files older than 6 months
        val selection = "${MediaStore.Files.FileColumns.DATE_ADDED} < ?"
        val selectionArgs = arrayOf((sixMonthsAgo / 1000).toString())

        context.contentResolver.query(
            MediaStore.Files.getContentUri("external"),
            projection, selection, selectionArgs, null
        )?.use { cursor ->
            val idCol = cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns._ID)
            val nameCol = cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns.DISPLAY_NAME)
            
            while (cursor.moveToNext()) {
                val id = cursor.getLong(idCol)
                val uri = ContentUris.withAppendedId(MediaStore.Files.getContentUri("external"), id)
                foundFiles.add(TrackedFile(
                    uriString = uri.toString(),
                    name = cursor.getString(nameCol),
                    size = cursor.getLong(cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns.SIZE)),
                    addedDate = cursor.getLong(cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns.DATE_ADDED)) * 1000,
                    mimeType = "file"
                ))
            }
        }
        return foundFiles
    }
}
