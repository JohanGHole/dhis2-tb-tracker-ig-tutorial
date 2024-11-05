// This is a comment

// (1) Declaration
Profile: Dhis2PatientProfile

// (2) Keywords
Parent: Patient
Title: "DHIS2 Patient Profile"
Id: dhis2-patient-profile
Description: "A profile for expressing DHIS2 Enrollment details as a FHIR Patient."

// (3) Rules 
* identifier 1..1 MS                              // Cardinality and flag rule
  * system = "http://example.org/dhis2/unique-id" // assignment rule
  * value MS                                      // flag rule
* name 1..1                                       // cardinality rule
* name.given and name.family MS                   // flag rule
* gender 1..1 MS                                  // cardinality and flag rule
* deceased[x] only boolean                        // type rule
* gender from GenderVS (required)                 // binding rule

