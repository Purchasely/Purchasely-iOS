//  AppRouter.swift
//
//  The navigation state of the sample. An `ObservableObject` bound to `NavigationStack(path:)`.
//  Route decisions (push/pop/present) live here; how a route is rendered is the view's concern.

import Foundation
import Combine

@MainActor
public final class AppRouter: ObservableObject {

    /// The navigation stack bound to `NavigationStack(path:)`. NOT `private(set)`: SwiftUI needs a
    /// read-write binding to drive back-navigation (pop/swipe).
    @Published public var path: [AppRoute] = []

    /// A pending modal presentation, rendered with SwiftUI `.sheet` / `.fullScreenCover`.
    @Published public var modal: ModalRequest?

    public struct ModalRequest: Identifiable, Hashable, Sendable {
        public let id: UUID
        public let route: AppRoute
        public let style: PresentationStyle
        public init(id: UUID = UUID(), route: AppRoute, style: PresentationStyle) {
            self.id = id
            self.route = route
            self.style = style
        }
    }

    public init() {}

    public func push(_ route: AppRoute) {
        path.append(route)
    }

    public func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    public func popToRoot() {
        path.removeAll()
    }

    /// Replace the whole stack (e.g. deep-link landing).
    public func setPath(_ routes: [AppRoute]) {
        path = routes
    }

    public func present(_ route: AppRoute, style: PresentationStyle = .sheet) {
        modal = ModalRequest(route: route, style: style)
    }

    public func dismissModal() {
        modal = nil
    }
}
