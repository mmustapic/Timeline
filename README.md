Timeline
========

A Twitter-like timeline model in Swift 3. A timeline holds events and sometimes gaps between groups of events. A gap can be filled by more events.

### Installation

Just copy `Timeline.swift` to your project.

### Usage

Just make your events implement the `TimelineEvent` protocol and you can add them to the timeline.

### Examples

The project is a simple iOS app that uses a `Timeline` as the model of a `UITableViewController`. Relevant code is in the `ViewController.swift` file.

### Limitations

`Timeline` is not thread safe, so don't update it in different threads.

### License

Public domain. Do whatever you want with this.