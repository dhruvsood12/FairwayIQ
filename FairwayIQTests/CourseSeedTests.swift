@testable import FairwayIQ
import Foundation
import Testing

@Suite("CourseSeed Tests")
struct CourseSeedTests {
    @Test("Bundled catalog decodes and carries no fabricated hole data")
    func bundledCatalogIsHonest() throws {
        let url = try #require(Bundle.main.url(forResource: "courses_catalog", withExtension: "json"))
        let data = try Data(contentsOf: url)
        let records = try JSONDecoder().decode([CourseSeedRecord].self, from: data)

        #expect(records.count == 79)
        let allHolesEmpty = records.allSatisfy(\.holes.isEmpty)
        #expect(allHolesEmpty)

        let withSourcePar = records.filter { $0.coursePar != nil }
        #expect(withSourcePar.count == 3)
        #expect(Set(withSourcePar.compactMap(\.coursePar)) == [72, 65, 71])
    }

    @Test("Seed records without the newer keys decode with null par")
    func legacyShapeDecodes() throws {
        let json = """
        [{"id": "osm:way:1", "name": "Legacy", "city": "Vista", "state": "CA",
          "kind": null, "websiteURL": null, "latitude": null, "longitude": null,
          "holes": []}]
        """
        let records = try JSONDecoder().decode([CourseSeedRecord].self, from: Data(json.utf8))
        #expect(records.first?.coursePar == nil)
        #expect(records.first?.holeCount == nil)
    }

    @Test("Starter records with hole detail keep summed par ahead of source par")
    func holeDetailWinsOverSourcePar() {
        let course = Course(id: "test", name: "Detail", sourcePar: 60)
        #expect(course.parIfKnown == 60)

        let hole = Hole(number: 1, par: 3)
        course.holes.append(hole)
        #expect(course.parIfKnown == 3)
    }

    @Test("Par is nil when nothing is known")
    func parNilWhenUnknown() {
        let course = Course(id: "test", name: "Bare")
        #expect(course.parIfKnown == nil)
    }
}
