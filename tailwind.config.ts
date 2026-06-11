import type { Config } from "tailwindcss";

const config: Config = {
  content: ["./src/**/*.{ts,tsx}"],
  theme: {
    extend: {
      fontFamily: {
        display: ["var(--font-display)", "Cormorant Garamond", "ui-serif", "Georgia", "serif"],
        sans: ["var(--font-sans)", "Inter", "ui-sans-serif", "system-ui", "sans-serif"],
        mono: ["ui-monospace", "SFMono-Regular", "Menlo", "monospace"],
      },
      colors: {
        // Forge background palette — black with subtle navy undertone
        obsidian: {
          950: "#050608",
          900: "#0a0c10",
          850: "#0d1015",
          800: "#11141a",
          700: "#171b23",
          600: "#1f2430",
          500: "#2a303d",
          400: "#3a4150",
          300: "#5a6275",
          200: "#8b93a8",
          100: "#c4cad8",
        },
        // Gold — primary accent
        gold: {
          50: "#fff8e1",
          100: "#fbedb0",
          200: "#f5dc7a",
          300: "#e9c659",
          400: "#d4af37",
          500: "#c19a2b",
          600: "#a07f1f",
          700: "#7a6118",
        },
        // Cream — primary text
        cream: {
          50: "#fbf7ed",
          100: "#f4ecd8",
          200: "#e6dbc0",
          300: "#cfc4a8",
          400: "#a89d83",
        },
        // Status
        forge: {
          green: "#5dd39e",
          "green-dim": "#2b6a4d",
          amber: "#e9b949",
          ruby: "#9b2a3f",
          "ruby-dim": "#5a1822",
          royal: "#3a5a8c",
        },
      },
      boxShadow: {
        gold: "0 0 32px rgba(212, 175, 55, 0.12)",
        "gold-strong": "0 0 48px rgba(212, 175, 55, 0.22)",
        ember: "0 0 24px rgba(155, 42, 63, 0.18)",
        inner: "inset 0 1px 0 rgba(255, 255, 255, 0.04)",
      },
      backgroundImage: {
        "gold-gradient": "linear-gradient(135deg, #d4af37 0%, #f5dc7a 50%, #c19a2b 100%)",
        "obsidian-fade": "radial-gradient(ellipse at top, rgba(212,175,55,0.06), transparent 60%)",
        noise:
          "url(\"data:image/svg+xml,%3Csvg viewBox='0 0 200 200' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.9' numOctaves='3' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23n)' opacity='0.4'/%3E%3C/svg%3E\")",
      },
      animation: {
        "pulse-gold": "pulse-gold 3s ease-in-out infinite",
        "shimmer": "shimmer 8s ease-in-out infinite",
        "rise": "rise 0.5s ease-out",
      },
      keyframes: {
        "pulse-gold": {
          "0%, 100%": { opacity: "0.6", filter: "drop-shadow(0 0 6px rgba(212,175,55,0.3))" },
          "50%": { opacity: "1", filter: "drop-shadow(0 0 18px rgba(212,175,55,0.7))" },
        },
        shimmer: {
          "0%, 100%": { backgroundPosition: "0% 50%" },
          "50%": { backgroundPosition: "100% 50%" },
        },
        rise: {
          "0%": { opacity: "0", transform: "translateY(8px)" },
          "100%": { opacity: "1", transform: "translateY(0)" },
        },
      },
    },
  },
  plugins: [],
};

export default config;
