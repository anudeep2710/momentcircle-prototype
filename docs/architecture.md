# MomentCircle architecture

## 1. Product boundary

The MVP indexes **one host/photographer archive per event**. Guests do not upload arbitrary galleries, and the system does not perform cross-event or public face search. A guest can only retrieve photos that belong to the event and that pass the event permission filter.

```text
Guest phone
  ├─ QR join + event session
  ├─ consent + up to three selfie samples
  ├─ local_auth gallery lock
  └─ authorized thumbnail gallery
          │
          ▼
       Appwrite
  ├─ Auth / guest session
  ├─ private Storage buckets
  ├─ Tables / Databases
  ├─ Functions for validation and expiry
  └─ Realtime processing status
          │
          ▼
   Local Python worker
  ├─ OpenCV YuNet face detection
  ├─ OpenCV SFace embeddings
  ├─ cosine similarity + threshold policy
  └─ idempotent match records
```

The Flutter prototype currently uses a seeded adapter in place of Appwrite and the worker. That keeps the judge demo deterministic while preserving the production seams.

## 2. Flutter modules

| Module | Responsibility | Production package/adapter |
|---|---|---|
| `MomentCircleShell` | Product story, navigation and demo state | Flutter/Dart |
| Event join | Decode an opaque event invite | `mobile_scanner` |
| Consent enrollment | Capture and validate up to three samples | `camera` + `google_mlkit_face_detection` |
| Private album | Display only permitted thumbnail IDs | Appwrite Storage adapter |
| Device lock | Hide gallery and require device credential | `local_auth` / Android `BiometricPrompt` |
| Cloud boundary | Sessions, records, file permissions, progress | Appwrite SDK |
| Index boundary | Batch archive processing | Local Python worker |

ML Kit is a **face detector and capture-quality helper**, not the identity engine. The worker produces embeddings with YuNet + SFace and compares them only inside the current `eventId`.

## 3. Appwrite resources

### Tables / Databases

- `events`: `eventId`, `ownerId`, `name`, `inviteHash`, `status`, `expiresAt`.
- `event_members`: `eventId`, `userId`, `role`, `consentAt`, `revokedAt`.
- `identities`: `identityId`, `eventId`, `memberId`, `embeddingRef`, `enrollmentStatus`, `deletedAt`.
- `photos`: `photoId`, `eventId`, `originalFileId`, `thumbnailFileId`, `checksum`, `processingStatus`.
- `photo_people`: `photoId`, `identityId`, `confidence`, `decision`, `modelVersion`.
- `audit_events`: actor, event, action, resource, timestamp and non-sensitive metadata.

### Private Storage buckets

- `event-originals`: host-owned compressed originals.
- `event-thumbnails`: private, event-member-readable thumbnails.
- `selfie-staging`: consent samples; delete after embedding or short TTL.
- `exports`: guest-selected albums with a short expiry.

Never use `read(any)` for event photos. Validate membership and `eventId` server-side before returning a thumbnail. Appwrite permissions protect cloud resources; `local_auth` protects the phone’s presentation layer. Both are needed.

## 4. Worker contract

```text
photoId, eventId, checksum, inputFileId, modelVersion
    -> processingStatus, faceCount, matches[], errorCode
```

The worker is idempotent: the same `photoId + checksum + modelVersion` cannot create duplicate matches. It should:

1. Read an authorized archive photo.
2. Detect faces with YuNet.
3. Align and embed each face with SFace.
4. Compare only against active identities in the same event.
5. Apply a conservative threshold and label uncertain results for review.
6. Write `photo_people` and processing status.
7. Delete temporary files and staging selfies according to retention policy.

For the hackathon fixture, 300 compressed photos and 10 synthetic/consented participants are enough. A seeded index remains the fallback if model setup or network access fails during the demo.

## 5. Security and privacy rules

- Explicit consent is required before identity creation.
- Identity scope is an event, never an account-wide face profile.
- Raw selfies are staging inputs, not gallery content.
- Guests can reject a result and delete their identity.
- Match confidence and uploader provenance remain visible.
- The app never exposes unknown faces to a guest.
- Device lock is a local presentation control, not a substitute for Appwrite permissions.
- Synthetic or explicitly consented images only for judging.
- No API keys, service accounts, raw embeddings, or private photos in Git.

