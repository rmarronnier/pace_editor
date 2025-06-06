# PACE Examples

This directory contains example projects, templates, and code samples to help you learn PACE and get started with your own adventure games.

## Example Projects

Complete adventure games demonstrating various PACE features:

### [Mysterious Library](projects/mysterious_library/)
**Difficulty:** Beginner  
**Features:** Basic scenes, hotspots, simple inventory  
**Story:** Find a hidden key to unlock a secret passage

A complete walkthrough of this project is available in the [Beginner Tutorial](../tutorials/beginner-tutorial.md).

### [Detective's Case](projects/detective_case/)
**Difficulty:** Advanced  
**Features:** Multi-character dialogs, complex inventory, branching story  
**Story:** Solve a museum theft through investigation and deduction

This project demonstrates advanced features covered in the [Advanced Tutorial](../tutorials/advanced-tutorial.md).

### [Space Station Mystery](projects/space_station/)
**Difficulty:** Intermediate  
**Features:** Sci-fi setting, puzzle mechanics, multiple endings  
**Story:** Investigate strange occurrences aboard a research station

### [Medieval Quest](projects/medieval_quest/)
**Difficulty:** Intermediate  
**Features:** Fantasy setting, character progression, combat system  
**Story:** Rescue a kidnapped princess from an evil sorcerer

## Templates

Starting points for common game types:

### [Blank Project](templates/blank/)
- Empty project with basic structure
- Single scene with character
- Minimal hotspots for testing

### [Room Escape](templates/room_escape/)
- Classic escape room setup
- Inventory system configured
- Puzzle framework included

### [Point & Click Adventure](templates/classic_adventure/)
- Traditional adventure game structure
- Multiple scenes with transitions
- Character dialog system

### [Mystery/Detective](templates/detective/)
- Investigation-focused template
- Evidence collection system
- Character interview framework

### [Visual Novel](templates/visual_novel/)
- Story-focused template
- Advanced dialog system
- Character portrait management

## Code Samples

Standalone code examples for specific features:

### [Dialog System Examples](code_samples/dialogs/)
- Simple conversations
- Branching dialog trees
- Conditional responses
- Character emotions

### [Inventory System Examples](code_samples/inventory/)
- Item collection
- Item combination
- Inventory UI
- Usage restrictions

### [Scene Management Examples](code_samples/scenes/)
- Scene transitions
- Camera controls
- Object layering
- Dynamic loading

### [Character Animation Examples](code_samples/animations/)
- Walking cycles
- Idle animations
- Expression changes
- Sprite sheet handling

### [Hotspot Examples](code_samples/hotspots/)
- Different interaction types
- Conditional hotspots
- Complex behaviors
- Debug visualization

### [Scripting Examples](code_samples/scripting/)
- Lua integration
- Custom functions
- Event handling
- Save/load systems

## Assets

Free assets for learning and prototyping:

### [Sprites](assets/sprites/)
- Character sprites with animations
- Object and item graphics
- UI elements and icons

### [Backgrounds](assets/backgrounds/)
- Indoor and outdoor scenes
- Different art styles
- Various resolutions

### [Audio](assets/audio/)
- Sound effects
- Background music
- Voice samples

### [Fonts](assets/fonts/)
- Game-appropriate fonts
- Different styles and sizes
- License information

## Quick Start Projects

### 5-Minute Game
Create a simple game in 5 minutes:

1. Open PACE
2. Create new project from "Blank Project" template
3. Import sample background from assets
4. Add a character sprite
5. Create one hotspot with a message
6. Test and export

### 30-Minute Adventure
Build a basic adventure in 30 minutes:

1. Use "Room Escape" template
2. Add 3-4 interactive objects
3. Create a simple puzzle chain
4. Add victory condition
5. Test complete playthrough

### 2-Hour Story
Develop a short story game:

1. Use "Visual Novel" template
2. Create 3 characters with portraits
3. Write branching dialog for key decisions
4. Add background music
5. Create multiple endings

## Using the Examples

### Running Example Projects

1. **Download or Clone**
   ```bash
   git clone https://github.com/pace-editor/examples.git
   cd examples
   ```

2. **Open in PACE**
   - Launch PACE
   - File → Open Project
   - Navigate to desired example
   - Select the `.pace` file

3. **Explore and Modify**
   - Examine the project structure
   - Try different editor modes
   - Modify objects and settings
   - Test your changes

### Using Templates

1. **Create New Project**
   - File → New Project
   - Choose "From Template"
   - Select desired template
   - Customize project name and location

2. **Customize Template**
   - Replace placeholder assets with your own
   - Modify scenes and layouts
   - Adjust game settings
   - Add your content

### Importing Code Samples

1. **Copy Sample Code**
   - Browse code samples directory
   - Copy relevant script files
   - Study the implementation

2. **Integrate into Project**
   - Add scripts to your project's scripts folder
   - Reference in appropriate scenes or objects
   - Modify for your specific needs

## Learning Path

### Beginner
1. Start with "Mysterious Library" example
2. Follow the Beginner Tutorial
3. Experiment with "Blank Project" template
4. Try modifying simple code samples

### Intermediate
1. Explore "Space Station Mystery" example
2. Use "Room Escape" template for your own game
3. Study inventory and scene management samples
4. Create a complete short game

### Advanced
1. Analyze "Detective's Case" example
2. Follow the Advanced Tutorial
3. Experiment with scripting samples
4. Build a complex multi-scene adventure

## Contributing Examples

We welcome contributions to the examples collection!

### What to Contribute
- Complete example projects
- Useful templates
- Educational code samples
- Creative assets (with proper licensing)

### Submission Guidelines
1. **Quality Standards**
   - Code should be well-commented
   - Projects should be complete and playable
   - Include clear documentation

2. **File Organization**
   - Follow existing directory structure
   - Include README for each example
   - Provide asset credits and licensing

3. **Submission Process**
   - Fork the examples repository
   - Add your contribution
   - Submit a pull request with description

### Example Submission Template
```
examples/projects/your_example/
├── README.md                 # Description and instructions
├── your_example.pace         # PACE project file
├── assets/                   # All game assets
├── scenes/                   # Scene files
├── scripts/                  # Custom scripts
└── screenshots/              # Preview images
```

## Troubleshooting Examples

### Common Issues

**"Project won't open"**
- Ensure you have the latest PACE version
- Check that all asset files are present
- Verify Crystal dependencies are installed

**"Missing assets"**
- Download the complete example package
- Check asset paths in project file
- Ensure assets are in correct directories

**"Scripts not working"**
- Verify Lua scripting is enabled
- Check script syntax and references
- Review error console for details

**"Performance issues"**
- Reduce image sizes if needed
- Close unnecessary applications
- Check system requirements

### Getting Help

- Check the [Troubleshooting Guide](../guides/troubleshooting.md)
- Visit our [Community Forum](https://forum.pace-editor.com)
- Ask questions in our [Discord Server](https://discord.gg/pace-editor)

## License

### Example Projects
Most example projects are released under MIT License for educational use.

### Assets
Asset licensing varies by contributor. Check individual asset files for specific licenses.

### Code Samples
All code samples are released under MIT License unless otherwise specified.

## Acknowledgments

Thanks to all contributors who have shared their examples and templates with the PACE community!