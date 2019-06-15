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
        return;     // while testing

        let center = CLLocation(latitude: 42.412060, longitude: -71.142201)
        let region = MKCoordinateRegion(center: center.coordinate, latitudinalMeters: 5000, longitudinalMeters: 5000)
        mapView.setRegion(region, animated: false)
        mapView.delegate = self
        
        guard let url = Bundle.main.url(forResource: "arlington", withExtension: "osm") else { fatalError("Failed to get osm file") }
        osm = OsmParser(contentsOf: url)
        print("OSM: \(osm.ways.count) ways \(osm.nodes.count) nodes")
        let graph = osm.buildGraph()
        print("Graph: \(graph.edgeCount) edges \(graph.verticies.count) nodes")
        graph.clampToMaxDistance(from: center, distance: 2415)
       
        if let origin = graph.originVertex {
            let home = MKPointAnnotation()
            home.coordinate = CLLocationCoordinate2D(latitude: origin.data.lat, longitude: origin.data.lon)
            mapView.addAnnotation(home)
        }
        
        let lines = generateLines(from: graph)
//        let lines = generateLines(from: osm)

        mapView.addOverlays(lines)
        print("Added \(lines.count) lines and \(osm!.nodes.count) nodes")
        
        strava = Strava()
        strava.auth()
        activities = strava.loadStreamsFromDisk()?.sorted{ $0.startDate < $1.startDate }
        plotActivities(activities: activities!)
        
        let startDate = activities?.last?.startDate
        strava.getActivities(after: startDate, perPage: 100)
    }
    
    func generateLines(from osm: OsmParser) -> [MKPolyline] {
        let lines = osm.ways.map { way -> MKPolyline in
            let coords = way.nodeIds.map({ nodeId -> CLLocationCoordinate2D? in
                guard let node = osm.nodes[nodeId] else { print("Node \(nodeId) not found"); return nil }
                return CLLocationCoordinate2D(latitude: node.lat, longitude: node.lon)
            }).compactMap { $0 }
            let line = MKPolyline(coordinates: coords, count: coords.count)
            return line
        }
        
        return lines
    }
    
    func generateLines(from graph: Graph<OsmNode>) -> [MKPolyline] {
        var lines: [MKPolyline] = []
        for vertex in graph.verticies {
            while case let path = buildPath(in: graph, from: vertex), path.count > 1 {
                let coords = path.map { CLLocationCoordinate2D(latitude: $0.data.lat, longitude: $0.data.lon) }
                lines.append(MKPolyline(coordinates: coords, count: coords.count))
            }
        }
        
        return lines
    }
    
    func buildPath(in graph: Graph<OsmNode>, from source: Vertex<OsmNode>) -> [Vertex<OsmNode>] {
        // find first unvisitted edge and traverse it
        let path = [source]
        
        for edge in graph.edges(from: source) {
            if !edge.traversed {
                graph.traverseUndirected(from: source, to: edge.destination)
                return path + buildPath(in: graph, from: edge.destination)
            }
        }
        
        return path
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
