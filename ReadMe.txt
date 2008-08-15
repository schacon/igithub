
WiTap

================================================================================
DESCRIPTION:

The WiTap sample application demonstrates how to achieve network communication between applications. Using Bonjour, the application both advertises itself on the local network and displays a list of other instances of this application on the network.

Simply build the sample using Xcode and run it in the simulator or on the device. Wait for another player to connect or select a game to connect to. Once connected, tap one or more colored pads on a device to see them highlighted simultaneously on the remote device.

===========================================================================
BUILD REQUIREMENTS:

Mac OS X 10.5.3, Xcode 3.1, iPhone OS 2.0

===========================================================================
RUNTIME REQUIREMENTS:

Mac OS X 10.5.3, iPhone OS 2.0

===========================================================================
PACKAGING LIST:

AppController.h
AppController.m
UIApplication's delegate class, the central controller of the application.

TapView.h
TapView.m
UIView subclass that can highlight itself when locally or remotely tapped.

Picker.h
Picker.m
A view that displays both the currently advertised game name and a list of other games
available on the local network (discovered & displayed by BrowserViewController).

Networking/TCPServer.h
Networking/TCPServer.m
A TCP server that listens on an arbitrary port.

Networking/BrowserViewController.h
Networking/BrowserViewController.m
View controller for the service instance list.
This object manages a NSNetServiceBrowser configured to look for Bonjour services.
It has an array of NSNetService objects that are displayed in a table view.
When the service browser reports that it has discovered a service, the corresponding NSNetService is added to the array.
When a service goes away, the corresponding NSNetService is removed from the array.
Selecting an item in the table view asynchronously resolves the corresponding net service.
When that resolution completes, the delegate is called with the corresponding net service.

main.m
The main file for the WiTap application.

===========================================================================
CHANGES FROM PREVIOUS VERSIONS:

Version 1.5
- Updated for and tested with iPhone OS 2.0. First public release.

Version 1.4
- Updated for Beta 7.
- Code clean up.
- Improved Bonjour support.

Version 1.3
- Updated for Beta 4. 
- Added code signing.

Version 1.2
- Added icon.

Copyright ©2008 Apple Inc. All rights reserved.