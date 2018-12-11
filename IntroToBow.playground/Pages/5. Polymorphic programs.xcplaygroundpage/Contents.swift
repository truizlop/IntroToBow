import Bow
import BowEffects
/*:
 ## Polymorphic programs
 
 ### Monomorphic purely functional programs
 Considering all what we have seen so far, let's try to write a simple program that greets a user after asking her name, in a purely functional way:
 */
class MonomorphicGreet {
    private func putString(_ line : String) -> IO<()> {
        return IO.invoke { print("Mono> \(line)") }
    }
    
    private func getString() -> IO<String> {
        return IO.invoke { "Tomás" } // This should call readLine, but it is not available in Swift Playgrounds
    }
    
    func greet() -> IO<()> {
        return self.putString("What's your name?").flatMap { _ in
            self.getString().flatMap { name in
                self.putString("Hello \(name)!")
            }
        }
    }
}

MonomorphicGreet().greet().unsafePerformIO()
/*:
 This program uses `IO` to encapsulate the effects of printing and reading from the standard input/output, and then concatenates those effects using `flatmap`. It is purely functional: every function is total, deterministic and pure. However, the `IO` data type is very powerful and, in fact, allows to perform almost every operation. Moreover, it binds the caller to use `IO`, which may result in a harder way to test the program.
 
 ### Tagless-final
 
 Is it possible to make it in a different way? Let's try an approach known as **Tagless-final**. We can abstract the operations used in a typeclass that is parameterized on the encapsulating type. Let's call this type `F`. We have two operations that we want to perform: `putString` and `getString`.
 
 Therefore, we can define the following typeclass:
 */
protocol Console {
    associatedtype F
    
    func putString(_ line : String) -> Kind<F, ()>
    func getString() -> Kind<F, String>
}
/*:
 We also need a way to chain instructions sequentially. As we discussed before, Bow provides the `Monad` typeclass that serves to this purpose.
 
 ```swift
 protocol Monad {
    associatedtype F
 
    func flatMap<A, B>(_ fa : Kind<F, A>, _ f : @escaping (A) -> Kind<F, B>) -> Kind<F, B>
 }
 ```
 
 Therefore, we can create our program in a polymorphic way:
 */
class PolymorphicGreet<F> {
    func greet<ConsoleF, MonadF>(_ console : ConsoleF, _ monad : MonadF) -> Kind<F, ()> where
        MonadF : Monad, MonadF.F == F,
        ConsoleF : Console, ConsoleF.F == F {
            
        return monad.flatMap(console.putString("What's your name?")) { _ in
            monad.flatMap(console.getString()) { name in
                console.putString("Hello \(name)!")
            }
        }
    }
}
/*:
 Now, we can interpret `PolymorphicGreet<ForIO>` by providing instances that implement `Console` and `Monad` for `IO`. Bow already provides an instance of `Monad` for `IO`, but we need to provide our own for `Console`:
 */
class IOConsole : Console {
    typealias F = ForIO
    
    func putString(_ line: String) -> Kind<ForIO, ()> {
        return IO.invoke{ print("Poly> \(line)") }
    }
    
    func getString() -> Kind<ForIO, String> {
        return IO.invoke { "Tomás" } // This should call readLine, but it is not available in Swift Playgrounds
    }
}
/*:
 With this, we can now invoke the program for `IO`:
 */
PolymorphicGreet<ForIO>().greet(IOConsole(), IO<()>.monad()).fix().unsafePerformIO()
/*:
 What if I want to leverage the power of other libraries, like RxSwift? Since Bow provides an integration with it, I can implement the necessary typeclass instances and interpret the same program with another type. Let's say I want to interpret the program using `SingleK`, as functions are not going to return more than one value. We can provide an instance of `Console` for `SingleK`:
 */
import RxSwift
import BowRx

class SingleKConsole : Console {
    typealias F = ForSingleK
    
    func putString(_ line: String) -> Kind<ForSingleK, ()> {
        return Single.just(()).do(onSuccess: { _ in print("Single> \(line)") }).k()
    }
    
