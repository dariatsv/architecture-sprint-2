cd sharding-repl-cache

docker compose up -d

docker compose -f compose.yaml exec -T configSrv mongosh --port 27017 <<EOF
rs.initiate(
  {
    _id : "config_server",
       configsvr: true,
    members: [
      { _id : 0, host : "configSrv:27017" }
    ]
  }
);
EOF

docker compose -f compose.yaml exec -T shard1_1 mongosh --port 27011 <<EOF
rs.initiate({_id: "shard1", members: [
    {_id: 0, host: "shard1_1:27011"},
    {_id: 1, host: "shard1_2:27012"},
    {_id: 2, host: "shard1_3:27013"}
]});
EOF

docker compose -f compose.yaml exec -T shard2_1 mongosh --port 27021 <<EOF
rs.initiate({_id: "shard2", members: [
    {_id: 0, host: "shard2_1:27021"},
    {_id: 1, host: "shard2_2:27022"},
    {_id: 2, host: "shard2_3:27023"}
]});
EOF

docker compose -f compose.yaml exec -T mongo_router mongosh --port 27020 <<EOF
sh.addShard( "shard1/shard1_1:27011");
sh.addShard( "shard2/shard2_1:27021");
sh.enableSharding("somedb");
sh.shardCollection("somedb.helloDoc", { "name" : "hashed" } )
use somedb
for(var i = 0; i < 1000; i++) db.helloDoc.insertOne({age:i, name:"my age "+i});
db.helloDoc.countDocuments();
exit();
EOF

docker compose -f compose.yaml exec -T redis echo "yes"