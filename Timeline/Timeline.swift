//
//  Timeline.swift
//  Timeline
//
//  Public Domain
//  No warranty is offered or implied; use this code at your own risk
//
//  Created by Marco Mustapic
//

import Foundation

/**
	Events added to the timeline must implement this protocol.
*/
protocol TimelineEvent {
	associatedtype Id : UnsignedInteger
	/// unique id of the event. A greater id means it is more recent.
	var id: Id { get }
}

/**
	A Timeline element. Timelines can contain either events or gaps.
 */
enum TimelineElement<EventType: TimelineEvent> {
	case event(event: EventType)
	case gap(maxId: EventType.Id)
}

extension TimelineElement: Equatable {
	
}

func ==<EventType: TimelineEvent>(lhs: EventType, rhs: EventType) -> Bool {
	return lhs.id == rhs.id
}

func ==<EventType: TimelineEvent>(lhs: TimelineElement<EventType>, rhs: TimelineElement<EventType>) -> Bool {
	switch (lhs, rhs) {
		case (.event(let levent), .event(let revent)):
			return levent == revent
		case (.gap(let lMaxId), .gap(let rMaxId)):
			return lMaxId == rMaxId
		default:
			return false
	}
}

func ==<EventType: TimelineEvent>(lhs: [TimelineElement<EventType>], rhs: [TimelineElement<EventType>]) -> Bool {
	guard lhs.count == rhs.count else {
		return false
	}
	var i1 = lhs.makeIterator()
	var i2 = rhs.makeIterator()
	var isEqual = true
	while let e1 = i1.next(), let e2 = i2.next(), isEqual
	{
		isEqual = e1 == e2
	}
	return isEqual
}

/**
	Indices update operations afeter modifying the timeline. This is useful for `UITableViewController`s.

	- reload: all events where replaced
	- update: a list of deleted, inserted and updated indices. The inserted indices depend on the deletions being made.
				The updated indices depend on the insertions being made. That is, if you want to get the final state of the `Timeline`,
				first delete, then insert, then update.
*/
enum TimelineIndicesUpdates {
	case reload
	case update(deletedIndices: [Int], insertedIndices: [Int], updatedIndices: [Int])
}

extension TimelineIndicesUpdates: Equatable {
	
}

func ==(lhs: TimelineIndicesUpdates, rhs: TimelineIndicesUpdates) -> Bool {
	switch (lhs, rhs) {
	case (.reload, .reload):
			return true
		case (.update(let lDeleted, let lInserted, let lUpdated), .update(let rDeleted, let rInserted, let rUpdated)):
			return lDeleted == rDeleted && lInserted == rInserted && lUpdated == rUpdated
		default:
			return false
	}
}

/**
	A twitter-like timeline model. A timeline contains ordered events and new ones can be added at the beginning or the end.

	It can contain two types of elements: events and gaps. Gaps are created automatically if new events added at the beginning are too new. A gap can be expanded (totally or partially) by adding new events.
*/
class Timeline<EventType: TimelineEvent> {
	
	fileprivate (set) var elements: [TimelineElement<EventType>] = []

	/// newest event id
	public var maxId: EventType.Id {
		get {
			guard let first = self.elements.first else {
				return 0
			}
			switch first {
				case .event(let event):
					return event.id
				default:
					fatalError("First element in timeline should be an event, it is a gap")
			}
		}
	}
	
	/// oldest event id
	public var minId: EventType.Id {
		get {
			guard let last = self.elements.last else {
				return 0
			}
			switch last {
			case .event(let event):
				return event.id
			default:
				fatalError("Last element in timeline should be an event, it is a gap")
			}
		}
	}

	/// number of elements (events and gaps) in the timeline
	public var numberOfElements: Int {
		return self.elements.count
	}

	/**
	Resets the timeline with new events

	- parameter evens: Events to add to the timeline
	- parameter sort: Optionally sort the new events
	- returns: Indices update operations after resetting the timeline
	*/
	func reset(_ events: [EventType], sort: Bool = false) -> TimelineIndicesUpdates? {
		let sorted = sort ? events.sorted(by: { $0.id > $1.id }) : events
		self.elements = sorted.map({ (event) -> TimelineElement<EventType> in
			return TimelineElement<EventType>.event(event: event)
		})
		return .reload
	}
	
