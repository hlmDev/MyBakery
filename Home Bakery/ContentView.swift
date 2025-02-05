import SwiftUI
import Foundation

// MARK: - Color Theme
struct BakeryColors {
    static let primary = Color("Primary")
    static let secondary = Color("Brown")
    static let accent = Color("Cream")
    static let background = Color("Background")
    static let grey = Color("Grey")
    static let white = Color.white
    static let text = Color("Brown")
}

// MARK: - API Service
import Foundation

class BakeryAPIService {
    private let baseURL = "https://api.airtable.com/v0/appXMW3ZsAddTpClm"
    private let token = "Bearer pat7E88yW3dgzlY61.2b7d03863aca9f1262dcb772f7728bd157e695799b43c7392d5faf4f52fcb001"

    func fetchAllCourses() async throws -> [BakeryCourse] {
        guard let url = URL(string: "\(baseURL)/course") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(token, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let airtableResponse = try JSONDecoder().decode(AirtableResponse<BakeryCourse>.self, from: data)
        return airtableResponse.records.map { record in
            var course = record.fields
            course.id = record.fields.id // Use the id from fields
            return course
        }
    }
}

// MARK: - Models
struct AirtableResponse<T: Codable>: Codable {
    let records: [AirtableRecord<T>]
}

struct AirtableRecord<T: Codable>: Codable {
    let id: String
    let fields: T
}

struct BakeryCourse: Identifiable, Codable {
    var id: String
    let title: String
    let description: String
    let imageURL: String
    let level: String
    let startDate: Double
    let endDate: Double
    let locationName: String
    let locationLatitude: Double
    let locationLongitude: Double
    
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case title = "title"
        case description = "description"
        case imageURL = "image_url"
        case level = "level"
        case startDate = "start_date"
        case endDate = "end_date"
        case locationName = "location_name"
        case locationLatitude = "location_latitude"
        case locationLongitude = "location_longitude"
    }
}

struct BakeryChef: Identifiable, Codable {
    let id: String
    let name: String
    let experience: String
}

struct User: Identifiable, Codable {
    let id: String
    let name: String
    let email: String
    let profileImage: String? // ✅ Make sure it's optional
}
// MARK: - ViewModel
class BakeryViewModel: ObservableObject {
    @Published var courses: [BakeryCourse] = []

    private let apiService = BakeryAPIService()

    init() {
        Task {
            await loadData()
        }
    }

    @MainActor
    private func loadData() async {
        do {
            self.courses = try await apiService.fetchAllCourses()
        } catch {
            print("Error loading data: \(error)")
        }
    }
}

// MARK: - UI Components
struct CourseCard: View {
    let course: BakeryCourse
    
