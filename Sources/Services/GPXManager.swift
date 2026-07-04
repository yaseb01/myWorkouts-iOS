import Foundation
import CoreLocation

struct GPXManager {

    // MARK: - Export

    static func exportWorkout(_ workout: Workout) -> Data? {
        guard !workout.trackPoints.isEmpty else { return nil }

        var gpx = """
        <?xml version="1.0" encoding="UTF-8"?>
        <gpx version="1.1" creator="myWorkouts"
             xmlns="http://www.topografix.com/GPX/1/1"
             xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
             xsi:schemaLocation="http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd">
          <metadata>
            <name>\(workout.sportType?.name ?? "Workout") - \(workout.startTime.formatted(date: .abbreviated, time: .shortened))</name>
            <time>\(workout.startTime.ISO8601Format())</time>
          </metadata>
          <trk>
            <name>\(workout.sportType?.name ?? "Workout")</name>
            <type>\(workout.sportType?.abbreviation ?? "WORKOUT")</type>
            <trkseg>
        """

        for point in workout.trackPoints {
            gpx += "\n              <trkpt lat=\"\(point.latitude)\" lon=\"\(point.longitude)\">"
            if let alt = point.altitude {
                gpx += "\n                <ele>\(alt)</ele>"
            }
            gpx += "\n                <time>\(point.timestamp.ISO8601Format())</time>"
            gpx += "\n              </trkpt>"
        }

        gpx += """
        \n            </trkseg>
          </trk>
        </gpx>
        """

        return gpx.data(using: .utf8)
    }

    // MARK: - Import

    static func importGPX(from data: Data) -> GPXData? {
        guard let parser = GPXParser(data: data) else { return nil }
        return parser.parse()
    }
}

// MARK: - GPX Data Structure

struct GPXData {
    let name: String?
    let trackPoints: [GPXTrackPoint]

    struct GPXTrackPoint {
        let latitude: Double
        let longitude: Double
        let altitude: Double?
        let timestamp: Date?
    }
}

// MARK: - GPX Parser

private class GPXParser: NSObject, XMLParserDelegate {
    private var trackPoints: [GPXData.GPXTrackPoint] = []
    private var currentElement = ""
    private var currentLat: Double = 0
    private var currentLon: Double = 0
    private var currentAlt: Double?
    private var currentTime: Date?
    private var trackName: String?
    private var elementText = ""
    private let data: Data

    init?(data: Data) {
        self.data = data
        super.init()
    }

    func parse() -> GPXData? {
        let parser = XMLParser(data: data)
        parser.delegate = self
        guard parser.parse() else { return nil }
        return GPXData(name: trackName, trackPoints: trackPoints)
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?,
                attributes attributeDict: [String: String] = [:]) {
        currentElement = elementName
        elementText = ""

        if elementName == "trkpt" {
            if let lat = Double(attributeDict["lat"] ?? ""),
               let lon = Double(attributeDict["lon"] ?? "") {
                currentLat = lat
                currentLon = lon
                currentAlt = nil
                currentTime = nil
            }
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        elementText += string
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?) {
        switch elementName {
        case "ele":
            currentAlt = Double(elementText.trimmingCharacters(in: .whitespacesAndNewlines))
        case "time":
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            currentTime = formatter.date(from: elementText.trimmingCharacters(in: .whitespacesAndNewlines))
            if currentTime == nil {
                formatter.formatOptions = [.withInternetDateTime]
                currentTime = formatter.date(from: elementText.trimmingCharacters(in: .whitespacesAndNewlines))
            }
        case "name":
            if trackName == nil {
                trackName = elementText.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        case "trkpt":
            let point = GPXData.GPXTrackPoint(
                latitude: currentLat,
                longitude: currentLon,
                altitude: currentAlt,
                timestamp: currentTime
            )
            trackPoints.append(point)
        default:
            break
        }
    }
}
