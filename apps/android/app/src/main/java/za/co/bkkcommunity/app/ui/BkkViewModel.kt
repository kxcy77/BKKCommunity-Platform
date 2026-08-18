package za.co.bkkcommunity.app.ui

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import za.co.bkkcommunity.app.AppContainer
import za.co.bkkcommunity.app.data.BkkRepository
import za.co.bkkcommunity.app.data.FeatureStore
import za.co.bkkcommunity.app.model.CommunityNotice
import za.co.bkkcommunity.app.model.CommunityEvent
import za.co.bkkcommunity.app.model.Discount
import za.co.bkkcommunity.app.model.LocalService
import za.co.bkkcommunity.app.model.Member
import za.co.bkkcommunity.app.model.SavedItems
import za.co.bkkcommunity.app.notification.ReminderScheduler

data class BkkUiState(
    val loading: Boolean = true,
    val working: Boolean = false,
    val events: List<CommunityEvent> = emptyList(),
    val discounts: List<Discount> = emptyList(),
    val services: List<LocalService> = emptyList(),
    val member: Member? = null,
    val attendanceHistory: List<CommunityEvent> = emptyList(),
    val historyLoading: Boolean = false,
    val savedItems: SavedItems = SavedItems(),
    val notices: List<CommunityNotice> = emptyList(),
    val lastUpdated: Long? = null,
    val eventDetails: Map<Long, CommunityEvent> = emptyMap(),
    val discountDetails: Map<Long, Discount> = emptyMap(),
    val detailLoading: Set<String> = emptySet(),
    val dataWarning: String? = null,
    val message: String? = null
)

