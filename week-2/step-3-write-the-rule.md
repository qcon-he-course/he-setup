# Step 3: write the rule

After e7b, in the clone the agent works on. Nothing runs in the container for this step: you type in your editor and run Maven on your machine, with JDK 17.

```bash
cd ~/.cache/qcon-he/week2/petclinic
```

To skip this step, or if it goes wrong: `./demo.sh reset week-2-sensors` (from `week-2/`) gives a fresh clone with the rule and the store as committed. Then go on to e8.

## 1. The dependency

In `pom.xml`, next to the other test dependencies:

```xml
<dependency>
  <groupId>com.tngtech.archunit</groupId>
  <artifactId>archunit-junit5</artifactId>
  <version>1.5.1</version>
  <scope>test</scope>
</dependency>
```

## 2. The rule, without freeze

`src/test/java/org/springframework/samples/petclinic/ArchitectureTests.java`:

```java
package org.springframework.samples.petclinic;

import com.tngtech.archunit.core.importer.ImportOption;
import com.tngtech.archunit.junit.AnalyzeClasses;
import com.tngtech.archunit.junit.ArchTest;
import com.tngtech.archunit.lang.ArchRule;

import org.springframework.stereotype.Controller;
import org.springframework.validation.Errors;

import static com.tngtech.archunit.base.DescribedPredicate.describe;
import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.noClasses;

@AnalyzeClasses(packages = "org.springframework.samples.petclinic",
		importOptions = ImportOption.DoNotIncludeTests.class)
class ArchitectureTests {

	@ArchTest
	static final ArchRule controllersLeaveFieldValidationToValidators = noClasses().that()
		.areAnnotatedWith(Controller.class)
		.should()
		.callMethodWhere(describe("Errors.rejectValue(..)",
				call -> call.getName().equals("rejectValue") && call.getTargetOwner().isAssignableTo(Errors.class)))
		.because("field validation belongs in the form's Validator (for pets, PetValidator), "
				+ "so the add and edit forms share one rule. Move the check into the validator "
				+ "instead of calling rejectValue in the controller");

}
```

The `because` text is what a person reads when the rule fails, and what the agent reads through the hook at step 7.

## 3. Run it: 8 violations

```bash
./mvnw -q test -Dtest=ArchitectureTests -Dspring-javaformat.skip=true -Dcheckstyle.skip=true
```

Expected: fails, "was violated (8 times)". PetController 5 (lines 112, 117, 132, 149, 163), OwnerController 2 (118, 162), VisitController 1 (101).

Fix eight places today, or don't adopt the rule? Freezing is the third option.

## 4. Freeze it

Wrap the rule: `freeze(noClasses()...because("..."))`, and add the import:

```java
import static com.tngtech.archunit.library.freeze.FreezingArchRule.freeze;
```

`src/test/resources/archunit.properties`:

```properties
freeze.store.default.path=src/test/resources/archunit_store
freeze.store.default.allowStoreCreation=true
```

## 5. Run again: green, and a store

Same command. Green. Then:

```bash
ls src/test/resources/archunit_store
cat src/test/resources/archunit_store/*-*
```

Eight readable lines, one per violation. One is `PetController.java:117`, the future-date check on the add form.

If the formatter complains later in a full build, it is the tabs: `./mvnw spring-javaformat:apply`.

About 10 minutes.
