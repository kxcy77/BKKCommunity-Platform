package za.co.bkkcommunity.app

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import za.co.bkkcommunity.app.model.ValidationRules

class ValidationRulesTest {
    @Test fun emailValidationRejectsIncompleteAddresses() {
        assertTrue(ValidationRules.isEmail("member@example.com"))
        assertFalse(ValidationRules.isEmail("member@"))
        assertFalse(ValidationRules.isEmail("not an email"))
    }

    @Test fun registrationRequiresMatchingStrongPasswordAndConsent() {
        assertTrue(ValidationRules.isRegistrationValid("Thandiwe Nkosi", "member@example.com", "password1", "password1", true))
        assertFalse(ValidationRules.isRegistrationValid("T", "member@example.com", "short", "different", false))
    }

    @Test fun contactMessageRequiresMeaningfulContent() {
        assertTrue(ValidationRules.isContactValid("Thandi", "member@example.com", "Please tell me about Friday's event."))
        assertFalse(ValidationRules.isContactValid("Thandi", "member@example.com", "Hello"))
    }
}

