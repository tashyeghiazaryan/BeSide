import SwiftUI

/// Minimal email OTP gate aligned with design-reference AuthScreen (email → OTP).
struct AuthGateView: View {
    @Bindable var session: AppSessionStore

    private enum Step {
        case email
        case otp
    }

    @State private var step: Step = .email
    @State private var email = ""
    @State private var otp = ""
    @State private var password = ""
    @State private var showPasswordDev = false
    @State private var errorMessage: String?
    @State private var isWorking = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hex: 0xF7F1F4),
                    Color(hex: 0xE8E4F0),
                    Color(hex: 0xDCE6F4),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 48)

                Text("beside")
                    .font(.system(size: 42, weight: .ultraLight))
                    .foregroundStyle(Color.black.opacity(0.78))
                    .padding(.bottom, 8)

                Text(step == .email ? "Sign in with email" : "Enter your code")
                    .font(.system(size: 15, weight: .light))
                    .foregroundStyle(Color.black.opacity(0.45))
                    .padding(.bottom, 28)

                Group {
                    switch step {
                    case .email:
                        emailCard
                    case .otp:
                        otpCard
                    }
                }
                .padding(.horizontal, 24)

                Spacer()
            }
        }
        .accessibilityIdentifier("auth.gate")
    }

    private var emailCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("EMAIL ADDRESS")
                .font(.system(size: 10, weight: .light))
                .tracking(1.4)
                .foregroundStyle(Color.black.opacity(0.28))

            TextField("your@email.com", text: $email)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
                .autocorrectionDisabled()
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color.white.opacity(0.9), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.black.opacity(0.08), lineWidth: 1)
                )
                .accessibilityIdentifier("auth.email")

            Text("We'll email a 6-digit code. Enter it here — don't open the link in the email.")
                .font(.system(size: 12, weight: .light))
                .foregroundStyle(Color.black.opacity(0.35))

            if let errorMessage {
                Text(errorMessage)
                    .font(.system(size: 12, weight: .light))
                    .foregroundStyle(Color(hex: 0xFB7185))
            }

            Button(action: sendOTP) {
                HStack {
                    if isWorking && !showPasswordDev { ProgressView().tint(.white) }
                    Text(isWorking && !showPasswordDev ? "Sending…" : "Continue with code")
                        .font(.system(size: 15, weight: .medium))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .foregroundStyle(.white)
                .background(Color(hex: 0x2D2D44), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .disabled(isWorking)
            .padding(.top, 8)
            .accessibilityIdentifier("auth.email.continue")

            #if DEBUG
            Divider().padding(.vertical, 4)

            Button {
                withAnimation { showPasswordDev.toggle() }
            } label: {
                Text(showPasswordDev ? "Hide password login" : "Email rate-limited? Use password (dev)")
                    .font(.system(size: 12, weight: .light))
                    .foregroundStyle(Color.black.opacity(0.45))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)

            if showPasswordDev {
                SecureField("Password (min 6)", text: $password)
                    .textContentType(.password)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Color.white.opacity(0.9), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.black.opacity(0.08), lineWidth: 1)
                    )
                    .accessibilityIdentifier("auth.password")

                Text("Works without sending email. Turn OFF “Confirm email” in Supabase Auth → Providers → Email.")
                    .font(.system(size: 11, weight: .light))
                    .foregroundStyle(Color.black.opacity(0.35))

                Button {
                    passwordAuth(createIfNeeded: true)
                } label: {
                    HStack {
                        if isWorking { ProgressView().tint(.white) }
                        Text("Create account / sign in")
                            .font(.system(size: 15, weight: .medium))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .foregroundStyle(.white)
                    .background(Color(hex: 0x2D2D44).opacity(0.85), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .disabled(isWorking || password.count < 6)
                .accessibilityIdentifier("auth.password.submit")
            }
            #endif
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var otpCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("CODE SENT TO \(email)")
                .font(.system(size: 10, weight: .light))
                .tracking(1.2)
                .foregroundStyle(Color.black.opacity(0.28))
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text("Type the 6-digit code from the email. Ignore any “Confirm” link (it goes to localhost).")
                .font(.system(size: 12, weight: .light))
                .foregroundStyle(Color.black.opacity(0.35))

            TextField("6-digit code", text: $otp)
                .keyboardType(.numberPad)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color.white.opacity(0.9), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.black.opacity(0.08), lineWidth: 1)
                )
                .onChange(of: otp) { _, newValue in
                    otp = String(newValue.filter(\.isNumber).prefix(6))
                }
                .accessibilityIdentifier("auth.otp")

            if let errorMessage {
                Text(errorMessage)
                    .font(.system(size: 12, weight: .light))
                    .foregroundStyle(Color(hex: 0xFB7185))
            }

            Button(action: verify) {
                HStack {
                    if isWorking { ProgressView().tint(.white) }
                    Text(isWorking ? "Verifying…" : "Verify & continue")
                        .font(.system(size: 15, weight: .medium))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .foregroundStyle(.white)
                .background(Color(hex: 0x2D2D44), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .disabled(isWorking || otp.count < 6)
            .accessibilityIdentifier("auth.otp.verify")

            Button("Resend code") {
                sendOTP()
            }
            .font(.system(size: 13, weight: .light))
            .foregroundStyle(Color.black.opacity(0.55))
            .frame(maxWidth: .infinity)
            .disabled(isWorking)
            .padding(.top, 4)

            Button("Use a different email") {
                step = .email
                otp = ""
                errorMessage = nil
            }
            .font(.system(size: 13, weight: .light))
            .foregroundStyle(Color.black.opacity(0.45))
            .frame(maxWidth: .infinity)
            .padding(.top, 2)
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func sendOTP() {
        Task {
            isWorking = true
            errorMessage = nil
            defer { isWorking = false }
            do {
                try await session.requestOTP(email: email)
                step = .otp
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func verify() {
        Task {
            isWorking = true
            errorMessage = nil
            defer { isWorking = false }
            do {
                try await session.verifyOTP(email: email, token: otp)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func passwordAuth(createIfNeeded: Bool) {
        Task {
            isWorking = true
            errorMessage = nil
            defer { isWorking = false }
            do {
                try await session.signInWithPassword(
                    email: email,
                    password: password,
                    createIfNeeded: createIfNeeded
                )
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
