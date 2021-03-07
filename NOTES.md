# Notes

## TODO

- Lag compensation for ranges?
- If OOR move to range
- Make everything happen in the past
- Player should be real-time then rubberband
- Only send 2d coordinates
- Send time with
- Single Interpolation time constant

## Movement

We should just ask the server to move our character server side
this also means we no longer should send player states
Just ask to move to location

Spells we ask to cast and the server calls the server side casting function,
if the spell is allowed to be casted we start the cast on the server and tell
players we are casting.

We could also just send out all spell states in the world_state, but again that might
be a bit much, lets see.

Then if a collision happens between a spell and a character, send it out on the network.

We also need to do things at the correct time and not just when it happens. Check every
frame in the spell queue if a spell should be cast, as well as death queue

We need lag compensation and stuff too

### SO

Client

- Player Does move command -> Send move
- Player Casts spell -> Send spell cast

GameServer

- Receive move command -> Simulate physics
- Receive spell command -> Is it allowed in lag compensated state (50ms)
  -> No ? Tell player; Yes ? tell everyone -> Simulate physics

- Every Server tick, send everyones positions and rotations and statuses (are they stone or shield)

  ? Should I send spell casts on ticks or when theyre cast
  ? I guess it means we either let the server send position
  ? Of all spells all the time, or we send the spell cast information
  ? When we know its good and let the client simulate also
  ? We dont have many spells and players, so I think we might just
  ? Send the entire simulation, but thats also kinda stupid
