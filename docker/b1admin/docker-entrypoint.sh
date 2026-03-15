#!/bin/sh
# Runtime env injection for B1Admin SPA.
#
# Replaces __B1_*__ sentinel placeholders in the built JS bundles with actual
# environment variable values. This allows a single Docker image to be deployed
# to any environment by setting env vars at runtime.
#
# nginx:alpine automatically sources scripts in /docker-entrypoint.d/ before
# starting nginx — no custom CMD needed.

set -e

HTML_DIR="/usr/share/nginx/html"

# Map: placeholder → env var name → fallback (staging URLs)
REPLACEMENTS="
__B1_MEMBERSHIP_API__|REACT_APP_MEMBERSHIP_API|https://api.staging.churchapps.org/membership
__B1_ATTENDANCE_API__|REACT_APP_ATTENDANCE_API|https://api.staging.churchapps.org/attendance
__B1_GIVING_API__|REACT_APP_GIVING_API|https://api.staging.churchapps.org/giving
__B1_REPORTING_API__|REACT_APP_REPORTING_API|https://api.staging.churchapps.org/reporting
__B1_MESSAGING_API__|REACT_APP_MESSAGING_API|https://api.staging.churchapps.org/messaging
__B1_MESSAGING_API_SOCKET__|REACT_APP_MESSAGING_API_SOCKET|wss://socket.staging.churchapps.org
__B1_CONTENT_API__|REACT_APP_CONTENT_API|https://api.staging.churchapps.org/content
__B1_DOING_API__|REACT_APP_DOING_API|https://api.staging.churchapps.org/doing
__B1_LESSONS_API__|REACT_APP_LESSONS_API|https://api.staging.lessons.church
__B1_CONTENT_ROOT__|REACT_APP_CONTENT_ROOT|https://content.staging.churchapps.org
__B1_B1_ROOT__|REACT_APP_B1_ROOT|https://{subdomain}.staging.b1.church
__B1_B1ADMIN_ROOT__|REACT_APP_B1ADMIN_ROOT|https://admin.staging.b1.church
"

echo "B1Admin: injecting runtime environment..."

for line in $REPLACEMENTS; do
  [ -z "$line" ] && continue
  placeholder=$(echo "$line" | cut -d'|' -f1)
  envvar=$(echo "$line" | cut -d'|' -f2)
  fallback=$(echo "$line" | cut -d'|' -f3)

  # Use env var value if set, otherwise fallback
  eval "value=\${$envvar:-$fallback}"

  # Replace in all JS files (Vite output)
  find "$HTML_DIR" -name '*.js' -exec sed -i "s|${placeholder}|${value}|g" {} +
done

echo "B1Admin: environment injection complete."
