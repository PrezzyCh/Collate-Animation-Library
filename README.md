# Collate Animation Library <V0.1.0>
A simple solution for subdivided animations allowing for ease of call, priorities, blending.
> [!NOTE]
> This script is in beta and is under active development and testing. Please submit any bug reports if you find any bugs, thx!

## Installation
To intall, the library must be in the same folder as your script. 
Then put a require in this form:
```lua
local CollateAnims = require("CollateAnim")
```

## Basics

### Initialization
Before putting down any animations, use the `.priorityCheck()` function in any `events.` function such as `events.render` or `events.tick`:
```lua
events.render()
  ANIMMANAGER.priorityCheck()
  --Stuff here
end
```
If you want to add any animations, use the `:newSet()` function to add the function into the list of AnimationSets. This function accepts
a string in the form `set_name-[extra stuff]-body_part` where `set_name` is the overall name of the group and the body part that each animation maps to. 
> [!Warning]
> This naming convention is VERY IMPORTANT to grouping of the animations and it is case sensitive in order to compare each AnimationSet's assigned body part
>  eg: running_armL is of a lower priority than attack_armL so attack_armL plays and running_armL does not.
> There are tools you may use to identify orphaned animations.

It also accepts a priority that will determine whether the body part within an AnimationSet plays or not; and blendIn blendOut parameters used in GS Animation Blend 
(This library is not strictly needed!).
Each `number` parameter has a default value of `0`.

**Example**
```lua
local animRunning = CollateAnims:newSet("running", 0, 4, 4) 
local animAttack = CollateAnims:newSet("attack", 1, 2, 4)
```

### Usage
To play your new grouped animations, simply use the `:play()`, `:stop()`, and `:setPlaying()` which works in a similar way to Figura's animation function.

**Example**
```lua
  events.render()
    ANIMMANAGER.priorityCheck()
    animRunning:play()
    animAttack:setPlaying(state)
  end
```
And you are all set!

## Documentation

### Debug functions

`CollateAnims:dbgPrintTbl()`  
Debugging function that prints out the state of the overrides of an animation set.  
Each override dictates whether an animation plays or not, where `true` indicates 
an animation will play if called and will not if `false`. This is printed in the 
following pattern:
`name + override`

`CollateAnims.dbgPrintAllSets()`  
Debugging function that prints out all identified animation sets.

`CollateAnims.dbgPrintQueue(type)`  
`type number`  
Debugging function that prints out the animation queues of animations 
that will be checked and played.

`type` defermines the type of queue checked where:
- 0 - main queue
- 1 - playing queue
- 2 - override queue

leaving the parameter un-filled or out of bounds, it defaults to 0

`CollateAnims.dbgPrintOrphaned()`  
Debugging function that prints out any orphaned animations (animations that
are not in an AnimationSet).

### Core Functions

`CollateAnims.priorityCheck()`  
Checks the priority of each active animation and setting each `tbl` to the according
override.  
Where if a priority is greater, then it will set the lower priority animation override to
false. If priority is equal, both animations will play.

`CollateAnims:newSet(name, priority, blendIn, blendOut)`  
`name string`  
`priority number`  
`blendIn number`  
`blendOut number`  
Creates a new animation set with the `name`, `priority`, and `blendIn`/`blendOut` 
for GSAnimBlend blending.  
Default value for `priority` is 0

### Animation Functions

`CollateAnims:setPlaying(state)`  
`state boolean`  
Sets and updates the animation state of the animation set.  
Until updated, the animation will continue to play. This will also reset 
priority overrides.

`CollateAnims:play()`  
Plays and the animation set.  
The animation will play until the end of the animation.

`CollateAnims:stop()`  
Stops the animation set.

`CollateAnims:setPlayingSelect(animStr, state, override)`  
`animStr string`  
`state boolean`  
`override boolean`
Plays a specific animation within an animation set.  
Until updated, the animation will continue to play.
If `override` is true, the animation will play regardless
of priority.

`CollateAnims:playSelect(animStr, override)`  
`animStr string`  
`override boolean`  
Plays a specific animation within an animation set.  
The animation will play until the end of the animation.
If `override` is true, the animation will play regardless
of priority.

### Getters/Setters

`CollateAnims:getName()`  
`return string`  
Gets the animation set name.

`CollateAnims:getPriority()`  
`return number`  
Gets the animation set priority.

`CollateAnims:setPriority(priority)`  
`priority number`  
Sets the animation set priority.

`CollateAnims:isPlaying()`  
`return boolean`  
Checks if any of the animations in the animation set is currently playing.
If any one animation is playing, it will return `true`, and `false` otherwise.  
If this AnimationSet does not contain the animation, it will return `false`

`CollateAnims:find(target)`  
`target string`  
`return Animation`  
Retrieves the animation in the AnimationSet if it contains the same name.  
If this AnimationSet contains the animation, it will return the aniamtion, and `nil` if
otherwise.

`CollateAnims:setSpeed(speed)`  
`speed number`  
Sets the speed of the animation set and all of it's animations.
