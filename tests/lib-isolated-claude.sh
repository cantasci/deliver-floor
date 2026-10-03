# Sourced by the live e2e script: runs `claude` as a fresh user would — own HOME, no inherited session state.
# Only the variables needed to reach the API (and the network proxy) are passed through.
iso_env() {
  local keep=(PATH TERM LANG ANTHROPIC_API_KEY ANTHROPIC_BASE_URL ANTHROPIC_AUTH_TOKEN CLAUDE_CODE_OAUTH_TOKEN
              CLAUDE_SESSION_INGRESS_TOKEN_FILE CLAUDE_CODE_PROVIDER_MANAGED_BY_HOST
              HTTPS_PROXY HTTP_PROXY NO_PROXY https_proxy http_proxy no_proxy NODE_EXTRA_CA_CERTS SSL_CERT_FILE
              GIT_AUTHOR_NAME GIT_AUTHOR_EMAIL GIT_COMMITTER_NAME GIT_COMMITTER_EMAIL DELIVER_HEADLESS PERMISSION_MODE IS_SANDBOX)
  local args=(HOME="$ISO_HOME" DELIVER_HOME="$ISO_HOME/.deliver") v
  for v in "${keep[@]}"; do [[ -n ${!v:-} ]] && args+=("$v=${!v}"); done
  env -i "${args[@]}" "$@"
}
