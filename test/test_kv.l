# Key/Value tests

[de test-commands-get-set ()
  (assert-nil (kv-cmd-set) "[SET] Should return NIL if no key is provided")
  (assert-nil (kv-cmd-set "testkey") "[SET] Should return NIL if no value is provided")
  (assert-nil (kv-cmd-get) "[GET] Should return NIL if no key is provided")
  (assert-nil (kv-cmd-get (kv-name "nonexistant")) "[GET] Should return NIL if the key doesn't exist")
  (assert-equal "OK" (kv-cmd-set "testkey" "testvalue") "[SET] Should set a key and return OK")
  (assert-equal "testvalue" (kv-cmd-get "testkey") "[GET] Should return the value of the key")
  ]

[de test-commands-rpush ()
  (assert-nil (kv-cmd-rpush) "[RPUSH] Should return NIL if no key is provided")
  (assert-nil (kv-cmd-rpush "tasks") "[RPUSH] Should return NIL if only 1 key is provided")
  (assert-nil (kv-cmd-rpush "tasks" (kv-name "tasks")) "[RPUSH] Should return NIL if no elements are provided")
  (assert-nil (kv-cmd-rpush "tasks" (kv-name "tasks") "element 1") "[RPUSH] Should return NIL if the elements aren't a list")
  (kv-cmd-del "keys")
  (assert-equal 5 (kv-cmd-rpush "tasks" (kv-name "tasks") '("task1" "task2" "task3" "task4" "task5")) "[RPUSH] Should return the length of the new list")
  (assert-equal 7 (kv-cmd-rpush "tasks" (kv-name "tasks") '("task6" "task7")) "[RPUSH] Should return the extended length of the list")
  (assert-equal "task1" (kv-cmd-lindex (kv-name "tasks") 0) "[LINDEX] Should return the key at index 0")
  (assert-equal "task5" (kv-cmd-lindex (kv-name "tasks") 4) "[LINDEX] Should return the key at index 5")
  (assert-equal "task7" (kv-cmd-lindex (kv-name "tasks") -1) "[LINDEX] Should return the last key")
  (assert-equal "task6" (kv-cmd-lindex (kv-name "tasks") -2) "[LINDEX] Should return the penultimate key")
  (assert-nil (kv-cmd-lindex (kv-name "tasks") 10) "[LINDEX] Should return NIL if no value exists at the index")
  (assert-equal 1 (kv-cmd-llen (kv-name "keys")) "[LLEN] Should return the number of keys in the keys list")
  (assert-equal "tasks" (kv-cmd-lindex (kv-name "keys") 0) "[LINDEX] Should return the name of the key in the keys list")
  (assert-equal "task1" (kv-cmd-lpop (kv-name "tasks")) "[LPOP] Should return the first value added to the tasks list")
  (assert-equal 6 (kv-cmd-llen (kv-name "tasks")) "[LLEN] Should return the number of keys remaining in the tasks list")
  ]

[de test-commands-stats-failures ()
  (assert-nil (kv-cmd-set "%stats%/connected_clients" 0) "[SET] Should fail to overwrite a stats key")
  (assert-nil (kv-cmd-rpush "%stats%/connected_clients" (kv-name "%stats%/connected_clients") '(1 2 3)) "[RPUSH] Should fail to rpush to a stats key")
  (assert-nil (kv-cmd-lpop (kv-name "%stats%/connected_clients")) "[LPOP] Should fail to left-pop a stats key")
  (assert-nil (kv-cmd-lpoprpush (kv-name "%stats%/connected_clients") "destkey") "[LPOPRPUSH] Should fail to left-pop a stats key")
  (assert-nil (kv-cmd-lpoprpush (kv-name "sourcekey") "%stats%/connected_clients") "[LPOPRPUSH] Should fail to rpush to a stats key")
  (assert-equal 0 (kv-cmd-del "%stats%/connected_clients") "[DEL] Should fail to delete a stats key")
  (assert-equal 1 (kv-cmd-del "validkey" (list "%stats%/connected_clients")) "[DEL] Should fail to delete multiple stats key")
  ]

[de test-commands-lindex ()
  (assert-nil (kv-cmd-lindex) "[LINDEX] Should return NIL if no key is provided")
  (assert-nil (kv-cmd-lindex (kv-name "testindex")) "[LINDEX] Should return NIL if no index is provided")
  (assert-nil (kv-cmd-lindex (kv-name "nonexistant")) "[LINDEX] Should return NIL if the key doesn't exist")
  (assert-nil (kv-cmd-lindex (kv-name "testindex") "abc") "[LINDEX] Should return NIL if index isn't a number")
  ]

[de test-commands-ident ()
  (assert-nil (kv-cmd-ident) "[IDENT] Should return NIL if no child pid is provided")
  (assert-nil (kv-cmd-ident 12345) "[IDENT] Should return NIL if no elements are provided")
  (assert-nil (kv-cmd-ident 12345 "abc") "[IDENT] Should return NIL if elements aren't a list")
  (assert-equal "OK abc" (kv-cmd-ident 12345 (list (cons "id" "abc"))) "[IDENT] Should return OK with the client ID")
  (assert-equal '(12345 (("id" . "abc") ("ip"))) (kv-cmd-lindex (kv-name "%stats%/connected_clients") 0) "[LINDEX] Should return the info of the connected client")
  (assert-kind-of 'Number (kv-cmd-llen (kv-name "%stats%/connected_clients")) "[LLEN] Should show only 1 connected client")
  ]

[de test-commands-info ()
  (assert-equal 46378 (cdr (assoc "tcp_port" (kv-info-server))) "[INFO-SERVER] Should return a list of server INFO")
  (assert-nil (cdr (assoc "connected_clients" (kv-info-server))) "[INFO-CLIENTS] Should return a list of clients INFO")
  (assert-equal "1M" (cdr (assoc "used_memory_human" (kv-info-memory))) "[INFO-MEMORY] Should return a list of memory INFO")
  (assert-equal 1 (cdr (assoc "total_connections_received" (kv-info-stats))) "[INFO-STATS] Should return a list of stats INFO")
  (assert-kind-of 'String (kv-info-default) "[INFO] Should return a string of INFO")
  ]

[de test-commands-lpop ()
  (assert-nil (kv-cmd-lpop) "[LPOP] Should return NIL if no key is provided")
  (assert-nil (kv-cmd-lpop (kv-name "nonexistant")) "[LPOP] Should return NIL if the key doesn't exist")
  ]

[de test-commands-lpoprpush ()
  (assert-nil (kv-cmd-lpoprpush) "[LPOPRPUSH] Should return NIL if no source is provided")
  (assert-nil (kv-cmd-lpoprpush (kv-name "inkey")) "[LPOPRPUSH] Should return NIL if no dest is provided")
  (assert-nil (kv-cmd-lpoprpush (kv-name "nonexistant")) "[LPOPRPUSH] Should return NIL if the key doesn't exist")
  (kv-cmd-rpush "inkey" (kv-name "inkey") '(5 6 7 8 9))
  (assert-equal 5 (kv-cmd-lpoprpush (kv-name "inkey") "outkey") "[LPOPRPUSH] Should return the element being popped")
  (assert-equal 4 (kv-cmd-llen (kv-name "inkey")) "[LLEN] Should list only 4 elements in the source key")
  (assert-equal 1 (kv-cmd-llen (kv-name "outkey")) "[LLEN] Should list only 1 element in the dest key")
  (assert-equal 5 (kv-cmd-lindex (kv-name "outkey") 0) "[LINDEX] Should return the value of the popped key")
  (assert-equal 6 (kv-cmd-lindex (kv-name "inkey") 0) "[LINDEX] Should return the value of the first key")
  (assert-equal 6 (kv-cmd-lpoprpush (kv-name "inkey") "outkey") "[LPOPRPUSH] Should return the element being popped (again)")
  ]

[de test-commands-del ()
  (kv-cmd-set "delkey1" "deletekey")
  (assert-equal 1 (kv-cmd-del "delkey1") "[DEL] Should delete a single key")
  (kv-cmd-rpush "delkey2" (kv-name "delkey2") '(0 0 1 1 0 1 0 0))
  (kv-cmd-rpush "delkey3" (kv-name "delkey3") '(0 0 1 1 0 1 1 0))
  (assert-equal 4 (kv-cmd-del "delkey2" (list "delkey3" "delkey4" "delkey5")) "[DEL] Should delete multiple keys and return how many were deleted")
  (assert-equal 0 (kv-cmd-llen (kv-name "delkey2")) "[LLEN] Should confirm if delkey2 was deleted")
  (assert-equal 0 (kv-cmd-llen (kv-name "delkey3")) "[LLEN] Should confirm if delkey3 was deleted")
  (assert-equal 0 (kv-cmd-del) "[DEL] Should not delete a key that isn't provided")
  ]

[de test-commands-process ()
  (assert-equal "Error: Unknown command" (kv-process 12345 (list "UNKNOWN")) "[PROCESS] Should return an ERROR message if the command is unknown")
  (assert-equal 1 (kv-process 12345 (list "DEL" "processkey")) "[PROCESS] Should process the DEL command")
  (assert-equal "OK" (kv-process 12345 (list "SET" "processkey" "processvalue")) "[PROCESS] Should process the SET command")
  (assert-equal "processvalue" (kv-process 12345 (list "GET" "processkey")) "[PROCESS] Should process the GET command")
  (assert-equal 3 (kv-process 12345 (list "RPUSH" "processkey" (11 22 33))) "[PROCESS] Should process the RPUSH command")
  (assert-equal "OK 007" (kv-process 12345 (list "IDENT" (list "id" "007"))) "[PROCESS] Should process the IDENT command")
  (assert-kind-of 'String (kv-process 12345 (list "INFO")) "[PROCESS] Should process the INFO command")
  (assert-equal 22 (kv-process 12345 (list "LINDEX" "processkey" 1)) "[PROCESS] Should process the LINDEX command")
  (assert-equal 3 (kv-process 12345 (list "LLEN" "processkey")) "[PROCESS] Should process the LLEN command")
  (assert-kind-of 'String (kv-process 12345 (list "LOLWUT" 1)) "[PROCESS] Should process the LOLWUT command")
  (assert-equal 11 (kv-process 12345 (list "LPOP" "processkey")) "[PROCESS] Should process the LPOP command")
  (assert-equal 22 (kv-process 12345 (list "LPOPRPUSH" "processkey" "processdest")) "[PROCESS] Should process the LPOPRPUSH command")
  (assert-kind-of 'String (kv-process 12345 (list "info" "server")) "[PROCESS] Should process a lowercase command")
  ]

[execute
  (prinl "^J  Testing Key/Value^J")

  '(assert-equal 0 (kv-cmd-llen (kv-name "nonexistant")) "[LLEN] Should return 0 if the key doesn't exist")
  '(assert-kind-of 'String (kv-cmd-lolwut 1) "[LOLWUT] Should return a sparkline as a string")
  '(test-commands-del)
  '(test-commands-get-set)
  '(test-commands-ident)
  '(test-commands-info)
  '(test-commands-lindex)
  '(test-commands-lpop)
  '(test-commands-lpoprpush)
  '(test-commands-rpush)
  '(test-commands-stats-failures)
  '(test-commands-process)
  ]