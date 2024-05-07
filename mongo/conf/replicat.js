rs.initiate(
  {
    _id: "rs-conf",
    configsvr: true,
    members: [
      { _id : 0, host : "<mongo_replication_1>:27017" },
      { _id : 1, host : "<mongo_replication_2>:27017" },
      { _id : 2, host : "<mongo_replication_3>:27017" }
    ]
  }
);
