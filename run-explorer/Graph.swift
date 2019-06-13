//
//  Graph.swift
//  run-explorer
//
//  Created by Konstantin Klitenik on 6/13/19.
//  Copyright © 2019 KK. All rights reserved.
//

import Foundation

final class Graph<T: Hashable> {
    var adjecencyList = Dictionary<Vertex<T>, Set<Edge<T>>>()
    
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
    
    func computeShortestPathTree(source: Vertex<T>) {
        // shortest path tree
        var spt = Dictionary<Vertex<T>, (distance: Double, prev: Vertex<T>?)>(minimumCapacity: adjecencyList.count)
        
        var unvisitted = Set<Vertex<T>>()
        
        for vertex in adjecencyList.keys {
            spt[vertex] = (Double.infinity, nil)
            unvisitted.insert(vertex)
        }
        spt[source] = (0, nil)
        
        while let vertex = unvisitted.min(by: { spt[$0]!.distance < spt[$1]!.distance }) {
            print("Processing \(vertex)")
            
            guard let edges = adjecencyList[vertex] else { print("No edges for \(vertex)"); return }
                
            for edge in edges {
                let alt = spt[vertex]!.distance + edge.weight
                if let (currentDistance, _) = spt[edge.destination], unvisitted.contains(edge.destination) && alt < currentDistance {
                    spt[edge.destination] = (alt, vertex)
                }
            }
                
            unvisitted.remove(vertex)
        }
        
        for entry in spt {
            print("\(entry.key): \(entry.value.distance)")
        }
    }
    
    func shortestPath(from source: Vertex<T>, to destination: Vertex<T>) -> [Vertex<T>] {
        
    }
    
    func printGraph() {
        for (vertex, edges) in adjecencyList {
            var edgeStr = "\(vertex):"
            for edge in edges {
                edgeStr += " \(edge.destination)(\(edge.weight ?? Double.infinity))"
            }
            print(edgeStr)
        }
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

struct Edge<T: Hashable>: Hashable {
    var source: Vertex<T>
    var destination: Vertex<T>
    var weight: Double
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(source)
        hasher.combine(destination)
    }
    
    static func ==(lhs: Edge, rhs: Edge) -> Bool {
        return lhs.source == rhs.source && lhs.destination == rhs.destination
    }
}

