import type { Metadata, Viewport } from "next";
import "./globals.css";
import { AnalyticsScripts } from "@/components/marketing/AnalyticsScripts";

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
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className="scroll-smooth">
      <body className="min-h-screen bg-forge text-cream-100">
        {children}
        <AnalyticsScripts />
      </body>
    </html>
  );
}
