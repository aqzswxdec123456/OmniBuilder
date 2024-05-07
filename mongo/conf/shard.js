rs.initiate(
  {
    _id: "rs-shard",
    configsvr: false,
    members: [
      { _id : 0, host : "<mongo_shard_1>:27017" },
      { _id : 1, host : "<mongo_shard_2>:27017" },
      { _id : 2, host : "<mongo_shard_3>:27017" }
    ]
  }
);
