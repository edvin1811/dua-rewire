/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./app/**/*.{js,jsx,ts,tsx}",
    "./components/**/*.{js,jsx,ts,tsx}",
  ],
  presets: [require("nativewind/preset")],
  theme: {
    extend: {
      // Duolingo-style color palette
      colors: {
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
        // Background colors (Dark mode focused)
        background: {
          DEFAULT: '#131F24',
          light: '#FFFFFF',
        },
        surface: {
          DEFAULT: '#1A2B32',
          light: '#F7F7F7',
        },
        card: {
          DEFAULT: '#1A2B32',
          light: '#FFFFFF',
        },
        // Text colors
        text: {
          primary: {
            DEFAULT: '#FFFFFF',
            light: '#4B4B4B',
          },
          secondary: {
            DEFAULT: '#AFAFAF',
            light: '#777777',
          },
          tertiary: {
            DEFAULT: '#6E6E6E',
            light: '#AFAFAF',
          },
        },
        // Border colors
        border: {
          DEFAULT: '#2D4047',
          light: '#E5E5E5',
        },
        // Card shadow
        'card-shadow': {
          DEFAULT: '#0D1518',
          light: '#E5E5E5',
        },
      },
      // 8-point grid spacing system
      spacing: {
        'xxs': '2px',
        'xs': '4px',
        'sm': '8px',
        'md': '16px',
        'lg': '24px',
        'xl': '32px',
        'xxl': '48px',
      },
      // Border radius tokens
      borderRadius: {
        'xs': '4px',
        'sm': '8px',
        'md': '12px',
        'lg': '16px',
        'xl': '20px',
        'pill': '999px',
      },
      // iOS HIG Typography scale
      fontSize: {
        'large-title': ['34px', { lineHeight: '41px', fontWeight: '700' }],
        'title-1': ['28px', { lineHeight: '34px', fontWeight: '700' }],
        'title-2': ['22px', { lineHeight: '28px', fontWeight: '700' }],
        'title-3': ['20px', { lineHeight: '25px', fontWeight: '600' }],
        'headline': ['17px', { lineHeight: '22px', fontWeight: '600' }],
        'body': ['17px', { lineHeight: '22px', fontWeight: '400' }],
        'callout': ['16px', { lineHeight: '21px', fontWeight: '400' }],
        'subhead': ['15px', { lineHeight: '20px', fontWeight: '400' }],
        'footnote': ['13px', { lineHeight: '18px', fontWeight: '400' }],
        'caption': ['12px', { lineHeight: '16px', fontWeight: '400' }],
      },
      // Animation timing
      transitionDuration: {
        'micro': '150ms',
        'standard': '300ms',
        'page': '400ms',
      },
      // Box shadow for 3D button effect
      boxShadow: {
        'button': '0 4px 0 0',
        'card': '0 4px 0 0',
      },
    },
  },
  plugins: [],
};
