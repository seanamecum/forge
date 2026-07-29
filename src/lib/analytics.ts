// @forge/analytics — a thin, provider-agnostic event layer.
//
// No tracking IDs are hard-coded. Each provider activates ONLY when its env var
// is present (see AnalyticsScripts.tsx + .env.example). Until then every call
// here is a no-op, so the funnel code below can ship as-is.
//
//   NEXT_PUBLIC_GA_ID        — Google Analytics 4 (e.g. G-XXXXXXXXXX)
//   NEXT_PUBLIC_META_PIXEL_ID — Meta / Facebook Pixel
//   NEXT_PUBLIC_TIKTOK_PIXEL_ID — TikTok Pixel

export const analyticsIds = {
  ga: process.env.NEXT_PUBLIC_GA_ID || "",
  metaPixel: process.env.NEXT_PUBLIC_META_PIXEL_ID || "",
  tiktokPixel: process.env.NEXT_PUBLIC_TIKTOK_PIXEL_ID || "",
};

export const analyticsEnabled =
  !!analyticsIds.ga || !!analyticsIds.metaPixel || !!analyticsIds.tiktokPixel;

/** Canonical conversion events. Keep names stable — dashboards depend on them. */
export const AnalyticsEvent = {
  WaitlistSubmitted: "waitlist_submitted",
  BetaApplicationSubmitted: "beta_application_submitted",
  WaitlistStarted: "waitlist_started",
  BetaStarted: "beta_started",
  ReferralCopied: "referral_copied",
  CtaClicked: "cta_clicked",
} as const;

export type AnalyticsEventName =
  (typeof AnalyticsEvent)[keyof typeof AnalyticsEvent];

type Props = Record<string, string | number | boolean | undefined>;

declare global {
  interface Window {
    gtag?: (...args: unknown[]) => void;
    fbq?: (...args: unknown[]) => void;
    ttq?: { track: (...args: unknown[]) => void; page: () => void };
    dataLayer?: unknown[];
  }
}

/**
 * Fire a conversion event to every configured provider at once. Safe to call
 * from anywhere on the client; guards against SSR and un-configured providers.
 */
export function track(event: AnalyticsEventName, props: Props = {}): void {
  if (typeof window === "undefined") return;

  // Always leave a breadcrumb in dev so events are verifiable without a backend.
  if (process.env.NODE_ENV !== "production") {
    // eslint-disable-next-line no-console
    console.info(`[analytics] ${event}`, props);
  }

  try {
    if (analyticsIds.ga && window.gtag) {
      window.gtag("event", event, props);
    }
    if (analyticsIds.metaPixel && window.fbq) {
      // Map our conversions onto Meta's standard events where it helps optimization.
      const meta = MetaEventMap[event];
      if (meta) window.fbq("track", meta, props);
      window.fbq("trackCustom", event, props);
    }
    if (analyticsIds.tiktokPixel && window.ttq) {
      window.ttq.track(event, props);
    }
  } catch {
    // Analytics must never break the UX.
  }
}

const MetaEventMap: Partial<Record<AnalyticsEventName, string>> = {
  [AnalyticsEvent.WaitlistSubmitted]: "Lead",
  [AnalyticsEvent.BetaApplicationSubmitted]: "CompleteRegistration",
  [AnalyticsEvent.WaitlistStarted]: "InitiateCheckout",
};
