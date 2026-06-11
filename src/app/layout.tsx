import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Forge — Human Performance, Engineered",
  description:
    "Forge is an AI-powered human performance operating system. Training, nutrition, recovery, injury rehab, wearables, and coaching — engineered into one daily decision engine.",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body className="min-h-screen bg-forge text-cream-100">{children}</body>
    </html>
  );
}
