Refactored book detail to match the project’s MVI and Compose conventions: it now uses `BaseViewModel`, gets its book ID through injected params, and separates lifecycle handling in a Route from stateless rendering in a Screen. The loading indicator and book title behavior are unchanged.

I did not run tests or a build.