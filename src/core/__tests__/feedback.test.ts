import { describe, expect, it } from "vitest";
import { buildFeedbackRequest } from "../../lib/feedback";

describe("buildFeedbackRequest", () => {
  it("inserts into the feedback table with the anon key", () => {
    const { url, init } = buildFeedbackRequest("love the app", "a@b.c");
    expect(url).toBe("https://vxprqlniecdcxjkevoob.supabase.co/rest/v1/feedback");
    expect(init.method).toBe("POST");
    expect(init.headers.apikey.length).toBeGreaterThan(40);
    const body = JSON.parse(init.body);
    expect(body.source).toBe("web");
    expect(body.message).toBe("love the app");
    expect(body.email).toBe("a@b.c");
  });

  it("normalizes a missing email to null", () => {
    const { init } = buildFeedbackRequest("hi there", null);
    expect(JSON.parse(init.body).email).toBeNull();
  });
});
