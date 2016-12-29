//
//  TimelineTests.swift
//  TimelineTests
//
//  Public Domain
//  No warranty is offered or implied; use this code at your own risk
//
//  Created by Marco Mustapic
//

import XCTest
@testable import Timeline

// a simple struct that implements the TimelineEvent protocol
struct Event: TimelineEvent, CustomStringConvertible {
	typealias Id = UInt64
	let id: Id
	let text: String
	init(id: Id, text: String = "") {
		self.id = id
		self.text = text
	}
	
	var description: String {
		return "\(self.id) (\(self.text))"
	}
}

class TimelineTests: XCTestCase {
	
	override func setUp() {
		super.setUp()
	}
	
	override func tearDown() {
		super.tearDown()
	}
	
	// reset a timeline
	func testReset() {
		let initial: [Event] = [
			Event(id: 10),
			Event(id: 9),
			Event(id: 8),
			Event(id: 7)
		]
		
		let timeline = Timeline<Event>()
		let resultUpdate = timeline.reset(initial)
		XCTAssertEqual(timeline.numberOfElements, initial.count, "Number of elements should be the same")
		let expectedElements = [
			TimelineElement<Event>.event(event: initial[0]),
			TimelineElement<Event>.event(event: initial[1]),
			TimelineElement<Event>.event(event: initial[2]),
			TimelineElement<Event>.event(event: initial[3])
		]
		let expectedUpdate = TimelineIndicesUpdates.reload
		
		let elements = timeline.elements
		XCTAssertEqual(elements, expectedElements, "Elements should be \(expectedElements), are \(elements)")
		XCTAssertEqual(timeline.minId, initial.last!.id, "minId should be \(initial.last!.id), is \(timeline.minId)")
		XCTAssertEqual(timeline.maxId, initial.first!.id, "minId should be \(initial.first!.id), is \(timeline.maxId)")
		guard let update = resultUpdate else {
			XCTFail("Update should be \(expectedUpdate), is nil")
			return
		}
		XCTAssertEqual(update, expectedUpdate, "Updates should be \(expectedElements), is \(elements)")
	}
	
	// reset a timeline with unordered elements
	func testResetUnordered() {
		let initial: [Event] = [
			Event(id: 8),
			Event(id: 10),
			Event(id: 7),
			Event(id: 9)
		]
		
		let timeline = Timeline<Event>()
		let resultUpdate = timeline.reset(initial, sort: true)
		XCTAssertEqual(timeline.numberOfElements, initial.count, "Number of elements should be the same")
		let expectedElements = [
			TimelineElement<Event>.event(event: initial[1]),
			TimelineElement<Event>.event(event: initial[3]),
			TimelineElement<Event>.event(event: initial[0]),
			TimelineElement<Event>.event(event: initial[2])
		]
		let expectedUpdate = TimelineIndicesUpdates.reload
		
		let elements = timeline.elements
		XCTAssertEqual(elements, expectedElements, "Elements should be \(expectedElements), are \(elements)")
		XCTAssertEqual(timeline.minId, 7, "minId should be \(7), is \(timeline.minId)")
		XCTAssertEqual(timeline.maxId, 10, "maxId should be \(10), is \(timeline.maxId)")
		guard let update = resultUpdate else {
			XCTFail("Update should be \(expectedUpdate), is nil")
			return
		}
		XCTAssertEqual(update, expectedUpdate, "Updates should be \(expectedElements), is \(elements)")
	}
	
	// try to prepend old elements
	func testPrependLowId() {
		let initial: [Event] = [
			Event(id: 10),
			Event(id: 9),
			Event(id: 8),
			Event(id: 7)
		]
		
		let new: [Event] = [
			Event(id: 7),
			Event(id: 6),
			Event(id: 5),
			Event(id: 4)
		]
		
		let timeline = Timeline<Event>()
		let _ = timeline.reset(initial)
		let prependUpdate = timeline.prepend(new)
		
		let expectedElements = [
			TimelineElement<Event>.event(event: initial[0]),
			TimelineElement<Event>.event(event: initial[1]),
			TimelineElement<Event>.event(event: initial[2]),
			TimelineElement<Event>.event(event: initial[3])
		]
		let elements = timeline.elements
		XCTAssertEqual(elements, expectedElements, "Elements should be \(expectedElements), are \(elements)")
		XCTAssertEqual(timeline.minId, initial.last!.id, "minId should be \(initial.last!.id), is \(timeline.minId)")
		XCTAssertEqual(timeline.maxId, initial.first!.id, "minId should be \(initial.first!.id), is \(timeline.maxId)")
		XCTAssertNil(prependUpdate, "Prenend update operation should be nil")
	}
	
