import Bow
import BowEffects
/*:
 ## Effects
 
 So far we have seen some data types that Bow provides in order to help us convert our partial functions into total ones. However, in many cases we need to perform effects, which make our functions to be impure. For these cases, Bow provides the **`IO`** data type, in order to encapsulate effects.
 */
func write(_ text : String) -> () {
    print(text)
}
/*:
 `write` is an impure function. It does not return any value, just causes an effect (printing an string to the standard output). Other effects may be writing a file, saving content to a database or sending an HTTP request. The `IO<A>` type encapsulate an effect of type `A`, but does not execute it:
 */
func writeIO(_ text : String) -> IO<()> {
    return IO.invoke{ print(text) }
}
/*:
 `writeIO` is a pure function as it returns a value encapsulating the computation/effect we want to perform. We need to explicitly evaluate it in order to execute it:
 */
writeIO("Hello, world!") // Returns an IO<()>, but does not run it
writeIO("Hello, world!").unsafePerformIO()
/*:
 We can also have effects that produce values:
 */
func fetchHTTP(userId : String) -> IO<String> {
    return IO.invoke {
        // Call server
        return "{ \"name\"  \"Tomás\" }"
    }
}
/*:
 Then, we can use `IO` functions to transform the result across the layers of our application:
 */
struct Contact : Codable {
    let name : String
}

enum ParsingError {
    case unableToParseContact(fromJSON : String)
}

func jsonToContact(_ json : String) -> Either<ParsingError, Contact> {
    let decoder = JSONDecoder()
    if let data = json.data(using: .utf8) {
        do {
            let contact = try decoder.decode(Contact.self, from: data)
            return Either.right(contact)
        } catch {}
    }
    return Either.left(.unableToParseContact(fromJSON: json))
}

fetchHTTP(userId: "1234")
    .map(jsonToContact)
    .unsafePerformIO()
/*:
 ## Third-party integrations
 
 `IO` is a suitable alternative to encapsulate effects. However, some people are already using other libraries like **RxSwift** or **BrightFutures**. Bow provides integrations with both through some wrappers.
 
 ### RxSwift
 
 There are three wrappers over the main types provided by RxSwift: `ObservableK`, `SingleK` and `MaybeK`. They can be constructed like:
 */
import RxSwift
import BowRx

let observable = ObservableK(Observable.from([1, 2, 3, 4]))
let single = SingleK(value: Single.just(1))
let maybe = MaybeK(Maybe.just(1))
/*:
 Or you can build them with an extension function `.k()`
 */
let observable2 = Observable.from([1, 2, 3, 4]).k()
let single2 = Single.just(1).k()
let maybe2 = Maybe.just(1).k()
/*:
 ### BrightFutures
 
 Similarly, Bow provides a wrapper, `FutureK`, over the main type provided in the library BrightFutures:
 */
import BrightFutures
import BowBrightFutures

enum NoError : Error {}

let future = FutureK(Future<Int, NoError>(value: 1))
let future2 = Future<Int, NoError>(value: 1).k()
/*:
 Next: [Higher Kinded Types and Typeclasses](@next)
 */
