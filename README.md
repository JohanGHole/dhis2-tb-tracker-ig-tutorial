# dhis2-tb-tracker-ig-tutorial

## Goal
In this exercise, we will showcase how to create a Logical Model representation of a DHIS2 Tracker Program. We will manually map the TB Tracker program from the Sierra Leone demo database to a FHIR IG, focusing on the machine-readable components of the IG using FSH and the IG publisher.

> **_Note_**: This exercise serves as an opinionated guide on how to represent your DHIS2 Tracker metadata as FHIR logical models and value sets. The selection of DHIS2 metadata fields to include or exclude may vary depending on your specific use case. For this tutorial, we have chosen to use the `formName`/`displayName` fields instead of `name`, as the latter often contains prefixes or suffixes that might not be suitable for direct mapping.

If you get stuck during the tutorial, please reference the tutorial solution found [here](https://github.com/JohanGHole/tb-tracker-program-ig). 

## Prerequisites
* [Visual Studio Code](https://code.visualstudio.com/download) with [vscode-language-fsh](https://marketplace.visualstudio.com/items?itemName=FHIR-Shorthand.vscode-fsh) extension installed.
* [SUSHI](https://github.com/FHIR/sushi) Installed (requires [Node.js](https://nodejs.org/en) to be installed on the user's system). Sushi is needed to compile FSH into valid FHIR definitions.
* Access to a local instance of DHIS2 with the Sierra Leone database installed. Alternatively, you can use the online play server found [here](https://play.im.dhis2.org/dev/dhis-web-login/).

## Part 1 - Fetch the TB tracker program's metadata
The goal of part 1 is to get familiar with the TB tracker program's metadata and how it is structured.

### 1.1 - Fetch the DHIS2 metadata
Before using the API, it might be a good idea to start by using the DHIS2 UI to explore the tracker metadata. Navigate to the [DHIS2 Maintenance App](https://play.im.dhis2.org/dev/dhis-web-maintenance/index.html#/edit/programSection/program/ur1Edk5Oe2n) and [DHIS2 Capture App](https://play.im.dhis2.org/dev/dhis-web-maintenance/index.html#/edit/programSection/program/ur1Edk5Oe2n) to get an overview of how the TB tracker metadata is structured.

Now, use the [DHIS2 API](https://docs.dhis2.org/en/develop/using-the-api/dhis-core-version-240/metadata.html) to fetch the metadata of the TB tracker program:

```http
GET /api/programs/ur1Edk5Oe2n
```
Example API query to fetch all of the TB program's metadata:

```http
GET /api/programs/ur1Edk5Oe2n?fields=*
```
However, this query will not include the nested structures such as program stages and tracked entity attributes directly. By default, the `fields=*` only retrieves the top-level fields of the program, and nested structures like `programStages` will only return an array of `id` references (e.g., `[{id: "stage1"}, {id: "stage2"}]`).

We therefore need to refine the queries to only pull the necessary details. For the scope of this exercise, we will need the following fields: 
```http
GET /api/programs/ur1Edk5Oe2n?fields=name,displayName,description,,programStages[name,description,programStageDataElements[compulsory,dataElement[formName,displayName,valueType,description,optionSet[options[code,name]]]]],programTrackedEntityAttributes[displayName,trackedEntityAttribute[displayName,valueType,description,,optionSet[options[code,name]]]]
```
This fetches:
* **Top-level Program Fields:**
  * `name`: The internal name of the program (required field in DHIS2).
  * `displayName`: The display name of the program. 
  * `description`: A brief description of the program. 
* **Program Stages:**
  * `name`: The internal name of the program stage (required field in DHIS2)
  * `description`: A brief description of the program stage.
  * **Program Stage Data Elements:**
    * `compulsory`: Whether the data element is mandatory in this stage. 
    * **Data Element Fields:**
      * `formName`: The name of the data element as used in forms.
      * `displayName`: The display name of the data element. 
      * `valueType`: The data value type (e.g., `TEXT`, `BOOLEAN`)
      * `description`: A brief description of the data element.
      * **Option Set (if the data element is an option set)**:
        * `options`: The possible options associated wit the data element's option set. 
          * `code`: The option code.
          * `name`: The display name of the option. 
* **Program Tracked Entity Attributes:**
  * `displayName`: The display name of the tracked entity attribute. 
  * **Tracked Entity Attribute:**
    * `displayName`: The displayname of the tracked entity attribute. 
    * `valueType`: the data type of the attribute (e.g., `TEXT`,`BOOLEAN`).
    * `description`: A brief description of the attribute. 
    * **Option Set (if the TEA is an option set)**:
      * `options`: The options associated with the TEA's option set. 
        * `code`: the option code.
        * `name`: The name of the option.

You should now have a payload like this:
```json
{
  "name": "TB program",
  "displayName": "TB program",
  "programStages": [
    {
      "name": "Lab monitoring",
      "description": "Laboratory monitoring",
      "programStageDataElements": [
        {
          "dataElement": {
            "formName": "CD4",
            "valueType": "TRUE_ONLY",
            "displayName": "TB lab CD4"
          },
          "compulsory": false
        },
        ...
      ]
    },
    ...
  ],
  "programTrackedEntityAttributes": [
    {
      "displayName": "TB program First name",
      "trackedEntityAttribute": {
        "description": "First name",
        "valueType": "TEXT",
        "displayName": "First name"
      }
    },
    ...
  ]
}
```
The complete payload is available in the repository within the `input/examples` folder.
Please note that for your use-case, you might need to add extra fields, such as `enrollmentDateLabel`, `id`and so on. If you would rather use the  attribute / data element `name` definition rather than the `formName` / `displayName`, this is also possible.

## Part 2 - Handling Option Sets: Creating Code System and Value Sets Using FSH
### Goal
Define FHIR code systems and value sets based on DHIS2 option sets. 

### 2.1 - Create FHIR Code Systems:
* For each DHIS2 option set, create a FHIR code system in FSH that lists all the available options. Use the DHIS2 metadata payload as reference.
* The general structure is as follows:
    ```fsh
    CodeSystem: Dhis2OptionSetCS
    Id: dhis2-option-set-cs
    Title: "DHIS2 Option Set Code System"
    Description: "This is the basic structure of a FHIR code system based on a DHIS2 option set."
    * #"optionsCode1" "optionsName1"
    * #"optionsCode2" "optionsName2"
    * ...
    ```
* Example:
    ```fsh
    CodeSystem: GenderCS
    Id: gender-cs
    Title: "Gender"
    * #"Male" "Male"
    * #"Female" "Female"
    ```
### 2.2 - Map Code Systems to Value Sets
* We need to create corresponding FHIR Value Sets that reference the Code Systems. For each Code System defined for the tracker, create a corresponding FHIR value set.
* Example:
    ```fsh
    ValueSet: GenderVS
    Id: gender-vs
    Title: "Gender value set"
    * codes from system GenderCS
    ```
You should now have representations of all your DHIS2 option sets as FHIR code systems, with the appropriate value sets linking to them. If you are stuck or need further clarification, you can reference the tutorial solution. 

## Part 3 - Define the Logical Models for the Program Stages
The goal of part 3 is to create FHIR logical models (LMs) for the three DHIS2 program stages in the TB Tracker Program: TB Visit, Lab Monitoring and Sputum Smear Microscopy Test. These LMs will map each program stage's data elements to FHIR data elements. 

* Each logical model will define the structue of the program stage using FSH. 
* Use the DHIS2 metadata you fetched in Part 1 as reference when mapping the data elements. 
* For each DHIS2 data element in that program stage: 
  * Define the corresponding FHIR data element by identifying: 
    * FHIR data element name
    * Cardinality. Set the appropriate cardinality based on whether the data element is mandatory (if `mandatory=true`, the cardinality is `1..1`, if not, `0..1`).
    * dataType. Map the DHIS2 value type to a FHIR datatype (for example, TEXT to string, BOOLEAN to boolean)
    * description.
### Example on how to bind the data element to a value set
If your DHIS2 data element is an option set, you need to express this in FSH. This can be done with the following syntax: 
```fsh
* diseaseClassification 0..1 code "TB Disease Classification"
* diseaseClassification from TBDiseaseClassificationVS (required)
```
First we define the FHIR data element, giving it the dataType `code`. We then declare which value set the codes should be drawn from. In this case, it is the `TBDiseaseClassificationVS` value set defined in [Part 2](#part-2---handling-option-sets-creating-code-system-and-value-sets-using-fsh).
## Part 4 - Define the Logical Model for the Tracker Program
The goal of part 4 is to create a FHIR logical model (LM) for the Tb Tracker Program itself, using the program's tracked entity attributes (TEAs) and linking program stages as part of the model. 
### 4.1 - Start by defining the logical model for the TB Tracker Program
Similar to the program stages, you will map the program's tracked entity attributes (TEAs) to FHIR data elements. 
Each TEA in DHIS2 becomes a FHIR data element in the logical model.
* For each TEA, specify: 
  * FHIR data element name.
  * Cardinality. Based on whether the attribute is mandatory (mandatory=true for 1..1, otherwise 0..1).
  * dataType: Map DHIS2 valueType to a FHIR data type (like `TEXT` to `string`, `BOOLEAN` to `boolean` etc.)
  * Description: Use the description field from DHIS2, or fallback to `formName` / `displayName` if no description exists. 
### 4.2 - Link Program Stages to the Logical Model
To represent the program stages in the tracker program, include references to the program stage logical models. Each program stage (TB Visit, Lab Monitoring, ...) should be linked as a FHIR data element with a data type referring to its logical mode. 
#### Example
Here is an example of how the logical model for the TB Tracker Program would look in FSH, linking both tracked entity attributes and program stages:
```fsh
Logical: TBTrackerProgram
Title: "TB Tracker Program"
Parent: Base
Description: "Logical model representation of the TB Tracker Program"

* firstName 1..1 string "First name of the patient"
* lastName 1..1 string "Last name of the patient"
* ...

// Link the program stages to the program
* tbVisit 0..1 TBVisit "TB Visit"
...
```
You must also provide the linking for the "Lab Monitoring" and "Sputum Smear Microscopy Test" program stages.
## Part 5 - Review and Validate
Go through the logical models, code systems and value sets to check for consistency and readability. The structure should give a clear view of the DHIS2 data model without needing to refer back to terms like "tracked entity instance", "program stages" and so on.  
### 5.1 - Validate the IG:
* Run the IG Publisher to validate the logical models and ensure everything is in order. 
* Example of how to run the validation steps:
    ```bash
    sushi .
    ./_genonce.sh
    ```
If you wrote valid FHIR Shorthand, SUSHI will exit reporting 0 errors. You also get a free random fish pun!
```cmd
╔════════════════════════ SUSHI RESULTS ══════════════════════════╗
║ ╭───────────────┬──────────────┬──────────────┬───────────────╮ ║
║ │    Profiles   │  Extensions  │   Logicals   │   Resources   │ ║
║ ├───────────────┼──────────────┼──────────────┼───────────────┤ ║
║ │       0       │      0       │      4       │       0       │ ║
║ ╰───────────────┴──────────────┴──────────────┴───────────────╯ ║
║ ╭────────────────────┬───────────────────┬────────────────────╮ ║
║ │      ValueSets     │    CodeSystems    │     Instances      │ ║
║ ├────────────────────┼───────────────────┼────────────────────┤ ║
║ │         4          │         4         │         1          │ ║
║ ╰────────────────────┴───────────────────┴────────────────────╯ ║
║                                                                 ║
╠═════════════════════════════════════════════════════════════════╣
║ You're making waves now!               0 Errors      0 Warnings ║
╠═════════════════════════════════════════════════════════════════╣
║    You are using SUSHI version 3.11.0, but the latest stable    ║
║ release is version 3.12.0. To install the latest release, run:  ║
║                    npm install -g fsh-sushi                     ║
╚═════════════════════════════════════════════════════════════════╝
```
If you got any errors, they will be reflected in the log and counted in the summary. You will also get a random bad fish pun as a punishment. Go back to your text editor, fix the FSH definitions, and try again!

When the build is successful, go ahead and take a look at the new `fsh-generated` folder in the project. This contains the files that SUSHI generated for you. These are representations of your FHIR resources in `json`format, and will be used as input to the HL7 FHIR IG Publisher.

### 5.2 - Run the HL7 IG Publisher
To run the HL7 IG Publisher on the files that SUSHI just generated:

* Go back to your command prompt (which should still be in your unzipped project directory)
* Run the following command to download the HL7 IG Publisher jar (Java Archive)
  * Windows: `_updatePublisher`
  * Mac: `./_updatePublisher.sh`
* Once it is downloaded, run the following command to invoke the HL7 IG Publisher:
  * Windows: `_genonce`
  * Mac: `./_genonce.sh`

If the IG Publisher completed successfully, you should now be able to view your human-readable Implementation Guide by opening the file at _output/index.html_ in your web browser. Click "Artifacts" in the menu, then click on the link for your **TB Program Logical Model**. And voilà! You should now see your logical model representation of the TB Tracker program.

## Part 6 (Bonus) - Add Narrative Content
In this bonus step, the goal is to learn how to add narrative content to the IG. Narrative content helps provide context and human-readable explanations in the IG, ensuring that end users understand the purpose and structure of the logical models. This step involves updating the home page and adding custom pages to the IG. 

### 6.1 - Update the Homepage
Navigate to the `input/pagecontent` folder in your _SUSHI_ project. Locate the `index.md`file. This file represents the homepage of your IG. Open the file and modify the content to reflect an introduction or overview of you TB Tracker program. You can format the content using Markdown for headings, lists, and links. A useful reference might be HL7's implementation guide on _how_ to author implementation guides. The link can be found [here](https://build.fhir.org/ig/FHIR/ig-guidance/). Example content could include:
```markdown
# DHIS2 TB Tracker Implementation Guide Tutorial

### Summary

### About this implementation guide

### Disclaimer
The specification herewith documented is a demo working specification and may not be used for any implementation purposes. This draft is provided without warranty of completeness or consistency and the official publication supersedes this draft. No liability can be inferred from the use or misuse of this specification or its consequences.
```
### 6.2 - Add Extra Pages
To add more sections to your IG, you can create new Markdown files inside the `input/pagecontent`folder. For example, if you want a separate page explaining the general structure of a DHIS2 Tracker program and its components, create a file named `tracker-program-structure.md`. You can then link to these pages from the homepage (`index.md`) or other relevant sections using Markdown link:
```markdown
- <a href="tracker-program-structure.html">Tracker Program Structure</a> - contains an overview over how DHIS2 tracker programs are structured.
```

### 6.3 - Update Pages in `sushi-config.yaml`
Open the sushi-config.yaml file in your project. Under the `pages`section, you can specify how you want to organize the pages in your IG. if the section doesn't exist, you'll need to add it to manually manage the pages.
```yaml
pages:
  index.md:
    title: "TB Tracker IG"
  tracker-program-structure.md:
    title: "DHIS2 Tracker Program Structure"
  artifacts.md:
    title: "Artifacts"
```
Ensure that each file in the `pagecontent` has a corresponding entry in `sushi-config.yaml` for it to be included correctly in the IG.  

### 6.4 - Update the Menu in `sushi-config.yaml`
To make sure the new pages are included in the IG's navigation menu, you need to update the `menu`section in the `sushi-config.yaml`file. First, open the `sushi-config.yaml`file and locate the `menu` section. Add your new pages to the menu. Here is an example on how to add the `tracker-program-structure.md` page:
```yaml
menu:
  Home: index.html
  DHIS2 Program Structure: tracker-program-structure.html
  Artifacts: artifacts.html
```
### 6.5 Validate Changes
After adding pages and updating the sushi-config.yaml file, run SUSHI and the IG Publisher to generate the updated IG. Ensure that the new pages are linked correctly in the navigation menu and that the content appears as expected. 