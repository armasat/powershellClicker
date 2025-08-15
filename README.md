# PowerShell Auto Clicker Scripts

This repository contains a set of PowerShell scripts designed to automate mouse clicks on specific coordinates. The scripts allow you to create configurations of clicks, execute them repeatedly, and adjust or view click positions.  

---

## Scripts Overview

### 1. `configCreator.ps1`
Used to **create JSON configuration files** that store click coordinates and actions. This is the first script you run when setting up a new automated action.  

- The output is a JSON file that defines where clicks should occur and in what order.  
- Once created, a configuration file can be reused multiple times with `configRunner.ps1`.  

### 2. `configRunner.ps1`
Used to **execute clicks based on a JSON configuration file**.  

- **Arguments:**
  - `-ConfigFile <path>`: Specifies the JSON file to use for clicks.
  - `-Loops <number>`: Determines how many times the sequence of clicks should run.  

- **Example usage:**
```powershell
# Run clicks from a single config file 5 times
.\configRunner.ps1 -ConfigFile "MyClicks.json" -Loops 5

# Run two different click configurations sequentially
.\configRunner.ps1 -ConfigFile "FirstAction.json" -Loops 3
.\configRunner.ps1 -ConfigFile "SecondAction.json" -Loops 2
```
You can string together multiple configurations by calling configRunner.ps1 multiple times in a script or command line sequence.

### 3. drawDraggableBoxes.ps1

Used to view and adjust click positions in a configuration file.

Loads the JSON file and displays all clicks as draggable boxes on the screen.

After adjusting, you can update the click coordinates in the JSON file.

This ensures accuracy and allows fine-tuning of click positions without manually editing the file.

Example usage:
```powershell
.\drawDraggableBoxes.ps1 -ConfigFile "MyClicks.json"
```

After positioning the boxes, closing the window will save any changes automatically.
---
### Workflow Example

Create a configuration
```powershell
.\configCreator.ps1
# Follow prompts to define click coordinates
```

Adjust or verify positions (optional)
```powershell
.\drawDraggableBoxes.ps1 -ConfigFile "MyClicks.json"
```

Run the clicks
```powershell
.\configRunner.ps1 -ConfigFile "MyClicks.json" -Loops 5
```

Chain multiple configurations
```powershell
.\configRunner.ps1 -ConfigFile "FirstAction.json" -Loops 2
.\configRunner.ps1 -ConfigFile "SecondAction.json" -Loops 3
```
### Notes

You only need to create a configuration file once for each unique action.

Config files can be reused, combined, or executed in sequence for more complex workflows.

Always verify click positions with drawDraggableBoxes.ps1 to prevent unintended actions.
