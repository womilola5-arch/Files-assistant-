@Entity(tableName = "file_inventory")
data class TrackedFile(
    @PrimaryKey val uriString: String,
    val name: String,
    val size: Long,
    val addedDate: Long,
    val mimeType: String,
    var status: String = "PENDING" // PENDING, ARCHIVED, IGNORED
)
