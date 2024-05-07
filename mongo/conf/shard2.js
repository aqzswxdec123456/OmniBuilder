rs.initiate(
  {
    _id: "rs-shard2",
    configsvr: false,
    members: [
      { _id : 0, host : "<mongo_shard2_1>:27017" },
      { _id : 1, host : "<mongo_shard2_2>:27017" },
      { _id : 2, host : "<mongo_shard2_3>:27017" }
    ]
  }
);