    var body: some View {
        HStack(spacing: 12) {
            // Course Image
            AsyncImage(url: URL(string: course.imageURL)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle().foregroundColor(BakeryColors.accent.opacity(0.3))
            }
            .frame(width: 80, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Course Info
            VStack(alignment: .leading, spacing: 4) {
                Text(course.title)
                    .font(.system(.headline))
                    .foregroundColor(BakeryColors.text)
                
                // Level Tag
                Text(course.level.capitalized)
                    .font(.system(.caption))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(levelColor(course.level).opacity(0.2))
                    .foregroundColor(levelColor(course.level))
                    .clipShape(Capsule())
                
                HStack(spacing: 4) {
                    // Duration
                    Image(systemName: "clock")
                        .font(.caption)
                    Text("2h")
                        .font(.caption)
                    
                    Spacer()
                    
                    // Date
                    Image(systemName: "calendar")
                        .font(.caption)
                    Text(formatDate(course.startDate))
                        .font(.caption)
                }
                .foregroundColor(BakeryColors.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(radius: 2)
    }
    
    private func levelColor(_ level: String) -> Color {
        switch level.lowercased() {
        case "beginner":
            return Color.brown
        case "intermediate":
            return Color.orange
        case "advanced":
            return Color.red
        default:
            return BakeryColors.primary
        }
    }
    
    private func formatDate(_ timestamp: Double) -> String {
        let date = Date(timeIntervalSince1970: timestamp)
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM - h:mm a"
        return formatter.string(from: date)
    }
}

struct BakeryTabBar: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        HStack {
            TabBarButton(imageName: "house.fill", title: "Home", isSelected: selectedTab == 0)
                .onTapGesture { selectedTab = 0 }

            TabBarButton(imageName: "book.fill", title: "Courses", isSelected: selectedTab == 1)
                .onTapGesture { selectedTab = 1 }

            TabBarButton(imageName: "person.fill", title: "Profile", isSelected: selectedTab == 2)
                .onTapGesture { selectedTab = 2 }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(radius: 4)
    }
}

struct TabBarButton: View {
    let imageName: String
    let title: String
    let isSelected: Bool
    
    var body: some View {
        VStack {
            Image(systemName: imageName)
                .foregroundColor(isSelected ? BakeryColors.primary : BakeryColors.secondary)

            Text(title)
                .font(.caption)
                .foregroundColor(isSelected ? BakeryColors.primary : BakeryColors.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
// MARK: - Screens
struct HomeView: View {
    @ObservedObject var viewModel: BakeryViewModel
    
    var body: some View {
        NavigationView {  // Add this
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Upcoming")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(BakeryColors.text)
                        .padding(.horizontal)

                    if let nextCourse = viewModel.courses.first {
                        NavigationLink(destination: CourseDetailView(course: nextCourse)) {  // Add this
                            CourseCard(course: nextCourse)
                                .padding(.horizontal)
                        }
                    }

                    Text("Popular Courses")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(BakeryColors.text)
                        .padding(.horizontal)

                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.courses) { course in
                            NavigationLink(destination: CourseDetailView(course: course)) {  // Add this
                                CourseCard(course: course)
                                    .padding(.horizontal)
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Home Bakery")  // Add this
        }
    }
}

struct ContentView: View {
    @StateObject private var viewModel = BakeryViewModel()
    @EnvironmentObject private var appState: AppState
    @State private var selectedTab = 0

    var body: some View {
        VStack {
            switch selectedTab {
            case 0:
                HomeView(viewModel: viewModel)
            case 1:
                CoursesView(viewModel: viewModel)
            case 2:
                ProfileView()
            default:
                ProfileView()
            }
            
            BakeryTabBar(selectedTab: $selectedTab)
        }
        .background(BakeryColors.background.ignoresSafeArea())
    }
}

struct ProfileView: View {
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        VStack(spacing: 0) {
            // Profile Header
            VStack(spacing: 16) {
                HStack {
                    Text("Profile")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Button(action: {
                        // Handle edit action
                    }) {
                        Text("Edit")
                            .foregroundColor(Color(red: 0.76, green: 0.45, blue: 0.33)) // Brown color from the image
                    }
                }
                .padding(.horizontal)
                
                // Profile Info
                HStack(spacing: 12) {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.gray)
                    
                    Text("Ali Boholaiqa")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Spacer()
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
            .background(Color.white)
            
            // Booked Courses Section
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Booked courses")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                        .padding(.top)
                    
                    // Booked Courses List
                    VStack(spacing: 12) {
                        ForEach(appState.bookedCourses) { course in
                            BookedCourseCardCompact(course: course)
                                .padding(.horizontal)
                        }
                    }
                }
            }
            .background(Color(UIColor.systemGray6))
        }
    }
}

struct BookedCourseCardCompact: View {
    let course: BakeryCourse
    
    var body: some View {
        HStack(spacing: 12) {
            // Course Image
            AsyncImage(url: URL(string: course.imageURL)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .foregroundColor(.gray.opacity(0.2))
            }
            .frame(width: 80, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            // Course Details
            VStack(alignment: .leading, spacing: 8) {
                Text(course.title)
                    .font(.headline)
                
                Text(course.level.capitalized)
                    .font(.subheadline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(getLevelColor(course.level).opacity(0.2))
                    .foregroundColor(getLevelColor(course.level))
                    .cornerRadius(12)
                
                HStack(spacing: 16) {
                    // Duration
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                        Text("2h")
                    }
                    
                    // Date
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                        Text(formatDate(course.startDate))
                    }
                }
                .font(.caption)
                .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
    
    private func getLevelColor(_ level: String) -> Color {
        switch level.lowercased() {
        case "beginner":
            return Color.brown
        case "intermediate":
            return Color.orange
        case "advanced":
            return Color.red
        default:
            return BakeryColors.primary
        }
    }
    
    private func formatDate(_ timestamp: Double) -> String {
        let date = Date(timeIntervalSince1970: timestamp)
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM - h:mm"
        return formatter.string(from: date)
    }
}

struct TabBarItem: View {
    let imageName: String
    let title: String
    var isSelected: Bool = false
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: imageName)
                .font(.system(size: 24))
            Text(title)
                .font(.caption)
        }
        .foregroundColor(isSelected ? BakeryColors.primary : .gray)
        .frame(maxWidth: .infinity)
    }
}

struct BookedCourseCard: View {
    let course: BakeryCourse
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Course Image
            AsyncImage(url: URL(string: course.imageURL)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .foregroundColor(.gray.opacity(0.2))
            }
            .frame(height: 140)
            .clipped()
            .cornerRadius(12)
            
            // Course Details
            VStack(alignment: .leading, spacing: 8) {
                Text(course.title)
                    .font(.title3)
                    .fontWeight(.semibold)
                
                HStack(spacing: 8) {
                    Text(course.level.capitalized)
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(getLevelColor(course.level).opacity(0.2))
                        .foregroundColor(getLevelColor(course.level))
                        .cornerRadius(12)
                    
                    Spacer()
                }
                
                HStack(spacing: 16) {
                    // Duration
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                        Text("2h")
                    }
                    
                    // Date
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                        Text(formatDate(course.startDate))
                    }
                }
                .font(.subheadline)
                .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    private func getLevelColor(_ level: String) -> Color {
        switch level.lowercased() {
        case "beginner":
            return Color.brown
        case "intermediate":
            return Color.orange
        case "advanced":
            return Color.red
        default:
            return BakeryColors.primary
        }
    }
    
    private func formatDate(_ timestamp: Double) -> String {
        let date = Date(timeIntervalSince1970: timestamp)
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM - h:mm"
        return formatter.string(from: date)
    }
}

// Add this new component for booked courses
    
  //  private func signOut() {
       // appState.isAuthenticated = false
     //   appState.currentUser = nil
  //  }

//
//  SignInView.swift
//  Home Bakery
//
//  Created by Ahlam Majed on 05/02/2025.
//


struct SignInView: View {
    @EnvironmentObject private var appState: AppState
    @State private var email = ""
    @State private var password = ""
    @State private var showingError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image("bakery-logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .padding(.top, 50)

                Text("Home Bakery")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(BakeryColors.primary)

                Text("Baked to Perfection")
                    .font(.subheadline)
                    .foregroundColor(BakeryColors.secondary)
                    .padding(.bottom, 40)

                VStack(spacing: 16) {
                    TextField("Email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)

                    SecureField("Password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                    Button(action: signIn) {
                        if appState.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Sign In")
                                .foregroundColor(.white)
                                .font(.headline)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(BakeryColors.primary)
                    .cornerRadius(10)
                    .disabled(appState.isLoading)
                }
                .padding(.horizontal)

                Spacer()
            }
            .padding()
            .background(BakeryColors.background)
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    private func signIn() {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in all fields"
            showingError = true
            return
        }

        appState.isLoading = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: DispatchWorkItem {
            appState.isLoading = false
            appState.isAuthenticated = true
            appState.currentUser = User(
                id: "1",
                name: "Test User",
                email: email,
                profileImage: nil
            )
        })

    }



}

