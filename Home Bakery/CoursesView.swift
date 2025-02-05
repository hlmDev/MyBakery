import SwiftUI
import MapKit
import Foundation

struct CoursesView: View {
    @ObservedObject var viewModel: BakeryViewModel
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                .padding()
                .background(Color.white.opacity(0.9))
                .cornerRadius(10)
                .padding()
                
                // Courses List
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredCourses) { course in
                            NavigationLink(destination: CourseDetailView(course: course)) {
                                CourseCard(course: course)
                                    .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.vertical)
                }
            }
            .background(BakeryColors.background.ignoresSafeArea())
            .navigationTitle("Courses")
        }
    }
    
    var filteredCourses: [BakeryCourse] {
        if searchText.isEmpty {
            return viewModel.courses
        } else {
            return viewModel.courses.filter { course in
                course.title.lowercased().contains(searchText.lowercased())
            }
        }
    }
}
struct CourseDetailView: View {
    let course: BakeryCourse
    @State private var region: MKCoordinateRegion
    @EnvironmentObject private var appState: AppState  // Add this
    
    init(course: BakeryCourse) {
        self.course = course
        _region = State(initialValue: MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: course.locationLatitude,
                longitude: course.locationLongitude
            ),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Course Image
                AsyncImage(url: URL(string: course.imageURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle().foregroundColor(BakeryColors.accent.opacity(0.3))
                }
                .frame(height: 300)
                .clipped()
                
                VStack(alignment: .leading, spacing: 24) {
                    // About the course section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("About the course:")
                            .font(.headline)
                        
                        Text(course.description)
                            .foregroundColor(.secondary)
                    }
                    
                    // Course details
                    VStack(alignment: .leading, spacing: 16) {
                        // Chef info
                        HStack {
                            Text("Chef:")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text("Ali Boholaiqa")
                                .font(.subheadline)
                        }
                        
                        // Level and Duration
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Level:")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text(course.level.capitalized)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(levelColor(course.level).opacity(0.2))
                                    .foregroundColor(levelColor(course.level))
                                    .cornerRadius(12)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing) {
                                Text("Duration:")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text("2h")
                                    .font(.subheadline)
                            }
                        }
                        
                        // Date and Location
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Date & time:")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text(formatDate(course.startDate))
                                    .font(.subheadline)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing) {
                                Text("Location:")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text(course.locationName)
                                    .font(.subheadline)
                            }
                        }
                    }
                    
                    // Map with actual location
                    Map(coordinateRegion: $region, annotationItems: [course]) { location in
                        MapMarker(coordinate: CLLocationCoordinate2D(
                            latitude: location.locationLatitude,
                            longitude: location.locationLongitude
                        ))
                    }
                    .frame(height: 200)
                    .cornerRadius(12)
                    
                    // Fixed Book button
                    Button(action: {
                        appState.bookCourse(course)
                    }) {
                        Text("Book a space")
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(BakeryColors.primary)
                            .cornerRadius(12)
                    }
                    .padding(.top, 20)
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func formatDate(_ timestamp: Double) -> String {
        let date = Date(timeIntervalSince1970: timestamp)
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM - h:mm a"
        return formatter.string(from: date)
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
}
