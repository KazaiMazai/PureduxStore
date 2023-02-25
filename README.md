<p align="center">
  <img src="Logo.svg?raw=true" alt="Sublime's custom image"/>
 </p>
 


# Puredux-Store

Yet another UDF Architecture Store implementation
<p align="left">
    <a href="https://github.com/KazaiMazai/PureduxStore/actions">
        <img src="https://github.com/KazaiMazai/PureduxStore/workflows/Tests/badge.svg" alt="Continuous Integration">
    </a>
</p>

## Features

- Minimalistic 
- Operates on main or background queue
- Light-weight store proxies
- Thread safe 
- Simple actions interceptor for side effects
____________


## Installation
 

### Swift Package Manager.

PureduxStore is available through Swift Package Manager. 
To install it, in Xcode 11.0 or later select File > Swift Packages > Add Package Dependency... and add Puredux repositoies URLs for the modules requried:

```
https://github.com/KazaiMazai/PureduxStore
```
____________

## Basics

- State is a type describing the whole application state or a part of it
- Actions describe events that may happen in the system and mutate the state
- Reducer is a function, that describes how Actions mutate the state
- Store is the heart of the whole thing. It takes Initial State and Reducer, performs mutations when Actions dispatched and deilvers new State to Observers


## Quick Start Guide

1. Import:
```swift
import PureduxStore

```

2. Create initial app state:

```swift
let initialState = AppState()
```

and `Action` protocol:

```swift

protocol Action {

}

```

3. Create reducer:

```swift 
let reducer: (inout AppState, Action) -> Void = { state, action in

    //mutate state here

}

```

4. Create root store with initial app state and reducer. Get light-weight store:

```swift
let factory = StoreFactory<AppState, Action>(
    initialState: initialState,
    reducer: reducer
)

let store = factory.store()
```

5. Setup actions interceptor for side effects:

Let's have an `AsyncAction` protocol defined as:

```swift

protocol AsyncAction: Action {
    func execute(completeHandler: @escaping (Action) -> Void)
}
```

and some long running action that with injected service:

```swift
struct SomeAsyncAction: AsyncAction {
    @DI var service: SomeInjectedService

    func execute(completeHandler: @escaping (Action) -> Void) {  
        service.doTheWork {
            switch $0 {
            case .success(let result):
                completeHandler(SomeResultAction(result))
            case .success(let error):
                completeHandler(SomeErrorAction(error))
            }
        }
    }
}

```

Execute side effects in the interceptor, passed to store factory:

```swift

let storeFactory = StoreFactory<AppState, Action>(
    initialState: initialState, 
    interceptor:  { action, dispatch in
        guard let action = ($0 as? AsyncAppAction) else  {
            return
        }
    
        DispatchQueue.main.async {
            action.execute { dispatch($0) }
        } 
    },
    reducer: reducer
)

```

6. Create scoped stores with substate:

```swift
let scopedStore = storeFactory.scopeStore { appState in appState.subState }

```

7. Create store observer and subscribe to store:


```swift 
let observer = Observer<SubState> { substate, completeHandler in
    
    // Handle your latest state here and dispatch some actions to the store
    
    scopedStore.dispatch(SomeAction())
    
    guard wannaKeepReceivingUpdates else {
        completeHandler(.dead)
        return 
    }
    
    completeHandler(.active)
}

scopedStore.subscribe(observer: observer)

```


8. Create child stores with local state and its own lifecycle:

```swift
 
storeFactory.childStore(
    initialState: LocalState(),
    reducer: { localState, action  in
        localState.reduce(action: action)
    }
)

let observer = Observer<(AppState, LocalState)> { stateComposition, complete in
    // Handle your latest state here and dispatch some actions to the store

    scopedStore.dispatch(SomeAction())

    guard wannaKeepReceivingUpdates else {
        completeHandler(.dead)
        return 
    }

    completeHandler(.active)
}

childStore.subscribe(observer: observer)


```


## How to migrate from v1.0.x to v1.1.x

Old API will be deprecated in the next major release. 
Please consider migration to the new API.

<details><summary>Click for details, it's not a big deal</summary>
<p>

### 1. Migrate From `RootStore` to `StoreFactory`:

Before: 

```swift
let rootStore = RootStore<AppState, Action>(
    queue: StoreQueue = .global(qos: .userInteractive)
    initialState: initialState, 
    reducer: reducer
)

```

Now:

```swift
let storeFactory = StoreFactory<AppState, Action>(
    initialState: initialState, 
    qos: .userInteractive,
    reducer: reducer
)

```

MainQueue is not available for Stores any more. 
Since now, stores operate on a global serial queue with configurable QoS.

### 2. Update actions interceptor and pass in to store factory:

Before:

