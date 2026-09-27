# One Markdown bullet per vulnerability in a Trivy JSON report, limited to one
# Trivy class (os-pkgs or lang-pkgs) when $class is not empty. Findings in
# binaries have no target, so their type (gobinary, cargo) stands in for it.
.Results[]?
| select($class == "" or .Class == $class)
| (if (.Target // "") == "" then .Type else .Target end) as $target
| .Vulnerabilities[]?
| "- \(.Severity) \(.VulnerabilityID): \(.PkgName) \(.InstalledVersion), fixed in \(.FixedVersion) (\($target))"
