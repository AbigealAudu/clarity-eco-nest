;; Define token for rewarding contributions
(define-fungible-token eco-token)

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-found (err u404))
(define-constant err-unauthorized (err u401))
(define-constant err-invalid-category (err u100))
(define-constant err-empty-content (err u101))
(define-constant err-rate-limit (err u102))

;; Data variables
(define-data-var tip-count uint u0)
(define-data-var total-supply uint u0)

(define-map tips 
  uint 
  {
    author: principal,
    title: (string-ascii 100),
    content: (string-utf8 1000),
    category: uint,
    votes: int,
    created-at: uint
  }
)

(define-map user-votes
  { user: principal, tip-id: uint }
  bool
)

(define-map user-post-times
  principal
  uint
)

;; Categories: 1=Energy, 2=Water, 3=Waste, 4=Food, 5=Transport
(define-private (is-valid-category (category uint))
  (<= category u5)
)

(define-private (is-valid-content (content (string-utf8 1000)))
  (> (len content) u0)
)

(define-private (can-post-tip (user principal))
  (let (
    (last-post-time (default-to u0 (map-get? user-post-times user)))
  )
    (> (- block-height last-post-time) u10)
  )
)

;; Post new tip
(define-public (post-tip (title (string-ascii 100)) (content (string-utf8 1000)) (category uint))
  (let
    (
      (tip-id (+ (var-get tip-count) u1))
    )
    (asserts! (is-valid-category category) err-invalid-category)
    (asserts! (is-valid-content content) err-empty-content)
    (asserts! (can-post-tip tx-sender) err-rate-limit)
    
    (map-set tips tip-id {
      author: tx-sender,
      title: title,
      content: content,
      category: category,
      votes: 0,
      created-at: block-height
    })
    (var-set tip-count tip-id)
    (map-set user-post-times tx-sender block-height)
    (var-set total-supply (+ (var-get total-supply) u10))
    (try! (ft-mint? eco-token u10 tx-sender))
    (ok tip-id)
  )
)

;; Vote on tip
(define-public (vote-tip (tip-id uint) (upvote bool))
  (let
    (
      (tip (unwrap! (map-get? tips tip-id) err-not-found))
      (vote-key { user: tx-sender, tip-id: tip-id })
    )
    (asserts! (is-none (map-get? user-votes vote-key)) err-unauthorized)
    (map-set user-votes vote-key true)
    (map-set tips tip-id (merge tip {
      votes: (if upvote 
        (+ (get votes tip) 1)
        (- (get votes tip) 1)
      )
    }))
    (ok true)
  )
)

;; Read-only functions
(define-read-only (get-tip (tip-id uint))
  (ok (map-get? tips tip-id))
)

(define-read-only (get-tips-by-category (category uint) (limit uint) (offset uint))
  (begin
    (asserts! (is-valid-category category) err-invalid-category)
    (ok (filter tips (lambda (tip) (= (get category tip) category))))
  )
)

(define-read-only (get-total-supply)
  (ok (var-get total-supply))
)
