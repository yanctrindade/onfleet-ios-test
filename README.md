# internal-mobile-ios-challenge
This is a simple phonebook app that needs to be refactored as a take home challenge for evaluating iOS engineers for the Mobile team.

# Description
This is a simple phone book app written in UIKit that combines two data sources with Combine. It also has random generation of new data.

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
- Please email kjell@onfleet.com and CC michal@onfleet.com and mhorvatovic@onfleet.com 
- You can send a zipped repo, or a link to a created repo that we can access.
- We'd like to see your commit history .

# Notes

- We don't expect you to spend more than a couple of hours on this, don't overthink it.
- You are allowed to use AI, but please tell us which one you used and how you used it.
- 

