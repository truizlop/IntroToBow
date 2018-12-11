import Bow
/*:
 ## Higher Kinded Types
 
 In previous sections we have seen multiple ways of defining the `divide` function:
 */
enum DivideError : Error {
    case divisionByZero
}

func divideOption(x : Int, y : Int) -> Option<Int> {
    guard y != 0 else { return Option.none() }
    return Option.some(x / y)
}

func divideEither(x : Int, y : Int) -> Either<String, Int> {
    guard y != 0 else { return Either.left("Divide by 0") }
    return Either.right(x / y)
}

func divideTry(x : Int, y : Int) -> Try<Int> {
    guard y != 0 else { return Try.failure(DivideError.divisionByZero) }
    return Try.success(x / y)
}
/*:
 Choosing one over the others would force callers of these functions to use a specific data type. Moreover, if we check the structure of the implementation of each function, we can see some similarities:
 
 1. We check that `y != 0`
 2. If not, we raise an error of some kind (absent value, string message or error value)
 3. If so, we perform the division and return it in a success case
 
 Would it be possible to generalize it? All three functions are returning a type of the form F<Int>. However, Swift only lets us abstract over the contained type, not the container. This is only possible with the notion of **Higher Kinded Types**. With this support, we could do something like:
 
 ```swift
 func divide(x : Int, y : Int) -> F<Int> { ... }
 ```
 
 Although Higher Kinded Types (HKTs) are listed in the [Swift Generics Manifesto](https://github.com/apple/swift/blob/master/docs/GenericsManifesto.md), they are not implemented yet. To overcome this situation, Bow has implemented a way of simulating HKTs. Bow defines an HKT as:
 
 ```swift
 class Kind<F, A> {} // This is equivalent to F<A>
 ```
 
 Therefore, if we want our types to have HKT support, we need to extend this class. As an example, let's see how `Option<A>` is implemented.
 
 If `F<A>` is equivalent to `Kind<F, A>`, then `Option<A>` should inherit `Kind<Option, A>`.
 
 ```swift
 class Option<A> : Kind<Option, A> {} // Compile error: missing type parameter and cyclic dependency
 ```
 
 However, this is a compile error (`Option` needs a type parameter) and introduces a cycle in the inheritance. Instead, we create tags to represent the type; they are usually prepended by the prefix `For`. Thus, the `Option` HKT would be something like:
 
 ```swift
 class ForOption {}
 typealias OptionOf<A> = Kind<ForOption, A>
 class Option<A> : OptionOf<A> { ... }
 ```
 
 All Bow data types have been implemented with HKT support. You should not worry about this unless you want to create your own HKTs.
 
 Moreover, there are wrappers over certain data types provided in the standard library:
 */
let list = ListK([1, 2, 3, 4])
let set = SetK([1, 2, 1, 2])
/*:
 Other integrations, like RxSwift and BrightFutures, have also been wrapped to have HKT support. You can distinguish the HKT versions because they have the suffix `K`
 
 The result of some operations may return values of type `Kind<F, A>` instead of the concrete classes. For instance, we may end up with a result of type `Kind<ForOption, A>`, when we really need an `Option<A>`. Bow HKTs have a static method `fix` to do this task:
 
 ```swift
 let kind : Kind<ForOption, A> = ...
 let option = Option<A>.fix(kind) // option is now of type Option<A>
 ```
 
 HKTs that only have a single type parameter usually have an instance method `fix` to do the same trick:
 
 ```swift
 let kind : Kind<ForOption, A> = ...
 let option = kind.fix() // option is now of type Option<A>
 ```
 */
/*:
 ## Typeclasses
 
 We have worked around the first problem we were having and now we can abstract over the container of a type thanks to Bow HKT simulation. Now, we need an abstract mechanism to do the two operations that we were dealing with in our `divide` function: create a success value and raise an error. This is possible thanks to the notion of **Typeclasses**.
 
 A typeclass is a set of operations for a generic type, with (typically) a set of laws that rule its behavior. The closest concept in Swift is the notion of **protocol with associated types**.
 
 Bow provides a number of typeclasses, among those we can find one that fits our purpose: **`ApplicativeError`**. This typeclass has, among others, two functions called `pure` (to create a successful result) and `raiseError` (to create an error result), which fits our purpose. We can now write our function like:
 */
func divide<F, ApplicativeErrorF>(x : Int, y : Int, _ applicativeError : ApplicativeErrorF) -> Kind<F, Int> where
    ApplicativeErrorF : ApplicativeError,
    ApplicativeErrorF.F == F,
    ApplicativeErrorF.E == DivideError {
        
    guard y != 0 else { return applicativeError.raiseError(DivideError.divisionByZero) }
    return applicativeError.pure(x / y)
}
/*:
 Now, callers may choose what data type they would like to receive:
 */
divide(x: 6, y: 3, Either<DivideError, Int>.applicativeError())
divide(x: 2, y: 0, Either<DivideError, Int>.applicativeError())

divide(x: 6, y: 3, Try<Int>.applicativeError())
divide(x: 2, y: 0, Try<Int>.applicativeError())
/*:
 Some of the typeclasses provided in Bow are:
 
 - **`Functor`**: map elements from a type to another.
 - **`Applicative`**: perform multiple independent computations.
 - **`Monad`**: perform multiple sequential computations.
 - **`ApplicativeError`**: `Applicative` with error handling capabilities.
 - **`MonadError`**: `Monad` with error handling capabilities.
 - **`Eq`**: compare equality of two values.
 - **`Order`**: compare order of two values.
 - **`Semigroup`**: combine two values.
 - **`Monoid`**: `Semigroup` with an "empty" value.
 */
/*:
 Next: [Polymorphic programs](@next)
 */
