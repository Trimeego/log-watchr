# log-watchr

log-watchr is a simple socket.io server that accepts post requests, saves inbound messages to a mongo DB instance, and emits the message out to other socket-io sockets.  Messages are received from a script that monitors a log file and transmits each line written to the server.

## Dependencies

The log-watchr server is written in [Node](http://nodejs.org) and has dependencies on the following node modules

* [Express](http://expressjs.com/)
* [MongoDB](http://www.mongodb.org/)
* [noe-mongodb-native](https://github.com/christkv/node-mongodb-native)

See links for full installation instructions

## Usage

### Server

Once the prerequisites are installed, the server can be starte like any other node module:

    node log-watchr

If you are using the awesome [forever](https://github.com/nodejitsu/forever/) module:

    forever start log-watchr.js


### Monitors

Because is was constructed to monitor Windows logs, where the avaialble natives options are very limited, [Windows Powershell](http://technet.microsoft.com/en-us/library/bb978526.aspx) is used to monitor a given log file.  

Note:  For ease of use, the URL for the server is contained within log-watchr.ps1 located int he /public folder.  You will want to change this value.

To start monitoring a file, from the powershell, assuming we are already in the directory containing log-watchr.ps1:

    .\log-watchr.ps1 [path\to\file\to\watch] [name]

If you have not yet set your execution policy, you may get an error indicating that scripts are not allowed.  If so, make sure you are running powershell as an administrator and use:

    Set-ExecutionPolicy RemoteSigned





