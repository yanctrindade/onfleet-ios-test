//
//  PhoneBookTests.swift
//  PhoneBookTests
//
//  Created by Milan Horvatovič on 25/07/2025.
//

@testable import PhoneBook
import ComposableArchitecture
import Testing

struct PhoneBookTests {
    
    // MARK: - Test Data
    
    private let mockDetails = [
        PersonDetail(id: "1", name: "Alice Johnson"),
        PersonDetail(id: "2", name: "Bob Smith"),
        PersonDetail(id: "3", name: "Charlie Brown")
    ]
    
    private let mockContacts = [
        PersonContact(id: "1", phoneNumber: "123-456-7890"),
        PersonContact(id: "2", phoneNumber: "987-654-3210"),
        PersonContact(id: "3", phoneNumber: "555-123-4567")
    ]
    
    private var mockPhoneBookSource: PhoneBookSource {
        PhoneBookSource(personDetails: mockDetails, personContacts: mockContacts)
    }
    
    // MARK: - Initial State Tests
    
    @Test func initialState() async throws {
        _ = await TestStore(initialState: PhoneBookFeature.State()) {
            PhoneBookFeature()
        }
        
        // Initial state is verified by the TestStore initialization
        // No actions needed for this test - we're just verifying the initial state structure
    }
    
    // MARK: - View Did Load Tests
    
    @Test func viewDidLoad_LoadsInitialData() async throws {
        let store = await TestStore(initialState: PhoneBookFeature.State()) {
            PhoneBookFeature()
        } withDependencies: {
            $0.phoneBookSource = mockPhoneBookSource
        }
        
        await store.send(.viewDidLoad)
        
        // viewDidLoad automatically sends .loadInitialData
        await store.receive(\.loadInitialData)
        
        let expectedRecords = [
            PhoneBookRecord(id: "1", detail: mockDetails[0], contact: mockContacts[0]),
            PhoneBookRecord(id: "2", detail: mockDetails[1], contact: mockContacts[1]),
            PhoneBookRecord(id: "3", detail: mockDetails[2], contact: mockContacts[2])
        ]
        
        await store.receive(\.recordsUpdated) {
            $0.records = expectedRecords
            $0.filteredRecords = expectedRecords
        }
    }
    
    // MARK: - Search Tests
    
    @Test func searchTextChanged_FiltersRecords() async throws {
        let initialRecords = [
            PhoneBookRecord(id: "1", detail: mockDetails[0], contact: mockContacts[0]),
            PhoneBookRecord(id: "2", detail: mockDetails[1], contact: mockContacts[1]),
            PhoneBookRecord(id: "3", detail: mockDetails[2], contact: mockContacts[2])
        ]
        
        let store = await TestStore(
            initialState: PhoneBookFeature.State(
                records: initialRecords,
                filteredRecords: initialRecords
            )
        ) {
            PhoneBookFeature()
        }
        
        // Search for "Alice"
        await store.send(.searchTextChanged("Alice")) {
            $0.searchText = "Alice"
            $0.filteredRecords = [initialRecords[0]] // Only Alice should match
        }
        
        // Search for phone number
        await store.send(.searchTextChanged("987")) {
            $0.searchText = "987"
            $0.filteredRecords = [initialRecords[1]] // Only Bob's number matches
        }
        
        // Clear search
        await store.send(.searchTextChanged("")) {
            $0.searchText = nil
            $0.filteredRecords = initialRecords // All records should be shown
        }
    }
    
    @Test func searchTextChanged_CaseInsensitive() async throws {
        let initialRecords = [
            PhoneBookRecord(id: "1", detail: mockDetails[0], contact: mockContacts[0])
        ]
        
        let store = await TestStore(
            initialState: PhoneBookFeature.State(
                records: initialRecords,
                filteredRecords: initialRecords
            )
        ) {
            PhoneBookFeature()
        }
        
        // Search with different case
        await store.send(.searchTextChanged("alice")) {
            $0.searchText = "alice"
            $0.filteredRecords = [initialRecords[0]]
        }
        
        await store.send(.searchTextChanged("ALICE")) {
            $0.searchText = "ALICE"
            $0.filteredRecords = [initialRecords[0]]
        }
    }
    
    // MARK: - Add Record Tests
    
    @Test func addRecord_AddsToStateAndSource() async throws {
        let store = await TestStore(initialState: PhoneBookFeature.State()) {
            PhoneBookFeature()
        } withDependencies: {
            $0.phoneBookSource = mockPhoneBookSource
        }
        
        let newRecord = NewPhoneBookRecord(
            id: "4",
            name: "Diana Prince",
            phoneNumber: "111-222-3333"
        )
        
        await store.send(.addRecord(newRecord))
        
        let expectedRecord = PhoneBookRecord(
            id: "4",
            detail: PersonDetail(id: "4", name: "Diana Prince"),
            contact: PersonContact(id: "4", phoneNumber: "111-222-3333")
        )
        
        await store.receive(\.recordAdded) {
            $0.records = [expectedRecord]
            $0.filteredRecords = [expectedRecord]
        }
    }
    
