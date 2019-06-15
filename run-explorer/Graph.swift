//
//  Graph.swift
//  run-explorer
//
//  Created by Konstantin Klitenik on 6/13/19.
//  Copyright © 2019 KK. All rights reserved.
//

import Foundation
import CoreLocation

final class Graph<T: Hashable> {
    private var adjecencyList: [Vertex<T>: Set<Edge<T>>] = [:]

    private(set) var originVertex: Vertex<T>?
    
    typealias sptVertexState = (distance: Double, prev: Vertex<T>?)
    private var spt: [Vertex<T>: sptVertexState]?
    
    var verticies: [Vertex<T>] {
        return Array(adjecencyList.keys)
    }
    
    var edgeCount: Int {
        adjecencyList.reduce(0) {
            return $0 + $1.value.count
        }
    }
    
    func edges(from source: Vertex<T>) -> [Edge<T>] {
        guard let edges = adjecencyList[source] else { return [] }
        return Array(edges)
    }
    
    func add(vertex: Vertex<T>) {
        guard adjecencyList[vertex] == nil else { return }  // do nothing if vertex exists
        adjecencyList[vertex] = []  // if doesn't exist, init with no edges
    }
    
    func remove(vertex: Vertex<T>) {
        // remove vertex from graph
        adjecencyList.removeValue(forKey: vertex)
        
        // remove any edges to this vertex
        adjecencyList.forEach { (arg) in
            var (_, edge) = arg
            if let edgeToRemove = edge.first(where: { $0.destination == vertex }) {
                edge.remove(edgeToRemove)
            }
        }
    }
    
    func addDirectedEdge(from source: Vertex<T>, to destination: Vertex<T>, weight: Double) {
        let edge = Edge(source: source, destination: destination, weight: weight)
        
        if adjecencyList[source] == nil {
            adjecencyList[source] = [edge]
        } else {
            adjecencyList[source]?.update(with: edge)
        }
    }
    
    func addUndirectedEdge(from source: Vertex<T>, to destination: Vertex<T>, weight: Double) {
        addDirectedEdge(from: source, to: destination, weight: weight)
        addDirectedEdge(from: destination, to: source, weight: weight)
    }
    
    func traverseDirected(from source: Vertex<T>, to destination: Vertex<T>) {
        guard let edge = adjecencyList[source]?.first(where: { $0.destination == destination }) else { return }
        edge.traversed = true
    }
    
    func traverseUndirected(from source: Vertex<T>, to destination: Vertex<T>) {
        traverseDirected(from: source, to: destination)
        traverseDirected(from: destination, to: source)
    }
    
    func untraverseAll() {
        adjecencyList.forEach { vertex, edgeSet in
            edgeSet.forEach { edge in
                edge.traversed = false
            }
        }
    }
    
    /// Compute shortest path tree from specified source using Dikjstra
    private func computeShortestPathTree(source: Vertex<T>) {
        // shortest path tree
        spt = Dictionary(minimumCapacity: adjecencyList.count)
        
        var unvisitted = Set<Vertex<T>>()
        
        for vertex in adjecencyList.keys {
            spt![vertex] = (Double.infinity, nil)
            unvisitted.insert(vertex)
        }
        spt![source] = (0, nil)
        
        while let vertex = unvisitted.min(by: { spt![$0]!.distance < spt![$1]!.distance }) {
            guard let edges = adjecencyList[vertex] else { print("No edges for \(vertex)"); return }
                
            for edge in edges {
                let alt = spt![vertex]!.distance + edge.weight
                if let (currentDistance, _) = spt![edge.destination], unvisitted.contains(edge.destination) && alt < currentDistance {
                    spt![edge.destination] = (alt, vertex)
                }
            }
                
            unvisitted.remove(vertex)
            print("SPT univisitted \(unvisitted.count)")
        }
        
//        for entry in spt! {
//            print("\(entry.key): \(entry.value.distance)")
//        }
    }
    
