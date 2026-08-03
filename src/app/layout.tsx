import type { Metadata, Viewport } from "next";
import { Cormorant_Garamond, Inter } from "next/font/google";
import "./globals.css";
import { AnalyticsScripts } from "@/components/marketing/AnalyticsScripts";

// Self-hosted at build time (no render-blocking external request) and exposed as
// the same CSS variables the design system already reads, so type stays identical.
const cormorant = Cormorant_Garamond({
  subsets: ["latin"],
  weight: ["400", "500", "600", "700"],
  style: ["normal", "italic"],
  display: "swap",
  variable: "--font-display",
});

const inter = Inter({
  subsets: ["latin"],
  weight: ["300", "400", "500", "600", "700"],
  display: "swap",
  variable: "--font-sans",
});

const siteUrl = process.env.NEXT_PUBLIC_APP_URL || "https://forge.fit";
const title = "Forge — Your Training. Recovery. Progress. One Platform.";
const description =
  "Forge connects your workouts, wearable data, recovery, goals, and performance into one intelligent fitness platform built to help you improve faster. Join the early-access waitlist.";

export const metadata: Metadata = {
  metadataBase: new URL(siteUrl),
  title: {
    default: title,
    template: "%s · Forge",
  },
  description,
  applicationName: "Forge",
  keywords: [
    "fitness platform", "AI fitness coach", "wearable integration", "training plans",
    "recovery tracking", "HRV", "WHOOP", "Garmin", "Apple Watch", "Oura", "Strava",
    "hybrid athlete", "strength training", "running", "performance analytics",
  ],
  authors: [{ name: "Forge Performance Systems" }],
  alternates: { canonical: "/" },
  openGraph: {
    type: "website",
    url: siteUrl,
    siteName: "Forge",
    title,
    description,
    locale: "en_US",
  },
  twitter: {
    card: "summary_large_image",
    title,
    description,
  },
  robots: { index: true, follow: true },
};

export const viewport: Viewport = {
  themeColor: "#050608",
  colorScheme: "dark",
  width: "device-width",
  initialScale: 1,
  // Extend under the notch/home-indicator so env(safe-area-inset-*) is non-zero.
  viewportFit: "cover",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className={`scroll-smooth ${cormorant.variable} ${inter.variable}`}>
      <body className="min-h-screen bg-forge text-cream-100">
        {children}
        <AnalyticsScripts />
      </body>
    </html>
  );
}