	// prepend events when the new ones are all newer than the existing ones
	func testPrependSplit() {
		let initial: [Event] = [
			Event(id: 10),
			Event(id: 9),
			Event(id: 8),
			Event(id: 7)
		]
		
		let new: [Event] = [
			Event(id: 20),
			Event(id: 19),
			Event(id: 18),
			Event(id: 17)
		]
		
		let timeline = Timeline<Event>()
		let _ = timeline.reset(initial)
		let prependUpdate = timeline.prepend(new)
		
		let expectedElements = [
			TimelineElement<Event>.event(event: new[0]),
			TimelineElement<Event>.event(event: new[1]),
			TimelineElement<Event>.event(event: new[2]),
			TimelineElement<Event>.event(event: new[3]),
			TimelineElement<Event>.gap(maxId: new[3].id),
			TimelineElement<Event>.event(event: initial[0]),
			TimelineElement<Event>.event(event: initial[1]),
			TimelineElement<Event>.event(event: initial[2]),
			TimelineElement<Event>.event(event: initial[3])
		]
		let expectedUpdate = TimelineIndicesUpdates.update(deletedIndices: [], insertedIndices: [0, 1, 2, 3, 4], updatedIndices: [])
		
		let elements = timeline.elements
		XCTAssertEqual(elements, expectedElements, "Elements should be \(expectedElements), are \(elements)")
		XCTAssertEqual(timeline.minId, initial.last!.id, "minId should be \(initial.last!.id), is \(timeline.minId)")
		XCTAssertEqual(timeline.maxId, new.first!.id, "minId should be \(new.first!.id), is \(timeline.maxId)")
		guard let update = prependUpdate else {
			XCTFail("Update should be \(expectedUpdate), is nil")
			return
		}
		XCTAssertEqual(update, expectedUpdate, "Updates should be \(update), is \(expectedUpdate)")
	}
	
	
	// prepend 0 events
	func testPrependNoEvents() {
		let initial: [Event] = [
			Event(id: 10),
			Event(id: 9),
			Event(id: 8),
			Event(id: 7)
		]
		
		let new: [Event] = [
		]
		
		let timeline = Timeline<Event>()
		let _ = timeline.reset(initial)
		let prependUpdate = timeline.prepend(new)
		
		let expectedElements = [
			TimelineElement<Event>.event(event: initial[0]),
			TimelineElement<Event>.event(event: initial[1]),
			TimelineElement<Event>.event(event: initial[2]),
			TimelineElement<Event>.event(event: initial[3])
		]
		let elements = timeline.elements
		XCTAssertEqual(elements, expectedElements, "Elements should be \(expectedElements), are \(elements)")
		XCTAssertEqual(timeline.minId, initial.last!.id, "minId should be \(initial.last!.id), is \(timeline.minId)")
		XCTAssertEqual(timeline.maxId, initial.first!.id, "minId should be \(initial.first!.id), is \(timeline.maxId)")
		XCTAssertNil(prependUpdate, "Prenend update operation should be nil")
	}
	
