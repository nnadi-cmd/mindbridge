;; MindBridge - Decentralized Mental Health Support Platform
;; Empowering communities through transparent mental health funding
;; Built on Stacks blockchain for maximum transparency and trust

;; Error Constants
(define-constant ERR-UNAUTHORIZED-ACCESS (err u100))
(define-constant ERR-SUPPORTER-EXISTS (err u101))
(define-constant ERR-SUPPORTER-NOT-FOUND (err u102))
(define-constant ERR-INSUFFICIENT-VAULT-BALANCE (err u103))
(define-constant ERR-CONTRIBUTION-TOO-SMALL (err u104))
(define-constant ERR-PLATFORM-OFFLINE (err u105))
(define-constant ERR-INVALID-AMOUNT (err u106))
(define-constant ERR-INVALID-SUPPORT-LEVEL (err u107))
(define-constant ERR-INVALID-GUARDIAN-ADDRESS (err u108))
(define-constant ERR-WITHDRAWAL-LIMIT-EXCEEDED (err u109))

;; Core Platform Variables
(define-data-var platform-guardian principal tx-sender)
(define-data-var community-vault-balance uint u0)
(define-data-var platform-operational bool true)
(define-data-var minimum-contribution-threshold uint u1000000) ;; 1 STX
(define-data-var crisis-mode-enabled bool false)
(define-data-var daily-withdrawal-limit uint u10000000) ;; 10 STX per day
(define-data-var total-supporters-count uint u0)

;; Support Recipients Registry
(define-map support-recipients-ledger 
    principal 
    {
        is-verified-recipient: bool,
        total-support-received: uint,
        last-support-timestamp: uint,
        support-tier-level: (string-ascii 20),
        crisis-priority-flag: bool
    }
)

;; Community Contributors Registry
(define-map community-contributors-ledger
    principal
    {
        lifetime-contributions: uint,
        last-contribution-timestamp: uint,
        contributor-tier: (string-ascii 15)
    }
)

;; Daily Withdrawal Tracking
(define-map daily-withdrawal-tracker
    uint ;; day (block-height / 144)
    uint ;; total withdrawn today
)

;; Read-only Platform Information Functions
(define-read-only (get-platform-guardian)
    (var-get platform-guardian)
)

(define-read-only (get-community-vault-balance)
    (var-get community-vault-balance)
)

(define-read-only (get-recipient-profile (recipient-address principal))
    (map-get? support-recipients-ledger recipient-address)
)

(define-read-only (get-contributor-profile (contributor-address principal))
    (map-get? community-contributors-ledger contributor-address)
)

(define-read-only (is-platform-operational)
    (and (var-get platform-operational) (not (var-get crisis-mode-enabled)))
)

(define-read-only (get-platform-statistics)
    {
        total-vault-balance: (var-get community-vault-balance),
        active-supporters: (var-get total-supporters-count),
        minimum-contribution: (var-get minimum-contribution-threshold),
        daily-limit: (var-get daily-withdrawal-limit),
        crisis-mode: (var-get crisis-mode-enabled)
    }
)

;; Private Utility Functions
(define-private (verify-guardian-access)
    (is-eq tx-sender (var-get platform-guardian))
)

(define-private (update-contributor-profile (contributor-address principal) (contribution-amount uint))
    (let (
        (existing-profile (default-to 
            { 
                lifetime-contributions: u0, 
                last-contribution-timestamp: u0,
                contributor-tier: "bronze"
            } 
            (map-get? community-contributors-ledger contributor-address)
        ))
        (new-total (+ (get lifetime-contributions existing-profile) contribution-amount))
        (new-tier (determine-contributor-tier new-total))
    )
    (map-set community-contributors-ledger
        contributor-address
        {
            lifetime-contributions: new-total,
            last-contribution-timestamp: block-height,
            contributor-tier: new-tier
        }
    ))
)

(define-private (determine-contributor-tier (total-contributed uint))
    (if (>= total-contributed u50000000) ;; 50+ STX
        "platinum"
        (if (>= total-contributed u20000000) ;; 20+ STX
            "gold"
            (if (>= total-contributed u5000000) ;; 5+ STX
                "silver"
                "bronze"
            )
        )
    )
)

