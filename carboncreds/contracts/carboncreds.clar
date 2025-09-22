;; Carbon Credits - Decentralized Carbon Offset Marketplace
;; A smart contract for minting, trading, and retiring carbon credits with verification

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-insufficient-balance (err u102))
(define-constant err-invalid-amount (err u103))
(define-constant err-unauthorized (err u104))
(define-constant err-already-retired (err u105))
(define-constant err-invalid-project (err u106))
(define-constant err-transfer-failed (err u107))

;; Data Variables
(define-data-var next-credit-id uint u1)
(define-data-var contract-paused bool false)
(define-data-var verification-fee uint u1000000) ;; 1 STX in microSTX

;; Data Maps
(define-map carbon-credits 
    { credit-id: uint }
    {
        project-id: (string-ascii 64),
        issuer: principal,
        owner: principal,
        amount: uint,
        price-per-ton: uint,
        vintage-year: uint,
        methodology: (string-ascii 128),
        verification-status: (string-ascii 32),
        is-retired: bool,
        retired-by: (optional principal),
        retirement-timestamp: (optional uint),
        created-at: uint
    }
)

(define-map project-registry
    { project-id: (string-ascii 64) }
    {
        name: (string-ascii 256),
        location: (string-ascii 128),
        project-type: (string-ascii 64),
        verifier: principal,
        total-credits-issued: uint,
        is-active: bool,
        created-at: uint
    }
)

(define-map user-balances
    { user: principal, project-id: (string-ascii 64) }
    { balance: uint }
)

(define-map verified-issuers principal bool)
(define-map project-verifiers principal bool)

;; Authorization Functions
(define-private (is-contract-owner)
    (is-eq tx-sender contract-owner)
)

(define-private (is-verified-issuer (issuer principal))
    (default-to false (map-get? verified-issuers issuer))
)

(define-private (is-project-verifier (verifier principal))
    (default-to false (map-get? project-verifiers verifier))
)

;; Admin Functions
(define-public (add-verified-issuer (issuer principal))
    (begin
        (asserts! (is-contract-owner) err-owner-only)
        (ok (map-set verified-issuers issuer true))
    )
)

(define-public (add-project-verifier (verifier principal))
    (begin
        (asserts! (is-contract-owner) err-owner-only)
        (ok (map-set project-verifiers verifier true))
    )
)

(define-public (set-verification-fee (new-fee uint))
    (begin
        (asserts! (is-contract-owner) err-owner-only)
        (ok (var-set verification-fee new-fee))
    )
)

(define-public (pause-contract)
    (begin
        (asserts! (is-contract-owner) err-owner-only)
        (ok (var-set contract-paused true))
    )
)

(define-public (unpause-contract)
    (begin
        (asserts! (is-contract-owner) err-owner-only)
        (ok (var-set contract-paused false))
    )
)

;; Project Registry Functions
(define-public (register-project 
    (project-id (string-ascii 64))
    (name (string-ascii 256))
    (location (string-ascii 128))
    (project-type (string-ascii 64))
    (verifier principal))
    (begin
        (asserts! (not (var-get contract-paused)) err-unauthorized)
        (asserts! (is-verified-issuer tx-sender) err-unauthorized)
        (asserts! (is-project-verifier verifier) err-unauthorized)
        (asserts! (is-none (map-get? project-registry { project-id: project-id })) err-invalid-project)
        
        (ok (map-set project-registry
            { project-id: project-id }
            {
                name: name,
                location: location,
                project-type: project-type,
                verifier: verifier,
                total-credits-issued: u0,
                is-active: true,
                created-at: u0
            }
        ))
    )
)

;; Carbon Credit Functions
(define-public (mint-carbon-credits
    (project-id (string-ascii 64))
    (amount uint)
    (price-per-ton uint)
    (vintage-year uint)
    (methodology (string-ascii 128)))
    (let
        (
            (credit-id (var-get next-credit-id))
            (project-data (unwrap! (map-get? project-registry { project-id: project-id }) err-invalid-project))
        )
        (begin
            (asserts! (not (var-get contract-paused)) err-unauthorized)
            (asserts! (> amount u0) err-invalid-amount)
            (asserts! (is-verified-issuer tx-sender) err-unauthorized)
            (asserts! (get is-active project-data) err-invalid-project)
            
            ;; Update project total credits
            (map-set project-registry
                { project-id: project-id }
                (merge project-data { total-credits-issued: (+ (get total-credits-issued project-data) amount) })
            )
            
            ;; Create carbon credit
            (map-set carbon-credits
                { credit-id: credit-id }
                {
                    project-id: project-id,
                    issuer: tx-sender,
                    owner: tx-sender,
                    amount: amount,
                    price-per-ton: price-per-ton,
                    vintage-year: vintage-year,
                    methodology: methodology,
                    verification-status: "pending",
                    is-retired: false,
                    retired-by: none,
                    retirement-timestamp: none,
                    created-at: u0
                }
            )
            
            ;; Update user balance
            (try! (update-user-balance tx-sender project-id amount true))
            
            ;; Increment credit ID
            (var-set next-credit-id (+ credit-id u1))
            
            (ok credit-id)
        )
    )
)

