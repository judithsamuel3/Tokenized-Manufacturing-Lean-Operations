;; Operations Manager Verification Contract
;; Manages verification and authorization of manufacturing operations managers

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-unauthorized (err u103))

;; Data structures
(define-map operations-managers principal {
  name: (string-ascii 50),
  department: (string-ascii 30),
  certification-level: uint,
  verified: bool,
  registered-at: uint
})

(define-map manager-permissions principal {
  can-identify-waste: bool,
  can-optimize-process: bool,
  can-measure-efficiency: bool,
  can-manage-improvements: bool
})

;; Public functions
(define-public (register-manager (manager principal) (name (string-ascii 50)) (department (string-ascii 30)) (cert-level uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (is-none (map-get? operations-managers manager)) err-already-exists)
    (map-set operations-managers manager {
      name: name,
      department: department,
      certification-level: cert-level,
      verified: false,
      registered-at: block-height
    })
    (ok true)
  )
)

(define-public (verify-manager (manager principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (is-some (map-get? operations-managers manager)) err-not-found)
    (map-set operations-managers manager
      (merge (unwrap-panic (map-get? operations-managers manager)) {verified: true}))
    (ok true)
  )
)

(define-public (set-permissions (manager principal) (waste bool) (optimize bool) (measure bool) (improve bool))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (is-some (map-get? operations-managers manager)) err-not-found)
    (map-set manager-permissions manager {
      can-identify-waste: waste,
      can-optimize-process: optimize,
      can-measure-efficiency: measure,
      can-manage-improvements: improve
    })
    (ok true)
  )
)

;; Read-only functions
(define-read-only (get-manager-info (manager principal))
  (map-get? operations-managers manager)
)

(define-read-only (get-manager-permissions (manager principal))
  (map-get? manager-permissions manager)
)

(define-read-only (is-verified-manager (manager principal))
  (match (map-get? operations-managers manager)
    manager-data (get verified manager-data)
    false
  )
)