    @Test func addRecord_WithExistingSearch_FiltersCorrectly() async throws {
        let existingRecord = PhoneBookRecord(
            id: "1", 
            detail: mockDetails[0], 
            contact: mockContacts[0]
        )
        
        let store = await TestStore(
            initialState: PhoneBookFeature.State(
                records: [existingRecord],
                filteredRecords: [existingRecord],
                searchText: "Diana"
            )
        ) {
            PhoneBookFeature()
        } withDependencies: {
            $0.phoneBookSource = mockPhoneBookSource
        }
        
        let newRecord = NewPhoneBookRecord(
            id: "4",
            name: "Diana Prince",
            phoneNumber: "111-222-3333"
        )
        
        await store.send(.addRecord(newRecord))
        
        let expectedNewRecord = PhoneBookRecord(
            id: "4",
            detail: PersonDetail(id: "4", name: "Diana Prince"),
            contact: PersonContact(id: "4", phoneNumber: "111-222-3333")
        )
        
        await store.receive(\.recordAdded) {
            $0.records = [existingRecord, expectedNewRecord]
            $0.filteredRecords = [expectedNewRecord] // Only Diana matches search
        }
    }
    
    // MARK: - Randomization Tests
    
    @Test func randomizationCompleted_ClearsRandomizingState() async throws {
        let store = await TestStore(
            initialState: PhoneBookFeature.State(isRandomizing: true)
        ) {
            PhoneBookFeature()
        }
        
        await store.send(.randomizationCompleted) {
            $0.isRandomizing = false
        }
    }
    
    // MARK: - Records Updated Tests
    
    @Test func recordsUpdated_UpdatesStateAndFiltering() async throws {
        let store = await TestStore(
            initialState: PhoneBookFeature.State(searchText: "Alice")
        ) {
            PhoneBookFeature()
        }
        
        let newRecords = [
            PhoneBookRecord(id: "1", detail: mockDetails[0], contact: mockContacts[0]),
            PhoneBookRecord(id: "2", detail: mockDetails[1], contact: mockContacts[1])
        ]
        
        await store.send(.recordsUpdated(newRecords)) {
            $0.records = newRecords
            $0.filteredRecords = [newRecords[0]] // Only Alice matches the existing search
        }
    }
    
    @Test func recordsUpdated_WithoutSearch_ShowsAllRecords() async throws {
        let store = await TestStore(initialState: PhoneBookFeature.State()) {
            PhoneBookFeature()
        }
        
        let newRecords = [
            PhoneBookRecord(id: "1", detail: mockDetails[0], contact: mockContacts[0]),
            PhoneBookRecord(id: "2", detail: mockDetails[1], contact: mockContacts[1])
        ]
        
        await store.send(.recordsUpdated(newRecords)) {
            $0.records = newRecords
            $0.filteredRecords = newRecords
        }
    }
    
    // MARK: - Integration Tests
    
    @Test func fullWorkflow_LoadDataSearchAndAdd() async throws {
        let store = await TestStore(initialState: PhoneBookFeature.State()) {
            PhoneBookFeature()
        } withDependencies: {
            $0.phoneBookSource = mockPhoneBookSource
        }
        
        // 1. Load initial data
        await store.send(.viewDidLoad)
        
        // viewDidLoad automatically sends .loadInitialData
        await store.receive(\.loadInitialData)
        
        let expectedInitialRecords = [
            PhoneBookRecord(id: "1", detail: mockDetails[0], contact: mockContacts[0]),
            PhoneBookRecord(id: "2", detail: mockDetails[1], contact: mockContacts[1]),
            PhoneBookRecord(id: "3", detail: mockDetails[2], contact: mockContacts[2])
        ]
        
        await store.receive(\.recordsUpdated) {
            $0.records = expectedInitialRecords
            $0.filteredRecords = expectedInitialRecords
        }
        
        // 2. Search for specific record
        await store.send(.searchTextChanged("Bob")) {
            $0.searchText = "Bob"
            $0.filteredRecords = [expectedInitialRecords[1]]
        }
        
        // 3. Add new record while search is active
        let newRecord = NewPhoneBookRecord(
            id: "4",
            name: "Bob Wilson",
            phoneNumber: "999-888-7777"
        )
        
        await store.send(.addRecord(newRecord))
        
        let expectedNewRecord = PhoneBookRecord(
            id: "4",
            detail: PersonDetail(id: "4", name: "Bob Wilson"),
            contact: PersonContact(id: "4", phoneNumber: "999-888-7777")
        )
        
        await store.receive(\.recordAdded) {
            $0.records = expectedInitialRecords + [expectedNewRecord]
            // Both Bob records should match the search
            $0.filteredRecords = [expectedInitialRecords[1], expectedNewRecord]
        }
    }

}
