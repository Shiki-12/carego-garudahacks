import { api } from "encore.dev/api";

export interface AppVersionResponse {
    latestVersion: string;
    downloadUrl: string;
    releaseNotes: string;
    forceUpdate: boolean;
}

export const version = api(
    { expose: true, method: "GET", path: "/app/version" },
    async (): Promise<AppVersionResponse> => {
        return {
            latestVersion: "1.0.0",
            downloadUrl: "https://carego.id/download",
            releaseNotes: "Initial release of CareGo Healthcare Platform.",
            forceUpdate: false
        };
    }
);
