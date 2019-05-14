import Foundation

public struct Future<A> {
    private let f: (@escaping (A) -> Void) -> Void

    public init(_ f: @escaping (@escaping (A) -> Void) -> Void) {
        self.f = f
    }

    public static func `return`(_ value: A) -> Future<A> {
        return Future<A> { $0(value) }
    }

    public func onResult(_ f: @escaping (A) -> Void) {
        self.f(f)
    }

    public func await() -> A {
        var a: A!
        let semaphore = DispatchSemaphore(value: 0)

        DispatchQueue(label: "queue not blocked by semaphore").sync {
            self.onResult {
                a = $0
                semaphore.signal()
            }
        }
        semaphore.wait()

        return a
    }

    public func map<B>(_ f: @escaping (A) -> B) -> Future<B> {
        return Future<B> { bToVoid in
            self.onResult { a in
                bToVoid(f(a))
            }
        }
    }

    public func flatMap<B>(_ f: @escaping (A) -> Future<B>) -> Future<B> {
        return Future<B> { bToVoid in
            self.onResult { a in
                f(a).onResult(bToVoid)
            }
        }
    }

    public func apply<B>(_ f: Future<(A) -> B>) -> Future<B> {
        return concat(f).map { $0.1($0.0) }
    }

    public func observe(on queue: DispatchQueue) -> Future<A> {
        return Future<A> { aToVoid in
            self.onResult { a in
                queue.async {
                    aToVoid(a)
                }
            }
        }
    }

    public func concat<B>(_ b: Future<B>) -> Future<(A, B)> {
        return Future<(A, B)> { abToVoid in

            let semaphore = DispatchSemaphore(value: 1)

            var resultA: A?
            var resultB: B?

            self.onResult { a in
                semaphore.wait()
                resultA = a
                if let b = resultB {
                    abToVoid((a, b))
                }
                semaphore.signal()
            }

            b.onResult { b in
                semaphore.wait()
                resultB = b
                if let a = resultA {
                    abToVoid((a, b))
                }
                semaphore.signal()
            }
        }
    }
}
