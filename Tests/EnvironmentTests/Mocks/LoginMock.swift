import Environment

struct LoginMock: Login {
    let username = "UsernameMock"

    let password = "PasswordMock"

    func renew(prompt _: Bool) -> Result<Login, Error> {
        .success(self)
    }
}
