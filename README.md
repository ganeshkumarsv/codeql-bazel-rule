# Running the Bazel Rule

To run the Baze rule, use the following Bazel command:

```
git clone git@github.com:ganeshkumarsv/codeql-bazel-rule.git
cd codeql-bazel-rule
bazel clean --expunge  
bzl run //reporter:scan_my_code
```


## Steps to Reproduce:

- Use any CodeQL Bundle that was released after 2023.
- Run a CodeQL analysis on a Go project using the go-security-and-quality.qls suite.
- A warning message appears indicating that the pattern `'ext/*.model.yml'` did not match any extension files, followed by the associated error. 
```
WARNING: Pattern 'ext/*.model.yml' did not match any extension files. (/private/var/tmp/_bazel_ganesh.kumar/5d2d1781e9efd51d2ee792b7a818d58b/execroot/_main/bazel-out/darwin_arm64-
fastbuild/bin/reporter/scan_my_code.executable.runfiles/_main/external/codeql-bundle-v2.18.2-darwin/qlpacks/codeql/
go-queries/1.0.5/.codeql/libraries/codeql/go-all/1.1.4/qlpack.yml:1,1-1)
  
[48/55 eval 0ms] Query failed: codeql/go-queries/Security/CWE-601/OpenUrlRedirect.ql (The query depends on an extensional predicate neutralModel which has not been defined.).
[49/55 eval 0ms] Query failed: codeql/go-queries/Security/CWE-640/EmailInjection.ql (The query depends on an extensional predicate neutralModel which has not been defined.).
...
44 of 55 queries failed to evaluate:
  codeql/go-queries/InconsistentCode/ConstantLengthComparison.ql,
  codeql/go-queries/InconsistentCode/LengthComparisonOffByOne.ql,
  ...
  codeql/go-queries/Security/CWE-798/HardcodedCredentials.ql,
  codeql/go-queries/Security/CWE-918/RequestForgery.ql:

The query depends on an extensional predicate neutralModel which has not been defined.

```
- Observe that 44 out of 55 queries fail with the error: **The query depends on an extensional predicate neutralModel which has not been defined.**

