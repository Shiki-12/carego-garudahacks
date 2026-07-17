import { describe, it } from "vitest";
import assert from "node:assert";
import { version } from "./api";

describe("App Service", () => {
    it("should return the latest app version", async () => {
        const res = await version();
        assert.strictEqual(res.latestVersion, "1.0.0");
        assert.strictEqual(res.forceUpdate, false);
        assert.ok(res.downloadUrl.includes("carego.id"));
    });
});