(define-private (get-current-day)
    (/ block-height u144) ;; Approximate blocks per day
)

(define-private (check-daily-withdrawal-limit (withdrawal-amount uint))
    (let (
        (current-day (get-current-day))
        (today-withdrawn (default-to u0 (map-get? daily-withdrawal-tracker current-day)))
        (proposed-total (+ today-withdrawn withdrawal-amount))
    )
    (<= proposed-total (var-get daily-withdrawal-limit))
    )
)

(define-private (update-daily-withdrawal-tracker (withdrawal-amount uint))
    (let (
        (current-day (get-current-day))
        (today-withdrawn (default-to u0 (map-get? daily-withdrawal-tracker current-day)))
    )
    (map-set daily-withdrawal-tracker
        current-day
        (+ today-withdrawn withdrawal-amount)
    ))
)

;; Validation Functions
(define-private (validate-contribution-amount (amount uint))
    (and 
        (> amount u0)
        (<= amount u1000000000000) ;; Reasonable upper limit
        (>= amount (var-get minimum-contribution-threshold))
    )
)

(define-private (validate-support-tier (tier-level (string-ascii 20)))
    (or 
        (is-eq tier-level "active")
        (is-eq tier-level "priority")
        (is-eq tier-level "crisis")
        (is-eq tier-level "recovering")
        (is-eq tier-level "graduated")
    )
)

(define-private (validate-guardian-address (new-guardian principal))
    (and 
        (not (is-eq new-guardian (var-get platform-guardian)))
        (not (is-eq new-guardian (as-contract tx-sender)))
    )
)

;; Core Platform Functions
(define-public (contribute-to-community-vault)
    (let (
        (contribution-amount (stx-get-balance tx-sender))
    )
    (asserts! (validate-contribution-amount contribution-amount) ERR-CONTRIBUTION-TOO-SMALL)
    (asserts! (is-platform-operational) ERR-PLATFORM-OFFLINE)
    
    (try! (stx-transfer? contribution-amount tx-sender (as-contract tx-sender)))
    (var-set community-vault-balance (+ (var-get community-vault-balance) contribution-amount))
    (update-contributor-profile tx-sender contribution-amount)
    
    ;; Increment supporter count if first-time contributor
    (if (is-none (map-get? community-contributors-ledger tx-sender))
        (var-set total-supporters-count (+ (var-get total-supporters-count) u1))
        true
    )
    
    (ok contribution-amount))
)

(define-public (register-support-recipient (recipient-address principal) (initial-tier (string-ascii 20)))
    (begin
        (asserts! (verify-guardian-access) ERR-UNAUTHORIZED-ACCESS)
        (asserts! (validate-support-tier initial-tier) ERR-INVALID-SUPPORT-LEVEL)
        (asserts! (is-none (map-get? support-recipients-ledger recipient-address)) ERR-SUPPORTER-EXISTS)
        
        (map-set support-recipients-ledger 
            recipient-address
            {
                is-verified-recipient: true,
                total-support-received: u0,
                last-support-timestamp: u0,
                support-tier-level: initial-tier,
                crisis-priority-flag: (is-eq initial-tier "crisis")
            }
        )
        (ok true)
    )
)

(define-public (distribute-support (recipient-address principal) (support-amount uint))
    (begin
        (asserts! (verify-guardian-access) ERR-UNAUTHORIZED-ACCESS)
        (asserts! (is-platform-operational) ERR-PLATFORM-OFFLINE)
        (asserts! (>= (var-get community-vault-balance) support-amount) ERR-INSUFFICIENT-VAULT-BALANCE)
        (asserts! (check-daily-withdrawal-limit support-amount) ERR-WITHDRAWAL-LIMIT-EXCEEDED)
        (asserts! 
            (is-some (map-get? support-recipients-ledger recipient-address)) 
            ERR-SUPPORTER-NOT-FOUND
        )
        
        (try! (as-contract (stx-transfer? support-amount tx-sender recipient-address)))
        (var-set community-vault-balance (- (var-get community-vault-balance) support-amount))
        (update-daily-withdrawal-tracker support-amount)
        
        (let (
            (recipient-profile (unwrap! (map-get? support-recipients-ledger recipient-address) ERR-SUPPORTER-NOT-FOUND))
        )
        (map-set support-recipients-ledger
            recipient-address
            {
                is-verified-recipient: (get is-verified-recipient recipient-profile),
                total-support-received: (+ (get total-support-received recipient-profile) support-amount),
                last-support-timestamp: block-height,
                support-tier-level: (get support-tier-level recipient-profile),
                crisis-priority-flag: (get crisis-priority-flag recipient-profile)
            }
        )
        (ok support-amount))
    )
)

