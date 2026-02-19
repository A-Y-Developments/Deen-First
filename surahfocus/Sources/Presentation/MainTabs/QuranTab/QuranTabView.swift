import SwiftUI

struct QuranTabView: View {
    @EnvironmentObject var router: Router
    @EnvironmentObject var viewModel: QuranTabViewModel
    
    var body: some View {
        VStack {
                Text("As-salamu alaykum, Jane!")
                    .font(.system(.title, design: .serif))
                    .italic()
                    .foregroundColor(.white)
                    .padding(.top, 124)
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
                
                Button {
                    router.navigate(to: .focusSection)
                } label: {
                    Text("Start Focus Session")
                        .padding(.vertical)
                        .padding(.horizontal, 48)
                        .background(Color.white)
                        .foregroundColor(Color.primary600)
                        .font(.system(.body, weight: .semibold))
                        .clipShape(Capsule())
                }
                .padding(.top, 32)
                .shadow(
                    color: Color.primary400,
                    radius: 12
                )
                
                Spacer()
        }
        .ignoresSafeArea(.all, edges: .top)
        .navigationBarHidden(true)
        .background {
            // Background
            Image("main-background")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
        }
        .task {
            if viewModel.surahs.isEmpty {
                await viewModel.loadSurahs()
            }
        }
        .onChange(of: viewModel.searchQuery) { oldValue, newValue in
            viewModel.searchSurahs()
        }
    }
}

