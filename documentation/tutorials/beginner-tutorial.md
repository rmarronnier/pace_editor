# Beginner Tutorial: Creating "The Mysterious Library"

In this comprehensive tutorial, you'll create a complete point-and-click adventure game called "The Mysterious Library". You'll learn all the essential features of PACE while building a real game from start to finish.

## What You'll Build

A short adventure game where the player:
1. Explores an old library
2. Finds a mysterious book
3. Solves a simple puzzle
4. Discovers a secret passage

**Estimated Time:** 2-3 hours  
**Difficulty:** Beginner  
**Prerequisites:** PACE installed and [Getting Started Guide](../guides/getting-started.md) completed

## Tutorial Assets

Before starting, download the tutorial assets:
- [Library Background](../examples/assets/library_background.png)
- [Character Sprites](../examples/assets/character_spritesheet.png)
- [Book Object](../examples/assets/old_book.png)
- [Key Object](../examples/assets/golden_key.png)
- [Door Object](../examples/assets/secret_door.png)

Or create your own simple images using any graphics software.

## Part 1: Project Setup

### Step 1: Create the Project

1. Launch PACE
2. Select **File → New Project**
3. Fill in project details:
   - **Name**: "The Mysterious Library"
   - **Location**: Choose your projects folder
   - **Resolution**: 1024x768
   - **Author**: Your name
4. Click **Create Project**

### Step 2: Understand the Project Structure

PACE creates this structure:
```
the_mysterious_library/
├── assets/
│   ├── backgrounds/
│   ├── characters/
│   ├── sounds/
│   ├── music/
│   └── ui/
├── scenes/
│   └── main_scene.yml
├── scripts/
├── dialogs/
├── exports/
└── the_mysterious_library.pace
```

### Step 3: Import Assets

1. Switch to **Assets Mode** (click the Assets tab)
2. Click **Import Asset**
3. Import each asset to the appropriate category:
   - `library_background.png` → **backgrounds**
   - `character_spritesheet.png` → **characters**
   - `old_book.png`, `golden_key.png`, `secret_door.png` → **objects** (create this subfolder)

## Part 2: Creating the Main Scene

### Step 1: Set Up the Background

1. Switch to **Scene Mode**
2. In the Scene Hierarchy, select "main_scene"
3. In the Property Panel:
   - **Scene Name**: "Library Main Hall"
   - **Background**: Click Browse and select `library_background.png`
4. Your scene now has a library background!

### Step 2: Add Objects to the Scene

1. Make sure you're in **Scene Mode**
2. Select the **Place Tool** (P key)
3. From the Asset Browser, drag these objects into the scene:
   - Place the `old_book.png` on a bookshelf
   - Place the `golden_key.png` on a desk (make it partially hidden)
   - Place the `secret_door.png` behind a bookshelf (barely visible)

### Step 3: Position Objects Precisely

1. Switch to **Move Tool** (M key)
2. Click and drag objects to fine-tune their positions
3. **Tips:**
   - Hold Shift while dragging for pixel-perfect positioning
   - Use the Property Panel to set exact coordinates
   - Press G to toggle grid for easier alignment

## Part 3: Adding Your Character

### Step 1: Create the Character

1. Switch to **Character Mode**
2. Click **Add Character**
3. Configure the character:
   - **Name**: "Scholar"
   - **Sprite Sheet**: Select `character_spritesheet.png`
   - **Frame Width**: 32 (adjust based on your sprite)
   - **Frame Height**: 48 (adjust based on your sprite)

### Step 2: Set Up Character Animations

1. In Character Mode, select your character
2. Click **Add Animation**:
   - **Name**: "idle"
   - **Frames**: [0] (just the first frame)
   - **Duration**: 1.0 seconds
   - **Loop**: Yes

3. Add walking animation:
   - **Name**: "walk"
   - **Frames**: [1, 2, 3, 2] (walking cycle)
   - **Duration**: 0.8 seconds
   - **Loop**: Yes

