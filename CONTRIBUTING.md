# Contributing to Gallery Suite

First off, thank you for considering contributing to Gallery Suite! It's people like you that make Gallery Suite such a great media picker for the Flutter ecosystem.

## 1. Where do I go from here?

If you've noticed a bug or have a feature request, make one! It's generally best if you get confirmation of your bug or approval for your feature request before starting to code.

## 2. Fork & create a branch

If this is something you think you can fix, then fork Gallery Suite and create a branch with a descriptive name.

## 3. Get the test suite running

Make sure you have a relatively recent version of Flutter.

1. Clone your fork.
2. Run `flutter pub get` in the root of the package.
3. If you're building the example app: `cd example` and run `flutter run`.

## 4. Implement your fix or feature

At this point, you're ready to make your changes! Feel free to ask for help; everyone is a beginner at first :smile:

## 5. Code Review & Formatting

Before submitting your pull request, please ensure your code is properly formatted and passes our CI checks. 

Run the following locally:
```bash
# Apply automatic safe fixes
dart fix --apply lib

# Format all files
dart format .

# Check for warnings
flutter analyze
```

If `flutter analyze` reports 0 errors or warnings, and `git status` shows you've committed the formatting changes, your PR will easily pass our automated GitHub Actions!

## 6. Make a Pull Request

At this point, you should switch back to your master branch and make sure it's up to date with Gallery Suite's master branch.
Then create a Pull Request on GitHub. 

We will review your code as quickly as possible. Thank you!
