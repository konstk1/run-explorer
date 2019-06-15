//
//  Graph.swift
//  run-explorer
//
//  Created by Konstantin Klitenik on 6/13/19.
//  Copyright © 2019 KK. All rights reserved.
//

import Foundation


final class Graph<T: Hashable> {
    private var adjecencyList: [Vertex<T>: Set<Edge<T>>] = [:]

    private var originVertex: Vertex<T>?
    
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
        }
        
//        for entry in spt! {
//            print("\(entry.key): \(entry.value.distance)")
//        }
    }
    
    func shortestPathFromOrigin(to destination: Vertex<T>) -> [Vertex<T>] {
        var shortestPath: [Vertex<T>] = []
        
        guard let origin = originVertex else {
            print("Origin is unset")
            return shortestPath
        }
        
        if spt == nil {
            print("Calculating SPT...")
            computeShortestPathTree(source: origin)
        }
        
        var vertex: Vertex? = destination
        repeat {
            shortestPath.append(vertex!)
            vertex = spt?[vertex!]?.prev
        } while vertex != nil
        
        return shortestPath.reversed()
    }
    
    func setOrigin(vertex: Vertex<T>) {
        guard originVertex != vertex else { return }  // nothing to do if origin hasn't changed
        
        // if new origin, save it and clear shortest path tree
        originVertex = vertex
        spt = nil
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
