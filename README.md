## ClickSync

ClickSync is an app built in SwiftUI designed to help musicians in small venues or with low budgets have the chance to play together with a syncronised click track.

This project makes use of AudioKit and MultipeerConnectivity

Currently still a work in progress, but thought I'd now track milestones!


<img width="406" height="739" alt="image" src="https://github.com/user-attachments/assets/d4d76c19-e816-4731-bdfc-d78f38f00ebc" />


#### MILESTONES

###### 17/12/2025
Added reactive beat symbols which flash on each click, working well with the current accented beat

###### 18/12/2025
Began to look into MultipeerConnectivity. Managed to get communication between devices and basic commands sent from master to slave devices (only start/stop). Next will be to sync the start/stop cmd between devices, and then add more cross device interaction such as tempo. 

###### 05/01/2026 
Added a new settings window for the network things instead of a new page. Seemed a lot cleaner and nicer, making it feel like its still part of the app.

###### 10/01/2026
Managed to sync up the metronomes! AppleSequencer from audiokit had differing startUp Times, so even though "start" command triggered at a commoon time, devices did not start together! Attmped to use `preroll()` but that didn't make much difference so implemented custom sequencer logic, with a frame size and by generating clicks in a chunk of upcoming time. Worked much better, although sometimes will not be synced.

###### 14/01/2026
Networked BPM control added, with new "Tempo Queue" options, which allows users to queue a tempo change at the end of a bar, with 4 customisable buttons available for users to be able to put the bpm that they want. This then allows for synchronised tempo changes for devices across the network! 


#### Cloning issues

Sometimes cloning this into a new XCode has some problems. 

Ensure to do:

- Project Settings -> Signing & Capabilities

- Add new Capability -> Background Modes

- Check "Audio, AirPlay, and Picture in Picture"


If peer to peer network connection isn't working:

You need to add privacy descriptions. In your "Info.plist', add:

- Privacy - Local Network Usage Description: "We need access to find nearby devices"
- Bonjour services: _word-share._tcp, _word-share._udp
