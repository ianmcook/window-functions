-- DuckDB
CREATE TABLE daylight(month TINYINT, day TINYINT, light DECIMAL(6,4));
COPY daylight from 'daylight.tsv' (AUTO_DETECT TRUE);

-- Impala or Hive
CREATE TABLE daylight (month TINYINT, day TINYINT, light DECIMAL(6,4)) ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t';
-- then copy daylight.tsv into the table directory