    func shortestPathFromOrigin(to destination: Vertex<T>) -> [Vertex<T>] {
        guard let origin = originVertex else {
            print("Origin is unset")
            return []
        }
        
        if spt == nil {
            print("Calculating SPT...")
            computeShortestPathTree(source: origin)
        }
        
        // build path by traversing backwards through SPT
        var shortestPath = [destination]
        
        var vertex: Vertex? = destination
        while let sv = spt?[vertex!]?.prev {
            shortestPath.append(sv)
            vertex = sv
        }
        
        guard shortestPath.last == originVertex else {
            return []
        }
        
        // reverse the path to get path from origin to destination
        return shortestPath.reversed()
    }
    
    func setOrigin(vertex: Vertex<T>) {
        guard originVertex != vertex else { return }  // nothing to do if origin hasn't changed
        
        // if new origin, save it and clear shortest path tree
        originVertex = vertex
        spt = nil
    }
    
    // 1.5mi = 2414.016m
    func clampToMaxDistance(from location: CLLocation, distance maxDistance: CLLocationDistance) {
        // find vertex nearest to center
        let origin = adjecencyList.keys.min { v1, v2 in
            guard let v1 = v1 as? Vertex<OsmNode>, let v2 = v2 as? Vertex<OsmNode> else { return false }
            return location.distance(from: CLLocation(latitude: v1.data.lat, longitude: v1.data.lon)) < location.distance(from: CLLocation(latitude: v2.data.lat, longitude: v2.data.lon))
        }
        
        print("Setting origin: \(origin!)")
        setOrigin(vertex: origin!)
        
        computeShortestPathTree(source: origin!)
        print("SPT ready")
        
        var numRemoved = 0
        
        for (vertex, state) in spt! {
            print("Processing \((vertex.data as! OsmNode).id)")
            if state.distance > maxDistance {
                remove(vertex: vertex)
                numRemoved += 1
            }
        }
        
        print("Removed \(numRemoved) vertecies")

//        for vertex in adjecencyList.keys {
//            var distanceToCenter: CLLocationDistance = 0
//
//            if let v = vertex as? Vertex<OsmNode> {
//                distanceToCenter = center.distance(from: CLLocation(latitude: v.data.lat, longitude: v.data.lon))
//            }
//
//            print("Processing \(vertex.data) [\(distanceToCenter)]")
//
//            if distanceToCenter > radius {
//                remove(vertex: vertex)
//            }
//        }
    }
    
    func printGraph() {
        var numEdges = 0
        for (vertex, edges) in adjecencyList {
            var edgeStr = "\(vertex):"
            for edge in edges {
                edgeStr += " \(edge.destination)(\(edge.weight))"
                numEdges += 1
            }
            print(edgeStr)
        }
        print("Summary: \(adjecencyList.count) nodes \(numEdges) edges")
    }
}

class Vertex<T: Hashable>: Hashable, CustomStringConvertible {
    let data: T
    
    init(data: T) {
        self.data = data
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(data.hashValue)
    }
    
    static func ==(lhs: Vertex, rhs: Vertex) -> Bool {
        return lhs.data == rhs.data
    }
    
    var description: String {
        return "\(data)"
    }
}

class Edge<T: Hashable>: Hashable {
    var source: Vertex<T>
    var destination: Vertex<T>
    var weight: Double
    var traversed = false
    
    init(source: Vertex<T>, destination: Vertex<T>, weight: Double) {
        self.source = source
        self.destination = destination
        self.weight = weight
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(source)
        hasher.combine(destination)
    }
    
    static func ==(lhs: Edge, rhs: Edge) -> Bool {
        return lhs.source == rhs.source && lhs.destination == rhs.destination
    }
}

extension Array where Element:CustomStringConvertible {
    func printPath() {
        var path = ""
        for (idx, v) in self.enumerated() {
            if idx == 0 {
                path += "[\(v)] -> "
            } else if idx == self.count - 1 {
                path += "[\(v)]"
            } else {
                path += "\(v) -> "
            }
        }
        print(path)
    }
}
