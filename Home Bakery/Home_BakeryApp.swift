//
//  Home_BakeryApp.swift
//  Home Bakery
//
//  Created by Ahlam Majed on 05/02/2025.
//

import SwiftUI

@main
struct Home_BakeryApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            if appState.isAuthenticated {
                ContentView()
                    .environmentObject(appState)
            } else {
                SignInView()
                    .environmentObject(appState)
            }
        }
    }
}

// MARK: - App State
class AppState: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var bookedCourses: [BakeryCourse] = []

    init() {
        checkAuthentication()
    }

    func bookCourse(_ course: BakeryCourse) {
        print("Booking course: \(course.title)")  // Add this debug print
        bookedCourses.append(course)
        print("Total booked courses: \(bookedCourses.count)")  // Add this debug print
    }

    private func checkAuthentication() {
        isAuthenticated = false
    }
}
