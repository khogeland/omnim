import
    locks

type Atomic*[T] = ref object
    value: T
    lock: Lock

proc initAtomic*[T](value: T): Atomic[T] =
    var lock: Lock
    lock.initLock()
    return Atomic[T](value: value, lock: lock)

proc getValue*[T](this: Atomic[T]): T = this.value
proc setValue*[T](this: Atomic[T], value: T) = this.value = value

proc getAndSet*[T](this: Atomic[T], value: T): T =
    withLock this.lock:
        result = this.getValue()
        this.setValue(value)

