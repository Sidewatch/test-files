(ns sample.inventory
  "Stock levels and reorder suggestions."
  (:require [clojure.string :as str]))

(def ^:const reorder-point 25)

(defrecord Item [sku qty price])

(defn low-stock
  "Items whose quantity is below the reorder point."
  [items]
  (filter #(< (:qty %) reorder-point) items))

(defn total-value [items]
  (reduce + (map (fn [{:keys [qty price]}] (* qty price)) items)))

(defmacro unless [test & body]
  `(if (not ~test) (do ~@body)))

(let [items [(->Item "A-100" 12 4.5) (->Item "B-200" 40 1.25) (->Item "C-300" 3 99.0)]
      low   (low-stock items)]
  (unless (empty? low)
    (println "Reorder:" (str/join ", " (map :sku low))))
  (printf "Stock value: %.2f%n" (total-value items)))
