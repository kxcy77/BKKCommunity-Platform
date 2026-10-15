package za.co.bkkcommunity.app.data

enum class ContentSection(val label: String) {
    EVENTS("Events"), DISCOUNTS("Discounts"), SERVICES("Local services")
}

data class ContentSyncStatus(val lastUpdated: Long? = null, val warning: String? = null)
