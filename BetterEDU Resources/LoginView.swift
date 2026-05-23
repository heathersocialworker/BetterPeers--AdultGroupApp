import SwiftUI
import FirebaseAuth

struct LavaLampBubble: View {
    @State private var offset = CGSize.zero
    let bubbleColor: Color
    
    var body: some View {
        Circle()
            .fill(bubbleColor.opacity(0.3))
            .frame(width: CGFloat.random(in: 150...300), height: CGFloat.random(in: 150...300))
            .offset(offset)
            .onAppear {
                let randomX = CGFloat.random(in: -250...250)
                let randomY = CGFloat.random(in: -800...800)
                offset = CGSize(width: randomX, height: randomY)
                
                withAnimation(
                    Animation.easeInOut(duration: Double.random(in: 10...20))
                        .repeatForever(autoreverses: true)
                ) {
                    offset = CGSize(width: -randomX, height: -randomY)
                }
            }
    }
}

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isPasswordVisible = false
    @State private var errorMessage: String?
    @State private var isLoggedIn = false

    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "251db4")
                    .ignoresSafeArea()
                
                ForEach(0..<5, id: \.self) { _ in
                    LavaLampBubble(bubbleColor: Color(hex: ["5a0ef6", "98b6f8", "7849fd"].randomElement()!))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                
                VStack(spacing: 20) {
                    Spacer()
                    
                    Image("BetterLogo 1")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 200)
                    
                    Text("Sign In to get started")
                        .font(.custom("Impact", size: 24))
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.top, 10)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Email")
                            .font(.custom("Impact", size: 18))
                            .foregroundColor(.white)
                        TextField("name@example.com", text: $email)
                            .padding()
                            .background(Color(hex: "98b6f8"))
                            .cornerRadius(10)
                            .foregroundColor(Color(hex: "251db4"))
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Password")
                            .font(.custom("Impact", size: 18))
                            .foregroundColor(.white)

                        ZStack(alignment: .trailing) {
                            if isPasswordVisible {
                                TextField("Password", text: $password)
                                    .padding()
                                    .background(Color(hex: "98b6f8"))
                                    .cornerRadius(10)
                                    .foregroundColor(Color(hex: "251db4"))
                            } else {
                                SecureField("Password", text: $password)
                                    .padding()
                                    .background(Color(hex: "98b6f8"))
                                    .cornerRadius(10)
                                    .foregroundColor(Color(hex: "251db4"))
                            }

                            Button(action: {
                                isPasswordVisible.toggle()
                            }) {
                                Image(systemName: isPasswordVisible ? "eye" : "eye.slash")
                                    .foregroundColor(.white)
                            }
                            .padding(.trailing, 10)
                        }
                    }

                    Button(action: { signInUser() }) {
                        Text("Sign In")
                            .font(.custom("Impact", size: 30))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(hex: "5a0ef6"))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.top, 20)

                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding()
                    }

                    HStack {
                        NavigationLink(destination: ForgotPasswordView()) {
                            Text("Forgot Password?")
                                .font(.custom("Impact", size: 16))
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                        
                        NavigationLink(destination: SignUpView()) {
                            Text("Sign Up")
                                .font(.custom("Impact", size: 16))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.top, 10)

                    Spacer()
                }
                .padding()
                .fullScreenCover(isPresented: $isLoggedIn) {
                    HomePageView()
                }
            }
        }
    }
    
    private func signInUser() {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter your email and password."
            return
        }

        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                self.errorMessage = error.localizedDescription
            } else {
                self.isLoggedIn = true
            }
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