### Step 3: Place Character in Scene

1. Return to **Scene Mode**
2. Your character should appear in the scene
3. Use **Move Tool** to position the character at the scene entrance

## Part 4: Creating Interactive Hotspots

### Step 1: Create Book Hotspot

1. Switch to **Hotspot Mode**
2. Select **Place Tool**
3. Click and drag over the book to create a hotspot
4. In the Property Panel, configure:
   - **Name**: "old_book"
   - **Interaction Type**: "Examine"
   - **Description**: "An ancient tome"
   - **Action**: "This book looks very old and mysterious. Maybe I should read it."

### Step 2: Create Key Hotspot

1. Create another hotspot over the key
2. Configure:
   - **Name**: "golden_key"
   - **Interaction Type**: "Take"
   - **Description**: "A golden key"
   - **Action**: "A beautiful golden key. This might unlock something important."

### Step 3: Create Door Hotspot

1. Create a hotspot over the secret door
2. Configure:
   - **Name**: "secret_door"
   - **Interaction Type**: "Use"
   - **Description**: "A hidden door"
   - **Action**: "The door is locked. I need to find a key."
   - **Condition**: "!has_key" (door locked until player has key)

### Step 4: Test Hotspots

1. Press **T** to test mode
2. Click on each hotspot to see your messages
3. Press **Esc** to return to editing

## Part 5: Adding Dialog and Story

### Step 1: Create Character Thoughts

1. Switch to **Dialog Mode**
2. Click **New Dialog Tree**
3. Name it "scholar_thoughts"
4. Create this dialog structure:

```
Root: "I need to find a way out of this library."
├─ Choice: "Examine the books" → "These books are ancient. One catches my eye..."
├─ Choice: "Look for exits" → "There must be another way out somewhere."
└─ Choice: "Search for clues" → "I should look around more carefully."
```

### Step 2: Create Book Reading Dialog

1. Create another dialog tree: "book_reading"
2. Structure:
```
Root: "The book is written in an ancient language."
└─ Auto: "Wait... there's something between the pages!"
    └─ Auto: "It's a riddle about finding the golden key!"
```

### Step 3: Link Dialogs to Hotspots

1. Return to **Hotspot Mode**
2. Select the book hotspot
3. In Property Panel, set **Dialog**: "book_reading"
4. Select the character
5. Set **Default Dialog**: "scholar_thoughts"

## Part 6: Creating Game Logic

### Step 1: Set Up Inventory System

1. Go to **Project Mode**
2. In Game Settings, enable **Inventory System**
3. Add inventory items:
   - **golden_key**: "Golden Key"

### Step 2: Update Key Hotspot Action

1. Return to **Hotspot Mode**
2. Select the key hotspot
3. Change the **Action** to:
```
You found the golden key!
ADD_INVENTORY golden_key
HIDE_OBJECT golden_key
```

### Step 3: Update Door Hotspot Logic

1. Select the door hotspot
2. Update **Action**:
```
IF has_inventory golden_key THEN
  You unlock the secret door!
  CHANGE_SCENE secret_chamber
ELSE
  The door is locked. You need a key.
END
```

## Part 7: Creating a Second Scene

### Step 1: Create New Scene

1. Go to **Scene Mode**
2. Click **File → New Scene**
3. Name it "secret_chamber"
4. Set a different background or reuse the same one

### Step 2: Add Victory Elements

1. Add some objects to make it look like a secret chamber
2. Create a hotspot that shows victory text:
   - **Action**: "Congratulations! You've discovered the secret chamber!"

### Step 3: Test Scene Transition

1. Test your game by:
   - Clicking the book (triggers story)
   - Taking the key
   - Using the key on the door
   - Entering the secret chamber

## Part 8: Polish and Testing

### Step 1: Add Sound Effects (Optional)

