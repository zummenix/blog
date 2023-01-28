+++
title = "You should still be careful using KVO"
description = "Discovering and solving an issue with KVO"
date = 2022-08-15
+++

Key-Value Observing or KVO for short is a good technology. Especially, when you
don't have other ways available to observe changes on some properties of an
object. For those who have never used KVO and not familiar with it I'm gently
asking to read about it in Apple documentation first. I won't explain it here.
I only add a small note: several years ago Apple introduced a new KVO API which
is definitely safer to use comparing to the old one. In this post we are
looking only into the new one. Ok, let's proceed.

## Introduction

Recently, I was working on an iOS project where KVO was implemented some time
ago. Worked fine. Not a single problem. But after some changes, completely
unrelated, the app started crashing. A stack trace showed a culprit which
undeniably was the part with KVO.

Let's dive in into the code.

```swift
class Store: NSObject {
    @objc
    dynamic var isValid = false
}

class Status: NSObject {
    @objc
    private let store: Store

    init(store: Store) {
        self.store = store
    }

    func subscribe(onChange: @escaping () -> Void) -> AnyObject {
        let observation = observe(\.store.isValid, options: [.new, .old]) { _, change in
            if change.oldValue != change.newValue {
                DispatchQueue.main.async {
                    onChange()
                }
            }
        }
        return observation
    }
}
```

Let me explain what is going on. We have two classes here. One of them is
called `Store` which has some properties that we want to observe. The second is
called `Status`, the actual observer, an abstraction that is hidden under
protocol (not shown here for simplicity). The `Store` is actually implemented
in Objective-C, but this part is irrelevant here. The `Status` has a method
`func subscribe(onChange: @escaping () -> Void) -> AnyObject`. The method is
just a wrapper for the KVO's `observe` method with some minor logic.

Do you smell anything "funny" here? I don't (at least initially). Look, even
notifications about changes are propagated on the main queue.

## A Crash

A crash was happening in some situations when other parts of our codebase were
changing `isValid` property of the `Store` instance. `EXC_BAD_ACCESS`
exception. It means it is a memory management error. The stack trace showed an
internal private function `_NSSetBoolValueAndNotify` of the objc runtime. I had
no idea what it was.

The situation was complicated by several factors. First of all, the crash
wasn't reproducible in debug builds, only in release builds. Second, to crash
you need to tap-tap-tap and click-click-click through several screens and
buttons. By following steps our QA gave me, I've spent many many hours trying
to reproduce the crash. No luck. Until I've decided to enable "Zombie Objects"
in xcode's scheme Diagnostics tab. After all, the crash is clearly related to
the memory management. Then, followed the QA's steps again and boom, the Crash!
But why though?

## Why?

After some more hours looking into debugger, checking out lifetimes of objects,
I finally got a vague idea what was going on. My assumption was that the
`Status` object was deallocated before the observation that we return in the
`Status.subscribe(_:)` method. Ok, let's write a unit test for this. Luckily,
we had some unit tests already and adding one more was an easy task.

```swift
class KVOTests: XCTestCase {
    private let store = Store()
    private var observation: AnyObject?

    func testDeinit() {
        var sut: Status? = makeSUT()
        observation = sut?.subscribe {
        }

        store.isValid.toggle()

        sut = nil
        observation = nil

        let exp = expectation(description: "wait and update on main")
        DispatchQueue.main.asyncAfter(deadline: .now() + .microseconds(100)) {
            self.store.isValid.toggle() // Should not crash here.
            exp.fulfill()
        }

        wait(for: [exp], timeout: 1)
    }

    // MARK: - Helpers

    private func makeSUT() -> Status {
        Status(store: store)
    }
}
```

> If you want to repeat it yourself at home, you probably need to enable the
> "Zombie Objects" setting for tests.

Basically, here we are emulating the situation when the `Status` (`sut`) object
is deallocated before the `observation`. I've pointed out where the crash is
happening by the comment `Should not crash here.`. Now we have a failing test.
Good! Classic TDD. I love it! Let's get it green.

## A Fix

We need to, somehow, extend the lifetime of the `Status` object to be at least
the same as our `observation`. Of course, we could change how we use it in our
codebase to make sure that `Status` instances were alive longer, but there
weren't any guarantees that other developers will not run into a similar
problem again. I want to avoid it and fix it once and for all. And I was
feeling a slight guilt because it was me who had implemented this abstraction
in the first place :)

One way to extend the lifetime of the `Status` object is to return it along
side the `observation`. Let's do that by adding a private class which would
combine observer and observation together:

```swift
private class Observation {
    private var observation: NSKeyValueObservation?
    private var observer: Status?

    init(observation: NSKeyValueObservation?, observer: Status?) {
        self.observation = observation
        self.observer = observer
    }

    deinit {
        // Order is important.
        observation?.invalidate()
        observation = nil
        observer = nil
    }
}
```

I think the code is clear and doesn't need an explanation. Let's create the
`Observation` in our `Status.subscribe(_:)` method and return it. Here is the
diff:

```diff
    func subscribe(onChange: @escaping () -> Void) -> AnyObject {
        let observation = observe(\.store.isValid, options: [.new, .old]) { _, change in
            if change.oldValue != change.newValue {
                DispatchQueue.main.async {
                    onChange()
                }
            }
        }
-       return observation
+       return Observation(observation: observation, observer: self)
    }
```

`Cmd+U` and... The test has passed. Nice! Yep, and the app is running fine now.

## Conclusion

Do you remember times where the old KVO observation API was hard to use without
encountering random crashes? Those times are still here. Maybe, the situation
is a little bit better, but still... Really, this behaviour isn't documented
anywhere (at least I haven't found it). I guess, at Apple nobody foreseen that
the API will be used this way where the observer is not the object who keeps
the observation. The fix works for us and I hope I haven't introduced other
bugs here. So, please still be careful using KVO in your projects.

