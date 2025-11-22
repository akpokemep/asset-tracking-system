;; PalletTrace - Decentralized Pallet and Asset Tracking
;; Track pallets, containers, and equipment across warehouses

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u400))
(define-constant err-not-found (err u401))
(define-constant err-invalid-state (err u402))
(define-constant err-unauthorized (err u403))
(define-constant err-already-assigned (err u404))

;; Data Variables
(define-data-var asset-counter uint u0)
(define-data-var location-counter uint u0)
(define-data-var transfer-counter uint u0)

;; Data Maps
(define-map assets
    { asset-id: uint }
    {
        asset-type: (string-ascii 20),
        barcode: (string-ascii 50),
        current-location: uint,
        status: (string-ascii 20),
        assigned-to: (optional principal),
        created-at: uint,
        last-maintenance: uint
    }
)

(define-map locations
    { location-id: uint }
    {
        name: (string-ascii 100),
        location-type: (string-ascii 30),
        capacity: uint,
        current-count: uint,
        manager: principal
    }
)

(define-map asset-transfers
    { transfer-id: uint }
    {
        asset-id: uint,
        from-location: uint,
        to-location: uint,
        transferred-by: principal,
        transfer-date: uint,
        reason: (string-ascii 200),
        approved: bool
    }
)

(define-map asset-maintenance
    { asset-id: uint, maintenance-date: uint }
    {
        maintenance-type: (string-ascii 50),
        performed-by: principal,
        notes: (string-ascii 300),
        next-due: uint
    }
)

;; Public Functions

(define-public (register-location 
    (name (string-ascii 100))
    (location-type (string-ascii 30))
    (capacity uint)
    (manager principal))
    (let
        (
            (location-id (+ (var-get location-counter) u1))
        )
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (map-set locations
            { location-id: location-id }
            {
                name: name,
                location-type: location-type,
                capacity: capacity,
                current-count: u0,
                manager: manager
            }
        )
        (var-set location-counter location-id)
        (ok location-id)
    )
)

(define-public (register-asset
    (asset-type (string-ascii 20))
    (barcode (string-ascii 50))
    (initial-location uint))
    (let
        (
            (asset-id (+ (var-get asset-counter) u1))
            (location-data (unwrap! (map-get? locations { location-id: initial-location }) err-not-found))
        )
        (asserts! (< (get current-count location-data) (get capacity location-data)) err-invalid-state)
        (map-set assets
            { asset-id: asset-id }
            {
                asset-type: asset-type,
                barcode: barcode,
                current-location: initial-location,
                status: "AVAILABLE",
                assigned-to: none,
                created-at: stacks-block-height,
                last-maintenance: stacks-block-height
            }
        )
        (map-set locations
            { location-id: initial-location }
            (merge location-data { current-count: (+ (get current-count location-data) u1) })
        )
        (var-set asset-counter asset-id)
        (ok asset-id)
    )
)

(define-public (transfer-asset
    (asset-id uint)
    (to-location uint)
    (reason (string-ascii 200)))
    (let
        (
            (asset-data (unwrap! (map-get? assets { asset-id: asset-id }) err-not-found))
            (from-location (get current-location asset-data))
            (from-location-data (unwrap! (map-get? locations { location-id: from-location }) err-not-found))
            (to-location-data (unwrap! (map-get? locations { location-id: to-location }) err-not-found))
            (transfer-id (+ (var-get transfer-counter) u1))
        )
        (asserts! (< (get current-count to-location-data) (get capacity to-location-data)) err-invalid-state)
        (asserts! (or (is-eq tx-sender contract-owner)
                     (is-eq tx-sender (get manager from-location-data))
                     (is-eq tx-sender (get manager to-location-data))) err-unauthorized)
        
        ;; Update asset location
        (map-set assets
            { asset-id: asset-id }
            (merge asset-data { current-location: to-location })
        )
        
        ;; Update location counts
        (map-set locations
            { location-id: from-location }
            (merge from-location-data { current-count: (- (get current-count from-location-data) u1) })
        )
        (map-set locations
            { location-id: to-location }
            (merge to-location-data { current-count: (+ (get current-count to-location-data) u1) })
        )
        
        ;; Record transfer
        (map-set asset-transfers
            { transfer-id: transfer-id }
            {
                asset-id: asset-id,
                from-location: from-location,
                to-location: to-location,
                transferred-by: tx-sender,
                transfer-date: stacks-block-height,
                reason: reason,
                approved: true
            }
        )
        (var-set transfer-counter transfer-id)
        (ok transfer-id)
    )
)

(define-public (assign-asset (asset-id uint) (assignee principal))
    (let
        (
            (asset-data (unwrap! (map-get? assets { asset-id: asset-id }) err-not-found))
        )
        (asserts! (is-none (get assigned-to asset-data)) err-already-assigned)
        (asserts! (is-eq (get status asset-data) "AVAILABLE") err-invalid-state)
        (map-set assets
            { asset-id: asset-id }
            (merge asset-data { 
                assigned-to: (some assignee),
                status: "ASSIGNED"
            })
        )
        (ok true)
    )
)

(define-public (release-asset (asset-id uint))
    (let
        (
            (asset-data (unwrap! (map-get? assets { asset-id: asset-id }) err-not-found))
        )
        (asserts! (or (is-eq tx-sender contract-owner)
                     (is-eq (some tx-sender) (get assigned-to asset-data))) err-unauthorized)
        (map-set assets
            { asset-id: asset-id }
            (merge asset-data { 
                assigned-to: none,
                status: "AVAILABLE"
            })
        )
        (ok true)
    )
)

(define-public (record-maintenance
    (asset-id uint)
    (maintenance-type (string-ascii 50))
    (notes (string-ascii 300))
    (next-due uint))
    (let
        (
            (asset-data (unwrap! (map-get? assets { asset-id: asset-id }) err-not-found))
        )
        (map-set asset-maintenance
            { asset-id: asset-id, maintenance-date: stacks-block-height }
            {
                maintenance-type: maintenance-type,
                performed-by: tx-sender,
                notes: notes,
                next-due: next-due
            }
        )
        (map-set assets
            { asset-id: asset-id }
            (merge asset-data { last-maintenance: stacks-block-height })
        )
        (ok true)
    )
)

;; Read Only Functions

(define-read-only (get-asset (asset-id uint))
    (map-get? assets { asset-id: asset-id })
)

(define-read-only (get-location (location-id uint))
    (map-get? locations { location-id: location-id })
)

(define-read-only (get-transfer (transfer-id uint))
    (map-get? asset-transfers { transfer-id: transfer-id })
)

(define-read-only (get-maintenance-record (asset-id uint) (maintenance-date uint))
    (map-get? asset-maintenance { asset-id: asset-id, maintenance-date: maintenance-date })
)

(define-read-only (get-asset-count)
    (var-get asset-counter)
)

(define-read-only (is-location-full (location-id uint))
    (match (map-get? locations { location-id: location-id })
        location-data (>= (get current-count location-data) (get capacity location-data))
        true
    )
)

(define-read-only (is-asset-available (asset-id uint))
    (match (map-get? assets { asset-id: asset-id })
        asset-data (and 
            (is-eq (get status asset-data) "AVAILABLE")
            (is-none (get assigned-to asset-data))
        )
        false
    )
)