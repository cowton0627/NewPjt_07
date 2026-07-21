import XCTest
@testable import StellarAPOD

final class AstroDetailViewModelTests: XCTestCase {
    func testDateUsesStableUppercaseDisplayFormat() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(secondsFromGMT: 0))
        let date = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 7, day: 21)))
        let astro = Astro(title: nil, url: nil, hdurl: nil, date: date,
                          copyright: nil, description: nil)

        let result = AstroDetailViewModel(astro: astro).dateAttributedText()

        XCTAssertEqual(result.string, "2026 JUL. 21")
        XCTAssertEqual(result.attribute(.kern, at: 0, effectiveRange: nil) as? Double, 1.5)
    }

    func testMissingDateDisplaysPlaceholder() {
        let astro = Astro(title: nil, url: nil, hdurl: nil, date: nil,
                          copyright: nil, description: nil)

        let result = AstroDetailViewModel(astro: astro).dateAttributedText()

        XCTAssertEqual(result.string, "—")
    }
}
