@testable import FairwayIQCore
import XCTest

final class GeoMathTests: XCTestCase {
    func testSamePointIsZeroYards() {
        let yards = GeoMath.distanceYards(
            fromLatitude: 37.0,
            fromLongitude: -122.0,
            toLatitude: 37.0,
            toLongitude: -122.0
        )
        XCTAssertEqual(yards, 0.0)
    }

    func testKnownLatitudeSpanConvertsToYards() throws {
        let yards = GeoMath.distanceYards(
            fromLatitude: 0.0,
            fromLongitude: 0.0,
            toLatitude: 0.001,
            toLongitude: 0.0
        )
        let unwrapped = try XCTUnwrap(yards)
        XCTAssertEqual(unwrapped, 110.574 / 0.9144, accuracy: 2.0)
    }

    func testDriveLengthSpanIsPlausible() throws {
        let yards = GeoMath.distanceYards(
            fromLatitude: 37.0,
            fromLongitude: -122.0,
            toLatitude: 37.002,
            toLongitude: -122.0
        )
        let unwrapped = try XCTUnwrap(yards)
        XCTAssertEqual(unwrapped, 222.3 / 0.9144, accuracy: 3.0)
    }

    func testMissingCoordinateReturnsNil() {
        XCTAssertNil(GeoMath.distanceYards(fromLatitude: nil, fromLongitude: 0, toLatitude: 1, toLongitude: 1))
        XCTAssertNil(GeoMath.distanceYards(fromLatitude: 0, fromLongitude: nil, toLatitude: 1, toLongitude: 1))
        XCTAssertNil(GeoMath.distanceYards(fromLatitude: 0, fromLongitude: 0, toLatitude: nil, toLongitude: 1))
        XCTAssertNil(GeoMath.distanceYards(fromLatitude: 0, fromLongitude: 0, toLatitude: 1, toLongitude: nil))
    }
}
