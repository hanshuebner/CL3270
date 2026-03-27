;;;; -*- Mode: Lisp -*-

;;;; cl3270.asd
;;;;
;;;; Minimal 3720 data stream emulation.
;;;;
;;;; See the file COPYING for copyright and licensing information.

(asdf:defsystem "cl3270"
  :author "Marco Antoniotti"
  :license "MIT"
  :description "The CL3270 system.

The CL3270 implements a 3270 data stream handling/emulation.

The inspiration (and source material) is Matthew R. Wilson's GO library
which can be found at
[go3720](https://pkg.go.dev/github.com/racingmars/go3270)."

  :components ((:file "cl3270-pkg")
               (:file "setup"    :depends-on ("cl3270-pkg"))
               (:file "debug"    :depends-on ("cl3270-pkg" "setup"))

               (:file "bytes"    :depends-on ("cl3270-pkg" "setup" "debug"))
               (:file "util"     :depends-on ("cl3270-pkg" "setup" "debug"))

               (:file "codepage" :depends-on ("bytes" "util"))

               ;; (:file "ebcdic-ascii" :depends-on ("cl3270-pkg" "bytes"))
               (:file "ebcdic"   :depends-on ("bytes" "codepage" "codepages"))

               (:file "device"   :depends-on ("cl3270-pkg" "setup" "debug"))

               (:file "codes"    :depends-on ("cl3270-pkg" "setup" "debug"))

               (:file "telnet"
                :depends-on ("ebcdic" "codes" "device" "bytes" "util" "debug")
                )

               (:file "tls"
                :depends-on ("telnet" "codes" "bytes")
                )

               (:file "response" :depends-on ("ebcdic" "codes" "telnet"))
               (:file "screen"   :depends-on ("telnet" "response"))
               (:file "defscreen" :depends-on ("screen"))
               (:file "looper"   :depends-on ("screen" "codes"))
               (:file "transactions" :depends-on ("device"))
               (:module "codepages"
                :components ((:file "cp310")
                             (:file "cpbracket" :depends-on ("cp310"))
                             (:module "cps"
                              :depends-on ("cp310")
                              :components ((:file "cp-37")
                                           (:file "cp-273")
                                           (:file "cp-275")
                                           (:file "cp-277")
                                           (:file "cp-278")
                                           (:file "cp-280")
                                           (:file "cp-284")
                                           (:file "cp-285")
                                           (:file "cp-297")
                                           (:file "cp-424")
                                           (:file "cp-500")
                                           (:file "cp-803")
                                           (:file "cp-870")
                                           (:file "cp-871")
                                           (:file "cp-875")
                                           (:file "cp-880")
                                           (:file "cp-1026")
                                           (:file "cp-1047")
                                           (:file "cp-1140")
                                           (:file "cp-1141")
                                           (:file "cp-1142")
                                           (:file "cp-1143")
                                           (:file "cp-1144")
                                           (:file "cp-1145")
                                           (:file "cp-1146")
                                           (:file "cp-1147")
                                           (:file "cp-1148")
                                           (:file "cp-1149")
                                           (:file "cp-1160")))
                             )
                :depends-on ("codepage"))
               )
  :depends-on ("usocket" "usocket-server" "split-sequence" "cl-ppcre" "cl+ssl")
  )

;;;; end of file -- cl3270.asd
