//
//  SubscriptionsView.swift
//  PurchaselySampleV2
//
//  Lists the current user's subscriptions (Purchasely.userSubscriptions()).
//  Handy for verifying a Web2App redemption attached a subscription (MOB-266).
//

import SwiftUI

struct SubscriptionsView: View {

    @StateObject private var viewModel = SubscriptionsViewModel()

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    var body: some View {
        VStack {
            Rectangle()
                .foregroundColor(.main)
                .frame(maxHeight: 1)
                .navigationBarTitle("Subscriptions", displayMode: .inline)

            ZStack(alignment: .top) {
                Color.backgroundGrey

                content()
            }
            .background(Color.backgroundGrey)
            .toastView(toast: $viewModel.toast)

        }.frame(maxWidth: .infinity,
                maxHeight: .infinity,
                alignment: .top)
        .background(Color.main)
    }

    @ViewBuilder
    private func content() -> some View {
        switch viewModel.viewState {
        case .loading:
            ProgressView("Loading subscriptions…")
                .padding(.top, 40)
        case .content, .failure:
            if viewModel.subscriptions.isEmpty {
                EmptyStateView()
            } else {
                SubscriptionsListView()
            }
        }
    }

    private func RefreshButton() -> some View {
        Button(action: { viewModel.load(invalidateCache: true) }, label: {
            Text("Refresh (invalidate cache)")
                .frame(maxWidth: .infinity)
                .bold()
        }).tint(.main)
            .controlSize(.large)
            .buttonStyle(.borderedProminent)
            .padding()
    }

    private func EmptyStateView() -> some View {
        VStack(spacing: 16) {
            Text("No subscriptions")
                .font(.title2)
                .bold()
            Text("This user has no active subscriptions. Redeem a link or purchase a plan, then refresh.")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            RefreshButton()
        }
        .card()
        .padding(.top, 15)
    }

    private func SubscriptionsListView() -> some View {
        VStack(spacing: 0) {
            RefreshButton()
            List {
                ForEach(viewModel.subscriptions) { subscription in
                    SubscriptionRow(subscription)
                }
            }
            .listRowSpacing(10)
        }
    }

    private func SubscriptionRow(_ subscription: SampleSubscriptionObject) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(subscription.productName)
                .font(.title2)
                .bold()
            row("Plan", subscription.planName)
            row("Status", subscription.status)
            row("Source", subscription.source)
            row("Environment", subscription.environment)
            row("Offer type", subscription.offerType)
            if let country = subscription.storeCountry {
                row("Store country", country)
            }
            if let purchasedAt = subscription.purchasedAt {
                row("Purchased", Self.dateFormatter.string(from: purchasedAt))
            }
            if let nextRenewalAt = subscription.nextRenewalAt {
                row("Next renewal", Self.dateFormatter.string(from: nextRenewalAt))
            }
            if let cancelledAt = subscription.cancelledAt {
                row("Cancelled", Self.dateFormatter.string(from: cancelledAt))
            }
            row("Revenue (USD)", String(format: "%.2f", subscription.cumulatedRevenuesInUsd))
        }
        .padding(.vertical, 4)
    }

    private func row(_ title: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .font(.subheadline)
                .multilineTextAlignment(.trailing)
        }
    }
}
