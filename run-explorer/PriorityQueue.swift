//
//  PriorityQueue.swift
//  run-explorer
//
//  Created by Konstantin Klitenik on 6/17/19.
//  Copyright © 2019 KK. All rights reserved.
//

import Foundation

final class PriorityQueue<Element> {
    
    var elements: [Element] = []
    let sort: (Element, Element) -> Bool
    
    var isEmpty: Bool {
        return elements.isEmpty
    }
    
    var count: Int {
        return elements.count
    }
    
    init(sort: @escaping (Element, Element) -> Bool) {
        self.sort = sort
    }
    
    func dequeue() -> Element? {
        guard !isEmpty else { return nil }
        
        elements.swapAt(0, count - 1)           // swap root and last elements
        let element = elements.removeLast()     // get former root (now last elemnt)
        siftDown(from: 0)
        
        return element
    }
    
    func enqueue(element: Element) {
        elements.append(element)
        siftUp(from: elements.count - 1)
    }
    
    private func siftDown(from index: Int) {
        let left = leftChildIndex(of: index)
        let right = rightChildIndex(of: index)
        
        var candidate = index
        if left < count && sort(elements[left], elements[candidate]) {
            candidate = left
        }
        if right < count && sort(elements[right], elements[candidate]) {
            candidate = right
        }
        
        if candidate == index {
            return
        }
        
        elements.swapAt(index, candidate)
        return siftDown(from: candidate)
    }
    
    private func siftUp(from index: Int) {
        let parent = parentIndex(of: index)
        
        if index > 0 && sort(elements[index], elements[parent]) {
            elements.swapAt(index, parent)
            siftUp(from: parent)
        }
    }
    
    private func leftChildIndex(of index: Int) -> Int {
        return (2 * index) + 1
    }
    
    private func rightChildIndex(of index: Int) -> Int {
        return (2 * index) + 2
    }
    
    private func parentIndex(of index: Int) -> Int {
        return (index - 1) / 2
    }
}
