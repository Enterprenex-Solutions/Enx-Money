import type { Config } from 'tailwindcss';

const config: Config = {
  content: [
    './src/pages/**/*.{js,ts,jsx,tsx,mdx}',
    './src/components/**/*.{js,ts,jsx,tsx,mdx}',
    './src/app/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {
      colors: {
        bg: '#090d16',
        surface: '#0f172a',
        'surface-elevated': '#131d35',
        'surface-hover': '#18233e',
        border: '#1e293b',
        'border-subtle': '#162032',
        primary: '#2563eb',
        'primary-hover': '#1d4ed8',
      },
    },
  },
  plugins: [],
};

export default config;
