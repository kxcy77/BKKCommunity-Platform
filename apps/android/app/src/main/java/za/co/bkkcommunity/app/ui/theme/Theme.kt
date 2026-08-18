package za.co.bkkcommunity.app.ui.theme

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Shapes
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

private val BkkColors = lightColorScheme(
    primary = BkkBlue,
    onPrimary = Color.White,
    primaryContainer = BkkSky,
    onPrimaryContainer = BkkNavy,
    secondary = BkkGreen,
    onSecondary = Color.White,
    secondaryContainer = BkkGreenSurface,
    onSecondaryContainer = BkkGreen,
    tertiary = BkkGold,
    onTertiary = Color.White,
    tertiaryContainer = BkkGoldSurface,
    onTertiaryContainer = Color(0xFF5E3900),
    error = BkkRed,
    errorContainer = BkkRedSurface,
    background = BkkSurface,
    onBackground = BkkInk,
    surface = BkkWarmSurface,
    onSurface = BkkInk,
    surfaceVariant = BkkSky,
    onSurfaceVariant = BkkMuted,
    outline = BkkMuted,
    outlineVariant = BkkLine
)

private val BkkTypography = androidx.compose.material3.Typography(
    displaySmall = TextStyle(fontFamily = FontFamily.SansSerif, fontWeight = FontWeight.ExtraBold, fontSize = 34.sp, lineHeight = 41.sp, letterSpacing = (-0.5).sp),
    headlineLarge = TextStyle(fontFamily = FontFamily.SansSerif, fontWeight = FontWeight.ExtraBold, fontSize = 29.sp, lineHeight = 36.sp, letterSpacing = (-0.25).sp),
    headlineMedium = TextStyle(fontFamily = FontFamily.SansSerif, fontWeight = FontWeight.Bold, fontSize = 25.sp, lineHeight = 32.sp),
    titleLarge = TextStyle(fontFamily = FontFamily.SansSerif, fontWeight = FontWeight.ExtraBold, fontSize = 22.sp, lineHeight = 29.sp),
    titleMedium = TextStyle(fontFamily = FontFamily.SansSerif, fontWeight = FontWeight.SemiBold, fontSize = 19.sp, lineHeight = 26.sp),
    bodyLarge = TextStyle(fontFamily = FontFamily.SansSerif, fontSize = 18.sp, lineHeight = 28.sp),
    bodyMedium = TextStyle(fontFamily = FontFamily.SansSerif, fontSize = 17.sp, lineHeight = 25.sp),
    labelLarge = TextStyle(fontFamily = FontFamily.SansSerif, fontWeight = FontWeight.Bold, fontSize = 18.sp, lineHeight = 24.sp),
    labelMedium = TextStyle(fontFamily = FontFamily.SansSerif, fontWeight = FontWeight.SemiBold, fontSize = 15.sp, lineHeight = 20.sp)
)

private val BkkShapes = Shapes(
    extraSmall = androidx.compose.foundation.shape.RoundedCornerShape(8.dp),
    small = androidx.compose.foundation.shape.RoundedCornerShape(12.dp),
    medium = androidx.compose.foundation.shape.RoundedCornerShape(18.dp),
    large = androidx.compose.foundation.shape.RoundedCornerShape(24.dp),
    extraLarge = androidx.compose.foundation.shape.RoundedCornerShape(32.dp)
)

@Composable
fun BkkTheme(content: @Composable () -> Unit) {
    MaterialTheme(colorScheme = BkkColors, typography = BkkTypography, shapes = BkkShapes, content = content)
}
