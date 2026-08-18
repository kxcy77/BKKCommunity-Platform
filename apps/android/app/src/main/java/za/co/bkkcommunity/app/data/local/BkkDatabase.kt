package za.co.bkkcommunity.app.data.local

import androidx.room.Database
import androidx.room.RoomDatabase

@Database(
    entities = [EventEntity::class, DiscountEntity::class, LocalServiceEntity::class],
    version = 1,
    exportSchema = false
)
abstract class BkkDatabase : RoomDatabase() {
    abstract fun eventDao(): EventDao
    abstract fun discountDao(): DiscountDao
    abstract fun localServiceDao(): LocalServiceDao
}
