# Baseline requirements for the pet form

`pets-spec.md` states what PetClinic does today when a pet is added or edited. It is written in OpenSpec's main-spec format, so it can go into `openspec/specs/pets/spec.md` and later changes can be written as deltas against it. Drafted by Claude on 25 October 2026 from the stored Week 2 runs, and updated on 31 October from the class runs. Nobody has reviewed it yet.

## What it describes

The state the Week 2 class left on 26 October, which is where Week 3 starts: `he-petclinic` branch `week-2-sensors` (`da90976`) with the class runs applied. The e11 class run `20261026-151413-claude-opus-5-5` carries all of them in its diff: the 29 class pins, e10's refactoring and e11's fix. In that state the future-date rule is in `PetValidator`, and the duplicate-name checks are still in `PetController` (they are among the frozen violations of the architecture rule).

## Sources

| Name | What it is | Evidence level |
|---|---|---|
| Run C | e9 class run `20261026-142703-claude-opus-5-5`, 29 pins, as it stands after e11 | Mocked: `@WebMvcTest` with mocked repositories |
| Run A | e9 stored run `20261024-222653-claude-opus-5-5`, 29 pins | Mocked |
| Run B | e9 stored run `20261025-041042-claude-opus-5-5`, 26 pins | Mocked |
| U | Upstream `PetControllerTests` and `PetValidatorTests`, plus `processUpdateFormRejectsFutureBirthDate` from the class | Mocked or unit |
| Conc | Upstream `PetClinicConcurrencyTests`, `@SpringBootTest` on a random port | Running application on H2 (the default profile). Not run in this session |
| Code | `PetController`, `PetValidator`, `Owner.getPet`, the three `schema.sql` files, `messages.properties`, read at the class end state | Read, not run |

A mocked test is evidence for the controller. For the running application it is INFERRED, except where Conc covers the same behaviour.

## How a pin became a requirement

- **Specified:** a user can reach the behaviour through the pet form, and the pin states an outcome they would see.
- **Incidental:** the pin needs a request the form never sends, or a state the application cannot produce, or it pins an implementation detail such as the order of errors or a message key. Recorded below, not specified.
- **Suspect:** the behaviour may be a bug. Recorded below. Prem decided on 31 October which suspect behaviours enter the spec (below).

Three runs of the same skill on the same code pinned three different sets. Runs A and B, matched by the behaviour each pin checks (a judgement, not a mechanical count): 22 behaviours in both, 7 only in A, 4 only in B. Run C pinned behaviours neither earlier run had, among them edit with separate instances, the values a rejected edit leaves on the loaded pet, and the two errors for a malformed date. It dropped the rename to a later pet's name, which A and B both pinned. The spec uses all three.

## Evidence per requirement

Moved out of the spec on 31 October, because `openspec validate --strict` warns when a requirement's text passes 500 characters.

