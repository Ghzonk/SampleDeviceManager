# README #

* About 'Sample Device Manager'
* Dependencies
* How to run
* Implementation details


## About Sample Device Manager ##

* This is a sample project to simulate bi-direction data synchronization.
* It uses RESTful API (JSON) along with Core Data.
* It is designed with MVVM architecture.

## Dependencies ##

In this project, I used 2 popular open source projects.

* Alamofire - It is used to handle network communication with server.
* SwiftyJSON - It is used to parse JSON file.

## How to run ##

Dependencies are managed using CocoaPods.
However, all of the necessary files should be in this repository, and should be straight forward to compile and run.

* Run **pod install** if necessary
* Open **SampleDeviceManager.xcworkspace** file in Xcode, compile & run.

## Implementation details ##

The following list is a quick summary of implementation details.

#### Basic Functionalities ####

* Fetch data from Server and display in the Tree View Controller.
* Item can be deleted from Table View after the confirmation.
* Detail View with Check-In and Check-Out implemented. Detail View and Tree View get updated immediately.
* Add New Device implementation - Because Server always returns with same response, user data is saved along with random ID. This enabled me to implement full offline synchronization.
* print statements in the source codes are intensionally added to show internal processes in the console output.

#### MVVM architecture is used for the App. ####

* Model consists of Server (JSON), Local storage (Managed Object) and Memory (Array) data.
* View Model handles fetch, add, modify and delete operations.
* View (ViewController) handles user interactions.

#### CoreData is used for local storage synchronization ####

* Initial data loading from server.
* Subsequent operation synchronization.
* Offline use, and synchronization when reconnected to network.
* All functionalities have offline synchronization mechanism implemented.

#### Online & Offline Synchronizations ####

* When App loads Main Table View, it synchronizes data from Server.
* Because Server does not change, App always has at least 5 data (Synchronize from Server to local storage).
* Online activities save changes to local storage at all times for Offline use.
* When network goes offline, App uses local data and saves operations for each item.
* When network comes back online, App synchronizes Offline data back to Server if any.
* Even if Server does not save the data, App will display all the data properly - as if Server works properly.
* **To test offline**, uncomment first line (return false) of **isConnectedToNetwork** method in **Reachability** class. This will simulate the offline mode.
* When online, background color of Main Table View is Green. When offline it will be Gray.