	// prepend events when some of the new ones update existing ones
	func testPrependCombine() {
		let initial: [Event] = [
			Event(id: 10, text: "initial 10"),
			Event(id: 8, text: "initial 8"),
			Event(id: 6, text: "initial 6"),
			Event(id: 5, text: "initial 5")
		]
		
		let new: [Event] = [
			Event(id: 14, text: "new 14"),
			Event(id: 13, text: "new 13"),
			Event(id: 9, text: "new 9"),
			Event(id: 8, text: "new 8"),
			Event(id: 7, text: "new 7")
		]
		
		let timeline = Timeline<Event>()
		let _ = timeline.reset(initial)
		let prependUpdate = timeline.prepend(new)
		
		let expectedElements = [
			TimelineElement<Event>.event(event: new[0]),
			TimelineElement<Event>.event(event: new[1]),
			TimelineElement<Event>.event(event: initial[0]),
			TimelineElement<Event>.event(event: initial[1]),
			TimelineElement<Event>.event(event: initial[2]),
			TimelineElement<Event>.event(event: initial[3])
		]
		let expectedUpdate = TimelineIndicesUpdates.update(deletedIndices: [], insertedIndices: [0, 1], updatedIndices: [])
		
		let elements = timeline.elements
		XCTAssertEqual(elements, expectedElements, "Elements should be \(expectedElements), are \(elements)")
		XCTAssertEqual(timeline.minId, initial.last!.id, "minId should be \(initial.last!.id), is \(timeline.minId)")
		XCTAssertEqual(timeline.maxId, new.first!.id, "minId should be \(new.first!.id), is \(timeline.maxId)")
		guard let update = prependUpdate else {
			XCTFail("Update should be \(expectedUpdate), is nil")
			return
		}
		XCTAssertEqual(update, expectedUpdate, "updates should be \(update), is \(expectedUpdate)")
	}
	
	// apend events with higest new id < lowest existing id
	func testAppendLowerId() {
		let initial: [Event] = [
			Event(id: 10, text: "initial 10"),
			Event(id: 8, text: "initial 8"),
			Event(id: 6, text: "initial 6"),
			Event(id: 5, text: "initial 5")
		]
		
		let new: [Event] = [
			Event(id: 4, text: "new 4"),
			Event(id: 3, text: "new 3"),
			Event(id: 2, text: "new 2"),
			]
		
		let timeline = Timeline<Event>()
		let _ = timeline.reset(initial)
		let appendUpdate = timeline.append(new)
		
		let expectedElements = [
			TimelineElement<Event>.event(event: initial[0]),
			TimelineElement<Event>.event(event: initial[1]),
			TimelineElement<Event>.event(event: initial[2]),
			TimelineElement<Event>.event(event: initial[3]),
			TimelineElement<Event>.event(event: new[0]),
			TimelineElement<Event>.event(event: new[1]),
			TimelineElement<Event>.event(event: new[2])
		]
		let expectedUpdate = TimelineIndicesUpdates.update(deletedIndices: [], insertedIndices: [4, 5, 6], updatedIndices: [])
		
		let elements = timeline.elements
		XCTAssertEqual(elements, expectedElements, "Elements should be \(expectedElements), are \(elements)")
		XCTAssertEqual(timeline.minId, new.last!.id, "minId should be \(new.last!.id), is \(timeline.minId)")
		XCTAssertEqual(timeline.maxId, initial.first!.id, "minId should be \(initial.first!.id), is \(timeline.maxId)")
		guard let update = appendUpdate else {
			XCTFail("Update should be \(expectedUpdate), is nil")
			return
		}
		XCTAssertEqual(update, expectedUpdate, "updates should be \(update), is \(expectedUpdate)")
	}
	
