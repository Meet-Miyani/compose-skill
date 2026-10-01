package com.example.brandtheme.theme

import androidx.compose.ui.graphics.Color

// GOOD regression fixture for check-hardcoded-colors.sh: a second
// brand/theme module. Palette colors legitimately live here, so
// DESIGN_SYSTEM_DIRS covers this directory and the check passes.
internal object BrandPalette {
    val primary = Color(0xFF2F6BFF)
    val onPrimary = Color(0xFFFFFFFF)
}
