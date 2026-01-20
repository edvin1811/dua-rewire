// Unwire Focus Design System
// Based on Duolingo design patterns with iOS HIG guidelines

export const Colors = {
  // Primary - Macaw Blue
  primary: {
    DEFAULT: '#1CB0F6',
    dark: '#1899D6',
    light: '#7ED4FC',
  },
  // Success - Feather Green (THE Duolingo button color)
  success: {
    DEFAULT: '#58CC02',
    dark: '#58A700',
    light: '#89E219',
  },
  // Accent - Bee Yellow
  accent: {
    DEFAULT: '#FFC800',
    dark: '#E5A000',
    light: '#FFD84D',
  },
  // Warning - Fox Orange
  warning: {
    DEFAULT: '#FF9600',
    dark: '#CC7000',
  },
  // Error - Cardinal Red
  error: {
    DEFAULT: '#FF4B4B',
    dark: '#CC3333',
  },
  // Purple - Premium
  purple: {
    DEFAULT: '#CE82FF',
    dark: '#A855F7',
  },
  // Theme-specific colors
  dark: {
    background: '#131F24',
    surface: '#1A2B32',
    card: '#1A2B32',
    cardShadow: '#0D1518',
    border: '#2D4047',
    textPrimary: '#FFFFFF',
    textSecondary: '#AFAFAF',
    textTertiary: '#6E6E6E',
  },
  light: {
    background: '#FFFFFF',
    surface: '#F7F7F7',
    card: '#FFFFFF',
    cardShadow: '#E5E5E5',
    border: '#E5E5E5',
    textPrimary: '#4B4B4B',
    textSecondary: '#777777',
    textTertiary: '#AFAFAF',
  },
} as const;

// 8-point grid spacing system
export const Spacing = {
  xxs: 2,
  xs: 4,
  sm: 8,
  md: 16,
  lg: 24,
  xl: 32,
  xxl: 48,
} as const;

// Border radius tokens
export const Radius = {
  xs: 4,
  sm: 8,
  md: 12,
  lg: 16,
  xl: 20,
  pill: 999,
} as const;

// iOS HIG Typography scale
export const Typography = {
  largeTitle: {
    fontSize: 34,
    lineHeight: 41,
    fontWeight: '700' as const,
  },
  title1: {
    fontSize: 28,
    lineHeight: 34,
    fontWeight: '700' as const,
  },
  title2: {
    fontSize: 22,
    lineHeight: 28,
    fontWeight: '700' as const,
  },
  title3: {
    fontSize: 20,
    lineHeight: 25,
    fontWeight: '600' as const,
  },
  headline: {
    fontSize: 17,
    lineHeight: 22,
    fontWeight: '600' as const,
  },
  body: {
    fontSize: 17,
    lineHeight: 22,
    fontWeight: '400' as const,
  },
  callout: {
    fontSize: 16,
    lineHeight: 21,
    fontWeight: '400' as const,
  },
  subhead: {
    fontSize: 15,
    lineHeight: 20,
    fontWeight: '400' as const,
  },
  footnote: {
    fontSize: 13,
    lineHeight: 18,
    fontWeight: '400' as const,
  },
  caption: {
    fontSize: 12,
    lineHeight: 16,
    fontWeight: '400' as const,
  },
} as const;

// Animation timing (iOS HIG Guidelines)
// Micro-interactions: 0.1-0.15s
// Standard transitions: 0.25-0.35s
// Page transitions: 0.3-0.4s
// Maximum: 400ms (never exceed)
export const Animation = {
  micro: 150,      // Button press feedback
  standard: 300,   // Card appearance, tab switch
  page: 400,       // Hero entrance, page transitions
} as const;

// Shadow offset for 3D buttons (exact Duolingo spec)
export const ShadowOffset = 4;
