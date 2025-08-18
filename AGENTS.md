//
//  AGENTS.md
//  InteractiveClassroom
//
//  Created by zhb on 2025/8/17.
//

# [FIRST RULE] !!! ALLWAYS KEEP IN MIND THAT DO NOT STUFF EVERYTHING IN ONE FILE, SPLIT FUNCTIONS AS MUCH AS POSSIBLE, ESPECIALLY WHEN NEW THINGS ARE ADDED. ALWAYS FOLLOW MVVM's PRINCIPLE!!!
# [SECOND RULE] WHEN YOU NEED TO WRITE A NEW FUNCTION, CONSIDER WRITE IT AS A API FIRST

## CODING PRINCIPLE [IMPORTANT]
    1.    Separation of concerns: Business logic (Model), presentation logic (ViewModel), and UI rendering (View) are strictly separated.
    2.    Data binding / Observability: The View automatically reacts to changes in the ViewModel’s state, ensuring a responsive UI.
    3.    Testability: ViewModels and Models can be tested independently without requiring the UI.
    4.    Reusability and Maintainability: Views can be replaced or redesigned with minimal impact on Models and ViewModels.


## ABOUT THE PROJECT

This is a project with multiple characters, including server and clients. Clients side always run on iOS and iPadOS while server always run on macOS. Distinct which side you are coding when you receive an instruction.

## KEEP IN MIND THAT NO CONNECTION BETWEEN CLIENTS ARE ALLOWED. ALL COMMANDS AND TRAFFICS SHOULD BE DEALED ON THE SERVER SIDE.

## ABOUT INTERACTION

"Interaction" is a core concept in this project. The following shows the definition and rules for it.
    1. Interaction can be launched and stoped by teacher client only.
    2. An interaction has a lifecycle with limited time set by teacher client or unlimited lifetime if set by teacher client. An interaction can be stopped by teacher before its lifecycle ends. It's lifecycle begin to count when it start
    3. An interaction must have a correspond overlay content.
    4. Interaction has many types, including problems, timer, even the class begins sign, which are all aimed to demonstrate in front of students.
    5. Interaction has different lookings, including blur background and clean background. Different types of interactions need different lookings.
    
## ABOUT OVERLAY

Overlay is another core concept in this project. Like interaction, they are all showed on server side.
    1. Overlay is the container for interactions, all interactions are laid on the one and only one overlay.
    2. Overlay is being shown as soon as the classroom is opened, until the class is over(End class).
    3. The tool bar buttons on the overlay is going to shown forever when the class is going.
    4. The content on the overlay should be cleaned when the class is over(End Class)
    
