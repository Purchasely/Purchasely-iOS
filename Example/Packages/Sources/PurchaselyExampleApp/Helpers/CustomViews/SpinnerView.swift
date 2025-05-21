//
//  SpinnerView.swift
//  PurchaselySampleV2
//
//  Created by Florian Huet on 18/12/2023.
//

import SwiftUI

struct SpinnerView: View {
  var body: some View {
    ProgressView()
      .progressViewStyle(CircularProgressViewStyle(tint: .main))
      .scaleEffect(2.0, anchor: .center) // Makes the spinner larger
  }
}

struct ContentView: View {
  var body: some View {
    SpinnerView()
  }
}
