/** @type {import('tailwindcss').Config} */
module.exports = {
  theme: {
    extend: {
      colors: {
        primary: 'rgb(var(--yd-color-primary-rgb) / <alpha-value>)',
        primaryStrong: 'rgb(var(--yd-color-primary-strong-rgb) / <alpha-value>)',
        bg: 'rgb(var(--yd-color-bg-rgb) / <alpha-value>)',
        card: 'rgb(var(--yd-color-card-rgb) / <alpha-value>)',
        cardAlt: 'rgb(var(--yd-color-card-alt-rgb) / <alpha-value>)',
        border: 'rgb(var(--yd-color-border-rgb) / <alpha-value>)',
        text: 'rgb(var(--yd-color-text-rgb) / <alpha-value>)',
        textStrong: 'rgb(var(--yd-color-text-strong-rgb) / <alpha-value>)',
        muted: 'rgb(var(--yd-color-muted-rgb) / <alpha-value>)',
        success: 'rgb(var(--yd-color-success-rgb) / <alpha-value>)',
        warning: 'rgb(var(--yd-color-warning-rgb) / <alpha-value>)',
        danger: 'rgb(var(--yd-color-danger-rgb) / <alpha-value>)',
        info: 'rgb(var(--yd-color-info-rgb) / <alpha-value>)',
        star: 'rgb(var(--yd-color-star-rgb) / <alpha-value>)',
        starOff: 'rgb(var(--yd-color-star-off-rgb) / <alpha-value>)',
      },
      borderRadius: {
        sm: 'var(--yd-radius-sm)',
        md: 'var(--yd-radius-md)',
        lg: 'var(--yd-radius-lg)',
        xl: 'var(--yd-radius-xl)',
      },
      spacing: {
        1: 'var(--yd-space-1)',
        2: 'var(--yd-space-2)',
        3: 'var(--yd-space-3)',
        4: 'var(--yd-space-4)',
        5: 'var(--yd-space-5)',
        6: 'var(--yd-space-6)',
      },
      boxShadow: {
        yd1: 'var(--yd-shadow-1)',
        yd2: 'var(--yd-shadow-2)',
        yd3: 'var(--yd-shadow-3)',
      },
      fontFamily: {
        sans: ['var(--yd-font-family)'],
      },
      transitionDuration: {
        fast: 'var(--yd-duration-fast)',
        medium: 'var(--yd-duration-medium)',
        slow: 'var(--yd-duration-slow)',
      },
      fontSize: {
        xs: ['var(--yd-font-size-11)', { lineHeight: 'var(--yd-line-snug)' }],
        sm: ['var(--yd-font-size-12)', { lineHeight: 'var(--yd-line-snug)' }],
        base: ['var(--yd-font-size-14)', { lineHeight: 'var(--yd-line-body)' }],
        body: ['var(--yd-font-size-15)', { lineHeight: 'var(--yd-line-body)' }],
        lg: ['var(--yd-font-size-16)', { lineHeight: 'var(--yd-line-body)' }],
        xl: ['var(--yd-font-size-18)', { lineHeight: 'var(--yd-line-snug)' }],
        '2xl': ['var(--yd-font-size-22)', { lineHeight: 'var(--yd-line-tight)' }],
      },
    },
  },
};

