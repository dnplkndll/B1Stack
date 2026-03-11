#!/bin/sh
# Runtime env injection for B1App (Next.js).
#
# Replaces __B1_*__ sentinel placeholders in the built .next JS bundles with
# actual environment variable values. This allows a single Docker image to be
# deployed to any environment by setting env vars at runtime.
#
# For Next.js: server-side code reads process.env at runtime natively.
# Client-side bundles have NEXT_PUBLIC_* inlined at build time — the sed
# replacement handles those.

set -e

NEXT_DIR="/app/.next"

REPLACEMENTS="
__B1_MEMBERSHIP_API__|NEXT_PUBLIC_MEMBERSHIP_API|https://api.staging.churchapps.org/membership
__B1_ATTENDANCE_API__|NEXT_PUBLIC_ATTENDANCE_API|https://api.staging.churchapps.org/attendance
__B1_GIVING_API__|NEXT_PUBLIC_GIVING_API|https://api.staging.churchapps.org/giving
__B1_REPORTING_API__|NEXT_PUBLIC_REPORTING_API|https://api.staging.churchapps.org/reporting
__B1_MESSAGING_API__|NEXT_PUBLIC_MESSAGING_API|https://api.staging.churchapps.org/messaging
__B1_MESSAGING_API_SOCKET__|NEXT_PUBLIC_MESSAGING_API_SOCKET|wss://socket.staging.churchapps.org
__B1_CONTENT_API__|NEXT_PUBLIC_CONTENT_API|https://api.staging.churchapps.org/content
__B1_DOING_API__|NEXT_PUBLIC_DOING_API|https://api.staging.churchapps.org/doing
__B1_LESSONS_API__|NEXT_PUBLIC_LESSONS_API|https://api.staging.lessons.church
__B1_CONTENT_ROOT__|NEXT_PUBLIC_CONTENT_ROOT|https://content.staging.churchapps.org
__B1_B1_ROOT__|NEXT_PUBLIC_B1_ROOT|https://{subdomain}.staging.b1.church
__B1_B1ADMIN_ROOT__|NEXT_PUBLIC_B1ADMIN_ROOT|https://admin.staging.b1.church
"

echo "B1App: injecting runtime environment..."

for line in $REPLACEMENTS; do
  [ -z "$line" ] && continue
  placeholder=$(echo "$line" | cut -d'|' -f1)
  envvar=$(echo "$line" | cut -d'|' -f2)
  fallback=$(echo "$line" | cut -d'|' -f3)

  eval "value=\${$envvar:-$fallback}"

  # Also check REACT_APP_* equivalents (CommonEnvironmentHelper reads both)
  react_envvar=$(echo "$envvar" | sed 's/NEXT_PUBLIC_/REACT_APP_/')
  eval "react_value=\${$react_envvar:-}"
  [ -n "$react_value" ] && value="$react_value"

  find "$NEXT_DIR" -name '*.js' -exec sed -i "s|${placeholder}|${value}|g" {} + 2>/dev/null || true
done

echo "B1App: environment injection complete."
