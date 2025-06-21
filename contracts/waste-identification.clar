;; Waste Identification Contract
;; Identifies and tracks operational waste in manufacturing processes

(define-constant contract-owner tx-sender)
(define-constant err-unauthorized (err u200))
(define-constant err-not-found (err u201))
(define-constant err-invalid-data (err u202))

;; Waste types
(define-constant WASTE-OVERPRODUCTION u1)
(define-constant WASTE-WAITING u2)
(define-constant WASTE-TRANSPORT u3)
(define-constant WASTE-OVERPROCESSING u4)
(define-constant WASTE-INVENTORY u5)
(define-constant WASTE-MOTION u6)
(define-constant WASTE-DEFECTS u7)

;; Data structures
(define-map waste-reports uint {
  reporter: principal,
  waste-type: uint,
  location: (string-ascii 50),
  description: (string-ascii 200),
  severity: uint,
  estimated-cost: uint,
  reported-at: uint,
  status: (string-ascii 20)
})

(define-map waste-metrics {waste-type: uint, period: uint} {
  total-instances: uint,
  total-cost: uint,
  avg-severity: uint
})

(define-data-var waste-report-id uint u0)

;; Public functions
(define-public (report-waste (waste-type uint) (location (string-ascii 50)) (description (string-ascii 200)) (severity uint) (cost uint))
  (let ((report-id (+ (var-get waste-report-id) u1)))
    (asserts! (<= waste-type u7) err-invalid-data)
    (asserts! (<= severity u10) err-invalid-data)
    (map-set waste-reports report-id {
      reporter: tx-sender,
      waste-type: waste-type,
      location: location,
      description: description,
      severity: severity,
      estimated-cost: cost,
      reported-at: block-height,
      status: "open"
    })
    (var-set waste-report-id report-id)
    (update-waste-metrics waste-type severity cost)
    (ok report-id)
  )
)

(define-public (update-waste-status (report-id uint) (new-status (string-ascii 20)))
  (begin
    (asserts! (is-some (map-get? waste-reports report-id)) err-not-found)
    (map-set waste-reports report-id
      (merge (unwrap-panic (map-get? waste-reports report-id)) {status: new-status}))
    (ok true)
  )
)

;; Private functions
(define-private (update-waste-metrics (waste-type uint) (severity uint) (cost uint))
  (let ((current-period (/ block-height u1000))
        (current-metrics (default-to {total-instances: u0, total-cost: u0, avg-severity: u0}
                         (map-get? waste-metrics {waste-type: waste-type, period: current-period}))))
    (map-set waste-metrics {waste-type: waste-type, period: current-period} {
      total-instances: (+ (get total-instances current-metrics) u1),
      total-cost: (+ (get total-cost current-metrics) cost),
      avg-severity: (/ (+ (* (get avg-severity current-metrics) (get total-instances current-metrics)) severity)
                      (+ (get total-instances current-metrics) u1))
    })
  )
)

;; Read-only functions
(define-read-only (get-waste-report (report-id uint))
  (map-get? waste-reports report-id)
)

(define-read-only (get-waste-metrics (waste-type uint) (period uint))
  (map-get? waste-metrics {waste-type: waste-type, period: period})
)

(define-read-only (get-current-waste-id)
  (var-get waste-report-id)
)
