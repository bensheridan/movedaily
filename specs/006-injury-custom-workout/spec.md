# Feature Specification: Injury & Custom Workout Builder

**Feature Branch**: `006-injury-custom-workout`  
**Created**: 2026-04-19  
**Status**: Draft  
**Input**: User description: "Users want to be able to indicate an injury and customise daily workouts to suit. This new feature will allow users to build custom workouts instead of the generated workout by multi selecting from the four categories and will let users enter their own custom exercise."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Indicate an Injury (Priority: P1)

A user has a shoulder injury and wants the app to know so that exercises that strain the shoulder are excluded from their daily session. The user navigates to their profile, indicates their active injury, and from that point on the daily generated workout respects the restriction.

**Why this priority**: Injury safety is the most important concern — generating a workout that aggravates an injury could cause real harm and destroys user trust. Everything else is enhancement; this is a safety baseline.

**Independent Test**: Can be fully tested by setting an injury in the profile, triggering workout generation, and verifying no contraindicated exercises appear — delivers standalone safety value with no other stories required.

**Acceptance Scenarios**:

1. **Given** the user opens their profile, **When** they select "I have an injury" and choose an injury type from the list, **Then** the injury is saved and displayed in their profile.
2. **Given** the user has an active injury recorded, **When** the daily workout is generated, **Then** exercises tagged as contraindicated for that injury are excluded.
3. **Given** the user's injury has healed, **When** they remove the injury from their profile, **Then** the full exercise pool is available again for generation.
4. **Given** a user has an injury that excludes exercises in a category entirely, **When** the workout is generated, **Then** the app fills the session from remaining categories and notifies the user why.

---

### User Story 2 - Build a Custom Workout by Multi-Selecting Categories (Priority: P2)

A user wants to skip the auto-generated session today and instead build their own workout by choosing which of the four categories (Stretching, Breathing, Bodyweight, Balance) they want to include, and the app assembles a session from those.

**Why this priority**: Gives users meaningful control over their session without requiring them to specify every exercise individually — a high-value, low-friction customisation.

**Independent Test**: Can be tested by entering the custom builder, selecting two or more categories, confirming the build, and verifying only exercises from the selected categories appear in the session — no injury or custom exercise stories are required.

**Acceptance Scenarios**:

1. **Given** the user is on the home screen, **When** they choose to build a custom workout, **Then** they see the four categories (Stretching, Breathing, Bodyweight, Balance) with multi-select controls.
2. **Given** the user selects at least one category, **When** they confirm, **Then** a workout is assembled from exercises in only those categories, respecting the current session tier duration.
3. **Given** the user selects no categories, **When** they try to confirm, **Then** a clear error message prevents proceeding.
4. **Given** the user has an active injury, **When** they build a custom workout, **Then** contraindicated exercises are still excluded from the selected categories.

---

### User Story 3 - Add a Custom Exercise (Priority: P3)

A user has a personal exercise (e.g., a physio-prescribed movement) that is not in the app's library. They want to add it to their session with a name and a duration.

**Why this priority**: Extends the app's value for users with specialist needs, but is not required for the core injury/custom-builder flows to work.

**Independent Test**: Can be tested by tapping "Add custom exercise" in the workout builder, entering a name and duration, and verifying it appears in the session — no injury story or category selection required.

**Acceptance Scenarios**:

1. **Given** the user is in the custom workout builder, **When** they tap "Add my own exercise", **Then** a form appears for entering a name and duration.
2. **Given** the user enters a name and a valid duration, **When** they confirm, **Then** the custom exercise is added to the current session.
3. **Given** the user enters a name but no duration (or an invalid duration), **When** they try to confirm, **Then** they see a validation error and cannot proceed.
4. **Given** the user adds a custom exercise, **When** the session runs, **Then** the custom exercise appears in the exercise list with the user-provided name and duration.
5. **Given** the user saves a custom exercise, **When** they build another custom workout later, **Then** their saved custom exercises are available to add again.

---

### Edge Cases

- What happens if an injury restricts so many exercises that the minimum session duration cannot be met?
- What happens if the user selects only one category and there are insufficient exercises to fill the session tier?
- How does the system behave if a custom exercise has an extremely long duration that exceeds the session tier budget?
- What happens when a user has both an injury restriction and has selected specific categories that further limit the exercise pool?
- Can a user have more than one active injury at a time?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Users MUST be able to indicate one or more active injuries from a predefined list of injury types within their profile.
- **FR-002**: Users MUST be able to remove or clear an active injury from their profile at any time.
- **FR-003**: The daily generated workout MUST exclude exercises contraindicated for the user's active injury or injuries.
- **FR-004**: When injury restrictions prevent reaching the minimum session duration, the app MUST notify the user and generate the longest possible safe session.
- **FR-005**: Users MUST be able to enter a custom workout builder mode as an alternative to the auto-generated daily session.
- **FR-006**: The custom workout builder MUST present the four exercise categories (Stretching, Breathing, Bodyweight, Balance) as individually selectable options.
- **FR-007**: Users MUST be able to select one or more categories; selecting zero categories MUST be prevented with a clear message.
- **FR-008**: On confirming category selection, the app MUST assemble a session from exercises in the chosen categories, respecting the user's current session tier duration.
- **FR-009**: Active injury restrictions MUST be respected inside the custom workout builder — contraindicated exercises are excluded even from selected categories.
- **FR-010**: Users MUST be able to add a custom exercise to the current session by providing a name and a duration.
- **FR-011**: Custom exercises MUST be validated — a name is required, and duration must be a positive whole number of seconds.
- **FR-012**: Custom exercises added by the user MUST persist so they can be reused in future custom sessions.
- **FR-013**: Custom exercises MUST appear and function correctly during a running session (displaying name and duration).

### Key Entities

- **Injury**: A named condition (e.g., "Shoulder injury", "Lower back pain") that restricts specific exercises. An injury has a type/name and is associated with a set of contraindicated exercise categories or specific exercises.
- **Custom Exercise**: A user-defined exercise with a name and duration. Persists across sessions for reuse.
- **Exercise (existing)**: Extended to carry contraindication metadata linking it to one or more injury types.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users with an active injury can complete a full daily session without any contraindicated exercises appearing — verified in 100% of generated sessions.
- **SC-002**: Users can build and start a custom workout from the category selector in under 60 seconds.
- **SC-003**: Users can add a custom exercise and have it appear in an active session in under 30 seconds.
- **SC-004**: When injury filtering reduces the available exercise pool, users receive a clear explanation rather than a silent failure or empty session.
- **SC-005**: Saved custom exercises are available for reuse in every subsequent custom workout session without re-entry.

## Assumptions

- The "four categories" are Stretching, Breathing, Bodyweight, and Balance — matching the existing `displayCategories` in the app.
- Injury types will be a predefined list rather than free-text entry (reduces data quality issues and enables reliable contraindication mapping).
- A user can have more than one active injury simultaneously.
- The custom workout builder produces a one-off session; it does not save or replace the auto-generated daily session permanently.
- Custom exercises created by the user belong to no specific category and are always included when added (not subject to category filtering, only injury filtering if explicitly marked).
- Session tier (Basic / Intermediate / Advanced) continues to govern the target duration even for custom-built sessions.
