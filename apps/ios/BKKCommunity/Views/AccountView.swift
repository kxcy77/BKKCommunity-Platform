import SwiftUI

// MARK: - Validation helpers
private func isValidEmail(_ email: String) -> Bool {
    let regex = #"^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$"#
    return email.range(of: regex, options: .regularExpression) != nil
}

private func isValidPhone(_ phone: String) -> Bool {
    let digits = phone.filter { $0.isNumber || $0 == "+" }
    return digits.count >= 7
}

public struct AccountView: View {
    @EnvironmentObject var viewModel: BKKViewModel
    private let requiresAuthentication: Bool
    @State private var showingAuthSheet = false
    @State private var isRegistering = false
    @State private var showingDeleteConfirmation = false
    @State private var showingProfileEditor = false
    @State private var showingContactForm = false
    @State private var profileName = ""
    @State private var profileEmail = ""
    @State private var profilePhone = ""
    @State private var contactName = ""
    @State private var contactEmail = ""
    @State private var contactMessage = ""

    @State private var nameInput = ""
    @State private var emailInput = ""
    @State private var phoneInput = ""
    @State private var passwordInput = ""
    @State private var confirmPasswordInput = ""
    @State private var authError: String? = nil
    @State private var isAuthenticating = false

    // Forgot Password State
    @State private var showingForgotPassword = false
    @State private var resetStep = 1
    @State private var resetEmail = ""
    @State private var resetToken = ""
    @State private var resetNewPassword = ""
    @State private var resetPasswordConfirmation = ""
    @State private var resetError: String? = nil
    @State private var isResetting = false

    // Track whether the user has touched each field to avoid showing errors before they start typing
    @State private var nameTouched = false
    @State private var emailTouched = false
    @State private var phoneTouched = false
    @State private var passwordTouched = false
    @State private var confirmTouched = false

    public init(requiresAuthentication: Bool = false) {
        self.requiresAuthentication = requiresAuthentication
        _showingAuthSheet = State(initialValue: requiresAuthentication)
    }

    // MARK: Computed validation
    private var nameError: String? {
        guard nameTouched else { return nil }
        if nameInput.trimmingCharacters(in: .whitespaces).isEmpty { return "Full name is required." }
        if nameInput.trimmingCharacters(in: .whitespaces).count < 2 { return "Name must be at least 2 characters." }
        return nil
    }

    private var emailError: String? {
        guard emailTouched else { return nil }
        if emailInput.isEmpty { return "Email address is required." }
        if !isValidEmail(emailInput) { return "Enter a valid email address." }
        return nil
    }

    private var phoneError: String? {
        guard phoneTouched, !phoneInput.isEmpty else { return nil }
        if !isValidPhone(phoneInput) { return "Enter a valid phone number." }
        return nil
    }

