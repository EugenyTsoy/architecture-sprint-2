echo "init  configSrv." 
docker compose exec -T configSrv  mongosh --port 27017 --quiet <<EOF
rs.initiate(
  {
    _id : "config_server",
    configsvr: true,
    members: [
      { _id : 0, host : "configSrv:27017" }
    ]
  }
);
exit();
EOF
#---
echo "init  shard1ReplMaster." 
docker compose exec -T  shard1ReplMaster mongosh --port 27018 --quiet <<EOF
rs.initiate(
    {
      _id : "shard1",
      members: [
        { _id : 0, host : "shard1ReplMaster:27018" },
        { _id : 1, host : "shard1Repl1:27019" },
        { _id : 2, host : "shard1Repl2:27020" },
      ]
    }
);
exit();
EOF
#---
echo "init  shard2ReplMaster." 
docker compose exec -T  shard2ReplMaster mongosh --port 27021 --quiet <<EOF
rs.initiate(
    {
      _id : "shard2",
      members: [
        { _id : 0, host : "shard2ReplMaster:27021" },
        { _id : 1, host : "shard2Repl1:27022" },
        { _id : 2, host : "shard2Repl2:27023" },
      ]
    }
);
exit();
EOF
#--
echo "router config." 
docker compose exec -T  mongos_router mongosh --port 27024 --quiet <<EOF
sh.addShard("shard1/shard1ReplMaster:27018");
sh.addShard("shard2/shard2ReplMaster:27021");
sh.enableSharding("somedb");
sh.shardCollection("somedb.helloDoc", { "name" : "hashed" } )
exit();
EOF
#--
echo "Filling data." 
docker compose exec -T  mongos_router mongosh --port 27024 --quiet <<EOF
use somedb
for(var i = 0; i < 1000; i++) db.helloDoc.insertOne({age:i, name:"ly"+i}) 
db.helloDoc.countDocuments()
exit();
EOF
#--
docker compose exec -T  shard1ReplMaster mongosh --port 27018 --quiet <<EOF
 use somedb;
 db.helloDoc.countDocuments();
 exit();
EOF
#--
docker compose exec -T  shard2ReplMaster mongosh --port 27021 --quiet <<EOF
 use somedb;
 db.helloDoc.countDocuments();
 exit();
EOF