import XCTest
@testable import Forge

/// Data export must be complete, versioned, and never a silent empty object.
final class ExportTests: XCTestCase {

    @MainActor
    func testExportIsVersionedAndCarriesMetadata() throws {
        let data = try PersistenceService.exportDocument(profile: MockData.sean)
        let doc = try XCTUnwrap(try JSONSerialization.jsonObject(with: data) as? [String: Any])

        XCTAssertEqual(doc["schema_version"] as? Int, PersistenceService.exportSchemaVersion)
        XCTAssertEqual(doc["app"] as? String, "Forge")
        XCTAssertNotNil(doc["app_version"])
        XCTAssertNotNil(doc["generated_at"])   // ISO-8601 timestamp
        XCTAssertNotNil(doc["timezone"])
        XCTAssertNotNil(doc["units"])
        // Never the old silent "{}".
        XCTAssertGreaterThan(data.count, 2)
    }

    @MainActor
    func testExportIncludesProfileAndTargets() throws {
        let data = try PersistenceService.exportDocument(profile: MockData.sean)
        let doc = try XCTUnwrap(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        let profile = try XCTUnwrap(doc["profile"] as? [String: Any])
        XCTAssertEqual(profile["name"] as? String, MockData.sean.name)
        XCTAssertFalse((profile["goals"] as? [String] ?? []).isEmpty)
        XCTAssertNotNil(profile["targets"])
    }

    @MainActor
    func testExportToTemporaryFileWritesReadableJSON() throws {
        let url = try PersistenceService.exportToTemporaryFile(profile: MockData.sean)
        addTeardownBlock { try? FileManager.default.removeItem(at: url) }
        let reloaded = try Data(contentsOf: url)
        XCTAssertNoThrow(try JSONSerialization.jsonObject(with: reloaded))
        XCTAssertTrue(url.lastPathComponent.hasSuffix(".json"))
    }
}
