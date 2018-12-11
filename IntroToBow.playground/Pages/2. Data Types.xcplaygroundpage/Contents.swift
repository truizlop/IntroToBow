import Bow
/*:
 ## Data types
 
 The examples in the [previous section](@previous) are written with total, deterministic and pure functions. However, this is not always the case. We can have business logic that is not defined for all input (non-total functions), that have some source of randomness (non-deterministic functions) or that need to cause side-effects (non-pure functions). For those cases, Bow provides a set of **data types** that will help us convert impure functions into pure ones.
 
 Let's consider the following function:
 */
func divide(x : Int, y : Int) -> Int {
    guard y != 0 else { fatalError("Division by 0") }
    return x / y
}
/*:
 As stated in the previous section, this is a **partial** function since it is not defined for every possible input. In fact, it crashes for every input in the form `(x, 0)`.
 
 ### Option
 
 A possible way to make the divide function **total** is to use the **`Option`** data type that Bow provides:
 */
func divideOption(x : Int, y : Int) -> Option<Int> {
    guard y != 0 else { return Option.none() }
    return Option.some(x / y)
}

divideOption(x: 6, y: 3)
divideOption(x: 2, y: 0)
/*:
 Now, `divideOption` is able to return a value for each possible input; i.e., it is a total function.
 
 `Option<A>` is similar to Swift `Optional`, except for a few differences that we will see later. In fact, you can convert back and forth between Bow `Option` and native `Optional`:
 */
let bowSome = Option<Int>.some(2)
let bowNone = Option<String>.none()
bowSome.toOption()
bowNone.toOption()

let nativeSome : Int? = 2
let nativeNone : String? = nil
Option.fromOption(nativeSome)
Option.fromOption(nativeNone)
/*:
 That means `Option` and `Optional` are **isomorphic**: there is a pair of functions (namely `toOption` and `fromOption`) that, when composed, their result is the **identity function**.
 
 ### Either
 
 Another data type provided in Bow is **`Either`**. `Either<A, B>` is known as a **sum** type: it means it can contain a value of type `A` or a value of type `B`.
 
 Let's say that, instead of returning `Option.none()`, we want to be more explicit about the reason for the absence of an output in the `divide` example. We can define an error type:
 */
enum DivideError : Error {
    case divisionByZero
}
/*:
 Then, we can rewrite the divide function using `Either`:
 */
func divideEither(x : Int, y : Int) -> Either<DivideError, Int> {
    guard y != 0 else { return Either.left(.divisionByZero) }
    return Either.right(x / y)
}

divideEither(x: 6, y: 3)
divideEither(x: 2, y: 0)
/*:
 `Either` allows us to be more explicit about the error in the return type, helping the caller to be prepared to deal with the possible outputs it may receive. Nonetheless, the left type does not need to be an error; it can be any type:
 */
func divideEither2(x : Int, y : Int) -> Either<String, Int> {
    guard y != 0 else { return Either.left("Division by 0") }
    return Either.right(x / y)
}

divideEither2(x: 6, y: 3)
divideEither2(x: 2, y: 0)
/*:
 ### Ior
 
 While `Either` is equivalent to an exclusive or between types, `Ior<A, B>` lets us represent cases where we can have a value of type `A`, a value of type `B`, or both at the same time.
 
 Let's illustrate it with an example. We can think of a function to validate user names. Some errors may be fatal (the process cannot proceed) but others may be just warnings. For instance, an empty name is a fatal error, while an username containing a "." may be deprecated and discouraged in our system. We can model this as:
 */
enum NameValidation {
    case emptyName
    case deprecatedDot
}

func validate(name : String) -> Ior<NameValidation, String> {
    if name.isEmpty { return Ior.left(.emptyName) }
    if name.contains(".") { return Ior.both(.deprecatedDot, name) }
    return Ior.right(name)
}

validate(name: "tomasruiz")
validate(name: "tomas.ruiz")
validate(name: "")
/*:
 `Ior` lets us convert values to `Either`.
 */
validate(name: "tomasruiz").toEither()
validate(name: "tomas.ruiz").toEither()
validate(name: "").toEither()
/*:
 ### Try
 
 Swift functions may throw errors. For instance, it could be usual to define our `divide` function as:
 */
func divideThrows(x : Int, y : Int) throws -> Int {
    guard y != 0 else { throw DivideError.divisionByZero }
    return x / y
}
/*:
 However, this way of dealing with errors forces us to use a special syntax to invoke functions (using `do/try/catch` notation) and breaks linear execution of code, making it more difficult to understand and reason about it. Moreover, since the function does not return values for some inputs, it is not total.
 
 Bow provides a data type to deal with functions that may throw errors. This is the **`Try`** data type. `Try<A>` means that it contains a value of type `A`, or an error (subtype of native `Error`). We can rewrite the function as:
 */
func divideTry(x : Int, y : Int) -> Try<Int> {
    guard y != 0 else { return Try.failure(DivideError.divisionByZero) }
    return Try.success(x / y)
}

divideTry(x: 6, y: 3)
divideTry(x: 2, y: 0)
/*:
 `Try` also has some utilities to wrap throwing functions:
 */
Try.invoke { try divideThrows(x: 6, y: 3) }
Try.invoke { try divideThrows(x: 2, y: 0) }
/*:
 ### Result
 
 Many Swift libraries already use a similar data type called **`Result`**. In order to maximize compatibility between Bow and other libraries, Bow provides some extensions that allow to convert from `Result` to some Bow data types:
 */
import Result
import BowResult

let result = Result<Int, DivideError>(value: 2)
let eitherFromResult = result.toEither()
let tryFromResult = result.toTry()
let optionFromResult = result.toOption()
/*:
 Next: [Effects](@next)
 */
