The reason I deleted the old repo before was because it had my roleplay extension for my server, me and Verb have spent a lot of time working on it and I made that just for my server. If I had that in here, the total command count would be 71.

The server for that is called: "Clutch Roleplay". It has some sexy features :)

> Note: I will update all these commands later on
# Moderation Commands | Moderation

    - [Owner] kill (shutsdown server)
    - [Owner] restart (restarts server)
    - [Owner] add_key_all <key> <default_value> (adds a new key to all users in 'players.json')
    - [Owner] say <msg> (console only)

    - [Admin] set_rank <user_name or secret> <int_rank>
    - [Admin] whitelist <name> <optional_secret> (will be opposite of current value)
    - [Admin] lock (kicks all players that aren't moderators and then disabled people joining)

    - [Moderator] kick <user> <reason>
    - [Moderator] ban <user> (time)
    - [Moderator] unban <user>
    - [Moderator] mute <user> (time)
    - [Moderation] unmute <user>
    - [Moderator] freeze <user>
    - [Moderator] unfreeze <user>
    - [Moderator] warn <user> (reason)

    - [VIP] ban <user> (time : max 2h)

    - [Trusted] voteban <user> (time : max 20m)

    - [User] votemute <user> (time : max 15m)

# Utility Commands | Moderation
    - [Owner] advertise <message>

    - [Admin] time_play
    - [Admin] time_stop
    - [Admin] set_time <hour>:(min):(second)
    - [Admin] set_fog (level)
    - [Admin] set_wind (user) <x> (y) (z)

    - [Trusted] tp <user> (user2)

    - [User] help (command) (/help kick)
    - [User] report <user> <reason>
    - [User] uptime
    - [User] playtime
    - [User] home
    - [User] mods
    - [User] discord
    - [User] pm <user>
    - [User] block <user>
    - [User] unblock <user>
    - [User] getblocks
    - [User] votekick <user>
    - [User] donate

# Fun Commands | Moderation
    - [Admin] imitate <user> <message>
    - [Admin] set_gravity (specific user) <value>
    - [Admin] destroy <user>

# New commands that need sorting
    get_ids
    send_message (displays ui message in a huge ass font)
    advertise <msg>
    

## Role System

- Ranks go off of integers
- You cannot perform certain moderation commands on someone who has a higher rank than you
- You cannot set your own rank (in-game)
- The console can change anyones rank

| Rank: 0 | Rank: 1 | Rank: 2 | Rank: 3   | Rank: 4 | Rank: 5 | Rank: 6 |
|:-------:|:-------:|:-------:|:---------:|:-------:|:-------:|:-------:|
|  User   | Trusted |   VIP   | Moderator |  Admin  |  Owner  | Console |