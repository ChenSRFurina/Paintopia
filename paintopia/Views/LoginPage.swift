import SwiftUI

struct LoginPage: View {
    // 登录回调
    var onLogin: ((String, String) -> Void)? = nil
    // 可自定义背景和logo图片名
    var backgroundImage: String = "background"
    var logoImage: String = "logo_name"
    
    @State private var username: String = ""
    @State private var password: String = ""
    @FocusState private var focusedField: Field?
    enum Field { case username, password }
    
    var body: some View {
        ZStack {
            // 背景图片
            Image(backgroundImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()
            VStack {
                Spacer(minLength: 60)
                // 标题区
                VStack(spacing: 0) {
                    Text("欢迎来到")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(Color(red: 0.87, green: 0.36, blue: 0.89))
                        .padding(.bottom, 18)
                        .shadow(color: .white.opacity(0.2), radius: 8, y: 2)
                    HStack(spacing: 20) {
                        Image(logoImage)
                            .resizable()
                            .frame(width: 220, height: 90)
                            .shadow(color: .gray.opacity(0.3), radius: 8, y: 2)
                        HStack(spacing: 0) {
                            Text("画").font(.system(size: 60, weight: .bold)).foregroundColor(Color(red: 0.35, green: 0.28, blue: 0.87)).shadow(color: .white, radius: 4)
                            Text("趣").font(.system(size: 60, weight: .bold)).foregroundColor(Color(red: 0.07, green: 0.51, blue: 1.0)).shadow(color: .white, radius: 4)
                            Text("星").font(.system(size: 60, weight: .bold)).foregroundColor(Color(red: 0.27, green: 0.75, blue: 0.95)).shadow(color: .white, radius: 4)
                            Text("球").font(.system(size: 60, weight: .bold)).foregroundColor(Color(red: 0.41, green: 0.89, blue: 0.36)).shadow(color: .white, radius: 4)
                        }
                    }
                }
                .padding(.bottom, 40)
                // 登录表单
                VStack(spacing: 0) {
                    HStack {
                        Text("账号：")
                            .foregroundColor(Color(red: 0.87, green: 0.36, blue: 0.89))
                            .font(.system(size: 18, weight: .bold))
                            .padding(.trailing, 6)
                        TextField("user5026", text: $username)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .foregroundColor(.white)
                            .font(.system(size: 15))
                            .padding(.vertical, 8)
                            .padding(.horizontal, 10)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(6)
                            .overlay(Rectangle().frame(height: 1.5).foregroundColor(.white), alignment: .bottom)
                            .focused($focusedField, equals: .username)
                            .submitLabel(.next)
                            .onSubmit { focusedField = .password }
                    }
                    .padding(.bottom, 12)
                    HStack {
                        Text("密码：")
                            .foregroundColor(Color(red: 0.87, green: 0.36, blue: 0.89))
                            .font(.system(size: 18, weight: .bold))
                            .padding(.trailing, 6)
                        SecureField("************", text: $password)
                            .foregroundColor(.white)
                            .font(.system(size: 15))
                            .padding(.vertical, 8)
                            .padding(.horizontal, 10)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(6)
                            .overlay(Rectangle().frame(height: 1.5).foregroundColor(.white), alignment: .bottom)
                            .focused($focusedField, equals: .password)
                            .submitLabel(.go)
                            .onSubmit { login() }
                    }
                    .padding(.bottom, 6)
                    HStack {
                        Spacer()
                        Button(action: { /* 忘记密码逻辑 */ }) {
                            Text("忘记密码")
                                .foregroundColor(.gray)
                                .font(.system(size: 13))
                                .underline()
                        }
                    }
                    .padding(.bottom, 12)
                    Button(action: login) {
                        Text("登录")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.vertical, 8)
                            .frame(maxWidth: 180)
                            .background(LinearGradient(gradient: Gradient(colors: [Color(red: 0.87, green: 0.36, blue: 0.89), Color(red: 0.85, green: 0.35, blue: 0.87)]), startPoint: .leading, endPoint: .trailing))
                            .cornerRadius(24)
                            .shadow(color: .purple.opacity(0.2), radius: 6, y: 2)
                    }
                    .padding(.top, 6)
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 20)
                .background(Color(red: 0.12, green: 0.12, blue: 0.24, opacity: 0.55))
                .cornerRadius(18)
                .shadow(color: Color(red: 0.7, green: 0.66, blue: 1.0, opacity: 0.33), radius: 10)
                .frame(minWidth: 220, maxWidth: 320)
                Spacer(minLength: 60)
            }
        }
        .onAppear { focusedField = .username }
    }
    
    private func login() {
        onLogin?(username, password)
    }
}

#Preview {
    LoginPage()
} 