1. Switch to **Assets Mode**
2. Import sound files to the **sounds** category
3. In hotspot actions, add:
```
PLAY_SOUND key_pickup.wav
```

### Step 2: Adjust Visual Settings

1. In **Scene Mode**, adjust:
   - Object layer orders (foreground/background)
   - Lighting and atmosphere
   - Character movement speed

### Step 3: Comprehensive Testing

1. Test the complete game flow:
   - Start → Read book → Find key → Open door → Victory
2. Test error cases:
   - Try to open door without key
   - Click on all hotspots
   - Try different dialog choices

### Step 4: Save Your Work

1. Press **Ctrl+S** to save
2. Go to **Project Mode**
3. Click **Export Game** to create a playable version

## Part 9: Extending Your Game

Now that you have a working game, try these enhancements:

### Easy Additions
- Add more rooms to explore
- Create additional puzzles
- Add background music
- Create character walking animations

### Intermediate Features
- Add multiple characters with conversations
- Create an inventory interface
- Add save/load functionality
- Include puzzle items that combine

### Advanced Features
- Create cutscenes with scripted events
- Add particle effects
- Implement a scoring system
- Create multiple endings

## Complete Game Structure

Your finished game should have:

**Scenes:**
- Library Main Hall (starting scene)
- Secret Chamber (victory scene)

**Characters:**
- Scholar (player character)

**Objects:**
- Old Book (story trigger)
- Golden Key (puzzle item)
- Secret Door (puzzle solution)

**Hotspots:**
- Book examination
- Key pickup
- Door interaction

**Game Flow:**
1. Player starts in library
2. Examines book to learn about key
3. Finds and takes golden key
4. Uses key to unlock secret door
5. Enters secret chamber (victory)

## Troubleshooting

### Common Issues

**"Hotspot not responding"**
- Check that hotspot bounds cover the object
- Verify the hotspot is enabled
- Test in preview mode

**"Character not appearing"**
- Ensure character sprite is imported correctly
- Check character layer order
- Verify character is placed within scene bounds

**"Dialog not triggering"**
- Confirm dialog tree is saved
- Check hotspot dialog assignment
- Verify dialog node connections

**"Scene transition not working"**
- Ensure target scene exists
- Check scene file names match exactly
- Verify transition condition logic

### Getting Help

- Check the [API Reference](../api/) for technical details
- Review the [User Interface Guide](../guides/user-interface.md)
- Look at other [example projects](../examples/)

## Exporting Your Game

Now let's export your game so others can play it!

### Step 1: Prepare for Export

1. Save your project one final time with **Ctrl+S**
2. Select **File → Export Game** from the menu

### Step 2: Review Validation

PACE automatically validates your project:

1. The Export Dialog shows validation results
2. Check for any **errors** (red) - these must be fixed
3. Review any **warnings** (yellow) - optional but recommended
4. Common checks include:
   - All referenced files exist
   - Scene backgrounds are present
   - Asset paths are correct

### Step 3: Configure Export

1. **Export Path**: Choose where to save
   - Browse to select a folder
   - Or add `.zip` for archive format
2. **Format**: Folder or ZIP archive
3. Click **Export**

### Step 4: Test Exported Game

Your exported game includes:
- `game_config.yaml` - Game settings
- `scenes/` - All scene files  
- `assets/` - All game assets
- `main.cr` - Entry point

To run: `crystal run main.cr`

## Next Steps

Congratulations! You've created your first complete adventure game. Here's what to learn next:

1. **[Advanced Tutorial](advanced-tutorial.md)** - More complex scenes and mechanics
2. **[Scripting Tutorial](scripting-tutorial.md)** - Custom Lua scripting
3. **[Publishing Guide](../guides/publishing.md)** - Share your games with others

## Project Files

The complete tutorial project is available at:
- [Download Complete Project](../examples/projects/mysterious_library.zip)
- [View Project Source](../examples/projects/mysterious_library/)

This includes all assets, scenes, and configured hotspots ready to run.