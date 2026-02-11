import SwiftUI

struct QuranTabView: View {
    @EnvironmentObject var router: Router
    @EnvironmentObject var viewModel: QuranTabViewModel
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color(hex: "062629"), location: 0.0),
                    .init(color: Color(hex: "041315"), location: 1.0)
                ]),
                startPoint: .bottom,
                endPoint: .top
            )
            .ignoresSafeArea()
            
            // Main Content
            VStack {
                Text("As-salamu alaykum, Jane!")
                    .font(.system(.title, design: .serif))
                    .italic()
                    .foregroundColor(.white)
                    .padding(.top, 54)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                
                VStack {
                    HStack(spacing: 0) {
                        Image("fire")
                        Text("0 days")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(Color(hex: "ADA666"))
                    }
                    .padding(.trailing, 32)
                    
                    Text("Start a new streak")
                        .font(.system(.footnote))
                        .foregroundStyle(Color(hex: "DBDABD"))
                }
                .padding(.top, 24)
                
                Button {
                    print("start focus session")
                } label: {
                    Text("Start Focus Session")
                        .padding()
                        .background(Color(hex: "1A494D"))
                        .foregroundColor(Color(hex: "DBDABD"))
                        .font(.system(.body, weight: .regular))
                        .clipShape(Capsule())
                }
                .padding(.top, 48)
                
                Spacer()
            }
        }
        .navigationTitle("Quran")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    router.navigate(to: .listenSession)
                } label: {
                    Image(systemName: "speaker.wave.2.fill")
                        .foregroundColor(Color(hex: "4facfe"))
                }
            }
        }
        .errorAlert(isError: $viewModel.showError, errorMessage: $viewModel.errorMessage)
        .task {
            if viewModel.surahs.isEmpty {
                await viewModel.loadSurahs()
            }
        }
        .onChange(of: viewModel.searchQuery) { _, _ in
            viewModel.searchSurahs()
        }
    }
}
