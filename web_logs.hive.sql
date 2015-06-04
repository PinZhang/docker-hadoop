create table web_logs (
  `date` string,
  `domain` string,
  `path` string,
  `ip` string,
  `time` string,
  `method` string,
  `query` map<string, string>,
  `status` string,
  `user_agent` string
)
PARTITIONED BY (`p_date` string, `p_domain` string, `p_path` string)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t'
COLLECTION ITEMS TERMINATED BY '&'
MAP KEYS TERMINATED BY '=';

