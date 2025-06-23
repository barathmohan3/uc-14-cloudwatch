plugin "aws" {
  enabled = true
}
 
rule "terraform_version" {
  enabled = true
  version = ">= 1.0"
}


rule "terraform_naming_convention" {
  enabled = true
  variables = "snake_case"
  outputs   = "snake_case"
  resources = "snake_case"
}

rule "terraform_unused_declarations" {
  enabled = true
}

rule "terraform_deprecated_syntax" {
  enabled = true
}
