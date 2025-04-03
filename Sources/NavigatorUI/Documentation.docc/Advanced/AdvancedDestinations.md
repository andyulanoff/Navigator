# Advanced Destinations

Building NavigationDestinations that access the environment and other use cases 

## External NavigationDestinations

Earlier we demonstrated how to provide ``NavigationDestination`` types with a view body that returns the correct view for that type.
```swift
extension HomeDestinations: NavigationDestination {
    public var body: some View {
        switch self {
        case .page2:
            HomePage2View()
        case .page3:
            HomePage3View()
        ...
        }
    }
}
```
It's a powerful technique, but what if we can't construct a specific view without external dependencies or without accessing the environment? 

### Destination Views

Simple. Just delegate the view building to a standard SwiftUI view!
```swift
extension HomeDestinations: NavigationDestination {
    public var body: some View {
        HomeDestinationsView(destination: self)
    }
}

private struct HomeDestinationsView: View {
    let destination: HomeDestinations
    @Environment(\.homeDependencies) var resolver
    var body: some View {
        switch self {
        case .home:
            HomePageView(viewModel: HomePageViewModel(dependencies: resolver))
        case .page2:
            HomePage2View(viewModel: HomePage2ViewModel(dependencies: resolver))
        case .page3:
            HomePage3View(viewModel: HomePage3ViewModel(dependencies: resolver))
        case .pageN(let value):
            HomePageNView(dependencies: resolver, number: value)
        case .external:
            resolver.externalView()
        }
    }
}
```
In the above code, we obtain a `homeDependencies` resolver from the environment and then use it to construct our views
and view models.

### Passing Dependencies

Note that some of the examples expose the view model to the caller, and that's a practice I would generally argue against. The fact that a view has a view model (or not) is an implementation detail and should be private to the view itself. 

Further, exposing the view model and its requirements complicates the call sites and really just kicks the can down the road. Sure, my VM gets its dependencies injected, but how does the *caller* get them to inject?

But creating a *private* destination view means that external dependency is never exposed to the outside world... and that tends to mitigate the problem in my book. 

```swift
case .page2:
    HomePage2View(viewModel: HomePage2ViewModel(dependencies: resolver))
```

Sites specify the desired view using its enumerated value, but they never see the actual view, nor are they concerned with its requirements.

Alternatively, one could simply pass our environment-based dependency resolver to the view and let the view handle it as needed.
```swift
case .pageN(let value):
    HomePageNView(dependencies: resolver, number: value)

struct HomePageNView: View {
    @StateObject private var viewModel: HomePageNViewModel
    init(dependencies: HomeDependencies, number: Int) {
        self._viewModel = .init(wrappedValue: .init(dependencies: dependencies, number: number))
    }
    var body: some View {
        ...
    }
}
```
*See the 'DemoDependency.swift' file in the NavigatorDemo project for a possible dependency injection mechanism.*

## NavigationDestinations within Views

This technique also allows us to construct and use fully functional views elsewhere in our view code. Consider.
```swift
struct RootHomeView: View {
    var body: some View {
        ManagedNavigationStack {
            HomeDestinations.home
                .nbNavigationDestination(HomeDestinations.self)
        }
    }
}
```
Remember, our enumerated values are Views! Just drop the value into a view to obtain a fully resolved `HomePageView` and view model from `HomeDestinationsView`, 
complete and ready to go.

## Custom Sheets using NavigationDestination
Let's demonstrate that again using a custom presentation mechanism with detents.

Only this time instead of evaluating the enumerated value directly we'll do the same using a destination variable.
```swift
struct CustomSheetView: View {
    @State private var showSettings: SettingsDestinations?
    var body: some View {
        List {
            Button("Present Page 2 via Sheet") {
                showSettings = .page2
            }
            Button("Present Page 3 via Sheet") {
                showSettings = .page3
            }
            .sheet(item: $showSettings) { destination in
                destination // obtain view
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                    .navigationDismissible()
            }
        }
    }
}
```
Setting the variable passes the desired destination to the sheet closure via the `$showSettings` binding. Which again allows us to directly evaluate the value and obtain a fully resolved view ready for presentation.

## Cross Module View Dependencies
Another technique that might not be apparent and you might have missed at first glance is how this gives us the ability to pass required views across features.

Take another look at our `HomeDestinationsView`.
```swift
private struct HomeDestinationsView: View {
    let destination: HomeDestinations
    @Environment(\.homeDependencies) var resolver
    var body: some View {
        switch self {
        ...
        case .external:
            resolver.externalView()
        }
    }
}
```
Note how our feature get an externally provided view from our dependency resolver. 

The Home feature doesn't know what module or feature provided the view. Nor should it care. It just knows that it needs it and that its up to `HomeDependencies` to provide it.

The application, however, sees all, knows all, and can provide the missing cross-module dependency.
```swift
typealias AppDependencies = CoreDependencies
    & HomeDependencies
    & SettingsDependencies

class AppResolver: AppDependencies {
    ...
    @MainActor func externalView() -> AnyView {
        // reach out to the settings module to provide the view needed
        SettingsDestinations.external.asAnyView()
    }
    ...
}
```
Have I mentioned how powerful this technique is?

## See Also

- <doc:Destinations>
