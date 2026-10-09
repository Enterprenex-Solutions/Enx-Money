/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        navy: {
          50: '#F0F4F8',
          100: '#D9E2EC',
          200: '#BCCCDC',
          300: '#9FB3C8',
          400: '#627D98',
          500: '#486581',
          600: '#334E68',
          700: '#243B53',
          800: '#142C4F',
          850: '#0F223D',
          900: '#0B192C',
          950: '#060E18',
        },
        brand: {
          navy: '#0B192C',
          navyLight: '#142C4F',
          blue: '#2563EB',
          blueDark: '#1D4ED8',
          blueLight: '#3B82F6',
          blue50: '#EFF6FF',
          green: '#10B981',
          greenDark: '#059669',
          greenLight: '#34D399',
          cyan: '#06B6D4',
          slate: '#F8FAFC',
          border: '#E2E8F0',
        },
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', '-apple-system', 'sans-serif'],
        display: ['"Plus Jakarta Sans"', 'Inter', 'sans-serif'],
      },
      boxShadow: {
        'soft': '0 2px 15px -3px rgba(0, 0, 0, 0.07), 0 10px 20px -2px rgba(0, 0, 0, 0.04)',
        'premium': '0 20px 40px -15px rgba(11, 25, 44, 0.08), 0 0 1px 1px rgba(11, 25, 44, 0.05)',
        'elevated': '0 25px 50px -12px rgba(11, 25, 44, 0.15)',
        'glow-green': '0 0 25px -5px rgba(16, 185, 129, 0.3)',
        'glow-navy': '0 0 35px -5px rgba(11, 25, 44, 0.25)',
      },
      animation: {
        'float-slow': 'float 6s ease-in-out infinite',
        'pulse-subtle': 'pulseSubtle 3s ease-in-out infinite',
      },
      keyframes: {
        float: {
          '0%, 100%': { transform: 'translateY(0px)' },
          '50%': { transform: 'translateY(-8px)' },
        },
        pulseSubtle: {
          '0%, 100%': { opacity: '1' },
          '50%': { opacity: '0.8' },
        },
      },
    },
  },
  plugins: [],
}