| Requirement | Tests |
|---|---|
| Add a pet to an owner | run C `createSavesOwnerWithNewPetAndFlashesMessage`; run A `CreationForm.successAddsPetToOwnerSavesAndFlashesMessage`; run B `AddForm.successSavesOwnerWithNewPetAndFlashesMessage`; `PetControllerTests.processCreationFormSuccess`. All mocked. |
| Edit a pet in place | run C `editUpdatesExistingPetAndFlashesMessage`, `editCopiesNameBirthDateAndTypeOntoOwnersPetWhenInstancesDiffer`; run A `UpdateForm.successUpdatesExistingPetInPlaceSavesAndFlashesMessage`; run B `EditForm.successUpdatesExistingPetSavesAndFlashesMessage`; `PetControllerTests.processUpdateFormSuccess`. All mocked. |
| Pet name is required | run C `createBlankNameReportsOnlyRequiredNotDuplicate`, `editBlankNameReportsOnlyRequiredNotDuplicate`; run A `CreationForm.blankNameIsOnlyRequiredNotDuplicateChecked`; run B `AddForm.validationErrorDoesNotSave`, `EditForm.validationErrorDoesNotSave`; `PetControllerTests.processCreationFormWithBlankName`, `processUpdateFormWithBlankName`. All mocked. |
| Pet name is at most 30 characters | run C `createNameOf30CharsAccepted`, `createNameOf31CharsRejectedWithSize`, `editNameOf31CharsRejectedWithSize`; run A `CreationForm` and `UpdateForm`, `nameOfThirtyCharactersIsAccepted` and `nameOfThirtyOneCharactersIsRejectedWithSize`; run B `AddForm` and `EditForm`, the same boundary. All mocked. |
| Pet name is unique per owner, ignoring case | run C `createDuplicateNameIsCaseInsensitive`, `editDuplicateNameOfOtherPetIsCaseInsensitive`, `editOwnNameInDifferentCaseIsAllowed`; run A `CreationForm.duplicateNameCheckIgnoresCase`, `UpdateForm.duplicateNameCheckIgnoresCase`, `UpdateForm.renamingToOwnNameInDifferentCaseIsAccepted`; run B `AddForm.duplicateNameIsCaseInsensitive`, `EditForm.duplicateNameOfEarlierPetIsCaseInsensitive`, `EditForm.keepingOwnNameInOtherCaseIsAccepted`; `PetControllerTests.processCreationFormWithDuplicateName`, `processUpdateFormWithDuplicateName`, `processUpdateFormWithSameName`. All mocked. |
| Duplicate names caught by the database | runs A, B and C, `...UniqueViolationMessageMatched...` or `uniqueConstraintMessageIsMatched...` and `otherDataIntegrityViolationIsRethrown` on both forms, mocked; `PetClinicConcurrencyTests.testDuplicatePetNameRaceConditionIsBlocked`, the running application on H2, add form only. |
| Birth date is required | run C `createMissingBirthDateIsRequired`, `editMissingBirthDateIsRequiredAndNotSaved`; run A `CreationForm.missingBirthDateIsRejectedAsRequired`, `UpdateForm.missingBirthDateIsRejectedAsRequired`; run B `AddForm.emptyBirthDateIsRequired`, `EditForm.emptyBirthDateIsRequired`. All mocked. |
| Birth date is a valid date, not in the future | run C `createAcceptsBirthDateOfToday`, `createRejectsBirthDateOfTomorrowWithCodeOnlyAndDoesNotSave`, `createUnparseableBirthDateReportsTypeMismatchAndRequired`, `editAcceptsBirthDateOfToday`; run A `CreationForm.birthDateTodayIsAccepted`, `birthDateTomorrowIsRejectedWithTypeMismatchBirthDate`, `malformedBirthDateIsRejectedAsTypeMismatch`, `UpdateForm.birthDateTodayIsAccepted`; run B the same on both forms; `PetControllerTests.processCreationFormWithInvalidBirthDate`; `PetControllerTests.processUpdateFormRejectsFutureBirthDate`, written in class at Week 2 step 4 and green after step 7. All mocked. |
| Pet type is required when adding a pet | run C `createReportsEveryValidatorErrorAtOnce`; run A `CreationForm.allErrorsAreReportedTogetherInOrder`; run B `AddForm.idParameterIsIgnoredSoTypeIsStillRequired`, `AddForm.unknownTypeIsTypeMismatch`; `PetControllerTests.processCreationFormWithMissingPetType`. All mocked. |
| Validation errors are reported together | run C `createReportsDuplicateNameAndFutureBirthDateTogether`, `createReportsEveryValidatorErrorAtOnce`; run A `CreationForm.allErrorsAreReportedTogetherInOrder` and `UpdateForm.allErrorsAreReportedTogetherInOrder`, which Week 2 step 6 changed to check the errors as a set; run B `AddForm.allErrorsAreReportedTogether`, `EditForm.allErrorsAreReportedTogether`. All mocked. |
| The pet id cannot be set from the form | run C `createIgnoresSubmittedId`, `editIgnoresSubmittedId`; run A `UpdateForm.idParameterIsNotBound`; run B `AddForm.idParameterIsIgnoredSoTypeIsStillRequired`. All mocked. |

## Decided on 31 October

| Behaviour | Decision |
|---|---|
| A future birth date gets "invalid date", the message for a malformed date | In the spec as current behaviour. A defect candidate for a later change |
| A rejected edit has already bound the submitted values onto the loaded pet (C `editRejectedFormHasAlreadyBoundValuesOntoOwnersPet`) | Left out, listed as known behaviour. Nothing is saved |
| An unknown pet id ends in a NullPointerException and the error page (A, B, C) | Left out, listed as known behaviour. A defect, outside this change |
| " petty" is accepted as a different name from "petty" (B `AddForm.duplicateNameIsNotTrimmed`) | Left out, listed as known behaviour |

The trimming scenario that the 25 October draft specified has moved out of the spec under this decision. A malformed date gives two errors on the birth date, "invalid date" and "is required" (C); the spec states it as current behaviour and it is a second defect candidate.

