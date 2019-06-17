//
//  run_explorerTests.swift
//  run-explorerTests
//
//  Created by Konstantin Klitenik on 5/31/19.
//  Copyright © 2019 KK. All rights reserved.
//

import XCTest
import CoreLocation
@testable import run_explorer

class run_explorerTests: XCTestCase {
    var osm: OsmParser!
    var graph: Graph<OsmNode>!

    override func setUp() {
        guard let url = Bundle.main.url(forResource: "test", withExtension: "osm") else { fatalError("Failed to get osm file") }
        osm = OsmParser(contentsOf: url)
        graph = osm.buildGraph()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testStrava() {
        let strava = Strava()
    }
    
    func testGraph() {
        // https://www.geeksforgeeks.org/dijkstras-shortest-path-algorithm-greedy-algo-7/
        
        let graph = Graph<String>()
        
        let verticies = (0...8).map { Vertex(data: "\($0)") }
        
        graph.addUndirectedEdge(from: verticies[0], to: verticies[1], weight: 4)
        graph.addUndirectedEdge(from: verticies[0], to: verticies[7], weight: 8)
        graph.addUndirectedEdge(from: verticies[1], to: verticies[7], weight: 11)
        graph.addUndirectedEdge(from: verticies[1], to: verticies[2], weight: 8)
        graph.addUndirectedEdge(from: verticies[2], to: verticies[3], weight: 7)
        graph.addUndirectedEdge(from: verticies[2], to: verticies[5], weight: 4)
        graph.addUndirectedEdge(from: verticies[2], to: verticies[8], weight: 2)
        graph.addUndirectedEdge(from: verticies[3], to: verticies[4], weight: 9)
        graph.addUndirectedEdge(from: verticies[3], to: verticies[5], weight: 14)
        graph.addUndirectedEdge(from: verticies[4], to: verticies[5], weight: 10)
        graph.addUndirectedEdge(from: verticies[5], to: verticies[6], weight: 2)
        graph.addUndirectedEdge(from: verticies[6], to: verticies[7], weight: 1)
        graph.addUndirectedEdge(from: verticies[6], to: verticies[8], weight: 6)
        graph.addUndirectedEdge(from: verticies[7], to: verticies[8], weight: 7)
        
//        graph.printGraph()
        graph.setOrigin(vertex: verticies[0])
        graph.shortestPathFromOrigin(to: verticies[8]).printPath()
        graph.shortestPathFromOrigin(to: verticies[3]).printPath()
        graph.setOrigin(vertex: verticies[8])
        graph.shortestPathFromOrigin(to: verticies[4]).printPath()
    }
    
    func testOsmGraph() {
        
        
    }
    
    func testPriorityQueue() {
        let q = PriorityQueue<Int>(sort: <)
        q.enqueue(element: 1)
        q.enqueue(element: 12)
        q.enqueue(element: 3)
        q.enqueue(element: 4)
        q.enqueue(element: 1)
        q.enqueue(element: 6)
        q.enqueue(element: 8)
        q.enqueue(element: 7)
        q.enqueue(element: 13)
//        1,12,3,4,1,6,8,7,13
//        13,12,8,7,6,4,3,1,1
        
        while !q.isEmpty {
            print(q.dequeue()!)
        }
    }

    func testGraphPerformance() {
        // This is an example of a performance test case.
        var i = 0
        let center = CLLocation(latitude: 42.412060, longitude: -71.142201)
        

        self.measure {
            graph.computeShortestPathTree(source: graph.verticies[0])
        }
    }

}
