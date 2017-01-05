{:user {:plugins [[lein-ancient "0.6.10"]
                  [lein-create-template "0.2.0"]
                  [lein-pprint "1.1.2"]]
        :repl-options {:init (set! *print-length* 100)}}}

;;; uncomment and update versions to run a stand alone repl and using cider-connect
;; {:repl {:plugins [[cider/cider-nrepl "0.14.0"]
;;                   [refactor-nrepl "2.2.0"]]}}
