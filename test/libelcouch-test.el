;;; libelcouch-test.el --- Tests for libelcouch.el   -*- lexical-binding: t; -*-

;; Copyright (C) 2018  Damien Cassou

;; Author: Damien Cassou <damien@cassou.me>

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;;

;;; Code:
(require 'ert)

(require 'libelcouch)


;;; Accessors

(ert-deftest libelcouch-entity-name ()
  (let* ((instance (libelcouch--instance-create :name "Instance"))
         (database (libelcouch--database-create :name "Database" :parent instance))
         (document (libelcouch--document-create :name "Document" :parent database)))
    (should (equal (libelcouch-entity-name instance) "Instance"))
    (should (equal (libelcouch-entity-name database) "Database"))
    (should (equal (libelcouch-entity-name document) "Document"))))

(ert-deftest libelcouch-entity-parent ()
  (let* ((instance (libelcouch--instance-create :name "Instance"))
         (database (libelcouch--database-create :name "Database" :parent instance))
         (document (libelcouch--document-create :name "Document" :parent database)))
    (should (eq (libelcouch-entity-parent database) instance))
    (should (equal (libelcouch-entity-parent document) database))))

(ert-deftest libelcouch-entity-instance ()
  (let* ((instance (libelcouch--instance-create :name "Instance"))
         (database (libelcouch--database-create :name "Database" :parent instance))
         (document (libelcouch--document-create :name "Document" :parent database)))
    (should (eq (libelcouch-entity-instance instance) instance))
    (should (eq (libelcouch-entity-instance database) instance))
    (should (eq (libelcouch-entity-instance document) instance))))

(ert-deftest libelcouch-entity-url ()
  (let* ((instance (libelcouch--instance-create :url "http://localhost:5984"))
         (database (libelcouch--database-create :name "Database" :parent instance))
         (document (libelcouch--document-create :name "Document" :parent database)))
    (should (equal (libelcouch-entity-url instance) "http://localhost:5984"))
    (should (equal (libelcouch-entity-url database) "http://localhost:5984/Database"))
    (should (equal (libelcouch-entity-url document) "http://localhost:5984/Database/Document"))))


;;; Private helpers

(ert-deftest libelcouch--entity-create-children-from-json-instance ()
  (let* ((instance (libelcouch--instance-create :name "Instance"))
         (json (list "db1" "db2"))
         (children (libelcouch--entity-create-children-from-json instance json)))
    (should (equal
             children
             (list
              (libelcouch--database-create :name "db1" :parent instance)
              (libelcouch--database-create :name "db2" :parent instance))))))

(ert-deftest libelcouch--entity-create-children-from-json-database ()
  (let* ((instance (libelcouch--instance-create :name "Instance"))
         (database (libelcouch--database-create :name "Database" :parent instance))
         (json '((rows . (
                          ((id . "doc1") (value . ((rev . "rev1"))))
                          ((id . "doc2") (value . ((rev . "rev2"))))))))
         (children (libelcouch--entity-create-children-from-json database json)))
    (should (equal
             children
             (list
              (libelcouch--document-create :name "doc1" :parent database)
              (libelcouch--document-create :name "doc2" :parent database))))))

(ert-deftest libelcouch--entity-children-url ()
  (let* ((instance (libelcouch--instance-create :name "Instance" :url "http://localhost:5984"))
         (database (libelcouch--database-create :name "Database" :parent instance)))
    (should (equal (libelcouch--entity-children-url instance) "http://localhost:5984/_all_dbs"))
    (should (equal (libelcouch--entity-children-url database) "http://localhost:5984/Database/_all_docs"))))

(provide 'libelcouch-test)
;;; libelcouch-test.el ends here
