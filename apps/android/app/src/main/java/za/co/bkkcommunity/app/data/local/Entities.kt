package za.co.bkkcommunity.app.data.local

import androidx.room.Entity
import androidx.room.PrimaryKey
import za.co.bkkcommunity.app.model.CommunityEvent
import za.co.bkkcommunity.app.model.Discount
import za.co.bkkcommunity.app.model.LocalService

@Entity(tableName = "events")
data class EventEntity(
    @PrimaryKey val id: Long,
    val title: String,
    val description: String,
    val startAt: String,
    val endAt: String,
    val location: String,
    val directions: String?,
    val category: String,
    val colourHex: String,
    val isAttending: Boolean,
    val isDemo: Boolean = false
)

@Entity(tableName = "discounts")
data class DiscountEntity(
    @PrimaryKey val id: Long,
    val storeName: String,
    val title: String,
    val details: String,
    val eligibility: String,
    val claimInstructions: String,
    val category: String,
    val validFrom: String?,
    val validUntil: String?,
    val isDemo: Boolean = false
)

@Entity(tableName = "local_services")
data class LocalServiceEntity(
    @PrimaryKey val id: Long,
    val type: String,
    val name: String,
    val address: String,
    val phone: String,
    val directions: String?,
    val openingHours: String?,
    val isDemo: Boolean = false
)

fun EventEntity.toDomain() = CommunityEvent(
    id, title, description, startAt, endAt, location, directions, category, colourHex, isAttending, isDemo
)

fun DiscountEntity.toDomain() = Discount(
    id, storeName, title, details, eligibility, claimInstructions, category, validFrom, validUntil
)

fun LocalServiceEntity.toDomain() = LocalService(id, type, name, address, phone, directions, openingHours)
