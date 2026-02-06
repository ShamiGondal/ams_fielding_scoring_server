


CREATE TABLE `bowling_types` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `type` varchar(255) DEFAULT NULL,
  `code` varchar(10) NOT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id_UNIQUE` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `certificates` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `public_key` text NOT NULL,
  `private_key` text NOT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id_UNIQUE` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `cities` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `state_id` int unsigned NOT NULL,
  `country_id` int unsigned NOT NULL,
  `country_code` varchar(255) DEFAULT NULL,
  `state_code` varchar(255) DEFAULT NULL,
  `latitude` double DEFAULT NULL,
  `longitude` double DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id_UNIQUE` (`id`),
  KEY `fk_country_id_cities_idx` (`country_id`),
  KEY `fk_state_id_cities_idx` (`state_id`),
  CONSTRAINT `fk_country_id_cities` FOREIGN KEY (`country_id`) REFERENCES `countries` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_state_id_cities` FOREIGN KEY (`state_id`) REFERENCES `states` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `claim` (
  `id` int NOT NULL,
  `claim_name` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `created_by` int DEFAULT NULL,
  `updated_by` int DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `claims` (
  `id` int NOT NULL,
  `name` varchar(255) NOT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `created_by` int NOT NULL,
  `updated_by` int NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `club_types` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL COMMENT 'Cricket Board, PSL, League, Competition Group',
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `updated_at` datetime NOT NULL,
  `created_by` int NOT NULL,
  `updated_by` int NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `clubs` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `clud_type_id` int DEFAULT NULL,
  `country_id` int unsigned NOT NULL,
  `region` varchar(255) DEFAULT NULL,
  `affiliated_to` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id_UNIQUE` (`id`),
  KEY `fk_country_id_clubs_idx` (`country_id`),
  CONSTRAINT `fk_country_id_clubs` FOREIGN KEY (`country_id`) REFERENCES `countries` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=74 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `competition_types` (
  `id` int NOT NULL,
  `name` varchar(255) NOT NULL COMMENT 'Cup, Tournament, Series, Friendly',
  `created_at` datetime NOT NULL DEFAULT '0000-00-00 00:00:00' ON UPDATE CURRENT_TIMESTAMP,
  `updated_at` datetime NOT NULL,
  `created_by` int NOT NULL,
  `updated_by` int NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `competitions` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `continuation_of` varchar(255) DEFAULT NULL,
  `competition_name` varchar(255) DEFAULT NULL,
  `season_id` int unsigned NOT NULL,
  `level_id` int unsigned NOT NULL,
  `match_type_id` int unsigned NOT NULL,
  `is_parent` int NOT NULL,
  `club_id` int unsigned NOT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `competition_type_id` int NOT NULL,
  `created_by` int NOT NULL,
  `updated_by` int NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id_UNIQUE` (`id`),
  KEY `fk_season_id_competitions_idx` (`season_id`),
  KEY `fk_club_id_competitions_idx` (`club_id`),
  KEY `fk_level_id_competitions_idx` (`level_id`),
  CONSTRAINT `fk_club_id_competitions` FOREIGN KEY (`club_id`) REFERENCES `clubs` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_level_id_competitions` FOREIGN KEY (`level_id`) REFERENCES `levels` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_season_id_competitions` FOREIGN KEY (`season_id`) REFERENCES `seasons` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=117 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `countries` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `region` varchar(255) DEFAULT NULL,
  `latitude` double DEFAULT NULL,
  `longitude` double DEFAULT NULL,
  `flag` tinyint DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id_UNIQUE` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=253 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `innings_notes` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `ball_number` int DEFAULT NULL,
  `note_description` varchar(255) DEFAULT NULL,
  `match_id` int unsigned NOT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id_UNIQUE` (`id`),
  KEY `fk_match_id_innings_notes_idx` (`match_id`),
  CONSTRAINT `fk_match_id_innings_notes` FOREIGN KEY (`match_id`) REFERENCES `matches` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `label_ground` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `positions` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `created_by` int NOT NULL,
  `updated_by` int NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id_UNIQUE` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `label_pitch` (
  `id` int unsigned NOT NULL,
  `positions` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `created_by` int NOT NULL,
  `updated_by` int DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `levels` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `level_type` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id_UNIQUE` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `match_details` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `club_id` int unsigned NOT NULL,
  `team_id` int unsigned NOT NULL,
  `capt_id` int unsigned NOT NULL,
  `wicket_keeper_id` int unsigned NOT NULL,
  `twelfth_man_id` int DEFAULT NULL,
  `toss_won` bit(1) DEFAULT NULL,
  `toss_decision` varchar(255) DEFAULT NULL,
  `is_first_inning` tinyint(1) NOT NULL,
  `team_playing_status` varchar(255) DEFAULT NULL,
  `match_id` int unsigned NOT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `inning_number` int unsigned NOT NULL,
  `day_number` int unsigned NOT NULL,
  `session_number` int unsigned NOT NULL,
  `follow_on` tinyint(1) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id_UNIQUE` (`id`),
  KEY `fk_club_id_match_details_idx` (`club_id`),
  KEY `fk_team_id_match_details_idx` (`team_id`),
  KEY `fk_capt_id_match_details_idx` (`capt_id`),
  KEY `fk_wicket_keeper_id_match_details_idx` (`wicket_keeper_id`),
  KEY `fk_match_id_match_details_idx` (`match_id`) /*!80000 INVISIBLE */,
  KEY `fk_twelfth_man_id_match_details_idx` (`twelfth_man_id`),
  CONSTRAINT `fk_capt_id_match_details` FOREIGN KEY (`capt_id`) REFERENCES `players` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_club_id_match_details` FOREIGN KEY (`club_id`) REFERENCES `clubs` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_match_id_match_details` FOREIGN KEY (`match_id`) REFERENCES `matches` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_team_id_match_details` FOREIGN KEY (`team_id`) REFERENCES `teams` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_wicket_keeper_id_match_details` FOREIGN KEY (`wicket_keeper_id`) REFERENCES `players` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=16351999 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `match_lookups` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `sort_order` smallint NOT NULL,
  `button_width` tinyint NOT NULL,
  `button_height` tinyint NOT NULL,
  `background_color` varchar(15) NOT NULL,
  `hover_color` varchar(15) NOT NULL,
  `select_color` varchar(15) NOT NULL,
  `text_color` varchar(15) NOT NULL,
  `is_disabled` tinyint(1) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=17 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `match_lookups_values` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `sort_order` smallint NOT NULL,
  `is_disabled` tinyint(1) NOT NULL,
  `match_lookup_id` int NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=145 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `match_officials` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `roles` varchar(100) DEFAULT NULL,
  `first_name` varchar(255) DEFAULT NULL,
  `middle_name` varchar(255) DEFAULT NULL,
  `last_name` varchar(255) DEFAULT NULL,
  `prefered_first` varchar(255) DEFAULT NULL,
  `scorecard_name` varchar(255) DEFAULT NULL,
  `short_display_name` varchar(255) DEFAULT NULL,
  `gender` varchar(255) DEFAULT NULL,
  `club_id` int unsigned NOT NULL,
  `panels` varchar(100) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `created_by` int NOT NULL,
  `updated_by` int NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id_UNIQUE` (`id`),
  KEY `fk_club_id_match_officials_idx` (`club_id`),
  CONSTRAINT `fk_club_id_match_officials` FOREIGN KEY (`club_id`) REFERENCES `clubs` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=66 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `match_partnerships` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `start_time` datetime DEFAULT NULL,
  `batter1_id` int unsigned NOT NULL,
  `batter1_runs` int DEFAULT NULL,
  `partnership_runs` int DEFAULT NULL,
  `batter2_id` int unsigned NOT NULL,
  `batter2_runs` int DEFAULT NULL,
  `end` time DEFAULT NULL,
  `mins` int DEFAULT NULL,
  `fow` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id_UNIQUE` (`id`),
  KEY `fk_batter1_id_match_partnerships_idx` (`batter1_id`),
  KEY `fk_batter2_id_match_partnerships_idx` (`batter2_id`),
  CONSTRAINT `fk_batter1_id_match_partnerships` FOREIGN KEY (`batter1_id`) REFERENCES `players` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_batter2_id_match_partnerships` FOREIGN KEY (`batter2_id`) REFERENCES `players` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `match_play_details` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `striker_id` int unsigned NOT NULL,
  `non_striker_id` int unsigned NOT NULL,
  `bowler_id` int unsigned NOT NULL,
  `opening_end` varchar(255) DEFAULT NULL,
  `wicket_umpire_id` int DEFAULT NULL,
  `match_status` varchar(255) DEFAULT NULL,
  `is_first_inning` tinyint(1) NOT NULL,
  `match_id` int unsigned NOT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `inning_number` int unsigned NOT NULL,
  `day_number` int unsigned NOT NULL,
  `session_number` int unsigned NOT NULL,
  `batting_team_id` int unsigned NOT NULL,
  `bowling_team_id` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id_UNIQUE` (`id`),
  KEY `fk_striker_id_match_play_details_idx` (`striker_id`),
  KEY `fk_non_striker_id_match_play_details_idx` (`non_striker_id`),
  KEY `fk_bowler_id_match_play_details_idx` (`bowler_id`),
  KEY `fk_wicket_umpire_id_match_play_details_idx` (`wicket_umpire_id`),
  KEY `fk_match_id_match_play_details_idx` (`match_id`),
  CONSTRAINT `fk_bowler_id_match_play_details` FOREIGN KEY (`bowler_id`) REFERENCES `players` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_match_id_match_play_details` FOREIGN KEY (`match_id`) REFERENCES `matches` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_non_striker_id_match_play_details` FOREIGN KEY (`non_striker_id`) REFERENCES `players` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_striker_id_match_play_details` FOREIGN KEY (`striker_id`) REFERENCES `players` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=36777 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `match_play_states` (
  `id` int NOT NULL AUTO_INCREMENT,
  `event_name` varchar(200) NOT NULL,
  `description` varchar(500) DEFAULT NULL,
  `event_time` datetime NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=571 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `match_players` (
  `id` int NOT NULL AUTO_INCREMENT,
  `match_id` int NOT NULL,
  `team_id` int NOT NULL,
  `player_id` int NOT NULL,
  `play_order` int DEFAULT NULL,
  `how_out` varchar(255) DEFAULT NULL,
  `total_runs` int NOT NULL DEFAULT '0',
  `total_balls` int NOT NULL DEFAULT '0',
  `total_fours` int NOT NULL DEFAULT '0',
  `total_sixes` int NOT NULL DEFAULT '0',
  `batting_score_details` varchar(255) DEFAULT NULL,
  `bowl_over_throws` int NOT NULL DEFAULT '0',
  `bowl_runs` int NOT NULL DEFAULT '0',
  `bowl_wickets` int NOT NULL DEFAULT '0',
  `bowling_score_details` varchar(255) DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `inning_number` int DEFAULT NULL,
  `day_number` int DEFAULT NULL,
  `session_number` int DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2223474 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='team players in a match';

CREATE TABLE `match_results` (
  `id` int NOT NULL AUTO_INCREMENT,
  `match_id` int NOT NULL,
  `result_display` varchar(255) DEFAULT NULL,
  `winner_team_id` int DEFAULT NULL,
  `result_status` varchar(30) NOT NULL,
  `won_by` varchar(10) DEFAULT NULL,
  `won_by_runs_or_wicket` int NOT NULL,
  `player_of_match` int DEFAULT NULL,
  `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=14310 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `match_scorings` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `ball_number` int DEFAULT NULL,
  `over_number` int NOT NULL,
  `batter_id` int unsigned NOT NULL,
  `batter_non_striker_id` int NOT NULL,
  `bowler_id` int unsigned NOT NULL,
  `runs` int DEFAULT NULL,
  `extras` varchar(255) DEFAULT NULL,
  `extra_runs` int DEFAULT NULL,
  `ball_type` varchar(30) DEFAULT NULL,
  `wickets` varchar(255) DEFAULT NULL,
  `length` varchar(200) DEFAULT NULL,
  `ball_arrival_point` varchar(200) DEFAULT NULL,
  `wagon_wheel_point` varchar(200) DEFAULT NULL,
  `delivery` int DEFAULT NULL,
  `match_id` int unsigned NOT NULL,
  `speed` double DEFAULT NULL,
  `feet` int DEFAULT NULL,
  `shot` int DEFAULT NULL,
  `connection` int DEFAULT NULL,
  `events_id` int DEFAULT NULL,
  `fielding` varchar(255) DEFAULT NULL,
  `highlights` varchar(255) DEFAULT NULL,
  `time` datetime DEFAULT NULL,
  `video` varchar(255) DEFAULT NULL,
  `vision_ai` varchar(255) DEFAULT NULL,
  `is_first_inning` tinyint(1) NOT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `created_by` int NOT NULL,
  `updated_by` int DEFAULT NULL,
  `video_clip_path` varchar(255) DEFAULT NULL,
  `inning_number` int NOT NULL,
  `day_number` int NOT NULL,
  `session_number` int NOT NULL,
  `batting_team_id` int NOT NULL,
  `bowling_team_id` int DEFAULT NULL,
  `claim` int DEFAULT NULL,
  `fielder1_id` int DEFAULT NULL,
  `fielder2_id` int DEFAULT NULL,
  `event` int DEFAULT NULL,
  `fielding_type` int DEFAULT NULL,
  `pick_up` int DEFAULT NULL,
  `field_runs_saved` int DEFAULT NULL,
  `field_runs_given` int DEFAULT NULL,
  `field_throw` int DEFAULT NULL,
  `in_field` int DEFAULT NULL,
  `field_position` int DEFAULT NULL,
  `wicket_side` varchar(20) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id_UNIQUE` (`id`),
  KEY `fk_batter_id_match_scorings_idx` (`batter_id`),
  KEY `fk_bowler_id_match_scorings_idx` (`bowler_id`),
  KEY `fk_match_id_match_scorings_idx` (`match_id`),
  KEY `fk_events_id_match_scorings_idx` (`events_id`),
  CONSTRAINT `fk_batter_id_match_scorings` FOREIGN KEY (`batter_id`) REFERENCES `players` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_bowler_id_match_scorings` FOREIGN KEY (`bowler_id`) REFERENCES `players` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_match_id_match_scorings` FOREIGN KEY (`match_id`) REFERENCES `matches` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=49164293 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `match_types` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `description` varchar(255) DEFAULT NULL,
  `display_name` varchar(255) DEFAULT NULL,
  `format` tinyint(1) DEFAULT NULL,
  `club_id` int unsigned NOT NULL,
  `match_days` int DEFAULT NULL,
  `innings_per_team` int DEFAULT NULL,
  `batters_per_team` int DEFAULT NULL,
  `players_per_team` int DEFAULT NULL,
  `over_limit` int DEFAULT NULL,
  `max_overs_first_innings` int DEFAULT NULL,
  `min_overs_first_innings` int DEFAULT NULL,
  `bowler_over_limit` int DEFAULT NULL,
  `consecutive_overs_per_end` int DEFAULT NULL,
  `consecutive_overs_per_bowler` int DEFAULT NULL,
  `catches` tinyint(1) DEFAULT NULL,
  `default_dls_method` varchar(255) DEFAULT NULL,
  `default_dls_display` varchar(255) DEFAULT NULL,
  `super_overs` int DEFAULT NULL,
  `super_over_batter` int DEFAULT NULL,
  `power_play` int DEFAULT NULL,
  `overs_per_day` int DEFAULT NULL,
  `overs_per_day_last` int DEFAULT NULL,
  `overs_for_new_ball` int DEFAULT NULL,
  `balls_per_over` int DEFAULT NULL,
  `no_ball_value` int DEFAULT NULL,
  `wide_value` int DEFAULT NULL,
  `double_runs` int DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `created_by` int NOT NULL,
  `updated_by` int NOT NULL,
  `follow_on_deficit` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id_UNIQUE` (`id`),
  KEY `fk_club_id_match_types_idx` (`club_id`),
  CONSTRAINT `fk_club_id_match_types` FOREIGN KEY (`club_id`) REFERENCES `clubs` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=17 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `matches` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `competition_id` int unsigned NOT NULL,
  `match_type_id` int unsigned NOT NULL,
  `venue_id` int unsigned NOT NULL,
  `scorer1_id` int DEFAULT NULL,
  `scorer2_id` int DEFAULT NULL,
  `umpire1_id` int DEFAULT NULL,
  `umpire2_id` int DEFAULT NULL,
  `tv_umpire_id` int DEFAULT NULL,
  `match_refree_id` int DEFAULT NULL,
  `analyst_id` int DEFAULT NULL,
  `start_date` datetime DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id_UNIQUE` (`id`),
  KEY `fk_competition_id_matchs_idx` (`competition_id`),
  KEY `fk_match_type_id_matchs_idx` (`match_type_id`),
  KEY `fk_venue_id_matchs_idx` (`venue_id`),
  KEY `fk_scorer1_id_matchs_idx` (`scorer1_id`),
  KEY `fk_scorer2_id_matchs_idx` (`scorer2_id`),
  KEY `fk_umpire1_id_matchs_idx` (`umpire1_id`),
  KEY `fk_umpire2_id_matchs_idx` (`umpire2_id`),
  KEY `fk_tv_umpire_id_matchs_idx` (`tv_umpire_id`),
  KEY `fk_match_refree_id_matchs_idx` (`match_refree_id`),
  KEY `fk_analyst_id_matchs_idx` (`analyst_id`),
  CONSTRAINT `fk_competition_id_matchs` FOREIGN KEY (`competition_id`) REFERENCES `competitions` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_match_type_id_matchs` FOREIGN KEY (`match_type_id`) REFERENCES `match_types` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_venue_id_matchs` FOREIGN KEY (`venue_id`) REFERENCES `venues` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=502 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `penalties` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `penalty_type` varchar(255) DEFAULT NULL,
  `penalty_runs_awarded` int DEFAULT NULL,
  `ball_outcome` bit(1) DEFAULT NULL,
  `match_id` int unsigned NOT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id_UNIQUE` (`id`),
  KEY `fk_match_id_penalties_idx` (`match_id`),
  CONSTRAINT `fk_match_id_penalties` FOREIGN KEY (`match_id`) REFERENCES `matches` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `pitch_daily_metrics` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `pitch_report_id` int unsigned NOT NULL,
  `day_number` int NOT NULL,
  `bounce_rating` int NOT NULL,
  `seam_movement_rating` int NOT NULL,
  `bounce_consistency_rating` int NOT NULL,
  `turn_amount_rating` int NOT NULL,
  `notes` text,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_report_day` (`pitch_report_id`,`day_number`),
  CONSTRAINT `fk_pitch_report_id_daily_metrics` FOREIGN KEY (`pitch_report_id`) REFERENCES `pitch_reports` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `pitch_daily_metrics_chk_1` CHECK ((`day_number` between 1 and 5)),
  CONSTRAINT `pitch_daily_metrics_chk_2` CHECK ((`bounce_rating` between 0 and 10)),
  CONSTRAINT `pitch_daily_metrics_chk_3` CHECK ((`seam_movement_rating` between 0 and 10)),
  CONSTRAINT `pitch_daily_metrics_chk_4` CHECK ((`bounce_consistency_rating` between 0 and 10)),
  CONSTRAINT `pitch_daily_metrics_chk_5` CHECK ((`turn_amount_rating` between 0 and 10))
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `pitch_reports` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `match_id` int unsigned NOT NULL,
  `report_date` datetime NOT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `created_by` int NOT NULL,
  `updated_by` int NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `match_id_UNIQUE` (`match_id`),
  CONSTRAINT `fk_match_id_pitch_reports` FOREIGN KEY (`match_id`) REFERENCES `matches` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `players` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `first_name` varchar(255) DEFAULT NULL,
  `middle_name` varchar(255) DEFAULT NULL,
  `last_name` varchar(255) DEFAULT NULL,
  `prefered_first` varchar(255) DEFAULT NULL,
  `scorecard_name` varchar(255) DEFAULT NULL,
  `short_display_name` varchar(255) DEFAULT NULL,
  `gender` varchar(255) DEFAULT NULL,
  `shirt_number` int DEFAULT NULL,
  `is_batter` tinyint(1) NOT NULL,
  `left_handed_batter` bit(1) DEFAULT NULL,
  `batting_type_id` int DEFAULT NULL,
  `is_bowler` tinyint(1) NOT NULL,
  `left_arm_bowler` tinyint(1) NOT NULL,
  `bowling_type_id` int unsigned DEFAULT NULL,
  `wicket_keeper` bit(1) DEFAULT NULL,
  `visual_impairment` varchar(255) DEFAULT NULL,
  `country_id` int DEFAULT NULL,
  `dob` date DEFAULT NULL,
  `email` varchar(255) DEFAULT NULL,
  `mobile_number` varchar(255) DEFAULT NULL,
  `profile_image` longblob,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `is_retired` bit(1) NOT NULL,
  `created_by` int NOT NULL,
  `updated_by` int NOT NULL,
  `cnic_number` varchar(15) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id_UNIQUE` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2502 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `roles` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `description` varchar(255) NOT NULL,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `created_by` int NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `seasons` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `commenced_year` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `created_by` int NOT NULL,
  `updated_by` int NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id_UNIQUE` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `states` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `country_id` int unsigned NOT NULL,
  `country_code` varchar(255) DEFAULT NULL,
  `latitude` double DEFAULT NULL,
  `longitude` double DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id_UNIQUE` (`id`),
  KEY `fk_country_id_state_idx` (`country_id`),
  CONSTRAINT `fk_country_countries_states` FOREIGN KEY (`country_id`) REFERENCES `countries` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;



CREATE TABLE `team_players` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `team_id` int unsigned NOT NULL,
  `player_id` int unsigned NOT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id_UNIQUE` (`id`),
  KEY `fk_team_id_team_players_idx` (`team_id`),
  KEY `fk_player_id_team_players_idx` (`player_id`),
  CONSTRAINT `fk_player_id_team_players` FOREIGN KEY (`player_id`) REFERENCES `players` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_team_id_team_players` FOREIGN KEY (`team_id`) REFERENCES `teams` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=6248 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `teams` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `club_id` int unsigned NOT NULL,
  `name_in_club` varchar(255) DEFAULT NULL,
  `full_name` varchar(255) DEFAULT NULL,
  `short_display_name` varchar(255) DEFAULT NULL,
  `abbreviation_name` varchar(255) DEFAULT NULL,
  `team_gender` varchar(255) DEFAULT NULL,
  `team_primary_colour` varchar(255) DEFAULT NULL,
  `team_secondary_colour` varchar(255) DEFAULT NULL,
  `team_name` varchar(255) DEFAULT NULL,
  `team_logo` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `created_by` int NOT NULL,
  `updated_by` int NOT NULL,
  `competition_id` int unsigned NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id_UNIQUE` (`id`),
  KEY `fk_club_id_teams_idx` (`club_id`),
  KEY `fk_competition_id_teams_idx` (`competition_id`),
  CONSTRAINT `fk_club_id_teams` FOREIGN KEY (`club_id`) REFERENCES `clubs` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_competition_id_teams` FOREIGN KEY (`competition_id`) REFERENCES `competitions` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=142 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `users` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `email` varchar(255) NOT NULL,
  `password` varbinary(64) NOT NULL,
  `password_salt` varbinary(64) NOT NULL,
  `first_name` varchar(30) NOT NULL,
  `last_name` varchar(30) NOT NULL,
  `contact` varchar(30) DEFAULT NULL,
  `address` varchar(255) DEFAULT NULL,
  `details` varchar(255) DEFAULT NULL,
  `active` tinyint(1) NOT NULL,
  `role_id` int NOT NULL,
  `otp` varchar(8) DEFAULT NULL,
  `is_supervisor` tinyint NOT NULL DEFAULT '0',
  `is_email_verify` tinyint NOT NULL DEFAULT '0',
  `is_root` tinyint(1) NOT NULL DEFAULT '0',
  `otp_attempts` int DEFAULT NULL,
  `otp_timestamp` datetime DEFAULT NULL,
  `vm_public_ip` varchar(99) DEFAULT NULL,
  `vm_port` varchar(99) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id_UNIQUE` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=25 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE `venues` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `city_id` int unsigned NOT NULL,
  `country_id` int unsigned NOT NULL,
  `northmost_end` varchar(255) DEFAULT NULL,
  `southmost_end` varchar(255) DEFAULT NULL,
  `north_boundry` double DEFAULT NULL,
  `south_boundry` double DEFAULT NULL,
  `east_boundry` double DEFAULT NULL,
  `west_boundry` double DEFAULT NULL,
  `club_id` int unsigned NOT NULL,
  `latitude` double DEFAULT NULL,
  `longitude` double DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id_UNIQUE` (`id`),
  KEY `fk_country_id_venues_idx` (`country_id`),
  KEY `fk_city_id_venues_idx` (`city_id`),
  CONSTRAINT `fk_city_id_venues` FOREIGN KEY (`city_id`) REFERENCES `countries` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_country_id_venues` FOREIGN KEY (`country_id`) REFERENCES `countries` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=71 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


