@Dao
interface FileDao {
    @Query("SELECT * FROM file_inventory WHERE status = 'PENDING' ORDER BY addedDate ASC")
    fun getOldFiles(): Flow<List<TrackedFile>>

    @Insert(onConflict = OnConflictStrategy.IGNORE)
    suspend fun insertFiles(files: List<TrackedFile>)

    @Update
    suspend fun updateFile(file: TrackedFile)
}
