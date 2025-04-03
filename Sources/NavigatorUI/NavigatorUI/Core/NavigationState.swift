//
//  NavigationState.swift
//  Navigator
//
//  Created by Michael Long on 1/17/25.
//

import Combine
import SwiftUI
import NavigationBackport

/// Persistent storage for Navigators.
public class NavigationState: ObservableObject, @unchecked Sendable {

    public enum Owner: Int {
        case application
        case root
        case stack
        case presenter
    }

    /// Navigation path for the current ManagedNavigationStack
    @Published internal var path: NBNavigationPath = .init() {
        didSet {
            cleanCheckpoints()
            pathChangedCounter += 1
        }
    }

    /// Presentation trigger for .sheet navigation methods.
    @Published internal var sheet: AnyNavigationDestination? = nil

    /// Presentation trigger for .cover navigation methods.
    @Published internal var cover: AnyNavigationDestination? = nil

    /// Dismiss trigger for ManagedNavigationStack or navigationDismissible views.
    @Published internal var triggerDismiss: Bool = false

    /// Checkpoints managed by this navigation stack
    @Published internal var checkpoints: [String: AnyNavigationCheckpoint] = [:]

    /// Navigation locks, if any
    @Published internal var navigationLocks: Set<UUID> = []

    /// Persistent id of this navigator.
    internal var id: UUID = .init()

    /// Name of the current ManagedNavigationStack, if any.
    internal var name: String? = nil

    /// Owner of this particular state object.
    internal var owner: Owner = .root

   /// Copy of the navigation configuration from the root view.
    internal var configuration: NavigationConfiguration?

    /// Determines whether or not users should see animation steps when deep linking.
    public var executionDelay: TimeInterval {
        configuration?.executionDelay ?? 0.6
    }

    /// Update counter for navigation path.
    internal var pathChangedCounter: Int = 0

    /// Parent navigator, if any.
    internal weak var parent: NavigationState? = nil

    /// Presented children, if any.
    internal var children: [UUID : WeakObject<NavigationState>] = [:]

    /// True if the current ManagedNavigationStack or navigationDismissible is presented.
    internal var isPresented: Bool = false

    /// Navigation send publisher
    internal var publisher: PassthroughSubject<NavigationSendValues, Never> = .init()

    /// Allows public initialization of root Navigators.
    internal init(configuration: NavigationConfiguration? = nil) {
        self.name = "root"
        self.configuration = configuration
        log(.lifecycle(.configured))
    }

    /// Internal initializer used by ManagedNavigationStack and navigationDismissible modifiers.
    internal init(owner: Owner, name: String?) {
        self.owner = owner
        self.name = name
    }

    /// Sentinel code removes child from parent when Navigator is dismissed or deallocated.
    deinit {
        log(.lifecycle(.deinit))
        parent?.removeChild(self)
    }

    /// Walks up the parent tree and returns the root Navigator.
    internal lazy var root: NavigationState = {
        parent?.root ?? self
    }()

    /// Adds a child state to parent.
    internal func addChild(_ child: NavigationState, isPresented: Bool) {
        guard !children.keys.contains(child.id) else {
            return
        }
        children[child.id] = WeakObject(object: child)
        child.configuration = configuration
        child.parent = self
        child.publisher = publisher
        child.isPresented = isPresented
        log(.lifecycle(.adding(child.id)))
    }

    /// Removes a child state from a parent.
    internal func removeChild(_ child: NavigationState) {
        log(.lifecycle(.removing(child.id)))
        children.removeValue(forKey: child.id)
    }

    /// Renames state for wrapped navigation stacks.
    internal func setting(_ name: String?) -> NavigationState {
        self.name = name
        return self
    }

}

extension NavigationState: Hashable, Equatable {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
        hasher.combine(self.name)
        hasher.combine(self.pathChangedCounter)
        hasher.combine(self.checkpoints)
        hasher.combine(self.sheet)
        hasher.combine(self.cover)
    }

    public static func == (lhs: NavigationState, rhs: NavigationState) -> Bool {
        lhs.id == rhs.id
    }

}

extension NavigationState {

    /// Errors that Navigator can throw
    public enum NavigationError: Error {
        case navigationLocked
    }

    /// Allows weak storage of reference types in arrays, dictionaries, and other collection types.
    internal struct WeakObject<T: AnyObject> {
        weak var object: T?
    }

}
