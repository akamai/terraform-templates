resource "local_file" "dom_challenges" {
  content  = <<EOT
# CNAME Validation Challenges
${yamlencode(module.dom_validation.cname_validation_challenges)}

# TXT Validation Challenges
${yamlencode(module.dom_validation.txt_validation_challenges)}
EOT

  filename = "${path.root}/dom_challenges.txt"
}

resource "local_file" "validation_entries" {
  content  = join("\n", [
    for entry in var.domain_validation_entries : 
    "Domain: ${entry.domain_name} | Method: ${entry.validation_method} | Scope: ${entry.validation_scope}"
  ])
  filename = "${path.root}/dom_validation_entries.txt"
}

resource "local_file" "dom_search_results" {
  # This works regardless of how deeply nested the search results are
  content  = yamlencode(module.dom_validation.domain_search_results)
  filename = "${path.root}/dom_search_results.txt"
}