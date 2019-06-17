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
    private var adjacencyList: [Vertex<T>: Set<Edge<T>>] = [:]

    private(set) var originVertex: Vertex<T>?
    
    typealias sptVertexState = (distance: Double, prev: Vertex<T>?)
    private var spt: [Vertex<T>: sptVertexState] = [:]
    
    var verticies: [Vertex<T>] {
        return Array(adjacencyList.keys)
    }
    
    var edgeCount: Int {
        adjacencyList.reduce(0) {
            return $0 + $1.value.count
        }
    }
    
    func edges(from source: Vertex<T>) -> [Edge<T>] {
        guard let edges = adjacencyList[source] else { return [] }
        return Array(edges)
    }
    
    func add(vertex: Vertex<T>) {
        guard adjacencyList[vertex] == nil else { return }  // do nothing if vertex exists
        adjacencyList[vertex] = []  // if doesn't exist, init with no edges
        resetSpt()
    }
    
    /// removes vertex from graph and any associated edges
    /// warning: assumes all edges is undirected to avoid iterating through every edge
    func remove(vertex: Vertex<T>) {
        // remove vertex from graph
        if let edges = adjacencyList[vertex] {
            for edge in edges {
                if let edgeToRemove = adjacencyList[edge.destination]?.first(where: { $0.destination == vertex }) {
                    adjacencyList[edge.destination]?.remove(edgeToRemove)
                }
            }
        }
        
        adjacencyList.removeValue(forKey: vertex)
        resetSpt()
    }
    
    func addDirectedEdge(from source: Vertex<T>, to destination: Vertex<T>, weight: Double) {
        let edge = Edge(source: source, destination: destination, weight: weight)
        
        if adjacencyList[source] == nil {
            adjacencyList[source] = [edge]
        } else {
            adjacencyList[source]?.update(with: edge)
        }
        
        resetSpt()
    }
    
    func addUndirectedEdge(from source: Vertex<T>, to destination: Vertex<T>, weight: Double) {
        addDirectedEdge(from: source, to: destination, weight: weight)
        addDirectedEdge(from: destination, to: source, weight: weight)
    }
    
    func traverseDirected(from source: Vertex<T>, to destination: Vertex<T>) {
        guard let edge = adjacencyList[source]?.first(where: { $0.destination == destination }) else { return }
        edge.traversed = true
    }
    
    func traverseUndirected(from source: Vertex<T>, to destination: Vertex<T>) {
        traverseDirected(from: source, to: destination)
        traverseDirected(from: destination, to: source)
    }
    
    func untraverseAll() {
        adjacencyList.forEach { vertex, edgeSet in
            edgeSet.forEach { edge in
                edge.traversed = false
            }
        }
    }
    
    private func resetSpt() {
        spt = [:]
        spt.reserveCapacity(adjacencyList.count)
    }
    
    /// Compute shortest path tree from specified source using Dikjstra
    internal func computeShortestPathTree(source: Vertex<T>) {
        // shortest path tree
        resetSpt()
        
        var visitted = Set<Vertex<T>>(minimumCapacity: adjacencyList.count)
        
        for vertex in adjacencyList.keys {
            spt[vertex] = (Double.infinity, nil)
//            unvisitted.insert(vertex)
        }
        spt[source] = (0, nil)
        
        let minQ = PriorityQueue<(Vertex<T>, Double)>(sort: { return $0.1 < $1.1 })
        minQ.enqueue(element: (source, 0))
        
        while let (vertex, _) = minQ.dequeue() {
            guard !visitted.contains(vertex) else { continue }      // if node has been visitted, skip it and go to next
            guard let edges = adjacencyList[vertex] else { print("No edges for \(vertex)"); return }
                
            for edge in edges {
                let alt = spt[vertex]!.distance + edge.weight
                if let (currentDistance, _) = spt[edge.destination], !visitted.contains(edge.destination) && alt < currentDistance {
                    spt[edge.destination] = (alt, vertex)
                    minQ.enqueue(element: (edge.destination, alt))
                }
            }
            
            visitted.insert(vertex)
//            print("SPT visitted \(visitted.count)")
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
        
        // re-calc SPT if number of verticies doesn't match
        if spt.count == 0 {
            print("Calculating SPT...")
            computeShortestPathTree(source: origin)
        }
        
        // build path by traversing backwards through SPT
        var shortestPath = [destination]
        
        var vertex: Vertex? = destination
        while let sv = spt[vertex!]?.prev {
            shortestPath.append(sv)
            vertex = sv
        }
        
        guard shortestPath.last == originVertex else {
            return []
        }
        
        // reverse the path to get path from origin to destination
        return shortestPath.reversed()
    }
    
    func shortestDistanceFromOrigin(to destination: Vertex<T>) -> Double {
        guard let state = spt[destination] else { return .infinity }
        return state.distance
    }
    
    func setOrigin(vertex: Vertex<T>) {
        guard originVertex != vertex else { return }  // nothing to do if origin hasn't changed
        
        // if new origin, save it and clear shortest path tree
        originVertex = vertex
        spt.removeAll()
    }
    
    // 1.5mi = 2414.016m
    func clampToMaxDistance(from location: CLLocation, distance maxDistance: CLLocationDistance) {
        // find vertex nearest to center
        let origin = adjacencyList.keys.min { v1, v2 in
            guard let v1 = v1 as? Vertex<OsmNode>, let v2 = v2 as? Vertex<OsmNode> else { return false }
            return location.distance(from: CLLocation(latitude: v1.data.lat, longitude: v1.data.lon)) < location.distance(from: CLLocation(latitude: v2.data.lat, longitude: v2.data.lon))
        }
        
        print("Setting origin: \(origin!)")
        setOrigin(vertex: origin!)
        
        computeShortestPathTree(source: origin!)
        print("SPT ready")
        
        var numRemoved = 0
        
        for (vertex, state) in spt {
            if state.distance > maxDistance {
                remove(vertex: vertex)
                numRemoved += 1
            }
        }
        
        print("Clipping to \(maxDistance)m -> removed \(numRemoved) vertecies")
    }
    
    func printGraph() {
        var numEdges = 0
        for (vertex, edges) in adjacencyList {
            var edgeStr = "\(vertex):"
            for edge in edges {
                edgeStr += " \(edge.destination)(\(edge.weight))"
                numEdges += 1
            }
            print(edgeStr)
        }
        print("Summary: \(adjacencyList.count) nodes \(numEdges) edges")
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