;; Enhanced Management Functions
(define-public (batch-distribute-support (recipients (list 10 {recipient: principal, amount: uint})))
    (begin
        (asserts! (verify-guardian-access) ERR-UNAUTHORIZED-ACCESS)
        (asserts! (is-platform-operational) ERR-PLATFORM-OFFLINE)
        
        (fold batch-distribute-helper recipients (ok u0))
    )
)

(define-private (batch-distribute-helper (recipient-data {recipient: principal, amount: uint}) (previous-result (response uint uint)))
    (match previous-result
        success-value (distribute-support (get recipient recipient-data) (get amount recipient-data))
        error-value (err error-value)
    )
)

(define-public (update-minimum-contribution (new-threshold uint))
    (begin
        (asserts! (verify-guardian-access) ERR-UNAUTHORIZED-ACCESS)
        (asserts! (validate-contribution-amount new-threshold) ERR-INVALID-AMOUNT)
        (var-set minimum-contribution-threshold new-threshold)
        (ok true)
    )
)

(define-public (toggle-platform-status)
    (begin
        (asserts! (verify-guardian-access) ERR-UNAUTHORIZED-ACCESS)
        (var-set platform-operational (not (var-get platform-operational)))
        (ok true)
    )
)

(define-public (activate-crisis-mode)
    (begin
        (asserts! (verify-guardian-access) ERR-UNAUTHORIZED-ACCESS)
        (var-set crisis-mode-enabled true)
        (var-set daily-withdrawal-limit u50000000) ;; Emergency limit: 50 STX
        (ok true)
    )
)

(define-public (deactivate-crisis-mode)
    (begin
        (asserts! (verify-guardian-access) ERR-UNAUTHORIZED-ACCESS)
        (var-set crisis-mode-enabled false)
        (var-set daily-withdrawal-limit u10000000) ;; Normal limit: 10 STX
        (ok true)
    )
)

(define-public (update-recipient-tier (recipient-address principal) (new-tier (string-ascii 20)))
    (begin
        (asserts! (verify-guardian-access) ERR-UNAUTHORIZED-ACCESS)
        (asserts! (validate-support-tier new-tier) ERR-INVALID-SUPPORT-LEVEL)
        (asserts! 
            (is-some (map-get? support-recipients-ledger recipient-address)) 
            ERR-SUPPORTER-NOT-FOUND
        )
        
        (let (
            (current-profile (unwrap! (map-get? support-recipients-ledger recipient-address) ERR-SUPPORTER-NOT-FOUND))
        )
        (map-set support-recipients-ledger
            recipient-address
            {
                is-verified-recipient: (get is-verified-recipient current-profile),
                total-support-received: (get total-support-received current-profile),
                last-support-timestamp: (get last-support-timestamp current-profile),
                support-tier-level: new-tier,
                crisis-priority-flag: (is-eq new-tier "crisis")
            }
        )
        (ok true))
    )
)

(define-public (transfer-guardianship (new-guardian-address principal))
    (begin
        (asserts! (verify-guardian-access) ERR-UNAUTHORIZED-ACCESS)
        (asserts! (validate-guardian-address new-guardian-address) ERR-INVALID-GUARDIAN-ADDRESS)
        (var-set platform-guardian new-guardian-address)
        (ok true)
    )
)

(define-public (set-daily-withdrawal-limit (new-limit uint))
    (begin
        (asserts! (verify-guardian-access) ERR-UNAUTHORIZED-ACCESS)
        (asserts! (and (> new-limit u0) (<= new-limit u100000000)) ERR-INVALID-AMOUNT)
        (var-set daily-withdrawal-limit new-limit)
        (ok true)
    )
)