    func getString() -> Kind<ForSingleK, String> {
        return Single.just("Tomás").k()
    }
}
/*:
 And invoke the polymorphic program with the appropriate instances:
 */
PolymorphicGreet<ForSingleK>().greet(SingleKConsole(), SingleK<()>.monad()).fix().value.subscribe { _ in }
/*:
 What about `Observable`? Same approach, just provide the necessary instance for `Console`:
 */
class ObservableKConsole : Console {
    typealias F = ForObservableK
    
    func putString(_ line: String) -> Kind<ForObservableK, ()> {
        return Observable.just(()).do(onNext: { _ in print("Obs> \(line)") }).k()
    }
    
    func getString() -> Kind<ForObservableK, String> {
        return Observable.from(["Tomás", "Migue", "Jorge", "Pepe"]).k()
    }
}
/*:
 And run the program with it:
 */
PolymorphicGreet<ForObservableK>().greet(ObservableKConsole(), ObservableK<()>.monad()).fix().value.subscribe { _ in }
/*:
 ### Testing
 
 The monomorphic version of the greeting program is difficult to test, since it is coupled to `IO`. The polymorphic version, though, is not aware of the exact type that we will be using; we can replace it by a more convenient type, with its instances, that enables us to inspect the result of executing the program. Before that, we can create a data structure where we can keep the data that will be consumed by the `getString` method, and produced by the `putString` method.
 */
struct TestData {
    let input : [String]
    let output : [String]
    
    init(input : [String], output : [String] = []) {
        self.input = input
        self.output = output
    }
    
    func copy(input : [String]? = nil, output : [String]? = nil) -> TestData {
        return TestData(input:  input  ?? self.input,
                        output: output ?? self.output)
    }
}
/*:
 Then, we can use the **`State`** data type to interpret the polymorphic program. This interpretation will consume a `String` from `TestData.input` every time `getString` is invoked, and will store a line into `TestData.output` every time `putString` is invoked. We will code this into the `Console` instance for `State`.
 */
typealias Test<A> = State<TestData, A>
typealias ForTest = StatePartial<TestData>

class TestConsole : Console {
    typealias F = ForTest
    
    func putString(_ line: String) -> Kind<ForTest, ()> {
        return Test<()>({ initialState in
            let nextState = initialState.copy(output: initialState.output + [line])
            return (nextState, ())
        })
    }
    
    func getString() -> Kind<ForTest, String> {
        return Test<String>({ initialState in
            let nextState = initialState.copy(input: Array(initialState.input.dropFirst()))
            let nextInput = initialState.input[0]
            return (nextState, nextInput)
        })
    }
}
/*:
 We can now produce a concrete program for `State` with its instances. In order to run it, we need to provide an initial `State`. An initial state is created with no output, and a single input (the one we expect to be consumed by the program.
 */
let testProgram = Test<()>.fix(PolymorphicGreet<ForTest>().greet(TestConsole(), Test<()>.monad()))
let initialState = TestData(input: ["Tomás"])
let result = testProgram.run(initialState)
/*:
 After running the program, the result will have a pair with the final state and the output of the program (which is `()`) in this case). We can assert that, during program execution, the inputs should have been consumed and we should have two outputs.
 */
result.0.input  == []                                    // Assert that input has been consumed
result.0.output == ["What's your name?", "Hello Tomás!"] // Assert that the correct output is produced
/*:
 ### Monad comprehensions
 
 `Monad` also enables a different syntax through a pattern known as **monad comprehensions**. The polymorphic version of the program can be written also as:
 */
class PolymorphicGreetMonadComprehensions<F> {
    func greet<ConsoleF, MonadF>(_ console : ConsoleF, _ monad : MonadF) -> Kind<F, ()> where
        MonadF : Monad, MonadF.F == F,
        ConsoleF : Console, ConsoleF.F == F {
            
        return monad.binding(
            {            console.putString("What's your name?") },
            { _       in console.getString() },
            { _, name in console.putString("Hello \(name)") }
        )
    }
}
/*:
 Next: [Conclusions](@next)
 */
