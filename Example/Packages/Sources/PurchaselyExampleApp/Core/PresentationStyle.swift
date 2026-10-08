//  PresentationStyle.swift
//
//  How a modal route is requested: pushed, as a sheet, or full screen.

import Foundation

public enum PresentationStyle: Hashable, Sendable {
    case push
    case sheet
    case fullScreen
}
