# Checkpoints

Navigation Checkpoints allow one to return to a specific waypoint in the navigation tree.

## Overview

Like most systems based on NavigationStack, Navigator supports operations like popping back to a previous view, dismissing a presented view, and so on.
```swift
Button("Pop To Previous Screen") {
    navigator.pop()
}
Button("Dismiss Presented View") {
    navigator.dismiss()
}
```
But those are all imperative operations. While one can programmatically pop and dismiss their way out of a screen, that approach is problematic and tends to be fragile. It also assumes that the code has explicit knowledge of the application structure and navigation tree.

One could pass bindings down the tree, but that can also be cumbersome and difficult to maintain.

Fortunately, Navigator supports checkpoints; named points in the navigation stack to which one can easily return.

## Examples

### Defining a Checkpoint
Checkpoints are easy to define and use. Let's create one called "home".
```swift
struct KnownCheckpoints: NavigationCheckpoint {
    public static var home: NavigationCheckpoint<Void> { checkpoint() }
}
```
Just conform your definitions to `NavigationCheckpoints` and specify the return type of the checkpoint (or void if none).

Using `{ checkpoint() }` ensures a checkpoint definition and name that's unique. Here, that's `KnownCheckpoints.home.()`.

### Establishing a Checkpoint
Now lets attach that checkpoint to our home view.
```swift
struct RootHomeView: View {
    var body: some View {
        ManagedNavigationStack(scene: "home") {
            HomeContentView(title: "Home Navigation")
                .navigationCheckpoint(KnownCheckpoints.home)
                .nbNavigationDestination(HomeDestinations.self)
        }
    }
}
```

### Returning to a Checkpoint
Once defined, they're easy to use.
```swift
Button("Return To Checkpoint Home") {
    navigator.returnToCheckpoint(KnownCheckpoints.home)
}
.disabled(!navigator.canReturnToCheckpoint(KnownCheckpoints.home))
```
When fired, checkpoints will dismiss any presented screens and pop any pushed views to return exactly where desired.

## Advanced Checkpoints

### Returning values to a Checkpoint
Checkpoints can also be used to return values to a caller.

As before we define our checkpoint, specifying the return value type.
```swift
struct KnownCheckpoints: NavigationCheckpoint {
    public static var settings: NavigationCheckpoint<Int> { checkpoint() }
}
```

We then establish our checkpoint, but this time we add a handler that receives our value type.
```swift
// Define a checkpoint with a value handler.
.navigationCheckpoint(KnownCheckpoints.settings) { result in
    returnValue = result
}
```
And then later on when we're ready to return we call `returnToCheckpoint` as usual, but in this case passing our return value as well. 
```swift
// Return, passing a value.
Button("Return to Settings Checkpoint Passing Value 5") {
    navigator.returnToCheckpoint(KnownCheckpoints.settings, value: 5)
}
```
The value type returned must match the checkpoint definition, otherwise you'll get a compiler error.

Checkpoint return values come in handy when enabling state restoration in our navigation system, especially since view bindings and callback closures can't be persisted to external storage.

> Important: The value types specified in the handler and sent by the return function must match. If they don't then the handler will not be called.

Checkpoints are a powerful tool. Use them.
