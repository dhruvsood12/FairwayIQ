import CoreLocation

public enum GeoMath {
    /// Geodesic distance between two coordinates in yards, or nil when any
    /// coordinate component is missing. Matches the app's shot-entry math:
    /// CLLocation meters divided by 0.9144.
    public static func distanceYards(
        fromLatitude: Double?,
        fromLongitude: Double?,
        toLatitude: Double?,
        toLongitude: Double?
    ) -> Double? {
        guard
            let fromLatitude,
            let fromLongitude,
            let toLatitude,
            let toLongitude
        else {
            return nil
        }
        let start = CLLocation(latitude: fromLatitude, longitude: fromLongitude)
        let end = CLLocation(latitude: toLatitude, longitude: toLongitude)
        return start.distance(from: end) / 0.9144
    }
}
