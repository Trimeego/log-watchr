express = require("express")
http = require("http")
Db = require("mongodb").Db
GridStore = require("mongodb").GridStore
ObjectID = require("mongodb").ObjectID
Connection = require("mongodb").Connection
Server = require("mongodb").Server
BSON = require("mongodb").BSONPure

app = express.createServer()

host = (if process.env["MONGO_NODE_DRIVER_HOST"]? then process.env["MONGO_NODE_DRIVER_HOST"] else "localhost")
port = (if process.env["MONGO_NODE_DRIVER_PORT"]? then process.env["MONGO_NODE_DRIVER_PORT"] else Connection.DEFAULT_PORT)

app.configure ->
  app.use express.methodOverride()
  app.use express.bodyParser()
  app.use app.router
  app.use express.static(__dirname + "/public")

app.set('views', __dirname + '/views');
app.set('view engine', 'jade');

db = new Db("logWatcher", new Server(host, port, {}),
  native_parser: true
)

db.open (err, db) ->

  io = require("socket.io").listen(app)
  io.sockets.on 'connection', (s) ->
    s.join "log-watchr"
    

  app.get "/", (req, res) ->
    relativePath = "/"
    res.redirect "/index.html"


  app.get "/api/:collection/:id?", (req, res) ->
    query = (if req.query.query then JSON.parse(req.query.query) else {})
    query = _id: new BSON.ObjectID(req.params.id)  if req.params.id
    options = req.params.options or {}
    test = [ "limit", "sort", "fields", "skip", "hint", "explain", "snapshot", "timeout" ]
    for o of req.query
      options[o] = req.query[o]  if test.indexOf(o) >= 0
    collectionName = req.params.collection
    db.collection collectionName, (err, collection) ->
      if err
        res.send err, 500
      else
        collection.find query, options, (err, cursor) ->
          if err
            res.send err, 500
          else
            cursor.toArray (err, docs) ->
              if err
                res.send err, 500
              else
                if req.params.id and docs.length > 0
                  res.send docs[0], 200
                else
                  res.send docs, 200


  app.post "/api/:collection?", (req, res) ->
    collectionName = req.params.collection
    if req.query.nodb
      io.sockets.in('log-watchr').emit("logs", req.body)
    else  
      db.collection collectionName, (err, collection) ->
        if err
          console.log err
          res.send err, 500
        else
          collection.insert req.body, (err, docs) ->
            if err
              console.log err
              res.send err, 500
            else
              # socket.emit "logs", req.body if socket
              io.sockets.in('log-watchr').emit("logs", req.body)
              res.send docs[0], 201
            

  app.put "/api/:collection/:id", (req, res) ->
    collectionName = req.params.collection
    spec = _id: new BSON.ObjectID(req.params.id)
    db.collection collectionName, (err, collection) ->
      if err
        console.log err
        res.send err, 500
      else
        setSpec = {}
        for prop of req.body
          setSpec[prop] = req.body[prop]  if prop isnt "_id"
        collection.update spec,
          $set: setSpec
        ,
          safe: true
        , (err, docs) ->
          if err
            console.log err
            res.send err, 500
          else
            res.send req.body, 200

  app.delete "/api/:collection/:id", (req, res) ->
    collectionName = req.params.collection
    spec = _id: new BSON.ObjectID(req.params.id)
    db.collection collectionName, (err, collection) ->
      if err
        console.log err
        res.send err, 500
      else
        collection.remove spec, (err, result) ->
          if err
            console.log err
            res.send err, 500
          else
            res.send result, 200



  console.log "Log Watchr Server Started."
  app.listen 8082