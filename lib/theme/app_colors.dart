// File: lib/theme/app_colors.dart

import 'package:flutter/material.dart';

// -----------------------------------------------------------------
// I. BRAND & CORE SEMANTIC COLORS (Used by both Light and Dark modes)
// -----------------------------------------------------------------

// 1. Primary (Trust, Stability, Main Action)
const Color kBrandNavy = Color(0xFF003366);
const Color kBrandLightBlue = Color(0xFF1E88E5);

// 2. Secondary (Accent, Highlight, Focus)
const Color kAccentCyan = Color(0xFF00BFA5); // A lively green-blue for accents
const Color kAccentOrange = Color(0xFFF9A825); // Warning/Highlight for alerts

// 3. Status/Semantic Colors
const Color kSuccessGreen = Color(0xFF4CAF50);
const Color kWarningYellow = Color(0xFFFFC107);
const Color kErrorRed = Color(0xFFD32F2F);
const Color kInfoBlue = Color(0xFF2196F3);

const Color primaryNavy = Color(0xFF003366);
const Color accentGreen = Color(0xFF4CAF50);
const Color errorRed = Color(0xFFD32F2F);
const Color lightGrey = Color(0xFFF5F5F5);


// 4. Specialized Account/Widget Colors (For visual distinction)
const Color kSavingsCardColor = Color(0xFF004D40); // Dark Teal
const Color kCurrentCardColor = Color(0xFF311B92); // Deep Purple
const Color kFixedDepositCardColor = Color(0xFFC62828); // Deep Red

// -----------------------------------------------------------------
// II. LIGHT THEME PALETTE (Neutral & Backgrounds)
// -----------------------------------------------------------------

const Color kLightSurface = Color(0xFFFFFFFF); // Pure white for Cards/Containers
const Color kLightBackground = Color(0xFFF5F7FA); // Very light grey screen background
const Color kLightTextPrimary = Color(0xFF212121); // Dark charcoal main text
const Color kLightTextSecondary = Color(0xFF616161); // Medium grey labels/hints
const Color kLightDivider = Color(0xFFE0E0E0); // Light divider/border color

// -----------------------------------------------------------------
// III. DARK THEME PALETTE (Neutral & Backgrounds)
// -----------------------------------------------------------------

const Color kDarkSurface = Color(0xFF1E1E1E); // Dark Grey surface for Cards/Containers
const Color kDarkBackground = Color(0xFF121212); // Near-black screen background
const Color kDarkTextPrimary = Color(0xFFE0E0E0); // Light text
const Color kDarkTextSecondary = Color(0xFF9E9E9E); // Lighter grey labels/hints
const Color kDarkDivider = Color(0xFF333333); // Dark divider/border color



const Color kSoftGoldBackground = Color(0xFFFBE09B);


const Color kDarkNavy = Color(0xFF004488); // For gradient use in AppBar
const Color kDividerColor = Color(0xFFE0E5EA);

const Color kPrimaryNavyBlue = Color(0xFF003366);

// Accent Color (A dynamic light blue/cyan)
const Color kSecondaryAccentBlue = Color(0xFF1E88E5);

// Background color for text fields (a common banking app style is a light, distinct background)
const Color kInputBackgroundColor = Color(0xFFF0F4F8); // Very light blue/gray for input fields

// Border color for text fields
const Color kInputBorderColor = Color(0xFFCCCCCC); // A light grey for borders

const Color kStatusNewRed = Color(0xFFD32F2F); // Specific color for "NEW" badges

// 5. App-Specific Accents (Matching Screenshot)
const Color kBrandPurple = Color(0xFF512DA8); // Deep purple for action items/icons in the Deposit screen.

// 6. Text Semantics
const Color kLightTextLink = kBrandPurple;

const double kTpinFieldSize = 40.0;
