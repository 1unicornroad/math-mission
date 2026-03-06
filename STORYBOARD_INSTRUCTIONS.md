# Storyboard Setup Instructions

To enable the menu system:

## Option 1: Manual Storyboard Update (Recommended)
1. Open `Main.storyboard` in Xcode
2. Add a new View Controller to the storyboard
3. Set its Custom Class to `MenuViewController`
4. Set its Storyboard ID to `MenuViewController`
5. Make it the Initial View Controller (check the "Is Initial View Controller" box)
6. Set the GameViewController's Storyboard ID to `GameViewController`

## Option 2: Programmatic Launch (Temporary)
The AppDelegate has been updated to launch MenuViewController programmatically.
This will work without storyboard changes.

## Adding a Back Button
In the GameViewController, tap the top-left corner to return to menu (already implemented).
