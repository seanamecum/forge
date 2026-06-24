// @forge/data — the app's single data entry point.
// Swap MockDataSource for a SupabaseDataSource here (gated on env) when M1 lands;
// nothing else in the app changes.

import { MockDataSource } from "./mock-source";
import type { ForgeDataSource } from "./source";

export type { DashboardData, ForgeDataSource } from "./source";

export const dataSource: ForgeDataSource = new MockDataSource();
