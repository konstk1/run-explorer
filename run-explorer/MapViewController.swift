//
//  MapViewController.swift
//  run-explorer
//
//  Created by Konstantin Klitenik on 5/31/19.
//  Copyright © 2019 KK. All rights reserved.
//

import Cocoa
import MapKit

class MapViewController: NSViewController {
    
    var osm: OsmParser!
    var strava: Strava!
    var activities: [ActivityStream]?
    var activityOverlays = Set<MKPolyline>()
    var selectedOverlay: MKOverlay?

    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let center = CLLocationCoordinate2D(latitude: 42.4176397, longitude: -71.1351914)
        let region = MKCoordinateRegion(center: center, latitudinalMeters: 2000, longitudinalMeters: 2000)
        mapView.setRegion(region, animated: false)
        mapView.delegate = self
        
        guard let url = Bundle.main.url(forResource: "arlington", withExtension: "osm") else { fatalError("Failed to get osm file") }
        osm = OsmParser(contentsOf: url)
        
        let lines = osm.ways.map { way -> MKPolyline in
            let coords = way.nodeIds.map({ nodeId -> CLLocationCoordinate2D? in
                guard let node = osm?.nodes[nodeId] else { print("Node \(nodeId) not found"); return nil }
                return CLLocationCoordinate2D(latitude: node.lat, longitude: node.lon)
            }).compactMap { $0 }
            let line = MKPolyline(coordinates: coords, count: coords.count)
            line.title = "test"
            return line
        }

        mapView.addOverlays(lines)
        print("Added \(lines.count) lines")
        
        strava = Strava()
        strava.auth()
        activities = strava.loadStreamsFromDisk()?.sorted{ $0.startDate < $1.startDate }
        plotActivities(activities: activities!)
        
        let startDate = activities?.last?.startDate
        strava.getActivities(after: startDate, perPage: 100)
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    func plotActivities(activities: [ActivityStream]) {
        let lines = activities.map { MKPolyline(coordinates: $0.coords, count: $0.coords.count) }
        activityOverlays = Set<MKPolyline>(lines)
        mapView.addOverlays(lines);
    }
    
    func highlightActivity(activity: ActivityStream) {
        let line = MKPolyline(coordinates: activity.coords, count: activity.coords.count)
        
        if let overlay = selectedOverlay {
            mapView.removeOverlay(overlay)
        }
        
        selectedOverlay = line
        mapView.addOverlay(line)
    }
}

extension MapViewController: NSTableViewDataSource, NSTableViewDelegate {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return activities?.count ?? 0
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "RunCell"), owner: self) as? NSTableCellView else {
            return nil
        }
        
        guard let activity = activities?[row] else { return nil }
        
        let dateStr = DateFormatter.localizedString(from: activity.startDate, dateStyle: .short, timeStyle: .none)
        cell.textField?.stringValue = "\(dateStr) - \(activities![row].activityId)"
        
        return cell
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        guard let tableView = notification.object as? NSTableView, tableView.selectedRow >= 0,
              let activity = activities?[tableView.selectedRow] else { return }
        
        highlightActivity(activity: activity)
        mapView.centerCoordinate = activity.coords.first!
    }
}

extension MapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let overlay = overlay as? MKPolyline {
            let lineRender = MKPolylineRenderer(overlay: overlay)
            lineRender.strokeColor = .red
            lineRender.alpha = 0.2
            lineRender.lineWidth = 3
            
            if let selectedOverlay = selectedOverlay, overlay == selectedOverlay as? MKPolyline {
                lineRender.strokeColor = .green
                lineRender.alpha = 0.8
            }
            
            if activityOverlays.contains(overlay) {
                lineRender.strokeColor = .blue
                lineRender.alpha = 0.6
            }
            
            return lineRender
        }
        return MKOverlayRenderer()
    }
}
