;; -*- mode: clojure; -*-

(ns ^{:doc "The Rouge core."
      :author "Arlen Christian Mart Cuss"}
  rouge.core)

(def seq (fn [coll]
           ; XXX right now this just coerces to a Cons
           (let [s (apply .[] ruby/Rouge.Cons (.to_a coll))]
             (if (.== s ruby/Rouge.Cons.Empty)
               nil
               s))))

(def concat (fn [& lists]
              ; XXX lazy seq
              (seq (.inject (.map lists | .to_a) | .+))))

(def list (fn [& elements]
            elements))

(defmacro defn [name args & body]
  `(def ~name (fn ~args ~@body)))

(defmacro when [cond & body]
  `(if ~cond
     (do
       ~@body)))

(defn vector [& args]
  (.to_a args))

(defn reduce [f coll]
  (.inject coll | f))

(defn map [f coll]
  ; XXX lazy seq
  (.map coll | f))

(defn str [& args]
  (let [args (map .to_s args)]
    (.join args "")))

(defn pr-str [& args]
  (let [args (map #(.print ruby/Rouge %) args)]
    (.join args " ")))

(defn print [& args]
  (.print ruby/Kernel (apply pr-str args)))

(defn puts [& args]
  (.print ruby/Kernel (apply str args) "\n"))

(defn count [coll]
  (.length coll))

(defn not [bool]
  (or (= bool nil)
      (= bool false)))

(defn or [& exprs]
  ; XXX NOT SHORT CIRCUITING!
  (.find exprs | [e] e))

(defn and [& exprs]
  ; XXX NOT SHORT CIRCUITING!  Also not Clojurish: doesn't return falsey value find.
  (if (.all? exprs | [e] e)
    (.last (.to_a exprs))))

(defn sequential? [coll]
  (and
    (or (.== (class coll) ruby/Array)
        (.== (class coll) ruby/Rouge.Cons)
        (.== coll ruby/Rouge.Cons.Empty))
    true))

(defn = [a b]
  (let [pre (if (and (sequential? a)
                     (sequential? b))
              seq
              #(do %))]
    (.== (pre a) (pre b))))

(defn empty? [coll]
  (= 0 (count coll)))

(defn + [& args]
  (if (empty? args)
    0
    (reduce .+ args)))

(defn - [a & args]
  (reduce .- (concat (list a) args)))

(defn * [& args]
  (if (empty? args)
    1
    (reduce .* args)))

(defn / [a & args]
  (reduce ./ (concat (list a) args)))

(defn require [lib]
  (.require ruby/Kernel lib))

(defn cons [head tail]
  ; XXX lazy seq
  (ruby/Rouge.Cons. head tail))

(defn range [from til]
  ; XXX this will blow so many stacks
  (if (= from til)
    ruby/Rouge.Cons.Empty
    (cons from (range (+ 1 from) til))))

(defn class [object]
  (.class object))

(defn seq? [object]
  (or (= (class object) ruby/Rouge.Cons)
      (= object ruby/Rouge.Cons.Empty)))

(def *ns* 'user)

(defn ns-publics [ns]
  )

(defn nth [coll index]
  (.[] (seq coll) index))

(defn first [coll]
  (.head (seq coll)))

(defn rest [coll]
  (.tail (seq coll)))

(defn next [coll]
  (seq (rest coll)))

(defn second [coll]
  (first (next coll)))

(defn macroexpand [form]
  (if (and (seq? form)
           (= (first form) :wah))
    :blah
    :hoo))

(defn push-thread-bindings [map]
  (.push ruby/Rouge.Var map))

(defn pop-thread-bindings []
  (.pop ruby/Rouge.Var))

(defn hash-map [& keyvals]
  (apply .[] ruby/Hash keyvals))

(defmacro binding [bindings & body]
  (let [var-ize (fn [var-vals]
                  (.flatten
                    (map
                      (fn [pair]
                        (let [key (first pair)
                              val (second pair)]
                          [`(.name (var ~key)) val]))
                      (.each_slice var-vals 2))
                    1))]
  `(do
     (push-thread-bindings (hash-map ~@(var-ize bindings)))
     (let [result (do ~@body)]
       (pop-thread-bindings)
       result))))
     ;(try
       ;~@body
       ;(finally
         ;(pop-thread-bindings)))) ))

(defn deref [derefable]
  (.deref derefable))

(defn atom [initial]
  (ruby/Rouge.Atom. initial))

(defn swap! [atom f & args]
  (apply .swap! atom f args))

(defn inc [v]
  (+ v 1))

(defn dec [v]
  (- v 1))

(defn conj [coll & xs]
  ; only cons and vector.  Also SUCKS.
  (if (= 0 (count xs))
    coll
    (let [c (class coll)
          hd (first xs)
          tl (rest xs)]
      (if (= c ruby/Rouge.Cons)
        (apply conj (ruby/Rouge.Cons coll hd) tl)
        (apply conj (.push (.dup coll) hd) tl)))))

(ns rouge.test
  (:use rouge.core ruby))

(def ^:dynamic *test-level* [])
(def *tests-passed* (atom 0))
(def *tests-failed* (atom []))

(defmacro testing [what & tests]
  `(do
     (when (= 0 *test-level*)
       (puts))
     (puts (* " " (count *test-level*) 2) "testing: " ~what)
     (binding [*test-level* (conj *test-level* ~what)]
       ~@tests
       {:passed @*tests-passed*
        :failed @*tests-failed*})))

(defmacro is [check]
  `(if (not ~check)
     (do
       (swap! *tests-failed* conj (conj *test-level* (pr-str '~check)))
       (puts "FAIL in ???")
       (puts "expected: " ~(pr-str check))
       (let [actual (if (and (seq? '~check)
                             (= 'not (first '~check)))
                      (second '~check)
                      `(not ~'~check))]
         (puts "  actual: " (pr-str actual))))
     (do
       (swap! *tests-passed* inc)
       true)))

; vim: set ft=clojure: