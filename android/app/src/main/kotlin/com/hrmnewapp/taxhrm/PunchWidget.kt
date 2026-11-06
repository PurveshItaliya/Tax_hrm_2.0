package com.hrmnewapp.taxhrm

import android.content.Context
import android.content.Intent
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.floatPreferencesKey
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.GlanceTheme
import androidx.glance.ImageProvider
import androidx.glance.LocalSize
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetReceiver
import androidx.glance.appwidget.SizeMode
import androidx.glance.appwidget.action.actionStartActivity
import androidx.glance.appwidget.cornerRadius
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.currentState
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.padding
import androidx.glance.state.GlanceStateDefinition
import androidx.glance.state.PreferencesGlanceStateDefinition
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider

class PunchWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = PunchWidget()
}

class PunchWidget : GlanceAppWidget() {
    override val sizeMode: SizeMode = SizeMode.Exact
    override val stateDefinition: GlanceStateDefinition<*>? = PreferencesGlanceStateDefinition

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        android.util.Log.d("TaxHrmPunchWidget", "provideGlance called for id: $id")
        val punchIntent = Intent(context, MainActivity::class.java).apply {
            action = "PUNCH_WIDGET_TAP"
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }

        provideContent {
            // Subscribe to reactive Glance state for 100% reliable instant updates
            val colorKey = stringPreferencesKey("widget_color")
            val transparencyKey = floatPreferencesKey("widget_transparency")
            val blurKey = floatPreferencesKey("widget_blur")

            val color = currentState(colorKey) ?: "blue"
            val transparency = currentState(transparencyKey) ?: 0.70f
            val blur = currentState(blurKey) ?: 24f

            GlanceTheme {
                PunchWidgetContent(punchIntent, color, transparency, blur)
            }
        }
    }

    @Composable
    fun PunchWidgetContent(
        punchIntent: Intent,
        color: String,
        transparency: Float,
        blur: Float
    ) {
        val size = LocalSize.current
        val fontSize = when {
            size.width >= 240.dp || size.height >= 180.dp -> 38.sp
            size.width >= 170.dp || size.height >= 120.dp -> 30.sp
            size.width >= 110.dp -> 24.sp
            else -> 20.sp
        }

        // Theme-wise text color: dark slate on white theme, crisp white on all other themes
        val textColor = if (color == "white") Color(0xFF0F172A) else Color.White

        // Dedicated theme backgrounds:
        // "black" -> Pure jet dark black (never grey!)
        // "blue"  -> Rich dark primary theme blue (#104EC8 to #0A368A)
        // "white" -> Crisp solid white
        // "transparent" -> Pure liquid glass with frost sheen
        val bgDrawableRes = when (color) {
            "white" -> R.drawable.ic_punch_widget_white
            "black" -> R.drawable.ic_punch_widget_black
            "blue" -> R.drawable.ic_punch_widget_blue
            "transparent" -> R.drawable.ic_punch_widget_bg
            else -> R.drawable.ic_punch_widget_blue
        }

        // Calculate dynamic blur frosted diffusion overlay for transparent liquid glass only
        val blurAlpha = ((blur.coerceIn(0f, 50f) / 50f) * 60).toInt().coerceIn(0, 80)
        val blurOverlayColor = Color(android.graphics.Color.argb(blurAlpha, 255, 255, 255))

        Box(
            modifier = GlanceModifier
                .fillMaxSize()
                .padding(4.dp)
                .clickable(actionStartActivity(punchIntent)),
            contentAlignment = Alignment.Center
        ) {
            Box(
                modifier = GlanceModifier
                    .fillMaxSize()
                    .background(ImageProvider(bgDrawableRes))
                    .cornerRadius(22.dp),
                contentAlignment = Alignment.Center
            ) {
                // Frost diffusion sheen only for transparent glass theme (never wash out dark black/blue)
                if (color == "transparent" && blurAlpha > 0) {
                    Box(
                        modifier = GlanceModifier
                            .fillMaxSize()
                            .background(blurOverlayColor)
                            .cornerRadius(22.dp)
                    ) {}
                }

                // Centered "PUNCH" bold text with theme-aware high-contrast color
                Text(
                    text = "PUNCH",
                    style = TextStyle(
                        color = ColorProvider(textColor),
                        fontSize = fontSize,
                        fontWeight = FontWeight.Bold
                    )
                )
            }
        }
    }
}
