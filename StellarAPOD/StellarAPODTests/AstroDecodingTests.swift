import XCTest
@testable import StellarAPOD

final class AstroDecodingTests: XCTestCase {
    func testDecodesRepresentativeAPODPayload() throws {
        let json = """
        [{
          "title": "Earthrise",
          "url": "https://example.com/earth.jpg",
          "hdurl": "https://example.com/earth-hd.jpg",
          "date": "2026-07-21",
          "copyright": "NASA",
          "description": "Earth above the lunar horizon."
        }]
        """.data(using: .utf8)!
        let decoder = JSONDecoder()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        decoder.dateDecodingStrategy = .formatted(formatter)

        let result = try decoder.decode([Astro].self, from: json)

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.title, "Earthrise")
        XCTAssertEqual(result.first?.copyright, "NASA")
        XCTAssertNotNil(result.first?.date)
    }

    func testMalformedPayloadThrows() {
        let json = #"[{"date":"not-a-date"}]"#.data(using: .utf8)!
        let decoder = JSONDecoder()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        decoder.dateDecodingStrategy = .formatted(formatter)

        XCTAssertThrowsError(try decoder.decode([Astro].self, from: json))
    }
}

