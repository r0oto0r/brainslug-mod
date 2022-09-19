# BrainSlug Command and Control Mod
Lua mod for injecting custom commands into PZ game server during runtime. Also allows to extrakt most available data from current game state.
This mod abuses the mod file writer classes in order to write and read from fifo pipes. No modifications to the java client required.

This mod is accompanied by a nodejs server which can communicate via inpipe/outpipe as well as providing express and websocket server.
Find it [here](https://github.com/r0oto0r/brainslug-server).

## Additional Setup
Run createPipes.sh or create inpipe and outpipe fifo pipes and change path in nodejs server.

## Current Available Custom Commands

| Command     | Payload                                                                                               | Effect |
|-------------|-------------------------------------------------------------------------------------------------------|--------|
| slap        | [SlapPayload](https://github.com/r0oto0r/brainslug-server/blob/main/src/Interfaces.ts#L207)           | Slaps player with username or all players if missing dealing 5 dmg to head body part. Also plays slap.ogg. |
| comegetsome | [ComeGetSomePayload](https://github.com/r0oto0r/brainslug-server/blob/main/src/Interfaces.ts#L211)    | Lets player with username or all players scream very loud attracting all nearby Zombies. Also plays comegetsome.ogg. | 
| horde       | [HordePayload](https://github.com/r0oto0r/brainslug-server/blob/main/src/Interfaces.ts#L215)          | Spawns random horde of zombies nearby player with username or all players. |
| message   | [MessagePayload](https://github.com/r0oto0r/brainslug-server/blob/main/src/Interfaces.ts#L219)        | Sends message to console of player with username or all players. |
| gift   | [GiftPayload](https://github.com/r0oto0r/brainslug-server/blob/main/src/Interfaces.ts#L224)           | Adds items to inventory of player with username or all players. |
| storm   | -                                                                                                     | Forces ClimateManager to enter storm stages. |
| sunny   | -                                                                                                     | Clears all changes so climate manager and forces it to switch the clearing stage. |
| climate   | [PZClimate](https://github.com/r0oto0r/brainslug-server/blob/main/src/Interfaces.ts#L176)             | Manupilate all climate variables. Will get activated in next weather cycle, so can take some ticks to get actualized. |
| zombieJumpScare   | [ZombieJumpScarePayload](https://github.com/r0oto0r/brainslug-server/blob/main/src/Interfaces.ts#229) | Spawns a random zombie with random outfit, gender and walking type nearby player with username or all players. Zombie will also target user and most likley attack right away |
| info    | -                                                                                                     | Triggers PZ server to fan out info |

You can find example requests [here](https://github.com/r0oto0r/brainslug-server#example-command-requests)

## RCON Support
You should also enable RCON in game server config when used with the nodejs server. It will also expose all rcon commands then.

You can find example requests [here](https://github.com/r0oto0r/brainslug-server#example-rcon-requests)
