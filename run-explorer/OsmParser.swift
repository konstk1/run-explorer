//
//  OsmParser.swift
//  run-explorer
//
//  Created by Konstantin Klitenik on 5/31/19.
//  Copyright © 2019 KK. All rights reserved.
//

import Foundation
import CoreLocation

final class OsmParser: NSObject {
    var nodes = Dictionary<Int, OsmNode>()
    var ways = Array<OsmWay>()
    
    fileprivate var currentNode: OsmNode?
    fileprivate var currentWay: OsmWay?
    
    fileprivate let group = DispatchGroup()
    
    init(contentsOf url: URL) {
        super.init()
        guard let parser = XMLParser(contentsOf: url) else { fatalError("Failed to create XMLParser"); }
        parser.delegate = self
        print("OSM Parsing...")
        group.enter()
        parser.parse()
        group.wait()
        print("OSM Done")
    }
    
    func buildGraph() -> Graph<OsmNode> {
        let graph = Graph<OsmNode>()
        
        for way in ways {
            for (i, nodeId) in way.nodeIds[0..<way.nodeIds.count - 1].enumerated() {
                guard let source = nodes[nodeId],
                      let destination = nodes[way.nodeIds[i+1]] else { continue }
                let c1 = CLLocation(latitude: source.lat, longitude: source.lon)
                let c2 = CLLocation(latitude: destination.lat, longitude: destination.lon)
                let distance = c1.distance(from: c2)
                graph.addUndirectedEdge(from: Vertex(data: source), to: Vertex(data: destination), weight: distance)
            }
        }
        
        return graph
    }
}

extension OsmParser: XMLParserDelegate {
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        print(parseError)
    }
    
    func parserDidStartDocument(_ parser: XMLParser) {
        print("Started document")
    }
    
    func parserDidEndDocument(_ parser: XMLParser) {
        print("Ended document")
        group.leave()
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
//        print("started el: \(elementName)")
//        print("attr: \(attributeDict)")
        switch elementName {
        case "node":
            guard let id = attributeDict["id"]?.toInt(), let lat = attributeDict["lat"]?.toDouble(), let lon = attributeDict["lon"]?.toDouble() else {
                print("Malformed node: \(attributeDict)")
                return
            }
            currentNode = OsmNode(id: id, visible: true, lat: lat, lon: lon)
        case "way":
            guard let id = attributeDict["id"]?.toInt() else {
                print("Malformed way: \(attributeDict)")
                return
            }
            
            currentWay = OsmWay(id: id, visible: true)
            break
        case "nd": // node reference in way element
            guard let currentWay = currentWay else { fatalError("Expected current way") }
            guard let nodeId = attributeDict["ref"]?.toInt() else { return }
            currentWay.nodeIds.append(nodeId)
        case "tag":
            guard let key = attributeDict["k"], let value = attributeDict["v"] else {
                print("Malformed tag")
                return
            }
            
            if currentNode != nil {
                currentNode?.tags[key] = value
            } else if currentWay != nil {
                currentWay?.tags[key] = value
            }
            break
        default:
            break
        }
        
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
//        print("ended el")
        switch elementName {
        case "node":
            defer { currentNode = nil } // reset current node
            guard let node = currentNode else { fatalError("Current node expected") }
            
            // filter out certain types of nodes with these tags
            let ignoreTags = ["surveillance", "addr:street"]
            let ignoredTags = node.tags.keys.filter { ignoreTags.contains($0) }
            guard ignoredTags.count == 0 else { return }
            
            nodes[node.id] = node
//            print(node)
        case "way":
            defer { currentWay = nil }  // reset current way
            guard let way = currentWay else { fatalError("Current way expected") }
            // only add ways that are highways (roads)
            guard let _ = way.tags["highway"] else { return }
            ways.append(way)
//            print(way)
        default:
            break
        }
    }
}

class OsmNode: Hashable {
    let id: Int
    let visible: Bool
    let lat: Double
    let lon: Double
    var tags = Dictionary<String, String>()
    
    init(id: Int, visible: Bool, lat: Double, lon: Double) {
        self.id = id
        self.visible = visible
        self.lat = lat
        self.lon = lon
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(lat)
        hasher.combine(lon)
    }
    
    static func ==(lhs: OsmNode, rhs: OsmNode) -> Bool {
        return lhs.id == rhs.id && lhs.lat == rhs.lat && lhs.lon == lhs.lon
    }
}

class OsmWay {
    let id: Int
    let visible: Bool
    var nodeIds = Array<Int>()
    var tags = Dictionary<String, String>()
    
    init(id: Int, visible: Bool) {
        self.id = id
        self.visible = visible
    }
}

extension OsmNode: CustomStringConvertible {
    var description: String {
        return "\(id) (\(lat),\(lon))"
    }
}

extension OsmWay: CustomStringConvertible {
    var description: String {
        let str = "Way \(id) (visible: \(visible)) \(nodeIds.reduce("") { $0 + "\n\t\($1)" }) \(tags.reduce("") { $0 + "\n\t\($1.key) = \($1.value)" })"
        return str
    }
}

