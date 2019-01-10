/*:
 # Functional Programming in Swift with ![Bow](bow-brand-color.png)
 
 by Tomás Ruiz-López ([@tomasruizlopez](https://twitter.com/tomasruizlopez), [github.com/truizlop](https://www.github.com/truizlop))
 Senior Software Engineer at 47degrees ([@47deg](https://twitter.com/47deg))
 
 Bow is a Swift library for Typed Functional Programming, available as an open-source project on [Github](https://github.com/bow-swift/bow).
 
 To use it, you only need to check it out with your preferred dependency manager (Cocoapods, Carthage or Swift Package Manager) and import it:
 */
import Bow
/*:
 ## What is Functional Programming?
 
 *Functional Programming is a programming paradigm - a style of building the structure and elements of computer programs - that treats computation as the evaluation of mathematical functions and avoids changing-state and mutable data.* - **Wikipedia**
 
 Functional Programming is programming with **functions**.
 
 Functions must be:
 - **Total**: there is an output for every input.
 - **Deterministic**: for a given input, the function always return the same output.
 - **Pure**: the evaluation of the function does not cause other effects besides computing the output.
 */
func add(x: Int, y: Int) -> Int {
    return x + y // Total, deterministic, pure
}

func divide(x: Int, y: Int) -> Int {
    guard y != 0 else { fatalError("Division by 0") } // Not total: function is not defined for y = 0
    return x / y
}

func dice(withSides sides: UInt32) -> UInt32 {
    return 1 + arc4random_uniform(sides) // Not deterministic: each invocation returns a different output
}

func save(data: String) -> Bool {
    print("Saving data: \(data)") // Not pure, causes an effect other than computing the output
    return true
}
/*:
 ## Function composition
 
 The most basic operation in functional programming is **composition**. Composing two functions is equivalent to applying them sequentially.
 
 In Bow, there is a function called `compose` to do this:
 */
func f1(_ x : Int) -> Int {
    return 2 * x
}

func f2(_ x : Int) -> String {
    return "\(x)"
}

let composed = compose(f2, f1)
composed(3)
/*:
 Alternatively, you can use the compose operator `<<<`:
 */
let composedWithOperator = f2 <<< f1
/*:
 Reading composition backwards is sometimes difficult, specially if we chain multiple functions. Bow has a function called `andThen`, which has inputs in reverse order:
 */
let composedWithAndThen = andThen(f1, f2)
/*:
 Likewise, Bow has the `andThen` operator, namely `>>>`:
 */
let composedWithAndThenOperator = f1 >>> f2
/*:
 Let's see it in a working example to guess someone's birthday. The steps are:
 
 1.  Multiply the number of the month in which you were born by 5.
 2.  Add 17.
 3.  Double the answer.
 4.  Subtract 13.
 5.  Multiply by 5
 6.  Subtract 8.
 7.  Double the answer.
 8.  Add 9.
 9.  Add the number of the day on which you were born.
 
 Then, you can subtract 203 and the resulting number will have the formay {month}{day}.
 
 We can convert this into functions that we can compose:
 */
class BirthdayComposition {
    static let month = 1
    static let day = 20
    
    static func multiplyBy5(_ x : Int) -> Int {
        return 5 * x
    }
    
    static func add17(_ x : Int) -> Int {
        return x + 17
    }
    
    static func multiplyBy2(_ x : Int) -> Int {
        return 2 * x
    }
    
    static func subtract13(_ x : Int) -> Int {
        return x - 13
    }
    
    static func subtract8(_ x : Int) -> Int {
        return x - 8
    }
    
    static func add9(_ x : Int) -> Int {
        return x + 9
    }
    
    static func addDay(_ x : Int) -> Int {
        return x + day
    }
    
    static func subtract203(_ x : Int) -> Int {
        return x - 203
    }
    
    static let guessBirthday = multiplyBy5
                            >>> add17
                            >>> multiplyBy2
                            >>> subtract13
                            >>> multiplyBy5
                            >>> subtract8
                            >>> multiplyBy2
                            >>> add9
                            >>> addDay
                            >>> subtract203
    
    static func run() -> Int {
        return guessBirthday(month)
    }
}

BirthdayComposition.run()
/*:
 The example above composes pure, deterministic, total functions in order to solve a problem, but has a small problem: it does not reuse existing operations. In fact, we are using functions `+`, `-` and `*` with one of the parameters fixed.
 
 Function composition is defined over functions that receive just one input and return an output. These operators, however, receive two inputs. How can we compose them? We can use a technique called **currying**.
 
 Currying is a technique that converts functions that receive multiple arguments into a sequence of evaluating unary functions. Dually, uncurrying allows to convert a sequence of evaluating unary functions into a function with multiple arguments.
 
 - **Currying**: `(A, B) -> C` is equivalent to `(A) -> (B) -> C`
 - **Uncurrying**: `(A) -> (B) -> C` is equivalent to `(A, B) -> C`
 
 Both functions are available in Bow. Therefore, we can rewrite `add-` and `multiply-` functions as:
 */
class BirthdayCurrying {
    static let month = 1
    static let day = 20
    
    static let multiplyBy5 = curry(*)(5)
    static let add17       = curry(+)(17)
    static let multiplyBy2 = curry(*)(2)
    static let add9        = curry(+)(9)
    static let addDay      = curry(+)(day)
/*:
 Add and multiply are commutative, so we can fix the first parameter in the curried version of the functions. However, in `subtract` we would need to write a helper function that reverses the parameters, curries it and fixes the first one (corresponding to the second in the original `subtract`. Bow includes a function `reverse` that, given a function, returns another function with the order of the arguments reversed. Therefore, we can rewrite the subtract functions as:
 */
    static let subtract13  = curry(reverse(-))(13)
    static let subtract8   = curry(reverse(-))(8)
    static let subtract203 = curry(reverse(-))(203)
    
    static let guessBirthday = multiplyBy5
                            >>> add17
                            >>> multiplyBy2
                            >>> subtract13
                            >>> multiplyBy5
                            >>> subtract8
                            >>> multiplyBy2
                            >>> add9
                            >>> addDay
                            >>> subtract203
    
    static func run() -> Int {
        return guessBirthday(month)
    }
}

BirthdayCurrying.run()
/*:
 ## Partial application
 
 A similar approach to solve the problem above is to use a technique called **partial application**. In Swift, when we have functions that receive multiple arguments, we need to pass all of them in order to run the function. Bow introduces the partial application operator `|>` that allows us to pass the first parameter and obtain a function with the rest of arguments. You can think of this operator as something similar to the pipe operator in terminal commands. The example above can be rewritten as:
 */
class BirthdayPartialApplication {
    static let multiplyBy5 =   5 |> (*)
    static let add17       =  17 |> (+)
    static let multiplyBy2 =   2 |> (*)
    static let subtract13  =  13 |> reverse(-)
    static let subtract8   =   8 |> reverse(-)
    static let add9        =   9 |> (+)
    static let subtract203 = 203 |> reverse(-)
    
    static func guessBirthday(_ day : Int, _ month : Int) -> Int {
        return month
                |> multiplyBy5
                |> add17
                |> multiplyBy2
                |> subtract13
                |> multiplyBy5
                |> subtract8
                |> multiplyBy2
                |> add9
                |> (day |> (+))
                |> subtract203
    }
}

BirthdayPartialApplication.guessBirthday(20, 1)
/*:
 Next: [Data types](@next)
 */