	// apend events with higest new id >= lowest existing id
	func testAppendHighId() {
		let initial: [Event] = [
			Event(id: 10, text: "initial 10"),
			Event(id: 8, text: "initial 8"),
			Event(id: 6, text: "initial 6"),
			Event(id: 5, text: "initial 5")
		]
		
		let new: [Event] = [
			Event(id: 5, text: "new 5"),
			Event(id: 4, text: "new 4"),
			Event(id: 3, text: "new 3"),
			Event(id: 2, text: "new 2"),
			]
		
		let timeline = Timeline<Event>()
		let _ = timeline.reset(initial)
		let appendUpdate = timeline.append(new)
		
		let expectedElements = [
			TimelineElement<Event>.event(event: initial[0]),
			TimelineElement<Event>.event(event: initial[1]),
			TimelineElement<Event>.event(event: initial[2]),
			TimelineElement<Event>.event(event: initial[3])
		]
		let elements = timeline.elements
		XCTAssertEqual(elements, expectedElements, "Elements should be \(expectedElements), are \(elements)")
		XCTAssertEqual(timeline.minId, initial.last!.id, "minId should be \(initial.last!.id), is \(timeline.minId)")
		XCTAssertEqual(timeline.maxId, initial.first!.id, "minId should be \(initial.first!.id), is \(timeline.maxId)")
		XCTAssertNil(appendUpdate, "Append update operation should be nil")
	}
	
	
	// apend 0 events
	func testAppendNoEvents() {
		let initial: [Event] = [
			Event(id: 10, text: "initial 10"),
			Event(id: 8, text: "initial 8"),
			Event(id: 6, text: "initial 6"),
			Event(id: 5, text: "initial 5")
		]
		
		let new: [Event] = [
		]
		
		let timeline = Timeline<Event>()
		let _ = timeline.reset(initial)
		let appendUpdate = timeline.append(new)
		
		let expectedElements = [
			TimelineElement<Event>.event(event: initial[0]),
			TimelineElement<Event>.event(event: initial[1]),
			TimelineElement<Event>.event(event: initial[2]),
			TimelineElement<Event>.event(event: initial[3])
		]
		let elements = timeline.elements
		XCTAssertEqual(elements, expectedElements, "Elements should be \(expectedElements), are \(elements)")
		XCTAssertEqual(timeline.minId, initial.last!.id, "minId should be \(initial.last!.id), is \(timeline.minId)")
		XCTAssertEqual(timeline.maxId, initial.first!.id, "minId should be \(initial.first!.id), is \(timeline.maxId)")
		XCTAssertNil(appendUpdate, "Append update operation should be nil")
	}
	
	// try to expand non existing gap
	func testExpandNonExistingGap() {
		let initial: [Event] = [
			Event(id: 10, text: "initial 10"),
			Event(id: 8, text: "initial 8"),
			Event(id: 6, text: "initial 6"),
			Event(id: 5, text: "initial 5")
		]
		
		let new: [Event] = [
			Event(id: 5, text: "new 5"),
			Event(id: 4, text: "new 4"),
			Event(id: 3, text: "new 3"),
			Event(id: 2, text: "new 2"),
			]
		
		let timeline = Timeline<Event>()
		let _ = timeline.reset(initial)
		let expandUpdate = timeline.expand(new, maxId: 15)
		
		let expectedElements = [
			TimelineElement<Event>.event(event: initial[0]),
			TimelineElement<Event>.event(event: initial[1]),
			TimelineElement<Event>.event(event: initial[2]),
			TimelineElement<Event>.event(event: initial[3])
		]
		let elements = timeline.elements
		XCTAssertEqual(elements, expectedElements, "Elements should be \(expectedElements), are \(elements)")
		XCTAssertEqual(timeline.minId, initial.last!.id, "minId should be \(initial.last!.id), is \(timeline.minId)")
		XCTAssertEqual(timeline.maxId, initial.first!.id, "minId should be \(initial.first!.id), is \(timeline.maxId)")
		XCTAssertNil(expandUpdate, "Expand update operation should be nil")
	}
	
