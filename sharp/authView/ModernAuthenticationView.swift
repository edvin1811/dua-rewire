import SwiftUI
import Clerk

// MARK: - Modern Authentication Container (Duolingo Style)
struct ModernAuthenticationView: View {
    @State private var showingSignUp = true
    @State private var appeared = false

    var body: some View {
        ZStack {
            ModernBackground()

            ScrollView {
                VStack(spacing: 32) {
                    Spacer(minLength: 60)

                    // App branding
                    appHeader

                    // Auth form
                    authForm

                    // Switch between sign up/in
                    authToggle

                    Spacer(minLength: 40)
                }
                .padding()
            }
        }
        .onAppear {
            withAnimation(DuoAnimation.cardBounce.delay(0.1)) {
                appeared = true
            }
        }
    }

    private var appHeader: some View {
        VStack(spacing: 20) {
            // 3D App icon/logo
            ZStack {
                // Shadow layer
                Circle()
                    .fill(Color.uwPrimaryDark)
                    .frame(width: 90, height: 90)
                    .offset(y: 4)

                // Main circle
                Circle()
                    .fill(Color.uwPrimary)
                    .frame(width: 90, height: 90)

                Image(systemName: "brain.head.profile")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.white)
            }
            .scaleEffect(appeared ? 1 : 0.5)
            .opacity(appeared ? 1 : 0)

            VStack(spacing: 8) {
                Text("Unwire")
                    .font(.duoTitle)
                    .foregroundColor(.uwTextPrimary)

                Text("Focus • Productivity • Balance")
                    .font(.duoBody)
                    .foregroundColor(.uwTextSecondary)
            }
            .offset(y: appeared ? 0 : 10)
            .opacity(appeared ? 1 : 0)
        }
    }

    private var authForm: some View {
        VStack(spacing: 24) {
            if showingSignUp {
                ModernSignUpView()
            } else {
                ModernSignInView()
            }
        }
        .offset(y: appeared ? 0 : 20)
        .opacity(appeared ? 1 : 0)
    }

    private var authToggle: some View {
        Button {
            withAnimation(DuoAnimation.tabSwitch) {
                showingSignUp.toggle()
            }
            DuoHaptics.selection()
        } label: {
            HStack(spacing: 4) {
                Text(showingSignUp ? "Already have an account?" : "Need an account?")
                    .font(.duoCaption)
                    .foregroundColor(.uwTextSecondary)

                Text(showingSignUp ? "Sign In" : "Sign Up")
                    .font(.duoCaptionBold)
                    .foregroundColor(.uwPrimary)
            }
            .padding(16)
        }
        .duoInteractiveCard(padding: 0, cornerRadius: 16)
        .offset(y: appeared ? 0 : 20)
        .opacity(appeared ? 1 : 0)
    }
}

// MARK: - Modern Sign Up View
struct ModernSignUpView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var firstName = ""
    @State private var code = ""
    @State private var isVerifying = false
    @State private var isLoading = false
    @State private var errorMessage = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("Create Account")
                .font(.duoHeadline)
                .foregroundColor(.uwTextPrimary)

            if isVerifying {
                verificationView
            } else {
                signUpForm
            }

            if !errorMessage.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.uwError)
                    Text(errorMessage)
                        .foregroundColor(.uwError)
                        .font(.duoSmall)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.uwError.opacity(0.1))
                )
            }
        }
        .duoCard(padding: 24)
    }

    private var signUpForm: some View {
        VStack(spacing: 16) {
            DuoTextField(
                text: $firstName,
                placeholder: "First Name",
                icon: "person"
            )

            DuoTextField(
                text: $email,
                placeholder: "Email",
                icon: "envelope",
                keyboardType: .emailAddress,
                autocapitalization: .never
            )

            DuoTextField(
                text: $password,
                placeholder: "Password",
                icon: "lock",
                isSecure: true
            )

            Button {
                Task {
                    await signUp()
                }
            } label: {
                HStack {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.white)
                    } else {
                        Text("Create Account")
                    }
                }
            }
            .buttonStyle(DuoPrimaryButton())
            .disabled(isLoading || email.isEmpty || password.isEmpty || firstName.isEmpty)
            .opacity((isLoading || email.isEmpty || password.isEmpty || firstName.isEmpty) ? 0.5 : 1.0)
        }
    }

    private var verificationView: some View {
        VStack(spacing: 16) {
            // 3D success icon
            ZStack {
                Circle()
                    .fill(Color.uwAccentDark)
                    .frame(width: 64, height: 64)
                    .offset(y: 3)

                Circle()
                    .fill(Color.uwAccent)
                    .frame(width: 64, height: 64)

                Image(systemName: "envelope.badge")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
            }

            Text("Check your email")
                .font(.duoSubheadline)
                .foregroundColor(.uwTextPrimary)

            Text("We sent a verification code to \(email)")
                .font(.duoSmall)
                .foregroundColor(.uwTextSecondary)
                .multilineTextAlignment(.center)

            DuoTextField(
                text: $code,
                placeholder: "Enter verification code",
                icon: "key",
                keyboardType: .numberPad
            )

            Button {
                Task {
                    await verify()
                }
            } label: {
                HStack {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.white)
                    } else {
                        Text("Verify & Continue")
                    }
                }
            }
            .buttonStyle(DuoSuccessButton())
            .disabled(isLoading || code.isEmpty)
            .opacity((isLoading || code.isEmpty) ? 0.5 : 1.0)

            Button("Resend code") {
                DuoHaptics.lightTap()
            }
            .font(.duoCaption)
            .foregroundColor(.uwTextSecondary)
        }
    }

    private func signUp() async {
        isLoading = true
        errorMessage = ""

        do {
            let signUp = try await SignUp.create(
                strategy: .standard(
                    emailAddress: email,
                    password: password,
                    firstName: firstName
                )
            )

            try await signUp.prepareVerification(strategy: .emailCode)
            withAnimation(DuoAnimation.cardBounce) {
                isVerifying = true
            }
        } catch {
            errorMessage = "Failed to create account. Please try again."
            print("Sign up error: \(error)")
        }

        isLoading = false
    }

    private func verify() async {
        isLoading = true
        errorMessage = ""

        do {
            guard let signUp = Clerk.shared.client?.signUp else {
                errorMessage = "Something went wrong. Please try again."
                isLoading = false
                return
            }

            try await signUp.attemptVerification(strategy: .emailCode(code: code))
            DuoHaptics.success()
        } catch {
            errorMessage = "Invalid verification code. Please try again."
            DuoHaptics.error()
            print("Verification error: \(error)")
        }

        isLoading = false
    }
}

