package za.co.bkkcommunity.app.data.local

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import kotlinx.coroutines.flow.Flow

@Dao
interface EventDao {
    @Query("SELECT * FROM events ORDER BY startAt ASC")
    fun observeAll(): Flow<List<EventEntity>>

    @Query("SELECT * FROM events WHERE id = :id LIMIT 1")
    fun observe(id: Long): Flow<EventEntity?>

    @Query("SELECT COUNT(*) FROM events")
    suspend fun count(): Int

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun replaceAll(items: List<EventEntity>)

    @Query("UPDATE events SET isAttending = :attending WHERE id = :id")
    suspend fun setAttendance(id: Long, attending: Boolean)

    @Query("DELETE FROM events")
    suspend fun clear()
}

@Dao
interface DiscountDao {
    @Query("SELECT * FROM discounts ORDER BY storeName ASC")
    fun observeAll(): Flow<List<DiscountEntity>>

    @Query("SELECT * FROM discounts WHERE id = :id LIMIT 1")
    suspend fun find(id: Long): DiscountEntity?

    @Query("SELECT COUNT(*) FROM discounts")
    suspend fun count(): Int

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun replaceAll(items: List<DiscountEntity>)

    @Query("DELETE FROM discounts")
    suspend fun clear()
}

@Dao
interface LocalServiceDao {
    @Query("SELECT * FROM local_services ORDER BY type, name")
    fun observeAll(): Flow<List<LocalServiceEntity>>

    @Query("SELECT * FROM local_services WHERE id = :id LIMIT 1")
    suspend fun find(id: Long): LocalServiceEntity?

    @Query("SELECT COUNT(*) FROM local_services")
    suspend fun count(): Int

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun replaceAll(items: List<LocalServiceEntity>)

    @Query("DELETE FROM local_services")
    suspend fun clear()
}
