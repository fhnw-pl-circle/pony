// Definition of topics as generic class and callbacks

actor Topic[A: Any #share]
  let subscribers:  Array[Callback[A] tag] = []


  be subscribe(callback: Callback[A] tag) =>
    subscribers.push(callback)


  be publish(message: A) =>
    for callback in subscribers.values() do
      callback(message)
    end

interface Callback[A: Any #send]
  be apply(message: A)
