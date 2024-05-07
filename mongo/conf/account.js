use admin
db.createUser(
  {
    user: "root",
    pwd: "root",
    roles: [ { role: "root", db: "admin" } ]
  }
);

show users
db.auth('root', 'root');



// db.createUser({user:"root",pwd:"root",roles:[{role:"root",db:"admin"}]});