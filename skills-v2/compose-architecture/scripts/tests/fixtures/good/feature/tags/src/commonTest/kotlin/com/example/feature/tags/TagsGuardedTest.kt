package com.example.feature.tags

// GOOD regression fixture for check-error-handling.sh: test source sets are
// not bound by the guarded-call rule. Tests call the base with and without
// onError on purpose, and test function names may start with the helper.
class TagsGuardedTest {
    fun launchGuarded_success_runs() {
        launchGuarded {
        }
    }
}
