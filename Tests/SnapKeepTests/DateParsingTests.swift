import XCTest
@testable import SnapKeep

final class DateParsingTests: XCTestCase {

    func testParsesISOStyleDate() {
        let date = DateParsing.parseFlexibleDate("2026-01-05")
        XCTAssertNotNil(date)

        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.year, .month, .day], from: date!)
        XCTAssertEqual(components.year, 2026)
        XCTAssertEqual(components.month, 1)
        XCTAssertEqual(components.day, 5)
    }

    func testParsesSlashStyleDate() {
        let date = DateParsing.parseFlexibleDate("2026/03/12")
        XCTAssertNotNil(date)
    }

    func testReturnsNilForEmptyString() {
        XCTAssertNil(DateParsing.parseFlexibleDate(""))
    }

    func testReturnsNilForGarbageString() {
        XCTAssertNil(DateParsing.parseFlexibleDate("not a date at all"))
    }
}
