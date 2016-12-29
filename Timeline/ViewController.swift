//
//  ViewController.swift
//  Timeline
//
//  Public Domain
//  No warranty is offered or implied; use this code at your own risk
//
//  Created by Marco Mustapic
//

import UIKit

struct Event: TimelineEvent {
	var id: UInt64
	var text: String
}

class ViewController: UITableViewController {

	let timeline: Timeline<Event> = Timeline()
	let reuseIdentifier = "reuseIdentifier"
	
	var minId: UInt64 = 0
	
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
	
		self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: self.reuseIdentifier)

		self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "+ 10", style: .plain, target: self, action: #selector(self.add10))
		self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "+ 10 + gap", style: .plain, target: self, action: #selector(self.add10Gap))
		
		let events = (20..<40).reversed().map { (id) -> Event in
			return Event(id: id, text: "This is event \(id)")
		}
		let _ = timeline.reset(events)
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

	// MARK: UITableViewController delegate and data source
	override func numberOfSections(in tableView: UITableView) -> Int {
		return 2
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if section == 0 {
			return timeline.numberOfElements
		}
		else {
			return 1
		}
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: self.reuseIdentifier, for: indexPath)
		if indexPath.section == 0 {
			let element = self.timeline.elements[indexPath.row]
			switch element {
				case .gap:
					cell.textLabel?.text = ">>> Tap for more <<<"
				case .event(let event):
					cell.textLabel?.text = event.text
			}
		}
		else {
			cell.textLabel?.text = "More..."
		}
		return cell
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		if indexPath.section == 0 {
			let element = self.timeline.elements[indexPath.row]
			switch element {
			case .gap(let maxId):
				let events = (maxId-10..<maxId).reversed().map { (id) -> Event in
					return Event(id: id, text: "This is event \(id)")
				}
				if let updates = self.timeline.expand(events, maxId: maxId) {
					self.processUpdates(updates: updates)
				}
			case .event:
				break
			}
			tableView.deselectRow(at: indexPath, animated: true)
		}
	}
	
	override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		if indexPath.section == 1 {
			let maxId = self.timeline.minId
			let minId: Event.Id
			if self.timeline.minId < 10 {
				minId = 0
			}
			else {
				minId = self.timeline.minId-10
			}
			if maxId > minId {
				let events = (minId..<maxId).reversed().map { (id) -> Event in
					return Event(id: id, text: "This is event \(id)")
				}
				// FIXME: we should use begin/end updates instead of reloadData(), but it will crash while scrolling
				let _ = self.timeline.append(events)
				self.tableView.reloadData()
			}
		}
	}
	
	// MARK: button actions
	func processUpdates(updates: TimelineIndicesUpdates) {
		switch updates {
		case .update(let deletes, let inserts, let updates):
			self.tableView.beginUpdates()
			self.tableView.deleteRows(at: deletes.map({ IndexPath(row: $0, section: 0) }), with: .none)
			self.tableView.insertRows(at: inserts.map({ IndexPath(row: $0, section: 0) }), with: .none)
			self.tableView.reloadRows(at: updates.map({ IndexPath(row: $0, section: 0) }), with: .none)
			self.tableView.endUpdates()
		case .reload:
			self.tableView.reloadData()
		}
	}
	
	
	func add10() {
		let events = (self.timeline.maxId..<self.timeline.maxId+10).reversed().map { (id) -> Event in
			return Event(id: id, text: "This is event \(id)")
		}
		if let updates = self.timeline.prepend(events) {
			self.processUpdates(updates: updates)
			self.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
		}
		
	}

	func add10Gap() {
		let events = (self.timeline.maxId+5..<self.timeline.maxId+15).reversed().map { (id) -> Event in
			return Event(id: id, text: "This is event \(id)")
		}
		if let updates = self.timeline.prepend(events) {
			self.processUpdates(updates: updates)
			self.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
		}
	}
}

