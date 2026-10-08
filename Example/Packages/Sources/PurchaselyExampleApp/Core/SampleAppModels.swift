//  SampleAppModels.swift
//
//  Model types shared by the settings store and the view models.

import Foundation

public enum DisplayMethodCategory: String, CaseIterable, Identifiable {
    case displayAsyncAwait = "Display API (async/await)"
    case displayObjC = "Display API (completion)"
    case fetchThenDisplay = "Fetch then Display"
    case sampleApp = "Display by Sample App"
    public var id: Self { self }
}

public enum SourceType: String, CaseIterable, Identifiable {
    case auto = "Auto"
    case placement = "Placement"
    case presentation = "Presentation"
    public var id: Self { self }
}
