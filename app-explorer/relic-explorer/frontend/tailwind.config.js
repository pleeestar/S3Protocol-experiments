/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './app/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {
      fontFamily: {
        sans: ['Inter', 'sans-serif'],
        mono: ['JetBrains Mono', 'monospace'],
      },
      colors: {
        background: '#09090b', // Zinc 950
        surface: '#18181b',    // Zinc 900
        surfaceHighlight: '#27272a', // Zinc 800
        border: '#27272a',
        primary: '#fafafa',    // Zinc 50
        muted: '#a1a1aa',      // Zinc 400
        accent: {
          start: '#4f46e5', // Indigo 600
          end: '#ec4899',   // Pink 500
        }
      },
      animation: {
        'pulse-slow': 'pulse 3s cubic-bezier(0.4, 0, 0.6, 1) infinite',
      }
    },
  },
  plugins: [],
}
