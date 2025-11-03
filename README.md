# PhoneBook iOS Application

A modern iOS phonebook application demonstrating advanced iOS development patterns including The Composable Architecture (TCA), AsyncSequence, Swift Concurrency, and thread-safe data handling.

## 📱 Project Description

This PhoneBook app showcases a complete architectural evolution from a basic UIKit + Combine implementation to a sophisticated, production-ready application using:

- **The Composable Architecture (TCA)** for predictable state management
- **AsyncSequence & Swift Concurrency** for modern async data handling  
- **Actor-based thread safety** for concurrent operations
- **Tuist** for project generation and dependency management
- **Comprehensive unit testing** with TCA's TestStore

### Key Features
- 📞 Contact management with name and phone number
- 🔍 Real-time search across names and phone numbers
- 🎲 Multi-threaded random contact generation (100 contacts across 4 threads)
- 📊 Thread-safe data operations using Swift actors
- 🧪 Full test coverage with TCA testing patterns

# Requirements

Please refactor the codebase to the requirements below:

1. Maintain the threaded nature of the code in `PhoneBook/Sources/View/PhonebookViewController.swift` function `addRandomizedRecords`. It is meant to simulate a multi-thread attempt for access to a critical area. You are otherwise free to refactor it.

2. Refactor from Combine to AsyncSequence for the data source handling.
- Make the data handling thread-safe.


3. Refactor view model to a Redux-style state machine.
- You may use any Redux-style framework. (eg. TCA, ReSwift, etc)


4. Any improvements that you see fit.
- Which other improvements do you feel are most important, and why?


5. Submit a Git repo.
- Please email gustav@onfleet.com
- You can send a zipped repo, or a link to a repo that we can access.
- We'd like to see your commit history.

## 🏗️ Architecture Overview

### The Composable Architecture (TCA)
The app uses TCA for state management, providing:
- **Unidirectional data flow** with predictable state mutations
- **Effect isolation** for side effects and async operations
- **Dependency injection** for testable, modular code
- **Time-travel debugging** capabilities

### Core Components

#### 1. **PhoneBookFeature** (`PhoneBookRedux.swift`)
- **@Reducer** struct implementing TCA patterns
- **State**: Manages records, filtered records, search text, and loading states
- **Actions**: Defines all possible user interactions and system events
- **Effects**: Handles async operations (data loading, randomization)

#### 2. **PhoneBookSource** (`PhoneBookSource.swift`)
- **Actor-based thread safety** preventing data races
- **AsyncStream publishers** for reactive data updates
- **Continuation management** with proper cleanup
- **Thread-safe CRUD operations**

#### 3. **View Layer** (`PhoneBookViewController.swift`)
- **TCA Store integration** for state observation
- **UIKit + TCA binding** for reactive UI updates
- **Multi-threaded operations** using TaskGroup
- **Proper lifecycle management**

## 🔄 Data Flow Architecture

```
User Interaction
    ↓
PhoneBookViewController (TCA Store)
    ↓
PhoneBookFeature.Action
    ↓
PhoneBookFeature.Reducer
    ↓ (Effects)
PhoneBookSource (Actor)
    ↓ (AsyncStream)
PhoneBookFeature.State
    ↓
UI Updates (Main Actor)
```

### Data Flow Details

1. **User Actions** → Dispatched to TCA Store
2. **Reducer Processing** → State mutations + Effect creation
3. **Effects Execution** → Async operations via actor isolation
4. **Data Updates** → AsyncStream notifications
5. **State Updates** → Automatic UI re-rendering

## 🧪 Testing Strategy

- **TCA TestStore** for deterministic state testing
- **Mock dependencies** via TCA's dependency injection
- **Async effect testing** with proper sequencing
- **Thread safety verification** through concurrent test scenarios

## 🚀 How to Run

### Prerequisites
- **Xcode 16.0+** (for Swift 6 support)
- **macOS 15.0+** (Sequoia)
- **iOS 18.0+** deployment target

### Setup Instructions

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd internal-mobile-ios-challenge
   ```

2. **Install Tuist** (if not already installed)
   ```bash
   curl -Ls https://install.tuist.io | bash
   ```

3. **Generate the Xcode project**
   ```bash
   tuist generate
   ```

4. **Open the workspace**
   ```bash
   open PhoneBook.xcworkspace
   ```

5. **Build and run**
   - Select `PhoneBook` scheme
   - Choose iOS Simulator or device
   - Press `Cmd+R` to build and run

### Running Tests

```bash
# Via Xcode
# Select UnitTests scheme and press Cmd+U

# Via command line
xcodebuild -workspace PhoneBook.xcworkspace -scheme UnitTests test CODE_SIGNING_ALLOWED=NO
```

### Project Structure
```
PhoneBook/
├── Sources/
│   ├── Redux/           # TCA implementation
│   ├── Model/           # Data models and actor-based sources
│   ├── View/            # UIKit view controllers
│   └── AppDelegate.swift
├── Resources/           # Storyboards and assets
└── Tests/
    └── UnitTests/       # TCA-based unit tests

Tuist/
├── Package.swift        # External dependencies
└── Project.swift        # Project configuration
```

## 🔧 Development Dependencies

- **The Composable Architecture** `~> 1.0` - State management and architecture
- **Fakery** `~> 5.0` - Random data generation for testing
- **Tuist** - Project generation and dependency management

## 📝 Implementation Notes

This project demonstrates advanced iOS development practices including:
- Modern Swift Concurrency patterns (async/await, TaskGroup, actor)
- Production-ready architecture with TCA
- Thread-safe concurrent programming
- Comprehensive testing strategies
- Modern project tooling with Tuist

# Original Challenge Requirements 

