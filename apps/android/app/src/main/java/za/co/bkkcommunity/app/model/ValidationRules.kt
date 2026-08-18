package za.co.bkkcommunity.app.model

object ValidationRules {
    fun isEmail(value: String): Boolean = value.trim().matches(
        Regex("^[A-Za-z0-9.!#$%&'*+/=?^_`{|}~-]+@[A-Za-z0-9-]+(?:\\.[A-Za-z0-9-]+)+$")
    )

    fun isPassword(value: String): Boolean = value.length in 8..128

    fun isRegistrationValid(name: String, email: String, password: String, confirmation: String, privacyAccepted: Boolean): Boolean =
        name.trim().length in 2..120 && isEmail(email) && isPassword(password) && password == confirmation && privacyAccepted

    fun isContactValid(name: String, email: String, message: String): Boolean =
        name.trim().length in 2..120 && isEmail(email) && message.trim().length in 10..3000
}

