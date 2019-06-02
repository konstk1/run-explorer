//
//  OsmParser.swift
//  run-explorer
//
//  Created by Konstantin Klitenik on 5/31/19.
//  Copyright © 2019 KK. All rights reserved.
//

import Foundation

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
            guard let id = attributeDict["id"]?.toInt(), let visible = attributeDict["visible"]?.toBool(), let lat = attributeDict["lat"]?.toDouble(), let lon = attributeDict["lon"]?.toDouble() else {
                print("Malformed node: \(attributeDict)")
                return
            }
            currentNode = OsmNode(id: id, visible: visible, lat: lat, lon: lon)
        case "way":
            guard let id = attributeDict["id"]?.toInt(), let visible = attributeDict["visible"]?.toBool() else {
                print("Malformed way: \(attributeDict)")
                return
            }
            
            currentWay = OsmWay(id: id, visible: visible)
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

class OsmNode {
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
        return "Node \(id) (visible: \(visible)) [\(lat),\(lon)] \(tags.reduce("") { $0 + "\n\t\($1.key) = \($1.value)" })"
    }
}

extension OsmWay: CustomStringConvertible {
    var description: String {
        let str = "Way \(id) (visible: \(visible)) \(nodeIds.reduce("") { $0 + "\n\t\($1)" }) \(tags.reduce("") { $0 + "\n\t\($1.key) = \($1.value)" })"
        return str
    }
}

//<node
//    id="61172530"
//    visible="true"
//    version="6"
//    changeset="12071447"
//    timestamp="2012-07-01T01:58:04Z"
//    user="wambag"
//    uid="326503"
//    lat="42.4145691"
//    lon="-71.1322815"
///>

//<way
//    id="94509762"
//    visible="true"
//    version="1"
//    changeset="6934974"
//    timestamp="2011-01-11T10:07:19Z"
//    user="JasonWoof"
//    uid="23351">
//        <nd ref="66473498"/>
//        <nd ref="1097821320"/>
//        <nd ref="1097821341"/>
//        <nd ref="1097821307"/>
//        <nd ref="1097821316"/>
//        <tag k="highway" v="footway"/>
//        <tag k="surface" v="paved"/>
//</way>