class BkkViewModel(
    private val repository: BkkRepository,
    private val reminders: ReminderScheduler,
    private val featureStore: FeatureStore
) : ViewModel() {
    private val _state = MutableStateFlow(BkkUiState())
    val state: StateFlow<BkkUiState> = _state.asStateFlow()
    private var historyMemberId: Long? = null

    init {
        viewModelScope.launch {
            combine(repository.eventStream, repository.discountStream, repository.serviceStream, repository.memberStream) {
                    events, discounts, services, member ->
                DataSnapshot(events, discounts, services, member)
            }.collect { data ->
                _state.update { it.copy(events = data.events, discounts = data.discounts, services = data.services, member = data.member) }
                if (historyMemberId != data.member?.id) {
                    historyMemberId = data.member?.id
                    if (data.member == null) {
                        _state.update { it.copy(attendanceHistory = emptyList(), historyLoading = false) }
                    } else {
                        loadAttendanceHistory()
                    }
                }
            }
        }
        viewModelScope.launch {
            val warning = repository.initialize()
            _state.update { it.copy(loading = false, dataWarning = warning) }
        }
        viewModelScope.launch {
            featureStore.savedItems.collect { saved -> _state.update { it.copy(savedItems = saved) } }
        }
        viewModelScope.launch {
            featureStore.notices.collect { notices -> _state.update { it.copy(notices = notices) } }
        }
        viewModelScope.launch {
            featureStore.lastUpdated.collect { updated -> _state.update { it.copy(lastUpdated = updated) } }
        }
    }

    fun refresh() = runAction { repository.refreshAll().getOrThrow(); "Information updated." }

    fun login(email: String, password: String, onSuccess: () -> Unit) = runAction(onSuccess) {
        repository.login(email, password).getOrThrow()
        "Welcome back."
    }

    fun register(name: String, email: String, phone: String?, password: String, onSuccess: () -> Unit) = runAction(onSuccess) {
        repository.register(name, email, phone, password).getOrThrow()
        "Your account is ready."
    }

    fun forgotPassword(email: String, onSuccess: () -> Unit) = runAction(onSuccess) {
        repository.forgotPassword(email).getOrThrow()
    }

    fun resetPassword(email: String, token: String, password: String, onSuccess: () -> Unit) = runAction(onSuccess) {
        repository.resetPassword(email, token, password).getOrThrow()
    }

    fun setAttendance(event: CommunityEvent, attending: Boolean, onLoginRequired: () -> Unit) {
        if (_state.value.member == null) {
            _state.update { it.copy(message = "Please sign in before confirming attendance.") }
            onLoginRequired()
            return
        }
        if (event.isDemonstration) {
            _state.update { it.copy(message = "This demonstration event cannot accept attendance.") }
            return
        }
        runAction(onSuccess = ::loadAttendanceHistory) {
            repository.setAttendance(event.id, attending).getOrThrow()
            if (attending) reminders.schedule(event) else reminders.cancel(event.id)
            if (attending) "Attendance confirmed. A reminder has been scheduled." else "Attendance cancelled."
        }
    }

    fun submitContact(name: String, email: String, message: String, onSuccess: () -> Unit) = runAction(onSuccess) {
        repository.submitContact(name, email, message).getOrThrow()
    }

    fun updateProfile(name: String, email: String, phone: String?) = runAction {
        repository.updateProfile(name, email, phone).getOrThrow()
        "Profile updated."
    }

    fun updatePreferences(notifications: Boolean, eventReminders: Boolean, discountAlerts: Boolean) = runAction {
        repository.updatePreferences(notifications, eventReminders, discountAlerts).getOrThrow()
        "Notification preferences updated."
    }

    fun logout(onComplete: () -> Unit) {
        viewModelScope.launch {
            val token = repository.beginLogout()
            // Navigate as soon as the local session is gone. The server
            // revocation below must not make sign-out depend on connectivity.
            onComplete()
            repository.revokeSession(token)
            _state.update { it.copy(message = "You have signed out.") }
        }
    }

    fun deleteAccount(onComplete: () -> Unit) = runAction(onComplete) {
        repository.deleteAccount().getOrThrow()
        "Your account has been deleted."
    }

    fun registerDevice(token: String) {
        viewModelScope.launch { repository.registerDevice(token) }
    }

    fun loadEventDetail(id: Long) {
        if (id < 0 || _state.value.events.any { it.id == id } || _state.value.detailLoading.contains("event-$id")) return
        viewModelScope.launch {
            val key = "event-$id"
            _state.update { it.copy(detailLoading = it.detailLoading + key) }
            repository.eventDetail(id)
                .onSuccess { event ->
                    _state.update { state ->
                        state.copy(
                            eventDetails = state.eventDetails + (id to event),
                            detailLoading = state.detailLoading - key
                        )
                    }
                }
                .onFailure { error ->
                    _state.update { it.copy(detailLoading = it.detailLoading - key, message = repository.errorMessage(error)) }
                }
        }
    }

    fun loadDiscountDetail(id: Long) {
        if (id < 0 || _state.value.discounts.any { it.id == id } || _state.value.detailLoading.contains("discount-$id")) return
        viewModelScope.launch {
            val key = "discount-$id"
            _state.update { it.copy(detailLoading = it.detailLoading + key) }
            repository.discountDetail(id)
                .onSuccess { discount ->
                    _state.update { state ->
                        state.copy(
                            discountDetails = state.discountDetails + (id to discount),
                            detailLoading = state.detailLoading - key
                        )
                    }
                }
                .onFailure { error ->
                    _state.update { it.copy(detailLoading = it.detailLoading - key, message = repository.errorMessage(error)) }
                }
        }
    }

    fun toggleSaved(type: String, id: Long) {
        viewModelScope.launch { featureStore.toggleSaved(type, id) }
    }

    fun markNoticeRead(id: String) {
        viewModelScope.launch { featureStore.markNoticeRead(id) }
    }

    fun clearNotices() {
        viewModelScope.launch { featureStore.clearNotices() }
    }

    fun loadAttendanceHistory() {
        val memberId = _state.value.member?.id ?: return
        viewModelScope.launch {
            _state.update { it.copy(historyLoading = true) }
            repository.attendanceHistory()
                .onSuccess { history ->
                    if (_state.value.member?.id == memberId) {
                        _state.update { it.copy(attendanceHistory = history, historyLoading = false) }
                    }
                }
                .onFailure { error ->
                    if (_state.value.member?.id == memberId) {
                        _state.update { it.copy(historyLoading = false, message = repository.errorMessage(error)) }
                    }
                }
        }
    }

    fun consumeMessage() = _state.update { it.copy(message = null) }

    private fun runAction(onSuccess: () -> Unit = {}, action: suspend () -> String?) {
        if (_state.value.working) return
        viewModelScope.launch {
            _state.update { it.copy(working = true) }
            runCatching { action() }
                .onSuccess { message ->
                    _state.update { it.copy(working = false, message = message) }
                    onSuccess()
                }
                .onFailure { error ->
                    _state.update { it.copy(working = false, message = repository.errorMessage(error)) }
                }
        }
    }

    private data class DataSnapshot(
        val events: List<CommunityEvent>,
        val discounts: List<Discount>,
        val services: List<LocalService>,
        val member: Member?
    )
}

class BkkViewModelFactory(private val container: AppContainer) : ViewModelProvider.Factory {
    @Suppress("UNCHECKED_CAST")
    override fun <T : ViewModel> create(modelClass: Class<T>): T {
        return BkkViewModel(container.repository, container.reminderScheduler, container.featureStore) as T
    }
}