## Left out of the spec

| Pin | Why |
|---|---|
| A `CreationForm.duplicateNameCheckIgnoresUnsavedPetsOfTheOwner`, C `createDuplicateCheckIgnoresUnsavedPetsOfOwner` | Incidental. Needs an unsaved pet in the owner's list during a POST. The owner is loaded fresh for each request, so the application cannot produce this state (INFERRED from the code) |
| A `UpdateForm.duplicateNameCheckIncludesUnsavedPetsOfTheOwner` | Incidental, for the same reason |
| A `UpdateForm.omittedFieldsKeepTheirStoredValues` | Incidental. The edit form always sends every field |
| A `UpdateForm.missingTypeIsAcceptedBecausePetIsNotNew`, B `EditForm.typeIsNotRequiredForExistingPet`, C `editDoesNotRequireType` | Incidental. The form always sends a type, and `pets.type_id` is NOT NULL, so a stored pet always has one |
| A `UpdateForm.renamingToTheNameOfALaterListedPetIsAccepted`, B `EditForm.duplicateNameOfLaterPetIsNotDetected` | Suspect, and probably a product of the mock. See finding 1 |
| C `editRejectedFormHasAlreadyBoundValuesOntoOwnersPet` | Known behaviour (decided 31 October). Its "two pets named petty" also depends on the mock's shared instance. See finding 1 |
| A, B, C: unknown pet id ends in a NullPointerException | Known behaviour (decided 31 October) |
| B `AddForm.duplicateNameIsNotTrimmed` | Known behaviour (decided 31 October) |
| The order of errors (A, before Week 2 step 6) | Incidental. Step 6 decided the errors are checked as a set |

## Findings

1. **The mocked tests share one `Owner` between the two lookups, and pins inherit that.** In `@WebMvcTest` the mocked `findById` returns the same instance to `findOwner` and `findPet`, so the bound pet is the owner's own pet, already changed when the duplicate check runs. Runs A and B pinned a rename that this allows and labelled it a suspected product bug. With `spring.jpa.open-in-view=false`, the running application loads separate instances, so the check sees the stored name and should reject the rename (INFERRED from the code and the setting). Run C took a step towards the running application: it added a pin with separate instances (`editCopiesNameBirthDateAndTypeOntoOwnersPetWhenInstancesDiffer`) and dropped the rename pin. It still pinned one SUSPECT that rests on the shared instance: after a rejected edit, "the in-memory owner holds two pets named petty". In the running application the owner in the model is a separate instance and keeps its stored names (INFERRED). This is the strongest case for checking a baseline against the running system.
2. **The database constraint differs by database.** H2: `UNIQUE (owner_id, name)`, named `unique_owner_pet_name`, on a `VARCHAR_IGNORECASE(30)` column, so it ignores case (corrected 31 October: the 25 October draft said case-sensitive; the H2 violation message in a test run on the tag shows `VARCHAR_IGNORECASE`, and the controller's lowercase match of the constraint name works there). PostgreSQL: a unique index on `(owner_id, LOWER(name))` with the same name. MySQL: `UNIQUE (owner_id, name)` with no name. `isDuplicatePetNameViolation` looks for `unique_owner_pet_name` in the message, so on MySQL a race on a duplicate name probably ends in an error page (INFERRED from the schema and the code, not run). Conc covers H2 and the add form only.
3. **Two date messages mislead.** A future date is reported as "invalid date" (key `typeMismatch.birthDate`). A malformed date gets both "invalid date" and "is required". Both are specified as they are and are defect candidates.
4. **The message for an unknown type is unknown.** `messages.properties` has no key for a type mismatch on `type`, so Spring probably shows its default text (INFERRED). The spec says only "an error on the type". Only run B pinned it.
5. **The pins cover two handlers.** The GET forms, owner not found, visits and the owner pages have no characterization tests. A Week 3 change outside this slice has no baseline. PC-301's implied lookup by chip is outside it.

## Validated

`openspec validate pets --type spec --strict` passes with OpenSpec 1.15.0 (31 October): 11 requirements, 22 scenarios. Run in a scratch OpenSpec project on the Linux machine linked to Prem's Mac.

## Not done

- Checks against the running application for findings 1, 2 and 4: a `@SpringBootTest` like Conc, or the browser on the ladder.
- An independent review of this spec against the pins. Whoever reviews it should not be the agent that wrote it.
