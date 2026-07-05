import unittest

from normalize import normalize, parse_int_tag


def element(tags, osm_type="way", osm_id=1, lat=32.7, lon=-117.1):
    return {"type": osm_type, "id": osm_id, "center": {"lat": lat, "lon": lon}, "tags": tags}


def run(elements, public_only=False):
    return normalize({"elements": elements, "_fairwayiq": {"fetchedAt": "2026-01-01T00:00:00Z"}}, public_only=public_only)


class NoFabricationTests(unittest.TestCase):
    def test_course_without_golf_tags_carries_no_holes_and_null_par(self):
        result = run([element({"name": "Bare Course", "leisure": "golf_course"})])
        self.assertEqual(len(result), 1)
        course = result[0]
        self.assertEqual(course["holes"], [])
        self.assertIsNone(course["coursePar"])
        self.assertIsNone(course["holeCount"])

    def test_no_output_field_ever_defaults_to_par_four(self):
        result = run([element({"name": "Bare Course"})])
        self.assertNotIn("4", str(result[0]["holes"]))

    def test_integer_golf_par_is_carried_through(self):
        result = run([element({"name": "Parkland", "golf:par": "71"})])
        self.assertEqual(result[0]["coursePar"], 71)
        self.assertEqual(result[0]["holes"], [])

    def test_arithmetic_golf_par_stays_null(self):
        result = run([element({"name": "Odd Tagging", "golf:par": "30 + 30 + 30"})])
        self.assertIsNone(result[0]["coursePar"])

    def test_integer_golf_holes_is_carried_through(self):
        result = run([element({"name": "Nine Holer", "golf:holes": "9"})])
        self.assertEqual(result[0]["holeCount"], 9)

    def test_non_numeric_golf_holes_stays_null(self):
        result = run([element({"name": "Vague", "golf:holes": "several"})])
        self.assertIsNone(result[0]["holeCount"])


class ParseIntTagTests(unittest.TestCase):
    def test_plain_integer_string(self):
        self.assertEqual(parse_int_tag({"golf:par": "72"}, "golf:par"), 72)

    def test_integer_value(self):
        self.assertEqual(parse_int_tag({"golf:holes": 18}, "golf:holes"), 18)

    def test_zero_and_negative_stay_null(self):
        self.assertIsNone(parse_int_tag({"golf:par": "0"}, "golf:par"))
        self.assertIsNone(parse_int_tag({"golf:par": -3}, "golf:par"))

    def test_missing_key_stays_null(self):
        self.assertIsNone(parse_int_tag({}, "golf:par"))


class ExistingBehaviorTests(unittest.TestCase):
    def test_unnamed_elements_are_skipped(self):
        result = run([element({"leisure": "golf_course"})])
        self.assertEqual(result, [])

    def test_dedupe_by_name_city_state(self):
        first = element({"name": "Twin Oaks", "addr:city": "Vista", "addr:state": "CA"}, osm_id=1)
        second = element({"name": "Twin Oaks", "addr:city": "Vista", "addr:state": "CA"}, osm_id=2)
        result = run([first, second])
        self.assertEqual(len(result), 1)

    def test_public_only_drops_private_access(self):
        private = element({"name": "Members Only", "access": "private"})
        public = element({"name": "City Course", "access": "yes"}, osm_id=2)
        result = run([private, public], public_only=True)
        self.assertEqual([c["name"] for c in result], ["City Course"])


if __name__ == "__main__":
    unittest.main()
