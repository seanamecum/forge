import { describe, expect, it } from "vitest";
import { buildAuthRequest, sessionFromPayload } from "../../lib/auth";

describe("buildAuthRequest", () => {
  it("targets the Forge Supabase project with the anon key", () => {
    const { url, init } = buildAuthRequest("signup", { email: "a@b.c" });
    expect(url).toBe("https://vxprqlniecdcxjkevoob.supabase.co/auth/v1/signup");
    expect(init.method).toBe("POST");
    expect(init.headers.apikey.length).toBeGreaterThan(40);
    expect(JSON.parse(init.body)).toEqual({ email: "a@b.c" });
  });

  it("passes grant-type query paths through untouched", () => {
    const { url } = buildAuthRequest("token?grant_type=password", {});
    expect(url).toContain("/auth/v1/token?grant_type=password");
  });
});

describe("sessionFromPayload", () => {
  it("maps a GoTrue token payload", () => {
    const s = sessionFromPayload(
      {
        access_token: "at",
        refresh_token: "rt",
        expires_at: 2_000_000_000,
        user: { email: "sean@forge.app" },
      },
      "fallback@x.com",
    );
    expect(s).toEqual({
      accessToken: "at",
      refreshToken: "rt",
      email: "sean@forge.app",
      expiresAt: 2_000_000_000,
    });
  });

  it("returns null when there is no session (email confirmation pending)", () => {
    expect(sessionFromPayload({ id: "user-only" }, "a@b.c")).toBeNull();
    expect(sessionFromPayload(null, "a@b.c")).toBeNull();
  });

  it("falls back to the typed email when the payload omits it", () => {
    const s = sessionFromPayload({ access_token: "at" }, "typed@x.com");
    expect(s?.email).toBe("typed@x.com");
  });
});
