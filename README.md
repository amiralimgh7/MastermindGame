# Mastermind — single-file version

A single-file Swift command-line client for the Mastermind API. This repository contains the same game source as the [Swift package version](https://github.com/amiralimgh7/mastermind), which is the recommended starting point for building the project.

The client creates a remote game, accepts four-digit guesses using digits from 1 to 6, displays black and white feedback, and deletes the session on victory or exit.

## Build this version

With a Swift toolchain that supports async/await:

```sh
swiftc -parse-as-library main.swift -o mastermind
./mastermind
```

On Windows, use `-o mastermind.exe` and run `./mastermind.exe`. The client connects to `https://mastermind.darkube.app` and requires the backend to be reachable.

## Contents

`main.swift` contains the API models, the `MastermindAPI` actor, and the interactive entry point. This snapshot has no package manifest or automated test suite.
