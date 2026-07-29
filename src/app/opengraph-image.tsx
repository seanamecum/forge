import { ImageResponse } from "next/og";

// Static OG / social share image, generated at build time. 1200×630.
export const runtime = "edge";
export const alt = "Forge — Your Training. Recovery. Progress. One Platform.";
export const size = { width: 1200, height: 630 };
export const contentType = "image/png";

export default function OpengraphImage() {
  return new ImageResponse(
    (
      <div
        style={{
          width: "100%",
          height: "100%",
          display: "flex",
          flexDirection: "column",
          justifyContent: "center",
          padding: "80px",
          background: "linear-gradient(135deg, #0c0d0a 0%, #050608 45%, #0a0906 100%)",
          color: "#f4ecd8",
          fontFamily: "sans-serif",
        }}
      >
        <div
          style={{
            display: "flex",
            alignItems: "center",
            gap: 16,
            fontSize: 26,
            letterSpacing: 12,
            textTransform: "uppercase",
            color: "#e9c659",
          }}
        >
          <div
            style={{
              width: 44,
              height: 44,
              borderRadius: 10,
              background: "linear-gradient(135deg,#f5dc7a,#a07f1f)",
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              color: "#11141a",
              fontSize: 30,
              fontWeight: 700,
            }}
          >
            F
          </div>
          Forge
        </div>

        <div style={{ display: "flex", flexDirection: "column", marginTop: 40 }}>
          <div style={{ fontSize: 74, fontWeight: 700, lineHeight: 1.05 }}>
            Your Training. Recovery. Progress.
          </div>
          <div
            style={{
              fontSize: 74,
              fontWeight: 700,
              lineHeight: 1.05,
              background: "linear-gradient(135deg,#f5dc7a,#d4af37,#a07f1f)",
              backgroundClip: "text",
              color: "transparent",
            }}
          >
            One platform.
          </div>
        </div>

        <div style={{ fontSize: 30, color: "#8b93a8", marginTop: 36, maxWidth: 900 }}>
          The performance operating system for athletes. Join the early-access waitlist.
        </div>
      </div>
    ),
    { ...size },
  );
}
