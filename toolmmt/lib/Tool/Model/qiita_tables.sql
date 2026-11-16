-- Qiita アクセス数集計用テーブル (MySQL)
--
--   qiita_item  : 記事一覧（最新の状態を1記事1行で保持）
--   qiita_daily : 日別の集計（集計日 × 記事 で1行）
--
-- 使い方:
--   mysql -u YourName -p YourDB < qiita_tables.sql

CREATE TABLE IF NOT EXISTS `qiita_item` (
  `記事ID`     varchar(20)  NOT NULL,
  `タイトル`   varchar(255) NOT NULL DEFAULT '',
  `URL`        varchar(255) NOT NULL DEFAULT '',
  `投稿日時`   datetime     DEFAULT NULL,
  `更新日時`   datetime     DEFAULT NULL,
  `PV数`       int          NOT NULL DEFAULT 0,
  `いいね数`   int          NOT NULL DEFAULT 0,
  `ストック数` int          NOT NULL DEFAULT 0,
  `UPD_TIME`   timestamp    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`記事ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `qiita_daily` (
  `集計日`     date         NOT NULL,
  `記事ID`     varchar(20)  NOT NULL,
  `PV数`       int          NOT NULL DEFAULT 0,   -- 集計時点の累計PV
  `増加PV`     int          DEFAULT NULL,         -- 前回集計日からの増加分（前回データがなければ NULL）
  `いいね数`   int          NOT NULL DEFAULT 0,
  `ストック数` int          NOT NULL DEFAULT 0,
  `UPD_TIME`   timestamp    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`集計日`,`記事ID`),
  KEY `idx_item_date` (`記事ID`,`集計日`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
