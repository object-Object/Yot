# Yot
Yot is a general-purpose Discord bot written in Lua with an emphasis on moderation. It is written, hosted, and maintained by @\[object Object]#0001.

## Dependencies
* [Luvit](https://luvit.io/)
* [Discordia](https://github.com/SinisterRectus/Discordia/)
* [lit-sqlite3](https://github.com/SinisterRectus/lit-sqlite3)

## Installation
I'd prefer if you would just invite my bot to your server using [the invite link](https://discordapp.com/api/oauth2/authorize?client_id=316932415840845865&permissions=805431366&scope=bot). However, if you want to run your own version, here's how.
* Download Yot.
* Install the dependencies.
* Run `./luvit create-db.lua`.
* Included is a shell script to start the bot using [PM2](https://pm2.keymetrics.io/), or just run `./luvit yot.lua`.
