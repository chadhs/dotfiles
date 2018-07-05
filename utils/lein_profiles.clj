{:user {:plugins [
                  [lein-ancient "0.6.15"]
                  ]
        :repl-options {:init (set! *print-length* 100)}}}

;;; useful plugins not currently in use
;; lein-pdo
;; lein-pprint
;; lein-create-template
;; nightlight/lein-nightlight
;; walmartlabs/vizdeps

;;; uncomment and update versions to run a stand alone repl and using cider-connect
;; {:repl {:plugins [[cider/cider-nrepl "0.14.0"]
;;                   [refactor-nrepl "2.2.0"]]}}
