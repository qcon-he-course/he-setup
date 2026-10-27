# Answer key for experiment 6: an owner adds a new pet

Draft, 18 October 2026. Not yet reviewed by Prem; `grade.sh` doesn't use it until he has.

Checked against seeded PetClinic at `b107a86` in a scratch clone (`~/.cache/qcon-he/e6-key`). Paths are under `src/main/java/org/springframework/samples/petclinic/` for Java and `src/main/resources/` for the rest.

The journey runs from submitting the form to the row in the database. It has seven steps. Four of them (2, 3, 4 and 7) are decided by the framework, through annotations, a bean Spring finds by itself, and a cascade mapping.

| Step | What happens | Evidence |
|---|---|---|
| 1 | The form posts the name, birth date and type to `/owners/{ownerId}/pets/new`. It has no `action`, so it posts back to the URL that showed it. `processCreationForm` handles the post. | `templates/pets/createOrUpdatePetForm.html:11, 20-22`; `owner/PetController.java:48, 107-108` |
| 2 | **Framework.** Before the handler runs, Spring MVC calls the controller's three `@ModelAttribute` methods. `populatePetTypes` loads the pet types, `findOwner` loads the owner named in the path, and `findPet` returns a new `Pet` because the path has no `petId`. Nothing in the code calls these methods. | `owner/PetController.java:62-87`; `owner/PetTypeRepository.java:36-37` |
| 3 | **Framework.** While binding the form to `pet`, Spring converts the type's name into a `PetType` by calling `PetTypeFormatter.parse`. Spring Boot registers the formatter because it is a `@Component` that implements `Formatter`. No code in the application registers it. | `owner/PetTypeFormatter.java:36-37, 52-59`; `templates/fragments/selectField.html:13-14` (each option's value is the type's name); `system/WebConfiguration.java:55-57` (registers only a locale interceptor) |
| 4 | **Framework.** `initPetBinder`, an `@InitBinder("pet")` method, installs `PetValidator` on the binder and stops `id` from being bound. Because the parameter carries `@Valid`, Spring runs the validator after binding. The name is required and at most 30 characters, a new pet needs a type, and the birth date is required. | `owner/PetController.java:94-98, 108`; `owner/PetValidator.java:36, 39-58` |
| 5 | `processCreationForm` adds two checks of its own: a name already used by one of the owner's saved pets, and a birth date after today. Any error from step 4 or step 5 shows the form again. | `owner/PetController.java:111-122`; `owner/Owner.java:147-157` |
| 6 | `owner.addPet(pet)` adds the new pet to the owner's list of pets. | `owner/PetController.java:125`; `owner/Owner.java:100-113` |
| 7 | **Framework.** `owners.saveAndFlush(owner)` saves the owner. The method comes from Spring Data: `OwnerRepository` extends `JpaRepository` and declares no save. JPA cascades from the owner to its pets, which inserts the row into `pets` with `owner_id` and `type_id`. A unique constraint on owner and name backs step 5's duplicate check; if it fires, the form shows again. | `owner/PetController.java:126-134`; `owner/OwnerRepository.java:36`; `owner/Owner.java:67-70`; `db/h2/schema.sql:46-55`; `application.properties:2-3` (H2 by default) |

After the row is written, the browser is redirected to the owner's page with the message "New Pet has been Added" (`owner/PetController.java:135-136`). That is outside the journey and is not counted.

## Order of steps 3 and 4

Spring calls `initPetBinder` when it creates the binder for `pet`, before binding. The validator it installs runs after binding. A drawing that puts step 4 before step 3, or folds the two into "bind and validate" with both named, gets both steps.

## How to mark a drawing

- A step counts when the drawing shows what happens and names the class and the method or annotation.
- Step 2 counts when the drawing shows Spring calling the `@ModelAttribute` methods before the handler. Record how many of the three it names.
- Steps 2, 3, 4 and 7 count only when the drawing shows the framework doing the work. An arrow "`processCreationForm` calls `findOwner`" does not count for step 2.
- Step 7 counts when the save goes through the owner and the cascade puts the pet's row in the table. Calling the method `save` instead of `saveAndFlush` still counts; note the slip.
- An arrow marked inferred still counts if it is right. Record that it was marked inferred.

## Typical wrong answers

- A service layer between the controller and the repository. There is none.
- A `PetRepository`, or a save of the pet on its own. There is no `PetRepository`; the save goes through the owner.
- The formatter called by the controller, or registered in `WebConfiguration`. Neither happens.
- The controller calling `findOwner` or `findPet` itself.
- Bean Validation checking the name through `@NotBlank` on `NamedEntity.name` (`model/NamedEntity.java:34`). INFERRED, not run: `setValidator` replaces the binder's default validator, so on this path `PetValidator` does the checks and `@NotBlank` is not applied. Source: Spring Framework's `DataBinder.setValidator` contract. Confirm before using this line to mark an answer wrong.

## Notes

- All three schemas have a unique constraint on owner and pet name: H2 (`db/h2/schema.sql:55`) and Postgres (`db/postgres/schema.sql:45`, on `LOWER(name)`) name it `unique_owner_pet_name`; MySQL's is unnamed (`db/mysql/schema.sql:47`). Corrected 18 October: an earlier version of this note said MySQL had none, from a search for the constraint's name only. The default database is H2.