// MARK: - Modern Sign In View
struct ModernSignInView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("Welcome Back")
                .font(.duoHeadline)
                .foregroundColor(.uwTextPrimary)

            VStack(spacing: 16) {
                DuoTextField(
                    text: $email,
                    placeholder: "Email",
                    icon: "envelope",
                    keyboardType: .emailAddress,
                    autocapitalization: .never
                )

                DuoTextField(
                    text: $password,
                    placeholder: "Password",
                    icon: "lock",
                    isSecure: true
                )

                Button {
                    Task {
                        await signIn()
                    }
                } label: {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(.white)
                        } else {
                            Text("Sign In")
                        }
                    }
                }
                .buttonStyle(DuoPrimaryButton())
                .disabled(isLoading || email.isEmpty || password.isEmpty)
                .opacity((isLoading || email.isEmpty || password.isEmpty) ? 0.5 : 1.0)

                Button("Forgot password?") {
                    DuoHaptics.lightTap()
                }
                .font(.duoCaption)
                .foregroundColor(.uwTextSecondary)
            }

            if !errorMessage.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.uwError)
                    Text(errorMessage)
                        .foregroundColor(.uwError)
                        .font(.duoSmall)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.uwError.opacity(0.1))
                )
            }
        }
        .duoCard(padding: 24)
    }

    private func signIn() async {
        isLoading = true
        errorMessage = ""

        do {
            try await SignIn.create(
                strategy: .identifier(email, password: password)
            )
            DuoHaptics.success()
        } catch {
            errorMessage = "Invalid email or password. Please try again."
            DuoHaptics.error()
            print("Sign in error: \(error)")
        }

        isLoading = false
    }
}

// MARK: - Duolingo-Style Text Field
struct DuoTextField: View {
    @Binding var text: String
    let placeholder: String
    let icon: String
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .words
    var isSecure: Bool = false

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 12) {
            // 3D icon circle
            ZStack {
                Circle()
                    .fill(isFocused ? Color.uwPrimary.opacity(0.2) : Color.uwTextTertiary.opacity(0.2))
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(isFocused ? .uwPrimary : .uwTextSecondary)
            }

            if isSecure {
                SecureField(placeholder, text: $text)
                    .font(.duoBody)
                    .foregroundColor(.uwTextPrimary)
                    .focused($isFocused)
            } else {
                TextField(placeholder, text: $text)
                    .keyboardType(keyboardType)
                    .textInputAutocapitalization(autocapitalization)
                    .font(.duoBody)
                    .foregroundColor(.uwTextPrimary)
                    .autocorrectionDisabled()
                    .focused($isFocused)
            }
        }
        .padding(14)
        .background(
            ZStack {
                // Shadow
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.black.opacity(0.1))
                    .offset(y: 2)

                // Main background
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.uwSurface)
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isFocused ? Color.uwPrimary : Color.clear, lineWidth: 2)
        )
        .animation(DuoAnimation.buttonPress, value: isFocused)
    }
}



// MARK: - Preview
#Preview {
    ModernAuthenticationView()
}
