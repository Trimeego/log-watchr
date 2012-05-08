// Generated by CoffeeScript 1.3.1
(function() {
  var BSON, Connection, Db, GridStore, ObjectID, Server, app, db, express, host, http, port;

  express = require("express");

  http = require("http");

  Db = require("mongodb").Db;

  GridStore = require("mongodb").GridStore;

  ObjectID = require("mongodb").ObjectID;

  Connection = require("mongodb").Connection;

  Server = require("mongodb").Server;

  BSON = require("mongodb").BSONPure;

  app = express.createServer();

  host = (process.env["MONGO_NODE_DRIVER_HOST"] != null ? process.env["MONGO_NODE_DRIVER_HOST"] : "localhost");

  port = (process.env["MONGO_NODE_DRIVER_PORT"] != null ? process.env["MONGO_NODE_DRIVER_PORT"] : Connection.DEFAULT_PORT);

  app.configure(function() {
    app.use(express.methodOverride());
    app.use(express.bodyParser());
    app.use(app.router);
    return app.use(express["static"](__dirname + "/public"));
  });

  app.set('views', __dirname + '/views');

  app.set('view engine', 'jade');

  db = new Db("logWatcher", new Server(host, port, {}), {
    native_parser: true
  });

  db.open(function(err, db) {
    var io;
    io = require("socket.io").listen(app);
    io.sockets.on('connection', function(s) {
      return s.join("log-watchr");
    });
    app.get("/", function(req, res) {
      var relativePath;
      relativePath = "/";
      return res.redirect("/index.html");
    });
    app.get("/api/:collection/:id?", function(req, res) {
      var collectionName, o, options, query, test;
      query = (req.query.query ? JSON.parse(req.query.query) : {});
      if (req.params.id) {
        query = {
          _id: new BSON.ObjectID(req.params.id)
        };
      }
      options = req.params.options || {};
      test = ["limit", "sort", "fields", "skip", "hint", "explain", "snapshot", "timeout"];
      for (o in req.query) {
        if (test.indexOf(o) >= 0) {
          options[o] = req.query[o];
        }
      }
      collectionName = req.params.collection;
      return db.collection(collectionName, function(err, collection) {
        if (err) {
          return res.send(err, 500);
        } else {
          return collection.find(query, options, function(err, cursor) {
            if (err) {
              return res.send(err, 500);
            } else {
              return cursor.toArray(function(err, docs) {
                if (err) {
                  return res.send(err, 500);
                } else {
                  if (req.params.id && docs.length > 0) {
                    return res.send(docs[0], 200);
                  } else {
                    return res.send(docs, 200);
                  }
                }
              });
            }
          });
        }
      });
    });
    app.post("/api/:collection", function(req, res) {
      var collectionName;
      collectionName = req.params.collection;
      return db.collection(collectionName, function(err, collection) {
        if (err) {
          console.log(err);
          return res.send(err, 500);
        } else {
          return collection.insert(req.body, function(err, docs) {
            if (err) {
              console.log(err);
              return res.send(err, 500);
            } else {
              io.sockets["in"]('log-watchr').emit("logs", req.body);
              return res.send(docs[0], 201);
            }
          });
        }
      });
    });
    app.put("/api/:collection/:id", function(req, res) {
      var collectionName, spec;
      collectionName = req.params.collection;
      spec = {
        _id: new BSON.ObjectID(req.params.id)
      };
      return db.collection(collectionName, function(err, collection) {
        var prop, setSpec;
        if (err) {
          console.log(err);
          return res.send(err, 500);
        } else {
          setSpec = {};
          for (prop in req.body) {
            if (prop !== "_id") {
              setSpec[prop] = req.body[prop];
            }
          }
          return collection.update(spec, {
            $set: setSpec
          }, {
            safe: true
          }, function(err, docs) {
            if (err) {
              console.log(err);
              return res.send(err, 500);
            } else {
              return res.send(req.body, 200);
            }
          });
        }
      });
    });
    app["delete"]("/api/:collection/:id", function(req, res) {
      var collectionName, spec;
      collectionName = req.params.collection;
      spec = {
        _id: new BSON.ObjectID(req.params.id)
      };
      return db.collection(collectionName, function(err, collection) {
        if (err) {
          console.log(err);
          return res.send(err, 500);
        } else {
          return collection.remove(spec, function(err, result) {
            if (err) {
              console.log(err);
              return res.send(err, 500);
            } else {
              return res.send(result, 200);
            }
          });
        }
      });
    });
    console.log("Log Watchr Server Started.");
    return app.listen(8082);
  });

}).call(this);
