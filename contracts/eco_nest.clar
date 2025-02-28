;; Define token for rewarding contributions
(define-fungible-token eco-token)

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-found (err u404))
(define-constant err-unauthorized (err u401))
(define-constant err-invalid-category (err u100))

;; Data variables
(define-data-var tip-count uint u0)
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

;; Categories: 1=Energy, 2=Water, 3=Waste, 4=Food, 5=Transport
(define-private (is-valid-category (category uint))
  (<= category u5)
)

;; Post new tip
(define-public (post-tip (title (string-ascii 100)) (content (string-utf8 1000)) (category uint))
  (let
    (
      (tip-id (+ (var-get tip-count) u1))
    )
    (if (is-valid-category category)
      (begin
        (map-set tips tip-id {
          author: tx-sender,
          title: title,
          content: content,
          category: category,
          votes: 0,
          created-at: block-height
        })
        (var-set tip-count tip-id)
        (try! (ft-mint? eco-token u10 tx-sender))
        (ok tip-id)
      )
      err-invalid-category
    )
  )
)

;; Vote on tip
(define-public (vote-tip (tip-id uint) (upvote bool))
  (let
    (
      (tip (unwrap! (map-get? tips tip-id) err-not-found))
      (vote-key { user: tx-sender, tip-id: tip-id })
    )
    (if (is-none (map-get? user-votes vote-key))
      (begin
        (map-set user-votes vote-key true)
        (map-set tips tip-id (merge tip {
          votes: (if upvote 
            (+ (get votes tip) 1)
            (- (get votes tip) 1)
          )
        }))
        (ok true)
      )
      err-unauthorized
    )
  )
)

;; Read-only functions
(define-read-only (get-tip (tip-id uint))
  (ok (map-get? tips tip-id))
)

(define-read-only (get-tips-by-category (category uint))
  (if (is-valid-category category)
    (ok (filter tips (lambda (tip) (= (get category tip) category))))
    err-invalid-category
  )
)