```swift

rootStore.interceptActions { action in
    guard let action = ($0 as? AsyncAppAction) else  {
        return
    }
    
    DispatchQueue.main.async {
        action.execute { store.dispatch($0) }
    }   
}

```

Now:

```swift
let storeFactory = StoreFactory<AppState, Action>(
    initialState: initialState, 
    interceptor:  { action, dispatched in
        guard let action = ($0 as? AsyncAppAction) else  {
            return
        }
    
        DispatchQueue.main.async {
            action.execute { dispatch($0) }
        } 
    },
    reducer: reducer
)

```
### 3. Migrate from `proxy(...)` to `scope(...)`:

Before:

```swift
let storeProxy = rootStore.store().proxy { appState in appState.subState }

```

Now:

```swift
let scopeStore = storeFactory.scopeStore() { appState in appState.subState }

```

</p>
</details>

## Basics Q&A

<details><summary>Click for details</summary>
<p>

  
### How to connect PureduxStore to UI?
  
- It can be done with the help of [PureduxUIKit](https://github.com/KazaiMazai/PureduxUIKit) or [PureduxSwiftUI](https://github.com/KazaiMazai/PureduxSwiftUI)


### What is StoreFactory?

StoreFactory is a factory for Stores and StoreObjects.
It suppports creation of the following store types:
- store - root parent Store
- scopeStore - scoped Store as proxy to the root store
- childStore - child StoreObject with `(Root, Local) -> Composition` state mapping and it's own lifecycle


### What queue does the root store operate on?

- By default, it works on a global serial queue with `userInteractive` quality of service. QoS can be changed.
 

### What is a Store?

- Store is a lightweight store. 
- It's only a proxy to the root store: it forwards subscribtions and all dispatched Actions to it.
- Root store can be another Store, StoreFactory's root store or a child store.
- Store is designed to be passed all over the app safely without extra effort.
- It's threadsafe. It allows to dispatch actions and subscribe from any thread. 
- It keeps weak reference to the root store, that allows to avoid creating reference cycles accidentally.

### What is a StoreObject?

- It's almost the same thing as a Store 
- It keeps a *strong* reference to the root store.
- It's designed to manage the lifecycle of child stores

</p>
</details>

## Child Store Q&A

<details><summary>Click for details</summary>
<p>

### What is child store?

- Child store is a separate store 
- Child store has its own local state
- Child store has its own local state reducer
- Child store is attached to the root store
- Child store's state is a composition of parent state and local state
- Creates child-parent hierarchy

### How to create child store?

StoreFactory allows to create child stores. 
You should only provide initial state and reducer:

```swift
 
storeFactory.childStore(
    initialState: LocalState(),
    reducer: { localState, action  in
        localState.reduce(action: action)
    }
)

```
### How to manage child store's and its state lifecycle?

Child store's `StoreObject` behaves just like normal class does.
It exist while you keep a reference to it.

### Actions dispatching for ChildStores follow the rules:
- Actions go up. From child stores to parent
- Actions don't go down. From parent to child stores.
- Action never go horizontally. From childStoreA to childStoreB
- State changes go down. From parent to child stores. From stores to subscribers.
- Interceptor dispatches new actions to the same store where the initial action was dispatched. 

According to the rules above.

When action is dispatched to RootStore:
- action is delivered to root store's reducer
- action is *not* delivered to child store's reducer
- root state update triggers root store's subscribers
- root state update triggers child stores' subscribers
- Interceptor dispatches additional actions to RootStore

When action is dispatched to ChildStore:
- action is delivered to root store's reducer
- action is delivered to child store's reducer
- root state update triggers root store's subscribers.
- root state update triggers child store's subscribers.
- local state update triggers child stores' subscribers.
- Interceptor dispatches additional actions to ChildStore

### Does Child Store deduplicate state changes somehow?
- No. Child Store observers are triggered at every state change: both parent's state  and its own.


</p>
</details>

## Scoped Store Q&A

<details><summary>Click for details</summary>
<p>

### What's the scoped store?
 
- Scoped store is a simple proxy to the root store  
- Scoped doesn't have its own local state.
- Scoped doesn't have its own reducer
- Scoped store's state is a mapping of the root state.
- Doesn't create any child-parent hierarchy

### Does Proxy Store deduplicate state changes somehow?
- No, Proxy Store observers are triggered at every root store state change.

### What for?
- The purpose is to scope entire app state to app features
  
</p>
</details>

### How to unsubscribe from store?
 
- Call store observer's complete handler with dead status:
  
```swift 
let observer = Observer<State> { state, completeHandler in
    //
    completeHandler(.dead)
}
 
``` 

</p>
</details>


## Licensing

PureduxStore is licensed under MIT license.