	/**
	Add events to the beggining of the timeline. If not forcing a sort, oldest event to add must be newer than newest event in the timeline.
	Events with the same id as existing ones will be ignored.
	
	If the id of last of the new events is greater then the id of the existing first event, a gap will be created.
	
	- parameter events: Events to add to the timeline
	- parameter sort: Optionally sort the new events
	- returns: Indices update operations after adding the new events to the timeline
	*/
	func prepend(_ events: [EventType], sort: Bool = false) -> TimelineIndicesUpdates? {
		// insert the events if the timeline is empty
		guard let firstExistingElement = self.elements.first else {
			return self.reset(events, sort: sort)
		}

		let existingEvent: EventType?
		switch firstExistingElement {
			case .event(let event):
				existingEvent = event
			case .gap:
				existingEvent = nil
		}
		
		let sorted = sort ? events.sorted(by: { $0.id > $1.id }) : events
		
		// do nothing when prepending zero events
		guard let firstExistingEvent = existingEvent,
			let firstNewEvent = sorted.first,
			let lastNewEvent = sorted.last else {
				return nil
		}
		
		// ignore if events to prepend are older than existing timeline
		guard firstNewEvent.id > firstExistingEvent.id else {
			return nil
		}

		if lastNewEvent.id > firstExistingEvent.id {
			// insert gap between new elements and old ones
			let gap = TimelineElement<EventType>.gap(maxId: lastNewEvent.id)

			// elements for new events
			let newElements = sorted.map({ (event) -> TimelineElement<EventType> in
				return TimelineElement<EventType>.event(event: event)
			})
			self.elements = newElements + [gap] + self.elements
			let inserts = Array<Int>(0...newElements.count)
			return TimelineIndicesUpdates.update(deletedIndices: [], insertedIndices: inserts, updatedIndices: [])
		}
		else {
			// ignore events that have id lower than existing ones
			let newElements = sorted.filter({ (event) -> Bool in
				return event.id > firstExistingEvent.id
			}).map({ (event) -> TimelineElement<EventType> in
				return TimelineElement<EventType>.event(event: event)
			})

			self.elements = newElements + self.elements
			let inserts = Array<Int>(0...newElements.count-1)
			return TimelineIndicesUpdates.update(deletedIndices: [], insertedIndices: inserts, updatedIndices: [])
		}
	}
	
	/**
	Replace a gap with new events. If the gap can be completely expanded then it is removed. Otherwise the events will be added and a new gap will be created.
	New event ids must be less than or equal to the gap's maxId. Events with the same id as existing ones will be ignored.
	
	- parameter events: Events to replace the gap
	- parameter sort: Optionally sort the new events
	- returns: Indices update operations after expanding a gap
	*/
	func expand(_ events: [EventType], maxId: EventType.Id, sort: Bool = false) -> TimelineIndicesUpdates? {
		let sorted = sort ? events.sorted(by: { $0.id > $1.id }) : events

		// do nothing when expanding with 0 elements
		guard let lastNewEvent = sorted.last else {
			return nil
		}

		// do nothing if no gap is found
		// check that we have an element after the gap, and it's an event
		guard let gapIndex = self.elements.index(where: { (element) -> Bool in
				switch element {
					case .event:
						return false
					case .gap(let gapMaxId):
						return maxId == gapMaxId
				}
			}),
			self.elements.count > gapIndex+1,
			case let .event(event: firstExistingEvent) = self.elements[gapIndex+1] else {
			return nil
		}

		// if last new event is older than first existing event, gap will be expanded completely
		if lastNewEvent.id <= firstExistingEvent.id {
			let newElements = sorted.filter({ (event) -> Bool in
				return event.id > firstExistingEvent.id
			}).map({ (event) -> TimelineElement<EventType> in
				return .event(event: event)
			})
			let suffix = self.elements.suffix(from: gapIndex+1)
			self.elements = self.elements.prefix(upTo: gapIndex) + newElements + suffix
			let inserts = Array<Int>(gapIndex...gapIndex+newElements.count-1)
			return TimelineIndicesUpdates.update(deletedIndices: [gapIndex], insertedIndices: inserts, updatedIndices: [])
		}
		// gap will be expanded partially
		else {
			let newElements = sorted.map({ (event) -> TimelineElement<EventType> in
				return .event(event: event)
			})
			let prefix = self.elements.prefix(upTo: gapIndex)
			let suffix = self.elements.suffix(from: gapIndex+1)
			self.elements = prefix + newElements + [.gap(maxId: lastNewEvent.id)] + suffix
			// include gap in inserts
			let inserts = Array<Int>(gapIndex...gapIndex+newElements.count)
			return TimelineIndicesUpdates.update(deletedIndices: [gapIndex], insertedIndices: inserts, updatedIndices: [])
		}
	}
	
	/**
	Add events to the end of the timeline. Events must be older than the last element in the timeline.
	
	- parameter events: Events to add to the end of the timeline
	- parameter sort: Optionally sort the new events
	- returns: Indices update operations after adding the new events to the timeline
	*/
	func append(_ events: [EventType], sort: Bool = false) -> TimelineIndicesUpdates? {
		// insert the events if the timeline is empty
		guard let lastExistingElement = self.elements.last else {
			return self.reset(events, sort: sort)
		}
		
		let existingEvent: EventType?
		switch lastExistingElement {
			case .event(let event):
				existingEvent = event
			case .gap:
				existingEvent = nil
		}
		
		let sorted = sort ? events.sorted(by: { $0.id > $1.id }) : events

		// do nothing when appending zero events
		guard let lastExistingEvent = existingEvent,
			let firstNewEvent = sorted.first else {
				return nil
		}
		
		// ignore if events to append are newer than existing timeline
		guard firstNewEvent.id < lastExistingEvent.id else {
			return nil
		}
		let newElements = sorted.map({ (event) -> TimelineElement<EventType> in
			return TimelineElement<EventType>.event(event: event)
		})

		let start = self.elements.count
		let inserts = Array<Int>(start...start+newElements.count-1)
		self.elements = self.elements + newElements
		return TimelineIndicesUpdates.update(deletedIndices: [], insertedIndices: inserts, updatedIndices: [])

	}
}
