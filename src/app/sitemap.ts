import type { MetadataRoute } from "next";

const base = process.env.NEXT_PUBLIC_APP_URL || "https://forge.fit";

// Public marketing routes only. The product demo under (app) is intentionally
// excluded from the sitemap pre-launch.
export default function sitemap(): MetadataRoute.Sitemap {
  const routes = ["", "/waitlist", "/beta"];
  return routes.map((path) => ({
    url: `${base}${path}`,
    changeFrequency: "weekly",
    priority: path === "" ? 1 : 0.8,
  }));
}
