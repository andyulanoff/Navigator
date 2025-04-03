# Destinations

All navigation in Navigator is accomplished using enumerated values that conform to the NavigationDestination protocol.

## Overview

NavigationDestination types can be used in order to push and present views as needed.

This can happen using…

* Standard SwiftUI modifiers like NBNavigationLink(value:label:).
* Imperatively by asking a Navigator to perform the desired action.
* Or via a deep link action enabled by a NavigationURLHander.

They’re one of the core elements that make Navigator possible, and they give us the separation of concerns we mentioned earlier.

### Defining Navigation Destinations
Destinations (or routes) are typically just public lists of enumerated values, one for each view desired.
```swift
public enum HomeDestinations {
    case page2
    case page3
    case pageN(Int)
}
```
SwiftUI requires navigation destination values to be `Hashable`, and so do we. That conformance, however, is satisfied by
conforming to the protocol NavigationDestination as shown next. 

### Defining Destination Views
Defining our destination views is easy, since NavigationDestination actually conforms to the View protocol! 

As such, we just extend our destination with a view body that returns the correct view for each case.
```swift
extension HomeDestinations: NavigationDestination {
    public var body: some View {
        switch self {
        case .page2:
            HomePage2View()
        case .page3:
            HomePage3View()
        case .pageN(let value):
            HomePageNView(number: value)
        }
    }
}
```
This is a powerful technique that lets Navigator easily create our views whenever or wherever needed. That could be via `NBNavigationLink(value:label)`, or presented via a sheet or fullscreen cover.

Note how associated values can be used to pass parameters to views as needed.

*To build more complex views that have external dependencies or that require access to environmental values, see <doc:AdvancedDestinations>.

### Registering Navigation Destinations
Like traditional `NavigationStack` destination types, `NavigationDestination` types need to be registered with the enclosing
navigation stack in order for `navigate(to:)` presentations and standard `NBNavigationLink(value:label:)` transitions 
to work correctly.

But since each `NavigationDestination` already defines the views to be provided, registering destination types can be done
using a simple one-line view modifier.
```swift
ManagedNavigationStack {
    HomeView()
        .nbNavigationDestination(HomeDestinations.self)
}
```
This also makes using the same destination type with more than one navigation stack a lot easier.

*Note that registering types more than once in the same NBNavigationStackisn't recommended and Navigator will in fact warn you if it see multiple registrations of the same type.*

### Using Navigation Destinations
With that out of the way, Navigation Destinations can be dispatched using a standard SwiftUI `NBNavigationLink(value:label:)` view.
```swift
NBNavigationLink(value: HomeDestinations.page3) {
    Text("Link to Home Page 3!")
}
```
Or they can be dispatched declaratively using modifiers.
```swift
// Sample using optional destination
@State var page: SettingsDestinations?
...
Button("Modifier Navigate to Page 3!") {
    page = .page3
}
.navigate(to: $page)

// Sample using trigger value
@State var triggerPage3: Bool = false
...
Button("Modifier Trigger Page 3!") {
    triggerPage3.toggle()
}
.navigate(trigger: $triggerPage3, destination: SettingsDestinations.page3)
```
Or imperatively by asking a Navigator to perform the desired action.
```swift
@Environment(\.navigator) var navigator: Navigator
...
Button("Button Push Home Page 55") {
    navigator.push(HomeDestinations.pageN(55))
}
Button("Button Navigate To Home Page 55") {
    navigator.navigate(to: HomeDestinations.pageN(55))
}
```
In case you're wondering, calling `push` pushes the associate view onto the current `NavigationStack`, while `Navigate(to:)` will push
the view or present the view, based on the `NavigationMethod` specified.

Speaking of which...

### Navigation Methods

`NavigationDestination` can be extended to provide a distinct ``NavigationMethod`` for each enumerated type.
```swift
extension HomeDestinations: NavigationDestination {
    public var method: NavigationMethod {
        switch self {
        case .page3:
            .sheet
        default:
            .push
        }
    }
}
```
In this case, should `navigator.navigate(to: HomeDestinations.page3)` be called, Navigator will automatically present that view in a
sheet. All other views will be pushed onto the navigation stack.

The current navigation methods are: .push (default), .sheet, .cover, and .send.

Predefined methods can be overridden using Navigator's `navigate(to:method:)` function.

```swift
Button("Present Home Page 55 Via Sheet") {
    navigator.navigate(to: HomeDestinations.pageN(55), method: .sheet)
}
```
Note that NavigationDestinations dispatched via NBNavigationLink will *always* push onto the NavigationStack. That's just how SwiftUI works.

## Values, Not Destinations

Navigator is designed to work with ``NavigationDestination`` types and SwiftUI's `NBNavigationLink(value:label:)`; not `NBNavigationLink(destination:label:)`.

Mixing the two on the same `NavigationStack` can lead to unexpected behavior, and using `NBNavigationLink(destination:label:)` at all can affect programatic navigation using Navigators. 

```swift
// DO
NBNavigationLink(value: HomeDestinations.page3) {
    Text("Link to Home Page 3!")
}

// DON'T DO
NBNavigationLink(destination: HomePage3View()) {
    Text("Link to Home Page 3!")
}
```
If you start seeing odd behavior returning to previous views, check to make sure a `NBNavigationLink(destination:label:)` link hasn't worked its way into your code.

> IMPORTANT: Use NavigationDestination values. Avoid using `NBNavigationLink(destination:label:)`.

## See Also

- <doc:AdvancedDestinations>
