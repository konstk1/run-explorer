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

    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let center = CLLocationCoordinate2D(latitude: 42.4176397, longitude: -71.1351914)
        let region = MKCoordinateRegion(center: center, latitudinalMeters: 2000, longitudinalMeters: 2000)
        mapView.setRegion(region, animated: false)
        mapView.delegate = self
        
        guard let url = Bundle.main.url(forResource: "map.osm", withExtension: ".orig") else { fatalError("Failed to get osm file") }
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
        
        let strava = Strava()
        strava.auth(vc: self)
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
}

extension MapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKPolyline {
            let lineRender = MKPolylineRenderer(overlay: overlay)
            lineRender.strokeColor = .red
            lineRender.lineWidth = 3
            lineRender.alpha = 0.2
            return lineRender
        }
        return MKOverlayRenderer()
    }
}