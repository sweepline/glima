# Notes

Every unit should have an id, represented by the RPC ID given by the server
We should then be able to have a map and fetch nodes for the units for distance
tracking and spell casting.

All actual gameplay should run on the server, but we of course still need to animate
client side, which means keeping track of positions and such. Out of range and such
might as well be client side too so that non-cheating clients dont send unnecesary
requests.