    private var passwordError: String? {
        guard passwordTouched else { return nil }
        if passwordInput.isEmpty { return "Password is required." }
        if passwordInput.count < 8 { return "Password must be at least 8 characters." }
        if isRegistering && passwordInput.range(of: #"[A-Za-z]"#, options: .regularExpression) == nil { return "Password must include a letter." }
        if isRegistering && passwordInput.range(of: #"[0-9]"#, options: .regularExpression) == nil { return "Password must include a number." }
        return nil
    }

    private var confirmError: String? {
        guard confirmTouched, isRegistering else { return nil }
        if confirmPasswordInput != passwordInput { return "Passwords do not match." }
        return nil
    }

    private var registerFormValid: Bool {
        nameInput.trimmingCharacters(in: .whitespaces).count >= 2
            && isValidEmail(emailInput)
            && (phoneInput.isEmpty || isValidPhone(phoneInput))
            && passwordInput.count >= 8
            && passwordInput.range(of: #"[A-Za-z]"#, options: .regularExpression) != nil
            && passwordInput.range(of: #"[0-9]"#, options: .regularExpression) != nil
            && confirmPasswordInput == passwordInput
    }

    private var loginFormValid: Bool {
        isValidEmail(emailInput) && !passwordInput.isEmpty
    }

    private var canSubmit: Bool {
        !isAuthenticating && (isRegistering ? registerFormValid : loginFormValid)
    }

    private var canSubmitPasswordReset: Bool {
        let hasRequiredPasswordContent = resetNewPassword.count >= 8
            && resetNewPassword.range(of: #"[A-Za-z]"#, options: .regularExpression) != nil
            && resetNewPassword.range(of: #"[0-9]"#, options: .regularExpression) != nil

        return resetToken.count == 6
            && resetToken.allSatisfy(\.isNumber)
            && hasRequiredPasswordContent
            && resetNewPassword == resetPasswordConfirmation
    }

    public var body: some View {
        if requiresAuthentication && viewModel.currentMember == nil {
            mandatoryAuthentication
        } else {
            accountPage
        }
    }

    private var accountPage: some View {
        NavigationView {
            List {
                if let member = viewModel.currentMember {
                    Section(header: Text("Profile Information")) {
                        HStack {
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 44))
                                .foregroundColor(Color(hex: "#315C24"))
                            VStack(alignment: .leading, spacing: 4) {
                                Text(member.fullName)
                                    .font(.headline)
                                Text(member.email)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                if let phone = member.phone, !phone.isEmpty {
                                    Text(phone)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.vertical, 4)

                        Button("Edit Profile") {
                            profileName = member.fullName
                            profileEmail = member.email
                            profilePhone = member.phone ?? ""
                            showingProfileEditor = true
                        }

                        Button(action: signOut) {
                            Text("Sign Out")
                                .foregroundColor(.red)
                        }
                    }

                    Section(header: Text("Saved Items")) {
                        HStack {
                            Text("Saved Events")
                            Spacer()
                            Text("\(viewModel.savedEventIDs.count)")
                                .foregroundColor(.secondary)
                        }
                        HStack {
                            Text("Saved Deals")
                            Spacer()
                            Text("\(viewModel.savedDiscountIDs.count)").foregroundColor(.secondary)
                        }
                        HStack {
                            Text("Saved Services")
                            Spacer()
                            Text("\(viewModel.savedServiceIDs.count)").foregroundColor(.secondary)
                        }
                    }

                    Section(header: Text("Attendance History")) {
                        if viewModel.attendanceHistory.isEmpty {
                            Text("No confirmed attendance yet.").foregroundColor(.secondary)
                        } else {
                            ForEach(viewModel.attendanceHistory.prefix(5)) { event in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(event.title).font(.headline)
                                    Text(event.startAt.toSouthAfricanFormattedDate())
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        Button("Refresh Attendance") { viewModel.loadAttendanceHistory() }
                    }

                    Section(header: Text("Notification Preferences")) {
                        Toggle("Allow Notifications", isOn: $viewModel.announcementsEnabled)
                        Toggle("Event Reminders", isOn: $viewModel.eventRemindersEnabled)
                        Toggle("Discount Alerts", isOn: $viewModel.discountAlertsEnabled)
                        Button("Save Notification Preferences") {
                            viewModel.saveNotificationPreferences()
                        }
                    }

                    Section(header: Text("Account Management")) {
                        Button("Delete Account", role: .destructive) {
                            showingDeleteConfirmation = true
                        }
                    }

                } else {
                    Section(header: Text("Account Access")) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Join or Sign In to BKK Community")
                                .font(.headline)
                            Text("Access your schedule, confirm attendance for events, and manage saved items.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            HStack(spacing: 12) {
                                Button(action: {
                                    isRegistering = false
                                    resetForm()
                                    showingAuthSheet = true
                                }) {
                                    Text("Sign In")
                                        .fontWeight(.semibold)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(Color(hex: "#315C24"))
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                }
                                .buttonStyle(BorderlessButtonStyle())

                                Button(action: {
                                    isRegistering = true
                                    resetForm()
                                    showingAuthSheet = true
                                }) {
                                    Text("Create Account")
                                        .fontWeight(.semibold)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(Color.appSecondarySystemBackground)
                                        .foregroundColor(.primary)
                                        .cornerRadius(10)
                                }
                                .buttonStyle(BorderlessButtonStyle())
                            }
                        }
                        .padding(.vertical, 6)
                    }
                }

                Section(header: Text("App Support")) {
                    Button("Contact BKK Community") {
                        contactName = viewModel.currentMember?.fullName ?? ""
                        contactEmail = viewModel.currentMember?.email ?? ""
                        contactMessage = ""
                        showingContactForm = true
                    }
                    HStack {
                        Text("App Version")
                        Spacer()
                        Text("1.0.0 (iOS)")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Backend Server")
                        Spacer()
                        Text("BKK MySQL API")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("My Account")
            .confirmationDialog(
                "Permanently delete your BKK Community account?",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete Account", role: .destructive) { viewModel.deleteAccount() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This deletes your profile, attendance and saved server data. It cannot be undone.")
            }
            .fullScreenCover(isPresented: $showingAuthSheet) {
                BkkAuthenticationSheet(
                    isRegistering: $isRegistering,
                    name: $nameInput,
                    email: $emailInput,
                    phone: $phoneInput,
                    password: $passwordInput,
                    passwordConfirmation: $confirmPasswordInput,
                    nameError: nameError,
                    emailError: emailError,
                    phoneError: phoneError,
                    passwordError: passwordError,
                    confirmationError: confirmError,
                    authError: authError,
                    canSubmit: canSubmit,
                    isWorking: isAuthenticating,
                    onNameEnded: { nameTouched = true },
                    onEmailEnded: { emailTouched = true },
                    onPhoneEnded: { phoneTouched = true },
                    onPasswordChanged: { passwordTouched = true },
                    onConfirmationChanged: { confirmTouched = true },
                    onModeChanged: resetForm,
                    onForgotPassword: beginPasswordReset,
                    onSubmit: submit,
                    onCancel: { showingAuthSheet = false },
                    allowsDismissal: !requiresAuthentication
                )
            }
            .sheet(isPresented: $showingForgotPassword) {
                NavigationView {
                    Form {
                        if resetStep == 1 {
                            Section(header: Text("Reset Password"), footer: Text("Enter the email associated with your account to receive a 6-digit code.")) {
                                TextField("Email Address", text: $resetEmail)
                                    .autocapitalization(.none)
                                    .keyboardType(.emailAddress)
                                
                                if let err = resetError {
                                    Text(err).font(.caption).foregroundColor(.red)
                                }
                            }
                            Section {
                                Button(action: {
                                    Task {
                                        isResetting = true
                                        resetError = nil
                                        do {
                                            resetToken = ""
                                            _ = try await viewModel.requestPasswordReset(email: resetEmail)
                                            resetStep = 2 // Move to enter 6-digit code from email
                                        } catch {
                                            resetError = error.localizedDescription
                                        }
                                        isResetting = false
                                    }
                                }) {
                                    if isResetting {
                                        ProgressView()
                                    } else {
                                        Text("Send 6-Digit Reset Code")
                                            .fontWeight(.bold)
                                            .frame(maxWidth: .infinity)
                                            .foregroundColor(isValidEmail(resetEmail) ? Color(hex: "#315C24") : .secondary)
                                    }
                                }
                                .disabled(!isValidEmail(resetEmail) || isResetting)
                            }
                        } else {
                            Section(header: Text("Create New Password"), footer: Text("Enter the 6-digit code from your email. It expires in 15 minutes. Your password must be at least 8 characters and include a letter and number.")) {
                                TextField("6-Digit Reset Code", text: Binding(
                                    get: { resetToken },
                                    set: { resetToken = String($0.filter { $0.isNumber }.prefix(6)) }
                                ))
                                    .keyboardType(.numberPad)
                                    .textContentType(.oneTimeCode)
                                SecureField("New Password", text: $resetNewPassword)
                                SecureField("Confirm New Password", text: $resetPasswordConfirmation)
                                
                                if let err = resetError {
                                    Text(err).font(.caption).foregroundColor(.red)
                                }
                            }
                            Section {
                                Button(action: {
                                    Task {
                                        isResetting = true
                                        resetError = nil
                                        do {
                                            try await viewModel.submitPasswordReset(email: resetEmail, token: resetToken, newPassword: resetNewPassword)
                                            showingForgotPassword = false
                                            viewModel.statusMessage = "Password successfully reset. Please sign in."
                                        } catch {
                                            resetError = error.localizedDescription
                                        }
                                        isResetting = false
                                    }
                                }) {
                                    if isResetting {
                                        ProgressView()
                                    } else {
                                        Text("Update Password")
                                            .fontWeight(.bold)
                                            .frame(maxWidth: .infinity)
                                            .foregroundColor(canSubmitPasswordReset ? Color(hex: "#315C24") : .secondary)
                                    }
                                }
                                .disabled(!canSubmitPasswordReset || isResetting)
                            }
                        }
                    }
                    .navigationTitle("Forgot Password")
                    .navigationBarItems(trailing: Button("Cancel") {
                        showingForgotPassword = false
                    })
                }
            }
            .sheet(isPresented: $showingProfileEditor) {
                NavigationView {
                    Form {
                        Section(header: Text("Profile Information")) {
                            TextField("Full Name", text: $profileName)
                            TextField("Email Address", text: $profileEmail)
                                .autocapitalization(.none)
                                .keyboardType(.emailAddress)
                            TextField("Phone (Optional)", text: $profilePhone)
                                .keyboardType(.phonePad)
                        }
                        Section {
                            Button("Save Profile") {
                                viewModel.updateProfile(
                                    name: profileName.trimmingCharacters(in: .whitespacesAndNewlines),
                                    email: profileEmail.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
                                    phone: profilePhone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : profilePhone
                                )
                                showingProfileEditor = false
                            }
                            .disabled(profileName.trimmingCharacters(in: .whitespacesAndNewlines).count < 2 || !isValidEmail(profileEmail))
                        }
                    }
                    .navigationTitle("Edit Profile")
                    .navigationBarItems(trailing: Button("Cancel") { showingProfileEditor = false })
                }
            }
            .sheet(isPresented: $showingContactForm) {
                NavigationView {
                    Form {
                        Section(header: Text("Your Details")) {
                            TextField("Full Name", text: $contactName)
                            TextField("Email Address", text: $contactEmail)
                                .autocapitalization(.none)
                                .keyboardType(.emailAddress)
                        }
                        Section(header: Text("How can we help?")) {
                            TextEditor(text: $contactMessage)
                                .frame(minHeight: 140)
                            Text("\(contactMessage.count)/3000 characters")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Section {
                            Button("Send Message") {
                                viewModel.submitContact(
                                    name: contactName.trimmingCharacters(in: .whitespacesAndNewlines),
                                    email: contactEmail.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
                                    message: contactMessage.trimmingCharacters(in: .whitespacesAndNewlines)
                                )
                                showingContactForm = false
                            }
                            .disabled(
                                contactName.trimmingCharacters(in: .whitespacesAndNewlines).count < 2 ||
                                !isValidEmail(contactEmail) ||
                                contactMessage.trimmingCharacters(in: .whitespacesAndNewlines).count < 10 ||
                                contactMessage.count > 3000
                            )
                        }
                    }
                    .navigationTitle("Contact BKK")
                    .navigationBarItems(trailing: Button("Cancel") { showingContactForm = false })
                }
            }
            .onAppear {
                if requiresAuthentication && viewModel.currentMember == nil && !showingForgotPassword {
                    isRegistering = false
                    resetForm()
                    showingAuthSheet = true
                } else if viewModel.currentMember != nil && viewModel.attendanceHistory.isEmpty {
                    // Attendance is account-only data; defer it until this tab
                    // is actually opened instead of slowing the home launch.
                    viewModel.loadAttendanceHistory()
                }
            }
            .onChange(of: viewModel.currentMember) { member in
                if member == nil && requiresAuthentication && !showingForgotPassword {
                    showingAuthSheet = true
                } else if member != nil {
                    showingAuthSheet = false
                }
            }
            .onChange(of: showingForgotPassword) { isShowing in
                if !isShowing && requiresAuthentication && viewModel.currentMember == nil {
                    showingAuthSheet = true
                }
            }
    }
    }

    // This is deliberately a root view, not a sheet. A signed-out member must
    // never depend on modal presentation timing to reach the sign-in screen.
    private var mandatoryAuthentication: some View {
        BkkAuthenticationSheet(
            isRegistering: $isRegistering,
            name: $nameInput,
            email: $emailInput,
            phone: $phoneInput,
            password: $passwordInput,
            passwordConfirmation: $confirmPasswordInput,
            nameError: nameError,
            emailError: emailError,
            phoneError: phoneError,
            passwordError: passwordError,
            confirmationError: confirmError,
            authError: authError,
            canSubmit: canSubmit,
            isWorking: isAuthenticating,
            onNameEnded: { nameTouched = true },
            onEmailEnded: { emailTouched = true },
            onPhoneEnded: { phoneTouched = true },
            onPasswordChanged: { passwordTouched = true },
            onConfirmationChanged: { confirmTouched = true },
            onModeChanged: resetForm,
            onForgotPassword: beginPasswordReset,
            onSubmit: submit,
            onCancel: {},
            allowsDismissal: false
        )
        .sheet(isPresented: $showingForgotPassword) {
            mandatoryPasswordReset
        }
    }

    private var mandatoryPasswordReset: some View {
        NavigationView {
            Form {
                if resetStep == 1 {
                    Section(header: Text("Reset Password"), footer: Text("Enter the email associated with your account to receive a 6-digit code.")) {
                        TextField("Email Address", text: $resetEmail)
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                        if let resetError {
                            Text(resetError).font(.caption).foregroundColor(.red)
                        }
                    }
                    Section {
                        Button(action: requestResetCode) {
                            if isResetting {
                                ProgressView()
                            } else {
                                Text("Send 6-Digit Reset Code")
                                    .fontWeight(.bold)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .disabled(!isValidEmail(resetEmail) || isResetting)
                    }
                } else {
                    Section(header: Text("Create New Password"), footer: Text("Enter the 6-digit code from your email. It expires in 15 minutes. Your password must be at least 8 characters and include a letter and number.")) {
                        TextField("6-Digit Reset Code", text: Binding(
                            get: { resetToken },
                            set: { resetToken = String($0.filter { $0.isNumber }.prefix(6)) }
                        ))
                        .keyboardType(.numberPad)
                        .textContentType(.oneTimeCode)
                        SecureField("New Password", text: $resetNewPassword)
                        SecureField("Confirm New Password", text: $resetPasswordConfirmation)
                        if let resetError {
                            Text(resetError).font(.caption).foregroundColor(.red)
                        }
                    }
                    Section {
                        Button(action: submitResetPassword) {
                            if isResetting {
                                ProgressView()
                            } else {
                                Text("Update Password")
                                    .fontWeight(.bold)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .disabled(!canSubmitPasswordReset || isResetting)
                    }
                }
            }
            .navigationTitle("Forgot Password")
            .navigationBarItems(trailing: Button("Cancel") {
                showingForgotPassword = false
            })
        }
    }

    // MARK: - Helpers

    private func signOut() {
        // Prime the authentication gate before changing the shared member state.
        // This avoids a one-frame signed-out Account screen while the root view
        // changes from the tab interface to mandatory authentication.
        isRegistering = false
        resetForm()
        showingAuthSheet = true
        viewModel.signOut()
    }

    private func submit() {
        // Mark all fields touched so any remaining errors become visible
        nameTouched = true; emailTouched = true; phoneTouched = true
        passwordTouched = true; confirmTouched = true
        guard canSubmit else { return }

        authError = nil
        isAuthenticating = true
        Task {
            defer { isAuthenticating = false }
            do {
                if isRegistering {
                    try await viewModel.register(
                        name: nameInput.trimmingCharacters(in: .whitespacesAndNewlines),
                        email: emailInput.lowercased().trimmingCharacters(in: .whitespacesAndNewlines),
                        phone: phoneInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : phoneInput,
                        password: passwordInput
                    )
                } else {
                    try await viewModel.login(
                        email: emailInput.lowercased().trimmingCharacters(in: .whitespacesAndNewlines),
                        password: passwordInput
                    )
                }
                showingAuthSheet = false
            } catch {
                authError = error.localizedDescription
            }
        }
    }

    private func beginPasswordReset() {
        showingAuthSheet = false
        resetEmail = emailInput
        resetStep = 1
        resetError = nil
        resetToken = ""
        resetNewPassword = ""
        resetPasswordConfirmation = ""
        showingForgotPassword = true
    }

    private func requestResetCode() {
        Task {
            isResetting = true
            resetError = nil
            defer { isResetting = false }
            do {
                resetToken = ""
                try await viewModel.requestPasswordReset(email: resetEmail)
                resetStep = 2
            } catch {
                resetError = error.localizedDescription
            }
        }
    }

    private func submitResetPassword() {
        Task {
            isResetting = true
            resetError = nil
            defer { isResetting = false }
            do {
                try await viewModel.submitPasswordReset(
                    email: resetEmail,
                    token: resetToken,
                    newPassword: resetNewPassword
                )
                showingForgotPassword = false
                viewModel.statusMessage = "Password successfully reset. Please sign in."
            } catch {
                resetError = error.localizedDescription
            }
        }
    }

    private func resetForm() {
        nameInput = ""; emailInput = ""; phoneInput = ""
        passwordInput = ""; confirmPasswordInput = ""
        authError = nil
        isAuthenticating = false
        nameTouched = false; emailTouched = false; phoneTouched = false
        passwordTouched = false; confirmTouched = false
    }
}

// MARK: - Branded authentication experience
private struct BkkAuthenticationSheet: View {
    @Binding var isRegistering: Bool
    @Binding var name: String
    @Binding var email: String
    @Binding var phone: String
    @Binding var password: String
    @Binding var passwordConfirmation: String

    let nameError: String?
    let emailError: String?
    let phoneError: String?
    let passwordError: String?
    let confirmationError: String?
    let authError: String?
    let canSubmit: Bool
    let isWorking: Bool
    let onNameEnded: () -> Void
    let onEmailEnded: () -> Void
    let onPhoneEnded: () -> Void
    let onPasswordChanged: () -> Void
    let onConfirmationChanged: () -> Void
    let onModeChanged: () -> Void
    let onForgotPassword: () -> Void
    let onSubmit: () -> Void
    let onCancel: () -> Void
    let allowsDismissal: Bool

    @State private var passwordVisible = false
    @State private var confirmationVisible = false

    var body: some View {
        NavigationView {
            ZStack(alignment: .topTrailing) {
                Color.bkkSurface.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        header
                        formCard
                            .padding(.horizontal, 18)
                            .padding(.top, -28)

                        HStack(spacing: 9) {
                            Image(systemName: "checkmark.shield.fill")
                                .font(.system(size: 19, weight: .semibold))
                                .foregroundColor(.bkkGreen)
                            Text("Secure sign-in. Your password is never stored on this device.")
                                .font(.system(size: 15))
                                .foregroundColor(.bkkMuted)
                                .multilineTextAlignment(.leading)
                        }
                        .padding(.horizontal, 28)
                        .padding(.vertical, 20)
                    }
                }

                if allowsDismissal {
                    Button(action: onCancel) {
                        Image(systemName: "xmark")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 48, height: 48)
                            .background(Color.white.opacity(0.16))
                            .clipShape(Circle())
                    }
                    .accessibilityLabel("Close sign in")
                    .disabled(isWorking)
                    .padding(.top, 10)
                    .padding(.trailing, 14)
                }
            }
            .navigationBarHidden(true)
        }
        .interactiveDismissDisabled(!allowsDismissal || isWorking)
    }

    private var header: some View {
        ZStack {
            BkkTheme.topBarGradient
            Circle()
                .fill(Color.white.opacity(0.07))
                .frame(width: 180, height: 180)
                .offset(x: 145, y: -75)
                .accessibilityHidden(true)
            Circle()
                .fill(Color.bkkGold.opacity(0.14))
                .frame(width: 110, height: 110)
                .offset(x: -155, y: 80)
                .accessibilityHidden(true)

            VStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 66, height: 66)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.24), lineWidth: 1)
                        )
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 29, weight: .semibold))
                        .foregroundColor(.white)
                }
                .accessibilityHidden(true)

                Text(isRegistering ? "Join your community" : "Welcome back")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                Text(isRegistering ? "Create your BKK Community account" : "Sign in to your BKK Community account")
                    .font(.system(size: 17))
                    .foregroundColor(Color.white.opacity(0.88))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 60)
            .padding(.top, 22)
            .padding(.bottom, 44)
        }
        .frame(minHeight: 230)
    }

    private var formCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            modePicker

            VStack(alignment: .leading, spacing: 5) {
                Text(isRegistering ? "Create an account" : "Account sign in")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.bkkNavy)
                Text(isRegistering ? "Your details help us manage attendance and reminders." : "Use the email address you registered with.")
                    .font(.system(size: 16))
                    .foregroundColor(.bkkMuted)
            }

            if let authError {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.bkkRed)
                    Text(authError)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.bkkRed)
                }
                .padding(13)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.bkkRedSurface)
                .cornerRadius(14)
                .accessibilityElement(children: .combine)
            }

            if isRegistering {
                AuthInputField(icon: "person.fill", label: "Full name", error: nameError) {
                    TextField("Enter your full name", text: $name, onEditingChanged: { editing in
                        if !editing { onNameEnded() }
                    })
                    .textFieldStyle(.plain)
#if canImport(UIKit)
                    .autocapitalization(.words)
                    .textContentType(.name)
#endif
                }

                AuthInputField(icon: "phone.fill", label: "Phone number (optional)", error: phoneError) {
                    TextField("e.g. 072 123 4567", text: $phone, onEditingChanged: { editing in
                        if !editing { onPhoneEnded() }
                    })
                    .textFieldStyle(.plain)
#if canImport(UIKit)
                    .keyboardType(.phonePad)
                    .textContentType(.telephoneNumber)
#endif
                }
            }

            AuthInputField(icon: "envelope.fill", label: "Email address", error: emailError) {
                TextField("name@example.com", text: $email, onEditingChanged: { editing in
                    if !editing { onEmailEnded() }
                })
                .textFieldStyle(.plain)
#if canImport(UIKit)
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
#endif
            }

            AuthInputField(icon: "lock.fill", label: "Password", error: passwordError) {
                HStack(spacing: 6) {
                    Group {
                        if passwordVisible {
                            TextField(isRegistering ? "At least 8 characters" : "Enter your password", text: $password)
                        } else {
                            SecureField(isRegistering ? "At least 8 characters" : "Enter your password", text: $password)
                        }
                    }
                    .textFieldStyle(.plain)
#if canImport(UIKit)
                    .textContentType(isRegistering ? .newPassword : .password)
#endif
                    .onChange(of: password) { _ in onPasswordChanged() }

                    Button(action: { passwordVisible.toggle() }) {
                        Image(systemName: passwordVisible ? "eye.slash.fill" : "eye.fill")
                            .foregroundColor(.bkkMuted)
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel(passwordVisible ? "Hide password" : "Show password")
                }
            }

            if isRegistering {
                AuthInputField(icon: "lock.shield.fill", label: "Confirm password", error: confirmationError) {
                    HStack(spacing: 6) {
                        Group {
                            if confirmationVisible {
                                TextField("Enter the password again", text: $passwordConfirmation)
                            } else {
                                SecureField("Enter the password again", text: $passwordConfirmation)
                            }
                        }
                        .textFieldStyle(.plain)
#if canImport(UIKit)
                        .textContentType(.newPassword)
#endif
                        .onChange(of: passwordConfirmation) { _ in onConfirmationChanged() }

                        Button(action: { confirmationVisible.toggle() }) {
                            Image(systemName: confirmationVisible ? "eye.slash.fill" : "eye.fill")
                                .foregroundColor(.bkkMuted)
                                .frame(width: 44, height: 44)
                        }
                        .accessibilityLabel(confirmationVisible ? "Hide password confirmation" : "Show password confirmation")
                    }
                }

                if !password.isEmpty {
                    VStack(alignment: .leading, spacing: 7) {
                        Text("PASSWORD STRENGTH")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.bkkMuted)
                        PasswordStrengthView(password: password)
                    }
                }
            } else {
                Button(action: onForgotPassword) {
                    Text("Forgot your password?")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.bkkBlue)
                        .frame(minHeight: 48)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .disabled(isWorking)
            }

            Button(action: onSubmit) {
                HStack(spacing: 10) {
                    if isWorking {
                        ProgressView().tint(.white)
                        Text(isRegistering ? "Creating account…" : "Signing in…")
                    } else {
                        Text(isRegistering ? "Create Account" : "Sign In")
                        Image(systemName: "arrow.right")
                    }
                }
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(canSubmit ? .white : Color(hex: "#465564"))
                .frame(maxWidth: .infinity, minHeight: 58)
                .background(canSubmit ? Color.bkkBlue : Color(hex: "#D7DEE5"))
                .cornerRadius(17)
            }
            .buttonStyle(.plain)
            .disabled(!canSubmit)

            HStack(spacing: 10) {
                Rectangle().fill(Color.bkkLine).frame(height: 1)
                Text(isRegistering ? "ALREADY A MEMBER?" : "NEW TO BKK?")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.bkkMuted)
                    .fixedSize()
                Rectangle().fill(Color.bkkLine).frame(height: 1)
            }

            Button(action: switchMode) {
                Text(isRegistering ? "Sign In Instead" : "Create an Account")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.bkkNavy)
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .overlay(
                        RoundedRectangle(cornerRadius: 17)
                            .stroke(Color.bkkBlue, lineWidth: 1.5)
                    )
            }
            .buttonStyle(.plain)
            .disabled(isWorking)
        }
        .padding(20)
        // Authentication uses a deliberately light surface even when the
        // device is in Dark Mode. The brand text tokens are dark, so allowing
        // the system background to turn black makes labels unreadable.
        .background(Color.white)
        .cornerRadius(28)
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(Color.bkkLine, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.09), radius: 16, x: 0, y: 7)
        .environment(\.colorScheme, .light)
    }

    private var modePicker: some View {
        HStack(spacing: 6) {
            modeButton("Sign In", selected: !isRegistering) {
                guard isRegistering, !isWorking else { return }
                isRegistering = false
                onModeChanged()
            }
            modeButton("Register", selected: isRegistering) {
                guard !isRegistering, !isWorking else { return }
                isRegistering = true
                onModeChanged()
            }
        }
        .padding(5)
        .background(Color.bkkSky)
        .cornerRadius(16)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Account action")
    }

    private func modeButton(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(selected ? .white : .bkkNavy)
                .frame(maxWidth: .infinity, minHeight: 46)
                .background(selected ? Color.bkkNavy : Color.clear)
                .cornerRadius(12)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func switchMode() {
        guard !isWorking else { return }
        isRegistering.toggle()
        onModeChanged()
    }
}

