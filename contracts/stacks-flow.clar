;; Title: StacksFlow - Bidirectional Payment Channels
;; Summary: Layer 2 scaling solution enabling instant, low-cost STX transactions
;; Description: A sophisticated payment channel implementation that allows two parties
;;              to conduct multiple off-chain transactions with on-chain settlement.
;;              Features include cooperative and unilateral channel closure,
;;              dispute resolution mechanisms, and comprehensive state management.
;;              Designed for Stacks Layer 2 compliance with robust security measures.

;; CONSTANTS & CONFIGURATION

(define-constant CONTRACT-OWNER tx-sender)
(define-constant DISPUTE-TIMEOUT u1008) ;; ~1 week in blocks (assuming 10min blocks)
(define-constant MAX-BALANCE u340282366920938463463374607431768211455) ;; Max uint value

;; ERROR CODES

(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-CHANNEL-EXISTS (err u101))
(define-constant ERR-CHANNEL-NOT-FOUND (err u102))
(define-constant ERR-INSUFFICIENT-FUNDS (err u103))
(define-constant ERR-INVALID-SIGNATURE (err u104))
(define-constant ERR-CHANNEL-CLOSED (err u105))
(define-constant ERR-DISPUTE-PERIOD (err u106))
(define-constant ERR-INVALID-INPUT (err u107))
(define-constant ERR-BALANCE-OVERFLOW (err u108))

;; DATA STRUCTURES

;; Primary storage for payment channel state
(define-map payment-channels
  {
    channel-id: (buff 32), ;; Unique channel identifier (SHA256 hash)
    participant-a: principal, ;; Channel initiator address
    participant-b: principal, ;; Counterparty address
  }
  {
    total-deposited: uint, ;; Total STX locked in channel
    balance-a: uint, ;; Current balance for participant A
    balance-b: uint, ;; Current balance for participant B
    is-open: bool, ;; Channel operational status
    dispute-deadline: uint, ;; Block height deadline for disputes
    nonce: uint, ;; State version for replay protection
  }
)

;; INPUT VALIDATION FUNCTIONS

(define-private (is-valid-channel-id (channel-id (buff 32)))
  ;; Validates channel ID format and length
  (and
    (> (len channel-id) u0)
    (<= (len channel-id) u32)
  )
)

(define-private (is-valid-deposit (amount uint))
  ;; Ensures deposit amount is greater than zero
  (> amount u0)
)

(define-private (is-valid-signature (signature (buff 65)))
  ;; Validates signature format and length
  (and
    (is-eq (len signature) u65)
    true
  )
)

(define-private (is-valid-balance (balance uint))
  ;; Validates that balance is within acceptable range
  (and
    (>= balance u0)
    (<= balance MAX-BALANCE)
  )
)