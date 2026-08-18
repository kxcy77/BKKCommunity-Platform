package za.co.bkkcommunity.app.ui

import android.Manifest
import android.content.Intent
import android.net.Uri
import android.os.Build
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CalendarMonth
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.LocalOffer
import androidx.compose.material.icons.filled.Person
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.NavigationBarItemDefaults
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.NavDestination.Companion.hierarchy
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import com.google.firebase.messaging.FirebaseMessaging
import androidx.core.net.toUri
import za.co.bkkcommunity.app.AppContainer
import za.co.bkkcommunity.app.ui.screens.ContactScreen
import za.co.bkkcommunity.app.ui.screens.DiscountDetailScreen
import za.co.bkkcommunity.app.ui.screens.DiscountsScreen
import za.co.bkkcommunity.app.ui.screens.EventDetailScreen
import za.co.bkkcommunity.app.ui.screens.EventsScreen
import za.co.bkkcommunity.app.ui.screens.ForgotPasswordScreen
import za.co.bkkcommunity.app.ui.screens.HomeScreen
import za.co.bkkcommunity.app.ui.screens.InfoScreen
import za.co.bkkcommunity.app.ui.screens.LoginScreen
import za.co.bkkcommunity.app.ui.screens.MeScreen
import za.co.bkkcommunity.app.ui.screens.MyScheduleScreen
import za.co.bkkcommunity.app.ui.screens.NotificationInboxScreen
import za.co.bkkcommunity.app.ui.screens.RegisterScreen
import za.co.bkkcommunity.app.ui.screens.ResetPasswordScreen
import za.co.bkkcommunity.app.ui.screens.SavedItemsScreen
import za.co.bkkcommunity.app.ui.theme.BkkBlue
import za.co.bkkcommunity.app.ui.theme.BkkInk
import za.co.bkkcommunity.app.ui.theme.BkkNavy
import za.co.bkkcommunity.app.ui.theme.BkkSky
import za.co.bkkcommunity.app.ui.theme.BkkSurface

object Routes {
    const val HOME = "home"
    const val EVENTS = "events"
    const val EVENTS_TODAY = "events-today"
    const val DISCOUNTS = "discounts"
    const val INFO = "info"
    const val CONTACT = "contact"
    const val ME = "me"
    const val MY_SCHEDULE = "my-schedule"
    const val SAVED = "saved"
    const val NOTIFICATIONS = "notifications"
    const val LOGIN = "login"
    const val REGISTER = "register"
    const val FORGOT = "forgot"
    const val RESET_PASSWORD = "reset-password/{email}"
    const val EVENT_DETAIL = "event/{eventId}"
    const val DISCOUNT_DETAIL = "discount/{discountId}"
    fun event(id: Long) = "event/$id"
    fun discount(id: Long) = "discount/$id"
    fun resetPassword(email: String) = "reset-password/${Uri.encode(email.trim())}"
}

private data class MainDestination(val route: String, val label: String, val icon: ImageVector)

private val mainDestinations = listOf(
    MainDestination(Routes.HOME, "Home", Icons.Default.Home),
    MainDestination(Routes.EVENTS, "Events", Icons.Default.CalendarMonth),
    MainDestination(Routes.DISCOUNTS, "Discounts", Icons.Default.LocalOffer),
    MainDestination(Routes.INFO, "Services", Icons.Default.Info),
    MainDestination(Routes.ME, "Account", Icons.Default.Person)
)

