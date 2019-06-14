//
//  run_explorerTests.swift
//  run-explorerTests
//
//  Created by Konstantin Klitenik on 5/31/19.
//  Copyright © 2019 KK. All rights reserved.
//

import XCTest
@testable import run_explorer

class run_explorerTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
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

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
//            let parser = OsmParser(contentsOf: URL(fileURLWithPath: "/Users/kon/Downloads/map.osm"))
        }
    }

}
