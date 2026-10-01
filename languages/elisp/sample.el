;;; sample.el --- Warehouse stock helpers  -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Acme Inc.
;; Author: Acme Dev <dev@example.com>
;; Version: 1.0.0
;; Package-Requires: ((emacs "28.1") (dash "2.19"))
;; Keywords: convenience, tools
;; URL: https://example.com/warehouse-el

;;; Commentary:

;; Opens today's stock note, counts reorder items and shows every
;; syntactic category of Emacs Lisp for the highlighter.
;; TODO: persist the bins.  FIXME: handle negative quantities.

;;; Code:

;; ── Requires ──
(require 'cl-lib)
(require 'subr-x)
(require 'json)
(eval-when-compile (require 'rx))
(declare-function org-element-parse-buffer "org-element")
(defvar org-directory)

;; ── Customisation ──
(defgroup warehouse nil
  "Warehouse stock helpers."
  :group 'convenience
  :prefix "warehouse-")

(defcustom warehouse-directory (expand-file-name "~/stock/")
  "Where the stock notes live."
  :type 'directory
  :safe #'stringp
  :group 'warehouse)

(defcustom warehouse-reorder-point 25
  "Quantity at or below which an item is reordered."
  :type '(choice (integer :tag "Number") (const :tag "Never" nil)))

(defface warehouse-low-face
  '((t :inherit warning :weight bold))
  "Face for low stock."
  :group 'warehouse)

(defvar warehouse--cache (make-hash-table :test 'equal)
  "Internal cache of bins.")
(defvar-local warehouse--buffer-bin nil)
(defconst warehouse-version "1.0.0")
(defconst warehouse-bins '(north south east west))

;; ── Literals ──
(defvar warehouse--literals
  (list 42 -17 +5 3.14 -2.5e10 6.02e+23 1.0e-5 .5 1.
        #xFF #o755 #b1010 #24r1k
        0.0e+NaN 1.0e+INF -1.0e+INF
        ?a ?\n ?\t ?\C-x ?\M-x ?\^I ?\x41 ?é ?\N{LATIN SMALL LETTER E WITH ACUTE}
        "Warehouse \"north\"\t\n"
        "multi-line
string with \\ backslash and \x41 hex and é unicode"
        t nil
        'symbol :keyword &optional &rest 'quoted-symbol
        '(1 2 . 3) [1 2 3] #s(hash-table) ?\s
        #'car #'(lambda (x) x)
        `(backquote ,unquote ,@splice)
        #1=(a b #1#)
        #("propertized" 0 5 (face bold))))

;; ── Functions ──
(defun warehouse--path (&optional time)
  "Return the stock note path for TIME (default now).
\\[universal-argument] is documented via a key substitution.
See also `warehouse-open' and URL `https://example.com'."
  (expand-file-name (format-time-string "%Y-%m-%d.org" time)
                    warehouse-directory))

(defun warehouse-total (items &rest rest)
  "Sum ITEMS quantities; REST is ignored."
  (declare (pure t) (side-effect-free t) (indent 1))
  (cl-loop for item in items
           sum (alist-get 'qty item 0) into total
           finally return total))

(cl-defun warehouse-find (sku &key (bins warehouse-bins) test)
  "Find SKU in BINS with TEST."
  (cl-find sku bins :test (or test #'equal)))

(cl-defstruct (warehouse-item (:constructor warehouse-item-create)
                              (:copier nil))
  sku (qty 0 :type integer) price)

(cl-defgeneric warehouse-describe (thing)
  "Describe THING.")
(cl-defmethod warehouse-describe ((item warehouse-item))
  (format "%s x%d" (warehouse-item-sku item) (warehouse-item-qty item)))
(cl-defmethod warehouse-describe ((n integer)) (number-to-string n))

(defmacro warehouse-with-bin (bin &rest body)
  "Run BODY with BIN current."
  (declare (indent 1) (debug (form body)))
  `(let ((warehouse--buffer-bin ,bin))
     ,@body))

(defsubst warehouse--low-p (qty)
  (<= qty (or warehouse-reorder-point 0)))

(define-inline warehouse--twice (x) (inline-quote (* 2 ,x)))
(defalias 'warehouse-total-alias #'warehouse-total "Alias.")
(define-obsolete-function-alias 'warehouse-old #'warehouse-total "1.0")
(make-obsolete-variable 'warehouse-dir 'warehouse-directory "1.0")

;; ── Control flow ──
(defun warehouse-count-todos ()
  "Count TODO headings in the current buffer."
  (interactive)
  (let ((count 0)
        (re (rx bol (+ "*") " TODO ")))
    (save-excursion
      (goto-char (point-min))
      (while (re-search-forward "^\\*+ TODO " nil t)
        (setq count (1+ count))))
    (when (called-interactively-p 'interactive)
      (message "%d TODO item%s" count (if (= count 1) "" "s")))
    count))

(defun warehouse-classify (qty)
  (cond ((null qty) 'unknown)
        ((zerop qty) 'out)
        ((< qty 5) 'low)
        ((and (>= qty 5) (not (> qty 1000))) 'ok)
        (t 'bulk)))

(defun warehouse-flow (items)
  (let* ((n (length items))
         (first (car items))
         (rest (cdr items)))
    (if (> n 3) 'many 'few)
    (unless (null items) (message "has items"))
    (pcase first
      (`(,sku . ,qty) (message "%s %s" sku qty))
      ((and (pred stringp) s) s)
      ('nil nil)
      (_ nil))
    (pcase-let ((`(,a ,b) '(1 2))) (+ a b))
    (cl-case n (0 'zero) ((1 2) 'few) (otherwise 'many))
    (dolist (item rest) (princ item))
    (dotimes (i 3) (princ i))
    (catch 'done
      (cl-loop for x in items
               when (eq x 'stop) do (throw 'done x)
               collect x))
    (condition-case err
        (signal 'wrong-type-argument (list 'integerp "x"))
      (wrong-type-argument (message "bad: %S" err))
      (error (message "error"))
      (:success (message "ok")))
    (unwind-protect
        (ignore-errors (error "boom %s" "now"))
      (message "cleanup"))
    (with-current-buffer (get-buffer-create "*stock*")
      (erase-buffer)
      (insert (format "%s\n" first)))
    (let ((fn (lambda (x &optional y) (+ x (or y 0)))))
      (funcall fn 1 2)
      (apply fn '(1 2))
      (mapcar fn '(1 2 3)))
    (thread-first 5 (+ 1) (* 2))
    (thread-last '(1 2 3) (mapcar #'1+) (apply #'+))
    (and-let* ((x (car items)) ((stringp x))) x)
    (when-let ((x (car items))) x)
    (if-let ((x (car items))) x 'none)
    (pcase-dolist (`(,k . ,v) '((a . 1))) (message "%s %s" k v))
    (named-let loop ((i 0)) (when (< i 3) (loop (1+ i))))))

;; ── Hooks, keymaps, modes ──
(defvar warehouse-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c w o") #'warehouse-open)
    (define-key map [remap save-buffer] #'warehouse-save)
    (keymap-set map "C-c w c" #'warehouse-count-todos)
    map))

(define-minor-mode warehouse-mode
  "Minor mode for stock buffers."
  :lighter " Stock"
  :keymap warehouse-mode-map
  (if warehouse-mode
      (add-hook 'before-save-hook #'warehouse--tidy nil t)
    (remove-hook 'before-save-hook #'warehouse--tidy t)))

(define-derived-mode warehouse-view-mode special-mode "Stock"
  "Major mode for viewing stock."
  (setq-local truncate-lines t))

(add-to-list 'auto-mode-alist '("\\.stock\\'" . warehouse-view-mode))
(add-hook 'find-file-hook (lambda () (when (string-match-p "stock" buffer-file-name) (warehouse-mode 1))))
(advice-add 'save-buffer :after #'warehouse--tidy)
(with-eval-after-load 'org (setq org-directory warehouse-directory))
(setq-default fill-column 80)
(setq warehouse-reorder-point 30
      warehouse--cache (make-hash-table :test 'equal))
(let ((inhibit-message t)) (message "silent"))
(cl-incf (gethash 'a warehouse--cache 0))
(push 'x warehouse-bins)
(pop warehouse-bins)

;;;###autoload
(defun warehouse-open ()
  "Open today's stock note, creating it if needed."
  (interactive)
  (find-file (warehouse--path)))

(defun warehouse--tidy (&rest _) (delete-trailing-whitespace))
(defun warehouse-save () (interactive) (save-buffer))

;; ── Further constructs ──
;; Reader syntax and special forms
(defvar warehouse--reader
  (list ?\C-\M-a ?\S-a ?\H-a ?\s-a ?\A-a ?\d ?\e ?\r ?\a ?\b ?\f ?\v ?\\ ?\( ?\) ?\" ?\' ?\;
        ?\x1F ?\000 ?\377 ?\U0001F4E6
        "\C-a \M-a \^@ \d \e \a \b \f \v \\ \" \012 \x41\ B"
        "ignored\
newline"
        #b-101 #o-17 #xdead #x-1F #36rZ 1e3 -1.0e-3 +.5 1.5e+3 123. 0.5
        '#:uninterned #:foo '(a . (b . (c)))
        '(quote x) ''x '#'car '`(a ,b ,@c)
        [vector (nested vector) "str" ?c 1.5]
        (symbol-with\ space symbol\;semi \,comma 1+ 1- foo-bar/baz *special* <=> &rest)))

;; Special forms and macros
(defun warehouse--special-forms (x)
  (declare (indent defun) (obsolete nil "1.0") (interactive-only t) (important-return-value t))
  (interactive "p\nsPrompt: ")
  (interactive (list (read-string "Sku: ") current-prefix-arg))
  (save-restriction (widen) (narrow-to-region 1 2))
  (save-match-data (looking-at "a"))
  (save-current-buffer (set-buffer (current-buffer)))
  (with-temp-buffer (insert "x") (buffer-string))
  (with-output-to-string (princ "x"))
  (with-demoted-errors "Error: %S" (error "x"))
  (with-local-quit (sit-for 0))
  (with-silent-modifications (put-text-property 1 2 'face 'bold))
  (with-suppressed-warnings ((obsolete foo)) (foo))
  (with-no-warnings (foo))
  (with-timeout (1 (message "timeout")) (sleep-for 0.1))
  (cl-flet ((helper (y) (* y 2))) (helper x))
  (cl-labels ((fact (n) (if (<= n 1) 1 (* n (fact (1- n)))))) (fact 5))
  (cl-macrolet ((twice (z) `(* 2 ,z))) (twice x))
  (cl-letf (((symbol-function 'foo) #'ignore)) (foo))
  (cl-destructuring-bind (a b &optional c &key d) '(1 2 3 :d 4) (list a b c d))
  (cl-multiple-value-bind (q r) (cl-floor 7 2) (list q r))
  (cl-block done (cl-return-from done 1))
  (cl-do ((i 0 (1+ i))) ((= i 3)) (princ i))
  (cl-loop for i from 1 to 10 by 2 for j in '(a b c) for k across [1 2] for (a . b) in '((1 . 2))
           when (cl-evenp i) collect i into evens
           else if (cl-oddp i) sum i into odds
           and append (list i)
           until (> i 8) while (< i 9) repeat 3
           with acc = nil do (push i acc) finally return (list evens odds acc))
  (cl-assert (> x 0) t "positive")
  (cl-check-type x integer)
  (cl-typep x 'integer)
  (cl-case x (1 'one) (t 'other))
  (cl-ecase x (1 'one))
  (cl-typecase x (integer 'int) (string 'str) (t nil))
  (cl-remove-if-not #'cl-evenp '(1 2 3 4))
  (cl-reduce #'+ '(1 2 3) :initial-value 0)
  (cl-find-if (lambda (v) (> v 1)) '(1 2 3))
  (cl-position 2 '(1 2 3))
  (cl-sort (list 3 1 2) #'<)
  (cl-subseq [1 2 3] 1)
  (seq-filter #'cl-evenp '(1 2 3)) (seq-map #'1+ '(1 2)) (seq-reduce #'+ '(1 2) 0)
  (map-elt '((a . 1)) 'a) (map-put! (list) 'a 1) (map-keys '((a . 1)))
  (string-join '("a" "b") ",") (string-trim "  a ") (string-prefix-p "a" "ab") (string-empty-p "")
  (when-let* ((a 1) (b 2)) (+ a b))
  (while-let ((x (pop items))) (princ x))
  (ert-deftest warehouse-test () (should (= 1 1)) (should-not nil) (should-error (error "x")))
  (rx (seq bol (or "a" "b") (+ digit) (? "x") (* space) (group (any "a-z")) eol))
  (rx-define sku (seq upper "-" (= 3 digit)))
  (regexp-opt '("foo" "bar") 'words)
  (propertize "text" 'face 'bold 'help-echo "tip")
  (add-face-text-property 0 4 'italic nil "text")
  (make-overlay 1 2) (overlay-put (make-overlay 1 2) 'face 'highlight)
  (run-with-timer 1 nil #'ignore) (run-at-time "10 sec" nil #'ignore) (run-with-idle-timer 5 t #'ignore)
  (make-process :name "p" :command '("ls") :filter #'ignore :sentinel #'ignore)
  (call-process "ls" nil nil nil "-l") (shell-command-to-string "echo hi")
  (url-retrieve-synchronously "https://example.com") (json-parse-string "{\"a\": 1}") (json-encode '((a . 1)))
  (format "%-10s|%5d|%05.2f|%x|%o|%c|%S|%%" "a" 1 2.5 255 8 ?a 'sym)
  (format-message "`%s' quoted" "x") (message nil) (user-error "no") (error "fatal %s" "x")
  (setq-local fill-column 70) (defvar-keymap warehouse-map :doc "Map." "C-c w" #'warehouse-open)
  (define-key global-map [f5] #'warehouse-open) (global-set-key (kbd "<f6>") #'ignore) (local-set-key "\C-cw" #'ignore)
  (use-package warehouse :ensure t :defer t :after org :hook (org-mode . warehouse-mode)
    :bind (("C-c w" . warehouse-open)) :custom (warehouse-reorder-point 30) :config (message "loaded") :init (setq x 1))
  (setf (alist-get 'a alist) 1) (setf (car x) 1) (cl-pushnew 'a lst) (add-to-list 'load-path "~/lisp") (cl-incf n) (cl-decf n)
  (defvar-local warehouse--local nil) (setq-default indent-tabs-mode nil) (make-local-variable 'x) (kill-local-variable 'x)
  (funcall #'identity x) (apply #'+ 1 2 '(3)) (mapc #'ignore '(1)) (mapconcat #'identity '("a" "b") ",") (mapcan #'list '(1 2)) (seq-do #'ignore [1])
  (or (and x (not x)) (eq x 'a) (eql x 1) (equal x "a") (string= x "a") (string< "a" "b") (/= 1 2) (>= 1 1))
  (let ((n 0)) (cl-incf n) (prog1 n (setq n 5)) (prog2 1 2 3) (progn 1 2))
  (provide-theme 'x)) 

(defconst warehouse--unicode "Café 日本語 📦 \u00e9 \U0001F4E6 \N{WHITE HEAVY CHECK MARK}")
(defvar warehouse--docstring "Docstring with `quoted-symbol', \\=`escaped, \\[command-name], \\{keymap-name} and \\<keymap-name> markers.")
(defvar warehouse--cl-struct (cl-defstruct (point3 (:constructor make-point3 (x y z))) x y z))
(oclosure-define warehouse-oc slot)
(cl-defmethod warehouse-describe :around ((n integer)) (cl-call-next-method))
(cl-defmethod warehouse-describe :before (x &context (major-mode org-mode)) nil)
(cl-defmethod warehouse-describe ((_x (eql 'special))) "special")
(cl-defmethod warehouse-describe ((x (head foo))) x)
(define-advice save-buffer (:around (orig &rest args) warehouse-advice) (apply orig args))
(define-globalized-minor-mode global-warehouse-mode warehouse-mode warehouse-mode)
(define-generic-mode warehouse-generic-mode '("#") '("if") nil '("\\.wh\\'") nil)
(define-error 'warehouse-error "Warehouse error" 'error)
(define-abbrev-table 'warehouse-abbrevs '(("whs" "warehouse")))
(define-widget 'warehouse-widget 'item "Widget.")
(define-compilation-mode warehouse-compilation-mode "Stock" nil)
(easy-menu-define warehouse-menu warehouse-mode-map "Menu." '("Stock" ["Open" warehouse-open t]))
(declare-function warehouse-open "sample")
(eval-and-compile (defvar warehouse--compile-time 1))
(eval-after-load 'org '(message "org loaded"))
(autoload 'warehouse-open "sample" "Open." t)
(unless (fboundp 'warehouse-open) (message "missing"))
(when (and (boundp 'x) (featurep 'org) (derived-mode-p 'text-mode) (bound-and-true-p warehouse-mode)) nil)
(if (version< emacs-version "28.1") (error "old") (message "ok"))
(when noninteractive (kill-emacs 0))

(provide 'sample)
;;; sample.el ends here