	// completely expand a gap with the exact number of elements
	func testExpandGapCompletely() {
		let initial: [Event] = [
			Event(id: 10, text: "initial 10"),
			Event(id: 8, text: "initial 8"),
			Event(id: 6, text: "initial 6"),
			Event(id: 5, text: "initial 5")
		]
		
		let top: [Event] = [
			Event(id: 18, text: "new 18"),
			Event(id: 17, text: "new 17"),
			Event(id: 16, text: "new 16"),
			Event(id: 15, text: "new 15"),
			]
		
		let new: [Event] = [
			Event(id: 14, text: "expanded 14"),
			Event(id: 13, text: "expanded 13"),
			Event(id: 12, text: "expanded 12"),
			Event(id: 11, text: "expanded 11"),
			]
		
		let timeline = Timeline<Event>()
		let _ = timeline.reset(initial)
		let _ = timeline.prepend(top)
		let expandUpdate = timeline.expand(new, maxId: 15)
		
		let expectedElements = [
			TimelineElement<Event>.event(event: top[0]),
			TimelineElement<Event>.event(event: top[1]),
			TimelineElement<Event>.event(event: top[2]),
			TimelineElement<Event>.event(event: top[3]),
			TimelineElement<Event>.event(event: new[0]),
			TimelineElement<Event>.event(event: new[1]),
			TimelineElement<Event>.event(event: new[2]),
			TimelineElement<Event>.event(event: new[3]),
			TimelineElement<Event>.gap(maxId: new[3].id),
			TimelineElement<Event>.event(event: initial[0]),
			TimelineElement<Event>.event(event: initial[1]),
			TimelineElement<Event>.event(event: initial[2]),
			TimelineElement<Event>.event(event: initial[3])
		]
		let expectedUpdate = TimelineIndicesUpdates.update(deletedIndices: [4], insertedIndices: [4, 5, 6, 7, 8], updatedIndices: [])
		
		let elements = timeline.elements
		XCTAssertEqual(elements, expectedElements, "Elements should be \(expectedElements), are \(elements)")
		XCTAssertEqual(timeline.minId, initial.last!.id, "minId should be \(initial.last!.id), is \(timeline.minId)")
		XCTAssertEqual(timeline.maxId, top.first!.id, "minId should be \(top.first!.id), is \(timeline.maxId)")
		guard let update = expandUpdate else {
			XCTFail("Update should be \(expectedUpdate), is nil")
			return
		}
		XCTAssertEqual(update, expectedUpdate, "Updates should be \(update), is \(expectedUpdate)")
	}
	
	// completely expand a gap with more elements than needed
	func testExpandGapCompletelyMore() {
		let initial: [Event] = [
			Event(id: 10, text: "initial 10"),
			Event(id: 8, text: "initial 8"),
			Event(id: 6, text: "initial 6"),
			Event(id: 5, text: "initial 5")
		]
		
		let top: [Event] = [
			Event(id: 18, text: "new 18"),
			Event(id: 17, text: "new 17"),
			Event(id: 16, text: "new 16"),
			Event(id: 15, text: "new 15"),
			]
		
		let new: [Event] = [
			Event(id: 14, text: "expanded 14"),
			Event(id: 13, text: "expanded 13"),
			Event(id: 12, text: "expanded 12"),
			Event(id: 11, text: "expanded 11"),
			Event(id: 10, text: "expanded 10"),
			]
		
		let timeline = Timeline<Event>()
		let _ = timeline.reset(initial)
		let _ = timeline.prepend(top)
		let expandUpdate = timeline.expand(new, maxId: 15)
		
		let expectedElements = [
			TimelineElement<Event>.event(event: top[0]),
			TimelineElement<Event>.event(event: top[1]),
			TimelineElement<Event>.event(event: top[2]),
			TimelineElement<Event>.event(event: top[3]),
			TimelineElement<Event>.event(event: new[0]),
			TimelineElement<Event>.event(event: new[1]),
			TimelineElement<Event>.event(event: new[2]),
			TimelineElement<Event>.event(event: new[3]),
			TimelineElement<Event>.event(event: initial[0]),
			TimelineElement<Event>.event(event: initial[1]),
			TimelineElement<Event>.event(event: initial[2]),
			TimelineElement<Event>.event(event: initial[3])
		]
		let expectedUpdate = TimelineIndicesUpdates.update(deletedIndices: [4], insertedIndices: [4, 5, 6, 7], updatedIndices: [])
		
		let elements = timeline.elements
		XCTAssertEqual(elements, expectedElements, "Elements should be \(expectedElements), are \(elements)")
		XCTAssertEqual(timeline.minId, initial.last!.id, "minId should be \(initial.last!.id), is \(timeline.minId)")
		XCTAssertEqual(timeline.maxId, top.first!.id, "minId should be \(top.first!.id), is \(timeline.maxId)")
		guard let update = expandUpdate else {
			XCTFail("Update should be \(expectedUpdate), is nil")
			return
		}
		XCTAssertEqual(update, expectedUpdate, "Updates should be \(update), is \(expectedUpdate)")
	}
	
	
	// completely expand a gap partially
	func testExpandGapPartially() {
		let initial: [Event] = [
			Event(id: 10, text: "initial 10"),
			Event(id: 8, text: "initial 8"),
			Event(id: 6, text: "initial 6"),
			Event(id: 5, text: "initial 5")
		]
		
		let top: [Event] = [
			Event(id: 18, text: "new 18"),
			Event(id: 17, text: "new 17"),
			Event(id: 16, text: "new 16"),
			Event(id: 15, text: "new 15"),
			]
		
		let new: [Event] = [
			Event(id: 14, text: "expanded 14"),
			Event(id: 13, text: "expanded 13")
		]
		
		let timeline = Timeline<Event>()
		let _ = timeline.reset(initial)
		let _ = timeline.prepend(top)
		let expandUpdate = timeline.expand(new, maxId: 15)
		
		let expectedElements = [
			TimelineElement<Event>.event(event: top[0]),
			TimelineElement<Event>.event(event: top[1]),
			TimelineElement<Event>.event(event: top[2]),
			TimelineElement<Event>.event(event: top[3]),
			TimelineElement<Event>.event(event: new[0]),
			TimelineElement<Event>.event(event: new[1]),
			TimelineElement<Event>.gap(maxId: new[1].id),
			TimelineElement<Event>.event(event: initial[0]),
			TimelineElement<Event>.event(event: initial[1]),
			TimelineElement<Event>.event(event: initial[2]),
			TimelineElement<Event>.event(event: initial[3])
		]
		let expectedUpdate = TimelineIndicesUpdates.update(deletedIndices: [4], insertedIndices: [4, 5, 6], updatedIndices: [])
		
		let elements = timeline.elements
		XCTAssertEqual(elements, expectedElements, "Elements should be \(expectedElements), are \(elements)")
		XCTAssertEqual(timeline.minId, initial.last!.id, "minId should be \(initial.last!.id), is \(timeline.minId)")
		XCTAssertEqual(timeline.maxId, top.first!.id, "minId should be \(top.first!.id), is \(timeline.maxId)")
		guard let update = expandUpdate else {
			XCTFail("Update should be \(expectedUpdate), is nil")
			return
		}
		XCTAssertEqual(update, expectedUpdate, "Updates should be \(update), is \(expectedUpdate)")
	}
	
