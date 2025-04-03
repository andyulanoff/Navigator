//
//  NavigationOperations.swift
//  Navigator
//
//  Created by Michael Long on 1/18/25.
//

import SwiftUI
import NavigationBackport

extension Navigator {

    /// Navigates to a specific ``NavigationDestination`` using the destination's ``NavigationMethod``.
    ///
    /// This may push an item onto the stacks navigation path, or present a sheet or fullscreen cover view.
    /// ```swift
    /// Button("Button Navigate to Home Page 55") {
    ///     navigator.navigate(to: HomeDestinations.pageN(55))
    /// }
    /// ```
    @MainActor
    public func navigate<D: NavigationDestination>(to destination: D) {
        navigate(to: destination, method: destination.method)
    }

    /// Navigates to a specific NavigationDestination overriding the destination's specified navigation method.
    /// ```swift
    /// Button("Button Present Home Page 55") {
    ///     navigator.navigate(to: HomeDestinations.pageN(55), method: .sheet)
    /// }
    /// ```
    @MainActor
    public func navigate<D: NavigationDestination>(to destination: D, method: NavigationMethod) {
        switch method {
        case .push:
            push(destination)

        case .send:
            send(destination)

        case .sheet, .managedSheet:
            guard state.sheet?.id != destination.id else { return }
            log(.navigation(.presenting(destination)))
            state.sheet = AnyNavigationDestination(wrapped: destination, method: method)

        case .cover, .managedCover:
            guard state.cover?.id != destination.id else { return }
            log(.navigation(.presenting(destination)))
            #if os(iOS)
            state.cover = AnyNavigationDestination(wrapped: destination, method: method)
            #else
            state.sheet = AnyNavigationDestination(wrapped: destination, method: method)
            #endif

        }
    }

}

extension Navigator {

    /// Pushes a new ``NavigationDestination`` onto the stack's navigation path.
    /// ```swift
    /// Button("Button Push Home Page 55") {
    ///     navigator.push(HomeDestinations.pageN(55))
    /// }
    /// ```
    /// Also supports plain Hashable values for better integration with existing code bases.
    @MainActor
    public func push<D: Hashable>(_ destination: D) {
        log(.navigation(.pushing(destination)))
        if let destination = destination as? any Hashable & Codable {
            state.path.append(destination) // ensures NBNavigationPath knows type is Codable
        } else {
            state.path.append(destination)
        }
    }

    /// Pops to a specific position on stack's navigation path.
    @MainActor
    @discardableResult
    public func pop(to position: Int)  -> Bool {
        log(.navigation(.popping))
        return state.pop(to: position)
    }

    /// Pops the specified number of the items from the end of a stack's navigation path.
    ///
    /// Defaults to one if not specified.
    /// ```swift
    /// Button("Go Back") {
    ///     navigator.pop()
    /// }
    /// ```
    @MainActor
    @discardableResult
    public func pop(last k: Int = 1) -> Bool {
        if state.path.count >= k {
            log(.navigation(.popping))
            state.path.removeLast(k)
            return true
        }
        return false
    }

    /// Pops all items from the current navigation path, returning to the root view.
    /// ```swift
    /// Button("Go Root") {
    ///     navigator.popAll()
    /// }
    /// ```
    @MainActor
    @discardableResult
    public func popAll() -> Bool {
        state.popAll()
    }

    /// Pops all items from *any* navigation path, returning each to the root view.
    /// ```swift
    /// Button("Pop Any") {
    ///     navigator.popAny()
    /// }
    /// ```
    @MainActor
    @discardableResult
    public func popAny() throws -> Bool {
        try state.popAny()
    }

    /// Pops an items from the navigation path, or dismiss if we're on the root view.
    /// ```swift
    /// Button("Go Back") {
    ///     navigator.back()
    /// }
    /// ```
    /// This mimics standard SwiftUI dismiss behavior.
    @MainActor
    @discardableResult
    public func back() -> Bool {
        pop() || dismiss()
    }

    /// Indicates whether or not the navigation path is empty.
    public nonisolated var isEmpty: Bool {
        state.path.isEmpty
    }

    /// Number of items in the navigation path.
    public nonisolated var count: Int {
        state.path.count
    }

}

extension View {

    public func navigate(to destination: Binding<(some NavigationDestination)?>) -> some View {
        self.modifier(NavigateToModifier(destination: destination, method: destination.wrappedValue?.method ?? .push))
    }

    public func navigate(to destination: Binding<(some NavigationDestination)?>, method: NavigationMethod) -> some View {
        self.modifier(NavigateToModifier(destination: destination, method: method))
    }

    public func navigate(trigger: Binding<Bool>, destination: some NavigationDestination) -> some View {
        self.modifier(NavigateTriggerModifier(trigger: trigger, destination: destination, method: destination.method))
    }

    public func navigate(trigger: Binding<Bool>, destination: some NavigationDestination, method: NavigationMethod) -> some View {
        self.modifier(NavigateTriggerModifier(trigger: trigger, destination: destination, method: method))
    }

}

extension NavigationState {

    /// Pops to a specific position on stack's navigation path.
    internal func pop(to position: Int)  -> Bool {
        if position <= path.count {
            path.removeLast(path.count - position)
            return true
        }
        return false
    }

    internal func popAll() -> Bool {
        let result = !path.isEmpty
        path = NBNavigationPath()
        return result
    }

    internal func popAny() throws -> Bool {
        guard !isNavigationLocked else {
            log(.warning("Navigator \(id) error navigation locked"))
            throw NavigationError.navigationLocked
        }
        return root.recursivePopAny()
    }

    internal func recursivePopAny() -> Bool {
        var popped = popAll()
        for child in children.values {
            if let child = child.object {
                popped = child.recursivePopAny() || popped
            }
        }
        return popped
    }

}

private struct NavigateToModifier<T: NavigationDestination>: ViewModifier {
    @Binding internal var destination: T?
    internal let method: NavigationMethod
    @Environment(\.navigator) internal var navigator: Navigator
    func body(content: Content) -> some View {
        content
            .onChange(of: destination) { destination in
                if let destination {
                    navigator.navigate(to: destination, method: method)
                    self.destination = nil
                }
            }
    }
}

private struct NavigateTriggerModifier<T: NavigationDestination>: ViewModifier {
    @Binding internal var trigger: Bool
    let destination: T
    internal let method: NavigationMethod
    @Environment(\.navigator) internal var navigator: Navigator
    func body(content: Content) -> some View {
        content
            .onChange(of: trigger) { trigger in
                if trigger {
                    navigator.navigate(to: destination, method: method)
                    self.trigger = false
                }
            }
    }
}
