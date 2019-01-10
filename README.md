# Intro to Bow

This repository is a Swift playground presenting an introduction about [Bow](https://github.com/bow-swift/bow) (version 0.3.0), a library for Functional Programming in Swift.

## How to build and run the project

In order to link the playground with the Bow framework, a workspace needed to be created. To be able to run it, you need to:

- 📥 Clone this project.
- ⚙️ Run `pod install` to fetch the dependencies.
- 🖥 Open `IntroToBow.xcworkspace`.
- 🔨 Build it. This will build the dependencies (different pods for the Bow modules that we are using in the introduction).
- ▶️ Run the playground.

## Contents

The playground contains 6 pages with an overview of the following concepts:

1. **Function composition**: it shows the main concepts behind Functional Programming and how to combine smaller functions to solve problems in a pure FP way.
2. **Data types**: some frequent data types to model absence of values, sum types or handle errors are presented in this section.
3. **Effects**: `IO` is the main way to handle effects in a pure FP manner, but integrations with other libraries such as RxSwift and BrightFutures are also possible.
4. **Higher Kinded Types and Typeclasses**: this section shows how Bow emulates Higher Kinded Types and how they can be used with Typeclasses to write generic programs.
5. **Polymorphic programs**: everything is put together in a simple example that demonstrates how to write a polymorphic program in Bow.
6. **Conclusions**: the main advantages and disadvantages of Bow are outlined here, with links for further reading and other examples.
