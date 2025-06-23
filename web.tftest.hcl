run "check_mfa_enabled" {
  module {
    source = "./."
  }

  assert {
    condition = module.cognito_user_pool.mfa_configuration == "ON"
    error_message = "MFA should be enabled for Cognito User Pool"
  }
}
