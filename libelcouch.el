;;; libelcouch.el --- Communication with CouchDB  -*- lexical-binding: t; -*-

;; Copyright (C) 2018  Damien Cassou

;; Author: Damien Cassou <damien@cassou.me>
;; Keywords: tools
;; Url: https:///DamienCassou/mpdel
;; Package-requires: ((emacs "25.1"))
;; Version: 0.1.0

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

;; The package libelcouch is an Emacs library client to communicate with
;; Music Player Daemon (MPD), a flexible, powerful, server-side
;; application for playing music.  For a user interface, please check
;; the mpdel project instead (which depends on this one).

;;; Code:
(require 'cl-lib)
(require 'request)
(require 'json)
(require 'map)


;;; Customization

(defgroup elcouch nil
  "View and manipulate CouchDB databases."
  :group 'externa)

(defcustom libelcouch-couchdb-instances nil
  "List of CouchDB instances."
  :type 'list)


;;; Structures

(cl-defstruct (libelcouch-named-entity
               (:constructor libelcouch--named-entity-create)
               (:conc-name libelcouch--named-entity-))
  (name nil :read-only t))

(cl-defstruct (libelcouch-instance
               (:include libelcouch-named-entity)
               (:constructor libelcouch--instance-create)
               (:conc-name libelcouch--instance-))
  (url nil :read-only t))

(cl-defstruct (libelcouch-database
               (:include libelcouch-named-entity)
               (:constructor libelcouch--database-create)
               (:conc-name libelcouch--database-))
  (instance nil :read-only t))

(cl-defstruct (libelcouch-document
               (:include libelcouch-named-entity)
               (:constructor libelcouch--document-create)
               (:conc-name libelcouch--document-))
  (revision nil :read-only t)
  (database nil :read-only t))


;;; Accessors

(cl-defgeneric libelcouch-entity-name ((entity libelcouch-named-entity))
  "Return the name of ENTITY."
  (libelcouch--named-entity-name entity))

(cl-defgeneric libelcouch-entity-parent (entity)
  "Return the entity containing ENTITY.")

(cl-defmethod libelcouch-entity-parent ((database libelcouch-database))
  (libelcouch--database-instance database))

(cl-defmethod libelcouch-entity-parent ((document libelcouch-document))
  (libelcouch--document-database document))

(cl-defgeneric libelcouch-entity-instance (entity)
  "Return the CouchDB instance of ENTITY.")

(cl-defmethod libelcouch-entity-instance ((instance libelcouch-instance))
  instance)

(cl-defmethod libelcouch-entity-instance ((database libelcouch-database))
  (libelcouch--database-instance database))

(cl-defmethod libelcouch-entity-instance ((document libelcouch-document))
  (libelcouch-entity-instance (libelcouch--document-database document)))

(cl-defgeneric libelcouch-entity-url (entity)
  "Return the url of ENTITY."
  (format "%s/%s"
          (libelcouch-entity-url (libelcouch-entity-parent entity))
          (libelcouch-entity-name entity)))

(cl-defmethod libelcouch-entity-url ((instance libelcouch-instance))
  (libelcouch--instance-url instance))


;;; Private helpers

(cl-defgeneric libelcouch--entity-create-children-from-json (entity json)
  "Create and return children of ENTITY from a JSON object.")

(cl-defmethod libelcouch--entity-create-children-from-json ((instance libelcouch-instance) json)
  (mapcar
   (lambda (database-name) (libelcouch--database-create :name database-name :instance instance))
   json))

(cl-defmethod libelcouch--entity-create-children-from-json ((database libelcouch-database) json)
  (let ((documents-json (map-elt json 'rows)))
    (mapcar
     (lambda (document-json) (libelcouch--document-create
                         :name (map-elt document-json 'id)
                         :revision (map-nested-elt document-json '(value rev))
                         :database database))
     documents-json)))

(cl-defgeneric libelcouch--entity-children-url (entity)
  "Return the path to query all children of ENTITY.")

(cl-defmethod libelcouch--entity-children-url ((instance libelcouch-instance))
  (format "%s/%s" (libelcouch-entity-url instance) "_all_dbs"))

(cl-defmethod libelcouch--entity-children-url ((database libelcouch-database))
  (format "%s/%s" (libelcouch-entity-url database) "_all_docs"))


;;; Navigating

(cl-defgeneric libelcouch-entity-list (entity function)
  "Evaluate function with the children of ENTITY as parameter."
  (request
   (libelcouch--entity-children-url entity)
   :headers '(("Content-Type" . "application/json")
              ("Accept" . "application/json"))
   :parser 'json-read
   :success (cl-function
             (lambda (&key data &allow-other-keys)
               (message "json: %S" data)
               (let* ((children (libelcouch--entity-create-children-from-json entity data)))
                 (funcall function children))))
   :error (cl-function (lambda (&rest args &key error-thrown &allow-other-keys)
                         (message "Got error: %S" error-thrown)))))

(provide 'libelcouch)
;;; libelcouch.el ends here
