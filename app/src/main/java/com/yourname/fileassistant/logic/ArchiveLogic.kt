class ArchiveLogic(private val context: Context) {
    fun archiveFile(file: TrackedFile): Boolean {
        return try {
            val sourceUri = Uri.parse(file.uriString)
            val destinationFile = File(context.getExternalFilesDir("Archive"), file.name)
            
            context.contentResolver.openInputStream(sourceUri)?.use { input ->
                destinationFile.outputStream().use { output ->
                    input.copyTo(output)
                }
            }
            // After copying to vault, we signal the app to request deletion of the original
            true
        } catch (e: Exception) { false }
    }
}
