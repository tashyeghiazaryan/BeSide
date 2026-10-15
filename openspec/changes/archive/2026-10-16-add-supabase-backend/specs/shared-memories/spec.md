# shared-memories Spec Delta

## MODIFIED Requirements

### Requirement: Shared memory model
A shared memory SHALL have an id, title, dateTime, optional description, mood emoji, optional photo reference (storage path or URL), likes count, likedByMe flag, and author identity (replacing session-only `addedByUser` semantics with the creating user). In Supabase mode, the couple’s ordered memories SHALL load from Postgres (and Storage for photos) and MUST survive relaunch. In demo mode, the session store MAY hold an ordered array and expose demo seeds on first launch.

#### Scenario: Memories load for couple (Supabase)
- **WHEN** a paired user opens Shared Memories after memories were added earlier
- **THEN** those memories appear without relying on in-memory seeds alone

#### Scenario: Seed memories on fresh demo session
- **WHEN** backend mode is demo and the session starts with no user-created memories
- **THEN** at least one non-user seed and one or more user-added seeds are available

### Requirement: Add memory modal
The Add memory modal SHALL be a centered frosted-glass card over a dimmed/blurred scrim titled “Share a new memory” with subtitle copy. It SHALL collect title (required, max 40), date/time (defaults to now if unset), optional description (max 120), optional photo via device picker (Wishlist-style), and a mood emoji from a fixed set. Title and description SHALL accept Latin letters, digits, common punctuation, spaces, and emoji only; disallowed characters are filtered on input. “Share a memory” SHALL create a new memory authored by the current user, prepend/refresh it in the couple list, close the modal, reset fields, and open the gallery with filter All when validation passes. In Supabase mode, create MUST persist the row and upload any photo to Storage before claiming success. Validation failures SHALL show inline alerts under the relevant field (not system alerts). Empty title, whitespace-only description, or invalid text MUST NOT create a memory. Dismiss via Close or scrim without requiring save.

#### Scenario: Create memory with photo (Supabase)
- **WHEN** the user submits a valid title and a photo while online in Supabase mode
- **THEN** the memory row and photo object are stored and the memory appears in the couple list

### Requirement: Edit and delete memory
The user SHALL be able to edit or delete memories they are allowed to modify (at minimum their own; couple-wide edit MAY match current UI). Edit SHALL open the Add modal in edit mode, prefilled with the memory’s fields, titled “Edit memory”, with CTA “Save changes”. The same Title/Description validation and inline alerts as Add SHALL apply. Photo MAY be kept, replaced, or removed. Save SHALL update the existing memory in place (no duplicate). Delete SHALL show a confirmation dialog; on confirm the memory is removed from the couple list (and Storage object cleaned up per `couple-backend`). If the deleted memory was selected in the feed, selection SHALL advance to an adjacent memory or close the feed when none remain.

#### Scenario: Delete removes persisted memory (Supabase)
- **WHEN** the user confirms delete on a memory while online
- **THEN** the memory no longer appears for either partner after sync
