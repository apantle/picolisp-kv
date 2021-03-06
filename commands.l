# picolisp-kv - https://github.com/aw/picolisp-kv
#
# Commands which mimic Redis: https://redis.io/commands
#
# The MIT License (MIT)
# Copyright (c) 2020 Alexander Williams, On-Prem <license@on-premises.com>

# MAIN
[de kv-process (Child Request)
  (let Key (when (cadr Request) (kv-name (cadr Request)))
    (case (uppc (car Request))
      ["BGSAVE"     (kv-bgsave-db *Aof_desc) ]
      ["CLIENT"     (kv-cmd-client Child (cdr Request) ]
      ["CONVERT"    (kv-cmd-convert) ]
      ["DEL"        (kv-cmd-del (cadr Request) (; Request 3) ]
      ["EXISTS"     (kv-cmd-exists (cadr Request) (; Request 3) ]
      ["GET"        (kv-cmd-get (cadr Request) ]
      ["GETSET"     (kv-cmd-getset (cadr Request) (; Request 3) ]
      ["IDENT"      (kv-cmd-ident Child (cdr Request) ]
      ["INFO"       (kv-cmd-info (cadr Request) ]
      ["LINDEX"     (kv-cmd-lindex Key (; Request 3) ]
      ["LLEN"       (kv-cmd-llen Key) ]
      ["LPOP"       (kv-cmd-lpop Key) ]
      ["LPOPRPUSH"  (kv-cmd-lpoprpush Key (; Request 3) ]
      ["PING"       (kv-cmd-ping (cadr Request) ]
      ["RPUSH"      (kv-cmd-rpush (cadr Request) Key (; Request 3) ]
      ["SAVE"       (kv-save-db) ]
      ["SET"        (kv-cmd-set (cadr Request) (; Request 3) ]
      [T            "Error: Unknown command" ] ]

# COMMANDS
[de kv-cmd-flushall ()
  (mapcar '((N) (off (kv-name N))) Keys) ]

[de kv-cmd-client (Child Cmd)
  (case (uppc (car Cmd))
    ("ID"   (kv-cmd-client-id Child))
    ("KILL" (kv-cmd-client-kill (; Cmd 2) (; Cmd 3)))
    ("LIST" (kv-cmd-client-list))
    (T      "Error: Unknown client command") ]

[de kv-cmd-client-id (Child)
  (cdr (assoc "id" (cadr (assoc Child (get (kv-value "%stats%/connected_clients") ]

[de kv-cmd-client-kill (Filter Arg)
  (case (uppc Filter)
    ["ID"  (length (make (mapcar '((N) (when (= Arg (cdr (assoc "id" (cadr N)))) (kv-remove-client (car N) T) (link T))) (get (kv-value "%stats%/connected_clients") ]
    (T      0) ]

[de kv-cmd-client-list ()
  (glue "^J" (mapcar '((N) (glue " " (mapcar '((S) (pack (car S) "=" (cdr S))) (cadr N)))) (get (kv-value "%stats%/connected_clients") ]

# convert a database to/from plaintext<->binary
[de kv-cmd-convert ()
  (setq *KV_binary (onOff *KV_binary))
  (setq *KV_db (pack (dirname *KV_db) (glue "." (append (head -1 (split (chop *KV_db) ".")) (if *KV_binary '(("b" "i" "n")) '(("d" "b")))))))
  (kv-save-db) ]

[de kv-cmd-del (Key Elements)
  (if (and Key (not (pre? "%stats%/" Key)))
      (length (wipe (extract '((N) (unless (pre? "%stats%/" N) (kv-name N))) (conc (list Key) Elements))))
      0 ]                                                      # return 0 if no key is specified

[de kv-cmd-exists (Key Elements)
  (if (and Key (not (pre? "%stats%/" Key)))
      (cnt '((N) (unless (pre? "%stats%/" N) (kv-value N))) (conc (list Key) Elements))
      0 ]                                                      # return 0 if no key is specified

[de kv-cmd-ident (Child Elements)
  (when (and Child Elements (lst? Elements))                   # NIL if the IDENT isn't a list
        [push1 '*KV/%stats%/connected_clients                  # only add unique clients to the list
          (list Child (append (list (cons "id" (inc '*KV/%stats%/last_client)) (cons "pid" Child)) Elements) ]
        (pack "OK " (cdr (assoc "name" Elements) ]

[de kv-cmd-info (Section)
  (case (lowc Section)
    ["server"      (kv-info-format "Server" (kv-info-server) ]
    ["clients"     (kv-info-format "Clients" (kv-info-clients) ]
    ["memory"      (kv-info-format "Memory" (kv-info-memory) ]
    ["persistence" (kv-info-format "Persistence" (kv-info-persistence) ]
    ["stats"       (kv-info-format "Stats" (kv-info-stats) ]
    (T             (kv-info-default) ]

[de kv-cmd-lindex (Src Index)
  (when (and Src (num? Index))
        (cond
          ((= -1 Index)   (last (car Src)))
          ((lt0 Index)    (last (head (+ 1 Index) (car Src))))
          (T              (get (car Src) (+ 1 Index) ]

[de kv-cmd-llen (Key)
  (length (car Key) ]

[de kv-cmd-lpop (Src)
  (when (and Src (not (pre? "*KV/%stats%/" Src))) (pop Src) ]

[de kv-cmd-lpoprpush (Src Dst)
  (when (and Src Dst (not (pre? "*KV/%stats%/" Src)) (not (pre? "%stats%/" Dst)) (pop Src))
        (let Result @
          (kv-cmd-rpush Dst (kv-name Dst) (list Result))
          Result ]

[de kv-cmd-ping (Msg)
  (if Msg @ "PONG") ]

[de kv-cmd-rpush (Key Dst Elements)
  (when (and Dst Elements (lst? Elements) (not (pre? "%stats%/" Key)))
        (kv-cmd-set Key (append (kv-value Key) Elements))
        (length (car Dst) ]

[de kv-cmd-set (Key Value)
  (when (and Key Value (not (pre? "%stats%/" Key)) (set (kv-name Key) Value))
        (push1 (kv-name "keys") Key)                           # keep a list of all the keys
        "OK" ]

[de kv-cmd-get (Key)
  (kv-value Key) ]

[de kv-cmd-getset (Key Value)
  (let Result (kv-cmd-get Key)
    (kv-cmd-set Key Value)
    Result ]

# COMMAND helpers
[de kv-name (Name)
  (any (pack "*KV/" Name) ]

[de kv-value (Name)
  (car (any (pack "*KV/" Name) ]

# INFO command helpers
[de kv-info-format (Title Info)
  (pack "^J# " Title "^J"
    (mapcar '((S) (pack (car S) ":" (cdr S) "^J")) (clip Info) ]

[de kv-info-server ()
  (list
    (cons "app_version" (cadr (assoc "version" APP_INFO)))
    (cons "os" (in (list 'uname "-srm") (line T)))
    (cons "arch_bits" (if *CPU 64 32))
    (cons "process_id" *Pid)
    (cons "tcp_port" *KV_port)
    (cons "uptime_in_seconds" (/ (usec) 1000000))
    (cons "uptime_in_days" (/ (usec) 1000000 60 60 24))
    (cons "executable" (cmd)) ]

[de kv-info-clients ()
  (list
    (cons "connected_clients" (length *KV/%stats%/connected_clients)) ]

[de kv-info-memory-split ()
  (car (split (clip (in "/proc/meminfo" (from "MemTotal:") (till "^J"))) " ")) ]

[de kv-info-memory ()
  (make
    (link
      (cons "used_memory" (* (heap) 1024 1024))
      (cons "used_memory_human" (pack (heap) "M"))
      (cons "used_memory_startup" *KV_startup_memory) )
    (when (= *OS "Linux")
          (let Total_memory (* (format (kv-info-memory-split)) 1024 1024)
            (link
              (cons "total_system_memory" Total_memory)
              (cons "total_system_memory_human" (/ Total_memory 1024 1024 1024) "M") ]

[de kv-info-persistence ()
  (list
    (cons "db_format" (if *KV_binary "binary" "plaintext"))
    (cons "loading" *KV/%stats%/loading)
    (cons "rdb_changes_since_last_save" (if (info *KV_aof) (lines *KV_aof) 0))
    (cons "rdb_bgsave_in_progress" (if (info *KV_db_lock) 1 0))
    (cons "rdb_last_save_time" *KV/%stats%/rdb_last_save_time)
    (cons "rdb_last_bgsave_status" *KV/%stats%/rdb_last_bgsave_status)
    (cons "rdb_last_cow_size" *KV/%stats%/rdb_last_cow_size)
    (cons "aof_enabled" (if *KV_persist 1 0))
    (cons "aof_rewrite_in_progress" *KV/%stats%/aof_rewrite_in_progress)
    (cons "aof_last_write_status" *KV/%stats%/aof_last_write_status)
    (cons "aof_current_size" (if (info *KV_aof) (car @) 0))
    (cons "aof_base_size" *KV/%stats%/aof_base_size)
  ]

[de kv-info-stats ()
  (list
    (cons "total_connections_received" (length *KV/%stats%/total_connections_received))
    (cons "total_commands_processed" *KV/%stats%/total_commands_processed)
    (cons "total_net_input_bytes" *KV/%stats%/total_net_input_bytes)
    (cons "total_net_output_bytes" *KV/%stats%/total_net_output_bytes)
    (cons "rejected_connections" *KV/%stats%/rejected_connections)
    (cons "keyspace_hits" *KV/%stats%/keyspace_hits)
    (cons "keyspace_misses" *KV/%stats%/keyspace_misses) ]

[de kv-info-default ()
  (pack
    (kv-info-format "Server"      (kv-info-server))
    (kv-info-format "Clients"     (kv-info-clients))
    (kv-info-format "Memory"      (kv-info-memory))
    (kv-info-format "Persistence" (kv-info-persistence))
    (kv-info-format "Stats"       (kv-info-stats)) ]
