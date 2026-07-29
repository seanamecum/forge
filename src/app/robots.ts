import type { MetadataRoute } from "next";

const base = process.env.NEXT_PUBLIC_APP_URL || "https://forge.fit";

export default function robots(): MetadataRoute.Robots {
  return {
    rules: [
      {
        userAgent: "*",
        allow: "/",
        // Keep the internal product demo + form endpoints out of the index.
        disallow: ["/api/", "/dashboard", "/auth", "/onboarding"],
      },
    ],
    sitemap: `${base}/sitemap.xml`,
    host: base,
  };
}
