#!/usr/bin/env bash

# Small script used to verify Bazel's analysis cache is not being discarded
# between a run and test invocation. While this example is rather trivial,
# as complexity increases, the analysis cache becomes more valuable.

set -euo pipefail

command_log=$(bzl info command_log)

bzl run --config=ci --bzl_skip_post_run //tools/bazelrc/analysis-cache:mock_test
echo "================================================================================"
bzl test --config=ci --bzl_skip_post_test //tools/bazelrc/analysis-cache:mock_test

# Check the command log of `bzl test` to see if the analysis cache is being discarded
discard_message=$(grep "discarding analysis cache" "${command_log}" || true)

echo "================================================================================"

# If command log has "discarding analysis cache", this test should fail
if [[ -n $discard_message ]]; then
  cat <<EOF
⚠️ Bazel is discarding the analysis cache ⚠️
The second Bazel invocation logged the following message:

${discard_message}

EOF
  exit 1
else
  echo "🎉 Bazel seems to be re-using the cache as expected 🎉"
fi