(define-public (verify-carbon-credit (credit-id uint))
    (let
        (
            (credit-data (unwrap! (map-get? carbon-credits { credit-id: credit-id }) err-not-found))
            (project-data (unwrap! (map-get? project-registry { project-id: (get project-id credit-data) }) err-invalid-project))
        )
        (begin
            (asserts! (not (var-get contract-paused)) err-unauthorized)
            (asserts! (is-eq tx-sender (get verifier project-data)) err-unauthorized)
            (asserts! (is-eq (get verification-status credit-data) "pending") err-unauthorized)
            
            ;; Pay verification fee
            (try! (stx-transfer? (var-get verification-fee) tx-sender contract-owner))
            
            ;; Update verification status
            (ok (map-set carbon-credits
                { credit-id: credit-id }
                (merge credit-data { verification-status: "verified" })
            ))
        )
    )
)

(define-public (transfer-carbon-credits
    (credit-id uint)
    (recipient principal)
    (amount uint))
    (let
        (
            (credit-data (unwrap! (map-get? carbon-credits { credit-id: credit-id }) err-not-found))
            (current-balance (get-user-balance tx-sender (get project-id credit-data)))
        )
        (begin
            (asserts! (not (var-get contract-paused)) err-unauthorized)
            (asserts! (> amount u0) err-invalid-amount)
            (asserts! (is-eq tx-sender (get owner credit-data)) err-unauthorized)
            (asserts! (not (get is-retired credit-data)) err-already-retired)
            (asserts! (is-eq (get verification-status credit-data) "verified") err-unauthorized)
            (asserts! (>= current-balance amount) err-insufficient-balance)
            
            ;; Update balances
            (try! (update-user-balance tx-sender (get project-id credit-data) amount false))
            (try! (update-user-balance recipient (get project-id credit-data) amount true))
            
            ;; If transferring full amount, update owner
            (if (is-eq amount (get amount credit-data))
                (begin
                    (map-set carbon-credits
                        { credit-id: credit-id }
                        (merge credit-data { owner: recipient })
                    )
                    (ok true)
                )
                (ok true)
            )
        )
    )
)

(define-public (retire-carbon-credits
    (credit-id uint)
    (amount uint))
    (let
        (
            (credit-data (unwrap! (map-get? carbon-credits { credit-id: credit-id }) err-not-found))
            (current-balance (get-user-balance tx-sender (get project-id credit-data)))
        )
        (begin
            (asserts! (not (var-get contract-paused)) err-unauthorized)
            (asserts! (> amount u0) err-invalid-amount)
            (asserts! (not (get is-retired credit-data)) err-already-retired)
            (asserts! (is-eq (get verification-status credit-data) "verified") err-unauthorized)
            (asserts! (>= current-balance amount) err-insufficient-balance)
            
            ;; Update user balance (remove credits)
            (try! (update-user-balance tx-sender (get project-id credit-data) amount false))
            
            ;; Mark as retired if full amount
            (if (is-eq amount (get amount credit-data))
                (begin
                    (map-set carbon-credits
                        { credit-id: credit-id }
                        (merge credit-data {
                            is-retired: true,
                            retired-by: (some tx-sender),
                            retirement-timestamp: (some u0)
                        })
                    )
                    (ok true)
                )
                (ok true)
            )
        )
    )
)

;; Helper Functions
(define-private (update-user-balance 
    (user principal) 
    (project-id (string-ascii 64)) 
    (amount uint) 
    (is-add bool))
    (let
        (
            (current-balance (get-user-balance user project-id))
            (new-balance (if is-add 
                (+ current-balance amount)
                (- current-balance amount)
            ))
        )
        (begin
            (asserts! (or is-add (>= current-balance amount)) err-insufficient-balance)
            (ok (map-set user-balances
                { user: user, project-id: project-id }
                { balance: new-balance }
            ))
        )
    )
)

;; Read-Only Functions
(define-read-only (get-carbon-credit (credit-id uint))
    (map-get? carbon-credits { credit-id: credit-id })
)

(define-read-only (get-project-info (project-id (string-ascii 64)))
    (map-get? project-registry { project-id: project-id })
)

(define-read-only (get-user-balance (user principal) (project-id (string-ascii 64)))
    (default-to u0 (get balance (map-get? user-balances { user: user, project-id: project-id })))
)

(define-read-only (get-next-credit-id)
    (var-get next-credit-id)
)

(define-read-only (is-contract-paused)
    (var-get contract-paused)
)

(define-read-only (get-verification-fee)
    (var-get verification-fee)
)

(define-read-only (is-issuer-verified (issuer principal))
    (is-verified-issuer issuer)
)

(define-read-only (is-verifier-authorized (verifier principal))
    (is-project-verifier verifier)
)

;; Enhanced Security: Emergency withdraw function (owner only)
(define-public (emergency-withdraw)
    (begin
        (asserts! (is-contract-owner) err-owner-only)
        (asserts! (var-get contract-paused) err-unauthorized)
        (as-contract (stx-transfer? (stx-get-balance tx-sender) tx-sender contract-owner))
    )
)