private struct AuthInputField<Content: View>: View {
    let icon: String
    let label: String
    let error: String?
    let content: Content

    init(icon: String, label: String, error: String?, @ViewBuilder content: () -> Content) {
        self.icon = icon
        self.label = label
        self.error = error
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(label)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.bkkInk)

            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(error == nil ? .bkkBlue : .bkkRed)
                    .frame(width: 24)
                    .accessibilityHidden(true)
                content
                    .font(.system(size: 17))
                    .foregroundColor(.bkkInk)
            }
            .padding(.leading, 15)
            .padding(.trailing, 8)
            .frame(minHeight: 58)
            .background(Color.bkkSurface)
            .cornerRadius(15)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(error == nil ? Color.bkkLine : Color.bkkRed, lineWidth: error == nil ? 1 : 1.5)
            )

            if let error {
                Text(error)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.bkkRed)
                    .accessibilityLabel("Error: \(error)")
            }
        }
    }
}

// MARK: - Password Strength Indicator
private struct PasswordStrengthView: View {
    let password: String

    private var score: Int {
        var s = 0
        if password.count >= 8 { s += 1 }
        if password.count >= 12 { s += 1 }
        if password.range(of: "[A-Z]", options: .regularExpression) != nil { s += 1 }
        if password.range(of: "[0-9]", options: .regularExpression) != nil { s += 1 }
        if password.range(of: "[^A-Za-z0-9]", options: .regularExpression) != nil { s += 1 }
        return s
    }

    private var label: String {
        switch score {
        case 0...1: return "Weak"
        case 2...3: return "Fair"
        case 4:     return "Good"
        default:    return "Strong"
        }
    }

    private var color: Color {
        switch score {
        case 0...1: return .red
        case 2...3: return .orange
        case 4:     return .yellow
        default:    return .green
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                ForEach(0..<5) { i in
                    RoundedRectangle(cornerRadius: 2)
                        .frame(height: 4)
                        .foregroundColor(i < score ? color : Color.secondary.opacity(0.3))
                }
            }
            Text(label)
                .font(.caption)
                .foregroundColor(color)
        }
    }
}
