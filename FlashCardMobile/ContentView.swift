//
//  ContentView.swift
//  FlashCardMobile
//

import SwiftUI
import UIKit

enum AppScreen {
    case splash
    case onboarding
    case main
}

struct RootView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var currentScreen: AppScreen = .splash

    var body: some View {
        Group {
            switch currentScreen {
            case .splash:
                SplashScreen {
                    if hasSeenOnboarding {
                        currentScreen = .main
                    } else {
                        currentScreen = .onboarding
                    }
                }
            case .onboarding:
                OnboardingScreen {
                    hasSeenOnboarding = true
                    currentScreen = .main
                }
            case .main:
                MainTabView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: currentScreen)
    }
}

struct MainTabView: View {
    @StateObject private var appViewModel = AppViewModel()
    @StateObject private var reviewViewModel: ReviewViewModel
    @StateObject private var statisticsViewModel: StatisticsViewModel
    @AppStorage("appearance_mode") private var appearanceModeRaw = AppearanceMode.system.rawValue

    private var appearanceMode: AppearanceMode {
        AppearanceMode(rawValue: appearanceModeRaw) ?? .system
    }

    init() {
        let app = AppViewModel()
        _appViewModel = StateObject(wrappedValue: app)
        _reviewViewModel = StateObject(wrappedValue: ReviewViewModel(appViewModel: app))
        _statisticsViewModel = StateObject(wrappedValue: StatisticsViewModel(appViewModel: app))
    }

    private enum Tab: Int {
        case learn = 0
        case review = 1
        case search = 2
        case statistics = 3
        case settings = 4
    }

    var body: some View {
        TabView(selection: Binding(
            get: { appViewModel.selectedTabIndex },
            set: { appViewModel.selectedTabIndex = $0 }
        )) {
            SubjectsScreen(viewModel: appViewModel)
                .tabItem { Label(L("tab.learn"), systemImage: "book.fill") }
                .tag(Tab.learn.rawValue)

            ReviewScreen(viewModel: reviewViewModel, appViewModel: appViewModel)
                .tabItem { Label(L("tab.review"), systemImage: "square.stack.3d.up.fill") }
                .tag(Tab.review.rawValue)

            SearchScreen(viewModel: appViewModel)
                .tabItem { Label(L("tab.search"), systemImage: "magnifyingglass.circle.fill") }
                .tag(Tab.search.rawValue)

            StatisticsScreen(viewModel: statisticsViewModel)
                .tabItem { Label(L("tab.statistics"), systemImage: "chart.bar.fill") }
                .tag(Tab.statistics.rawValue)

            SettingsScreen(appViewModel: appViewModel)
                .tabItem { Label(L("tab.settings"), systemImage: "gearshape.fill") }
                .tag(Tab.settings.rawValue)
        }
        .tint(AppTheme.iconTint)
        .onAppear {
            UITabBar.appearance().unselectedItemTintColor = UIColor(AppTheme.tabBarInactive)
        }
        .onChange(of: appViewModel.selectedTabIndex) { _, _ in
            HapticFeedback.impact()
        }
        .preferredColorScheme(appearanceMode.colorScheme)
    }
}