@Composable
fun BkkApp(container: AppContainer, deepLink: Uri?) {
    val context = LocalContext.current
    val navController = rememberNavController()
    val viewModel: BkkViewModel = viewModel(factory = BkkViewModelFactory(container))
    val state by viewModel.state.collectAsStateWithLifecycle()
    val snackbarHost = remember { SnackbarHostState() }
    val permissionLauncher = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) { granted ->
        if (granted) registerFcmToken(viewModel)
    }

    fun requestNotifications() {
        if (Build.VERSION.SDK_INT >= 33) permissionLauncher.launch(Manifest.permission.POST_NOTIFICATIONS)
        else registerFcmToken(viewModel)
    }

    fun openPlatform() {
        navController.navigate(Routes.HOME) {
            popUpTo(Routes.LOGIN) { inclusive = true }
            launchSingleTop = true
        }
    }

    fun requireLogin() {
        navController.navigate(Routes.LOGIN) {
            popUpTo(navController.graph.id) { inclusive = true }
            launchSingleTop = true
        }
    }

    LaunchedEffect(state.message) {
        state.message?.let {
            snackbarHost.showSnackbar(it)
            viewModel.consumeMessage()
        }
    }
    LaunchedEffect(state.member?.id, deepLink) {
        if (state.member == null) {
            val currentRoute = navController.currentDestination?.route
            if (currentRoute != null && currentRoute !in setOf(
                    Routes.LOGIN,
                    Routes.REGISTER,
                    Routes.FORGOT,
                    Routes.RESET_PASSWORD
                )
            ) {
                requireLogin()
            }
            return@LaunchedEffect
        }

        if (navController.currentDestination?.route in setOf(
                Routes.LOGIN,
                Routes.REGISTER,
                Routes.FORGOT,
                Routes.RESET_PASSWORD
            )
        ) {
            openPlatform()
        }

        val segment = deepLink?.pathSegments?.firstOrNull() ?: return@LaunchedEffect
        when (deepLink.host) {
            "event" -> segment.toLongOrNull()?.let { navController.navigate(Routes.event(it)) }
            "discount" -> segment.toLongOrNull()?.let { navController.navigate(Routes.discount(it)) }
        }
    }
    LaunchedEffect(state.member?.id) {
        if (state.member != null) registerFcmToken(viewModel)
    }

    val backStack by navController.currentBackStackEntryAsState()
    val destination = backStack?.destination
    val showBottomBar = mainDestinations.any { item -> destination?.hierarchy?.any { it.route == item.route } == true } ||
        destination?.route == Routes.EVENTS_TODAY

    Scaffold(
        containerColor = BkkSurface,
        snackbarHost = { SnackbarHost(snackbarHost) },
        bottomBar = { if (showBottomBar) BkkBottomBar(navController) }
    ) { padding ->
        NavHost(navController, startDestination = Routes.LOGIN) {
            composable(Routes.HOME) {
                HomeScreen(state, padding, onNavigate = navController::navigate, onRefresh = viewModel::refresh,
                    onAttendance = { event, attending -> viewModel.setAttendance(event, attending) { navController.navigate(Routes.LOGIN) } },
                    onToggleSaved = viewModel::toggleSaved)
            }
            composable(Routes.EVENTS) {
                EventsScreen(state, padding, onProfile = { navController.navigate(Routes.ME) },
                    onOpen = { navController.navigate(Routes.event(it)) },
                    onAttendance = { event, attending -> viewModel.setAttendance(event, attending) { navController.navigate(Routes.LOGIN) } },
                    onToggleSaved = viewModel::toggleSaved)
            }
            composable(Routes.EVENTS_TODAY) {
                EventsScreen(state, padding, onProfile = { navController.navigate(Routes.ME) },
                    onOpen = { navController.navigate(Routes.event(it)) },
                    onAttendance = { event, attending -> viewModel.setAttendance(event, attending) { navController.navigate(Routes.LOGIN) } },
                    initialPeriod = "Today", onToggleSaved = viewModel::toggleSaved)
            }
            composable(Routes.DISCOUNTS) {
                DiscountsScreen(state, padding, onProfile = { navController.navigate(Routes.ME) },
                    onOpen = { navController.navigate(Routes.discount(it)) }, onToggleSaved = viewModel::toggleSaved)
            }
            composable(Routes.INFO) { InfoScreen(state, padding, onProfile = { navController.navigate(Routes.ME) }, onToggleSaved = viewModel::toggleSaved) }
            composable(Routes.CONTACT) {
                ContactScreen(state, padding, onBack = navController::popBackStack, onSubmit = viewModel::submitContact)
            }
            composable(Routes.ME) {
                MeScreen(state, padding, onLogin = { navController.navigate(Routes.LOGIN) },
                    onContact = { navController.navigate(Routes.CONTACT) }, onNotifications = ::requestNotifications,
                    onOpenInbox = { navController.navigate(Routes.NOTIFICATIONS) },
                    onOpenSchedule = { navController.navigate(Routes.MY_SCHEDULE) },
                    onOpenSaved = { navController.navigate(Routes.SAVED) },
                    onCallBkk = { context.startActivity(Intent(Intent.ACTION_DIAL, "tel:0728885030".toUri())) },
                    onRefreshAttendance = viewModel::loadAttendanceHistory,
                    onUpdateProfile = viewModel::updateProfile, onUpdatePreferences = viewModel::updatePreferences,
                    onLogout = { viewModel.logout(::requireLogin) },
                    onDelete = { viewModel.deleteAccount(::requireLogin) })
            }
            composable(Routes.EVENT_DETAIL) { entry ->
                val eventId = entry.arguments?.getString("eventId")?.toLongOrNull()
                LaunchedEffect(eventId) { eventId?.let(viewModel::loadEventDetail) }
                val event = state.events.firstOrNull { it.id == eventId } ?: state.eventDetails[eventId]
                EventDetailScreen(event, padding, onBack = navController::popBackStack,
                    onAttendance = { item, attending -> viewModel.setAttendance(item, attending) { navController.navigate(Routes.LOGIN) } },
                    loading = eventId != null && "event-$eventId" in state.detailLoading,
                    isSaved = eventId?.let { it in state.savedItems.eventIds } == true,
                    onToggleSaved = { eventId?.let { viewModel.toggleSaved("event", it) } },
                    onReport = { navController.navigate(Routes.CONTACT) })
            }
            composable(Routes.DISCOUNT_DETAIL) { entry ->
                val discountId = entry.arguments?.getString("discountId")?.toLongOrNull()
                LaunchedEffect(discountId) { discountId?.let(viewModel::loadDiscountDetail) }
                val discount = state.discounts.firstOrNull { it.id == discountId } ?: state.discountDetails[discountId]
                DiscountDetailScreen(
                    discount, padding, onBack = navController::popBackStack,
                    loading = discountId != null && "discount-$discountId" in state.detailLoading,
                    isSaved = discountId?.let { it in state.savedItems.discountIds } == true,
                    onToggleSaved = { discountId?.let { viewModel.toggleSaved("discount", it) } },
                    onReport = { navController.navigate(Routes.CONTACT) }
                )
            }
            composable(Routes.MY_SCHEDULE) {
                MyScheduleScreen(
                    state, padding, navController::popBackStack,
                    onOpen = { navController.navigate(Routes.event(it)) },
                    onAttendance = { event, attending -> viewModel.setAttendance(event, attending) { navController.navigate(Routes.LOGIN) } },
                    onRefresh = viewModel::loadAttendanceHistory,
                    onToggleSaved = viewModel::toggleSaved
                )
            }
            composable(Routes.SAVED) {
                SavedItemsScreen(
                    state, padding, navController::popBackStack,
                    onOpenEvent = { navController.navigate(Routes.event(it)) },
                    onOpenDiscount = { navController.navigate(Routes.discount(it)) },
                    onAttendance = { event, attending -> viewModel.setAttendance(event, attending) { navController.navigate(Routes.LOGIN) } },
                    onToggleSaved = viewModel::toggleSaved
                )
            }
            composable(Routes.NOTIFICATIONS) {
                NotificationInboxScreen(
                    state, padding, navController::popBackStack,
                    onOpen = { notice ->
                        viewModel.markNoticeRead(notice.id)
                        when (notice.type) {
                            "event" -> notice.itemId?.let { navController.navigate(Routes.event(it)) }
                            "discount" -> notice.itemId?.let { navController.navigate(Routes.discount(it)) }
                        }
                    },
                    onClear = viewModel::clearNotices
                )
            }
            composable(Routes.LOGIN) {
                LoginScreen(state, padding,
                    onLogin = { email, password -> viewModel.login(email, password, ::openPlatform) },
                    onRegister = { navController.navigate(Routes.REGISTER) },
                    onForgot = { navController.navigate(Routes.FORGOT) })
            }
            composable(Routes.REGISTER) {
                RegisterScreen(
                    state,
                    padding,
                    onBack = navController::popBackStack,
                    onRegister = { name, email, phone, password, _ ->
                        viewModel.register(name, email, phone, password, ::openPlatform)
                    }
                )
            }
            composable(Routes.FORGOT) {
                ForgotPasswordScreen(
                    state,
                    padding,
                    onBack = navController::popBackStack,
                    onSubmit = { email ->
                        viewModel.forgotPassword(email) { navController.navigate(Routes.resetPassword(email)) }
                    }
                )
            }
            composable(Routes.RESET_PASSWORD) { entry ->
                val email = Uri.decode(entry.arguments?.getString("email").orEmpty())
                ResetPasswordScreen(state, padding, email, onBack = navController::popBackStack,
                    onSubmit = { accountEmail, code, password ->
                        viewModel.resetPassword(accountEmail, code, password) {
                            navController.navigate(Routes.LOGIN) { popUpTo(Routes.FORGOT) { inclusive = true } }
                        }
                    })
            }
        }
    }
}

