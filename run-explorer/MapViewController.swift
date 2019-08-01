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
    var graph: Graph<OsmNode>!
    var strava: Strava!
    var activities: [ActivityStream]?
    var activityOverlays = Set<MKPolyline>()
    var selectedOverlay: MKOverlay?
    
    let center = CLLocation(latitude: 42.412060, longitude: -71.142201)

    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var distanceLabel: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        return;     // while testing

        mapView.delegate = self
        let tapRecog = NSPressGestureRecognizer(target: self, action: #selector(self.pressed(gestureRecognizer:)))
        tapRecog.minimumPressDuration = 1
        mapView.addGestureRecognizer(tapRecog)
        
        guard let url = Bundle.main.url(forResource: "arlington", withExtension: "osm") else { fatalError("Failed to get osm file") }
        osm = OsmParser(contentsOf: url)
        print("OSM: \(osm.ways.count) ways \(osm.nodes.count) nodes")
        graph = osm.buildGraph()
        print("Graph: \(graph.edgeCount) edges \(graph.verticies.count) nodes")
        // 1.5mi = 2415m, 1.25mi = 2012m
        graph.clampToMaxDistance(from: center, distance: 2415)
       
        if let origin = graph.originVertex {
            let home = MKPointAnnotation()
            home.coordinate = CLLocationCoordinate2D(latitude: origin.data.lat, longitude: origin.data.lon)
            home.title = "Home"
            mapView.addAnnotation(home)
        }
        
        let lines = generateLines(from: graph)
//        let lines = generateLines(from: osm)

        mapView.addOverlays(lines)
        print("Added \(lines.count) lines and \(graph.verticies.count) nodes")
        
        strava = Strava()
        strava.auth()
        
        refreshStravaActivities()
    }
    
    override func viewDidAppear() {
        print("Window \(mapView.frame)")
        let region = MKCoordinateRegion(center: center.coordinate, latitudinalMeters: 5000, longitudinalMeters: 5000)
        mapView.setRegion(region, animated: false)
    }
    
    func refreshStravaActivities() {
        print("Window \(mapView.frame)")
        activities = strava.loadStreamsFromDisk()?.sorted{ $0.startDate < $1.startDate }
        plotActivities(activities: activities!)
        
        let startDate = activities?.last?.startDate
        strava.getActivities(after: startDate, perPage: 100) { [weak self] result in
            switch result {
            case .success(let numActivities):
                print("Refreshed \(numActivities) activities")
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                }
            case .failure(let error):
                print("Failed to refresh Strava activities: \(error)")
            }
        }
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
            while case let path = buildPath(from: vertex), path.count > 1 {
                let coords = path.map { CLLocationCoordinate2D(latitude: $0.data.lat, longitude: $0.data.lon) }
                lines.append(MKPolyline(coordinates: coords, count: coords.count))
            }
        }
        
        return lines
    }
    
    func nearestVertex(to location: CLLocation) -> Vertex<OsmNode>? {
        return graph.verticies.min { (v1, v2) -> Bool in
            return location.distance(from: CLLocation(latitude: v1.data.lat, longitude: v1.data.lon)) <
                   location.distance(from: CLLocation(latitude: v2.data.lat, longitude: v2.data.lon))
        }
    }
    
    func buildPath(from source: Vertex<OsmNode>) -> [Vertex<OsmNode>] {
        // find first unvisitted edge and traverse it
        let path = [source]
        
        for edge in graph.edges(from: source) {
            if !edge.traversed {
                graph.traverseUndirected(from: source, to: edge.destination)
                return path + buildPath(from: edge.destination)
            }
        }
        
        return path
    }
    
    func plotActivities(activities: [ActivityStream]) {
        // remove existing strava activity overlays
        mapView.removeOverlays(Array(activityOverlays))
        
        // add strava activity overlays
        let lines = activities.map { MKPolyline(coordinates: $0.coords, count: $0.coords.count) }
        activityOverlays = Set<MKPolyline>(lines)
        mapView.addOverlays(lines);
    }
    
    func highlightActivity(activity: ActivityStream) {
        let line = MKPolyline(coordinates: activity.coords, count: activity.coords.count)
        
        addHighlightedOverlay(overlay: line)
    }
    
    func addHighlightedOverlay(overlay: MKOverlay) {
        if let selectedOverlay = selectedOverlay {
            mapView.removeOverlay(selectedOverlay)
        }
        
        selectedOverlay = overlay
        mapView.addOverlay(overlay)
    }
    
    @objc func pressed(gestureRecognizer: NSGestureRecognizer) {
        if gestureRecognizer.state == .began {
            let point = gestureRecognizer.location(in: mapView)
            let coord = mapView.convert(point, toCoordinateFrom: mapView)
            print("Pressed \(coord)")
            if let vertex = nearestVertex(to: CLLocation(latitude: coord.latitude, longitude: coord.longitude)) {
                print("Found vertex \(vertex)")
                let path = graph.shortestPathFromOrigin(to: vertex)
                let coords = path.map { CLLocationCoordinate2D(latitude: $0.data.lat, longitude: $0.data.lon) }
                let line = MKPolyline(coordinates: coords, count: coords.count)
                addHighlightedOverlay(overlay: line)
                
                // update distance label
                let distanceMi = graph.shortestDistanceFromOrigin(to: vertex).metersToMiles()
                print("Distance \(distanceMi) mi")
                distanceLabel.stringValue = String(format: "%.2f mi", distanceMi)
            }
        }
    }
    
    @IBAction func refreshPressed(_ sender: NSButton) {
        refreshStravaActivities()
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
              let activity = activities?[tableView.selectedRow] else {
                // if nothing is selected, clear out selected overlay
                if let selectedOverlay = selectedOverlay {
                    mapView.removeOverlay(selectedOverlay)
                }
                return
        }
        
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
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard annotation is MKPointAnnotation else { return nil }
        
        let identifier = "Annotation"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
        
        if annotationView == nil {
            annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView!.canShowCallout = true
        } else {
            annotationView!.annotation = annotation
        }
        
        return annotationView
    }
}

class MapWindowController: NSWindowController {
    override func windowDidLoad() {
        super.windowDidLoad()
        
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
        self.windowFrameAutosaveName = NSWindow.FrameAutosaveName(stringLiteral: "position")
    }
}
