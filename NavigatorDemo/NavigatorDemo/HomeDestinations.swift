//
//  TestPage.swift
//  Nav5
//
//  Created by Michael Long on 11/10/24.
//

import Navigator
import SwiftUI

public enum HomeDestinations: Codable {
    case home(String)
    case page2
    case page3
    case pageN(Int)
    case presented1
    case presented2
}

extension HomeDestinations: NavigationDestination {
    public var view: some View {
        // Illustrates external mapping of destination type to views. See Settings for simple mapping.
        HomeDestinationsView(destination: self)
    }
}

// External view mapping allows access to environment variables, in this case homeDependencies.
private struct HomeDestinationsView: View {
    // Destination to display
    let destination: HomeDestinations
    // Obtain core dependency resolver
    @Environment(\.homeDependencies) var resolver
    // Standard view body
    var body: some View {
        switch destination {
        case .home(let title):
            HomeContentView(title: title)
        case .page2:
            // Demonstrates method of injecting dependencies and building fully constructed view models
            HomePage2View(viewModel: HomePage2ViewModel(dependencies: resolver))
        case .page3:
            // Simply passing dependent value to view
            HomePage3View(initialValue: resolver.homeValue)
        case .pageN(let value):
            // Demonstrates passing resolver to view and letting it do what's needed.
            HomePageNView(dependencies: resolver, number: value)
        case .presented1:
            NestedHomeContentView(title: "Via Sheet")
        case .presented2:
            NestedHomeContentView(title: "Via Cover")
        }
    }
}

extension HomeDestinations {
    // not required but shows possibilities in predefining navigation destination types
    public var method: NavigationMethod {
        switch self {
        case .home, .page2, .page3, .pageN:
            .push
        case .presented1:
            .sheet
        case .presented2:
            .cover
        }
    }
}
