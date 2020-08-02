# Poker

A multiplayer Texas Hold'em Poker game built with Phoenix LiveView.

Years ago I attempted to build a [poker game in Phoenix](https://github.com/begleynk/elixir-poker-server/),
but like many side projects it fell by the wayside. This is a re-imagining of that project, but
with LiveView.

## Status

Still a work in progress.

## TODO

* [x] Proof of concept game UI
  * [x] PubSub broadcast of game state changes
  * [ ] Hook up Phoenix presence to detect user disconnects
* [x] Fully implement games flowing from game to game
* [ ] UI Improvements
  * [ ] Show active bets on table
  * [ ] Move to SVG/CSS/Image cards, because some browsers/fonts don't support Unicode cards
  * [ ] Show the winning hand/winner more prominently
* [ ] Reload game state from database on crash/server restart
  * [x] Persist tables
  * [ ] Persist games
  * [ ] Persist game actions
* [ ] Action Timers - timeout inactive users
* [ ] All-In handling
* [ ] Split pots
* [ ] Bug: Properly handle players joining while a game is running

## Future features

* [ ] CSS animations for cards
* [ ] Private/Public tables
* [ ] Custom blinds
* [ ] More than 6 player tables