@Composable
private fun BkkBottomBar(navController: NavHostController) {
    val backStack by navController.currentBackStackEntryAsState()
    val current = backStack?.destination
    NavigationBar(containerColor = Color.White, tonalElevation = 10.dp) {
        mainDestinations.forEach { item ->
            val selected = current?.hierarchy?.any { destination ->
                destination.route == item.route || (item.route == Routes.EVENTS && destination.route == Routes.EVENTS_TODAY)
            } == true
            NavigationBarItem(
                selected = selected,
                onClick = {
                    navController.navigate(item.route) {
                        popUpTo(Routes.HOME) { saveState = true }
                        launchSingleTop = true
                        restoreState = true
                    }
                },
                icon = { Icon(item.icon, contentDescription = null) },
                label = { Text(item.label) },
                colors = NavigationBarItemDefaults.colors(
                    selectedIconColor = BkkNavy,
                    selectedTextColor = BkkNavy,
                    indicatorColor = BkkSky,
                    unselectedIconColor = BkkInk.copy(alpha = .66f),
                    unselectedTextColor = BkkInk.copy(alpha = .72f)
                )
            )
        }
    }
}

private fun registerFcmToken(viewModel: BkkViewModel) {
    runCatching {
        FirebaseMessaging.getInstance().token.addOnSuccessListener(viewModel::registerDevice)
    }
}