	// try to expand an existing gap with 0 events
	func testExpandGapNoEvents() {
		let initial: [Event] = [
			Event(id: 10, text: "initial 10"),
			Event(id: 8, text: "initial 8"),
			Event(id: 6, text: "initial 6"),
			Event(id: 5, text: "initial 5")
		]
		
		let top: [Event] = [
			Event(id: 18, text: "new 18"),
			Event(id: 17, text: "new 17"),
			Event(id: 16, text: "new 16"),
			Event(id: 15, text: "new 15"),
			]
		
		let new: [Event] = [
		]
		
		let timeline = Timeline<Event>()
		let _ = timeline.reset(initial)
		let _ = timeline.prepend(top)
		let expandUpdate = timeline.expand(new, maxId: 15)
		
		let expectedElements = [
			TimelineElement<Event>.event(event: top[0]),
			TimelineElement<Event>.event(event: top[1]),
			TimelineElement<Event>.event(event: top[2]),
			TimelineElement<Event>.event(event: top[3]),
			TimelineElement<Event>.gap(maxId: top[3].id),
			TimelineElement<Event>.event(event: initial[0]),
			TimelineElement<Event>.event(event: initial[1]),
			TimelineElement<Event>.event(event: initial[2]),
			TimelineElement<Event>.event(event: initial[3])
		]
		let elements = timeline.elements
		XCTAssertEqual(elements, expectedElements, "Elements should be \(expectedElements), are \(elements)")
		XCTAssertEqual(timeline.minId, initial.last!.id, "minId should be \(initial.last!.id), is \(timeline.minId)")
		XCTAssertEqual(timeline.maxId, top.first!.id, "minId should be \(top.first!.id), is \(timeline.maxId)")
		XCTAssertNil(expandUpdate, "Expand update operation should be nil")
	}
	
}
