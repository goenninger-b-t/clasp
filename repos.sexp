;;;; The order in this file should be
;;;;   1. dependencies/ - needed by the host
;;;;   2. src/lisp/kernel/contrib/ - needed by the clasp images
;;;;   3. src/lisp/modules/ - other lisp modules
;;;;   4. src/ - C/C++ dependencies for iclasp
;;;;   5. extensions/ - extensions and their dependencies
((:name :ansi-test
  :repository "https://gitlab.common-lisp.net/yitzchak/ansi-test"
  :directory "dependencies/ansi-test/"
  :branch "add-expected-failures")
 (:name :cl-bench
  :repository "https://gitlab.common-lisp.net/ansi-test/cl-bench.git"
  :directory "dependencies/cl-bench/"
  :branch "master")
 (:name :cl-who
  :repository "https://github.com/edicl/cl-who.git"
  :directory "dependencies/cl-who/"
  :branch "master")
 (:name :quicklisp-client
  :repository "https://github.com/quicklisp/quicklisp-client.git"
  :directory "dependencies/quicklisp-client/"
  :commit "version-2021-02-13")
 (:name :shasht
  :repository "https://github.com/yitzchak/shasht.git"
  :directory "dependencies/shasht/"
  :branch "master")
 (:name :trivial-do
  :repository "https://github.com/yitzchak/trivial-do.git"
  :directory "dependencies/trivial-do/"
  :branch "master")
 (:name :trivial-gray-streams
  :repository "https://github.com/trivial-gray-streams/trivial-gray-streams.git"
  :directory "dependencies/trivial-gray-streams/"
  :branch "master")
 (:name :acclimation
  :repository "https://github.com/robert-strandh/Acclimation.git"
  :directory "src/lisp/kernel/contrib/Acclimation/"
  :commit "dd15c86b0866fc5d8b474be0da15c58a3c04c45c")
 (:name :alexandria
  :repository "https://gitlab.common-lisp.net/alexandria/alexandria.git"
  :directory "src/lisp/kernel/contrib/alexandria/"
  :commit "v1.4")
 (:name :anaphora
  :repository "https://github.com/spwhitton/anaphora.git"
  :directory "src/lisp/kernel/contrib/anaphora/"
  :commit "bcf0f7485eec39415be1b2ec6ca31cf04a8ab5c5"
  :extension :cando)
 (:name :architecture.builder-protocol
  :repository "https://github.com/scymtym/architecture.builder-protocol.git"
  :directory "src/lisp/kernel/contrib/architecture.builder-protocol/"
  :commit "0c1a9ebf9ab14e699c2b9c85fc20265b8c5364dd"
  :extension :cando)
 (:name :array-utils
  :repository "https://github.com/Shinmera/array-utils.git"
  :directory "src/lisp/kernel/contrib/array-utils/"
  :commit "5acd90fa3d9703cea33e3825334b256d7947632f"
  :extension :cando)
 (:name :babel
  :repository "https://github.com/cl-babel/babel.git"
  :directory "src/lisp/kernel/contrib/babel/"
  :commit "f892d0587c7f3a1e6c0899425921b48008c29ee3"
  :extension :cando)
 (:name :bordeaux-threads
  :repository "https://github.com/sionescu/bordeaux-threads.git"
  :directory "src/lisp/kernel/contrib/bordeaux-threads/"
  :commit "3d25cd01176f7c9215ebc792c78313cb99ff02f9"
  :extension :cando)
 (:name :cffi ; TODO remove once cando-user no longer needs
  :repository "https://github.com/cffi/cffi.git"
  :directory "src/lisp/kernel/contrib/cffi/"
  :commit "9c912e7b89eb09dd347d3ebae16e4dc5f53e5717"
  :extension :cando)
 (:name :cl-markup
  :repository "https://github.com/arielnetworks/cl-markup.git"
  :directory "src/lisp/kernel/contrib/cl-markup/"
  :commit "e0eb7debf4bdff98d1f49d0f811321a6a637b390"
  :extension :cando)
 (:name :cl-ppcre
  :repository "https://github.com/edicl/cl-ppcre.git"
  :directory "src/lisp/kernel/contrib/cl-ppcre/"
  :commit "b4056c5aecd9304e80abced0ef9c89cd66ecfb5e"
  :extension :cando)
 (:name :cl-svg
  :repository "https://github.com/wmannis/cl-svg.git"
  :directory "src/lisp/kernel/contrib/cl-svg/"
  :commit "1e988ebd2d6e2ee7be4744208828ef1b59e5dcdc"
  :extension :cando)
 (:name :cleavir
  :repository "https://github.com/s-expressionists/Cleavir.git"
  :directory "src/lisp/kernel/contrib/Cleavir/"
  :commit "a73d313735447c63b4b11b6f8984f9b1e3e74ec9")
 (:name :closer-mop
  :repository "https://github.com/pcostanza/closer-mop.git"
  :directory "src/lisp/kernel/contrib/closer-mop/"
  :commit "d4d1c7aa6aba9b4ac8b7bb78ff4902a52126633f")
 (:name :concrete-syntax-tree
  :repository "https://github.com/s-expressionists/Concrete-Syntax-Tree.git"
  :directory "src/lisp/kernel/contrib/Concrete-Syntax-Tree/"
  :commit "4f01430c34f163356f3a2cfbf0a8a6963ff0e5ac")
 (:name :documentation-utils
  :repository "https://github.com/Shinmera/documentation-utils.git"
  :directory "src/lisp/kernel/contrib/documentation-utils/"
  :commit "98630dd5f7e36ae057fa09da3523f42ccb5d1f55"
  :extension :cando)
 (:name :eclector
  :repository "https://github.com/s-expressionists/Eclector.git"
  :directory "src/lisp/kernel/contrib/Eclector/"
  :commit "state-value-protocol")
 (:name :esrap ; Needed both by the host and eclasp
  :repository "https://github.com/scymtym/esrap.git"
  :directory "src/lisp/kernel/contrib/esrap/"
  :commit "7588b430ad7c52f91a119b4b1c9a549d584b7064")
 (:name :global-vars
  :repository "https://github.com/lmj/global-vars.git"
  :directory "src/lisp/kernel/contrib/global-vars/"
  :commit "c749f32c9b606a1457daa47d59630708ac0c266e"
  :extension :cando)
 (:name :let-plus
  :repository "https://github.com/sharplispers/let-plus.git"
  :directory "src/lisp/kernel/contrib/let-plus/"
  :commit "455e657e077235829b197f7ccafd596fcda69e30"
  :extension :cando)
 (:name :cl-netcdf ; TODO remove once cando-user no longer needs
  :repository "https://github.com/clasp-developers/cl-netcdf.git"
  :directory "src/lisp/kernel/contrib/cl-netcdf/"
  :commit "593c6c47b784ec02e67580aa12a7775ed6260200"
  :extension :cando)
 (:name :lparallel
  :repository "https://github.com/yitzchak/lparallel.git"
  :directory "src/lisp/kernel/contrib/lparallel/"
  :branch "fix-asdf-feature"
  :extension :cando)
 (:name :parser.common-rules
  :repository "https://github.com/scymtym/parser.common-rules.git"
  :directory "src/lisp/kernel/contrib/parser.common-rules/"
  :commit "b7652db5e3f98440dce2226d67a50e8febdf7433"
  :extension :cando)
 (:name :plump
  :repository "https://github.com/Shinmera/plump.git"
  :directory "src/lisp/kernel/contrib/plump/"
  :commit "d8ddda7514e12f35510a32399f18e2b26ec69ddc"
  :extension :cando)
 (:name :split-sequence ; Needed both by the host and eclasp
  :repository "https://github.com/sharplispers/split-sequence.git"
  :directory "src/lisp/kernel/contrib/split-sequence/"
  :commit "89a10b4d697f03eb32ade3c373c4fd69800a841a")
 (:name :static-vectors ; TODO remove once cando-user no longer needs
  :repository "https://github.com/sionescu/static-vectors.git"
  :directory "src/lisp/kernel/contrib/static-vectors/"
  :commit "87a447a8eaef9cf4fd1c16d407a49f9adaf8adad"
  :extension :cando)
 (:name :trivial-features ; Needed both by the host and eclasp
  :repository "https://github.com/yitzchak/trivial-features.git"
  :directory "src/lisp/kernel/contrib/trivial-features/"
  :branch "asdf-feature")
 (:name :trivial-garbage
  :repository "https://github.com/trivial-garbage/trivial-garbage.git"
  :directory "src/lisp/kernel/contrib/trivial-garbage/"
  :commit "b3af9c0c25d4d4c271545f1420e5ea5d1c892427"
  :extension :cando)
 (:name :trivial-http ; Needed both by the host and eclasp
  :repository "https://github.com/gwkkwg/trivial-http.git"
  :directory "src/lisp/kernel/contrib/trivial-http/"
  :commit "ca45656587f36378305de1a4499c308acc7a03af")
 (:name :trivial-indent
  :repository "https://github.com/Shinmera/trivial-indent.git"
  :directory "src/lisp/kernel/contrib/trivial-indent/"
  :commit "8d92e94756475d67fa1db2a9b5be77bc9c64d96c"
  :extension :cando)
 (:name :trivial-with-current-source-form ; Needed both by the host and eclasp
  :repository "https://github.com/scymtym/trivial-with-current-source-form.git"
  :directory "src/lisp/kernel/contrib/trivial-with-current-source-form/"
  :commit "3898e09f8047ef89113df265574ae8de8afa31ac")
 (:name :usocket ; Needed both by the host and eclasp
  :repository "https://github.com/usocket/usocket.git"
  :directory "src/lisp/kernel/contrib/usocket/"
  :commit "7ad6582cc1ce9e7fa5931a10e73b7d2f2688fa81")
 (:name :asdf
  :repository "https://gitlab.common-lisp.net/asdf/asdf.git"
  :directory "src/lisp/modules/asdf/"
  :commit "3.3.5")
 (:name :mps
  :repository "https://github.com/Ravenbrook/mps.git"
  :directory "src/mps/"
  :commit "b8a05a3846430bc36c8200f24d248c8293801503")
 (:name :bdwgc
  :repository "https://github.com/ivmai/bdwgc.git"
  :directory "src/bdwgc/"
  :commit "v8.2.0")
 (:name :libatomic_ops
  :repository "https://github.com/ivmai/libatomic_ops.git"
  :directory "src/libatomic_ops/"
  :commit "v7.6.12")
 (:name :cando
  :repository "https://github.com/cando-developers/cando.git"
  :directory "extensions/cando/"
  :branch "main"
  :extension :cando)
 (:name :seqan-clasp
  :repository "https://github.com/clasp-developers/seqan-clasp.git"
  :directory "extensions/seqan-clasp/"
  :branch "main"
  :extension :seqan-clasp)
 (:name :seqan
  :repository "https://github.com/seqan/seqan.git"
  :directory "extensions/seqan-clasp/seqan/"
  :branch "master"
  :extension :seqan-clasp))